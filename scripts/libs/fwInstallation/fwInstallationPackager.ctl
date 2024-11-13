#uses "fwInstallation/fwInstallation.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationPackagerLibVersion = "9.1.3";
const string csFwInstallationPackagerLibTag = "";

/** This function exports FSM tree as a component.
 * @param componentName	name of the component
 * @param sourcePath	path of component folder
 * @param rootNodes	list of root nodes of FSM trees
 * @param doNotExportTypes	list of FSM object types that should not be exported
 * @return -1 when in case of errors (path is not specified or FSM is not installed), else 0
 */
int fwInstallationPackager_exportFsm(string componentName,
                                     string sourcePath,
                                     dyn_string rootNodes,
                                     dyn_string doNotExportTypes)
{
  dyn_string nodes, dps, exceptionInfo;
  string type, installScript, installScriptPath, installScriptName;
  file installScriptFile;
  string tree;
  dyn_string devices;
  dyn_string fwDps = makeDynString("fwOT_FwChildMode", "fwOT_FwChildrenMode", "fwOT_FwDevMajority",
                                   "fwOT_FwDevMode", "fwOT_FwFSMConfDBDUT", "fwOT_FwMode");

  if(dynlen(doNotExportTypes) > 0 && doNotExportTypes[1] != "")
  {
    dynAppend(fwDps, doNotExportTypes);
  }


  if(sourcePath == "")
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR",
                          makeDynString("$1:You must choose the source path first."));
    else
      DebugTN("ERROR: fwInstallation_packagerExportFSM() -> You must choose the source path first.");

    return -1;
  }

  // Is FSM installed?
  if(fwInstallation_checkInstalledComponent("fwFSM") != 0)
  {
    if(myManType() == UI_MAN)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR",
                          makeDynString("$1:FwFSM is not installed. No FSM to be exported"));
    }
    else
    {
      DebugTN("ERROR: fwInstallation_packagerExportFSM() -> FwFSM is not installed. No FSM to be exported");
    }

    return -1;
  }

  for(int ii = 1; ii <= dynlen(rootNodes); ii++)
  {
    tree = rootNodes[ii];
    if(myManType() == UI_MAN)
    {
      // openProgressBar("FSM Export", "copy.gif", "Exporting FSM tree: " + tree, "still exporting", " Do not
      // close this panel. Be patient!", 2);
      fsmExportProgressBar.progress((int)(100 / dynlen(rootNodes)) * ii);
    }

    strreplace(tree, "/", "_");
    if(tree != "Types only")
    {
      dynClear(nodes);
      callFunction("fwTree_getAllTreeNodes", tree, nodes, exceptionInfo);
      dynAppend(nodes, tree);
      dynClear(dps);
      installScript =
          "#uses \"fwFSM/fwFsm.ctl\"\n" +
          "\n" +
          "main()\n" +
          "{\n" +
          "  dyn_string exceptionInfo;\n";

      if(dynlen(nodes) > 0)
      {
        for(int i = 1; i <= dynlen(nodes); i++) // object types
        {
          callFunction("fwTree_getNodeDevice", nodes[i], devices[i], type, exceptionInfo);
          if(!dynContains(dps, "fwOT_" + type))
            dynAppend(dps, "fwOT_" + type);
        }

        for(int i = 1; i <= dynlen(nodes); i++) // tree nodes + DevMajority Objects
        {
          dynAppend(dps, "fwTN_" + nodes[i]);
          if(patternMatch("*_FWMAJ", nodes[i]))
          {
            // Found a device majority object. Make sure the type is also added
            string typeDp = "";
            dpGet("fwTN_" + nodes[i] + ".device", typeDp);

            if(dynContains(dps, typeDp) <= 0 && typeDp != "")
            {
              dynAppend(dps, typeDp);
            }
          }
        }


        // do some gymnastics in order to get the FSM right
        for(int i = 1; i <= dynlen(nodes); i++)
        {
          if(strreplace(devices[i], getSystemName(), ""))
            installScript +=
                "  dpSet(\"fwTN_" + nodes[i] + ".device\", getSystemName()+\"" + devices[i] + "\");\n";
        }
        // end sports

        if(myManType() == UI_MAN)
        {
          // showProgressBar("", "", "Creating dpl files with FSM datapoints. Do not close this panel", 50.);
          fsmExportProgressBar.progress(20);
        }


        fwInstallationPackager_createDpl(sourcePath + "/dplist/" + componentName + "_" + tree + ".dpl", dps);


        installScript +=
            "  fwTree_addNode(\"FSM\", \"" + tree + "\", exceptionInfo);\n" +
            "  fwFsmTree_generateAll();\n" +
            "}\n";


        installScriptPath = sourcePath + "/scripts/" + componentName + "/";
        if(access(installScriptPath + ".", F_OK) != 1)
        {
          // DebugN("INFO: fwInstallation -> Creating new subdirectory: " + sourcePath.text +"/scripts/" +
          // componentName.text + "/");
          mkdir(installScriptPath, "755");
        }

        // DebugN("Filename: " + sourcePath.text +"/scripts/"+ componentName.text + "/" + componentName.text +
        // "_" + tree +"_FSM.postInstall");
        if(myManType() == UI_MAN)
        {
          // showProgressBar("", "", "Creating post-installation scripts. Please wait", 50.);
          fsmExportProgressBar.progress(60);
        }

        installScriptName = componentName + "_" + tree + "_FSM.postInstall";
        installScriptFile = fopen(installScriptPath + installScriptName, "w");
        fputs(installScript, installScriptFile);
        fclose(installScriptFile);
      }
    }
    else
    {
      if(myManType() == UI_MAN)
      {
        // showProgressBar("", "", "Creating dpl files with FSM datapoints. Do not close this panel", 50.);
        fsmExportProgressBar.progress(90);
      }
      dps = dpNames("fwOT_*");
      // Remove standard FSM types:
      for(int k = 1; k <= dynlen(fwDps); k++)
      {
        if(dynContains(dps, getSystemName() + fwDps[k]) > 0)
        {
          dynRemove(dps, dynContains(dps, getSystemName() + fwDps[k]));
        }
      }

      if(dynlen(dps) > 0)
        fwInstallationPackager_createDpl(sourcePath + "/dplist/" + componentName + "_FSMTypes.dpl", dps);
    }
    if(myManType() == UI_MAN)
    {
      fsmExportProgressBar.progress(100);
    }
  }

  return 0;
}

