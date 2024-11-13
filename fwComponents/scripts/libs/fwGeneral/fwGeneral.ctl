// SPDX-FileCopyrightText: © 2004 CERN <mail-TTO@cern.ch>
/**@file

   @par Creation Date
        24/03/04

   @par Constraints
        None

   @author
        Manuel Gonzalez Berges (IT-CO)
 */

#uses "fwGeneral/fwException.ctl"
#uses "fwGeneral/fwDPELock.ctl"
#uses "fwGeneral/fwExceptionHandling.ctl"
#uses "fwGeneral/fwListManipulation.ctl"

//@{

// Constants
const string fwGeneral_DYN_STRING_DEFAULT_SEPARATOR = "|";
// Date Time Widget constants
const string FW_GENERAL_NATURAL_TIME_FORMAT = "%d/%m/%Y - %H:%M:%S";
const string FW_GENERAL_GENERIC_TIME_FORMAT = "%Y.%m.%d %H:%M:%S";
const string FW_GENERAL_TIMEZONE_UTC = "UTC";
const string FW_GENERAL_TIMEZONE_LOCAL = "LOCAL";
// DP and DP-type definition
const string FW_GENERAL_DPT = "_FwGeneral";
const string FW_GENERAL_DP = "fwGeneral";
// _FwGeneral DP-type elements definition
const string FW_GENERAL_HELP_DPE = FW_GENERAL_DP + ".help";
const string FW_GENERAL_HELP_BROWSER_CMD_LIN_DPE = FW_GENERAL_HELP_DPE + ".helpBrowserCommandLinux";
const string FW_GENERAL_HELP_BROWSER_CMD_WIN_DPE = FW_GENERAL_HELP_DPE + ".helpBrowserCommandWindows";
const string FW_GENERAL_HELP_USE_INTERNAL_BROWSER_DPE = FW_GENERAL_HELP_DPE + ".useInternalHelpBrowser";
// Default help browser configuration
const string FW_GENERAL_DEFAULT_HELP_EXT_BROWSER_COMMAND_LIN = "xdg-open \"$1\"";
const string FW_GENERAL_DEFAULT_HELP_EXT_BROWSER_COMMAND_WIN = "cmd /c start \"\" \"$1\"";
const string FW_GENERAL_DEFAULT_HELP_USE_INTERNAL_BROWSER = true;
// File URI scheme definition
const string FW_GENERAL_FILE_URI_SCHEME = "file:///";
// Help file allowed extenstions (fwGeneral_openHelpForPanel() will search for help file with one of these extensions)
const dyn_string FW_GENERAL_HELP_FILE_EXTENSIONS = makeDynString(".html", ".htm");


// Global variables

/// constants representing dynamic dpe types @reviewed 2019-08-19
global const dyn_int g_fwGeneral_dynDpeTypes = makeDynInt(  DPEL_DYN_BIT32,     // dynamic array of 32-bit pattern
															DPEL_DYN_BIT64,     // dynamic array of 64-bit pattern
															DPEL_DYN_BLOB,      // dynamic array of blob
															DPEL_DYN_BOOL,      // dynamic array of booleans
															DPEL_DYN_CHAR,      // dynamic array of character
															DPEL_DYN_DPID,      // dynamic array of DP-Identifiers
															DPEL_DYN_FLOAT,     // dynamic array of floating-point numbers
															DPEL_DYN_INT,       // dynamic array of integer numbers
															DPEL_DYN_LANGSTRING,// dynamic array of multilingual texts
															DPEL_DYN_LONG,      // dynamic array of long integer values
															DPEL_DYN_STRING,    // dynamic array of texts
															DPEL_DYN_TIME,      // dynamic array of timestamps
															DPEL_DYN_UINT,      // dynamic array of unsignes integer numbers
															DPEL_DYN_ULONG);    // dynamic array of long unsigned integer numbers


/** Opens confirmation dialog panel, and returns result
   user selection

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION

   @param dpe name of the datapoint where the command will be applied
   @param command short explanation of the action to be confirmed
   @param confirmation whether the user confirmed the command or not
   @param exceptionInfo returns details of any errors
 */
void fwGeneral_commandConfirmation(string dpe, string command, bool &confirmation, dyn_string &exceptionInfo)
{

	dyn_float df;
	dyn_string ds;

	ChildPanelOnCentralModalReturn( "fwGeneral/fwCommandConfirmation.pnl",
									"Command confirmation.",
									makeDynString(  "$sDpName:" + dpe,
													"$sCommand:" + command),
									df, ds);
	if (ds[1] == "TRUE") {
		confirmation = TRUE;
	} else {
		confirmation = FALSE;
	}
}


/** Returns end date and time selected by the user and performs format check.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - endDateField
   - endTimeField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param  bOk Output - Returns info whether provided times were in correct format or not. In case of wrong format, current time is given back as return value.
   @param  dsException - Input/Output: Carrier for exception message to be shown to user
   @return End date as time value
 */
time fwGeneral_dateTimeWidget_getEndDateTime(bool &bOk, dyn_string &dsException)
{
	string sEndTime;
	time tEndTime;

	sEndTime = endDateField.text + " " + endTimeField.text;
	bOk = fwGeneral_hasCorrectFormat(sEndTime);

	if (bOk) {
		tEndTime = fwGeneral_stringToDate(sEndTime);
	} else {
		tEndTime = getCurrentTime();
		dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
	}

	return tEndTime;
}


/** Returns start date and time selected by the user and performs format check.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - startDateField
   - startTimeField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param  bOk Output - Returns info whether provided times were in correct format or not. In case of wrong format, current time is given back as return value.
   @param  dsException - Input/Output: Carrier for exception message to be shown to user
   @return Start date as time value
 */
time fwGeneral_dateTimeWidget_getStartDateTime(bool &bOk, dyn_string &dsException)
{
	string sStartTime;
	time tStartTime;

	sStartTime = startDateField.text + " " + startTimeField.text;
	bOk = fwGeneral_hasCorrectFormat(sStartTime);

	if (bOk) {
		tStartTime = fwGeneral_stringToDate(sStartTime);
	} else {
		tStartTime = getCurrentTime();
		dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
	}

	return tStartTime;
}


/** Returns the time zone used to determine the current time.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - selectedTimeZone

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @return Time zone as string
 */
string fwGeneral_dateTimeWidget_getTimeZone()
{
	string sTimeZone;

	sTimeZone = selectedTimeZone.text();

	return sTimeZone;
}


/** Checks whether the user has selected a positive time interval in the date/time widget or not.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - startDateField
   - startTimeField
   - endDateField
   - endTimeField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param  dsException - Input/Output: Carrier for exception message to be shown to user
   @return Boolean value TRUE if positive, FALSE if negative time interval
 */
bool fwGeneral_dateTimeWidget_positivePeriodSelected(dyn_string &dsException)
{
	bool isPositive = FALSE;
	bool bOkStart, bOkEnd;
	time tStartTime, tEndTime;
	string sStartTime, sEndTime;

	sStartTime = startDateField.text + " " + startTimeField.text;
	sEndTime = endDateField.text + " " + endTimeField.text;

	bOkStart = fwGeneral_hasCorrectFormat(sStartTime);
	bOkEnd = fwGeneral_hasCorrectFormat(sEndTime);

	if (bOkStart && bOkEnd) {
		tStartTime = fwGeneral_stringToDate(sStartTime);
		tEndTime = fwGeneral_stringToDate(sEndTime);

		if (period(tStartTime) < period(tEndTime)) {
			isPositive = TRUE;
		} else {
			dsException = makeDynString("Error", "End date is prior to start date.\nPlease correct.", "");
		}
	} else {
		dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
	}

	return isPositive;
}


/** Enables or disables the UI elements of the Date Time Widget.
    !!! Make sure widget is initialised before using this function. !!!
    (If you want to enable/disable upon initialization, use the provided $-parameter)

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - startNowButton
   - startDateField
   - startTimeField
   - startTimeSpin
   - startDateChooserButton
   - startDateButton
   - endNowButton
   - endDateField
   - endTimeField
   - endTimeSpin
   - endDateChooserButton
   - endDateButton

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] bState  state
 */
