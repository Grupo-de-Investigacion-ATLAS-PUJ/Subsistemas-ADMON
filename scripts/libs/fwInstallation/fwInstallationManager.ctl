/**@file
 *
 * This library  contains general functions of the FW Component Installation tool
 * to manipulate managers.
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */
#uses "fwInstallation/fwInstallation.ctl"
#uses "fwInstallation/fwInstallationDB.ctl"
#uses "fwInstallation/fwInstallationRedu.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationManagerLibVersion = "9.1.3";
const string csFwInstallationManagerLibTag = "";

/**
 * @name fwInstallationManager.ctl: Definition of constants
   that are used by this library.
 * @{
 */
const int FW_INSTALLATION_MANAGER_PMON_IDX = 1;
const int FW_INSTALLATION_MANAGER_PMON_USER = 2;
const int FW_INSTALLATION_MANAGER_PMON_PWD = 3;
const int FW_INSTALLATION_MANAGER_PMON_PORT = 4;
const int FW_INSTALLATION_MANAGER_HOST = 5;
const int FW_INSTALLATION_MANAGER_TYPE = 6;
const int FW_INSTALLATION_MANAGER_OPTIONS = 7;
const int FW_INSTALLATION_MANAGER_START_MODE = 8;
const int FW_INSTALLATION_MANAGER_SEC_KILL = 9;
const int FW_INSTALLATION_MANAGER_RESTART_COUNT = 10;
const int FW_INSTALLATION_MANAGER_RESET_MIN = 11;
const int FW_INSTALLATION_MANAGER_DONT_STOP_RESTART = 12;

const int FWINSTALLATION_MANAGER_MIN_SEC_KILL = 1;
const int FWINSTALLATION_MANAGER_MAX_SEC_KILL = 9999;
const int FWINSTALLATION_MANAGER_MIN_RESTART_COUNT = 1;
const int FWINSTALLATION_MANAGER_MAX_RESTART_COUNT = 100;
const int FWINSTALLATION_MANAGER_MIN_RESET_MIN = 1;
const int FWINSTALLATION_MANAGER_MAX_RESET_MIN = 60;
const dyn_string FWINSTALLATION_MANAGER_START_MODES = makeDynString("manual", "always", "once");

const int FWINSTALLATION_MANAGER_STATE_STOPPED = 0;
const int FWINSTALLATION_MANAGER_STATE_INIT = 1;
const int FWINSTALLATION_MANAGER_STATE_RUNNING = 2;
const int FWINSTALLATION_MANAGER_STATE_BLOCKED = 3;

const string FWINSTALLATION_MANAGER_ACTION_START = "START";
const string FWINSTALLATION_MANAGER_ACTION_STOP = "STOP";
const string FWINSTALLATION_MANAGER_ACTION_KILL = "KILL";
const string FWINSTALLATION_MANAGER_ACTION_RESTART = "RESTART";


///@} // end of constants


/** This function retrieves the manager start time

@param type  type of manager
@param options  manager options
@param manNum manager number
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password
@return 0 if OK, -1 if error
*/
int fwInstallationManager_getStartTime(string type,
                                       string options,
                                       time &manStartTime,
                                       string host = "",
                                       int port = 4999,
                                       string user = "",
                                       string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_getStartTime(): Could not " +
                           "resolve pmon username and password. Action aborted",
                           "error", 1);
      return -1;
    }
  dyn_mixed properties;
  int retCode = fwInstallationManager_getProperties(type, options, properties, host, port, user, pwd);
  if(retCode != 0)
  {
    fwInstallation_throw("fwInstallationManager_getStartTime(): Could not get manager properties." +
                         " Action aborted", "error", 1);
    return -1;
  }
  if(properties[FW_INSTALLATION_MANAGER_PMON_IDX] != -1)
  {
    manStartTime = pmonGetStartTime((int)properties[FW_INSTALLATION_MANAGER_PMON_IDX]);
  }
  else
  {
    fwInstallation_throw("fwInstallationManager_getStartTime()-> Manager doesn't exist: " + type + "  " +
                         options);
    manStartTime = (time)0;
  }
  return 0;
}


/** Stops managers for the installation process.
 * 
 * @return 0 on sucess, -1 on error
 */
int fwInstallationManager_stopManagersForInstallation()
{
  int err = 0;

  // Check if there are managers to be stopped
  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("dist")))
  {
    if(fwInstallationManager_stopAllOfTypes(makeDynString(fwInstallation_getWCCOAExecutable("dist"))) != 0)//! fwInstallation_stopManagers?
    {
      fwInstallation_throw("Could not stop dist manager.", "WARNING", 10);
      if(myManType() == UI_MAN)
        ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping dist manager",
                            makeDynString("Could not stop dist manager.\nPlease do it manually."));

      ++err;
    }
  }

  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("ui")))
  {
    showProgressBar("Stopping UI managers", "This may take a few seconds", "Please wait", 66.);
    if(fwInstallationManager_stopAllOfTypes(makeDynString(fwInstallation_getWCCOAExecutable("ui"))) != 0)
    {
      fwInstallation_throw("Could not stop UI managers. Please stop these managers manually");
      if(myManType() == UI_MAN)
        ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping UI managers",
                            makeDynString("Could not stop UI managers.\nPlease do it " +
                                          "manually and then click OK\nto continue."));

      ++err;
    }
  }

  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("ctrl")))
  {
    if(fwInstallationManager_stopAllOfTypes(makeDynString(fwInstallation_getWCCOAExecutable("ctrl"))) != 0)
    {
      fwInstallation_throw("Could not stop ctrl managers.", "WARNING", 10);
      if(myManType() == UI_MAN)
        ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping control managers",
                            makeDynString("Could not stop control managers.\nPlease do it " +
                                          "manually and then click OK\nto continue."));
      ++err;
    }
  }

  if(err)
    return -1;

  return 0;
}


/** This function removes WinCC OA prefix ('WCCOA' or 'WCCIL') from manager type.
 * 
 * @param managerType  (string)  IN  manager type
 * @return value of type 'string' manager type without prefix
 */
string fwInstallationManager_removeManagerTypePrefix(string managerType)
{
  string typeWithoutPrefix = managerType;
  strreplace(typeWithoutPrefix, "WCCOA", "");
  strreplace(typeWithoutPrefix, "WCCIL", "");
  strreplace(typeWithoutPrefix, "PVSS00", "");
  return typeWithoutPrefix;
}


/** This function stops all manager of the project except those given in 'exceptions' argument.
 * All scattered managers are also stopped.
 * 
 * @param exceptions  (dyn_dyn_mixed)  IN  list of mangers that should stay running [type, command line arg]
 * @param host  (string)  IN  is optional with default value '""'  hostname
 * @param port  (int)  IN  is optional with default value '4999'  pmon port
 * @param user  (string)  IN  is optional with default value '""'  pmon user
 * @param pwd  (string)  IN  is optional with default value '""'  pmon password
 * @param wait  (bool)  IN  is optional with default value 'false'  indicates if wait for a manager to be in
 *                                   a particular state
 * @return value of type 'int'
 */
int fwInstallationManager_stopAll(dyn_dyn_mixed exceptions,
                                  string host = "",
                                  int port = 4999,
                                  string user = "",
                                  string pwd = "",
                                  bool wait = false)
{
  int error = 0;
  dyn_int diManPos, diStartMode, diSecKill, diRestartCount, diResetMin;
  dyn_string dsManager, dsCommandLine;
  string mode;

  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_stopAll(): Could not resolve " +
                           "pmon username and password. Action aborted",
                           "error", 1);
      return -1;
    }

  // Stop all scattered managers:
  fwInstallation_throw("Stopping all scattered managers. Please wait...", "INFO", 10);
  if(fwInstallationManager_stopAllScattered(makeDynString(), wait))
  {
    fwInstallation_throw("fwInstallationManager_stopAll(): Failed to stop scattered managers", "error", 1);
    return -1;
  }

  // Now stop all managers of the local pmon
  fwInstallation_throw("Stopping all local managers via PMON. Please wait...", "INFO", 10);
  dyn_dyn_mixed managersInfo;
  if(fwInstallationManager_pmonGetManagers(managersInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_stopAll(): Failed to get managers from PMON. Action aborted",
                         "error", 1);
    return -1;
  }

  diManPos = managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  dsManager = managersInfo[FW_INSTALLATION_MANAGER_TYPE];
  diStartMode = managersInfo[FW_INSTALLATION_MANAGER_START_MODE];
  diSecKill = managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL];
  diRestartCount = managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  diResetMin = managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN];
  dsCommandLine = managersInfo[FW_INSTALLATION_MANAGER_OPTIONS];

  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    bool skip = false;
    for(int k = 1; k <= dynlen(exceptions); k++)
    {
      if(dsManager[i] == exceptions[k][1] &&
         patternMatch(exceptions[k][2], dsCommandLine[i])) // hit one of the protected managers, skip it
      {
        skip = true;
        break;
      }
    }

    if(skip)
      continue;

    // Check if manager has to be reconfigured:
    if(diStartMode[i] == 2)
    {
      // Manager has to be reconfigured:
      mode = fwInstallationManager_startModeIntToString(diStartMode[i]);

      if(fwInstallationManager_logCurrentConfiguration(dsManager[i], mode, diSecKill[i], diRestartCount[i],
                                                       diResetMin[i], dsCommandLine[i]) != 0)
      {
        fwInstallation_throw("ERROR: fwInstallationManager_stopAll(): Could not log current manager " +
                             "configuration for manager: " + dsManager[i] + " " + dsCommandLine[i] +
                             ". Manager will not be stopped. Please do it manually", "error", 1);
        ++error;
        continue;
      }

      if(fwInstallationManager_setMode(dsManager[i], dsCommandLine[i], "manual", host, port, user, pwd) != 0)
      {
        fwInstallation_throw("ERROR: fwInstallationManager_stopAll(): Cannot change manager properties. " +
                             "Skipping manager: " + dsManager[i] + " " + dsCommandLine[i], "error", 1);
        ++error;
        continue;
      }
    }
    if(fwInstallationManager_command("STOP", dsManager[i], dsCommandLine[i], host, port, user, pwd, wait))
      ++error;
  }
  //! should it return 0 even in case of failed to change manger properties.
  return 0;
}


/** This function log the current configuration of a manager by writing it into
  an internal datapoint of the installation tool
  @param manager manager type
  @param startMode {always, once, manual}
  @param secKill seconds before the manager is flag as in the wrong state
  @param restartCount restart counter
  @param resetMin time in min that the manager must be OK before the reset
  counter is reset
  @return 0 if OK, -1 if error
 */
