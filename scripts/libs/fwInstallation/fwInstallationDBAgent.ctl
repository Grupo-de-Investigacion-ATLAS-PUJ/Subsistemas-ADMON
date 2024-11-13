// $License: NOLICENSE


/**@file
 *
 * This library contains builds on top of fwInstallation.ctl and fwInstallationDB.ctl
 * and it contains the functions called by the DB-Agent of the FW Comonent Installation Tool
 * for the synchronization of the contents of the local project and of the System Configuration DB. 
 * The functions in this library are not intended to be called from user scripts
 *
 * @author Fernando Varela Rodriguez (EN-ICE)
 * @version 3.3.10
 * @date   April 2007
 */
#uses "fwInstallation/fwInstallation.ctl"
#uses "fwInstallation/fwInstallationDB.ctl"
#uses "fwInstallation/fwInstallationRedu.ctl"
#uses "CtrlPv2Admin"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string gFwInstallationAgentLibVersion = "9.1.3";
const string gFwInstallationAgentLibTag = "";

/**
 * @name fwInstallationDB.ctl: Definition of variables

   The following variables are used by the fwInstallationDB.ctl library

 * @{
 */
//Project status:
const int FW_INSTALLATION_DB_PROJECT_OK = 1;
const int FW_INSTALLATION_DB_PROJECT_MISSMATCH = 0;
const int FW_INSTALLATION_DB_PROJECT_NEVER_CHECKED = -1;
const int FW_INSTALLATION_DB_PROJECT_DISABLED = -2;

//
const int FW_INSTALLATION_DB_STATUS_PVSS_INFO = 1;
const int FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO = 2;
const int FW_INSTALLATION_DB_STATUS_HOST_INFO = 3;
const int FW_INSTALLATION_DB_STATUS_PROJECT_INFO = 4;
const int FW_INSTALLATION_DB_STATUS_PATH_INFO = 5;
const int FW_INSTALLATION_DB_STATUS_MANAGER_INFO = 6;
const int FW_INSTALLATION_DB_STATUS_GROUP_INFO = 7;
const int FW_INSTALLATION_DB_STATUS_COMPONENT_INFO = 8;
//const int FW_INSTALLATION_DB_STATUS_EXT_PROCESS_INFO = 9;
const int FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO = 9;
//const int FW_INSTALLATION_DB_STATUS_REDU_INFO = 10;
const int FW_INSTALLATION_DB_STATUS_PROJ_FILE_ISSUES = 10;
const int FW_INSTALLATION_DB_STATUS_DEV_AND_APPS = 11;

const string csFwInstallationDBAgentLibVersion = "3.4.2";

const int FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX = 3;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SOURCEDIR_IDX = 4;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX = 5;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX = 6;
const int FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX = 7;
const int FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX = 8;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX = 9;
const int FW_INSTALLATION_DB_PVSS_INSTALL_GROUP_IDX = 10;

const int FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_DELETE_VERSION_IDX = 2;

const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_GROUP_IDX = 4;

const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_GROUP_IDX = 4;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_DESCFILE_IDX = 5;

const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_DESCFILE_IDX = 4;
const int FW_INSTALLATION_DB_REINSTALL_RESTART_PROJECT_IDX = 5;
const int FW_INSTALLATION_DB_REINSTALL_OVERWRITE_FILES_IDX = 6;


const int FW_INSTALLATION_DB_AGENT_SYNC_PROJ_PATHS = 1;
const int FW_INSTALLATION_DB_AGENT_SYNC_PROJ_MANAGERS = 2;
const int FW_INSTALLATION_DB_AGENT_SYNC_DIST_PEERS = 3;
const int FW_INSTALLATION_DB_AGENT_SYNC_COMP_FILE_ISSUES = 4;
const int FW_INSTALLATION_DB_AGENT_SYNC_REDU_CONF = 5;
const int FW_INSTALLATION_DB_AGENT_SYNC_DEV_AND_APPS = 6;
const int FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LEN = 6;

const string FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_DPE = ".synchronizedComponents";
const string FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LOCAL_DPE = FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_DPE + ".enabledInLocal";
const string FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_CENTRAL_DPE = FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_DPE + ".enabledInCentral";

const string FW_INSTALLATION_DB_AGENT_WMIC_CMD = "%SystemRoot%/system32/wbem/wmic";

//@} // end of constants

///Beginning of executable code:
int fwInstallationDbAgent_terminateOldInstances()
{
  dyn_int alienpids = fwInstallationDBAgent_getOldInstancesPid();
  for(int i=1;i<=dynlen(alienpids);i++){
    fwInstallation_throw("Previous instance of the FW Installation Tool DB-Agent found with PID=" +
                         alienpids[i] + ". This process will be terminated now...", "INFO", 10);
    string command =FW_INSTALLATION_DB_AGENT_WMIC_CMD + " PROCESS where (" +
                    "commandline like \"%" + FW_INSTALLATION_DB_AGENT_MANAGER_CMD + "%\" and " +
                    "name=\""+fwInstallation_getWCCOAExecutable("ctrl")+".exe\" and " +
                    "processId='"+alienpids[i]+"'" +
                    ") delete ";
    string output, err;
    system(command, output, err);
    output = strltrim(strrtrim(output));
    err = strltrim(strrtrim(err));
    if(err != ""){
      fwInstallation_throw("Failed to terminate previous instance of DB-Agent with PID = " + alienpids[i] +
                           ". System command returned: '" + err + "'; Proceeding anyway", "WARNING", 10);
    }else if(output != ""){
      dyn_string lines = fwInstallation_splitLines(output);
      fwInstallation_throw("Previous instance of the FW Installation Tool DB-Agent with PID = " + alienpids[i] +
                           " terminated. System command returned: '" + lines[dynlen(lines)] + "'", "INFO");
    }
  }
  return 0;
}

dyn_int fwInstallationDBAgent_getOldInstancesPid()
{
  const string cmd = FW_INSTALLATION_DB_AGENT_WMIC_CMD + " PROCESS  where \"" +
                     "name='" + fwInstallation_getWCCOAExecutable("ctrl")+".exe' and "
                     "commandline like '%" + FW_INSTALLATION_DB_AGENT_MANAGER_CMD + "%' and " +
                     "(commandline like '%-PROJ \\\"" + PROJ + "\\\"%' or" +
                     " commandline like '%-PROJ " + PROJ + " %')"
                     "\" get creationDate, processId";
  string output, err;
  int retVal = system(cmd, output, err);
  err = strltrim(strrtrim(err));
  if(err != ""){
    fwInstallation_throw("DB Agent check for other instances could not find any (including own one). " +
                         "System command returned: '" + err + "'; Can proceed anyway", "WARNING", 10);
  }
  dyn_string lines = fwInstallation_splitLines(output);

  dynRemove(lines, 1); // remove header line
  dynRemove(lines, dynlen(lines)); // remove last, empty line
  dynRemove(lines, dynlen(lines)); // remove line containing manager's own process (wmic output is ordered by creation time)

  dyn_int runningPids;
  int linesLen = dynlen(lines);
  for(int i=1;i<=linesLen;i++){
    string line = strrtrim(lines[i]);
    int pidPos = regexpIndex("[0-9]+$", line);
    int pid;
    sscanf(substr(line, pidPos), "%d", pid);
    if(pid > 0){
      dynAppend(runningPids, pid);
    }
  }
  return runningPids;
}

/** This function executes all pending reinstallation actions for the project
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_executeProjectPendingReinstallations(int &restartProject)
{
  string project = PROJ;
  string host = fwInstallation_getHostname();
  dyn_dyn_mixed reinstallationsInfo;
  string component;
  bool status;
  string dontRestartProject;
  int error = 0;
  dyn_int xmlRestart = 0;
  int restartRequired = 0;
  
  fwInstallationDB_getProjectPendingReinstallations(host, project, reinstallationsInfo);
  if(dynlen(reinstallationsInfo) <= 0)//nothing to be done
    return 0;
    
  for(int i = 1; i <= dynlen(reinstallationsInfo); i++)
  {
    string descFile = fwInstallationDBAgent_getComponentFile(reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_DESCFILE_IDX]);
    string sourceDir = fwInstallation_getComponentPath(descFile);
    
    fwInstallation_throw("DB Agent re-installing component from XML file: " + descFile, "INFO", 10);
    fwInstallation_installComponent(descFile,
                                    sourceDir,
                                    reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_SUBCOMP_IDX],
                                    component,
                                    status,
                                    dontRestartProject,
                                    "",
                                    false,
                                    reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_OVERWRITE_FILES_IDX],
                                    true,
                                    false);
 
    //Unregister this installation:
    fwInstallationDB_unregisterProjectReinstallation(host, project, reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_NAME_IDX], reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_VERSION_IDX]);    
       
    //Check if component installation requires to restart the project:
    if(reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_RESTART_PROJECT_IDX] == 1)
      restartRequired = 1;

     if(strtolower(dontRestartProject) == "yes")
       dynAppend(xmlRestart, 0);
      
     if(!status)
       ++error;
  }//end of loop over components.
  
  fwInstallation_trackDependency_clear(); // ensure that dependency tracking mapping is cleared after installations are finished.
  
  //Check if restart project is necessary:
  if(restartProject != 1) //restartProject == 1 means that the function was called with the option to force project restart.
  {
    if(dynContains(xmlRestart, 1) <= 0 ) //None of the reinstalled components requires a project restart
      restartProject = 2; //make sure the post-install scripts run
    
    if(restartRequired == 1)
    {
      restartProject = 1;    //At least one of the reinstallations required to restart the project.
    }
  }
  
  if(error)
    return -1;
  
  return 0; 
}

/** This function sets the synchronization lock, i.e. a kind of semaphore to ensure 
    that not concurrent installation are performed by the agent and the main panel of the installation tool.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_setSynchronizationLock()
{
  return dpSet("fwInstallation_agentParametrization.lock", 1);   
}

/** This function releases the synchronization lock.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_releaseSynchronizationLock()
{
  
  return dpSet("fwInstallation_agentParametrization.lock", 0);   
}

/** This function returns the current value of the synchronization lock
  @return 1 if the lock is set, 0 if unset
*/
int fwInstallationDBAgent_getSynchronizationLock()
{
  int lock;
  
  while(lock){
    dpGet("fwInstallation_agentParametrization.lock", lock);  
    delay(0, 500);
  }
  
  fwInstallationDBAgent_setSynchronizationLock();  
  
  return lock;
}

/** This function writes to the System Configuration DB result of the synchronization process
  @param status array of flags indicating the result of each of the steps performed during the synchronization process
  @param projectName Name of the project
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_setProjectStatus(string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

   int project_id, computer_id;
          
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);


  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0 || 
     fwInstallationDB_isPCRegistered(computer_id, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Cannot access the DB. Please check connection");
    return -1;       
  }
  else if(project_id == -1 || computer_id == -1)
  {
    fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Project: " + projectName + " in computer: " + computerName + " not registered in DB.");
    return -1;      
  }
  else
  {
    dyn_mixed dbInfo, pvssInfo;
    fwInstallationDBAgent_checkComponents(gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO], dbInfo, pvssInfo);
    
    dyn_mixed var;
    var[1] =  gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO];
    var[2] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO];
    var[3] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO];
    var[4] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO];
    var[5] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO];
    var[6] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO];
    var[7] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO];
    var[8] = gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO];
    var[9] = project_id;
    var[10] = computer_id;
    sql = "UPDATE fw_sys_stat_project_status SET is_project_ok = :1, is_pvss_ok = :2, is_patch_ok = :3, " + 
          "is_host_ok = :4, is_path_ok = :5, is_manager_ok = :6, is_component_ok = :7, "  + 
          "is_dist_peers_ok = :8, last_time_checked = SYSDATE WHERE project_id = :9 and computer_id = :10 "; 
    
    if(fwInstallationDB_execute(sql, var)) {fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Could not execute the following SQL: " + sql); return -1;};
  }      
  
  return dpSet("fwInstallation_agentParametrization.db.projectStatus", gFwInstallationDBAgentStatus);
}

/** Check if project files issues synchronization/checking is enabled.
  This is done by reading a proper data point.
  @return True if file issue synchronization is enabled, false if not.
*/
bool fwInstallationDBAgent_isSyncProjectFileIssuesEnabled()
{
  bool isSyncDisabled = false; // Set the (safer) default here.
  string syncDisabledDp = fwInstallation_getAgentDp() + "." + fwInstallation_getFileIssuesSyncDpElem();
  
  if(dpExists(syncDisabledDp))
  {
    dpGet(syncDisabledDp, isSyncDisabled);
  }
  
  return !isSyncDisabled;
}