void fwGeneral_dateTimeWidget_setEnabled(bool bState)
{
	startNowButton.enabled(bState);
	startTimeField.enabled(bState);
	startTimeSpin.enabled(bState);
	startDateChooserButton.enabled(bState);
	startDateField.enabled(bState);
	startDateButton.enabled(bState);

	endNowButton.enabled(bState);
	endTimeField.enabled(bState);
	endTimeSpin.enabled(bState);
	endDateChooserButton.enabled(bState);
	endDateField.enabled(bState);
	endDateButton.enabled(bState);
}

/**
 * Is the DateTime widget enabled?
 *
 * @return bool
 */
public bool fwGeneral_dateTimeWidget_isEnabled()
{

	if (myManType() == UI_MAN) {
		return shapeExists("startNowButton") && startNowButton.enabled;
	} else {
		return false;
	}

}


/** Sets the end date and time in the Date Time Widget.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - endDateField
   - endTimeField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] tDateTime date and time
 */
void fwGeneral_dateTimeWidget_setEndDateTime(time tDateTime)
{
	endDateField.text = formatTime("%d/%m/%Y", tDateTime);
	endTimeField.text = formatTime("%H:%M:%S", tDateTime);
}


/** Sets the start date and time in the Date Time Widget.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - startDateField
   - startTimeField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] tDateTime date and time
 */
void fwGeneral_dateTimeWidget_setStartDateTime(time tDateTime)
{
	startDateField.text = formatTime("%d/%m/%Y", tDateTime);
	startTimeField.text = formatTime("%H:%M:%S", tDateTime);
}


/** Sets the time zone used to determine the current time.

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - selectedTimeZone

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] sTimeZone time zone (e.g. FW_GENERAL_NATURAL_TIME_FORMAT, FW_GENERAL_GENERIC_TIME_FORMAT)
 */
void fwGeneral_dateTimeWidget_setTimeZone(string sTimeZone)
{
	selectedTimeZone.text(sTimeZone);
}


/** Makes the UI elements of the Date Time Widget visible/invisible
    while still allowing for the different modes (date and time vs. only date; time zone shown).
    !!! Make sure the widget is initialised before using this function. !!!

   @par Constraints
        To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
   The following UI elements have to be existent:
   - startNowButton
   - startDateField
   - startTimeField
   - startTimeSpin
   - startDateChooserButton
   - startDateButton
   - endNowButton
   - endDateField
   - endTimeField
   - endTimeSpin
   - endDateChooserButton
   - endDateButton
   - startTimeLabel
   - endTimeLabel
   - timeZoneLabel
   - selectedTimeZone
   - dateTimeSeparator
   - dateAndTimeShownField
   - timeZoneShownField

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] bState state
 */
void fwGeneral_dateTimeWidget_setVisible(bool bState)
{
	startTimeLabel.visible(bState);
	endTimeLabel.visible(bState);
	startDateField.visible(bState);
	endDateField.visible(bState);

	if (dateAndTimeShownField.text) {
		dateTimeSeparator.visible(bState);
		startTimeField.visible(bState);
		startTimeSpin.visible(bState);
		startNowButton.visible(bState);
		startDateChooserButton.visible(bState);
		endTimeField.visible(bState);
		endTimeSpin.visible(bState);
		endNowButton.visible(bState);
		endDateChooserButton.visible(bState);
	} else {
		startDateButton.visible(bState);
		endDateButton.visible(bState);
	}

	if (timeZoneShownField.text) {
		timeZoneLabel.visible(bState);
		selectedTimeZone.visible(bState);
	}
}


/** Opens the datapoint type selector panel and return the
   user selection

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS maangers
        VISION

   @param selectedDpTypes  returns the list of selected DP Types (one or multiple, depending on selectMultiple parameter.
                                        If specified as input it can contain the pre-defined selection.
   @param disabledDpTypes  list of DP Types that are disabled in the selection list. Specifying empty list means that all
                                        items are selectable
   @param exceptionInfo	returns details of any errors
   @param selectMultiple   determines if the selection list allows for multiple selection, or single selection only.
   @param text          panel title. If an empty string is specified, then "Select Datapoint Types" will be used.
 */
void fwGeneral_DpTypeSelector(  dyn_string &selectedDpTypes, dyn_string disabledDpTypes, dyn_string &exceptionInfo,
								bool selectMultiple = FALSE, string text = "")
{
	dyn_float df;
	dyn_string ds;

	if (text == "")
		text = "Select DP Types";
	DebugN(selectedDpTypes);
	ChildPanelOnCentralReturn(  "fwGeneral/fwGeneralDpTypeSelector.pnl",
								text,
								makeDynString(  "$text:" + text,
												"$selectMultiple:" + selectMultiple,
												"$disabledItems:" + disabledDpTypes,
												"$selectedItems:" + selectedDpTypes),
								df, ds);
//	DebugN(selectedDpTypes);
	selectedDpTypes = ds;
	return;
}


/**Converts a dyn_string to a string with the chosen separator.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param theDynString dyn_string to be converted
   @param theString result of the conversion
   @param separator separator used for splitting. The default value should be fwGeneral_DYN_STRING_DEFAULT_SEPARATOR,
                                but PVSS doesn't allow constants in default arguments
 */
void fwGeneral_dynStringToString(dyn_string theDynString, string &theString, string separator = fwGeneral_DYN_STRING_DEFAULT_SEPARATOR)
{
	if (dynlen(theDynString) < 1) {
		theString = "";
		return;
	}

//	DebugN("separator " + separator);
	theString = theDynString[1];
	for (int i = 2; i <= dynlen(theDynString); i++) theString = theString + separator + theDynString[i];
}


/** Extend a dynamic string to the specified length.
 * Initialise the newly added entries (strings) with the initial value given
   (null by default).
   If the initial length of the
   dynamic string is already longer than (or equal to) the requested length,
   then we leave the original dynamic string unchanged.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param ds the dynamic string to be modified
   @param length minimum length required for the dynamic string
   @param exceptionInfo returns details of any exceptions
   @param value value to be used to fill in the array
 */
void fwGeneral_fillDynString(dyn_string &ds, int length, dyn_string &exceptionInfo, string value = "")
{
	int dsLen = dynlen(ds);

	if (dsLen >= length) return;

	for (int i = dsLen + 1; i <= length; i++) ds[i] = value;
}

/** Returns a list with the dpes in a dp or a dp type. The method used is a workaround,
   because the function dpTypeGet doesn't return the dpes when there is a reference to
   another type.

   @par Constraints
        If a dp type is specified , at least one datapoint of the type has to exist

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param dp datapoint to get the elements from
   @param dpType dp type to get the elements from if no datapoint was specified (dp = "")
   @param dpElements returns the list of dp elements sorted into alphabetical order. NB Their name(s) begin with "." !
   @param dpElementTypes returns the list of types of corresponding to the list of dp elements
   @param exceptionInfo returns details of any exceptions
   @param excludedTypes excluded dp elements of these types from the list
   @param forceDpCreation if there are no dps of the specified type, it is possible to force the
                                                creation of a dummy dp to be able to get the structure
 */