int fwInstallationManager_logCurrentConfiguration(
    string manager, string startMode, int secKill, int restartCount, int resetMin, string commandLine)
{
  bool found = false;

  dyn_string dsManager, dsCommandLine, dsStartMode;
  dyn_int diSecKill, diRestartCount, diResetMin;

  if(fwInstallationManager_getReconfigurationActions(
     dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationManager_logCurrentConfiguration(): Could not read current " +
                         "configuration from an internal datapoint. Action aborted.", "error", 1);
    return -1;
  }

  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    if(manager == dsManager[i] && commandLine == dsCommandLine[i])
    {
      // Found manager. Still pending action.
      dsStartMode[i] = startMode;
      diSecKill[i] = secKill;
      diRestartCount[i] = restartCount;
      diResetMin[i] = resetMin;
      found = true;
      break;
    }
  }

  if(!found)
  {
    int count = 0;
    const int logElementsCount = 6;
    if(dynAppend(dsManager, manager) > 0)
      ++count;
    if(dynAppend(dsStartMode, startMode) > 0)
      ++count;
    if(dynAppend(diSecKill, secKill) > 0)
      ++count;
    if(dynAppend(diRestartCount, restartCount) > 0)
      ++count;
    if(dynAppend(diResetMin, resetMin) > 0)
      ++count;
    if(dynAppend(dsCommandLine, commandLine) > 0)
      ++count;

    if(count != logElementsCount)
    {
      fwInstallation_throw("ERROR: fwInstallationManager_logCurrentConfiguration(): Failed to add current " +
                           "configuration of manager to the lists. Action aborted.", "error", 1);
      return -1;
    }
  }

  return fwInstallationManager_setReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount,
                                                         diResetMin, dsCommandLine);
}


/** This function retrieves all managers' properties for the local project. Data is read from progs file in 
 *  'config/' folder
  @param managersInfo managers' properties as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if error
*/
int fwInstallationManager_getAllInfoFromPvss(dyn_dyn_mixed &managersInfo)
{
  file f;
  int err;
  string line;
  const string progsFilename = getPath(CONFIG_REL_PATH, "progs");
  dyn_string ds;
  int i = 1;

  if(access(progsFilename, R_OK) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationManagers_getAllInfoFromPvss(): Could not access file: " +
                         progsFilename, "error", 4);
    return -1;
  }

  f = fopen(progsFilename, "r");
  err = ferror(f);
  if(err != 0)
  {
    fclose(f);
    fwInstallation_throw("ERROR: fwInstallationManagers_getAllInfoFromPvss(): Error no. " + err +
                         " while opening the file: " + progsFilename, "error", 4);
    return -1;
  }

  while(feof(f) == 0)
  {
    fgets(line, 200, f);
    // check that we are dealing with a pvss manager:
    if(patternMatch("PVSS00*", line) || patternMatch("WCC*", line))
    {
      ds = strsplit(line, "|");
      // remove blank spaces:
      for(int j = 1; j <= dynlen(ds); j++)
      {
        if(j != FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX)
          strreplace(ds[j], " ", "");
        else
          strreplace(ds[j], "\n", "");
      }

      managersInfo[i][FW_INSTALLATION_DB_MANAGER_NAME_IDX] = ds[1];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] = ds[2];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] = ds[3];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] = ds[4];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] = ds[5];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] = ds[6];

      if(managersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == "always")
        managersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] = 1;
      else
        managersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] = 0;

      ++i;
    }
  }
  fclose(f);

  return 0;
}


/** This function allows to insert a manager into a project. It is checked before, if the
  * manager already exists.
  *
  * @param manager        name of the manager
  * @param startMode      {manual, once, always}
  * @param secKill        seconds to kill after stop
  * @param restartCount    number of restarts
  * @param resetMin        restart counter reset time (minutes)
  * @param commandLine    commandline for the manager
  * @param host  hostname
  * @param port  pmon port
  * @param user  pmon user
  * @param pwd    pmon password
  * @return 1 - manager added, 2 - manager already existing, 3 - manager addition disabled,
  *         0 - manager addition failed
  * @author F. Varela (original idea by S. Schmeling)
  */
int fwInstallationManager_add(string manager,
                              string startMode,
                              int secKill,
                              int restartCount,
                              int resetMin,
                              string commandLine,
                              string host = "",
                              int port = 4999,
                              string user = "",
                              string pwd = "")
{
  if(host == ""){
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "" && fwInstallation_getPmonInfo(user, pwd) != 0){
    fwInstallation_throw("fwInstallationManager_add(): Could not resolve pmon username and password. " + 
                         "Action aborted", "ERROR", 1);
    return 0;
  }
  
  if(!fwInstallationManager_isManagerFileExecutable(manager) && // Check only when adding manager to console on local host
     host == fwInstallation_getPmonHostname()){ // If manager does not exist - show warning in the log but proceed
    fwInstallation_throw("fwInstallationManager_add(): Manager executable file is not available in the system. " +
                         "It will not be possible to run manager: " + manager, "WARNING");
  }
  if(!fwInstallationManager_isManagerPropertiesValid(manager, startMode, secKill, restartCount, resetMin))
  {
    fwInstallation_throw("fwInstallationManager_add(): One or more properties of manager are incorrect. " + 
                         "Action aborted", "ERROR", 1);
    return -1; // Bad manager properties
  }
  
  /// For versions above 3.8-SP2, make sure that managers are added with the
  /// WinCC OA prefix
  if(VERSION_DISP != "3.8-SP2" && VERSION_DISP != "3.8" && (strpos(manager, "PVSS00") == 0))
  {
    strreplace(manager, "PVSS00", "");
    manager = fwInstallation_getWCCOAExecutable(manager);
  }

  commandLine = strltrim(strrtrim(commandLine));
  bool blockUis = false;
  bool disabled;
  string dp = fwInstallation_getInstallationDp();
  if(dpGet(dp + ".addManagersDisabled", disabled, dp + ".blockUis", blockUis) != 0)
  {
    fwInstallation_throw("fwInstallationManager_add(): Failed to get information if possibility to add " +
                         "managers to console is disabled. Assume no restrictions.", "WARNING");
  }

  dyn_string exceptions = makeDynString(FW_INSTALLATION_DB_AGENT_MANAGER_CMD, FW_INSTALLATION_SCRIPTS_MANAGER_CMD);
  if(blockUis && manager == fwInstallation_getWCCOAExecutable("ui"))
  {
    for(int i = 1; i <= dynlen(exceptions); i++)
    {
      if(patternMatch("*" + exceptions[i] + "*", commandLine))
      {
        blockUis = false;
        break;
      }
    }
    if(blockUis)
    {
      fwInstallation_throw("WARNING: Addition of UI managers have been disabled. Manager: " + manager + " " +
                           commandLine + " will not be added to the console.", "WARNING");
      return 0;
    }
  }

  if(disabled)
  {
    for(int i = 1; i <= dynlen(exceptions); i++)
    {
      if(patternMatch("*" + exceptions[i] + "*", commandLine))
      {
        disabled = false;
        break;
      }
    }
    if(disabled)
    {
      fwInstallation_throw("Manager addition will be skipped due to project settings", "WARNING", 10);
      return 3; // manager addition disabled
    }
  }

  // localhost:
  int err = 0;
  int ret = _fwInstallation_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port,
                                user, pwd);
  if(ret < 0)
  {
    ++err;
    fwInstallation_throw("Failed to add manager: " + manager + " " + commandLine + " to project console " +
                         "on localhost. Return code " + ret);
  }
  else if(ret == 2) // manager already added to the project, nothing to be done
  {
    return 2;
  }

  if(fwInstallationRedu_isRedundant() && fwInstallation_getAddManagersOnReduPartner())
  {
    string reduHost = fwInstallationRedu_getPair();
    if(_fwInstallation_add(manager, startMode, secKill, restartCount, resetMin, commandLine, reduHost, port,
                           user, pwd) < 0)
    {
      ++err;
      fwInstallation_throw("Failed to add manager: " + manager + " " + commandLine +
                           " to project console on redu partner: " + reduHost);
    }
  }

  if(err)
  {
    return 0; // unfortunately this is not coherent with the convention followed in the libraries (legacy);
  }

  return 1; // unfortunately this is not coherent with the convention followed in the libraries (legacy);
}


/** Add manager to WinCC OA console.
 * 
 * @param manager  (string)  IN manager to add
 * @param startMode  (string)  IN start mode: manual, always, once
 * @param secKill  (int)  IN 
 * @param restartCount  (int)  IN maximum count of restarts within resetMin before
 *                               pmon stops restarting the manager
 * @param resetMin  (int)  IN maximum time before stop restarting the manager
 * @param commandLine  (string)  IN command line options for new manager
 * @param host  (string)  IN host for pmon manager
 * @param port  (int)  IN port for pmon manager
 * @param user  (string)  IN username for pmon manager
 * @param pwd  (string)  IN password for pmon manager
 * @return value of type 'int' -1 on error, 0 - success, 2 - such manager already exists in WinCC OA Console 
 */
int _fwInstallation_add(string manager,
                        string startMode,
                        int secKill,
                        int restartCount,
                        int resetMin,
                        string commandLine,
                        string host = "",
                        int port = 4999,
                        string user = "",
                        string pwd = "")
{
  dyn_mixed managerInfo;

  if(user == "N/A")
    user = "";
  if(pwd == "N/A")
    pwd = "";

  const int retCode = fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  if(retCode != 0)
  {
    fwInstallation_throw("_fwInstallation_add(): Could not get manager properties. Action aborted",
                         "error", 1);
    return -1;
  }
  if(managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX] != -1)
  {
    return 2; // Manager already in the WinCC OA console
  }

  dyn_dyn_mixed allManagers;
  if(fwInstallationManager_pmonGetManagers(allManagers, host, port, user, pwd) != 0 || dynlen(allManagers) <= 0)
  {
    fwInstallation_throw("_fwInstallation_add(): Could not read manager properties");
    return -1;
  }

  string str = user + "#" + pwd + "#SINGLE_MGR:INS " + dynlen(allManagers[1]) + " " + manager + " " +
               startMode + " " + secKill + " " + restartCount + " " + resetMin + " " + commandLine;

  if(pmon_command(str, host, port, FALSE, TRUE))
  {
    fwInstallation_throw("_fwInstallation_add(): Failed to insert manager: " + manager + " " +
                         commandLine + " " + host + " " + port + " " + user);
    return -1;
  }
  return 0;
}


/** Checks if executable binary file exists for given manager.
  * @note On Linux it checks if file has executable flag set, on Windows it searches for .exe file
  * @param managerName (in)  WinCC OA manager name
  * @return true if manager binary file exists, false if not
  */
bool fwInstallationManager_isManagerFileExecutable(string managerName)
{
  /// For versions above 3.8-SP2, make sure that managers are added with the WinCC OA prefix
  if(VERSION_DISP != "3.8-SP2" && VERSION_DISP != "3.8" && (strpos(managerName, "PVSS00") == 0))
  {
    strreplace(managerName, "PVSS00", "");
    managerName = fwInstallation_getWCCOAExecutable(managerName);
  }
  
  if(managerName == ""){
    return false;
  }
  // note: check if valid manager names can start only with WCCIL and WCCOA prefix to make rule more strict.
  if(_WIN32){
    if(getPath(BIN_REL_PATH, managerName + ".exe") == ""){
      return false;
    }
  }else{ // _UNIX - check also executable flag in manager file
    string managerPathLin = getPath(BIN_REL_PATH, managerName);
    if(managerPathLin == "" || access(managerPathLin, X_OK) != 0){
      return false;
    }
  }
  return true;
}