/** This function packs the component files specified in xml-style description. The files are copied
 * to the destination directory maintaining directories structures specified in xml description.
 * @param destinationFolder	the folder where component files will be copied
 * @param sourcePath	the path from where the files will be copied at the first try, if the file does not
 * exist in this directory, then it will be searched in all project paths.
 * @param xmlDesc	xml-style description of component (each element of list is a single line of xml file)
 * @return -1 in case of errors during packing of component, 0 when success
 */
int fwInstallationPackager_packNgo(string destinationFolder, string sourcePath, dyn_string xmlDesc)
{
  int errCount = 0;
  fwInstallation_normalizePath(destinationFolder);
  string component = _fwInstallation_fileName(destinationFolder);

  fwInstallation_throw("Packaging component: " + component, "INFO", 10);

  if(dynlen(xmlDesc) > 0)
  {
    if(destinationFolder != "")
    {
      for(int i = 1; i <= dynlen(xmlDesc); i++)
      {
        errCount +=
            fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config", sourcePath, destinationFolder);
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config_linux", sourcePath,
                                                              destinationFolder);
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config_windows", sourcePath,
                                                              destinationFolder);
        errCount +=
            fwInstallationPackager_transferTaggedFile(xmlDesc[i], "init", sourcePath, destinationFolder);
        errCount +=
            fwInstallationPackager_transferTaggedFile(xmlDesc[i], "delete", sourcePath, destinationFolder);
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "postInstall", sourcePath,
                                                              destinationFolder);
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "postDelete", sourcePath,
                                                              destinationFolder);
        errCount +=
            fwInstallationPackager_transferTaggedFile(xmlDesc[i], "dplist", sourcePath, destinationFolder);
        errCount +=
            fwInstallationPackager_transferTaggedFile(xmlDesc[i], "script", sourcePath, destinationFolder);

        if(patternMatch("*" + component + ".xml</file>", xmlDesc[i]))
        {
          errCount +=
              fwInstallationPackager_transferTaggedFile(xmlDesc[i], "file", PROJ_PATH, destinationFolder);
        }
        else
        {
          errCount +=
              fwInstallationPackager_transferTaggedFile(xmlDesc[i], "file", sourcePath, destinationFolder);
        }
        generationLog.append("-/- Transfering tagged files: " + xmlDesc[i]);
      }
    }
  }
  if(errCount)
    return -1;

  return 0;
}

