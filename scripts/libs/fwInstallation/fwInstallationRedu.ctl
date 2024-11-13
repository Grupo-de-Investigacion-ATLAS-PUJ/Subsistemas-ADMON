/**@file
 *
 * This library contains helper functions to address redundant systems
 *
 * @author Fernando Varela Rodriguez (EN-ICE)
 * @date   August 2010
 */

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationReduLibVersion = "9.1.3";
const string csFwInstallationReduLibTag = "";

const int fwInstallationRedu_WAIT_COUNT = 10;

const int FW_INSTALLATION_REDU_EXEC_MAN_NUM = 111;
const int FW_INSTALLATION_REDU_EXEC_MAN_NUM_PEER_2 = 112;


/** Starts control script connecting to both event manager to exit the split mode.
@param pairToKeep   peer to keep alive
*/
void fwInstallationRedu_setReduSplitOff(int pairToKeep) {
  fwInstallationRedu_execScriptConnectedToBothPeers("fwInstallation/fwInstallationExitSplitMode.ctl", makeDynString(pairToKeep));
}

void fwInstallationRedu_execScriptConnectedToBothPeers(string script, dyn_string parameters) {
  dyn_string hosts = fwInstallationRedu_getDataHosts();
  if (dynlen(hosts) <2) {
    fwInstallation_throw("fwInstallationRedu_execScriptConnectedToBothPeers: Cannot run on a non redundant system");
    return;
  }

  int managerNum = FW_INSTALLATION_REDU_EXEC_MAN_NUM;
  if(fwInstallationRedu_myReduHostNum() == 2){ // if running on second peer use different manager number
    managerNum = FW_INSTALLATION_REDU_EXEC_MAN_NUM_PEER_2;
  }

  string managerDbgDp = "_CtrlDebug_CTRL_" + (string)managerNum;
  if(!dpExists(managerDbgDp)){
    dpCreate(managerDbgDp, "_CtrlDebug");
  }

  string parameterString = strjoin(parameters, " ");

  string firstPeer = hosts[1];
  string secondPeer = hosts[2];
  int dataP = dataPort();
  int eventP = eventPort();

  string cmd = PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ctrl") +
                " -data " + firstPeer + ":" + dataP + "$" + secondPeer + ":" + dataP
                + " -event "+ firstPeer + ":" + eventP + "$" + secondPeer + ":" + eventP
                + " -proj " + PROJ
                + " -num " + (string)managerNum
                + " " +script + " " + parameterString;

  DebugTN("Executing command", cmd);
  system(cmd);
}


/** Exists the split mode
@praram sSystem    PVSS system name
@param bAsk       ask user input
@param stayHost   host that survives
*/
int fwInstallationRedu_reduSetSplitOff(string sSystem, bool bAsk=true, int stayHost = 1)
{
  dyn_string dpe;
  dyn_string ds;
  dyn_bool   value;
  dyn_float dfReturn;
  dyn_string dsReturn;
  dyn_string dsDataHosts, dsDataHosts_2;
  bool bSplitMode, bSplitMode_2;
  int manId = convManIdToInt(EVENT_MAN,0);
  int manId_2 = convManIdToInt(EVENT_MAN,0,0,2);

  string h1, h2;

  time tExit, tExit_2;

  if (!getUserPermission(3))  //check user permissions
  {
    if (bAsk)
      ChildPanelOnCentral("vision/MessageWarning",getCatStr("va","headerPanelhost"),
                          makeDynString(getCatStr("general","permission"),
                                        getCatStr("general","cancel")));
    else
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 0, getCatStr("va","headerPanelhost"), getCatStr("va","headerPanelhost")));
    return -1;
  }

  dpGet( sSystem + "_ReduManager.SplitMode:_original.._value",   bSplitMode,
         sSystem + "_ReduManager_2.SplitMode:_original.._value", bSplitMode_2);

  if (!(bSplitMode || bSplitMode_2))        // not in splitmode -> cancel
     return 0;

  dpGet(sSystem + "_Connections.Data.HostNames:_online.._value",   dsDataHosts,
        sSystem + "_Connections_2.Data.HostNames:_online.._value", dsDataHosts_2);

  if (dynlen(dsDataHosts) >= 1)        h1 = dsDataHosts[1];
  if (dynlen(dsDataHosts) == 2)        h2 = dsDataHosts[2];
  else if (dynlen(dsDataHosts_2) == 1) h2 = dsDataHosts_2[1];
  else if (dynlen(dsDataHosts_2) == 2) h2 = dsDataHosts_2[2];

  dyn_int diDistMan, diDistMan_2;


  bool bEventConnection = isConnOpen(manId);
  bool bEventConnection_2 = isConnOpen(manId_2);