/** Sets synchronization of files issues. This is done by writing a boolean
  value to a datapoint.
  @param enable what value should be written to datapoint, false - file issue
                synchronization is disabled, true - file issue synchronization
                is enabled.
*/
void fwInstallationDBAgent_setSyncProjectFileIssues(bool enable)
{
  string syncDisabledDp = fwInstallation_getAgentDp() + "." + fwInstallation_getFileIssuesSyncDpElem();
  
  if(dpExists(syncDisabledDp))
  {
    dpSet(syncDisabledDp, !enable);
  }
}


/** This function synchronizes the contents of the System Configuration DB and of the local project
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @return 0 if OK, -1 if errors
*/

int fwInstallationDBAgent_synchronize(int &restartProject)
{
gFwInstallationDbQueriesCnt = 0;
    //Check if synchronization is necessary: if it is not, delay 
    if( !fwInstallationDBAgent_getForceFullSync() ) {
      int project_id;
      bool needsSynchronize = true;
      if(  fwInstallationDB_needsSynchronize(project_id,needsSynchronize) != 0 ) {
        fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize host information with DB");
      } else {
        if ( needsSynchronize == false ) {
          } else {
            fwInstallationDBCache_clear();
          }
      }
    }
    
  int error=0;
  
  if(!globalExists("gFwInstallationDBAgentStatus")) 
    addGlobal("gFwInstallationDBAgentStatus", DYN_INT_VAR);
  
  while(!globalExists("gFwInstallationDBAgentStatus"))
  {
    delay(0, 100);
  }
	
  dynClear(gFwInstallationDBAgentStatus);

  if(!globalExists("gFwInstallationDBAgentSetSplit"))  // boolean indicating whether the agent should set redundancy after the sync
    addGlobal("gFwInstallationDBAgentSetSplit", BOOL_VAR);
  
  while(!globalExists("gFwInstallationDBAgentSetSplit"))
  {
    delay(0, 100);
    gFwInstallationDBAgentSetSplit = false;
  }
  //InitializeCache (Moved into fwInstallationAgentConsistencyChecker)

  //Call to synchronization functions:  
  if(fwInstallationDBAgent_synchronizeHostInfo() != 0){
    ++error;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] = 0;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize host information with DB");
  }
  else
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] = 1;

  // Sync WinCC OA setup information
  if(fwInstallationDBAgent_synchronizePvssSetupInfo() != 0){
    ++error;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] = 0;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] = 0;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize PVSS information with DB");
  }
  else
  {
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] = 1;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] = 1;
  }

  // Sync project information  
  if(fwInstallationDBAgent_synchronizeProjectInfo() != 0){
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] = 0;
    ++error;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project information with DB");
  }
  else
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] = 1;
      
  // Sync project paths
  switch(fwInstallationDBAgent_synchronizeProjectPaths()){
    case 0: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] = FW_INSTALLATION_DB_PROJECT_OK; break;
    case FW_INSTALLATION_DB_PROJECT_DISABLED: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] = FW_INSTALLATION_DB_PROJECT_DISABLED; break;
    default:
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
      ++error;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project paths with DB");
  }

  // Sync project managers
  switch(fwInstallationDBAgent_synchronizeProjectManagers()){
    case 0: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] = FW_INSTALLATION_DB_PROJECT_OK; break;
    case FW_INSTALLATION_DB_PROJECT_DISABLED: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] = FW_INSTALLATION_DB_PROJECT_DISABLED; break;
    default:
      ++error;
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project managers with DB");
  }

  // Sync project components
  if(fwInstallationDBAgent_synchronizeProjectComponents(restartProject) != 0){
    ++error;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] = 0;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project FW components");
  }
  else
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] = 1;

  // Sync dist peers
  switch(fwInstallationDBAgent_synchronizeDistPeers()){
    case 0: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] = FW_INSTALLATION_DB_PROJECT_OK; break;
    case FW_INSTALLATION_DB_PROJECT_DISABLED: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] = FW_INSTALLATION_DB_PROJECT_DISABLED; break;
    default:
      ++error;
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize list of dist peers with DB");
  }

  // Sync redu information 
  switch(fwInstallationDBAgent_synchronizeReduInfo()){
    case 0: /*gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] = FW_INSTALLATION_DB_PROJECT_OK;*/ break;
    case FW_INSTALLATION_DB_PROJECT_DISABLED: /*gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] = FW_INSTALLATION_DB_PROJECT_DISABLED;*/ break;
    default:
      ++error;
      //gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize redundant info with DB");
  }

  // Sync WinCC OA (UNICOS) applications and devices
  switch(fwInstallationDBAgent_synchronizeWCCOAApplicationsAndDevices()){
    case 0: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DEV_AND_APPS] = FW_INSTALLATION_DB_PROJECT_OK; break;
    case FW_INSTALLATION_DB_PROJECT_DISABLED: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DEV_AND_APPS] = FW_INSTALLATION_DB_PROJECT_DISABLED; break;
    default:
    /*++error;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize WinCC OA applications " +
                         "and devices with DB"); //This will not be treated as error for now to maintain a kind of compatibility with db schema 5.1.4
						                           //Note: This code should be restored after enforcing usage of db schema 5.1.7 or higher
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DEV_AND_APPS] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
    */
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Problem occured during synchronization of WinCC OA applications " +
                         "and devices with DB, see log for details", "WARNING", 9);
  }

  // Sync file issues
  if(fwInstallationDBAgent_isSyncProjectFileIssuesEnabled())
  {
    switch(fwInstallationDBAgent_synchronizeProjectFileIssues()){
      case 0: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJ_FILE_ISSUES] = FW_INSTALLATION_DB_PROJECT_OK; break;
      case FW_INSTALLATION_DB_PROJECT_DISABLED: gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJ_FILE_ISSUES] = FW_INSTALLATION_DB_PROJECT_DISABLED; break;
      default:
        ++error;
        gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJ_FILE_ISSUES] = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
        fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project file issues with DB");
    }
  }else{
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJ_FILE_ISSUES] = FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
 
  //export current project component list:
  if(fwInstallationDB_registerProjectFwComponents() != 0)
  {
    fwInstallation_throw("fwInstallationAgentDBConsistencyChecker -> Could not export current project component list. Check DB connection...");
  } 
  
  //Write the result of the synchronization process to the db
  if(fwInstallationDBAgent_setProjectStatus() != 0)  
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not verify PVSS-DB data consistency.");
    ++error;
  }
  
  if (globalExists("gFwInstallationProjectJustRegistered"))
    removeGlobal("gFwInstallationProjectJustRegistered");
  
  //Synchronization is done, does not need any more, until change triggered on the DB
  fwInstallationDB_setNeedsSynchronize(false);      
  
//DebugN("End of sync, number of queries was: " + gFwInstallationDbQueriesCnt);
  gFwInstallationDbQueriesCnt = 0;

  if (gFwInstallationDBAgentSetSplit) 
  {
    bool splitForced;
    string pairToKeep;

    _fwInstallationRedu_getSplitInfo(splitForced, pairToKeep);
    if (splitForced && pairToKeep != "" && fwInstallation_getRestoreRedundancyAfterInstallation() == 1)
    {
      fwInstallation_throw("Re-enabling redundancy", "INFO");
      _fwInstallationRedu_setSplitInfo(0, "");
      fwInstallationRedu_setReduSplitOff(getSystemName(), false, pairToKeep);
    }
  }
  //fwInstallationDB_storeInstallationLog();
  if(error){
    fwInstallation_throw("PVSS-System Configuration DB synchronization finished with errors");
    return -1;
  }
  else{
    return 0;  
  }
}

/** This function retrieves from the System Configuration DB the current status of the syncrhonization process
  @param syncStepsStatus array of flags indicating the result of each of the steps performed during the synchronization process
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkIntegrity()
{
  string dbPvssVersion;
  string dbPvssOs;
  string pvssPvssVersion;
  string pvssPvssOs;
  dyn_string dbPatches;
  dyn_string pvssPatches;
  dyn_string dbIps;
  dyn_string pvssIps;
  dyn_string dbPaths;
  dyn_string pvssPaths;
  dyn_dyn_mixed dbManagersInfo;
  dyn_dyn_string pvssManagersInfo;
  dyn_mixed dbSystem;
  
  dyn_dyn_mixed dbComponentsInfo;
  dyn_dyn_mixed pvssComponentsInfo;
  dyn_mixed dbHostInfo;
  dyn_mixed dbPvssInfo;
  dyn_mixed dbProjectInfo;
  dyn_mixed pvssProjectInfo;
  dyn_mixed dbExtProcessInfo;
  dyn_mixed pvssExtProcessInfo;
  int status;
  int error = 0;
  
  dyn_string onlyPvssSystemNames, onlyDbSystemNames, onlyPvssComputerNames, onlyDbComputerNames;
  dyn_int onlyPvssSystemNumbers, onlyDbSystemNumbers;
  
  //dynClear(syncStepsStatus);
  
  //TODO check with FV if this is supposed to be done (commented out on newer version, with fewer argumentS).. 
  // check the need for status as well.
  //if(fwInstallationDBAgent_checkProjectPvssInfo(status, dbPvssInfo, pvssPvssVersion, pvssPvssOs) != 0)
  if(fwInstallationDBAgent_checkProjectPvssInfo(status, dbPvssInfo, pvssPvssVersion) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for PVSS setup info");
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] =  status; 
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(status, dbPatches, pvssPatches) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for PVSS patch level");
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] =  status; 
  
  if(fwInstallationDBAgent_checkHostInfo(status, dbHostInfo, pvssIps) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for host: " + strtoupper(fwInstallation_getHostname()));
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] =  status; 
  
  if(fwInstallationDBAgent_checkProjectInfo(status, dbProjectInfo, pvssProjectInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project: " + PROJ);
     ++error;     
  }
  
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] =  status; 
  
  if(fwInstallationDBAgent_checkProjectPathsInfo(status, dbPaths, pvssPaths) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project paths");
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] =  status; 
  
  if(fwInstallationDBAgent_checkProjectManagersInfo(status, dbManagersInfo, pvssManagersInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project managers");
     ++error;     
  }
 // syncStepsStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] =  status; 

  if(fwInstallationDBAgent_checkComponents(status, dbComponentsInfo, pvssComponentsInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for FW components");
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] =  status; 

  if(fwInstallationDBAgent_checkDistPeers(status, onlyPvssSystemNames, onlyDbSystemNames, onlyPvssComputerNames, onlyDbComputerNames, onlyPvssSystemNumbers, onlyDbSystemNumbers) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for FW components");
     ++error;     
  }
  //syncStepsStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] =  status; 

  
  //Set project status:
  /*if(fwInstallationDBAgent_setProjectStatus(syncStepsStatus) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not set project status in DB.");
     ++error;     
  }*/
  
  if(error)
    return -1;
  else
    return 0;  
}



/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the PVSS setup information
  @param status 1 if DB and local project information is in sync, 0 when not
  @param dbPvssInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPvssInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
  
  TODO: Check with FV if this is supposed to remain. Activating for now, commented out on last version.
*/

/*int fwInstallationDBAgent_checkProjectPvssInfo(int &status, dyn_mixed &dbPvssInfo, dyn_mixed &pvssPvssInfo)
{
  
  string project = PROJ;  
  string hostname = fwInstallation_getHostname();    
  
  hostname = strtoupper(hostname);
  
  pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] = VERSION_DISP;
  
  if(_WIN32)
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "WINDOWS";
  else
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "LINUX";
  
  
  dyn_dyn_mixed dbHostPvssInfo; //contains all pvss versions and os in the host
  if(fwInstallationDB_getHostPvssVersions(dbHostPvssInfo)!=0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectPvssInfo() -> Could not retrieve PVSS info from DB for host: " + hostname);
    return -1;
  }//end of if

  //Check that everything is ok:  
  status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  for(int i = 1; i <= dynlen(dbHostPvssInfo); i++)
  {
    if(dynlen(dbHostPvssInfo[i]) >= 2 ) 
    {
      if(dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] == pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] 
       && dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] == pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] ) 
      {
        dbPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX]= dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX];
        dbPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX]= dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_OS_IDX];
        status = FW_INSTALLATION_DB_PROJECT_OK;
        break;
      }
    }
  }
  return 0;  
}
*/

int fwInstallationDBAgent_checkProjectPvssInfo(int &status, dyn_mixed &dbPvssInfo, dyn_mixed &pvssPvssInfo)
{
  string project = PROJ;  
  string hostname = fwInstallation_getHostname();    
  
  hostname = strtoupper(hostname);
  
  pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] = VERSION_DISP;
  
  if(_WIN32)
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "WINDOWS";
  else
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "LINUX";
    
  if(fwInstallationDB_getProjectPvssInfo(project, hostname, dbPvssInfo) != 0) {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectPvssInfo() -> Could not retrieve PVSS info from DB for project: " + project);
    return -1;
  }//end of if
  
  //Check that everything is ok: 
  status = (dbPvssInfo == pvssPvssInfo)?FW_INSTALLATION_DB_PROJECT_OK:FW_INSTALLATION_DB_PROJECT_MISSMATCH;
 
  return 0;  
}