/** This function checks if following manager console parameters are valid.
@param manager (in)  Name of the manager (obsolete, legacy - use fwInstallationManager_isManagerFileExecutable()
                                                             to check if manager name is valid)
@param startMode (in)  WinCC OA console manager start mode. Allowed values: [manual, once, always]
@param secondsToKill (in)  Seconds to kill manager (kill -9) if it didn't stop with 'normal' stop signal (kill -15)
@param restartCount (in)  Maximum number of manager restart attempts in a time period
@param resetStartCounter (in)  Time after which the manager restart attempts counter is reset
@return true when all properties are valid, false if one or more properties are invalid
*/
bool fwInstallationManager_isManagerPropertiesValid(
    string manager, string startMode, int secondsToKill, int restartCount, int resetStartCounter)
{
  if(!fwInstallationManager_isManagerStartModeValid(startMode)){
    return false;
  }
  if(!fwInstallationManager_isManagerSecondsToKillValid(secondsToKill)){
    return false;
  }
  if(!fwInstallationManager_isManagerRestartCountValid(restartCount)){
    return false;
  }
  if(!fwInstallationManager_isManagerResetStartCounterValid(resetStartCounter)){
    return false;
  }
  return true;
}


/** Checks if given manager start mode is valid.
  * @note The allowed WinCC OA manager start modes are: "always", "once", "manual"
  * @param startMode (in)  Manager start mode
  * @return true if given start mode is correct, false if not
  */
bool fwInstallationManager_isManagerStartModeValid(string startMode){
  if(dynContains(FWINSTALLATION_MANAGER_START_MODES, startMode) <= 0){
    fwInstallation_throw("fwInstallationManager_isManagerStartModeValid() -> Invalid \"Start Mode\" value (" +
                         startMode + "). Valid types are: " + strjoin(FWINSTALLATION_MANAGER_START_MODES, ", "));
    return false;
  }
  return true;
}


/** Checks if manager console parameter "Seconds to kill" is correct.
  * @note "Seconds to kill" value must be in range 1 - 9999.
  * @param secondsToKill (in)  Manager "Seconds to kill" parameter value
  * @return true if given "Seconds to kill" value is correct, false if not
  */
bool fwInstallationManager_isManagerSecondsToKillValid(int secondsToKill){
  if(secondsToKill < FWINSTALLATION_MANAGER_MIN_SEC_KILL ||
     secondsToKill > FWINSTALLATION_MANAGER_MAX_SEC_KILL)
  {
    fwInstallation_throw("fwInstallationManager_isManagerSecondsToKillValid() -> Invalid " +
                         "\"Seconds to Kill\" value (" + secondsToKill + "). " + "Valid values are between " +
                         FWINSTALLATION_MANAGER_MIN_SEC_KILL + " and " + FWINSTALLATION_MANAGER_MAX_SEC_KILL);
    return false;
  }
  return true;
}


/** Checks if manager console parameter "Restart Counter" is correct.
  * @note "Restart Counter" must be in range 1 - 100.
  * @param restartCount (in)  Restart counter - how often (at most) manager can be restarted in a specified period
  * @return true if given "Restart Counter" value is correct, false if not
  */
bool fwInstallationManager_isManagerRestartCountValid(int restartCount){
  if(restartCount < FWINSTALLATION_MANAGER_MIN_RESTART_COUNT ||
     restartCount > FWINSTALLATION_MANAGER_MAX_RESTART_COUNT)
  {
    fwInstallation_throw("fwInstallationManager_isManagerRestartCountValid() -> Invalid \"Restart Counter\" " +
                         "value (" + restartCount + "). Valid values are between " +
                         FWINSTALLATION_MANAGER_MIN_RESTART_COUNT + " and " + FWINSTALLATION_MANAGER_MAX_RESTART_COUNT);
    return false;
  }
  return true;
}


/** Checks if manager console parameter "Reset Start Counter" is correct.
  * @note "Reset Start Counter" must be in range 1 - 60
  * @param resetStartCounter (in)  Time in minutes, after which the counter of manager restart attempts is reset
  * @return true if given "Reset Start Counter" value is correct, false if not
  */
bool fwInstallationManager_isManagerResetStartCounterValid(int resetStartCounter){
  if(resetStartCounter < FWINSTALLATION_MANAGER_MIN_RESET_MIN ||
     resetStartCounter > FWINSTALLATION_MANAGER_MAX_RESET_MIN)
  {
    fwInstallation_throw("fwInstallationManager_isManagerResetStartCounterValid() -> Invalid \"Reset start " +
                         "counter\" value(" + resetStartCounter + "). " + "Valid values are between " +
                         FWINSTALLATION_MANAGER_MIN_RESET_MIN + " and " + FWINSTALLATION_MANAGER_MAX_RESET_MIN);
    return false;
  }
  return true;
}


/** This function allows to insert a driver and the correspoding simulator in
the local project. It is checked before, if the
manager already exists.

@param defActivated if by the default the manager must be activated (i.e. no
selection is done in the popup windows and the timer expires)
@param manTitle Text shown as title
@param manager        name of the manager
@param startMode      {manual, once, always}
@param secKill        seconds to kill after stop
@param restartCount    number of restarts
@param resetMin        restart counter reset time (minutes)
@param commandLine    commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - manager addition
disabled, 0 - manager addition failed, -1 - invalid manager properties
@author F. Varela (original idea by S. Schmeling)
*/
int fwInstallationManager_appendDriver(string defActivated,
                                       string manTitle,
                                       string manager,
                                       string startMode,
                                       int secKill,
                                       int restartCount,
                                       int resetMin,
                                       string commandLine,
                                       string host = "",
                                       int port = 4999,
                                       string user = "",
                                       string pwd = "")
{
  if(host == ""){
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "" && fwInstallation_getPmonInfo(user, pwd) != 0){
    fwInstallation_throw("fwInstallationManager_appendDriver(): Could not resolve pmon username " +
                         "and password. Action aborted", "ERROR", 1);
    return 0;
  }
  // Check if manager file exists only when adding manager to console on local host
  bool skipAddingDriver = (!fwInstallationManager_isManagerFileExecutable(manager) &&
                           host == fwInstallation_getPmonHostname());
  
  if(!fwInstallationManager_isManagerPropertiesValid(manager, startMode, secKill, restartCount, resetMin)){
    fwInstallation_throw("fwInstallationManager_appendDriver: One or more properties of manager are " + 
                         "incorrect. Action aborted", "ERROR", 1);
    return -1; // Bad manager properties
  }

  bool activateManagersDisabled;
  string installationDp = fwInstallation_getInstallationDp();
  if(dpGet(installationDp + ".activateManagersDisabled", activateManagersDisabled) != 0){
    fwInstallation_throw("fwInstallationManager_appendDriver(): Could not get dpe .activateManagersDisabled " +
                         "value for dp: " + installationDp + ". Assume false", "WARNING");
    activateManagersDisabled = false;
  }
  
  string managerToActivate = defActivated;
  if(startMode != "manual"){ // need to choose which manager - driver or simulator - has start mode "always" or "once"
    if(myManType() == UI_MAN){ // if UI manager prompt user to choose one
      dyn_float df;
      dyn_string ds;
      ChildPanelOnCentralReturn("fwInstallation/fwInstallation_addDriver.pnl", "Add Driver ...",
                                makeDynString("$manTitle:" + manTitle, "$defActivated:" + defActivated,
                                              "$skipDriver:" + (skipAddingDriver?"yes":"no")), df, ds);
      switch(ds[1]){
        case "DRIVER": // handle cases together
        case "SIM":
          managerToActivate = ds[1];
          break;
        case "DENY":
          return 0; // to keep previous behavior - DENY means "do not add managers to console"
        // default: (case "timeout") use value of defActivated already assigned to managerToActivate
      }
    }else if(activateManagersDisabled){ // in silent mode check if activation of managers is disabled
      managerToActivate = "NONE";
    }
  }
   
  string driverStartMode = (managerToActivate=="DRIVER")?startMode:"manual";
  string simulatorStartMode = (managerToActivate=="SIM")?startMode:"manual";
  
  if(skipAddingDriver){
    fwInstallation_throw("fwInstallationManager_appendDriver(): Hardware driver: " + manager + " is not "
                         "available in the system. Appending only simulation driver.", "INFO", 10);
    if(managerToActivate == "DRIVER"){
      simulatorStartMode = startMode;
    }
  }
  
  int drvAddStatus = skipAddingDriver?1:
                     fwInstallationManager_add(manager, driverStartMode, secKill, restartCount, resetMin,
                                               commandLine, host, port, user, pwd);
  int simAddStatus = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), simulatorStartMode,
                                               secKill, restartCount, resetMin,
                                               commandLine, host, port, user, pwd);
  if(drvAddStatus == 1 && simAddStatus == 1 && myManType() != UI_MAN && activateManagersDisabled &&
     startMode != "manual"){ // Drivers appended in silent mode, activation is blocked
    fwInstallation_throw("The installation tool appended a driver to your project. If you want it to start " +
                         "'always' or 'once', please change the start mode in the console by hand.", "INFO", 10);
    return 3;
  }
  
  if(simAddStatus != 1 && simAddStatus != 2){
    return simAddStatus;
  }
  return drvAddStatus;
}


/** This function appends a manager to the console of the local project.

@param defActivated if by the default the manager must be activated (i.e. no
selection is done in the popup windows and the timer expires)
@param manTitle Text shown as title
@param manager        name of the manager
@param requestedStartMode    {manual, once, always}
@param secKill        seconds to kill after stop
@param restartCount    number of restarts
@param resetMin        restart counter reset time (minutes)
@param commandLine    commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - manager addition
disabled, 0 - manager addition failed
@author F. Varela (original idea by S. Schmeling)
*/
int fwInstallationManager_append(bool defActivated,
                                 string manTitle,
                                 string manager,
                                 string requestedStartMode,
                                 int secKill,
                                 int restartCount,
                                 int resetMin,
                                 string commandLine,
                                 string host = "",
                                 int port = 4999,
                                 string user = "",
                                 string pwd = "")
{
  if(!fwInstallationManager_isManagerPropertiesValid(manager, requestedStartMode, secKill, restartCount, resetMin))
  {
    fwInstallation_throw("fwInstallationManager_append(): One or more properties of manager are incorrect. " + 
                         "Action aborted", "ERROR", 1);
    return -1; // Bad manager properties
  }
  
  if(host == ""){
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }if(user == "" && fwInstallation_getPmonInfo(user, pwd) != 0){
    fwInstallation_throw("fwInstallationManager_append(): Could not resolve pmon username and password. " +
                         "Action aborted", "ERROR", 1);
    return 0;
  }
  
  bool activateManagersDisabled;
  string installationDp = fwInstallation_getInstallationDp();
  if(dpGet(installationDp + ".activateManagersDisabled", activateManagersDisabled) != 0){
    fwInstallation_throw("fwInstallationManager_appendDriver(): Could not get dpe .activateManagersDisabled " +
                         "value for datapoint: " + installationDp + ". Assume false", "warning");
    activateManagersDisabled = false;
  }
  
  string managerStartMode = requestedStartMode;
  if(requestedStartMode != "manual"){
    if(myManType() == UI_MAN){
      dyn_float df;
      dyn_string ds;
      ChildPanelOnCentralReturn("fwInstallation/fwInstallation_addManager.pnl", "fwInstallation",
                                makeDynString("$manTitle:" + manTitle), df, ds);
      if(ds[1] == "DENY" || // to keep previous behavior - here DENY means "add manager in manual start mode"
         ds[1] == "timeout" && !defActivated){
        managerStartMode = "manual";
      }
    }else if(activateManagersDisabled){
      managerStartMode = "manual";
    }
  }
  
  int manAddStatus = fwInstallationManager_add(manager, managerStartMode, secKill, restartCount, resetMin, commandLine,
                                               host, port, user, pwd);
  if(manAddStatus == 1){
    if(myManType() != UI_MAN && activateManagersDisabled && requestedStartMode != "manual"){
      fwInstallation_throw("The installation tool appended a manager to your project. If you want it to start " +
                           "'always' or 'once', please change the start mode in the console by hand.", "INFO", 10);
      return 3;
    }
    fwInstallation_throw("The installation tool appended a manager: " + manager + " " + commandLine +
                         " with start mode: " + managerStartMode + " to your project.", "INFO", 10);
  }
  return manAddStatus;
}


