// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file
  This file contains functions related to building Qt Help Collection for a project.
*/

#uses "std.ctl"
#uses "fwInstallation/fwInstallation.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
 */
const string csFwInstallationQtHelpLibVersion = "9.1.3";
const string csFwInstallationQtHelpLibTag = "";

/////////////////////////////////////////////////////
const string FW_INSTALLATION_QT_HELP_FILE_DPE = ".qtHelpFiles";
const string FW_INSTALLATION_QT_HELP_ASSISTANT_EXE_WIN32 = "assistant.exe";
const string FW_INSTALLATION_QT_HELP_ASSISTANT_EXE_UNIX = "assistant";
const string FW_INSTALLATION_QT_HELP_COLLECTION_FILENAME = "help.qhc";
const string FW_INSTALLATION_QT_HELP_COLLECTION_CACHE_DIR = "qtHelpAssistantCache/";
const string FW_INSTALLATION_QT_HELP_SYMLINKS_DIR = "symlinks/";
const string FW_INSTALLATION_QT_HELP_QHC_TEMPLATE =
    "fwInstallation/qt_help_collection_template.en_US.utf8.qhc";
const string FW_INSTALLATION_QT_HELP_GENERATION_SCRIPT = "fwInstallation_generateQtHelp.ctl";

const dyn_string FW_INSTALLATION_QT_HELP_EXCLUDE = makeDynString("hsp.qch", "TestFramework.qch");
const dyn_string FW_INSTALLATION_QT_HELP_INCLUDE = makeDynString("fwInstallation/fwInstallation.qch");

/** Bash command to get list of PIDs of running assistant processes, that use custom project collection */
const string FW_INSTALLATION_QT_CMD_UNIX_GET_ASSISTANT_PIDS =
    "pgrep -d ' ' -f '/assistant .*/" + PROJ + "/.*/" + FW_INSTALLATION_QT_HELP_COLLECTION_FILENAME + "'";

/** PowerShell command to get running assistant processes, that use custom project collection */
const string FW_INSTALLATION_QT_CMD_WIN_PS_GET_ASSISTANT_PROC =
    "Get-WmiObject -Class Win32_Process -Filter " +
    "'name=''assistant.exe'' AND CommandLine LIKE ''%" + PROJ + "%" +
    FW_INSTALLATION_QT_HELP_COLLECTION_FILENAME + "%'' '";


/**
 * Return WinCC OA help collection file path in project data/ directory
 *
 * @return WinCC OA help collection file path
 */
private string _fwInstallationQtHelp_getCollectionFilePath(){
  return (PROJ_PATH + DATA_REL_PATH + FW_INSTALLATION_QT_HELP_COLLECTION_FILENAME);
}


/**
 * Built a Qt Help Collection for the current project
 *
 * Locate all Qt Compressed Help (QCH) files within the `help/<language>/`
 * subdirectory, and all QCH files related to JCOP components defined by the
 * data-point element `qtHelpFiles` in the data-point type
 * `_FwInstallationComponents`.
 *
 * @return 0 if successful, or a negative number in case of failure.
 */
