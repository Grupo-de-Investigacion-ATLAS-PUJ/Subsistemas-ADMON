// $License: NOLICENSE
#uses "fwInstallation/fwInstallation.ctl"
#uses "fwInstallation/fwInstallationUpgrade.ctl"

/** fwInstallationAgent script version and tag
 * Used to determine the coherency of installation tool
 * Please do not edit it manually
 */
const string FW_SYS_STAT_DB_AGENT_SCRIPT = "9.1.3";
const string FW_SYS_STAT_DB_AGENT_SCRIPT_TAG = "";

// Constant parameters
const int FW_INSTALLATION_DB_AGENT_INIT_DELAY = 5; // [sec] - delay for initialization to start
const int FW_INSTALLATION_DB_AGENT_INIT_WAIT_TIMEOUT = 3600; // [sec] - timeout waiting for fwScripts manager to finish

main()
{
  int error;
  int restartProject = 0;
  int isRunning = 0;
  bool isConnected = false;

  fwInstallation_throw("Starting FW Installation Tool DB-Agent v." + fwInstallation_getVersionString(FW_SYS_STAT_DB_AGENT_SCRIPT, FW_SYS_STAT_DB_AGENT_SCRIPT_TAG), "INFO");

  if(fwInstallationInit_isCleanupNeeded()){ // At first check if cleanup of obsolete files and config entries is needed
    fwInstallationInit_consolidationCleanup();
  }

  //Check that the installation tool has been successfully installed:
  if(fwInstallationAgentDBConsistencyChecker_checkFilesVersionConsistency() != 0){
    fwInstallation_throw("FW Component Installation Tool exiting...");
    return;
  }

  //Give time to pmon to start all managers in the console and wait for fwScripts.lst manager to finish
  delay(FW_INSTALLATION_DB_AGENT_INIT_DELAY);
  bool isPostInstallRunning;
  int timeoutCounter;
  while(true){
    int retVal = fwInstallationDBAgent_isPostInstallRunning(isPostInstallRunning);
    if(!isPostInstallRunning){
      if(timeoutCounter > 0){
        fwInstallation_throw("fwScripts.lst manager has finished execution. Proceeding with " +
                             "FW Installation Tool DB-Agent initialization", "INFO");
      }
      break;
    }
    if(retVal != 0){
      fwInstallation_throw("Continue with FW Installation Tool DB-Agent initialization " +
                           "without waiting for fwScripts.lst manager to finish", "WARNING", 9);
      break;
    }
    if(timeoutCounter == 0){
      fwInstallation_throw("Detected running fwScripts.lst manager. Waiting up to " +
                           FW_INSTALLATION_DB_AGENT_INIT_WAIT_TIMEOUT + "s for it to finish before " +
                           "proceeding with FW Installation Tool DB-Agent initialization", "INFO");
    }
    if(timeoutCounter > FW_INSTALLATION_DB_AGENT_INIT_WAIT_TIMEOUT){
      fwInstallation_throw("Timeout of " + FW_INSTALLATION_DB_AGENT_INIT_WAIT_TIMEOUT + "s " +
                           "waiting for fwScripts.lst manager to finish has expired", "WARNING", 9);
      fwInstallation_throw("Continue with FW Installation Tool DB-Agent initialization " +
                           "without waiting for fwScripts.lst manager to finish", "WARNING", 9);
      break;
    }
    timeoutCounter++;
    delay(1);
  }

  //Before connecting to the DB and if Windows, kill previous instances of the DB-agent if they exist.
  //This is necessary to overcome some problems with CtrlRDBAccess that prevents the manager from exiting when the project is stopped.
  if(_WIN32){
    fwInstallationDbAgent_terminateOldInstances();
  }

  //Initial configuration of the FW Installation Tool, ensure component installation directory is defined
  while(true){
    setUserId(getUserId("para"));
    if (!getUserPermission(4)){ //Make sure that we have the rights, otherwise exit...
      fwInstallation_throw("Sorry but you do not have sufficient rights on this system to run the FW Installation Tool. Exiting...");
      return;
    }
    else{
      if(fwInstallationInit_execute(false)){
        fwInstallation_throw("Failed to initialize the FW Component Installation Tool. Exiting...");
        return;
      }
    }

    string sPath;
    string dp = fwInstallation_getInstallationDp();
    if(dpExists(dp + ".installationDirectoryPath")){
      dpGet(dp + ".installationDirectoryPath", sPath);
    }

    if(sPath != ""){
      break; // component installation directory is defined, exit loop and proceed
    }
    //fwInstallation_throw("FW Installation directory not defined. Checking again in " + fwInstallationDBAgent_getSyncInterval() + "s.", "INFO");
    delay(fwInstallationDBAgent_getSyncInterval()); // Agent panel is pop-up. Let the user interact with it
  }

  fwInstallationDBAgent_releaseSynchronizationLock();

  //InitializeCache for new cycle.
  if( fwInstallationDB_initializeCache() != 0) {
    ++error;
    fwInstallation_throw("fwInstallationAgentDBConsistencyChecker() -> Could not start cache.");
  }

  while(1)
  {
    /*
    if(fwInstallationRedu_isPassive())
    {
      //DebugN("INFO: Passive redundant system. Checking again in " + fwInstallationDBAgent_getSyncInterval() + "s.");
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }*/
    if(!fwInstallationDB_getUseDB()){
        delay(fwInstallationDBAgent_getSyncInterval());
        continue;
    }

    //Note: Connection in most cases should be established earlier by fwInstallationInit_execute() function.
    if(fwInstallationDB_connect() != 0){
      isConnected = false;
      fwInstallation_throw("fwInstallationDBConsistencyChecker script -> Could not connect to DB. Next attempt in "+ fwInstallationDBAgent_getSyncInterval() + "s.", "WARNING"); 
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }

 
    //Check schema version is correct, otherwise sleep:
    string version = "";
    fwInstallationDB_getSchemaVersion(version);
    
    if(!fwInstallationDB_compareSchemaVersion())
    {
      fwInstallation_throw("FW Installation Tool DB-Agent: Wrong db schema. Required schema version is: " + FW_INSTALLATION_DB_REQUIRED_SCHEMA_VERSION + " current is " + version);         
      fwInstallationDB_storeInstallationLog();
      delay(1);
      fwInstallationDB_closeDBConnection();
      isConnected = false;      
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }
    
    if(!isConnected) //we got this far, we have a valid DB connection
    {
      isConnected = true;
      fwInstallation_throw("Connection to FW System Configuration DB successfully established. Schema v." + version, "INFO");    
    }
      
    //do not do anything if post-installation scripts of a previous installation are still running:
    isRunning = 1;
    fwInstallationDBAgent_isPostInstallRunning(isRunning); 
    if(isRunning)
    {
      fwInstallation_throw("FW Installation Tool DB-Agent: PostInstallation scripts still running. Skipping sync...", "INFO");
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }
    
    // If centrally managed... (we only do one-time operation if currently running version is newer than the one id DB)
    if(fwInstallationDB_getCentrallyManaged())
    {
      bool runnningCorrectVersion;
      int retCode;

      retCode = fwInstallationUpgrade_isToolVersionSameAsInDB(runnningCorrectVersion);
      if(retCode != 0)
      {
        // Error - just assume the version in DB and here differs
        runnningCorrectVersion = false;
      }

      if(!runnningCorrectVersion)
      {
        // We're in centrally managed mode and this is a fresh new version running. This shouldn't happen.
        // To prevent any damage switch to (force) to locally managed mode
        fwInstallation_throw("This is a first start of new version, detected centrally managed mode, for safety setting mode to locally managed", "WARNING", 10);
        retCode = fwInstallationDB_setCentrallyManaged(false);
        
        // Clear cache so that we'll grab fresh data from DB (this is for extra safety)
        fwInstallationDBCache_clear();
        if((retCode != 0) || fwInstallationDB_getCentrallyManaged())
        {
          // Many improbable things happend: we were upgraded, somehow we are in central mode, for safety measures we've switched 
          // to local mode, but it didn't work - set manager to manual and kill ourselves
          fwInstallation_throw("Failed to switch to locally managed mode, for safety reasons this manager will set to manual and stop", "ERROR", 10);
          fwInstallationDB_storeInstallationLog();
          
          fwInstallationUpgrade_switchToManualAndStop();
        }
      }
    }
    else // Check if the FW Component Installation Tool has to be upgraded (can do that only in locally managed mode)
    {
      // Locally managed - the only thing that we're allowed to do is to upgrade ourselfs
      int errCode = fwInstallationUpgrade_execute();
      if(errCode == -1)
      {
        fwInstallation_throw("Failed to execute the Upgrade Remote Request of the FW Component Installation Tool. Old version of the tool still running", "WARNING", 13);
	       fwInstallationDB_storeInstallationLog();
      }
      else if(errCode == -2)
      {
        fwInstallation_throw("Failed to execute the Upgrade Remote Request of the FW Component Installation Tool. DB-Agent exiting...");
	       fwInstallationDB_storeInstallationLog();
	       delay(1);
        return;
      }
      // else - should be OK (no need to upgrade)
    }
      
//    fwInstallationDBAgent_getSynchronizationOptions(options);
//    if(dynlen(options))
//    {
      int projectId, autoregEnabled;
      fwInstallationDB_isProjectRegistered(projectId);
      fwInstallationDB_getProjectAutoregistration(autoregEnabled);
      if (projectId > 0 || autoregEnabled == 1) //if the project is already registered or the autoregistration is enabled
      {
        error = fwInstallationDBAgent_getSynchronizationLock();
        
        bool partiallyRegisteredProject = fwInstallationDB_isProjectRegisteredPartially(projectId);
        if (partiallyRegisteredProject)
        {
          //This sets the global variable originaly set in fwInstallationDB_registerProject()
          //that is used in fwInstallationDBAgent_synchronize, otherwise the installation tool
          //doesn't work properly with a project created using automated script
          
          //keep in a global that the project was just created
          if(!globalExists("gFwInstallationProjectJustRegistered")) 
            addGlobal("gFwInstallationProjectJustRegistered", BOOL_VAR);
          while(!globalExists("gFwInstallationProjectJustRegistered"))
          {
            delay(0, 100);
          }
          gFwInstallationProjectJustRegistered = true;
        }
      
        if(fwInstallationDBAgent_synchronize(restartProject) != 0)
        {
          error = fwInstallationDBAgent_releaseSynchronizationLock();
          fwInstallation_throw("DB-Project synchronization failed.");
          delay(fwInstallationDBAgent_getSyncInterval());
          continue;
        }
        
        if (partiallyRegisteredProject)
        {
          fwInstallationDB_completeProjectPartialRegistration(projectId);
        }
      
        //Re-sync unicos ows files if needed:
        if(isFunctionDefined("unConfigGenericFunctions_Create_Config_ows"))
        {
          callFunction("unConfigGenericFunctions_Create_Config_ows", "config_ows");
        }
      
        //DebugN("**************right after sync ", restartProject);      
        error = fwInstallationDBAgent_releaseSynchronizationLock();
        
        // Project restart is required
        if((restartProject == 1) || fwInstallation_isProjectRestartAfterInitPending())
        {
          // Clear reset flag if it was set
          if(fwInstallation_isProjectRestartAfterInitPending())
          {
            fwInstallation_clearProjectRestartAfterInit();
          }
          fwInstallationDBAgent_releaseSynchronizationLock();
          fwInstallation_throw("Closing connection to System Configuration DB", "INFO"); 
          fwInstallationDB_storeInstallationLog();
          int ret = fwInstallationDB_closeDBConnection(); 
        
          //DebugN("&&&&&&&&&&&&&&&&&&&&Calling restart project from script");   
          fwInstallation_throw("FW Installation Tool: Forcing project restart", "INFO"); 
          fwInstallationDB_storeInstallationLog();

          if(fwInstallation_forceProjectRestart())
            fwInstallation_throw("FW Installation Tool: Failed to restart the project"); 
        
	  delay(5);
          exit(); //make sure own manager dies in PVSS 3.8-SP1
        }
        else if(restartProject == 2) //No project restart required. Run PostInstallation Scripts
        {
          //Trigger postInstallation scripts here:
          //DebugN("&&&&&&&&&&&&&&&&&&&&Running post install scripts");   
          fwInstallation_throw("FW Installation Tool: Running component post-installation scripts. Project restart will be skipped", "INFO"); 
          fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("ctrl"), FW_INSTALLATION_SCRIPTS_MANAGER_CMD);
          fwInstallationDBAgent_releaseSynchronizationLock();
        }   
      
        fwInstallationDBAgent_releaseSynchronizationLock();
        fwInstallationDB_storeInstallationLog();

        //Clear the cache.
        //fwInstallationDBCache_clear();      
      }
      delay(fwInstallationDBAgent_getSyncInterval());
      
//    }
  }//end while(1)
}//end of main