/** This function copy file specified in a single line of xml description, when specified tag matches the one
 * in the xml description. At the beginning function tries to copy from sourceFolder, when it fails,
 * then tries to copy the file from each project path untill success.
 * @param line	single line of xml description
 * @param tag	xml tag of file
 * @param sourceFolder	the folder from where the file should be copied
 * @param destinationFolder	the folder to where the file should be copied
 * @return 0 if file was copied succesfully or the tag doesn't match, -1 when copying fails.
 */
int fwInstallationPackager_transferTaggedFile(string line,
                                              string tag,
                                              string sourceFolder,
                                              string destinationFolder)
{
  string source, destination;
  int itemNo;
  dyn_string sourceItems;

  fwInstallation_getProjPaths(sourceItems);
  itemNo = dynlen(sourceItems);

  if(strpos(line, "<" + tag + ">") == 0)
  {
    line = strrtrim(strltrim(line, "<" + tag), "/" + tag + ">");
    line = strrtrim(strltrim(line, ">."), "<");
    source = sourceFolder + line;
    destination = destinationFolder + line;
    while(fwInstallation_copyFile(source, destination) != 0 && itemNo > 0)
    {
      source = sourceItems[itemNo] + line;
      itemNo--;
    }
  }
  if(itemNo == 0)
    return -1;
  else
    return 0;
}


int FW_INSTALLATION_PACKAGER_MAX_CMD_LINE_LENGTH_WINDOWS = 8191;
int FW_INSTALLATION_PACKAGER_MIN_CMD_LINE_LENGTH_LINUX = 4096; // POSIX smallest allowable upper limit on
                                                               // argument length
// int FW_INSTALLATION_PACKAGER_MAX_CMD_LINE_LENGTH_LINUX = 131072;

/** This function returns the maximum length of the command that we can execute with the
 * system(string command) function.
 * @return maximum command length
 */
int fwInstallationPackager_getSystemCommandLimit()
{
  if(_WIN32) // on Windows system(<command>) calls 'cmd /c <command>'
    return FW_INSTALLATION_PACKAGER_MAX_CMD_LINE_LENGTH_WINDOWS - strlen("cmd /c ") - 1;

  /* Note: For linux usually the limit is MAX_ARG_STRLEN = 32 * PAGE_SIZE
   * PAGE_SIZE is usually equal 4kB = 4096B, so the limit is 131072
   * this is maximum limit for the single string in command line
   * because system() executes a command specified in <command> by calling /bin/sh -c <command>
   * (see linux.die.net/man/3/system).
   * Just to be absolutely correct we are checking also maximum length of command line
   */
  string sMaxLen, sPageSize;
  // read the configuration variables
  if(system("getconf ARG_MAX", sMaxLen) == 0 && system("getconf PAGE_SIZE", sPageSize) == 0)
  {
    int maxLen = (int)sMaxLen;
    int maxStrLen = (int)sPageSize * 32;
    DebugTN(__FUNCTION__ + ": Detected cmd line length: ", maxLen);
    DebugTN(__FUNCTION__ + ": Detected cmd line single string length: " + maxStrLen);
    if(maxLen >= maxStrLen && maxStrLen >= FW_INSTALLATION_PACKAGER_MIN_CMD_LINE_LENGTH_LINUX)
      return maxStrLen - 1;
    if(maxLen < maxStrLen && maxLen >= FW_INSTALLATION_PACKAGER_MIN_CMD_LINE_LENGTH_LINUX)
      return maxLen - 1;
  }
  // something went wrong - error while reading configuration variable
  // or the read limit is less than minimum limit
  return FW_INSTALLATION_PACKAGER_MIN_CMD_LINE_LENGTH_LINUX - strlen("/bin/sh -c ") - 1;
}


