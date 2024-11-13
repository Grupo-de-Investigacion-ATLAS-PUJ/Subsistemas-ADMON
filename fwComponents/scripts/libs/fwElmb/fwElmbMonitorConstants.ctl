#uses "fwInstallation/fwInstallation.ctl"


// Constant Definitions
// --------------------
const string ELMB_MONITOR_DPNAME = "fwElmbMonitor";
const string ELMB_MONITOR_SCRIPT_NAME = "fwElmb/fwElmbMonitor.ctl";

const string ELMB_MONITOR_PSU_VERSION_REQD = "1.0.3";

const unsigned ELMB_MONITOR_EM_BUFFER_SIZE = 8;

// Action IDs - These must NOT be changed, ever!
const int ELMB_MONITOR_ACTION_NONE = 0;
const int ELMB_MONITOR_ACTION_WARNING = 1;
const int ELMB_MONITOR_ACTION_NODE_RESET = 2;
const int ELMB_MONITOR_ACTION_BUS_RESET = 3;
const int ELMB_MONITOR_ACTION_HARD_RESET = 4;
const int ELMB_MONITOR_ACTION_POWER_OFF = 5;

// Parameter IDs - These must NOT be changed, ever!
const int ELMB_MONITOR_PARAMETER_ERROR_STATE = 1;
const int ELMB_MONITOR_PARAMETER_ERROR_PASSIVE = 2;
const int ELMB_MONITOR_PARAMETER_PORT_ERROR = 3;
const int ELMB_MONITOR_PARAMETER_CANI_HIGH = 4;
const int ELMB_MONITOR_PARAMETER_CANV_HIGH = 5;
const int ELMB_MONITOR_PARAMETER_CANI_LOW = 6;
const int ELMB_MONITOR_PARAMETER_CANV_LOW = 7;
const int ELMB_MONITOR_PARAMETER_ADI_HIGH = 8;
const int ELMB_MONITOR_PARAMETER_ADV_HIGH = 9;
const int ELMB_MONITOR_PARAMETER_ADI_LOW = 10;
const int ELMB_MONITOR_PARAMETER_ADV_LOW = 11;

// Functions for retrieving other constant definitions that cannot be
// defined above
dyn_int fwElmbMonitorAutomaticActions(bool forBus = false)
{
// Local Variables
// ---------------
	int iResult;
	
	dyn_int diActions = makeDynInt(	ELMB_MONITOR_ACTION_NONE,
																	ELMB_MONITOR_ACTION_WARNING);
	dyn_int diPSUActions = makeDynInt(ELMB_MONITOR_ACTION_HARD_RESET,
																		ELMB_MONITOR_ACTION_POWER_OFF);
	
// Executable Code
// ---------------
	// Check whether to give automatic actions for bus or node
	if (forBus) {
		// It means nothing to reset a node for a bus error (i.e. which node to reset!?)
		dynAppend(diActions, ELMB_MONITOR_ACTION_BUS_RESET);
	} else {
		dynAppend(diActions, ELMB_MONITOR_ACTION_NODE_RESET);
		dynAppend(diActions, ELMB_MONITOR_ACTION_BUS_RESET);
	}
	
	// Check whether the PSU component is installed
	fwInstallation_componentInstalled("fwElmbPSU", ELMB_MONITOR_PSU_VERSION_REQD, iResult);
	if (iResult == 1) {
		dynAppend(diActions, diPSUActions);
	}
	
	// Return to values to the calling routine
	return(diActions);
}

dyn_int fwElmbMonitorNodeParameters()
{
// Local Variables
// ---------------
	dyn_int diParameters = makeDynInt(ELMB_MONITOR_PARAMETER_ERROR_STATE);
	
// Executable Code
// ---------------
	// Return to values to the calling routine
	return(diParameters);
}

dyn_int fwElmbMonitorBusParameters()
{
// Local Variables
// ---------------
	int iResult;
	
	dyn_int diParameters = makeDynInt(ELMB_MONITOR_PARAMETER_ERROR_PASSIVE,
																		ELMB_MONITOR_PARAMETER_PORT_ERROR);
	dyn_int diPSUParameters = makeDynInt(	ELMB_MONITOR_PARAMETER_CANI_HIGH,
																				ELMB_MONITOR_PARAMETER_CANV_HIGH,
																				ELMB_MONITOR_PARAMETER_CANI_LOW,
																				ELMB_MONITOR_PARAMETER_CANV_LOW,
																				ELMB_MONITOR_PARAMETER_ADI_HIGH,
																				ELMB_MONITOR_PARAMETER_ADV_HIGH,
																				ELMB_MONITOR_PARAMETER_ADI_LOW,
																				ELMB_MONITOR_PARAMETER_ADV_LOW);
	
// Executable Code
// ---------------
	// Check whether the PSU component is installed
	fwInstallation_componentInstalled("fwElmbPSU", ELMB_MONITOR_PSU_VERSION_REQD, iResult);
	if (iResult == 1) {
		dynAppend(diParameters, diPSUParameters);
	}
	
	// Return to values to the calling routine
	return(diParameters);
}
