#uses "classes/fwStdLib/FwException.ctl"
#uses "CtrlOOUtils"
#uses "classes/fwTree/FwTree.ctl"
#uses "classes/fwTree/FwTree_Repository.ctl"
#uses "classes/fwTree/FwTree_DpObserver.ctl"


class FwTree_RepositoryImpl: FwTree_Repository
{
    protected FwTreeNodePVec                  allNodes;
    protected mapping                         treeNodeMap; // keys: tree dp names, values: shared_ptr<FwTreeNode?
    protected shared_ptr<FwTree_DpObserver>   dpObserver=nullptr;

    protected FwTree_RepositoryImpl()
    {
        fwGeneral_loadCtrlLib("classes/fwTree/FwTreeImpl.ctl", true, true);
        dpObserver = FwTree_DpObserver::get();
    }
    //_________________________________________________________________________

    public FwTreeNodePtr get(string treeNodeDP)
    {
        if (!treeNodeDP.contains(":")) treeNodeDP=getSystemName()+treeNodeDP; // make it work for non-prefixed datapoints...
        FwTreeNodePtr tn=treeNodeMap.value(treeNodeDP,nullptr);
        // additionally, exclude the invalidated ones
        if (!equalPtr(tn,nullptr) && tn._invalid) tn=nullptr;
        return tn;
    }
    //_________________________________________________________________________

    public FwTreeNodePVec findBy(string memberName, mixed value, ...)
    {
        FwTreeNodePVec matchingNodes;
        dyn_int foundIdxList = allNodes.indexListOf(memberName, value);
        for (int i=0; i<foundIdxList.count(); i++) {
          FwTreeNodePtr tn = allNodes.at(foundIdxList.at(i));
          // exclude the nodes that are invalid
          if (!equalPtr(tn,nullptr) && tn._invalid==false) matchingNodes.append(tn);
        }

        // now iterate over extra params...
        va_list parameters;
        int len=va_start(parameters)/2;
        for (int va_iter=1; va_iter<=len; va_iter++) {
            memberName=va_arg(parameters);
            value=va_arg(parameters);
            foundIdxList.clear();
            foundIdxList = matchingNodes.indexListOf(memberName, value);
            FwTreeNodePVec tmpMatchingNodes;
            for (int i=0; i<foundIdxList.count(); i++) tmpMatchingNodes.append(matchingNodes.at(foundIdxList.at(i)));
            matchingNodes=tmpMatchingNodes;
        }

        return matchingNodes;
    }
    //_________________________________________________________________________

    public FwTreeNodePtr _createTreeNode(string treeDp)
    {
        //DebugTN(__FUNCTION__,treeDp);
        shared_ptr<FwTreeNode> tn = fwCreateInstance("FwTreeNodeImpl");
        fwInvokeMethod(tn, "FwTreeNodeImpl", treeDp, false); // false =>no check of dpexists/dptype
        allNodes.append(tn);
        treeNodeMap.insert(treeDp, tn);
        return tn;
    }
    //_________________________________________________________________________

    protected bool _setTreeNodeData(FwTreeNodePtr treeNode, dyn_anytype data)
    {
        // Called to update the values - from a callback or creation.
        // it resets the _disconnected and respects the _invalid flag (ie. does nothing if it is set)
        // @param data - follows the structure/order of dpQuery
        // @returns true if there was actually a change for the node, false otherwise

        if (treeNode._invalid) return false;

        // would be nice to set multiple properties at once, or even deserialize them somehow from dyn_mixed
        //string treeDp=data[1];
        bool tnDataModified=false;
        if (treeNode.linkedObj!=data[2]) { treeNode.linkedObj  =   data[2]; tnDataModified=true;}
        if (treeNode.type     !=data[3]) { treeNode.type       =   data[3]; tnDataModified=true;}
        if (treeNode._children!=data[4]) { treeNode._children  =   data[4]; tnDataModified=true;}
        if (treeNode._parent  !=data[5]) { treeNode._parent    =   data[5]; tnDataModified=true;}
        if (treeNode.isMaster !=data[6]) { treeNode.isMaster   =   data[6]; tnDataModified=true;}
        if (treeNode.userData !=data[7]) { treeNode.userData   =   data[7]; tnDataModified=true;}
        if (treeNode._disconnected)      { treeNode._disconnected=false;    tnDataModified=true;}
        return tnDataModified;
    }
    //_________________________________________________________________________