void fwGeneral_getDpElements(string dp, string dpType, dyn_string &dpElements, dyn_string &dpElementTypes,
							 dyn_string &exceptionInfo, dyn_int excludedTypes = "", bool forceDpCreation = false)
{
	int i, dpeType;
	string systemName;
	dyn_string ds, localDpElements;

	dpElements = makeDynString();
	dpElementTypes = makeDynInt();

	// if no dp was specified, try to get one
	if (dp == "") {
		if (dpType != "") {
			ds = dpNames("*", dpType);
			if (dynlen(ds) > 0) {
				dp = ds[1];
			} else {
				if (forceDpCreation == true) {
					dpCreate("tmp_" + dpType, dpType);
					dp = "tmp_" + dpType;
				}
			}


			if (!dpExists(dp)) {
				fwException_raise(      exceptionInfo,
										"ERROR",
										"fwGeneral_getDpElements(): there are no dps of the specified type (" + dpType + ")",
										"");

				return;
			}
		} else {
			fwException_raise(      exceptionInfo,
									"ERROR",
									"fwGeneral_getDpElements(): specify either a dp or a dp type.",
									"");
			return;
		}
	} else {
		if (!dpExists(dp)) {
			fwException_raise(      exceptionInfo,
									"ERROR",
									"fwGeneral_getDpElements(): the specified dp does not exist (" + dp + ")",
									"");
			return;

		}
	}

	// Initialize variables
	dpElements = makeDynString();
	dpElementTypes = makeDynInt();

//	DebugN("fwGeneral_getDpElements() " + dpElements + " " + dpElementTypes);

	localDpElements = dpNames(dp + ".*;");
	dynSortAsc(localDpElements);

	// make sure that dp has the system name because the elements have it.
	fwGeneral_getSystemName(dp, systemName, exceptionInfo);
	if (systemName == "")
		dp = getSystemName() + dp;

	// remove dp name from elements, we are only interested in the element name
	// exclude dpe if type in list if excluded dpe types
	for (i = 1; i <= dynlen(localDpElements); i++) {
		dpeType = dpElementType(localDpElements[i]);
		if (dynContains(excludedTypes, dpeType) < 1) {
			dynAppend(dpElementTypes, dpeType);
			strreplace(localDpElements[i], dp, "");
			dynAppend(dpElements, localDpElements[i]);
		}
	}
//	DebugN("fwGeneral_getDpElements() " + dpElements + " " + dpElementTypes);
}





/** Returns the value of a global variable

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param globalVariable name of the global variable to get the value from
   @param value returns the value of the global variable
   @param exceptionInfo details of any exceptions
 */
void fwGeneral_getGlobalValue(string globalVariable, anytype &value, dyn_string &exceptionInfo)
{
	evalScript(     value,
					"anytype main() { return " + globalVariable + ";}",
					makeDynString());
}

/** Returns the system name extracted from the passed string

   The function parses the passed @c name parameter in search of
   the first colon (:) character, and returns the substring prior
   to it. Typical use case is to get the name of the system from
   the name of a datapoint.

   Contrary to builtin dpSubStr(), the function may be called for
   any string, not necessarily being the name of an existing datapoint.
   It is safe to use with UTF strings.

   See also @ref fwGeneral_getSystemName

   @public

   @param name string from which the system name is to be extracted;
   @param keepColon (optional) determines if returned system name
          should contain the colon character (default: no).
*/
string fwSysName(string name, bool keepColon=false)
{
	int colonPos=uniStrPos(name,":");
	if (keepColon) {
		return uniSubStr(name, 0, colonPos + 1);
	} else {
		return uniSubStr(name, 0, colonPos);
	}
}

/** Returns a string with system name removed

   The function parses the passed @c name parameter in search of
   the first colon (:) character, and returns the substring after it.
   Typical use case is to cut the system name part from the datapoint name.

   Contrary to builtin dpSubStr(), the function may be called for
   any string, not necessarily being the name of an existing datapoint,
   It is safe to use with UTF strings.

   See also @ref fwGeneral_getNameWithoutSN

   @public

   @param name string from which the system name is to be extracted;
*/
string fwNoSysName(string name)
{
	return uniSubStr(name, uniStrPos(name, ":") + 1);
}

/** Removes the system name from the passed name.

   See also @sa fwNoSysName

   @public

   @reviewed 2019-08-19

   @param name name to be processed
   @param nameWithoutSN on return will contant @c name with system name removed
   @param exceptionInfo not used (compatibility)
 */
void fwGeneral_getNameWithoutSN(string name, string &nameWithoutSN, dyn_string &exceptionInfo)
{
	nameWithoutSN = fwNoSysName(name);
}


/** Returns ipAddress and hostName where the PVSS system with
   name systemName is running.

   @par Constraints
        Local system not supported.
        The remote system has to be connected at the time the function is called.

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param systemName name of the system we are interested in
   @param ipAddress ip address of the machine where the PVSS system is running
   @param hostName host name of the machine where the PVSS system is running
   @param exceptionInfo returns details of any exceptions
 */
void fwGeneral_getSystemIpAddress(string systemName, string &ipAddress, string &hostName, dyn_string &exceptionInfo)
{
	int sysId, index;
	string sys;
	dyn_int distManNumbers;
	dyn_string hostNames;

	hostName = "";
	ipAddress = "";
	sys = getSystemName();

	// make sure that the system name always contains :
	systemName = strrtrim(systemName, ":") + ":";

	if (sys == systemName) {
		fwException_raise(      exceptionInfo,
								"ERROR",
								"fwGeneral_getSystemIpAddress: local system not supported for the moment",
								"");
	} else {
		sysId = getSystemId(systemName);

		dpGet(  "_DistConnections.Dist.ManNums", distManNumbers,
				"_DistConnections.Dist.HostNames", hostNames);
		//DebugN(distManNumbers, sysId);
		index = dynContains(distManNumbers, sysId);
		if (index > 0) {
			hostName =      hostNames[index];
			ipAddress = getHostByName(hostName);
		} else {
			fwException_raise(      exceptionInfo,
									"ERROR",
									"fwGeneral_getSystemIpAddress: could not retrieve host name and ip address for system " + systemName,
									"");
		}
	}
}


/** Gets the system name from the passed name.

   See also @sa fwSysName

   Note that this function returns the system name with the colon character at the end.
   Use the @ref fwSysName function with the @c keepColon=true parameter to get the name without.

   @public

   @reviewed 2019-08-19

   @param name name to be processed (e.g. "dist_1:CAEN/crate01/board03/channel005")
   @param systemName on return will contain system name extracted from the @c name parameter;
                     in example above it would yeild "dist_1:"
   @param exceptionInfo not used (compatibility)
 */
void fwGeneral_getSystemName(string name, string &systemName, dyn_string &exceptionInfo)
{
	systemName = fwSysName(name,true);
}


/** Checks the format of a provided date. Checks for following format: dd/mm/yyyy

   @par Constraints
   None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] sDate date at question
   @return Boolean value indicating result of check
 */
bool fwGeneral_hasCorrectDateFormat(string sDate)
{
	dyn_string dsSplitDate;
	bool bOk = TRUE;

	const string sRegexNumber = "[0123456789]";

	dsSplitDate = strsplit(sDate, "/");

	if (3 != dynlen(dsSplitDate)) {
		bOk = FALSE;
	} else {
		if ((!patternMatch(sRegexNumber + sRegexNumber + sRegexNumber + sRegexNumber, dsSplitDate[3]))          // Year is 4 digits
			|| (!patternMatch(sRegexNumber + sRegexNumber, dsSplitDate[2]))                                     // Month is two digits
			|| (!patternMatch(sRegexNumber + sRegexNumber, dsSplitDate[1]))) {                                  // Day is two digits

			bOk = FALSE;

		}
	}

	return bOk;
}


/** Checks the format of a provided date and time. Checks for following format: dd/mm/yyyy hh:mm:ss

   @par Constraints
   None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] sDateTime date and time at question
   @return Boolean value indicating result of check
 */
bool fwGeneral_hasCorrectFormat(string sDateTime)
{
	bool bDateOk = FALSE;
	bool bTimeOk = FALSE;
	dyn_string dsDateTimeSplit;

	dsDateTimeSplit = strsplit(sDateTime, " ");

	if (dynlen(dsDateTimeSplit) == 2) {
		bDateOk = fwGeneral_hasCorrectDateFormat(dsDateTimeSplit[1]);
		bTimeOk = fwGeneral_hasCorrectTimeFormat(dsDateTimeSplit[2]);
	}

	return bDateOk && bTimeOk;
}


/** Checks the format of a provided time. Checks for following format: hh:mm:ss

   @par Constraints
   None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] sTime time at question
   @return Boolean value indicating result of check
 */