/** This function checks the consistency of the PVSS version information
  @param status 1 if DB and local project information is in sync, 0 when not
  @param dbPvssVersions PVSS information in the system configuration DB as a dyn_string array
  @param pvssPvssVersions PVSS information from the local host
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkHostPvssInfo(int &status, dyn_string &dbPvssVersions, dyn_string &pvssPvssVersions)
{
  string project = PROJ;  
  dyn_dyn_mixed dbPvssInfo;
  string hostname = strtoupper(fwInstallation_getHostname());    

  pvssPvssVersions = fwInstallation_getHostPvssVersions();
  for(int i = 1; i <= dynlen(pvssPvssVersions); i++)
    if(pvssPvssVersions[i] == VERSION)
      pvssPvssVersions[i] = VERSION_DISP;

  fwInstallationDB_getHostPvssVersions(dbPvssInfo);
  
  for(int i = 1; i <= dynlen(dbPvssInfo); i++)
    dynAppend(dbPvssVersions, dbPvssInfo[i][1]);

  dynSortAsc(pvssPvssVersions);  
  dynSortAsc(dbPvssVersions);  
  
  status = (pvssPvssVersions == dbPvssVersions)?FW_INSTALLATION_DB_PROJECT_OK:FW_INSTALLATION_DB_PROJECT_MISSMATCH;

  return 0;  
}


/** This function updates the contents of the System Configuration DB for the PVSS setup information
  @return 0 if OK, -1 if errors
*/
/*
int fwInstallationDBAgent_synchronizePvssSetupInfo()
{
  bool patchesOk, pvssOk;
  dyn_string pvssPatches, dbPatches;
  dyn_mixed dbPvssInfo, pvssPvssInfo;

  if(fwInstallationDBAgent_checkProjectPvssInfo(pvssOk, dbPvssInfo, pvssPvssInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to compare the host PVSS versions.");
    return -1;
  } 

  if(!pvssOk)
  {
	   //gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();


    if(fwInstallationDB_unregisterAllHostPvssVersions() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to remove the previous PVSS versions from the DB.");
      return -1;
    }
    
    if(fwInstallationDB_registerProjectPvssVersion() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update the host PVSS versions in the DB.");
      return -1;
    }
  }
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(patchesOk, dbPatches, pvssPatches) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve list of PVSS patches from PVSS and DB.");
    return -1;
  } 

  if(!patchesOk)
  {
    //gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();
    if(fwInstallationDB_registerPvssSetup() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update PVSS setup info in DB.");
      return -1;
    }
  }
  

  return 0;  
  
}
*/

int fwInstallationDBAgent_synchronizePvssSetupInfo()
{
  int pvssStatus, patchesStatus;
  dyn_mixed dbPvssInfo, pvssPvssInfo;
  dyn_string pvssPatches, dbPatches;
    
  if(fwInstallationDBAgent_checkProjectPvssInfo(pvssStatus, dbPvssInfo, pvssPvssInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve PVSS info from PVSS and DB.");
    return -1;
  } 
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(patchesStatus, dbPatches, pvssPatches) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve list of PVSS patches from PVSS and DB.");
    return -1;
  } 
  if(pvssStatus != FW_INSTALLATION_DB_PROJECT_OK || patchesStatus != FW_INSTALLATION_DB_PROJECT_OK)
  {
    if(fwInstallationDB_registerPvssSetup() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update PVSS setup info in DB.");
      return -1;
    }
  }

  return 0;
}
/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the PVSS patches information
  @param status 1 if DB and local project information is in sync for patches, 0 when not
  @param dbPatches PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPatches PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectPvssPatchesInfo(int &status, dyn_string &dbPatches, dyn_string &pvssPatches)
{
  string hostname = fwInstallation_getHostname();    

  string os = (_WIN32)?"WINDOWS":"LINUX";
  string version = VERSION_DISP;

  hostname = strtoupper(hostname);

  fwInstallationDB_getPatchList(hostname, version, os, dbPatches);
  fwInstallation_getPvssVersion(pvssPatches);

  //Check that everything is ok:  
  dynSortAsc(dbPatches);
  dynSortAsc(pvssPatches);

  status = (dbPatches == pvssPatches)?FW_INSTALLATION_DB_PROJECT_OK:FW_INSTALLATION_DB_PROJECT_MISSMATCH;

  return 0;  
}

/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the host information
  @param status 1 if DB and local project information is in sync for patches, 0 when not
  @param dbHostInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssHostInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkHostInfo(int &status, dyn_mixed &dbHostInfo, dyn_mixed &pvssHostInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    

  if(fwInstallationDB_getHostProperties(hostname, dbHostInfo) != 0) // DB host properties
  {
    fwInstallation_throw("fwInstallationDBAgent_checkHostInfo() -> Could not list of properties of host: " + hostname + " from DB.");
    return -1;
  } 
  fwInstallation_getHostProperties(hostname, pvssHostInfo); // Local host properties

  // Check if we have some discrepancies between DB and local data.
  if(dynlen(dbHostInfo) >= 2 && 
     dbHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] && 
     dbHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] &&
     dbHostInfo[FW_INSTALLATION_DB_HOST_WCCOA_INSTALL_PKG_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_WCCOA_INSTALL_PKG_IDX] &&
     dbHostInfo[FW_INSTALLATION_DB_HOST_CPU_INFO_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_CPU_INFO_IDX] &&
     dbHostInfo[FW_INSTALLATION_DB_HOST_MEM_SIZE_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_MEM_SIZE_IDX] &&
     dbHostInfo[FW_INSTALLATION_DB_HOST_FMC_INSTALL_PKG_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_FMC_INSTALL_PKG_IDX])
    status = FW_INSTALLATION_DB_PROJECT_OK;
  else
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;

  return 0;  
}


int fwInstallation_synchronizeHostPvssVersions()
{
  dyn_string pvssPvssVersions = fwInstallation_getHostPvssVersions();
  dyn_dyn_mixed dbPvssVersionsInfo;
  fwInstallationDB_getHostPvssVersions(dbPvssVersionsInfo);
  
  //Remove from the DB versions that are not installed any longer:
  for(int i = 1; i <= dynlen(dbPvssVersionsInfo); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(pvssPvssVersions); j++)
    {
      if(patternMatch(pvssPvssVersions[j] + "*", dbPvssVersionsInfo[i][1]) > 0)
      {
        found = true;
        break;
      }
    }
    if(!found)
    {
      string host = strtoupper(fwInstallation_getHostname());
      fwInstallation_throw("PVSS version: " + dbPvssVersionsInfo[i][1] + " no longer installed in host: " + host + ". Unregistering it from the DB now...", "INFO", 10);
      if(fwInstallationDB_unregisterHostPvssVersion(host, dbPvssVersionsInfo[i][1], dbPvssVersionsInfo[i][2]))
      {
        fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to unregister old PVSS versions from the DB: " + dbPvssVersionsInfo[i][1]);
      }
    }
  }

  return 0;
}  


/** This function updates the contents of the System Configuration DB for the host information
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_synchronizeHostInfo()
{
  int status;
  dyn_mixed dbHostInfo, pvssHostInfo;
  
  //syncrhonize host pvss versions:
  if(fwInstallation_synchronizeHostPvssVersions())
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeHostInfo() -> Failed to synchronize the host PVSS versions");
    return -1;
  }
  
  if(fwInstallationDBAgent_checkHostInfo(status, dbHostInfo, pvssHostInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeHostInfo() -> Could not retrieve host info from PVSS and DB.");
    return -1;
  } 
  if(status == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }
  //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();

  if(fwInstallationDB_setHostProperties(strtoupper(fwInstallation_getHostname()), pvssHostInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update host info in DB.");
    return -1;
  }

  return 0;  
  
}

/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the project information
  @param status 1 if DB and local project information is in sync for patches, 0 when not
  @param dbProjectInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssProjectInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectInfo(int &status, dyn_mixed &dbProjectInfo, dyn_mixed &pvssProjectInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  int projectId;

  if(fwInstallationDB_getProjectProperties(project, hostname, dbProjectInfo, projectId) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of project: " + project + " from DB.");
    return -1;
  }//end of if
  
  if(fwInstallation_getProjectProperties(pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of project: " + project + " from PVSS.");
    return -1;
  }
  
  if(projectId >0 ) //if project already registered in DB, compare values
  {
    int dbPmon = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PORT];
    int dbData = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA];
    int dbDist= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DIST];
    int dbEvent= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT];
    int dbRedu= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT];
    int dbSplit= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT];
    int instToolStatus = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS];

    if(dynlen(dbProjectInfo) && dbProjectInfo[FW_INSTALLATION_DB_PROJECT_NAME] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_NAME] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] == fwInstallation_getHostname(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST]) &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DIR] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DIR] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] &&
       dbPmon == pmonPort() &&
       dbData == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA] &&
       dbEvent == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] &&
       dbDist == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DIST] &&
       dbRedu == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT] &&
       dbSplit == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER] == 
         fwInstallationDB_fitStringToLength(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER], 32) &&
       instToolStatus == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_OS] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_OS] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST])
    {
      status = FW_INSTALLATION_DB_PROJECT_OK;
    }
    else
    {
      status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;  
    }
  }else{
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;  
  }
  
  dyn_mixed dbSystem;
  dyn_mixed pvssSystem;

  if(status == FW_INSTALLATION_DB_PROJECT_OK)//project info ok, check now system info.
  {
    if(fwInstallationDB_getPvssSystemProperties(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], dbSystem) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of the system: " + pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] + " from DB.");
      return -1;
    }
    
    if(fwInstallation_getPvssSystemProperties(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], pvssSystem) != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not list of properties of project: " + project + " from PVSS.");
      return -1;
    }
    if(dynlen(dbSystem) && 
       dbSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER] == fwInstallation_getHostname(pvssSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER]))
    {
      status = FW_INSTALLATION_DB_PROJECT_OK;
    }
    else
    {
      status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;  
    }
  }

  return 0;  
}

/** This function checks the consistency between the current project file issues and the contents of the 
    System Configuration DB for the project file issues
  @param status 1 if DB and local project file issues information is in sync, 0 when not, -2 when synchronization is disabled
  @param dbProjectFileIssues File issues information in the system configuration DB as a dyn_dyn_mixed array
  @param pvssProjectFileIssues File issues information from the local project
  @return 0 if OK, -1 if errors
*/ 
int fwInstallationDBAgent_checkProjectFileIssues(int &status, dyn_dyn_mixed &dbProjectFileIssues, dyn_dyn_mixed &pvssProjectFileIssues)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  int projectId;
  
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(false, FW_INSTALLATION_DB_AGENT_SYNC_COMP_FILE_ISSUES))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  
  if(fwInstallationDB_getProjectFileIssues(dbProjectFileIssues, project, hostname) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectFileIssues() -> Could not retrieve file issues of project: " + project + " from DB.");
    return -1;
  }
  
  if(fwInstallation_getProjectFileIssues(pvssProjectFileIssues) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectFileIssues() -> Could not retrieve file issues of project: " + project + " from PVSS.");
    return -1;
  }
  
  status = FW_INSTALLATION_DB_PROJECT_OK;
  if (dynlen(dbProjectFileIssues) != dynlen(pvssProjectFileIssues))
  {
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  }
  else //compare whether the arrays contain the same files
  {
    //Check whether all file issues in PVSS are registered in DB (the oppposite is not necessary because of the comparasion of the num of elements)
    for (int i=1; i<=dynlen(pvssProjectFileIssues); i++)
    {
      bool found = false;
      for (int j=1; j<=dynlen(dbProjectFileIssues);j++)
      {
        if(pvssProjectFileIssues[i][FW_INSTALLATION_DB_FILE_ISSUE_COMPONENT] == dbProjectFileIssues[j][FW_INSTALLATION_DB_FILE_ISSUE_COMPONENT] &&
           pvssProjectFileIssues[i][FW_INSTALLATION_DB_FILE_ISSUE_VERSION] == dbProjectFileIssues[j][FW_INSTALLATION_DB_FILE_ISSUE_VERSION] &&
           pvssProjectFileIssues[i][FW_INSTALLATION_DB_FILE_ISSUE_FILENAME] == dbProjectFileIssues[j][FW_INSTALLATION_DB_FILE_ISSUE_FILENAME] &&
           pvssProjectFileIssues[i][FW_INSTALLATION_DB_FILE_ISSUE_TYPE] == dbProjectFileIssues[j][FW_INSTALLATION_DB_FILE_ISSUE_TYPE])
        {
          found = true;
          break;
        }
      }
      if (!found)
      {
        status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
        break;
      }
    }
  }

  return 0;  
}