    protected void _treeDataModifiedCB(string what, const dyn_dyn_mixed &data) synchronized(treeNodeMap)
    {
        //DebugTN(__FUNCTION__,what,dynlen(data)-1);


        FwTreeNodePVec modifiedNodes; // keep the list of modified to trigger only once per node...
        FwTreeNodePVec processedNodes; // all processed nodes (for the case of what="INIT" or "dist")

        for (int i=2; i<=data.count(); i++) { // we skip the first row (header);
            string treeDp=(string)data[i][1];
            if (treeDp.startsWith("(Type: ")) {
                // this is a line that tells us about a deleted DP... Skip it - we get another notification anyway
                continue;
            }
            if (substr(fwNoSysName(treeDp),0,5)!="fwTN_") {
              DebugTN("WARNING skipping invalid FwTreeNode DP (no fwTN_ prefix):"+treeDp);
              continue;
            }

            string tnType=data[i][3];
            dyn_string children=data[i][4];
            string parent=data[i][5];
            // suppress the notifications from the FwTreeNodes that we've just created
            // and they are not yet initialised - ie. they have neither parent nor children
            if (children.isEmpty() && parent.isEmpty() && tnType.isEmpty()) continue;

            bool modified=false;
            FwTreeNodePtr tn=treeNodeMap.value(treeDp);

            if (tnType=="*RENAMED*") {
               if (equalPtr(tn,nullptr)) {
                   //DebugTN("OLD TN "+treeDp+" does not exist");
                   continue;
               }
               string renamedTo=data[i][2]; // transferred in the "linkedObj" a.k.a. ".device"
               tn._dp=renamedTo;
               string name= substr(fwNoSysName(renamedTo), 5); // cut the leading "fwTN_"
               if (name.startsWith("&")) name=substr(name, 5); // cut the &0001
               tn.name=name;
               treeNodeMap.remove(treeDp);
               treeNodeMap[renamedTo]=tn; // replace the one created in response to dpCreate()
               modified=true;
               // trigger the notification about the rename.
               evTreeNodeRenamed(tn, treeDp);
               continue;
           } else {
               if (equalPtr(tn, nullptr)) tn = _createTreeNode(treeDp);
               modified=_setTreeNodeData(tn, data[i]);
           }

            if (!processedNodes.contains(tn)) processedNodes.append(tn);
            if (modified && !modifiedNodes.contains(tn)) modifiedNodes.append(tn); // unique() does not work for shared_ptr...
        }

        if (what!="DATA_CHANGED") { // initialization or new dist connection/reconnection
            // in this case "what" holds the system name
            string sysName=what;

            // we will get a complete up-to-date data set retrieved by dpQuery FOR sysName.
            // hence we should invalidate/remove the nodes that are not there anymore...
            // by this point in the code the modifiedNodes will contain the current snapshot
            for (int i=0; i<allNodes.count(); i++) {
                FwTreeNodePtr tn=allNodes.at(i);
                if (!(tn._dp.startsWith(sysName))) continue; // not this system
                if (!processedNodes.contains(tn)) {
                    DebugTN("NODE DOES NOT EXIST ANYMORE", tn._dp);
                    tn._invalid=true;
                    tn._disconnected=true;
                    allNodes.removeAt(i);
                    i--; // update the index as we removed...
                    treeNodeMap.remove(tn._dp);
                }
            }
        }

        // trigger the events yet only if this is an update, not the initialization (in which
        // case one is expected to explore the tree using the repository rather than having callbacks)
        // or a new DIST connect (in which case it is conveyed with another signal)
        if (what=="DATA_CHANGED") {
            evTreeNodesModified(modifiedNodes);
            // trigger on each modified nodes
            for (int i=0; i<modifiedNodes.count(); i++) modifiedNodes.at(i).triggerModified();
        }
    }
    //_________________________________________________________________________


