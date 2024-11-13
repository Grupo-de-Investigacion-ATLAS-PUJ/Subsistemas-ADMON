// Entrypoint for script
int main()
{
  return fwInstallationLegacy_buildLegacyLibrary();
}

// Name of the legacy includes library file
const string FW_INSTALLATION_LEGACY_LIB_FILENAME = "includes_legacy.ctl";

// List of components that should not be taken into account when creating the list of main libraries
const dyn_string FW_INSTALLATION_EXCLUDE_LIST = makeDynString("fwCore" // fwCore libraries are continued to be loaded through the config file entry
                                                          );

/**
 * Build a CTRL library for the project that includes main libraries of all components following the JCOP convention
 * (main library is located in fwComponentName/ subdirectory and is named fwComponentName.[ctl|ctc])
 *
 * @return 0 if successful, or a negative number in case of failure.
 */
int fwInstallationLegacy_buildLegacyLibrary()
{
  string legacyLibraryPath = getPath(LIBS_REL_PATH) + FW_INSTALLATION_LEGACY_LIB_FILENAME;
  dyn_string libs = _fwInstallationLegacy_getComponentsMainLibsList();

  if (dynlen(libs) == 0)
  {
    if(isfile(legacyLibraryPath) && remove(legacyLibraryPath) != 0)
    {
      fwInstallation_throw("Failed to remove: '" + legacyLibraryPath + "'", "ERROR");
      return -1;
    }
  }
  else
  {
    if (_fwInstallationLegacy_createLegacyIncludesFile(legacyLibraryPath, libs) != 0)
    {
      return -2;
    }
  }
  return 0;
}


/**
 * Get the list of CTRL libraries to be included in legacy library
 *
 * @return List of relative paths (inside libs/) to main component libraries
 */
dyn_string _fwInstallationLegacy_getComponentsMainLibsList()
{
  dyn_string mainLibs;
  dyn_string componentDps = fwInstallation_getInstalledComponentDps();

  for (int i = 1; i <= dynlen(componentDps); i++)
  {
    string componentDp = componentDps[i];
    string componentName, componentInstallationPath;
    if (dpGet(componentDp + ".name", componentName,
              componentDp + ".installationDirectory", componentInstallationPath) != 0)
    {
      fwInstallation_throw("Could not retrieve component information from dp: '" + componentDp + "'", "ERROR");
      continue;
    }

    if(!_fwInstallationLegacy_isSubcomponent(componentDp) &&
       !_fwInstallationLegacy_isComponentExcluded(componentName))
    {
      fwInstallation_normalizePath(componentInstallationPath, true);
      string componentLibPath = componentInstallationPath + LIBS_REL_PATH + componentName;
      string fallbackComponentLibPath = getPath(LIBS_REL_PATH, componentName);
      if(fallbackComponentLibPath == "") // component does not have any libraries, go to next one
      {
        continue;
      }
      dyn_string componentMainLibs = _fwInstallationLegacy_getComponentMainLibsFromPath(componentName, componentLibPath);
      if(dynlen(componentMainLibs) > 0)
      {
        dynAppendConst(mainLibs, componentMainLibs);
      }
      else if(fallbackComponentLibPath != componentLibPath)
      {
        componentMainLibs = _fwInstallationLegacy_getComponentMainLibsFromPath(componentName, fallbackComponentLibPath);
        if(dynlen(componentMainLibs) > 0)
        {
          dynAppendConst(mainLibs, componentMainLibs);
        }
      }
    }
  }
  return mainLibs;
}

/**
 * Checks in component datapoint whether given component is subcomponent or not.
 *
 * @param componentDp Name of the data point that describes the component.
 * @return true if component is a subcomponent, false otherwise
 */
bool _fwInstallationLegacy_isSubcomponent(string componentDp)
{
  bool isSubComponent;
  if(dpGet(componentDp + ".isItSubComponent", isSubComponent) != 0)
  {
    fwInstallation_throw("Failed to check if component stored in dp '" + componentDp + "' is subcomponent", "ERROR");
    return false;
  }
  return isSubComponent;
}

