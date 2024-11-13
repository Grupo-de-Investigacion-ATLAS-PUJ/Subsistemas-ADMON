// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file
  This file contains functions to perform actions needed to initialize installation tool.
  They initialize necessary global variables as well as perform upgrade of internal datapoints if needed.
*/

// Purposes:
// * Initialization of needed global variables each time the manager starts
// * Checking if initialization or upgrade is needed and performing respective actions

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "fwInstallation/fwInstallation.ctl"
// Would be good not to load this whole library. Needed functionality should be moved to some kind of utils library.
// fwInstallation.ctl (or other lib) should load that one.

//--------------------------------------------------------------------------------
// variables and constants

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationInitLibVersion = "9.1.3";
const string csFwInstallationInitLibTag = "";

/** Name of the init file loaded at start up of the tool.
 * @ingroup Constants
*/
const string FW_INSTALLATION_INIT_SCRIPT = "fwInstallationInitScript.ctl";

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/** This function needs to be called when starting Installation Tool panel or DB-Agent script
  * @param runPostInstall (in)  Flag that specifies whether pending post-install scripts, if any, must be run
  *        during initialization, default: true (yes)
  * @param installationPath (in)  If not empty: Component installation path to be set, it overwrites any previously
  *        configured path and path given in init file. Directory is created and registered as project path if needed
  @return 0 if OK, -1 if errors
*/
int fwInstallationInit_execute(bool runPostInstall = true, string installationPath = ""){
  if(!globalExists("gFwInstallationLog")){
    addGlobal("gFwInstallationLog", DYN_DYN_STRING_VAR);
  }
  if(!globalExists("gFwInstallationCurrentComponent")){
    addGlobal("gFwInstallationCurrentComponent", STRING_VAR);
  }
  fwInstallationInit_initPmonVariables();

  fwInstallationInit_configureProjectConfigFile();

  if(fwInstallationInit_configureDatapoints(FW_INSTALLATION_INIT_TOOL_COMPONENT) != 0){
    fwInstallation_setToolStatus(false);
    return -1;
  }

  // Install Agent here
  if(fwInstallationInit_configureDatapoints(FW_INSTALLATION_INIT_DB_AGENT_COMPONENT) != 0){
    fwInstallation_setToolStatus(false);
    return -1;
  }

  // Installation path was given as an argument - set a DP and create directory if not existing
  if(installationPath != ""){
    fwInstallationInit_configureInstallationDirectory(installationPath);
  }

  //Load init file as the user may have defined the schema owner there
  fwInstallationInit_loadInitFile();
  //Run init script
  if(fwInstallationInit_runInitScript()){
    fwInstallation_setToolStatus(false);
    return -1;
  }

  // If installation directory exists ensure, that it has proj_path entry in config file
  fwInstallationInit_ensureExistingInstallationDirectoryIsProjPath();

  fwInstallationInit_addPostInstallManagerToConsole();

  // Try DB-connection
  fwInstallationInit_tryDbConnection();
  // Add agent manager to console
  fwInstallationInit_addDbAgentManagerToConsole();

  if(runPostInstall){
    fwInstallation_executePostInstallScripts();
  }
  fwInstallation_setToolStatus(true);
  return 0;
}

/** This function checks whether a migration procedure has to be perfomed to upgrade fwInstallation from versions < 8.4.0 to the latest ones.
  * @return true if updating Installation Tool from version < 8.4.0, false otherwise
  */
bool fwInstallationInit_isCleanupNeeded(){
  if(!fwInstallationInit_consolidation_areLibsVersionsConsistent()){
    return true; // library versions are compared for the case when old libraries are already loaded - in this case cleanup procedure is obligatory
  }
  // additional checks needed when -LoadNoCtrlLib option is used, then comparison of library versions is not sufficient

  string fwInstallationDp = fwInstallation_getInstallationDp();
  if(dpExists(fwInstallationDp)){ // check if fwInstallation dp exists (is fwInstallation already initialized in the project)
    // look for obsolete config entries that are added by fwInstallation
    mapping obsoleteConfigLibs;
    fwInstallationInit_consolidation_getObsoleteConfigLibs(getPath(CONFIG_REL_PATH, "config"), obsoleteConfigLibs);
    if(mappinglen(obsoleteConfigLibs) > 0){
      return true;
    }
    // check previous fwInstallation version
    string fwInstallationVersion;
    dpGet(fwInstallationDp + ".version", fwInstallationVersion);
    if(fwInstallationVersion == ""){
      return true; // fwInstallation may be migrated from version, that did not set the 'version' dpe.
    }
    if(_fwInstallation_CompareVersions(fwInstallationVersion, "8.4.0", false, false, true) != 1){
      return true; //  fwInstallation version is lower than 8.4.0, cleanup needed
    }
  }
  return false; // version >= 8.4.0 or first run of fwInstallation
}