    protected string generateNewID(string name)
    {
        FwException::assert(name!="", "Tree node name may not be empty");

        // we need to have a unique ID - construct it taking into account what's already there
        string sysName=getSystemName();
        if (name.contains(":")) {
            sysName=fwSysName(name, true);
            name=fwNoSysName(name);
        }

        int sysID=getSystemId(sysName);
        FwException::assert(sysID>0,           "Invalid tree node name: system does not exist for specified node "+sysName+":"+name);
        FwException::assert(nameCheck(name)==0,   "Invalid tree node name: characters not permitted "+name);

        string newID=sysName+"fwTN_"+name;
        if (dpExists(newID)) {
            dyn_string matches=getMatchingDPs(name,sysName);
            // "matches" already contain our preferred ID; we remove it to keep only fwTN_&NNNNXXX items
            // then get the last of it
            matches.removeAt(matches.indexOf(newID));
            if (matches.isEmpty()) {
                newID=sysName+"fwTN_&0001"+name;
            } else {
                matches.sort();
                string lastMatch=matches.last();
                int idx=strpos(lastMatch, ":");
                int lastNum=(int)(lastMatch.mid(idx+7, 4));
                FwException::assert(lastNum>0, "Could not generate ID for tree node "+name+" - failed to parse the id of tree node "+lastMatch);
                sprintf(newID, "%sfwTN_&%04d%s", sysName, lastNum+1, name);
            }
        }
        return newID;
    }

    public FwTreeNodePtr create(string name, FwTreeNodePtr parent, string type="",
                                string linkedObject="", dyn_string userData=makeDynString(),
                                bool isMaster=false)
    {
        FwException::assertNotNull(parent,     "Cannot create a node with empty parent: "+name);
        FwException::assert(!parent._invalid,  "Cannot create node "+name+" with invalid parent "+parent._dp);

        string sysName=getSystemName();
        if (name.contains(":")) {
            sysName=fwSysName(name, true);
            name=fwNoSysName(name);
        }

        int sysID=getSystemId(sysName);

        string newID=generateNewID(name);

        // prepare what we will dpSet (we will complete it below);
        // bulking them into a single dpSet helps
        dyn_string dpesToSet    = makeDynString(newID+".device", newID+".type", newID+".cu", newID+".userdata");
        dyn_mixed  valsToSet    = makeDynMixed(linkedObject, type, isMaster, userData);

        // firstly create our own FwTreeNode instance and register it,
        // so that we could return it already; then we will deal with dpCreate/dpSet
        FwTreeNodePtr newNode = _createTreeNode(newID);
        dyn_string emptyChildren; // will be set below anyway
        string emptyParent="";
        _setTreeNodeData(newNode, makeDynMixed(newID, linkedObject, type, emptyChildren, emptyParent, isMaster, userData));
        // Make sure the node will get updated by the callback of the dpSet, and then we get a notification
        newNode._disconnected=true;
        if (!equalPtr(parent, nullptr)) {
            // link the new child to the parent
            dyn_string newChildrenList=parent._children;
            dynAppend(newChildrenList, fwNoSysName(newID)); // TO REVIEW: SHOULD WE NOT HAVE A SYSTEM PREFIX (CHANGE OF CONVENTION!)
            parent._children=newChildrenList;
            string parentDP=parent._dp;
            newNode._parent = fwNoSysName(parentDP);

            dpesToSet.append(newID+".parent");
            valsToSet.append(fwNoSysName(parentDP));
            dpesToSet.append(parentDP+".children");
            valsToSet.append(newChildrenList);
        }
        dpCreate(fwNoSysName(newID), "_FwTreeNode", sysID);
        FwException::checkLastError();

        dpSetWait(dpesToSet, valsToSet);
        FwException::checkLastError();

        return newNode;
    }
    //_________________________________________________________________________


    public dyn_string getMatchingDPs(string name, string sysName="")
    {
        if (name.contains(":")) {
            sysName=fwSysName(name, true);
            name=fwNoSysName(name);
        }
        string pattern1=sysName+"fwTN_"+name;
        string pattern2=sysName+"fwTN_&*{0,1,2,3,4,5,6,7,8,9}"+name;
        dyn_string matches=dpNames("{"+pattern1+","+pattern2+"}", "_FwTreeNode");
        return matches;
    }
    //_________________________________________________________________________