/** This function updates the contents of the System Configuration DB for the project information
  @return 0 if OK, -1 if errorsfwInstallationDB_registerSystem
*/
int fwInstallationDBAgent_synchronizeProjectInfo()
{
  int status;
  dyn_mixed dbProjectInfo;
  dyn_mixed pvssProjectInfo;
  
  if(fwInstallationDBAgent_checkProjectInfo(status, dbProjectInfo, pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectInfo() -> Could not retrieve project info from PVSS and DB.");
    return -1;
  } 
  
  if(status == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }

  //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();

  if(dynlen(dbProjectInfo) >= FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED)
  {
    int centrally = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED];
    if(centrally)
    {
      pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST];
      pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT] = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT];
      pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST] = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST];
      fwInstallation_setInstallOnlyInSplit(dbProjectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT]);
      fwInstallation_setRestoreRedundancyAfterInstallation(dbProjectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST]);
    }
  }

  if(fwInstallationDB_setProjectProperties(PROJ, strtoupper(fwInstallation_getHostname()), pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectInfo() -> Failed to update project info in DB.");
    return -1;
  }
  
  return 0;  
}

/** This function updates the contents of the System Configuration DB for the file issues
  @return 0 if OK, -1 if error, -2 when synchronization is disabled
*/
int fwInstallationDBAgent_synchronizeProjectFileIssues()
{
  int status;
  dyn_dyn_mixed dbProjectFileIssues;
  dyn_dyn_mixed pvssProjectFileIssues;
  
  if(fwInstallationDBAgent_checkProjectFileIssues(status, dbProjectFileIssues, pvssProjectFileIssues) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectFileIssues() -> Could not retrieve project file issues from PVSS and DB.");
    return -1;
  }
  
  if(status == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }else if(status == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }

  //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();

  if(fwInstallationDB_deleteProjectFileIssues(PROJ, strtoupper(fwInstallation_getHostname())) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectFileIssues() -> Failed to delete old project file issues from DB.");
    return -1;
  }
  
  if(fwInstallationDB_registerProjectFileIssues(pvssProjectFileIssues, PROJ, strtoupper(fwInstallation_getHostname())) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectFileIssues() -> Failed to update project file issues in DB.");
    return -1;
  }

  return 0;  
}


/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the project paths
  @param status 1 if DB and local project information is in sync for patches, 0 when not, -2 when synchronization is disabled
  @param dbPaths PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPaths PVSS information from the local project
  @param checkRequiredTable When true read from fw_sys_stat_inst_path, otherwise from fw_sys_stat_current_inst_path
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectPathsInfo(int &status, 
                                                  dyn_string &dbPaths, 
                                                  dyn_string &pvssPaths,
                                                  bool checkRequiredTable = false)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  dyn_string commonPaths;
  
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(checkRequiredTable, FW_INSTALLATION_DB_AGENT_SYNC_PROJ_PATHS))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  
  dynClear(commonPaths);  
  
  if (checkRequiredTable)
  {
    if(fwInstallationDB_getRequiredProjectPaths(project, hostname, dbPaths) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkProjectPathsInfo() -> Could not list of paths of project: " + project + " from DB.");
      return -1;
    }
  }
  else
  {
     if(fwInstallationDB_getProjectPaths(project, hostname, dbPaths) != 0){
        fwInstallation_throw("fwInstallationDBAgent_checkProjectPathsInfo() -> Could not list of paths of project: " + project + " from DB.");
        return -1;
      }
  }
  
  
  //Rest of the proj_paths:
  fwInstallation_getProjPaths(pvssPaths);
    
  //Check that everything is ok:  
  if(dynlen(pvssPaths) != dynlen(dbPaths))
  {
//DebugN("Different list of project paths, ", pvssPaths, dbPaths);
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
    return 0;
  }
  else
  {
    for(int i = 1; i <= dynlen(pvssPaths); i++)
    {
      bool pathFound = false;
      for(int j = 1; j<= dynlen(dbPaths); j++)
      {
        if(pvssPaths[i] == dbPaths[j])
        {
          pathFound = true;
          break;
        }
      }
      if (!pathFound)
      {
        status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
        return 0;
      }
    }
  }
  status = FW_INSTALLATION_DB_PROJECT_OK;
  return 0;  
}

/** This function synchronizes the list of project paths in the current project and in the
    System Configuration. The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, the contents of the system configuration DB
      are updated with the list of project paths currently defined in the project.
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the list of project paths defined in the local project to reflect the contents of the system configuration DB,
      then updates back the content of system configuration DB
      
  @return 0 if OK, -1 if errors, -2 when synchronization is disabled
*/
int fwInstallationDBAgent_synchronizeProjectPaths()
{
  bool pvssUpdated;
  int status, centralStatus;
  dyn_mixed dbPaths;
  dyn_mixed pvssPaths;
  
  bool isCentrallyManaged = fwInstallationDB_getCentrallyManaged();
  if(isCentrallyManaged){
    if(fwInstallationDBAgent_checkProjectPathsInfo(centralStatus, dbPaths, pvssPaths, true) != 0){
      fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Could not retrieve " +
                           "project info from PVSS and DB.");
      return -1;
    }
    if(centralStatus == FW_INSTALLATION_DB_PROJECT_MISSMATCH && fwInstallationRedu_ensureInstallationConditions()){
      if(fwInstallation_deleteFromConfigFile()){
        // Normalize  paths coming from DB
        if(fwInstallation_normalizePathList(dbPaths)){
          return -1;
        }
        int len1 = dynlen(dbPaths);
        int len2 = dynUnique(dbPaths);
        if(len1 != len2){
          fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> " +
                               "Duplicate paths detected in DB (FW_SYS_STAT_INST_PATH)", "WARNING");
        }
        dynRemove(pvssPaths, dynlen(pvssPaths));
        fwInstallation_deleteProjectPaths(pvssPaths);
        fwInstallation_addProjectPaths(dbPaths);
        pvssUpdated = true;
      }
      else{
        fwInstallation_throw("Synchronization of Project Paths was only partially done - " +
                             "the deletion from config file is not allowed.", "WARNING");
      }
    }
  }
    
  dynClear(dbPaths);
  dynClear(pvssPaths);
  if(!pvssUpdated && fwInstallationDBAgent_checkProjectPathsInfo(status, dbPaths, pvssPaths, false) != 0){
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Could not retrieve " +
                         "project info from PVSS and DB.");
    return -1;
  }

  if(pvssUpdated || status == FW_INSTALLATION_DB_PROJECT_MISSMATCH){
    fwInstallationDBCache_clear();
    if(!isCentrallyManaged &&
       globalExists("gFwInstallationProjectJustRegistered") && gFwInstallationProjectJustRegistered){
      fwInstallationDB_registerRequiredProjectPaths();
    }
    if(fwInstallationDB_registerProjectPaths() != 0 && !pvssUpdated){
      fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Failed to update " +
                           "project paths in DB.");
      return -1;
    }
  }
  if(isCentrallyManaged && centralStatus == FW_INSTALLATION_DB_PROJECT_DISABLED ||
     !isCentrallyManaged && status == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
  return 0;
}