/** This function deletes a manager reconfiguration action

@param manager        name of the manager
@param startMode      {manual, once, always}
@param secKill        seconds to kill after stop
@param restartCount    number of restarts
@param resetMin        restart counter reset time (minutes)
@param commandLine    commandline for the manager
@return 0 if OK, -1 if error
*/
int fwInstallationManager_deleteReconfigurationAction(
    string manager, string startMode, int secKill, int restartCount, int resetMin, string commandLine)
{
  dyn_string dsManager, dsCommandLine, dsStartMode;
  dyn_int diSecKill, diRestartCount, diResetMin;

  if(fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount,
                                                     diResetMin, dsCommandLine) != 0)
  {
    fwInstallation_throw("fwInstallationManager_deleteReconfigurationAction(): Could not get list of " +
                         "manager reconfiguration actions. Action aborted.", "ERROR", 1);
    return -1;
  }

  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    if(manager == dsManager[i] && commandLine == dsCommandLine[i])
    {
      int count = 0;
      const int logElementsCount = 6;
      if(dynRemove(dsManager, i) == 0)
        ++count;
      if(dynRemove(dsStartMode, i) == 0)
        ++count;
      if(dynRemove(diSecKill, i) == 0)
        ++count;
      if(dynRemove(diRestartCount, i) == 0)
        ++count;
      if(dynRemove(diResetMin, i) == 0)
        ++count;
      if(dynRemove(dsCommandLine, i) == 0)
        ++count;

      if(count != logElementsCount)
      {
        fwInstallation_throw("fwInstallationManager_deleteReconfigurationAction(): Failed to remove " +
                             "configuration of particular manager from the lists. Action aborted.",
                             "ERROR", 1);
      return -1;
      }
      break;
    }
  }

  return fwInstallationManager_setReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount,
                                                         diResetMin, dsCommandLine);
}


/** This function stores a set of manager reconfiguration action in an internal dp

@param dsManager      names of the managers
@param dsStartMode  array of  {manual, once, always}
@param diSecKill      array of seconds to kill after stop
@param diRestartCount  array of  number of restarts
@param diResetMin        array of restart counter reset time (minutes)
@param dsCommandLine    array of commandline for the manager
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setReconfigurationActions(dyn_string dsManager,
                                                    dyn_string dsStartMode,
                                                    dyn_int diSecKill,
                                                    dyn_int diRestartCount,
                                                    dyn_int diResetMin,
                                                    dyn_string dsCommandLine)
{
  string dpr = fwInstallation_getAgentRequestsDp();
  
  if(!dpExists(dpr))
  {
    fwInstallation_throw("fwInstallationManager_setReconfigurationActions(): Agent request dp " +
                         "doesn't exist in the project. Action aborted.", "ERROR", 1);
    return -1;
  }

  return dpSet(dpr + ".managerReconfiguration.manager", dsManager,
               dpr + ".managerReconfiguration.startMode", dsStartMode,
               dpr + ".managerReconfiguration.secKill", diSecKill,
               dpr + ".managerReconfiguration.restartCount", diRestartCount,
               dpr + ".managerReconfiguration.resetMin", diResetMin,
               dpr + ".managerReconfiguration.commandLine", dsCommandLine);
}


/** This function retrieves from an internal dp, the list of manager reconfiguration actions

@param dsManager      names of the managers
@param dsStartMode  array of  {manual, once, always}
@param diSecKill      array of seconds to kill after stop
@param diRestartCount  array of  number of restarts
@param diResetMin        array of restart counter reset time (minutes)
@param dsCommandLine    array of commandline for the manager
@return 0 if OK, -1 if error
*/

int fwInstallationManager_getReconfigurationActions(dyn_string &dsManager,
                                                    dyn_string &dsStartMode,
                                                    dyn_int &diSecKill,
                                                    dyn_int &diRestartCount,
                                                    dyn_int &diResetMin,
                                                    dyn_string &dsCommandLine)
{
  string dpr = fwInstallation_getAgentRequestsDp();
  
  if(!dpExists(dpr))
  {
    fwInstallation_throw("fwInstallationManager_getReconfigurationActions(): Agent request dp " +
                         "doesn't exist in the project. Action aborted.", "ERROR", 1);
    return -1;
  }

  return dpGet(dpr + ".managerReconfiguration.manager", dsManager,
               dpr + ".managerReconfiguration.startMode", dsStartMode,
               dpr + ".managerReconfiguration.secKill", diSecKill,
               dpr + ".managerReconfiguration.restartCount", diRestartCount,
               dpr + ".managerReconfiguration.resetMin", diResetMin,
               dpr + ".managerReconfiguration.commandLine", dsCommandLine);
}


/** This function executes a manager reconfiguration action

@param manager        name of the manager
@param startMode      {manual, once, always}
@param secKill        seconds to kill after stop
@param restartCount    number of restarts
@param resetMin        restart counter reset time (minutes)
@param commandLine    commandline for the manager
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_executeReconfigurationAction(string manager,
                                                       string startMode,
                                                       int secKill,
                                                       int restartCount,
                                                       int resetMin,
                                                       string commandLine,
                                                       string host = "",
                                                       int port = 4999,
                                                       string user = "",
                                                       string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_executeReconfigurationAction(): Could not resolve " +
                           "pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  string str;

  dyn_mixed managerInfo;
  if(fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_executeReconfigurationAction(): Failed to get " +
                         "properties of particular manager. Action aborted", "error", 1);
    return -1;
  }
  int pos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];

  if(pos < 0)
  {
    fwInstallation_throw("fwInstallationManager_executeReconfigurationAction(): Could not find given " +
                         "manager " + manager + " " + commandLine + " in console."); 
    return -1; // manager could not be found.
  }
    
  if(startMode == "always" || startMode == "once") // start the manager is required. In most of the
                                                   // cases this is redundant but it helps when pmon
                                                   // has given up starting the manager because it's
                                                   // been restarted too many times
    if(fwInstallationManager_command("START", manager, commandLine, host, port, user, pwd))
      fwInstallation_throw("fwInstallationManager_executeReconfigurationAction(): failed to start " +
                           "the manager explicitly: " + manager + " " + commandLine + " " + host + " " +
                           port + " " + user, "WARNING", 14);

  str = user + "#" + pwd + "#SINGLE_MGR:PROP_PUT " + (pos) + " " + startMode + " " + fabs(secKill) + " " +
        fabs(restartCount) + " " + fabs(resetMin) + " " + commandLine;

  if(pmon_command(str, host, port, FALSE, TRUE) != 0)
  {
    fwInstallation_throw("fwInstallationManager_executeReconfigurationAction(): Could not execute " + 
                         "action on manager" + manager + " " + commandLine + " " + host + " " + port +
                         " " + user);
    return -1;
  }
  return 0;
}


/** This function executes all manager reconfiguration action
@param fromPostInstall if false this function does nothing
@return 0 if OK, -1 if error
*/

int fwInstallationManager_executeAllReconfigurationActions(bool fromPostInstall = false)
{
  dyn_string dsManager, dsStartMode, dsCommandLine;
  dyn_int diSecKill, diRestartCount, diResetMin;

  if(!fromPostInstall)
    return 0;

  if(fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount,
                                                     diResetMin, dsCommandLine) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationManager_executeAllReconfigurationActions(): " +
                         "Could not get list of manager reconfiguration actions");
    return -1;
  }
  
  int error = 0;
  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    fwInstallation_throw("Reverting Manager Configuration: " + dsManager[i] + " " + dsCommandLine[i] + " " +
                         dsStartMode[i], "INFO", 10);
    error += fwInstallationManager_executeReconfigurationAction(
        dsManager[i], dsStartMode[i], diSecKill[i], diRestartCount[i], diResetMin[i], dsCommandLine[i]);
    error += fwInstallationManager_deleteReconfigurationAction(
        dsManager[i], dsStartMode[i], diSecKill[i], diRestartCount[i], diResetMin[i], dsCommandLine[i]);
  }

  if(error)
  {
    fwInstallation_throw("ERROR: fwInstallationManager_executeAllReconfigurationActions(): " +
                         "There were errors reconfiguring automatically the project managers");
    return -1;
  }

  return 0;
}


/** This function converts start mode given as an integer value into corresponding text (i.e. 0 -> "manual").
 * 
 * @param startModeInt  (int)  IN 
 * @return value of type 'string'
 */
string fwInstallationManager_startModeIntToString(int startModeInt)
{
  switch(startModeInt)
  {
    case 0:  return "manual"; break;
    case 1:  return "once";   break;
    case 2:  return "always"; break;
  }
  DebugTN("Invalid start mode value, should be 0, 1 or 2, given value = " + startModeInt +
          " cannot be converted to text. Empty string returned");
  return "";
}


/** This function converts start mode given as an text into corresponding integer value (i.e. "manual" -> 0).
 * 
 * @param startModeInt  (int) IN 
 * @return value of type 'string'
 */
int fwInstallationManager_startModeStringToInt(string startModeString)
{
  switch(strtolower(startModeString))
  {
    case "manual":  return 0; break;
    case "once":    return 1; break;
    case "always":  return 2; break;
  }
  DebugTN("Unrecognised start mode: " + startModeString + ". Cannot be converted to integer, -1 returned");
  return -1;
}


