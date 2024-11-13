#uses "fwInstallation/fwInstallation.ctl"
main()
{

//  if ( !globalExists("gFwInstallationLog") )
//    addGlobal("gFwInstallationLog", STRING_VAR);
//    
//  gFwInstallationLog = "";

  // if there are any postInstallation files execute them

  int iReturn;
  int i;
  bool postInstallsRun = false;

  dyn_string dynPostInstallFiles_all;

  if(fwInstallationRedu_isRedundant())
  {
    if (fwInstallation_getInstallOnlyInSplit())
    {
      bool isSplitMode = fwInstallationRedu_isSplitMode();
      if (!isSplitMode || (isSplitMode && fwInstallationRedu_isSplitActive()))
      {
        fwInstallation_throw("Post installation scripts could run only in the split passive peer!", "INFO", 26);
        exit(0);
        return;
      }
  
      if (isSplitMode && ! fwInstallationRedu_isSplitActive()) {
        while (fwInstallationRedu_isRecovering()) {
            delay(30);
        }
          
      }
    }
    else if (fwInstallationRedu_isPassive())
    {
      fwInstallation_throw("Post installation scripts could run only in the active peer!", "INFO", 26);
      exit(0);
      return;
    }
  }
  
  setUserId(getUserId("para"));
  
  string dp = fwInstallation_getInstallationPendingActionsDp();
  if(dpExists(dp))
  {
    if(_isPostInstallActionRequested(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_LEGACY_LIB)){
      fwInstallation_throw("Start generating legacy includes library", "INFO");
      fwInstallation_evalScriptFile(getPath(SCRIPTS_REL_PATH, FW_INSTALLATION_BUILD_LEGACY_LIB_SCRIPT), iReturn);
      if(iReturn != 0){
        fwInstallation_throw("Error while generating legacy includes library", "ERROR");
      }
      else{
        fwInstallation_throw("Completed generating legacy includes library - OK", "INFO");
      }
    }

    dyn_string components, scriptFiles;
    _fwInstallation_GetComponentsWithPendingPostInstall(components, scriptFiles);

    int scriptFilesNum = dynlen(scriptFiles);
    if(scriptFilesNum > 0){
      // Prepare postinstall scripts execution
      _flagPostInstallActionExecution(
              FW_INSTALLATION_POSTINSTALL_ACTION_BIT_POSTINSTALLS, scriptFilesNum);

      if(fwInstallationDB_getUseDB()){
        if(fwInstallationDB_connect() != 0){
            fwInstallation_throw("Failed to connect to the System Configuration DB before executing post-install and/or post-delete scripts", "WARNING", 10);
            _clearActionBits();
            return;
        }
      }
      fwInstallation_throw("Starting execution of Components' Post-Installation Scripts", "INFO", 26);
      postInstallsRun = true;
    }

    mapping component2PostInstallStatus;
    for(i = 1; i <= scriptFilesNum; i++)
    {
      _setActionCurrentStep(i); // report on postinstalls progress

      string component = components[i];
      string scriptFile = scriptFiles[i];
      fwInstallation_setCurrentComponent(component);
      fwInstallation_throw("Running " + component + " post-installation script: " +
                           scriptFile, "INFO", 26);
      // execute the file and check returned code
      fwInstallation_evalScriptFile(scriptFile, iReturn);

      if(iReturn != 0) {
        fwInstallation_throw("ERROR - execution of " + component + " post-installation script: " +
                             scriptFile + " failed", "ERROR", 26);
      } else {
        fwInstallation_throw("OK - execution of " + component + " post-installation script: " +
                             scriptFile + " completed", "INFO", 26);
      }

      // register component status based on returned code
      if(mappingHasKey(component2PostInstallStatus, component)) {
        component2PostInstallStatus[component] &= (iReturn == 0);
      } else {
        component2PostInstallStatus[component] = (iReturn == 0);
      }

      fwInstallation_unsetCurrentComponent();
    }

    // set component statuses based on combined result of their postInstall scripts
    dyn_string componentKeys = mappingKeys(component2PostInstallStatus);
    for(i = 1; i <= dynlen(componentKeys); i++) {
      fwInstallation_setComponentInstallationStatus(
              componentKeys[i], component2PostInstallStatus[componentKeys[i]]);
    }

    // all the files were executed - if there were any errors the user has been informed
    // clearing the fwInstallationInfo.postInstallFiles:_original.._value
    dpSet(dp + ".postInstallFiles", makeDynString());


    dynClear(dynPostInstallFiles_all);
    // get all the post delete files
    dpGet(dp + ".postDeleteFiles", dynPostInstallFiles_all);
    scriptFilesNum = dynlen(dynPostInstallFiles_all);
    if(scriptFilesNum > 0){
      _flagPostInstallActionExecution(
              FW_INSTALLATION_POSTINSTALL_ACTION_BIT_POSTDELETE, scriptFilesNum);
      fwInstallation_showMessage(makeDynString("Executing post delete  files ..."));
    }

    // for each post delete file
    for(i = 1; i <= scriptFilesNum; i++)
    {
      _setActionCurrentStep(i); // report on postdelete progress

      string postDeleteFile = dynPostInstallFiles_all[i];
      fwInstallation_setCurrentComponent(postDeleteFile);
      fwInstallation_throw("Running post-delete script: " + postDeleteFile, "INFO", 26);
      // execute the file
      fwInstallation_evalScriptFile(postDeleteFile , iReturn);
      // check the return value
      if(iReturn == -1) {
        fwInstallation_throw("ERROR - execution of post-delete script: " +
                             postDeleteFile + " failed", "ERROR", 26);
      } else {
        fwInstallation_throw("OK - execution of post-delete script: " +
                             postDeleteFile + " completed", "INFO", 26);
      }

      fwInstallation_unsetCurrentComponent();
    }

    // all the files were executed - if there were any errors the user has been informed
    // clearing the fwInstallationInfo.postDeleteFiles:_original.._value
    dpSet(dp + ".postDeleteFiles", makeDynString());

    if(_isPostInstallActionRequested(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP)){
      fwInstallation_evalScriptFile(getPath(SCRIPTS_REL_PATH, "fwInstallation/" +
                                            FW_INSTALLATION_QT_HELP_GENERATION_SCRIPT), iReturn);
      if(iReturn == -1){
        fwInstallation_throw("There was an error while attempting to regenerate Qt help collection", "ERROR");
      }
    }
    _clearActionBits();
  }
  else
    fwInstallation_throw("Dp does not exist: " + dp, "ERROR", 26);   
        
  //Re-sync unicos ows files if needed:
  if(isFunctionDefined("unConfigGenericFunctions_Create_Config_ows"))
  {
    callFunction("unConfigGenericFunctions_Create_Config_ows", "config_ows");
  }
    
  if(fwInstallationManager_executeAllReconfigurationActions(true))
  {
    fwInstallation_throw("There were errors executing the managers' reconfiguration actions", "WARNING", 26);
    delay(1); //Make sure that our message gets print out.
  }

  postInstallsRun = true;
  //Update System Configuration DB if required:
  if(postInstallsRun && fwInstallationDB_getUseDB())
  {
    if(fwInstallationDB_connect()){fwInstallation_throw("Failed to connect to the System Configuration DB after executing post-install and/or post-delete scripts", "WARNING", 26); return;}
    if(fwInstallationDB_registerProjectFwComponents()) {fwInstallation_throw("Failed to upate the System Configuration DB after execution of the component post-installation scripts", "WARNING", 26); return;}
//    DebugN("Wrinting log with", gFwInstallationLog);
//    fwInstallationDB_storeInstallationLog();
  }
 
  bool splitForced;
  string pairToLive;
  _fwInstallationRedu_getSplitInfo(splitForced, pairToLive);
  if(fwInstallationRedu_isSplitMode() && splitForced && pairToLive == fwInstallationRedu_myReduHostNum() && fwInstallation_getRestoreRedundancyAfterInstallation() == 1)
  {
    DebugN("Re-enabling redundancy", pairToLive);
    _fwInstallationRedu_setSplitInfo(0, "");
    fwInstallationRedu_setReduSplitOff(pairToLive);
    delay(30);
  }
  fwInstallation_throw("All post-install tasks completed, stopping fwScripts.lst manager", "INFO");
  exit(0);
}