/** This function checks the consistency between the list of project managers 
  in the current project and those registered in the System Configuration DB
  @param status overall result of the consistency check
  @param dbManagersInfo managers information from the database
  @param pvssManagersInfo managers information from the local project
  
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectManagersInfo(int &status,
                                                   dyn_dyn_mixed &dbManagersInfo, 
                                                   dyn_dyn_string &pvssManagersInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  int count = 0;

  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(false, FW_INSTALLATION_DB_AGENT_SYNC_PROJ_MANAGERS))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  
  if(fwInstallationDB_getProjectManagers(dbManagersInfo, project, hostname) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not list of managers of project: " + project + " from DB.");
    return -1;
  }//end of if

  fwInstallationManager_getAllInfoFromPvss(pvssManagersInfo);

  //Check consistency:
  if(dynlen(dbManagersInfo) != dynlen(pvssManagersInfo))
  {
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
    return 0;
  }
  
  for(int i =1 ; i <= dynlen(dbManagersInfo); i++)
  {
    //Find pvss component that matches dbComponent
    for(int j = 1; j <= dynlen(pvssManagersInfo); j++){
      if(pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_NAME_IDX] == dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_NAME_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_START_IDX])
      {
        //We have indentified one manager. Comparing rest of the settings:
        if(dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_START_IDX] &&
           dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX])
        {
          ++count;
          continue;
        }
      }//end of if
    }//end of loop over j    
  }
  status = (count == dynlen(dbManagersInfo))?FW_INSTALLATION_DB_PROJECT_OK:FW_INSTALLATION_DB_PROJECT_MISSMATCH;

  return 0;
}

/** This function updates the contents of the System Configuration DB for the project managers
  @return 0 if OK, -1 if errors, -2 when synchronization is disabled
*/
int fwInstallationDBAgent_synchronizeProjectManagers()
{
  int status;
  dyn_mixed dbManagersInfo;
  dyn_mixed pvssManagersInfo;
  //bool isCentrallyManaged;
  bool found = false;
  
  if(fwInstallationDBAgent_checkProjectManagersInfo(status, dbManagersInfo, pvssManagersInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Could not retrieve project info from PVSS and DB.");
    return -1;
  } 

  if(status == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }else if(status == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
  
	 //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();
  
  if(fwInstallationDB_deleteProjectManagers())  
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Failed to remove from the DB the old list of project managers");
    return -1;
  }
 
 //Add managers that are not registered
  if(fwInstallationDB_registerProjectManagers() != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Failed to update project paths in DB.");
    return -1;
  }
  return 0;  
  
}

/** This function checks the consistency between the list of components 
  currently installed in the local project and those registered in the System Configuration DB
  @param status overall result of the consistency check
  @param dbComponentsInfo components information in the DB
  @param pvssComponentsInfo components information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkComponents(int &status,
                                          dyn_dyn_mixed &dbComponentsInfo,
                                          dyn_dyn_mixed &pvssComponentsInfo)
{
  int count = 0;

  status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  
  fwInstallation_getInstalledComponents(pvssComponentsInfo);
    
  if(fwInstallationDB_getProjectComponents(dbComponentsInfo) != 0){
    fwInstallation_throw(" fwInstallationDBAgent_checkComponents() -> Could not retrieve the list of project FW components from DB."); 
    return -1;
  }
  
  if(dynlen(pvssComponentsInfo) != dynlen(dbComponentsInfo))
    return 0; 
    
  for(int i = dynlen(dbComponentsInfo); i > 0; i--) 
  {
    for(int j = dynlen(pvssComponentsInfo); j > 0; j--) 
    {
      if(dbComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == pvssComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         dbComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == pvssComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        ++count;
      } 
    }
  }
  
  if(count != dynlen(pvssComponentsInfo))
    return 0;
  
  status = FW_INSTALLATION_DB_PROJECT_OK;
  
  return 0;
  
}

/** This function cast a dyn_mixed to an string where the different elements are separated by "|";
  @param request dyn_mixed to be casted
  @return result of the casting operation as string
*/
string fwInstallationDBAgent_stringCastRequest(dyn_mixed request)
{
  string strRequest;
  
  for(int i =1; i <= dynlen(request); i++)
    strRequest += request[i] + "|";
  
  return strRequest;
}

/** This function synchronizes the list of components in the current project and in the
    System Configuration and exports the current list of components installed in the project to the DB.
    The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, no synchronization is done. 
      Only the current list of components in the System Configuration DB 
      is updated with the list of components in the local project.
      
      
    - if the project is centrally managed, the DB-Agent of the installation tool uninstalls 
      and/or uninstalls all components such that the list of components installed in the project
      reflects the contents of the system configuration DB.
      
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run  
       
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_synchronizeProjectComponents(int &restartProject)
{
  if(fwInstallationDB_maxLogSizeExceeded()){
    fwInstallationDB_deleteInstallationLog();
  }
  //export current configuration of the project:
  fwInstallationDB_registerProjectFwComponents();

  bool centrallyManaged = fwInstallationDB_getCentrallyManaged();
  if(!centrallyManaged ){ //Locally managed - nothing to be done at the component level
    restartProject = 0;
    return 0;
  }
  // else - Centrally managed
  int reinstalls = 0;
  dyn_dyn_mixed pvssInstallComponents, pvssDeleteComponents;

  int pendingActionsStatus = fwInstallationDBAgent_getComponentPendingActions(
      restartProject, pvssInstallComponents, pvssDeleteComponents, reinstalls);
  bool hasPendingActions = (pendingActionsStatus == 0 &&
                            (dynlen(pvssInstallComponents) > 0 || dynlen(pvssDeleteComponents) > 0 || reinstalls));

  if(hasPendingActions && fwInstallationRedu_ensureInstallationConditions()){
    gFwInstallationDBAgentSetSplit = false; //we want the redundant mode to be set from the postinstall
    return fwInstallationDBAgent_executeComponentPendingActions(restartProject, pvssInstallComponents, pvssDeleteComponents);
  }
  // else - just check if there are any postinstalls pending to set restartProject flag accordingly
  restartProject = (fwInstallation_arePostInstallsPending())?2:0;

  return pendingActionsStatus;
}

/** This function checks if the post-installation scripts are still running
  @param isRunning TRUE if post-install scripts are still being executed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_isPostInstallRunning(bool &isRunning) 
{
  string manager = fwInstallation_getWCCOAExecutable("ctrl");
  return fwInstallationManager_isRunning(manager, FW_INSTALLATION_SCRIPTS_MANAGER_CMD, isRunning);
}

/** This function returns the path to a description file where any Windows-Linux 
    path mapping is resolved, e.g. from /afs/cern.ch/myComponent.xml -> P:/myComponent.xml
  @param descFile original description file of the component including path
  @return new path to the component description file where possible path mappings have been resolved
*/
string fwInstallationDBAgent_getComponentFile(string descFile)
{

  string fileName = "";
  dyn_string ds;
  string pattern;
  string mappedPath;
  string sourceDir;  
  
  //Check that the description file can be accessed:
  if(access(descFile, R_OK) != 0)
  {
    //the original file is not accessible. 
    //Could it be a problem of the groups being 
    //defined with windows paths and being used 
    //in Linux or the other way around? If so, 
    //let us see if we can resolve the path mapping 
    //from the DB   
    
    if(!fwInstallationDB_getUseDB())  
    {
      //configure not to use the DB.
      return "";
    }

    //Original path is Windows or Linux?
    if(patternMatch("*:*", descFile) ||
       patternMatch("*\\*", descFile)) //Windows
    {
      fileName = _fwInstallation_fileName(descFile);
      
      if(fwInstallationDB_getMappedPath(strtoupper(substr(descFile, 0, 1)) + ":", mappedPath) <0)
      {
        fwInstallation_throw("fwInstallationDBAgent_getComponentFile() -> Cannot resolve path mapping for description file: " + descFile);            
        return "";
      }
      else
      {
        strreplace(descFile, strtoupper(substr(descFile, 0, 1)) + ":", mappedPath);
        strreplace(sourceDir, strtoupper(substr(descFile, 0, 1)) + ":", mappedPath);
      }
    }
    else //Linux path
    {
      //needs to do some gymnastics: Check recursively from the longest possible path to the minimum one.
      ds = strsplit(descFile, "/");
      int len = dynlen(ds)-1;
      fileName = ds[dynlen(ds)]; 
      for(int i = 1; i <= (dynlen(ds)-1) ; i++)
      {
        pattern = "";
        for(int k = 1; k <= len ; k++)
        {
          if(ds[k] == "")
            continue;
                  
          pattern += "/" + ds[k];
        }
        --len;
            
        if(fwInstallationDB_getMappedPath(pattern, mappedPath) < 0)
        {
          fwInstallation_throw("fwInstallationDBAgent_getComponentFile() -> Cannot resolve path mapping for description file: " + descFile);            
          return "";
        }
            
        if(mappedPath != "")
          break;
                        
      }
      
      if(!patternMatch("*:", mappedPath))
        mappedPath += ":";
          
      strreplace(descFile, pattern, mappedPath);
      strreplace(sourceDir, pattern, mappedPath);
    }
  }

  return descFile;
}

/** This function executes all pending installation/uninstallatio of components
  @param restartProject (in/out) flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @param pvssInstallComponents (in) list of components to be installed in the project
  @param pvssDeleteComponents (in) list of components to be delete from the project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_executeComponentPendingActions(int &restartProject, 
                                                         dyn_dyn_mixed pvssInstallComponents, 
                                                         dyn_dyn_mixed pvssDeleteComponents) 
{
  int error;
  dyn_float df;
  dyn_string ds;
  int status;
  string component;
  string pattern;
  string mappedPath;
  string fileName;
  string descFile;
  string sourceDir;
  dyn_string dontRestartProjects;
  int xmlRestart = 0;
  dyn_mixed projectInfo;
  bool deletionAborted;
  dyn_string allComponents, allVersions, allFiles, orderedFiles;

  if(dynlen(pvssInstallComponents) > 0)
  {
	//gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();
    //order components according to their dependencies:
    for(int i = 1; i <= dynlen(pvssInstallComponents); i++)
    {
      string str = fwInstallationDBAgent_getComponentFile(pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX]);
      
      dynAppend(allFiles, str);
      dynAppend(allComponents, pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX]);
      dynAppend(allVersions, pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX]);     
    }
    
    int retVal;
    retVal = fwInstallation_putComponentsInOrder_Install(allComponents, allVersions, allFiles, orderedFiles);
    if(retVal != 0)
    {
      return -1;
    }

    for(int f = 1; f <= dynlen(orderedFiles); f++)
    {    
      for(int i = 1; i <= dynlen(allFiles); i++)
      {
        if(allFiles[i] == orderedFiles[f])
        {
          fwInstallation_throw("DB Agent installing component from XML file: " + allFiles[i], "INFO", 10);

          sourceDir = fwInstallation_getComponentPath(allFiles[i]);	  
          fwInstallation_installComponent(allFiles[i],
                                          sourceDir,
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX],
                                          component,
                                          status,
                                          dontRestartProjects[i],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX],
                                          false,
                                          false);
          
          dontRestartProjects[i] = strtolower(dontRestartProjects[i]);
      
          if(!status)
            ++error;
          
          break; //do not loop over the remaining allFiles.
          
        }//end of if
      }//end of loop over components.     
      
    }
    fwInstallation_trackDependency_clear();
  } //end of if dynlen(pvssInstallComponents)
  
  if(dynlen(pvssDeleteComponents) > 0)
  {
	//gCacheRequiresUpgrade = true;
    
    fwInstallationDBCache_clear();
    //read project properties to find out if files should be deleted:
    int projectId;
    string host = fwInstallation_getHostname();
    fwInstallationDB_getProjectProperties(PROJ, host, projectInfo, projectId);
    
    int deleteFiles = 0;    
    if(dynlen(projectInfo) >= FW_INSTALLATION_DB_PROJECT_DELETE_FILES)
      deleteFiles = projectInfo[FW_INSTALLATION_DB_PROJECT_DELETE_FILES];
    
    for(int i = 1; i <= dynlen(pvssDeleteComponents); i++)
    {    
      if(pvssDeleteComponents[i][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX] != "")
      {
        fwInstallation_deleteComponent(pvssDeleteComponents[i][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX], status, deleteFiles, false, deletionAborted); //do not delete files, do not delete subcomponents.
        if(!status)
          ++error;
      }
    }
    
    if(dynlen(pvssInstallComponents) <= 0)
    {
      restartProject = 2;  //Run post-delete scripts without restarting the project.
    }
  }

  //Execute reinstallations:
  error += fwInstallationDBAgent_executeProjectPendingReinstallations(restartProject);

  if(error > 0)
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("vision/MessageInfo1", "Synchronization failed", makeDynString("$1:There were errors while synchronizing the list of\nFW Components in PVSS and DB."));
    else
      fwInstallation_throw("fwInstallationDBAgent_executeComponentPendingActions() -> There were errors while synchronizing the list of FW Components in PVSS and DB.");
  }
  
  if(restartProject == 1)// && !isRunning)
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("fwInstallation/fwInstallationRestart.pnl", "Project restart required", makeDynString(""));
    else
    {
      DebugTN("INFO: Forcing project restart now...");
      fwInstallationDBAgent_releaseSynchronizationLock();
      fwInstallation_forceProjectRestart();
    } 
  }
   
  if(error > 0)
    return -1;
  
  return 0;
}

/** This function retrieves the list of pending installation/uninstallatio of components
  @param restartProject (out) flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @param pvssInstallComponents (out) list of components to be installed in the project
  @param pvssDeleteComponents (out) list of components to be delete from the project
  @param reinstalls (out) if not 0 means that there are pending reinstallation actions
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_getComponentPendingActions(int &restartProject, 
                                                     dyn_dyn_mixed &pvssInstallComponents, 
                                                     dyn_dyn_mixed &pvssDeleteComponents, 
                                                     int &reinstalls)
{
  dynClear(pvssInstallComponents);
  dynClear(pvssDeleteComponents);

  bool isCentrallyManaged = fwInstallationDB_getCentrallyManaged();
  if(isCentrallyManaged)
  {
    restartProject = 2; //assume no restart required but there are insatallations and we want to run the postinstall scritps

    dyn_dyn_mixed dbComponentsInfo;
    dyn_dyn_mixed pvssComponentsInfo;
    // Get list of all components installed in project
    fwInstallation_getInstalledComponents(pvssComponentsInfo);
    // Get list of all components registered in central database
    if(fwInstallationDB_getProjectComponents(dbComponentsInfo) != 0){
      fwInstallation_throw("fwInstallationDBAgent_getComponentPendingActions() -> Could not " +
                           "retrieve list of project components registered in DB. Aborting " +
                           "creation of component pending installation/deletion lists");
      return -1;
    }

    bool found;
    //Loop over the components of the group and check if installed in PVSS:
    int ii = 1;
    for(int j = 1; j <= dynlen(dbComponentsInfo); j++)
    {
      found = false;
      for(int k = 1; k <= dynlen(pvssComponentsInfo); k++)
      {
        if(dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == pvssComponentsInfo[k][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
           dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == pvssComponentsInfo[k][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
        {
          found = true;
          break;
        }
      }

      if(!found){
        string sourceDir = fwInstallation_getComponentPath(dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_DESCFILE_IDX]);

        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_NAME_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_VERSION_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_DESCFILE_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SOURCEDIR_IDX]= sourceDir;
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX] = "";
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_IS_SUBCOMP_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_FORCE_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_OVERWRITE_IDX];
        pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_IS_SILENT_IDX];

        if(dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_RESTART_PROJECT_IDX]){
          restartProject = 1;
        }
        ++ii;
      }
    }//end of loop over group components

    if(dynlen(pvssInstallComponents)<=0){
      restartProject = 0;
    }

    //Loop over all pvss groups and see if there is any component to be removed:
    int jj = 1;
    for(int i = 1; i <= dynlen(pvssComponentsInfo); i++)
    {
      found = false;
      for(int j = 1; j <= dynlen(dbComponentsInfo); j++){
        if(pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX]){
          found = true;
          break;
        }
      }

      if(!found)
      {
        if(dynlen(pvssInstallComponents) <=0) //Avoid project restart but only if there are no components to be installed
        {  
          restartProject = 2;
        }
        pvssDeleteComponents[jj][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX]= pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX];
        pvssDeleteComponents[jj][FW_INSTALLATION_DB_PVSS_DELETE_VERSION_IDX]= pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX];
        ++jj;
      }
    }//end of loop over pvss groups

    //Check if there are reinstallations to be done:
    dyn_dyn_mixed reinstallationsInfo;
    fwInstallationDB_getProjectPendingReinstallations(fwInstallation_getHostname(), PROJ, reinstallationsInfo);

    if(dynlen(reinstallationsInfo) > 0){
      reinstalls = 1;
    }else{
      reinstalls = 0;
    }
  }//end of if centrally managed.
  else // locally managed
  {
    restartProject = 0;
  }
  return 0;
}

/** This function sets the synchronization method
  @param bool: either true (force full synchronize on the client) or false (use server flag)
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_setForceFullSync(bool forceFullSynchronization)
{
  //[TODO] create configuration?
  //return dpSet("fwInstallation_agentParametrization.forceFullSynchronization", forceFullSynchronization);
  return 0;
}

/** This function reads the synchronization method
  @return true if full synchronize is intended
          false for synchronize on server trigger only.
*/
bool fwInstallationDBAgent_getForceFullSync()
{
  bool forceSynchronization = false;
  
  //[TODO] create configuration?
  //if(dpExists("fwInstallation_agentParametrization.forceFullSynchronize"))
  //  dpGet("fwInstallation_agentParametrization.forceFullSynchronize", forceSynchronization);

  return forceSynchronization;
}

/** This function sets the synchronization interval
  @param interval time in seconds between two consecutive synchronizations
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_setSyncInterval(int interval)
{
  return dpSet("fwInstallation_agentParametrization.syncInterval", interval);
}

/** This function reads the synchronization interval
  @return time in seconds between two consecutive synchronizations
*/
int fwInstallationDBAgent_getSyncInterval()
{
  int interval = 0;
  
  if(dpExists("fwInstallation_agentParametrization.syncInterval"))
    dpGet("fwInstallation_agentParametrization.syncInterval", interval);

  if(interval == 0)
    interval = 30;
    
  return interval;
}

/** This function checks the consistency between the list of dist peers defined
    in the local project and in the System Configuration DB
  @param status overall result of the consistency check
  @param onlyPvssSystemNames UNUSED currently (not modified by the function)
         Reserved for PVSS system names correspoding to peers defined
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbSystemNames PVSS system names correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project
  @param onlyPvssComputerNames Hostnames correspoding to peers defined 
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbComputerNames Hostnames correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project.
  @param onlyPvssSystemNumbers PVSS system numbers correspoding to peers defined 
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbSystemNumbers PVSS system numbers correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project.
  @param checkRequiredTable When true read from fw_sys_stat_system_connect, otherwise from fw_sys_stat_sys_curr_connect
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_checkDistPeers(int &status,
                                         dyn_string &onlyPvssSystemNames, 
                                         dyn_string &onlyDbSystemNames, 
                                         dyn_string &onlyPvssComputerNames, 
                                         dyn_string &onlyDbComputerNames, 
                                         dyn_int &onlyPvssSystemNumbers, 
                                         dyn_int &onlyDbSystemNumbers,
                                         bool checkRequiredTable = false)
{
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(checkRequiredTable, FW_INSTALLATION_DB_AGENT_SYNC_DIST_PEERS)){
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }

  status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;

  dyn_string pvssConnectedSystemsInfo;
  string configFilePath = PROJ_PATH + CONFIG_REL_PATH + "config";
  paCfgReadValueList(configFilePath, "dist", "distPeer", pvssConnectedSystemsInfo);

  // Check/protect againts duplicate entries (make them unique)
  int distCount = dynlen(pvssConnectedSystemsInfo);
  int uniqueCount = dynUnique(pvssConnectedSystemsInfo); // Note: this will change the list *inline*.
  if(distCount != uniqueCount){
  	fwInstallation_throw("Duplicate distributed connections entries detected in configuration file, please inspect the problem", "WARNING", 10);
  }

  //system connectivity:
  dyn_dyn_mixed dbConnectedSystemsInfo;
  string systemName = getSystemName();
  if (checkRequiredTable){
    if(fwInstallationDB_getSystemRequiredConnectivity(systemName, dbConnectedSystemsInfo, true) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkDistPeers() -> DB Error. Could not retrieve the list of required connected systems from DB");
      return -1;   
    }
  }else{
    string hostname = strtoupper(fwInstallation_getHostname());
    if(fwInstallationDB_getSystemConnectivity(systemName, hostname, dbConnectedSystemsInfo, true) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkDistPeers() -> DB Error. Could not retrieve the list of connected systems from DB");
      return -1;   
    }
  }
  dyn_bool dbConnectedSystemsMatchedToPvss;
  if(dynlen(dbConnectedSystemsInfo) > 0){
    dbConnectedSystemsMatchedToPvss[dynlen(dbConnectedSystemsInfo)] = false;
  }

  for(int i = 1; i <= dynlen(pvssConnectedSystemsInfo); i++){  //find all pvss systems only defined in the project
    dyn_dyn_string pvssDistHosts;
    dyn_dyn_int pvssDistPorts;
    int systemNumber = fwInstallation_config_parseDistPeer(pvssConnectedSystemsInfo[i], pvssDistHosts, pvssDistPorts);
    if(systemNumber < 0){
      fwInstallation_throw("fwInstallationDBAgent_checkDistPeers() -> skipping distPeer config entry: " + pvssConnectedSystemsInfo[i] +
                           " from checking - unrecognized format");
      continue;
    }

    bool found = false;
    for(int j = 1; j <= dynlen(dbConnectedSystemsInfo); j++){
      dyn_dyn_string dbDistHosts;
      dyn_dyn_int dbDistPorts;
      fwInstallation_parseHostPortConfigEntry(dbConnectedSystemsInfo[j][FW_INSTALLATION_DB_SYSTEM_COMPUTER],
                                              dbDistHosts, dbDistPorts, 4777);
      dbDistHosts[1][1] = strtoupper(fwInstallation_getHostname(dbDistHosts[1][1]));
      if(dynlen(dbDistHosts) == 2){
        dbDistHosts[2][1] = strtoupper(fwInstallation_getHostname(dbDistHosts[2][1]));
      }

      if((int)dbConnectedSystemsInfo[j][FW_INSTALLATION_DB_SYSTEM_NUMBER] == systemNumber &&
         dbDistHosts == pvssDistHosts && dbDistPorts == pvssDistPorts){
        found = true;
        dbConnectedSystemsMatchedToPvss[j] = true;
        break;
      }
    }

    if(!found){
      string computerNamePort = pvssDistHosts[1][1] + ":" + pvssDistPorts[1][1];
      if(dynlen(pvssDistHosts) == 2){
        computerNamePort += "$" + pvssDistHosts[2][1] + ":" + pvssDistPorts[2][1];
      }
      dynAppend(onlyPvssSystemNumbers, systemNumber);
      dynAppend(onlyPvssComputerNames, computerNamePort);
    }    
  }

  for(int i = 1; i <= dynlen(dbConnectedSystemsInfo); i++){  //find all pvss systems only defined in the DB
    if(!dbConnectedSystemsMatchedToPvss[i]){
      dynAppend(onlyDbSystemNames, dbConnectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_NAME]);
      dynAppend(onlyDbSystemNumbers, dbConnectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_NUMBER]);
      dynAppend(onlyDbComputerNames, dbConnectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_COMPUTER]);
    }
  }

  //Check consistency:
  if(dynlen(onlyPvssComputerNames) <= 0 &&
     dynlen(onlyDbComputerNames) <= 0){
    status = FW_INSTALLATION_DB_PROJECT_OK;  
  }else{
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  }

  return 0;
}  

/** This function returns whether the distribution manager has to be restarted during the synchronization process
  @return 1 if the dist manager has to be restarted, otherwise 0.  
*/

int fwInstallationDBAgent_isDistRestartRequired()
{
  int required = 0;
  dpGet("fwInstallation_agentParametrization.managers.stopDistAfterSync", required);
  
  return required;  
}

/** This function synchronizes the list of dist peers in the current project and in the
    System Configuration. The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, the contents of the system confiuguration db 
      are updated with the list of dist peers currently defined in the project.
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the list of dist-peers defined in the local project to reflect the contents of the 
      system configuration DB and then updates back the content of system configuration DB
  @return 0 if OK, -1 if errors, -2 when synchronization is disabled
*/
int fwInstallationDBAgent_synchronizeDistPeers()
{
  bool pvssUpdated;
  int centralStatus;
  dyn_string onlyPvssSystemNamesCentral, onlyDbSystemNamesCentral;
  dyn_string onlyPvssComputerNamesCentral, onlyDbComputerNamesCentral;
  dyn_int onlyPvssSystemNumbersCentral, onlyDbSystemNumbersCentral;
    
  bool isCentrallyManaged = fwInstallationDB_getCentrallyManaged();
  if(isCentrallyManaged){
    int retVal = fwInstallationDBAgent_checkDistPeers(centralStatus, onlyPvssSystemNamesCentral, onlyDbSystemNamesCentral,
                                                      onlyPvssComputerNamesCentral, onlyDbComputerNamesCentral,
                                                      onlyPvssSystemNumbersCentral, onlyDbSystemNumbersCentral, true);
    if(retVal != 0){
      fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not retrieve " +
                           "project info from PVSS and DB.");
      return -1;
    }
    if(centralStatus == FW_INSTALLATION_DB_PROJECT_MISSMATCH && fwInstallationRedu_ensureInstallationConditions()){
      string configPath = PROJ_PATH + CONFIG_REL_PATH + "config";
      //Delete first unncessary entries in the config file..but only if we are allowed
      if(fwInstallation_deleteFromConfigFile()){
        for(int i=1;i<=dynlen(onlyPvssComputerNamesCentral);i++){
          string entry = "\"" + onlyPvssComputerNamesCentral[i] + "\" " + onlyPvssSystemNumbersCentral[i];
          fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Deleting from config " +
                               "file connectivity to distPeer: " + entry, "INFO");
          paCfgDeleteValue(configPath, "dist", "distPeer" , entry);
          pvssUpdated = true;
        }
      }else{
        fwInstallation_throw("Synchronization of Dist Peers was only partially done - the deletion " +
                             "from config file is not allowed.", "WARNING");
      }
      //Add now missing entries to the config file:
      for(int i=1;i<=dynlen(onlyDbComputerNamesCentral);i++){
        string entry = "NOQUOTE:\"" + onlyDbComputerNamesCentral[i] + "\" " + onlyDbSystemNumbersCentral[i];
        fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Registering in config " +
                             "file connectivity to distPeer: " + entry, "INFO");
        paCfgInsertValue(configPath, "dist", "distPeer" , entry);
        pvssUpdated = true;
      }
      //Restart the dist manager if necessary:
      if(pvssUpdated){
        string distManager = fwInstallation_getWCCOAExecutable("dist");
        if(fwInstallationDBAgent_isDistRestartRequired()){
          fwInstallation_throw("List of dist peers modified, restarting the " + distManager +
                               " manager now...", "INFO", 10);
          fwInstallationManager_restart(distManager, "");
        }else{
          fwInstallation_throw("List of dist peers modified. The distribution manager (" + distManager +
                               ") must be restarted manually.", "INFO", 10);
        }
      }    
    }
  }
    
  int status;
  dyn_string onlyPvssSystemNamesLocal, onlyDbSystemNamesLocal;
  dyn_string onlyPvssComputerNamesLocal, onlyDbComputerNamesLocal;
  dyn_int onlyPvssSystemNumbersLocal, onlyDbSystemNumbersLocal;
  int retVal = fwInstallationDBAgent_checkDistPeers(status, onlyPvssSystemNamesLocal, onlyDbSystemNamesLocal,
                                                    onlyPvssComputerNamesLocal, onlyDbComputerNamesLocal,
                                                    onlyPvssSystemNumbersLocal, onlyDbSystemNumbersLocal, false);
  if(retVal != 0){
    fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not retrieve " +
                         "project info from PVSS and DB.");
    return -1;
  }
  if(status == FW_INSTALLATION_DB_PROJECT_MISSMATCH){
    fwInstallationDBCache_clear();
    string localSystemName = getSystemName();
    string hostname = strtoupper(fwInstallation_getHostname());
    int err = 0;
    //Delete first unncessary entries in the db:
    for(int i=1;i<=dynlen(onlyDbSystemNamesLocal);i++){
      string sysConnToDel = onlyDbSystemNamesLocal[i];
      bool isCentralUpdate = (dynContains(onlyPvssSystemNumbersCentral, onlyDbSystemNumbersLocal[i]) > 0);
      int remRevVal = fwInstallationDB_removeSystemConnection(localSystemName, sysConnToDel, hostname);
      if(!isCentralUpdate){
        if(remRevVal != 0){
        ++err;
          fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not delete peer " +
                               "from DB: " + sysConnToDel, "WARNING");
        }else{
          fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Deleted connection to " +
                               "distPeer: " + sysConnToDel + " from DB", "INFO");
      }
    }
    }
    //Add now missing entries to DB:
    for(int i=1;i<=dynlen(onlyPvssComputerNamesLocal);i++){
      bool isCentralUpdate = (dynContains(onlyDbSystemNumbersCentral, onlyPvssSystemNumbersLocal[i]) > 0);
      string peerName = "";
      fwInstallationDB_getSystemName(onlyPvssSystemNumbersLocal[i], peerName);
      if(peerName == "" || fwInstallationDB_addSystemConnection(localSystemName, peerName, hostname) != 0){
        if(!isCentralUpdate){
          fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not register in DB " +
                               "connection to peer " + peerName + " " + onlyPvssSystemNumbersLocal[i] +
                               " in host: " + onlyPvssComputerNamesLocal[i], "WARNING", 12);
        }
        ++err;
        continue;
      }
      
      if(!isCentrallyManaged &&
         globalExists("gFwInstallationProjectJustRegistered") && gFwInstallationProjectJustRegistered){
        fwInstallationDB_addSystemRequiredConnection(localSystemName, peerName, hostname);
    }
      if(!isCentralUpdate){
        fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Registered in DB connection " +
                             "to distPeer: " + peerName + " in host: " + onlyPvssComputerNamesLocal[i], "INFO", 10);
      }
    }
  }
  if(isCentrallyManaged && centralStatus == FW_INSTALLATION_DB_PROJECT_DISABLED ||
     !isCentrallyManaged && status == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
  return 0;   
}