/** This function sets the start mode of a manager

@param manager        name of the manager
@param commandLine    commandline for the manager
@param mode      {manual, once, always}
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setMode(string manager,
                                  string commandLine,
                                  string mode,
                                  string host = "",
                                  int port = 4999,
                                  string user = "",
                                  string pwd = "")
{
  dyn_mixed managerInfo;
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_setMode(): Could not resolve pmon username and " +
                           "password. Action aborted", "error", 1);
      return -1;
    }

  if(fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_setMode(): Could not get manager properties. " +
                         "Action aborted", "error", 1);
    return -1;
  }
  if(managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX] == -1)
  {
    fwInstallation_throw("fwInstallationManager_setMode() -> Given manager: " + manager + " " +
                         commandLine + " doesn't exist", "error", 1);
    return -1;
  }
  
  // Change start mode of manager
  managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = fwInstallationManager_startModeStringToInt(mode);
  return fwInstallationManager_setProperties(manager, commandLine, managerInfo, host, port, user, pwd);
}


/** This stops all managers of a set of particular types

@param types  types of manager to be stopped, e.g. PVSS00ui or WCCOAui
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_stopAllOfTypes(dyn_string types,
                                         string host = "",
                                         int port = 4999,
                                         string user = "",
                                         string pwd = "",
                                         bool wait = false,
                                         bool useKill = false)
{
  int error = 0;
  dyn_string protectedManagersArgs;
  if(_fwInstallationManager_getManagersProtectedFromStopping(protectedManagersArgs))
  {
    fwInstallation_throw("fwInstallationManager_stopAllOfTypes(): Could not get list of managers protected " +
                         "from stopping. All managers of given types will be stopped", "WARNING");
  }

  dyn_int diManPos, diStartMode, diSecKill, diRestartCount, diResetMin;
  dyn_string dsManager, dsCommandLine;
  string mode;

  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_stopAllOfTypes(): Could not resolve pmon username " +
                           "and password. Action aborted", "error", 1);
      return -1;
    }

  dyn_dyn_mixed managersInfo;
  if(fwInstallationManager_pmonGetManagers(managersInfo, host, port, user, pwd))
  {
    fwInstallation_throw("fwInstallationManager_stopAllOfTypes(): Could not get list of managers from PMON. " +
                         "Action aborted.", "error", 1);
    return -1;
  }
  diManPos = managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  dsManager = managersInfo[FW_INSTALLATION_MANAGER_TYPE];
  diStartMode = managersInfo[FW_INSTALLATION_MANAGER_START_MODE];
  diSecKill = managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL];
  diRestartCount = managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  diResetMin = managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN];
  dsCommandLine = managersInfo[FW_INSTALLATION_MANAGER_OPTIONS];

  // Avoid opening the main panel of the installation tool is opened from the
  // Gedi
  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    if(dynlen(dynPatternMatch(dsManager[i], types)))
    {
      // Stop all managers except the protected ones:
      bool protect = false;
      for(int j = 1; j <= dynlen(protectedManagersArgs); j++)
      {
        if(patternMatch("*" + protectedManagersArgs[j] + "*", dsCommandLine[i]))
          protect = true; // this manager is in the protected list
      }

      if(!protect) // stop it if it is not a protected manager
      {
        // Check if manager has to be reconfigured:
        if(diStartMode[i] == 2)
        {
          // Manager has to be reconfigured:
          mode = "always"; // Current mode of the manager
          if(fwInstallationManager_logCurrentConfiguration(
                 dsManager[i], mode, diSecKill[i], diRestartCount[i], diResetMin[i], dsCommandLine[i]) != 0)
          {
            fwInstallation_throw("ERROR: fwInstallation_stopManagers(): Could not log current manager " +
                                 "configuration for manager: " + dsManager[i] + " " + dsCommandLine[i] +
                                 ". Manager will not be stopped. Please do it manually", "error", 1);
            ++error;
            continue;
          }

          if(dsManager[i] == fwInstallation_getWCCOAExecutable("ctrl") &&
             patternMatch("*" + FW_INSTALLATION_SCRIPTS_MANAGER_CMD + "*", dsCommandLine[i]))
          {
            mode = "once";
          }
          else
            mode = "manual";

          if(fwInstallationManager_setMode(dsManager[i], dsCommandLine[i], mode, host, port, user, pwd) != 0)
          {
            fwInstallation_throw("ERROR: fwInstallation_stopManagers(): Cannot change manager " +
                                 "properties. Skipping manager: " + dsManager[i] + " " + dsCommandLine[i],
                                 "error", 1);
            ++error;
            continue;
          }
        }

        string cmd = "STOP";
        if(useKill)
          cmd = "KILL";
          
        if(fwInstallationManager_command(cmd, dsManager[i], dsCommandLine[i], host, port, user, pwd, wait))
          ++error;
      }
    }
  } // end of loop over managers

  // Done the work through PMON. Stop now scattered UIs if any:
  return fwInstallationManager_stopAllScattered(types, wait);
}


/** Stop all scattered managers.
 * 
 * @param types (dyn_string) IN which types of manager to stop, empty = all
 * @param wait (bool) IN wait for managers to stop if true
 * @return 0 - success, -1 - operation failed
 */
int fwInstallationManager_stopAllScattered(dyn_string types = makeDynString(), bool wait = false)
{
  dyn_int pendingManagers;
  dyn_int managerTypes;
  dyn_string hosts;
  dyn_string internalTypes;
  const int tmax = 5;
  bool actionTaken = false;

  if(dynlen(types) <= 0)
  {
    dynAppend(internalTypes, "Ui");
    dynAppend(managerTypes, UI_MAN);
    dynAppend(internalTypes, "Ctrl");
    dynAppend(managerTypes, CTRL_MAN);
    dynAppend(internalTypes, "Api");
    dynAppend(managerTypes, API_MAN);
    dynAppend(internalTypes, "Device");
    dynAppend(managerTypes, DEVICE_MAN);
    dynAppend(internalTypes, "Driver");
    dynAppend(managerTypes, DRIVER_MAN);
    dynAppend(internalTypes, "Redu");
    dynAppend(managerTypes, REDU_MAN);
    dynAppend(internalTypes, "Ascii");
    dynAppend(managerTypes, ASCII_MAN);
  }
  else
  {
    if(dynContains(types, fwInstallation_getWCCOAExecutable("ui")) > 0)
    {
      dynAppend(internalTypes, "Ui");
      dynAppend(managerTypes, UI_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("ctrl")) > 0)
    {
      dynAppend(internalTypes, "Ctrl");
      dynAppend(managerTypes, CTRL_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("api")) > 0)
    {
      dynAppend(internalTypes, "Api");
      dynAppend(managerTypes, API_MAN);
      dynAppend(internalTypes, "Device");
      dynAppend(managerTypes, DEVICE_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("driver")) > 0)
    {
      dynAppend(internalTypes, "Driver");
      dynAppend(managerTypes, DRIVER_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("redu")) > 0)
    {
      dynAppend(internalTypes, "Redu");
      dynAppend(managerTypes, REDU_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("ascii")) > 0)
    {
      dynAppend(internalTypes, "Ascii");
      dynAppend(managerTypes, ASCII_MAN);
    }
  }

  for(int i = 1; i <= dynlen(internalTypes); i++)
  {
    dynClear(hosts);
    if(dynlen(fwInstallationManager_getRunningScattered(internalTypes[i], hosts)))
    {
      if(fwInstallationManager_exitScattered(makeDynString(internalTypes[i]), makeDynInt(managerTypes[i])))
      {
        fwInstallation_throw("fwInstallationManager_stopAllScattered(): Failed to stop managers of type: "
                             + internalTypes[i]);
        return -1;
      }
      actionTaken = true;
    }
  }

  bool goOn = false;
  if(wait && actionTaken) // wait for the managers to stop:
  {
    // fwInstallation_throw("fwInstallationManager_stopPendingManagers() ->
    // Waiting for managers to stop...", "INFO", 10);
    int t = 0;
    do
    {
      dynClear(pendingManagers);
      dynClear(hosts);
      goOn = false;
      for(int i = 1; i <= dynlen(internalTypes); i++)
        if(dynlen(fwInstallationManager_getRunningScattered(internalTypes[i], hosts)))
        {
          fwInstallationManager_exitScattered(makeDynString(internalTypes[i]), makeDynInt(managerTypes[i]));
          goOn = true; // Managers are still running.
        }
      ++t;
      delay(10);
    } while(goOn && t <= tmax);

    if(goOn && t >= tmax)
    {
      for(int i = 1; i <= dynlen(internalTypes); i++)
      {
        dynClear(pendingManagers);
        pendingManagers = fwInstallationManager_getRunningScattered(internalTypes[i], hosts);
        if(dynlen(pendingManagers))
          fwInstallation_throw("fwInstallationManager_stopAllScattered(): Failed to stop all managers of type: "
                               + internalTypes[i] + ": " + strjoin((dyn_string)pendingManagers, ", "));
      }
      return -1;
    }
  }
  return 0;
}


/** Return what script is being run by ctrl manager. 
 * 
 * @param num (int) IN manager number
 * @param scripts (dyn_string) variable to receive (output) scripts that are being run
 * @param systemName (string) system where to check running scripts
 * @return 0 on success, -1 on error
 */
int fwInstallationManager_getScripts(int num, dyn_string &scripts, string systemName = "")
{
  if(num < 1) // wrong ctrl number
    return -1;

  if(systemName == "")
    systemName = getSystemName();

  string dp = systemName + "_CtrlDebug_CTRL_" + num;
  if(!dpExists(dp))
  {
    fwInstallation_throw("fwInstallationManager_getScripts(): _CtrlDebug dp for CTRL manager num " + num +
                         "doesn't exist, cannot continue", "ERROR", 10);
    return -1;
  }
  time t0;
  dpSetWait(dp + ".Command:_original.._value", "info scripts",
            dp + ".Result:_original.._value", makeDynString());
  //dpGet(dp + ".Command:_online.._stime", t0);
  
  int count;
  dyn_string tmpScripts;
  while(count < 500) // max 5 seconds
  {
    dpGet(dp + ".Result:_online.._value", tmpScripts);
    if(dynlen(tmpScripts) > 0){
      break;
    }
    delay(0,10);
    count++;
  }
  if(count >= 500)
  {
    fwInstallation_throw("fwInstallationManager_getScripts(): Failed to read the scripts run by " +
                         "Ctrl manager number: " + num, "WARNING", 10);
    return -1;
  }
  
  for(int i = 1; i <= dynlen(tmpScripts); i++)
  {
    dyn_string dsTemp = strsplit(tmpScripts[i], ";");
    if(dynlen(dsTemp) >= 1)
      dynAppend(scripts, dsTemp[dynlen(dsTemp)]);
  }
  return 0;
}


/** Get manager numbers and hosts where they are running.
 * 
 * @param type (string) type of manager (ex. "Ctrl")
 * @param remoteHosts (dyn_string) variable to receive remote host names 
 * @return manager numbers (also check remoteHosts)
 */
