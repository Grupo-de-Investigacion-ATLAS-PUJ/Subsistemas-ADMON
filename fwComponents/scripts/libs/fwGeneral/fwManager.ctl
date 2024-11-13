// SPDX-FileCopyrightText: © 2015 CERN <mail-TTO@cern.ch>
/**@file

   This library contains functions related to WinCC OA Managers

   @par Creation Date
        18/02/2015


   @author Piotr Golonka (CERN EN/ICE)
 */


#uses "fwGeneral/fwDPELock.ctl"
//#uses "fwInstallationRedu.ctl" // fwInstallation are libs loaded by default

/** Returns the list of Ctrl scripts executed by a given Ctrl Manager.

    @par systemName (input) the name of the system to be queried
    @par ctrlManNum (input) the manager number to be queried
    @par exceptionInfo (output) the standard exception-handling variable

    @returns the list of names of scripts executed by given Ctrl manager,

    If not existing, the necessaery _CtrlDebug datapoint is created.
 */
synchronized dyn_string fwManager_getScriptsRunByCtrlMan(string systemName, unsigned ctrlManNum, dyn_string &exceptionInfo)
{
	dyn_string listOfScripts;
	string ctrlDbgDP =  "_CtrlDebug_CTRL_" + ctrlManNum;

	if (systemName == "") systemName = getSystemName();
	int systemNumber = getSystemId(systemName);
	if (systemNumber < 0) {
		fwException_raise(exceptionInfo, "ERROR", "Cannot retrieve list of scripts for Ctrl " +
						  ctrlManNum + " on " + systemName + ": system not connected or does not exist", "");
		return listOfScripts;
	}

	if (!dpExists(ctrlDbgDP)) {
		DebugTN("WARNING: fwManager_getScriptsRunByCtrlMan: trying to create missing datapoint " + ctrlDbgDP + " on system " + systemName);
		int rc = dpCreate(ctrlDbgDP, "_CtrlDebug", systemNumber);

		if (rc < 0) {
			dyn_errClass err = getLastError();
			fwException_raise(exceptionInfo, "ERROR", "Cannot retrieve list of scripts for Ctrl " +
							  ctrlManNum + " on " + systemName + ": Failed to create _CtrlDebug DP " + ctrlDbgDP + ";" + getErrorText(err), "");
			return listOfScripts;
		}
		delay(0, 100); // make sure that the DP already exists
	}


	ctrlDbgDP =  systemName + ctrlDbgDP;

	// lock, then trigger the command on the Debug datapoint
	fwDPELock_tryLock(ctrlDbgDP + ".Command", exceptionInfo, 7, 10);
	if (dynlen(exceptionInfo)) {
		DebugTN("PROBLEM at fwManager_getScriptsRunByCtrlMan() for " + systemName + " CTRL#" + (int)ctrlManNum, exceptionInfo[2]);
		dynClear(exceptionInfo);
		return listOfScripts;
	}

	dpSet(ctrlDbgDP + ".Command:_original.._value", "info scripts");

	bool hasResult = false;
	dyn_string result;

	bool timerExpired;
	dyn_anytype retValues;
	const int maxTimeout = 5;
	dpWaitForValue(ctrlDbgDP + ".Result:_original.._value", makeDynMixed(),
				   makeDynString(ctrlDbgDP + ".Result:_original.._stime",
								 ctrlDbgDP + ".Result:_original.._value"),
				   retValues, maxTimeout, timerExpired);


	// unlock the Debug datapoint
	fwDPELock_unlock(ctrlDbgDP + ".Command", exceptionInfo);
	if (dynlen(exceptionInfo)) {
		DebugTN("WARNING: fwManager_getScriptsRunByCtrlMan() exception in unlocking CTRL Manager " + systemName + " #" + (int)ctrlManNum, exceptionInfo[2]);
		dynClear(exceptionInfo);
	}


	if (!timerExpired) {
		hasResult = true;
		result = retValues[2];
		if (dynlen(result) && result[1] == "all breakpoints deleted") {
			//the value was already discarded by the debugger...
			DebugTN("WARNING: fwManager_getScriptsRunByCtrlMan: CTRL Manager " + systemName + " #" + (int)ctrlManNum + " cannot check (CtrlDbg discarded the value)");
			hasResult = false;
			return listOfScripts;
		}
	}

	if (!hasResult) {
		// note: sometimes the manager is not running (even though indicated in _Connections DP.
		// in this case, the CtrlDebug does not respond. Report it in the log, yet do not fail.
		DebugTN("WARNING: fwManager_getScriptsRunByCtrlMan: CTRL Manager " + systemName + " #" + (int)ctrlManNum + " does not respond");
	}

	// the result is a list of strings in form such as
	// ScriptId: 0;unSelectDeselect.ctl
	// ScriptId: 1;unDistributedControl.ctl
	// ScriptId: 2; current thread: 2;unSystemIntegrity.ctl
	// ScriptId: 3;unSendMail.ctl
	// ScriptId: 4;scheduler.ctc
	// ScriptId: 5;unDeviceSet.ctl
	for (int i = 1; i <= dynlen(result); i++) {
		dyn_string ds = strsplit(result[i], ";");
		if (dynlen(ds) > 1) {
			// we take the last token (see example of scripId:2 above!
			string scriptName = ds[dynlen(ds)];
			dynAppend(listOfScripts, scriptName);
		}
	}


	return listOfScripts;
}