//  DebugN("bEventConnection" ,bEventConnection);
//  DebugN("bEventConnection_2" ,bEventConnection_2);
  if (bEventConnection && bEventConnection_2)   // both EB running
  {
    dpGet(sSystem + "_Managers.Exit:_original.._stime", tExit,
          sSystem + "_Managers_2.Exit:_original.._stime", tExit_2);

    if (tExit + 10 > getCurrentTime() || tExit_2 + 10 > getCurrentTime())
    {
      if (bAsk)
        ChildPanelOnCentral("vision/MessageWarning", getCatStr("general", "headerswitchToRedundantMode"),
                            makeDynString(getCatStr("general","notCorrectStateForSwitch"),
                                          getCatStr("general","cancel")));
      else
        throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 0, getCatStr("general", "headerswitchToRedundantMode"), getCatStr("general","notCorrectStateForSwitch")));
      return -1;
    }

    if (bAsk)
    {
      ChildPanelOnCentralModalReturn("vision/MessageInfo3",getCatStr("general", "headerswitchToRedundantMode"),
                                     makeDynString(getCatStr("general","switchToRedundantMode"),
                                                   h1, h2,
                                                   getCatStr("general","cancel")),
                                     dsReturn, dfReturn);

      if( dynlen(dsReturn)<1 || dsReturn[1]=="2")        // !OK
         return 0;
      else if (dsReturn[1]=="0")    // host2 stays active -> shutdown host 1
        stayHost = 2;
      else if (dsReturn[1]=="1")    // host1 stays active -> shutdown host 2
        stayHost = 1;
    }

    if (getCtrlManagerRunningScript(sSystem, "fileSync.ctl")>-1) // This function is defined in WinCC OA inst. dist.ctl
      fsStartSync(stayHost==1 ? 2 : 1, TRUE); // Defined in libFileSync.ctl


    bEventConnection = isConnOpen(manId);      // check ob noch immer da
    bEventConnection_2 = isConnOpen(manId_2);

    //Wenn nur zu einem verbunden
    if ((stayHost==2 && !bEventConnection_2) || (stayHost==1 && !bEventConnection))
    {
      if (bAsk)
        ChildPanelOnCentral("vision/MessageWarning", getCatStr("general", "headerswitchToRedundantMode"),
                            makeDynString(getCatStr("general","notCorrectStateForSwitch"),
                                          getCatStr("general","cancel")));
      else
        fwInstallation_throw(getCatStr("general", "headerswitchToRedundantMode") + getCatStr("general","notCorrectStateForSwitch"));
      return -1;
    }
    else
    {
      if ( ((stayHost == 1) && (myReduHostNum() == 2)) ||
           ((stayHost == 2) && (myReduHostNum() == 1)) )
      {
        fwInstallation_throw("Switch to REDUMode by "+ getUserName() + " on "+getHostname() + " "+sSystem, "INFO", 10);

        //Alle auf FALSE
        dynClear(dpe);
        dynAppend(dpe, ds = dpNames(sSystem + "*.MS:_original.._value",                     "_DriverCommon"));
        dynAppend(dpe, ds = dpNames(sSystem + "*.SplitMode:_original.._value",              "_ReduManager"));
        dynAppend(dpe, ds = dpNames(sSystem + "*.DC:_original.._value",                     "_DriverCommon"));
        dynAppend(dpe, ds = dpNames(sSystem + "*.Redundancy.ManualState:_original.._value", "_DistManager"));
        dynAppend(dpe, ds = dpNames(sSystem + "*.SplitActive:_original.._value",            "_ReduManager"));

        for (int i=1; i<=dynlen(dpe); i++)
          value[i] = FALSE;
        dpSet(dpe, value);
      }

      if (stayHost==1)       //Reduhost 1 soll laufen bleiben Reduhost 2 neu starten
      {
         //DebugTN("dpSet",sSystem + "_Managers_2.Exit:_original.._userbit1", 1); //prepare for exit
        dpSet(sSystem + "_Managers_2.Exit:_original.._userbit1", 1); //prepare for exit
        delay(0,500);
        //DebugTN("dpSet",sSystem + "_Managers_2.Exit:_original.._userbit1", 0); //prepare for exit
        dpSet(sSystem + "_Managers_2.Exit:_original.._userbit1", 0); //prepare for exit
        //DebugTN("dpSet",sSystem + "_Managers_2.Exit:_original.._value", 256);
        dpSet(sSystem + "_Managers_2.Exit:_original.._value", 256); // exit
        // Set -1 again, to avoid inifinte loop of recovery after change back from split to redumode IM106100
        //DebugTN("dpSet",sSystem + "_Managers_2.Exit:_original.._value", -1);
        dpSet(sSystem + "_Managers_2.Exit:_original.._value", -1);
        //IM 109425
//        bRestart_2[sSystem] = TRUE;
//        setAllObjectsVisible(FALSE, "_2");
      }
      else if (stayHost==2)  //Reduhost 2 soll laufen bleiben Reduhost 1 neu starten
      {
        dpSet(sSystem + "_Managers.Exit:_original.._userbit1", 1); //prepare for exit
        delay(0,500);
        dpSet(sSystem + "_Managers.Exit:_original.._userbit1", 0); //prepare for exit
        dpSet(sSystem + "_Managers.Exit:_original.._value", 256); // exit
        // Set -1 again, to avoid inifinte loop of recovery after change back from split to redumode IM106100
        dpSet(sSystem + "_Managers.Exit:_original.._value", -1);
        //IM 109425
//        bRestart[sSystem] = TRUE;
      //  setAllObjectsVisible(FALSE, "");
      }
    }
  }
  else
  {
    if (bAsk)  //Noch mal nachfragen
    {
      ChildPanelOnCentralModalReturn("vision/MessageInfo",getCatStr("general", "headerswitchToRedundantMode"),
                                     makeDynString(getCatStr("general","switchToRedundantModeSingle"),
                                                   getCatStr("general","OK"),
                                                   getCatStr("general","cancel")),
                                     dsReturn, dfReturn);

      if ( dynlen(dsReturn) < 1 || dsReturn[1] == "0" )  // !OK
        return 0;
    }

    if ( (bEventConnection_2 && (myReduHostNum() == 1)) ||
        (!bEventConnection_2 && (myReduHostNum() == 2)) )
    {
      fwInstallation_throw("Switch to REDUMode by "+ getUserName() + " on "+getHostname() + " "+sSystem, "INFO", 10);

      //Alle auf FALSE
      dynClear(dpe);
      dynAppend(dpe, ds = dpNames(sSystem + "*.MS:_original.._value",                     "_DriverCommon"));
      dynAppend(dpe, ds = dpNames(sSystem + "*.SplitMode:_original.._value",              "_ReduManager"));
      dynAppend(dpe, ds = dpNames(sSystem + "*.DC:_original.._value",                     "_DriverCommon"));
      dynAppend(dpe, ds = dpNames(sSystem + "*.Redundancy.ManualState:_original.._value", "_DistManager"));
      dynAppend(dpe, ds = dpNames(sSystem + "*.SplitActive:_original.._value",            "_ReduManager"));

      for (int i=1; i<=dynlen(dpe); i++)
        value[i] = FALSE;
      dpSet(dpe, value);
    }

    if (bEventConnection_2)    // host2 is active -> shutdown host 1
      {
        dpSet(sSystem + "_Managers.Exit:_original.._value", 256); // exit
        // Set -1 again, to avoid inifinte loop of recovery after change back from split to redumode IM106100
        dpSet(sSystem + "_Managers.Exit:_original.._value", -1);
      }
    else
      {
        dpSet(sSystem + "_Managers_2.Exit:_original.._value", 256); // exit
        // Set -1 again, to avoid inifinte loop of recovery after change back from split to redumode IM106100
        dpSet(sSystem + "_Managers_2.Exit:_original.._value", -1);
      }
  }

  int manIdLeft = convManIdToInt(EVENT_MAN,0, getSystemId(), 1);
  int manIdRight = convManIdToInt(EVENT_MAN,0, getSystemId(), 2);
  int i = 0;

  while (i<200) //wait max. 2 Seconds
  {
    delay(0,10);
    if ( !isConnOpen(manIdLeft) || !isConnOpen(manIdRight) )
    {
      break;
    }
    i++;
  }

  fwInstallation_throw("Switch to REDUMode by "+ getUserName() + " on "+getHostname() + " "+sSystem, "INFO", 10);

  //Alle auf FALSE
  dynClear(dpe);
  dynAppend(dpe, ds = dpNames(sSystem + "*.MS:_original.._value",                     "_DriverCommon"));
  dynAppend(dpe, ds = dpNames(sSystem + "*.SplitMode:_original.._value",              "_ReduManager"));
  dynAppend(dpe, ds = dpNames(sSystem + "*.DC:_original.._value",                     "_DriverCommon"));
  dynAppend(dpe, ds = dpNames(sSystem + "*.Redundancy.ManualState:_original.._value", "_DistManager"));
  dynAppend(dpe, ds = dpNames(sSystem + "*.SplitActive:_original.._value",            "_ReduManager"));

  for (i=1; i<=dynlen(dpe); i++)
    value[i] = FALSE;
  dpSet(dpe, value);

  return 1;
}