/** This function formats the file name of ascii export - if necessary adds the file number
 * @param fileName	base file name
 * @param currCmdNum	number of current command that will be executed
 * @param commandNumbers	amount of commands that will be executed
 * @return formatted file name
 */
string fwInstallationPackager_formatExportFileName(string fileName, int currCmdNum, int commandNumbers)
{
  string newFileName = fileName;
  if(commandNumbers > 1) // more than one file will be created - needs to add number to the file name
  {
    dyn_string fileNameElements = strsplit(fileName, ".");
    if(dynlen(fileNameElements) > 1) // if file name contains extension
    {
      newFileName = fileNameElements[1];
      for(int j = 2; j < dynlen(fileNameElements); j++)
      { // handle the case when file has more dots in name
        newFileName += "." + fileNameElements[j];
      }
    }

    string sNum;
    sprintf(sNum, "_%03d", currCmdNum);
    newFileName += sNum; // add number

    if(dynlen(fileNameElements) > 1) // add file extension when necessary
    {
      newFileName += "." + fileNameElements[dynlen(fileNameElements)];
    }
  }
  return newFileName;
}


/** This function allows to make an ASCII export with specific filters.
 * Note 1: When only datapoint names are specified, then function will try to pass all of them
 * to ASCII manager in a file, in order to export all in a single file. If this attempt failed or also the
 * dataPointTypes list is specified then each datapoint name or/and datapoint type will be passed as
 * an argument for ASCII manager (fallback mechanism).
 * Note 2: When both dataPointNames and dataPointTypes are specified they are connected with AND operator.
 * If specified datapoint has type that is not included in dataPointTypes list, then it will not be exported.
 * Note 3: When fallback mechanism is used and the list of datapoints or datapoint types is longer than
 * allowed by system limits, the list will be splitted and for each one the ASCII export will be done
 * separately. The export files will be named with following pattern <filename>_XXX.<ext> where XXX is file
 * number.
 * @param fileName	path and name of the output file
 * @param dataPointNames	names of the dps to be put out
 * @param dataPointTypes	names of the dpts to be put out (default all)
 * @param filter	filter on dps/dpts (default dps with alerts, params, and original values)
 * @return 0 when ASCII export was done succesfully, -1 when error occured
 * @author Sascha Schmeling, Fernando Varela and Mariusz Suder
 */
