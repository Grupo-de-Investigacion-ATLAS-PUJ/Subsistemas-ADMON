/**@name SCRIPT: unDistributedControl.ctl

@author: Herve Milcent (LHC-IAS)

Creation Date: 12/07/2002

Modification History: 
  05/09/2011: Herve
  - IS-599: system name and component version added in the MessageText log and in the diagnostic  
  
	19/02/2008: Herve
		- check if unMessagetext function defined
		
	11/05/2006: Herve
		- optimization of dpSet
		
	06/07/2004: Herve
		- in unDistributedControl_init: 
			. remove the dist_read and replace it by unDistributedControl_getAllDeviceConfig
			. unDistributedControl DP are not created anymore, must be present
			. remove the redundancy
			. dpConnect to _Connection.Dist.ManNums and _DistManager.State.SystemNums
			

version 1.0

Purpose: 
This script implements the unDistributedControl component. The DistributedControl component checks if the 
remote PVSS systems defined are connected or not. The result of this check can be used to set 
the graphical characteristics of a component, send a message to the operator, send email, send an SMS, etc.

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. global variable: the following variables are global to the script
		. g_unDistributedControl_localDpName: the data point name for the local system: string
		. g_unDistributedControl_dsSysName: the list of the remote system names: dyn_string
		. g_unDistributedControl_dsRemoteDpName: the list of data point name for the remote systems: dyn_string
		. g_DistConnected: is the local WCCILdist manager connected
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
		. c_unDistributedControl_dpName: the beginning of the data point name of the DistributedControl component
		. c_unDistributedControl_dpElementName: the data point element name of the DistributedControl component
	. data point type needed: _UnDistributedControl
	. data point: the following data point is needed per system names
		. _unDistributedControl_XXX_n: of type _UnDistributedControl, XXX is the remote system name (without :)
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/

#uses "unDistributedControl/unDistributedControl.ctl"

// global declaration
global string g_unDistributedControl_localDpName;
global dyn_string g_unDistributedControl_dsRemoteSysName;
global dyn_string g_unDistributedControl_dsRemoteDpName;
global dyn_bool g_unDistributedControl_bRemoteState;
global bool g_unDistributedControl_active;
global bool g_unDistributedControl_bLocalState;
global bool g_unDistributedControl_initialized;
global bool g_unMessagetextDefined;
global string g_DistributedControl_sSystemName;
// end global declaration

//@{

// main
/**
Purpose:
This is the main of the script.

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. no temporary data point, no graphical element
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
main()
{
	dyn_string exceptionInfo; // to hold any errors returned by the function
  int iRes, i, len;
  dyn_dyn_string ddsComponentsInfo;
  string sMessage;
	
	g_unMessagetextDefined = isFunctionDefined("unMessageText_sendException");
  g_DistributedControl_sSystemName = getSystemName();

// initialize the select/deselect mechanism
	unDistributedControl_init(exceptionInfo);

// handle any error, send message to the MessageText component
	if(dynlen(exceptionInfo) > 0) {
//		DebugN("MessageText", "-1;0", "DistributedControl initialisation failed", exceptionInfo);
		if(g_unMessagetextDefined)
			unMessageText_sendException("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", exceptionInfo);
// handle any error uin case the send message failed
		if(dynlen(exceptionInfo) > 0) {
			DebugTN(g_DistributedControl_sSystemName+"DistributedControl", exceptionInfo);
		}
	}
	else {
//		DebugN("MessageText", "-1;0", "DistributedControl initialisation successfully done");
    iRes = fwInstallation_getInstalledComponents(ddsComponentsInfo);
    len = dynlen(ddsComponentsInfo);
    for(i=1;i<=len;i++)
    {
      if(ddsComponentsInfo[i][1] == "unDistributedControl")
      {
        sMessage = "unDistributedControl version "+ddsComponentsInfo[i][2]+" loaded";
        i = len+1;
      }
    }
    if(g_unMessagetextDefined)
    {
  			unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "INFO", 
  					getCatStr("unDistributedControl", "STARTED") , exceptionInfo);
  			unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "INFO", sMessage , exceptionInfo);
    }
    else
    {
  			DebugTN(g_DistributedControl_sSystemName+"DistributedControl: "+getCatStr("unDistributedControl", "STARTED"));
  			DebugTN(g_DistributedControl_sSystemName+"DistributedControl: "+ sMessage);
    }
// handle any error uin case the send message failed
		if(dynlen(exceptionInfo) > 0) {
			DebugTN(g_DistributedControl_sSystemName+"DistributedControl: "+getCatStr("unDistributedControl", "STARTED"), exceptionInfo);
		}
	}
}

// unDistributedControl_init
/**
Purpose:
This function does the initialisation the DistributedControl component. 

The list of remote PVSS system is read from the config file via the dist_readConfig function. A dpConnect is done to 
the internal data point in order to check if the remote systems are connected or not. Redundancy is not supported.

	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. global variable: the following variables are global to the script
		. g_unDistributedControl_localDpName: the data point name for the local system: string
		. g_unDistributedControl_dsRemoteDpName: the list of data point name for the remote systems: dyn_string
		. g_unDistributedControl_dsRemoteSysName: the list of remote system name
		. g_unDistributedControl_localDpName: the local data point name
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
		. c_unDistributedControl_dpName: the beginning of the data point name of the DistributedControl component
		. c_unDistributedControl_dpElementName: the data point element name of the DistributedControl component
	. data point type needed: _UnDistributedControl
	. data point: the following data point is needed per system names, if it does not exist it is created at startup
		. _unDistributedControl_XXX_n: of type _UnDistributedControl, XXX is the remote system name (without :)
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
unDistributedControl_init(dyn_string &exceptionInfo)
{
	dyn_string dsSystemName, dsHost;
	dyn_int diPortNumber, diSystemId;
	int len, i, pos, iRes;
	string sDpName;
	
  //Make sure the CtrlDebug dp exists for the control manager:
  string debugDp = "_CtrlDebug_CTRL_" + myManNum();
  if(!dpExists(debugDp))
  {
    dpCreate(debugDp, "_CtrlDebug");
  }
// read all the config of type _UnDistributedControl
	unDistributedControl_getAllDeviceConfig(dsSystemName, diSystemId, dsHost, diPortNumber);
	g_unDistributedControl_initialized = false;
	
	len = dynlen(dsSystemName);	
	for(i=1;i<=len;i++) {
// fill the global variables
		if((dsSystemName[i]+":") != getSystemName()) {
			dynAppend(g_unDistributedControl_dsRemoteDpName, c_unDistributedControl_dpName+dsSystemName[i]);
			dynAppend(g_unDistributedControl_dsRemoteSysName, dsSystemName[i]+":");
			dynAppend(g_unDistributedControl_bRemoteState, false);
		}
	}	

// initialise the local dpname
	// make sure the local system is indicated as connected (FWCORE-3379)
	g_unDistributedControl_localDpName = c_unDistributedControl_dpName+ 
						substr(getSystemName(), 0, strpos(getSystemName(), ":"));
	g_unDistributedControl_bRemoteState = true;
	dpSetWait(g_unDistributedControl_localDpName+c_unDistributedControl_dpElementName, true);

// end of initialisation, connect to the dist dps.

 // to handle redundancy just connect to the right dp (_Connections / _Connections_2 and _DistManager / _DistManager_2). The logic is based on the list of connected system numbers so it will work
  // even if the remote system is redundant. Only the active unDistributedControl.ctl script will be able to write the data point so we have the information from the active system
  if (isRedundant()) {
  	iRes = dpConnect("_unDistributedControl_callbackRedundant", fwInstallationRedu_getLocalDp("_Connections") + ".Dist.ManNums", fwInstallationRedu_getLocalDp("_DistManager") + ".State.SystemNums",
                     fwInstallationRedu_getLocalDp("_ReduManager") + ".Status.Active");
  } else {
   	iRes = dpConnect("_unDistributedControl_callback","_Connections.Dist.ManNums", "_DistManager.State.SystemNums");
  }

	if(iRes == -1) {
		fwException_raise(exceptionInfo, "ERROR", "unDistributedControl_init: cannot monitor dist manager connection datapoints" ,"");
	}

	string version;
	bool inUnicos = fwInstallation_isComponentInstalled("unCore", version);
	if (inUnicos) {

	    // make a hotlink to follow changes applied through the configuration panel;
	    // they come by creating/deleting/modifying datapoints of type _UnDistributedControl
	    // we also want all the changes to be reflected, hence we trace the .config DPE;
	    // note that due to some buggy behavious of callbacks, we need a very long wait time.
	    string query = "SELECT '.config:_original.._value' FROM '*' WHERE _DPT = \"_UnDistributedControl\"";
	    iRes = dpQueryConnectSingle("_unDistributedControl_DPsChangedCB",true,"Trace Changes in _UnDistributedControl DPs",query,3000);
	    if(iRes == -1) {
		fwException_raise(exceptionInfo, "ERROR", "unDistributedControl_init: cannot monitor configuration","");
	    }
	}
}


/** Trace changes applied by configuration panel (added/removed systems)

    @note We might want to rewrite it using unDistributedControl_getAllDeviceConfig() 
    that returns all the information retrieved with dpNames+dpGet's.

    It should be refactored for WinCC OA 3.16 to use systemConnect instead.

    The functionality of a hotlink on "all" systems (including new ones configured,
    as well as "unconfigured") should be exposed in the API, as it is used also
    in the SystemStatus panel (some code duplication).

    @whitelisted{Callback}
*/
void _unDistributedControl_DPsChangedCB(anytype userData, dyn_dyn_anytype results)
{
    // note that the first row in the results is the header;
    // first column is the DPE that had the value changed, second the config data;

    string mySysName=getSystemName();

    dyn_string newRemoteDpName, newRemoteSysName;
    dyn_bool newRemoteState;

    for (int i=2;i<=dynlen(results);i++) {
	string dp=results[i][1];
	dyn_string params=strsplit(results[i][2],";");

	// protect from invalid entries with deleted/incomplete result
	if (dynlen(params)!=3) continue;
	if (strpos(dp,mySysName)!=0) continue; //sometimes we get entries for deleted DPs; they do not start with system name

	int iSplitPos = strpos(dp, c_unDistributedControl_dpName); // skip the "_unDistributedControl_" string to extract system name
	if ( iSplitPos < 0) {
	    DebugTN(__FUNCTION__,"Cannot decode system name from dpname",dp);
	    continue; // DP has wrong name
	}

	string sysName = substr(dp, iSplitPos + strlen(c_unDistributedControl_dpName));

	if (sysName+":"==mySysName) continue; // skip the local system

	dynAppend(newRemoteDpName, dp);
	dynAppend(newRemoteSysName, sysName+":");
	dynAppend(newRemoteState,false);
    }


    g_unDistributedControl_dsRemoteDpName=newRemoteDpName;
    g_unDistributedControl_dsRemoteSysName=newRemoteSysName;
    g_unDistributedControl_bRemoteState=newRemoteState;

    // trigger the callbacks
    dyn_int val;
    time ts;
    dpGet("_DistManager.State.SystemNums",val, "_DistManager.State.SystemNums:_online.._stime",ts);
    dpSetTimed(ts,"_DistManager.State.SystemNums",val);

}