int fwInstallationDBAgent_checkReduInfo(int &status, string &dbData, string &dbEvent, string &pvssData, string &pvssEvent)
{
  dyn_mixed pvssProjectInfo;
  dyn_mixed dbProjectInfo;
  int projId = -1;
  
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(true, FW_INSTALLATION_DB_AGENT_SYNC_REDU_CONF))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  
  fwInstallationDB_getProjectProperties(PROJ, fwInstallation_getHostname(), dbProjectInfo, projId);

  if (dynlen(dbProjectInfo) == 0)
  {
    status = FW_INSTALLATION_DB_PROJECT_OK;
    return 0;
  }
  
  
  //not a redundant project
  if (dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] == dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST])
  {
    status = FW_INSTALLATION_DB_PROJECT_OK;
  }
  else
  {
    dbData = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA] + "$" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA];
    dbEvent = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] + "$" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT];

    paCfgReadValue(PROJ_PATH + CONFIG_REL_PATH + "config", "general", "data", pvssData);
    paCfgReadValue(PROJ_PATH + CONFIG_REL_PATH + "config", "general", "event", pvssEvent);

    status = (strtoupper(dbData) == strtoupper(pvssData)) && (strtoupper(dbEvent) == strtoupper(pvssEvent))?
           FW_INSTALLATION_DB_PROJECT_OK:FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  }
  