/** This function provides the migration path from the fwInstallation versions < 8.4.0 to the latest ones.
  * It updates the fwInstallation LoadCtrlLibs config entries, removes obsolete files and restarts manager.
  * When it is called in UI manager, user has to confirm the actions.
  * Note: Due to the changes in the library locations, this function has to be called before fwInstallation script/panel checks the consistency of the library versions.
  *       It is because the existing old versions of libraries are already loaded via LoadCtrlLibs entry in the config file,
          and the new libraries, which were not present in the previous version are loaded with #uses statement.
*/
fwInstallationInit_consolidationCleanup(){
  string configPath = getPath(CONFIG_REL_PATH, "config");

  mapping obsoleteConfigLibs;
  fwInstallationInit_consolidation_getObsoleteConfigLibs(configPath, obsoleteConfigLibs);

  dyn_string filesToRemove, dirsToRemove, dirsToRemoveRecursively;
  fwInstallationInit_consolidation_getObsoletePathsToRemove(filesToRemove, dirsToRemove, dirsToRemoveRecursively);

  if(mappinglen(obsoleteConfigLibs) == 0 && dynlen(filesToRemove) == 0 &&
     dynlen(dirsToRemoveRecursively) == 0){
    return; // we've got there only because version number is not updated yet, no need for cleanup
  }

  fwInstallation_throw("fwInstallation will perform the update of its entries in project config file and obsolete files' cleanup", "INFO", 28);

  bool isLoadNoCtrlLibsOptionUsed = !isFunctionDefined("RootPanelOn"); // detect whether we use -LoadNoCtrlLib option to start manager
                                                                       // in this case the RootPanelOn function from panel.ctl is not defined
  if(myManType() == UI_MAN){
    if(isLoadNoCtrlLibsOptionUsed){
      execScript("#uses \"panel.ctl\" main(){}"); // needed as panels.ctl is not yet loaded
    }
    fwInstallation_throw("Waiting for user decision...", "INFO", 28);
    dyn_string ds;
    dyn_float df;
    ChildPanelOnCentralModalReturn("fwInstallation/fwInstallationUpgrade.pnl", "InstallationToolUpgrade",
                                   makeDynString("$obsoleteCfgLibs:" + fwInstallationInit_mappingObsoleteCfgLibsToString(obsoleteConfigLibs),
                                                 "$filesToRemove:" + strjoin(filesToRemove, "|"),
                                                 "$dirsToRemove:" + strjoin(dirsToRemove, "|"),
                                                 "$dirsToRmvRec:" + strjoin(dirsToRemoveRecursively, "|")), df, ds);
    if(dynlen(ds) <= 0 || ds[1] != "yes"){
      fwInstallation_throw("User decided not to continue the Installation Tool upgrade procedure. Closing the panel.", "WARNING", 28);
      PanelOff(); // close fwInstallation panel, but don't stop the manager
      delay(10); // ensure that panel will be closed, before we continue
      return;
    }
    fwInstallation_throw("User agreed to continue the Installation Tool upgrade procedure.", "INFO", 28);
  }

  if(fwInstallationInit_consolidation_removeObsoleteConfigLibs(configPath, obsoleteConfigLibs) != 0){
    fwInstallation_throw("Failed to remove obsolete fwInstallation entries from the config file. Cannot continue. Current manager will be stopped.", "ERROR", 28);
    exit(1);
  }

  int addCfgEntriesStatus = fwInstallationInit_configureProjectConfigFile();

  fwInstallationInit_consolidation_removeObsoletePaths(filesToRemove, dirsToRemove, dirsToRemoveRecursively);

  fwInstallation_throw("---------------------------", "INFO", 28);
  fwInstallation_throw("Cleanup procedure finished.", "INFO", 28);


  if(addCfgEntriesStatus != 0){
    fwInstallationInit_notifyUserAndStopManager(
        "Failed to add required entries to the config file. It is not recommended to continue until this problem is fixed. Current UI manager will be stopped now.",
        "Required project config entries are missing. It is not recommended to continue until this problem is fixed. Current manager will be stopped now.",
        "ERROR", 1);
  }

  if(mappinglen(obsoleteConfigLibs) > 0){
    fwInstallationInit_notifyUserAndStopManager(
        "Installation Tool upgrade to version 8.4.0 finished.\nProject config file was updated. Obsolete libraries are still loaded by current UI manager. It is neccessary to load the new libraries.\n" +
        "Current UI manager will be stopped. Please restart it manually, if start mode is different than 'always'.\nIf -LoadNoCtrlLib option was used, do not activate it again.",
        "Project config file was updated. Current manager will be stopped, please restart it in order to continue. If -LoadNoCtrlLib option was used, do not activate it again.");
  }
  if(isLoadNoCtrlLibsOptionUsed){
    fwInstallationInit_notifyUserAndStopManager(
        "Installation Tool upgrade to version 8.4.0 finished.\nDetected, that UI manager was started with -LoadNoCtrlLib option. It is not recommended to continue operation, " +
        "having this option activated after the upgrade is finished.\nCurrent UI manager will be stopped. Please restart it manually without using -LoadNoCtrlLib option.",
        "Detected -LoadNoCtrlLib option for manager. Current manager will be stopped, please restart it without using -LoadNoCtrlLib option in order to continue");
  }
  if(!fwInstallationInit_consolidation_areLibsVersionsConsistent()){
    fwInstallationInit_notifyUserAndStopManager(
        "Installation Tool upgrade to version 8.4.0 finished.\nObsolete libraries are still loaded by current UI manager. It is neccessary to load the new libraries.\n" +
        "Current UI manager will be stopped. Please restart it manually, if start mode is different than 'always'.",
        "Current manager will be stopped to unload obsolete libraries, please restart it in order to continue.");
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**** Functions called from fwInstallationInit_isCleanupNeeded() and fwInstallationInit_consolidationCleanup() ****/

/** For purpose of consolidation cleanup checks if version of this (fwInstallationInit.ctl) library and main library are the same */
private bool fwInstallationInit_consolidation_areLibsVersionsConsistent(){
  return (csFwInstallationInitLibVersion == csFwInstallationToolVersion &&
          csFwInstallationInitLibTag == csFwInstallationToolTag);
}

/** Creates a string from a mapping with obsolete fwInstallation config entries */
private string fwInstallationInit_mappingObsoleteCfgLibsToString(const mapping &obsoleteConfigLibs){
  string obsoleteCfgLibsString;
  int obsoleteConfigLibsLen = mappinglen(obsoleteConfigLibs);
  for(int i=1;i<=obsoleteConfigLibsLen;i++){
    string section = mappingGetKey(obsoleteConfigLibs, i);
    string libsStr = strjoin(obsoleteConfigLibs[section], "|");
    obsoleteCfgLibsString += section + "#" + libsStr + "#";
  }
  return strrtrim(obsoleteCfgLibsString, "#");
}


/** Creates a mapping with obsolete fwInstallation LoadCtrlLibs entries in project config file */
private int fwInstallationInit_consolidation_getObsoleteConfigLibs(string configPath, mapping &obsoleteConfigLibs){
  const dyn_string obsoleteFwInstallationLibraries = makeDynString("fwInstallation.ctl", "fwInstallationDB.ctl");
  dyn_string cfgSections;
  if(fwInstallation_getSections(cfgSections) != 0){
    fwInstallation_throw("Failed to retrieve list sections in project config file. " +
                         "Cannot detect if config contains obsolete fwInstallation entries", "ERROR", 28);
    return -1;
  }
  dyn_string sections = dynIntersect(makeDynString("ui", "ctrl"), cfgSections);
  int sectionsLen = dynlen(sections);
  for(int i=1;i<=sectionsLen;i++){
    string section = sections[i];
    dyn_string loadedCtrlLibs;
    if(paCfgReadValueList(configPath, section, "LoadCtrlLibs", loadedCtrlLibs) != 0){
      fwInstallation_throw("Failed to read list of libraries loaded with 'LoadCtrlLibs' entry from config file", "ERROR", 28);
      return -1;
    }
    dyn_string oldLibsLoaded = dynIntersect(obsoleteFwInstallationLibraries, loadedCtrlLibs);
    if(dynlen(oldLibsLoaded) > 0){
      obsoleteConfigLibs[section] = oldLibsLoaded;
    }
  }
  return 0;
}

/** Removes obsolete fwInstallation entries from the project config file */
private int fwInstallationInit_consolidation_removeObsoleteConfigLibs(string configPath, const mapping &obsoleteConfigLibs){
  dyn_string removeFromSections = mappingKeys(obsoleteConfigLibs);
  int removeFromSectionsLen = dynlen(removeFromSections);
  bool err;
  for(int i=1;i<=removeFromSectionsLen;i++){
    string section = removeFromSections[i];
    dyn_string libsToRemove = obsoleteConfigLibs[section];
    int libsToRemoveLen = dynlen(libsToRemove);
    for(int j=1;j<=libsToRemoveLen;j++){
      if(paCfgDeleteValue(configPath, section, "LoadCtrlLibs", libsToRemove[j]) != 0){
        err = true;
        fwInstallation_throw("Failed to remove 'LoadCtrlLibs = " + libsToRemove[j] + " entry from the [" + section + "] section of the project config file.", "ERROR", 28);
      }else{
        fwInstallation_throw("LoadCtrlLibs = " + libsToRemove[j] + " entry removed from the [" + section + "] section of the project config file", "INFO", 28);
      }
    }
  }
  if(err){
    fwInstallation_throw("Please try to locate and manually remove reported entries in the project config file or contact support.", "INFO", 28);
    return -1;
  }
  return 0;
}

/** Creates lists of obsolete fwInstallation directories/files in the project */
private fwInstallationInit_consolidation_getObsoletePathsToRemove(dyn_string &filesToRemove, dyn_string &dirsToRemove, dyn_string &dirsToRemoveRecursively){
  const dyn_string obsoleteScriptFiles =
      makeDynString("fwInstallationAgentDBConsistencyChecker.ctl",
                    "fwInstallationExitSplitMode.ctl",
                    "fwInstallationFakeScript.ctl",
                    "fwInstallationGetDpe.ctl",
                    "fwInstallation_projectRegistration.ctl");
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInProjDirs(SCRIPTS_REL_PATH, obsoleteScriptFiles));

  const dyn_string obsoleteLibFiles =
      makeDynString("fwInstallation.ctl",
                    "fwInstallationDBAgent.ctl",
                    "fwInstallationDBCache.ctl",
                    "fwInstallationDB.ctl",
                    "fwInstallationDBUpgrade.ctl",
                    "fwInstallationDeprecated.ctl",
                    //"fwInstallationFSM.ctl",
                    //"fwInstallationFSMDB.ctl",
                    "fwInstallationManager.ctl",
                    "fwInstallationPackager.ctl",
                    "fwInstallationProjParam.ctl",
                    "fwInstallationRedu.ctl",
                    "fwInstallationUpgrade.ctl",
                    "fwInstallationXml.ctl");
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInProjDirs(LIBS_REL_PATH, obsoleteLibFiles));

  // get Installation Tool path from the obsolete files added so far to the list (don't want to use getPath() later on some generic dir names like en_US.iso88591/)
  string fwInstallationPath = PROJ_PATH; // fallback;
  if(dynlen(filesToRemove) > 0){
    string fwInstallationFilePath = filesToRemove[1];

    while(_fwInstallation_fileName(fwInstallationFilePath) != "scripts" &&
          _fwInstallation_fileName(fwInstallationFilePath) != ""){
      fwInstallationFilePath = _fwInstallation_baseDir(fwInstallationFilePath);
    }
    if(_fwInstallation_fileName(fwInstallationFilePath) != ""){
      fwInstallationPath = _fwInstallation_baseDir(fwInstallationFilePath);
    }
    fwInstallation_throw("Detected location of old version of Installation Tool: " + fwInstallationPath, "INFO", 28);
  }

  const dyn_string obsoletePictureFiles =
      makeDynString("5.bmp", "71.xpm", "arrow_single_right_16.png", "fwInstallation_question.bmp", "open_22.png");
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInDir(fwInstallationPath + PICTURES_REL_PATH, obsoletePictureFiles));

  dyn_string obsoleteDbSchemaFiles = getFileNames(fwInstallationPath + CONFIG_REL_PATH, "fwSysStat_*.sql");
  dynAppendConst(obsoleteDbSchemaFiles, getFileNames(fwInstallationPath + CONFIG_REL_PATH, "fw_sys_stat_sas_target*.sql"));
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInDir(fwInstallationPath + CONFIG_REL_PATH, obsoleteDbSchemaFiles));

  const string obsoleteImageDir = "fwInstallation/";
  dynAppendConst(dirsToRemoveRecursively, fwInstallationInit_consolidation_filterPathsExistingInProjDirs(IMAGES_REL_PATH, makeDynString(obsoleteImageDir)));

  const string obsoleteIsoDir = "en_US.iso88591/";

  const dyn_string obsoleteMsgCatFiles = makeDynString(obsoleteIsoDir + "fwInstallation.cat");
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInProjDirs(MSG_REL_PATH, obsoleteMsgCatFiles));
  dynAppendConst(dirsToRemove, fwInstallationInit_consolidation_filterPathsExistingInDir(fwInstallationPath + MSG_REL_PATH, obsoleteIsoDir));

  const string obsoleteWebHelpDir = obsoleteIsoDir + "WebHelp/";
  const string obsoleteFwInstallationHelpDir = obsoleteWebHelpDir + "fwInstallation/";
  dynAppendConst(dirsToRemoveRecursively, fwInstallationInit_consolidation_filterPathsExistingInProjDirs(HELP_REL_PATH, obsoleteFwInstallationHelpDir));
  dynAppendConst(dirsToRemove, fwInstallationInit_consolidation_filterPathsExistingInDir(fwInstallationPath + HELP_REL_PATH, obsoleteWebHelpDir));
  dynAppendConst(dirsToRemove, fwInstallationInit_consolidation_filterPathsExistingInDir(fwInstallationPath + HELP_REL_PATH, obsoleteIsoDir));

  const string obsoleteReleaseNotesFile = makeDynString("fwInstallationReleaseNotes.txt");
  dynAppendConst(filesToRemove, fwInstallationInit_consolidation_filterPathsExistingInProjDirs("", obsoleteReleaseNotesFile));
}