int fwInstallationQtHelp_buildCollection()
{
  // Step 1: Check that the template collection is present
  string templateFilePath = getPath(DATA_REL_PATH, FW_INSTALLATION_QT_HELP_QHC_TEMPLATE);
  if (templateFilePath == "")
  {
    fwInstallation_throw("Could not find required *.qhc template file'" +
                         FW_INSTALLATION_QT_HELP_QHC_TEMPLATE + "' in any data/ directory", "ERROR", 27);
    return -1;
  }

  // Step 2: Find and get paths for QHC files
  dyn_string qchFilePaths;
  _fwInstallationQtHelp_getExistingQchFilePaths(qchFilePaths);
  _fwInstallationQtHelp_getExistingQchFilePaths(qchFilePaths, OaLanguage::undefined); // handle CtrlRDBAccess help temporarily
  _fwInstallationQtHelp_getComponentQchFilePaths(qchFilePaths);
  _fwInstallationQtHelp_getAdditionalQchFilePaths(qchFilePaths);
  _fwInstallationQtHelp_filterQchFiles(qchFilePaths, FW_INSTALLATION_QT_HELP_EXCLUDE);
  _fwInstallationQtHelp_replacePvssDirQchFilesWithLinks(qchFilePaths);
  qchFilePaths.unique(); // ensure no duplicates (if component qch files are also added as existing ones)
  if (qchFilePaths.count() == 0)
  {
    fwInstallation_throw("Couldn't find any QCH files. Aborting collection build.", "ERROR", 27);
    return -2;
  }

  _fwInstallationQtHelp_flagExecution(qchFilePaths.count());
  // Step 3: Copy QHC and add QHC files
  string qhcFilePath = _fwInstallationQtHelp_getCollectionFilePath();
  if (_fwInstallationQtHelp_buildQhc(templateFilePath, qhcFilePath, qchFilePaths) != 0)
  {
    fwInstallation_throw("Failed to build Qt Help Collection (*.qhc)", "ERROR", 27);
    _fwInstallationQtHelp_clearExecutionBits();
    return -3;
  }
  _fwInstallationQtHelp_clearExecutionBits();
  return 0;
}


/**
 * Check if this project has a custom Qt Help Collection
 *
 * @return True if collection exists, else false.
 */
bool fwInstallationQtHelp_projectHasCollection()
{
  return isfile(_fwInstallationQtHelp_getCollectionFilePath());
}


/**
 * Check if Qt Assistant tool with customized project Qt Help Collection is opened on local system
 *
 * @return True if Qt Assistant is open, else false.
 */
bool fwInstallationQtHelp_isAssistantOpen()
{
  string cmd = _WIN32?
               fwInstallation_formatPowershellCommandForWinCmd(FW_INSTALLATION_QT_CMD_WIN_PS_GET_ASSISTANT_PROC):
               FW_INSTALLATION_QT_CMD_UNIX_GET_ASSISTANT_PIDS;
  string stdOut;
  system(cmd, stdOut);
  return (stdOut != "");
}


/**
 * Close all opened Qt Assistant processes, that use customized project Qt Help Collection
 */
void fwInstallationQtHelp_closeAssistant(){
  string cmd = _WIN32?
               fwInstallation_formatPowershellCommandForWinCmd(
                   "Foreach ($process in " + FW_INSTALLATION_QT_CMD_WIN_PS_GET_ASSISTANT_PROC + ") { $process.Terminate() }"):
               "kill $(" + FW_INSTALLATION_QT_CMD_UNIX_GET_ASSISTANT_PIDS + ") &";
  string stdOut, stdErr;
  system(cmd, stdOut, stdErr);
  if (stdErr != "")
  {
    fwInstallation_throw("Error executing command '" + cmd + "':\nstdOut=\n" + stdOut + "\n\nstdErr=\n" + stdErr, "ERROR");
  }
}


/**
 * Build the Qt Help Collection (QHC) from the Qt Help Collection Project (QHCP)
 *
 * Locates the `qcollectiongenerator` executable, and sterilises the file paths
 * into quoted native paths, then runs the executable on those paths.
 *
 * @param templateFilePath Qt Help Collection template.
 * @param collectionPath Output file path for the Qt Help Collection binary.
 * @param qchFilePaths List of Qt Compressed Help files to include.
 * @return 0 if successful, or a negative number in case of failure.
 */