    public void drop(FwTreeNodePtr tn, bool recursively=false)
    {
        // note! we MUST be able to remove the tree node that is marked as invalid!
        dyn_string dpsToDrop = makeDynString(tn._dp);

        FwTreeNodePVec childrenList;
        FwTreeNodePtr parentNode=tn.getParent();

        if (!tn._invalid) {
            FwException::assert(!equalPtr(parentNode, nullptr), "Cannot drop the top tree node: "+tn._dp);
            childrenList = tn.getAllChildren(); // recursive list of children
        }

        FwException::assert(childrenList.isEmpty() || recursively, "Cannot remove a tree node that has children nodes attached: "+tn._dp);

        // mark the nodes invalid ASAP to avoid e.g. dpDelete callbacks
        // fo attempt mainpulating our ._children
        tn._invalid=true;
        tn._disconnected=true;
        tn.triggerModified();

        for (int i=0; i<childrenList.count(); i++) {
            FwTreeNodePtr childTn = childrenList.at(i);
            if (childTn._invalid) continue; // already being deleted...
            dpsToDrop.append(childTn._dp);
            childTn._disconnected=true;
            childTn._invalid=true;
            // trigger the notification to the node as it gets invalid...
            childTn.triggerModified();
        }

        FwTreeNodePVec modifiedNodes = childrenList;
        modifiedNodes.append(tn);

        if (!equalPtr(parentNode, nullptr) && (!parentNode._invalid) && (!parentNode._disconnected)) {
            // remove ourselves from the parent
            dyn_string childrenList=parentNode._children;
            int idx=dynContains(childrenList, fwNoSysName(tn._dp));
            if (idx) dynRemove(childrenList, idx);
            parentNode._children=childrenList;
            dpSetWait(parentNode._dp+".children", childrenList); // this will trigger the update on parent
            parentNode.triggerModified();
            modifiedNodes.append(parentNode);
        }

        // trigger update on all impacted nodes
        evTreeNodesModified(modifiedNodes);

        // delayed dpDelete() to avoid the infamous warning
        // "DpIdentifier, formatValue, could not convert DpIdentifier to string";
        //  Still, we need to wait for it to finish to make sure
        // that DPs were really deleted (tried async execution of it via startScript
        // yet it is not guaranteed to finish when unit test stop).
        delay(0, 600);
        for (int i=0; i<dpsToDrop.count(); i++) {
            string dp=dpsToDrop.at(i);
            if (dpExists(dp)) dpDelete(dp);
        }

    }
    //_________________________________________________________________________

    protected void _treeDpDeletedCB(string treeNodeDP)
    {
        FwTreeNodePtr deletedNode = get(treeNodeDP);
        if (equalPtr(deletedNode,nullptr)) return; // not found anymore...
        deletedNode._invalid=true;
        triggerClassEventWait(evTreeNodeDeleted, deletedNode);

        string parentNodeID=deletedNode._parent;
        FwTreeNodePtr parentNode=get(parentNodeID);
        if (!equalPtr(parentNode, nullptr) && !parentNode._invalid) {
            dyn_string childrenList=parentNode._children;
            dynUnique(childrenList);
            int idx = dynContains(childrenList, fwNoSysName(treeNodeDP));
            if (idx>0) {
                dynRemove(childrenList, idx);
                parentNode._children=childrenList;
            }
        }
        // now remove the node from our lists
        int idx=allNodes.indexOf(deletedNode);
        if (idx>=0) allNodes.removeAt(allNodes.indexOf(deletedNode));
        if (treeNodeMap.contains(treeNodeDP)) treeNodeMap.remove(treeNodeDP);
    }
    //_________________________________________________________________________

    protected void _distChangedCB(string sysName, bool connected)
    {
        //DebugTN(__FUNCTION__,sysName,connected);
        dyn_string allIDs = mappingKeys(treeNodeMap);
        dyn_string idsInThisSys=dynPatternMatch(sysName+":*", allIDs);
        vector<shared_ptr<FwTreeNode> > modifiedNodes;
        for (int i=0; i<idsInThisSys.count(); i++) {
            FwTreeNodePtr tn=treeNodeMap[idsInThisSys.at(i)];
            if (tn._disconnected != !connected) {
                tn._disconnected = !connected;
                tn.triggerModified();
            }
            modifiedNodes.append(tn);
        }
        triggerClassEventWait(evDistChanged, sysName, connected);
        triggerClassEventWait(evTreeNodesModified, modifiedNodes);
    }
    //_________________________________________________________________________