bool fwGeneral_hasCorrectTimeFormat(string sTime)
{
	dyn_string dsSplitTime;
	bool bOk = TRUE;

	const string sRegexNumber = "[0123456789]";

	dsSplitTime = strsplit(sTime, ":");

	if (3 != dynlen(dsSplitTime)) {
		bOk = FALSE;
	} else {
		// Hour minute and second are 2 digits
		if ((!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[1]))
			|| (!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[2]))
			|| (!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[3]))) {

			bOk = FALSE;
		}
	}

	return bOk;
}

/** Returns whether the dpe type is dyn or not

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param type integer number for dpe type
   @param isDyn whether the dpetype is dyn or not
   @param exceptionInfo details of any exceptions
 */
void fwGeneral_isDpeTypeDyn(int type, bool &isDyn, dyn_string &exceptionInfo)
{
	if (dynContains(g_fwGeneral_dynDpeTypes, type) > 0) {
		isDyn = TRUE;
	} else {
		isDyn = FALSE;
	}
}


/** Opens the details panel for a given datapoint element

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION

   @param dpe datapoint element to get the details from
   @param exceptionInfo details of any exceptions
 */
void fwGeneral_openDetailsPanel(string dpe, dyn_string &exceptionInfo)
{
	bit32 status;

	dpGet(dpe + ":_original.._status", status);

	ChildPanelOnCentralModal("fwGeneral/fwDetailDpElement.pnl", "Details", makeDynString("$1:" + dpe, "$2:" + status));


/*	if(!isModuleOpen("Detail"))
        {
                ModuleOnWithPanel(	"Detail", -1, -1, 0, 0, 1, 1, "",
                                                        "para/originalHelp.pnl", "Detail",
                                                        makeDynString("$1:" + dpe, "$2:" + status));
        }
        else
        {
                RootPanelOnModule(	"para/originalHelp.pnl", " ", "Detail",
                                                        makeDynString("$1:" + dpe, "$2:" + status));
        }*/
}


/** Opens a message panel with the specified message. If it is used as a
   dialog (onlyInfo = FALSE) it will return whether the user pressed Ok or not.
   If it is used as information panel it will just display the panel and wait
   for the user to press Ok.

   @par Constraints
        None

   @par Usage
        Public

   PVSS manager usage
        VISION

   @param message the message to be presented in the panel
   @param ok returns TRUE if the user pressed the Ok button, FALSE otherwise
   @param exceptionInfo details of any exceptions
   @param panelBarTitle title for the panel <b>WARNING</b>: deprecated from PVSS 3.6 and higher
   @param onlyInfo whether the panel is just for information, or it will also ask for user input
 */
void fwGeneral_openMessagePanel(string message, bool &ok, dyn_string &exceptionInfo, string panelBarTitle = "", bool onlyInfo = FALSE)
{
	dyn_float df;
	dyn_string ds;

	string panelName = panelBarTitle;

	if (panelName == "") panelName = myPanelName() + cryptoHash((string)rand());

	if (onlyInfo) {
		ChildPanelOnCentralModalReturn("vision/MessageInfo1", panelName,
									   makeDynString(message),
									   df, ds);
	} else {
		ChildPanelOnCentralModalReturn("vision/MessageInfo", panelName,
									   makeDynString(  message,
													   "Ok",
													   "Cancel"),
									   df, ds);

		if ( (dynlen(df) >= 1) && df[1] > 0) {
			ok = TRUE;
		} else {
			ok = FALSE;
		}
	}
}


/** Opens a panel to select one or several of the items in a list

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param list list of strings to select from
   @param selection returns the selected items
   @param exceptionInfo details of any exceptions
   @param multipleSelection whether it is possible to select more than one item or not
   @param title title of the pop-up window with the dialog box
 */
void fwGeneral_selectFromList(  dyn_string list, dyn_string &selection, dyn_string &exceptionInfo,
								bool multipleSelection = false, string title = "Select fromt the list")
{
	dyn_float df;
	dyn_string ds;

//	fwGeneral_stringToDynString();
	ChildPanelOnCentralModalReturn( "fwGeneral/fwGeneralEditDynString.pnl",
									title,
									makeDynString(  "$sTitle:" + title,
													"$dsValues:" + list,
													"$bMultipleSelection:" + multipleSelection),
									df,
									selection);
}


/** Sets the value of a global variable

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param globalVariable name of the global variable to set the value to
   @param value the value to be set to the global variable
   @param exceptionInfo details of any exceptions
 */
void fwGeneral_setGlobalValue(string globalVariable, anytype value, dyn_string &exceptionInfo)
{
	int val;

	evalScript(     val, "int main(anytype objectValue) {" + globalVariable + " = objectValue; return 0;}",
					makeDynString(), value);
}

/** Converts a string to a dyn_string with the chosen separator.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param theString string to be split
   @param theDynString result of splitting
   @param separator     separator used for splitting. The default value should be fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, but
                                        PVSS doesn't allow constants in default arguments
   @param removeSpaces whether to remove spaces in the string before parsing it or not
   @param compatibilityMode     useful to parse strings that are the result of the automatic conversion by PVSS of
                                                        a dyn_string to a string. In this case, the parts are separated by " | " (space-tube-space).
                                                        If you want to get the original dyn_string, set this parameter to TRUE.
 */
void fwGeneral_stringToDynString(string theString, dyn_string &theDynString, string separator = "|", bool removeSpaces = true, bool compatibilityMode = false)
{
//	DebugN(separator, removeSpaces, compatibilityMode, fwGeneral_DYN_STRING_DEFAULT_SEPARATOR);
	if (compatibilityMode) strreplace(theString, " " + separator + " ", separator);

	if (removeSpaces) strreplace(theString, " ", "");
	theDynString = strsplit(theString, separator);

	// Add empty element in the end if the original
	// string ended in the separator character
	if (strlen(strrtrim(theString, separator)) != strlen(theString)) {

		theDynString[dynlen(theDynString) + 1] = "";
	}
}


/** Converts previously checked time string into time value.

   @par Constraints
        None

   @par Usage
        Public

   @par WinCC managers
        VISION, CTRL

   @param[in] sDateTime date and time to be checked

   @return Time value of string including milliseconds (1970.01.01 00:00:00 in case of bad format)
 */
time fwGeneral_stringToDate(string sDateTime)
{
	dyn_string dsDateTimeSplit, dsDateSplit;
	string sDate;
	time tDateTime = makeTime(1970, 1, 1, 0, 0, 0);

	// Split in two parts: date and time
	dsDateTimeSplit = strsplit(sDateTime, " ");

	if (dynlen(dsDateTimeSplit) == 2) {
		sDate = dsDateTimeSplit[1];
		dsDateSplit = strsplit(sDate, "/");

		if (dynlen(dsDateSplit) == 3) {
			// Create correct time format for calendar widget
			sDateTime = dsDateSplit[3] + "." + dsDateSplit[2] + "." + dsDateSplit[1] + " " + dsDateTimeSplit[2] + ".000";
			tDateTime = sDateTime;
		}
	}

	return tDateTime;
}


/** Gets an ISO-8859-1 encoded text file and returns the path of a new text file in UTF-8 encoding.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param fnameToRecode filename+path which needs to be encoded
   @param[out] exceptionInfo standard exception handling variable
   @return string path+filename of the encoded file.
 */

string fwGeneral_recodeFile(string fnameToRecode, dyn_string &exceptionInfo)
{
	string tmpfname, file2Str, encFileStr;
	int err;

	tmpfname = tmpnam();
	if (_UNIX) {
		err = system("iconv -f ISO-8859-1 -t UTF-8 \"" + fnameToRecode + "\" > " + tmpfname);
		if (err != 0) {
			fwException_raise(exceptionInfo,
							  "ERROR",
							  "Error, iconv exit code:" + err + ", command in system(iconv -f ISO-8859-1 -t UTF-8 \""
							  + fnameToRecode + "\" > " + tmpfname + ")",
							  "");
		}
	} else {
		fileToString(fnameToRecode, file2Str);
		encFileStr = recodeFileName(file2Str);
		file f;
		f = fopen(tmpfname, "w");
		err = ferror(f);         // export error if exists
		if (err != 0) {
			fwException_raise(       exceptionInfo,
									 "ERROR",
									 "fwGeneral_recodeFile() Error No:" + err + " occurred in fopen(" + tmpfname + ",w)",
									 "");
		}
		fputs(encFileStr, f);
		fclose(f);
	}
	return tmpfname;
}