dyn_int fwInstallationManager_getRunningScattered(string type, dyn_string &remoteHosts)
{
  dyn_int di;
  dyn_int pendingManagers;
  dyn_string hosts;
  dyn_string protectedScripts;

  if(_fwInstallationManager_getManagersProtectedFromStopping(protectedScripts) != 0)
  {
    fwInstallation_throw("fwInstallationManager_getRunningScattered(): Could not get list of managers " +
                         "protected from stopping. All managers of given types will be stopped", "WARNING");
  }

  string connectionsDp = fwInstallationRedu_getLocalDp("_Connections");
  if(!dpExists(connectionsDp))
  {
    fwInstallation_throw("fwInstallationManager_getRunningScattered(): _Connections dp doesn't exist. " + 
                         "Empty dyn_int returned", "ERROR", 1);
    return makeDynInt();
  }
  if(dpGet(connectionsDp + "." + type + ".ManNums", di, connectionsDp + "." + type + ".HostNames", hosts) != 0)
  {
    fwInstallation_throw("fwInstallationManager_getRunningScattered(): Failed to get information about " +
                         "connected scattered managers.", "ERROR", 1);
  }

  for(int i = 1; i <= dynlen(di); i++)
  {
    // check that if a control manager, it does not run any of the scripts of
    // PVSS and of the Installation tool:
    bool isProtected = false;
    if(type == "Ctrl")
    {
      dyn_string scripts;
      if(fwInstallationManager_getScripts(di[i], scripts))
      {
        fwInstallation_throw("fwInstallationManager_getRunningScattered(): Could not resolve the scripts " +
                             "run by CTRL manager " + di[i] + ". This CTRL manager will be skipped.",
                             "WARNING", 10);
        continue;
      }
      for(int j = 1; j <= dynlen(scripts); j++)
      {
        if(dynlen(dynPatternMatch(scripts[j], protectedScripts)) > 0)
        {
          isProtected = true;
          break;
        }
      } // end of loop over j
    }
    else if(type == "Ui")
    {
      if(myManType() == UI_MAN && di[i] == myManNum())
        isProtected = true; // avoid stopping the calling UI.
    }

    if(!isProtected)
      if(dynAppend(pendingManagers, di[i]) <= 0)
        fwInstallation_throw("fwInstallationManager_getRunningScattered(): Could not add manager number " +
                             di[i] + " to the list of managers to be closed.", "WARNING", 10);
                           
    if(dynAppend(remoteHosts, hosts[i]) <= 0)
      fwInstallation_throw("fwInstallationManager_getRunningScattered(): Could not add host: " + hosts[i] +
                           " to the list of host with running scattered manager.", "WARNING", 10);
  }
  return pendingManagers;
}


/** Stop scattered managers.
 * 
 * @param types (dyn_string) type of manager (ex. "Ctrl") 
 * @param pvssManagerTypes (dyn_int) manager type (ex. CTRL_MAN)
 * @return 0 on success, -1 on error
 */
int fwInstallationManager_exitScattered(dyn_string types, dyn_int pvssManagerTypes)
{
  int err = 0;
  dyn_string hosts;

  for(int k = 1; k <= dynlen(types); k++)
  {
    dyn_int pendingManagers = fwInstallationManager_getRunningScattered(types[k], hosts);

    for(int i = 1; i <= dynlen(pendingManagers); i++)
    {
      fwInstallation_throw(
          "Stopping " + types[k] + ": " + pendingManagers[i] + " running on host: " + hosts[i], "INFO", 10);
      if(dpSet(fwInstallationRedu_getLocalDp("_Managers") + ".Exit",
               convManIdToInt(pvssManagerTypes[k], pendingManagers[i])) != 0)
      {
        fwInstallation_throw("Failed to stop manager: " + types[k] + ": " + pendingManagers[i] +
                             " running on remote host: " + hosts[i]);
                             //Note: this error info probably is incorrect, as the indexes of hosts and pendingManagers are different.
                             //      host is added to list of hosts even if manager is protected so is not added to the pendingManagers list.
        ++err;
      }
    }
  }

  if(err)
    return -1;

  return 0;
}


/** This function retrieves from an internal dp of the installation tool whether
the managers of a particular type have to be stopped prior to the installation of
a component or not

@param managerType type of manager, e.g. PVSS00ui
@return 1 if manager shall be stopped, 0 if not or Agent DP doesn't exist
*/
int fwInstallationManager_shallStopManagersOfType(string managerType)
{
  string dp = fwInstallation_getAgentDp();
  int val;

  switch(fwInstallationManager_removeManagerTypePrefix(managerType))
  {
    case "dist":
      dp += ".managers.stopDist";
      break;
    case "ui":
      dp += ".managers.stopUIs";
      break;
    case "ctrl":
      dp += ".managers.stopCtrl";
      break;
    default:
      fwInstallation_throw("ERROR: fwInstallationManager_shallStopManagersOfType(): " +
                           "Invalid manager type: " + managerType,  "error", 1);
      dp = "";
  }

  if(dpExists(dp))
    dpGet(dp, val);
  else
    val = 0;

  return val;
}


/** This function send a pmon command onto a manager

@param action   {START, STOP, KILL, RESTART}
@param manager manager type
@param commandLine    commandline for the manager
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password

@return 0 if OK, -1 if error
*/

int fwInstallationManager_command(string action,
                                  string manager,
                                  string commandLine,
                                  string host = "",
                                  int port = 4999,
                                  string user = "",
                                  string pwd = "",
                                  bool wait = false)
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_command(): Could not resolve " +
                           "pmon username and password. Action aborted",
                           "error", 1);
      return -1;
    }
  }

  dyn_mixed managerInfo;
  if(fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_command(): Could not get manager properties. Action aborted",
                         "error", 1);
    return -1;
  }

  int pos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(pos < 0)
  {
    fwInstallation_throw("fwInstallationManager_command(): Manager not found: " + manager + " " +
                         commandLine);
    return -1;
  }

  bool isStopped = false;
  int desiredState = -1;
  dyn_string cmds;
  switch(strtoupper(action))
  {
    case FWINSTALLATION_MANAGER_ACTION_START:
      dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:START " + pos);
      desiredState = FWINSTALLATION_MANAGER_STATE_RUNNING;
      break;
    case FWINSTALLATION_MANAGER_ACTION_STOP:
      dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:STOP " + pos);
      desiredState = FWINSTALLATION_MANAGER_STATE_STOPPED;
      break;
    case FWINSTALLATION_MANAGER_ACTION_KILL:
      dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:KILL " + pos);
      desiredState = FWINSTALLATION_MANAGER_STATE_STOPPED;
      break;
    case FWINSTALLATION_MANAGER_ACTION_RESTART:
      fwInstallationManager_isStopped(manager, commandLine, isStopped, host, port, user, pwd);
      if(!isStopped)
      {
        dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:KILL " + pos);
      }
      dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:START " + pos);
      desiredState = FWINSTALLATION_MANAGER_STATE_RUNNING;
      break;
    default:
      fwInstallation_throw("ERROR: fwInstallationManager_command(): Unknown action: " + action +
                           ". Valid actions are: START, STOP, KILL, RESTART");
      return -1;
  }
  int err = 0;
  for(int i = 1; i <= dynlen(cmds); i++)
  {
    if(pmon_command(cmds[i], host, port, false, true))
    {
      ++err;
      fwInstallation_throw("ERROR: fwInstallationManager_command(): Failed " +
                           "to execute command: " + cmds[i]);
    }
    if(i < dynlen(cmds)) // wait only if necessary
      delay(5);
  }

  // commands have been sent. Wait for the desired state if necessary:
  if(wait)
  {
    int currentState;
    fwInstallationManager_getState(manager, commandLine, currentState, host, port, user, pwd);
    if(currentState == desiredState)
    { // the manager is already in the desired state, nothing to be done.
      return 0;
    }
    bool running = (desiredState == FWINSTALLATION_MANAGER_STATE_RUNNING);
    fwInstallation_throw("Waiting for the manager " + manager + " " + commandLine + " to be: " +
                         (running ? "RUNNING" : "STOPPED"), "INFO", 10);
    bool timeoutExpired;
    fwInstallationManager_wait(running, manager, commandLine, 30, timeoutExpired, host, port, user, pwd);
    if(timeoutExpired)
    {
      fwInstallation_throw("Manager: " + manager + " " + commandLine + " is still " +
                           (!running ? "RUNNING" : "STOPPED"));
      return -1;
    }
    else
    {
      fwInstallation_throw("Manager: " + manager + " " + commandLine + " has been successfully " +
                           (running ? "STARTED" : "STOPPED"), "INFO", 10);
    }
  }
  return err?-1:0;
}


/** This function retrieves all managers from pmon

@param managersInfo (out) managers properties
@param host  (in) host name where the project runs
@param port  (in) pmon port
@param user  (in) pmon user
@param pwd    (in) pmon password
@return 0 if OK, -1 if error
@author F. Varela based on an original implmentation done by S. Schmeling
*/
int fwInstallationManager_pmonGetManagers(
    dyn_dyn_mixed &managersInfo, string host = "", int port = 4999, string user = "", string pwd = "")
{
  string str;
  dyn_dyn_string dsResult;

  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_pmonGetManagers(): Could not " +
                           "resolve pmon username and password. Action aborted",
                           "error", 1);
      return -1;
    }
  }
  str = user + "#" + pwd + "#MGRLIST:LIST";

  int err = pmon_query(str, host, port, dsResult, FALSE, TRUE);
  if(err != 0)
  {
    fwInstallation_throw("fwInstallationManager_pmonGetManagers(): Error executing pmon_query. Action aborted",
                         "error", 1);
      return -1;
  }
  if(dynlen(dsResult) > 0)
    for(int i = 1; i <= dynlen(dsResult); i++)
    {
      managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX][i] = i;
      managersInfo[FW_INSTALLATION_MANAGER_TYPE][i] = dsResult[i][1];
      managersInfo[FW_INSTALLATION_MANAGER_START_MODE][i] = dsResult[i][2];
      managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL][i] = dsResult[i][3];
      managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT][i] = dsResult[i][4];
      managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN][i] = dsResult[i][5];
      if(dynlen(dsResult[i]) > 5)
        managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i] = dsResult[i][6];
      else
        managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i] = "";
    }

  return 0;
}