/** Returns list of existing paths from given list of obsolete paths, relative the the given project-specific directory (eg. data/) */
private dyn_string fwInstallationInit_consolidation_filterPathsExistingInProjDirs(string relativeProjPath, const dyn_string &obsoletePathsList){
  dyn_string existingObsoletePathsList;
  int obsoletePathsListLen = dynlen(obsoletePathsList);
  for(int i=1;i<=obsoletePathsListLen;i++){
    string obsoletePath = getPath("", relativeProjPath + obsoletePathsList[i]);
    if(obsoletePath != ""){
      dynAppend(existingObsoletePathsList, obsoletePath);
    }
  }
  return existingObsoletePathsList;
}

/** Returns list of existing paths from given list of obsolete paths relative to the given directory */
private dyn_string fwInstallationInit_consolidation_filterPathsExistingInDir(string absoluteDirPath, const dyn_string &relativePathsList){
  dyn_string absolutePathsList;
  int relativePathsListLen = dynlen(relativePathsList);
  for(int i=1;i<=relativePathsListLen;i++){
    string absolutePath = absoluteDirPath + relativePathsList[i];
    if(access(absolutePath, F_OK) == 0){
      dynAppend(absolutePathsList, absolutePath);
    }
  }
  return absolutePathsList;
}

/** Removes given obsolete fwInstallation directories/files from the project */
private fwInstallationInit_consolidation_removeObsoletePaths(const dyn_string &filesToRemove, const dyn_string &dirsToRemove, const dyn_string &dirsToRemoveRecursively){
  fwInstallation_cleanupObsoleteFilesFromPath(gFwInstallationComponentName, "", filesToRemove);
  fwInstallation_cleanupObsoleteFilesFromPath(gFwInstallationComponentName, "", dirsToRemoveRecursively, true);
  fwInstallation_cleanupObsoleteFilesFromPath(gFwInstallationComponentName, "", dirsToRemove);
}

/** Prints message to the log and in UI manager it displays pop-up informing about necessity to stop manager. Then terminates the manager with given exit code. */
private fwInstallationInit_notifyUserAndStopManager(string uiMessage, string logMessage, string messageType = "INFO", int exitCode = 0){
  fwInstallation_throw(logMessage, messageType, 28);
  if(myManType() == UI_MAN){
    dyn_string ds;
    dyn_float df;
    ChildPanelOnCentralModalReturn("fwInstallation/fwInstallation_messageInfo.pnl", "Manager restart required",
                                   makeDynString("$text:" + uiMessage, "$okLabel:Continue", "$hideCancelBtn:yes"), df, ds);
  }
  exit(exitCode);
}

///////////////////////////////////////////////////////////////////////////////////////
/**** Functions called from fwInstallationInit_execute() and subsequent functions ****/

/** Ensure that fwInstallation global variables to store pmon credentials exist and have default values
  */
private fwInstallationInit_initPmonVariables(){
  if(!globalExists("gFwInstallationPmonUser")){
    addGlobal("gFwInstallationPmonUser", STRING_VAR);
  }
  if(!globalExists("gFwInstallationPmonPwd")){
    addGlobal("gFwInstallationPmonPwd", STRING_VAR);
  }
  gFwInstallationPmonUser = "N/A";
  gFwInstallationPmonPwd = "N/A";
}

/** Adds the main Installation Tool library to the [ui] and [ctrl] section of the project config file
  * @note Not marked as private as deprecated fwInstallation_addLibToConfig() is calling this function
  * @return 0 if config entries added successfully or already there, -1 when error
  */
int fwInstallationInit_configureProjectConfigFile(){
  bool err = (fwInstallationInit_addInstallationToolLibToConfigSection("ui") != 0);
  err |= (fwInstallationInit_addInstallationToolLibToConfigSection("ctrl") != 0);
  return err?-1:0;
}

/** Adds the main Installation Tool library to the given section of the project config file
  * @param section (in)  Project config file section
  * @return 0 if config entries added successfully or already there, -1 when error
  */
private int fwInstallationInit_addInstallationToolLibToConfigSection(string section){
  dyn_string libs;
  paCfgReadValueList(PROJ_PATH + CONFIG_REL_PATH + FW_INSTALLATION_CONFIG_FILE_NAME, section, "LoadCtrlLibs", libs);
  if(dynContains(libs, "fwInstallation/fwInstallation.ctl") > 0){ // Installation tool library already in config
    return 0;
  }
  if(paCfgInsertValue(PROJ_PATH + CONFIG_REL_PATH + FW_INSTALLATION_CONFIG_FILE_NAME, section, "LoadCtrlLibs",
                      "fwInstallation/fwInstallation.ctl") == 0){
    fwInstallation_throw("Added 'LoadCtrlLibs = \"fwInstallation/fwInstallation.ctl\"' entry to the " +
                         "[" + section + "] section of the project config file", "INFO");
    return 0;
  }
  fwInstallation_throw("Failed to add 'LoadCtrlLibs = \"fwInstallation/fwInstallation.ctl\"' entry to the " +
                       "[" + section + "] section of the project config file", "ERROR");
  return -1;
}

/** This function updates the component name stored in name dpe in case it is different than the name included in component datapoint name
  * @note This function may be deprecated in the subsequent releases.
  */
fwInstallationInit_updateComponentDps(){
  dyn_string compDps = fwInstallation_getInstalledComponentDps();
  for(int i=1;i<=dynlen(compDps);i++){
    string compDp = compDps[i];
    string name;
    dpGet(compDp + ".name", name);
    if(name != fwInstallation_dp2name(compDp)){
      dpSet(compDp + ".name", fwInstallation_dp2name(compDp));
    }
  }
}

/** This function updates the version of the installation tool in the internal datapoint.
  * Tool version is taken from the fwInstallation.ctl library.
  * @return 0 if datapoint was updated successfully or update was not needed (version in dp and library are equal),
  *         -1 if update failed
  */
int fwInstallationInit_updateToolVersionInDp(){
  string versionLib;
  fwInstallation_getToolVersionLocal(versionLib);

  bool updateNeeded;
  string versionDp;
  if(fwInstallation_getToolVersionFromDp(versionDp) != 0){
    updateNeeded = true;
    fwInstallation_throw("fwInstallationInit_updateToolVersionInDp() -> Could not retrieve installation tool" +
                         " version from datapoint, current version from file will be set in dp", "WARNING");
  }else if(versionDp != versionLib){
    updateNeeded = true;
  }
  if(!updateNeeded){
    return 0; // Version in file and in dp are the same, no need to update, exit.
  }

  if(dpSet(fwInstallation_getInstallationDp() + ".version", versionLib) != 0){
    fwInstallation_throw("fwInstallationInit_updateToolVersionInDp -> Failed to update Installation Tool "+
                         "version in datapoint to version=" + versionLib);
    return -1;
  }

  if(versionDp != ""){ // Other version of installation tool was present in dp, display info about update.
    fwInstallation_throw("INFO: Installation tool updated to version: " + versionLib +
                         ". Previous version: " + versionDp, "INFO");
  }
  return 0;
}

/** This function imports the Installation Tool ASCII init file if it exists
  * @return 0 if no import done or import done successfully, -1 in case of import errors.
  */
int fwInstallationInit_loadInitFile(){
  const string asciiFile = getPath(CONFIG_REL_PATH, gFwInstallationInitFile); // try to find fwInstallationInit.config ASCII file
  if(asciiFile == "" || access(asciiFile, R_OK) != 0){ // Exit if init file does not exist
    return 0;
  }
  fwInstallation_throw("FW Installation Tool Init file found. Loading now: " + asciiFile, "INFO", 10);

  dyn_string asciiImportOptions;

  // In split mode we need to explicitly connect to only one host,
  // the one that we are currently being executed on
  if(fwInstallationRedu_isRedundant() && fwInstallationRedu_isSplitMode()){
    // Note: we assume that event and data hosts are the same, this will not support some exotic configurations
    // where active data & even are on separate hosts
    string hostname = fwInstallation_getHostname(myReduHost());
    // If this is a Remote UI - don't try loading init file
    if(strtoupper(hostname) != strtoupper(fwInstallation_getHostname())){
      fwInstallation_throw("fwInstallationInit_loadInitFile(): skipping loading of init file (redundand system in split mode, remote UI).", "WARNING", 10);
      return 0;
    }
    dynAppend(asciiImportOptions, "-event " + hostname + ":" + (string)eventPort());
    dynAppend(asciiImportOptions, "-data "  + hostname + ":" + (string)dataPort());
  }

  dynAppend(asciiImportOptions, "-yes"); // Allow update of DP-types

  string asciiLogFile;
  if(access(PROJ_PATH + LOG_REL_PATH, W_OK) != 0 ||
     fwInstallation_ensureAsciiImportLogFileSizeLimit() != 0){ // Can we write to the log directory? Adjust command line accordingly
    fwInstallation_throw("fwInstallationInit_loadInitFile() -> Project log directory not writeable. Omitting stderr output.", "warning");
    dynAppend(asciiImportOptions, "-noVerbose");
  }else{
    dynAppend(asciiImportOptions, "-log +stderr");
    dynAppend(asciiImportOptions, "-log -file");
    asciiLogFile = fwInstallation_getAsciiImportLogFilePath();
  }

  string asciiCommand = fwInstallation_getImportAsciiManagerCommand(asciiFile, asciiImportOptions, asciiLogFile, asciiLogFile);
  int errCode = system(asciiCommand);
  if(_UNIX && errCode > 128){
    errCode -= 256;
  }
  if(errCode < 0){
    fwInstallation_throw("fwInstallationInit_loadInitFile() -> Errors while importing FW Installation Tool Init file.", "ERROR");
    return -1;
  }
  if(errCode > 0){
    fwInstallation_throw("fwInstallationInit_loadInitFile() -> Warings while importing FW Installation Tool Init file.", "WARNING");
  }
  // If installationDirectoryPath is defined in init file, make sure that directory exists
  string instDir;
  dpGet(fwInstallation_getInstallationDp() + ".installationDirectoryPath", instDir);
  if(instDir == ""){
    fwInstallation_throw("fwInstallationInit_loadInitFile() -> Installation directory is not specified, adding to project paths skipped.", "INFO", 10);
    return 0;
  }
  return fwInstallationInit_ensureInstallationDirectoryIsCreated(instDir);
}