/** To report on post-install progress the _userbits attribute of
  * fwInstallation_pendingActions[_2].postInstallFiles DPE is used.
  * The meaning of 4 bytes of that 32bit register are following:
  * - _userbyte1 - actions requested to be executed by postinstall script (this is in addtion to
  *                processing component scripts stored in DPE value). Action is requested when
  *                corresponding bit is set. Meaning of bits is defined in
  *                FW_INSTALLATION_POSTINSTALL_ACTION_BIT_* constants in fwInstallation.ctl library
  * - _userbyte2 - indicates current action being executed, meaning of bits is the same as in
  *                _userbyte1. Only one bit can be set at a time.
  * - _userbyte3 - holds the information on total number of steps that are to be completed by an
  *                action (8-bit value - max 255). This is to provide information on the progress
  *                of an action. Can be 0 if action can't provide progress information or while
  *                this information is being calculated.
  * - _userbyte4 - indicates the current step being executed.
  */

bool _isPostInstallActionRequested(int actionBit){
  string dp = fwInstallation_getInstallationPendingActionsDp();
  bool isRequested;
  dpGet(dp + ".postInstallFiles:_original.._userbit" + (string)(actionBit+1), isRequested);
  return isRequested;
}

_flagPostInstallActionExecution(int actionBit, char totalSteps){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSetWait(dp + ".postInstallFiles:_original.._userbyte2", (1<<actionBit),
              dp + ".postInstallFiles:_original.._userbyte3", totalSteps,
              dp + ".postInstallFiles:_original.._userbyte4", 0);
}

_setActionCurrentStep(char currentStep){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSetWait(dp + ".postInstallFiles:_original.._userbyte4", currentStep);
}

_clearActionBits(){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSetWait(dp + ".postInstallFiles:_original.._userbits", 0);
}