/**This method resolves the list of components missing in the local peer w.r.t the remote one a
*/
int fwInstallationRedu_checkComponents(bool &isOk, dyn_dyn_mixed &componentsToBeInstalled, dyn_dyn_mixed &componentsToBeRemoved)
{
  dyn_dyn_mixed componentsInfo, reduPartnerComponentsInfo;

  isOk = false;

  fwInstallation_getInstalledComponents(componentsInfo, fwInstallationRedu_myReduHostNum());
  fwInstallation_getInstalledComponents(reduPartnerComponentsInfo, fwInstallationRedu_myReduHostNum()==1?2:1);

  //find out components to be installed:
  int k = 1;
  for(int i = 1; i <= dynlen(reduPartnerComponentsInfo); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(componentsInfo); j++)
    {
      if(reduPartnerComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == componentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         reduPartnerComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == componentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        found = true;
        break;
      }
    }
    if(!found)
    {
      componentsToBeInstalled[k] = reduPartnerComponentsInfo[i];
      ++k;
    }
  }

  //find components to be removed:
  k = 1;
  for(int i = 1; i <= dynlen(componentsInfo); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(reduPartnerComponentsInfo); j++)
    {
      if(reduPartnerComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         reduPartnerComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        found = true;
        break;
      }
    }
    if(!found)
    {
      componentsToBeRemoved[k] = componentsInfo[i];
      ++k;
    }
  }

  if(dynlen(componentsToBeInstalled) == 0 &&
     dynlen(componentsToBeRemoved) == 0) isOk = true; //list of components in both partners is consistent

  return 0; //error code to be implemented later.
}

/**This function forces the sync of component in the local system, i.e. it removes from the local system
   components that are not installed in the remote redu peer and installs the ones that are missing in the
   local peer but already installed in the remote one
*/

int fwInstallationRedu_synchronize(bool deleteFiles = false,
                                   string &dontRestartProject,
                                   dyn_string descFilesInstallComponents = makeDynString())
{
  bool isOk = false;
  bool isSubComponent = false;
  string sourceDir = "";
  int err = 0;

  dyn_dyn_mixed componentsToBeInstalled;
  dyn_dyn_mixed componentsToBeRemoved;
  dyn_string componentFiles;
  dyn_string componentNamesToBeRemoved;

  dontRestartProject = "no";
  fwInstallationRedu_checkComponents(isOk, componentsToBeInstalled, componentsToBeRemoved);


  if(isOk) return 0;

  //work to be done. Reset installation log now...
  fwInstallation_resetLog();
  fwInstallationManager_stopManagersForInstallation();
//  fwInstallation_backupProjectConfigFile();

  //Install components first
  if(dynlen(descFilesInstallComponents))
  {
DebugN("fwInstallationRedu_synchronize called forcing desc files of the components to be intalled: ",descFilesInstallComponents);
    componentFiles = descFilesInstallComponents;
  }
  else
  {
    for(int i = 1; i <= dynlen(componentsToBeInstalled); i++)
    {
      //check that the component XML file can be accessed:
  DebugN("before checking access to xml files. components to be installed: ", componentsToBeInstalled[i]);

      if(access(componentsToBeInstalled[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX], R_OK))
      {
        fwInstallation_throw("Cannot install component as the XML file is not readable: " + componentsToBeInstalled[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX] + ". This component will be skipped", "WARNING");
        ++err;
        continue;
      }
      else
      {
        DebugN("appending", componentsToBeInstalled[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX]);
        dynAppend(componentFiles, componentsToBeInstalled[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX]);
      }
    }
  }

  DebugN("Now installing the following components", componentFiles);
  if(dynlen(componentFiles)>0)
  {
    if(fwInstallation_installComponentSet(componentFiles, dontRestartProject) != 0)
    {
      return -1;
    }
  }


  //Remove components:
  for(int i =1; i <= dynlen(componentsToBeRemoved); i++)
  {
    dynAppend(componentNamesToBeRemoved, componentsToBeRemoved[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX]);
  }

  DebugN("now removing", componentNamesToBeRemoved);
  if(dynlen(componentNamesToBeRemoved))
    fwInstallation_deleteComponentSet(componentNamesToBeRemoved, deleteFiles);

  //update db if required
  if(fwInstallationDB_getUseDB()) fwInstallationDB_update();

  return 0;
}

/** This functions appends the suffix '_'+ myRedHostNum() to the dp passed as input argument
@param dp: name of the dp
@return dp if redu system is number 1, dp + "_" + myReduHostNumber() if redu number is greater than 1
@author F. Varela
*/
string fwInstallationRedu_getLocalDp(string dp)
{
  int reduHostNum = fwInstallationRedu_myReduHostNum();
  if(reduHostNum > 1)
    dp = dp + "_" + reduHostNum;

  return dp;
}


/** This functions appends the suffix '_'+ reduHostNum to the dp passed as input argument
@param dp: name of the dp
@param systemName: when it is different that the local system and no reduHostNum is provided, if the remote system is redundant the active system's redu num is used
@param reduHostNum: redu number; when 0 and systemName is the local system, the local redu number is used
@return dp if redu system is number 1, dp + "_" + reduHostNum if redu number is greater than 1
*/
string fwInstallationRedu_getReduDp(string dp, string systemName = "", int reduHostNum = 0)
{
  if(systemName == "")
  {
    systemName = getSystemName();
  }
  if (systemName != getSystemName() && reduHostNum == 0)
  {
    bool isSystemRedundant;
    isRemoteSystemRedundant(isSystemRedundant, systemName);
    if (isSystemRedundant)
    {
      reduActive(reduHostNum, systemName);
    }
    else reduHostNum = 1;
  }

  if (reduHostNum == 0)
    reduHostNum = fwInstallationRedu_getActivePeer();
  if(reduHostNum > 1)
    dp = dp + "_" + reduHostNum;

  return dp;
}