/**
 * Checks whether component with given name is on the list of excluded components.
 *
 * @param componentName Name of the component.
 * @return true if component should be excluded (is on the list), false otherwise
 */
bool _fwInstallationLegacy_isComponentExcluded(string componentName)
{
  return (dynContains(FW_INSTALLATION_EXCLUDE_LIST, componentName) > 0);
}


/**
 * @TODO UPDATE
 * Get the main component libraries from given path. Path should point to a subfolder named after component inside libs/
 *
 * Main component library is recognized by name that should be the same as component name (case insensitive comparison)
 * Supported library extensions are *.ctl and *.ctc.
 *
 * @param componentName Name of the component.
 * @param libsPath Path to search for component libraries
 * @return List of libraries paths relative to `scripts/libs/` or empty list if no main lib found.
 */
dyn_string _fwInstallationLegacy_getComponentMainLibsFromPath(string componentName, string libsPath)
{
  dyn_string componentLibs = _fwInstallationLegacy_getLibsFromPath(libsPath);
  dyn_int componentMainLibsPos = _fwInstallationLegacy_getMainLibsPos(componentLibs, componentName);

  if(dynlen(componentLibs) > 0 && dynlen(componentMainLibsPos) == 0)
  { // if no matching libraries are found, try case insensitive search (fwFSM)
    componentMainLibsPos = _fwInstallationLegacy_getMainLibsPos(_fwInstallationLegacy_listToLower(componentLibs),
                                                                strtolower(componentName));
  }

  dyn_string componentMainLibs;
  int libsCount = dynlen(componentMainLibsPos);
  for(int i=1;i<=libsCount;i++)
  {
    string mainLibName = componentLibs[componentMainLibsPos[i]];
    string mainLibPath = componentName + "/" + mainLibName;
    dynAppend(componentMainLibs, mainLibPath);
  }
  return componentMainLibs;
}

/**
 * Get all files located in given path.
 *
 * @param libsPath Path to search for files.
 * @return List of file names in the specified directory or empty list if directory is empty or does not exist.
 */
dyn_string _fwInstallationLegacy_getLibsFromPath(string libsPath){
  dyn_string libsList;
  if(libsPath != "" && isdir(libsPath))
  {
    libsList = getFileNames(libsPath);
  }
  return libsList;
}

/**
 * Get the positions of main component libraries on the list of component libraries.
 *
 * @param componentLibs List of component libraries.
 * @param componentName Name of the component.
 * @return List of indexes indicating main libraries position on the given list of libraries.
 */
dyn_int _fwInstallationLegacy_getMainLibsPos(const dyn_string &componentLibs, string componentName)
{
  dyn_int mainLibsPos;
  int ctlPos = dynContains(componentLibs, componentName + ".ctl");
  if(ctlPos > 0)
  {
    dynAppend(mainLibsPos, ctlPos);
  }
  int ctcPos = dynContains(componentLibs, componentName + ".ctc");
  if(ctcPos > 0)
  {
    dynAppend(mainLibsPos, ctcPos);
  }
  return mainLibsPos;
}

/**
 * Creates a list containing all elements of given list converted to lowercase characters.
 *
 * @param list List containing elements of type string.
 * @return List containing elements of type string in lowercase characters.
 */
dyn_string _fwInstallationLegacy_listToLower(const dyn_string &list)
{
  int listLen = dynlen(list);
  dyn_string listLower;
  for(int i=1;i<=listLen;i++)
  {
    listLower[i] = strtolower(list[i]);
  }
  return listLower;
}

/**
 * Prepares content of the legacy include library and writes it to the file.
 *
 * Legacy include library consists of comment header, #uses statements of
 *
 * @param libs List of libraries to include.
 * @param filePath Path to write legacy include library file.
 * @return 0 if succesful, else negative number indicating failure.
 */