    public void initialize()
    {
        // NOTE that it does not hurt to classConnect many times the same object to the same callback
        // it will be only once that it will be invoked anyway.
        // and in order to deal with re-running the panel when the objects kept in static data members
        // survive, we would rather have the classConnect's below called every time (it won't hurt)
        // rather that too few times...

        //DebugTN(__FUNCTION__);
        FwTree_Repository::getInstance(); // make sure the instance exists...
        classConnect(this, this._treeDataModifiedCB, dpObserver, FwTree_DpObserver::evTreeDataModified);
        classConnect(this, this._treeDpDeletedCB,    dpObserver, FwTree_DpObserver::evDatapointDeleted);
        classConnect(this, this._distChangedCB,      dpObserver, FwTree_DpObserver::evDistConnectionChanged);

        dpObserver.initialize();

        // the above command executes synchronously and populates the DP Cache so now we could validate it...

        for (int i=0; i<allNodes.count(); i++) {
            FwTreeNodePtr tn=allNodes.at(i);
            if (tn._invalid) continue; // no point in doing anything with this node anymore...
            FwTreeNodePtr parentTn=tn.getParent();
            if (!equalPtr(parentTn, nullptr)) {
                if (! tn._dp.contains("fwTN_---Clipboard")) {
                    FwTreeNodePVec pChildren = parentTn.getChildren();
                    if (!pChildren.contains(tn)) DebugTN("WARNING: TreeNode "+tn._dp+" not contained in the children list of its parent "+parentTn._dp);
                }
            }
            FwTreeNodePVec childrenList = tn.getChildren();
            for (int j=0; j<childrenList.count(); j++) {
                FwTreeNodePtr child=childrenList.at(j);
                if (equalPtr(child, nullptr)) {
                    DebugTN("WARNING: TreeNode "+tn._dp+" refers to non-existing child "+tn._children.at(j));
                } else {
                    FwTreeNodePtr cParent=child.getParent();
                    if (equalPtr(cParent, nullptr)) {
                        DebugTN("WARNING: TreeNode "+tn._dp+" has child "+tn._children.at(j)+" which points to empty parent");
                    } else if (!equalPtr(cParent, tn)) {
                        DebugTN("WARNING: TreeNode "+tn._dp+" has child "+tn._children.at(j)+" which points to another parent "+cParent._dp);
                    }
                }
            }
        }
    }
    //_________________________________________________________________________

    // reset the cache...
    public void reset()
    {
        allNodes.clear();
        treeNodeMap.clear();
        initialize();
    }
    //_________________________________________________________________________

    public void showCache(bool full=true)
    {
        DebugTN(__FUNCTION__, full);
        if (!full) {
            dyn_string keys=mappingKeys(treeNodeMap);
            dynSort(keys);
            DebugTN(keys);
            return;
        }
        // otherwise... print full
        for (int i=0; i<allNodes.count(); i++) {
            allNodes.at(i).ls();
        }
    }
    //_________________________________________________________________________


    public void reorderChildren(FwTreeNodePtr parent, FwTreeNodePVec children)
    {
        FwException::assert(!parent._invalid,"Cannot reorder children on invalid tree node"+parent._dp);
        dyn_string newChildrenList;
        dyn_string oldChildrenList=parent._children;

        string parentSysName=fwSysName(parent._dp);
        for (int i=0; i<children.count(); i++) {
            string childDP=children.at(i)._dp;
            FwException::assertEqual(parentSysName, fwSysName(childDP), "Cannot reorder tree items: Child item "+childDP+" is from different system that the parent "+parent._dp);
            string childID = fwNoSysName(childDP);
            int idx=oldChildrenList.indexOf(childID);
            FwException::assert(idx>=0, "Cannot reorder tree items: item "+childID+" is not a child of "+parent._dp);
            newChildrenList.append(childID);
            oldChildrenList.removeAt(idx);
        }
        // check/treat the clipboard node...
        for (int i=0; i<oldChildrenList.count(); i++) {
            string tnName=oldChildrenList.at(i);
            if (tnName.startsWith("fwTN_---Clipboard")) {
                oldChildrenList.removeAt(i);
                newChildrenList.prepend(tnName);
                break;
            }
        }
        // ensure all of children are in the new list...
        FwException::assert(oldChildrenList.isEmpty(), "Cannot reorder tree items: not all children included in the new list , "+strjoin(oldChildrenList, " , "));

        parent._children=newChildrenList; // immediately modify our entry and trigger the events
        FwTreeNodePVec modifiedNodes;
        modifiedNodes.append(parent);
        evTreeNodesModified(modifiedNodes);
        parent.triggerModified();

        dpSetWait(parent._dp+".children", newChildrenList);
        FwException::checkLastError();
    }
    //_________________________________________________________________________