/** This function switches between the real driver and the simulator.

@param driver    if set to one the real driver is started, otherwise the
simulator
@param name      manager type
@param number    driver number
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_switch(bool driver,
                                 string name,
                                 int number,
                                 string host = "",
                                 int port = 4999,
                                 string user = "",
                                 string pwd = "")
{
  string msg = "Switching to " + (driver ? "Driver" : "Simulation Driver") + " for " + name;
  fwInstallation_throw(msg, "INFO", 10);

  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not resolve " +
                           "pmon username and password. Action aborted",
                           "error", 1);
      return -1;
    }

  if(driver)
  {
    fwInstallation_throw("Setting simulator: -num " + number + " to " + (!driver ? "always" : "manual"),
                         "INFO", 10);
    if(fwInstallationManager_setMode(fwInstallation_getWCCOAExecutable("sim"), "-num " + number, "manual",
                                     host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not change simulator" + number +
                           " start mode to manual");
      return -1;
    }
    fwInstallation_throw((!driver ? "Starting" : "Stopping") + " simulator: -num " + number, "INFO", 10);
    if(fwInstallationManager_command("STOP", fwInstallation_getWCCOAExecutable("sim"), "-num " + number, host,
                                     port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not stop simulator" + number);
      return -1;
    }
    fwInstallationManager_waitForState(false, number);
    fwInstallation_throw(
        "Setting driver: " + name + " -num " + number + " to " + (driver ? "always" : "manual"), "INFO", 10);
    if(fwInstallationManager_setMode(name, "-num " + number, "always", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not change manager: " + name + " -num " +
                           number + " start mode to always");
      return -1;
    }
    fwInstallation_throw((driver ? "Starting" : "Stopping") + " driver: " + name + " -num " + number, "INFO",
                         10);
    if(fwInstallationManager_command("START", name, "-num " + number, host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not start manager: " + name + " -num " +
                           number);
      return -1;
    }
  }
  else
  {
    fwInstallation_throw(
        "Setting driver: " + name + " -num " + number + " to " + (driver ? "always" : "manual"), "INFO", 10);
    if(fwInstallationManager_setMode(name, "-num " + number, "manual", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not change manager: " + name + " -num " +
                           number + " start mode to manual");
      return -1;
    }
    fwInstallation_throw((driver ? "Starting" : "Stopping") + " driver: " + name + " -num " + number, "INFO",
                         10);
    if(fwInstallationManager_command("STOP", name, "-num " + number, host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not stop manager: " + name + " -num " +
                           number);
      return -1;
    }
    fwInstallationManager_waitForState(false, number);
    fwInstallation_throw("Setting simulator: -num " + number + " to " + (!driver ? "always" : "manual"),
                         "INFO", 10);
    if(fwInstallationManager_setMode(fwInstallation_getWCCOAExecutable("sim"), "-num " + number, "always",
                                     host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not change simulator" + number +
                           " start mode to always");
      return -1;
    }
    fwInstallation_throw((!driver ? "Starting" : "Stopping") + " simulator: -num " + number, "INFO", 10);
    if(fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("sim"), "-num " + number,
                                     host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch(): Could not start simulator" + number);
      return -1;
    }
  }

  return 0;
}


/** This function restarts a manager.

@param name      manager type
@param commandLine    commandline for the manager
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_restart(
    string name, string commandLine, string host = "", int port = 4999, string user = "", string pwd = "")
{
  return fwInstallationManager_command("RESTART", name, commandLine, host, port, user, pwd);
}


/** This function wait for a manager to be in a particular state

@param running   if set to one the function waits for the manager to be
running, otherwise to be stopped
@param number    driver number
@param retries  how many time to retry
@param systemName  name of the pvss system where to check the state of the
manager

@return 0 if OK, -1 if error
*/
void fwInstallationManager_waitForState(bool running, int number, int retries = 0, string systemName = "")
{
  dyn_anytype returnValues;
  time t = (time)60;
  bool timerExpired;
  dyn_anytype condition;
  dyn_int drivers;

  if(systemName == "")
    systemName = getSystemName();

  string connectionsDp = fwInstallationRedu_getReduDp("_Connections", systemName);
  // Check if the manager is already running:
  if(dpGet(systemName + connectionsDp + ".Driver.ManNums", drivers) != 0)
  {
    fwInstallation_throw("fwInstallationManager_waitForState(): Could not get managers' states from dp " +
                         "Action aborted", "ERROR", 1);
  }
  if((dynContains(drivers, number) > 0 && running) || (dynContains(drivers, number) <= 0 && !running))
  {
    // Manager already in the desired state, nothing to be done:
    return;
  }

  fwInstallation_throw("fwInstallationManager_waitForState(): Waiting for manager " + number + " to " +
                       (running ? "START" : "STOP"), "INFO", 10);
  if(dpWaitForValue(makeDynString(systemName + connectionsDp + ".Driver.ManNums:_original.._value"),
                    condition,
                    makeDynString(systemName + connectionsDp + ".Driver.ManNums:_original.._value"),
                    returnValues, t, timerExpired) == -1)
  {
    delay(5);
  }

  if(timerExpired)
  {
    fwInstallation_throw("fwInstallationManager_waitForState(): Timer expired. Manager " + number +
                         " has not " + (running ? "STARTED" : "STOPPED"));
  }

  if(fwInstallationManager_isDriverRunning(number, systemName) == running)
  {
    fwInstallation_throw("fwInstallationManager_waitForState(): Ok, manager " + number + " " +
                         (running ? "STARTED" : "STOPPED"), "INFO", 10);
    return;
  }
  else
  {
    fwInstallation_throw("fwInstallationManager_waitForState(): Manager: " + number + " is still " +
                         (!running ? "STARTED" : "STOPPED"), "WARNING", 10);
    if(retries == 3)
    {
      fwInstallation_throw("fwInstallationManager_waitForState(): Giving up " +
                           "after three failed attempts");
      return;
    }
    else
    {
      fwInstallationManager_waitForState(running, number, ++retries, systemName);
    }
  }
}


/** This function wait for a manager to be in a particular state

@param running    (in)  if true the desired state of the
manager is running,
                 otherwise it is stopped
@param manager    (in)  type of the pvss manager
@param commandLine    (in) manager options
@param timeout   (int)  how long to wait for in seconds
@param timeout   (in)  if true, the time has expired, otherwise the manager
                reached the desired state within the timeout time
@param host  (in) hostname
@param port  (in) pmon port
@param user  (in) pmon user
@param pwd    (in) pmon password
*/
void fwInstallationManager_wait(bool running,
                                string manager,
                                string commandLine,
                                int timeout,
                                bool &expired,
                                string host = "",
                                int port = 4999,
                                string user = "",
                                string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_wait(): Could not resolve pmon username and password. " +
                           "Action aborted", "error", 1);
      return;
    }
  }

  int t = 0;
  expired = false;
  int desiredState = running?FWINSTALLATION_MANAGER_STATE_RUNNING:
                             FWINSTALLATION_MANAGER_STATE_STOPPED;
  int currentState;
  do
  {
    if(fwInstallationManager_getState(manager, commandLine, currentState, host, port, user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_wait(): Error while checking if manager runs.", "WARNING");
    }
    delay(1);
    ++t;
  } while(currentState != desiredState && t <= timeout);

  expired = (t >= timeout && currentState != desiredState);
}


/** This function outputs the current manager state
  (for example: 0 - stopped; 2 - running)
  See FWINSTALLATION_MANAGER_STATE_* constants for possible states.

@param manager    (in)  type of the pvss manager
@param commandLine    (in) manager options
@param state   (out)  manager state
@param host  (in) hostname
@param port  (in) pmon port
@param user  (in) pmon user
@param pwd    (in) pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_getState(string manager,
                                   string commandLine,
                                   int &state,
                                   string host = "",
                                   int port = 4999,
                                   string user = "",
                                   string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }
  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_getManagerState(): Could not resolve pmon username and " +
                           "password. Action aborted", "error", 1);
      return -1;
    }
  }

  dyn_mixed managerInfo;
  if(fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("WARNING: fwInstallationManager_getManagerState(): Could not get manager " +
                         "properties.", "ERROR", 1);
    return -1;                 
  } 

  int pmonManIdx = (int)managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(pmonManIdx < 0)
  {
    //fwInstallation_throw("WARNING: fwInstallationDBAgent_isManagerRunning() -> Manager: " + manager +
    //                     " " + commandLine + " doesn't exist.", "ERROR", 1); 
    return -1;
  }

  dyn_dyn_string ddsStates;
  string str = user + "#" + pwd + "#MGRLIST:STATI";
  if(pmon_query(str, host, port, ddsStates, FALSE, TRUE))
  {
    fwInstallation_throw("WARNING: fwInstallationManager_getManagerState(): failed to execute pmon query");
    return -1;
  }
  state = (int)(ddsStates[pmonManIdx + 1][1]);
  return 0;
}


/** This function checks if a manager is running or not
Note: If manager is in initialization state (status=1 in console) this funtion outputs false.
      This function outputs true only when manager is up and running (status=2 in console).

@param manager    (in)  type of the pvss manager
@param commandLine    (in) manager options
@param isRunning   (out)  manager state. If 1 the manager is up and running, otherwise false
@param host  (in) hostname
@param port  (in) pmon port
@param user  (in) pmon user
@param pwd    (in) pmon password

@return 0 if OK, -1 if error
*/

int fwInstallationManager_isRunning(string manager,
                                    string commandLine,
                                    bool &isRunning,
                                    string host = "",
                                    int port = 4999,
                                    string user = "",
                                    string pwd = "")
{
  int state;
  if(fwInstallationManager_getState(manager, commandLine, state, host, port, user, pwd) != 0){
    fwInstallation_throw("fwInstallationManager_isRunning(): Could not check if manager is running",
                         "error", 1);
    return -1;
  }
  isRunning = (state == FWINSTALLATION_MANAGER_STATE_RUNNING);
  return 0;
}


/** This function checks if a manager is stopped

@param manager    (in)  type of the pvss manager
@param commandLine    (in) manager options
@param isStopped   (out)  manager state. True if manager stopped, false otherwise
@param host  (in) hostname
@param port  (in) pmon port
@param user  (in) pmon user
@param pwd    (in) pmon password

@return 0 if OK, -1 if error
*/

int fwInstallationManager_isStopped(string manager,
                                    string commandLine,
                                    bool &isStopped,
                                    string host = "",
                                    int port = 4999,
                                    string user = "",
                                    string pwd = "")
{
  int state;
  if(fwInstallationManager_getState(manager, commandLine, state, host, port, user, pwd) != 0){
    fwInstallation_throw("fwInstallationManager_isStopped(): Could not check if manager is stopped",
                         "error", 1);
    return -1;
  }
  isStopped = (state == FWINSTALLATION_MANAGER_STATE_STOPPED);
  return 0;
}


/** This function checks if a driver is running.

@param number    driver number
@param systemName  PVSS system where to find the manager
@return true if the driver runs, false otherwise
*/
bool fwInstallationManager_isDriverRunning(int number, string systemName = "", int reduHostNum = 0)
{
  dyn_int drivers;

  string connectionsDp = fwInstallationRedu_getReduDp("_Connections", systemName, reduHostNum);

  if(dpGet(systemName + connectionsDp + ".Driver.ManNums", drivers) != 0)
  {
    fwInstallation_throw("fwInstallationManager_isDriverRunning(): Could not get managers' states from " +
                         "datapoint.", "ERROR", 1);
    return false;
  }
  return (dynContains(drivers, number) > 0);
}


/** This function retrieves the manager properties

@param type  type of manager
@param options  manager options
@param properties manager properties
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password
@return 0 if OK, -1 if error
*/

int fwInstallationManager_getProperties(string type,
                                        string options,
                                        dyn_mixed &properties,
                                        string host = "",
                                        int port = 4999,
                                        string user = "",
                                        string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_getProperties(): Could not resolve pmon username and " + 
                           "password. Action aborted", "error", 1);
      return -1;
    }

  string cmd = user + "#" + pwd + "#MGRLIST:LIST";
  dyn_dyn_string res;
  bool found = false;
  bool failed = pmon_query(cmd, host, port, res, false, true);

  if(failed)
  {
    fwInstallation_throw("fwInstallationManager_getProperties(): Could not " +
                         "read manager properties via PMON. Query on host: " +
                         host + " PMON port: " + port);
    dynClear(properties);
    properties[FW_INSTALLATION_MANAGER_PMON_IDX] = -1;
    return -1;
  }

  string managerType = fwInstallationManager_removeManagerTypePrefix(type);
  for(int i = 1; i <= dynlen(res); i++)
  {
    if(strtoupper(fwInstallationManager_removeManagerTypePrefix(res[i][1])) == strtoupper(managerType))
    {
      if(dynlen(res[i]) >= 5 && (options == "" || (dynlen(res[i]) >= 6 && ((res[i][6] == options) ||
         patternMatch("*" + options + " *", res[i][6]) || patternMatch("*" + options, res[i][6])))))
      {
        found = true;
        properties[FW_INSTALLATION_MANAGER_PMON_IDX] = i - 1;
        properties[FW_INSTALLATION_MANAGER_TYPE] = res[i][1];
        properties[FW_INSTALLATION_MANAGER_START_MODE] = res[i][2];
        properties[FW_INSTALLATION_MANAGER_SEC_KILL] = res[i][3];

        if((int)res[i][3] >= 0)
          properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART] = 0;
        else
          properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART] = 1;

        properties[FW_INSTALLATION_MANAGER_RESTART_COUNT] = res[i][4];
        properties[FW_INSTALLATION_MANAGER_RESET_MIN] = res[i][5];
        properties[FW_INSTALLATION_MANAGER_PMON_USER] = user;
        properties[FW_INSTALLATION_MANAGER_PMON_PWD] = pwd;
        properties[FW_INSTALLATION_MANAGER_PMON_PORT] = port;
        properties[FW_INSTALLATION_MANAGER_HOST] = host;

        if(dynlen(res[i]) > 5)
          properties[FW_INSTALLATION_MANAGER_OPTIONS] = res[i][6];
        else
          properties[FW_INSTALLATION_MANAGER_OPTIONS] = "";
        break;
      }
    }
  }

  if(!found)
  {
    dynClear(properties);
    // fwInstallation_throw("Manager: " + type + ", Options: " + options + ",
    // Host: " + host + ", PMON Port: " + port + " not found in project",
    // "WARNNIG", 1);
    properties[FW_INSTALLATION_MANAGER_PMON_IDX] = -1;
  }
  return 0;
}


