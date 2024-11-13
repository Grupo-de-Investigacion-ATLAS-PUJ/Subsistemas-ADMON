#uses "fwGeneral/fwGeneral.ctl"

main(){
	bool isInstalled = FALSE;
	int idTop, idAccessControl, idAction;
	string version;

	idTop = moduleAddMenu("JCOP Framework");

	// Legacy Alarm Screen
	isInstalled = fwInstallation_isComponentInstalled("fwAlarmHandling", version);
	if (isInstalled) idAction = moduleAddAction("Legacy Alarm Screen", "SysMgm/16x16/AesScreenAlerts.png", "", idTop, -1, "_openAs");

	// Alarm Handling
	isInstalled = fwInstallation_isComponentInstalled("fwAlarmScreenNg", version);
	if (isInstalled) idAction = moduleAddAction("Alarm Screen", "", "", idTop, -1, "_openAsNg");

	// DIM
	isInstalled = fwInstallation_isComponentInstalled("fwDIM", version);
	if (isInstalled) idAction = moduleAddAction("DIM", "", "", idTop, -1, "_openDIM");

	// DIP
	isInstalled = fwInstallation_isComponentInstalled("fwDIP", version);
	if (isInstalled) idAction = moduleAddAction("DIP", "", "", idTop, -1, "_openDIP");

	// Trending
	isInstalled = fwInstallation_isComponentInstalled("fwTrending", version);
	if (isInstalled) idAction = moduleAddAction("Trending", "trend.png", "", idTop, -1, "_openTrendingTool");

	// UNICOS HMI
	isInstalled = fwInstallation_isComponentInstalled("unCore", version);
	if (isInstalled) idAction = moduleAddAction("Unicos HMI", "logo/logo1-white-small.png", "", idTop, -1, "_openUnicosHmi");

	// Unit Test
	isInstalled = fwInstallation_isComponentInstalled("fwUnitTestComponent", version);
	if (isInstalled) idAction = moduleAddAction("Unit Test Panel", "", "", idTop, -1, "_openUnitTestPanel");

	// add the list of deprecated functions
	idAction = moduleAddAction("List calls to deprecated functions", "", "", idTop, -1, "_reportDeprecatedCalls");
}

void _openDIM()
{
	_fwGediToolbar_openTool("fwDIM",
							"JCOP Framework DIM",
							"fwDIM/fwDim.pnl",
							"JCOP DIM");
}

void _openDIP()
{
	_fwGediToolbar_openTool("fwDIP",
							"JCOP Framework DIP",
							"fwDIP/fwDip.pnl",
							"JCOP DIP");
}

void _openTrendingTool()
{
	_fwGediToolbar_openTool("fwTrending",
							"JCOP Framework Trending Tool",
							"fwTrending/fwTrending.pnl",
							"JCOP Trending");
}

void _openUnicosHmi()
{
	_fwGediToolbar_openTool("unCore",
							"UNICOS HMI",
							"vision/graphicalFrame/unicosHMI.pnl",
							"UNICOS");
}

void _openAs()
{
	_fwGediToolbar_openTool("fwAlarmHandling",
							"fwAS",
							"fwAlarmHandling/fwAlarmScreen.pnl",
							"");
}

void _openAsNg(){
	_fwGediToolbar_openTool("fwAlarmScreenNg",
							"fwAlarmScreenNg",
							"vision/fwAlarmScreenNg/fwAlarmScreenNg.xml",
							"");
}

void _openUnitTestPanel()
{
	_fwGediToolbar_openTool("fwUnitTestComponent",
							"fwUniTestComponent",
							"FwUnitTestComponent/fwUnitTestComponentTestRunner.pnl",
							"");
}

void _reportDeprecatedCalls()
{
	_fwGediToolbar_openTool("fwGeneral", "DeprecatedFunctionCalls", "fwGeneral/fwDeprecatedList.pnl", "");
}



void _fwGediToolbar_openTool(string componentName, string moduleName, string fileName, string panelName)
{
	bool ok, isInstalled = FALSE;
	string version;
	dyn_string exceptionInfo;

	if (componentName == "") {
		// If what we are opening is not related to a component, then we assume the panel to open is available
		isInstalled = TRUE;
	} else {
		// we check again whether the component is installed because it could be that the component was uninstalled
		// after the menu was added
		isInstalled = fwInstallation_isComponentInstalled(componentName, version);
	}

	if (isInstalled) {

		if (isModuleOpen(moduleName) && isPanelOpen(panelName,moduleName)){
			moduleRaise(moduleName);
		} else {
			ModuleOnWithPanel(moduleName,
						  -1, -1, 100, 200, 1, 1,
						  "",
						  fileName,
						  panelName,
						  makeDynString());
		}
	} else {
		fwGeneral_openMessagePanel("The component " + componentName + " is not installed",
								   ok, exceptionInfo,  "Error opening panel", TRUE);
	}
}