/** Gets status of QueryRDBdirect (on, off)

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[out] queryRDBdirectEnabled	returns the value of  queryRDBdirect true=on false=off
 */
void fwGeneral_getQueryRDBdirectEnabled(bool &queryRDBdirectEnabled)
{
	queryRDBdirectEnabled = useQueryRDBDirect();

}

/** Gets status of Parallel archiving (RDB installed + parallel on-off)

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[out] rdbinstalled				returns true if RDB is installed
   @param[out] parallelArchivingEnabled	returns true if parallel archiving is enabled
 */
void fwGeneral_getParallelArchivingEnabled(bool &rdbinstalled,
										   bool &parallelArchivingEnabled)
{
	parallelArchivingEnabled = false;

	rdbinstalled =  useRDBArchive();

	int iRet, iLen;

	dyn_string dsDpValArchState =   dpNames("_ValueArchive_*.state", "_ValueArchive");
	dyn_string dsDpValArchFwd2Rdb = dpNames("_ValueArchive_*.general.forwardToRDB", "_ValueArchive");
	dyn_int diValArchState;
	dyn_bool dbValArchFwd2Rdb;
	if (dynlen(dsDpValArchState) > 0) {
		dpGet(dsDpValArchState, diValArchState);
		dpGet(dsDpValArchFwd2Rdb, dbValArchFwd2Rdb);
		iLen = dynlen(dsDpValArchState);
		for (int i = 1; i <= iLen; i++) {
			if (diValArchState[i] == 1 && dbValArchFwd2Rdb [i] == true) {
				parallelArchivingEnabled = true;
				break;
			}
		}
	}
}

/** set the status of QueryRDBdirect (on, off)

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param queryRDBdirectEnabled	sets the queryRDBdirect true=on false=off
 */
void fwGeneral_setQueryRDBdirectEnabled(bool queryRDBdirectEnabled)
{
	setQueryRDBDirect(queryRDBdirectEnabled);
}

/** Returns file extension of given file.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param filePath	Path to a file, may be absoulte or relative. File name is accepted also
   @return string  File extension, empty string if file doesn't have extension
 */
string fwGeneral_getFileExtension(string filePath)
{
	return getExt(filePath);
}


/** Returns file path without file extension.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] filePath  Path to a file, may be absoulte or relative. File name is accepted also
   @return string  File path without file extension, if file doesn't have extension then returned string is same as input parameter
 */
string fwGeneral_removeFileExtension(string filePath)
{
	string fileExtension = fwGeneral_getFileExtension(filePath);

	return (fileExtension == "") ? filePath : substr(filePath, 0, strpos(filePath, fileExtension) - 1);
}


/** Sets in configuration datapoint if internal browser should be used to open help files.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] useInternalBrowser	Flag indicating if internal browser should be used to open help files.
   @param[out] exceptionInfo		Standard exception handling variable
 */
void fwGeneral_setHelpUseInternalBrowser(bool useInternalBrowser, dyn_string &exceptionInfo)
{
	if (dpSet(FW_GENERAL_HELP_USE_INTERNAL_BROWSER_DPE, useInternalBrowser) != 0) {
		fwException_raise(exceptionInfo, "ERROR", "Failed to set in dp which browser (internal/external) " +
						  "should be used to open help files.", "");
	}
}

/** Retrieves from configuration datapoint if internal built-in browser should be used to open help files.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[out] useInternalBrowser	Flag indicating if internal browser should be used to open help files.
   @param[out] exceptionInfo		standard exception handling variable
 */
void fwGeneral_getHelpUseInternalBrowser(bool &useInternalBrowser, dyn_string &exceptionInfo)
{
	if (dpGet(FW_GENERAL_HELP_USE_INTERNAL_BROWSER_DPE, useInternalBrowser) != 0) {
		fwException_raise(exceptionInfo, "WARNING", "Failed to retrieve information if internal browser should be used." +
						  " Default option will be used", "");
		useInternalBrowser = FW_GENERAL_DEFAULT_HELP_USE_INTERNAL_BROWSER;
	}
}

/** Sets in configuration datapoint commands used to open external browser on Linux and Windows.
   @note Command should contain "$1" keyword that will be replaced by the URL to open.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] browserCmdLin		Command to open external browser on Linux operating systems.
   @param[in] browserCmdWin		Command to open external browser on Windows operating systems.
   @param[out] exceptionInfo	Details of any exceptions
 */
int fwGeneral_setHelpExtBrowserCommand(string browserCmdLin, string browserCmdWin, dyn_string &exceptionInfo)
{
	if (dpSet(FW_GENERAL_HELP_BROWSER_CMD_LIN_DPE, browserCmdLin,
			  FW_GENERAL_HELP_BROWSER_CMD_WIN_DPE, browserCmdWin) != 0) {

		fwException_raise(exceptionInfo, "ERROR", "Failed to set in dp commands to open external browser.", "");
	}
}

/** Retrieves from configuration datapoint commands used to open external browser on Linux and Windows.

   @par Constraints
        None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[out] browserCmdLin	Command to open external browser on Linux operating systems.
   @param[out] browserCmdWin	Command to open external browser on Windows operating systems.
   @param[out] exceptionInfo	standard exception handling variable
 */
int fwGeneral_getHelpExtBrowserCommand(string &browserCmdLin, string &browserCmdWin, dyn_string &exceptionInfo)
{
	if (dpGet(FW_GENERAL_HELP_BROWSER_CMD_LIN_DPE, browserCmdLin,
			  FW_GENERAL_HELP_BROWSER_CMD_WIN_DPE, browserCmdWin) != 0) {
		fwException_raise(exceptionInfo, "WARNING", "Failed to retrieve command to open external browser." +
						  " Default command will be used", "");
		browserCmdLin = FW_GENERAL_DEFAULT_HELP_EXT_BROWSER_COMMAND_LIN;
		browserCmdWin = FW_GENERAL_DEFAULT_HELP_EXT_BROWSER_COMMAND_WIN;
	}
}


/** @internal @private
	Opens given help file in defined help file's browser.

   @par Constraints
        None

   @par Usage
        Private

   @par PVSS managers
        VISION, CTRL

   @param[in] helpFilePath string		Path to the help file.
   @param[out] exceptionInfo			standard exception handling variable
   @param[in] label						The label of the tab in fwViewer.
   @param[in] windowName				The name of the window in fwViewer (groups tabs together)
 */
private void fwGeneral_openHelpFile(string helpFilePath, dyn_string &exceptionInfo, string label="", string windowName="fwGeneralHelp")
{
	strreplace(helpFilePath, "\\", "/");
	if(patternMatch("//*", helpFilePath)){ // Detect UNC path
		helpFilePath = substr(helpFilePath, 1); // Remove first slash, otherwise help file URL is not recognized in internal browser
	}
	string helpFileUrl = (strpos(helpFilePath, FW_GENERAL_FILE_URI_SCHEME) == 0) ?
						 helpFilePath : (FW_GENERAL_FILE_URI_SCHEME + helpFilePath);

	bool useInternalBrowser;
	fwGeneral_getHelpUseInternalBrowser(useInternalBrowser, exceptionInfo);

	if (useInternalBrowser) {
		fwWebBrowser_showStandaloneWindow(helpFileUrl, exceptionInfo, label, windowName);
	} else {
		fwGeneral_openInExternalBrowser(helpFileUrl, exceptionInfo);
	}
}

/** Opens given URL in external browser.

   @par Constraints
   None

   @par Usage
        Public

   @par PVSS managers
        VISION, CTRL

   @param[in] url				Address to open in external browser
   @param[out] exceptionInfo	standard exception handling variable
 */
