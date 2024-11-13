// $License: NOLICENSE
/**@file
 *
 * This library contains all functions to handle remote upgrade request of the FW Component Installation Tool in the local project. 
 * The functions in these library are not intended to be called 
 * from user scripts
 *
 * @author Fernando Varela Rodriguez (IT-CO/BE)
 * @date   September 2010
 */
#uses "fwInstallation/fwInstallation.ctl"
#uses "fwInstallation/fwInstallationDBUpgrade.ctl"
/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationUpgradeLibVersion = "9.1.3";
const string csFwInstallationUpgradeLibTag = "";

dyn_dyn_mixed fwInstallationUpgrade_getManagerExceptions()
{
  dyn_dyn_mixed exceptions;
  
  exceptions[1][1] = fwInstallation_getWCCOAExecutable("sim");
  exceptions[1][2] = "";
  
  exceptions[2][1] = fwInstallation_getWCCOAExecutable("ctrl");
  exceptions[2][2] = "-f pvss_scripts.lst";
  
  exceptions[3][1] = fwInstallation_getWCCOAExecutable("ctrl");
  exceptions[3][2] = FW_INSTALLATION_DB_AGENT_MANAGER_CMD;
 
  exceptions[4][1] = fwInstallation_getWCCOAExecutable("pmon");
  exceptions[4][2] = "";
  
  exceptions[5][1] = fwInstallation_getWCCOAExecutable("data");
  exceptions[5][2] = "";
  
  exceptions[6][1] = fwInstallation_getWCCOAExecutable("event");
  exceptions[6][2] = "";

  exceptions[7][1] = fwInstallation_getWCCOAExecutable("valarch");
  exceptions[7][2] = "-num 0";
  
  exceptions[8][1] = fwInstallation_getWCCOAExecutable("ctrl");
  exceptions[8][2] = FW_INSTALLATION_DB_AGENT_MANAGER_CMD;
  
  return exceptions;
}

int fwInstallationUpgrade_execute()
{
  dyn_mixed upgradeInfo;
  string targetDir = "";
  int error = 0;
  string user = "", pwd = "";
  dyn_dyn_mixed exceptions = fwInstallationUpgrade_getManagerExceptions();
  
  if(!fwInstallationDB_getUseDB()) //Nothing to be done
    return 0;
  
  if(fwInstallationDBUpgrade_getProjectToolUpgradeRequest(upgradeInfo))
  {
    fwInstallation_throw("fwInstallationUpgrade_execute() -> Could not check if the remote upgrade of the FW Component Installation Tool has been requested");
    return -1;
  }

  if(dynlen(upgradeInfo) <= 0) //No request exists
    return 0;
  
  targetDir = upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_TARGET_DIR];
  
  if(targetDir == "") //if target dir has not been defined, it means, use the project path
    targetDir = PROJ_PATH;

  fwInstallation_throw("Upgrade of the installation tool requested. New path - " + upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR], "INFO", 10);
  
  dyn_string files = fwInstallation_getFileNamesRec(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR]);

  if(dynlen(files) <= 0)
    return 0; //nothing to be done

  fwInstallation_throw("FW Component Installation Tool has to be upgraded.", "INFO", 10);  
  //stop all managers required:
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("ERROR: fwInstallationManager_stopAllOfTypes: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }    
  
  if(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SAFE_MODE])
  {
    fwInstallation_throw("Entering safe upgrade mode now. Managers will be stopped, please wait..", "INFO", 10);  
    if(fwInstallationManager_stopAll(exceptions))
    {
      fwInstallation_throw("Failed to stop the project managers. Upgrade of the FW Component Installation Tool aborted");
      if(fwInstallationManager_executeAllReconfigurationActions())
      {
        fwInstallation_throw("Failed to reconfigure all project managers. The FW Component Installation Tool has been sucessfully upgrade but please, check the manager configuration", "WARNING", 10);
        return -1;
      }
      return -1;
    }
  }

  for(int i = 1; i <= dynlen(files); i++)
  {
    string target = targetDir + "/" + files[i];
    if(fwInstallation_copyFile(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR] + "/" + files[i], target))
    {
      fwInstallation_throw("Failed to copy: " + upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR] + "/" + files[i]);
      return -2;
    }
  }
  
  fwInstallation_throw("All files of the new version of the Installation Tool has been copied", "INFO", 10);      
  if(fwInstallationManager_executeAllReconfigurationActions())
  {
      fwInstallation_throw("Failed to reconfigure the project managers. The FW Component Installation Tool has been sucessfully upgrade but please, check the manager configuration", "WARNING", 10);
      return -1;
  }

  if(fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest())
  {
    fwInstallation_throw("fwInstallationUpgrade_execute() -> Failed to unregister the pending request for the upgrade FW Component Installation Tool after execution");
    return -1;
  }

  if(error)
    fwInstallation_throw("There have been errors upgrading the FW Component Installation Tool");  
  else
  {
    fwInstallation_throw("FW Component Installation Tool has been successfully upgraded. Restarting the DB-Agent of the Installation Tool now...", "INFO", 10);  
    fwInstallationManager_command("STOP", fwInstallation_getWCCOAExecutable("ctrl"), FW_INSTALLATION_DB_AGENT_MANAGER_CMD);
  }
  
  return 0;
}

/** Check if we run for the first time as a new version (an upgrade was made),
  it will set reference to true if the current running version is the same
  as in DB, false if current version differs from the one in DB.
  @param desiredVersion - output, if current version matches version in DB
  @return - 0 - OK, -1 - error occured
*/
int fwInstallationUpgrade_isToolVersionSameAsInDB(bool &desiredVersion)
{
  desiredVersion = false; // By default set to safe value
  string project = PROJ;
  string hostname = fwInstallation_getHostname();

  dyn_mixed projectInfo;
  int projectId;
  if(fwInstallationDB_getProjectProperties(project, hostname, projectInfo, projectId) != 0 ||
     dynlen(projectInfo) < FW_INSTALLATION_DB_PROJECT_TOOL_VER)
  {
    return -1;
    }
  string toolVersionInDB = projectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER];
  desiredVersion = (toolVersionInDB == "" || fwInstallation_checkToolVersion(toolVersionInDB) == 1);
  return 0;
}

/** Set installation agent to manual and kill, then
  wait for it to happen. This is used as a safety
  measure in case something bad happens.
*/
void fwInstallationUpgrade_switchToManualAndStop()
{
  int retCode;
  
  // Set our manager to manual
  retCode = fwInstallationManager_setMode(fwInstallation_getWCCOAExecutable("ctrl"), FW_INSTALLATION_DB_AGENT_MANAGER_CMD, "manual");
  if(retCode != 0)
  {
    // In case of an error there's not much we can do about it - just log it
    fwInstallation_throw("fwInstallationUpgrade_switchToManualAndStop() -> Failed to set project to manual", "ERROR", 10);
  }
  
  // Stop our manager
  retCode = fwInstallationManager_command("KILL", fwInstallation_getWCCOAExecutable("ctrl"), FW_INSTALLATION_DB_AGENT_MANAGER_CMD);
  if(retCode != 0)
  {
    // In case of an error there's not much we can do about it - just log it
    fwInstallation_throw("fwInstallationUpgrade_switchToManualAndStop() -> Failed to stop manager", "ERROR", 10);
  }
  
  // Wait silently for the end
  while(1)
  {
    delay(1);
  }
}