//DebugN("in agent lib, dbData, dbEvent, pvssData, pvssEvent, status", dbData, dbEvent, pvssData, pvssEvent, status);  

  return 0;  
}  

/** Check consistency of WinCC OA (UNICOS) applications between configuration DB and current state.
  @param status result of consistency check: 0 - not consistent, 1 - consistent, -2 - disabled
  @param dbAppsToAdd array of applications that should be added or updated in database.
  @param dbAppsToRemove array of applications that should be unregistered from database.
  @return 0 on success, -1 on error.
*/
int fwInstallationDBAgent_checkWCCOAApplications(int &status, dyn_dyn_mixed &dbAppsToAdd, dyn_dyn_mixed &dbAppsToRemove)
{
  dyn_dyn_mixed wccoaAppsDB;
  dyn_dyn_mixed wccoaAppsLocal;
  
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(false, FW_INSTALLATION_DB_AGENT_SYNC_DEV_AND_APPS))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;  

  // Get list of apps from database
  if(fwInstallationDB_getWCCOAApplications(wccoaAppsDB) != 0)
  {
    fwInstallation_throw("Couldn't get WinCC OA (UNICOS) application list from database.");
    return -1;
  }
  // Get list of apps from local project
  if(fwInstallation_getWCCOAApplications(wccoaAppsLocal) != 0)
  {
    fwInstallation_throw("Couldn't get WinCC OA (UNICOS) application list for local machine.");
    return -1;
  }

  dynClear(dbAppsToAdd);
  dynClear(dbAppsToRemove);
  
  int appsLocalLen = dynlen(wccoaAppsLocal);
  int appsDbLen = dynlen(wccoaAppsDB);
  if(appsLocalLen == 0 && appsDbLen == 0)
  {
    status = FW_INSTALLATION_DB_PROJECT_OK;
    return 0;
  }
  
  int removeCount = 1;
  int addCount = 1;
    
  dyn_int dbAppInLocal;
  for(int j=1;j<=appsLocalLen;j++)
  {
    bool isAppInDb = false;
    for(int k=1;k<=appsDbLen;k++)
    {
      if(wccoaAppsLocal[j][FW_INSTALLATION_DB_WCCOA_APP_NAME] == 
         wccoaAppsDB[k][FW_INSTALLATION_DB_WCCOA_APP_NAME])
      {
        //application is in local project and in db
        isAppInDb = true;
        dynAppend(dbAppInLocal, k);
        
        int lastElemInArray = FW_INSTALLATION_DB_WCCOA_APP_ALARM_OVERVIEW_PANEL;
        //make sure all elements in array are accessible
        wccoaAppsLocal[j][lastElemInArray + 1] = "";
        dynRemove(wccoaAppsLocal[j], lastElemInArray + 1);
        wccoaAppsDB[k][lastElemInArray + 1] = "";
        dynRemove(wccoaAppsDB[k], lastElemInArray + 1);
        
        if(wccoaAppsLocal[j] == wccoaAppsDB[k])
        {//device has the same information in local project and in db
          break;//move to the next device then
        }
        //information about application in db must be updated
        dbAppsToAdd[addCount] = wccoaAppsLocal[j];
        addCount++;
      }
    }
    if(!isAppInDb)//application is in local project and but not in db
    {
      dbAppsToAdd[addCount] = wccoaAppsLocal[j];
      addCount++;
    }
  }
    
  for(int j=1;j<=appsDbLen;j++)//get the application that are in db but not in local project
  {
    if(!dynContains(dbAppInLocal, j))
    {
      dbAppsToRemove[removeCount] = wccoaAppsDB[j];
      removeCount++;
    }
  }

  // If both lists are empty it means they're the same, we don't have to do anything
  if((dynlen(dbAppsToAdd) == 0) && (dynlen(dbAppsToRemove) == 0))
  {
    status = FW_INSTALLATION_DB_PROJECT_OK;
  }

  return 0;
}

/** This function synchronizes the project redundant information with the System Configuration. 
    The synchronization steps depend on the management mode of the project:
    
    - if the project is locally managed, the contents of the system configuration db
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the contents of the local project config file and adds the necessary managers to the project console 
      to reflect the contents of the system configuration DB.
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_synchronizeReduInfo()
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
  string systemName = getSystemName();
  bool centrallyManaged = fwInstallationDB_getCentrallyManaged();
  int err = 0;
  int status;
  bool modified = false;
  string dbData, dbEvent, pvssData, pvssEvent;
  
  fwInstallationDBAgent_checkReduInfo(status, dbData, dbEvent, pvssData, pvssEvent);

  if(status == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }else if(status == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
    
	//gCacheRequiresUpgrade = true;
  
  if(centrallyManaged)
  {
    fwInstallationDBCache_clear();
    fwInstallation_throw("fwInstallationDBAgent_synchronizeReduInfo() -> Registering in config file event and data definition for redundant project: event = " + dbEvent + ", data = " + dbData, "INFO");
    paCfgDeleteValue(filename, "general", "event");   
    paCfgInsertValue (filename, "general", "event" , dbEvent);
    paCfgDeleteValue(filename, "general", "data");   
    paCfgInsertValue (filename, "general", "data" , dbData);
    
    fwInstallationManager_add(fwInstallation_getWCCOAExecutable("redu"), "always", 30, 1, 1, "");
    fwInstallationManager_add(fwInstallation_getWCCOAExecutable("split"), "always", 30, 1, 1, "");

    //Restart managers:
    fwInstallation_throw("Redundancy configured. Starting " + fwInstallation_getWCCOAExecutable("redu") + " manager now...", "INFO", 10);
    fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("redu"), "");
    fwInstallation_throw("Redundancy configured. Starting " + fwInstallation_getWCCOAExecutable("split") + " manager now...", "INFO", 10);
    fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("split"), "");   
  }

  return 0;   
}


/** This function unregisters all project paths from the System Configuration DB for a particular project
  @param projectName name of the PVSS project
  @param computerName hostaname where the project runs
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_unregisterProjectPaths(string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isValid;
  
  int project_id;

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0 )
  {
    fwInstallation_throw("fwInstallationDB_unregisterProjectPaths() -> Could not retrieve project installation path information from DB");
    return -1;
    
  }
  else if(project_id == -1 )
  {
    return 0;      
  }
  else
  {
    dyn_mixed var;
    var[1] = project_id;
    sql = "delete fw_sys_stat_inst_path WHERE project_id = :1";
    if(fwInstallationDB_execute(sql, var)) {fwInstallation_throw("fwInstallationDB_unregisterProjectPaths() -> Could not execute the following SQL: " + sql); return -1;};
     
  }      
  return 0;
}


/** This function registers all project paths in the System Configuration DB for a particular project
  @param paths list of project paths
  @param projectName name of the PVSS project
  @param computerName hostaname where the project runs
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_registerProjectPaths(dyn_string paths, string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isValid;
  
  int project_id;

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerProjectPaths() -> Could not retrieve project installation path information from DB");
    return -1;
    
  }
  else if(project_id == -1 )
  {
    return 0;      
  }
  else
  {
    dyn_mixed var;
    var[1] = project_id;
    for(int i = 1; i <= dynlen(paths); i++)
    {    
      var[2] = paths[i];
      sql = "INSERT INTO fw_sys_stat_inst_path(id, project_id, path, valid_from, valid_until) VALUES((fw_sys_stat_inst_path_sq.NEXTVAL), :1, :2, SYSDATE, NULL)";      
      if(fwInstallationDB_execute(sql, var)) {fwInstallation_throw("fwInstallationDB_registerProjectPaths() -> Could not execute the following SQL: " + sql); return -1;};
       
    }
  }      
  return 0;
}

const string FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE = "devType";
const string FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION = "application";
const string FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO = "devicesInfo";


/** Check consistency of devices between configuration DB and current state.
  @param status result of consistency check: 0 - not consistent, 1 - consistent, -2 - disabled.
  @param dbDevicesToAdd mapping with device types, applications and information about devices that should be added or updated in database.
  @param dbDevicesToRemove mapping with device types, applications and information about devices that should be unregistered from database.
  @return 0 on success, -1 on error.
*/
int fwInstallationDBAgent_checkDevices(int &status, dyn_mapping &dbDevicesToAdd, dyn_mapping &dbDevicesToRemove)
{  
  dyn_mapping devicesDB;
  dyn_mapping devicesLocal;
  
  if(!fwInstallationDBAgent_isSynchronizationComponentEnabled(false, FW_INSTALLATION_DB_AGENT_SYNC_DEV_AND_APPS))
  {
    status = FW_INSTALLATION_DB_PROJECT_DISABLED;
    return 0;
  }
  
  //get the list of device types and application in local project
  dyn_string localDeviceTypes;
  fwInstallation_getDeviceTypes(localDeviceTypes);
  dyn_dyn_mixed localApplications;
  if(fwInstallation_getWCCOAApplications(localApplications) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkDevices(): Cannot get the list of applications on this system. Action aborted.");
    return -1;
  }
  int localApplicationsLen = dynlen(localApplications);
  int localDeviceTypesLen = dynlen(localDeviceTypes);
  
  //create mapping with device types, applications and information about devices that are in local project
  for(int i=1;i<=localApplicationsLen;i++)
  {
    for(int j=1;j<=localDeviceTypesLen;j++)
    {
      dyn_dyn_mixed devicesInfoLocal;
      
      if(fwInstallation_getDevices(localDeviceTypes[j], localApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME],
                                   devicesInfoLocal) != 0)
      {
        fwInstallation_throw("Couldn't get devices list of type: " + localDeviceTypes[j] + " in application: " +
                             localApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME]  + " for local machine.");
        return -1;
      }
      
      if(dynlen(devicesInfoLocal) > 0)
      {
        dynAppend(devicesLocal,
                  makeMapping(FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE, localDeviceTypes[j],
                              FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION,
                              localApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME],
                              FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO, devicesInfoLocal));
      }
    }
  }
  
  //get the list of device types and applications registered in db for local project
  dyn_string dbDeviceTypes;
  if(fwInstallationDB_getDeviceTypes(dbDeviceTypes) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkDevices(): Cannot get the list of device types in DB. Action aborted.");
    return -1;
  }
  dyn_dyn_mixed dbApplications;
  if(fwInstallationDB_getWCCOAApplications(dbApplications) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkDevices(): Cannot get the list of applications in DB for this system. Action aborted.");
    return -1;
  }
  int dbApplicationsLen = dynlen(dbApplications);
  int dbDeviceTypesLen = dynlen(dbDeviceTypes);
  
  //create mapping with device types, applications and information about devices that are registered in db for local project
  for(int i=1;i<=dbApplicationsLen;i++)
  {
    for(int j=1;j<=dbDeviceTypesLen;j++)
    {
      dyn_dyn_mixed devicesInfoDb;
      
      if(fwInstallationDB_getDevices(dbDeviceTypes[j], dbApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME],
                                     devicesInfoDb) != 0)
      {
        fwInstallation_throw("Couldn't get devices list of type: " + dbDeviceTypes[j] + " in application: " +
                             dbApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME]  + " from database.");
        return -1;
      }
      
      if(dynlen(devicesInfoDb) > 0)//Add array of devices of particular type and application
      {                            //only when these devices exists
        dynAppend(devicesDB,
                  makeMapping(FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE, dbDeviceTypes[j],
                              FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION,
                              dbApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME],
                              FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO, devicesInfoDb));
      }
    }
  }
  
  dynClear(dbDevicesToAdd);
  dynClear(dbDevicesToRemove);
  
  int devicesLocalLen = dynlen(devicesLocal);
  int devicesDbLen = dynlen(devicesDB);
  if(devicesLocalLen == 0 && devicesDbLen == 0)
  {
    status = FW_INSTALLATION_DB_PROJECT_OK;
    return 0;
  }
  
  dyn_int dbTypeAppInLocal;//indicate which device types and applications from db exists also in local project
  for(int i=1;i<=devicesLocalLen;i++)//repeat it for each device type and local application
  {
    //get the local device list
    dyn_dyn_mixed localDevicesOfTypeInApp = devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO];
    dyn_dyn_mixed dbDevicesOfTypeInApp;
    
    bool isAppTypeInDb = false;//flag that indicate if device list of particular type and application is also in db
    for(int j=1;j<=devicesDbLen;j++)
    {//look for list of devices registered in db
      if(devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE] ==
         devicesDB[j][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE] &&
         devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION] ==
         devicesDB[j][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION])
      {//get the list of devices registered in db
        dbDevicesOfTypeInApp = devicesDB[j][FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO];
        dynAppend(dbTypeAppInLocal, j);//indicate that device type and application exists both in db and local project
        isAppTypeInDb = true;
        break;
      }
    }
    if(!isAppTypeInDb)//devices of particular type and application are not in db
    {
      dynAppend(dbDevicesToAdd, devicesLocal[i]);//add them to the mapping of devices to add
      continue;//move to the next iteration
    }
    
    //the list of devices of particular type and application exists both in local project and in db
    //compare those two lists with device info
    
    int removeCount = 1;
    int addCount = 1;
    dyn_dyn_mixed devicesToRemoveInfo;//array of devices that are in db but not in local project
    dyn_dyn_mixed devicesToAddInfo;//array of devices that are in local project but not in db or has changed information
    
    dyn_int dbDevInLocal;
    for(int j=1;j<=dynlen(localDevicesOfTypeInApp);j++)
    {
      bool isDeviceInDb = false;
      for(int k=1;k<=dynlen(dbDevicesOfTypeInApp);k++)
      {
        if(localDevicesOfTypeInApp[j][FW_INSTALLATION_DB_WCCOA_DEV_NAME] == 
           dbDevicesOfTypeInApp[k][FW_INSTALLATION_DB_WCCOA_DEV_NAME])
        {
          //device is in local project and in db
          isDeviceInDb = true;
          dynAppend(dbDevInLocal, k);
          
          int lastElemInArray = FW_INSTALLATION_DB_WCCOA_DEV_STATUS;
          //make sure all elements in array are accessible
          localDevicesOfTypeInApp[j][lastElemInArray + 1] = "";
          dynRemove(localDevicesOfTypeInApp[j], lastElemInArray + 1);
          dbDevicesOfTypeInApp[k][lastElemInArray + 1] = "";
          dynRemove(dbDevicesOfTypeInApp[k], lastElemInArray + 1);
          
          if(localDevicesOfTypeInApp[j] == dbDevicesOfTypeInApp[k])
          {//device has the same information in local project and in db
            break;//move to the next device then
          }
          //information about device in db must be updated
          devicesToAddInfo[addCount] = localDevicesOfTypeInApp[j];
          addCount++;
        }
      }
      if(!isDeviceInDb)//device is in local project and but not in db
      {
        devicesToAddInfo[addCount] = localDevicesOfTypeInApp[j];
        addCount++;
      }
    }
    
    for(int j=1;j<=dynlen(dbDevicesOfTypeInApp);j++)//get the devices that are in db but not in local project
    {
      if(!dynContains(dbDevInLocal, j))
      {
        devicesToRemoveInfo[removeCount] = dbDevicesOfTypeInApp[j];
        removeCount++;
      }
    }
    
    //add element to mapping if corresponding list of devices in not empty
    if(dynlen(devicesToAddInfo) > 0)
      dynAppend(dbDevicesToAdd, 
                makeMapping(FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE,
                            devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE],
                            FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION,
                            devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION],
                            FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO, devicesToAddInfo));
    if(dynlen(devicesToRemoveInfo) > 0)
      dynAppend(dbDevicesToRemove, 
                makeMapping(FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE,
                            devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE],
                            FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION,
                            devicesLocal[i][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION],
                            FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO, devicesToRemoveInfo));
    
  }
  
  for(int i=1;i<=devicesDbLen;i++)
  {//get devices of particular type and application which are in db but not in local project
    if(!dynContains(dbTypeAppInLocal, i))
    {
      dynAppend(dbDevicesToRemove, devicesDB[i]);
    }
  }
  
  // If three lists are empty it means there is consistency between local data and db
  if((dynlen(dbDevicesToAdd) == 0) && (dynlen(dbDevicesToRemove) == 0))
    status = FW_INSTALLATION_DB_PROJECT_OK;
  else
    status = FW_INSTALLATION_DB_PROJECT_MISSMATCH;
  
  return 0;
}