/** This function executes the Installation Tool init script if it exists
  * @return Value returned by Init script, 0 if it does not exists
  */
int fwInstallationInit_runInitScript(){
  int retVal = 0;
  string initScriptPath = getPath(SCRIPTS_REL_PATH, FW_INSTALLATION_INIT_SCRIPT);
  if(initScriptPath != ""){
    fwInstallation_throw("FW Installation Tool Init script found. Executing now: " + initScriptPath, "INFO", 10);
    fwInstallation_evalScriptFile(initScriptPath, retVal);
    if(retVal != 0){
      fwInstallation_throw("There were errors while executing the init script of FW Component Installation Tool", "ERROR");
    }
  }
  return retVal;
}

/** This function checks the WinCC OA version and patch level that runs the project
  * and updates this information in the internal datapoint if new version/patch is detected.
  * @return 0 if version/patch are the same as stored internally or an update of internal dpe was successful
  *         -1 if failed to update internal version/path info
  */
int fwInstallationInit_updateWCCOAInfo(){
  dyn_string patches;
  string version = fwInstallation_getPvssVersion(patches);

  string dp = fwInstallation_getInstallationDp();
  dyn_string patchesInDp;
  string versionInDp;
  dpGet(dp + ".projectInfo.wccoaVersion", versionInDp,
        dp + ".projectInfo.wccoaPatchList", patchesInDp);

  bool isProjectInfoUpdateNeeded;
  if(versionInDp == ""){
    isProjectInfoUpdateNeeded = true;
  }else{
    string currentPatchLevel = (dynlen(patches) > 0)?patches[dynlen(patches)]:"";
    if(version != versionInDp){
      isProjectInfoUpdateNeeded = true;
      fwInstallation_throw("First run of Installation Tool in new WinCC OA version: " + version +
                           " " + currentPatchLevel, "INFO", 10);
    }else if(patches != patchesInDp){
      isProjectInfoUpdateNeeded = true;
      string previousPatchLevel = (dynlen(patchesInDp) > 0)?patchesInDp[dynlen(patchesInDp)]:"";
      if(currentPatchLevel != previousPatchLevel){
        fwInstallation_throw("First run of Installation Tool in WinCC OA version: " + version +
                             " with new patch level: " + currentPatchLevel, "INFO", 10);
      }
    }
  }
  int retVal;
  if(isProjectInfoUpdateNeeded){
    retVal = dpSet(dp + ".projectInfo.wccoaVersion", version,
                   dp + ".projectInfo.wccoaPatchList", patches);
  }
  return retVal;
}

/** Sets the component installation path in internal datapoint and creates it if it does not exist.
  */
private fwInstallationInit_configureInstallationDirectory(string installationDirectoryPath){
  if(dpSetWait(fwInstallation_getInstallationDp() + ".installationDirectoryPath", installationDirectoryPath) != 0){
    fwInstallation_throw("Could not save installation directory path (" + installationDirectoryPath +
                         ") in internal datapoint", "ERROR");
  }else{
    fwInstallationInit_ensureInstallationDirectoryIsCreated(installationDirectoryPath);
  }
}

/** Checks if given installation directory exists and creates it if not.
  */
private int fwInstallationInit_ensureInstallationDirectoryIsCreated(string installationDirectoryPath){
  if(access(installationDirectoryPath, F_OK) != 0){
    fwInstallation_throw("Requested component installation directory: '" + installationDirectoryPath + "' does not exist, " +
                         "will be created now", "INFO", 10);
    if(!mkdir(installationDirectoryPath, 777) || !isdir(installationDirectoryPath)){
      fwInstallation_throw("Could not create component installation directory: " + installationDirectoryPath +
                           ". Please create it manually and restart Component Installation Tool", "ERROR");
      return -1;
    }
  }
  return 0;
}

/** If component installation path stored in internal datapoint is valid and the directory exists,
  * add it to config proj_path if not yet there.
  */
private fwInstallationInit_ensureExistingInstallationDirectoryIsProjPath(){
  string instDir;
  dpGet(fwInstallation_getInstallationDp() + ".installationDirectoryPath", instDir);
  if(instDir == "" || access(instDir, W_OK) != 0){
    return;
  }
  if(fwInstallation_addProjPath(instDir, 999) != 0){
    fwInstallation_throw("Configured component installation directory: '" + instDir + "' could not be " +
                         "registered as project path. Please correct this manually", "ERROR");
  }
}

/** Add WCCOActrl manager running postinstall scripts
  */
private fwInstallationInit_addPostInstallManagerToConsole(){
  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "once", 30, 1, 1,
                            FW_INSTALLATION_SCRIPTS_MANAGER_CMD);
}

/** Add WCCOActrl manager running DB-Agent
  */
private fwInstallationInit_addDbAgentManagerToConsole(){
  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "always", 30, 3, 3,
                            FW_INSTALLATION_DB_AGENT_MANAGER_CMD);
}

/** If configured, try to connect with Configuration and System Information database and check if schema is supported
  */
fwInstallationInit_tryDbConnection(){
  if(!fwInstallationDB_getUseDB() || fwInstallationDB_connect() != 0){
    return;
  }
  string version = ""; // Check version of the schema
  int getSchemaRetVal = fwInstallationDB_getSchemaVersion(version);
  if(getSchemaRetVal != 0 || !fwInstallationDB_compareSchemaVersion()){
    fwInstallationDB_closeDBConnection(); // Disconnect DB as DB schema is wrong or has wrong version
    fwInstallationDB_setUseDB(false);

    if(getSchemaRetVal != 0){ // Schema not found
      fwInstallation_throw("fwInstallationInit_tryDbConnection(): Failed to retrieve version of the DB schema. " +
                           "Please check if Configuration DB System Information schema is present in the DB");
    }else{ // Wrong schema version
      fwInstallation_throw("fwInstallationInit_tryDbConnection(): Current DB schema version: " + version + " is lower than " +
                           "required: " + FW_INSTALLATION_DB_REQUIRED_SCHEMA_VERSION + ". Please upgrade the DB schema");
    }
  }else{
    int projectId = -1;
    fwInstallationDB_isProjectRegistered(projectId);
  }
}

/** Installation Tool Components: main Tool and DB-Agent */
const string FW_INSTALLATION_INIT_TOOL_COMPONENT = "Tool";
const string FW_INSTALLATION_INIT_DB_AGENT_COMPONENT = "DB-Agent";

/** Checks/initializes/updates Installation Tool datapoints in the project.
  * - verifies if required DP-Types and DPs exist in the project, missing ones are created
  * - if needed, performs DP-Type update
  * - sets default DPE values where needed
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return 0 when success, -1 in case of error
  */
private int fwInstallationInit_configureDatapoints(string installationToolComponent){
  bool isFirstRun;
  dyn_string dpTypesToCreate = fwInstallationInit_checkDpTypesConsistency(isFirstRun, installationToolComponent);
  if(isFirstRun){
    fwInstallationInit_showFirstStartNotification(installationToolComponent);
  }
  fwInstallationInit_createDpTypes(dpTypesToCreate);
  if(dynlen(dpTypesToCreate) > 0){
    fwInstallation_throw("Could not create following internal Installation " + installationToolComponent + " DP-types: " +
                         strjoin(dpTypesToCreate, ", ") + ". Please try to start Installation Tool/DB-Agent again or contact support", "ERROR");
    return -1;
  }
  mapping dpsToCreate = fwInstallationInit_checkDpsConsistency(isFirstRun, installationToolComponent);
  mapping dpsCreated = fwInstallationInit_createDps(dpsToCreate);
  if(mappinglen(dpsToCreate) > 0){
    fwInstallation_throw("Could not create following internal Installation " + installationToolComponent + " datapoints: " +
                         strjoin(mappingKeys(dpsToCreate), ", ") + ". Please try to start Installation Tool/DB-Agent " +
                         "again or contact support", "ERROR");
    return -1;
  }
  if(isFirstRun){
    fwInstallation_throw("Internal DP-types and datapoints for the Installation " + installationToolComponent + " created", "INFO", 10);
  }

  fwInstallationInit_setDefaultDpValues(dpsCreated, installationToolComponent);

  if(fwInstallationRedu_isSplitMode() || !fwInstallationRedu_isPassive()){ // to keep previous behaviour regarding DP-type upgrade
    mapping dpTypeUpdateActions;
    if(fwInstallationInit_checkDpTypeUpdates(dpTypeUpdateActions, installationToolComponent) != 0){
      fwInstallation_throw("Could not verify if update of internal " + installationToolComponent + " DP-types is needed", "ERROR");
      return -1;
    }
    if(mappinglen(dpTypeUpdateActions) > 0){
      dyn_string dpTypesToUpdate = mappingKeys(dpTypeUpdateActions);
      fwInstallation_throw("Updating the following internal " + installationToolComponent + " DP-types: " +
                           strjoin(dpTypesToUpdate, ", "), "INFO", 10);
      fwInstallationInit_createDpTypes(dpTypesToUpdate);
      if(dynlen(dpTypesToUpdate) > 0){
        fwInstallation_throw("Could not update following internal " + installationToolComponent + " DP-types: " +
                             strjoin(dpTypesToUpdate, ", ") + ". Please try to start Installation Tool/DB-Agent " +
                             "again or contact support", "ERROR");
        return -1;
      }
      fwInstallationInit_executeDpTypeUpdateActions(dpTypeUpdateActions, installationToolComponent);
    }
  }
  fwInstallationInit_updateDpValues(installationToolComponent);

  return 0;
}