    public void moveNode(FwTreeNodePtr tn, FwTreeNodePtr newParent, FwTreeNodePtr beforeTN=nullptr)
    {
        FwException::assert(!tn._invalid,"Cannot move tree node that is invalid: "+tn._dp);
        FwException::assertNotNull(newParent,"Cannot move tree node "+tn._dp+" to a null parent");

        // DebugTN(__FUNCTION__, tn._dp, newParent._dp);
        if (tn.getParent()==newParent) return; // moving to the current parent - just skip it.
        FwException::assert(!newParent._invalid,"Cannot move tree node "+tn._dp+ " to a invalid parent "+newParent._dp);
        string nodeDP=tn._dp;
        string parentDP=newParent._dp;
        FwException::assertEqual(fwSysName(nodeDP),fwSysName(parentDP), "Cannot move tree node "+nodeDP+" - new parent is in different system: "+parentDP);
        FwException::assert(!tn.isRoot(), "Cannot move the tree root node");
        if (nodeDP==parentDP) {
            DebugTN(__FUNCTION__, "TODO: MAYBE WE SHOULD DO reorderChildren here");
            return; // nothing to do
        }
        string nodeID=fwNoSysName(nodeDP);
        string parentID=fwNoSysName(parentDP);

        // make sure we are not moving this node to one of its children
        FwTreeNodePVec allChildren=tn.getAllChildren();
        FwException::assert(!allChildren.contains(newParent),"Cannot move tree node "+nodeDP+" below itself in the tree");

        FwTreeNodePtr prevParent=tn.getParent(); // we know it is not null as it is not a root node
        string prevParentDP = prevParent._dp;
        dyn_string prevParentChildren = prevParent._children;
        dyn_string newParentChildren = newParent._children;

        int idx=prevParentChildren.indexOf(nodeID);
        // note: it may happen that it was not found if the parent's list of children was inconsistent...
        if (idx>=0) prevParentChildren.removeAt(idx);

        int newPos=-1; // means append; notably if beforeTN==nullptr
        if (!equalPtr(beforeTN, nullptr)) {
            // find the place at which we should insert it
            newPos=newParentChildren.indexOf(fwNoSysName(beforeTN._dp));
        }
        if (newPos>=0 && newPos<newParentChildren.count()) {
            newParentChildren.insertAt(newPos, nodeID);
        } else {
            newParentChildren.append(nodeID);
        }

        prevParent._children=prevParentChildren;
        newParent._children=newParentChildren;
        tn._parent=parentID;
        // trigger all the local events to have immediate feedbask
        FwTreeNodePVec modifiedNodes;
        modifiedNodes.append(prevParent);
        modifiedNodes.append(newParent);
        modifiedNodes.append(tn);
        evTreeNodesModified(modifiedNodes);
        prevParent.triggerModified();
        newParent.triggerModified();
        tn.triggerModified();

        dpSetWait(nodeDP+".parent", parentID,
                  parentDP+".children", newParentChildren,
                  prevParentDP+".children", prevParentChildren);
        FwException::checkLastError();
    }
    //_________________________________________________________________________

    public void setFromObject(FwTreeNodePtr tn, bool setParent=false, bool setChildren=false)
    {
        FwException::assert(!tn._invalid, "Cannot set tree node data from invalid object "+tn._dp);
        string dp=tn._dp;
        dyn_string dpes =  makeDynString(dp+".type", dp+".device" , dp+".cu"    ,dp+".userdata");
        dyn_mixed values = makeDynMixed (  tn.type , tn.linkedObj , tn.isMaster ,  tn.userData);
        if (setParent) {
            dpes.append(dp+".parent");
            values.append(tn._parent);
        }
        if (setChildren) {
            dpes.append(dp+".children");
            values.append(tn._children);
        }
        dpSetWait(dpes,values);
        FwException::checkLastError();
        FwTreeNodePVec modifiedNodes;
        modifiedNodes.append(tn);
        evTreeNodesModified(modifiedNodes);
        // tn.triggerModified();    // we leave calling this up to the FwTreeNode that invokes us
    }
    //_________________________________________________________________________