/** Checks version consistency between fwInstallation tool libraries and fwInstallationAgentDBConsistencyChecker script.
  * @return 0 when libraries versions and version tags are consistent with script,
  *        -1 when versions are the same but version tags differs,
  *        -2 when versions are not consistent
  */
int fwInstallationAgentDBConsistencyChecker_checkFilesVersionConsistency(){
  bool areVersionsConsistent =
      (FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationToolVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationInitLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationDBLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == gFwInstallationAgentLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationDBCacheLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationManagerLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationXmlLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationPackagerLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationReduLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationDBUpgradeLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationUpgradeLibVersion &&
       FW_SYS_STAT_DB_AGENT_SCRIPT == csFwInstallationQtHelpLibVersion);
  bool areVersionTagsConsistent = (areVersionsConsistent &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationToolTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationInitLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationDBLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == gFwInstallationAgentLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationDBCacheLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationManagerLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationXmlLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationPackagerLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationReduLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationDBUpgradeLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationUpgradeLibTag &&
       FW_SYS_STAT_DB_AGENT_SCRIPT_TAG == csFwInstallationQtHelpLibTag);
  if(areVersionsConsistent && areVersionTagsConsistent){
    return 0;
  }
  if(!areVersionsConsistent){
    fwInstallation_throw("Inconsistency between library versions of the FW Installation Tool. Reinstall the tool...");
  }else{
    fwInstallation_throw("Inconsistency between library version tags of the FW Installation Tool. Reinstall the tool...");
  }
  fwInstallation_throw("Tool is v." + fwInstallation_getVersionString(csFwInstallationToolVersion, csFwInstallationToolTag), "INFO", 10);
  fwInstallation_throw("fwInstallation.ctl is v." + fwInstallation_getVersionString(csFwInstallationLibVersion, csFwInstallationToolTag), "INFO", 10);
  fwInstallation_throw("fwInstallationInit.ctl is v." + fwInstallation_getVersionString(csFwInstallationInitLibVersion, csFwInstallationInitLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationDB.ctl is v." + fwInstallation_getVersionString(csFwInstallationDBLibVersion, csFwInstallationDBLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationDBAgent.ctl is v." + fwInstallation_getVersionString(gFwInstallationAgentLibVersion, gFwInstallationAgentLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationDBCache.ctl is v." + fwInstallation_getVersionString(csFwInstallationDBCacheLibVersion, csFwInstallationDBCacheLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationManager.ctl is v." + fwInstallation_getVersionString(csFwInstallationManagerLibVersion, csFwInstallationManagerLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationXml.ctl is v." + fwInstallation_getVersionString(csFwInstallationXmlLibVersion, csFwInstallationXmlLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationPackager.ctl is v." + fwInstallation_getVersionString(csFwInstallationPackagerLibVersion, csFwInstallationPackagerLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationRedu.ctl is v." + fwInstallation_getVersionString(csFwInstallationReduLibVersion, csFwInstallationReduLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationDBUpgrade.ctl is v." + fwInstallation_getVersionString(csFwInstallationDBUpgradeLibVersion, csFwInstallationDBUpgradeLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationUpgrade.ctl is v." + fwInstallation_getVersionString(csFwInstallationUpgradeLibVersion, csFwInstallationUpgradeLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationQtHelp.ctl is v." + fwInstallation_getVersionString(csFwInstallationQtHelpLibVersion, csFwInstallationQtHelpLibTag), "INFO", 10);
  fwInstallation_throw("fwInstallationAgentDBConsistencyChecker.ctl script is v." + fwInstallation_getVersionString(FW_SYS_STAT_DB_AGENT_SCRIPT, FW_SYS_STAT_DB_AGENT_SCRIPT_TAG), "INFO", 10);
  return (areVersionsConsistent?-1:-2);
}