void fwGeneral_openInExternalBrowser(string url, dyn_string &exceptionInfo)
{
	string browserCmdLin, browserCmdWin;

	fwGeneral_getHelpExtBrowserCommand(browserCmdLin, browserCmdWin, exceptionInfo);

	string browserCmd = _WIN32 ? browserCmdWin : browserCmdLin;
	if (browserCmd == "") {
		fwException_raise(exceptionInfo, "WARNING", "Opening help files is blocked in this system as command " +
						  "to run external browser is not specified. Open 'System settings' panel to set new command", "");
		return;
	}

	if (strreplace(browserCmd, "$1", url) == 0) {
		// $1 was not replaced by url (assume that $1 not present in browserCmd)
		// In such case add help file url at the end of the browserCmd
		browserCmd += " " + url;
	}

	systemDetached(browserCmd);
}


/** Opens help of a given panel file.


    For backward-compatibility, firstly the HTML file is attempted, and if the HTML help file is not present
    then the Qt-Assistant is called to open the QtHelp.

   @param[in] panelFilePath    Relative path to a panel file (from panels/ directory)
   @param[out] exceptionInfo    standard exception handling variable
 */
void fwGeneral_openHelpForPanel(string panelFilePath, dyn_string &exceptionInfo)
{
    // Get component name from component path. We assume panels are inside a directory
    // named after the component name
    strreplace(panelFilePath, "\\", "/");
    dyn_string panelFilePathDirs = strsplit(panelFilePath, "/");
    if (dynlen(panelFilePathDirs) < 1 || panelFilePathDirs[1] == "") {
        fwException_raise(exceptionInfo, "ERROR", "Could not find the component name of " +
                          "the current panel file: " + panelFilePath, "");
        return;
    }
    string componentName = panelFilePathDirs[1];

    // Remove panel file extension if given
    string panelFilePathWithoutExt = fwGeneral_removeFileExtension(panelFilePath);

    string helpFilePathWithoutExt = componentName + "/panels/" + panelFilePathWithoutExt;
    string helpFilePath;
    int helpFileExtensionsLen = dynlen(FW_GENERAL_HELP_FILE_EXTENSIONS);
    for (int i = 1; (i <= helpFileExtensionsLen && helpFilePath == ""); i++) {
        // Get path to a help file with a file extension
        helpFilePath = getPath(HELP_REL_PATH, helpFilePathWithoutExt + FW_GENERAL_HELP_FILE_EXTENSIONS[i]);
    }
    if (helpFilePath != "") {
        fwGeneral_openHelpFile(helpFilePath, exceptionInfo);
    } else {
        fwGeneral_openQtHelp(componentName,exceptionInfo, panelFilePathWithoutExt+"_8pnl.html"); // doxygen does it this way...
   }
}
/** Open Qt Help for a particular component name and particular help path


    The help needs to be placed either in the "help/en_US.utf8/<fwComponentName>/<fwPanelNameWithoutExt>.htm"
    or in the component's QT Documentation with URL such as
    "qthelp://ch.cern.jcop.fwcomponentname/fwComponentName/fwPanelNameWithoutExt_8pnl.html"
   or
    "qthelp://ch.cern.unicos.uncomponentname/unComponentName/unPanelNameWithoutExt_8pnl.html"
    for instance
    "qthelp://ch.cern.jcop.fwdeviceeditornavigator/fwDeviceEditorNavigator/fwDeviceEditorNavigator_8pnl.html"

    @param componentName[in] the name of the component
    @paran exceptionInfo[out] standard exception-handling variable
    @param helpPath[in] specifies which file of the help to open; if not specified it will open
        the index.html (ie. the main component help page);
  */
void fwGeneral_openQtHelp(string componentName, dyn_string &exceptionInfo, string helpPath="")
{
    // check if we have the QtHelp for this panel/component...
    string componentDp = fwInstallation_getComponentDp(componentName);
    if (!dpExists(componentDp)) {
        fwException_raise(exceptionInfo, "ERROR", "Component " + componentName + " is not installed, cannot open help for it", "");
        return;
    }
    dyn_string qtHelpFiles;
    dpGet(componentDp + ".qtHelpFiles", qtHelpFiles);
    if (qtHelpFiles.isEmpty()) {
        fwException_raise(exceptionInfo, "ERROR", "Component " + componentName + " has no QtHelp files - cannot open help for it", "");
        return;
    }

    string frameworkName="jcop"; // by default....
    if (componentName.startsWith("un")) frameworkName="unicos";
    // treat exceptions...
    if (componentName=="fwDeviceComment") frameworkName="unicos";
    if (componentName=="unDistributedControl") frameworkName="jcop";

    if (helpPath=="") helpPath=componentName+"/index.html";

    string qtHelpUrl = "qthelp://ch.cern." + frameworkName +
                       "." + strtolower(componentName) +
                       "/" + helpPath;

    DebugTN(__FUNCTION__,"Invoking QtHelp for "+helpPath + " using URL", qtHelpUrl);
    //DebugTN("assistant -collectionFile "+getPath(DATA_REL_PATH,"help.qhc") +" -showUrl "+qtHelpUrl);
    string out, err;
    int rc = system("assistant -quiet -collectionFile "+getPath(DATA_REL_PATH, "help.qhc") +" -showUrl "+qtHelpUrl, out, err);
    if (rc) {
        fwException_raise(exceptionInfo, "ERROR", "Error while opening Qt help for component " + componentName + " : "+err+";"+out, "");
        return;
    }
}

/** Opens help file of a given component.

   @param[in] componentName     Name of a component, note that underscore should be removed from the beggining of a subcomponent name
                                   if necessary, before passing it to the function.
   @param[out] exceptionInfo    standard exception handling variable
 */
void fwGeneral_openHelpForComponent(string componentName, dyn_string &exceptionInfo)
{
    string componentDp = fwInstallation_getComponentDp(componentName);

    if (!dpExists(componentDp)) {
        fwException_raise(exceptionInfo, "ERROR", "Component " + componentName + " is not installed, cannot open help", "");
        return;
    }
    // Retrieve help file relative path from component installation datapoint
    string helpFile;
    dyn_string qtHelpFiles;
    dpGet(componentDp + ".helpFile", helpFile,
          componentDp + ".qtHelpFiles", qtHelpFiles);
    //DebugTN(__FUNCTION__, componentName,helpFile,qtHelpFiles);

    if (!qtHelpFiles.isEmpty()) {
      fwGeneral_openQtHelp(componentName,exceptionInfo);
      return;
    }
    string helpFilePath = getPath(HELP_REL_PATH, helpFile);
    if (helpFile == "" || helpFilePath == "") {
        fwException_raise(exceptionInfo, "ERROR", "Help file for component " + componentName +
                          " is not defined or doesn't exist", "");
        return;
    }
    fwGeneral_openHelpFile(helpFilePath, exceptionInfo, "Help for component " + componentName, "componentHelp");
}

// internal list of deprecated function calls;
// content is synced through a dpQueryConnect
private global dyn_string g_fwDeprecatedFunctions;

// max number of deprecated calls logged
// if you change it here, change also the alert threshold
// of fwDeprecated.count in the fwGeneral.dpl file!
const int _fwGeneral_maxDeprecatedLogEntries = 100;

// flag that we already printed the warning about too many
// deprecated function calls were recorded
private global bool _fwGeneral_maxDeprecatedWarningPrinted = false;

// flag that checks the initalization was done
private global bool _fwDeprecated_CBInitialized = false;

// the name of the DPE holding the list of deprecated calls
global const string _fwDeprecated_DPE = "fwDeprecated.deprecatedList";

/** Marks a function or a panel as deprecated (reports and records the incident)
 *
 */
