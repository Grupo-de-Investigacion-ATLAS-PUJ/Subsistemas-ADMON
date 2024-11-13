#uses "fwInstallation/fwInstallation.ctl"

/** Initialization script for GUIless setup of InstallationTool
  @param commandLineArg (in) path where components should be installed
*/
main(string commandLineArg)
{
  fwInstallationInit_execute(true, commandLineArg);
  fwInstallationManager_setMode("WCCOActrl", FW_INSTALLATION_DB_AGENT_MANAGER_CMD, "manual");
}