/** Prints to the log information about first run of the given installation tool component
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_showFirstStartNotification(string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: fwInstallation_throw("Starting the Installation Tool for the first time", "INFO", 10); break;
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: fwInstallation_throw("Installing Installation Tool DB Agent", "INFO", 10); break;
  }
}

/// ========================== DP-types consistency checking ==========================

/** Checks whether all required DP-Types exists in the project and returns the list of missing ones
  * @param isFirstRun (out)  If none of DP-Types is found it is set to true. This flag indicates a first run of the installation tool
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return List of missing DP-Types
  */
private dyn_string fwInstallationInit_checkDpTypesConsistency(bool &isFirstRun, string installationToolComponent){
  dyn_string requiredDpTypes = fwInstallationInit_getRequiredDpTypes(installationToolComponent);
  dyn_string missingDpTypes = fwInstallationInit_getMissingDpTypes(requiredDpTypes, installationToolComponent);
  int missingDpTypesLen = dynlen(missingDpTypes);
  if(missingDpTypesLen == dynlen(requiredDpTypes)){
    isFirstRun = true;
  }else if(missingDpTypesLen > 0){
    fwInstallationInit_reportDpTypeInconsistency(missingDpTypes, installationToolComponent);
  }
  return missingDpTypes;
}

/** Returns the list of DP-Types that are required by a given Installation Tool component
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return List of required DP-Types
  */
private dyn_string fwInstallationInit_getRequiredDpTypes(string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: return fwInstallationInit_getRequiredDpTypes_tool();
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: return fwInstallationInit_getRequiredDpTypes_dbAgent();
  }
  fwInstallation_throw("Unknown Installation Tool Component: " + installationToolComponent +
                       ". Cannot retrieve required DP-Types", "ERROR");
  return makeDynString();
}

/** From given list of DP-Types returns the ones that are missing in the project
  * @param requiredDpTypes  List of required DP-Types
  * @return List of missing DP-Types
  */
private dyn_string fwInstallationInit_getMissingDpTypes(const dyn_string &requiredDpTypes){
  dyn_string missingDpTypes;
  const dyn_string systemDpTypes = dpTypes();
  int requiredDpTypesLen = dynlen(requiredDpTypes);
  for(int i=1;i<=requiredDpTypesLen;i++){
    if(dynContains(systemDpTypes, requiredDpTypes[i]) <= 0){
      dynAppend(missingDpTypes, requiredDpTypes[i]);
    }
  }
  return missingDpTypes;
}

/** Prints to the log information about DP-Types that needs to be created because they are missing or
  * because it is a first run of a new version of the Installation Tool, that adds new DP-Types
  * @param missingDpTypes  List of necessary installation tool DP-Types that are missing in the project
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_reportDpTypeInconsistency(const dyn_string &missingDpTypes, string installationToolComponent){
  dyn_string newDpTypes = fwInstallationInit_getNewDpTypes(missingDpTypes, installationToolComponent);
  int missingDpTypesLen = dynlen(missingDpTypes);
  for(int i=1;i<=missingDpTypesLen;i++){
    string missingDpType = missingDpTypes[i];
    if(dynContains(newDpTypes, missingDpType) > 0){
      string registeredVersion, localVersion;
      fwInstallation_getToolVersionFromDp(registeredVersion);
      fwInstallation_getToolVersionLocal(localVersion);
      fwInstallation_throw("New DP-type: " + missingDpType + " will be created when upgrading Installation Tool from " +
                           registeredVersion + " to " + localVersion, "INFO");
    }else{
      fwInstallation_throw("Required DP-type: " + missingDpType + " is missing. It will be created, " +
                           "but it is advised to verify why this inconsistency occured.", "WARNING");
    }
  }
}

/** In case of upgrade of the Installation Tool, it returns the list of new DP-Types added to the given component of Installation Tool,
  * when upgrading from the previous version to the current one
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return List of new DP-Types
  */
private dyn_string fwInstallationInit_getNewDpTypes(string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: return fwInstallationInit_getNewDpTypes_tool();
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: return fwInstallationInit_getNewDpTypes_dbAgent();
  }
  return makeDynString();
}

/** Creates or updates DP-Types given in the list
  * @note Successfully created DP-Types are removed from the list. Any elements that are in dpTypesToCreate after
  *       this function is executed, indicating DP-Types for which creation/update failed.
  *       Success condition: dynlen(dpTypesToCreate) == 0
  * @param dpTypesToCreate (in/out)  Input:  List of DP-Types to create/update
  *                                  Output: List of DP-Types for which creation/update failed.
  */
private fwInstallationInit_createDpTypes(dyn_string &dpTypesToCreate){
  int i = 1;
  dyn_dyn_string elements;
  dyn_dyn_int types;
  while(dynlen(dpTypesToCreate) > 0 || i <= dynlen(dpTypesToCreate)){
    fwInstallationInit_getDptStruct(dpTypesToCreate[i], elements, types);
    if(dpTypeChange(elements, types) == 0){
      dynRemove(dpTypesToCreate, i);
    }else{
      i++;
    }
  }
}

/** Returns the structure of given DP-Type name in output arguments.
  * @param dptName (in)  DP-Type name
  * @param elements (out)  Array containing names of data point elements
  * @param types (out)  Array containing types of data point elements
  */
private fwInstallationInit_getDptStruct(string dptName, dyn_dyn_string &elements, dyn_dyn_int &types){
  dynClear(elements);
  dynClear(types);
  switch(dptName){
    // Installation Tool DP-Types
    case FW_INSTALLATION_DPT_INFORMATION: fwInstallationInit_getDptStruct_Information(elements, types); break;
    case FW_INSTALLATION_DPT_COMPONENTS: fwInstallationInit_getDptStruct_Components(elements, types); break;
    case FW_INSTALLATION_DPT_PENDING_ACTIONS: fwInstallationInit_getDptStruct_PendingActions(elements, types); break;
    // DB-Agent DP-Types
    case FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION: fwInstallationInit_getDptStruct_agentParametrization(elements, types); break;
    case FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS: fwInstallationInit_getDptStruct_agentPendingRequests(elements, types); break;
    default: fwInstallation_throw("Failed to get DP-Type structure for: " + dptName + ". It is not recognized as internal " +
                                  "DP-Type of Installation Tool", "ERROR");
  }
}

/** This function checks for given Installation Tool component if DP-Type update is needed and if there are any actions
  * that needs to be executed when updating the DP-Type. Actions are returned in a mapping output argument.
  * Mapping keys are the DP-types that needs to be updated and values are nested mappings with key = action and values = parameters
  * @param dpTypeUpdateActions (out)  Mapping containing needed DP-Type update actions
  * @param installationToolComponent (in)  Installation tool component (Tool itself or DB-Agent)
  * @param 0 if check finished succesfully, -1 when failed to verify what DP-Type update actions are needed
  */
private int fwInstallationInit_checkDpTypeUpdates(mapping &dpTypeUpdateActions, string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: return fwInstallationInit_checkDpTypeUpdates_tool(dpTypeUpdateActions);
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: return fwInstallationInit_checkDpTypeUpdates_dbAgent(dpTypeUpdateActions);
  }
  return -1;
}

/** This function for given Installation Tool component executes the necessary DP-Type update actions
  * @param dpTypeUpdateActions  Mapping containing needed DP-Type update actions
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_executeDpTypeUpdateActions(const mapping &dpTypeUpdateActions, string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: fwInstallationInit_executeDpTypeUpdateActions_tool(dpTypeUpdateActions); break;
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: fwInstallationInit_executeDpTypeUpdateActions_dbAgent(dpTypeUpdateActions); break;
  }
}

/// ========================== Datapoints consistency checking ==========================

/** Checks if all required DPs of given Installation Tool component exists in the project
  * @param isFirstRun  Flag indicating whether Installation Tool is started for the first time in the project
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return Missing datapoints mapping (key: DP name, value: DPT name)
  */
private mapping fwInstallationInit_checkDpsConsistency(bool isFirstRun, string installationToolComponent){
  const mapping requiredDps = fwInstallationInit_getRequiredDps(installationToolComponent);
  if(isFirstRun){
    return requiredDps;
  }
  mapping missingDps = fwInstallationInit_getMissingDps(requiredDps);
  int missingDpsNum = mappinglen(missingDps);
  if(mappinglen(missingDps) > 0){ // Verify if datapoint is missing because the new datapoint was just added and fwInstallation is not yet upgraded or if there is an inconsistency.
    fwInstallationInit_reportDpInconsistency(missingDps, installationToolComponent);
  }
  return missingDps;
}

/** For given Installation Tool component it returns mapping with its required DPs
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return Required datapoints mapping (key: DP name, value: DPT name)
  */
private mapping fwInstallationInit_getRequiredDps(string installationToolComponent){
  mapping datapoints;
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT:
      datapoints = makeMapping(
          fwInstallation_getInstallationDp(), FW_INSTALLATION_DPT_INFORMATION,
          fwInstallation_getInstallationPendingActionsDp(1), FW_INSTALLATION_DPT_PENDING_ACTIONS);
      if(fwInstallationRedu_isRedundant()){
        datapoints[fwInstallation_getInstallationPendingActionsDp(2)] = FW_INSTALLATION_DPT_PENDING_ACTIONS;
      }
      break;
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT:
      datapoints = makeMapping(
          fwInstallation_getAgentDp(), FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION,
          fwInstallation_getAgentRequestsDp(1), FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS);
      if(fwInstallationRedu_isRedundant()){
        datapoints[fwInstallation_getAgentRequestsDp(2)] = FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS;
      }
      break;
    default:
      fwInstallation_throw("Unknown Installation Tool Component: " + installationToolComponent +
                           ". Cannot retrieve required datapoints", "ERROR");
  }
  return datapoints;
}