void FWDEPRECATED()
{

	// check/setup callback to sync the content from the DP;
	// note that first sync in this manager will only happen at the first call to FWDEPRECATED(),
	// and not at the startup of manager; it is sufficient.
	synchronized(_fwDeprecated_CBInitialized) {
		if (!_fwDeprecated_CBInitialized) {
			dpQueryConnectSingle("_fwGeneral_fwDeprecatedDPCB", true, "", "SELECT '_original.._value' FROM '" + _fwDeprecated_DPE + "'", 500);
			_fwDeprecated_CBInitialized = true;
		}
	}

	dyn_string stkTrace = getStackTrace();
	// get the stack frame of the deprecated function and its parent
	string thisFrame  = "UNKNOWN";
	string calledFrom = "UNKNOWN";
	string rootCause = "";
	int stkTraceDynlen = dynlen(stkTrace);
	if (stkTraceDynlen >= 2) thisFrame  = stkTrace[2];
	if (stkTraceDynlen >= 3) calledFrom = stkTrace[3];
	if (stkTraceDynlen >= 4) rootCause =  stkTrace[stkTraceDynlen];
	string deprecatedObject;

	strreplace(thisFrame, "\n", "");        // eliminate line-end chars to ease parsing
	strreplace(thisFrame, "\"", "");        // eliminate additional string-escaping


	// check if it comes from the Init script of a panel
	// we may have two cases to distinguish
	// (1)   "void main() at [Module: _QuickTest_ Panel: TestWithRefs.pnl    In reference: TestFwDeprecated.pnl Group: 0 named: \"PANEL_REF0\" Script: Initialize]:4";
	// (2)   "void main() at [Module: _QuickTest_ Panel: TestRefDeprecatedButton.pnl Script: Initialize]:3";
	//
	// both of them could be served by the following regexp,
	// which needs the special escaping for the "[" => \0133 and "]" => \0135 and "(" => \( and ")" => \)
	// we use (\S+) to capture a string of non-empty characters and (\s*) to match whitespaces
	// for the lattter we use it in a non-capture mode (?:\s*)
	//
	// at return from regexp we should have 9 elements in array, first being the complete string, then all the captured params in order

	string rexpPanel = "void main\\(\\) at \\0133Module: (\\S+)(?:\\s*)Panel: (\\S+)(?:\\s*)(In reference: (\\S+)(?:\\s*) Group: (\\S+)(?:\\s*) named: (\\S+)(?:\\s*))?Script: (\\S+)(?:\\s*)\\0135:(.*)";

	dyn_string result;
	int rc = regexpSplit(rexpPanel, thisFrame, result);

	if ( rc == 0) {
		// it is running in a panel

		if (dynlen(result) == 9) {
			if (result[5] != "") {
				// case 1: reference panel embedded somewhere
				deprecatedObject = result[5];
				calledFrom = result[3] + " REF " + result[7];
				int x, y;                                           // where to pop up a "Deprecated" label
				getValue(this, "position", x, y);                   // this works for ref panels
				startThread("_fwGeneral_displayDeprecatedLabel", x, y);;
			} else {
				// panel opened directly
				deprecatedObject = result[3];
				calledFrom = myPanelName();

				// TO ENHANCE: Use the information from the _Ui DPE to find the parent panel.

				startThread("_fwGeneral_displayDeprecatedLabel");
			}
			_fwGeneral_logDeprecated(deprecatedObject, calledFrom);
		} else {
			// DebugTN("ERROR PARSING THE STACK TRACE FROM PANEL!",rc,rexpPanel, thisFrame, result);
			_fwGeneral_logDeprecated(thisFrame, calledFrom);
		}
	} else {
		// it is a function call

		// let us try to parse the calledFrom in search of a string such as
		//  void main() at [Module: _QuickTest_ Panel: TestDeprecated.pnl    In reference: objects/TestDeprecatedObject2.pnl Group: 991 named: "R10SQUARE42" Script: Initialize]:3
		// to eliminate the Group/named/Script... ; note that regexp is similar to the one above, yet without "optional" match of the whole "In reference..." clause
		dynClear(result);
		string rexpCaller = "void main\\(\\) at \\0133Module: (\\S+)(?:\\s*)Panel: (\\S+)(?:\\s*)\\s+In reference: (\\S+)(?:\\s*) Group: (\\S+)(?:\\s*) named: (\\S+)(?:\\s*)?Script: (\\S+)(?:\\s*)\\0135:(.*)";
		rc = regexpSplit(rexpCaller, calledFrom, result);
		if (dynlen(result) >= 4) {
			calledFrom = result[3] + " REF " + result[4];
		} else {
			string rexp = "([^\\(]*)?(?:\\(.*\\))( at .*)";
			rc = regexpSplit(rexp, calledFrom, result);
			calledFrom = result[2] + "(...)" + result[3];
		}

		if (rootCause != "") {
			dynClear(result);
			string rexp = "([^\\(]*)?(?:\\(.*\\))( at .*)";
			rc = regexpSplit(rexp, rootCause, result);
			rootCause = result[2] + "(...)" + result[3];
		}

		//FunctionName("parameters") at [Module: _QuickTest_ Panel: FolderName/FileName.pnl ScopeLib: FileName.pnl]:16
		//depracatedObject = FunctionName(...) at [Module: _QuickTest_ Panel: FolderName/FileName.pnl ScopeLib: FileName.pnl]:16
		//
		// yet it could also be a deprecated lib function that is called in a ref panel; then the stack frame is like
		// FunctionName(parameterts) at DeprecatedLib.ctl:3
		//
		//Ignore the function parameters so that the "deprecatedObject" which is part of the hashKey
		//remains unique even when called with different parameters from the same place

		// first variant: the panel
		string rexp = "([^\\(]*)?(?:\\(.*\\))( at \\0133Module:.*)";
		rc = regexpSplit(rexp, thisFrame, result);
		if (dynlen(result) == 3) {
			deprecatedObject = result[2] + "(...)" + result[3];
			_fwGeneral_logDeprecated(deprecatedObject, calledFrom, rootCause);
			return;
		}

		// second variant: call to deprecated lib
		rexp = "([^\\(]*)?(?:\\(.*\\))( at .*)";
		rc = regexpSplit(rexp, thisFrame, result);
		if (dynlen(result) == 3) {
			deprecatedObject = result[2] + "(...)" + result[3];
			_fwGeneral_logDeprecated(deprecatedObject, calledFrom, rootCause);
			return;
		}

		// otherwise: could not parse: last resort is to pass the complete frame...
		//DebugTN(__FUNCTION__,"ERROR PARSING THE STACK TRACE FROM PANEL!",rc,rexp, thisFrame, result);
		_fwGeneral_logDeprecated(thisFrame, calledFrom, rootCause);
	}
}

/** @internal @private

 */
void _fwGeneral_fwDeprecatedDPCB(anytype userData, dyn_dyn_anytype result)
{

	int len = dynlen(result);

	if (len < 2) return;                    // skip empty CBs
	dyn_string values = result[len][2];     // get the last one at [len] idx: most recent/complete!

	// we simply accept as a new set of deprecated objects
	// no need to merge, because it is done already in the _fwGeneral_logDeprecated,
	// which will trigger this callback anyway!

	synchronized(g_fwDeprecatedFunctions) {
		g_fwDeprecatedFunctions = values;
	}
}

/** @internal @private used internally by the fwGeneral/fwDeprecatedList.pnl
	Clears the log of deprecated function calls
 */
void _fwGeneral_fwDeprecatedClear()
{
	synchronized(g_fwDeprecatedFunctions) {
		dynClear(g_fwDeprecatedFunctions);
		dpSetWait(_fwDeprecated_DPE, g_fwDeprecatedFunctions);
	}
}

/** @internal @private
 */