/** Synchronize UNICOS application and devices on this project with the System Configuration.
  Applications are read from _UnApplication datapoint type.
  @return 0 on success, -1 on error, -2 when synchronization is disabled
*/
int fwInstallationDBAgent_synchronizeWCCOAApplicationsAndDevices()
{
  //bool centrallyManaged = fwInstallationDB_getCentrallyManaged();
  
  int appsStatus;
  dyn_dyn_mixed dbAppAddList;
  dyn_dyn_mixed dbAppRemoveList;
  fwInstallationDBAgent_checkWCCOAApplications(appsStatus, dbAppAddList, dbAppRemoveList);
  
  int devStatus;
  dyn_mapping dbDevAddList;
  dyn_mapping dbDevRemoveList;
  fwInstallationDBAgent_checkDevices(devStatus, dbDevAddList, dbDevRemoveList);
  
  if(appsStatus == FW_INSTALLATION_DB_PROJECT_OK && devStatus == FW_INSTALLATION_DB_PROJECT_OK){
    return 0;
  }else if(appsStatus == FW_INSTALLATION_DB_PROJECT_DISABLED || devStatus == FW_INSTALLATION_DB_PROJECT_DISABLED){
    return FW_INSTALLATION_DB_PROJECT_DISABLED;
  }
  
  int err = 0;
  //synchronize apps and devices
  //remove devices
  int dbDevRemoveListCount = dynlen(dbDevRemoveList);
  for(int i=1;i<=dbDevRemoveListCount;i++)
  {
    string devApp = dbDevRemoveList[i][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION];
    string devType = dbDevRemoveList[i][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE];
    dyn_dyn_mixed devicesInfo = dbDevRemoveList[i][FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO];
      
    int devToRemoveCount = dynlen(devicesInfo);
    for(int j=1;j<=devToRemoveCount;j++)
    {
      string devName = devicesInfo[j][FW_INSTALLATION_DB_WCCOA_DEV_NAME];
      if(fwInstallationDB_unregisterDevice(devType, devApp, devName) != 0)
      {
        fwInstallation_throw("Couldn't unregister device from database (device name: " + devName +
                             " of type: " + devType + " in application: " + devApp + ").");
        err++;
      }
    }
  }
  if(err > 0)
  {
    fwInstallation_throw("Errors occured during unregistering devices from database. " +
                         "Synchronization of devices and applications was aborted.");
    return -1;
  }
  //remove apps
  int dbAppRemoveListCount = dynlen(dbAppRemoveList);
  for(int i=1;i<=dbAppRemoveListCount;i++)
  {
    string application = dbAppRemoveList[i][FW_INSTALLATION_DB_WCCOA_APP_NAME];
    if(fwInstallationDB_unregisterWCCOAApplication(application) != 0)
    {
      fwInstallation_throw("Couldn't unregister WinCC OA application from database (application name: " +
                           application + ").");
      err++;
    }
  }
  if(err > 0)
  {
    fwInstallation_throw("Errors occured during unregistering applications from database. " +
                         "Synchronization of devices and applications was aborted.");
    return -1;
  }
  //add or update apps
  int dbAppAddListCount = dynlen(dbAppAddList);
  for(int i=1;i<=dbAppAddListCount;i++)
  {
    dyn_mixed applicationInfo = dbAppAddList[i];
    if(fwInstallationDB_setWCCOAApplicationProperties(applicationInfo) != 0)
    {//this function also registers application if it is not yet in DB
      fwInstallation_throw("Couldn't update WinCC OA application in database (application name: " +
                           applicationInfo[FW_INSTALLATION_DB_WCCOA_APP_NAME] + ").");
      err++;
    }
  }
  if(err > 0)
  {
    fwInstallation_throw("Errors occured during adding and updating applications in database. " +
                         "Synchronization of devices and applications was aborted.");
    return -1;
  }
  //add or update devices
  int dbDevAddListCount = dynlen(dbDevAddList);
  for(int i=1;i<=dbDevAddListCount;i++)
  {
    string devApp = dbDevAddList[i][FW_INSTALLATION_DB_DEVICES_LIST_APPLICATION];
    string devType = dbDevAddList[i][FW_INSTALLATION_DB_DEVICES_LIST_DEV_TYPE];
      
    //synchronize device type if necessary
    int deviceTypeId = -1;
    fwInstallationDB_isDeviceTypeRegistered(deviceTypeId, devType);
    if(deviceTypeId == -1)
    {//Device type not yet registered, registering now.
      if(fwInstallationDB_registerDeviceType(devType) != 0)
      {
        fwInstallation_throw("Couldn't register device type: " + devType + " in DB, updating devices of this type aborted", "ERROR", 20);
        err++;
        continue;
      }
      //Check if device type was correctly registered.
      fwInstallationDB_isDeviceTypeRegistered(deviceTypeId, devType);
      if(deviceTypeId == -1)
      {
        fwInstallation_throw("Device type : " + devType + " was not registered correctly in DB, updating devices of this type aborted", "ERROR", 20);
        err++;
        continue;
      }
    }      
      
    dyn_dyn_mixed devicesInfo = dbDevAddList[i][FW_INSTALLATION_DB_DEVICES_LIST_DEVICES_INFO];
      
    int devToAddCount = dynlen(devicesInfo);
    for(int j=1;j<=devToAddCount;j++)
    {
      dyn_mixed devInfo = devicesInfo[j];
      if(fwInstallationDB_setDeviceProperties(devType, devApp, devInfo) != 0)
      {//this function also registers device if it is not yet in DB
        fwInstallation_throw("Couldn't update device in database (device name: " + 
                             devInfo[FW_INSTALLATION_DB_WCCOA_DEV_NAME] + " of type: " +
                             devType + " in application: " + devApp + ").");
        err++;
      }
    }
  }
  if(err > 0)
  {
    fwInstallation_throw("Errors occured during adding and updating devices in database. " +
                         "Synchronization of devices and applications was aborted.");
    return -1;
  }
  return 0;
}


dyn_bool fwInstallationDBAgent_getEnabledSynchronizationComponents(bool isCentralMode)
{
  string dpeMode = isCentralMode?FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_CENTRAL_DPE:
                                 FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LOCAL_DPE;
  dyn_bool syncCompsEnabled;
  if(dpGet(fwInstallation_getAgentDp() + dpeMode, syncCompsEnabled) != 0){
    fwInstallation_throw("Failed to retrieve enabled synchronization components, assuming that all are disabled", "WARNING");
    syncCompsEnabled[FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LEN] = false;
    return syncCompsEnabled;
  }
  
  fwInstallationDBAgent_completeEnabledSynchronizationComponentsArray(syncCompsEnabled);
  return syncCompsEnabled;
}

int fwInstallationDBAgent_setEnabledSynchronizationComponents(bool isCentralMode, dyn_bool enabledSyncComponents)
{
  string dpeMode = isCentralMode?FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_CENTRAL_DPE:
                                 FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LOCAL_DPE;
  fwInstallationDBAgent_completeEnabledSynchronizationComponentsArray(enabledSyncComponents);
 
  return dpSet(fwInstallation_getAgentDp() + dpeMode, enabledSyncComponents);
}

void fwInstallationDBAgent_completeEnabledSynchronizationComponentsArray(dyn_bool &enabledSyncComponents)
{
  int enabledSyncComponentsLen = dynlen(enabledSyncComponents);
  for(int i=enabledSyncComponentsLen + 1;i<=FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_LEN;i++){
    enabledSyncComponents[i] = true;
  }
}

bool fwInstallationDBAgent_isSynchronizationComponentEnabled(bool isCentralMode, int synchronizationComponentId)
{
  dyn_bool enabledSyncComponents = fwInstallationDBAgent_getEnabledSynchronizationComponents(isCentralMode);
  return enabledSyncComponents[synchronizationComponentId];
}

