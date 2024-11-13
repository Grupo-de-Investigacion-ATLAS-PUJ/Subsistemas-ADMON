#uses "fwInstallation/fwInstallation.ctl"

main()
{
	string version;

	int idMenu = moduleAddMenu("JCOP Framework");
	bool isInstalled = fwInstallation_isComponentInstalled("fwDeviceEditorNavigator", version);
	if (!isInstalled) return;

	moduleAddAction("Device Editor and Navigator", "", "", idMenu, -1, "_fwDeviceEditorNavigatorGedi_openDEN");
    moduleAddDockModule("fwDeviceEditorNavigator", "fwDeviceEditorNavigator/fwDeviceEditorNavigator.pnl", makeDynString("$hideCloseButton:"+true));
}


void _fwDeviceEditorNavigatorGedi_openDEN()
{
	string moduleName="Device Editor Navigator (GEDI)";
	string panelName="DEN";

	if (isModuleOpen(moduleName) && isPanelOpen(panelName,moduleName)) {
		moduleRaise(moduleName);
	} else {
		ModuleOnWithPanel(	moduleName,
							-1, -1, 100, 200, 1, 1,
							"",
							"fwDeviceEditorNavigator/fwDeviceEditorNavigator.pnl",
							panelName, makeDynString());
	}
}