/** Checks if datapoints given in a mapping, are present in the project and reports the missing ones
  * @param requiredDps Mapping with required datapoints (key: DP name, value: DPT name)
  * @return Mapping of missing datapoints (key: DP name, value: DPT name)
  */
private mapping fwInstallationInit_getMissingDps(const mapping &requiredDps){
  mapping missingDps;
  int requiredDpsNum = mappinglen(requiredDps);
  for(int i=1;i<=requiredDpsNum;i++){
    string requiredDp = mappingGetKey(requiredDps, i);
    if(!dpExists(requiredDp)){
      missingDps[requiredDp] = requiredDps[requiredDp];
    }
  }
  return missingDps;
}

/** Prints to the log information about DPs that needs to be created because they are missing or
  * because it is a first run of a new version of the Installation Tool, that adds new DPs
  * @param missingDps  List of necessary installation tool DPs that are missing in the project
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_reportDpInconsistency(const mapping &missingDps, string installationToolComponent){
  dyn_string newDps = fwInstallationInit_getNewDps(installationToolComponent);
  int missingDpsNum = mappinglen(missingDps);
  for(int i=1;i<=missingDpsNum;i++){
    string missingDp = mappingGetKey(missingDps, i);
    if(dynContains(newDps, missingDp) > 0){
      string registeredVersion, localVersion;
      fwInstallation_getToolVersionFromDp(registeredVersion);
      fwInstallation_getToolVersionLocal(localVersion);
      fwInstallation_throw("New datapoint: " + missingDp + " of type: " + missingDps[missingDp] + " will be created " +
                           "when upgrading Installation Tool from " + registeredVersion + " to " + localVersion, "INFO");
    }else{
      fwInstallation_throw("Required datapoint: " + missingDp + " of type: " + missingDps[missingDp] + " is missing. " +
                           "It will be created with default dpe values. Please update them if necessary", "WARNING");
    }
  }
}

/** In case of upgrade of the Installation Tool, it returns the list of new DPs added to the given component of Installation Tool,
  * when upgrading from the previous version to the current one
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  * @return List of new DPs
  */
private dyn_string fwInstallationInit_getNewDps(string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: return fwInstallationInit_getNewDps_tool();
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: return fwInstallationInit_getNewDps_dbAgent();
  }
  return makeDynString();
}

/** Creates DPs given as a mapping (key: DP name, value: DPT name)
  * @param dpsToCreate (in/out)  Mapping of datapoints to be created, on output it contains datapoints that could not be created
  * @return Mapping of datapoints that were created
  */
private mapping fwInstallationInit_createDps(mapping &dpsToCreate){
  mapping dpsCreated;
  dyn_string dpNamesToCreate = mappingKeys(dpsToCreate);
  int dpNamesToCreateLen = dynlen(dpNamesToCreate);
  for(int i=1;i<=dpNamesToCreateLen;i++){
    string dpNameToCreate = dpNamesToCreate[i];
    string dpType = dpsToCreate[dpNameToCreate];
    if(dpCreate(dpNameToCreate, dpType) == 0){
      dpsCreated[dpNameToCreate] = dpType;
      mappingRemove(dpsToCreate, dpNameToCreate);
    }
  }
  return dpsCreated;
}

/** Sets default defined DPE values to the datapoints given in a mapping
  * This function is called once when DP(s) is/are created
  * @param dpsCreated  Mapping of datapoints for which, the default DPE values should be set (key: DP name, value: DPT name)
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_setDefaultDpValues(const mapping &dpsCreated, string installationToolComponent){
  switch(installationToolComponent){
    case FW_INSTALLATION_INIT_TOOL_COMPONENT: fwInstallationInit_setDefault_tool(dpsCreated); break;
    case FW_INSTALLATION_INIT_DB_AGENT_COMPONENT: fwInstallationInit_setDefault_dbAgent(dpsCreated); break;
  }
}

/** Updates (resets) defined DPE values for given Installation Tool component
  * This function is called at every start of Installation Tool
  * @param dpsCreated  Mapping of datapoints for which, the default DPE values should be set (key: DP name, value: DPT name)
  * @param installationToolComponent  Installation tool component (Tool itself or DB-Agent)
  */
private fwInstallationInit_updateDpValues(string installationToolComponent){
  switch(installationToolComponent){
   case FW_INSTALLATION_INIT_TOOL_COMPONENT: fwInstallationInit_updateDpValues_tool(); break;
  }
}

/// ====================== Installation Tool DP-Types/DPs specific functions ======================

/** Returns list of DP-Types required by the Installation Tool
  */
private dyn_string fwInstallationInit_getRequiredDpTypes_tool(){
  return makeDynString(
      FW_INSTALLATION_DPT_COMPONENTS,
      FW_INSTALLATION_DPT_INFORMATION,
      FW_INSTALLATION_DPT_PENDING_ACTIONS);
}

/** Returns list of new DP-Types that were added since last Installation Tool version used in the project
  */
private dyn_string fwInstallationInit_getNewDpTypes_tool(){
  dyn_string newDpTypesList;
  // Template to be used when new DP-type is added to fwInstallation:
  //fwInstallationInit_checkIfNewDpOrType(<newDpTypeName>, <versionWhereNewDpTypeWasAdded>, newDpTypesList);
  return newDpTypesList;
}

/** Checks whether it is needed to perform updates required due to the DP-Type change
  * @param dpTypeUpdateActions (out)  Mapping of DP-Type update actions
  * @return 0 when check finished succesfully, -1 in case of errors (could not create probe datapoint)
  */
private int fwInstallationInit_checkDpTypeUpdates_tool(mapping &dpTypeUpdateActions){
  // Check _FwInstallationComponents DP-type
  if(fwInstallationInit_checkDpTypeUpdates_Components(dpTypeUpdateActions) != 0){
    return -1;
  }
  // Check _FwInstallationInformation DP-type
  fwInstallationInit_checkDpTypeUpdates_Information(dpTypeUpdateActions);
  return 0;
}

/** Checks whether it is needed to perform updates required due to the _FwInstallationComponents DP-Type change
  */
private int fwInstallationInit_checkDpTypeUpdates_Components(mapping &dpTypeUpdateActions){
  string ComponentDp_probe = fwInstallationRedu_getLocalDp("fw_InstallationProbing");
  if(fwInstallationInit_createProbeDp(ComponentDp_probe, FW_INSTALLATION_DPT_COMPONENTS) != 0){
    return -1;
  }
  mapping componentsUpdateActions;
  // Check if _FwInstallationComponents dpt does not contain element "sourceFilesHashes"; introduced in version 8.1.0 [Dec 2017]
  if(!fwInstallationInit_dpHasElement(ComponentDp_probe, ".sourceFilesHashes")){
    componentsUpdateActions["sourceFilesHashes"] = "";
  }

  // Check if _FwInstallationComponents dpt does not contain element "qtHelpFiles"; introduced in version 8.4.0 [Dec 2019]
  if(!fwInstallationInit_dpHasElement(ComponentDp_probe, ".qtHelpFiles")){
    componentsUpdateActions["qtHelpFiles"] = "";
  }
  if(mappinglen(componentsUpdateActions) > 0){
    dpTypeUpdateActions[FW_INSTALLATION_DPT_COMPONENTS] = componentsUpdateActions;
  }

  // Check if _FwInstallationComponents dpt does not contain element "postInstallPending"; introduced in version 8.4.3 [Aug 2021]
  if(!fwInstallationInit_dpHasElement(ComponentDp_probe, ".postInstallPending")){
    componentsUpdateActions["postInstallPending"] = "";
  }
  if(mappinglen(componentsUpdateActions) > 0){
    dpTypeUpdateActions[FW_INSTALLATION_DPT_COMPONENTS] = componentsUpdateActions;
  }
  dpDelete(ComponentDp_probe);
  return 0;
}

/** Checks whether it is needed to perform updates required due to the _FwInstallationInformation DP-Type change
  */
private fwInstallationInit_checkDpTypeUpdates_Information(mapping &dpTypeUpdateActions){
  mapping informationUpdateActions;
  // Check if _FwInstallationInformation dpt does not contain element "asciiImportLogSettings"; introduced in version 8.4.2 [Nov 2020]
  if(!fwInstallationInit_dpHasElement(fwInstallation_getInstallationDp(), ".asciiImportLogSettings")){
    informationUpdateActions["asciiImportLogSettings"] = "";
  }

  if(mappinglen(informationUpdateActions) > 0){
    dpTypeUpdateActions[FW_INSTALLATION_DPT_INFORMATION] = informationUpdateActions;
  }
}

/** Executes given actions required due to the DP-Type change
  */
private fwInstallationInit_executeDpTypeUpdateActions_tool(const mapping &dpTypeUpdateActions){
  if(mappingHasKey(dpTypeUpdateActions, FW_INSTALLATION_DPT_COMPONENTS)){
    mapping componentsUpdateActions = dpTypeUpdateActions[FW_INSTALLATION_DPT_COMPONENTS];
    if(mappingHasKey(componentsUpdateActions, "sourceFilesHashes")){
      fwInstallationInit_updateComponentDps_sourceFilesHashes();
    }
  }
  if(mappingHasKey(dpTypeUpdateActions, FW_INSTALLATION_DPT_INFORMATION)){
    mapping informationUpdateActions = dpTypeUpdateActions[FW_INSTALLATION_DPT_INFORMATION];
    if(mappingHasKey(informationUpdateActions, "asciiImportLogSettings")){
      fwInstallationInit_updateComponentDps_asciiImportLogSettings();
    }
  }
}