// Internal variables for driver checks
private global bool _fwManager_driverCheckConnected = false;
private global dyn_int _fwManager_connectedDrivers;

/** @internal @private
 *	internal callback tracing the driver check
 *
 * @reviewed 2018-06-21 @whitelisted{BackgroundProcessing}
 */
private void _fwManager_checkDriverRunningCB(string dp, dyn_int values)
{
	_fwManager_connectedDrivers = values;
	_fwManager_driverCheckConnected = true;
}

/** Check whether specified driver is running

    @par drvNumber (input) the driver number to be checked
    @par exceptionInfo (output) the standard exception-handling variable
    @par systemName (input,optional) the name of the system to be queried; by default local system ("")
    @returns a boolean value with the result of check.

    The calls for the local system are handled through a cache, whereas those for remote ones
    are handled with dpGet (consider the latency of a roundtrip).
    The cache is established through a dpConnect to the _Connections.Driver.ManNums datapoint.
 */
bool fwManager_checkDriverRunning(int drvNumber, dyn_string &exceptionInfo, string systemName = "")
{
	// start with most probable fast path using the cache
	if (systemName == "" || systemName == getSystemName()) {

		if (_fwManager_driverCheckConnected) return (bool)(dynContains(_fwManager_connectedDrivers, drvNumber));
		// otherwise not yet inited - see the code past the else statement below

	} else {

		// non-local system
		// note the peculiarity of getReduDp, which needs system name in the dpname and in the argument!
		string connectionsDp = fwInstallationRedu_getReduDp(systemName + "_Connections", systemName);
		dyn_int drvsRunning;
		if ( (!dpExists(connectionsDp)) || (dpGet(connectionsDp + ".Driver.ManNums", drvsRunning) != 0) ) {
			fwException_raise(exceptionInfo, "ERROR", "Could not get running drivers on system " + systemName, "");
			return false;
		}
		return (bool)(dynContains(drvsRunning, drvNumber));

	}

	// if we ended up here, it means that this is for local system but the first call ever:
	// need to initialize the cache-handling, and get the result...

	string connectionsDp = fwInstallationRedu_getReduDp("_Connections", systemName);

	// we want the dpConnect to stay forever in this manager, hence we trigger it with
	// the startScript() construct, in a global context
	string dpe = connectionsDp + ".Driver.ManNums";
	string script;
	script += "main() {";
	script += "  dpConnect(\"_fwManager_checkDriverRunningCB\" ,true, "   + "\"" + dpe + "\""   +    " );";
	script += "}";
	startScript(script);

	delay(0, 100);// some more opportunity to get the first callback finish

	if (!_fwManager_driverCheckConnected) {
		// for this first time, get it immediately with dpGet and put in the cache...
		if (dpGet(systemName + connectionsDp + ".Driver.ManNums", _fwManager_connectedDrivers) != 0) {
			fwException_raise(exceptionInfo, "ERROR", "Could not get running drivers", "");
			return false;
		}
	}
	// get the response based on cached value
	return (bool)(dynContains(_fwManager_connectedDrivers, drvNumber));
}


/** This function returns the host name where the given manager is running.  The manager id passed is
the internal PVSS manager ID as used by functions like convManIdToInt().  The function looks in the
internal PVSS _Connections DPs to find this information.

@par Constraints
    Currently only supports CTRL and UI managers (because users can lock configs from these managers)

@par Usage
    Internal

@par PVSS managers
    VISION, CTRL

@param managerId                     The manager ID for which you want to find the host name
@param exceptionInfo       Details of any exceptions are returned here

@returns the host name
*/  
string fwManager_getManagerHostname(int managerId, dyn_string &exceptionInfo)
{
	string managerHostName;
    
    int managerType;
    unsigned manType, manNum, manSystem;
    string systemName, typeName;
    
    //extract manager type and manager number from composite manager id
    getManIdFromInt(managerId, manType, manNum, manSystem);
    //currently only supporting UI and CTRL managers
    switch(manType)
    {
        case UI_MAN:
            typeName = "Ui";
            break;
        case CTRL_MAN:
            typeName = "Ctrl";
            break;
        default:
            return "Unknown";
            break;
    }
    
    systemName = getSystemName(manSystem);
    
    //get the internal DP which stores the host of each manager
    dyn_int manNums;
    dyn_string manHosts;
    string sConnectionsDp = fwInstallationRedu_getLocalDp("_Connections");
    dpGet(systemName + sConnectionsDp + "." + typeName + ".ManNums", manNums,
          systemName +  sConnectionsDp + "."  + typeName + ".HostNames", manHosts);
    
    int pos = dynContains(manNums, manNum);
    
    if (pos <= 0) return "Unknown";
    
    return manHosts[pos];
}