/** Wrapper function for the standard PVSS function dpTypeCreate to work in redundant systems.
@param elements: dp-type elements
@param types: dp-type element types
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpTypeChange(dyn_dyn_string elements, dyn_dyn_int types)
{
  if(fwInstallationRedu_isPassive())
    return 0;

  return dpTypeChange(elements, types);
}


/** Wrapper function for the standard PVSS function dpTypeCreate to work in redundant systems.
@param elements: dp-type elements
@param types: dp-type element types
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpTypeCreate(dyn_dyn_string elements, dyn_dyn_int types)
{
  if(fwInstallationRedu_isPassive())
    return 0;

  return dpTypeCreate(elements, types);
}

/** Wrapper function for the standard PVSS function dpCreate to work in redundant systems.
@param dpname: name of the dp to be deleted
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpDelete(string dpname)
{
  if(fwInstallationRedu_isPassive())
    return 0;

  return dpDelete(dpname);
}
/** Wrapper function for the standard PVSS function dpCreate to work in redundant systems.
@param dpname name of the dp to be created
@param dptype dp-type of the new dp
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpCreate(string dpname, string dptype)
{
  if(fwInstallationRedu_isPassive())
    return 0;

  return dpCreate(dpname, dptype);
}

/** Wrapper function for the standard PVSS function dpSet to work in redundant systems.
@param dpname: name of the dp to be set
@param val: value to be set
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpSet(string dpname, anytype val)
{
  if(fwInstallationRedu_isPassive())
    return 0;

  return dpSet(dpname, val);
}

/** This functions checks whether the local system is the passive peer in a redundant system or not.
@return FALSE - local system is not the passive peer, TRUE the local system is the passive peer
@author F. Varela
*/
int fwInstallationRedu_isPassive()
{
  bool isPassive = true;
  int active, local;

  if(!fwInstallationRedu_isRedundant()) //if it is not a redundant system, it will always be the active one.
    return false;

  local = fwInstallationRedu_myReduHostNum();

  reduActive(active, getSystemName());
  //DebugN(local, active, local > 0, active > 0, local != active, local > 0 && active > 0 && local != active);
  if(local > 0 && active > 0 && local == active)
    isPassive = false;

  //DebugN("returning: ", isPassive);
  return isPassive;
}
/** This functions returns the names of the hosts of a redundant project
@author F. Varela
*/
dyn_string fwInstallationRedu_getDataHosts() {
    dyn_string hosts = dataHost();

  for(int i = 1; i <= dynlen(hosts); i++) //get rid of network domain
  {
    if(strpos(hosts[i], ".") > 0)
      hosts[i] = substr(hosts[i], 0, strpos(hosts[i], "."));

    if(strtoupper(hosts[i]) == "LOCALHOST") //make sure localhost is replace with a proper host name
      hosts[i] = strtoupper(fwInstallation_getHostname());
    hosts[i] = strtoupper(hosts[i]);
  }
  return hosts;
}
/** This functions returns the name of the host where the redundant pair runs
@return name of the redundant pair
@author F. Varela
*/
string fwInstallationRedu_getPair()
{

  dyn_string hosts = fwInstallationRedu_getDataHosts();


  if(fwInstallationRedu_isRedundant() && strtoupper(hosts[1]) == strtoupper(fwInstallation_getHostname())) //redu system
    return strtoupper(hosts[2]);

  return strtoupper(hosts[1]);//return the name of the local host in any other case.
}

/** This functions checks if a particular version of a component is installed in the redundant pair
@param component (in) name of the component
@param version (in) version of the component
@return True if the component is installed in the pair. Otherwise, false
@author F. Varela
*/
bool fwInstallationRedu_isComponentInstalledInPair(string component, string version)
{
  string dp, ver;
  int nok;

  if(fwInstallationRedu_myReduHostNum() == 1)
    dp = "fwInstallation_" + component + "_" + 2;
  else
    dp =  "fwInstallation_" + component;

  if(dpExists(dp))
  {
    dpGet(dp + ".componentVersionString", ver,
          dp + ".installationNotOK", nok);

    if(version == ver && !nok)
      return true;
  }

  return false;
}

/** Returns information whether the current project is redundant.
  * User can parametrize return value of this function by creating fwReduInfo DP,
  * that has a priority if available and valid, otherwise a config file is read to check
  * whether project is redundant.
  * @note If user creates fwReduInfo DP it becomes responsible of the correctness of information supplied there.
  *       Search for FW_INSTALLATION_REDU_INFO_DP for additional information.
  * @return TRUE if project is redundant, FALSE otherwise
*/
bool fwInstallationRedu_isRedundant()
{
  bool isRedu = false;
  if(_fwInstallationRedu_getIsRedundantReduInfo(isRedu))
  {
    return isRedu;
  }

  string event = _fwInstallationRedu_getEventFromCfg();
  if (event != "")
  {
    return (strpos(event, FW_INSTALLATION_CONFIG_REDU_SYS_DELIMITER) > 0);
  }
  return isRedundant();
}


/** \private
  * If fwReduInfo DP is present and accessible in the given system then sets isRedu parameter according
  * to a value retrieved from isRedundant DPE (if valid) that allows user to mark system as redundant.
  * Search for FW_INSTALLATION_REDU_INFO_DP for more details.
  * @param isRedu (out)  Output argument indicating if project is marked as redundant in fwReduInfo DP.
  * @param sysName (in)  System to check (default - current system)
  * @return TRUE if information retrieved from fwReduInfo DP and isRedu contains valid information,
  *         FALSE otherwise (fwReduInfo DP not present or read attempt failed or DPE invalid)
  */
private bool _fwInstallationRedu_getIsRedundantReduInfo(bool &isRedu, string sysName = getSystemName())
{
  bool isRedundantReduInfo, isDpeInvalid = true;
  string dpe = sysName + FW_INSTALLATION_REDU_INFO_IS_REDUNDANT_DPE;
  if(dpExists(dpe) &&
     dpGet(dpe, isRedundantReduInfo, dpe + ":_original.._invalid", isDpeInvalid) == 0 &&
     dynlen(getLastError()) == 0 &&
     !isDpeInvalid){
    isRedu = isRedundantReduInfo;
    return true;
  }
  return false;
}


/** Name of user-supplied DP that parametrizes the result of checking if system is redundant.
  * If user creates fwReduInfo DP in a system and sets the isRedundant DPE, then fwInstallationRedu
  * functions that checks whether project is redundant will return result as given in isRedundant DPE
  * without performing any additional validations.
  * This affects: fwInstallationRedu_isRedundant() and fwInstallationRedu_isSystemRedundant()
  *
  * Purpose: Verification whether project is redundant or not may be impossible in certain states and
  * and configurations - for example in remote system when redu manager is stopped there or when running
  * a scattered manager where redu connection parameters are supplied in the command argument and not in the config.
  * User can use fwReduInfo DP to pernamently mark system as redundant so that fwInstallationRedu functions
  * will always return the same result, regardless of project state and manager configuration.
  *
  * IMPORTANT: Once fwReduInfo DP is created by user, it becomes its responsibility to ensure correctness of
  * information supplied in that DP!
  *
  * To create fwReduInfo DP:
  * 1) Create DPT FwReduInfo containing one boolean DPE: isRedundant
  *    FwReduInfo [DPEL_STRUCT]
  *    |--- isRedundant [DPEL_BOOL]
  * 2) Create datapoint fwReduInfo
  * 3) Set isRedundant DPE to desired value (TRUE if redundant system, FALSE if non-redu)
  */
const string FW_INSTALLATION_REDU_INFO_DP = "fwReduInfo";
const string FW_INSTALLATION_REDU_INFO_IS_REDUNDANT_DPE = FW_INSTALLATION_REDU_INFO_DP + ".isRedundant";


/** This function returns the peer number where the Event Manager is running,
  * to which my manager has an open and active connection.
  * @return peer number of redu system, in non-redu system always 1;
  *         1 if peer number cannot be determined + reason printed to the log
  */
int fwInstallationRedu_myReduHostNum()
{
  if (!fwInstallationRedu_isRedundant()){
    return 1; // Not a redu system
  }
  int eventManIdP1 = convManIdToInt(EVENT_MAN, 0, 0, 1);
  int eventManIdP2 = convManIdToInt(EVENT_MAN, 0, 0, 2);

  bool connActiveToP1 = isConnActive(eventManIdP1);
  bool connActiveToP2 = isConnActive(eventManIdP2);
  bool connOpenToP1 = isConnOpen(eventManIdP1);
  bool connOpenToP2 = isConnOpen(eventManIdP2);

  // determine peer based on EM to which the connection is active
  if(!connActiveToP1 && !connActiveToP2){
    fwInstallation_throw("No active connection to any Event Manager. Cannot determine " +
                         "redu host number. Defaults to 1", "WARNING");
    return 1;
  }
  if(!connActiveToP2){ return 1; }
  if(!connActiveToP1){ return 2; }

  // code below is executed when probing results show an active connection
  // to both EMs. It is incorrect and usually means an transient state.
  // If that's the case, determine peer based on connection to EM
  if(!connOpenToP1 && !connOpenToP2){
    fwInstallation_throw("Connections to both Event Managers appear as active, but no " +
                         "one is opened. Cannot determine redu host number. " +
                         "Defaults to 1", "WARNING");
    return 1;
  }
  if(!connOpenToP2){ return 1; }
  if(!connOpenToP1){ return 2; }

  fwInstallation_throw("Opened connections to both Event Managers and both appear as " +
                       "active. Cannot determine redu host number. Defaults to 1", "WARNING");
  return 1;
}