/** Calculates and sets the source file hashes in case of an upgrade from version < 8.1.0
  */
private fwInstallationInit_updateComponentDps_sourceFilesHashes(){
  dyn_dyn_string installedComponents;
  if(fwInstallation_getInstalledComponents(installedComponents) != 0){
    fwInstallation_throw("Failed to get installed components properties. Cannot calculate hashes of source files. " +
                         "This needs to be done manually later", "ERROR");
  }

  int installedComponentsCount = dynlen(installedComponents);
  for(int i=1;i<=installedComponentsCount;i++){
    if(fwInstallation_calculateComponentSourceFilesHashes(installedComponents[i][1]) != 0)
      fwInstallation_throw("Error when calculating source files hashes for component: " + installedComponents[i][1] +
                           ". Hash calculation needs for this component to be done manually later", "ERROR");
  }
}

/** Sets default ASCII import log settings in case of an upgrade from version < 8.5.0
  */
private fwInstallationInit_updateComponentDps_asciiImportLogSettings(){
  fwInstallationInit_setDefault_asciiImportLogSettings();
}

/** Returns list of new DPs that were added since last Installation Tool version used in the project
  */
private dyn_string fwInstallationInit_getNewDps_tool(){
  dyn_string newDpsList;
  // Template to be used when new datapoint is added to fwInstallation:
  //fwInstallationInit_checkIfNewDpOrType(<newDpName>, <versionWhereNewDpWasAdded>, newDpsList);
  return newDpsList;
}

/** Calculates and sets the source file hashes if they are not yet calculated (can happen in upgraded redu project)
  */
private fwInstallationInit_initSourceFilesHashesIfEmpty(){
  dyn_string installedComponentDps = fwInstallation_getInstalledComponentDps();
  if(dynlen(installedComponentDps) <= 0){
    return;
  }
  string dpe = installedComponentDps[1] + ".sourceFilesHashes";
  if(!dpExists(dpe)){
    fwInstallation_throw("Internal DPTs of the installation tool are not up-to-date. Need to run on active peer first", "WARNING", 10);
    return;
  }
  time t;
  dpGet(dpe + ":_original.._stime", t);
  if(t > 0){
    return;
  }

  fwInstallationInit_updateComponentDps_sourceFilesHashes();
}

/** Sets default DPEs values of given Installation Tool datapoints
  */
private fwInstallationInit_setDefault_tool(const mapping &dpsCreated){
  if(mappingHasKey(dpsCreated, fwInstallation_getInstallationDp())){
    fwInstallationInit_setDefault_asciiImportLogSettings();
  }
}

/** Sets default values of fwInstallationInfo.asciiImportLogSettings.* DPEs
  */
private fwInstallationInit_setDefault_asciiImportLogSettings(){
  if(dpSet(fwInstallation_getInstallationDp() + ".asciiImportLogSettings.fileName",
           FW_INSTALLATION_ASCII_IMPORT_LOG_FILE_NAME_DEFAULT,
           fwInstallation_getInstallationDp() + ".asciiImportLogSettings.rotationSize",
           FW_INSTALLATION_ASCII_IMPORT_LOG_ROTATION_SIZE_DEFAULT) != 0){
     fwInstallation_throw("Could not set default component installation ASCII import log settings", "WARNING");
  }
}

/** Updates (resets) values of specified Installation Tool DPEs
  */
private fwInstallationInit_updateDpValues_tool(){
  if(fwInstallationRedu_isRedundant()){
    fwInstallationInit_initSourceFilesHashesIfEmpty();
  }
  // Keep setting option not to add managers on redu system
  fwInstallation_setAddManagersOnReduPartner(false);
  // Update installation tool version stored in dp
  fwInstallationInit_updateToolVersionInDp();
  // Fill pvss version and patch list here:
  fwInstallationInit_updateWCCOAInfo();
  // If there are components installed, make sure that the dp-element 'name' is properly filled:
  fwInstallationInit_updateComponentDps(); /** @TODO consider removing this function; since long time '.name' is same as the postfix of component dp name.
                                               There should not be any attempt to retrieve name from dp name instead of getting it directly from dpe */
}


/// ====================== Installation DB-Agent DP-Types/DPs specific functions ======================

/** Returns list of DP-Types required by the Installation DB-Agent
  */
private dyn_string fwInstallationInit_getRequiredDpTypes_dbAgent(){
  return makeDynString(
      FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION,
      FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS);
}

/** Returns list of new Installation DB-Agent DP-Types that were added since last Installation Tool version used in the project
  */
private dyn_string fwInstallationInit_getNewDpTypes_dbAgent(){
  dyn_string newDpTypesList;
  // Template to be used when new DP-type is added to fwInstallation:
  //fwInstallationInit_checkIfNewDpOrType(<newDpTypeName>, <versionWhereNewDpTypeWasAdded>, newDpTypesList);
  return newDpTypesList;
}

/** Checks whether it is needed to perform updates required due to the DP-Type change
  * @param dpTypeUpdateActions (out)  Mapping of DP-Type update actions
  * @return 0
  */
private int fwInstallationInit_checkDpTypeUpdates_dbAgent(mapping &dpTypeUpdateActions){
  // Check _FwInstallation_agentParametrization DP-type
  fwInstallationInit_checkDpTypeUpdates_agentParametrization(dpTypeUpdateActions);
  // Check _FwInstallation_agentPendingRequests DP-type
  fwInstallationInit_checkDpTypeUpdates_agentPendingRequests(dpTypeUpdateActions);
  return 0;
}

/** Checks whether it is needed to perform updates required due to the _FwInstallation_agentParametrization DP-Type change
  */
private fwInstallationInit_checkDpTypeUpdates_agentParametrization(mapping &dpTypeUpdateActions){
  mapping agentParametrizationUpdateActions;
  string agentParametrizationDp = fwInstallation_getAgentDp();
  // Check if _FwInstallation_agentParametrization dpt does not contain element "postInitRestartNeeded"; introduced in version 7.2.3 [Nov 2014]
  if(!fwInstallationInit_dpHasElement(agentParametrizationDp, "." + fwInstallation_getAfterInitRestartNeededDpElem())){
    agentParametrizationUpdateActions[fwInstallation_getAfterInitRestartNeededDpElem()] = "";
  }

  // Check if _FwInstallation_agentParametrization dpt does not contain element "synchronizedComponents"; introduced in version 8.2.0 [Jun 2018]
  if(!fwInstallationInit_dpHasElement(agentParametrizationDp, FW_INSTALLATION_DB_AGENT_SYNC_COMPONENTS_DPE)){
    agentParametrizationUpdateActions["synchronizedComponents"] = "";
  }

  if(mappinglen(agentParametrizationUpdateActions) > 0){
    dpTypeUpdateActions[FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION] = agentParametrizationUpdateActions;
  }
}

/** Checks whether it is needed to perform updates required due to the _FwInstallation_agentPendingRequests DP-Type change
  */
private fwInstallationInit_checkDpTypeUpdates_agentPendingRequests(mapping &dpTypeUpdateActions){
  mapping agentPendingRequestsUpdateActions;
  // No modifications to check so far
  if(mappinglen(agentPendingRequestsUpdateActions) > 0){
    dpTypeUpdateActions[FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS] = agentPendingRequestsUpdateActions;
  }
}

/** Executes given actions required due to the DP-Type change
  */
private fwInstallationInit_executeDpTypeUpdateActions_dbAgent(const mapping &dpTypeUpdateActions){
  if(mappingHasKey(dpTypeUpdateActions, FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION)){
    mapping agentParametrizationUpdateActions = dpTypeUpdateActions[FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION];
    if(mappingHasKey(agentParametrizationUpdateActions, fwInstallation_getAfterInitRestartNeededDpElem())){
      fwInstallationInit_updateAgentParametrizationDp_afterInitRestartNeeded();
    }
    if(mappingHasKey(agentParametrizationUpdateActions, "synchronizedComponents")){
      fwInstallationInit_setDefaultEnabledSynchronizationComponents();
    }
  }
}

/** Sets/updates the .postInitRestartNeeded flag and list of managers protected from stopping (.managers.protected)
  */
private fwInstallationInit_updateAgentParametrizationDp_afterInitRestartNeeded(){
  fwInstallation_clearProjectRestartAfterInit();
  dyn_string protectedManagers;
  _fwInstallationManager_getManagersProtectedFromStopping(protectedManagers);
  if(dynlen(protectedManagers) == 0){ // Initialize the protected managers
    fwInstallationInit_setDefaultProtectedManagersList();
  }
}

/** Returns list of new Installation DB Agent DP-Types, that were added since last Installation Tool version used in the project
  */
private dyn_string fwInstallationInit_getNewDps_dbAgent(){
  dyn_string newDpsList;
  // Template to be used when new datapoint is added to fwInstallation:
  //fwInstallationInit_checkIfNewDpOrType(<newDpName>, <versionWhereNewDpWasAdded>, newDpsList);
  return newDpsList;
}

/** Sets the default value to specified Installation DB Agent DPEs
  */
private fwInstallationInit_setDefault_dbAgent(const mapping &dpsCreated){
  if(mappingHasKey(dpsCreated, fwInstallation_getAgentDp())){
    fwInstallationInit_setDefault_agentParametrizationDp();
  }
}

/** Sets the default value to specified DPEs of fwInstallation_agentParametrizationDp
  */