int fwInstallationPackager_createDpl(string fileName,
                                     dyn_string dataPointNames,
                                     dyn_string dataPointTypes = makeDynString(),
                                     string filter = "DAOP")
{
  int ret = -1;
  string fileNameTag = "<filename>";
  int fileNameLen = strlen(fileName) - strlen(fileNameTag) + 4; // 4 - reserved place for file number '_000'

  string baseCmdLine;
  if((string)dataPointTypes == "")
    dynClear(dataPointTypes);

  if(_WIN32)
    baseCmdLine = "cmd /c " + PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ascii") + " -proj " + PROJ +
                  " -out " + fileNameTag + " -filter " + filter + " -user para:";
  else
    baseCmdLine = PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ascii") + " -proj " + PROJ + " -out " +
                  fileNameTag + " -filter " + filter + " -user para:";

  // At first try to pass dp list in a file whenever it is possible (no dataPointTypes specified)
  if(dynlen(dataPointTypes) == 0)
  {
    // create export file
    string exportFileName = tmpnam();
    file f = fopen(exportFileName, "w");
    bool isError = (ferror(f) != 0);
    if((!isError) && dynlen(dataPointNames) > 0)
    {
      for(int i = 1; i <= dynlen(dataPointNames); i++)
      {
        fputs(dataPointNames[i] + ";\n", f);
      }
      fclose(f);

      // add filter file as an argument for ascii export
      string commandLine = baseCmdLine + " -filterFile " + exportFileName;
      // replace the fileNameTag with desired file name
      strreplace(commandLine, fileNameTag, fileName);

      ret = system(commandLine); // execute the command

      if(remove(exportFileName) != 0) // remove temporary file
      {
        DebugTN(__FUNCTION__ + ": ERROR: Cannot remove temporary file: " + exportFileName);
      }
    }

    if(ret == 0 && (!isError))
    {             // ascii export was done succesfully, using fallback mechanism is not necessary
      return ret; // so in this case escape the function
    }
    DebugTN(__FUNCTION__ + ": WARNING: Problem while exporting dpl specified in file, " +
            "attempt to export with dpl specified in command.");
    // if creation of export file fails add each dp and dpt to command line
  }

  // Fallback mechanism - there was an error while doing ascii export with dp list passed in file
  //                      or also dataPointTypes has to be exported

  // add filterDpType - dataPointTypes are combined with AND operator with dataPointNames, so they have to
  // be added to each command line
  if(dynlen(dataPointTypes) > 0)
    for(int i = 1; i <= dynlen(dataPointTypes); i++)
    {
      baseCmdLine += " -filterDpType " + dataPointTypes[i];
    }

  int cmdLineLenLimit = fwInstallationPackager_getSystemCommandLimit(); // get the maximum command line lenght
  int baseCmdLineLen = strlen(baseCmdLine) + fileNameLen;

  if(baseCmdLineLen > cmdLineLenLimit)
  { // Note: we don't handle the case when we have only list of dataPointTypes and it is so long that it
    // should be splitted to more than one command line.
    DebugTN(__FUNCTION__ + ": ERROR: Cannot perform ASCII export, the list of dataPointTypes is too long. " +
            "Action aborted. Try to split the list of dataPointTypes.");
    return -1;
  }

  dyn_string cmdLine = makeDynString(baseCmdLine); // array that contains all commands that should be executed
  int currCmdLine = 1;                             // indicates currently filled command in array
  int currCmdLineLen = baseCmdLineLen;             // current length of command line

  // add filterDp
  if(dynlen(dataPointNames) > 0)
    for(int i = 1; i <= dynlen(dataPointNames); i++)
    {
      if(patternMatch("*&*", dataPointNames[i]) && _WIN32)
      {
        dataPointNames[i] = "\"" + dataPointNames[i] + "\"";
      }

      string argument2pass;
      if(_WIN32)
        argument2pass = " -filterDp " + dataPointNames[i] + ";";
      else
        argument2pass = " -filterDp '" + dataPointNames[i] + ";'";


      int argLen = strlen(argument2pass);
      if(currCmdLineLen + argLen <= cmdLineLenLimit)
        cmdLine[currCmdLine] += argument2pass;
      else
      {
        if(currCmdLineLen == baseCmdLineLen) // no arguments were added - base cmd line is too long already
        {
          DebugTN(__FUNCTION__ + ": ERROR: Cannot perform ASCII export, the list of dataPointTypes has to " +
                  "much elements or/and argument: " + argument2pass + " is too long. Action aborted.");
          return -1; // prevent entering an infinite loop
        }
        currCmdLine++;
        cmdLine[currCmdLine] = baseCmdLine + argument2pass;
        currCmdLineLen = baseCmdLineLen;
      }
      currCmdLineLen += argLen;
    }

  // execute all commands
  int commandNumbers = dynlen(cmdLine);
  for(int i = 1; i <= commandNumbers; i++)
  {
    // format file name
    string formattedFileName = fwInstallationPackager_formatExportFileName(fileName, i, commandNumbers);
    strreplace(cmdLine[i], fileNameTag, formattedFileName);

    // execute command
    ret = system(cmdLine[i]);
    if(ret != 0)
    {
      DebugTN("Failed to do ascii export (command: " + (string)i + ") to file: " + formattedFileName);
      DebugTN("Command: ", cmdLine[i]);
    }
  }
  return ret;
}