/** This function checks if hostname resolved from given network alias matches the given hostname.
  * Note: According to the help of getHostByAddr() function it may introduce a delay until host will be dermined from alias.
  * @param alias (in)  Network alias
  * @param hostName (in)  Host name
  * @return true if alias points to given hostname, false if not
  */
private bool fwInstallationRedu_matchAliasWithHostName(string alias, string hostName)
{
  dyn_string addressList;
  string hostNameFromAlias = getHostByAddr(getHostByName(alias, addressList));
  return (strtoupper(fwInstallation_getHostname(hostNameFromAlias)) == strtoupper(fwInstallation_getHostname(hostName)));
}

/** This functions returns the event host name from the config file
@return hostname of the event manager from the config file
*/
string _fwInstallationRedu_getEventFromCfg()
{
  string eventHostName;
  paCfgReadValue(PROJ_PATH + "/config/config", "general", "event", eventHostName);
  return eventHostName;
}

int fwInstallationRedu_myPairReduHostNum(int reduHostNum = 0)
{
  if (reduHostNum == 0)
    reduHostNum = fwInstallationRedu_myReduHostNum();
  if (reduHostNum == 1)
    return 2;
  else return 1;
}

/** This functions returns whether split mode is enabled for a redundant project
@return true if the project is in split mode
*/
bool fwInstallationRedu_isSplitMode()
{
  bool splitMode = false;

  string reduManagerDp = fwInstallationRedu_getReduManagerDp();
  dpGet(reduManagerDp + ".SplitMode", splitMode);

  return splitMode;
}

/** This functions returns whether this is the split active pair
@return true if this is the split active pair
*/
bool fwInstallationRedu_isSplitActive()
{
  bool splitActive = false;
  bool eventActive = false;
  string reduManagerDp = fwInstallationRedu_getReduManagerDp();
  dpGet(reduManagerDp + ".SplitActive", splitActive,
        reduManagerDp + ".Status.Active", eventActive);

  return splitActive && eventActive;
}

string fwInstallationRedu_getReduManagerDp()
{
  string reduManagerDp = "_ReduManager";
  int hostNum = fwInstallationRedu_myReduHostNum();
  if (hostNum > 1)
  {
    reduManagerDp += "_" + hostNum;
  }
  return  reduManagerDp;
}

bool fwInstallatinRedu_isConnectedToEventManager(int replicaNum)
{
  if (replicaNum != 1 && replicaNum != 2)
  {
    fwInstallation_throw("fwInstallatinRedu_isConnectedToEventManager should be called with parameter equal to 1 or 2!");

  }
  int manID;
  if (replicaNum == 1)
  {
    manID = convManIdToInt(EVENT_MAN, 0); /* Integer corresponding to the manager identifier. See convManIdToInt() */
  }
  else
  {
    manID = convManIdToInt(EVENT_MAN,0,0,2); /*ManagerIdentifier with replica 2*/
  }
  bool connOpened = isConnOpen(manID);

  return connOpened;
}

bool fwInstallationRedu_ensureInstallationConditions()
{
  //return false;
  bool readyToInstall = false;
  int cnt = 0;
  if (fwInstallationRedu_isRedundant() && (fwInstallation_getInstallOnlyInSplit() == 1))
  {
    fwInstallation_throw("This is redundant project and we should install only in split", "INFO");
    if (fwInstallationRedu_isSplitMode())
    {
      readyToInstall = !fwInstallationRedu_isSplitActive() && ! fwInstallationRedu_isRecovering();
    }
    else
    {

      string project = PROJ;
      string hostname = fwInstallationRedu_getPair();
      hostname = strtoupper(hostname);
      dyn_mixed projectProperties;
      int project_id;
      fwInstallationDB_getProjectProperties(project, hostname, projectProperties, project_id);
      // if we are the passive system, or we are active but everything is already done in partner
      if (fwInstallationRedu_isPassive() || (project_id > 0 && projectProperties[FW_INSTALLATION_DB_PROJECT_DIST_PEERS_OK] == 1 &&
          projectProperties[FW_INSTALLATION_DB_PROJECT_PATH_OK] == 1 &&  projectProperties[FW_INSTALLATION_DB_PROJECT_COMPONENT_OK] == 1 && projectProperties[FW_INSTALLATION_DB_PROJECT_NEED_SYNCHRONIZE] == 'N'))
      {
        if (fwInstallationRedu_isRecovering()) {
          readyToInstall = false;
       } else {
          fwInstallation_throw("Is this the passive pair - " + fwInstallationRedu_isPassive(), "INFO");
          fwInstallation_throw("Is everything installed in partner? - " + project_id +  " " +
                 projectProperties[FW_INSTALLATION_DB_PROJECT_DIST_PEERS_OK] +  " " +
                 projectProperties[FW_INSTALLATION_DB_PROJECT_PATH_OK] +  " " +
                 projectProperties[FW_INSTALLATION_DB_PROJECT_COMPONENT_OK] + " " +
                 projectProperties[FW_INSTALLATION_DB_PROJECT_NEED_SYNCHRONIZE], "INFO");

          int myPartnerNum = fwInstallationRedu_myPairReduHostNum();
          if (!fwInstallationRedu_isPassive())
          {
            fwInstallation_throw("Setting partner as active..", "INFO");
            reduSetActive(getSystemName(), myPartnerNum, false);
            cnt = 1;
            while(cnt <= fwInstallationRedu_WAIT_COUNT && !fwInstallationRedu_isPassive())
            {
              delay(1);
              cnt++;
            }
            if (!fwInstallationRedu_isPassive())
            {
              fwInstallation_throw("fwInstallationRedu_ensureInstallationConditions: Cannot make partner active.", "ERROR");
              return false;
            }
          } // now partner is active

          //set split mode
          fwInstallation_throw("Setting split mode...", "INFO");
          if(VERSION_DISP == "3.14")
          {
            // For 3.14 there's an extra parameter which should be a shape name,
            // just pass anything (empty string), for second argument (false) this
            // should be ignored. FWINS-1998 might have more info.
            reduSetSplitOn(getSystemName(), false, "");
          }
          else
          {
            reduSetSplitOn(getSystemName(), false);
          }
          cnt = 1;
          while(cnt <= fwInstallationRedu_WAIT_COUNT && !fwInstallationRedu_isSplitMode())
          {
            delay(1);
            cnt++;
          }
          if (!fwInstallationRedu_isSplitMode())
          {
            fwInstallation_throw("fwInstallationRedu_ensureInstallationConditions: Cannot set split mode.", "ERROR");
            return false;
          }
          fwInstallation_throw("Project is in split mode now and the agent is ready to install", "INFO");
          delay(5);
          gFwInstallationDBAgentSetSplit = true;
          _fwInstallationRedu_setSplitInfo(true, fwInstallationRedu_myReduHostNum());
          //split mode is set and we are the passive system -> ready to install
          readyToInstall = true;
          }
        }
      else //not installed in partner and we are passive -> do nothing
      {
        fwInstallation_throw("This is not the passive pair and it is still not installed in the partner: " + project_id + " " +
               projectProperties[FW_INSTALLATION_DB_PROJECT_DIST_PEERS_OK] + " " +
               projectProperties[FW_INSTALLATION_DB_PROJECT_PATH_OK] + " " +
               projectProperties[FW_INSTALLATION_DB_PROJECT_COMPONENT_OK], "INFO");
        readyToInstall = false;
      }
    }
  }
  else
  {
    readyToInstall = !fwInstallationRedu_isPassive();
  }
  return readyToInstall;

}

