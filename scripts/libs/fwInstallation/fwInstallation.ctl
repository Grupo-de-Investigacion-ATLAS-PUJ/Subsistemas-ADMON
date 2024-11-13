//FVR
// $License: NOLICENSE
/**@file
 *
 * This package contains general functions of the FW Component Installation tool
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */

#uses "CtrlPv2Admin"
#uses "pmon.ctl"
#uses "dist.ctl"    //Not loaded by default by control managers

#uses "fwInstallation/fwInstallationInit.ctl"
#uses "fwInstallation/fwInstallationDB.ctl"
#uses "fwInstallation/fwInstallationDBAgent.ctl"
#uses "fwInstallation/fwInstallationRedu.ctl"
#uses "fwInstallation/fwInstallationManager.ctl"
#uses "fwInstallation/fwInstallationXml.ctl"
#uses "fwInstallation/fwInstallationPackager.ctl"
#uses "fwInstallation/fwInstallationQtHelp.ctl"
#uses "fwInstallation/fwInstallationDeprecated.ctl"
///////////////////////////////////////////////////
/** Version of this tool.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationToolVersion = "9.1.3";
/** Tool version tag. In repository it has a value "devel", when snapshot/beta is built it is replaced by pre-release tag. In final relase this global is an empty string.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationToolTag = "";
/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationLibVersion = "9.1.3";


///EN-ICE support line:
const string FW_INSTALLATION_SUPPORT_ADDRESS = "icecontrols.support@cern.ch";

///////////////////////////////////////////////////
/**
 * @name fwInstallation.ctl: Definition of variables

   The following variables are used by the fwInstallationManager.ctl library

 * @{
 */

dyn_bool    gButtonsEnabled;
string      gUserName;
string      gPassword;
string      gDebugFlag;
int         gSelectedMan;
int         gManShifted;
bool        gRefreshManagerList;
int         gRefreshSec;
int         gRefreshMilli;
int         gRefreshTime;

// Global variables needed by functions defined in pmon.ctl
string      gTcpHostName;
int         gTcpPortNumber;
int         gTcpFileDescriptor;
int         gTcpFileDescriptor2;
string      gTcpFifo;

string      gTestVariable;
bool        gShowLicenseWarning;
int         gErrorCounter;
bool        gCloseEnabled;
dyn_string  gParams;

global string      gFwInstallationPmonUser = "N/A";
global string      gFwInstallationPmonPwd = "N/A";
global dyn_dyn_string      gFwInstallationLog;
global string      gFwInstallationLogPost;

mapping            gFwInstallationTrackDependency; // mapping to store information about dependencies of components being installed.

global string      gFwInstallationCurrentComponent;

//@} // end of constants

/** Error codes that can be ignored while doing ASCII import
 * @ingroup Constants
 */
//const dyn_int gASCIIImportErrorsToIgnore = makeDynInt(0, 55, 56, 58, 69, 76);

/** Name of this component.
 * @ingroup Constants
*/
const string gFwInstallationComponentName = "fwInstallation";
/** Name of the config file of the tool.
 * @ingroup Constants
*/
const string gFwInstallationConfigFile = "fwInstallation.config";
/** Name of the init file loaded at start up of the tool.
 * @ingroup Constants
*/
const string gFwInstallationInitFile = "fwInstallationInit.config";

/** Returned error code in case of problems
 * @ingroup Constants
*/
const int gFwInstallationError = -1;
/** Returned error code in case everything is OK
 * @ingroup Constants
*/
const int gFwInstallationOK = 0;
/** Constant that stores a particular error has already been shown
 * @ingroup Constants
*/
bool gFwInstallationErrorShown = FALSE;

/** Constant that stores if the user has clicked in the Yes to All button during installations
 * @ingroup Constants
*/
bool gFwYesToAll = FALSE;

//const int EXPIRED_REQUEST_ACTION = 1;
//const int EXPIRED_REQUEST_NAME = 2;
//const int EXPIRED_REQUEST_VERSION = 3;
//const int EXPIRED_REQUEST_EXECUTION_DATE = 4;

/** Name of the Installation Tool internal dp-types
 * @ingroup Constants
*/
const string FW_INSTALLATION_DPT_COMPONENTS = "_FwInstallationComponents";
const string FW_INSTALLATION_DPT_INFORMATION = "_FwInstallationInformation";
const string FW_INSTALLATION_DPT_PENDING_ACTIONS = "_FwInstallationPendingActions";

/** Name of the Installation Tool DB-Agent internal dp-types
 * @ingroup Constants
*/
const string FW_INSTALLATION_DPT_AGENT_PARAMETRIZATION = "_FwInstallation_agentParametrization";
const string FW_INSTALLATION_DPT_AGENT_PENDING_REQUESTS = "_FwInstallation_agentPendingRequests";

/** keyword used to replace by the current version name
 * @ingroup Constants
*/
string fwInstallation_VERSION_KEYWORD = "%VERSION%";
/** Path to the trash folder
 * @ingroup Constants
*/
const string gFwTrashPath = PROJ_PATH + "/fwTrash/";

/** Relative path from help/en_US.utf8/ directory to the fwInstallation release notes file
 * @ingroup Constants
*/
const string FW_INSTALLATION_RELEASE_NOTES = "fwInstallation/fwInstallationReleaseNotes.txt";

/** fwInstallation main log file name.
 * @ingroup Constants
*/
const string FW_INSTALLATION_LOG_FILE = "fwInstallation.log";

/** Log files to store stdout and stderr ASCII import messages.
 * @ingroup Constants
*/
const string FW_INSTALLATION_ASCII_IMPORT_LOG_FILE_NAME_DEFAULT =
    "fwInstallation_" + fwInstallation_getWCCOAExecutable("ascii") + "_log.txt";
const string FW_INSTALLATION_ASCII_IMPORT_LOG_ROTATION_SIZE_DEFAULT = 25; // MB
const string FW_INSTALLATION_ASCII_IMPORT_LOG_OVERWRITE_ALWAYS = 0;
const string FW_INSTALLATION_ASCII_IMPORT_LOG_OVERWRITE_NEVER = -1;
const string FW_INSTALLATION_ASCII_IMPORT_LOG_SIZE_INVALID = -2;

const string FW_INSTALLATION_CONFIG_FILE_NAME = "config";

const string FW_INSTALLATION_SCRIPTS_MANAGER_CMD = "-f fwScripts.lst";
const string FW_INSTALLATION_DB_AGENT_MANAGER_CMD = "-f fwInstallationAgent.lst";

const string gFwInstallationOverparametrizedFileIssue = "OVERPARAMETERIZED"; // multiple instances
const string gFwInstallationHashFileIssue             = "HASH"; // hash error
const string gFwInstallationCompNotPossibleFileIssue  = "HASH_COMPARASION_NOT_POSSIBLE"; // no hash comparison possible

const string FW_INSTALLATION_BUILD_LEGACY_LIB_SCRIPT = "fwInstallation/fwInstallation_buildLegacyLibrary.ctl";

//Beginning executable code:

//======== Source file hashes =========

const dyn_string FW_INSTALLATION_HASH_FOLDERS = makeDynString("bin/", "colorDB/", "msg/", "panels/", "scripts/"); //calculate hash only for files from these folders
const dyn_string FW_INSTALLATION_HASH_FILES_EXCEPTIONS = makeDynString("panels/fwFSMuser/fwUi.pnl",
                                                                       "panels/fwFSMuser/logo.pnl"); //don't calculate hash for files from this list

/** Gets the list of component files for which hash calculation should be done.
  * It retreives list of all component files from internal component dp and filters out files for which hash calculation should not be performed.
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param componentFiles (out)  List of component files for which hash calculation should be done
  * @return 0 in case when list was retreived successfully, -1 in case of error (component doesn't have any files)
  */
int fwInstallation_getComponentFilesForHashCalculation(string component, dyn_string &componentFiles)
{
  //get list of all component files
  dyn_string allComponentFiles;
  fwInstallation_getComponentInfo(component, "componentfiles", allComponentFiles);
  if(dynlen(allComponentFiles) <= 0)
  {
    fwInstallation_throw("Component: " + component + " does not have any files", "INFO", 17);
    return -1;
  }
  const int allComponentFilesLen = dynlen(allComponentFiles);
  const int hashFoldersLen = dynlen(FW_INSTALLATION_HASH_FOLDERS);
  const int hashFilesExceptionLen = dynlen(FW_INSTALLATION_HASH_FILES_EXCEPTIONS);
  dynClear(componentFiles);
  for(int i=1;i<=allComponentFilesLen;i++)
  {
    string componentFile = allComponentFiles[i];
    strreplace(componentFile, "./", "");
    for(int j=1;j<=hashFoldersLen;j++)
      if(patternMatch(FW_INSTALLATION_HASH_FOLDERS[j] + "*", componentFile))
      {//check if file should be included by checking its folder
        if(fwInstallation_normalizePath(componentFile) != 0)
        {
          fwInstallation_throw("Failed to normalize path of file: " + componentFile + ". File is not added to the list of files for hash calculation", "WARNING", 17);
          continue;
        }
        bool addComponentFile = true;
        for(int k=1;k<=hashFilesExceptionLen;k++)
          if(patternMatch(FW_INSTALLATION_HASH_FILES_EXCEPTIONS[k], componentFile))
          {//file should be excluded from hash calculation and comparison
            addComponentFile = false;
            break;
          }

        if(addComponentFile)
        {//add component file to the list of files for which hash is calculated
          dynAppend(componentFiles, componentFile);
          break;
        }
      }
  }
  dynUnique(componentFiles);
  return 0;
}

/** Checks if for given file a hash calculation should be performed.
  * @param componentFile  Relative path to the file from the component source directory
  * @return true if hash calculation should be done for file, false otherwise
  */
private bool fwInstallation_shallCalculateHashForFile(string componentFile){
  strreplace(componentFile, "./", "");
  bool shallCalculateHash;
  for(int i=1;i<=dynlen(FW_INSTALLATION_HASH_FOLDERS);i++){
    if(patternMatch(FW_INSTALLATION_HASH_FOLDERS[i] + "*", componentFile)){
      shallCalculateHash = true; // file should be included as it is in directory for which file hash is calculated
      break;
    }
  }
  if(shallCalculateHash){ // check also if file does not appear on the list of files that should be excluded
    fwInstallation_normalizePath(componentFile);
    for(int i=1;i<=dynlen(FW_INSTALLATION_HASH_FILES_EXCEPTIONS);i++){
      if(patternMatch(FW_INSTALLATION_HASH_FILES_EXCEPTIONS[i], componentFile)){
        shallCalculateHash = false;
        break;
      }
    }
  }
  return shallCalculateHash;
}

const string FW_INSTALLATION_HASH_FILENAME_SEPARATOR = "|"; //this serves as separator between hash value and file name when they are stored together.

/** This function calculates and saves sources files hashes of given component.
  * See also fwInstallation_calculateSourceFilesHashes() help for information how this information is stored
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @return 0 whem hashes were successfully calculated and stored, -2 when component files do not exist in source directory,
  *         -1 in case of other error (failed to retreive source directory or component descriptor, failed to store hashes in a file)
  */
int fwInstallation_calculateComponentSourceFilesHashes(string component){
  //get component source directory
  dyn_anytype sourceDirCompInfo, descFileCompInfo;
  if(fwInstallation_getComponentInfo(component, "sourcedir", sourceDirCompInfo) != 0 ||
     dynlen(sourceDirCompInfo) < 1 || sourceDirCompInfo[1] == "" ||
     fwInstallation_getComponentInfo(component, "descfile", descFileCompInfo) != 0 ||
     dynlen(descFileCompInfo) < 1 || descFileCompInfo[1] == ""){
    fwInstallation_throw("Could not retrieve the source directory and/or description file for component: " + component +
                         " from internal dp. Hash calculation not possible", "WARNING", 18);
    return -1;
  }
  string sourceDir = sourceDirCompInfo[1];
  string descFile = descFileCompInfo[1];
  string descFilePath = sourceDir + strltrim(descFile, "./");
  if(access(descFilePath, R_OK) != 0){
    fwInstallation_throw("Component " + component + " not found in source directory: " + sourceDir +
                         ". Hash calculation not possible", "WARNING", 18);
    return -2;
  }

  dyn_dyn_mixed parsedComponentInfo;
  if(fwInstallationXml_parseFile("", descFilePath, "", "", parsedComponentInfo) != 0){
    fwInstallation_throw("Could not parse component description file. Hash calculation not possible");
    return -1;
  }
  return fwInstallation_calculateSourceFilesHashes(parsedComponentInfo, sourceDir);
    }

/** Calculates and saves in internal dp the source file hashes of component given as an info array
  * Data is stored as a list of formatted strings in a component installation dp: _fwInstallation_[componentName].sourceFilesHashes.
  * Single string contains information about particular file, it has the following pattern:
  * [baseHashValue]|[alternativeHashValue]|[relativePathToComponentFile]
  * - baseHashValue is a hash of a file in component source directory
  * - alternativeHashValue by default is the same as base hash value, however user can store there hash value of component file from installation directory - it can be used to mask 'hash mismatch' file issue
  * If source file is not accessible or it is not possible to calculate hash for the file then it is added to the list with empty hash.
  * File issue 'Hash comparison not possible' will be detected in such case, user later can mask this error by setting an alternativeHashValue for file (as for 'hash mismatch' file issue)
  * @param parsedComponentInfo (in)  Array containing component information (incl. files) parsed from component XML description file
  * @param sourceDir (in)  Directory containing component files
  * @return 0 whem hashes were successfully calculated and stored, -1 in case of error (failed to store hashes in a dp)
  */
private int fwInstallation_calculateSourceFilesHashes(const dyn_dyn_mixed &parsedComponentInfo, string sourceDir){
  dyn_string sourceFileHashStringList = fwInstallation_getSourceFileHashStringList(parsedComponentInfo, sourceDir);
  string component = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
  return dpSet(fwInstallation_getComponentDp(component) + ".sourceFilesHashes", sourceFileHashStringList);
  }

/** Returns a list of hash strings of files of component given as an info array
  * @param parsedComponentInfo (in)  Array containing component information (incl. files) parsed from component XML description file
  * @param sourceDir (in)  Directory containing component files
  * @return List containing hash strings of files of a component
  */
dyn_string fwInstallation_getSourceFileHashStringList(const dyn_dyn_mixed &parsedComponentInfo, string sourceDir){
  dyn_string sourceFileHashStringList;
  dyn_string componentFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_FILES];
  for(int i=1;i<=dynlen(componentFiles);i++){
    string componentFile = componentFiles[i];
    if(strpos(componentFile, "./") == 0){
      componentFile = substr(componentFile, 2);
    }
    if(fwInstallation_shallCalculateHashForFile(componentFile)){
      string fileHashString = fwInstallation_getSourceFileHashString(sourceDir, componentFile);
      dynAppendConst(sourceFileHashStringList, fileHashString);
    }
  }
  string componentName = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
  dyn_string componentBinaries = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES];
  for(int i=1;i<=dynlen(componentBinaries);i++){
    string sourceComponentBinary = componentBinaries[i];
    string targetComponentBinary = fwInstallation_getBinaryFileTargetPath(componentName, sourceComponentBinary);
    if(targetComponentBinary != ""){
      fwInstallation_normalizePath(targetComponentBinary);
      string fileHashString =
          fwInstallation_getSourceFileHashString(sourceDir, sourceComponentBinary, targetComponentBinary);
      dynAppendConst(sourceFileHashStringList, fileHashString);
    }
  }
  return sourceFileHashStringList;
}

/** Returns a file hash string of a given file
  * A hash string has the following pattern: [baseHashValue]|[alternativeHashValue]|[relativePathToComponentFile]
  * If hash calculation cannot be done for a file baseHashValue and alternativeHashValue are empty
  * @param sourceDir (in)  Directory containing component files
  * @param sourceFile (in)  Relative path to the component file inside the component source directory
  * @param targetFile (in) Relative path to the component file inside the component installation directory
  * @return File hash string
  */
private string fwInstallation_getSourceFileHashString(string sourceDir, string sourceFile, string targetFile = ""){
  string fileHash = "";
  string sourceFilePath = sourceDir + strltrim(sourceFile, "./");
  if(access(sourceFilePath, R_OK) == 0){
    fileHash = getFileCryptoHash(sourceFilePath);
    if(fileHash == "")
      fwInstallation_throw("Failed to calculate hash for source file: " + sourceFilePath + ". Saving file without hash in the list", "WARNING");
  }else{
    fwInstallation_throw("Failed to access file: " + sourceFilePath + ". Hash calculation not possible, saving file without hash in the list.", "WARNING");
  }
  return fwInstallation_formatComponentSourceFileHashString(targetFile == ""?sourceFile:targetFile, fileHash, fileHash);
}

/** Store list of component files and list of corresponding hash values for given component in the component dp.
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param fileNames (in)  List of relative paths of component files for which the hash was calculated
  * @param baseFileHashes (in)  List of base hash values of component files
  * @param alternativeFileHashes (in)  List of alternative hash values of component files
  * @return 0 if lists of files and hashes were saved successfully in dp, -1 in case of errors (provided lists are of different size, failed to set value of dp)
  */
int fwInstallation_storeComponentSourceFilesHashes(string component, dyn_string fileNames, dyn_string baseFileHashes, dyn_string alternativeFileHashes)
{
  int componentFilesLen = dynlen(fileNames);
  if(dynlen(baseFileHashes) != componentFilesLen || dynlen(alternativeFileHashes) != componentFilesLen)
  {
    fwInstallation_throw("List of files and list of hashes are of different size. Failed to store list of file hashes for component: " + component);
    return -1;
  }

  dyn_string componentFilesHashes;
  for(int i=1;i<=componentFilesLen;i++)
    dynAppend(componentFilesHashes, fwInstallation_formatComponentSourceFileHashString(fileNames[i], baseFileHashes[i], alternativeFileHashes[i]));

  return dpSet(fwInstallation_getComponentDp(component) + ".sourceFilesHashes", componentFilesHashes);
}

/** This function formats string that contains information about particular component file, its hash value and hash comparison status
  * @param fileName (in)  Relative path to a component file
  * @param baseFileHash (in)  Base hash value for component file (should be the one calculated for file in component source directory)
  * @param alternativeFileHash (in)  Alternative hash value for component file, when empty (default) then baseFileHash is used here
  * @return Formatted string with component source file hash info
  */
string fwInstallation_formatComponentSourceFileHashString(string fileName, string baseFileHash, string alternativeFileHash = "")
{
  if(alternativeFileHash == "")
    alternativeFileHash = baseFileHash;
  return baseFileHash + FW_INSTALLATION_HASH_FILENAME_SEPARATOR + alternativeFileHash + FW_INSTALLATION_HASH_FILENAME_SEPARATOR + fileName;
}

/** Retrieves list of component files and list of corresponding hash values for given component.
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param fileNames (out)  List of relative paths of component files for which the hash was calculated
  * @param baseFileHashes (out)  List of base hash values of component files
  * @param alternativeFileHashes (out)  List of alternative hash values of component files
  * @return 0 if lists of files and hashes were retreived successfully, -1 in case of errors (failed to get list of files and hashes from dp)
  */
int fwInstallation_getComponentSourceFilesHashes(string component, dyn_string &fileNames, dyn_string &baseFileHashes, dyn_string &alternativeFileHashes)
{
  dyn_string componentFilesHashes;
  if(dpGet(fwInstallation_getComponentDp(component) + ".sourceFilesHashes", componentFilesHashes) != 0)
  {
    fwInstallation_throw("Failed to get list of component source files hashes for component: " + component);
    return -1;
  }
  dynClear(fileNames);
  dynClear(baseFileHashes);
  dynClear(alternativeFileHashes);
  int componentFilesHashesLen = dynlen(componentFilesHashes);
  for(int i=1;i<=componentFilesHashesLen;i++)
  {
    string componentFileHash = componentFilesHashes[i];
    //get position of first separator
    int separator1Pos = strpos(componentFileHash, FW_INSTALLATION_HASH_FILENAME_SEPARATOR);
    if(separator1Pos < 0)
    {
      fwInstallation_throw("Failed to get base and alternative hash and filename from line: " + componentFileHash + " - incorrect line format. Skipping this line.", "WARNING");
      continue;
    }
    if(separator1Pos != 32 && separator1Pos != 0)//second condition to avoid log littering when there is no hash value for file - this will appear on file issue list as 'hash comparison not possible'
      fwInstallation_throw("Base hash in line: " + componentFileHash + " has unexpected length of " + (string)separator1Pos + " bits. The expected length is 32 bits", "WARNING");
    //get base file hash value (part of componentFileHash string before first separator)
    string baseFileHash = substr(componentFileHash, 0, separator1Pos);

    //get position of second separator
    int separator2Pos = strpos(componentFileHash, FW_INSTALLATION_HASH_FILENAME_SEPARATOR, separator1Pos + 1);
    if(separator2Pos < 0)
    {
      fwInstallation_throw("Failed to get alternative hash and filename from line: " + componentFileHash + " - incorrect line format. Skipping this line.", "WARNING");
      continue;
    }
    int separator2PosRelative = separator2Pos - separator1Pos - 1;
    if(separator2PosRelative != 32 && separator2PosRelative != 0)//second condition to avoid log littering when there is no hash value for file - this will appear on file issue list as 'hash comparison not possible'
      fwInstallation_throw("Alternative hash in line: " + componentFileHash + " has unexpected length of " + (string)separator2PosRelative + " bits. The expected length is 32 bits", "WARNING");
    //get alternative file hash value (part of componentFileHash string between first and second separator)
    string alternativeFileHash = substr(componentFileHash, separator1Pos + 1, separator2PosRelative);

    //get file name from the rest of the componentFileHash string
    string fileName = substr(componentFileHash, separator2Pos + 1);

    dynAppend(fileNames, fileName);
    dynAppend(baseFileHashes, baseFileHash);
    dynAppend(alternativeFileHashes, alternativeFileHash);
  }
  return 0;
}

/** This function allows to set alternative hash value for file.
  * It can be used to hide 'hash mismatch' file issues for given file.
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param fileName (in)  Relative path to a component file
  * @param directory (in)  Flag that indicates if hash comparison should be enabled (true - default) or disabled
  * @return 0 when file hash value was updated successfully, -1 in case of an error (error reading dp that contains component file hashes, given file is not a component file or failed to update dp with hashes)
  */
int fwInstallation_setAlternativeComponentFileHash(string component, string fileName, string directory = "")
{
  dyn_string fileNames, baseFileHashes, alternativeFileHashes;
  if(fwInstallation_getComponentSourceFilesHashes(component, fileNames, baseFileHashes, alternativeFileHashes) != 0)
  {
    fwInstallation_throw("Failed to get base and alternative file hashes for component: " + component + ". Failed to set alternative hash value for file: " + fileName);
    return -1;
  }
  int componentFilesLen = dynlen(fileNames);
  if(dynlen(baseFileHashes) != componentFilesLen || dynlen(alternativeFileHashes) != componentFilesLen)
  {
    fwInstallation_throw("List of files and list of hashes are of different size. Failed to set alternative hash value for file: " + fileName);
    return -1;
  }
  fwInstallation_normalizePath(fileName);
  int filePosition = dynContains(fileNames, fileName);//get index of fileName in an array of component files
  if(filePosition < 1)
  {
    fwInstallation_throw("Provided file name " + fileName + " is not a part of " + component + " component. Cannot to set alternative hash value for this file");
    return -1;
  }

  if(directory == "")//resolve default installation directory when it is not provided
  {
    dyn_string at;
    fwInstallation_getComponentInfo(component, "installationdirectory", at);
    if(dynlen(at) <= 0 || at[1] == "")
    {
      fwInstallation_throw("Could not retrieve the installation directory for component: " + component + ". Failed to to set alternative hash value for file: " + fileName);
      return -1;
    }
    directory = at[1];
  }
  fwInstallation_normalizePath(directory, true);
  string filePath = directory + fileName;
  if(access(directory + fileName, F_OK) != 0)
  {
    fwInstallation_throw("Cannot access file " + filePath + ". Failed to set alternative hash value for this file");
    return -1;
  }
  string fileHash = getFileCryptoHash(filePath);
  if(fileHash == "")
  {
    fwInstallation_throw("Error while calculating hash for file: " + filePath + ". Failed to set alternative hash value for this file");
    return -1;
  }

  alternativeFileHashes[filePosition] = fileHash;

  return fwInstallation_storeComponentSourceFilesHashes(component, fileNames, baseFileHashes, alternativeFileHashes);
}

/** This function resets alternative hash value for given file (set alternative hash same as base hash)
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param fileName (in)  Relative path to a component file
  * @return 0 when file hash value was reset successfully, -1 in case of an error (error reading dp that contains component file hashes, given file is not a component file or failed to update dp with hashes)
  */
int fwInstallation_resetAlternativeComponentFileHash(string component, string fileName)
{
  dyn_string fileNames, baseFileHashes, alternativeFileHashes;
  if(fwInstallation_getComponentSourceFilesHashes(component, fileNames, baseFileHashes, alternativeFileHashes) != 0)
  {
    fwInstallation_throw("Failed to get base and alternative file hashes for component: " + component + ". Failed to reset alternative hash value for file: " + fileName);
    return -1;
  }
  int componentFilesLen = dynlen(fileNames);
  if(dynlen(baseFileHashes) != componentFilesLen || dynlen(alternativeFileHashes) != componentFilesLen)
  {
    fwInstallation_throw("List of files and list of hashes are of different size. Failed to reset alternative hash value for file: " + fileName);
    return -1;
  }
  int filePosition = dynContains(fileNames, fileName);//get index of fileName in an array of component files
  if(filePosition < 1)
  {
    fwInstallation_throw("Provided file name " + fileName + " is not a part of " + component + " component. Cannot to reset alternative hash value for this file");
    return -1;
  }

  alternativeFileHashes[filePosition] =  baseFileHashes[filePosition];

  return fwInstallation_storeComponentSourceFilesHashes(component, fileNames, baseFileHashes, alternativeFileHashes);
}

/** This function retrieves list of files that have set alternative hash value different than base hash value
  * @param component (in)  Component name, when subcomponent then must be provided without leading underscore
  * @param filesWithAlternativeHash (out)  List of files that have set alternative hash value different than base hash value
  * @return 0 when list was retrieved successfully, -1 in case of an error when reading dp that contains component file hashes
  */
int fwInstallation_getComponentFilesWithAlternativeHash(string component, dyn_string &filesWithAlternativeHash)
{
  dyn_string fileNames, baseFileHashes, alternativeFileHashes;
  if(fwInstallation_getComponentSourceFilesHashes(component, fileNames, baseFileHashes, alternativeFileHashes) != 0)
  {
    fwInstallation_throw("Failed to get base and alternative file hashes for component: " + component + ". Cannot retrieve list of files with alternative hashes for this component");
    return -1;
  }
  int componentFilesLen = dynlen(fileNames);
  if(dynlen(baseFileHashes) != componentFilesLen || dynlen(alternativeFileHashes) != componentFilesLen)
  {
    fwInstallation_throw("List of files and list of hashes are of different size. Failed to retrieve list of files with alternative hashes for component: " + component);
    return -1;
  }

  dynClear(filesWithAlternativeHash);
  for(int i=1;i<=componentFilesLen;i++)
    if(baseFileHashes[i] != alternativeFileHashes[i])
      dynAppend(filesWithAlternativeHash, fileNames[i]);
  return 0;
}

//========== File issues for project and particular component ===========
/**
Gets all the file issues for the project
@param fileIssues (out) array of all file issues
*/
int fwInstallation_getProjectFileIssues(dyn_dyn_mixed &fileIssues)
{
  dyn_mapping projectFileIssues;
  dyn_dyn_string componentsInfo;
  fwInstallation_getInstalledComponents(componentsInfo);

  int n = 1;
  for(int i = 1; i <= dynlen(componentsInfo); i++)
  {
    dynClear(projectFileIssues);
    fwInstallation_getComponentFilesIssues(componentsInfo[i][1], projectFileIssues);
    //append file issues to array:
    for(int j = 1; j <= dynlen(projectFileIssues); j++)
    {

      fileIssues[n][FW_INSTALLATION_DB_FILE_ISSUE_COMPONENT] = componentsInfo[i][1];
      fileIssues[n][FW_INSTALLATION_DB_FILE_ISSUE_VERSION] = componentsInfo[i][2];
      fileIssues[n][FW_INSTALLATION_DB_FILE_ISSUE_FILENAME] = projectFileIssues[j]["name"];
      fileIssues[n][FW_INSTALLATION_DB_FILE_ISSUE_TYPE] = projectFileIssues[j]["error"];
      fileIssues[n][FW_INSTALLATION_DB_FILE_ISSUE_MODIFICATION_DATE] = projectFileIssues[j]["time"];
      ++n;
    }
  }

  return 0;
}

/** Gets all the file issues for a particular component in the project
  * @param component (in)  Name of the component, when subcomponent then must be provided without leading underscore
  * @param errorFiles (out)  Array of all file issues. Each file issue is represented by a mapping with following fields: 'name' (absolute path to a file), 'error' (file issue type), 'size' (file size), 'time' (file modification time)
  * @param getOverparameterized (in)  Indicates whether the method should include the overparameterized files in the result, default value is true
  * @param getHash (in)  Indicates whether the method should include the files with hash issue in the result, default value is true
  * @param getHashCompNotPossible (in)  Indicates whether the method should include the files for which hash comparasion is not possible in the result, default value is true
  * @param useAlternativeHash (in)  Indicates whether file hash should be compared to the alternative hash value (true - default) or base hash value (false)
  * @return 0 if OK, -1 if error (component is not installed, failed to get installation directory, failed to read file with source files hashes values, failed to calculate hash for component's file)
  */
int fwInstallation_getComponentFilesIssues(string component, dyn_mapping &errorFiles, bool getOverparameterized = true, bool getHash = true,
                                           bool getHashCompNotPossible = true, bool useAlternativeHash = true)
{
  string version = "";
  if(!fwInstallation_isComponentInstalled(component, version))
  {
    fwInstallation_throw("Component: " + component + " not installed in the local project. Not possible to find out error files", "WARNING", 16);
    return -1;
  }

  //get list of files that should be checked in project directories
  dyn_string componentFiles;
  if(fwInstallation_getComponentFilesForHashCalculation(component, componentFiles))
  {
    fwInstallation_throw("Could not get list of source files of component: " + component + ". Failed to get component file issues", "WARNING", 18);
    return -1;
  }
  //get reference hash values for component files
  dyn_string sourceFileNames, sourceFileHashes, alternativeFileHashes;
  if(fwInstallation_getComponentSourceFilesHashes(component, sourceFileNames, sourceFileHashes, alternativeFileHashes) != 0)
  {
    fwInstallation_throw("Failed to get " + component + " component source files hashes. Failed to get component file issues");
    return -1;
  }
  int sourceFileNamesLen = dynlen(sourceFileNames);

  //get installation directory
  dyn_anytype at;
  fwInstallation_getComponentInfo(component, "installationdirectory", at);
  if(dynlen(at) <= 0 || at[1] == "")
  {
    fwInstallation_throw("Could not retrieve the installation directory for component: " + component + ". Failed to get component file issues", "WARNING", 18);
    return -1;
  }
  string installationDir = at[1];
  if(fwInstallation_normalizePath(installationDir, true) != 0)
  {
    fwInstallation_throw("Could not normalize installation directory path of component: " + component + ". Failed to get component file issues");
    return -1;
  }
  //get all project paths:
  dyn_string projPaths;
  fwInstallation_getProjPaths(projPaths);
  int installationDirPosition = dynContains(projPaths, strrtrim(installationDir, "/"));//find where is installation directory
  if(installationDirPosition < 1)
  {
    fwInstallation_throw("Could not get find installation directory of component: " + component + " in the list of project paths. Failed to get component file issues");
    return -1;
  }
  int componentFilesLen = dynlen(componentFiles);
  int projPathsLen = dynlen(projPaths);
  for(int i=installationDirPosition;i<=projPathsLen;i++)//search for file issues in installation directory and in all directories that are below it in the hierarchy
  {
    string projPath = projPaths[i] + "/";//add trailing slash for directory path
    if(getOverparameterized && i > installationDirPosition)
    {//look for overparametrized files only when they are in paths that are below the installation directory in config file, in other cases there is no overparametrization - a file from installation directory is loaded by WinCC OA
      for(int j=1;j<=componentFilesLen;j++)
      {
        string overparametrizedFile = projPath + componentFiles[j];
        if(isfile(overparametrizedFile))
          dynAppend(errorFiles, makeMapping("name", overparametrizedFile,
                                            "error", gFwInstallationOverparametrizedFileIssue,
                                            "size", getFileSize(overparametrizedFile),
                                            "time", getFileModificationTime(overparametrizedFile)));
      }
    }
    else if(getHash || getHashCompNotPossible)
    {//compare file hashes, if getOverparameterized is false then compare hashes of files in all project directories starts from installation directory
      for(int j=1;j<=sourceFileNamesLen;j++)
      {
        string componentFileName = projPath + sourceFileNames[j];
        if(access(componentFileName, R_OK) != 0)
        {
          if(i == installationDirPosition)//file should be in installation directory, if not then throw an error/(or report as file issue - 'missing file' - TODO)
          {
            fwInstallation_throw("File " + componentFileName + " of " + component + " component not found in installation directory. Cannot calculate hash for this file");
          }
          continue;
        }

        string componentFileHash = getFileCryptoHash(componentFileName);
        if(componentFileHash == "")
        {
          fwInstallation_throw("Failed to calculate file hash for file " + componentFileName + " of " + component + " component. Failed to get component file issues");
          continue;
        }

        int hashMismatch = -1;
        if(useAlternativeHash && alternativeFileHashes[j] != "")
          hashMismatch = (int)(componentFileHash != alternativeFileHashes[j]);
        if(!useAlternativeHash && sourceFileHashes[j] != "")
          hashMismatch = (int)(componentFileHash != sourceFileHashes[j]);

        if(hashMismatch == 1)
          dynAppend(errorFiles, makeMapping("name", componentFileName,
                                            "error", gFwInstallationHashFileIssue,
                                            "size", getFileSize(componentFileName),
                                            "time", getFileModificationTime(componentFileName)));
        else if(hashMismatch < 0)
          dynAppend(errorFiles, makeMapping("name", componentFileName,
                                        "error", gFwInstallationCompNotPossibleFileIssue,
                                        "size", getFileSize(componentFileName),
                                        "time", getFileModificationTime(componentFileName)));

      }
    }
  }
  return 0;
}

/**
fwInstallation_installComponentSet installs a set of components in the local project.
@param componentNames (in) array of string containing the names of the components to be installed.
@param dontRestartProject (out) overall flag that specifies if project restart can be skipped at the end of the installation,
       "yes" means the project restart can be skipped and the post-installation scripts are launched.
@return 0 if all components were installed succesfully, -2 if circular depnedencies detected, -3 if failed to back up config file, -1 if there were errors while installing compoents
*/
int fwInstallation_installComponentSet(dyn_string componentFiles,
                                       string &dontRestartProject)
{
  int err = 0;
  dyn_string componentFilesInOrder;
  dontRestartProject = "yes"; //assume that the project does not have to be restarted.
  string localDontRestartProject = "yes";
  dyn_string componentNames, componentVersions;
  for(int i = dynlen(componentFiles); i >= 1; i--)
  {
    dyn_dyn_mixed componentInfo;
    dynClear(componentInfo);
    if(fwInstallationXml_load(componentFiles[i], componentInfo))
    {
      fwInstallation_throw("Could not load XML file: " + componentFiles[i] + ". Component skipped from installation.");
      dynRemove(componentFiles, i);
      continue;

    }
    dynInsertAt(componentNames, componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME][1], 1);
    dynInsertAt(componentVersions, componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION][1], 1);
  }//end of loop over components.

  // put the components in order for installing
  if(fwInstallation_putComponentsInOrder_Install(componentNames, componentVersions,
                                                 componentFiles, componentFilesInOrder) != 0){
    return -2; // circular dependencies detected
  }
  dyn_string componentNamesInOrder;
  for (int i=1;i<=dynlen(componentFilesInOrder);i++)
  {
    dyn_dyn_mixed componentInfo;
    if(fwInstallationXml_load(componentFilesInOrder[i], componentInfo))
      continue;
    componentNamesInOrder[i] = componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME][1];
  }
  fwInstallation_reportSetTotalComponentsNumber(dynlen(componentFilesInOrder));
  fwInstallation_reportInstallationStartTime();

  fwInstallation_throw("Backing up project config file", "INFO", 10);

  //backup project config file before starting the installation:
  if(fwInstallation_backupProjectConfigFile() != 0)
  {
    fwInstallation_throw("Project config file could not be backed up. Component installation aborted.");
    return -3;
  }
  if(fwInstallationRedu_isRedundant() && fwInstallation_backupProjectConfigFile(true) != 0)
  {
    fwInstallation_throw("Project redu config file could not be backed up. Component installation aborted.");
    return -3;
  }

  setDbgFlag("EXT_WARNING", true); // make sure all installation messages are printed to the log and not blocked after 50 of them

  // install every component
  fwInstallation_throw("Project config file successfully backed up. Proceding now with installation of components", "INFO", 10);
  try{
    for (int i =1; i <= dynlen(componentFilesInOrder); i++)
    {
      string componentName = componentNamesInOrder[i];
      fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_STARTING_INSTALLATION);

      fwInstallation_throw("Installing component from XML file: " + componentFilesInOrder[i], "INFO", 10);
      fwInstallation_showMessage(makeDynString("Now installing: " + componentName));
      bool isSubcomponent = false;
      fwInstallation_isSubComponent(componentFilesInOrder[i], isSubcomponent);

      string sourceDir = _fwInstallation_baseDir(componentFilesInOrder[i]);
      bool componentInstalled = false;
      int retVal = fwInstallation_installComponent(componentFilesInOrder[i],
                                                   sourceDir,
                                                   isSubcomponent,
                                                   componentName,
                                                   componentInstalled,
                                                   localDontRestartProject);
      err += retVal;
      if(retVal != 0){}//report installation status (success/error)
      if(componentName != "")
        fwInstallation_reportComponentInstallationFinished(componentName);

      if(localDontRestartProject == "no")
      {
        dontRestartProject = "no";
      }
    }
  }catch{
    fwInstallation_throw("Unhandled exception occured during component installation");
    DebugTN(getLastException());
    err += 1;
  }
  setDbgFlag("EXT_WARNING", false); // disable logging repeatable messages (return to manager default behaviour)
  fwInstallation_trackDependency_clear();

  if(err)
    return -1;

  return 0;
///end of components intallation
}

/** fwInstallation_deleteComponentSet removes a set of components in the local project.
 * @param dynComponentsNames (in) Array of string containing the names of the components to be removed.
 * @param deleteFiles (in) Indicates whether component files should be removed from the installation directory.
 * @return 0 if OK, -1 if error
*/
int fwInstallation_deleteComponentSet(dyn_string dynComponentsNames, bool deleteFiles)
{
  dyn_string componentsNamesInOrder;
  bool componentDeleted = false;
  dyn_int status;
  string sMessage;

  // put the components in order depending on dependencies between the components
  fwInstallation_putComponentsInOrder_Delete(dynComponentsNames,  componentsNamesInOrder);

  //backup project config file before starting the installation:
  if(fwInstallation_backupProjectConfigFile() != 0)
  {
    fwInstallation_throw("Project config file could not be backed up. Component deinstallation aborted.");
    return -1;
  }
  if(fwInstallationRedu_isRedundant() && fwInstallation_backupProjectConfigFile(true) != 0)
  {
    fwInstallation_throw("Project redu config file could not be backed up. Component deinstallation aborted.");
    return -1;
  }
  // delete the components - one by one
  for (int i =1; i <= dynlen(componentsNamesInOrder); i++)
  {
    bool deletionAborted = false;
    fwInstallation_deleteComponent(componentsNamesInOrder[i], componentDeleted, deleteFiles, true, deletionAborted);
    if(!componentDeleted && !deletionAborted)
    {
      sMessage = componentsNamesInOrder[i] + " not deleted.";
      fwInstallation_showMessage(makeDynString(fwInstallation_timestampString() + sMessage));
      fwInstallation_throw(sMessage);
    }
  }
  return 0;
}

/** This function stops managers for the period of installation of components.
 * @return 0 if OK, -1 if error
*/
int fwInstallation_stopManagersForInstallation()
{
  //Check if there are managers to be stopped:
  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("dist")))
  {
    if(fwInstallation_stopManagers(makeDynString(fwInstallation_getWCCOAExecutable("dist"))) != 0)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping dist manager", makeDynString("Could not stop dist manager.\nPlease do it manually and then click OK\nto continue."));
      return -1;
    }
  }

  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("ui")))
  {
    if(fwInstallation_stopManagers(makeDynString(fwInstallation_getWCCOAExecutable("ui"), fwInstallation_getWCCOAExecutable("NV"))) != 0)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping UI managers", makeDynString("Could not stop UI and NV managers.\nPlease do it manually and then click OK\nto continue."));
      return -1;
    }
  }

  if(fwInstallationManager_shallStopManagersOfType(fwInstallation_getWCCOAExecutable("ctrl")))
  {
    if(fwInstallation_stopManagers(makeDynString(fwInstallation_getWCCOAExecutable("ctrl"))) != 0)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR Stopping control managers", makeDynString("Could not stop control managers.\nPlease do it manually and then click OK\nto continue."));
      return -1;
    }
  }

  return 0;
}


const string FW_INSTALLATION_CONFIG_REDU_SYS_DELIMITER = "$";
const string FW_INSTALLATION_CONFIG_REDU_CONN_DELIMITER = ",";
const string FW_INSTALLATION_CONFIG_PORT_DELIMITER = ":";
const string FW_INSTALLATION_CONFIG_QUOTE_MARKS = "\"";
const string FW_INSTALLATION_CONFIG_HOST_DOMAIN_DELIMITER = ".";

/** This function parses the config entries that contains host name and port ('data', 'event', part of 'distPeer' within quotes).
  * For redundant systems and in case of redundant connections it returns all host aliases and ports.
  * Example entries and outputs:
  * "host1[:port1]" -> hostAliases[1][1] = "host1"
  * "host1[:port1]$host2[:port2]" // redundant system -> hostAliases[1][1] = "host1"; hostAliases[2][1] = "host2";
  * "host1-1[:port1],host1-2[:port1]" // redundant network connections -> hostAliases[1][1] = "host1-1"; hostAliases[1][2] = "host1-2";
  * "host1-1[:port1],host1-2[:port1]$host2-1[:port2],host2-2[:port2]" // redundant system with redundant network connection
  * -> hostAliases[1][1] = "host1-1"; hostAliases[1][2] = "host1-2"; hostAliases[2][1] = "host2-1"; hostAliases[2][2] = "host2-2"
  * @param configHostEntry (in)  Config file entry as given in the above examples
  * @param hostAliases (out)  Array of parsed hostnames/aliases
  * @param ports (out)  List of corresponding ports, when port is not specified in config entry then it has value 0
  * @param defaultPort (in)  Default port number to be used if not defined in config entry, default = 0
  * @return 0 when success, -1 in case of error (invalid config entry passed)
  */
int fwInstallation_parseHostPortConfigEntry(string configHostEntry,
                                            dyn_dyn_string &hostAliases,
                                            dyn_dyn_int &ports,
                                            int defaultPort = 0)
{
  dyn_string reduPeers = strsplit(configHostEntry, FW_INSTALLATION_CONFIG_REDU_SYS_DELIMITER);
  int reduPeersLen = dynlen(reduPeers);
  if(reduPeersLen <= 0 || reduPeersLen > 2){
    fwInstallation_throw("Invalid number of redu peers (" + reduPeersLen + ") in config entry: " + configHostEntry);
    return -1;
  }
  for(int i=1;i<=reduPeersLen;i++){
    dyn_string reduPeerConns = strsplit(reduPeers[i], FW_INSTALLATION_CONFIG_REDU_CONN_DELIMITER);
    for(int j=1;j<=dynlen(reduPeerConns);j++){
      dyn_string hostPortPair = strsplit(reduPeerConns[j], FW_INSTALLATION_CONFIG_PORT_DELIMITER);
      int hostPortPairLen = dynlen(hostPortPair);
      if(hostPortPairLen <= 0 || hostPortPairLen > 2){
        fwInstallation_throw("Invalid host-port pair: " + reduPeerConns[j] + " in config entry: " + configHostEntry);
        return -1;
      }

      hostAliases[i][j] = hostPortPair[1];
      int port = defaultPort;
      if(hostPortPairLen > 1){
        sscanf(hostPortPair[2], "%d", port);
        if(port <= 0){
          fwInstallation_throw("Invalid port number (" + port + ") for host: " + hostPortPair[1] + " in config entry: " + configHostEntry);
          return -1;
        }
      }
      ports[i][j] = port;
    }
  }
  return 0;
}

/** Parses distPeer config entry and returns the hostname, dist port number and a system number
  * to which distributed connection is initiated.
  * For a non-redundant simple system, hostname and port number are at the position [1][1] in the corresponding arrays.
  * For a redundant simple system (w/o redu connections), the positions are [1][1] for the first peer and [2][1] for the second.
  * See help of fwInstallation_parseHostPortConfigEntry for detailed information and different possible output array sizes.
  * @param distPeer (in)  Value of distPerr config file entry (eg. '"hostname:4777" 15')
  * @param hostAliases (out)  Array of parsed hostnames/aliases of discributed system
  * @param ports (out)  Array of corresponding dist manager ports, when port is not specified in config entry it defaults to 4777
  * @return Distributed system number (> 0) or -1 in case or error
  */
int fwInstallation_config_parseDistPeer(const string &distPeer,
                                        dyn_dyn_string &hosts,
                                        dyn_dyn_int &ports){
  const string distPeerRegexp = "\\s*\"([^\"]+)\"\\s+(\\d+)";
  dyn_string resultsList;
  regexpSplit(distPeerRegexp, distPeer, resultsList);
  if(dynlen(resultsList) != 3){ // regexpSplit returns list containing whole match + matched groups
    fwInstallation_throw("Unrecognized distPeer entry format: " + distPeer +
                         ", cannot retrieve host and system info", "SEVERE");
    return -1;
  }
  int systemNumber = (int)resultsList[3];
  string distString = resultsList[2];
  if(fwInstallation_parseHostPortConfigEntry(distString, hosts, ports, 4777) != 0){
    return -1;
  }
  // force dist hostname to be in uppercase characters and without domain name
  for(int i=1;i<=dynlen(hosts);i++){
    for(int j=1;j<=dynlen(hosts[i]);j++){
      string host = hosts[i][j];
      if(host != ""){
        host = strtoupper(fwInstallation_getHostname(host));
        hosts[i][j] = host;
      }
    }
  }
  return systemNumber;
}

/** This function removes the given project paths from the config file.
 * @param (in) paths array of strings that contains the project paths to be removed from the config file.
 * @return 0
*/
int fwInstallation_deleteProjectPaths(dyn_string paths)
{
  for(int i = 1; i <= dynlen(paths); i++)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Deleting project path from config file: " + paths[i], "info", 10);
    fwInstallation_removeProjPath(paths[i]);
  }

  return 0;
}

/** This function adds the given project paths to the config file.
 * @param (in) dbPaths array of strings that contains the project paths to be added to the config file.
 * @return 0
*/
int fwInstallation_addProjectPaths(dyn_string dbPaths)
{
  for(int i = 1; i <= dynlen(dbPaths); i++)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Adding new project path to config file: " + dbPaths[i], "info", 10);
    fwInstallation_addProjPath(dbPaths[i], 999);
  }
  return 0;
}

/** This function returns the list of all installed WinCC OA versions on current machine.
 * @return list of all installed WinCC OA versions in a dyn_string
*/
dyn_string fwInstallation_getHostPvssVersions()
{
  dyn_string pvssVersions;

  if(_WIN32){
    //Get the installed WinCC OA versions up to 3.13//Get the installed WinCC OA versions up to 3.13
    //32-bit hosts first:
    string key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\ETM\\PVSS II";
    dynAppendConst(pvssVersions, fwInstallation_getPvssVersionsFromWinRegKey(key));
    //and now 64-bit hosts:
    key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\ETM\\PVSS II";
    dynAppendConst(pvssVersions, fwInstallation_getPvssVersionsFromWinRegKey(key));
    //Get the installed WinCC OA versions from 3.14 (FWINS-2050)
    key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\ETM\\WinCC_OA";
    dynAppendConst(pvssVersions, fwInstallation_getPvssVersionsFromWinRegKey(key));
    //Get the installed WinCC OA versions from 3.19 (CERN distribution)
    key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\ETM/CERN\\WinCC_OA";
    dynAppendConst(pvssVersions, fwInstallation_getPvssVersionsFromWinRegKey(key));
    dynUnique(pvssVersions);
  }else{
    string res = "";
    _fwInstallation_getStringFromSystemCommand("rpm -qa | grep -i -e pvss -e wincc_oa", res, true);
    dyn_string values = fwInstallation_splitLines(res);
    for(int i=1;i<=dynlen(values); i++){
      dyn_string ds = strsplit(values[i], "-");
      //version
      dyn_string ds2 = strsplit(ds[1], "_");
      string version = ds2[dynlen(ds2)];
      dyn_string ds3 = strsplit(ds[2], ".");

      //append the service pack if necessary:
      if(ds3[1] != "0") version = version + "-SP" + ds3[1];

      if(values[i] == VERSION)
         values[i] = VERSION_DISP;
      if (!dynContains(pvssVersions,values[i]))
        dynAppend(pvssVersions, version);
    }
  }
  return pvssVersions;

}

/** This function returns the WinCC OA versions that are under given Windows registry key
  * @param key (in)  Windows registry key
  * @return List of WinCC OA versions
*/
private dyn_string fwInstallation_getPvssVersionsFromWinRegKey(string key){
  dyn_string pvssVersions;
  string res = fwInstallation_getWinRegKey(key);
  dyn_string values = fwInstallation_splitLines(res);
  for(int i=1;i<=dynlen(values);i++){
    string value = strltrim(strrtrim(values[i]));
    if(!patternMatch(key + "\\*", value)){
      continue;
    }
    strreplace(value, key + "\\", "");
    if(value != "" && value != "AutoStart" && value != "Configs" && strtoupper(value) != "CMF"){
      if(value == VERSION){
        value = VERSION_DISP;
      }
      dynAppend(pvssVersions, value);
    }
  }
  return pvssVersions;
}

/** This function returns the next tier of subkeys of the specified key in the Windows registry.
 * @note It returns a single string that contains subkeys separated with newline character ("\n").
 * @param key (in) registry key that will be queried
 * @return string contains all subkeys of specified key
*/
string fwInstallation_getWinRegKey(string key)
{
  string output;
  _fwInstallation_getStringFromSystemCommand("cmd /c reg query \"" + key +"\" 2> NUL", output, true);
  return output;
}

/** This function returns the list of pending postInstall scripts of the given component.
 * @param component (in) Name of the component.
 * @param reduHostNum (in) Local host redu number, default value (0) indicates that the number will be obtained automatically.
 * @return Array of strings that contains the names of pending postInstall scripts for the given component.
*/
dyn_string fwInstallation_getComponentPendingPostInstalls(string component, int reduHostNum = 0)
{
  dyn_string components, scripts;
  _fwInstallation_GetComponentsWithPendingPostInstall(components, scripts, reduHostNum);

  dyn_string pendingPostInstalls;
  for(int i=1;i<=dynlen(components);i++){
    if(components[i] == component){
      dynAppend(pendingPostInstalls, scripts[i]);
    }
  }
  return pendingPostInstalls;
}

/** This function returns the list of pending postInstall scripts in the project.
 * @param reduHostNum (in) Local host redu number, default value (0) indicates that the number will be obtained automatically.
 * @return Array of strings that contains the names of pending postInstall scripts.
*/
dyn_string fwInstallation_getProjectPendingPostInstalls(int reduHostNum = 0)
{
  if(reduHostNum == 0) reduHostNum = fwInstallationRedu_myReduHostNum();

  dyn_string scripts;
  char requestedActions;

  string dp = fwInstallation_getInstallationPendingActionsDp(reduHostNum);
  dpGet(dp + ".postInstallFiles:_original.._value", scripts,
        dp + ".postInstallFiles:_original.._userbyte1", requestedActions);

  // For compatibility with < 9.1.0 add special scripts to the list returned by this function
  if(requestedActions & (1<<FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP)){
      dynInsertAt(scripts, "<qthelp>|" + getPath(SCRIPTS_REL_PATH, "fwInstallation/" + FW_INSTALLATION_QT_HELP_GENERATION_SCRIPT), 1);
  }
  if(requestedActions & (1<<FW_INSTALLATION_POSTINSTALL_ACTION_BIT_LEGACY_LIB)){
      dynInsertAt(scripts, "<legacy_includes>|" + getPath(SCRIPTS_REL_PATH, FW_INSTALLATION_BUILD_LEGACY_LIB_SCRIPT), 1);
  }
  return scripts;
}

/** This function clears the global array of stings that contains fwInstallation log messages.
*/
void fwInstallation_resetLog()
{
  gFwInstallationLog = makeDynString();
}

/** This function returns the name of WinCC OA manager executable file.
 * @param type (in) Type of manager (UI, CTRL, dist, etc., case insensitive)
 * @return Name of WinCC OA executable file (WCCOA or WCCIL + type)
*/
string fwInstallation_getWCCOAExecutable(string type)
{
  type = strtolower(type);
  int componentId = -1;
  switch(type){ // translate type to integer constant digestible by WinCC OA function getComponentName()
    // Resolve componentId for WCCIL managers:
    case "data":   componentId = DATA_COMPONENT; break;
    case "databg": componentId = DATABG_COMPONENT; break;
    case "dist":   componentId = DIST_COMPONENT; break;
    case "event":  componentId = EVENT_COMPONENT; break;
    case "pmon":   componentId = PMON_COMPONENT; break;
    case "proxy":  componentId = MXPROXY_COMPONENT; break;
    case "redu":   componentId = REDU_COMPONENT; break;
    case "sim":    componentId = SIM_COMPONENT; break;
    case "split":  componentId = SPLIT_COMPONENT; break;
    // Resolve componentId for WCCOA managers that depends on project type: RAIMA/SQLite
    case "ascii":  componentId = ASCII_COMPONENT; break;
  }
  if(componentId >= 0){
    return getComponentName(componentId);
  }else{ // WCCIL managers are resolved using componentId and WinCC OA function, hence here handling only WCCOA managers
    return ("WCCOA" + type);
  }
}

/** This function append a new log message to the fwInstallation log.
 * Logs are appended to the global array of logs and, if there is a connection, stored in the DB
 * @param msg (in) Log message
 * @param severity (in) Severity of the message
*/
void fwInstallation_appendLog(string msg, string severity)
{
  if(myManType() == CTRL_MAN)
    msg = fwInstallation_getWCCOAExecutable("ctrl") + "(" + myManNum() + "): " + msg;
  else
    msg = fwInstallation_getWCCOAExecutable("ui") + "(" + myManNum() + "): " + msg;

  dyn_string log_line = makeDynString((string) getCurrentTime(), severity, msg);
  dynAppend(gFwInstallationLog, log_line);

  if(fwInstallationDB_isConnected())
    fwInstallationDB_storeInstallationLog();
}

/** This function deploys the crashAction script for the restart of the DB-Agent
 *  of the Installation Tool when it gets blocked
 *
 * @return  0 if OK, -1 if error
*/
/*
int fwInstallation_deployCrashActionScript()
{
  string fw_installation_filename = PROJ_PATH +  BIN_REL_PATH;
  string filename = PROJ_PATH +  BIN_REL_PATH;

  //initialize
  if(_WIN32)
  {
    filename += "crashAction.cmd";
    fw_installation_filename += "fwInstallation_crashAction.cmd";
  }
  else
  {
    filename += "crashAction.sh";
    fw_installation_filename += "fwInstallation_crashAction.sh";
  }

  if(access(filename, R_OK)) //the file does not exist or it is not readable. Just copy the new one
  {
    fwInstallation_throw("Copying the Crash Action Script for the DB-agent of the Component Installation Tool", "INFO", 10);
    if(fwInstallation_copyFile(fw_installation_filename, filename))
    {
      fwInstallation_throw("Failed to copy the Crash Action Script for the DB-agent of the Component Installation Tool");
      return -1;
    }
    system("chmod +x " + filename);
    system("dos2unix " + filename);
    system("dos2unix " + fw_installation_filename);
  }
  //if the file already exists, check if the necessary info for the installation tool is up-to-date
  return fwInstallation_updateCrashActionScript(filename, fw_installation_filename);
}
*/

/** This function checks and, if necessary, updates the crash action script of the Installation Tool
 *
 * @param filename name of the crash action script as expected by PMON, including the full path
 * @param fw_installation_filename name of the crash action script delievered with this version of the Installation Tool, including the full name
 * @return  0 if OK, -1 if error
*/

/*
int fwInstallation_updateCrashActionScript(string filename, string fw_installation_filename)
{
  string scriptContents;
  string fwInstallationScriptContents;
  dyn_string ds, dsInstallation;
  string beginTag = "::#Beginning FW_INSTALLATION#";
  string endTag = "::#End FW_INSTALLATION#";
  string versionTag = "::# Version:";
  string version = "";
  string versionInstallation = "";
  bool write = false;

  if(!_WIN32)
  {
    beginTag = substr(beginTag, 2, strlen(beginTag));
    endTag = substr(endTag, 2, strlen(endTag));
    versionTag = substr(versionTag, 2, strlen(versionTag));
  }

  fileToString(filename, scriptContents);
  fileToString(fw_installation_filename, fwInstallationScriptContents);

  ds = strsplit(scriptContents, "\n");
  dsInstallation = strsplit(fwInstallationScriptContents, "\n");

  int beginPos = dynContains(ds, beginTag);
  int endPos = -1;
  if(beginPos > 0)
  {
    version = fwInstallation_getCrashActionScriptVersion(filename);
    versionInstallation = fwInstallation_getCrashActionScriptVersion(fw_installation_filename);
    if(version != versionInstallation)
    {
      fwInstallation_throw("Crash Action script for the Installation Tool needs to be udpate from version "
                           + version + " to version " + versionInstallation, "INFO", 10);
      //find end tag:
      endPos = dynContains(ds, endTag);
      if(endPos > beginPos)
      {
        write = true;
        for(int z = endPos; z >= beginPos; z--)
        {
          dynRemove(ds, z);
        }
        dynAppend(ds, dsInstallation);
      }
    }
  }

  if(write)
    if(fwInstallation_saveFile(ds, filename))
    {
      fwInstallation_throw("Failed to save the crashAction script");
      return -1;
    }

  if(!_WIN32)
  {
    system("chmod +x " + filename);    //make sure the file is executable
    system("dos2unix " + filename);
    system("dos2unix " + fw_installation_filename);
  }

  return 0;
}
*/

/** This function returns the version of a crash action script
 *
 * @param filename name of the file containing the crash action script
 * @return  version of the script as a string
*/
/*
string fwInstallation_getCrashActionScriptVersion(string filename)
{
  string scriptContents;
  dyn_string ds;
  string beginTag = "::#Beginning FW_INSTALLATION#";
  string versionTag = "::# Version:";

  if(!_WIN32)
  {
    beginTag = substr(beginTag, 2, strlen(beginTag));
//    endTag = substr(endTag, 2, strlen(endTag));
    versionTag = substr(versionTag, 2, strlen(versionTag));
  }

  fileToString(filename, scriptContents);

  ds = strsplit(scriptContents, "\n");
  int beginPos = dynContains(ds, beginTag);
  if(beginPos > 0)
  {
    for(int i = beginPos; i <= dynlen(ds); i++)
    {
      if(patternMatch(versionTag + "*", ds[i]))
      {
        //Check the version
        string version = ds[i];
        strreplace(version, versionTag, "");
        strreplace(version, " ", "");
        strreplace(version, "\n", "");
        return version;
      }
    }//end of loop
  }

  return "";
}
*/

/** Checks if a particular patch has been applied to the current installation
 *
 * @param patch patch name
 * @return  0 if the patch is not present
            1 if the patch has been applied
*/
bool fwInstallation_isPatchInstalled(string patch)
{
  dyn_string patches;
  fwInstallation_getPvssVersion(patches);

  return dynContains(patches, patch);
}

/** Check if the PVSS version is equal or newer than the required PVSS version passed as argument
 *
 * @param reqVersion required PVSS version
 * @return  2 if current PVSS version is greater than the required one.
            1 if current and required PVSS versions are equal.
            0 if the required version is greater than the current one.

*/
int fwInstallation_checkPvssVersion(string reqVersion)
{
  int reqMajor, reqMinor, reqSP;
  int currMajor, currMinor, currSP;

  float fReqVersion = fwInstallation_pvssVersionAsFloat(reqVersion, reqMajor, reqMinor, reqSP);
  float fCurrVersion = fwInstallation_pvssVersionAsFloat(VERSION_DISP, currMajor, currMinor, currSP);

  if(fReqVersion > fCurrVersion)
    return 0;
  else if(fReqVersion == fCurrVersion)
    return 1;

  return 2;
}
/** Checks if the version of the FW Component Installation Tool is equal or newer than the required PVSS version passed as argument
 *
 * @param reqVersion required version of the FW Component Installation Tool
 * @return  2 if current Tool version is greater than the required one.
            1 if current and required Tool versions are equal.
            0 if the required version is greater than the current one.

*/
int fwInstallation_checkToolVersion(string reqVersion)
{
  string currVersion;
  fwInstallation_getToolVersionLocal(currVersion);
  if(_fwInstallation_CompareVersions(currVersion, reqVersion, false, false, true) == 0){
    return 0;
  }
  if(_fwInstallation_CompareVersions(currVersion, reqVersion, true) == 1){
    return 1;
  }
  return 2;
}

/** Converts a PVSS version from string to float for easy comparison
 *
 * @param  reqVersion - (in) name of the pvss version
 * @param  major - (out) number corresponding to the major version of the release
 * @param  minor - (out) number corresponding to the minor version of the release
 * @param  sp - (out) number corresponding to the Service Pack of the release
 * @return  pvss version as a float
*/
float fwInstallation_pvssVersionAsFloat(string reqVersion, int &major, int &minor, int &sp)
{
  dyn_string ds = strsplit(reqVersion, "-");
  dyn_string ds2 = strsplit(ds[1], ".");

  major = 0;
  minor = 0;
  sp = 0;

  major = (int)ds2[1];
  if(dynlen(ds2) >= 2)
    minor = (int)ds2[2];

  if(dynlen(ds) >= 2)
  {
    string str = substr(ds[2], 2, (strlen(ds[2])-2));
    sp = (int)str;
  }

  return major * 1000. + minor + sp/100.;
}

/** Gets the properties of a particular PVSS system as a dyn_mixed
 *
 * @param  systemName - (in) name of the pvss system
 * @param  pvssSystem - (out) properties of the system
 * @return  0 if everything OK, -1 if errors
*/
int fwInstallation_getPvssSystemProperties(string systemName, dyn_mixed &pvssSystem)
{

  pvssSystem[FW_INSTALLATION_DB_SYSTEM_NAME] = systemName;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] = getSystemId();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] = dataPort();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] = eventPort();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_PARENT_SYS_ID] = -1;
  dyn_string evHosts = eventHost();

  pvssSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = strtoupper(evHosts[1]);

  int distPort = fwInstallation_getDistPort();
  int reduPort = fwInstallation_getReduPort();
  int splitPort = fwInstallation_getSplitPort();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] = distPort;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] = reduPort;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] = splitPort;

  return 0;
}

/** Throws a PVSS error in the log
 * @param  msg - error message
 * @param  severity - severity of the message: "ERROR", "WARNING", "INFO"
 * @param  code - code of the error message in the fwInstallation catalog
*/
void fwInstallation_throw(string msg, string severity = "ERROR", int code = 1)
{
  int prio = PRIO_WARNING;
  int type = ERR_CONTROL;

  switch(strtoupper(severity))
  {
    case "INFO": prio = PRIO_INFO;
      if(code ==1)
        code =10;

      break;
    case "WARNING": prio = PRIO_WARNING; break;
    case "ERROR": prio = PRIO_SEVERE; break;
  }

  errClass err = makeError("fwInstallation", prio, type, code, msg);
  throwError(err);

  if(dynlen(dynPatternMatch("void fwInstallation_throw(*", getStackTrace())) > 1)
  {//detect recursive call of fwInstallation_throw() (FWINS-1888)
    throwError(makeError("fwInstallation", PRIO_WARNING, ERR_CONTROL, 1, "Detected recursive call " +
                         "of fwInstallation_throw() function. There is a problem with DB connection. " +
                         "Cannot write log message: " + msg + " to the DB"));
    return;
  }

  fwInstallation_reportInstallationMessage(err);
  if(fwInstallationDB_getUseDB() && fwInstallationDB_isConnected())
  {
    fwInstallation_appendLog(msg, strtoupper(severity));
  }

  return;
}

/** Return data point for value indicating
 * if restart is needed before running
 * post install scripts.
 *
 * @return value of type 'string' data point (element) if
 * restart is needed.
 */
string fwInstallation_getAfterInitRestartNeededDpElem()
{
  return "postInitRestartNeeded";
}

/** Return data point for value containing
 * component that requested project restart.
 * Data point contains only the last component
 * requesting the restart.
 *
 * @return value of type 'string' Data point pointing to
 * project restart requester (component name).
 */
string fwInstallation_getAfterInitRestartRequesterDpElem()
{
  return "postInitRestartRequester";
}

/** Request project restart after component installation, but
 * before running postInstall scripts.
 *
 * This function will set requester to a datapoint which later
 * be used to issue a project request.
 *
 * @param requester	(string)	IN 	component requesting project restart.
 * @return value of type 'int' 0 if request is successful, otherwise -1.
 */
int fwInstallation_requestProjectRestartAfterInit(string requester)
{
  int retVal = -1;

  // TODO: get real datapoints here
  string requesterDp = fwInstallation_getAgentDp() + "." + fwInstallation_getAfterInitRestartRequesterDpElem();
  string restartDp = fwInstallation_getAgentDp() + "." + fwInstallation_getAfterInitRestartNeededDpElem();

   // Remember requester
  if(dpSetWait(requesterDp, requester) == 0)
  {
    // Issue an restart after init scripts
    if(dpSetWait(restartDp, 1) == 0)
    {
      retVal = 0;
    }
  }

  return retVal;
}

/** Clear data point that will cause project restart
 * after init scripts (before post install scripts).
 *
 * @return value of type 'int' 0 - success clearing project
 * restart request, -1 - failure to clear restart request.
 */
int fwInstallation_clearProjectRestartAfterInit()
{
  int retVal = -1;

  string restartDp = fwInstallation_getAgentDp() + "." + fwInstallation_getAfterInitRestartNeededDpElem();

  if(dpSetWait(restartDp, 0) == 0)
  {
    retVal = 0;
  }

  return retVal;
}

/** Return if project should be restarted after init
 * scripts were executed.
 *
 * @return value of type 'int' 1 - project should be
 * restarted after init scripts, 0 - project should NOT
 * be restarted after init scripts.
 */
int fwInstallation_isProjectRestartAfterInitPending()
{
  string restartDp = fwInstallation_getAgentDp() + "." + fwInstallation_getAfterInitRestartNeededDpElem();

  int restartPending;
  dpGet(restartDp, restartPending);

  return restartPending;
}

/** Order the dpl files of a component according to the attributes defined in the XML file
 * @param  files - (in) files to the ordered as a dyn_string
 * @param  attribs - (int) XML attributes for the files ordered as the 'files' argument
 * @return  ordered list of the files according to the attribs values
*/
dyn_string fwInstallation_orderDplFiles(dyn_string files, dyn_int attribs)
{
  dyn_string orderedFiles;
  dyn_string ds;

  //find those files having an attributed specified and build ds array with only them:
  for(int i = 1; i <= dynlen(files); i++)
    if(attribs[i] > 0)
      ds[attribs[i]] = files[i];

  //now append files with no attribute defined:
  for(int i = 1; i <= dynlen(files); i++)
    if(dynContains(ds, files[i]) <= 0)
      dynAppend(ds, files[i]);

  //Now remove empty/non-initialized elements that there could be in ds array
  for(int i = 1; i <= dynlen(ds); i++)
    if(ds[i] != "")
      dynAppend(orderedFiles, ds[i]);

  return orderedFiles;
}

/** This functions is to be called from the close event of a panel.
    It checks whether the connection with the event manager is established or not.
    If the connection is down, the function will call exit() to close the actual panel.
    If the connection is to the event manager is still up, the calling code can decide
    whether the panel must closed or not. This is done through the argument closeIfConnected.
    Typically the argument will be set to false in the cases where the developer wants to prevent
    that the user closes the panel by clicking on the top-right 'x' of the window.

  @param closeIfConnected: (boolean) Defines whether the current panel has to be close if the
                         connection to the event manager is still up. The default value is false
                         (i.e. the function will not close the panel)
  @return 0 - success,  -1 - error
  @author F. Varela
*/
int fwInstallation_closePanel(bool closeIfConnected = false)
{
  dyn_anytype da, daa;
  da[1]  = myModuleName();
  da[2]  = myPanelName();
  daa[1] = 0.0; daa[2] = "FALSE"; // Return value optional
  da[3] = daa;                    // dyn_anytype binding

  if(!isEvConnOpen())
    return panelOff(da);
  else if(closeIfConnected)
    PanelOff();

  return 0;
}


/** Retrieves the name of a host without network domain
   @param hostName name of the host to parse; when empty - the local host
 * @return  name of the  host as string
*/
string fwInstallation_getHostname(string hostName = "")
{
  string host = hostName == "" ? getHostname() : hostName ;
  dyn_string ds = strsplit(host, FW_INSTALLATION_CONFIG_HOST_DOMAIN_DELIMITER);

  return ds[1];
}

/** Gets the name of the internal datapoint of the Installation Tool
 * @return  dp name as string
*/
string fwInstallation_getInstallationDp()
{
  string dp;

//  if(fwInstallationRedu_myReduHostNum() > 1)
//    dp = "fwInstallationInfo_" + fwInstallationRedu_myReduHostNum();
//  else
    dp = "fwInstallationInfo";

  return dp;
}

/** Get file issues sychronization enable/disable data point element.
  @return name of data point element for file issues synchronization enabled/disabled.
*/
string fwInstallation_getFileIssuesSyncDpElem()
{
  string dp;

  dp = "fileIssuesSyncDisabled";

  return dp;
}

/** Returns wether the DB-agent must delete or not from the project config file during synchronization with the System Configuration DB
 * @return  True is deletions must be carried out, FALSE if deletion is inhibited.
*/
bool fwInstallation_deleteFromConfigFile()
{
  bool edit = false;
  string dp = fwInstallation_getInstallationDp();

  dpGet(dp + ".deleteFromConfigFile", edit);

  return edit;
}

/** Function used to flag deprecated functions in the library
 * @param deprecated name of the deprecated function
 * @param toBeUsed name of the function to be used instaed. If an empty argument is passed, a
 *                 different message will be shown, telling that the user must report its usage.
*/
void fwInstallation_flagDeprecated(string deprecated, string toBeUsed = "")
{
  string str = gFwInstallationCurrentComponent + " Function :" + deprecated +" is deprecated and may eventually disappear.";

  if(toBeUsed != "")
    str += " Please use " + toBeUsed + " instead.";
  else
    str += " Should you be using it, please, reported to IceControls.Support@cern.ch";

  fwInstallation_throw(str, "WARNING", 11);

  return;

}

/** Function during the installation of the components to resolve the right name for a file depending on the current PVSS version
 * @param baseFileName (in) base name of the file
 * @param targetVersions (in) name of the target PVSS version
 * @param considerSpLevel (in) argument that defines whether the Service Pack level has to be also taken into account
 * @return final name of the file matching the target pvss version
*/
string fwInstallation_findFileForPvssVersion(string baseFileName, dyn_string targetVersions = makeDynString(), bool considerSpLevel = FALSE)
{
  bool matchingVersion = FALSE;
  string localFileName = "", currentVersion;

  //get current VERSION of VERSION_DISP (DISP includes Service Pack level)
  currentVersion = considerSpLevel?VERSION_DISP:VERSION;

  //if target versions specified, check if current version matches the pattern of any target version
  //if not, then assume that current version is a valid target version
  if(dynlen(targetVersions) == 0)
    matchingVersion = TRUE;
  else
  {
    //search for pattern in target versions that matches current PVSS version
    for(int i=1; i<=dynlen(targetVersions) && !matchingVersion; i++)
      matchingVersion = patternMatch(targetVersions[i], currentVersion);
  }

  //if current PVSS version is a valid target version then try to search for the specified file
  if(matchingVersion)
  {
    //substitute the keyword with the current PVSS version, if no keyword, simply append version to file name
    if(strpos(baseFileName, fwInstallation_VERSION_KEYWORD) >= 0)
      strreplace(baseFileName, fwInstallation_VERSION_KEYWORD, currentVersion);
    else
      baseFileName += currentVersion;

    //search for file in all PVSS paths, return highest level file found
    localFileName = getPath("", baseFileName);
  }

  return localFileName;
}

/** Execute command and read the output.
  @note Function reports success always when command exits with code different than -1, so it may report success even when command returned error code.
        This is to not modify previous behaviour of this function.
        Note that it is not possible to distinguish if -1 is error code returned by command or error code of WinCC OA system() function.
  @note2 Newline character in output is different on Windows (CR+LF) and Linux (LF). It is recommended to use fwInstallation_splitLines() to get list of lines in output correctly.
  @param command (in)  System command to execute
  @param systemExecResult (out)  Contains output from command execution.
  @param trim (in)  Flag that indicates if the leading and trailing whitespaces should be removed from output (by default no).
  @return Returns 0 on success, -1 on error (system() function error or command returned -1 (only on Windows)).
*/
int _fwInstallation_getStringFromSystemCommand(string command, string &systemExecResult, bool trim = false)
{
  string cmdOutput;
  int retCode = system(command, cmdOutput);
  if(retCode == -1){
    return -1;
  }
  systemExecResult = cmdOutput;
  if(trim){
    systemExecResult = strltrim(strrtrim(systemExecResult));
  }
  return 0;
}

/** Return memory size in bytes.
  @param memSizeInBytes - return value, memory size in bytes.
  @return 0 on success, -1 on failure.
*/
int fwInstallation_getHostMemorySize(string &memSizeInBytes)
{
  const string win32HostMemorySizeCmd = "cmd.exe /c @for /f \"skip=2 tokens=2 delims==\" %p in ('wmic ComputerSystem get TotalPhysicalMemory /format:list') do @echo %p";
  const string linuxHostMemorySizeCmd = "free -b | grep Mem: | tr -s ' ' | cut -f2 -d ' '";

  string command = _WIN32?win32HostMemorySizeCmd:linuxHostMemorySizeCmd;
  if(_fwInstallation_getStringFromSystemCommand(command, memSizeInBytes, true) != 0)
  {
    fwInstallation_throw("Couldn't get host memory information", "ERROR", 10);
    return -1;
  }
  return 0;
}

/** Return CPU information.
  @param cpuInfo - return CPU information, ex. "".
  @return 0 on success, -1 on failure.
*/
int fwInstallation_getHostCpuInfo(string &cpuInfo)
{
  const string win32HostCpuInfoCmd = "cmd.exe /c @for /f \"skip=2 tokens=2 delims==\" %p in ('wmic cpu get name /format:list') do @echo %p"; // A bit hacky but should work for Windows Vista and up
  const string linuxHostCpuInfoCmd = "grep -m 1 \"model name\" /proc/cpuinfo | cut -f2 -d\":\"";

  string command = _WIN32?win32HostCpuInfoCmd:linuxHostCpuInfoCmd;
  if(_fwInstallation_getStringFromSystemCommand(command, cpuInfo, true) != 0)
  {
    fwInstallation_throw("Couldn't get CPU information", "ERROR", 10);
    return -1;
  }
  return 0;
}

/** Returns packages installed on an RPM based Linux system.
  Note that an argument (grepExpression) is passed to filter out
  interesting packages out of all installed packages, filter is
  case insensitive.
  @param grepExpression grep expression to filter out packages.
  @param packages output string receiving comma separated list of packages.
  @return 0 on success, -1 on error.
*/
int fwInstallation_getLinuxInstalledPackages(string grepExpression, string &packages)
{
  string command = "rpm -qa | grep -i " + grepExpression + " | sort -r";
  if(_fwInstallation_getStringFromSystemCommand(command, packages) == 0)
  {
    if(packages == "")
    {
      // TODO: remove in future
      //fwInstallation_throw("There seem not to be any requested packages installed (" + grepExpression +
      //                     ", is this Linux distribution supported /not rpm based?/)?", "WARNING", 10);
      packages = "(none)";
    }
    else
    {
      packages = strltrim(strrtrim(packages, "\n"), "\n");
      strreplace(packages, "\n", ",");
    }
  }
  else
  {
    fwInstallation_throw("Couldn't get packages list (command: " + command + ").");
    return -1;
  }

  return 0;
}

/** Get list of installed FMC.
  @param packages variable to receive comma separated list of FMC packages.
  @return 0 on success, -1 on error.
*/
int fwInstallation_getFMCInstalledPackages(string &packages)
{
  bool error = true;

  if(_WIN32)
  {
    packages = "?"; // Windows not yet supported
    error = false; // Do not report problems if not supported (creates spam in log)
  }
  else if(fwInstallation_getLinuxInstalledPackages("fmc", packages) == 0)
  {
    error = false;
  }

  if(error)
  {
    fwInstallation_throw("Couldn't get installed FMC packages", "ERROR", 10);
    return -1;
  }

  return 0;
}

/** Get list of installed WinCC OA packages (also inclused PVSS packages).
  @param packages variable to recieve comma separated list of WinCC OA/PVSS packages.
  @return 0 on success, -1 on error.
*/
int fwInstallation_getWCCOAInstalledPackages(string &packages)
{
  bool error = true;

  if(_WIN32)
  {
    packages = "?"; // Windows not yet supported
    error = false; // Do not report problems if not supported (creates spam in log)
  }
  else if(fwInstallation_getLinuxInstalledPackages("-e pvss -e wincc_oa", packages) == 0)
  {
    error = false;
  }

  if(error)
  {
    fwInstallation_throw("Couldn't get installed WinCCOA packages", "ERROR", 10);
    return -1;
  }

  return 0;
}


/** Function to retrieve host properties as a dyn_mixed array
 * @param hostname (int) name of the host
 * @param pvssHostInfo (out) host properties
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_getHostProperties(string hostname, dyn_mixed &pvssHostInfo)
{
  dyn_string pvssIps;

  hostname = strtoupper(hostname);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = hostname;
  pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] = getHostByName(hostname, pvssIps);

  //assign pvssIps to ...
  if(dynlen(pvssIps) && pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] == "")
    pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] = pvssIps[1];

  if(dynlen(pvssIps) > 1)
    pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_2_IDX] = pvssIps[2];

  // WinCC OA/PVSS packages
  string packages = "?";
  fwInstallation_getWCCOAInstalledPackages(packages);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_WCCOA_INSTALL_PKG_IDX] = packages;
  packages = "?";
  fwInstallation_getFMCInstalledPackages(packages);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_FMC_INSTALL_PKG_IDX] = packages;

  // CPU & memory information
  string hwInfo = "?";
  fwInstallation_getHostCpuInfo(hwInfo);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_CPU_INFO_IDX] = hwInfo;
  hwInfo = "0";
  fwInstallation_getHostMemorySize(hwInfo);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_MEM_SIZE_IDX] = hwInfo;

  return 0;
}

/** Function to move files into the trash
 * @param filename (in) name of the file to be moved
 * @param trashPath (in) path to the trash. Empty path means use the default path
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_sendToTrash(string filename, string trashPath = "")
{
  if(filename == "")
  {
    fwInstallation_throw("fwInstallation_sendToTrash()-> Empty file name, cannot send file to trash.", "ERROR", 1);
    return -1;
  }
  string trashedName = _fwInstallation_fileName(filename) + formatTime(".%Y_%m_%d_%H_%M", getCurrentTime());

  if(trashPath == "")
    trashPath = gFwTrashPath;
  else
    trashPath += "/fwTrash/";

  if(access(trashPath, W_OK) && !mkdir(trashPath))
  {
    fwInstallation_throw("fwInstallation_sendToTrash()-> Could not create trash folder. File cannot be sent to trash.", "ERROR", 1);
    return -1;
  }

  return fwInstallation_moveFile(filename, trashPath + trashedName, true);
}

/** Empty the trash of the FW Component Installation Tool
 * @param path (in) path to the trash. Empty path means use the default path
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_emptyTrash(string path = "")
{
  int err = 0;
  if(path == "")
    path = gFwTrashPath;
  else
    path += "/fwTrash/";

  dyn_string files = getFileNames(path);

  for(int i = 1; i <= dynlen(files); i++)
  {
    if(remove(path + files[i]))
      ++err;
  }
  if(err)
    return -1;

  return 0;
}

/** Moves file/directory to the target directory.
  * This is a wrapper of WinCC OA moveFile() function that allows also to overwrite existing file while moving.
  * @param source (in)  Path to file or a directory to be moved
  * @param target (in)  Target directory or target path
  * @param overwriteFile (in)  Indicates whether moved file can overwrite the one that exists in target path, by default false
  * @return 0 when file moved successfully, -1 when failed
  */
int fwInstallation_moveFile(string source, string target, bool overwriteFile = false){
  if(isfile(source) && isfile(target) && overwriteFile){
    if(remove(target) != 0){
      fwInstallation_throw("fwInstallation_moveFile: Moving failed as removal of an existing file: " + target + " failed. " + source + " file cannot overwrite it.");
      return -1;
    }
  }
  return moveFile(source, target)?0:-1;
}

////
/** Function to make a binary comparison of two files. Contribution from TOTEM.
 * @param filename1 (in) name of the first file for comparison
 * @param filename2 (in) name of the second file for comparison
 * @return true if the two files are identical, false if the files are different
 *
*/
bool fwInstallation_fileCompareBinary(string filename1, string filename2)
{
   if (!isfile(filename1)||!isfile(filename2))
   {
       return false;
   }

   if (getFileSize(filename1)!=getFileSize(filename2))
   {
     return false;
   }

   file f1, f2;
   int size=1024;
   int c1, c2;
   blob b1, b2;

   //opens a file for reading in the binary mode rb
   f1 = fopen(filename1, "rb");
   f2 = fopen(filename2, "rb");

     bool result = true;
   while (true)
   {
     if (feof(f1)!=0) {break;}
     if (feof(f2)!=0) {break;}

     c1 = blobRead(b1, size, f1);
     c2 = blobRead(b2, size, f2);

     if (c1!=c2) {result=false;}
     if (b1!=b2) {result=false;}
   }

   fclose(f1);
   fclose(f2);

   return result;
}

/** This function unlinks a file under Linux and then overwrites it.
 * @param source (in) name of the file to be copied
 * @param destination (in) target file name including full path
 * @param trashPath (in) path to trash
 * @param compare (in) argument used to compare files before copying. If files are identical the file is not re-copied.
 * @return 0 if OK, -1 if errors
 *
*/
int fwInstallation_safeFileOverwrite(string source, string destination, string trashPath = "", bool compare = true)
{
  if(!_WIN32){
    system("/bin/unlink " + destination);
  }
  return fwInstallation_copyFile(source, destination, trashPath, compare);
}

/** Function to copy files. If blind copy fails (e.g. an executable is in used) and file exists already in target path,
 * then it tries to perform additional actions in order to successfully copy file.
 * @param source (in) name of the file to be copied
 * @param destination (in) target file name including full path
 * @param trashPath (in) path to trash (when not specify, then default one is used (PROJ_PATH/fwTrash/))
 * @param compare (in) argument used to compare files before copying. If files are identical the file is not re-copied.
 * @return 0 if OK, -1 if errors
 *
*/
int fwInstallation_copyFile(string source, string destination, string trashPath = "", bool compare = true)
{
  if(compare && fwInstallation_fileCompareBinary(source, destination)){
    return 0; // if compare flag is set and files are binary identical, do not copy them
  }
  //if linux and trying to overwrite an .so, unlink the file prior to the copy so that all running processes are happy.
  if(_UNIX && patternMatch("*.so", source) && access(destination, F_OK) == 0){
    system("/bin/unlink " + destination);
  }

  if(!copyFile(source, destination)){ // First attempt to copy file
    if(access(destination, F_OK) == 0){ // If it failed, check if file exists in target path
      return fwInstallation_copyFile_handleFileOverwriting(source, destination, trashPath);
    }
    fwInstallation_throw("fwInstallation_copyFile() -> Could not copy file from: " + source + " to: " + destination, "error", 5);
    return -1;
  }
  return 0;
}

/** Function to be called from fwInstallation_copyFile(). Provides functionality to handle cases, when overwriting
  * file in target directory failed at first attempt. It either tries to overwrite file using native system copy function
  * or move the file from target path to project trash directory.
  * @param source (in)  Path to file to be copied
  * @param destination (in)  Target path for file
  * @param trashPath (in) path to trash
  * @return 0 if OK, -1 if errors
  */
private int fwInstallation_copyFile_handleFileOverwriting(string source, string destination, string trashPath = "")
{
  if(_WIN32 && (patternMatch("*.qch", source) ||
                patternMatch("*.qhc", source))){ // Workaround to overwrite *.qch or *.qhc file on Windows, when it is already in use (FWINS-2201)
    fwInstallation_throw("INFO: fwInstallation_copyFile_overwrite() -> " + _fwInstallation_fileName(destination) + " is in use. Trying to overwrite it.", "INFO", 10);

    if(fwInstallation_copyFile_windowsCmd(source, destination) != 0){
      fwInstallation_throw("fwInstallation_copyFile() -> Could not overwite file that is in use: " + destination, "error", 5);
      return -1;
    }
  }else{ // Any other case - try to move the old file, so that the new file will not overwrite it in target
    fwInstallation_throw("INFO: fwInstallation_copyFile_overwrite() -> Moving old file in target to project trash before trying to copy new one....", "INFO", 10);

    if(fwInstallation_sendToTrash(destination, trashPath)){ // Move file to trash folder
      fwInstallation_throw("fwInstallation_copyFile_overwrite() -> Could not move previous version of the file in target directory: " + destination, "error", 4);
      return -1;
    }
    if(!copyFile(source, destination)){
      fwInstallation_throw("fwInstallation_copyFile_overwrite() -> Could not copy file from: " + source + " to: " + destination, "error", 5);
      return -1;
    }
  }
  return 0;
}

/** This function copies the file from the source to target path using Windows 'copy' command.
  * To be used only in Windows and to copy files (not directories).
  * @note It was developed specifically to workaround problem with overwriting files,
  *       that are in use by another process, when using WinCC OA copyFile(). Consider removing it when ETM-1807 will be fixed.
  * @param source (in)  Path to file to be copied
  * @param target (in)  Target path for file
  * @return 0 when success, other value in case of error (!=0)
  */
private int fwInstallation_copyFile_windowsCmd(string source, string target)
{
  source = fwInstallation_getPathWithinQuotationMarks(makeNativePath(source));
  target = fwInstallation_getPathWithinQuotationMarks(makeNativePath(target));
  return system("copy /Y " + source + " " + target);
}

/** This function registers a PVSS project path
  @note Registered project paths can be found in pvssInst.conf file (usually C:\ProgramData\Siemens\WinCC_OA\pvssInst.conf or /etc/opt/pvss/pvssInst.conf)
  @param sPath: (in) path to be registered as string
  @return 0 if success,  -1 if error
  @author F. Varela
*/
int fwInstallation_registerProjectPath(string sPath)
{
  fwInstallation_normalizePath(sPath);
  string projName = _fwInstallation_fileName(sPath);
  if(strrtrim(sPath, " /.") == "" || projName == "")
  {
    if(myManType() == UI_MAN )
      ChildPanelOnCentralModal("vision/MessageInfo1", "ERROR", "$1:Project registration error.\nEmpty path or project name");
    else
      fwInstallation_throw("Project registration error.\nEmpty path or project name");
    return -1;
  }
  //Check if path exists:
  if(!isdir(sPath) && !mkdir(sPath)) //if directory does not exist, create it now
  {
    fwInstallation_throw("Path registration failed. Given path does not exists and creation of directory failed.");
    return -1;
  }
  int iPmonPort;
  string remoteHost;
  int iErr = paRegProj(projName, _fwInstallation_baseDir(sPath), remoteHost, iPmonPort, true, false);
/*
  if ( iErr )
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("vision/MessageInfo1", "ERROR", "$1:Path registration failed.");
    else
      fwInstallation_throw("Path registration failed.");

    return -1;
  }
*/
  return 0;
}

/** This function retrieves the version of an installed component
  @param component (in) name of the component
  @return component version as string
*/
string fwInstallation_getComponentVersion(string component, int reduHostNum = 0)
{
  string version;
  if(reduHostNum == 0) reduHostNum = fwInstallationRedu_myReduHostNum();
  fwInstallation_isComponentInstalled(component, version, reduHostNum);

  return version;
}

/** This function checks if a component is installed in the current project.
	Returns true if component is installed and its version is succesfully retrieved.
	If component is not installed or retrieving component version failed, "version" is set to empty.
  @param component (in)  Name of the component
  @param version (out)  Current version of the installed component
  @param reduHostNum (in)
  @return true if the component is installed, false otherwise
*/
bool fwInstallation_isComponentInstalled(string component, string &version, int reduHostNum = 0)
{
  if(reduHostNum == 0){
    reduHostNum = fwInstallationRedu_myReduHostNum();
  }

  version = "";
  if(!dpExists(fwInstallation_getComponentDp(component, reduHostNum))){
    return false;
  }

  dyn_anytype componentInfo;
  if(fwInstallation_getComponentInfo(component, "componentversionstring", componentInfo, reduHostNum) != 0){
    fwInstallation_throw("fwInstallation_isComponentInstalled() -> Could not retrieve the version of component: " + component);
    return false;
  }

  if(dynlen(componentInfo)){
    version = componentInfo[1];
  }
  return true;
}

/** This function retrieves the source directory from which a component was installed
  @param component (in) name of the component
  @param sourceDir (out) source directory
  @return 0 if everything OK, -1 if errors.
*/
int fwInstallation_getComponentSourceDir(string component, string &sourceDir)
{
  dyn_anytype componentInfo;

  if(fwInstallation_getComponentInfo(component, "sourceDir", componentInfo ) != 0)
  {
    fwInstallation_throw("fwInstallation_getComponentSourceDir() -> Could not retrieve the source directory of component: " + component);
    return -1;
  }

  if(dynlen(componentInfo))
    sourceDir = componentInfo[1];
  else
    sourceDir = "";

  return 0;
}

/** This function returns the name of a component correspoding to an internal dp of the installation tool
  @param dp (in) name of the dp of the installation tool
  @return name of the component
*/
string fwInstallation_dp2name(string dp)
{

  //remove system name
  if(strpos(dp, ":") > 0)
    strreplace(dp, getSystemName(), "");

  //remove fwInstallation prefix
  strreplace(dp, "fwInstallation_", "");

  //remove _2 if it exists
  if(dp.endsWith("_1") || dp.endsWith("_2")){
    dp.chop(2);
  }
  return dp;
}

void fwInstallation_setCurrentComponent(string component, string version = "")
{
  gFwInstallationCurrentComponent = component;
  if(version != "")
    gFwInstallationCurrentComponent = gFwInstallationCurrentComponent + " v." + version;

  return;
}

void fwInstallation_unsetCurrentComponent()
{
  gFwInstallationCurrentComponent = "";
  return;
}


/** Sets the status of the installation tool
  @param status true if OK, false if error
*/
void fwInstallation_setToolStatus(bool status)
{
  string dp = fwInstallation_getInstallationDp();
  if(dpExists(dp)){
    dpSet(dp + ".status", status);
  }
}

bool fwInstallation_getToolStatus()
{
  bool status = false;
  string dp = fwInstallation_getInstallationDp();
  dpGet(dp + ".status", status);

  return status;
}

int fwInstallation_getProjectWCCOAInfo(string &version,
                                      dyn_string &patchList,
                                      time &lastUpdate,
                                      dyn_string &exception,
                                      string sys = "")
{
  if(sys == "")
    sys = getSystemName();

  string dp = sys + fwInstallation_getInstallationDp();

  if(!dpExists(dp + ".projectInfo.wccoaVersion"))
  {
    version = "";
    patchList = makeDynString();

    dynAppend(exception, "ERROR: fwInstallation_getProjectPvssInfo() -> Could not retrieve PVSS info from system: " + sys + ".Please, upgrade the installation tool in the remote system to enable this functionality");
    return -1;
  }

  dpGet(dp + ".projectInfo.wccoaVersion", version,
        dp + ".projectInfo.wccoaPatchList", patchList,
        dp + ".projectInfo.wccoaVersion:_online.._stime", lastUpdate);

  return 0;
}

/** This function checks if there are any post-install scripts or action pending to be executed
  * @return true if there are pending post-install scripts or actions, false if not
  */
bool fwInstallation_arePostInstallsPending(){
  dyn_string scriptsList;
  char actionsBitPattern;

  string dp = fwInstallation_getInstallationPendingActionsDp();
  dpGet(dp + ".postInstallFiles:_original.._value", scriptsList,
        dp + ".postInstallFiles:_original.._userbyte1", actionsBitPattern);

  return (dynlen(scriptsList) > 0 || actionsBitPattern);
}

/** This function lauches the pending post-installation of scripts of installed components (if any)
  * @return 0 if OK, -1 if errors
  */
int fwInstallation_executePostInstallScripts()
{
  if(!fwInstallation_arePostInstallsPending()){
    return 0;
  }
  return fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("ctrl"),
                                       FW_INSTALLATION_SCRIPTS_MANAGER_CMD);
}

/** This function creates the trash for the installation tool
  @param sourceDir (in) path where to create the trash as string
  @return 0 if OK, -1 if errors
*/
int fwInstallation_createTrash(string sourceDir)
{
  if(sourceDir != "" && access(sourceDir, W_OK))
  if(!mkdir(sourceDir))
    return -1;

  return 0;
}

/** This function retrieves the current version of the installation tool used in a particular PVSS system.
  @note Please do not use this function. It will be marked as obsolete in the future.
        Use fwInstallation_getToolVersionLocal() or fwInstallation_getToolVersionFromDp() instead, depending on the needs.
  @param version (out) version of the tool
  @param systemName (int) name the pvss system where to read the installation tool version from
  @return 0 if OK, -1 if errors
*/
int fwInstallation_getToolVersion(string &version, string systemName = "")
{
  string dp = fwInstallation_getInstallationDp();

  if(systemName == "")
    systemName = getSystemName();

  if(systemName == getSystemName())
  {
    version = csFwInstallationToolVersion;
    return 0;  //If local system we are done
  }

  //In case we want to read tool version in a different version
  if(!patternMatch("*:", systemName))
    systemName += ":";

  if(!dpExists(systemName + dp + ".version")){
    version = "";
    return -1;
  }
  else {
    dpGet(systemName + dp + ".version", version);
  }
  return 0;
}

/** Retrieves the current version of installation tool in the local project.
  * @param version (out)  Version of the tool (format: X.X.X[-tag[-tagId]])
  *                       Example: 8.2.0 (stable release, tag is empty), 8.3.0-SNAPSHOT-20181015090802, 9.0.0-beta-02
  */
void fwInstallation_getToolVersionLocal(string &version)
{
  version = fwInstallation_getVersionString(csFwInstallationToolVersion, csFwInstallationToolTag);
}

/** Retrieves the current version of installation tool used in given WinCC OA system
  * from internal installation tool datapoint.
  * @note 'version' argument is always modified, in case of error empty string is assigned to it.
  * @param version (out)  Version of the tool (format: X.X.X[-tag[-tagId]])
  *                       Example: 8.2.0 (stable release, tag is empty), 8.3.0-SNAPSHOT-20181015090802, 9.0.0-beta-02
  * @param systemName (in)  Name of WinCC OA system where to read installation tool version from. Local system when empty (default)
  * @return 0 when version was read correctly. -1 in case of errors while reading values from datapoint.
  *         -2 when internal installation tool datapoint does not exists in the system.
  */
int fwInstallation_getToolVersionFromDp(string &version, string systemName = "")
{
  if(systemName == ""){ // If system name is not provided assume local system
    systemName = getSystemName();
  }
  if(!patternMatch("*:", systemName)){ // Append colon if missing
    systemName += ":";
  }

  version = "";
  string sysDp = systemName + fwInstallation_getInstallationDp();

  if(!dpExists(sysDp + ".version")){
    return -2; // Missing version dp - installation tool is not installed on remote system
  }
  int retVal = dpGet(sysDp + ".version", version);
  return retVal;
}

/** This function retrieves name of the internal dp holding the parameterization of the DB-agent
  @return name of the internal dp as string
*/
string fwInstallation_getAgentDp()
{
//  string dp;

//  if(fwInstallationRedu_myReduHostNum() > 1)
//    dp = "fwInstallation_agentParametrization_" + fwInstallationRedu_myReduHostNum();
//  else
    return "fwInstallation_agentParametrization";
}

/** This function retrieves name of the internal dp holding the pending installation requests to be executed by the DB-Agent
  @return name of the dp as string
*/
string fwInstallation_getAgentRequestsDp(int localReduHostNum = 0)
{
  if(localReduHostNum == 0)
    localReduHostNum = fwInstallationRedu_myReduHostNum();

  return fwInstallationRedu_getReduDp("fwInstallation_agentPendingRequests", getSystemName(), localReduHostNum);
}

string fwInstallation_getInstallationPendingActionsDp(int localReduHostNum = 0)
{
  if(localReduHostNum == 0)
    localReduHostNum = fwInstallationRedu_myReduHostNum();

  return fwInstallationRedu_getReduDp("fwInstallation_pendingActions", getSystemName(), localReduHostNum);
}

/** The function reads all project paths from the config file, normalizes them and adds to a dyn_string list.
  * Project paths have the same order as in the config file.
  * @param projPaths (out)  dyn_string which will be filled with the project paths from the config file
  * @param adjustScattered (in)  Flag that indicates if projPaths should be adjusted when it is a scattered project (default = false)
  * @return 0 if success, -1 if error, -2? if no project paths in the config file (this should not happen)
*/
int fwInstallation_getProjPaths(dyn_string& projPaths, bool adjustScattered = false)
{
  // Get paths from config file and normalize them
  int retVal = fwInstallation_getProjPathsRaw(projPaths);
  if(retVal != 0) return retVal;
  if(fwInstallation_normalizePathList(projPaths) == -1) return -1;

  string projPathConst = PROJ_PATH;
  if(fwInstallation_normalizePath(projPathConst) == -1) return -1;

  if(!adjustScattered)
    return 0; // Don't have to adjust paths in case of scattered UI so nothing more to do, exit

  string nativePathToReplace, scatteredPathReplacement;
  retVal = fwInstallation_getPathMappingForScattered(nativePathToReplace, scatteredPathReplacement);
  if(retVal == 1)
    return 0; // It's not a scattered UI, there is no need for adjustment, exit
  if(retVal != 0)
  {
    fwInstallation_throw("fwInstallation_getProjPaths() -> Failed to get path mapping for scattered UI, returned project paths are not adjusted");
    return -1;
  }

  int projPathsLen = dynlen(projPaths);
  for(int i=1;i<=projPathsLen;i++)
    strreplace(projPaths[i], nativePathToReplace, scatteredPathReplacement);

  return 0;
}

/** The function reads all project paths from the config file into a dyn_string list. Paths are exactly as in config file.
  * @param projPaths (out)  dyn_string which will be filled with the project paths from the config file
  * @return 0 if success, -1 if error, -2? if no project paths in the config file (this should not happen)
*/
private int fwInstallation_getProjPathsRaw(dyn_string& projPathsRaw)
{
  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;
  return paCfgReadValueList(configFile, "general", "proj_path", projPathsRaw);
}

/** When running a scattered project, function returns the part of the project path that should be replaced and the replacement
  * to be put instead in order to create a valid path to the project directories from scattered project.
  * Use case: Accessing component installation directory when running on Scattered project.
  * Example: When path of the main project is:      /opt/user/PVSS_projects/mainProject/mainProject and path
  * to the main project from scattered project is: //scatteredProjectHost/PVSS_projects/mainProject/mainProject
  * then /opt/user/  should be replaced by //scatteredProjectHost/ whenever main project directories needs to be accessed from Scattered.
  * @param nativePathToReplace (out)  Part of the project path (as it is in original config file) that should be replaced.
  * @param scatteredPathReplacement (out)  Part of the path that should be put instead the original one (remote path to the project from Scattered).
  * @return -1 in case of an error (failed to get project paths from config file), 1 when it is not a scattered project (no need to change paths)
  *         0 when project is scattered and path mapping was retrieved correctly (note that the output variables are changed inside function only when 0 is returned).
  */
int fwInstallation_getPathMappingForScattered(string &nativePathToReplace, string &scatteredPathReplacement)
{
  dyn_string configPaths;
  if(fwInstallation_getProjPaths(configPaths) != 0 || dynlen(configPaths) < 1)
  {
    fwInstallation_throw("fwInstallation_getPathMappingForScattered() -> Failed to get project paths from config file, cannot obtain path mapping for scattered UI");
    return -1;
  }
  string configProjPath = configPaths[dynlen(configPaths)];
  string pvssProjPath = PROJ_PATH;
  fwInstallation_normalizePath(pvssProjPath);

  if(configProjPath == pvssProjPath)
    return 1; // Not a scattered project

  // Look for the first character that differs in both path, starting from the last character
  int configProjPathCount = strlen(configProjPath) - 1;
  int pvssProjPathCount = strlen(pvssProjPath) - 1;
  while(configProjPathCount >= 0 && pvssProjPathCount >= 0 &&
        configProjPath[configProjPathCount] == pvssProjPath[pvssProjPathCount])
  {
    configProjPathCount--;
    pvssProjPathCount--;
  }

  nativePathToReplace = substr(configProjPath, 0, configProjPathCount + 1);
  scatteredPathReplacement = substr(pvssProjPath, 0, pvssProjPathCount + 1);
  return 0;
}

/** Helper function to convert data point name (remove blank spaces, etc.).
 * @param app (string) IN WCCOA application name to convert (may contain blanks, etc.)
 * @return converted data point type
 */
string _fwInstallation_getWCCOAApplicationDpName(string app)
{
  string dp = strtoupper(app);

  strreplace(dp, ".", "_dot_");
  strreplace(dp, " ", "_");

  return dp;
}

/** Retrieve existing WinCC OA (UNICOS) applications on this system
  @param wccoaApplications variable to receive info about currently installed WinCC OA applications.
  @return 0 on success, -1 on error.

  @Note: Currently only 'Default_Panel' field is filled. 'Info_URL', 'Comment_text', 'Status', 'Responsible' and 'Alarm_Overview_Panel' are missed.
*/
int fwInstallation_getWCCOAApplications(dyn_dyn_mixed &wccoaApplications)
{
  dyn_string feDps = dpNames(getSystemName() + "*.configuration.subApplications");
  dyn_string apps;

  int n = dynlen(feDps);
  for(int i = 1; i <= n; i++)
  {
    dyn_string temp;
    dpGet(feDps[i], temp);
    dynAppend(apps, temp);
  }
  dynUnique(apps);

  n = dynlen(apps);
  for(int i = 1; i <= n; i++)
  {
  	string appName = apps[i];
    string appNameDp = "_unApplication_" + _fwInstallation_getWCCOAApplicationDpName(appName);
    string defaultPanelDpElem = appNameDp + ".defaultPanel";
    string defaultPanelName;

    wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_NAME] = appName;

    if(dpExists(defaultPanelDpElem) && dpGet(defaultPanelDpElem, defaultPanelName) == 0)
    {
      wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_DEFAULT_PANEL] = defaultPanelName;
    }
    else
    {
      fwInstallation_throw("Unable to retrieve WinCC OA default panel name, dp: " + appNameDp, "WARNING", 10);
      wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_DEFAULT_PANEL] = "?";
    }

    // Commented out intentionally, we don't have this information
    //wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_INFO_URL] = "";
    //wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_COMMENT_TEXT] = "";
    //wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_STATUS] = "";
    //wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_RESPONSIBLE] = "";
    //wccoaApplications[i][FW_INSTALLATION_DB_WCCOA_APP_ALARM_OVERVIEW_PANEL] = "";
  }

  return 0;
}


/** This function backs up the project config file.
*   It is intendended to be called before component installation/uninstallation
* @param reduConfig  Flag indicating if redu config file should be backed up instead of main project config
* @return 0 if OK, -1 otherwise
*/
int fwInstallation_backupProjectConfigFile(bool reduConfig = false)
{
  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;
  string configFileExt = reduConfig?FW_INSTALLATION_REDU_CONFIG_FILE_EXT:"";
  if(reduConfig && !isfile(configFile + configFileExt)){
    return 0;
  }

  //Get string with following format _YYYY_MM_DD_HH_mm_ss_nnn (n stands for a ms)
  string str = formatTime("_%Y_%m_%d_%H_%M_%S", getCurrentTime(), "_%03d");
  string bkConfigFile = configFile + str;

  return fwInstallation_copyFile(configFile + configFileExt, bkConfigFile + configFileExt);
}

/** This functions writes all project paths given in a dyn_string to the config file
*   and overwrites existing paths exept the main project path.
  @param projPaths: dyn_string with the project paths for the config file
  @return 0 if OK, -1 if error
*/
int fwInstallation_setProjPaths( dyn_string projPaths )
{
	dyn_string configLines;

	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;

	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(tempLine, "proj_path") >= 0)
			{
				dynAppend(tempPositions,i);
			}
		}
		if(dynlen(tempPositions)>0)
		{
			sectionFound = TRUE;
			dynClear(tempLines);
			for (j=1; j<=dynlen(projPaths); j++)
			{
				tempLine = "proj_path = \"" + projPaths[j] + "\"";
				dynAppend(tempLines,tempLine);
			}
			for (j=dynlen(tempPositions); j>=1; j--)
			{
				dynRemove(configLines,tempPositions[j]);
			}
			dynInsertAt(configLines,tempLines,tempPositions[1]);
		}
		if(sectionFound)
		{
			fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
 return 0;
}

/** This function checks if given path exists in config file
* @param projPath: Project path (in)
* @param isPathInConfig:
@return 0 if path was successfully normalised, -1 in case of error
*/

int fwInstallation_isPathInConfigFile(string projPath, bool &isPathInConfig)
{
	dyn_string projPathsFromConfig;
  // Sequence of operations to compact the code
	if((fwInstallation_normalizePath(projPath) == -1) ||
		 (fwInstallation_getProjPaths(projPathsFromConfig) == -1))
	{
		return -1;
	}

  int retVal = dynContains(projPathsFromConfig, projPath);
  if(retVal == -1)
  {
    return -1;
  }

  isPathInConfig = (retVal > 0);

	return 0;
}

/** This function add a project path to the config file.
@param projPath: string that contains the project path to be added to the config file
@param position: position of the added path in the list (n = specified position, try 999 for last before main project path)
@return 0 if success,  -1 if error,  -2 if position out of range
@author S. Schmeling
*/
synchronized int fwInstallation_addProjPath(string projPath, int position)
{
	dyn_string configLines;

	dyn_int tempPositions;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;

	bool isPathInConfigFile = false;
	if(fwInstallation_normalizePath(projPath) == -1 ||
		fwInstallation_isPathInConfigFile(projPath,isPathInConfigFile) == -1)
	{
		return -1;
	}
	if(isPathInConfigFile)
	{
		return 0;
	}

	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(tempLine, "proj_path") >= 0)
			{
				dynAppend(tempPositions,i);
			}
		}

		if(dynlen(tempPositions)>0)
		{
			sectionFound = TRUE;
			tempLine = "proj_path = \"" + projPath + "\"";
			if(position > 0)
			{
				if(position < dynlen(tempPositions))
				{
					dynInsertAt(configLines,tempLine,tempPositions[position]);
				} else {
					dynInsertAt(configLines,tempLine,tempPositions[dynlen(tempPositions)]);
				}
			}
		}
		if(sectionFound == TRUE)
		{
    fwInstallation_registerProjectPath(projPath);
			return fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
        return 0;
}


/** This function removes the given project path from the config file.
@param projPath: string that contains the project path to be removed from the config file
@return 0 if success or path is not in config, -1 if general error
*/
synchronized int fwInstallation_removeProjPath( string projPathToRemove )
{
  if(fwInstallation_normalizePath(projPathToRemove) == -1){
    return -1;
  }

  const string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

  dyn_string projPathsRawInCfg;
  if(fwInstallation_getProjPathsRaw(projPathsRawInCfg) != 0){
    fwInstallation_throw("fwInstallation_removeProjPath(): Could not retrieve paths from project config file, cannot remove path: " + projPathToRemove);
    return -1;
  }

  bool err;
  int projPathsRawInCfgLen = dynlen(projPathsRawInCfg);
  for(int i=1;i<=projPathsRawInCfgLen;i++){
    string projPathInCfgRaw = projPathsRawInCfg[i];
    string projPathInCfg = projPathInCfgRaw;
    fwInstallation_normalizePath(projPathInCfg);
    if(projPathInCfg == projPathToRemove){
      if(paCfgDeleteValue(configFile, "general", "proj_path", projPathInCfgRaw) != 0){
        fwInstallation_throw("fwInstallation_removeProjPath(): Could not remove remove path: " + projPathInCfgRaw + " from the project config file");
        err = true;
      }else{
        fwInstallation_throw("fwInstallation_removeProjPath(): Path removed from the project config file: " + projPathInCfgRaw, "INFO");
      }
    }
  }
  return err?-1:0;
}

/** This function retrieves name of the internal dp associated
 * with an installed component.
 *
 * @param componentName name of the component
 * @param reduHostNum number of redundant host
 * @return datapoint name for a given component, or empty it doesn't exist
 */
string fwInstallation_getComponentDp(string componentName, int reduHostNum = 0)
{
  string dp = "fwInstallation_" + strltrim(strrtrim(componentName));

  if(reduHostNum == 0) reduHostNum = fwInstallationRedu_myReduHostNum();
  if(reduHostNum > 1 && !patternMatch("*_" + reduHostNum, componentName))
    dp += "_" + reduHostNum;

  return dp;
}


/** This function returns the following property of the installed component: list of files for this component

@param componentName: string with the name of the component
@param componentProperty: name of the requested property
@param componentInfo: variable that contains the property of the component
@return 0 - "success"  -1 - error
@author S. Schmeling and F. Varela
*/
int fwInstallation_getComponentInfo(string componentName, string componentProperty, dyn_anytype & componentInfo, int reduHostNum = 0)
{
  string temp_componentProperty, temp_string;
  float temp_float;
  dyn_anytype temp_dyn_string;
  bool temp_bool;
  int i;

  if(reduHostNum == 0) reduHostNum = fwInstallationRedu_myReduHostNum();

  temp_componentProperty = strtolower(componentProperty);

  string dp = fwInstallation_getComponentDp(componentName, reduHostNum);
  if(!dpExists(dp)) // Check if component data exists
    return -1;

	switch(temp_componentProperty)
	{
		case "componentfiles":
			i = dpGet(dp +".componentFiles", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configgeneral":
			i = dpGet(dp+".configFiles.configGeneral", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configlinux":
			i = dpGet(dp+".configFiles.configLinux", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configwindows":
			i = dpGet(dp+".configFiles.configWindows", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "initfiles":
			i = dpGet(dp+".initFiles", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "postinstallfiles":
			i = dpGet(dp+".postInstallFiles", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "dplistfiles":
			i = dpGet(dp+".dplistFiles", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "requiredcomponents":
			i = dpGet(dp+".requiredComponents", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "subcomponents":
			i = dpGet(dp+".subComponents", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "scriptfiles":
			i = dpGet(dp+".scriptFiles", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "date":
			i = dpGet(dp+".date:_original.._value", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "descfile":
			i = dpGet(dp+".descFile", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "sourcedir":
			i = dpGet(dp+".sourceDir", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "installationdirectory":
			i = dpGet(dp+".installationDirectory", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "componentversion":
		case "componentversionstring":
			i = dpGet(dp+".componentVersionString", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "requiredinstalled":
			i = dpGet(dp+".requiredInstalled", temp_bool);
			dynAppend(componentInfo, temp_bool);
			return i;
			break;
		case "isitsubcomponent":
			i = dpGet(dp+".isItSubComponent", temp_bool);
			dynAppend(componentInfo, temp_bool);
			return i;
			break;
		default:
			dynAppend(componentInfo, "Property not known");
			return -1;
	}
	return -1; // Default to fail
}

/** This function returns the name of the internal dps correspoding to all components installed in the local project.
  * In redundant system peer number can be specified.
  * @param reduHostNum (in)  Redu peer number (1 or 2), if 0 (default) then local peer number is used. Note that in non-redu system local peer is always 1.
  * @return List of the internal fwInstallation component dps (dyn_string). Note that as of version 8.2.1 returned datapoints always contain the system name.
*/
dyn_string fwInstallation_getInstalledComponentDps(int reduHostNum = 0)
{
  if(reduHostNum == 0){
    reduHostNum = fwInstallationRedu_myReduHostNum();
  }

  string installedComponentDpPrefix = fwInstallation_getComponentDp("", 1); // must be 1 to ensure that "_2" is not appended to the prefix
  if(reduHostNum > 1){
    return dpNames(installedComponentDpPrefix + "*_" + reduHostNum, FW_INSTALLATION_DPT_COMPONENTS);
  }
  //else reduHostNum == 1
  dyn_string componentDPs = dpNames(installedComponentDpPrefix + "*", FW_INSTALLATION_DPT_COMPONENTS);
  for(int i=dynlen(componentDPs);i>=1;i--){
    /*if(strpos(componentDPs[i], ":") > 0)
      strreplace(componentDPs[i], getSystemName(), "");*/ // Don't remove the system name
    if(patternMatch("*_2", componentDPs[i]) ||  patternMatch("*_3", componentDPs[i]) || patternMatch("*_4", componentDPs[i])){
      dynRemove(componentDPs, i); // Remove dps of other redu peers (filters for 3rd and 4th are not necessary currently)
    }
  }
  return componentDPs;
}

/** This function gets the information about all installed components into a dyn_dyn_string structure:
	[n][1] component name
	[n][2] component version
	[n][3] path to the installation
  [n][4] description file
@param componentsInfo: dyn_dyn_string that will contain all installed components and their respective version numbers
@return 0 if success,  -1 if error, -999999 if no components installed
@author S. Schmeling and F. Varela
*/
int fwInstallation_getInstalledComponents(dyn_dyn_string & componentsInfo, int reduHostNum = 0)
{
  dyn_dyn_string tempAllInfo;
  dyn_string componentDPs;
  string componentVersionString, installationDirectory, descFile;
  float componentVersion;
  string sourcePath;
  int installationNotOK;
  int dependenciesOK;
  string name;
  bool isSubcomponent = false;

  if(reduHostNum == 0) reduHostNum = fwInstallationRedu_myReduHostNum();

  componentDPs = fwInstallation_getInstalledComponentDps(reduHostNum);
  dynClear(tempAllInfo);

	if(dynlen(componentDPs) == 0)
	{
		return -999999;
	}
  else
  {
		for (int i=1; i<=dynlen(componentDPs); i++)
		{
      dpGet(componentDPs[i]+".name", name,
            componentDPs[i]+".componentVersionString",componentVersionString,
            componentDPs[i]+".installationDirectory",installationDirectory,
            componentDPs[i]+".descFile", descFile,
            componentDPs[i]+".sourceDir", sourcePath,
            componentDPs[i]+".installationNotOK", installationNotOK,
            componentDPs[i]+".requiredInstalled", dependenciesOK,
            componentDPs[i]+".isItSubComponent", isSubcomponent);

      if(patternMatch("*/", sourcePath))
        descFile = sourcePath + descFile;
      else
        descFile = sourcePath + "/" + descFile;

      dynAppend(tempAllInfo[i], name);
      dynAppend(tempAllInfo[i], componentVersionString);
      dynAppend(tempAllInfo[i], installationDirectory);
      dynAppend(tempAllInfo[i], descFile);
      dynAppend(tempAllInfo[i], installationNotOK);
      dynAppend(tempAllInfo[i], dependenciesOK);
      dynAppend(tempAllInfo[i], (string)fwInstallation_getComponentPendingPostInstalls(name, reduHostNum));
      dynAppend(tempAllInfo[i], isSubcomponent);
    }
		componentsInfo = tempAllInfo;
		return 0;
	}
}

/** This function gets the information about all available components in the specified paths into a dyn_dyn_string structure:
	- component name
	- component version
	- subcomponent [yes/no]
	- path to the description file

@param componentPaths (in) dyn_string with the paths to description files
@param componentsInfo (out) dyn_dyn_string that will contain all installed components and their respective version numbers and their paths
@param component (in) component pattern
@param scanRecursively (in) flag indicating if the search must recurse over subdirectories
@return 0 if success, -1 if error
@author S. Schmeling and F. Varela
*/
int fwInstallation_getAvailableComponents(dyn_string componentPaths,
                                          dyn_dyn_string & componentsInfo,
                                          string component = "*",
                                          bool scanRecursively = false)
{
 	string dirCurrentValue;
	dyn_string dynAvailableDescriptionFiles;
	string componentFileName;
	string strComponentFile;
	string tagName;
	string tagValue;

	string componentName;
	string componentVersionString;

	int result;

	bool	fileLoaded;
	bool isItSubComponent = false;

	int i, j, ii, iii;

	dyn_dyn_string tempAllInfo;
	dynClear(tempAllInfo);
	iii = 0;

        string dontRestartProject = "no";

	if(dynlen(componentPaths) == 0)
	{
		return -1;
	}

	for(ii=1; ii<=dynlen(componentPaths); ii++)
	{
		dirCurrentValue = componentPaths[ii];
		// it the directory name is empty
		if (dirCurrentValue != "")
		{
			// read the names of files that have the .xml extension in a directory specified by dirCurrentValue
			//FVR: Do it recursively
			if(scanRecursively)
  	          dynAvailableDescriptionFiles =  fwInstallation_getFileNamesRec(dirCurrentValue, component + ".xml");
 	        else
	          dynAvailableDescriptionFiles =  getFileNames(dirCurrentValue, component + ".xml");

			// for each component description file, read the component name, version and display it in the graphic table

			for( i = 1; i <= dynlen(dynAvailableDescriptionFiles); i++)
			{
				// get the file name of an .xml description file
				componentFileName = dynAvailableDescriptionFiles[i];
                                dyn_string tags, values;
                                dyn_anytype attribs;
                                int err = 0;

                                if(fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "name", values, attribs) != 0 ||
                                   dynlen(values) <= 0)
                                {
                                  //non-component file
                                  continue;
                                }

                                componentName = values[1];
                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "version", values, attribs);
                                componentVersionString = values[1];

                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "subComponent", values, attribs);
                                if(dynlen(values) > 0 )
                                  if((strtolower(values[1]) == "yes"))
                                    isItSubComponent = true;
                                  else
                                    isItSubComponent = false;

                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "dontRestartProject", values, attribs);
                                if(dynlen(values) > 0 )
                                  dontRestartProject = values[1];

					// check whether the description file contains the component name
					if(componentName != "")
					{
						iii++;
						dynAppend(tempAllInfo[iii], componentName);
						dynAppend(tempAllInfo[iii], componentVersionString);
						dynAppend(tempAllInfo[iii], dontRestartProject);
						if(isItSubComponent)
						{
							dynAppend(tempAllInfo[iii], "yes");
						} else {
							dynAppend(tempAllInfo[iii], "no");
						}
						dynAppend(tempAllInfo[iii], dirCurrentValue + "/" + componentFileName);
					 	componentName = "";
						isItSubComponent = false;
					}
			}
		}
	}
	componentsInfo = tempAllInfo;
	return 0;
}

//Predefined window titles for fwInstallation_popup() function
const string FW_INSTALLATION_POPUP_TITLE_ERROR = "Installation Error";
const string FW_INSTALLATION_POPUP_TITLE_INFORMATION = "Information";
const string FW_INSTALLATION_POPUP_TITLE_WARNING = "Warning";

/**
 * This function opens a timed out popup with title and test provided as parameter.
 * @param popupText   text to be shown in popup window
 * @param popupTitle  title of the popup window, the default one is "Installation Error".
 * It is possible to use predefined titles:
 * FW_INSTALLATION_POPUP_TITLE_ERROR - "Installation Error"
 * FW_INSTALLATION_POPUP_TITLE_INFORMATION - "Information"
 * FW_INSTALLATION_POPUP_TITLE_WARNING - "Warning"
 * @author Sascha Schmeling
 */
int fwInstallation_popup(string popupText, string popupTitle = FW_INSTALLATION_POPUP_TITLE_ERROR)
{
  dyn_string dollarParams = makeDynString("$text:" + popupText, "$keepOnTop:yes");
  if(popupTitle == FW_INSTALLATION_POPUP_TITLE_ERROR ||
     popupTitle == FW_INSTALLATION_POPUP_TITLE_WARNING){
    dynAppend(dollarParams, "$icon:WARNING");
  }

  if(myManType() == UI_MAN){
    ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", popupTitle, dollarParams);
  }

  if(popupText.contains("<br/>") || popupText.contains("<a href=")){ // is HTML text?
    popupText = fwInstallation_stripHtml(popupText);
  }

  fwInstallation_throw(popupText, "INFO", 10);
  return 0;
}

/** Removes HTML tags from given string and returns plain-text string
  * @param text  Input HTML text
  * @return Plain-text string
  */
string fwInstallation_stripHtml(string text){
  while(true){ // 1st loop - remove unpaired tags
    dyn_string matches;
    regexpSplit("<\\w+/>", text, matches, makeMapping("minimal", true));
    if(matches.count() < 1){
      break;
    }
    text.replace(matches.at(0), " ");
  }
  while(true){ // 2nd loop - remove paired tags
    dyn_string matches;
    regexpSplit("<(\\w+).*>(.*)</\\1>", text, matches, makeMapping("minimal", true));
    if(matches.count() < 3){
      break;
    }
    text.replace(matches.at(0), matches.at(2));
  }
  return text;
}

/** This function returns the project name
@return project name as string
*/
string paGetProjName()
{
	return PROJ;
}

/** This function retrieves the system name(s) on which a certain
"application" = component is installed.

@param applicationName	name of the application/component to be found
@param systemNames			name(s) of the system(s) with the application/component installed
@author Sascha Schmeling
*/

void fwInstallation_getApplicationSystem(string applicationName, dyn_string &systemNames)
{
  string tempString;
  dyn_string reduSystems;

  systemNames = dpNames("*:fwInstallation_" + applicationName, FW_INSTALLATION_DPT_COMPONENTS);
  reduSystems = dpNames("*:fwInstallation_" + applicationName + "_2", FW_INSTALLATION_DPT_COMPONENTS);

  for (int i=1; i<=dynlen(reduSystems); i++)
  {
    tempString = substr(reduSystems[i], 0, strlen(reduSystems[i])-2);
    if (!dynContains(systemNames, tempString))
    {
      dynAppend(systemNames, reduSystems[i]);
    }
  }

  if(dynlen(systemNames) > 0)
  {
    for(int i=1; i<=dynlen(systemNames); i++)
    {
      dpGet(systemNames[i] + ".componentVersionString", tempString);
      if(tempString != "")
        systemNames[i] = dpSubStr(systemNames[i], DPSUB_SYS);
      else
        systemNames[i] = "*" + dpSubStr(systemNames[i], DPSUB_SYS) + "*";
    }
  }

  dynSortAsc(systemNames);
}


/** This function retrieves the PVSS version number as well as the installed patches

@param patches (out) dyn_string array with all installed patches
@return pvss version as a string
*/
string fwInstallation_getPvssVersion(dyn_string & patches)
{
  string pvssVersion = VERSION_DISP;
  dynClear(patches);

  patches = getFileNames(PVSS_PATH, "Readme*.txt");
  for(int i = dynlen(patches); i >= 1; i--) {
    strreplace(patches[i], "Readme", "");
    strreplace(patches[i], ".txt", "");
  }

	return pvssVersion;
}

/** This function shows the help file associated to a component

@param componentName	(in) name of the component in the database
@param systemName (in) name of the system where to look for the component
@author Sascha Schmeling
*/
fwInstallation_showHelpFile(string componentName, string systemName = "")
{
  if(isFunctionDefined("fwGeneral_openHelpForComponent"))
  {
    dyn_string exceptionInfo;
    callFunction("fwGeneral_openHelpForComponent", componentName, exceptionInfo);
    if (dynlen(exceptionInfo)) fwInstallation_throw(exceptionInfo[2],exceptionInfo[1]);
    return;
  }

  if(systemName == "")
    systemName = getSystemName();
  if(!patternMatch("*:", systemName))
    systemName += ":";

  componentName = strltrim(componentName, "_");
  string dp = fwInstallation_getComponentDp(componentName);
  string helpFileRelativePath, componentInstallationPath;
  dpGet(dp + ".installationDirectory", componentInstallationPath,
        dp + ".helpFile", helpFileRelativePath);
  fwInstallation_normalizePath(componentInstallationPath);

  string nativePathToReplace, scatteredPathReplacement;
  if(fwInstallation_getPathMappingForScattered(nativePathToReplace, scatteredPathReplacement) == 0)
  { // Adjust path if running a scattered project (FWINS-1981)
    strreplace(componentInstallationPath, nativePathToReplace, scatteredPathReplacement);
  }

  // FWINS-2172: allow help from either utf8 or iso88591 subfolder, prefering the utf8
  // FWINS-2252: (PG) as of 3.19 prefer no-lang specific directory (help/)
  const dyn_string searchHelpDirs = makeDynString("", "en_US.utf8/", "en_US.iso88591/");
  string helpFile;
  for(int i=0;i<searchHelpDirs.count();i++){
    string tmpHelpFile = componentInstallationPath + "/" + HELP_REL_PATH + searchHelpDirs.at(i) +
                         helpFileRelativePath; // can't use getPath() as installation path may not be taken into account
    if(access(tmpHelpFile, R_OK) == 0){
      helpFile = tmpHelpFile;
      break;
    }
  }

  string browserCommand;
  if(_WIN32)
  {
    helpFile = makeNativePath(helpFile);
    if (dpExists(systemName + "fwGeneral.help.helpBrowserCommandWindows")) dpGet(systemName + "fwGeneral.help.helpBrowserCommandWindows", browserCommand);

    if(browserCommand == "") {
      browserCommand = "start \"\" $1"; // note that "start" needs to have the window title name as 1st param - we pass an empty string
    }
  }
  else
  {
    if (dpExists(systemName + "fwGeneral.help.helpBrowserCommandLinux")) dpGet(systemName + "fwGeneral.help.helpBrowserCommandLinux", browserCommand);

    if(browserCommand == "") browserCommand = "xdg-open $1";
  }
  // if someone forgot to put $1 as a parameter for the configured browser, do our best to construct the command
  if(strreplace(browserCommand, "$1", helpFile) == 0) {
    browserCommand = browserCommand + " \"file://" + helpFile+"\"";
  }

  system(browserCommand);
}

const string FW_INSTALLATION_FILE_URI_SCHEME = "file:///";
const string FW_INSTALLATION_HELP_FILE_EXTENSION = ".html";
const string FW_INSTALLATION_PANEL_HELP_FILE_DIR = "fwInstallation/" + PANELS_REL_PATH;

/** This function shows the help file for fwInstallation panels.
  * @param panelFilePath (in)  Relative path to a panel file from panels/ directory
  */
fwInstallation_showHelpForPanel(string panelFilePath)
{
  const string fwGeneralOpenPanelHelpFunction = "fwGeneral_openHelpForPanel";
  if(isFunctionDefined(fwGeneralOpenPanelHelpFunction)){
    dyn_string exceptionInfo;
    callFunction(fwGeneralOpenPanelHelpFunction, panelFilePath, exceptionInfo);
    return;
  }
  fwInstallation_normalizePath(panelFilePath);
  string panelFilePathWithoutExt = delExt(panelFilePath);
  string helpFilePath = getPath(HELP_REL_PATH, FW_INSTALLATION_PANEL_HELP_FILE_DIR + panelFilePathWithoutExt +
                                FW_INSTALLATION_HELP_FILE_EXTENSION);
  if(helpFilePath == ""){
    fwInstallation_throw("Could not find the help file associated with the panel: " + panelFilePath, "ERROR");
    return;
  }
  openUrl(FW_INSTALLATION_FILE_URI_SCHEME + strltrim(helpFilePath, "/"));
}

/** This function gets all entries from the config file into string structures
@param configLines: dyn_string containing the lines from the config file
@return 0 if OK, -1 if error
@author M. Sliwinski, adapted for library by S. Schmeling and F. Varela
*/
int _fwInstallation_getConfigFile(dyn_string & configLines)
{
	bool fileLoaded = false;
	string fileInString;
	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

// load config file into dyn_string
	fileLoaded = fileToString(configFile, fileInString);
	if (! fileLoaded )
	{
		fwInstallation_throw("fwInstallationLib: Cannot load config file");
		return -1;
	} else {
		configLines = fwInstallation_splitLines(fileInString);
		return 0;
	}
}

/** this function saves the dyn_string  into PVSS project confg file

@param configLines: the dyn_string containing the lines from the  file
@param filename: the name of a file
@author M.Sliwinski. Modified by F. Varela (with a lot of pain...)
*/
int fwInstallation_saveFile( dyn_string & configLines, string filename)
{
	int i;
	string strLinesToSave;


	file fileHdlConfig;

	int writeResult;

	// open the file for writing
	fileHdlConfig = fopen(filename, "w");
	// if the file is not opened
	if(fileHdlConfig == 0)
	{
		fwInstallation_throw("fwInstallation: File " + filename + " could not be opened", "error", 4);
		return -1;
	}
	else
	{
		// copy each line from a dyn_string into string and separate the lines with newline character
		for(i = 1; i <= dynlen(configLines); i++)
		{
                  if(configLines[i] !=  "")
                  {
                    if(configLines[i] != "\n")
                    {
                      if(patternMatch("[*", configLines[i]))
                        strLinesToSave += "\n" + configLines[i]; //If a new section, add also a blank line just before

		      strLinesToSave += configLines[i] + "\n";
                    }
                      else
                      strLinesToSave += configLines[i];
                  }
		}
		// save the string into the file
		writeResult = fputs(strLinesToSave , fileHdlConfig);
		fclose(fileHdlConfig);
		return 0;
	}
}

/** This function returns the list of pending pending post-install scripts and their components
  * @param components (out) list of components corresponding to the scripts
  * @param scripts (out) list of pending post-install scripts
  * @param reduHostNum (in) Redu peer number (1 or 2), if 0 (default) then local peer number is used.
  *                     In non-redu system local peer is always 1.
  */
void _fwInstallation_GetComponentsWithPendingPostInstall(dyn_string &components,
                                                         dyn_string &scripts,
                                                         int reduHostNum = 0)
{
  dynClear(components);
  dynClear(scripts);

  dyn_string compDelimScripts;
  dpGet(fwInstallation_getInstallationPendingActionsDp(reduHostNum) + ".postInstallFiles",
        compDelimScripts);
  for(int i = 1; i <= dynlen(compDelimScripts); i++) {
    string compDelimScript = compDelimScripts[i];
    int delimPos = strtok(compDelimScript, "|");
    if(delimPos < 0) {
      fwInstallation_throw("fwInstallation: Wrong entry " + compDelimScript +
                           " in pending postInstall actions");
      continue;
    }

    string component = substr(compDelimScript, 0, delimPos);
    string script = substr(compDelimScript, delimPos + 1);
    dynAppend(components, component);
    dynAppend(scripts, script);
  }
}

/** This function deletes the information for the component from the project config file.

@param componentName: the name of a component
@param reduConfig: Flag indicating if redu config file should be updated instead of main project config
@author S.Schmeling and patched by F. Varela.
*/
void _fwInstallation_DeleteComponentFromConfig(string componentName, bool reduConfig = false)
{
  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;
  if(reduConfig){
    configFile += FW_INSTALLATION_REDU_CONFIG_FILE_EXT;
    if(!isfile(configFile)){
      return; // redu config file does not exist, skip it
    }
  }
  dyn_string projectConfigLines; // this table contains the config file - each row contains one line from project config file
  if(fwInstallation_loadFileLines(configFile, projectConfigLines) == 0){
    fwInstallation_deleteComponentConfigEntries(projectConfigLines, componentName);
    fwInstallation_saveFile(projectConfigLines, configFile);
  }else{
    fwInstallation_throw("Failed to get config file content", "ERROR", 10);
  }
}

bool fwInstallation_getAddManagersOnReduPartner()
{
  bool addManagersOnReduPartner = false;
  dpGet(fwInstallation_getInstallationDp() + ".addManagersOnReduPartner", addManagersOnReduPartner);
  return addManagersOnReduPartner;
}

int fwInstallation_setAddManagersOnReduPartner(bool addManagersOnReduPartner)
{
  return dpSetWait(fwInstallation_getInstallationDp() + ".addManagersOnReduPartner", addManagersOnReduPartner);
}

/** This function returns proposals of the component installation directory.
  * List contains paths from config file appearing in reverse order excluding main project path or if there are no such paths in config file then a set of default locations.
  * @return list of proposed paths for installation directory
  */
dyn_string _fwInstallation_proposeInstallationDirs()
{
  dyn_string installationDirProposals;

  // get paths from config file
  dyn_string projPathsInConfig;
  fwInstallation_getProjPaths(projPathsInConfig);
  int projPathsInConfigLen = dynlen(projPathsInConfig) - 1; // exclude main project path (PROJ_PATH)
  for(int i=projPathsInConfigLen;i>0;i--)
    dynAppend(installationDirProposals, projPathsInConfig[i]);

  if(dynlen(installationDirProposals) > 0)
    return installationDirProposals;

  // if there is no directories other than PROJ_PATH in config file then propose a list of default installation paths
  installationDirProposals = makeDynString(
      _fwInstallation_baseDir(PROJ_PATH) + "fwComponents_" + formatTime("%Y%m%d", getCurrentTime()), // default option
      _fwInstallation_baseDir(PROJ_PATH) + "installed_components", // UNICOS style
      PROJ_PATH + "/fwComponents"); // fwComponents subfolder of the project folder
  fwInstallation_normalizePathList(installationDirProposals);
  return installationDirProposals;
}

/** This function gets the components data from the directory specified in the textBox and fills the graphic table with it.

@param tableName (in) the name of a graphic table to be filled with data
@param sourceWidget (in) the name of a widget containing the directory from which the data about the components is taken
@param systemName (in) name of the pvss system where to look for components
@param scanRecursively (in) flag indicating if the search must recurse over subdirectories
@return 0 - "success"  -1 - error
@author M.Sliwinski. Modified by F. Varela.
*/
int fwInstallation_getComponentsInfo(string tableName ,
                                     string sourceWidget,
                                     string systemName = "",
                                     bool scanRecursively = false)
{
  string dirCurrentValue;
  dyn_string dynAvailableDescriptionFiles;
  string componentFileName;
  string strComponentFile;
  string tagName;
  string tagValue;

  string componentName;
  string componentVersionString;

  shape shape_dirFromSourceWidget = getShape(sourceWidget);
  shape shape_destinationTable = getShape(tableName);
  int result;

  bool	fileLoaded;
  bool isItSubComponent = false;
  bool isItHiddenComponent = false;

  int i, j;
  bool showSubComponents;
  bool showHiddenComponents;
  string dontRestartProject = "no";
  dyn_anytype attribs;


  if(systemName == "")
    systemName = getSystemName();

  if(!patternMatch("*:", systemName))
    systemName += ":";

  shape_destinationTable.deleteAllLines();

  dirCurrentValue = shape_dirFromSourceWidget.text;
  if (dirCurrentValue == "")
  {
    //fwInstallation_throw("You must define the source directory", "WARNING", 10);
    return 0;
  }

  if(fwInstallation_normalizePath(dirCurrentValue, true) != 0)
    fwInstallation_throw("Failed to normalize directory path: " + dirCurrentValue);

  openProgressBar("FW Component Installation Tool", "copy.gif", "Looking for components in: " + dirCurrentValue, "This make take a while", "Please wait...", 1);

  // read the names of files that have the .xml extension in a directory specified by dirCurrentValue
  //FVR: Do it recursively
  if(scanRecursively)
    dynAvailableDescriptionFiles =  fwInstallation_getFileNamesRec( dirCurrentValue, "*.xml");
  else
    dynAvailableDescriptionFiles = getFileNames(dirCurrentValue, "*.xml");


  if(dynlen(dynAvailableDescriptionFiles) <= 0)
  {
    if(myManType() == UI_MAN)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "Not files found", makeDynString("$1:No component files found.\nAre you sure the directory is readable?"));
    }
    else
    {
      fwInstallation_throw("No component files found.\nAre you sure the directory is readable?");
    }
    closeProgressBar();
    return 0;
  }
  showProgressBar("Found : " + dynlen(dynAvailableDescriptionFiles) + " XML files", "Verifying that they are component files", "Please wait...", 75);

  // for each component description file, read the component name, version and display it in the graphic table
  for( i = 1; i <= dynlen(dynAvailableDescriptionFiles); i++)
  {
    isItSubComponent = false;
    isItHiddenComponent = false;
    // get the file name of an .xml description file
    componentFileName = dynAvailableDescriptionFiles[i];

    // load the description file
    //fileLoaded = fileToString(dirCurrentValue + "/" + componentFileName, strComponentFile);
    dyn_string ds;
    if(fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "name", ds, attribs))
    {
      //fwInstallation_throw("Cannot load " + componentFileName + " file ", "error", 4);
      continue;
    }
    else if(dynlen(ds) < 1)//bug #38484: Check that it is a component file:
      continue;

    componentName = ds[1];

    dynClear(ds);
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "version", ds, attribs);
    if(dynlen(ds) < 1)//bug #38484: Check that it is a component file:
    {
      continue; //not a component file
    }
    componentVersionString = ds[1];

    dynClear(ds);
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "hiddenComponent", ds, attribs);
    if(dynlen(ds) > 0 && strtolower(ds[1]) == "yes")
      isItHiddenComponent = true;

    dynClear(ds);
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "subComponent", ds, attribs);
    if(dynlen(ds) > 0 && strtolower(ds[1]) == "yes")
      isItSubComponent = true;

    ///TODO: check if it is always the same as subcomponent as ds array is not cleared
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "dontRestartProject", ds, attribs);
    if((dynlen(ds) > 0 && strtolower(ds[1]) == "yes"))
      dontRestartProject = "yes";

    // check whether the description file contains the component name
    // and whether it is a subcomponent - if it is a subcomponent - do not display it in a table with available components
    getValue("ShowSubComponents","state", 0, showSubComponents);
    // if there is a ShowHiddenComponents button on a panel then get its state, otherwise always show hidden components (checking if shape exists is needed as this function is used also in fwConfigurationDBSystemInformation that doesn't have this checkbox in older versions)
    showHiddenComponents = true;
    if(shapeExists("ShowHiddenComponents"))
    {
      getValue("ShowHiddenComponents","state", 0, showHiddenComponents);
    }

    if((componentName != "") && ((!isItSubComponent) || (isItSubComponent && showSubComponents)) && ((!isItHiddenComponent) || (isItHiddenComponent && showHiddenComponents)))
    {
      // this component can be installed - put it in the table with available components.
      //if (componentName == "") - it means that the xml file does not contain the component name
      //                           or the component file does not describe a component
      // Check if the component is already installed
      if(systemName != "*" || systemName != "*:")  //If we are not dealing with more than one system, look if component is installed
        fwInstallation_componentInstalled(componentName, componentVersionString, result, systemName, true);

      if (result == 1) // component is installed
      {
        if(isItSubComponent)
          shape_destinationTable.appendLine("componentName", "_"+componentName, "componentVersion", componentVersionString, "colStatus" , "Installed" , "descFile", dirCurrentValue + "/" + componentFileName);
        else
          shape_destinationTable.appendLine("componentName", componentName, "componentVersion", componentVersionString, "colStatus" , "Installed" , "descFile", dirCurrentValue + "/" + componentFileName);
      }
      else // component is not installed
      {
        // display the information about the component
        if(isItSubComponent)
          shape_destinationTable.appendLine("componentName", "_"+componentName, "componentVersion", componentVersionString, "descFile", dirCurrentValue + "/" + componentFileName);
        else
          shape_destinationTable.appendLine("componentName", componentName, "componentVersion", componentVersionString, "descFile", dirCurrentValue + "/" + componentFileName);
      }
      componentName = "";
    }
  }

  closeProgressBar();
  return 0;
}



/** This function checks if the component is installed in version equal or higher than requested.
  * @param componentName (in)  The name of a component to be checked
  * @param requestedComponentVersion (in)  Requested version of the component
  * @param result (out)  Returned value indicating if component in requested version is installed (1) or not (0)
  * @param systemName (in)  System where to check if the component is installed
  * @param beStrict (in)  Flag to indicate an exact match of the versions installed and required
  * @param caseSensitive (in) Indicates if comparison of alphabetical characters should be case-sensitive (by default false)
  * @param compareOnlyVersionNumber (in) If true then only version number are compared (pre-release tag and number are not taken into account) (by default false)
  *                                      Note: if beStrict and compareOnlyVersionNumber are both true then comparison results is 1 when version numbers are identical
  */
void fwInstallation_componentInstalled(string componentName,
                                       string requestedComponentVersion,
                                       int &result,
                                       string systemName = "",
                                       bool beStrict = false,
                                       bool caseSensitive = false,
                                       bool compareOnlyVersionNumber = false)
{
  if(systemName == ""){
    systemName = getSystemName();
  }
  if(!patternMatch("*:", systemName)){
    systemName += ":";
  }
  string dp = systemName + fwInstallation_getComponentDp(componentName);

  result = 0; // by default set to 0 (component not installed)
  if(dpExists(dp)){ // check whether the component data point exists - if it exists, it is installed
    string installedComponentVersion;
    dpGet(dp + ".componentVersionString:_original.._value", installedComponentVersion);
    result = _fwInstallation_CompareVersions(installedComponentVersion, requestedComponentVersion,
                                             beStrict, caseSensitive, compareOnlyVersionNumber);
  }
}

/** Displays information about component file issues in installed components table.
  * Note: UI function. Requires that the table shape "tblInstalledComponents" exists in a panel.
  * @param componentName (in)  Name of the component
  * @param isSubComponent (in)  Flag that indicates if component is a subcomponent
  */
void fwInstallation_showFileIssues(string componentName, bool isSubComponent)
{
  dyn_mapping filesIssues;
  fwInstallation_getComponentFilesIssues(componentName, filesIssues, true, true, false);

  int fileIssuesNum = dynlen(filesIssues);
  tblInstalledComponents.updateLine(1, "componentName", (isSubComponent?"_":"") + componentName,
                                       "filesIssuesCount", makeDynString(fileIssuesNum, (fileIssuesNum == 0)?"green":"yellow"),
                                       "filesIssues", (string)filesIssues);

  if (shapeExists("fileIssueFeedbackText") && shapeExists("fileIssueFeedbackArrow"))
  {
    fileIssueFeedbackArrow.visible = dynlen(filesIssues);
    fileIssueFeedbackText.visible = dynlen(filesIssues);

    fileIssueFeedbackText.text = "Component(s) have file issues.";
  }
}

/** this functions outputs the message into the log textarea of a panel
@param message: the message to be displayed
*/
fwInstallation_showMessage(dyn_string message)
{
  bool displayInUi = (myManType() == UI_MAN && shapeExists("list"));
  int msgLen = dynlen(message);
  for(int i=1;i<=msgLen;i++){
    fwInstallation_writeToMainLog(message[i], false);
    if(displayInUi){
      list.appendItem(message[i]);
    }
  }
  if(displayInUi){
    int listLen = list.itemCount();
    list.bottomPos(listLen);
    list.selectedPos(listLen);
  }
}

/** This function executes a script from the component .init file

@param componentInitFile: the .init file with the functions to be executed
@param iReturn: -1 if error calling the script, otherwise, it returns the error code of the user script
@author F. Varela
*/
fwInstallation_evalScriptFile(string componentInitFile , int &iReturn)
{
	string fileInString;
	anytype retVal;
	int result;

  if(access(componentInitFile, R_OK) != 0)
  {
    fwInstallation_throw("Execution of script: " + componentInitFile + " aborted as the file is not readable");
    iReturn = -1;
    return;
  }

	if (!fileToString(componentInitFile, fileInString))
	{
		fwInstallation_throw("fwInstallation: Cannot load " + componentInitFile);
		iReturn =  -1;
   return;
	}

  iReturn = evalScript(retVal, fileInString, makeDynString("$value:12345"));
  if(iReturn)
    return;

  iReturn = retVal; //Make iReturn equal to the error code returned by the user script

  return;
}

// Delimiter of main parts of component version sequence [versionNumber]-[preReleaseTag]-[preReleaseNumber] (e.g. 1.2.3-beta-4)
const string FW_INSTALLATION_COMPONENT_VERSION_PARTS_DELIMITER = "-";

/** Parse parts of componet version sequence ([versionNumber]-[preReleaseTag]-[preReleaseNumber]).
  * All parts are optional, however, if present, they must appear in the presented order. Any characters after third '-' delimiter are discarded.
  * @private Used in version comparison (_fwInstallation_CompareVersions())
  * @param versionString (in)  String containing component version sequence.
  * @param versionNumber (out)  Main version number (first part of component version sequence)
  * @param preReleaseTag (out)  Pre-release tag (second part of component version sequence)
  * @param preReleaseNumber (out)  Pre-release number (third part of component version sequence)
  */
private _fwInstallation_CompareVersions_parseVersionParts(string versionString, string &versionNumber, string &preReleaseTag, string &preReleaseNumber)
{
  versionNumber = "";
  preReleaseTag = "";
  preReleaseNumber = "";

  dyn_string versionParts = strsplit(versionString, FW_INSTALLATION_COMPONENT_VERSION_PARTS_DELIMITER);
  int versionPartsLen = dynlen(versionParts);
  if(versionPartsLen >= 1){ versionNumber = versionParts[1];
    if(versionPartsLen >= 2){ preReleaseTag = versionParts[2];
      if(versionPartsLen >= 3){ preReleaseNumber = versionParts[3];}
    }
  }
}

const string FW_INSTALLATION_COMPONENT_VERSION_NUMBERS_SEQUENCE_DELIMITER = "."; // Delimiter of version numbers sequence [major].[minor].[...]...
// Constants below are used in internal version comparison functions, they are not intended to use for comparison with returned values of _fwInstallation_CompareVersions() function.
const int FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER = 1; // Indicates that installed component version (first argument of interal version comparison functions) is higher than requested component version
const int FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER = 2; // Indicates that requested component version (second argument of interal version comparison functions) is higher than installed component version
const int FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL = 0;               // Indicates that both provided component versions are equal, must be lower than previus ones

/** Compares given parts of version strings as sequence of version number strings ([major].[minor].[...]...). Version number strings can contain non-numerical character.
  * @private Used in version comparison (_fwInstallation_CompareVersions())
  * @param instCompVersionNumber (in)  Part of version string of installed component
  * @param reqCompVersionNumber (in)  Part of version string of requested component
  * @return Integer value that indicates whether first or second argument contains higher version string.
  *         Following codes are possible: FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL
  */
private int _fwInstallation_CompareVersions_compareVersionNumbers(string instCompVersionNumber, string reqCompVersionNumber)
{
  // Split version number string into parts
  dyn_string instCompVersionNumberParts = strsplit(instCompVersionNumber, FW_INSTALLATION_COMPONENT_VERSION_NUMBERS_SEQUENCE_DELIMITER);
  dyn_string reqCompVersionNumberParts = strsplit(reqCompVersionNumber, FW_INSTALLATION_COMPONENT_VERSION_NUMBERS_SEQUENCE_DELIMITER);
  int instCompVersionNumberPartsLen = dynlen(instCompVersionNumberParts);
  int reqCompVersionNumberPartsLen = dynlen(reqCompVersionNumberParts);

  int commonPartsLen = (instCompVersionNumberPartsLen < reqCompVersionNumberPartsLen)?
                       instCompVersionNumberPartsLen:reqCompVersionNumberPartsLen;
  // Compare each part of the version number until difference is found or all parts of shorter list are checked
  for(int i=1;i<=commonPartsLen;i++)
  {
    int comparisonResult = _fwInstallation_CompareVersions_compareVersionNumberPart(instCompVersionNumberParts[i],
                                                                                    reqCompVersionNumberParts[i]);
    if(comparisonResult > FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL) return comparisonResult;
  }
  // If all common parts are equal, the one with more parts of version number is higher. If number of parts is equal then version numbers are equal.
  if(instCompVersionNumberPartsLen > commonPartsLen) return FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER;
  if(reqCompVersionNumberPartsLen > commonPartsLen) return FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER;
  return FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL;
}

/** Compares given strings containing particular number (string) eg. [major] from the sequence of version numbers strings ([major].[minor].[...]...)
  * @private Used in version comparison (_fwInstallation_CompareVersions_compareVersionNumbers())
  * @param instCompVersionNumberPart (in)  Single number from the sequence of version numbers of installed component version
  * @param reqCompVersionNumberPart (in)  Single number from the sequence of version numbers of required component version,
  *                                       must be on the same position in the sequence of version numbers as instCompVersionNumberPart
  * @return Integer value that indicates whether first or second argument contains higher number.
  *         Following codes are possible: FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL
  */
private int _fwInstallation_CompareVersions_compareVersionNumberPart(string instCompVersionNumberPart, string reqCompVersionNumberPart)
{
  // Parse number and modifier (if present) from the single "number" string of version numbers strings sequence,
  // eg. "1a" results in number=1 and modifier="a", "a" -> number=0 and modifier="a" (this way also alphabetic characters are handled in the version number)
  string installVerModifier, requestVerModifier;
  int installVerNumber = _fwInstallation_CompareVersions_parseNumberAndModifierString(instCompVersionNumberPart, installVerModifier);
  int requestVerNumber = _fwInstallation_CompareVersions_parseNumberAndModifierString(reqCompVersionNumberPart, requestVerModifier);
  // Compare numbers
  if(installVerNumber > requestVerNumber) return FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER;
  if(installVerNumber < requestVerNumber) return FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER;

  return _fwInstallation_CompareVersions_compareVersionStrings(installVerModifier, requestVerModifier);
}

/** Parses number (integer value) and modifier string (string of alphanumeric characters that appears after the integer value)
  * from given part of version numbers string sequence.
  * @private Used in version comparison (_fwInstallation_CompareVersions_compareVersionNumberPart())
  * @param versionNumberPart (in)  Part of the sequence of version numbers strings ([major].[minor].[...]...)
  * @param modifierString (out)  Modifier string for the retrieved numeric value.
  * @return Integer value retrieved from the first numeric characters of versionNumberPart.
  */
private int _fwInstallation_CompareVersions_parseNumberAndModifierString(string versionNumberPart, string &modifierString)
{
  int number;
  if(sscanf(versionNumberPart, "%d", number) > 0){
    string numberAsString;
    sprintf(numberAsString, "%d", number); // Format number back to string to get its position in versionNumberPart string
    int modifierStringPos = strpos(versionNumberPart, numberAsString) + strlen(numberAsString); // Find position of first character of modifier string
    modifierString = substr(versionNumberPart, modifierStringPos);
  }else{ // If versionNumberPart string does not begin with numeric character - asssuming that whole versionNumberPart string is modifier and integer number is 0.
    modifierString = versionNumberPart;
  }
  return number;
}

/** This function compares two version strings as a string of characters. Higher string is the one with character with higher ASCII code
  * on the first position that differs in both string. If one string is longer than the other and the common parts are equal then the longer string is higher.
  * An exception is a situation when one string is empty - then it is considered to be higher as string version should be used to indicate pre-release versions.
  * @private Used in version comparison (_fwInstallation_CompareVersions_compareVersionNumberPart(), _fwInstallation_CompareVersions())
  * @param instCompVersionString (in)  Part of installed component version identifier that should be compared as a string
  * @param reqCompVersionString (in)  Part of requested component version identifier corresponding to the same part of instCompVersionString
  * @return Integer value that indicates whether first or second argument contains higher string version.
  *         Following codes are possible: FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER, FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL
  */
private int _fwInstallation_CompareVersions_compareVersionStrings(string instCompVersionString, string reqCompVersionString)
{
  if(instCompVersionString == "" && reqCompVersionString == "") return FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL;
  if(instCompVersionString == "" && reqCompVersionString != "") return FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER;
  if(reqCompVersionString == "") return FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER;
  if(instCompVersionString > reqCompVersionString) return FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER;
  if(instCompVersionString < reqCompVersionString) return FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER;
  return FW_INSTALLATION_BOTH_VERSIONS_ARE_EQUAL;
}

/** This function compares two component versions.
  The following version format is supported: [versionNumber]-[preReleaseTag]-[preReleaseNumber] (e.g. 1.2.3-beta-4).
  preReleaseTag and preReleaseNumber are not mandatory and they are used for indicating the pre-release version of component (eg. beta).
  - preReleaseTags (second part of version format) are compared as a strings (string is higher when it has a character with higher ASCII code on the first position that differs in both strings).
  - versionNumbers and preReleaseNumbers are compared as a sequence of version numbers ([major].[minor].[...]...).
    Single part of the sequence (element) can contain number and a string modifier (eg. 10a -> number=10, modifier="a"). Numer contains all numerical chracter starting from the first position in element of a sequence.
    If at the first position is non-numerical character it is assumed that number has value of 0. Any characters that appears after the first non-numerical character are treated as a string modifier and they are compared as a string (so 1a10 < 1a9)
    hence next versions should not be indicated this way (for this pupose 'number' part should be used).
    If element contains modifier it is considered to be lower than the element that contains only the number (10a < 10) - it gives possibility to indicate pre-release version by the modifier (eg. 1.1beta)
  If version contain pre-release tags then it is lower than the version with the same versionNumber that does not have any pre-release tags (1.0.0-beta-1 < 1.0.0).
  @param installedComponentVersion (in) Version name as string of the installed component
  @param requestedComponentVersion (in) Required component version
  @param beStrict (in) If set to true, the comparison will required that both component versions as identical
  @param caseSensitive (in) Indicates if comparison of alphabetical characters should be case-sensitive (by default false)
  @param compareOnlyVersionNumber (in) If true then only version number are compared (pre-release tag and number are not taken into account) (by default false)
                                       Note: if beStrict and compareOnlyVersionNumber are both true then comparison results in 1 when version numbers are identical
  @return 1 if the requested component version is equal or older than the version installed (if beStrict=false), 0 otherwise
*/
int _fwInstallation_CompareVersions(string installedComponentVersion, string requestedComponentVersion, bool beStrict = false, bool caseSensitive = false, bool compareOnlyVersionNumber = false)
{
  if(!caseSensitive){ // Prepare for case-insensitive comparison
    installedComponentVersion = strtolower(installedComponentVersion);
    requestedComponentVersion = strtolower(requestedComponentVersion);
  }

  if(installedComponentVersion == requestedComponentVersion) // Skip detailed comparison if version strings are equal
    return 1;

  // Extract main parts of version string
  string instCompVersionNumber, instCompPreReleaseTag, instCompPreReleaseNumber;
  _fwInstallation_CompareVersions_parseVersionParts(installedComponentVersion, instCompVersionNumber,
                                                    instCompPreReleaseTag, instCompPreReleaseNumber);
  string reqCompVersionNumber, reqCompPreReleaseTag, reqCompPreReleaseNumber;
  _fwInstallation_CompareVersions_parseVersionParts(requestedComponentVersion, reqCompVersionNumber,
                                                    reqCompPreReleaseTag, reqCompPreReleaseNumber);
  // Compare version numbers
  int versionNumbersComparisonResult = _fwInstallation_CompareVersions_compareVersionNumbers(instCompVersionNumber, reqCompVersionNumber);
  if(versionNumbersComparisonResult == FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER) return beStrict?0:1;
  if(versionNumbersComparisonResult == FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER) return 0;

  // Version numbers are the same, if pre-release tags should be excluded from comparison then return 1 here
  if(compareOnlyVersionNumber) return 1;

  // Compare pre-release tags as a strings
  int preReleaseTagComparisonResult = _fwInstallation_CompareVersions_compareVersionStrings(instCompPreReleaseTag, reqCompPreReleaseTag);
  if(preReleaseTagComparisonResult == FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER) return beStrict?0:1;
  if(preReleaseTagComparisonResult == FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER) return 0;

  // Check if both version strings contains pre-release number
  if(instCompPreReleaseNumber == "" && reqCompPreReleaseNumber != "") return beStrict?0:1;
  if(instCompPreReleaseNumber != "" && reqCompPreReleaseNumber == "") return 0;
  // Compare pre-release numbers
  int preReleaseNumbersComparisonResult = _fwInstallation_CompareVersions_compareVersionNumbers(instCompPreReleaseNumber, reqCompPreReleaseNumber);
  if(preReleaseNumbersComparisonResult == FW_INSTALLATION_INSTALLED_COMPONENT_VERSION_IS_HIGHER) return beStrict?0:1;
  if(preReleaseNumbersComparisonResult == FW_INSTALLATION_REQUESTED_COMPONENT_VERSION_IS_HIGHER) return 0;
  //else - installed component version and requested component version are equal
  return 1;
}

/** this function deletes the component  files
@param componentFiles: the dyn_string with the names of the files to be deleted
@param installationDirectory: the name of the installation directory
@return 0 if OK, -1 if errors
@author M.Sliwinski and modified by F. Varela
*/

int fwInstallation_deleteFiles(const dyn_string &componentFiles, string installationDirectory)
{
  if(installationDirectory != ""){
  fwInstallation_normalizePath(installationDirectory, true);
  }

  bool err;
  int componentFilesLen = dynlen(componentFiles);
  for(int i=1;i<=componentFilesLen;i++){ // Deleting the files
    string fileToDelete = componentFiles[i];
    if(strpos(fileToDelete, "./") == 0){
      fileToDelete = substr(fileToDelete, 2);
    }
    string fileToDeletePath = installationDirectory + fileToDelete;
    if(!isfile(fileToDeletePath)){
      continue; // File does not exist, don't need to do anything
    }
    if(patternMatch(BIN_REL_PATH + "*", fileToDelete)){
      if(fwInstallation_uninstallBinaryFile(fileToDeletePath)){
        fwInstallation_showMessage(makeDynString("Could not uninstall binary file " + fileToDeletePath));
        err = true;
      }
    }else{
      if(remove(fileToDeletePath) != 0){
        if(_WIN32 && patternMatch("*.qch", fileToDelete)){
          fwInstallation_showMessage(makeDynString("Could not delete help file " + fileToDeletePath,
                                                   "Please close any programs that may use it (Qt Assistant, WinCC OA gedi) and remove it manually"));
          fwInstallation_throw("Could not delete Qt Help file: " + fileToDeletePath, "WARNING");
          fwInstallation_throw("Please close any programs that may use *.qch file (Qt Assistant, WinCC OA gedi) and remove it manually", "INFO");
        }else{
          fwInstallation_showMessage(makeDynString("Could not delete file " + fileToDeletePath));
          err = true;
        }
      }
    }
  }
  return err?-1:0;
}

/** Uninstalls binary file. On Linux it does the unlink. On Windows it attempts to remove file and if it fails then tries to move file to the project trash directory.
  * @param binaryFilePath (in)  Absolute path to the binary file.
  * @return 0 when binary file was uninstalled successfully, -1 in case of error.
  */
int fwInstallation_uninstallBinaryFile(string binaryFilePath){
  if(_UNIX){
    return system("/bin/unlink " + binaryFilePath);
  }
  // else _WIN32
  if(remove(binaryFilePath) == 0){
    return 0;
  } // removal failed - usually because file is in use
  if(fwInstallation_sendToTrash(binaryFilePath) == 0){
    fwInstallation_throw("File: " + binaryFilePath + " was moved to project trash (fwTrash). Can be manually removed when no longer in use.", "INFO");
    return 0;
  }
  return -1;
}

/** This function writes to the main log
  * @param message (in)  Message to be written in the main log
  * @param addTimestamp (in)  Flag that indicates if timestamp should be prepended to the message (default = true)
  */
void fwInstallation_writeToMainLog(string message, bool addTimestamp = true)
{
  fwInstallation_writeToLogFile(getPath(LOG_REL_PATH) + FW_INSTALLATION_LOG_FILE, message, addTimestamp);
}

/** Writes log message to given file.
  * @param logPath (in)  Path to the log file
  * @param message (in)  Message to be written in the given log file
  * @param addTimestamp (in)  Flag that indicates if timestamp should be prepended to the message (default = true)
  */
private void fwInstallation_writeToLogFile(string logPath, string message, bool addTimestamp = true)
{
  file logFile = fopen(logPath, "a");
  if(ferror(logFile) != 0){
    fwInstallation_throw("fwInstallation: Cannot write to LogFile " + logPath, "error", 4);
  }else{
    fprintf(logFile,"%s\n", (addTimestamp?fwInstallation_timestampString():"") + message);
  }
  fclose(logFile);
}

/** Returns current time in timestamp format.
  * @return Timestamp string
  */
string fwInstallation_timestampString()
{
  return formatTime("[%Y-%m-%d_%H:%M:%S] ", getCurrentTime());
}

/** This function retrieves the path from a full filename
@param filePath (in) full file name (basedir + filename)
@return path to the file
*/
string _fwInstallation_baseDir(string filePath)
{
  if(filePath == "")
    return "";

  string baseDir = dirName(filePath);
  if(baseDir == "//")
    return "/";

  return baseDir;
}

/** This function retrieves the name of a file from the full path to the file
@param filePath (in) full file name (basedir + filename)
@return filename as string
*/
string _fwInstallation_fileName(string filePath)
{
  return baseName(filePath);
}


/** This function puts the components to be installed in order in which they should be installed
The algorithm is similar to that used during deleting the components (see fwInstallation_putComponentsInOrder_Delete() function btn_ApplyDelete())

@param componentsNames: the names of the components to be installed
@param componentsVersions: the versions of components to be installed
@param componentFiles: the file names with the description of the components
@param componentFilesInOrder: the  file names with the description of the components

@author F. Varela and R. Gomez-Reino
*/
int fwInstallation_putComponentsInOrder_Install(dyn_string & componentsNames,
                                                dyn_string & componentsVersions,
                                                dyn_string & componentFiles,
                                                dyn_string & componentFilesInOrder)
{
  dyn_dyn_string dependecyMatrix;
  dyn_string componentsInOrder;
  dyn_string tempDynRequired;
  dyn_string componentSubComps;
  mapping componentToDependencies;

  for(int i = 1; i <= dynlen(componentFiles); i++)
  {
     componentFiles[i] = fwInstallationDBAgent_getComponentFile(componentFiles[i]);

     fwInstallation_readComponentRequirements(componentFiles[i], tempDynRequired);
     fwInstallation_readSubcomponents(componentFiles[i], componentSubComps);

     //put that each of the subcomponents has the same dependencies like its component
     //and in addition add that each component dependns on the subcomponents before it in the list
     dyn_string tempComponentSubComps = componentSubComps;
     for (int j=dynlen(componentSubComps); j >= 1; j--)
     {
       dynRemove(tempComponentSubComps, j);
       //if the subcomponent should be installed
       if (dynContains(componentsNames, componentSubComps[j]))
       {
         dyn_string currentDependencies;
         if (mappingHasKey(componentToDependencies, componentSubComps[j]))
         {
           currentDependencies = componentToDependencies[componentSubComps[j]];
         }
         dyn_string tmp = tempComponentSubComps;
         dynAppend(currentDependencies, tmp);
         tmp = tempDynRequired;
         dynAppend(currentDependencies, tmp);
         dynUnique(currentDependencies);
         componentToDependencies[componentSubComps[j]] = currentDependencies;
       }
     }

     // put implicit dependency of the component on the subcomponent
     for (int j=1; j <= dynlen(componentSubComps); j++)
     {
       //only if the subcomponents is going to be installed
       if (dynContains(componentsNames, componentSubComps[j]))
       {
         dynAppend(tempDynRequired, componentSubComps[j]);
       }
     }

     //add the dependencies to the mapping that will be used for building the dependency matrix
     if (mappingHasKey(componentToDependencies, componentsNames[i]))
     {
       dyn_string currentDependencies = componentToDependencies[componentsNames[i]];
       dynAppend(currentDependencies, tempDynRequired);
       dynUnique(currentDependencies);
       componentToDependencies[componentsNames[i]] = currentDependencies;
     }
     else
     {
       componentToDependencies[componentsNames[i]] = tempDynRequired;
     }

  }

  //build the dependency matrix
  dyn_string componentWithDependencies = mappingKeys(componentToDependencies);
  int k =1;
  for (int i=1; i<=dynlen(componentWithDependencies); i++)
  {
    int originalIndex = dynContains(componentsNames, componentWithDependencies[i]);
    if (originalIndex >= 0)
    {
      //if the component has dependencies
      if (dynlen(componentToDependencies[componentWithDependencies[i]]) > 0)
      {
        dependecyMatrix[k] = makeDynString(componentWithDependencies[i], componentFiles[originalIndex]);
        dynAppend(dependecyMatrix[k], componentToDependencies[componentWithDependencies[i]]);
        k++;
      }
      else
      {
        dynAppend(componentFilesInOrder,componentFiles[originalIndex]);
        dynAppend(componentsInOrder, componentWithDependencies[i]);
      }
    }
  }

  // +1 just make it different to fail first cyclic dependency test
  int lastDepMatrixSize = dynlen(dependecyMatrix) + 1;
  while (dynlen(dependecyMatrix)>0)
  {
    dyn_dyn_string remaningMatrix ;
    remaningMatrix = dependecyMatrix;
    for (int i=1;i<=dynlen(dependecyMatrix);i++)
    {
      bool skip = false;
      for (int j=3;j<=dynlen(dependecyMatrix[i]);j++)
      {
        string componentName, componentVersion;
        fwInstallation_parseRequiredComponentNameVersion(dependecyMatrix[i][j], componentName, componentVersion);

        if (!dynContains(componentsInOrder, componentName) &&
             dynContains(componentsNames, componentName))
        {
          skip = true;
        }
      }

      if(lastDepMatrixSize == dynlen(dependecyMatrix))
      {
        fwInstallation_throw("fwInstallation: cyclic dependency in components detected, aborting installation", "error", 10);
        fwInstallation_throw("Dumping list of components, that could not be put in order", "INFO");
        for(int j=1;j<=dynlen(dependecyMatrix);j++){
          string componentName = dependecyMatrix[j][1];
          string componentRequirements;
          for(int k=3;k<=dynlen(dependecyMatrix[j]);k++){
            componentRequirements += dependecyMatrix[j][k] + ", ";
          }
          fwInstallation_throw(componentName + " - requires: " + componentRequirements, "INFO");
        }
        return -1;
      }

      if(skip == false)
      {
          dynAppend(componentFilesInOrder,dependecyMatrix[i][2]);
          dynAppend(componentsInOrder,dependecyMatrix[i][1]);
          for(int g=dynlen(remaningMatrix);g>=1;g--)
          {
            if(remaningMatrix[g][1] == dependecyMatrix[i][1])
            {
              dynRemove(remaningMatrix,g);
            }
          }
      }
    }

    lastDepMatrixSize = dynlen(dependecyMatrix);
    dependecyMatrix = remaningMatrix;
  }

  fwInstallation_throw("Resulting list of components sorted for installation according to their dependencies: " +  componentsInOrder + ". Please wait...", "INFO");
  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    fwInstallationDB_storeInstallationLog();
  }

  return 0;
}

/** This function reads the requirements from the component description file

@param descFile (in) the file with the description of a component
@param dynRequiredComponents (out) the dyn_string of requiredComponents
@author M.Sliwinski
*/
fwInstallation_readComponentRequirements(string descFile, dyn_string & dynRequiredComponents)
{
	bool	fileLoaded;
	string strComponentFile;
	string tagName;
	string tagValue;
	int i;
        dyn_anytype attribs;
        dyn_string values;

	// clear the required components table
	dynClear(dynRequiredComponents);

	if(_WIN32)
	{
		strreplace(descFile, "/", "\\");
	}
	// load the description file into strComponentFile string
        if(fwInstallationXml_getTag(descFile, "required", dynRequiredComponents, attribs))
        {
          fwInstallation_throw("fwInstallation_readComponentRequirements() -> Cannot load " + descFile + " file ", "error", 4);
          return;
        }

}

/** This function reads the sub components from the component description file
@param descFile (in) the file with the description of a component
@param dynSubcomponents (out) the dyn_string of the subcomponents
*/
fwInstallation_readSubcomponents(string descFile, dyn_string & dynSubcomponents)
{
  dynClear(dynSubcomponents);
  fwInstallation_normalizePath(descFile);
  // load the description file into strComponentFile string
  dyn_string subcompFiles;
  dyn_anytype attribs;
  if(fwInstallationXml_getTag(descFile, "includeComponent", subcompFiles, attribs))
  {
    fwInstallation_throw("fwInstallation_readSubcomponents() -> Cannot load " + descFile + " file ", "error", 4);
    return;
  }

  string componentDirectory = fwInstallation_getComponentPath(descFile);
  dyn_string values;
  //read the names of the components
  for(int i=1;i<=dynlen(subcompFiles);i++)
  {
    strreplace(subcompFiles[i], "./", "/");
    dynClear(values);
    fwInstallationXml_getTag(componentDirectory + subcompFiles[i], "name", values, attribs);
    if(dynlen(values) > 0)
      dynAppend(dynSubcomponents, values[1]);
  }
}

/** This function resolves the Pmon Information (i.e. user name and password)
  @param user (out) user
  @param pwd (out) password
  @return 0 if OK, -1 if errors.
*/
int fwInstallation_getPmonInfo(string &user, string &pwd)
{
  dyn_float df;
  dyn_string ds;
  dyn_mixed projectProperties;
  int projectId;

  //Cache Segment
    bool isProjectRegisteredCache = false;
    string dbCacheProjectUser = "";
    string dbCacheProjectPassword = "";
    dyn_mixed dbProjectInfo;
    if( globalExists("gDbCache") && mappingHasKey(gDbCache, "dbProjectInfo") ) {
       dbProjectInfo = gDbCache["dbProjectInfo"];
       if( dynlen(dbProjectInfo) > 1 ) {
         isProjectRegisteredCache = true;
         dbCacheProjectUser = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_USER];
         dbCacheProjectPassword = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PWD];
       }
     }
  //End Cache segment


  //Check if password can be read from the DB
  if(gFwInstallationPmonUser != "N/A" && gFwInstallationPmonPwd != "N/A")   //nothing to be done. Globals have already been initialized
  {
    user = gFwInstallationPmonUser;
    pwd = gFwInstallationPmonPwd;
    return 0;
  }

  if(!fwInstallation_isPmonProtected())
  {
    //Nothing to be done; Return empty strings
    user = "";
    pwd = "";
  }
  else if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    if( isProjectRegisteredCache ) {
      user = dbCacheProjectUser;
      pwd = dbCacheProjectPassword;
    } else {
      if(fwInstallationDB_isProjectRegistered(projectId, PROJ, strtoupper(fwInstallation_getHostname())))
      {
        fwInstallation_throw("fwInstallation_getPmonInfo() -> Could not access the DB to read the PMON info. Failed to check if the project is registered in the System Configuration DB", "error", 7);
        gFwInstallationPmonUser = "N/A";
        gFwInstallationPmonPwd = "N/A";
        return -1;
      }
      else if(projectId == -1)
      {
        if(myManType() != UI_MAN)
        {
          fwInstallation_throw("fwInstallation_getPmonInfo() -> Project not yet registered in the DB. Cannot resolve the pmon parameters from the System Configuration DB", "warning", 10);
          gFwInstallationPmonUser = "N/A";
          gFwInstallationPmonPwd = "N/A";
          return -1;
        }
        else
        {
          fwInstallation_throw("Prompting user to enter PMON info", "INFO", 10);
          int err = fwInstallation_askForPmonInfo(user, pwd);
          gFwInstallationPmonUser = user;
          gFwInstallationPmonPwd = pwd;
          return err;
        }
      }
      else if(fwInstallationDB_getProjectProperties(PROJ, strtoupper(fwInstallation_getHostname()), projectProperties, projectId))
      {
        fwInstallation_throw("fwInstallation_getPmonInfo() -> Could not access the DB to read the PMON info", "error", 7);
        gFwInstallationPmonUser = "N/A";
        gFwInstallationPmonPwd = "N/A";
        return -1;
      }

      user = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
      pwd = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD];
     }
  }
  else if(myManType() == UI_MAN)
  {
    fwInstallation_askForPmonInfo(user, pwd);
  }
  else
  {
    fwInstallation_throw("Could not resolve pmon username/password");
    user = "N/A";
    pwd = "N/A";
    gFwInstallationPmonUser = "N/A";
    gFwInstallationPmonPwd = "N/A";
    return -1;
  }

  gFwInstallationPmonUser = user;
  gFwInstallationPmonPwd = pwd;

  return 0;
}

int fwInstallation_askForPmonInfo(string &user, string &pwd)
{
  dyn_string ds;
  dyn_float df;
  ChildPanelOnCentralReturn("fwInstallation/fwInstallation_pmon.pnl", "Username/Password required", makeDynString(""), df, ds);
  if(!dynlen(df) || df[1] != 1.)
  {
    user = "N/A";
    pwd = "N/A";
//    gFwInstallationPmonUser = "N/A";
//    gFwInstallationPmonPwd = "N/A";
    return -1;
  }
  else
  {
    user = ds[1];
    pwd = ds[2];
  }

  return 0;
}

/** This function forces the restart of the whole project
@author F. Varela
*/
int fwInstallation_forceProjectRestart()
{
  string host;
  int port;
  int iErr = paGetProjHostPort(paGetProjName(), host, port);
  string cmd;
  string user, pwd;
  string dpr = fwInstallation_getAgentRequestsDp();


  //Try to use first pmon without user and password and see if it fails:
  if(!fwInstallation_isPmonProtected())
  {
    cmd = "##RESTART_ALL:";
    if(!pmon_command(cmd, host, port, FALSE, TRUE))
    {
      fwInstallation_throw("FW Installation Tool forcing project restart now. Please, wait...", "INFO", 10);
      //Project successfully restarted. We are done
      return 0;
    }
  }

  //Pmon does have a username and password. Try to resolve them on the fly.
  fwInstallation_getPmonInfo(user, pwd);
  cmd = user + "#" + pwd + "#" + "RESTART_ALL:";

  paVerifyPassword(PROJ, user, pwd, iErr);
  if(iErr)
  {
    fwInstallation_throw("Invalid Pmon Username/Password. Cannot restart the project", "WARNING", 6);
    return -1;
  }
  if(pmon_command(cmd, host, port, FALSE, TRUE))
  {
    fwInstallation_throw("Cannot restart the project", "WARNING");
    return -1;
  }

  fwInstallation_throw("FW Installation Tool forcing project restart", "INFO", 10);
  return 0;
}


/** This function resolves the source path from the component description file
  @param componentFile (out) full path to the XML file of the component
  @return source directory
*/
string fwInstallation_getComponentPath(string componentFile)
{
  return _fwInstallation_baseDir(componentFile);
}

/** This function retrieves whether the component can be registered only
    or if all component files have to be copied during installation
  @param destinationDir (in) target directory for installation.
                         Note that a previous installtion of the component may exist in there.
  @param componentName (in) name of the component being installed
  @param forceOverwriteFiles (in) flag to force overwriting of existing files
  @param isSilent (in) flag to specify if the installation is silent (no windows will be pop up even during interactive installation)
  @return 1 when component can only be registered, without copying files,
          0 when component files have to be copied to the target directory during instalation,
         -1 when component installation is aborted (user request)
*/
int fwInstallation_getRegisterOnly(string destinationDir,
                                   string componentName,
                                   bool forceOverwriteFiles,
                                   bool isSilent)
{
  const int REGISTER_ONLY = 1, COPY_FILES = 0, USER_ABORT = -1;
  string installedVersion;
  bool areComponentFilesInTargetDir = (fwInstallation_checkTargetDirectory(destinationDir, componentName, installedVersion) == 1);

  if(fwInstallationDB_getUseDB() && fwInstallationDB_getCentrallyManaged() && !forceOverwriteFiles && areComponentFilesInTargetDir){
    fwInstallation_throw("fwInstallation_getRegisterOnly() -> Registering component " + componentName + " only. Not copying files...", "INFO");
    return REGISTER_ONLY;
  }
  if(!gFwYesToAll && areComponentFilesInTargetDir && !forceOverwriteFiles){
    if(!isSilent && myManType() == UI_MAN){
      switch(fwInstallation_overwriteComponentFilesDialog(componentName, installedVersion)){
        case 0:
          fwInstallation_throw("fwInstallation_getRegisterOnly() -> Registering component " + componentName + " only. Not copying files...", "INFO");
          return REGISTER_ONLY;
        case 1:
          fwInstallation_throw("fwInstallation_getRegisterOnly() -> Overwriting files of component " + componentName + " in directory " + destinationDir, "INFO");
          return COPY_FILES;
        default:
          fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installation of " + componentName + " aborted by the user.", "INFO");
          return USER_ABORT;
      }
    }
    fwInstallation_throw("fwInstallation_getRegisterOnly() -> Registering component " + componentName + " only. Not copying files...", "INFO");
    return REGISTER_ONLY;
  }

  dyn_anytype componentProperties;
  int retVal = fwInstallation_getComponentInfo(componentName, "installationdirectory", componentProperties);
  if(retVal != 0 || dynlen(componentProperties) < 1){
    return COPY_FILES; // Component not installed - copy files to installation directory
  }

  string previousDir = componentProperties[1];
  fwInstallation_normalizePath(previousDir);
  fwInstallation_normalizePath(destinationDir);
  if(destinationDir != previousDir){
    fwInstallation_throw("fwInstallation_getRegisterOnly() -> Component " + componentName + " was previously installed in: " + previousDir +
                         ". Now it will be installed in a different path: " + destinationDir, "INFO");
    if(!gFwYesToAll && !isSilent && myManType() == UI_MAN){
      if(fwInstallation_acceptComponentInstallationPathChangeDialog(componentName, installedVersion) != 1){
        fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installation of " + componentName + " in a new directory aborted by the user.", "INFO");
        return USER_ABORT;
      }
      fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installing component " + componentName + " in a new directory: " + destinationDir, "INFO");
    }
  }
  fwInstallation_throw("fwInstallation_getRegisterOnly() -> Overwriting files of component " + componentName + " in directory " + destinationDir, "INFO");
  return COPY_FILES;
}

/** Asks user in a dialog window whether to overwrite existing component files in a destination directory and returns its choice.
  @param componentName (in)  Name of the component being installed
  @param installedVersion (in)  Version of component that currently exists in destination directory
  @return 0 when user selected not to overwrite the existing component files,
          1 when user allowed to overwrite current component files,
         -1 when user decided to abort component installation.
  */
private int fwInstallation_overwriteComponentFilesDialog(string componentName, string installedVersion)
{
  dyn_string ds;
  dyn_float df;
  ChildPanelOnCentralReturn("fwInstallation/fwInstallation_messageInfo3", "Warning", makeDynString("$1:Version " + installedVersion + " of \"" +
                            componentName + "\" \nalready exists in the destination directory.\n\nDo you want to overwrite the files?"), df, ds);
  if(dynlen(df) < 1 || df[1] < 0.){ // Error? or Cancel
    return -1;
  }
  if(df[1] == 0.){ // No
    return 0;
  }
  if(df[1] != 1.){ // Yes to All
    gFwYesToAll = true;
  }
  return 1; // Yes | Yes to All
}

/** Asks user in a dialog window whether to install component in a different directory, than the one, where previous version of this component was installed.
  @param componentName (in)  Name of the component being installed
  @param installedVersion (in)  Version of component currently installed
          1 when user selected to proceed with installation in a different directory,
         -1 when user decided to abort component installation.
*/
private int fwInstallation_acceptComponentInstallationPathChangeDialog(string componentName, string installedVersion)
{
  dyn_string ds;
  dyn_float df;
  ChildPanelOnCentralReturn("fwInstallation/fwInstallation_messageInfo3", "Warning", makeDynString("$1:Version " + installedVersion + " of \"" +
                            componentName + "\" component \nwas previously installed in a different path.\n\nDo you want to proceed?"), df, ds);
  if(dynlen(df) < 1 || df[1] <= 0.){ // Error? | Cancel | No
    return -1;
  }
  if(df[1] != 1.){ // Yes to All
    gFwYesToAll = true;
  }
  return 1; // Yes | Yes to All
}

/** This function forces all required components to be installed prior to the installation of a given component if available in the distribution
 @param componentName (in) name of the component being installed
 @param dynRequiredComponents (in) array of required components
 @param sourceDir (in) source directory for installation
 @param forceInstallRequired (in) flag to force installation of required components
 @param forceOverwriteFiles (in) flag to force all existing files to be overwritten
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @param requiredInstalled (out) returned argument indicating if the required components have been successfully installed or not
 @param actionAborted (out) flag that indicates if the action was aborted by the user
 @return 0 if OK, -1 if errors
*/
int fwInstallation_installRequiredComponents(string componentName,
                                             dyn_string dynRequiredComponents,
                                             string sourceDir,
                                             bool forceInstallRequired,
                                             bool forceOverwriteFiles,
                                             bool isSilent,
                                             int & requiredInstalled,
                                             bool &actionAborted)
{
  string strNotInstalledNames = "";
  dyn_string dsNotInstalledComponents, dsFileComponentName, dsFileComponentVersion, dsFileComponent;
  dyn_string dreturns;
  dyn_string dreturnf;
  string componentDirPath;

  actionAborted = false;

  fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynRequiredComponents, strNotInstalledNames);

  // show the panel that asks if it should be installed
  if(strNotInstalledNames == ""){
    return 0; // There is no missing required components to be installed, exit.
  }
  fwInstallation_throw("Missing at installation of "+componentName+ ": " + strNotInstalledNames, "info", 10);

  //If all components are available proceed with the installation otherwise cancel installation of dependent components by claering the arrays
  dsNotInstalledComponents = strsplit(strNotInstalledNames, "|");
  fwInstallation_checkDistribution(sourceDir, dsNotInstalledComponents, dsFileComponentName, dsFileComponentVersion, dsFileComponent);

  //FVR: Check the forceInstallRequired flag is not set:
  if(!forceInstallRequired){
    // show the panel informing the user about broken dependencies
    if(myManType() == UI_MAN){
      ChildPanelOnCentralReturn("fwInstallation/fwInstallationDependency.pnl", "Dependencies of " + componentName,
                          makeDynString("$strDependentNames:" + strNotInstalledNames , "$componentName:" + componentName,
                                        "$fileComponentName:" + strjoin(dsFileComponentName, "|"),
                                        "$fileComponentVersion:" + strjoin(dsFileComponentVersion, "|")),
                          dreturnf, dreturns);
    }else{
      dreturns[1] = "Install_Delete"; //Force installation of this component
    }

    // check the return value
    if(dreturns[1] == "Install_Delete"){
      requiredInstalled = false;
      fwInstallation_showMessage(makeDynString("User choice at installation of "+componentName+": INSTALL"));
    }else if(dreturns[1] == "InstallAll_DeleteAll"){
      forceInstallRequired = true; //FVR: 30/03/2006: Install all required components
    }else if(dreturns[1] == "DoNotInstall_DoNotDelete"){
      fwInstallation_showMessage(makeDynString("User choice at installation of "+componentName+": ABORT"));
      actionAborted = true;
      return gFwInstallationOK;
    }
  }

  //Check if flag is still false -> Need of another if since the value of the flag could have changed in the previous loop
  if(!forceInstallRequired){
    return 0;
  }
  int dsFileComponentNameLen = dynlen(dsFileComponentName);
  //update number of components with added required components (don't count these ones for which there is no XML file - not available or version lower than required)
  fwInstallation_reportUpdateTotalComponentsNumber(dsFileComponentNameLen - dynCount(dsFileComponent, ""));

  for(int i=1;i<=dsFileComponentNameLen;i++)
  {
    if(dsFileComponent[i] == ""){ // No XML - skip required component
      continue;
    }
    string requiredComponentName = dsFileComponentName[i];
    string requiredComponentVersion = dsFileComponentVersion[i];
    string requiredComponentPath = dsFileComponent[i];

    if(fwInstallation_trackDependency_register(componentName, requiredComponentName) != 0){
      fwInstallation_throw("Detected circular dependency while installing components, triggering another installation of: " + requiredComponentName + " aborted", "ERROR");
      return gFwInstallationError;
    }
    fwInstallation_reportComponentInstallationProgress(requiredComponentName, FW_INSTALLATION_REPORT_STEP_STARTING_INSTALLATION);

    componentDirPath = fwInstallation_getComponentPath(requiredComponentPath);
    string componentSubPath = substr(componentDirPath, strlen(sourceDir));
    bool componentInstalled = false;
    string dontRestartProject = "no";
    bool isSubcomponent = false;
    fwInstallation_isSubComponent(requiredComponentPath, isSubcomponent);
    fwInstallation_throw("Forcing installation of the required component: " + requiredComponentName + " v." + requiredComponentVersion, "INFO");
    if(fwInstallation_installComponent(requiredComponentPath,
                                       sourceDir,
                                       isSubcomponent,
                                       requiredComponentName,
                                       componentInstalled,
                                       dontRestartProject,
                                       componentSubPath,
                                       forceInstallRequired,
                                       forceOverwriteFiles,
                                       isSilent) == gFwInstallationError && isSilent)
    {
      // + report installation status (success/error)
      if(requiredComponentName != ""){
        fwInstallation_reportComponentInstallationFinished(requiredComponentName);
      }

      fwInstallation_showMessage(makeDynString("ERROR: Silent installation failed installing dependent component: " + componentName));
      fwInstallation_throw("Silent installation failed installing dependent component: " + componentName);

      fwInstallation_setComponentInstallationStatus(requiredComponentName, false);
      return gFwInstallationError;
    }
    if(requiredComponentName != ""){
      fwInstallation_reportComponentInstallationFinished(requiredComponentName);
    }
  } // end check the component dependencies
  return 0;
}

/** This function verifies if destination (installation) directory is writeable and if files in the component package are accessible.
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param destinationDir (in) target directory for installation
 @param dynFileNames (in) component files
 @param dynBinFiles (in) component binary files
 @param registerOnly (in) flag indicating whether file copying can be avoided or not if the files already exist
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @param actionAborted (out) flag that indicates if the action was aborted by the user
 @return 0 if OK, -1 if error
*/
int fwInstallation_verifyDestinationDirAndSourceFiles(string componentName,
                                                      string sourceDir,
                                                      string subPath,
                                                      string destinationDir,
                                                      const dyn_string &dynFileNames,
                                                      const dyn_string &dynBinFiles,
                                                      bool registerOnly,
                                                      int isSilent,
                                                      bool &actionAborted){
  actionAborted = false;
  dyn_string strErrors;

  // Check if destination directory is writeable
  if(access(destinationDir, W_OK) != 0 && !registerOnly)
  {
    string strError = "The folder " + destinationDir + " is not write enabled";
    dynAppend(strErrors, strError);
    fwInstallation_throw("fwInstallation: " + strError);
  }

  // Check if source files are accessible
  int dynFileNamesLen = dynlen(dynFileNames);
  for(int i=1;i<=dynFileNamesLen;i++)
  {
    string filePath = sourceDir + subPath + "/" + dynFileNames[i];
    if(access(filePath, R_OK) != 0)
    {
      string strError = "The file " + filePath + " does not exist";
      dynAppend(strErrors, strError);
      fwInstallation_throw(strError, "WARNING", 3);
    }
  }

  // Check if binary source files are accessible
  int dynBinFilesLen = dynlen(dynBinFiles);
  for(int i=1;i<=dynBinFilesLen;i++)
  {
    string binFilePath = sourceDir + subPath + "/" + dynBinFiles[i];
    if(access(binFilePath, R_OK) != 0)
    {
      string strError = "The binary file " + binFilePath + " does not exist";
      dynAppend(strErrors, strError);
      fwInstallation_throw(strError, "WARNING", 3);
    }
  }

  int errorCounter = dynlen(strErrors);
  if(errorCounter!=0)
  {
    if(!isSilent)
    {
      dyn_string dreturns;
      dyn_float dreturnf;

      if(myManType() == UI_MAN )
      {
        ChildPanelOnCentralReturn("fwInstallation/fwInstallationShowErrors.pnl", "Installation Errors",
                                  makeDynString("$strErrors:" + strErrors , "$componentName:" + componentName), dreturnf, dreturns);
      }
      else
        dreturns[1] = "Install_Delete";

      // check the return value
      if(dreturns[1] == "Install_Delete")
      {
        fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Installation of "+componentName+" will continue on user request", "WARNING", 10);
        return gFwInstallationError;
      }
      else if(dreturns[1] == "DoNotInstall_DoNotDelete")
      {
        fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Installation of "+componentName+" is aborted", "INFO");
        actionAborted = true;
        return gFwInstallationOK;
      }
    }
    else
    {
      fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Silent installation of "+componentName+" is aborted");
      actionAborted = true;
      return gFwInstallationError;
    }
  }
  return 0;
}

/** This function copies all component files
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param destinationDir (in) target directory for installation
 @param dynFileNames (in) component files
 @param registerOnly (in) flag indicating whether file copying can be avoided or not if the files already exist
 @return 0 if OK, -1 if error
*/
int fwInstallation_copyComponentFiles(string componentName,
                                      string sourceDir,
                                      string subPath,
                                      string destinationDir,
                                      const dyn_string &dynFileNames,
                                      bool registerOnly)
{
  int dynFileNamesLen = dynlen(dynFileNames);
  if(dynFileNamesLen == 0){
    return 0; // No files to be copied
  }

  string componentSourceDir = sourceDir + subPath;
  fwInstallation_normalizePath(componentSourceDir, true);
  fwInstallation_normalizePath(destinationDir, true);
  if(componentSourceDir == destinationDir){
    fwInstallation_throw("Destination directory: " + destinationDir + " is the same as component source directory, no need to copy files", "INFO", 10);
    return 0;
  }
  if(registerOnly){
    fwInstallation_throw("RegisterOnly mode active. Copying of component files is skipped", "INFO", 10);
    return 0;
  }
  fwInstallation_showMessage(makeDynString("Copying files ...."));

  for(int i=1;i<=dynFileNamesLen;i++){
    string fileToCopy = dynFileNames[i];
    fwInstallation_normalizePath(fileToCopy);
    if(strpos(fileToCopy, "./") == 0){
      fileToCopy = substr(fileToCopy, 2);
    }
    string sourceFileAbsolutePath = componentSourceDir + fileToCopy;
    string targetFileAbsolutePath = destinationDir + fileToCopy;
    if(fwInstallation_copyFile(sourceFileAbsolutePath, targetFileAbsolutePath) != 0){
      fwInstallation_throw("Error copying file - source: " + sourceFileAbsolutePath + " destination: " + targetFileAbsolutePath, "error", 4);
      fwInstallation_showMessage(makeDynString("Error copying file: " + fileToCopy));
      return -1;
    }
  }
  return 0;
}

/** Returns the shell command to execute the WCCOAascii manager to import given dpl file.
  * @param inputFile (in)  Path to the input dpl file
  * @param extraOptions (in)  List of additional WCCOAascii manager command line options (default - empty)
  * @param stdoutFile (in)  Path to the file where to redirect standard output stream. If empty (default) then stdout is not redirected to the file.
  * @param stderrFile (in)  Path to the file where to redirect standard error stream. If empty (default) then stderr is not redirected to the file.
  */
string fwInstallation_getImportAsciiManagerCommand(string inputFile, dyn_string extraOptions = makeDynString(), string stdoutFile = "", string stderrFile = "")
{
  const string asciiManagerPath = PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ascii");
  const string setInputFile = " -in " + inputFile;
  const string extraOptionsString = strjoin(extraOptions, " ");
  const string redirChar = ">>";
  string streamRedirString;
  if(stdoutFile != ""){
    streamRedirString += " " + redirChar + " " + stdoutFile;
  }
  if(stderrFile != ""){
    streamRedirString += " 2" + redirChar + " " + stderrFile;
  }
  if(streamRedirString != "" && stdoutFile == stderrFile){ // write to the same file, exclude case when both file paths are empty
    streamRedirString += " " + redirChar + " " + stdoutFile + " 2>&1";
  }
  return asciiManagerPath + setInputFile + (extraOptionsString != ""?(" " + extraOptionsString):"") +
      streamRedirString;
}

const string FW_INSTALLATION_QUOTATION_MARK_CHAR = "\"";

/** Returns the given path with qoutation marks added at the beggining and end.
  * @param path (in)  Path
  * @return Path with quotation marks (eg. "/opt/New Folder/file")
  */
private string fwInstallation_getPathWithinQuotationMarks(const string &path)
{
  return FW_INSTALLATION_QUOTATION_MARK_CHAR + path + FW_INSTALLATION_QUOTATION_MARK_CHAR;
}

/** Checks if given path contains space character.
  * @param path (in)  Path to be checked
  * @return true if path contains space, false if not
  */
private bool fwInstallation_doesPathContainSpace(const string &path)
{
  return (strpos(path, " ") >= 0);
}

/** Performs ASCII import of a component single dpl file.
  * @param componentName (in)  Name of the component
  * @param dplFilePath (in)  Path to the dpl file to import
  * @param asciiImportCmd (in)  Command to call ASCII manager, it must have embedded "%s" format specifier to be replaced by dplFilePath
  * @param updateTypes (in) flag to indicate if existing types have to be updated (true - default) or not
  * @param isSilent (in) Flag to indicate if installation is performed in silent mode (true - default) or in interactive mode
  */
private int fwInstallation_importComponentSingleAsciiFile(string componentName,
                                                          string dplFilePath,
                                                          string asciiImportCmd,
                                                          bool updateTypes = true,
                                                          bool isSilent = true)
{
  if(fwInstallation_doesPathContainSpace(dplFilePath)){
    dplFilePath = fwInstallation_getPathWithinQuotationMarks(dplFilePath);
  }

  if(dplFilePath == "" || strreplace(asciiImportCmd, "%s", dplFilePath) != 1){
    fwInstallation_throw("fwInstallation_importComponentAsciiFiles() -> Failed to prepare command to import ASCII file: " +
                         dplFilePath + " of component " + componentName + ". Installation failed");

    fwInstallation_setComponentInstallationStatus(componentName, false);
    return gFwInstallationError;
  }

  fwInstallation_throw("Calling ASCII manager with" + (!updateTypes?"out":"") + " DP-Type update option", "INFO", 10);
  int err = system(asciiImportCmd);
  if(_UNIX && err > 128){ // Needed to get proper WCCOAascii error code from exit code.
    err -= 256; // On Linux exit code is truncated to 8 bits so WCCOAascii exit code in case of negative error code is equal to 256 + <negative_error_code>
  } // For more information see: https://unix.stackexchange.com/questions/418784/what-is-the-min-and-max-values-of-exit-codes-in-linux

  int importStatus;
  if(err > 0){
    fwInstallation_throw("code = " + err + ", when importing " + dplFilePath + " file of component " + componentName, "WARNING", 30);
    string infoMessage;
    switch(err){
      case 55:
        infoMessage = "ASCII warning 55: DP already defined with different ID. Typically safe to ignore. " +
                      "Installation will proceed...";
        break;
      case 56:
        infoMessage = "ASCII warning 56: Duplicated DP ID. Different one will be used. Typically safe to ignore. " +
                      "Installation will proceed...";
        break;
      default:
        infoMessage = "Please consult WinCC OA help on WCCOAascii to check the meaning of code " + err + ". " +
                      "Installation will proceed anyway...";
    }
    fwInstallation_throw(infoMessage + "\n-----------------------------------", "INFO");
  }else if(err < 0){
    fwInstallation_throw("code = " + err + ", when importing " + dplFilePath + " file of component " + componentName + " ", "ERROR", 29);
    if(!isSilent && myManType() == UI_MAN){ // Interactive - popup asking user if wants to continue
      dyn_string ds;
      dyn_float df;
      ChildPanelOnCentralReturn("fwInstallation/fwInstallation_messageInfo.pnl", "ASCII import error",
                                makeDynString("$text:ASCII import of file: " + dplFilePath + " finished with error code: " +
                                              err + ".\nTo abort installation of " + componentName + " component press Cancel. " +
                                              "If you are convinced to continue installation anyway, press OK",
                                              "$icon:WARNING"), df, ds);
      if(dynlen(ds) > 0 && ds[1] == "OK"){
        fwInstallation_throw("User has chosen to continue installation of (" + componentName + ") despite of ASCII import error (" +
                             err + "). Installation will proceed...\n-----------------------------------", "INFO");
        importStatus = 1;
      }else{
        fwInstallation_throw("User has chosen to abort installation of component: " + componentName + " due to ASCII import error (" +
                             err + ")\n-----------------------------------", "INFO");
        importStatus = -1;
      }
    }else{ // Silent - continue, but show info in log in case of negative code - to keep previous behavior
      fwInstallation_throw("Installation of " + componentName + " will proceed despite of ASCII import error (" + err + ") - " +
                           "default behavior when installing in silent or headless mode\n-----------------------------------", "INFO");
      importStatus = 1;
    }
  }
  dyn_string logMessages = makeDynString("ASCII import of file " + _fwInstallation_fileName(dplFilePath) + " is finished ");
  if(err==0){
    logMessages[1] += "successfully";
  }else{
    logMessages[1] += "with status code: " + (string)err;
    logMessages[2] = "Details can be found in ASCII import log: " + fwInstallation_getAsciiImportLogFilePath();
  }
  fwInstallation_showMessage(logMessages);

  return importStatus;
}

/** This function imports the dpl files of a component
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynDplistFiles (in) list of dpl files to be imported
 @param updateTypes (in) flag to indicate if existing types have to be updated (true - default) or not
 @param isSilent (in) Flag to indicate if installation is performed in silent mode (true - default) or in interactive mode
 @return 0 if OK, -1 if error
*/
int fwInstallation_importComponentAsciiFiles(string componentName,
                                             string sourceDir,
                                             string subPath,
                                             dyn_string dynDpListFiles,
                                             bool updateTypes = true,
                                             bool isSilent = true)
{
  const string host = fwInstallation_getHostname();

  dyn_string asciiImportOptions = makeDynString(
      "-event " + host + ":" + (string)eventPort(),
      "-data " + host + ":" + (string)dataPort(),
      "-log +stderr", // print output to the stderr
      "-log -file" // don't write output to the log file
      );

  // "-yes" - confirm that DP-types can be updated if necessary during ASCII import
  if(updateTypes){
    const string confirmDpTypesUpdate = "-yes";
    dynAppend(asciiImportOptions, confirmDpTypesUpdate);
  }

  // "-commit N" - command line option that indicates how many messages the ASCII Man waits for a reply from the Event Man
  if(_WIN32){
    const string setCommitCntOnWin32 = "-commit 10"; // Set "commit" option to 10 messages on Windows (on Linux this is 10 by default - doesn't have to be specified)
    dynAppend(asciiImportOptions, setCommitCntOnWin32);
  }

  const string fileNameToSubstitute = "%s";
  const string asciiLogFile = fwInstallation_getAsciiImportLogFilePath();
  string commandFormat = fwInstallation_getImportAsciiManagerCommand(fileNameToSubstitute, asciiImportOptions,
                                                                     asciiLogFile, asciiLogFile);

  int dynDpListFilesLen = dynlen(dynDpListFiles);
  for(int i=1;i<=dynDpListFilesLen;i++){
    string dpListFile = dynDpListFiles[i];
    if(dpListFile == ""){
      fwInstallation_throw("fwInstallation_importComponentAsciiFiles() -> Empty ASCII file name passed for component: " +
                           componentName + ". Installation failed");
      fwInstallation_setComponentInstallationStatus(componentName, false);
      return gFwInstallationError;
    }
    if(fwInstallation_ensureAsciiImportLogFileSizeLimit() != 0){
      return -1;
    }

    fwInstallation_throw("Importing dplist file: " + dpListFile + " of component: " + componentName, "INFO");

    string dpListFilePath = sourceDir + "/" + subPath + "/" + strltrim(dpListFile, ".");
    fwInstallation_normalizePath(dpListFilePath);

    if(fwInstallation_importComponentSingleAsciiFile(componentName, dpListFilePath, commandFormat,
                                                     updateTypes, isSilent) < 0){
      return -1;
    }
  }
  return 0;
}

/** Returns the path to the component installation ASCII import log file
  * @return Absolute path to ASCII import log file
  */
string fwInstallation_getAsciiImportLogFilePath(){
  return (getPath(LOG_REL_PATH) + fwInstallation_getAsciiImportLogFileName());
}

/** Ensures that component installation ASCII import log file does not exceeds defined maximum size.
  * If the current log size is above the limit, it moves the log to .bak file.
  * This function should be called before starting new ASCII import, that writes to the log file.
  * @return 0 if ensured that log size is below the limit, -1 if not (could not move log file that exceeded the limit)
  */
int fwInstallation_ensureAsciiImportLogFileSizeLimit(){
  const string asciiLogFilePath = fwInstallation_getAsciiImportLogFilePath();
  const int asciiLogRotationSizeMB = fwInstallation_getAsciiImportLogRotationSize();
  if(asciiLogRotationSizeMB != FW_INSTALLATION_ASCII_IMPORT_LOG_OVERWRITE_NEVER &&
     access(asciiLogFilePath, F_OK) == 0 && getFileSize(asciiLogFilePath) / 1e6 > asciiLogRotationSizeMB){
    if(fwInstallation_moveFile(asciiLogFilePath, asciiLogFilePath + ".bak", true) != 0){
      fwInstallation_throw("ASCII import log size exceeded the limit (" + asciiLogRotationSizeMB +
                           " MB), but unable to rename " + asciiLogFilePath, "ERROR");
      return -1;
    }
    fwInstallation_throw("ASCII import log size exceeded the limit (" + asciiLogRotationSizeMB +
                         " MB). Renamed the log file " + asciiLogFilePath, "INFO");
  }
  return 0;
}

/** Retrieves the component installation ASCII import log file name from internal dp.
  * If it cannot be retrieved or dpe is empty, then default log file name is returned
  * @return Component installation ASCII import log file
  */
private string fwInstallation_getAsciiImportLogFileName(){
  string asciiImportLogFileName;
  if(dpGet(fwInstallation_getInstallationDp() + ".asciiImportLogSettings.fileName", asciiImportLogFileName) != 0){
    fwInstallation_throw("Could not retrieve the ASCII import log file name from internal setting dp, default will be used: " +
                         FW_INSTALLATION_ASCII_IMPORT_LOG_FILE_NAME_DEFAULT, "WARNING");
    asciiImportLogFileName = "";
  }
  if(asciiImportLogFileName == ""){
    return FW_INSTALLATION_ASCII_IMPORT_LOG_FILE_NAME_DEFAULT;
  }
  return asciiImportLogFileName;
}

/** Retrieves the component installation ASCII import log file rotation size from internal dp.
  * If it cannot be retrieved or dpe is empty, then default log file rotation size is returned
  * @return Component installation ASCII import log rotation size
  */
private int fwInstallation_getAsciiImportLogRotationSize(){
  int asciiImportLogRotationSize = FW_INSTALLATION_ASCII_IMPORT_LOG_SIZE_INVALID;
  if(dpGet(fwInstallation_getInstallationDp() + ".asciiImportLogSettings.rotationSize", asciiImportLogRotationSize) != 0){
    fwInstallation_throw("Could not retrieve the ASCII import log rotation size from internal setting dp, default will be used: " +
                         FW_INSTALLATION_ASCII_IMPORT_LOG_ROTATION_SIZE_DEFAULT, "WARNING");
    asciiImportLogRotationSize = FW_INSTALLATION_ASCII_IMPORT_LOG_SIZE_INVALID;
  }
  if(asciiImportLogRotationSize <= FW_INSTALLATION_ASCII_IMPORT_LOG_SIZE_INVALID){
    return FW_INSTALLATION_ASCII_IMPORT_LOG_ROTATION_SIZE_DEFAULT;
  }
  return asciiImportLogRotationSize;
}

const string FW_INSTALLATION_REDU_CONFIG_FILE_EXT = ".redu";

/** This function imports the config files of a component.
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynConfigFiles_general (in) list of config files to be imported
 @param dynConfigFiles_linux (in) list of config files to be imported (linux only)
 @param dynConfigFiles_windows (in) list of config files to be imported (windows only)
 @return 0 if OK, -1 if error
*/
int fwInstallation_importConfigFiles(string componentName,
                                     string sourceDir,
                                     string subPath,
                                     dyn_string dynConfigFiles_general,
                                     dyn_string dynConfigFiles_linux,
                                     dyn_string dynConfigFiles_windows)
{
  // First remove all existing entries of this component from project config file
  _fwInstallation_DeleteComponentFromConfig(componentName);
  if(fwInstallationRedu_isRedundant()){
    _fwInstallation_DeleteComponentFromConfig(componentName, true);
  }

  // Then add config entries provided by the version of component that is being installed
  if(_WIN32){
    fwInstallation_importConfigFilesOfType(componentName, sourceDir, subPath, dynConfigFiles_windows, "windows");
  }else{
    fwInstallation_importConfigFilesOfType(componentName, sourceDir, subPath, dynConfigFiles_linux, "linux");
  }
  fwInstallation_importConfigFilesOfType(componentName, sourceDir, subPath, dynConfigFiles_general, "general");

  return 0;
}

/** This function imports the component config files of particular given type.
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynConfigFiles (in) list of config files to be imported
 @param typeLabel (in) Config files type label ["windows", "linux", "general"] to be displayed
 @return Currently always 0
  */
int fwInstallation_importConfigFilesOfType(string componentName, string sourceDir, string subPath, const dyn_string &dynConfigFiles, string typeLabel)
{
  int dynConfigFilesLen = dynlen(dynConfigFiles);
  string messageFormat = "  Importing " + typeLabel + " config file: %s ... ";
  for(int i=1;i<=dynConfigFilesLen;i++)
  {
    string configFile = dynConfigFiles[i];
    string message;
    sprintf(message, messageFormat, configFile);
    fwInstallation_showMessage(makeDynString(message));

    string configFilePath = sourceDir + subPath + strltrim(configFile, ".");
    bool shallAddToConfigRedu = (strtolower(substr(configFilePath, strlen(configFilePath) - 5)) == FW_INSTALLATION_REDU_CONFIG_FILE_EXT);

    if(!shallAddToConfigRedu || fwInstallationRedu_isRedundant()){ // Ensure that we don't add config.redu to non-redundant project
      fwInstallation_AddComponentIntoConfig(configFilePath, componentName, shallAddToConfigRedu);
    }
  }
  return 0;
}

/** This function copies component binary files and appends their location in the installation directory to the list of component files.
  * It copies the binaries from source directory to the bin/ directory in component installation path.
  * Only binaries for current WinCC OA version and not-versioned binaries are copied.
  * Binary is versioned if is placed in the directory named as WinCC OA version (e.g. 3.15/)
  * @param componentName (in)  Name of the component
  * @param sourceDir (in)  Component source directory
  * @param subPath (in)  Path to be appended to the sourceDir
  * @param destinationDir (in)  Component installation directory
  * @param binaryFiles (in)  List of binary files to be copied (relative paths to sourceDir + subPath)
  * @param componentFileList (in/out)  List of all component files to be updated with copied binaries
  * @param registerOnly (in) flag indicating whether file copying can be avoided or not if the files already exist
  * @return 0 when binaries are copied successfully, -1 in case of errors
  */
int fwInstallation_copyComponentBinaries(string componentName, string sourceDir, string subPath, string destinationDir,
                                         const dyn_string &binaryFiles, dyn_string &componentFileList, bool registerOnly)
{
  string componentSourceDir = sourceDir + subPath;
  fwInstallation_normalizePath(componentSourceDir, true);
  fwInstallation_normalizePath(destinationDir, true);

  int binaryFilesLen = dynlen(binaryFiles);
  for(int i=1;i<=binaryFilesLen;i++){
    string binaryFile = binaryFiles[i];
    //fwInstallation_normalizePath(binaryFile); // Path from XML cannot be standardized as some components use './' inside path to keep component name in target path (i.e. fwDIP).

    string targetBinFileRelPath = fwInstallation_getBinaryFileTargetPath(componentName, binaryFile);
    if(targetBinFileRelPath == ""){
      continue;
    }
    string targetBinFileAbsolutePath = destinationDir + targetBinFileRelPath;
    string sourceBinFileAbsolutePath = componentSourceDir + binaryFile;

    if(registerOnly && access(targetBinFileAbsolutePath, F_OK) == 0){
      fwInstallation_throw("Binary file already exists in target: " + targetBinFileAbsolutePath +
                           " and RegisterOnly mode is set. Skipping copy.", "INFO");
    }else{
      if(fwInstallation_copyFile(sourceBinFileAbsolutePath, targetBinFileAbsolutePath) != 0){
        fwInstallation_throw("Failed to copy binary file from: " + sourceBinFileAbsolutePath + " to: " +
                             targetBinFileAbsolutePath + ". Installation aborted", "ERROR");
        fwInstallation_showMessage(makeDynString("Error copying binary file from: " + sourceBinFileAbsolutePath +
                                                 " to: " + targetBinFileAbsolutePath));
        return -1;
      }
      if(_UNIX){ // Make binary file executable on Linux (FWINS-2171)
        system("/usr/bin/chmod +x '" + targetBinFileAbsolutePath + "'");
      }
    }
    dynAppend(componentFileList, targetBinFileRelPath); // add the binary file to the list of component files
  }
  return 0;
}

/** Returns a relative path of a binary file inside target (installation) directory
  * @param componentName  Component name
  * @param binaryFileSourcePath  Binary file relative path inside source directory
  * @return Binary file target path or empty string if binary file is not from the current WinCC OA version
  */
string fwInstallation_getBinaryFileTargetPath(string componentName, string binaryFileSourcePath){
  string binaryFileSourceDir = _fwInstallation_baseDir(binaryFileSourcePath);
  string binaryFileName = _fwInstallation_fileName(binaryFileSourcePath);

  if(fwInstallation_isDirNameMatchingWinccoaVersion(binaryFileSourceDir) == 0){
    return ""; // Binary file is of different WinCC OA version, return empty path
  }

  string binaryFileTargetDir = fwInstallation_getBinaryFileDirectoryInTarget(componentName, binaryFileSourceDir);
  string binaryFileTagetRelPath = binaryFileTargetDir + binaryFileName;
  if(strpos(binaryFileTagetRelPath, "./") == 0){
    binaryFileTagetRelPath = substr(binaryFileTagetRelPath, 2);
  }
  return binaryFileTagetRelPath;
}

/** This functions returns the path to the binary file directory in target for a binary file of a given component and in a given source directory
  * It removes the directory with a name of component inside bin/ directory and directory with a given WinCC OA version from the last element of the path
  * @example fwInstallation_getBinaryFileDirectoryInTarget("myComponent", "./bin/myComponent/dummy/3.16/", "3.16") -> "./bin/dummy/"
  * @param componentName (in)  Name of the component
  * @param sourceBinFileDir (in)  Path to the binary file directory in source
  * @param winccoaVersion (in)   WinCC OA version as a string, default: current WinCC OA version
  * @return Path to the binary file directory in target
  */
string fwInstallation_getBinaryFileDirectoryInTarget(string componentName, string sourceBinFileDir, string winccoaVersion = VERSION_DISP)
{
  string dirPathInTarget = sourceBinFileDir;

  // 1) Remove directory with name of component (if inside bin/ directory) from the target path (./bin/componentName/... -> ./bin/...)
  if(patternMatch("*" + BIN_REL_PATH + componentName + "/*", dirPathInTarget)){
    strreplace(dirPathInTarget, BIN_REL_PATH + componentName + "/", BIN_REL_PATH);
  }

  // 2) Remove directory with name of WinCC OA version (if it is the last directory in the path) from the target path (.../winccoaVersion/ -> .../)
  const string versionDir = winccoaVersion + "/";
  const int versionDirRefPos = strlen(dirPathInTarget) - strlen(versionDir);
  if(strpos(dirPathInTarget, versionDir, strlen(dirPathInTarget) - strlen(versionDir)) > 0){
    dirPathInTarget = substr(dirPathInTarget, 0, versionDirRefPos);
  }

  return dirPathInTarget;
}

/** This function checks if directory name, in the given directory path, matches pattern of a WinCC OA version and if it is equal to given version.
  * @param dirPath (in)  Path to the directory
  * @param winccoaVersion (in)  WinCC OA version as a string, default: current WinCC OA version
  * @return 0 if directory name matches the pattern of WinCC OA version BUT it is not equal to given version
  *         1 if directory name matches the pattern of WinCC OA version AND it is equal to given version
  *         2 if directory name does not match the pattern of WinCC OA version.
  */
int fwInstallation_isDirNameMatchingWinccoaVersion(string dirPath, string winccoaVersion = VERSION_DISP)
{
  const string cVersionedBinRegex = "\\d+\\.\\d+$"; // Search for directory with version number (one or more digits, dot and again one and more digits)

  string directoryName = _fwInstallation_fileName(dirPath);
  if(regexpIndex(cVersionedBinRegex, directoryName) != 0){ // Directory name is not a WinCC OA version (does not match version pattern)
    return 2;
  }
  if(directoryName == winccoaVersion){ // Directory name is equal to given WinCC OA version
    return 1;
  }
  return 0; // Directory name is of different WinCC OA version (match the version pattern, but is not a given version
}

/** This function executes the component init scripts
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynInitFiles (in) list of init files to be executed
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @return 0 if OK, -1 if error
*/
int fwInstallation_executeComponentInitScripts(string componentName,
                                               string sourceDir,
                                               string subPath,
                                               dyn_string dynInitFiles,
                                               int isSilent)
{
  int i;
  string componentInitFile;
  int iReturn;

  for(i =1; i <= dynlen(dynInitFiles); i++)
  {
    componentInitFile = sourceDir + subPath+ strltrim(dynInitFiles[i], ".");
    fwInstallation_throw("Executing the init file : " + componentInitFile, "INFO");

    // read the file and execute it
    fwInstallation_evalScriptFile(componentInitFile , iReturn);
    if(iReturn == -1)
    {
      fwInstallation_throw("Error executing script: " + componentInitFile);
      return -1;
    }
  }
  return 0;
}

/** This function stores in the component internal dp of the installation tool the list of post install scripts to be run with names
  of the components from which they came in following format "<component>|<postInstallScript>"
 @param component (in) components corresponding to post-install scripts
 @param dynPostInstallFiles_current (in) list of post-install files to be stored
 @return 0 if OK, -1 if error
*/
int fwInstallation_storeComponentPostInstallScripts(const string &component, const dyn_string &dynPostInstallFiles_current)
{
  dyn_string dynPostInstallFiles_all;
  string dp = fwInstallation_getInstallationPendingActionsDp();

  dpGet(dp + ".postInstallFiles", dynPostInstallFiles_all);
  for(int i = 1; i <= dynlen(dynPostInstallFiles_current); i++) {
    string postInstallEntry = component + "|" + dynPostInstallFiles_current[i];
    if(dynContains(dynPostInstallFiles_all, postInstallEntry) <= 0){
      dynAppend(dynPostInstallFiles_all, postInstallEntry);
    }
  }
  dpSetWait(dp + ".postInstallFiles", dynPostInstallFiles_all);

  return 0;
}

const int FW_INSTALLATION_POSTINSTALL_ACTION_BIT_LEGACY_LIB = 0;
const int FW_INSTALLATION_POSTINSTALL_ACTION_BIT_POSTINSTALLS = 1; // used only for status reporting
const int FW_INSTALLATION_POSTINSTALL_ACTION_BIT_POSTDELETE = 2; // used only for status reporting
const int FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP = 6;

/** Registers need for execution, in postinstall routine, an action given by a code.
  * For meaning of the codes see FW_INSTALLATION_POSTINSTALL_ACTION_BIT_* constants.
  * Currently legacy library generation (0) and qt help registration (7) are supported.
  * @param actionBit (in)  Postinstall action code
  * @return -2 if illegal action code given, -1 if problem with request registrations, 0 if success
  */
int fwInstallation_requestPostInstallAction(int actionBit){
    if(actionBit > 7 || actionBit < 0){
        fwInstallation_throw("Invalid post install action code: " + actionBit + ". Only 0-7 are allowed");
        return -2;
    }
    string dp = fwInstallation_getInstallationPendingActionsDp();
    return dpSetWait(dp + ".postInstallFiles:_original.._userbit" + (string)(actionBit+1), true);
}


/** This function registers component installation in the project by filling
    internal datapoint with component info
 @param componentName (in) name of the component being installed
 @param componentVersion (in) component version
 @param descFile (in) component description file
 @param isItSubComponent (in) component description file
 @param sourceDir (in) source directory for installation
 @param date (in) source directory for installation
 @param helpFile (in) source directory for installation
 @param qtHelpFiles (in) list of relative paths to component QCH files
 @param destinationDir (in) source directory for installation
 @param dynComponentFiles (in) source directory for installation
 @param dynConfigFiles_general (in) list of dpl files to be imported
 @param dynConfigFiles_linux (in) list of dpl files to be imported (linux only)
 @param dynConfigFiles_windows (in) list of dpl files to be imported (windows only)
 @param dynInitFiles (in) list of init scripts
 @param dynPostInstallFiles (in) list of post install scritps
 @param dynDeleteFiles (in) list of delete scripts
 @param dynPostDeleteFiles (in) list of post-delete scripts
 @param dynDplistFiles (in) list of dpl files
 @param dynRequiredComponents (in) list of required components
 @param dynSubComponents (in) list of subcomponents
 @param dynScriptsToBeAdded (in) list of scritps
 @param requiredInstalled (in) flag to indicated if the required component were installed
 @param comments (in) component comments
 @param description (in) component description
 @return 0 if OK, -1 if error
*/
int fwInstallation_registerComponentInstallation(
    string componentName, string componentVersion, string descFile, int isItSubComponent,
    string sourceDir, string date, string helpFile, dyn_string qtHelpFiles, string destinationDir,
    dyn_string dynComponentFiles, dyn_string dynConfigFiles_general, dyn_string dynConfigFiles_linux,
    dyn_string dynConfigFiles_windows, dyn_string dynInitFiles, dyn_string dynPostInstallFiles,
    dyn_string dynDeleteFiles, dyn_string dynPostDeleteFiles, dyn_string dynDplistFiles,
    dyn_string dynRequiredComponents, dyn_string dynSubComponents, dyn_string dynScriptsToBeAdded,
    int requiredInstalled, dyn_string comments, string description)
{
  // save the component info into the PVSS database
  fwInstallation_throw("Saving the component info into the project database: " + componentName + " v." + componentVersion, "INFO");
  string dp = fwInstallation_getComponentDp(componentName);

  if(!dpExists(dp)){
    int res = dpCreate(dp, FW_INSTALLATION_DPT_COMPONENTS);
    dyn_errClass err = getLastError();

    if(res != 0 || err.count() > 0){
      fwInstallation_showMessage(makeDynString("    ERROR: Component installation cannot be registered into the project database "));
      fwInstallation_writeToMainLog(componentName + " " + componentVersion + " installed but installation not registered - error");
      if(err.count() > 0){
        fwInstallation_showMessage(makeDynString((string)err.at(0)));
      }
      return -1;
    }
  }

  int res = dpSetWait(
      dp + ".componentVersion", componentVersion, dp + ".componentVersionString", componentVersion,
      dp + ".descFile", descFile, dp + ".sourceDir", sourceDir,
      dp + ".installationDirectory", destinationDir, dp + ".date", date,
      dp + ".helpFile", helpFile, dp + ".qtHelpFiles", qtHelpFiles,
      dp + ".componentFiles", dynComponentFiles,
      dp + ".configFiles.configGeneral", dynConfigFiles_general,
      dp + ".configFiles.configLinux", dynConfigFiles_linux,
      dp + ".configFiles.configWindows", dynConfigFiles_windows,
      dp + ".initFiles", dynInitFiles,
      dp + ".postInstallFiles", dynPostInstallFiles,
      dp + ".deleteFiles", dynDeleteFiles,
      dp + ".postDeleteFiles", dynPostDeleteFiles,
      dp + ".dplistFiles", dynDplistFiles,
      dp + ".requiredComponents", dynRequiredComponents,
      dp + ".requiredInstalled", requiredInstalled,
      dp + ".subComponents", dynSubComponents,
      dp + ".isItSubComponent", isItSubComponent,
      dp + ".scriptFiles", dynScriptsToBeAdded,
      dp + ".comments", comments,
      dp + ".description", description,
      dp + ".name", componentName);
  dyn_errClass err = getLastError();

  if(res != 0 || err.count() > 0){
    fwInstallation_showMessage(makeDynString("    ERROR: Component installation incorrectly registered into the project database "));
    fwInstallation_writeToMainLog(componentName + " " + componentVersion + " installed but installation incorrectly registered - error");
    if(err.count() > 0){
      fwInstallation_showMessage(makeDynString((string)err.at(0)));
    }
    return -1;
  }
  return 0;
}

/** This function checks if there is any dependency broken among the installed components
 *  and sets the values of the internal dps accordingly
 * @param reduHostNum (in)  Redu peer number (1 or 2), if 0 (default) then local peer number is used. Note that in non-redu system local peer is always 1.
 * @return 0 (error code not yet implemented)
*/
int fwInstallation_checkComponentBrokenDependencies(int reduHostNum = 0)
{
  if(reduHostNum == 0){
    reduHostNum = fwInstallationRedu_myReduHostNum();
  }

  dyn_string dynRequiredComponents;
  dyn_string dynSubComponents;

  dyn_string dps = fwInstallation_getInstalledComponentDps(reduHostNum);

  for(int i = 1; i <= dynlen(dps); i++)
  {
    dynRequiredComponents.clear();
    dynSubComponents.clear();

    string componentDp = dps[i];
    dpGet(componentDp + ".requiredComponents", dynRequiredComponents,
          componentDp + ".subComponents", dynSubComponents);

    string requiredNotInstalledNames = "";
    fwInstallation_getNotInstalledComponentsFromRequiredComponents(
            dynRequiredComponents, requiredNotInstalledNames, reduHostNum);
    if(!requiredNotInstalledNames.isEmpty())
    { // not all required components are installed
      dpSet(componentDp + ".requiredInstalled", false);
      continue;
    }

    string subcomponentsNotInstalledNames = "";
    fwInstallation_getNotInstalledComponentsFromRequiredComponents(
            dynSubComponents, subcomponentsNotInstalledNames, reduHostNum);
    if(!subcomponentsNotInstalledNames.isEmpty())
    { // not all subcomponents are installed
      dpSet(componentDp + ".requiredInstalled", false);
      continue;
    }
    // all dependencies of a component are OK
    dpSet(componentDp + ".requiredInstalled", true);
  }

  return 0;
}


/*
int fwInstallation_checkComponentBrokenDependencies()
{
  dyn_string dynNotProperlyInstalled;
  dyn_string dynRequiredComponents;
  string strNotInstalledNames;
  int i = 1;
  string str = "";

  if(fwInstallationRedu_myReduHostNum() > 1)
    str = "_" + fwInstallationRedu_myReduHostNum();

  fwInstallation_getListOfNotProperlyInstalledComponents(dynNotProperlyInstalled);

  for(i = 1; i <= dynlen(dynNotProperlyInstalled); i++)
  {
    dynClear(dynRequiredComponents);
    string dp = fwInstallation_getComponentDp(dynNotProperlyInstalled[i]);
    //dpGet(dp + ".requiredComponents", dynRequiredComponents);

    dpGet(dynNotProperlyInstalled[i] + ".requiredComponents", dynRequiredComponents);

    fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynRequiredComponents, strNotInstalledNames);

    if(strNotInstalledNames == "")
      dpSet(dynNotProperlyInstalled[i] + ".requiredInstalled", true);
//      dpSet(dp + ".requiredInstalled", true);
  }

  return 0;
}
*/
string fwInstallation_getComponentName(string filename)
{//Note: check if code below should be changed, component name should be retrieved from tag name in component description file, see: FWINS-1956
  string component = _fwInstallation_fileName(filename);
  strreplace(component, ".xml", "");
  return component;
}
/** This function installs the component. It copies the files, imports the component DPs, DPTs, updates the project config file

@param descFile: the file with the description of a component
@param sourceDir: the root directory with the component files
@param isItSubComponent: it is false - if it is the master component; it is true if it is the sub component
@param componentName: it is the return value - the name of the installed component
@param componentInstalled: set to 1 if the component is properly installed
@param dontRestartProject: indicates whether the project has to be restarted after installations or not
@param subPath: path to be appended to the source directory
@param forceInstallRequired this flag indicates whether all required components must be installed provided that
       they correct versions are found in the distribution. This is a optional parameter. The default value is false to keep the tool backwards compatible.
	   Note that the value of this parameter is set to the default value (TRUE) when a silent installation is chosen.
@param forceOverwriteFiles this flag indicates whether the files of the component must be overwritten if a previous installation of the component is detected in the target directory
       This is a optional parameter. The default value is false to keep the tool backwards compatible.
	   Note that the value of this parameter is set to the default value (FALSE) when a silent installation is chosen.
@param isSilent flag indicating whether we are dealing with a silent installation of the packages or not. The default value is false.
@param installSubComponents flag indicating whether subcomponents have to also be installed
@return Error code: -1 if ERROR, 0 if all OK.
@author  F. Varela.
*/
int fwInstallation_installComponent(string descFile,
                                    string sourceDir,
                                    bool isItSubComponent,
                                    string & componentName,
                                    bool & componentInstalled,
                                    string &dontRestartProject,
                                    string subPath = "",
                                    bool forceInstallRequired = false,
                                    bool forceOverwriteFiles = false,
                                    bool isSilent = false,
                                    bool installSubComponents = true)
{
  bool requiredInstalled = true;
  int error = 0;
  int registerOnly = 0;

  string dp = fwInstallation_getInstallationDp();

  dontRestartProject = "no";

  // add a control manager for the fwScripts.lst
  string user, pwd, host = fwInstallation_getPmonHostname();
  int port = pmonPort();
  fwInstallation_getPmonInfo(user, pwd);
  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "once", 30, 1, 1,
                            FW_INSTALLATION_SCRIPTS_MANAGER_CMD, host, port, user, pwd);

  if(componentName != "")//theoretically it might be the case that component name is empty - don't report the first step then as it will create wrong entry in report list
    fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_PARSING_XML);

  if(descFile == "")
  {
    fwInstallation_popup("Installation of \"" + componentName + "\" failed. \nNo XML file defined.");
    return -1;
  }

  // get the destination dir
  string destinationDir;  // the name of a directory where the component will be installed
  dpGet(dp + ".installationDirectoryPath", destinationDir);

  //step 1
  dyn_dyn_mixed parsedComponentInfo;
  if(fwInstallationXml_parseFile(sourceDir, descFile, subPath, destinationDir, parsedComponentInfo))
  {
    fwInstallation_popup("Installation of \"" + componentName + "\" failed. \nXML file not properly parsed.");
    return -1;
  }

  componentName = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];

  string     componentVersion           = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
  dyn_string dynSubComponents           = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS];
  dyn_string dynFileNames               = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_FILES];
  dyn_string dynPostDeleteFiles         = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS];
  dyn_string dynPostInstallFiles        = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS];
  dyn_string dynPostDeleteFilesCurrent  = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS_CURRENT]; //  Note: not used currently (dynPostDeleteFiles is used instead), consider removing in the future
  dyn_string dynPostInstallFilesCurrent = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS_CURRENT]; //  Note: not used currently (dynPostInstallFiles is used instead), consider removing in the future
  dyn_string dynConfigFiles_general     = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  dyn_string dynConfigFiles_linux       = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX];
  dyn_string dynConfigFiles_windows     = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS];
  dyn_string dynInitFiles               = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
  dyn_string dynDeleteFiles             = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
  dyn_string dynDplistFiles             = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
  dyn_string dynScriptsToBeAdded        = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  dyn_string dynBinFiles                = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES];
  string     helpFile                   = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE];
  string     date                       = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DATE];
  dyn_string comments                   = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS];
  string     description                = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION];
  dyn_string dynRequiredComponents      = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS];
  string     requiredPvssVersion        = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION];
  bool       strictPvssVersion          = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION][1];
  string     requiredPvssPatch          = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH];
  dyn_string dynPreinit                 = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS];
  bool       updateTypes                = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES][1];
  string     requiredInstallerVersion   = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION];
  bool       strictInstallerVersion     = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION][1];
  dyn_string qtHelpFiles                = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES];

  fwInstallation_setCurrentComponent(componentName, componentVersion);

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_CHECKING_REQUIREMENTS);

  int ret = -1;
  if(requiredPvssVersion != "") //Check PVSS version
  {
    fwInstallation_throw("Component: "+componentName + " v." + componentVersion + " requires PVSS version: " + requiredPvssVersion + ". Checking condition now...", "INFO", 10);
    ret = fwInstallation_checkPvssVersion(requiredPvssVersion);

    if(ret <= 0)
    {
      fwInstallation_popup("Installation of \""+componentName + "\" (" + componentVersion + ") aborted. Requires WinCC version " + requiredPvssVersion + " or later.");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else if(strictPvssVersion && ret!= 1)
    {
      fwInstallation_popup("Installation aborted. Requires WinCC version " + requiredPvssVersion + " or later.");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Current PVSS version: " + VERSION_DISP + " equal or newer than required version "
                           + requiredPvssVersion, "INFO", 10);
    }
  }

  if(requiredPvssPatch != "") //Check patching
  {
    fwInstallation_throw("Component: "+componentName + " v." + componentVersion + " requires PVSS patch: " + requiredPvssPatch + ". Checking condition now...", "INFO", 10);

    if(fwInstallation_isPatchInstalled(requiredPvssPatch) <= 0 && ret == 1) //Check the patch level only if we are talking about the exact PVSS version.
    {
      fwInstallation_popup("Installation aborted. Current WinCC version " + VERSION_DISP + " does not contain patch " + requiredPvssPatch + ".");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Patch: " + requiredPvssPatch + " applied to current PVSS version: " + VERSION_DISP, "INFO", 10);
    }
  }

  if(requiredInstallerVersion != "") //Check PVSS version
  {
    fwInstallation_throw("Component: "+componentName + " v." + componentVersion + " requires a version: " + requiredInstallerVersion + " of the FW Component Installation Tool. Checking condition now...", "INFO", 10);
    ret = fwInstallation_checkToolVersion(requiredInstallerVersion);
    if(ret <= 0)
    {
      fwInstallation_popup("Installation aborted.\nRequires Installation Tool version " + requiredInstallerVersion + " or later.");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else if(strictInstallerVersion && ret!= 1)
    {
      fwInstallation_popup("Installation aborted. \""+componentName + "\" \nneeds Installation Tool version " + requiredInstallerVersion + ".");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Current version of the FW Component Installation Tool: " + csFwInstallationToolVersion + " equal or newer than required version "
                           + requiredInstallerVersion, "INFO", 10);
    }
  }

  fwInstallation_throw("Now installing " + componentName  + " v." + componentVersion + " from " + sourceDir + ". XML File: " + descFile, "INFO");

  fwInstallation_throw("Installation options: " +
                       (installSubComponents?"installSubcomponentsOfParent":"skipSubcomponentsNotTargetted") + "|" +
                       (forceInstallRequired?"forceRequired":"noForceRequired") + "|" +
                       (forceOverwriteFiles?"overwriteFiles":"noOverwriteFiles") + "|" +
                       (isSilent?"silentInstallation":"interactiveInstallation") + "|" +
                       (gFwYesToAll?"yesToAll":"alwaysRequireUserInput"), "INFO");
  //////////
  //step 2
  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_VERIFYING_COMPONENT_PACKAGE);

  //FVR: 31/03/2006: Check if the component already exists in the destination directory:
  //Check that the forceOverwriteFiles is not true in addition
  registerOnly = fwInstallation_getRegisterOnly(destinationDir, componentName,  forceOverwriteFiles, isSilent);
  if(registerOnly < 0.) //Installation aborted by the user.
    return 0;

  //// check if all scripts all valid, and all directories are writeable and if all source files exist
  bool actionAborted = false;
  bool componentIntegrityWrong = false;
  if(fwInstallation_verifyDestinationDirAndSourceFiles(componentName,
                                                       sourceDir,
                                                       subPath,
                                                       destinationDir,
                                                       dynFileNames,
                                                       dynBinFiles,
                                                       registerOnly,
                                                       isSilent,
                                                       actionAborted))
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to verify component package: " + componentName);
    componentIntegrityWrong = true; //signal that we know that there was a problem with the component but the user has decided to go ahead.
    ++error;
  }

  if(actionAborted) //user has decided to cancel the installation or we are running from a ctrl manager
  {
    fwInstallation_unsetCurrentComponent();
    return 0;
  }

  //step 2.5, :-)
  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_EXECUTING_PREINIT_SCRIPTS);
  //Run Pre-init scripts
  if(fwInstallation_executeComponentInitScripts(componentName, sourceDir, subPath, dynPreinit, isSilent))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    fwInstallation_popup("Installation of \"" + componentName + "\" (" + componentVersion + ") aborted. Execution of component pre-init script(s) failed.");
    fwInstallation_unsetCurrentComponent();
    return -1;
  }
  //step 3
  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_INSTALLING_REQUIRED_COMPONENTS);
  //install required component if necessary:
  if(fwInstallation_installRequiredComponents(componentName, dynRequiredComponents, sourceDir, forceInstallRequired, forceOverwriteFiles, isSilent, requiredInstalled, actionAborted))
  {
    fwInstallation_popup("Forced installation of required components \nfor \"" + componentName + "\" failed.");
    ++error;
  }

  if(actionAborted) //user has decided to cancel the installation or running from ctrl script
  {
    fwInstallation_unsetCurrentComponent();
    fwInstallation_trackDependency_clear();
    return 0;
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_INSTALLING_SUBCOMPONENTS);
  fwInstallation_reportUpdateTotalComponentsNumber(dynlen(dynSubComponents));
// install the subcomponents if they exist
  if(installSubComponents && dynlen(dynSubComponents) > 0)
  {
    fwInstallation_showMessage(makeDynString("     Installing sub Components ... "));
    fwInstallation_throw(componentName + " has " + dynlen(dynSubComponents) + " subcomponent(s). " +
                         "Installing them now", "INFO");
    for(int i = 1; i <= dynlen(dynSubComponents); i++)
    {
      string subComponentXml = dynSubComponents[i];
      // try to load subcomponent XML to retrieve its name
      dyn_dyn_mixed componentInfo;
      if(fwInstallationXml_load(subComponentXml, componentInfo)){
        fwInstallation_throw("Subcomponent XML description: " + subComponentXml + " not found", "ERROR");
        fwInstallation_popup(componentName + " subcomponent: " + _fwInstallation_fileName(subComponentXml) +
                             "\nis missing in source directory.\nInstallation of " + componentName + " is incorrect.");
        ++error;
        fwInstallation_reportUpdateTotalComponentsNumber(-1);
        continue;
      }
      string subComponentName = componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME][1];

      if(fwInstallation_trackDependency_register(componentName, subComponentName) != 0){
        fwInstallation_throw("Detected circular dependency while installing components, triggering another installation of: " + subComponentName + " aborted", "ERROR");
        fwInstallation_trackDependency_clear();
        return -1;
      }

      fwInstallation_throw("Installing subcomponent of " + componentName + " (" + i + "/" +
                           dynlen(dynSubComponents) + ") - " + subComponentName, "INFO");
      fwInstallation_reportComponentInstallationProgress(subComponentName, FW_INSTALLATION_REPORT_STEP_STARTING_INSTALLATION);

      if(fwInstallation_installComponent(subComponentXml, sourceDir, true, subComponentName, componentInstalled, dontRestartProject,
                                         subPath, forceInstallRequired, forceOverwriteFiles, isSilent, installSubComponents) != 0)
      {
        // + report installation status (success/error)
        if(subComponentName != "")
          fwInstallation_reportComponentInstallationFinished(subComponentName);

        fwInstallation_setComponentInstallationStatus(componentName, false);

        fwInstallation_popup("Installation of sub-component \n\"" + subComponentXml + "\" failed.");

        fwInstallation_unsetCurrentComponent();
        fwInstallation_trackDependency_clear();
        return -1;
      }
      if(subComponentName != "")
        fwInstallation_reportComponentInstallationFinished(subComponentName);
    }
    fwInstallation_throw("Installation of all " + componentName + " subcomponents completed, continuing with " +
                         componentName + " installation", "INFO");
  }else if(dynlen(dynSubComponents) > 0){
    fwInstallation_throw("Installation of subcomponents during " + componentName +
                         " installation skipped (enabled option 'skipSubcomponentsNotTargetted')", "INFO");
  }
  fwInstallation_trackDependency_unregister(componentName);

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_COPYING_FILES);
  // copy all the files
  if(fwInstallation_copyComponentFiles(componentName, sourceDir, subPath, destinationDir, dynFileNames, registerOnly))
  {
    fwInstallation_popup("Copying files of \"" + componentName + "\" failed.");
    fwInstallation_setComponentInstallationStatus(componentName, false);

    if(!componentIntegrityWrong) // The component integrity is OK but there were problems copying the file.
    {
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_INSTALL_BINARIES);
  if(fwInstallation_copyComponentBinaries(componentName, sourceDir, subPath, destinationDir,
                                          dynBinFiles, dynFileNames, registerOnly) != 0)
  {
    fwInstallation_popup("Installing binary files of \"" + componentName + "\" failed.");
    fwInstallation_setComponentInstallationStatus(componentName, false);

    if(!componentIntegrityWrong){ // The component integrity is OK but there were problems copying the file.
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_IMPORTING_DPS);
// import the dplist files with the ASCII manager

  if(fwInstallationRedu_isComponentInstalledInPair(componentName, componentVersion))
  {
    fwInstallation_throw("Redundant system. Component already installed in pair. ASCII import will be skipped for component: " + componentName, "INFO");
  }
  else
  {
    if(fwInstallation_importComponentAsciiFiles(componentName, sourceDir, subPath, dynDplistFiles, updateTypes, isSilent))
    {
      fwInstallation_setComponentInstallationStatus(componentName, false);
      fwInstallation_popup("Import of .dpl files for \"" + componentName + "\" failed.");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_CONFIGURING_PROJECT);
  if(fwInstallation_importConfigFiles(componentName, sourceDir, subPath, dynConfigFiles_general, dynConfigFiles_linux, dynConfigFiles_windows))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    fwInstallation_popup("Import of config files for \"" + componentName + "\" failed.");
    fwInstallation_unsetCurrentComponent();
    return -1;
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_EXECUTING_INIT_SCRIPTS);
// add scripts to the fwScripts.lst file
  if(fwInstallation_executeComponentInitScripts(componentName, sourceDir, subPath, dynInitFiles, isSilent))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    fwInstallation_popup("Execution of init script(s) for \"" + componentName + "\" failed.");
    fwInstallation_unsetCurrentComponent();
    return -1;
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_REGISTERING_INSTALLATION);
  string xml = "./" + _fwInstallation_fileName(descFile);
  //dynSubComponents is the list of XML files of the subcomponents. We need to extract only the names to set the internal dp
  dyn_string subcomponents;
  for(int i = 1; i <= dynlen(dynSubComponents); i++)
    subcomponents[i] = fwInstallation_getComponentName(dynSubComponents[i]);

  if(fwInstallation_registerComponentInstallation(
      componentName, componentVersion, xml, isItSubComponent, sourceDir, date, helpFile, qtHelpFiles,
      destinationDir, dynFileNames, dynConfigFiles_general, dynConfigFiles_linux, dynConfigFiles_windows,
      dynInitFiles, dynPostInstallFiles, dynDeleteFiles, dynPostDeleteFiles, dynDplistFiles,
      dynRequiredComponents, subcomponents, dynScriptsToBeAdded, requiredInstalled, comments, description) != 0)
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    fwInstallation_popup("Registering component installation in internal\nInstallation Tool " +
                         "datapoint for\n\"" + componentName + "\" failed.");
    fwInstallation_unsetCurrentComponent();
    return -1;
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_CALCULATING_SOURCE_FILES_HASHES);
  // calculate hashes of component source files
  if(fwInstallation_calculateSourceFilesHashes(parsedComponentInfo, sourceDir) != 0)
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to calculate source files' hashes for component: " + componentName);
    ++error;
  }
  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_VERIFYING_DEPENDENCIES);
  // the component has been installed - check whether it has corrected the broken dependencies
  if(fwInstallation_checkComponentBrokenDependencies())
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to check broken dependencies for component: " + componentName);
    ++error;
  }

  fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_REQUESTING_POSTINSTALLS);
  bool postInstallPending = (dynlen(dynPostInstallFiles) > 0);
  if(error == 0){
    // Requesting qt help regeneration in postinstall if component has one
    if(dynlen(qtHelpFiles) > 0){
      fwInstallation_requestPostInstallAction(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP);
    }
    // Requesting generation legacy library includes in postinstall
    fwInstallation_requestPostInstallAction(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_LEGACY_LIB);
    // Store component post-installation scripts for later execution:
    if(fwInstallation_storeComponentPostInstallScripts(componentName, dynPostInstallFiles)){
      fwInstallation_popup("Storing post-install scripts for \"" + componentName + "\" failed.");
      ++error;
    }
  }else if(postInstallPending){
    fwInstallation_throw("Skipping registration of post-install scripts of component " + componentName +
                         " because it is incorrectly installed.", "WARNING");
  }

  //Legacy
  componentInstalled = true;

  if(error)
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    fwInstallation_popup("Installation of \"" + componentName + "\" failed.");
  }
  else
  {
    string msg = "The installation of component " + componentName + " v." + componentVersion + " completed OK" +
                 (postInstallPending?" - Note that there are still post-installation scripts pending execution":"");
    fwInstallation_setComponentInstallationStatus(componentName, true, postInstallPending);
    fwInstallation_throw(msg, "INFO", 10);
  }

  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    fwInstallation_reportComponentInstallationProgress(componentName, FW_INSTALLATION_REPORT_STEP_REGISTERING_INSTALLATION_IN_DB);

    fwInstallation_throw("Updating FW System Configuration DB after installation of " + componentName + " v"+ componentVersion, "INFO", 10);
    fwInstallationDB_storeInstallationLog();
    fwInstallationDB_registerProjectFwComponents();

    fwInstallationDBAgent_checkIntegrity();
  }

  fwInstallation_unsetCurrentComponent();
  return gFwInstallationOK;
}


/** This function sets the internal dpes of the component dp according to the status of the installation

@param componentName component name
@param installationOk status of installation
@param postInstallPending indicates if component has post-install scripts pending for execution
@return Error code: -1 if ERROR, 0 if all OK.
@author  F. Varela.
*/

int fwInstallation_setComponentInstallationStatus(string componentName, bool installationOk, bool postInstallPending = false)
{
  string dp = fwInstallation_getComponentDp(componentName);
  if(!dpExists(dp)){
    return 0;
  }
  return (dpSetWait(dp + ".installationNotOK", !installationOk,
                    dp + ".postInstallPending", postInstallPending) == 0 &&
          dynlen(getLastError()) == 0)?0:-1;
}

/** This function checks if all the required components are installed. It returns a string of components that are not
installed and required.

@param dynRequiredComponents: the name of a componentConfigFile
@param strNotInstalledNames: the name of a component
@param reduHostNum: redu peer number (1 or 2), if 0 (default) then local peer number is used. Note that in non-redu system local peer is always 1.
@author M.Sliwinski
*/
fwInstallation_getNotInstalledComponentsFromRequiredComponents(dyn_string & dynRequiredComponents,
                                                               string & strNotInstalledNames,
                                                               int reduHostNum = 0)
{
    int dynRequiredComponentsLen = dynlen(dynRequiredComponents);
    if(dynRequiredComponentsLen <= 0){ // No required components = nothing to do => return
        return;
    }

    // retrieve all installed components
    dyn_string installedComponentDps =  fwInstallation_getInstalledComponentDps(reduHostNum);
    int installedComponentDpsLen = dynlen(installedComponentDps);

    dyn_string installedComponentNames;
    dyn_string installedComponentVersions;

    if(installedComponentDpsLen > 0){
        dyn_string installedComponentNameDpes;
        dyn_string installedComponentVersionDpes;
        for(int i=1;i<=installedComponentDpsLen;i++){
            installedComponentNameDpes.append(installedComponentDps[i] + ".name");
            installedComponentVersionDpes.append(installedComponentDps[i] + ".componentVersionString");
        }
        // Get names and versions of all installed components
        dpGet(installedComponentNameDpes, installedComponentNames,
              installedComponentVersionDpes, installedComponentVersions);
        if(dynlen(installedComponentNames) != dynlen(installedComponentVersions) ||
           dynlen(installedComponentNames) != installedComponentDpsLen){
            fwInstallation_throw("Error retrieving lists of component names and versions installed in the project " +
                                 "when checking dependencies. Assuming no components installed", "WARNING");
            installedComponentNames.clear();
            installedComponentVersions.clear();
        }
    }

    for(int i=1;i<=dynRequiredComponentsLen;i++){
        // retrieve the name and version of the component
        string requiredComponent = dynRequiredComponents[i];
        string strRequiredName, strRequiredVersion;
        fwInstallation_parseRequiredComponentNameVersion(requiredComponent, strRequiredName, strRequiredVersion);

        bool isRequiredInstalled = false;
        // check whether the required component is installed
        int requiredComponentPos = dynContains(installedComponentNames, strRequiredName);
        if(requiredComponentPos > 0){
            // the required component is installed
            // checking the version of the installed component
            string strInstalledVersion = installedComponentVersions[requiredComponentPos];
            if(_fwInstallation_CompareVersions(strInstalledVersion, strRequiredVersion, false, false, true) == 1){
                // the installed version of the component is greater than the required version or equal to it - OK
                isRequiredInstalled = true;
            }
        }
        if(!isRequiredInstalled){
            // the required component is not installed
            strNotInstalledNames += requiredComponent + "|";
        }
    }
}

/** This function reads the component config file and copies its entries to the project config file (if they are not yet there).
  * @param componentConfigFile (in)  Path of the component config file
  * @param componentName (in)  Name of the component
  * @param addToReduConfig (in)  Flag that indicates if component entries should be added to the project redu config file (by default false)
  */
fwInstallation_AddComponentIntoConfig(string componentConfigFile, string componentName, bool addToReduConfig = false)
{
  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

  if(addToReduConfig){
    configFile += FW_INSTALLATION_REDU_CONFIG_FILE_EXT;

    if(!isfile(configFile)){ // Create file redu config file if not exists yet
      file f = fopen(configFile, "w");
      // TODO: Check if file was opened/created
      fclose(f);
    }
  }

  dyn_string projectConfigLines, componentConfigLines;
  fwInstallation_loadFileLines(componentConfigFile, componentConfigLines);
  fwInstallation_loadFileLines(configFile, projectConfigLines);

  fwInstallation_mergeComponentConfigIntoProject(projectConfigLines, componentConfigLines, componentName);
  fwInstallation_saveFile(projectConfigLines, configFile);
}

/** Reads the given file and loads it into memory as a list of lines.
  * @param filePath (in)  Path of the file to be read
  * @param fileLines (out)  List of the file lines
  * @return 0 when file was loaded successfully, -1 when failed to load the file
  */
int fwInstallation_loadFileLines(string filePath, dyn_string &fileLines)
{
  string fileInString;
  if(!fileToString(filePath, fileInString)){
    fwInstallation_throw("Cannot load " + filePath + " file");
    return -1;
  }
  fileLines = fwInstallation_splitLines(fileInString);
  return 0;
}

const string FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_PATTERN = "#--------- begin %-20s - Do not edit it manually";
const string FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN   = "#----------- end %-20s -------------------------";

const dyn_string FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_ALL_PATTERNS =
    makeDynString("#begin %s", // obsolete pattern
                  FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_PATTERN);
const dyn_string FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_ALL_PATTERNS =
    makeDynString("#end %s", // obsolete pattern
                  FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN);

/** Removes all lines containing component parametrization from the list of config lines.
  * @param configLines (in/out)  List of the config lines
  * @param componentName (in)  Name of the component
  */
void fwInstallation_deleteComponentConfigEntries(dyn_string &configLines, string componentName)
{
  const dyn_string configComponentTagsBegin = fwInstallation_config_getConfigComponentAllTags(componentName, FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_ALL_PATTERNS);
  const dyn_string configComponentTagsEnd = fwInstallation_config_getConfigComponentAllTags(componentName, FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_ALL_PATTERNS);
  const string errMessageFormat = "Found only %s of %s component parametrization section, but no %s. " +
                                  "Please review the config file. Component parametrization is not removed from corrupted section";

  int componentLineEnd;
  int configLinesLen = dynlen(configLines);
  for(int i=configLinesLen;i>=1;i--)
  {
    string configLine = configLines[i];

    if(fwInstallation_config_isSectionDefinition(strltrim(strrtrim(configLine))) && componentLineEnd > 0){
      componentLineEnd = 0; // If new section and componentLineEnd > 0 reset its value - prevent removal from different sections when component tags are corrupted
      string errMsg;
      sprintf(errMsg, errMessageFormat, "end", componentName, "begin");
      fwInstallation_throw(errMsg);
    }

    if(dynContains(configComponentTagsEnd, configLine) > 0){ // Iterate over config lines in reverse order so component part starts when "#end ..." tag is found
      componentLineEnd = i;
    }

    if(dynContains(configComponentTagsBegin, configLine) > 0){ // Component part ends when "#begin ..." tag is found (reverse order)
      for(int j=componentLineEnd;j>=i;j--){ // Remove all config lines that belongs to given component
        dynRemove(configLines, j);
      }
      if(componentLineEnd == 0){
        string errMsg;
        sprintf(errMsg, errMessageFormat, "begin", componentName, "end");
        fwInstallation_throw(errMsg);
      }
      componentLineEnd = 0; // make sure that when only begin tag of component is present, no lines are removed
    }
  }
  if(componentLineEnd > 0){
    string errMsg;
    sprintf(errMsg, errMessageFormat, "end", componentName, "begin");
    fwInstallation_throw(errMsg);
  }
}

dyn_string fwInstallation_config_getConfigComponentAllTags(string componentName, const dyn_string &configComponentTagAllPatterns){
  dyn_string configComponentTags;
  int configComponentTagAllPatternsLen = dynlen(configComponentTagAllPatterns);
  for(int i=1;i<=configComponentTagAllPatternsLen;i++){
    string configComponentTag;
    sprintf(configComponentTag, configComponentTagAllPatterns[i], componentName);
    dynAppend(configComponentTags, configComponentTag);
  }
  return configComponentTags;
}

// Constants indicating the type (content) of config line
const int FW_INSTALLATION_CONFIG_EMPTY_LINE_CODE = 0; // Empty config line
const int FW_INSTALLATION_CONFIG_COMMENT_LINE_CODE = 1; // Config line containing only comment
const int FW_INSTALLATION_CONFIG_SECTION_LINE_CODE = 2; // Config line with section definition
const int FW_INSTALLATION_CONFIG_ENTRY_LINE_CODE = 3; // Config line with valid entry (key-values pair)

/** Parses key-values pair from config file line.
  * @note: If line contains section definition or only comment then it is returned via key parameter and keyValues is not modified.
  * @param configLine (in)  Config file line
  * @param key (out)  Config entry key/section name/comment
  * @param keyValues (out)  List of config entry values
  * @return -1 when failed to parse config line, otherwise code indicating the type of config line (empty/comment/section/key-value entry), see FW_INSTALLATION_CONFIG_*_LINE_CODE constants
  */
int fwInstallation_parseConfigLine(string configLine, string &key, dyn_string &keyValues)
{
  configLine = strltrim(strrtrim(configLine));
  if(configLine == ""){
    //DebugTN("Config line: " + configLine + " is empty");
    return FW_INSTALLATION_CONFIG_EMPTY_LINE_CODE;
  }
  if(fwInstallation_config_isCommentLine(configLine)){
    key = configLine;
    //DebugTN("Config line: " + configLine + " is a comment");
    return FW_INSTALLATION_CONFIG_COMMENT_LINE_CODE;
  }
  if(fwInstallation_config_isSectionDefinition(configLine)){
    key = fwInstallation_config_trimComment(configLine);
    //DebugTN("Config line: " + configLine + " defines a section");
    return FW_INSTALLATION_CONFIG_SECTION_LINE_CODE;
  }

  // Config line is none of the above so it must contain config entry
  if(fwInstallation_config_getKeyValue(configLine, key, keyValues) != 0){
    fwInstallation_throw("Failed to parse config line: " + configLine);
    return -1;
  }
  return FW_INSTALLATION_CONFIG_ENTRY_LINE_CODE;
}

/** Parses config lines into memory representation: list of sections ([section]), array of keys ([section][key]), array of values ([section][key][value]).
  * @note Config lines contains only comment are discarded, on the other hand currently comment after the value is treated as a part of this value.
  * @param configLines (in)  List of config file lines
  * @param configSections (out)  List of config sections ([section])
  * @param configKeysArray (out)  Array of config entry keys ([section][key])
  * @param configValuesArray (out)  Array of config entry keys values ([section][key][value])
  */
void fwInstallation_parseConfigFileLines(const dyn_string &configLines, dyn_string &configSections, dyn_dyn_string &configKeysArray, dyn_dyn_mixed &configValuesArray)
{
  dynClear(configSections);
  dynClear(configKeysArray);
  dynClear(configValuesArray);

  int currentSectionId = 0;
  int configLinesLen = dynlen(configLines);
  for(int i=1;i<=configLinesLen;i++){
    string key;
    dyn_string keyValues;
    string configLine = configLines[i];
    switch(fwInstallation_parseConfigLine(configLine, key, keyValues)){
      case FW_INSTALLATION_CONFIG_SECTION_LINE_CODE:
        currentSectionId = fwInstallation_config_setSectionInMemory(key, configSections, configKeysArray, configValuesArray);
        break;
      case FW_INSTALLATION_CONFIG_ENTRY_LINE_CODE:
        if(currentSectionId <= 0){
          fwInstallation_throw("WARNING: Config entry: " + configLine + " is not in any known section, its value will be discarded", "WARNING");
          break;
        }
        fwInstallation_config_addEntryIntoMemory(key, keyValues, configKeysArray[currentSectionId], configValuesArray[currentSectionId]);
        break;
    }
  }
}

/** Checks if config entry (key-value pair) exists in memory representation of the particular section of config file
  * @param key (in)  Key to be searched
  * @param value (in)  Value of given key to be searched
  * @param configKeys (in/out)  List of config keys (of particular section)
  * @param configValues (in/out)  Array of config values ([key][value]) (of particular section)
  * @return true if key-value exists in the memory representation, false if not
  */
bool fwInstallation_config_entryExistsInMemory(string key, string value, const dyn_string &configKeys, const dyn_mixed &configValues)
{
  int keyId = dynContains(configKeys, key);
  if(keyId == 0){
    return false;
  }
  return (dynContains(configValues[keyId], value) > 0);
}

/** Adds config entry (key-values pair) into memory representation of the particular section of config file.
  * @param key (in)  Key to be added
  * @param keyValues (in)  Values to be added under given key
  * @param configKeys (in/out)  List of config keys (of particular section)
  * @param configValues (in/out)  Array of config values ([key][value]) (of particular section)
  */
void fwInstallation_config_addEntryIntoMemory(string key, dyn_string keyValues, dyn_string &configKeys, dyn_mixed &configValues)
{
  dyn_string allValues; // If there are already parsed other values for given key, preserve them
  int keyId = dynContains(configKeys, key);
  if(keyId > 0){ // Key already exists, retrieve its values
    allValues = configValues[keyId];
  }else{ // Key not yet here, append and store its position
    keyId = dynAppend(configKeys, key);
  }
  dynAppend(allValues, keyValues);
  configValues[keyId] = allValues;
}

/** Retrieves ID of the section in the memory representation of config file.
  * If section is not yet there, appends it and initializes corresponding indexes in configKeysArray and configValuesArray.
  * @param section (in)  Name of the section
  * @param configSections (in/out)  List of the sections in config file ([section])
  * @param configKeysArray (in/out)  Array of config entry keys ([section][key])
  * @param configValuesArray (in/out)  Array of config entry keys values ([section][key][value])
  * @return ID of the section (index in configSections array)
  */
int fwInstallation_config_setSectionInMemory(string section, dyn_string &configSections, dyn_dyn_string &configKeysArray, dyn_dyn_mixed &configValuesArray)
{
  int sectionId = dynContains(configSections, section);
  if(sectionId > 0){ // Section already in memory, just return ID
    return sectionId;
  }
  // Append section to the list of config sections, initialize corresponding element in keys and values arrays
  sectionId = dynAppend(configSections, section);
  configKeysArray[sectionId] = makeDynString();
  configValuesArray[sectionId] = makeDynMixed();
  return sectionId;
}

const string FW_INSTALLATION_CONFIG_COMMENT_CHAR = "#";
const string FW_INSTALLATION_CONFIG_KEY_VALUE_SEPARATOR = "=";
const string FW_INSTALLATION_CONFIG_SECTION_BEGIN_CHAR = "[";
const string FW_INSTALLATION_CONFIG_SECTION_END_CHAR = "]";

/** Checks if the config line is a line that contains only comment (starts with '#' symbol).
  * @note Leading whitespaces must be removed before calling this function (use strltrim())
  * @TODO: Maybe regexp (or piece of code) to find the first occurence of '#' that is not inside quotes '"', then take only this part that is not a comment
  * @param configLine (in)  Single line of a config file
  * @return true if config line is a comment line, false if not (a section or key-value entry)
  */
bool fwInstallation_config_isCommentLine(string configLine)
{
  return (strtok(configLine, FW_INSTALLATION_CONFIG_COMMENT_CHAR) == 0);
}

/** Checks if the config line is a line that defines a config file section (e.g. [ui], [general])
  * @note Leading whitespaces must be removed before calling this function (use strltrim())
  * @param configLine (in)  Single line of a config file
  * @return true if config line is a line that specifies config section, false if not
  */
bool fwInstallation_config_isSectionDefinition(string configLine)
{ // regexp: match '[' bracket at the beginning of the string, then one or more characters that are NOT the end bracket ']' or whitespace or comment char '#',
  //         then end bracket ']', zero or more whitespaces followed by end of line or comment character '#'
  const string SECTION_REGEXP = "^\\" + FW_INSTALLATION_CONFIG_SECTION_BEGIN_CHAR +
                                "[^\\" + FW_INSTALLATION_CONFIG_SECTION_END_CHAR + "\\s#]+" +
                                "\\" + FW_INSTALLATION_CONFIG_SECTION_END_CHAR +
                                "\\s*($|" + FW_INSTALLATION_CONFIG_COMMENT_CHAR + ")"; // ^\[[^\]\s#]+\]\s*($|#)
  return (regexpIndex(SECTION_REGEXP, configLine) == 0);
}


/** Returns the config line with any comments removed.
  * @IMPORTANT @TODO: Currently it doesn't take into account that '#' might occur inside quotes "[...]" and then should not be treated as a character that starts comment.
  *                   Now this function is used only for section definition lines where quotes are not used.
  * @param configLine (in)  Single line of a config file
  * @return Config line that does not contains comments, empty string if comment line is provided as an argument
  */
string fwInstallation_config_trimComment(string configLine)
{
  int commentStartPos = strtok(configLine, FW_INSTALLATION_CONFIG_COMMENT_CHAR);
  if(commentStartPos < 0){
    return configLine;
  }
  return strrtrim(substr(configLine, 0, commentStartPos));
}

/** Parses key-values pair in a config line.
  * @param configLine (in)  Single line of a config file
  * @param key (out)  Config key
  * @param values (out)  The values of a config key
  * @return -1 in case of error (not possible to parse config line), 0 when success
  */
int fwInstallation_config_getKeyValue(string configLine, string &key, dyn_string &values)
{
  int keyValueSeparatorPosition = strtok(configLine, FW_INSTALLATION_CONFIG_KEY_VALUE_SEPARATOR);
  if(keyValueSeparatorPosition <= 0){
    fwInstallation_throw("Cannot get key-values pair from a config line: " + configLine + " as it doesn't contain '=' character");
    return -1;
  }
  key = strrtrim(substr(configLine, 0, keyValueSeparatorPosition));
  string valueString = strltrim(substr(configLine, keyValueSeparatorPosition + 1));

  values = callFunction(fwInstallation_config_getConfigEntryParser(key), valueString);
  return 0;
}

const string FW_INSTALLATION_CONFIG_PARSE_FUNCTION = "fwInstallation_config_parse"; // Default parser function name

/** Returns the name of the function that should be used to parse config entry with specific key.
  * It is possible to define custom parser functions for specific config keys.
  * Name of such function must have the following pattern: fwInstallation_config_parse[key]().
  * For example: fwInstallation_config_parseLoadCtrlLibs() for LoadCtrlLibs config key.
  * If custom function for the config key is not defined then default parser function is returned: fwInstallation_config_parse()
  * @param key (in)  Config entry key
  * @return Name of the parser function.
  */
string fwInstallation_config_getConfigEntryParser(string key)
{
  if(isFunctionDefined(FW_INSTALLATION_CONFIG_PARSE_FUNCTION + key)){
    return FW_INSTALLATION_CONFIG_PARSE_FUNCTION + key;
  }
  return FW_INSTALLATION_CONFIG_PARSE_FUNCTION;
}

/** Default parser function, returns the provided value as a one-element list, without any further processing.
  * @param valueString (in)  Config key string value
  * @return One-element list containing provided valueString
  */
dyn_string fwInstallation_config_parse(string valueString) // Default config entry parser
{
  return makeDynString(valueString);
}

/** Parser function for LoadCtrlLibs entries. Splits provided string into a list of library files.
  * @param valueString (in)  LoadCtrlLibs key value (string contains library files delimited with comma)
  * @retrun List of ctrl library files
  */
dyn_string fwInstallation_config_parseLoadCtrlLibs(string valueString) // Custom config entry parser for LoadCtrlLibs entry value
{
  dyn_string values = strsplit(valueString, ",");
  int valuesLen = dynlen(values);
  for(int i=1;i<=valuesLen;i++){
    values[i] = "\"" + strltrim(strrtrim(values[i], "\" "), "\" ") + "\"";
  }
  return values;
}

/** Adds component config lines into project config lines if not yet there.
  * @param projectConfigLines (in/out)  Project config lines
  * @param componentConfigLines (in)  Component config lines
  * @param componentName (in)  Name of the component
  */
fwInstallation_mergeComponentConfigIntoProject(dyn_string &projectConfigLines, const dyn_string &componentConfigLines, string componentName)
{
  dyn_string projectConfigSections, componentConfigSections;
  dyn_dyn_string projectConfigKeysArray;
  dyn_dyn_mixed projectConfigValuesArray;
  fwInstallation_parseConfigFileLines(projectConfigLines, projectConfigSections, projectConfigKeysArray, projectConfigValuesArray);

  int projectSectionId;
  int projectConfigLineNum; // Stores the line number at which component entries are inserted into project config lines list
  int componentConfigLinesLen = dynlen(componentConfigLines);
  for(int i=1;i<=componentConfigLinesLen;i++){
    string key;
    dyn_string keyValues;
    switch(fwInstallation_parseConfigLine(componentConfigLines[i], key, keyValues)){
      case FW_INSTALLATION_CONFIG_SECTION_LINE_CODE:
        if(projectSectionId > 0){ // Put component end tag in previous section (if there was any)
          fwInstallation_config_insertComponentTag(projectConfigLines, projectConfigLineNum++, componentName, FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN);
        }
        string currentSection = key;
        projectSectionId = fwInstallation_config_setSectionInMemory(currentSection, projectConfigSections, projectConfigKeysArray, projectConfigValuesArray);
        // Find the line (position) where section is defined in project config lines
        projectConfigLineNum = fwInstallation_config_getSectionLineNum(projectConfigLines, currentSection);
        if(projectConfigLineNum == 0){ // Section not yet in the config lines, append it
          projectConfigLineNum = dynAppend(projectConfigLines, currentSection);
        }
        projectConfigLineNum++; // Move to the next line (component config entries must be inserted after section definition line)
        // Store list of processed sections of component config file to be able to find the duplicates
        if(dynContains(componentConfigSections, currentSection) == 0){
          dynAppend(componentConfigSections, currentSection);
        }else{ // If section is duplicated show warning (component config will be merged successfully anyway, but component tags will be duplicated)
          fwInstallation_throw("Section: " + currentSection + " is duplicated in component config file, please correct this by merging entries into one section", "WARNING");
        }
        fwInstallation_config_insertComponentTag(projectConfigLines, projectConfigLineNum++, componentName, FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_PATTERN);
        break;
      case FW_INSTALLATION_CONFIG_COMMENT_LINE_CODE:
        if(projectSectionId <= 0){
          break; // Discard comments that don't belong to any section
        }
        dynInsertAt(projectConfigLines, key, projectConfigLineNum++);
        break;
      case FW_INSTALLATION_CONFIG_ENTRY_LINE_CODE:
        if(projectSectionId <= 0){ // Discard entries that don't belong to any section, show warning in log
          fwInstallation_throw("WARNING: Config entry: " + componentConfigLines[i] + " is not in any known section, its value will be discarded", "WARNING");
          break;
        }
        int keyValuesLen = dynlen(keyValues);
        for(int j=1;j<=keyValuesLen;j++){
          string value = keyValues[j];
          /*if(fwInstallation_config_entryExistsInMemory(key, value, projectConfigKeysArray[projectSectionId], projectConfigValuesArray[projectSectionId])){
            continue; // Entry is already in the project config file, don't add duplicate
          }*/ // Allow duplicate config entries, see ENS-24203
          // Add entry to: 1) memory representation of the project config file and 2) project config lines
          fwInstallation_config_addEntryIntoMemory(key, makeDynString(value), projectConfigKeysArray[projectSectionId], projectConfigValuesArray[projectSectionId]);
          string configEntry;
          sprintf(configEntry, "%s %s %s", key, FW_INSTALLATION_CONFIG_KEY_VALUE_SEPARATOR, value);
          dynInsertAt(projectConfigLines, configEntry, projectConfigLineNum++);
        }
        break;
    }
  }
  if(projectSectionId > 0){ // Put component end tag in previous section (if there was any)
    fwInstallation_config_insertComponentTag(projectConfigLines, projectConfigLineNum++, componentName, FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN);
  }
}

/** Returns the config line number where the given section is defined.
  * @note If section is defined more than once (might happen in component config), only the number of the line, where section is defined for the first time, is returned.
  *       Therefore this function should not be used for the component config lines.
  * @param configLines (in)  List of the config lines
  * @param sectionName (in)  Name of the section to look for
  * @param 0 when section was not found in the config file, otherwise number of the line where section is defined (>0)
  */
int fwInstallation_config_getSectionLineNum(const dyn_string &configLines, string sectionName){
  int configLinesLen = dynlen(configLines);
  for(int i=1;i<=configLinesLen;i++){
    string configLine = strltrim(strrtrim(configLines[i]));
    if(fwInstallation_config_isSectionDefinition(configLine) &&
       fwInstallation_config_trimComment(configLine) == sectionName){
      return i;
    }
  }
  return 0;
}

/** This function inserts the component tag into the config lines (information where the component parametrization starts/ends).
  * @param configLines (in/out)  Config file lines
  * @param lineNumber (in)  Line number where the tag should be inserted
  * @param componentName (in)  Name of the component
  * @param tagTypePattern (in)  Pattern with the config component tag, only FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_PATTERN or
                                FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN should be used
  */
void fwInstallation_config_insertComponentTag(dyn_string &configLines, int lineNumber, string componentName, string tagTypePattern)
{
  if(tagTypePattern == FW_INSTALLATION_CONFIG_COMPONENT_TAG_BEGIN_PATTERN ||
     tagTypePattern == FW_INSTALLATION_CONFIG_COMPONENT_TAG_END_PATTERN){
    string configComponentTag;
    sprintf(configComponentTag, tagTypePattern, componentName);
    dynInsertAt(configLines, configComponentTag, lineNumber);
  }
}

/** This function adds the lines from linesToAdd into the configLines under the section specified by currentSection
@note Currently not used anywhere in the frameworks, might became obsolete, if not it should be reviewed (what if there is a comment after section definition?)
@param configLines: the dyn_string with file lines
@param currentSection: the name of a currentSection
@param linesToAdd: the lines to be added

@author M.Sliwinski
*/

int fwInstallation_addLinesIntoSection(dyn_string & configLines, string currentSection, dyn_string  linesToAdd)
{
	int idxOfLine;
	int i;
	int returnValue;

	string tempLine;

	for( i = 1; i <= dynlen(configLines); i++)
	{
		tempLine = strltrim(strrtrim(configLines[i]));

		// find the section where it should be inserted
		if(tempLine == currentSection)
		{
			// insert the lines into the configLines
			returnValue = dynInsertAt(configLines, linesToAdd, ++i);

			if(returnValue == -1)
			{
				return -1;
			}
			else
			{
				return 1;
			}
		}
	}
}

/** This function saves the new order of project paths into the config file.
Provided list of paths must contain all paths that were previously in config file.
If PROJ_PATH is not at the last position in the list (or is missing) it will be automatically moved/added at the end of the provided list.

@param projPaths (in)  List of project paths in choosen order
@return 0 if OK, -1 if error
@author Sascha Schmeling
*/

int fwInstallation_changeProjPaths(dyn_string projPaths)
{
  string proj_path = PROJ_PATH;
  fwInstallation_normalizePath(proj_path);
  fwInstallation_normalizePathList(projPaths);

  //FVR reshuffle project paths to make sure that the last one corresponds to the project path
  dynRemove(projPaths, dynContains(projPaths, proj_path));
  dynAppend(projPaths, proj_path);

  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;
  string fileInString;
  if(!fileToString(configFile, fileInString))//load config file into string
  {
    fwInstallation_throw("Failed to load config file: " + configFile + ". Cannot change order of project paths");
    return -1;
  }
  dyn_string configLines = fwInstallation_splitLines(fileInString);
  int configLinesLen = dynlen(configLines);

  int projPathsToChange = dynlen(projPaths);//get length of provided list of project paths
  int changedProjPath = 0;
  for(int i=1;i<=configLinesLen;i++)
  {
    string currentLine = strltrim(strrtrim(configLines[i]));
    if(currentLine == "")//empty config line - skipping
      continue;

    dyn_string paramNameValue = strsplit(currentLine, FW_INSTALLATION_CONFIG_KEY_VALUE_SEPARATOR);
    string paramName = strltrim(strrtrim(paramNameValue[1]));

    if(paramName != "proj_path" || dynlen(paramNameValue) != 2)//skip lines that don't contain project paths, second condition to avoid exception in exotic cases
      continue;

    string paramValue = strltrim(strrtrim(paramNameValue[2]));
    paramValue = strltrim(strrtrim(paramValue, "\""), "\"");
    fwInstallation_normalizePath(paramValue);//prepare path from config for comparison
    if(dynContains(projPaths, paramValue) <= 0)//if path which is currently in config is missing in the provided list of ordered paths then abort changes
    {
      fwInstallation_throw("Missing path: " + paramValue + " in the list of provided path. Cannot change order of project paths");
      return -1;
    }

    changedProjPath++;
    if(changedProjPath > projPathsToChange)//make sure that list of ordered paths does not contain less paths than config file - to avoid 'index out of range' exception
    {
      fwInstallation_throw("List of provided project paths does not contain all paths from config file. Cannot change order of project paths");
      return -1;
    }
    //now config entry can be updated safely
    configLines[i] = "proj_path = \"" + projPaths[changedProjPath] + "\"";
  }

  if(changedProjPath != projPathsToChange)//ensure that all paths from provided list were written to configLines
  {
    fwInstallation_throw("List of provided project paths contains more paths (" + (string)projPathsToChange +
                         ") than config file (" + (string)changedProjPath + "). Cannot change order of project paths");
    return -1;
  }
  if(fwInstallation_saveFile(configLines, configFile) != 0)
  {
    fwInstallation_throw("Failed to save config file with reordered project paths. Project paths order remains unchanged");
    return -1;
  }
  return 0;
}

/** This function creates a project path, either creates the directory or just adds the path

@param sPath:	project path to be created
@param createDirectory flag to indicate if the directory has to be created if it does not exist (default value is true)
@return 0 if OK, -1 if error
*/

int fwInstallation_createPath(string sPath, bool createDirectory = true)
{
  dyn_string projPaths;
  int i, x;
  string result;

  int directoryExists;
  bool state;
  string cmd, err = 0;
  string dp = fwInstallation_getInstallationDp();

	if(fwInstallation_normalizePath(sPath) == -1)
	{
	  return -1;
	}
  if (access(sPath, F_OK) == -1 && createDirectory)
  {
    mkdir(sPath, "755");
		if(access(sPath, F_OK) != -1)
      fwInstallation_throw("New directory successfully created: " + sPath, "INFO", 10);
		else
		{
         fwInstallation_throw("You must define the full path. Project path will not be added");
         return -1;
     }
  }
	//the directory has been created - add it into the config file
	if(fwInstallation_addProjPath(sPath, 999))
  {
    fwInstallation_throw("File to add project path to config file: " + sPath);
    return -1;
  }

  dpSet(dp + ".installationDirectoryPath", sPath);

  return 0;
}

///FVR: 29/03/2006

/** This function retrieves the component information from the PVSS DB and
	displays it in the panel

@param componentName the name of a file with component description
@author M.Sliwinski
*/

fwInstallation_getComponentDescriptionPVSSDB(string componentName, int reduHostNum = 0)
{
  string dp = fwInstallation_getComponentDp(componentName, reduHostNum);

  // Display component name
  TextName.text = componentName;

  // Retrieve and display basic info about component (version, date, source directory)
  string componentVersionString, descFile, date, description, sourceDirectory;
  dpGet(dp + ".componentVersionString:_original.._value", componentVersionString,
        dp + ".descFile:_original.._value", descFile,
        dp + ".date:_original.._value", date,
        dp + ".description:_original.._value", description,
        dp + ".sourceDir:_original.._value", sourceDirectory);
  TextVersion.text = componentVersionString;
  TextDate.text = date;
  TextSourceDirectory.text = sourceDirectory;
  selectionDescription.items = makeDynString(description);

  // Check if component package source directory is still available
  string descFilePath = sourceDirectory + descFile;
  fwInstallation_normalizePath(descFilePath);
  bool isSourceDirReadable = isfile(descFilePath);
  btnCalculateHash.enabled = isSourceDirReadable;
  TextIsAccessible.text = isSourceDirReadable?"Yes":"No";

  // Retrieve and display subcomponents and required components
  dyn_string dynSubComponents, requiredComponents;
  dpGet(dp + ".subComponents:_original.._value", dynSubComponents,
        dp + ".requiredComponents:_original.._value", requiredComponents);
  selectionSubComponents.items = dynSubComponents;
  string requiredName, requiredVersion;
  int requiredComponentsLen = dynlen(requiredComponents);
  for(int i=1;i<=requiredComponentsLen;i++){
    fwInstallation_parseRequiredComponentNameVersion(requiredComponents[i], requiredName, requiredVersion);
    selectionRequiredComponents.appendLine("requirement", requiredName + " ver.: " + requiredVersion);
    string installedVersion;
    bool isInstalled = fwInstallation_isComponentInstalled(requiredName, installedVersion, reduHostNum);
    bool isRequiredVersion;
    if(!isInstalled ||
       _fwInstallation_CompareVersions(installedVersion, requiredVersion, false, false, true) != 1){
        int lineToUpdate = selectionRequiredComponents.lineCount() - 1;
        selectionRequiredComponents.cellBackColRC(lineToUpdate, "requirement",
                                                  FW_INSTALLATION_COLOR_BROKEN_DEPENDENCY);
        selectionRequiredComponents.cellToolTipRC(lineToUpdate, "requirement", isInstalled?
                                                  ("Installed: " + requiredName + " ver.: " + installedVersion):
                                                  "Component not installed");
    }
  }
  selectionRequiredComponents.adjustColumn(0);

  // Retrieve and display component files with its config entries
  dyn_string configFiles_linux, configFiles_windows, configFiles_general;
  dpGet(dp + ".configFiles.configLinux:_original.._value", configFiles_linux,
        dp + ".configFiles.configWindows:_original.._value", configFiles_windows,
        dp + ".configFiles.configGeneral:_original.._value", configFiles_general);
  selectionConfigFiles_linux.items = configFiles_linux;
  selectionConfigFiles_windows.items = configFiles_windows;
  selectionConfigFiles_general.items = configFiles_general;

  // Retrieve and display lists of other specific component files (scripts, init and postinstall scripts, dpl files)
  dyn_string initFiles, scriptFiles, dplistFiles, postInstallFiles;
  dpGet(dp + ".initFiles:_original.._value", initFiles,
        dp + ".scriptFiles:_original.._value", scriptFiles,
        dp + ".dplistFiles:_original.._value", dplistFiles,
        dp + ".postInstallFiles:_original.._value", postInstallFiles);
  selectionInitFiles.items = initFiles;
  selectionScripts.items = scriptFiles;
  selectionDplistFiles.items = dplistFiles;
  selectionPostInstallFiles.items = postInstallFiles;

  // Retrieve and display list of all component files
  dyn_string componentFiles;
  dpGet(dp + ".componentFiles:_original.._value", componentFiles);
  selectionOtherFiles.items = componentFiles;
}

/** This function puts the components to be deleted in order in which they should be deleted
The function only checks if the component chosen for deleting depend on each other.
The function operates on the component information contained in the PVSS DB

algorithm: suppose we have the following components to delete:  com1, com2, com3
the dependencies are following:
	com1: is required by com2
	com2: is required by com3
	com3: is nor required by them
We can first delete the com3 because it is not required by com1 i com3
	the dependencies are following:
	com1: is required by com2
	com2: is not required by any component
If there is a loop: com1 is required by com2 and com2 is required by com1 the components can not be ordered

@param componentsNames: the dyn_string of the components to be put in order before deleting
@param componentsNamesInOrder: the dyn_string of the ordered components to be deleted

@author M.Sliwinski
*/

fwInstallation_putComponentsInOrder_Delete(dyn_string componentsNames, dyn_string & componentsNamesInOrder)
{
	dyn_dyn_string dependencies; //  first column - component name, next columns - components that require this component
	dyn_string dynDependentComponents;
	string tempComponentName;
	bool emptyListExists = true;
	int i, j, k;

	// build the dependencies table
	// for each compomponent
	for(i = 1; i <= dynlen(componentsNames); i++)
	{
		// build the dependencies table
		dynAppend(dependencies[i] , componentsNames[i]);

		// get the list of dependent components
		fwInstallation_getListOfDependentComponents(componentsNames[i], dynDependentComponents);
		// append the dependent components
		dynAppend(dependencies[i], dynDependentComponents);
	}


	// put the components in order - algorithm is described in the comment before the function
	while(emptyListExists)
	{
		emptyListExists = false;

			// for each component
			for(i = 1; i <= dynlen(componentsNames); i++)
			{
				// if it is not required by other components
				if((dynlen(dependencies[i]) == 1) && (dependencies[i][1] != "EMPTY"))
				{
					emptyListExists = true;

					tempComponentName = dependencies[i][1];

					// remove the component name from the dependencies table ( set it to EMPTY value )
					dependencies[i][1] = "EMPTY";

					// put it at the end of the  components in order
					dynAppend(componentsNamesInOrder, tempComponentName);

					// remove the component from the list
					for(j = 1; j <= dynlen(componentsNames); j++)
					{

						k = dynContains(dependencies[j], tempComponentName);

						if(k > 0)
						{
							// this component no longer requires other components
							dynRemove(dependencies[j], k);
						}
					}
				}
			}
	}

	// if there were unsolved dependencies copy the components to the end of the list

	for(i = 1; i <= dynlen(componentsNames); i++)
	{
		if(dependencies[i][1] != "EMPTY")
		{
			dynAppend(componentsNamesInOrder, dependencies[i][1]);
		}
	}

}


/** This function gets the list of dependent components. This functions from the list of  all  installed components
 retrieves the list of components that require strComponentName

@param componentName: the name of the component for which we would like to find dependent components
@param dependentComponentsList: the dyn_string of components that require the strComponentName component
@author M.Sliwinski
*/
fwInstallation_getListOfDependentComponents(string componentName, dyn_string & dependentComponentsList)
{
  dynClear(dependentComponentsList);
  dyn_string installedComponentDps = fwInstallation_getInstalledComponentDps();
  int installedComponentDpsLen = dynlen(installedComponentDps);
  for(int i=1;i<=installedComponentDpsLen;i++){
    dyn_string requiredComponents;
    string name;
    string installedComponentDp = installedComponentDps[i];
    dpGet(installedComponentDp + ".requiredComponents", requiredComponents,
          installedComponentDp + ".name", name);
    if(componentName == name){ // skip component for which getting list of dependent components
      continue;
    }
    int requiredComponentsLen = dynlen(requiredComponents);
    for(int j=1;j<=requiredComponentsLen;j++){
      string requiredComponentNameVersion = requiredComponents[j];
      string requiredComponentName, requiredComponentVersion;
      fwInstallation_parseRequiredComponentNameVersion(requiredComponentNameVersion,
                                                       requiredComponentName, requiredComponentVersion);
      if(requiredComponentName == componentName){
        dynAppend(dependentComponentsList, name);
      }
    }
  }
}

const string FW_INSTALLATION_REQUIRED_COMPONENT_NAME_VERSION_SEPARATOR = "=";

/** Parses required component name and version from requirement string
  * @param requiredComponentNameVersion (in)  Requirement string with component name and minimal required version separated with '=' (eg. fwComponent=8.0.0)
  * @param requiredComponentName (out)  Parsed required component name
  * @param requiredComponentVersion (out)  Parsed required version, empty if requirement string contains only component name
  */
fwInstallation_parseRequiredComponentNameVersion(string requiredComponentNameVersion, string &requiredComponentName, string &requiredComponentVersion){
  requiredComponentNameVersion = strltrim(strrtrim(requiredComponentNameVersion));
  int separatorPos = strpos(requiredComponentNameVersion, FW_INSTALLATION_REQUIRED_COMPONENT_NAME_VERSION_SEPARATOR);
  if(separatorPos < 0){
    requiredComponentName = requiredComponentNameVersion;
    requiredComponentVersion = "";
  }else{
    requiredComponentName = strrtrim(substr(requiredComponentNameVersion, 0, separatorPos));
    requiredComponentVersion = strltrim(substr(requiredComponentNameVersion, separatorPos + 1));
  }
}

/** this function deletes the component files, the component information from the config file
	and the internal DP created by the installation tool with the description of a component.
	This function does not delete the component data point types ( ETM is planning to
	add the functionality of deleting the DPT, DP from the ASCII Manager ).

@param componentName (in) the name of a component to be deleted
@param componentDeleted (out) result of the operation
@param deleteAllFiles (in) flag indicating if the components files must also be deleted. Default value is true.
@param deleteSubComponents flag indicating if the subcomponent must also be deleted. Default value is true.
@author F. Varela
*/
int fwInstallation_deleteComponent(string componentName,
                                   bool & componentDeleted,
                                   bool deleteAllFiles = TRUE,
                                   bool deleteSubComponents = true,
                                   bool &deletionAborted)
{
  string dp = fwInstallation_getComponentDp(componentName);

  if(!dpExists(dp)){
    componentDeleted = true;
    return 0;
  }

  string componentVersion, installationDirectory;
  dyn_string dynSubComponents;
  dyn_string componentFiles;
  dyn_string deleteFiles, postDeleteFiles;
  dyn_string qtHelpFiles;
  dpGet(dp + ".componentVersionString", componentVersion,
        dp + ".installationDirectory", installationDirectory,
        dp + ".subComponents", dynSubComponents,
        dp + ".componentFiles", componentFiles,
        dp + ".deleteFiles", deleteFiles,
        dp + ".postDeleteFiles", postDeleteFiles,
        dp + ".qtHelpFiles", qtHelpFiles);
  dynUnique(componentFiles);
  fwInstallation_normalizePathList(postDeleteFiles);
  bool hasPostDeleteFiles = (dynlen(postDeleteFiles) > 0);

  if(installationDirectory == ""){
    fwInstallation_throw("The installation directory for the " + componentName + " does not exist or is not specified!", "error", 4);
    return -1;
  }
  fwInstallation_throw("Deleting component: " + componentName + " v." + componentVersion + " from project " + PROJ + " in host " + fwInstallation_getHostname(), "info", 10);

  //begin check the component dependencies - if it is required by other components
  dyn_string dynDependentComponents;
  fwInstallation_getListOfDependentComponents(componentName, dynDependentComponents);

  if(dynlen(dynDependentComponents) > 0){
    string strDependentComponentsNames;
    for(int i=1;i<=dynlen(dynDependentComponents);i++){
      strDependentComponentsNames += dynDependentComponents[i] + "|";
    }
    fwInstallation_showMessage(makeDynString("Dependent components at deletion of " + componentName + ":", strDependentComponentsNames));
    // ask the user if he wants to delete this component - other components are using it
    dyn_string ds;
    dyn_float df;
    if(myManType() == UI_MAN){
      ChildPanelOnCentralReturn("fwInstallation/fwInstallationDependencyDelete.pnl", "Dependencies of " + componentName,
                                makeDynString("$strDependentNames:" + strDependentComponentsNames , "$componentName:" + componentName), df, ds);
    }else{
      ds[1] = "Install_Delete";
    }

    // check the return value of fwInstallationDependency .pnl
    if(ds[1] == "Install_Delete"){
      fwInstallation_showMessage(makeDynString("User choice at deletion of "+componentName+": DELETE"));
    }else if(ds[1] == "DoNotInstall_DoNotDelete"){
      fwInstallation_showMessage(fwInstallation_timestampString() + ": Component deletion aborted by the user.");
      deletionAborted = true;
      return 0;
    }
  }

  int errorDeletingComponent;
  if(!deletionAborted){
    // check if all files are deletable
    // FVR: Do this check only if the deleteAllFiles flag is set to true
    dyn_string componentFilesDelete;
    if(deleteAllFiles){
      for(int i=1;i<=dynlen(componentFiles);i++){
        string componentFile = componentFiles[i];
        if(hasPostDeleteFiles && fwInstallation_isPostDeleteScript(postDeleteFiles, installationDirectory, componentFile)){
          continue; // if this is a post-delete script, don't append it to the list of files that are removed - it has to be kept until post-delete script is executed
        }
        if(access(installationDirectory + "/" + componentFile, F_OK) == 0){
          dynAppend(componentFilesDelete, componentFile);
        }else{
          fwInstallation_throw("Component " + componentName + " points to a non existing file: " + installationDirectory + "/" + componentFile, "WARNING", 3);
        }
      }
    }

    fwInstallation_writeToMainLog("Starting to delete " + componentName);
    fwInstallation_showMessage(makeDynString("Deleting " + componentName + " ... "));

    if(deleteSubComponents){
      // delete all subcomponents
      int subComponentsNum = dynlen(dynSubComponents);
      dyn_string dynSubComponentsOrdered;
      if(subComponentsNum > 1){
        fwInstallation_putComponentsInOrder_Delete(dynSubComponents, dynSubComponentsOrdered);
      }else{
        dynSubComponentsOrdered = dynSubComponents;
      }
      for(int i=1;i<=dynlen(dynSubComponentsOrdered);i++){
        string subComponentName = dynSubComponentsOrdered[i];
        fwInstallation_showMessage(makeDynString("  Deleting sub component (" + i + "/" +
                                                 subComponentsNum + "): " + subComponentName));
        fwInstallation_deleteComponent(subComponentName, componentDeleted, deleteAllFiles, deleteSubComponents, deletionAborted);
      }
    }

    // request to regenerate Qt Help Collection in a post delete script (if deleted component had one)
    if(dynlen(qtHelpFiles) > 0){
      fwInstallation_requestPostInstallAction(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_QT_HELP);
    }
    // Generate legacy library includes.
    fwInstallation_requestPostInstallAction(FW_INSTALLATION_POSTINSTALL_ACTION_BIT_LEGACY_LIB);

    // delete the DP
    dpDelete(dp);
    delay(1);

    // execute delete scripts
    for(int i=1;i<=dynlen(deleteFiles);i++){
      string msg = "Executing the delete file ... ";
      fwInstallation_throw(msg, "INFO", 10);
      fwInstallation_showMessage(makeDynString(msg));
      string componentDeleteFile = deleteFiles[i];
      // read the file and execute it
      int retVal;
      fwInstallation_evalScriptFile(installationDirectory + "/" + componentDeleteFile, retVal);
      if(retVal == -1){
        fwInstallation_throw("Executing the delete file: " + componentDeleteFile + " - Component: " + componentName, "WARNING", 10);
        errorDeletingComponent = -1;
      }
    }

    if(deleteAllFiles){
      string msg = "Deleting files for component: " + componentName;
      fwInstallation_throw(msg, "INFO", 10);
      fwInstallation_showMessage(makeDynString(msg));
      if(fwInstallation_deleteFiles(componentFilesDelete, installationDirectory)){
        errorDeletingComponent = -1;
      }
    }

    // begin store the postDelete files in a datapoint
    if(hasPostDeleteFiles){
      fwInstallation_storePostDeleteScripts(postDeleteFiles);
    }

    // now delete the component info from the config file
    fwInstallation_throw("Updating the project config file after component deletion: " + componentName, "INFO", 10);
    _fwInstallation_DeleteComponentFromConfig(componentName);
    if(fwInstallationRedu_isRedundant()){
      _fwInstallation_DeleteComponentFromConfig(componentName, true);
    }
  }

  if((errorDeletingComponent == -1)){
    fwInstallation_throw("There were errors while deleting the components - see the log for details - Component: " + componentName);
    if(deletionAborted){
      fwInstallation_writeToMainLog(componentName + " de-installation aborted");
    }else{
      fwInstallation_writeToMainLog(componentName + " deleted with errors");
    }
    componentDeleted = false;
  }else{
    fwInstallation_throw("Component deleted: " + componentName, "INFO", 10);
    fwInstallation_showMessage(makeDynString(fwInstallation_timestampString() + componentName + " deleted"));
    componentDeleted = true;
  }

  if(fwInstallation_checkComponentBrokenDependencies()){
    fwInstallation_throw("fwInstallation_deleteComponent() -> Failed to check broken dependencies");
  }

  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0){
    fwInstallation_throw("Updating FW System Configuration DB after deletion of " + componentName + " v."+ componentVersion, "INFO", 10);
    fwInstallationDB_storeInstallationLog();
    fwInstallationDB_registerProjectFwComponents();
    fwInstallationDBAgent_checkIntegrity();
  }
  return 0;
}

/** Checks if component file, given with a relative path, is one of the post-delete scripts given in a list.
  * @param dynPostDeleteFiles (in)  List of absolute paths to post-delete files. Paths must be normalized.
  * @param installationDirectory (in)  Component installation directory
  * @param fileToCheck (in)  Relative path to a component file
  * @return True if component file is a post-delete script (one from the given in the list), False otherwise.
  */
bool fwInstallation_isPostDeleteScript(const dyn_string &dynPostDeleteFiles, string installationDirectory, string fileToCheck)
{
  string componentFilePath = installationDirectory + "/" + fileToCheck;
  fwInstallation_normalizePath(componentFilePath);
  return (dynContains(dynPostDeleteFiles, componentFilePath) > 0);
}

/** This function stores in the component internal dp of the installation tool the list of post delete scripts to be run
 @param dynPostDeleteFiles_current (in) list of post-delete files to be stored
 @return 0 if OK, -1 if error
*/
int fwInstallation_storePostDeleteScripts(const dyn_string &dynPostDeleteFiles_current)
{
  dyn_string dynPostDeleteFiles_all;
  string dp = fwInstallation_getInstallationPendingActionsDp();
  dpGet(dp + ".postDeleteFiles", dynPostDeleteFiles_all);

  int dynPostDeleteFiles_currentLen = dynlen(dynPostDeleteFiles_current);
  for(int i = 1; i <= dynPostDeleteFiles_currentLen; i++) {
    string postDeleteFile = dynPostDeleteFiles_current[i];
    if(access(postDeleteFile, R_OK) != 0){
      fwInstallation_throw("Post-delete script file: " + + " is not accessible. Not appending to a post-delete routine", "WARNING");
      continue;
    }
    if(dynContains(dynPostDeleteFiles_all, postDeleteFile) <= 0){
      dynAppend(dynPostDeleteFiles_all, postDeleteFile);
    }
  }
  return dpSetWait(dp + ".postDeleteFiles", dynPostDeleteFiles_all);
}

/** This function resolves the XML files and versions of the components required
  * for installation during the installation of a particular component
  * @param sourceDir (in)  Source directory
  * @param requiredComponents (in)  List of required components, each element must have format <componentName>=<minVersionRequired>
  * @param dsFileComponentName (out)  List of available component names, element from particular index corresponds to the same index in requiredComponents list,
  *                                   when required component is not available in source directory, element contains empty string
  * @param dsFileVersions (out)  List of available component versions, each version correspond to the component on the same index in dsFileComponentName, if
  *                              component is not available in source directory, version is an empty string
  * @param dsFileComponent (out)  list of available component XML files, each XML path correspond to the component on the same index in dsFileComponentName,
  *                               when component is not available or in version lower than required, the XML file is an empty string
  * @return 0 if success, -1 if error (at least one required component is missing in source directory or failed to parse name and version from requirement string)
  */
int fwInstallation_checkDistribution(string sourceDir,
                                     const dyn_string &requiredComponents,
                                     dyn_string &dsFileComponentName,
                                     dyn_string &dsFileVersions,
                                     dyn_string &dsFileComponent)
{
  int retVal;
  dyn_dyn_string componentsInfo;
  fwInstallation_getAvailableComponents(sourceDir, componentsInfo);
  int componentsInfoLen = dynlen(componentsInfo);

  dynClear(dsFileComponentName);
  dynClear(dsFileVersions);
  dynClear(dsFileComponent);
  int requiredComponentsLen = dynlen(requiredComponents);
  dsFileComponentName[requiredComponentsLen] = ""; // Initialize arrays of available components data
  dsFileVersions[requiredComponentsLen] = "";
  dsFileComponent[requiredComponentsLen] = "";

  for(int i=1;i<=requiredComponentsLen;i++){
    string requiredComponentName, requiredComponentVersion;
    fwInstallation_parseRequiredComponentNameVersion(requiredComponents[i], requiredComponentName, requiredComponentVersion);

    for(int j=1;j<=componentsInfoLen;j++){
      string fileComponentName = componentsInfo[j][1];
      if(!patternMatch(requiredComponentName, fileComponentName)){
        continue;
      }

      string fileComponentVersion = componentsInfo[j][2];
      string fileComponent = componentsInfo[j][5];
      fwInstallation_throw("Required component found in distribution:" + requiredComponentName + ". Comparing versions", "info", 10);

      dsFileComponentName[i] = fileComponentName;
      dsFileVersions[i] = fileComponentVersion;

      if(_fwInstallation_CompareVersions(fileComponentVersion, requiredComponentVersion, false, false, true) != 1){
        fwInstallation_throw("Distribution version NOT OK. Component: " + fileComponentName + " in version: " + fileComponentVersion +
                             ", version required: " +  requiredComponentVersion + ". Required component cannot be installed.");
        retVal = -1;
        break;
      }
      fwInstallation_throw("Distribution version OK. Proceeding with the installation: " + fileComponentVersion + " required: " +  requiredComponentVersion, "info", 10);
      fwInstallation_throw("Component description file: " + fileComponent, "info", 10);
      dsFileComponent[i] = fileComponent;
      break;
    }
    if(dsFileComponentName[i] == ""){
      fwInstallation_throw("Required component missing. Component: " + requiredComponentName + " not found in the source directory.");
      retVal = -1;
    }
  }
  // Display error message when some of the required components are missing
  if(dynCount(dsFileComponentName, "") > 0){
    fwInstallation_throw("Not all required components were found in source directory.");
    retVal = -1;
  }
  return retVal;
}

/** This function checks if a given component is correctly installed

@param componentName: Name of the component to be checked
@param version: Version of the component to be checked. Optional parameter: if emtpy it checks for any version.
@return 0 if the component version or newer correctly installed,  -1 if the component is not installed correctly (missing required components) or just not installed
@author F. Varela
*/
int fwInstallation_checkInstalledComponent(string componentName, string version = "")
{
  string componentDP = fwInstallation_getComponentDp(componentName);
  if(!dpExists(componentDP)){
    return -1;
  }

  bool requiredInstalled;
  string componentVersionString, installationDirectory;
  if(dpGet(componentDP + ".componentVersionString:_online.._value", componentVersionString,
           componentDP + ".installationDirectory:_online.._value", installationDirectory,
           componentDP + ".requiredInstalled:_online.._value", requiredInstalled) != 0){
    fwInstallation_throw("fwInstallation_checkInstalledComponent()-> Failed to retrieve component information from datapoint, cannot continue", "ERROR");
    return -1;
  }

  if(version != "" && !_fwInstallation_CompareVersions(componentVersionString, version)){
    fwInstallation_throw("fwInstallation_checkInstalledComponent()-> An old version:" + componentVersionString + " of the component: " +
                         componentName + " is installed in this system. Requested version: " + version, "INFO", 10);
    return -1;
  }

  if(!requiredInstalled){
    fwInstallation_throw("fwInstallation_checkInstalledComponent()-> Version:" + componentVersionString + " of the component: " +
                         componentName + " is installed but not all required components", "INFO", 10);
    return -1;
  }
  //fwInstallation_throw("fwInstallation_checkInstalledComponent()-> Version:"+ componentVersionString +" of the component: " + componentName + " installed in this system", "INFO", 10);
  return 0;
}

/** This function checks if a previous installation of a particular directory exists in the target directiory
@param destinationDir (in) target directory
@param componentName (in) name of the component to be checked
@param versionInstalled (in) version of the component installed, if any
@return 0 if OK, -1 if error
*/
int fwInstallation_checkTargetDirectory(string destinationDir, string componentName, string &versionInstalled)
{
  dyn_string componentFiles = getFileNames(destinationDir, componentName + ".xml");

  if(dynlen(componentFiles) >0)
  {
    dyn_dyn_mixed componentInfo;
    fwInstallationXml_load(destinationDir + "/" + componentFiles[1], componentInfo);
    versionInstalled = componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
    return 1;
  }

  versionInstalled = "";
  return 0;
}


/** This function retrieves the files in a directory recursing over sub-directories
@param dir (in) directory where to look for files
@param pattern (in) search pattern
@return list of file found as a dyn_string
*/
dyn_string fwInstallation_getFileNamesRec(string dir = ".", string pattern = "*")
{
	dyn_string tempDynString;
	dyn_string allFileNames;
	string newDir = "/*";
	dynClear(allFileNames);
	fwInstallation_recurserFileNames(dir, "*", allFileNames);

	if(dynlen(allFileNames) > 0)
		for(int i=1; i<=dynlen(allFileNames); i++)
		{
			strreplace(allFileNames[i], dir + "/", "");
			strreplace(allFileNames[i], "//", "/");
		}

    if(pattern != "*")
      pattern = "*" + pattern;

	for(int i=1; i<=dynlen(allFileNames); i++){
		if(patternMatch(pattern, allFileNames[i]))
			dynAppend(tempDynString, allFileNames[i]);
	}
	return tempDynString;
}

/** Helper function used by fwInstallation_getFileNamesRec
@param dir (in) directory where to look for files
@param pattern (in) search pattern
@param fileNames (out) names of the files found
*/
fwInstallation_recurserFileNames(string dir, string pattern, dyn_string &fileNames)
{
  dyn_string tempDynString = fwInstallation_getSubdirectories(dir + "/", pattern);
	dyn_string tempDynString2 = getFileNames(dir, pattern, FILTER_FILES);

  int tempDynString2Len = dynlen(tempDynString2);
  for(int i=1;i<=tempDynString2Len;i++){
    tempDynString2[i] = dir + "/" + tempDynString2[i];
  }
	dynAppend(fileNames, tempDynString2);

  int tempDynStringLen = dynlen(tempDynString);
 	for(int i=1;i<=tempDynStringLen;i++){
    fwInstallation_recurserFileNames(dir + "/" + tempDynString[i] + "/", pattern, fileNames);
  }
}

/** This function retrieves the full path to the XML description file of a component
@param componentName (in) name of the component
@param componentVersion (in) version of the component (legacy, not used)
@param sourceDir (in) source directory
@param descriptionFile (out) XML description file
@param isItSubComponent (out) indicates if it is a subcomponent or not
@return 0 if OK, -1 if error
*/
int fwInstallation_getDescriptionFile(string componentName,
                                      string componentVersion,
                                      string sourceDir,
                                      string &descriptionFile,
                                      bool &isItSubComponent)
{
  string fileName = componentName + ".xml";
  dyn_dyn_string componentsInfo;

  fwInstallation_getAvailableComponents(makeDynString(sourceDir), componentsInfo, componentName);
  for(int i =1; i <= dynlen(componentsInfo); i++){

	  if(componentsInfo[i][1] == componentName && componentsInfo[i][2] == componentVersion)
    {
	    descriptionFile = componentsInfo[i][4];

	    if(componentsInfo[i][3] == "no")
	      isItSubComponent = false;
	    else
	      isItSubComponent = true;

        return 0;
    }
  }
  return -1;
}

/** This function parses the xml file of a coponent to find out if it is a sub-component
@param xmlFile (in) XML file name
@param isSubComponent (out) indicates if it is a subcomponent or not
@return 0 if OK, -1 if error
*/
int fwInstallation_isSubComponent(string xmlFile, bool &isSubComponent)
{
  dyn_dyn_mixed componentInfo;
  isSubComponent = false;
  if(fwInstallationXml_load(xmlFile, componentInfo))
  {
     fwInstallation_throw("fwInstallation_isSubComponent() -> Could not load XML file " + xmlFile + ". Aborted.", "error", 4);
     return -1;
  }
  isSubComponent = componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT][1];

  return 0;

}
/** This function returns the port used by the distribution manager of the local project
@return port number
*/
int fwInstallation_getDistPort()
{
  int port;
  string filename = PROJ_PATH + "/config/config";
  string section = "dist";

  paCfgReadValue(filename,section, "distPort", port);

  if(port == 0)
    port = 4777;

  return port;
}

/** This function returns the redundancy port of the local project
@return port number
*/
int fwInstallation_getReduPort()
{
  int port;
  const string filename = PROJ_PATH + "/config/config";
  const string section = "redu";

  // reduPort is the new configuration entry. portNr is deprecated
  paCfgReadValue(filename, section, "reduPort", port);

  // FIXME: backward compatibility, to be removed in future
  if(port == 0)
    paCfgReadValue(filename, section, "portNr", port);

  if(port == 0)
    port = 4899;

  return port;
}

/** This function returns the split port of the local project
@return port number
*/
int fwInstallation_getSplitPort()
{
  int port;
  string filename = PROJ_PATH + "/config/config";
  string section = "split";

  paCfgReadValue(filename,section, "splitPort", port);

  if(port == 0)
    port = 4778;

  return port;
}

/** This function returns the pmon user (not yet implemented)
@return pmon user
*/
string fwInstallation_getPmonUser()
{
   return "N/A";
}

/** This function returns the pmon pwd (not yet implemented)
@return pmon user
*/
string fwInstallation_getPmonPwd()
{
   return "N/A";
}

/** This function returns hostname 'localhost'
  */
string fwInstallation_getPmonHostname()
{
  string pmonHost = "localhost";
  if(VERSION_DISP == "3.11-SP1") // Emulate 3.11 behaviour
    pmonHost = fwInstallation_getHostname();
  return pmonHost;
}

/** This function returns the properties of the local project as a dyn_mixed array
@param projectInfo (in) Project properties
@return 0 if OK, -1 if error
*/
int fwInstallation_getProjectProperties(dyn_mixed &projectInfo)
{
  string pvssOs;
  dyn_string ds = eventHost();
  string hostname = strtoupper(ds[1]);
  if(_WIN32)
    pvssOs = "WINDOWS";
  else
    pvssOs = "LINUX";

  string fwInstToolVer;
  fwInstallation_getToolVersionLocal(fwInstToolVer);

  projectInfo[FW_INSTALLATION_DB_PROJECT_NAME] = PROJ;
  projectInfo[FW_INSTALLATION_DB_PROJECT_HOST] = hostname;
  projectInfo[FW_INSTALLATION_DB_PROJECT_DIR] = PROJ_PATH;
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] = getSystemName();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] = getSystemId();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PORT] = pmonPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_USER] = fwInstallation_getPmonUser();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PWD] = fwInstallation_getPmonPwd();
  projectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER] = fwInstToolVer;

  if(fwInstallationDB_getUseDB())
    projectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED] = fwInstallationDB_getCentrallyManaged();
  else
    projectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED] = 0;

  projectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] = VERSION_DISP;
  projectInfo[FW_INSTALLATION_DB_PROJECT_DATA] = dataPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] = eventPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_DIST] = fwInstallation_getDistPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT] = fwInstallation_getReduPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT] = fwInstallation_getSplitPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW] = 1;
  projectInfo[FW_INSTALLATION_DB_PROJECT_UPGRADE] = "";
  projectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS]= fwInstallation_getToolStatus();
//  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_NR] = fwInstallation_getRedundancyNumber();
  ds = eventHost();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER] = strtoupper(ds[1]);


  if(_WIN32)
    projectInfo[FW_INSTALLATION_DB_PROJECT_OS] = "WINDOWS";
  else
    projectInfo[FW_INSTALLATION_DB_PROJECT_OS] = "LINUX";

  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = dynlen(ds) > 1 && ds[2] != ""?strtoupper(ds[2]):hostname;
  projectInfo[FW_INSTALLATION_DB_PROJECT_INSTALL_ONLY_IN_SPLIT] = fwInstallation_getInstallOnlyInSplit();
  projectInfo[FW_INSTALLATION_DB_PROJECT_RESTORE_REDUNDANCY_AFTER_INST] = fwInstallation_getRestoreRedundancyAfterInstallation();

  return 0;
}

/** Saves DB connection configuration stored in internal dp to fwInstallationInit.config file.
  * @return 0 when success, -1 when file creation failed
  */
int fwInstallation_createDbInitFile()
{
  const dyn_string dbConfigDpes = makeDynString(
      "fwInstallation_agentParametrization.db.connection.server",
      "fwInstallation_agentParametrization.db.connection.username",
      "fwInstallation_agentParametrization.db.connection.schemaOwner",
      "fwInstallation_agentParametrization.db.connection.password",
      "fwInstallation_agentParametrization.db.connection.initialized",
      "fwInstallation_agentParametrization.db.useDB");
  return fwInstallationPackager_createDpl(getPath(CONFIG_REL_PATH) + gFwInstallationInitFile, dbConfigDpes);
}

/** This function checks if pmon is protected with a username and a pwd
@return 0 if PMON is NOT protected, 1 otherwise
*/
int fwInstallation_isPmonProtected()
{
  bool err;
  string str, host;
  int port, iErr = paGetProjHostPort(PROJ, host, port);
  dyn_dyn_string dsResult;

  paVerifyPassword(PROJ, "", "", iErr);
  if(iErr > 0)
    return 1;

  return 0;
}
/** This function returns post install files that are scheduled to run
  * @param allPostInstallFiles:	dyn_string to contain the list of post install files
  * @return 0 - "success"  -1 - error
  * @author S. Schmeling
  */
int fwInstallation_postInstallToRun(dyn_string & allPostInstallFiles)
{
  dyn_string dynPostInstallFiles_all;
  string dp = fwInstallation_getInstallationPendingActionsDp();

  if(dpExists(dp))
  {
    // get all the post install init files
    allPostInstallFiles = fwInstallation_getProjectPendingPostInstalls();
    return 0;
  }
  else
  {
		  dynClear(allPostInstallFiles);
		  return -1;
  }
}
/** This function gets list of sections in config file into a dyn_string
@param dsSectionList (out)  dyn_string that will contain names of the all configs' sections
@param sPattern (in)  string to define the pattern
@return 0 - sections with specified pattern were forund in config file,
        -1 - error (config file cannot be loaded),  -2 - no sections with given pattern were found in config file (dsSectionList is empty)
@author D. Dyngosz
*/
int fwInstallation_getSections(dyn_string &dsSectionList, string sPattern = "")
{
  dynClear(dsSectionList);

  string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

  dyn_string configLines;
  if(_fwInstallation_getConfigFile(configLines) != 0)
    return -1;

  int configLinesLen = dynlen(configLines);
  for (int i=1;i<=configLinesLen;i++)
  {
    string configLine = strltrim(strrtrim(configLines[i]));
    if(fwInstallation_config_isSectionDefinition(configLine)){
      int iEndPos = strpos(configLine, FW_INSTALLATION_CONFIG_SECTION_END_CHAR);
      if(iEndPos > 1) { //section exist
        dynAppend(dsSectionList, substr(configLine, 1, iEndPos-1));
      }
    }
  }
  if(sPattern != ""){
    dsSectionList = dynPatternMatch(sPattern, dsSectionList);
  }
  if(dynlen(dsSectionList)<1)
    return -2;

  return 0;
}
/** This function gets a specified section into a dyn_string

@param section: string to define the section
@param configEntry: dyn_string that will contain the lines for the section
@return 0 - "success"  -1 - error  -2 - section does not exist
@author S. Schmeling
*/

int fwInstallation_getSection(string section, dyn_string & configEntry )
{
	dyn_string configLines;

	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;

	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				if(sectionFound == FALSE)
				{
					sectionFound = TRUE;
				}
				j = 1;
				do
				{
					if(i+j <= dynlen(configLines))
					{
						tempLine = configLines[i+j];
						if(strpos(strltrim(strrtrim(tempLine)),"[") != 0)
						{
//							if(tempLine != "")
//							{
							dynAppend(tempLines,tempLine);
//							}
							j++;
						}
					}
				}
				while ((strpos(strltrim(strrtrim(tempLine)),"[") != 0) && (i+j <=dynlen(configLines)));
				i += j-1;
			}
		}
		if(sectionFound == TRUE)
		{
			configEntry = tempLines;
			return 0;
		} else {
			return -2;
		}
	} else {
		return -1;
	}
}


/** This function sets a specified section from a dyn_string

@param section: string to define the section to where the data has to written
@param configEntry: dyn_string that contains the lines for the section
@return 0 - "success"  -1 - error
@author S. Schmeling
*/

int fwInstallation_setSection( string section, dyn_string configEntry )
{
	if(fwInstallation_clearSection( section ) != -1)
	{
		return fwInstallation_addToSection( section, configEntry );
	} else {
		return -1;
	}
}


/** This function will delete all entries of the specified section as well as all but the first header.

@param section: string to define the section which will be cleared (first header will stay)
@return 0 - "success"  -1 - error  -2 - section does not exist
@author S. Schmeling
*/

int fwInstallation_clearSection( string section )
{
	dyn_string configLines;
	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;

	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				if(sectionFound == FALSE)
				{
					sectionFound = TRUE;
				} else {
					dynAppend(tempPositions,i);
				}
				if(i < dynlen(configLines))
				{
					j = 1;
					do
					{
						tempLine = configLines[i+j];
						if(strpos(strltrim(strrtrim(tempLine)),"[") != 0)
						{
							dynAppend(tempPositions,i+j);
							if(tempLine != "")
							{
								dynAppend(tempLines,tempLine);
							}
							j++;
						}
					}
					while ((strpos(strltrim(strrtrim(tempLine)),"[") != 0) && (i+j <=dynlen(configLines)));
					i += j-1;
				}
			}
		}
		if(dynlen(tempPositions)>0)
		{
			for (i=dynlen(tempPositions); i>0; i--)
			{
				dynRemove(configLines, tempPositions[i]);
			}
		}
		if(sectionFound == TRUE)
		{
			return fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
}

/** This function adds the given lines to a section in the config file.

@param section: string to define the section where the data has to be added (will be created if not existing)
@param configEntry: dyn_string containing the lines to be added
@return 0 - "success"  -1 - error
@author S. Schmeling
*/
int fwInstallation_addToSection( string section, dyn_string configEntry )
{
	dyn_string configLines;

	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;

	string configFile = getPath(CONFIG_REL_PATH) + FW_INSTALLATION_CONFIG_FILE_NAME;

	j = -1;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				j = i;
				break;
			}
		}
		tempLines = configEntry;
		if(j > 0)
		{
			if(j+1 <= dynlen(configLines))
				dynInsertAt(configLines,tempLines,j+1);
			else
				dynAppend(configLines,tempLines);
		} else {
			tempLine = "[" + section + "]";
			dynInsertAt(tempLines,tempLine,1);
			dynAppend(configLines,tempLines);
		}
		return fwInstallation_saveFile(configLines, configFile);
	} else {
		return -1;
	}
}

int fwInstallation_getInstallOnlyInSplit()
{
  int installInSplit = 0;
  string dp = fwInstallation_getAgentDp() + ".redundancy.installOnlyInSplit";
  if (dpExists(dp))
  {
    dpGet(dp, installInSplit);
  }
  return installInSplit;
}

void fwInstallation_setInstallOnlyInSplit(int installOnlyInSplit)
{
  int currentInstallInSplit = 0;
  string dp = fwInstallation_getAgentDp() + ".redundancy.installOnlyInSplit";
  if (dpExists(dp))
  {
    dpGet(dp, currentInstallInSplit);
    if (currentInstallInSplit != installOnlyInSplit)
      dpSet(dp, installOnlyInSplit);
  }
}
int fwInstallation_getRestoreRedundancyAfterInstallation()
{
  int restore = 0;
  string dp = fwInstallation_getAgentDp() + ".redundancy.restoreRedundancyAfterInstallation";
  if (dpExists(dp))
  {
    dpGet(dp, restore);
  }
  return restore;
}

void fwInstallation_setRestoreRedundancyAfterInstallation(int restore)
{
  int currentRestore = 0;
  string dp = fwInstallation_getAgentDp() + ".redundancy.restoreRedundancyAfterInstallation";
  if (dpExists(dp))
  {
    dpGet(dp, currentRestore);
    if (currentRestore != restore)
      dpSet(dp, restore);
  }
}

string fwInstallation_getLastInstToolSourcePath()
{
  string lastPath;
  string dp = fwInstallation_getInstallationDp() + ".lastInstToolSourcePath";
  if (dpExists(dp))
  {
    dpGet(dp, lastPath);
  }
  return lastPath;
}

void fwInstallation_setLastInstToolSourcePath(string lastPath)
{
  string dp = fwInstallation_getInstallationDp() + ".lastInstToolSourcePath";
  if (dpExists(dp))
  {
    dpSet(dp, lastPath);
  }
}

/** This function retrieves the component information from the xml file and
	displays it in the panel
@param descFile: the name of a file with component description
@author M.Sliwinski
*/
void fwInstallationXml_getComponentDescription(string descFile)
{
  dyn_string tags, values;
  dyn_anytype attribs;

  if(fwInstallationXml_get(descFile, tags, values, attribs))
  {
    fwInstallation_throw("fwInstallationXml_getComponentDescription() -> Cannot load " + descFile + " file ");
    return;
  }

  string requiredName;
  string requiredVersion;

  for(int i = 1; i <= dynlen(tags); i++)
  {
  	switch(tags[i])
				{
					case "file" : 		selectionOtherFiles.appendItem(values[i]);
										break;

					case "name":  		TextName.text = values[i];
										break;

					case "desc":		selectionDescription.appendItem(values[i]);
										break;

					case "version": 	TextVersion.text = values[i];
										break;

					case "date": 		TextDate.text = values[i];
										break;

					case "required":	if(values[i] != "")
										{
											fwInstallation_parseRequiredComponentNameVersion(values[i], requiredName, requiredVersion);
											selectionRequiredComponents.appendLine("requirement", requiredName + " ver.: " + requiredVersion);
										}
										break;

					case "config":		selectionConfigFiles_general.appendItem(values[i]);
										break;

					case "script": 		selectionScripts.appendItem(values[i]);
										break;

					case "postInstall": selectionPostInstallFiles.appendItem(values[i]);
										break;

					case "init": 		selectionInitFiles.appendItem(values[i]);
										break;

					case "config_windows": 	selectionConfigFiles_windows.appendItem(values[i]);
											break;

					case "config_linux" : 	selectionConfigFiles_linux.appendItem(values[i]);
											break;

					case "dplist":		selectionDplistFiles.appendItem(values[i]);
										break;

					case "includeComponent": strreplace(values[i], "./", "");
											 selectionSubComponents.appendItem(values[i]);
											 break;

				} // end switch
			} // end while
}

const string FW_INSTALLATION_PATH_SEPARATOR = "/";


/** This function normalises the path. After execution of the function the given argument is normalised - all backslashes in path are replaced with slashes.
  * Note: Leading "./" is removed from path.
  * @param projPath: Project path (in/out)
  * @return 0 if path was successfully normalised, -1 in case of error
*/
int fwInstallation_normalizePath(string &projPath, bool addTrailingSlash = false)
{
  string tempPath = projPath;

  //handle UNC paths, it is enough to replace double backslashes with double slashes (although path in that form is not handled by windows file explorer)
  bool isUnc = false;
  if(patternMatch("\\\\*", projPath) || patternMatch("//*", projPath))//double backslashes for original paths, double slashes for paths that were normalized previously
  {
    isUnc = true;
    tempPath = substr(projPath, 2);
  }

  if(strreplace(tempPath, "\\", FW_INSTALLATION_PATH_SEPARATOR) == -1)
  {
    fwInstallation_throw("fwInstallation_normalizePath() -> failed to convert \"\\\"");
    return -1;
  }
  dyn_string pathElem = strsplit(tempPath, FW_INSTALLATION_PATH_SEPARATOR);
  if(dynlen(pathElem) == 0)
  {
    fwInstallation_throw("fwInstallation_normalizePath() -> empty path");
    return -1;
  }

  if(tempPath[0] == FW_INSTALLATION_PATH_SEPARATOR)//linux absolute path
    tempPath = FW_INSTALLATION_PATH_SEPARATOR;
  else
    tempPath = "";

  int pathElemLen = dynlen(pathElem);
  for(int i=1;i<=pathElemLen;i++)
  {
    if(pathElem[i] != "" && pathElem[i] != ".")
      tempPath += pathElem[i] + FW_INSTALLATION_PATH_SEPARATOR;
  }
  if(!addTrailingSlash)
    tempPath = strrtrim(tempPath,"/");

  if(isUnc)
    tempPath = "//" + tempPath;

  projPath = tempPath;
  return 0;
}

/** Normalize list of paths. Replaces all backslashes with slashes.
  * @param projPaths - list of project paths
  * @return In case of error returns -1 (no changes are made to input variable),
  *         normally (OK) returns 0
 */
int fwInstallation_normalizePathList(dyn_string &projPaths, bool addTrailingSlash = false)
{
  // Get a copy to prevent changes in case of error
  dyn_string tmpPaths = projPaths;

  int pathCount = dynlen(projPaths);
  for(int i=1; i<=pathCount; i++)
  {
    if(fwInstallation_normalizePath(tmpPaths[i], addTrailingSlash) == -1)
    {
      return -1; // In case of error, exit (no changes made to projPaths)
    }
  }

  projPaths = tmpPaths;
  return 0;
}

/** Returns a list of lines in given string, breaking at line boundaries.
  * New line characters (LF or CR+LF) are removed and don't occur in the returned list.
  * If string contains n new line characters then the returned list has size n+1. However if
  * the last new line character is also the last character of the string then last empty substring
  * is ignored and returned list has size n.
  * @note This function is recommended to use instead of strsplit(string, "\n") as it provides
  *       the correct handling of carriage return (CR) character in UNIX systems.
  * @param s (in)  String to be splitted.
  * @return List of lines in given string.
  */
dyn_string fwInstallation_splitLines(string s)
{
  if(!_WIN32) strreplace(s, "\r\n", "\n");
  return strsplit(s, "\n");
}

/** Returns a given Powershell command, formatted to be run from Windows Command Prompt (in system() function call)
  * @note Any double qoute character in the PS command is escaped with backslash (\) in the output string.
  * @note NUL is passed through stdin to ensure that PowerShell exists after execution of given script is finished.
  * @param powershellCommand (in)  PowerShell command
  * @return Windows Command Prompt command, that executes the given PowerShell command.
  */
string fwInstallation_formatPowershellCommandForWinCmd(string powershellCommand){
  strreplace(powershellCommand, "\"", "\\\"");
  return "powershell -Command \"" + powershellCommand + "\" < NUL";
}

/** Returns the version string from given version and tag.
  * @param version (in)  Version (pattern: X.X.X)
  * @param versionTag (in)  Tag (eg. "beta-01", "SNAPSHOT-201810140930", "")
  * @return Version string of pattern: <version>-<versionTag> or <version> when versionTag is empty (stable release)
  */
string fwInstallation_getVersionString(string version, string versionTag)
{
  return version + ((versionTag != "")?("-" + versionTag):"");
}

/** This function removes given files or folders from the installation directory of specified component.
  * It is intended for performing cleanup of component obsolete files in component installation script (init [recommended] or post-install).
  * If component is not installed, function returns immediately. If file does not exist already, it is skipped.
  * @param componentName (in)  Name of the component
  * @param obsoleteFiles (in)  List of files or folders to be removed (relative paths from component installation directory);
  *                            note that folder-removal is not recursive unless 'recursive' parameter is set to true
  * @param recursive (in)      Remove folders recursively if set to true; default=false
  */
void fwInstallation_cleanupObsoleteFiles(string componentName, const dyn_string &obsoleteFiles, bool recursive=false){
  string version;
  if(!fwInstallation_isComponentInstalled(componentName, version)){
    return; // Component is not installed, no need for cleanup
  }
  dyn_anytype installationDirInfo;
  if(fwInstallation_getComponentInfo(componentName, "installationdirectory", installationDirInfo) != 0 ||
     dynlen(installationDirInfo) != 1){
    fwInstallation_throw("Failed to retrieve installation directory of " + componentName + ". Cleanup of obsolete files is not possible.", "WARNING", 28);
    return;
  }
  string installationDir = installationDirInfo[1];
  fwInstallation_cleanupObsoleteFilesFromPath(componentName, installationDir, obsoleteFiles, recursive);
}

/** This function removes given files or folders from the specified path if they exists.
  * @note This is for internal use in fwInstallation. In the component cleanup script use fwInstallation_cleanupObsoleteFiles() function instead.
  * @param componentName (in)  Name of the component
  * @param path (in)           Common part of the path to obsolete files
  * @param obsoleteFiles (in)  List of files or folders to be removed (relative paths);
  *                            note that folder-removal is not recursive unless 'recursive' parameter is set to true
  * @param recursive (in)      Remove folders recursively if set to true; default=false
  */
void fwInstallation_cleanupObsoleteFilesFromPath(string componentName, string path, const dyn_string &obsoleteFiles, bool recursive = false){
  int obsoleteFilesLen = dynlen(obsoleteFiles);
  for(int i=1;i<=obsoleteFilesLen;i++){
    string obsoleteFile = obsoleteFiles[i];
    fwInstallation_normalizePath(obsoleteFile); // ensure that path has UNIX format
    // do not allow any parent paths
    if(strpos(obsoleteFile, "/..") >= 0 || obsoleteFile == ".."){
      fwInstallation_throw("Refusing to remove " + componentName + " file containing parent path: " + obsoleteFile + " - skipping it", "WARNING", 28);
      continue;
    }

    if(path != "" && !patternMatch("*/", path)){
      path += "/";
    }
    string obsoleteFilePath = path + obsoleteFile;
    int retVal=0;
    if(isdir(obsoleteFilePath)){
      if (recursive) {
       bool ok = rmdir(obsoleteFilePath,recursive);
       if (!ok) retVal=-1;
      } else {
       retVal = fwInstallation_removeEmptyDirectory(obsoleteFilePath);
      }
      if(retVal > 0){
        fwInstallation_throw("Directory " + obsoleteFilePath + " marked as obsolete by " + componentName + " was not removed because it is not empty. " +
                             "You may verify its content and remove it manually.", "INFO", 28);
        continue;
      }else if (retVal < 0){
        fwInstallation_throw("Failed to remove obsolete " + componentName + " dir: " + obsoleteFilePath + " . Need to be removed manually", "WARNING", 28);
        continue;
      }
    }else if(isfile(obsoleteFilePath)){
      if(fwInstallation_deleteFiles(makeDynString(obsoleteFile), path) != 0){
        fwInstallation_throw("Failed to remove obsolete " + componentName + " file: " + obsoleteFilePath + " . Need to be removed manually", "WARNING", 28);
        continue;
      }
    }else{
      continue; // File does not exist, jump to the next one
    }
    fwInstallation_throw(componentName + " obsolete file/dir: " + obsoleteFilePath + " was removed.", "INFO", 28);
  }
}

/** This function removes specified directory only if it is empty - it does not contain any files nor subfolders.
  * @param dirPath (in)  Path to the directory that should be removed.
  * @return 0 when directory was removed or it didn't exist. 1 if it could not be removed because it is not empty
  *        -1 when it could not be removed due to other reasons (eg. insufficent access rights)
  */
int fwInstallation_removeEmptyDirectory(string dirPath){
  if(!isdir(dirPath)){ // directory does not exists, nothing to do... exit
    return 0;
  }
  dyn_string files = getFileNames(dirPath);
  dyn_string dirs = fwInstallation_getSubdirectories(dirPath);
  if(dynlen(files) > 0 || dynlen(dirs) > 0){
    return 1;
  }
  return rmdir(dirPath)?0:-1;
}

/** Returns the list of subdirectories in the given directory that match the pattern. The list does not contain current "." and parent ".." directory.
  * @param dir (in)  Path to the directory where to look for subdirectories
  * @param pattern (in)  Subdirectory name pattern, when not provided then all subdirectories are returned ("*")
  * @return List of subdirectories as dyn_string
  */
dyn_string fwInstallation_getSubdirectories(string dir, string pattern = "*"){
  dyn_string subdirs = getFileNames(dir, pattern, FILTER_DIRS);
  int currDirPos = dynContains(subdirs, ".");
  if(currDirPos > 0){
    dynRemove(subdirs, currDirPos);
  }
  int parentDirPos = dynContains(subdirs, "..");
  if(parentDirPos > 0){
    dynRemove(subdirs, parentDirPos);
  }
  return subdirs;
}

/** Registers components pair (component and its required component) for dependency tracking during components installation.
  * It is registered in global mapping variable gFwInstallationTrackDependency.
  * @param triggeringComponent (in)  Component requiring another component to be installed
  * @param requiredComponent (in)  Component that is required
  * @return 0 if registration ok, -1 when it failed, because circular dependency was detected.
  */
int fwInstallation_trackDependency_register(string triggeringComponent, string requiredComponent){
  if(fwInstallation_trackDependency_isCircular(triggeringComponent, requiredComponent)){
    return -1;
  }

  if(!mappingHasKey(gFwInstallationTrackDependency, triggeringComponent)){
    gFwInstallationTrackDependency[triggeringComponent] = makeDynString(requiredComponent);
  }else{
    dynAppend(gFwInstallationTrackDependency[triggeringComponent], requiredComponent);
  }
  return 0;
}

/** Unregisters component and all its required components from dependency tracking.
  * @param triggeringComponent (in)  Component to be unregistered along with its dependencies.
  */
void fwInstallation_trackDependency_unregister(string triggeringComponent){
  if(mappingHasKey(gFwInstallationTrackDependency, triggeringComponent)){
    mappingRemove(gFwInstallationTrackDependency, triggeringComponent);
  }
}

/** Clears all dependency tracking entries.
  */
fwInstallation_trackDependency_clear(){
  mappingClear(gFwInstallationTrackDependency);
}

/** Checks if given components pair (component and its required component) creates circular dependency chain with already tracked dependencies.
  * @param triggeringComponent (in)  Component requiring another component to be installed
  * @param requiredComponent (in)  Component that is required
  * @return true if given pair creates circular dependency chain, false if not
  */
bool fwInstallation_trackDependency_isCircular(string triggeringComponent, string requiredComponent){
  dyn_string recursiveChain;
  if(fwInstallation_trackDependency_findCircularRecursively(triggeringComponent, requiredComponent, recursiveChain)){
   fwInstallation_throw("Circular dependency chain: " + strjoin(recursiveChain, "->") + "->" + triggeringComponent + "->" + requiredComponent, "ERROR");
    return true;
  }
  return false;
}

/** Checks for occurence of circular dependency chain in given components pair and tracked dependencies recursively.
  * @param triggeringComponent (in)  Component requiring another component to be installed
  * @param requiredComponent (in)  Component that is required
  * @param recursiveChain (out)  List of components checked recursively
  * @return true if circular dependency occurs for given pair, false if not
  */
private bool fwInstallation_trackDependency_findCircularRecursively(string triggeringComponent, string requiredComponent, dyn_string &recursiveChain){
  if(mappingHasKey(gFwInstallationTrackDependency, requiredComponent)){
    dynAppend(recursiveChain, requiredComponent);
    if(dynContains(gFwInstallationTrackDependency[requiredComponent], triggeringComponent) > 0){
      return true;
    }
    dyn_string nextLevelRequiredComponents = gFwInstallationTrackDependency[requiredComponent];
    int nextLevelRequiredComponentsLen = dynlen(nextLevelRequiredComponents);
    for(int i=1;i<=nextLevelRequiredComponentsLen;i++){
      if(fwInstallation_trackDependency_findCircularRecursively(triggeringComponent, nextLevelRequiredComponents[i], recursiveChain)){
        return true;
      }
    }
  }
  return false;
}

const int FW_INSTALLATION_DEV_TYPE_DP_PATTERN = 1;
const int FW_INSTALLATION_DEV_TYPE_DP_TYPE = 2;

//Device Types mapping - key: device type, value: {device type dp pattern, device type dp type}
mapping deviceTypesInfo = makeMapping(
    "SCHNEIDER_PLC", makeDynString("_unPlc_", "_UnPlc"),
    "SIEMENS_PLC", makeDynString("S7_PLC_", "S7_PLC"),
    "FEC", makeDynString("CRYOGTW_", "CRYOGTW")
    );

void fwInstallation_getDeviceTypes(dyn_string &devTypes)
{
  devTypes = mappingKeys(deviceTypesInfo);
}

const string FW_INSTALLATION_DEV_DP_PATTERN_WILDCARD = "*";
const string FW_INSTALLATION_DEV_DPE = ".configuration.subApplications";

/** This functions returns the dp pattern and dp type for given device type.
 * @param deviceType Device type name.
 * @param devicesDpt (out) Datapoint type of given device type name.
 * @return Datapoint pattern for given device type name or empty string when unknown device type.
*/
string _fwInstallation_getDevicesDpPattern(string deviceType, string &devicesDpt)
{
  if(!mappingHasKey(deviceTypesInfo, deviceType))
  {
    DebugTN("Unknown Device type: " + deviceType);
    return "";
  }

  string devicesDpPattern;
  if(dynlen(deviceTypesInfo[deviceType]) > 1)
  {
    devicesDpPattern = deviceTypesInfo[deviceType][FW_INSTALLATION_DEV_TYPE_DP_PATTERN] +
                       FW_INSTALLATION_DEV_DP_PATTERN_WILDCARD + FW_INSTALLATION_DEV_DPE;
    devicesDpt = deviceTypesInfo[deviceType][FW_INSTALLATION_DEV_TYPE_DP_TYPE];
  }
  else
  {
    DebugTN("Invalid device type dp info for: " + deviceType);
  }

  return devicesDpPattern;
}

const string FW_INSTALLATION_DEV_TYPE_GET_NAME_FUNCTION = "_fwInstallation_getDeviceName_";

string _fwInstallation_getDeviceName_FEC(string deviceDp)
{
  if(patternMatch("*__*", deviceDp))
    return substr(deviceDp, 0, (strlen(deviceDp) - 3));
  return deviceDp;
}

/** This functions gets the device name from device datapoint.
 * @param deviceDp Device datapoint.
 * @param deviceType Device type name.
 * @return Device name or empty string when unknown device type.
*/
string fwInstallation_getDeviceNameFromDp(string deviceDp, string deviceType)
{
  if(!mappingHasKey(deviceTypesInfo, deviceType))
  {
    DebugTN("Cannot get the device name. Unknown Device type: " + deviceType);
    return "";
  }

  deviceDp = dpSubStr(deviceDp, DPSUB_DP);
  strreplace(deviceDp, deviceTypesInfo[deviceType][FW_INSTALLATION_DEV_TYPE_DP_PATTERN], "");

  // execute additional name formatting function if there is any
  string formatNameFunction = FW_INSTALLATION_DEV_TYPE_GET_NAME_FUNCTION + deviceType;
  if(isFunctionDefined(formatNameFunction))
    deviceDp = callFunction(formatNameFunction, deviceDp);

  strreplace(deviceDp, "_", "-");
  return deviceDp;
}

const string FW_INSTALLATION_DEV_TYPE_GET_ADDITONAL_INFO_FUNCTION = "_fwInstallation_getDeviceAdditionalInfo_";

string _fwInstallation_getDeviceAdditionalInfo_SCHNEIDER_PLC(string deviceDp)
{
  return fwInstallation_getAdditionalPlcInfo(deviceDp);
}

string _fwInstallation_getDeviceAdditionalInfo_SIEMENS_PLC(string deviceDp)
{
  return fwInstallation_getAdditionalPlcInfo(deviceDp);
}

/** This function gets additional PLC info for the Schneider and Siemens PLCs.
 * @param plcDp (in) PLC datapoint
 * @return JSON formatted string with additional PLC info
*/
string fwInstallation_getAdditionalPlcInfo(string plcDp)
{
  string info = "{\"Application\":[\"Type\":\"<type>\",\"Framework\":\"<framework>\"," +
                "\"Import Date\":\"<importDate>\", \"PLC Application Version\":\"<plcApplicationVersion>\"]," +
                "\"Resources\":[\"PLC Baseline\":\"<baseline>\",\"PLC Resource Package\":\"<plcResourcePackage>\"," +
                "\"SCADA Resource Package\":\"<scadaResourcePackage>\"]}";
  string type;
  string framework;
  string importDate;
  string plcApplicationVersion;
  string baseline;
  string a;
  string b;
  string c;
  string plcResourcePackage;
  string scadaResourcePackage;

  dpGet(plcDp + ".version.import", framework,
        plcDp + ".configuration.importTime", importDate,
        plcDp + ".configuration.type", type,
        plcDp + ".version.PLCApplication", plcApplicationVersion,
        plcDp + ".version.PLCBaseline", baseline,
        plcDp + ".version.PLCresourcePackageMajor", a,
        plcDp + ".version.PLCresourcePackageMinor", b,
        plcDp + ".version.PLCresourcePackageSmall", c,
        plcDp + ".version.resourcePackage", scadaResourcePackage);

  plcResourcePackage = a + "." + b + "." + c;

  strreplace(info, "<type>", type);
  strreplace(info, "<framework>", framework);
  strreplace(info, "<importDate>", importDate);
  strreplace(info, "<plcApplicationVersion>", plcApplicationVersion);
  strreplace(info, "<baseline>", baseline);
  strreplace(info, "<plcResourcePackage>", plcResourcePackage);
  strreplace(info, "<scadaResourcePackage>", scadaResourcePackage);

  return info;
}

/** Retrieve existing devices of given type in given application on this system.
  @param deviceType Device type name.
  @param application Application name, when it is empty string then all devices will of given type will be retrieved.
  @param devices Variable to receive info about devices.
  @return 0 on success, -1 on error.

  @Note: Currently only information from 'Comment' field are filled, 'Info_URL' and 'Status' are missed.
         The 'Moon_Info' will be updated from MOON project.
*/
int fwInstallation_getDevices(string deviceType, string application, dyn_dyn_mixed &devices)
{
  string devicesDpt;
  string devicesDpPattern = _fwInstallation_getDevicesDpPattern(deviceType, devicesDpt);
  if(devicesDpPattern == "")
  {
    DebugTN("fwInstallation_getDevices(): Couldn't find dp pattern for given device type: " + deviceType);
    return -1;
  }

  dynClear(devices);

  //Check if device dpt exists in current system
  if(dynlen(dpTypes(devicesDpt)) < 1)
    return 0;

  dyn_string devDps = dpNames(getSystemName() + devicesDpPattern, devicesDpt);

  int n = dynlen(devDps);
  int k = 0;
  for(int i = 1; i <= n; i++)
  {
    dyn_string devApplications;
    dpGet(devDps[i], devApplications);
    if(dynContains(devApplications, application) == 0)
      continue;
    k++;

    string device = fwInstallation_getDeviceNameFromDp(devDps[i], deviceType);
    devices[k][FW_INSTALLATION_DB_WCCOA_DEV_NAME] = device;

    //get additional info if available
    string getAdditionalInfoFunction = FW_INSTALLATION_DEV_TYPE_GET_ADDITONAL_INFO_FUNCTION + deviceType;
    if(isFunctionDefined(getAdditionalInfoFunction))
      devices[k][FW_INSTALLATION_DB_WCCOA_DEV_COMMENT] = callFunction(getAdditionalInfoFunction,
                                                                      dpSubStr(devDps[i], DPSUB_SYS_DP));
    // Commented out intentionally, we don't have this information
    //devices[i][FW_INSTALLATION_DB_WCCOA_DEV_INFO_URL] = "";
    //devices[i][FW_INSTALLATION_DB_WCCOA_DEV_STATUS] = "";
  }

  return 0;
}

const int FW_INSTALLATION_INSTALLED_COMPONENT_NAME = 1;
const int FW_INSTALLATION_INSTALLED_COMPONENT_DISP_NAME_FORMAT = 2;
const int FW_INSTALLATION_INSTALLED_COMPONENT_VERSION = 3;
const int FW_INSTALLATION_INSTALLED_COMPONENT_HAS_HELP = 4;
const int FW_INSTALLATION_INSTALLED_COMPONENT_IS_SUBCOMPONENT = 5;

const string FW_INSTALLATION_COLOR_INSTALLATION_NOT_OK = "red";
const string FW_INSTALLATION_COLOR_BROKEN_DEPENDENCY = "STD_trend_pen6";
const string FW_INSTALLATION_COLOR_POSTINSTALL_PENDING = "STD_man";

/** Retrieves information about components installed in the project.
  * @param installedComponentsToDisplay (out)  Array of installed components information, note indexing: [information_type][component]
  * @param componentsIncorrectlyInstalled (out)  Flag that indicates if there are components installed incorrectly
  * @param componentsBrokenDependencies (out)  Flag that indicates if there are components with missing dependencies
  * @param componentsPendingPostInstallCount (out)  Counter of components with pending postinstall scripts
  * @param reduHostNum (in) Local host redu number, in non-redundant system it is always 1.
  * @return Number of installed components
  */
private int fwInstallation_ui_getInstalledComponentsInfo(dyn_dyn_mixed &installedComponentsToDisplay,
                                                         bool &componentsIncorrectlyInstalled,
                                                         bool &componentsBrokenDependencies,
                                                         int &componentsPendingPostInstallCount,
                                                         int reduHostNum)
{
  dyn_string componentDps = fwInstallation_getInstalledComponentDps(reduHostNum);
  int componentDpsLen = dynlen(componentDps);
  int index;
  dyn_string pendingSubcomponents; // List to store subcomponents for which datapoint has beed found but they could not be yet appended
                                   // to the array as subcomponents can be appended only if they have a parent component
  for(int i=1;i<=componentDpsLen;i++){
    fwInstallation_ui_getInstalledComponentsInfoRecursively(installedComponentsToDisplay, componentDps[i], "",
                                                            index, pendingSubcomponents, componentsIncorrectlyInstalled,
                                                            componentsBrokenDependencies, componentsPendingPostInstallCount,
                                                            reduHostNum);
  }

  int pendingSubcomponentsLen = dynlen(pendingSubcomponents);
  int cnt = 0;
  // Handle "orphans" (subcomponents without parents) as by default they are not appended to the array
  while(dynlen(pendingSubcomponents) > 0 && cnt < pendingSubcomponentsLen){
    // Note that current sollution is not optimal, may display incorrectly sub-sub-component (subcomponent of orphan subcomponent)
    string subcomponentDp = fwInstallation_getComponentDp(pendingSubcomponents[1], reduHostNum);
    // orphanSubcomponent - dummy parent component name for subcomponents without parent, this name must be non-empty to display a subcomponent
    fwInstallation_ui_getInstalledComponentsInfoRecursively(installedComponentsToDisplay, subcomponentDp, "orphanSubcomponent",
                                                            index, pendingSubcomponents, componentsIncorrectlyInstalled,
                                                            componentsBrokenDependencies, componentsPendingPostInstallCount,
                                                            reduHostNum);
    cnt++;
  }
  return index;
}

/** Retrieves information about particular installed component from datapoint.
  * Note: Does recursive call for subcomponents of current component.
  * @param installedComponentsToDisplay (out)  Array of installed components information, note indexing: [information_type][component]
  * @param componentDp (in)  Component datapoint name
  * @param parentComponent (in)  Name of the parent component, when empty then component doesn't have a parent
  * @param index (in/out)  Number of elements in installedComponentsToDisplay array
  * @param pendingSubcomponents (out)  List of subcomponents that could not be added as their parent is not in the array.
  * @param componentsIncorrectlyInstalled (out)  Flag that indicates if there are components installed incorrectly
  * @param componentsBrokenDependencies (out)  Flag that indicates if there are components with missing dependencies
  * @param componentsPendingPostInstallCount (out)  Counter of components with pending postinstall scripts
  * @param reduHostNum (in) Local host redu number, in non-redundant system it is always 1.
  */
private void fwInstallation_ui_getInstalledComponentsInfoRecursively(dyn_dyn_mixed &installedComponentsToDisplay,
                                                                     string componentDp,
                                                                     string parentComponent,
                                                                     int &index,
                                                                     dyn_string &pendingSubcomponents,
                                                                     bool &componentsIncorrectlyInstalled,
                                                                     bool &componentsBrokenDependencies,
                                                                     int &componentsPendingPostInstallCount,
                                                                     int reduHostNum)
{
  bool requiredInstalled, installationNotOK, postInstallPending, isItSubcomponent;
  dyn_string subcomponents;
  string componentName, componentVersionString, helpFile;
  if(dpGet(componentDp + ".name", componentName,
           componentDp + ".componentVersionString", componentVersionString,
           componentDp + ".helpFile", helpFile,
           componentDp + ".isItSubComponent", isItSubcomponent,
           componentDp + ".installationNotOK", installationNotOK,
           componentDp + ".postInstallPending", postInstallPending,
           componentDp + ".requiredInstalled", requiredInstalled,
           componentDp + ".subComponents", subcomponents) != 0){
    fwInstallation_throw("Failed to retrieve component information from dp: " + componentDp +
                         ". Components list may be incomplete", "WARNING");
    return;
  }

  bool isComponentInArray = (dynlen(installedComponentsToDisplay) >= FW_INSTALLATION_INSTALLED_COMPONENT_NAME) &&
                            (dynContains(installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_NAME], componentName) > 0);
  if(isComponentInArray){
    return; // Prevent adding same component multiple times (needed when components relationship (included/subcomponent) are incorrectly defined
  }

  if(isItSubcomponent){
    if(parentComponent == ""){ // Don't process subcomponents at the root level, wait until we get to subcomponent through its parent
      if(!isComponentInArray){
        dynAppend(pendingSubcomponents, componentName); // If subcomponent not yet in the list of components to display add it to pending subcomponents
      }
      return;
    } // else (parentComponent != "")
    int subCompPos = dynContains(pendingSubcomponents, componentName);
    if(subCompPos > 0){ // Subcomponent can be appended as it has a parent, remove it from the list of pending subcomponents if it is there
      dynRemove(pendingSubcomponents, subCompPos);
    }
  }

  string bgColor = "";
  if(installationNotOK){
    bgColor = FW_INSTALLATION_COLOR_INSTALLATION_NOT_OK;
  }else if(postInstallPending){
    bgColor = FW_INSTALLATION_COLOR_POSTINSTALL_PENDING;
  }else if(!requiredInstalled){
    bgColor = FW_INSTALLATION_COLOR_BROKEN_DEPENDENCY;
  }
  componentsIncorrectlyInstalled |= installationNotOK;
  componentsBrokenDependencies |= !requiredInstalled;
  componentsPendingPostInstallCount += postInstallPending?1:0;

  index++;
  installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_NAME][index] = componentName;
  installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_DISP_NAME_FORMAT][index] =
      makeDynString((isItSubcomponent?"_":"") + componentName, bgColor); // Formatted for table appendLines() method (name + background color)
  installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_VERSION][index] = componentVersionString;
  installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_HAS_HELP][index] = (helpFile != "");
  installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_IS_SUBCOMPONENT][index] = isItSubcomponent;

  dynSortAsc(subcomponents);
  int subcomponentsLen = dynlen(subcomponents);
  for(int i=1;i<=subcomponentsLen;i++){ // Get info about each subcomponent (recursive call)
    string subcomponentDp = fwInstallation_getComponentDp(subcomponents[i], reduHostNum);
    if(dpExists(subcomponentDp)){ // Only if subcomponent is installed
      fwInstallation_ui_getInstalledComponentsInfoRecursively(installedComponentsToDisplay, subcomponentDp, componentName,
                                                              index, pendingSubcomponents, componentsIncorrectlyInstalled,
                                                              componentsBrokenDependencies, componentsPendingPostInstallCount,
                                                              reduHostNum);
    }
  }
}

/** Displays status info of installed components (incorrect installation/missing dependencies).
  * @param fileIssueLabelShape (in)  Shape of label where to put status info
  * @param fileIssueArrowShape (in)  Shape of array to be displayed in case of component issues
  * @param componentsIncorrectlyInstalled (in)  Flag that indicates if there are components installed incorrectly
  * @param componentsBrokenDependencies (in)  Flag that indicates if there are components with missing dependencies
  * @param componentsPendingPostInstallNum (out)  Number of components with pending postinstall scripts
  */
private void fwInstallation_ui_updateInstalledComponentsStatusInfo(shape fileIssueLabelShape, shape fileIssueArrowShape,
                                                                   bool componentsIncorrectlyInstalled,
                                                                   bool componentsBrokenDependencies,
                                                                   int componentsPendingPostInstallNum)
{
  string statusInfoColor;
  if(componentsIncorrectlyInstalled || componentsBrokenDependencies){
    statusInfoColor = FW_INSTALLATION_COLOR_INSTALLATION_NOT_OK;
  }else if(componentsPendingPostInstallNum > 0){
    statusInfoColor = FW_INSTALLATION_COLOR_POSTINSTALL_PENDING;
  }
  bool displayStatusInfo = (statusInfoColor != "");
  fileIssueArrowShape.visible = displayStatusInfo;
  fileIssueLabelShape.visible = displayStatusInfo;
  if(displayStatusInfo){
    fileIssueArrowShape.foreCol(statusInfoColor);
    fileIssueArrowShape.backCol(statusInfoColor);
    fileIssueLabelShape.foreCol(statusInfoColor);
  }

  string errorLabel;
  if(componentsIncorrectlyInstalled){
    errorLabel = "Component(s) not correctly installed";
    if(componentsPendingPostInstallNum > 0){
      errorLabel += " and " + (string)componentsPendingPostInstallNum + " pending post-installs";
    }else if(componentsBrokenDependencies){
      errorLabel = " and broken dependencies";
    }
  }else if(componentsBrokenDependencies){
    errorLabel = "Component(s) have broken dependencies";
    if(componentsPendingPostInstallNum > 0){
      errorLabel += " and " + (string)componentsPendingPostInstallNum + " pending post-installs";
    }
  }else if(componentsPendingPostInstallNum > 0){
    errorLabel = (string)componentsPendingPostInstallNum + " component(s) with post-installs pending.";
  }
  fileIssueLabelShape.text = errorLabel;
}

/** Searches for components installed in project and displays them in 'Installed components' table.
  * @param tableShape (in)  Installed components table shape
  * @param fileIssueLabelShape (in)  Shape of label where to put status info
  * @param fileIssueArrowShape (in)  Shape of array to be displayed in case of component issues
  * @param subcomponentsVisible (in)  Flag that indicates if subcomponents should be shown (true) or hidden
  * @param reduHostNum (in) Local host redu number, default value (0) indicates that the number will be obtained automatically.
  */
synchronized void fwInstallation_ui_displayInstalledComponents(shape tableShape, shape fileIssueLabelShape, shape fileIssueArrowShape,
                                                               bool subcomponentsVisible, int reduHostNum = 0)
{
  const string tableHelpFillPattern = "[pattern,[center,any,help_2.xpm]]";
  const string tableFilesIssuesInitLabel = "Not checked";

  if(reduHostNum == 0){
    reduHostNum = fwInstallationRedu_myReduHostNum();
  }

  fwInstallation_checkComponentBrokenDependencies(reduHostNum); // Update information about dependencies status for components.

  bool componentsIncorrectlyInstalled, componentsBrokenDependencies;
  int componentsPendingPostInstallCount;
  dyn_dyn_mixed installedComponentsToDisplay;
  int installedComponentsNumber =
      fwInstallation_ui_getInstalledComponentsInfo(installedComponentsToDisplay, componentsIncorrectlyInstalled,
                                                   componentsBrokenDependencies, componentsPendingPostInstallCount,
                                                   reduHostNum);
  tableShape.deleteAllLines();

  if(installedComponentsNumber <= 0){ // When no components found, ensure that info about problems with components is hidden and leave function
    fwInstallation_ui_updateInstalledComponentsStatusInfo(fileIssueLabelShape, fileIssueArrowShape,
                                                          false, false, 0);
    return;
  }

  tableShape.appendLines(installedComponentsNumber,
                         "componentName", installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_DISP_NAME_FORMAT],
                         "componentVersion", installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_VERSION],
                         "isSubcomponent", installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_IS_SUBCOMPONENT]);

  if(reduHostNum == fwInstallationRedu_myReduHostNum()){ // On local peer
    for(int i=1;i<=installedComponentsNumber;i++){
      tableShape.cellValueRC(i-1, "filesIssuesCount", tableFilesIssuesInitLabel); // Fill the "Files issues" column
      if(installedComponentsToDisplay[FW_INSTALLATION_INSTALLED_COMPONENT_HAS_HELP][i]){
        tableShape.cellFillRC(i-1, "helpFile", tableHelpFillPattern); // Show help icon in "Help" column if it is available for component
      }
    }
  }

  fwInstallation_ui_filterComponentsTable(tableShape, subcomponentsVisible, true);
  fwInstallation_ui_updateInstalledComponentsStatusInfo(fileIssueLabelShape, fileIssueArrowShape,
                                                        componentsIncorrectlyInstalled, componentsBrokenDependencies,
                                                        componentsPendingPostInstallCount);
}

const string FW_INSTALLATION_COMPONENT_STATUS_INSTALLED = "Installed";

const int FW_INSTALLATION_AVAILABLE_COMPONENT_DISP_NAME = 1;
const int FW_INSTALLATION_AVAILABLE_COMPONENT_VERSION = 2;
const int FW_INSTALLATION_AVAILABLE_COMPONENT_XML = 3;
const int FW_INSTALLATION_AVAILABLE_COMPONENT_INST_STATUS = 4;
const int FW_INSTALLATION_AVAILABLE_COMPONENT_IS_SUBCOMPONENT = 5;
const int FW_INSTALLATION_AVAILABLE_COMPONENT_IS_HIDDEN = 6;

/** Retrieves information about available components in given source directory
  * @param availableComponentsToDisplay (out)  Array of available components information, note indexing: [information_type][component]
  * @param sourceDir (in)  Path to look for available components
  * @param scanRecursively (in)  Flag that indicates if components are searched also in subdirectories
  * @param systemName (in)  System where it is checked if component is already installed, if empty (default) then local system
  * @return 0 when components were not found in given directory, otherwise number of found components
  */
private int fwInstallation_ui_getAvailableComponentsInfo(dyn_dyn_anytype &availableComponentsToDisplay,
                                                         string sourceDirectory,
                                                         bool scanRecursively = false,
                                                         string systemName = "")
{
  if(sourceDirectory == ""){
    //fwInstallation_throw("You must define the source directory", "WARNING", 10);
    return 0;
  }
  if(fwInstallation_normalizePath(sourceDirectory, true) != 0){
    fwInstallation_throw("Failed to normalize directory path: " + sourceDirectory, "WARNING");
  }

  if(systemName == "")
    systemName = getSystemName();

  if(!patternMatch("*:", systemName))
    systemName += ":";

  openProgressBar("FW Component Installation Tool", "copy.gif", "Looking for components in: " + sourceDirectory, "This may take a while", "Please wait...", 1);

  dyn_string availableXmlList = scanRecursively?fwInstallation_getFileNamesRec(sourceDirectory, "*.xml"):
                                                getFileNames(sourceDirectory, "*.xml");
  int availableXmlListLen = dynlen(availableXmlList);

  if(availableXmlListLen <= 0){
    if(myManType() == UI_MAN){
      ChildPanelOnCentral("vision/MessageInfo1", "Not files found", makeDynString("$1:No component files found.\nAre you sure the directory is readable?"));
    }else{
      fwInstallation_throw("No component files found.\nAre you sure the directory is readable?");
    }
    closeProgressBar();
    return 0;
  }
  showProgressBar("Found : " + availableXmlListLen + " XML files", "Verifying that they are component files", "Please wait...", 75);

  dynClear(availableComponentsToDisplay);
  int index = 0;
  for(int i=1;i<=availableXmlListLen;i++)
  {
    dyn_string dsValues;
    dyn_anytype daAttribs;

    string xmlFile = availableXmlList[i];
    string xmlFilePath = sourceDirectory + xmlFile;

    int retCode = fwInstallationXml_getTag(xmlFilePath, "name", dsValues, daAttribs);
    if(retCode != 0){ // Error code returned
      if(retCode == -2){continue;} // NOT a component XML file, skip it
      // It is a component XML file and an error occured
      fwInstallation_throw("Cannot load " + xmlFile + " file ", "error", 4);
      continue;
    }else if(dynlen(dsValues) < 1){//bug #38484: Check that it is a component file
      continue;
    }
    string componentName = dsValues[1];

    dynClear(dsValues);
    fwInstallationXml_getTag(xmlFilePath, "version", dsValues, daAttribs);
    if(dynlen(dsValues) < 1){
      continue;
    }
    string componentVersion = dsValues[1];

    dynClear(dsValues);
    fwInstallationXml_getTag(xmlFilePath, "hiddenComponent", dsValues, daAttribs);
    bool isHidden = (dynlen(dsValues) > 0 && strtolower(dsValues[1]) == "yes");

    dynClear(dsValues);
    fwInstallationXml_getTag(xmlFilePath, "subComponent", dsValues, daAttribs);
    bool isSubcomponent = ((dynlen(dsValues) > 0) && (strtolower(dsValues[1]) == "yes"));

    int componentInstalledResult = 0;
    if(systemName != "*"){  //If we are not dealing with more than one system, look if component is installed
      fwInstallation_componentInstalled(componentName, componentVersion, componentInstalledResult, systemName, true);
    }

    index++;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_DISP_NAME][index] = (isSubcomponent?"_":"") + componentName;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_VERSION][index] = componentVersion;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_XML][index] = xmlFilePath;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_IS_HIDDEN][index] = isHidden;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_IS_SUBCOMPONENT][index] = isSubcomponent;
    availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_INST_STATUS][index] =
        (componentInstalledResult == 1)?FW_INSTALLATION_COMPONENT_STATUS_INSTALLED:"";
  }
  closeProgressBar();
  return index;
}

/** Searches for available components in given source directory and displays them in 'Available components' table.
  * @param tableShape (in)  Available components table shape
  * @param sourceDir (in)  Path to look for components
  * @param scanRecursively (in)  Flag that indicates if components are searched also in subdirectories
  * @param subcomponentsVisible (in)  Flag that indicates if subcomponents should be shown (true) or hidden
  * @param hiddenComponentsVisible (in)  Flag that indicates if hidden components should be shown (true) or hidden
  * @param systemName (in)  System where it is checked if component is already installed, if empty (default) then local system
  */
void fwInstallation_ui_displayAvailableComponents(shape tableShape, string sourceDir, bool scanRecursively, bool subcomponentsVisible,
                                                  bool hiddenComponentsVisible, string systemName = "")
{
  tableShape.deleteAllLines();

  dyn_dyn_anytype availableComponentsToDisplay;
  int availableComponentsNumber =
      fwInstallation_ui_getAvailableComponentsInfo(availableComponentsToDisplay, sourceDir, scanRecursively, systemName);

  if(availableComponentsNumber <= 0){return;}

  tableShape.appendLines(availableComponentsNumber,
                         "componentName", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_DISP_NAME],
                         "componentVersion", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_VERSION],
                         "descFile", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_XML],
                         "colStatus", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_INST_STATUS],
                         "isSubcomponent", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_IS_SUBCOMPONENT],
                         "isHidden", availableComponentsToDisplay[FW_INSTALLATION_AVAILABLE_COMPONENT_IS_HIDDEN]);

  fwInstallation_ui_filterComponentsTable(tableShape, subcomponentsVisible, hiddenComponentsVisible);
}

/** Show/hide rows with subcomponents and hidden component in components table according to given parameters.
  * @param tableShape (in)  Components table shape
  * @param subcomponentsVisible (in)  Flag that indicates if subcomponents should be shown (true) or hidden
  * @param hiddenComponentsVisible (in)  Flag that indicates if hidden components should be shown (true) or hidden
  */
void fwInstallation_ui_filterComponentsTable(shape tableShape, bool subcomponentsVisible, bool hiddenComponentsVisible)
{
  dyn_string filterColumns;
  dyn_bool filterValues;
  // Note: See help of filterRows table method
  // Only rows that match created filter will be shown in the table
  if(!subcomponentsVisible) // don't show subcomponents - create filter on "isSubcomponent" column - show only rows where column value is false
  {
    dynAppend(filterColumns, "isSubcomponent");
    dynAppend(filterValues, false);
  }
  if(!hiddenComponentsVisible) // don't show hidden components - create filter on "isHidden" column - show only rows where column value is false
  {
    dynAppend(filterColumns, "isHidden");
    dynAppend(filterValues, false);
  }
  // When filterColumns and filterValues are empty (show subcomponents and hidden components) then all rows will be shown
  tableShape.filterRows(filterColumns, filterValues, true);
}

/** This function retrieves from a table requested data of components that have specific labels set in colum "colStatus".
  * @usage Retrieving data of components that are selected in a table for installation or removal.
  * @param tableShape (in)  Shape of a table
  * @param markLabels (in)  List of labels - components that have these labels in "colStatus" column will be retrieved
  * @param columnsToGet (in)  List of table columns from which the information are read.
  * @param componentsInfo (out)  Retrieved marked components info. Columns are indexed corresponding to the columnsToGet list, each row contains one component data.
  */
fwInstallation_ui_getMarkedComponentsData(shape tableShape, const dyn_string &markLabels, const dyn_string &columnsToGet, dyn_dyn_mixed &componentsInfo)
{
  int index = 1;
  int tableLinesNo = tableShape.lineCount();
  for(int i=0;i<tableLinesNo;i++){
    if(!tableShape.isRowHidden(i) &&
       dynContains(markLabels, tableShape.cellValueRC(i, "colStatus")) > 0){
      componentsInfo[index] = fwInstallation_ui_getColumnsInRow(tableShape, i, columnsToGet);
      index++;
    }
  }
}

/** Retrieves values from table cells in a given row and given columns.
  * @param tableShape (in)  Shape of a table
  * @param row (in)  Table row number
  * @param columnsToGet (in)  List of table columns from which the information are read.
  * @return List of values in a particular row and in given columns. Column values are in the same order as in columnsToGet list.
  */
dyn_mixed fwInstallation_ui_getColumnsInRow(shape tableShape, int row, const dyn_string &columnsToGet)
{
  dyn_mixed rowColumnsVals;
  int columnsToGetLen = dynlen(columnsToGet);
  for(int i=1;i<=columnsToGetLen;i++){
    rowColumnsVals[i] = tableShape.cellValueRC(row, columnsToGet[i]);
  }
  return rowColumnsVals;
}

/** Shows and handles the right click pop-up menu in components table.
  * @param tableShape (in)  Components' table shape
  * @param row (in)  Row number
  * @param column (in)  Name of a column (currently unused)
  */
fwInstallation_ui_componentsTableRightClickPopupMenu(shape tableShape, int row, string column)
{
  if(row < 0) return;

  const int menuIdCopyComponents = 1;
  dyn_string menu = makeDynString("PUSH_BUTTON, Copy component list to clipboard, " + menuIdCopyComponents + ", 1");

  int selectedItemId;
  popupMenu(menu, selectedItemId);

  switch(selectedItemId)
  {
    case menuIdCopyComponents: fwInstallation_ui_copyComponentsListToClipboard(tableShape); break;
  }
}

/** Copies to clipboard a list of components and their versions as a string.
  * @param tableShape (in)  Components' table shape
  */
private void fwInstallation_ui_copyComponentsListToClipboard(shape tableShape)
{
  const dyn_string columns = makeDynString("componentName", "componentVersion");
  string componentListAsString = fwInstallation_ui_getTableColumnsAsString(tableShape, columns);
  if(setClipboardText(componentListAsString) != 0)
    fwInstallation_throw("Failed to copy components' list to clipboard", "WARNING");
}

/** Returns rows of the given table's columns as a string.
  * @param tableShape (in)  Shape of a table
  * @param columns (in)  List of table columns
  * @param addHeader (in)  Flag that indicates if columns headers should be added at the beginning (true - default)
  * @param colSeparator (in)  String that separates fields of different columns (default is TAB character)
  * @param processingMode (in)  Flag that indicates which rows should be returned:
  *                             0 - all, 1 - only visible, 2 - only selected (1 - default)
  * @return Content of table's columns as string. When shape is not ot type 'TABLE' or table don't have a specified column then empty string is returned.
  */
string fwInstallation_ui_getTableColumnsAsString(shape tableShape, dyn_string columns,
                                                 bool addHeader = true, string colSeparator = "\t", int processingMode = 1)
{
  if(fwInstallation_ui_areTableColumnsValid(tableShape, columns) != 0) return "";

  const string newLineChar = "\n";

  dyn_string columnHeadersText;
  int columnsToGet = dynlen(columns);
  if(addHeader){
    for(int j=1;j<=columnsToGet;j++){
      dynAppend(columnHeadersText, tableShape.columnHeader(
          tableShape.nameToColumn(columns[j])));
    }
  }

  dyn_string tableRowsText;
  int tableRowsCount = tableShape.lineCount();
  dyn_int selectedRows = tableShape.getSelectedLines();
  for(int i=0;i<tableRowsCount;i++) {
    if(processingMode == 1 && tableShape.isRowHidden(i)){
      continue; // If processingMode is set to only visible rows then skip hidden rows
    }
    if(processingMode == 2 && !selectedRows.contains(i)){
      continue; // If processingMode is set to only selected rows then skip other rows
    }
    dyn_string rowColumnsVal = fwInstallation_ui_getColumnsInRow(tableShape, i, columns);
    dynAppend(tableRowsText, strjoin(rowColumnsVal, colSeparator));
  }
  return (addHeader?(strjoin(columnHeadersText, colSeparator) + newLineChar):"") +
      strjoin(tableRowsText, newLineChar);
}

private int fwInstallation_ui_areTableColumnsValid(shape tableShape, dyn_string columns)
{
  if(tableShape.shapeType() != "TABLE")
  {
    fwInstallation_throw("fwInstallation_ui_areTableColumnsValid() -> Given shape is not of type 'TABLE'");
    return -1;
  }
  int columnsLen = dynlen(columns);
  for(int i=1;i<=columnsLen;i++)
  {
    if(tableShape.nameToColumn(columns[i]) < 0)
    {
      fwInstallation_throw("fwInstallation_ui_areTableColumnsValid() -> Given table does not have a column named: '" + columns[i] + "'");
      return -2;
    }
  }
  return 0;
}

/** Enables alternating row colors for a given table.
  * @param table (in)  Table shape
  */
void fwInstallation_ui_setTableAlternatingRowColors(shape table){
  const dyn_string altRowColors = makeDynString("_Window",
                                                "_WindowAlternate");
  table.alternatingRowColors(altRowColors);
}

/** Opens fwInstallation Release Notes in text editor (read only mode)
  */
void fwInstallation_ui_openReleaseNotes()
{
  textEditor("file",     getPath(HELP_REL_PATH, FW_INSTALLATION_RELEASE_NOTES),
             "readOnly", true,
             "title",    "Framework Installation Tool Release Notes",
             //"font",     "Arial,-1,13,5,50,0,0,0,0,0,Regular", // Do not change font as it is global change for textEditor
             "wordWrap", true);
}

/******************************************
 *      Report installation progress      */

//Name of global variable that stores shape of 'Installation Info' panel
const string FW_INSTALLATION_REPORT_GLOBAL_SHAPE = "reportShape";

/** Creates/updates global variable that stores provided shape of a 'Installation Info' reference panel and therefore enables reporting of component installation process.
  * This function is called in fwInstallation_installationInfo.pnl panel with its own shape as an argument when user-defined event eventStartReporting() occurs.
  * @param sh (in)  Shape of 'Installation Info' reference panel on main installation panel.
  */
void fwInstallation_reportInit(shape sh)
{
  if(!fwInstallation_reportReportShapeExists())
    addGlobal(FW_INSTALLATION_REPORT_GLOBAL_SHAPE, SHAPE_VAR);
  fwInstallation_reportSetReportShape(sh);
}

/** Removes global variable with shape of a 'Installation Info' reference panel. This disables reporting of reporting of component installation process.
  * This function is called in fwInstallation_installationInfo.pnl panel when user-defined event eventStopReporting() occurs.
  */
void fwInstallation_reportTeardown()
{
  removeGlobal(FW_INSTALLATION_REPORT_GLOBAL_SHAPE);
}

/** Sets the shape stored by 'reportShape' global variable.
  * @param sh (in)  Shape that is assigned to 'reportShape' global variable
  */
private fwInstallation_reportSetReportShape(shape sh){
  execScript("int main(shape sh){" + FW_INSTALLATION_REPORT_GLOBAL_SHAPE + " = sh;}", makeDynString(), sh);
}

/** Returns the shape stored in 'reportShape' global variable.
  * @note fwInstallation_reportReportShapeExists() function should be called before to check if global variable exists.
  * @return Shape stored in 'reportShape'
  */
shape fwInstallation_reportGetReportShape()
{
  shape sh;
  evalScript(sh, "int main(){return " + FW_INSTALLATION_REPORT_GLOBAL_SHAPE + ";}", makeDynString());
  return sh;
}

/** Checks if global variable 'reportShape' exists.
  * @return TRUE when 'reportShape' exists or else, FALSE
  */
bool fwInstallation_reportReportShapeExists(){
  return globalExists(FW_INSTALLATION_REPORT_GLOBAL_SHAPE);
}

//Name of the public function in fwInstallation_installationInfo.pnl panel ScopeLib, that processes parameter sent by fwInstallation_updateReport() according to the given message type
const string FW_INSTALLATION_REPORT_MESSAGE_HANDLING_FUNCTION = "updateReport";

/** Sends installation report messages to the 'Installation Info' panel.
  * This function invokes 'updateReport' public function in fwInstallation_installationInfo.pnl, with message type and parameter value provided as an arguments.
  * @note Handling of provided message type should be implemented in 'updateReport' public function in fwInstallation_installationInfo.pnl
  * @param messageType (in)  Type of the message
  * @param value (in)  Parameter value for given message type
  */
private void fwInstallation_updateReport(string messageType, anytype value)
{
  shape sh;
  if(fwInstallation_reportReportShapeExists())
    sh = fwInstallation_reportGetReportShape();
  if(!sh)//don't send messages when report panel shape does not exists or it is empty
    return;

  invokeMethod(fwInstallation_reportGetReportShape(), FW_INSTALLATION_REPORT_MESSAGE_HANDLING_FUNCTION, messageType, value);
}

/** Elements of mapping, that stores information about installation of particular component **/
const string FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_COMPONENT = "componentName";
const string FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_PARENT = "parentComponentId";
const string FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_REASON = "installationReason";
const string FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_STAGE = "installationStage";
const string FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_FINISHED = "isFinished";

/** Definition of report message types and functions that sends them **/

 const string FW_INSTALLATION_REPORT_MESSAGE_INSTALLATION_STARTED = "installationStarted";
/** This function sends installation start time. Start time is the current time.
  * @note This function must be called after the number of components to be installed is set.
  */
fwInstallation_reportInstallationStartTime()
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_INSTALLATION_STARTED, getCurrentTime());
}

const string FW_INSTALLATION_REPORT_MESSAGE_COMPONENTS_NUMBER = "componentsNumber";
/** This function sends number of components to be installed.
  * @param componentsNumber (in)  Number of components to be installed
  */
fwInstallation_reportSetTotalComponentsNumber(int componentsNumber)
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_COMPONENTS_NUMBER, componentsNumber);
}

const string FW_INSTALLATION_REPORT_MESSAGE_ADDITIONAL_COMPONENTS_NUMBER = "additionalComponentsNumber";
/** This function sends number of additional components to be installed (this number is added to the current number of components to be installed).
  * @param additionalComponentsNumber (in)  Number of additional components to be installed
  */
fwInstallation_reportUpdateTotalComponentsNumber(int additionalComponentsNumber)
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_ADDITIONAL_COMPONENTS_NUMBER, additionalComponentsNumber);
}

/** Definition of component installation steps **/
const int FW_INSTALLATION_REPORT_STEP_STARTING_INSTALLATION = 1;
const int FW_INSTALLATION_REPORT_STEP_PARSING_XML = 2;
const int FW_INSTALLATION_REPORT_STEP_CHECKING_REQUIREMENTS = 3;
const int FW_INSTALLATION_REPORT_STEP_VERIFYING_COMPONENT_PACKAGE = 4;
const int FW_INSTALLATION_REPORT_STEP_EXECUTING_PREINIT_SCRIPTS = 5;
const int FW_INSTALLATION_REPORT_STEP_INSTALLING_REQUIRED_COMPONENTS = 6;
const int FW_INSTALLATION_REPORT_STEP_INSTALLING_SUBCOMPONENTS = 7;
const int FW_INSTALLATION_REPORT_STEP_COPYING_FILES = 8;
const int FW_INSTALLATION_REPORT_STEP_INSTALL_BINARIES = 9;
const int FW_INSTALLATION_REPORT_STEP_IMPORTING_DPS = 10;
const int FW_INSTALLATION_REPORT_STEP_CONFIGURING_PROJECT = 11;
const int FW_INSTALLATION_REPORT_STEP_EXECUTING_INIT_SCRIPTS = 12;
const int FW_INSTALLATION_REPORT_STEP_REGISTERING_INSTALLATION = 13;
const int FW_INSTALLATION_REPORT_STEP_CALCULATING_SOURCE_FILES_HASHES = 14;
const int FW_INSTALLATION_REPORT_STEP_VERIFYING_DEPENDENCIES = 15;
const int FW_INSTALLATION_REPORT_STEP_REQUESTING_POSTINSTALLS = 16;
const int FW_INSTALLATION_REPORT_STEP_REGISTERING_INSTALLATION_IN_DB = 17;//optional step, only when DB is used

const string FW_INSTALLATION_REPORT_MESSAGE_INSTALLING_COMPONENT = "installingComponent";
/** This function sends installation progress of given component
  * @param componentName (in)  Name of the component being installed
  * @param stage (in)  Current component installation step number
  */
fwInstallation_reportComponentInstallationProgress(string componentName, int stage)
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_INSTALLING_COMPONENT,
                              makeMapping(FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_COMPONENT, componentName,
                                          FW_INSTALLATION_REPORT_VARIABLE_INSTALATION_INFO_STAGE, stage));
}

const string FW_INSTALLATION_REPORT_MESSAGE_COMPONENT_INSTALLATION_FINISHED = "componentInstallationFinished";
/** This function sends information that installation of given component is finished
  * @param componentName (in)  Name of the component which installation is finished
  */
fwInstallation_reportComponentInstallationFinished(string componentName)
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_COMPONENT_INSTALLATION_FINISHED, componentName);
}

const string FW_INSTALLATION_REPORT_MESSAGE_INSTALLATION_LOG_MESSAGE = "installationLogMessage";
/** This function sends installation log messages ()
  * @note During processing of log messages in 'Installation Info' panel it is assumed that fwInstallation_throw() is called only by functions that run installation process
  * (this might not always be true - DB agent? - but this can be detected by checking if error comes from UI manager that runs fwInstallation main panel, but what about executing init scripts in dedicated control manager [future solution?]?)
  * + that component installation is not run in parallel (only one component is being installed at the moment - this should be always true)
  * @param message (in) Log message of errClass type
  */
fwInstallation_reportInstallationMessage(errClass message)
{
  fwInstallation_updateReport(FW_INSTALLATION_REPORT_MESSAGE_INSTALLATION_LOG_MESSAGE, message);
}
