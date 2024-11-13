main()
{
  int id  = moduleAddMenu("JCOP Framework");
  moduleAddAction("Installation", "", "Meta+I", id, 0, "_openInstallationTool");

  // If new project, wait till fwInstallation libraries are loaded
  while(!isFunctionDefined("fwInstallation_getInstallationPendingActionsDp")){
    delay(10);
  }

  // and to be on safe side, wait till DP, used later in this script, is created
  while(!dpExists(fwInstallation_getInstallationPendingActionsDp())){
    delay(1);
  }

  dpConnect("_monitorFwScriptsActionCB",
            fwInstallation_getInstallationPendingActionsDp() + ".postInstallFiles:_original.._userbyte2");
}

 /**
 * @reviewed 2018-06-26 @whitelisted{WinCCOAIntegration}
 */
void _openInstallationTool()
{
  const string moduleName = "JCOP Framework Installation Tool";
  const string panelName = "JCOP Framework Installation Tool";

  if(isModuleOpen(moduleName) && isPanelOpen(panelName, moduleName)){
    moduleRaise(moduleName);
    return;
  }

  const string fileName = "fwInstallation/fwInstallation.pnl";
  const int xPosCentered = -1;
  const int yPosCentered = -1;
  const int moduleWidthFromPanel = 0;
  const int moduleHeightFromPanel = 0;
  const uint iconBarHidden = 1;
  const uint menuBarHidden = 1;
  const string resizeModeDefault = "";
  const dyn_string dollarParamsEmpty = makeDynString();

  ModuleOnWithPanel(moduleName, xPosCentered, yPosCentered,
                    moduleWidthFromPanel, moduleHeightFromPanel,
                    iconBarHidden, menuBarHidden, resizeModeDefault,
                    fileName, panelName, dollarParamsEmpty);
}

synchronized void _monitorFwScriptsActionCB(string dp1, char currentAction){
  if(!currentAction || isModuleOpen("FwScriptsMonitor")){
    return;
  }
  bool isRunning;
  int retVal = evalScript(isRunning, // fwInstallationManager_isRunning wrapped into evalScript
        "bool main(){\n" +    // to work correctly when first start of fwInstallation in the project.
        "bool isRunning;\n" + // I uses script-scope pmon variables that are defined in fwInstallation.ctl.
        "int retVal =\n" +    // These are available only to scripts started after the library has been loaded.
        "  fwInstallationManager_isRunning(\"ctrl\", FW_INSTALLATION_SCRIPTS_MANAGER_CMD, isRunning);\n" +
        "return (retVal == 0 && isRunning);\n" +
        "}");
  if(retVal != 0 || !isRunning){
    return;
  }
  // fwScripts manager is running and window is not yet open
  _openFwScriptsMonitor();
}

void _openFwScriptsMonitor(){
  const string moduleName = "FwScriptsMonitor";
  const string panelName = "FwScriptsMonitor";

  const string fileName = "fwInstallation/fwInstallation_postInstallProgress.pnl";
  const int xPosCentered = -1;
  const int yPosCentered = -1;
  const int moduleWidthFromPanel = 0;
  const int moduleHeightFromPanel = 0;
  const uint iconBarHidden = 1;
  const uint menuBarHidden = 1;
  const string resizeModeDefault = "None";
  const dyn_string dollarParamsEmpty = makeDynString();

  ModuleOnWithPanel(moduleName, xPosCentered, yPosCentered,
                    moduleWidthFromPanel, moduleHeightFromPanel,
                    iconBarHidden, menuBarHidden, resizeModeDefault,
                    fileName, panelName, dollarParamsEmpty);
  while(!isModuleOpen(moduleName)){
    delay(0, 10);
  }
}