    public FwTreeNodePtr createRootNode(string name)
    {
        FwException::assert(name!="", "Cannot create root tree node with empty name");

        // we need to have a unique ID - construct it taking into account what's already there
        string sysName=getSystemName();
        if (name.contains(":")) {
            sysName=fwSysName(name, true);
            name=fwNoSysName(name);
        }
        FwException::assert(!name.startsWith("fwTN"), "Need to specify tree node NAME (not ID, starting fwTN) in createRootNode: "+name);
        string treeDP = sysName+"fwTN_"+name;

        int sysID=getSystemId(sysName);
        FwException::assert(sysID>0, "Cannot create root tree node - system does not exist for specified node "+sysName+name);
        FwException::assert(nameCheck(name)==0,      "Cannot create root tree node - invalid name (chars not permitted) "+name);
        FwException::assert(!dpExists(treeDP),      "Cannot create root tree node - datapoint already in use "+treeDP);

        FwTreeNodePtr newNode = _createTreeNode(treeDP);
        dpCreate(fwNoSysName(treeDP), "_FwTreeNode", sysID);
        FwException::checkLastError();

        // immediately set it as valid and connected (usually done with _setTreeNodeData, which we don't call here as no need for it)
        newNode._invalid=false;
        newNode._disconnected=false;
        return newNode;
    }
    //_________________________________________________________________________

    // NOTE! The node that is created has the _invalid flag set!
    public FwTreeNodePtr createDetachedNode(string name)
    {
        FwTreeNodePtr tn=_createTreeNode(createUuid());
        tn._invalid=true;
        tn._disconnected=true;
        return tn;
    }
    //_________________________________________________________________________

    public void renameNode(FwTreeNodePtr tn, string newNodeName)
    {
        if (newNodeName==tn.getName()) return; // nothing to be done

        // Implemented through drop/create rathen than dpRename, as we would
        // otherwise have problems with interpreting the callbacks.
        // We want the original tn ro remain valid, ie. have it updated
        // (as well as all the mappings, etc).

        string oldNodeDP=tn._dp;
        string newNodeDP=generateNewID(newNodeName); // throws as necessary
        string sysName=getSystemName();
        if (newNodeName.contains(":")) {
            FwException::assertEqual(fwSysName(newNodeName),fwSysName(tn._dp),
                                 "Tree node rename does not work across systems: "+tn._dp+"->"+newNodeName);
            newNodeName=fwNoSysName(newNodeName);
            sysName=fwSysName(newNodeName);
        }
       // preserve the list of children, as we will need to update them
        FwTreeNodePVec children = tn.getChildren();
        FwTreeNodePtr  parent   = tn.getParent();

        // create the tree node DP
        dpCreate(fwNoSysName(newNodeDP), "_FwTreeNode", getSystemId(sysName));
        // now we have it. Let us modify the map and our own tn to be used by the subsequent callbacks!
        tn._dp=newNodeDP;
        tn.name=newNodeName;
        tn._disconnected=true; // will help us to get the notification later
        treeNodeMap.remove(tn._dp);
        treeNodeMap.insert(newNodeDP,tn);

        // prepare to re-link parent/children pointers
        dyn_string dpes;
        dyn_mixed values;
        for (int i=0;i<children.count();i++) {
            dpes.append(children.at(i)._dp+".parent");
            values.append(newNodeDP);
        }
        if (!equalPtr(parent,nullptr)) {
            dyn_string pChildren=parent._children;
            int idx=pChildren.indexOf(fwNoSysName(oldNodeDP));
            if (idx>=0) pChildren[idx+1]=fwNoSysName(newNodeDP);
            parent._children=pChildren;
            dpes.append(parent._dp+".children");
            values.append(pChildren);
        }

        // yet before we set everything to datapoints...

        // trigger the notification locally already...
        evTreeNodeRenamed(tn, oldNodeDP);

        //  ... and remotel by setting special values:
        // note that for local system it means another notification...
        dpSetWait( oldNodeDP+".type","*RENAMED*",
                   oldNodeDP+".device",newNodeDP);

        // now flush all the necessary modifications to DPs...

        setFromObject(tn,true,true); // dump to DP, including parent and children; it triggers evTreeNodesModified()!
        dpSetWait(dpes,values);


        delay(0,500); // to avoid callbacks from setting the oldNodeDP (e.g. the "*RENAMED*" thing above);
        dpDelete(oldNodeDP);
    }
    //_________________________________________________________________________

};