void _fwInstallationRedu_setSplitInfo(bool splitForced, string pairToKeep)
{
  string dp = fwInstallation_getAgentDp();
  dpSetWait(dp + ".redundancy.splitModeForced", splitForced,
        dp + ".redundancy.pairToKeepAfterSplit", pairToKeep);
}

void _fwInstallationRedu_getSplitInfo(bool& splitForced, string& pairToKeep)
{
  string dp = fwInstallation_getAgentDp();
  dpGet(dp + ".redundancy.splitModeForced", splitForced,
        dp + ".redundancy.pairToKeepAfterSplit", pairToKeep);
}

bool fwInstallationRedu_isRecovering() {
  string dp = fwInstallationRedu_getReduManagerDp();
  string fn = getPath(DATA_REL_PATH) + "/fwInstallationDpGetResult" + period(getCurrentTime()) + ".txt";
  fwInstallationRedu_execScriptConnectedToBothPeers("fwInstallation/fwInstallationGetDpe.ctl",makeDynString(dp + ".IsRecovering", fn));
  delay(0,10);
  string result;
  fileToString(fn,result);
  int status = (int) result;

  fwInstallation_throw("Checking is Recovering (" + dp + ") status = " + status , "INFO");

  remove(fn);
  return (status != 0);
}

// ***********************************************************************
// Code contributed by CMS team (function names adopted, code reformatted)

global bool fwInstallationRedu_debugActive = false;

const string fwInstallationRedu_peer1ActiveDpe = "_ReduManager.EvStatus:_online.._value";

/*
  * Returns the right dp in case there is dp and dp_2
  * @param dp - must be the dp name only (with or without system name, but excluding dp elements, configs or attributes)
  * @param which can be
  *   - 1 or 2 to specify which data point
  *   - my or peer to specify if you want the local or the remote dp
  *   - active or passive to specify if you want to get the dp from the system that is currently active (passive)
  *   - "" (default) defaults to my for the ctrl scripts and UIs connected to one system and to active for the UIs and ctrl script conntected to both systems
  * @param fallBackToOne
  *   - If true, when a peer two DP is required and does not exist, then return the peer one DP
  *   - If false (default), then the peer two DP name will be returned as required even if it does not exist
  */
string fwInstallationRedu_resolveDp(string dp, string which = "", bool fallBackToOne = false)
{
  string sys;

  sys = substr(dp, 0, strpos(dp, ":") + 1);
  dp = substr(dp, strpos(dp, ":") + 1);

  int num = fwInstallationRedu_resolvePeer(sys, which);
  string resDp = sys + dp;

  if(num == 2)
  {
    string newDp = resDp + "_2";
    if(fallBackToOne)
    {
      //if specified to fall back to peer one, only append the _2 if the DP exists
      if(dpExists(newDp))
        resDp = newDp;
    }
    else
      resDp = newDp;
  }

  fwInstallationRedu_debug("[fwInstallationRedu_resolveDp] Returning " + resDp);

  return resDp;
}

int fwInstallationRedu_resolvePeer(string sys, string which = "")
{
  int conn = -100; // not initialized
  fwInstallationRedu_debug("[fwInstallationRedu_resolvePeer] Called with sys = " + sys + " which = " + which , false, true);

  if (which == "")
  {
    which = fwInstallationRedu_getDefaultWhich(sys, conn);
    fwInstallationRedu_debug("[fwInstallationRedu_resolvePeer] Got default which = " + which);
  }

  if ((sys != "") && (sys != getSystemName()))
  {
    //Makes no sense to ask for my and peer for a non local dp
    if (which == "my")
    {
      DebugTN("[fwInstallationRedu_resolvePeer] Cannot use 'my' for a non local dp. Assuming active");
      which = "active";
    }
    else if (which == "peer")
    {
      DebugTN("[fwInstallationRedu_resolvePeer] Cannot use 'peer' for a non local dp. Assuming passive");
      which = "passive";
    }
  }

  if ((which== "my") || (which == "peer"))
  {
    conn = fwInstallationRedu_getEventConnection();
    if (conn == 0) // not redundantant
    {
      if (which == "my")
        which = "1";
      else if (which == "peer")
      {
        DebugTN("[fwInstallationRedu_resolvePeer] ERROR It makes no sense to query the peer in a non redundant system");
        which = "1";
      }
    }
    else if (conn == 3) // connected to both
    {
      if (which == "my")
        which = "active";
      else if (which == "peer")
        which = "passive";
    }
    else if ((conn == 1) || (conn == 2)) // connected just to one of the system
    {
      if (which == "my")
        which = "" + conn;
      else if (which == "peer")
        which = "" + ((conn==1) ? 2 : 1);
    }
  }

  fwInstallationRedu_debug("[fwInstallationRedu_resolvePeer] Finally which = " + which);

  int num;
  if ((which == "active") || (which == "passive"))
  {
    int active = fwInstallationRedu_getActivePeer(sys, conn);
    if (which == "active")
      num = active;
    else
      num = (active==1) ? 2 : 1;
  }
  else
  {
    num = (int) which;
  }

  return num;
}

string fwInstallationRedu_getHostnameNormalized(string host)
{
  int pos = strpos(host, ":");

  if (pos > 0)
    host = substr(host, 0, pos);

  host = fwInstallation_getHostname(host);

  return host;
}