int _fwInstallationQtHelp_buildQhc(string templateFilePath,
                                   string collectionPath,
                                   const dyn_string &qchFilePaths)
{
  string qtAssistantExePath = _fwInstallationQtHelp_getQtHelpAssistantExePath();
  if (qtAssistantExePath == "")
  {
    fwInstallation_throw("Could not find 'assistant' executable.", "ERROR", 27);
    return -1;
  }
  if (_UNIX && access(qtAssistantExePath, X_OK) != 0)
  {
    fwInstallation_throw("Executable permission missing for '" + qtAssistantExePath + "'",
                         "ERROR", 27);
    return -2;
  }

  // Copy template file into place, this should overwrite the collection file if it already exists.
  if (fwInstallation_copyFile(templateFilePath, collectionPath) != 0)
  {
    fwInstallation_throw("Failed copying template *.qhc file '" + templateFilePath + "' to '" +
                         collectionPath + "'.", "ERROR", 27);
    return -3;
  }

  // Quote paths in case of spaces
  string sterileExePath = makeNativePath("\"" + qtAssistantExePath + "\"");
  string sterileCollectionPath = makeNativePath("\"" + collectionPath + "\"");

  for (int i=1; i <= dynlen(qchFilePaths); i++)
  {
    _fwInstallationQtHelp_setExecutionCurrentStep(i);

    string sterileHelpPath = makeNativePath("\"" + qchFilePaths[i] + "\"");

    // Build command
    string cmd = sterileExePath + " -collectionFile " +
                 sterileCollectionPath + " -register " + sterileHelpPath;
    if (_WIN32)
    {
      cmd = "call " + cmd + " -quiet";
    }
    // Execute the command
    string stdOut, stdErr;
    system(cmd, stdOut, stdErr);

    if (stdErr != "")
    {
      string log_entry =
      "Standard Error pipe was not clean after running Qt Help Assistant.\n" +
      "Logging full command output:\n\n" +
      "cmd=" + cmd + "\n\n" +
      "stdOut=" + stdOut + "\n\n" +
      "stdErr=" + stdErr + "\n";
      fwInstallation_throw(log_entry, "WARNING", 27);
    }
  }

  return 0;
}


/**
 * Locate the `assistant` executable.
 *
 * Searches for the `assistant` executable in the WinCC OA installation `./bin` subdirectory.
 *
 * @return Path to the `assistant` executable, or empty string if not found.
 */
string _fwInstallationQtHelp_getQtHelpAssistantExePath()
{
  string qtAssistantExeName = (_WIN32) ? FW_INSTALLATION_QT_HELP_ASSISTANT_EXE_WIN32
                                       : FW_INSTALLATION_QT_HELP_ASSISTANT_EXE_UNIX;
  return getPath(BIN_REL_PATH, qtAssistantExeName, getActiveLang(), SEARCH_PATH_LEN);
}


/**
 * Locate Qt Compressed Help files (*.qch) for installed JCOP components.
 *
 * For installed components, described by data points of type
 * `_FwInstallationComponents`, get the path to all files listed in the
 * `.qtHelpFiles` data point element. This function also verifies that the
 * files exist and can be read.
 *
 * @param[out] qchFilePaths A list that QCH file paths will be appended to.
 * @return 0 for success, or a negative number with the error count.
 */
int _fwInstallationQtHelp_getComponentQchFilePaths(dyn_string &qchFilePaths /*out*/)
{
  int err = 0;

  dyn_string componentDPs = fwInstallation_getInstalledComponentDps();
  int componentDPsLen = dynlen(componentDPs);
  fwInstallation_throw("Checking " + componentDPsLen + " components for Qt Help Files",
                       "INFO", 27);

  for (uint idx = 1; idx <= componentDPsLen; idx++)
  {
    string name = componentDPs[idx];

    // Get list of Qt Compressed Help (QCH) files from .qtHelpFiles DPE
    dyn_string qtHelpFiles;
    string dpe = componentDPs[idx] + FW_INSTALLATION_QT_HELP_FILE_DPE;
    if (dpGet(dpe, qtHelpFiles) != 0)
    {
      err--;
      fwInstallation_throw("dpGet failed on " + dpe, "ERROR", 27);
      continue;
    }

    // Ensure QCH files can be found and read
    for (int i = 1; i <= dynlen(qtHelpFiles); i++)
    {
      string qtHelpFile = qtHelpFiles[i];
      fwInstallation_normalizePath(qtHelpFile);
      string qchFilePath = getPath("", qtHelpFile);
      if (qchFilePath == "")
      {
        err--;
        fwInstallation_throw("Cannot determine absolute path for qt help file '" + qtHelpFile +
                             "' for component '" + name + "'", "WARNING", 27);
      }
      else
      {
        if (access(qchFilePath, R_OK) == 0)
        {
          // All good! Add to list!
          dynAppend(qchFilePaths, qchFilePath);
        }
        else
        {
          err--;
          fwInstallation_throw("Cannot find qt help file '" + qchFilePath + "' for component '" +
                               name + "'", "WARNING", 27);
        }
      }
    }
  }

  return err;
}