private void _fwGeneral_logDeprecated(string functionName, string calledFrom, string rootCause = "")
{
	string key = functionName + " # " + calledFrom;

	if (rootCause != "") key = key + " , CALL ORIGIN : " + rootCause;

	if (dynContains(g_fwDeprecatedFunctions, key)) return;     // fast-path, without locking anything yet...

	// handle the overflow case
	if (dynlen(g_fwDeprecatedFunctions) >= _fwGeneral_maxDeprecatedLogEntries) {
		synchronized(_fwGeneral_maxDeprecatedWarningPrinted) {
			if (!_fwGeneral_maxDeprecatedWarningPrinted) {
				_fwGeneral_maxDeprecatedWarningPrinted = true;

				// 1) throw the original error to the log this time,
				//    without recording it in DP anymore
				errClass err = makeError("fwGeneral", PRIO_WARNING, ERR_IMPL, 99999, functionName, "called from", calledFrom);
				throwError(err);
				// 2) throw a overflow warning to the log
				errClass err = makeError("fwGeneral", PRIO_SEVERE, ERR_IMPL, 99998, "Deprecated function calls will not be logged/reported anymore until reset");
				throwError(err);
			}
		}
		return;         // we are not going to record it in DP anymore...
	}

	synchronized(g_fwDeprecatedFunctions) {

		if (dynContains(g_fwDeprecatedFunctions, key)) return;         // check once again, in synchronized section

		dynAppend(g_fwDeprecatedFunctions, key);

		// throw deprecation info to the log already now:
		errClass err = makeError("fwGeneral", PRIO_WARNING, ERR_IMPL, 99999, functionName, "called from", calledFrom);
		throwError(err);

		// record the deprecated call; this requires DPE locking, etc
		dyn_string exceptionInfo;
		int lockOK = fwDPELock_tryLock(_fwDeprecated_DPE, exceptionInfo);
		if (dynlen(exceptionInfo) || !lockOK) {
			DebugTN(__FUNCTION__, "Could not lock " + _fwDeprecated_DPE, "Deprecation of function may be lost", exceptionInfo);
			DebugTN(key);
			return;
		}
		dyn_string deprFuncs;
		dpGet(_fwDeprecated_DPE, deprFuncs);
		dynAppend(g_fwDeprecatedFunctions, deprFuncs);
		dynUnique(g_fwDeprecatedFunctions);
		dynSortAsc(g_fwDeprecatedFunctions);
		dpSetWait(_fwDeprecated_DPE, g_fwDeprecatedFunctions);
		fwDPELock_unlock(_fwDeprecated_DPE, exceptionInfo);
		if (dynlen(exceptionInfo)) {
			DebugTN(__FUNCTION__, "Could not unlock " + _fwDeprecated_DPE, exceptionInfo);
			return;
		}
	}     // end of synchronized section
}

/** @internal @private
	Displays flashing "Deprecated" label at a certain position for a couple of seconds
 *
 *
 * The function is to be used through startThread() so that it does not block
 * critical setion that may need to be locked.
 *
 * The x and y param make particular sense for reference panels; they need to be
 * passed from the parent object, otherwise it would not work...
 *
 */
private void _fwGeneral_displayDeprecatedLabel(int x = 0, int y = 0)
{
	// construct the name of symbol
	string deprSmblName = "DEPRECATED_LABEL_" + tmpnam();

	strreplace(deprSmblName, "/", "_");

	// show it for a few seconds
	addSymbol(myModuleName(), myPanelName(), "objects/fwGeneral/fwDeprecatedIndicator.pnl", deprSmblName, makeDynString(), x, y);
	delay(3, 0);
	removeSymbol(myModuleName(), myPanelName(), deprSmblName);
}

/** Load a CTRL library at runtime
 *
 *  Dynamically loads a CTRL library into the running UI or CTRL Manager. Allows for conditional loading
 *   of functionality (ie. if library exists). As it uses the startScript(), it could be automatically
 *   executed on the library loading (see example below)
 *
 * @par libRelPath    : the path and file name of the library relative to the scripts/libs
 * @par excOnNotFound : (optional) if set to true, the function will raise an exception if the library
 *                      is not found
 * @par useBeyondInit  : (optional) if set to true, the function may be called not only from the
 *                      lib global initialization, but from any other place; see the warning below.
 *
 * @return true if library was loaded succesfully
 *
 * @throws if excOnNotFound set to true, exception raised if library was not found
 * @throws if problem occurs with the library while loading
 * @throws if called not from the lib global initialization without setting the useBeyondInit param
 *
 * @warning Due to current limitations in WinCC OA (ETM-1752, ETM-1753 issues), calling this
 *          function from another function, and not from the library global init script
 *          (ie. as in example below) may result in lib-scope variables not being visible,
 *          and possibly other side effects. The optional param useBeyondInit should be set
 *          to true to force the attempt anyway (and avoid the exception)
 *
 * @remark If debug flag "fwGeneral_loadCtrlLib" is set, then information is printed to the log
 *         for every library load.
 *
 * Example: library A.ctl that conditionally loads B.ctl if it exists
 * @code{A.ctl}
 *    private const bool Alib_init = fwGeneral_loadCtrlLib("B.ctl",false);
 * @endcode
 */
bool fwGeneral_loadCtrlLib(string libRelPath, bool excOnNotFound = true, bool useBeyondInit = false)
{
	if (isDbgFlag("fwGeneral_loadCtrlLib"))
		throwError(makeError("", PRIO_INFO, ERR_CONTROL, 0, __FUNCTION__ + "(" + libRelPath + "," + excOnNotFound + "," + useBeyondInit + ")"));

	dyn_string stk = getStackTrace();
	if (dynlen(stk) < 2) {
		DebugTN("fwGeneral_loadCtrlLib: invalid stack trace", stk);
		throw(makeError("", PRIO_SEVERE, ERR_CONTROL, 0, "fwGeneral_loadCtrlLib: invalid stack trace (see log); could not load the library " + libRelPath));
	}
	string caller = stk[dynlen(stk)];

	if (!useBeyondInit) {
		// make sure it is called from the init manager global, and not directly

		if (strpos(caller, "init manager global") < 0) {
			throw(makeError("", PRIO_SEVERE, ERR_CONTROL, 0,
			                "fwGeneral_loadCtrlLib not called from lib init script - this may not work now; refused to load the library "             + libRelPath)
				  );
		}
	}
	string sPath = getPath(LIBS_REL_PATH, libRelPath);
	// attempt Ctrl extensions...
	if (sPath == "") {
		if (_UNIX) {
			sPath = getPath(BIN_REL_PATH, libRelPath+".so");
			if (sPath == "") sPath = getPath(BIN_REL_PATH, "linux-rhel-x86_64/"+libRelPath+".so");
		} else {
			sPath = getPath(BIN_REL_PATH, libRelPath+".dll");
			if (sPath == "") sPath = getPath(BIN_REL_PATH, "windows/"+libRelPath+".dll");
		}
	}

	if (sPath == "") {
		if (excOnNotFound) throw(makeError("", PRIO_SEVERE, ERR_CONTROL, 0, "fwGeneral_loadCtrlLib: library not found " + libRelPath));
		return false;
	}

	string script;
	script += "#uses \"" + libRelPath + "\" ";
	script += "   main(){ ";
	if (isDbgFlag("fwGeneral_loadCtrlLib")) {
		script += "   throwError(makeError(\"\",PRIO_INFO,ERR_CONTROL,0,";
		script += "     \"fwGeneral_loadCtrlLib: demand from " + caller + " to load " + libRelPath + " => " + sPath + " \"));";
	}
	script += " }";
	int rc = startScript(script);
	dyn_errClass err = getLastError();
	if (dynlen(err)) {
		int errCode = getErrorCode(err);
		const int ERR_SYNTAXERROR = 81;
		if (errCode == ERR_SYNTAXERROR) {
			throw(makeError("", PRIO_SEVERE, ERR_CONTROL, 0, "fwGeneral_loadCtrlLib: syntax error in library " + libRelPath));
		} else {
			string errTxt = getErrorCode(err);
			throw(makeError("", PRIO_SEVERE, ERR_CONTROL, 0, "fwGeneral_loadCtrlLib: could not load the library " + libRelPath + " ; " + errTxt));
		}
	}

	return true;
}

/** Checks whether a datapoint type of a given name exists in current system.

   @param[in] dptName		Datapoint type name to check
   @return true if DPType of a given name exists in the system; false if not
 */
bool fwGeneral_dpTypeExists(string dptName){
    dyn_string dptNames = dpTypes();
    return dptNames.contains(dptName);
}

//@}