int _fwInstallationLegacy_createLegacyIncludesFile(string filePath, const dyn_string &libs)
{
  string fileContent = _fwInstallationLegacy_makeFileHeader();
  fileContent += _fwInstallationLegacy_makeFileUsesStatements(libs);
  fileContent += _fwInstallationLegacy_makeFileDeprecationWarning();

  file handle;
  try
  {
    handle = fopen(filePath, "w");
    if (ferror(handle) != 0)
    {
      fwInstallation_throw("Failed to open file for writing: '" + filePath + "'", "ERROR");
      return -2;
    }
    if(fputs(fileContent, handle) < 0)
    {
      fwInstallation_throw("Failed to write to file: '" + filePath + "'", "ERROR");
      return -3;
    }
  }
  catch
  {
    fwInstallation_throw("Unexpected error", "ERROR");
    return -4;
  }
  finally
  {
    fclose(handle);
  }
  return 0;
}


/**
 * Makes the header for the legacy include library.
 *
 * A header consists of comment lines containing a note about purpose and usage of the library.
 *
 * @return Header text as a string
 */
string _fwInstallationLegacy_makeFileHeader()
{
  return "// # " + FW_INSTALLATION_LEGACY_LIB_FILENAME + " #\n\n" +
         "// This is a 'fallback' library containing appropriate #uses statements for\n" +
         "// component main libraries which follows the JCOP naming naming convention.\n"
         "// The aim of this library is to provide a 'safety-net' solution, after\n" +
         "// deprecating the policy of loading all libraries through config file entries\n" +
         "// in JCOP Framework. Please consult JCOPFramework-releaseNotes.txt for detailed\n" +
         "// information.\n\n" +
         "//=================================================================================\n\n" +
         "// * Usage *\n" +
         "// Open the project config file and locate the [ui] and [ctrl] sections in it.\n"
         "// Add the following entry to both listed sections, to include all of\n" +
         "// the libraries, that previously were loaded by default by UI and CTRL managers\n" +
         "// as they had their own config file entries:\n" +
         "// LoadCtrlLibs = \"" + FW_INSTALLATION_LEGACY_LIB_FILENAME + "\"\n\n" +
         "//=================================================================================\n\n" +
         "// * Deprecation notice *\n" +
         "// Use of this file is considered deprecated. It should be used only in emergency\n" +
         "// cases, eg. dependency-resolution problems in a production system.\n" +
         "// * Adding library-loading statement to the config file is STRONGLY DISCOURAGED\n" +
         "// by the JCOP CB. *\n\n" +
         "//=================================================================================\n\n" +
         "// Please note that the content of this file is automatically recreated after\n" +
         "// each installation/reinstallation/removal of components' set by Installation\n" +
         "// Tool. This file should not be edited manually, as any custom entries are not\n" +
         "// preserved during file recreation.\n" +
         "// When none of the installed components provides a main library that follows\n" +
         "// the JCOP naming convention, the file is either removed (if prevoiously existed)\n" +
         "// or not created. If file is removed while entries, which load it, exist in the\n" +
         "// config file, they should be removed manually to avoid 'library could not be\n" +
         "// found' warning being displayed to the log at the moment, when each UI or CTRL\n" +
         "// manager starts.\n\n" +
         "//=================================================================================\n\n";
}


/**
 * Makes the block of #uses statements loading the given list of libraries.
 *
 * @return String containing #uses statements for libraries
 */
string _fwInstallationLegacy_makeFileUsesStatements(const dyn_string &libs)
{
  string usesStatements;
  for (int i = 1; i <= dynlen(libs); i++)
  {
    usesStatements += "#uses \"" + libs[i] + "\"\n";
  }
  usesStatements += "\n";
  return usesStatements;
}


/**
 * Makes the statement that displays deprecation warning in log when library is loaded.
 *
 * @return String with statement displaying deprecation warning
 */
string _fwInstallationLegacy_makeFileDeprecationWarning(){
  return "private global int INCLUDES_LEGACY_WARNING =\n" +
      "    throwError(makeError(\"fwInstallation\",PRIO_WARNING, ERR_CONTROL, 1,\n" +
      "                         \"Use of " + FW_INSTALLATION_LEGACY_LIB_FILENAME + " file is deprecated. \" +\n" +
      "                         \"Please include components directly.\"));\n\n";
}