private fwInstallationInit_setDefault_agentParametrizationDp(){
  fwInstallationInit_setDefaultProtectedManagersList();
  fwInstallationInit_setDefaultEnabledSynchronizationComponents();

  fwInstallationDBAgent_setSyncInterval(300);

  dyn_int initialStatus;
  initialStatus[FW_INSTALLATION_DB_STATUS_DEV_AND_APPS] = 0; // initialize list with zeros
  dpSet(fwInstallation_getAgentDp() + ".db.projectStatus", initialStatus);
}

/** Sets the default value to the list of managers protected from stopping
  */
private fwInstallationInit_setDefaultProtectedManagersList(){
  _fwInstallationManager_setManagersProtectedFromStopping(
      makeDynString("-m gedi", "-f pvss_scripts.lst", "-p fwInstallation/fwInstallation.pnl",
                    FW_INSTALLATION_SCRIPTS_MANAGER_CMD, FW_INSTALLATION_DB_AGENT_MANAGER_CMD,
                    "fwInstallation/fwInstallationFakeScript.ctl",
                    "fwInstallation/fwInstallationAgentDBConsistencyChecker.ctl",
                    "archiv_client.ctl", "calculateState.ctl",
                    "libs/PVSSBootstrapper/PVSSBootstrapper_insider.ctl"));
}

/** Sets the default value to the list of enabled DB Agent synchronization components
  */
private fwInstallationInit_setDefaultEnabledSynchronizationComponents(){
  if(fwInstallationDBAgent_setEnabledSynchronizationComponents(true, makeDynBool()) != 0 ||
     fwInstallationDBAgent_setEnabledSynchronizationComponents(false, makeDynBool()) != 0){
    fwInstallation_throw("Failed to set initial values for the list of enabled synchronization components in local and/or central mode", "ERROR");
  }
}

/// ==================================  Utility functions =========================================

/** Checks if given DP-Type name or DP name is new - this is a first run of the new version of Installation Tool
  * and the DP/DP-Type was not in the one that was previously used.
  * @param newDpOrType (in)  DP-Type or DP name to be checked if it is new for the project
  * @param versionWhereAdded (in)  Installation Tool version where the DP-Type or DP was introduced
  * @param newDpsOrTypesList (out)  List containing new DP-Types or DP names
  */
private fwInstallationInit_checkIfNewDpOrType(string newDpOrType, string versionWhereAdded, dyn_string &newDpsOrTypesList){
  string registeredVersion;
  fwInstallation_getToolVersionFromDp(registeredVersion);
  if(_fwInstallation_CompareVersions(registeredVersion, versionWhereAdded) == 0){
    dynAppend(newDpsOrTypesList, newDpOrType, false, false, true);
  }
}

/** This function creates a probe datapoint of a given DP-type
  * @param dp  Name of the probe datapoint
  * @param dpType  Name of DP-Type
  * @return 0 when probe DP created successfully, -1 when it was not possible to create it
  */
int fwInstallationInit_createProbeDp(string dp, string dpType){
  int attempts = 25;
  dyn_errClass errors;
  for(int i=1;i<=attempts;i++){
    if(dpCreate(dp, dpType) != 0){
      errors = getLastError();
    }else if(dpExists(dp)){
      return 0;
    }
    delay(0, 200);
  }
  fwInstallation_throw(getErrorText(errors), "ERROR");
  fwInstallation_throw("Failed to create internal fwInstallation probe component dp: " + dp + " for 5 seconds. " +
                       "Cannot continue. Please kill the UI and check para privledges or contact support" , "ERROR");
  return -1;
}

/** Checks if datapoint has given DP-element
  * @param dp  Datapoint name
  * @param element  DP-element name (beginning with dot '.')
  * @return true if datapoint has given element, false otherwise
  */
private bool fwInstallationInit_dpHasElement(string dp, string element){
  return dpExists(dp + element);
}

/// ============================  DP-Types structure definition ===================================

/** Returns the structure _FwInstallation_Information datapoint type in output arguments.
  */
private fwInstallationInit_getDptStruct_Information(dyn_dyn_string &ddElements, dyn_dyn_int &ddTypes){
  int pos = 1; //Note: [pos++] - first returns pos value, then increments it.
  ddElements[pos] = makeDynString (FW_INSTALLATION_DPT_INFORMATION);
  ddTypes[pos++]  = makeDynInt    (DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "installationDirectoryPath");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "lastSourcePath");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "lastInstToolSourcePath"); // used in CDBSI tool, API functions in fwInstallation
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "addManagersDisabled");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "activateManagersDisabled");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "version");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "blockUis");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "deleteFromConfigFile");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "status");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "addManagersOnReduPartner"); // always set to false at each start of Installation Tool or DB Agent
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "projectInfo");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "wccoaVersion");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "", "wccoaPatchList");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "asciiImportLogSettings");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "fileName");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "", "rotationSize");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
}

/** Returns the structure _FwInstallation_Components datapoint type in output arguments.
  */
private fwInstallationInit_getDptStruct_Components(dyn_dyn_string &ddElements, dyn_dyn_int &ddTypes){
  int pos = 1; //Note: [pos++] - first returns pos value, then increments it.
  ddElements[pos] = makeDynString (FW_INSTALLATION_DPT_COMPONENTS);
  ddTypes[pos++]  = makeDynInt    (DPEL_STRUCT);

  ddElements[pos] = makeDynString ("", "componentFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "configFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);

  ddElements[pos] = makeDynString ("", "", "configWindows");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "", "configLinux");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "", "configGeneral");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);

  ddElements[pos] = makeDynString ("", "initFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "postInstallFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);

  ddElements[pos] = makeDynString ("", "dplistFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "sourceFilesHashes");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);

  ddElements[pos] = makeDynString ("", "componentVersion");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_FLOAT);
  ddElements[pos] = makeDynString ("", "date");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "descFile");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "installationDirectory");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "requiredComponents");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "requiredInstalled");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "subComponents");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "isItSubComponent");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "scriptFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "componentVersionString");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);

  ddElements[pos] = makeDynString ("", "deleteFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "postDeleteFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);

  ddElements[pos] = makeDynString ("", "helpFile");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "qtHelpFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);

  ddElements[pos] = makeDynString ("", "sourceDir");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "installationNotOK");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "postInstallPending");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "comments");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "name");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "description");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
}

/** Returns the structure _FwInstallation_PendingActions datapoint type in output arguments.
  */
private fwInstallationInit_getDptStruct_PendingActions(dyn_dyn_string &ddElements, dyn_dyn_int &ddTypes){
  int pos = 1; //Note: [pos++] - first returns pos value, then increments it.
  ddElements[pos] = makeDynString (FW_INSTALLATION_DPT_PENDING_ACTIONS);
  ddTypes[pos++]  = makeDynInt    (DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "postInstallFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "postDeleteFiles");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
}

/** Returns the structure _FwInstallation_agentParametrization datapoint type in output arguments.
  */
private fwInstallationInit_getDptStruct_agentParametrization(dyn_dyn_string &ddElements, dyn_dyn_int &ddTypes){
  int pos = 1; //Note: [pos++] - first returns pos value, then increments it.
  ddElements[pos] = makeDynString (FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION);
  ddTypes[pos++]  = makeDynInt    (DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "db");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "connection");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "", "driver");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "", "", "server");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "", "", "username");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("" , "", "", "password");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("" , "", "", "initialized");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("" , "", "", "schemaOwner");
  ddTypes[pos++]  = makeDynInt    (0,  0,  0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "", "useDB");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "projectStatus");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_INT);
  ddElements[pos] = makeDynString ("", "lock");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "restart");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "syncInterval");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "managers");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "stopDist");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "stopUIs");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "stopCtrl");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "stopDistAfterSync");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "protected");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "redundancy");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "installOnlyInSplit");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "restoreRedundancyAfterInstallation");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "", "splitModeForced");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", "", "pairToKeepAfterSplit");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", fwInstallation_getFileIssuesSyncDpElem());
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_BOOL);
  ddElements[pos] = makeDynString ("", fwInstallation_getAfterInitRestartNeededDpElem());
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", fwInstallation_getAfterInitRestartRequesterDpElem());
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "synchronizedComponents");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "enabledInLocal");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_BOOL);
  ddElements[pos] = makeDynString ("", "", "enabledInCentral");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_BOOL);
}

/** Returns the structure _FwInstallation_agentPendingRequests datapoint type in output arguments.
  */
private fwInstallationInit_getDptStruct_agentPendingRequests(dyn_dyn_string &ddElements, dyn_dyn_int &ddTypes){
  int pos = 1; //Note: [pos++] - first returns pos value, then increments it.
  ddElements[pos] = makeDynString (FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS);
  ddTypes[pos++]  = makeDynInt    (DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "restart");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "pvssInstallRequests");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "pvssDeleteRequests");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "dbInstallRequests");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "dbDeleteRequests");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "trigger");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "execute");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_INT);
  ddElements[pos] = makeDynString ("", "msg");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRING);
  ddElements[pos] = makeDynString ("", "managerReconfiguration");
  ddTypes[pos++]  = makeDynInt    (0,   DPEL_STRUCT);
  ddElements[pos] = makeDynString ("", "", "manager");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "", "startMode");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
  ddElements[pos] = makeDynString ("", "", "secKill");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_INT);
  ddElements[pos] = makeDynString ("", "", "restartCount");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_INT);
  ddElements[pos] = makeDynString ("", "", "resetMin");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_INT);
  ddElements[pos] = makeDynString ("", "", "commandLine");
  ddTypes[pos++]  = makeDynInt    (0,  0,   DPEL_DYN_STRING);
}
