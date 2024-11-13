#uses "fwElmbPSU/fwElmbPSU.ctl"
#uses "fwElmb/fwElmbMonitorConstants.ctl"
#uses "fwInstallation/fwInstallation.ctl"

bool fwElmbMonitorLib_getConnectDPEs(	string ElmbDpName,
																			string &BootupCounter,
																			string &EMCounter,
																			string &EMBuffer,
																			string &EMBufferIndex,
																			string &ErrorStateCounter,
																			string &ResetTime)
{
// Local Variables
// ---------------
	bool bStatus = false;

	string sElmb;

// Executable Code
// ---------------
	// Ensure we have the correct DP type and get the DP name (without any
	// DPEs or configs)
	if (dpTypeName(ElmbDpName) == ELMB_TYPE_NAME) {
		sElmb = dpSubStr(ElmbDpName, DPSUB_SYS_DP);

		// Set status return to true
		bStatus = true;

		// Set all other return values
		BootupCounter = sElmb + ".monitoring.bootup.bCount";
		EMCounter = sElmb + ".monitoring.emergencyMessage.emCount";
		EMBuffer = sElmb + ".monitoring.emergencyMessage.emBuffer";
		EMBufferIndex = sElmb + ".monitoring.emergencyMessage.emIndex";
		ErrorStateCounter = sElmb + ".monitoring.errorState.esCount";
		ResetTime = sElmb + ".monitoring.resetTime";
	}

	// Return to calling routine
	return (bStatus);
}

