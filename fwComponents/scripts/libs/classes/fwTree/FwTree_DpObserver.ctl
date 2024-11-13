#uses "classes/fwStdLib/FwException.ctl"


/**
  The way to use it is
  1) get the pointer to the instance using get()
  2) establish all classConnects as necessary
  3) when you are ready to start receiving callbacks, call initialize()

  */
class FwTree_DpObserver
{

#event evTreeDataModified(string what, dyn_dyn_anytype data)
#event evDatapointDeleted(string treeNodeDp)
#event evDistConnectionChanged(string sysName, bool connected)


    protected string sqlElements;

    private static shared_ptr<FwTree_DpObserver> _theInstance=nullptr;
    private static bool _initialized=false;
    protected FwTree_DpObserver()    // restrict!(?)
    {
        // for constructions of the queries:
        const dyn_string elements=makeDynString("device", "type", "children", "parent", "cu", "userdata");
        for (int i=0; i<elements.count(); i++) {
            if (i>0) sqlElements+=" , ";
            sqlElements+="'"+elements.at(i)+":_original.._value'";
        }
    }

    public static shared_ptr<FwTree_DpObserver> get() synchronized(_theInstance)
    {
        if (equalPtr(_theInstance, nullptr)) {
            _theInstance = new FwTree_DpObserver();
        }
        return _theInstance;
    }

    public void sysConnectCB(string what, mapping data)
    {
        //DebugTN(__FUNCTION__,what,data);
        if (what=="dist") {
            if (data["reason"]=="allDisconnected") {

                dyn_string allSysNames;
                dyn_uint allSysIds;
                getSystemNames(allSysNames, allSysIds);
                for (int i=0; i<allSysNames.count(); i++) {
                    string sysName=allSysNames.at(i);
                    if (sysName==strrtrim(getSystemName(), ":")) continue;
                    evDistConnectionChanged(sysName, false);
                }
            } else {
                bool connected=(data["reason"]=="connected");
                string sysName=data["systemName"];
                if (connected) handleSystemConnection(sysName);
                evDistConnectionChanged(sysName, connected);
            }
        }
    }

    public void dpCB(string what, mapping data)
    {
        if (data["dpType"]!="_FwTreeNode") return;
        //DebugTN(__FUNCTION__,what,data);
        if (what=="dpDeleted") {
            evDatapointDeleted(data["dp"]);
        }
    }

    // the function is invoked from dpQueryConnectSingle as well
    // as from the initialize script (after a "static" dpQuery)
    // to feed data to the connected callbacks.
    // Hence, even though it is trivial we need to have a function
    public void dpValueChangeCB(string what, dyn_dyn_anytype data)
    {
        if (dynlen(data)<1) return;
        triggerClassEventWait(evTreeDataModified, what, data);
    }

    /**
      Triggered where a system connects, or at the initialization (for the local system):
      will rebuild the DP cache and then trigger the evDistConnectionChanged signal
      */
    protected void handleSystemConnection(string sysName)
    {
        string localSysName=strrtrim(getSystemName(), ":");
        //DebugTN(__FUNCTION__,sysName);

        string sql="SELECT "+sqlElements+" FROM '*' ";
        if (sysName!="" && sysName!=localSysName) {
            sql += " REMOTE '"+sysName+ "' ";
        } else {
            // set the correct sysName, to be used below
            sysName=localSysName;
        }
        sql+= " WHERE _DPT = \"_FwTreeNode\"";

        dyn_dyn_anytype data;
        try {
            dpQuery(sql, data);
            FwException::checkLastError();
        } catch {
            FwException::raise("Failed dpQuery "+sql, FwException::last().getText());
        }
        // feed the data to the value observer
        dpValueChangeCB(sysName, data); // trigger the cache rebuild
        triggerClassEventWait(evDistConnectionChanged, sysName, true);
    }