int fwInstallationRedu_getActivePeer(string systemName = "", int conn=-100)
{
  int isRemSysRedundant;
  if (conn<0) // not initialized
  {
    isRemSysRedundant = fwInstallationRedu_isSystemRedundant(systemName); //won't report properly if REDU MANAGER is stopped till ENS-25859 is not solved
  }
  else
  {
    if (conn == 0)
      isRemSysRedundant = 0;
    else
      isRemSysRedundant = 1;
  }

  if (isRemSysRedundant == 0) {
    return 1;
  }

  const string reduMan1statusActiveDpe = systemName + "_ReduManager.Status.Active";
  const string reduMan2statusActiveDpe = systemName + "_ReduManager_2.Status.Active";

  bool active1, active2;
  int rc = dpGet( reduMan1statusActiveDpe, active1,
                  reduMan2statusActiveDpe, active2);
  if (dynlen(getLastError())>0) rc=-1;
  if (rc!=0) {
    DebugTN("[fwInstallationRedu_getActivePeer]: Warning: could not retrieve " + systemName + "_ReduManager(_2).Status.Active. " +
            "If checking remote system, it might not be connected. Returning 1.");
    return 1;
  }

  if (active1 && (!active2))
    return 1;
  if (active2 && (!active1))
    return 2;

  time time1,time2;
  dpGet( reduMan1statusActiveDpe + ":_original.._stime", time1,
         reduMan2statusActiveDpe + ":_original.._stime", time2);

  DebugTN("[fwInstallationRedu_getActivePeer] Warning: non consistent state of " +
          reduMan1statusActiveDpe + " (" + active1 + ") and " + reduMan2statusActiveDpe + " (" + active2 + "). " +
          "Using timestamps time1 (" + (string)time1 + ") and time2 (" + (string)time2 + ")");

  if (active1)
    return (period(time1)-period(time2)>0)?1:2;
  else
    return (period(time1)-period(time2)>0)?2:1;
}

string fwInstallationRedu_getDefaultWhich(string sys, int& conn)
{
  if ((sys == "") || (sys == getSystemName()))
  {
    conn = fwInstallationRedu_getEventConnection();
    if (conn == 0)
      return "1"; // non redundant
    if (conn == 3)
      return  "active";
    if (conn == 1)
      return "1";
    if (conn == 2)
      return "2";

    return "1";    // shouldn't happen
  }

  return "active";
}


bool fwInstallationRedu_isConnectedToBoth()
{
   return (fwInstallationRedu_getEventConnection() == 3);
}

/** Returns information whether the given system is redundant.
  * User can parametrize return value of this function by creating fwReduInfo DP in target system,
  * that (if available and valid) has a priority, otherwise a check is performed to determine if system is redu or not.
  * @note If user creates fwReduInfo DP it becomes responsible of the correctness of information supplied there.
  *       Search for FW_INSTALLATION_REDU_INFO_DP for additional information.
  * @return 1 if system is redundant, 0 if not, -1 in case remote system is not available
*/
int fwInstallationRedu_isSystemRedundant(string sysName = "")
{
  if(sysName == "")
  {
    sysName = getSystemName();
  }
  sysName = strrtrim(sysName, ":") + ":";

  // local system
  if(sysName == getSystemName())
  {
    return (int)fwInstallationRedu_isRedundant();
  }

  // remote system
  fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant]  Checking if remote system " + sysName + " is Redundant");

  fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] Getting systemnames ");
  dyn_string dsSystemNames;
  dyn_uint diSystemIds;
  getSystemNames(dsSystemNames, diSystemIds );
  fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] Got  " + dynlen(dsSystemNames) + " system names");

  if (dynContains(dsSystemNames, strrtrim(sysName, ":") )==0)
  {
    fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] Remote System " + sysName + " not conected - return -1");
    return -1;
  }

  bool isRedu = false;
  if(_fwInstallationRedu_getIsRedundantReduInfo(isRedu, sysName))
  {
    fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] Redundancy info retrieved from fwReduInfo DP, returning answer");
    return isRedu?1:0;
  }

  // logic based on isRemoteSystemRedundant
  dyn_int diRemote1, diRemote2 ;
  int res = dpGet(sysName + "_Connections.Redu.ManNums:_online.._value",   diRemote1,
                  sysName + "_Connections_2.Redu.ManNums:_online.._value", diRemote2);

  dyn_errClass derr = getLastError();
  if ((dynlen(derr)>=1) || (res == -1))
  {
    fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] System " + sysName + " cannot be contacted" );
    return -1; // System can not be contacted
  }
  if (dynlen(diRemote1) > 0 || dynlen(diRemote2) > 0)
  {
    fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] System " + sysName + " is redundant" );
    return 1; // System is redundant
  }
  fwInstallationRedu_debug("[fwInstallationRedu_isSystemRedundant] System " + sysName + " is NOT redundant" );
  return 0;
}

/*
  Returns 1 or 2 if it is connected only to event 1 or 2
  Returns 3 if it is connected to both
  Returns 0 if not redundant
  Returns -1 if not connected to anything (impossible i guess)
*/
int fwInstallationRedu_getEventConnection()
{
  if (fwInstallationRedu_isSystemRedundant() == 0)
    return 0;

  int manId = convManIdToInt(EVENT_MAN,0);
  int manId_2 = convManIdToInt(EVENT_MAN,0,0,2);

  bool bEventConnection = isConnOpen(manId);
  bool bEventConnection_2 = isConnOpen(manId_2);
  fwInstallationRedu_debug("[fwInstallationRedu_getEventConnection] bEventConnection=" + bEventConnection + " bEventConnection_2=" + bEventConnection_2);

  if (bEventConnection && bEventConnection_2)
    return 3;
  if (bEventConnection)
    return 1;
  if (bEventConnection_2)
    return 2;

  return -1;
}

int fwInstallationRedu_dpGet(dyn_string dpe, mixed& value, string which = "", bool fallBackToOne = true)
{
  string sys; dyn_string exc, dpeList;

  for(int i=1; i<=dynlen(dpe); i++)
  {
    sys = dpSubStr(dpe[i], DPSUB_SYS);
    string dp = dpSubStr(dpe[i], DPSUB_DP);
    dpe[i] = dpSubStr(dpe[i], DPSUB_DP_EL_CONF_DET_ATT);
    string element = substr(dpe[i], strlen(dp));

    dp = fwInstallationRedu_resolveDp(sys + dp, which, fallBackToOne);
    dynAppend(dpeList, dp + element);
    fwInstallationRedu_debug("Getting " + dp + element);
  }

  int res;
  if(dynlen(dpeList) == 1)
    res = dpGet(dpeList[1], value);
  else
  {
    dyn_anytype dynValue;
    res = dpGet(dpeList, dynValue);
    value = dynValue;
  }
  return res;
}

/* IMPORTANT: If calling this function from a panel, the work callback function must be located in the ScopeLib */
int fwInstallationRedu_dpConnect(string work, bool answer, dyn_string dplist, string which="")
{
  return fwInstallationRedu_dpConnectUserData(work, makeDynAnytype(), answer, dplist, which);
}

/* IMPORTANT: If calling this function from a panel, the work callback function must be located in the ScopeLib */
int fwInstallationRedu_dpConnectAnswer(string work, dyn_string dplist, string which="")
{
  return fwInstallationRedu_dpConnectUserData(work, makeDynAnytype(), true, dplist, which);
}

/* IMPORTANT: If calling this function from a panel, the work callback function must be located in the ScopeLib */
int fwInstallationRedu_dpConnectAnswerUserData(string work, anytype userData, dyn_string dplist, string which="")
{
  return fwInstallationRedu_dpConnectUserData(work, userData, true, dplist, which);
}