// _unDistributedControl_callbackRedundant
// called if the system is redundant. Just uses the _ReduManager.Status.Active data point as a trigger but the logic is the same of non redundant case (the old callback is called)
_unDistributedControl_callbackRedundant(string sConn, dyn_int localSystemIds, string sDistConnectionDp, dyn_int remoteSystemIds, string sReduActive, bool active) {
 
  // if we change the redundancy state set g_unDistributedControl_initialized to false to be sure to reset the data points to the proper state read out in this system
  if (g_unDistributedControl_active != active) {
    g_unDistributedControl_initialized = false;
  }
  g_unDistributedControl_active = active;
  _unDistributedControl_callback(sConn,localSystemIds,sDistConnectionDp,remoteSystemIds);
  
}



// _unDistributedControl_callback
/**
Purpose:
This is the callback function called in the case of no redundant system. It sets the _unDistributedControl data point according to the state 
of the remote systems. 

localSystemIds contains the manager number of the local WCCILdist. No value means that the WCCILdist 
is not connected, therefore all the _unDistributedControl have to be set to false because there is no connection to the 
remote systems. 

remoteSystemIds contains the list of remote WCCILdist manager number connected and ready to the local WCCILdist, equivalent to 
remote system name because the WCCILdist manager number must be unique within the whole distributed system. 
getSystemId(remote systemName) returns the Id of the remote system, if the corresponding Id is in the remoteSystemIds 
then the _unDistributedControl is set to true, otherwise it is set to false.

	@param sConn: string, input, the _Connections.Dist.ManNums data point element
	@param localSystemIds: dyn_int, input, the value of _Connections.Dist.ManNums data point element
	@param sDistConnectionDp: string, input, the _DistManager.State.SystemNums data point element
	@param remoteSystemIds: dyn_int, input, the value of _DistConnections.Dist.ManNums data point element

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
_unDistributedControl_callback(string sConn, dyn_int localSystemIds, string sDistConnectionDp, dyn_int remoteSystemIds)
{

	int deviceSystemId, posId, i, len;
	string messageString;
	dyn_string exceptionInfo;

  //DebugN("_unDistributedControl_callback", localSystemIds, remoteSystemIds);
  string version = "N/A";
  bool notUnicos = !fwInstallation_isComponentInstalled("unCore", version);

	if(dynlen(localSystemIds) < 1) {
// local WCCILdist not connected  
// set the all the system state dps to false
		len = dynlen(g_unDistributedControl_dsRemoteDpName);
		for(i=1;i<=len;i++) {
			if(!g_unDistributedControl_initialized) {
				dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, false);
				messageString = getCatStr("unDistributedControl", "REMNOTCON")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
				if(g_unMessagetextDefined)
					unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
			}
			else if(g_unDistributedControl_bRemoteState[i])  {
				dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, false);
				messageString = getCatStr("unDistributedControl", "REMNOTCON")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
				if(g_unMessagetextDefined)
					unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
			}
			g_unDistributedControl_bRemoteState[i] = false;
		}
		// FWCORE-3379 DO NOT set the local dp to false
		// yet still emit a message to the log

		if(!g_unDistributedControl_initialized) {
			//dpSetWait(g_unDistributedControl_localDpName+c_unDistributedControl_dpElementName, false);
			messageString = getCatStr("unDistributedControl", "LOCNOTCON")+ ": "+g_unDistributedControl_localDpName;
			if(g_unMessagetextDefined)
				unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
		}
		else if(g_unDistributedControl_bLocalState) {
			//dpSetWait(g_unDistributedControl_localDpName+c_unDistributedControl_dpElementName, false);
			messageString = getCatStr("unDistributedControl", "LOCNOTCON")+ ": "+g_unDistributedControl_localDpName;
			if(g_unMessagetextDefined)
				unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
		}
		//g_unDistributedControl_bLocalState = false;
	}
	else {
    
    if(notUnicos)
    {
      //If unCore is not installed, we will create a new dp for each of the connected WinCC OA systems    
      len = dynlen(remoteSystemIds);
      for(int i = 1; i <= len; i++)
      {
        string sys = getSystemName(remoteSystemIds[i]);
        strreplace(sys, ":", "");
        //DebugN("Checking if dp exists: " + sys , !dpExists(c_unDistributedControl_dpName + sys));
        if(sys != "" && !dpExists(c_unDistributedControl_dpName + sys))  
        {
          DebugTN(g_DistributedControl_sSystemName+"DistributedControl: Detected new connection to system " + sys + ". Creating internal datapoint as this is not a UNICOS project.");
          dpCreate(c_unDistributedControl_dpName + sys, "_UnDistributedControl");
          dpSet(c_unDistributedControl_dpName + sys + ".config", ";;" + remoteSystemIds[i],
                c_unDistributedControl_dpName + sys + ".connected", true);
          //Add the new system to the global variables:
     			dynAppend(g_unDistributedControl_dsRemoteDpName, c_unDistributedControl_dpName+sys);
    			dynAppend(g_unDistributedControl_dsRemoteSysName, sys+":");
    			dynAppend(g_unDistributedControl_bRemoteState, true);

        }
      }
    }

		len = dynlen(g_unDistributedControl_dsRemoteSysName);
// check which system among the defined one are connected, check in systemIds
		for(i=1;i<=len;i++) {
      // get the systemId
			deviceSystemId = getSystemId(g_unDistributedControl_dsRemoteSysName[i]);
// if the systemId is included, remote system connected and ready
			posId = dynContains(remoteSystemIds, deviceSystemId);
			if(posId>0) {
// set the dp to true.
				if(!g_unDistributedControl_initialized) {
					dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, true);
					messageString = getCatStr("unDistributedControl", "REMCONOK")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
					if(g_unMessagetextDefined)
						unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
				}
				else if(!g_unDistributedControl_bRemoteState[i]) {
					dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, true);
					messageString = getCatStr("unDistributedControl", "REMCONOK")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
					if(g_unMessagetextDefined)
						unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
				}
				g_unDistributedControl_bRemoteState[i] = true;

			}
			else {
// remote system not connected
// set the dp to false.
				if(!g_unDistributedControl_initialized) {
					dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, false);
					messageString = getCatStr("unDistributedControl", "REMNOTCON")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
					if(g_unMessagetextDefined)
						unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
				}
				else if(g_unDistributedControl_bRemoteState[i]) {
					dpSetWait(g_unDistributedControl_dsRemoteDpName[i]+c_unDistributedControl_dpElementName, false);
					messageString = getCatStr("unDistributedControl", "REMNOTCON")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
					if(g_unMessagetextDefined)
						unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
				}
				g_unDistributedControl_bRemoteState[i] = false;
			}
		}
    
// local WCCILdist connected
    //make sure that the local system dp has not been deleted:
    if(!dpExists(g_unDistributedControl_localDpName))
    {
      dpCreate(g_unDistributedControl_localDpName, "_UnDistributedControl");
    }

    // set the local dp to true
		if(!g_unDistributedControl_initialized) {
			//dpSetWait(g_unDistributedControl_localDpName+c_unDistributedControl_dpElementName, true);
			messageString = getCatStr("unDistributedControl", "LOCCONOK")+ ": "+g_unDistributedControl_localDpName;
			if(g_unMessagetextDefined)
				unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
		}
		else if(!g_unDistributedControl_bLocalState) {
			//dpSetWait(g_unDistributedControl_localDpName+c_unDistributedControl_dpElementName, true);
			messageString = getCatStr("unDistributedControl", "LOCCONOK")+ ": "+g_unDistributedControl_localDpName;
			if(g_unMessagetextDefined)
				unMessageText_send("*", "*", g_DistributedControl_sSystemName+"DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
		}
		g_unDistributedControl_bLocalState = true;
	}

	if(!g_unDistributedControl_initialized)
		g_unDistributedControl_initialized = true;
		
//DebugTN("end _unDistributedControl_callback", g_unDistributedControl_bLocalState, g_unDistributedControl_bRemoteState);

// handle any error in case the send message failed
	if(dynlen(exceptionInfo) > 0) {
		DebugTN(g_DistributedControl_sSystemName+"DistributedControl", messageString, exceptionInfo);
	}
}

//@}