    /** Initialize the observer

      */
    public void initialize()
    {
        // minimal sanity checks
        FwException::assert(fwGeneral_dpTypeExists("_FwTreeNode"),"DPType _FwTreeNode does not exist");
        // Note: if there are no datapoints of type _FwTreeNode then the dpQueryConnectSingle still fails
        // with an error "Connect Query not successful, error on fetching header description"...
        // hence we require that at least one DP of such type exists.
        FwException::assertDynNotEmpty(dpNames("*","_FwTreeNode"),"No datapoints of type _FwTreeNode found. Cannot set up the cache");
        // if (_initialized) return;
        //DebugTN(__FUNCTION__);

        // set up exceptions assuring compatibility.
        // we will use exceptions, but we want to keep the original settings for this thread (ie. restore on exit)
        bool origThrowErrorAsExceptions = getThrowErrorAsException();
        setThrowErrorAsException(true);

        try {

            // establish sysConnects already at this point so we won't loose anything;
            // maybe we should synchronize them...
            sysConnect(this, this.dpCB,        "dpDeleted");
            sysConnect(this, this.sysConnectCB, "dist");

            // establish callbacks for all the updates, but without the values - we will do it with dpQuery below
            // and this way we will have the function complete synchronously already with data
            //
            // if DIST manager is stopped the above function may throw an error to the log:
            //  "Message could not be sent, MAN: (SYS: 900 Dist -num 1 CONN: 1), Could not send message DP_MSG_FILTER_REQUEST #58"
            // and
            // "Message could not be sent, MAN: (SYS: 900 Dist -num 1 CONN: 1), Could not send message DP_MSG_FILTER_CONNECT #55"
            // still, it establishes the filter and once DIST is started the callback becomes active. Still, we want to be
            // able to react on any other error and throw it as exception...
            int blockTime=500;
            string sql="SELECT "+sqlElements+" FROM '*' REMOTE ALL WHERE _DPT = \"_FwTreeNode\"";
            try {
                dpQueryConnectSingle(this, this.dpValueChangeCB, false, "DATA_CHANGED", sql, blockTime);
                FwException::checkLastError(); // dpQueryConnectSingle does not throw on its own...
            } catch {
                FwException exc=FwException::last();
                if (!(exc.getText().contains("DP_MSG_FILTER_CONNECT"))) FwException::raise("Failed dpQueryConnectSingle, "+sql, exc.getText());
            }

            // initialize for our own system
            handleSystemConnection("");

            // Initialize the data for the first time synchronously with dpQuery
            // Note that getSystemNames() result is based on DPContainer, not the connection state
            // hence we'd rather get the information about connected system from the _DistManager
            // datapoint. The good thing is that if our local dist manager is stopped then
            // the .State.SystemNums is wiped, hence we could trust it.
            //
            // But we also need to handle the case where a system got disconnected while this
            // observer was not executing - e.g. the case when a panel is re-run from GEDI
            // and DIST got disconnected while the panel was not running.
            // in this case we need to send the disconnection signals too...

            dyn_string allSysNames;
            dyn_uint connectedSysIds, allSysIds;
            dpGet("_DistManager.State.SystemNums", connectedSysIds);
            getSystemNames(allSysNames, allSysIds);
            for (int i=0; i<allSysIds.count(); i++) {
                unsigned sysId=allSysIds.at(i);
                string sysName=allSysNames.at(i);
                if (sysId==getSystemId()) continue; // handled above already; local sys always connected
                if (connectedSysIds.contains(sysId)) {
                    handleSystemConnection(sysName);
                } else {
                    triggerClassEventWait(evDistConnectionChanged, sysName, false);
                }
            }
            //for (int i=0;i<connectedSysIds.count();i++) {
            //  int idx=allSysIds.indexOf(connectedSysIds.at(i));
            //  if (idx>=0) handleSystemConnection(allSysNames.at(idx));
            //}
        } finally {
            _initialized=true;
            setThrowErrorAsException(origThrowErrorAsExceptions);
        }
    }

};