bool fwInstallationRedu_prepareDpConnectionList(dyn_string dplist, string which, dyn_string &reduDplist, mapping &dataIndexes)
{
  reduDplist = makeDynString();
  mapping dataLocations;
  string sys;

  for(int i=1; i<=dynlen(dplist); i++)
  {
    //extract all the basic DPE information
    sys            = dpSubStr(dplist[i], DPSUB_SYS);
    string dp      = dpSubStr(dplist[i], DPSUB_DP);
    dplist[i]      = dpSubStr(dplist[i], DPSUB_DP_EL_CONF_DET_ATT);
    if(dplist[i] == dpSubStr(dplist[i], DPSUB_DP_EL))
      dplist[i] += ":_online.._value";
    string element = substr(dplist[i], strlen(dp));

    //if active or passive, we need to add the peer1 and peer2 variants of each DP in the list
    if(which == "active" || which == "passive")
    {
      dynAppend(reduDplist, fwInstallationRedu_resolveDp(sys+dp, 1, true)+element);
      dynAppend(reduDplist, fwInstallationRedu_resolveDp(sys+dp, 2, true)+element);
    }
    else
      dynAppend(reduDplist, fwInstallationRedu_resolveDp(sys+dp, which, true)+element);

    //DebugN(dplist[i], sys, dp, element, which, reduDplist[dynlen(reduDplist)]);
  }

  //if active or passive, we need to identify the positions in the list of the DPs relating to peer1 and peer2
  if(which == "active" || which == "passive")
  {
    dataLocations["peer1"] = makeDynInt();
    dataLocations["peer2"] = makeDynInt();

    //Check for duplicated DPs (this implies that peer 2 DP does not exist, i.e. DP does/should not have _2 variant)
    //Find these cases and build lists for peer 1 & 2 of the positions that each DP will be in after the dynUnique call
    int index = 1;
    for(int i=index; i<=dynlen(reduDplist)-1; i+=2)
    {
      if(reduDplist[i] == reduDplist[i+1])
      {
        dynAppend(dataLocations["peer1"], index);
        dynAppend(dataLocations["peer2"], index++);
      }
      else
      {
        dynAppend(dataLocations["peer1"], index++);
        dynAppend(dataLocations["peer2"], index++);
      }
    }

    //ensure not duplicated DPs in the list as dpConnect does not support this
    dynUnique(reduDplist);
  }
  else //just build a list saying that the DPs for the relevant peer are in sequential order in the list
  {
    dataLocations["peer" + which] = makeDynInt();
    for(int i=1; i<=dynlen(reduDplist); i++)
      dynAppend(dataLocations["peer" + which], i);
  }

  dataIndexes = dataLocations;
  //DebugN(dplist, which, reduDplist, dataIndexes);

  //return TRUE if the REDU list is long than the original list (i.e. which was active or passive AND some entries in the list had an _2 version)
  return (dynlen(reduDplist) > dynlen(dplist));
}


/* IMPORTANT: If calling this function from a panel, the work callback function must be located in the ScopeLib */
int fwInstallationRedu_dpConnectUserData(string work, anytype userData, bool answer, dyn_string dplist, string which="")
{
  if(which == "")
  {
    int conn = -100; //not initialised
    which = fwInstallationRedu_getDefaultWhich(dpSubStr(dplist[1], DPSUB_SYS), conn);
  }

  dyn_string reduDplist;
  mapping dataLocations;
  bool needsEvStatus = fwInstallationRedu_prepareDpConnectionList(dplist, which, reduDplist, dataLocations);
  if(needsEvStatus)
    dynAppend(reduDplist, dpSubStr(reduDplist[1], DPSUB_SYS) + fwInstallationRedu_peer1ActiveDpe);

  dyn_anytype callbackData;
  callbackData[1] = which;
  callbackData[2] = work;
  callbackData[3] = dataLocations;

  if(getType(userData) == DYN_ANYTYPE_VAR)
  {
    if(userData != makeDynAnytype())
      callbackData[4] = userData; //if user data is dyn_anytype but is not empty (i.e. unused), then copy the user data
  }
  else
    callbackData[4] = userData; //if user data is not dyn_anytype then also assume it is used, so copy the user data

  return dpConnectUserData("fwInstallationRedu_callbackForConnect", callbackData, answer, reduDplist);
}

void fwInstallationRedu_callbackForConnect(dyn_anytype callbackData, dyn_string dplist, dyn_anytype values)
{
  string which = callbackData[1];
  string work = callbackData[2];
  mapping dataLocations = callbackData[3];

  //the final value of "values" contains the active state of peer1
  string peer;
  if(which == "active")
    peer = values[dynlen(values)]?"peer1":"peer2";
  else if(which == "passive")
    peer = values[dynlen(values)]?"peer2":"peer1";
  else
    peer = "peer" + which;

  dyn_string userDplist;
  dyn_anytype userValues;

  for(int i=1; i<=dynlen(dataLocations[peer]); i++)
  {
    dynAppend(userDplist, dplist[dataLocations[peer][i]]);
    userValues[dynlen(userDplist)] = values[dataLocations[peer][i]];  //do not use dynAppend in order to avoid flattening any dyn_values into a list
  }

  //TODO - should try to add smoothing here to avoid callbacks when the observed peer dps do not change
  //but how to check? timestamp cannot be used because attributes other than ..value can be connected to


  //DebugTN("[fwInstallationRedu_callbackForConnect] ", work, " is Defined? " , isFunctionDefined(work));

  // NOTE: Here it is needed to use startThread because callFunction won't work if the function is in the script scope (not clear why)

  if(dynlen(callbackData) > 3)
  {
   if(dynlen(userDplist) == 1)
      startThread(work, callbackData[4], userDplist[1], userValues[1]);
    else
      startThread(work, callbackData[4], userDplist, userValues);

  }
  else
  {
    if(dynlen(userDplist) == 1)
      startThread(work,  userDplist[1], userValues[1]);
    else
      startThread(work,  userDplist, userValues);

  }
}


void fwInstallationRedu_debug(string msg, bool printStackTrace = false, bool newLine = false)
{
  if (! fwInstallationRedu_debugActive)
    return;

  int thr = getThreadId();
  if (newLine)
  {
    DebugTN(thr,"*******************\n");
  }
  if (printStackTrace)
  {
    dyn_string stack = getStackTrace();
    dynRemove(stack,1);
    DebugTN(thr,msg, stack);
  }
  else
  {
    DebugTN(thr,msg);
  }
}

/** Get recovering direction of the given peer. Default is my peer
  @param peer (default my)
  @return 0 -> not recovering 1 -> pushing data to other peer 2-> receiving data from the other peer
*/
int fwInstallationRedu_getRecoveringDirection(string peer= "my")
{
  string dp = fwInstallationRedu_resolveDp("_ReduManager", peer);
  string fn = getPath(DATA_REL_PATH) + "/fwInstallationDpGetResult" + period(getCurrentTime()) + ".txt";
  fwInstallationRedu_execScriptConnectedToBothPeers("fwInstallation/fwInstallationGetDpe.ctl",makeDynString(dp + ".IsRecovering", fn));
  delay(0,2);
  string result;
  fileToString(fn,result);
  int status = (int) result;

  remove(fn);
  return (status);
}