/**
 * Find pre-existing Qt Compressed Help files (*.qch)
 *
 * Searches the 'help' directories in relevant locations, starting from the main
 * WinCC OA installation directory, to find existing QCH files. This should
 * locate the WinCC OA primary documentation.
 *
 * @param[out] qchFilePaths A list that QCH file paths will be appended to.
 * @param activeLangId OaLanguage enum of the language subdirectory to search. By
 * default this is undefined language (search directly in help/ and not in lang subdir)
 * @param searchPathMin Minimum search path level which is passed as the `level`
 * parameter for the `getPath` function. Default is 1.
 * @param searchPathMax Maximum search path level which is passed as the `level`
 * parameter for the `getPath` function. Default is the constant
 * `SEARCH_PATH_LEN`.
 */
void _fwInstallationQtHelp_getExistingQchFilePaths(
    dyn_string &qchFilePaths /*out*/,
    OaLanguage activeLangId = getActiveLangId(),
    int searchPathMin = 1,
    int searchPathMax = SEARCH_PATH_LEN)
{
  // Mapping: key (file name) => value (file directory)
  mapping qchFiles;

  for (int idx = searchPathMax; idx >= searchPathMin; idx--)
  {
    string helpDir = getPath(HELP_REL_PATH, "", activeLangId, idx);
    dyn_string helpFilesFound = getFileNames(helpDir, "*.qch", FILTER_FILES);
    fwInstallation_throw("Found " + dynlen(helpFilesFound) + " *.qch files in '" + helpDir + "'",
                         "INFO", 27);

    for (int i = 1; i <= dynlen(helpFilesFound); i++)
    {
      string helpFile = helpFilesFound[i];
      if (mappingHasKey(qchFiles, helpFile))
      {
        fwInstallation_throw("Override: '" + qchFiles[helpFile] + helpFile +
                             "' is replaced by '" + helpDir + helpFile + "'", "WARNING", 27);
      }
      qchFiles[helpFile] = helpDir;
    }
  }

  dyn_string keys = mappingKeys(qchFiles);
  for (int m = 1; m <= dynlen(keys); m++)
  {
    string filePath = qchFiles[keys[m]] + keys[m];
    dynAppend(qchFilePaths, filePath);
  }
}

/**
 * Add additional *.QCH help files from the FW_INSTALLATION_QT_HELP_INCLUDE list to the list of file paths
 *
 * @param[out] qchFilePaths A list that QCH file paths will be appended to.
 */
void _fwInstallationQtHelp_getAdditionalQchFilePaths(dyn_string &qchFilePaths /*out*/)
{
  for(int i = 1; i <= dynlen(FW_INSTALLATION_QT_HELP_INCLUDE); i++)
  {
    string helpToInclude = FW_INSTALLATION_QT_HELP_INCLUDE[i];
    string helpPath = getPath(HELP_REL_PATH, helpToInclude, getActiveLang());
    if(helpPath != "" && dynContains(qchFilePaths, helpPath) == 0)
    {
      dynAppend(qchFilePaths, helpPath);
    }
  }
}


/**
 * Remove *.QCH help files from the list of file paths if specified as excluded
 *
 * @param[out] qchFilePaths A list that QCH file paths will be trimmed to remove excluded files.
 * @param excludes List of filenames to exclude from the collection.
 */