/** This function sets the manager properties

@param type  type of manager
@param currentOptions  manager options
@param properties manager properties
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setProperties(string type,
                                        string currentOptions,
                                        dyn_mixed properties,
                                        string host = "",
                                        int port = 4999,
                                        string user = "",
                                        string pwd = "")
{
  if(dynlen(properties) < FW_INSTALLATION_MANAGER_RESET_MIN)
  {
    fwInstallation_throw("fwInstallationManager_setProperties(): Invalid number of elements in dyn_mixed " +
                         "properties variable passed to the function");
    return -1;
  }
  
  if(!fwInstallationManager_isManagerPropertiesValid(type,
       fwInstallationManager_startModeIntToString(properties[FW_INSTALLATION_MANAGER_START_MODE]),
       properties[FW_INSTALLATION_MANAGER_SEC_KILL],
       properties[FW_INSTALLATION_MANAGER_RESTART_COUNT],
       properties[FW_INSTALLATION_MANAGER_RESET_MIN]))
  {
    fwInstallation_throw("fwInstallationManager_setProperties(): One or more properties of manager are " + 
                         "incorrect. Action aborted", "error", 1);
    return -1; // Bad manager properties
  }
  
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_setProperties(): Could not resolve pmon username " +
                           "and password. Action aborted", "error", 1);
      return -1;
    }

  // Find manager pmon index:
  dyn_mixed oldProperties;
  if(fwInstallationManager_getProperties(type, currentOptions, oldProperties, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_setProperties(): Failed to find manager: " + type +
                         " Options: " + currentOptions + " on host: " + host + " Port: " + port);
    return -1;
  }

  int index = oldProperties[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(index == -1)
  {
    fwInstallation_throw("fwInstallationManager_setProperties(): Could not find manager: " + type +
                         " Options: " + currentOptions + " on host: " + host + " Port: " + port,
                         "WARNING", 1);
    return -1;
  }

  // Set new properties
  string mode;
  string options = properties[FW_INSTALLATION_MANAGER_OPTIONS];
  int restartCount = properties[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  int resetMin = properties[FW_INSTALLATION_MANAGER_RESET_MIN];
  int sKill = properties[FW_INSTALLATION_MANAGER_SEC_KILL];
  bool noStop = false;
  string command;
  bool err;
  //Check if they are valid

  if(dynlen(properties) >= FW_INSTALLATION_MANAGER_DONT_STOP_RESTART)
    noStop = properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART];

  mode = fwInstallationManager_startModeIntToString(properties[FW_INSTALLATION_MANAGER_START_MODE]);

  command = user + "#" + pwd + "#SINGLE_MGR:PROP_PUT " + index + " " + mode + " " +
            (noStop ? -sKill : sKill) + " " + restartCount + " " + resetMin + " " + options;

  err = pmon_command(command, host, port, false, true);

  if(err)
  {
    fwInstallation_throw("fwInstallationManager_setProperties(): Could not set manager properties " +
                         "via PMON: " + type + " current options: " + currentOptions +
                         ". Command on host: " + host + " PMON port: " + port);
    return -1;
  }
  return 0;
}


/** This function retrieves the manager number

@param type  type of manager
@param options  manager options
@param manNum manager number
@param host  hostname
@param port  pmon port
@param user  pmon user
@param pwd    pmon password
@return 0 if OK, -1 if error
*/

int fwInstallationManager_getNum(string type,
                                 string options,
                                 int &manNum,
                                 string host = "",
                                 int port = 4999,
                                 string user = "",
                                 string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_getNum(): Could not resolve pmon username and password. " +
                           "Action aborted", "error", 1);
      return -1;
    }
  dyn_mixed properties;
  fwInstallationManager_getProperties(type, options, properties, host, port, user, pwd);
  if(properties[FW_INSTALLATION_MANAGER_PMON_IDX] != -1)
  {
    string cmd = user + "#" + pwd + "#MGRLIST:STATI";
    dyn_dyn_string res;
    bool failed = pmon_query(cmd, host, port, res, false, true);

    if(failed)
    {
      fwInstallation_throw("fwInstallationManager_getNum(): Could not read manager properties via PMON. " +
                           "Query on host: " + host + " PMON port: " + port);
      manNum = -1;
      return -1;
    }

    manNum = (int)res[(int)properties[FW_INSTALLATION_MANAGER_PMON_IDX] + 1][5];
  }
  else
  {
    fwInstallation_throw("fwInstallationManager_getNum(): Manager doesn't exist: " + type + "  " + options);
    manNum = -1;
  }
  return 0;
}


/** This function read the list of managers protected from stopping stored in
 * agent parametrisation dp
 * 
 * @param protectedManagers  (dyn_string)  IN/OUT 
 * @return value of type 'int' - 0 if OK, -1 if error
 */
int _fwInstallationManager_getManagersProtectedFromStopping(dyn_string &protectedManagers)
{
  string agentDp = fwInstallation_getAgentDp();
  if(!dpExists(agentDp))
  {
    fwInstallation_throw("_fwInstallationManager_getManagersProtectedFromStopping(): Agent " +
                         "parametrisation dp doesn't exist in the project. Action aborted.", "ERROR", 1);
  }
  return dpGet(agentDp + ".managers.protected", protectedManagers);
}


/** This function sets the list of managers protected from stopping in
 * agent parametrisation dp
 * 
 * @param protectedManagers  (dyn_string)  IN/OUT 
 * @return value of type 'int' - 0 if OK, -1 if error
 */
int _fwInstallationManager_setManagersProtectedFromStopping(dyn_string protectedManagers)
{
  string agentDp = fwInstallation_getAgentDp();
  if(!dpExists(agentDp))
  {
    fwInstallation_throw("_fwInstallationManager_getManagersProtectedFromStopping(): Agent " +
                         "parametrisation datapoint doesn't exist in the project. Action aborted.",
                         "ERROR", 1);
  }
  return dpSet(agentDp + ".managers.protected", protectedManagers);
}


/** This function removes a manager from pmon. It is only possible to remove it
  if no manager following it is running.
  @param manager
  @param commandLine
  @param host
  @param port
  @param user
  @param pwd
  @return 0 if OK, -1 if error
*/
int fwInstallationManager_remove(
    string manager, string commandLine, string host = "", int port = 4999, string user = "", string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getPmonHostname();
    port = pmonPort();
  }

  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_remove(): Could not resolve pmon username and password. " +
                           "Action aborted", "error", 1);
      return -1;
    }
  }

  // Check if manager exist
  dyn_mixed properties;
  if(fwInstallationManager_getProperties(manager, commandLine, properties, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_remove(): Could not get manager properties. " +
                         "Action aborted", "error", 1);
    return -1;
  }

  int index = properties[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(index == -1)
  {
    fwInstallation_throw("fwInstallationManager_remove(): Manager " + manager + " " + commandLine +
                         " not found", "error", 1);
    return -1;
  }

  // Set the manager to manual
  int res = fwInstallationManager_setMode(manager, commandLine, "manual", host, port, user, pwd);
  if(res == -1)
    return -1;

  // Stop the manager
  res = fwInstallationManager_command("STOP", manager, commandLine, host, port, user, pwd);
  if(res == -1)
    return -1;

  // Wait for a period of time and ensure that manager is stopped
  bool isExpired;
  int timeout = 30;
  fwInstallationManager_wait(false, manager, commandLine, timeout, isExpired, host, port, user, pwd);
  if(isExpired)
  {
    fwInstallation_throw("fwInstallationManager_remove(): Failed to stop manager " + manager + " "
                         + commandLine + " within " + timeout + " sec. Action aborted", "error", 1);
    return -1;
  }

  // Check that all the managers starting from the selected one are stopped
  dyn_int diManPos;
  dyn_string dsManager, dsCommandLine;

  dyn_dyn_mixed managersInfo;
  if(fwInstallationManager_pmonGetManagers(managersInfo, host, port, user, pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_remove(): Failed to get managers from PMON to check if all " +
                         "managers that follows " + manager + " " + commandLine + " manager in console " +
                         "are stopped. Action aborted", "error", 1);
    return -1;
  }
  diManPos = managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  dsManager = managersInfo[FW_INSTALLATION_MANAGER_TYPE];
  dsCommandLine = managersInfo[FW_INSTALLATION_MANAGER_OPTIONS];
  
  string removalBlockingManagers = "";
  for(int i = index + 1; i <= dynlen(dsManager); i++) // +1 because the index starts at 0
  {
    bool isStopped;
    res = fwInstallationManager_isStopped(dsManager[i], dsCommandLine[i], isStopped, host, port, user, pwd);
    if(res == -1)
    {
      fwInstallation_throw("fwInstallationManager_remove(): Failed to check if manager " + dsManager[i] + " " +
                           dsCommandLine[i] + " is stopped. This information is required before an attempt " +
                           "to remove manager " + manager + "  " + commandLine + ". Action aborted",
                           "error", 1);
      return -1;
    }
    if(!isStopped)
    {
      removalBlockingManagers = removalBlockingManagers + dsManager[i] + " " + dsCommandLine[i] + ", ";
    }
  }
  if(removalBlockingManagers != "")
  {
    removalBlockingManagers = strrtrim(removalBlockingManagers, ", ");
    fwInstallation_throw("fwInstallationManager_remove(): Cannot remove manager " + manager + " " +
                         commandLine + " as there are running managers on the console's list that are below " +
                         "this manager. Ensure that following managers are stopped and try again: " +
                         removalBlockingManagers, "error", 1);
    return -1;
  }

  // Remove selected manager
  string cmd = user + "#" + pwd + "#SINGLE_MGR:DEL " + index;
  if(pmon_command(cmd, host, port, false, true))
  {
    fwInstallation_throw("fwInstallationManager_remove(): Cannot remove the manager, pmon command failed",
                         "ERROR");
    return -1;
  }
  return 0;
}