void fwElmbMonitorLib_setupMonitorAll()
{
// Local Variables
// ---------------
	int i;

	dyn_string dsBuses;
	dyn_string dsElmbs;

// Executable Code
// ---------------
	// Get all buses in the system
	dsBuses = dpNames("*", ELMB_CAN_BUS_TYPE_NAME);

	// Set up the default monitoring for all buses
	for (i = 1; i <= dynlen(dsBuses); i++)
		fwElmbMonitorLib_setupMonitor(dsBuses[i]);

	// Get all ELMBs in the system
	dsElmbs = dpNames("*", ELMB_TYPE_NAME);

	// Set up the default monitoring for all ELMBs
	for (i = 1; i <= dynlen(dsElmbs); i++)
		fwElmbMonitorLib_setupMonitor(dsElmbs[i]);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_setupMonitor(string argsDpName)
{
// Local Variables
// ---------------
	string sDpt;
	string sDpName;

// Executable Code
// ---------------
	// Ensure we have the DP name without "."s
	sDpName = dpSubStr(argsDpName, DPSUB_SYS_DP);

	// Check which DPT has been given
	sDpt = dpTypeName(sDpName);

	if (sDpt == ELMB_TYPE_NAME) {
		// Initialise all values
		fwElmbMonitorLib_resetCounters(sDpName);
		fwElmbMonitorLib_resetBuffer(sDpName);
		fwElmbMonitorLib_clearEmergencyMessage(sDpName);
		dpSet(sDpName + ".monitoring.bootup.bExpected", false,
					sDpName + ".monitoring.autoActions.active", false,
					sDpName + ".monitoring.autoActions.parameters", fwElmbMonitorNodeParameters());
	} else if (sDpt == ELMB_CAN_BUS_TYPE_NAME) {
		dpSet(sDpName + ".monitoring.autoActions.active", false,
					sDpName + ".monitoring.autoActions.parameters", fwElmbMonitorBusParameters());
	}

	// Return to calling routine
	return;
}

dyn_bool fwElmbMonitorLib_monitorRunningActive(bool giveMessage = true)
{
// Local Variables
// ---------------
	bool bRunning;
	bool bActive;
    bool sText;

	dyn_bool dbRunningActive;

// Executable Code
// ---------------
	// Get the flags indicating whether the monitor is running and/or active
	dpGet(ELMB_MONITOR_DPNAME + ".running", bRunning,
				ELMB_MONITOR_DPNAME + ".active", bActive);

	// Check whether to display a message from this function
	if (giveMessage) {
		if (!bRunning)
			sText = "ELMB monitor script, " + ELMB_MONITOR_SCRIPT_NAME + ", is not running.\nNo automatic actions will be performed";
		else if (!bActive)
			sText = "ELMB monitor script, " + ELMB_MONITOR_SCRIPT_NAME + ", is running, but not active.\nNo automatic actions will be performed";

		// Display message
		ChildPanelOnCentral("vision/MessageInfo1",
												"Warning",
												makeDynString(sText));
	}

	// Create the dyn_bool to be returned
	dynClear(dbRunningActive);
	dynAppend(dbRunningActive, bRunning);
	dynAppend(dbRunningActive, bActive);

	// Return to calling routine
	return (dbRunningActive);
}

int fwElmbMonitorLib_monitorScriptRunning()
{
// Local Variables
// ---------------
	int iManNum = 0;
	int i, j;

	string sCtrlDebugDP;

	dyn_int diManNums;

	dyn_string dsScriptInfo;
	dyn_string dsTemp;

// Executable Code
// ---------------
	// Get manager numbers of running control scripts
	dpGet("_Connections.Ctrl.ManNums", diManNums);

	// Loop through each manager number, or until script found running
	for (i = 1; (i <= dynlen(diManNums)) && (iManNum == 0); i++) {

		// Create name of DP used to find script file names
		sCtrlDebugDP = "_CtrlDebug_CTRL_" + diManNums[i];

		// Check Dp exists, and if not, create it
		if (!dpExists(sCtrlDebugDP))
			dpCreate(sCtrlDebugDP, "_CtrlDebug");

		// Check creation worked
		if (dpExists(sCtrlDebugDP)) {
			// Clear the result so that it's known the information is up-to-date
			dpSetWait(sCtrlDebugDP + ".Result", makeDynString(""));

			// Write correct command to get name of script file
			dpSetWait(sCtrlDebugDP + ".Command", "info scripts");

			// Get result back
			dpGet(sCtrlDebugDP + ".Result", dsScriptInfo);
			for (j = 1; (j <= dynlen(dsScriptInfo)) && (iManNum == 0); j++) {
				dsTemp = strsplit(dsScriptInfo[j], ";");
				if (dynContains(dsTemp, ELMB_MONITOR_SCRIPT_NAME) > 0)
					iManNum = diManNums[i];
			}
		}
	}

	// Return to calling routine
	return (iManNum);
}

void fwElmbMonitorLib_connectToELMB(string argsElmbDpName,
																		bool argbCheckForExpected = false)
{
// Local Variables
// ---------------
	string sElmb;
	string sBus;

	dyn_string dsTemp;

// Executable Code
// ---------------
	// Ensure we have the DP name without "."s
	sElmb = dpSubStr(argsElmbDpName, DPSUB_SYS_DP);

	// We need to connect to various elements of the ELMB DP
	// Connect to the bootup messages
	dpConnect("cbkBootup", false, sElmb + ".bootup");

	// Connect to all elements of the emergency message (apart from the
	// error register, as this is read repeatedly)
  dpConnect("cbkEmergencyMessage",
  					false,
  					sElmb + ".emergency.emergencyErrorCode",
  					sElmb + ".emergency.errorCodeByte1",
  					sElmb + ".emergency.errorCodeByte2",
  					sElmb + ".emergency.errorCodeByte3",
  					sElmb + ".emergency.errorCodeByte4",
  					sElmb + ".emergency.errorCodeByte5");

	// Connect to the state
	dpConnect("cbkState", false, sElmb + ".state.value");

	if (argbCheckForExpected) {
		// Get which bus this ELMB is on
		dsTemp = strsplit(sElmb, fwDevice_HIERARCHY_SEPARATOR);
		sBus = dsTemp[1] + fwDevice_HIERARCHY_SEPARATOR + dsTemp[2];

		// Connect to the NMT for both the bus (if necessary) and the ELMB
		dpConnect("cbkManagement", false, sElmb + ".management");
		dpConnect("cbkManagement", false, sBus + ".management");

		// Connect to the item for whether a bootup is expected (after an NMT reset)
		dpConnect("cbkBootupExpected", false, sElmb + ".monitoring.bootup.bExpected");
	}

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_disconnectFromELMB(	string argsElmbDpName,
																					bool argbCheckForExpected = false)
{
// Local Variables
// ---------------
	string sElmb;
	string sBus;

	dyn_string dsTemp;

// Executable Code
// ---------------
	// Ensure we have the DP name without "."s
	sElmb = dpSubStr(argsElmbDpName, DPSUB_SYS_DP);

	// We need to connect to various elements of the ELMB DP
	// Connect to the bootup messages
	dpDisconnect("cbkBootup", sElmb + ".bootup");

	// Connect to all elements of the emergency message (apart from the
	// error register, as this is read repeatedly)
  dpDisconnect(	"cbkEmergencyMessage",
		  					sElmb + ".emergency.emergencyErrorCode",
		  					sElmb + ".emergency.errorCodeByte1",
		  					sElmb + ".emergency.errorCodeByte2",
		  					sElmb + ".emergency.errorCodeByte3",
		  					sElmb + ".emergency.errorCodeByte4",
		  					sElmb + ".emergency.errorCodeByte5");

	// Connect to the state
	dpDisconnect("cbkState", sElmb + ".state.value");

	if (argbCheckForExpected) {
		// Get which bus this ELMB is on
		dsTemp = strsplit(sElmb, fwDevice_HIERARCHY_SEPARATOR);
		sBus = dsTemp[1] + fwDevice_HIERARCHY_SEPARATOR + dsTemp[2];

		// Connect to the NMT for both the bus (if necessary) and the ELMB
		dpDisconnect("cbkManagement", sElmb + ".management");
		dpDisconnect("cbkManagement", sBus + ".management");

		// Connect to the item for whether a bootup is expected (after an NMT reset)
		dpDisconnect("cbkBootupExpected", sElmb + ".monitoring.bootup.bExpected");
	}

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_connectToBus(string argsBusDpName)
{
// Local Variables
// ---------------
	int iResult;

	string sBus;

	dyn_string dsTemp;

// Executable Code
// ---------------
	// Ensure we have the DP name without "."s
	sBus = dpSubStr(argsBusDpName, DPSUB_SYS_DP);

	// We need to connect to various elements of the Bus DP
	// Connect to the port error
	dpConnect("cbkPortError", false, sBus + ".portError");

	// Connect to the 'error passive'
  dpConnect("cbkErrorPassive", false, sBus + ".errorPassive");

  // Need to connect to alerts for voltages/currents, if the PSU component is installed
	fwInstallation_componentInstalled("fwElmbPSU", ELMB_MONITOR_PSU_VERSION_REQD, iResult);
	if (iResult == 1) {
		fwElmbPSU_connectToVI(argsBusDpName);
	}

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_disconnectFromBus(string argsBusDpName)
{
// Local Variables
// ---------------
	string sBus;
	int iResult;

	dyn_string dsTemp;

// Executable Code
// ---------------
	// Ensure we have the DP name without "."s
	sBus = dpSubStr(argsBusDpName, DPSUB_SYS_DP);

	// We need to connect to various elements of the Bus DP
	// Connect to the port error
	dpDisconnect("cbkPortError", sBus + ".portError");

	// Connect to the 'error passive'
  dpDisconnect("cbkErrorPassive", sBus + ".errorPassive");

  // Need to disconnect from alerts for voltages/currents, if the PSU component is installed
	fwInstallation_componentInstalled("fwElmbPSU", ELMB_MONITOR_PSU_VERSION_REQD, iResult);
	if (iResult == 1) {
		fwElmbPSU_disconnectFromVI(argsBusDpName);
	}

	// Return to calling routine
	return;
}

void cbkBootup(string argsDpeName, int argiBootupCounter)
{
// Local Variables
// ---------------
	bool bExpected;

	unsigned uCounter;

	string sDpName;

// Executable Code
// ---------------
	// Get the name of the DP from the DPE name
	sDpName = dpSubStr(argsDpeName, DPSUB_SYS_DP);

	// Check if the bootup is expected or not
	dpGet(sDpName + ".monitoring.bootup.bExpected", bExpected);

	// Increment the bootup counter for the monitor
	dpGet(sDpName + ".monitoring.bootup.bCount", uCounter);
	uCounter++;
	dpSet(sDpName + ".monitoring.bootup.bCount", uCounter);

	// Return to calling routine
	return;
}

// Callback to set emergency message as text into DPE
void cbkEmergencyMessage(	string sDpErrorCode, int iValueErrorCode,
													string sDpErrorByte1, unsigned uValueErrorByte1,
													string sDpErrorByte2, unsigned uValueErrorByte2,
													string sDpErrorByte3, unsigned uValueErrorByte3,
													string sDpErrorByte4, unsigned uValueErrorByte4,
													string sDpErrorByte5, unsigned uValueErrorByte5)
{
// Local Variables
// ---------------
	unsigned uIndex;
	unsigned uNewIndex;
	unsigned uValueErrorRegister;
	unsigned uCounter;

	string sDpName;
	string sMonitorDpName;
	string sMessage;
	string sTime;

	dyn_string dsBuffer;

// Executable Code
// ---------------
	// Check for zeroed emergency message
	if ((iValueErrorCode != 0) ||
			(uValueErrorByte1 != 0) ||
			(uValueErrorByte2 != 0) ||
			(uValueErrorByte3 != 0) ||
			(uValueErrorByte4 != 0) ||
			(uValueErrorByte5 != 0)) {

		// Get the name of the DP from the DPE name
		sDpName = dpSubStr(sDpErrorCode, DPSUB_SYS_DP);

		// Get the error register value
		dpGet(sDpName + ".error", uValueErrorRegister,
					sDpName + ".monitoring.emergencyMessage.emBuffer", dsBuffer,
					sDpName + ".monitoring.emergencyMessage.emIndex", uIndex,
					sDpName + ".monitoring.emergencyMessage.emCount", uCounter);

		// Increment the count of emergency messages
		uCounter++;

		// Format the emergency message as text
		sprintf(sMessage, "%04x %02x %02x %02x %02x %02x %02x",
						iValueErrorCode,
						uValueErrorRegister,
						uValueErrorByte1,
						uValueErrorByte2,
						uValueErrorByte3,
						uValueErrorByte4,
						uValueErrorByte5);

		// Add the time to the message
		sTime = getCurrentTime();
		sMessage += " (" + sTime + ")";

		// Add the formatted text to the buffer
		uNewIndex = fwElmbMonitorLib_addEmergencyMessage(sMessage, uIndex, dsBuffer);

		// Set the formatted text into the correct DPEs
		dpSet(sDpName + ".monitoring.emergencyMessage.emBuffer", dsBuffer,
					sDpName + ".monitoring.emergencyMessage.emIndex", uNewIndex,
					sDpName + ".monitoring.emergencyMessage.emCount", uCounter);

		// Zero the emergency message
		fwElmbMonitorLib_clearEmergencyMessage(sDpName);
	}

	// Return to calling routine
	return;
}

void cbkState(string argsDpeName, unsigned arguState)
{
// Local Variables
// ---------------
	bool bActive;

	int iAction;

	unsigned uCounter;

	string sDpName;
	string sAction;

	dyn_int diParameters;
	dyn_int diActions;

// Executable Code
// ---------------
	// Check for the error state
	if (arguState == 1) {

		// Get the name of the DP from the DPE name
		sDpName = dpSubStr(argsDpeName, DPSUB_SYS_DP);

		// Increment the error state counter for the monitor
		dpGet(sDpName + ".monitoring.errorState.esCount", uCounter);
		uCounter++;
		dpSet(sDpName + ".monitoring.errorState.esCount", uCounter);

		// Check whether to do any automatic action
		dpGet(sDpName + ".monitoring.autoActions.parameters", diParameters,
					sDpName + ".monitoring.autoActions.actions", diActions,
					sDpName + ".monitoring.autoActions.active", bActive);

		if (bActive) {
			iAction = dynContains(diParameters, ELMB_MONITOR_PARAMETER_ERROR_STATE);
			if (iAction > 0)
				fwElmbMonitorLib_doAction(diActions[iAction], ELMB_MONITOR_PARAMETER_ERROR_STATE, sDpName);
		}
	}

	// Return to calling routine
	return;
}

void cbkManagement(string argsDpeName, unsigned arguManagement)
{
// Local Variables
// ---------------
	string sType;

	dyn_string dsElmbs;

// Executable Code
// ---------------
	// Check if the value is for a reset
	if (arguManagement == 129) {

		// Check whether this is the bus or a specific ELMB being reset
		sType = dpTypeName(argsDpeName);
		if (sType == ELMB_CAN_BUS_TYPE_NAME) {
			// Get all ELMBs on this bus
			dsElmbs = dpNames(dpSubStr(argsDpeName, DPSUB_SYS_DP) + fwDevice_HIERARCHY_SEPARATOR + "*", ELMB_TYPE_NAME);
		} else if (sType == ELMB_TYPE_NAME) {
			dynAppend(dsElmbs, dpSubStr(argsDpeName, DPSUB_SYS_DP));
		}

		for (int i = 1; i <= dynlen(dsElmbs); i++)
			dpSet(dsElmbs[i] + ".monitoring.bootup.bExpected", true);
	}

	// Return to calling routine
	return;
}

void cbkBootupExpected(string argsDpeName, bool argbBootupExpected)
{
// Local Variables
// ---------------
	bool bTimeout;

	string sElmb;
	string sDpeName;

	time tTimeout = 10;

	dyn_string dsDpNamesToWaitFor;
	dyn_string dsDpNamesReturn;

	dyn_anytype daConditions;
	dyn_anytype daReturnedValues;

// Executable Code
// ---------------
	if (argbBootupExpected) {
		// Get the name of the DP from the DPE name
		sElmb = dpSubStr(argsDpeName, DPSUB_SYS_DP);

		// Set up parameters to wait for the bootup
		dsDpNamesToWaitFor = makeDynString(sElmb + ".bootup:_online.._value");
		dsDpNamesReturn = dsDpNamesToWaitFor;

		// Wait for up to five seconds for a bootup message
		dpWaitForValue(	dsDpNamesToWaitFor,
										daConditions,
										dsDpNamesReturn,
										daReturnedValues,
										tTimeout,
										bTimeout);

		// Check whether timeout has expired or bootup received
		if (bTimeout)
			DebugTN("Timeout expired for " + sElmb);
		else
			DebugTN("Expected bootup received from " + sElmb);

		// Reset the value
		sDpeName = dpSubStr(argsDpeName, DPSUB_SYS_DP_EL);
		dpSet(sDpeName, false);
	}

	// Return to calling routine
	return;
}

void cbkPortError(string argsDpeName, unsigned arguPortError)
{
// Local Variables
// ---------------
	bool bActive;

	int iAction;

	string sDpName;

	dyn_int diActions;
	dyn_int diParameters;

// Executable Code
// ---------------
	if (arguPortError != 0) {

		// Get the name of the DP from the DPE name
		sDpName = dpSubStr(argsDpeName, DPSUB_SYS_DP);

		// Check whether to do any automatic action
		dpGet(sDpName + ".monitoring.autoActions.parameters", diParameters,
					sDpName + ".monitoring.autoActions.actions", diActions,
					sDpName + ".monitoring.autoActions.active", bActive);

		if (bActive) {
			iAction = dynContains(diParameters, ELMB_MONITOR_PARAMETER_PORT_ERROR);
			if (iAction > 0)
				fwElmbMonitorLib_doAction(diActions[iAction], ELMB_MONITOR_PARAMETER_PORT_ERROR, sDpName);
		}
	}

	// Return to calling routine
	return;
}

void cbkErrorPassive(string argsDpeName, int argiErrorPassive)
{
// Local Variables
// ---------------
	bool bActive;

	int iAction;

	string sDpName;

	dyn_int diActions;
	dyn_int diParameters;

// Executable Code
// ---------------
	if (argiErrorPassive != 0) {

		// Get the name of the DP from the DPE name
		sDpName = dpSubStr(argsDpeName, DPSUB_SYS_DP);

		// Check whether to do any automatic action
		dpGet(sDpName + ".monitoring.autoActions.parameters", diParameters,
					sDpName + ".monitoring.autoActions.actions", diActions,
					sDpName + ".monitoring.autoActions.active", bActive);

		if (bActive) {
			iAction = dynContains(diParameters, ELMB_MONITOR_PARAMETER_ERROR_PASSIVE);
			if (iAction > 0)
				fwElmbMonitorLib_doAction(diActions[iAction], ELMB_MONITOR_PARAMETER_ERROR_PASSIVE, sDpName);
		}
	}

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_resetCounters(string argsDpName)
{
// Local Variables
// ---------------
	string sDpName;

// Executable Code
// ---------------
	// Make certain we have just the DP name (and not the DPE name)
	sDpName = dpSubStr(argsDpName, DPSUB_SYS_DP);

	// Reset all counters
	dpSet(sDpName + ".monitoring.bootup.bCount", 0,
				sDpName + ".monitoring.emergencyMessage.emCount", 0,
				sDpName + ".monitoring.errorState.esCount", 0,
				sDpName + ".monitoring.resetTime", getCurrentTime());

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_resetBuffer(string argsDpName)
{
// Local Variables
// ---------------
	string sDpName;

// Executable Code
// ---------------
	// Make certain we have just the DP name (and not the DPE name)
	sDpName = dpSubStr(argsDpName, DPSUB_SYS_DP);

	// Clear the emergency message buffer
	dpSet(sDpName + ".monitoring.emergencyMessage.emBuffer", makeDynString(),
				sDpName + ".monitoring.emergencyMessage.emIndex", 0);

	// Return to calling routine
	return;
}

unsigned fwElmbMonitorLib_addEmergencyMessage(string argsNewEmergencyMessage,
																							unsigned arguCurrentIndex,
																							dyn_string &argdsEmergencyMessageBuffer)
{
// Local Variables
// ---------------
	unsigned uNewIndex;

// Executable Code
// ---------------
	// Check for certain cases that have to be handled in special ways
	if (dynlen(argdsEmergencyMessageBuffer) == 0) {
		// This is about the easiest case
		argdsEmergencyMessageBuffer = makeDynString(argsNewEmergencyMessage);
		uNewIndex = 2;
	} else if (dynlen(argdsEmergencyMessageBuffer) < ELMB_MONITOR_EM_BUFFER_SIZE) {
		dynAppend(argdsEmergencyMessageBuffer, argsNewEmergencyMessage);
		uNewIndex = arguCurrentIndex + 1;
	} else {
		// The current index alway points to the oldest emergency message, therefore, replace it
		argdsEmergencyMessageBuffer[arguCurrentIndex] = argsNewEmergencyMessage;
		uNewIndex = arguCurrentIndex + 1;
	}

	// Check the index is valid before returning
	if (uNewIndex > ELMB_MONITOR_EM_BUFFER_SIZE)
		uNewIndex = 1;

	// Return to calling routine
	return (uNewIndex);
}

// Callback to clear (set to zero) emergency message elements in the ELMB
void fwElmbMonitorLib_clearEmergencyMessage(string argsElmbDpName)
{
// Local Variables
// ---------------
	string sElmb;

// Executable Code
// ---------------
	// Ensure we have just the DP name
	sElmb = dpSubStr(argsElmbDpName, DPSUB_SYS_DP);

	// Zero the emergency message
  dpSet(sElmb + ".emergency.emergencyErrorCode", 0,
 				sElmb + ".emergency.errorCodeByte1", 0,
 				sElmb + ".emergency.errorCodeByte2", 0,
 				sElmb + ".emergency.errorCodeByte3", 0,
 				sElmb + ".emergency.errorCodeByte4", 0,
 				sElmb + ".emergency.errorCodeByte5", 0);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_giveWarning(int iParameter, string argsDp)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
	// None!!!

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_nodeReset(int iParameter, string argsDp)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
	dpSet(argsDp + ".management", 129);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_busReset(int iParameter, string argsDp)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
	dpSet(argsDp + ".management", 129);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_hardReset(int iParameter, string argsDp)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
	fwElmbPSU_hardReset(argsDp);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_powerOff(int iParameter, string argsDp)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
	fwElmbPSU_switchPower(argsDp, false);

	// Return to calling routine
	return;
}

void fwElmbMonitorLib_doAction(int iAction, int iParameter, string sDpe)
{
// Local Variables
// ---------------
	string sAction;
	string sParameter;
	string sText;

// Executable Code
// ---------------
	if (iAction != ELMB_MONITOR_ACTION_NONE) {
		sAction = fwElmbMonitorLib_getActionText(iAction);
		sParameter = fwElmbMonitorLib_getParameterText(iParameter);
		sText = sAction + " for " + sDpe + " due to " + sParameter;
		DebugTN(sText);
	}

	// Select which action to complete
	switch (iAction) {
		case ELMB_MONITOR_ACTION_WARNING:
			fwElmbMonitorLib_giveWarning(iParameter, sDpe);
			break;
		case ELMB_MONITOR_ACTION_NODE_RESET:
			fwElmbMonitorLib_nodeReset(iParameter, sDpe);
			break;
		case ELMB_MONITOR_ACTION_BUS_RESET:
			fwElmbMonitorLib_busReset(iParameter, sDpe);
			break;
		case ELMB_MONITOR_ACTION_HARD_RESET:
			fwElmbMonitorLib_hardReset(iParameter, sDpe);
			break;
		case ELMB_MONITOR_ACTION_POWER_OFF:
			fwElmbMonitorLib_powerOff(iParameter, sDpe);
			break;
	}

	// Return to calling routine
	return;
}

string fwElmbMonitorLib_getActionText(int iAction)
{
// Local Variables
// ---------------
	string sText;

// Executable Code
// ---------------
	// Select the relevant text
	switch (iAction) {
		case ELMB_MONITOR_ACTION_NONE:
			sText = "None";
			break;
		case ELMB_MONITOR_ACTION_WARNING:
			sText = "Give Warning";
			break;
		case ELMB_MONITOR_ACTION_NODE_RESET:
			sText = "Node Soft Reset";
			break;
		case ELMB_MONITOR_ACTION_BUS_RESET:
			sText = "Bus Soft Reset";
			break;
		case ELMB_MONITOR_ACTION_HARD_RESET:
			sText = "Bus Hard Reset";
			break;
		case ELMB_MONITOR_ACTION_POWER_OFF:
			sText = "Switch Off Power to Bus";
			break;
	}

	// Return to calling routine
	return (sText);
}

string fwElmbMonitorLib_getParameterText(int iParameter)
{
// Local Variables
// ---------------
	string sText;

// Executable Code
// ---------------
	// Select the relevant text
	switch (iParameter) {
		case ELMB_MONITOR_PARAMETER_ERROR_STATE:
			sText = "Error State";
			break;
		case ELMB_MONITOR_PARAMETER_ERROR_PASSIVE:
			sText = "Error Passive";
			break;
		case ELMB_MONITOR_PARAMETER_PORT_ERROR:
			sText = "Port Error";
			break;
		case ELMB_MONITOR_PARAMETER_CANI_HIGH:
			sText = "CAN Current too high";
			break;
		case ELMB_MONITOR_PARAMETER_CANV_HIGH:
			sText = "CAN Voltage too high";
			break;
		case ELMB_MONITOR_PARAMETER_CANI_LOW:
			sText = "CAN Current too low";
			break;
		case ELMB_MONITOR_PARAMETER_CANV_LOW:
			sText = "CAN Voltage too low";
			break;
		case ELMB_MONITOR_PARAMETER_ADI_HIGH:
			sText = "Analog and Digital Current too high";
			break;
		case ELMB_MONITOR_PARAMETER_ADV_HIGH:
			sText = "Analog and Digital Voltage too high";
			break;
		case ELMB_MONITOR_PARAMETER_ADI_LOW:
			sText = "Analog and Digital Current too low";
			break;
		case ELMB_MONITOR_PARAMETER_ADV_LOW:
			sText = "Analog and Digital Voltage too low";
			break;
	}

	// Return to calling routine
	return (sText);
}