void _fwInstallationQtHelp_filterQchFiles(
  dyn_string &qchFilePaths /*out*/,
  const dyn_string excludes)
{
  for (int x = 1; x <= dynlen(excludes); x++)
  {
    int removeIdx = 0;
    for (int i = 1; i <= dynlen(qchFilePaths); i++)
    {
      dyn_string parts = strsplit(qchFilePaths[i], "/");
      int lastPartIdx = dynlen(parts);
      if (parts[lastPartIdx] == excludes[x])
      {
        removeIdx = i;
      }
    }

    if (removeIdx > 0)
    {
      dynRemove(qchFilePaths, removeIdx);
    }
  }
}

/**
 * Create symbolic links inside project help collection directory to *.QCH files located in
 * WinCC OA installation directory. Update paths of these files in a list of help files.
 * Linux only, has no effect on Windows.
 *
 * @param[out] qchFilePaths A list that QCH file paths will be searched and updated.
 */
void _fwInstallationQtHelp_replacePvssDirQchFilesWithLinks(dyn_string &qchFilePaths /*out*/){
  if(_WIN32){
    return; // functionality available only on Linux, when Windows - exit immediately
  }
  string linksDirPath = getPath(HELP_REL_PATH, "", getActiveLang()) +
                    FW_INSTALLATION_QT_HELP_SYMLINKS_DIR;
  if(isdir(linksDirPath)){
    if(!rmdir(linksDirPath, true)){
      fwInstallation_throw("Could not remove directory with symbolic links to QCH files inside " +
                           "WinCC OA installation directory. Registering WinCC OA QCH files with "
                           "their original paths", "WARNING", 27);
      return;
    }
  }
  if(!mkdir(linksDirPath)){
    fwInstallation_throw("Could not create directory to store symbolic links to QCH files " +
                         "inside WinCC OA installation directory. Registering WinCC OA QCH files "
                         "with their original paths", "WARNING", 27);
    return;
  }
  for(int i=1;i<=dynlen(qchFilePaths);i++){
    string qchFilePath = qchFilePaths[i];
    if(strpos(qchFilePath, PVSS_PATH) == 0){
      string qchFileName = _fwInstallation_fileName(qchFilePath);
      if(_fwInstallationQtHelp_createSymbolicLink(qchFilePath, linksDirPath) != 0){
        fwInstallation_throw("Could not create symbolic link to: " + qchFilePath + " inside " +
                             "project path. Registering file with its original path", "WARNING", 27);
      }else{
        qchFilePaths[i] = linksDirPath + qchFileName;
        fwInstallation_throw("QCH file: " + qchFilePath + " replaced with symbolic link inside " +
                             "project path help directory", "INFO", 27);
      }
    }
  }
  // force update of cached help collection file
  rmdir(getPath(HELP_REL_PATH, "", getActiveLang()) + FW_INSTALLATION_QT_HELP_COLLECTION_CACHE_DIR);
}

/**
 * Execute bash command to create symbolic link inside linkDir directory to target file.
 *
 * @param target A path to file where symbolic link should point to
 * @param linkDir Path to directory where symbolic link shold be created
 * @return 0 for success, non-zero value in case of failure
 */
int _fwInstallationQtHelp_createSymbolicLink(string target, string linkDir){
  return system("ln -s " + target + " " + linkDir);
}


/** Internal functions to report progress of help generation
  */
_fwInstallationQtHelp_flagExecution(char totalSteps){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSet(dp + ".postInstallFiles:_original.._userbyte2",
          (1<<FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP),
          dp + ".postInstallFiles:_original.._userbyte3", totalSteps,
          dp + ".postInstallFiles:_original.._userbyte4", 0);
}

_fwInstallationQtHelp_setExecutionCurrentStep(char currentStep){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSetWait(dp + ".postInstallFiles:_original.._userbyte4", currentStep);
}

_fwInstallationQtHelp_clearExecutionBits(){
    string dp = fwInstallation_getInstallationPendingActionsDp();
    dpSetWait(dp + ".postInstallFiles:_original.._userbits", 0);
}
