// SPDX-FileCopyrightText: © 2001 CERN <mail-TTO@cern.ch>
/**@file

   This library is used to convert the given states of a device into the colour which represents this state.
   Funcitons are also available for dpConnecting the colour of graphical elements to a device state.

   @par Creation Date
        23/01/01

   @par Modification History
        02/05/01	Oliver Holme - Added support for connecting to summary alerts
                                Created new function _fwCalculateColourWithSummaryAlertCB()

   11/09/14 Lorenzo Masetti - 13 years later... -  added possibility to specify shapeName  (fwColour_connectShapeBackColToStatus). Implemented with dpConnnectUserData. New function fwColour_getColourForDpe to get the colour without connecting

   @par Constraints

   @author
        Oliver Holme (IT-CO)
 */

//@{

/**This function controls the background colour of the item from within which the function was called.
        The colour is controlled by dpConnecting to the invalid bit of the given data point element, and if it exists,
        the alert active bit and the alert colour are also connected to.
        When the function is called, and any time when the alert state or invalid state changes, a function is called
        which evaluates the current state, selects the relevant colour and sets the background colour of the graphical item.

   @par Modification History
        02/05/01 Oliver Holme - Added support for connecting to summary alerts
                                                        If a summary alert exists, the _fwCalculateColourWithSummaryAlertCB
                                                        is connected to.  If no alert exists on a dpe of type structure,
                                                        the OK colour is shown.

   @par Constraints
        This function can only be called from within a graphical interface

   @par Usage
        Public

   @par PVSS managers
        VISION

   @param dpe data point element
   @param exceptionInfo details of any exceptions are placed in here.
 */
void fwColour_connectItemBackColToStatus(string dpe, dyn_string &exceptionInfo)
{
	fwColour_connectShapeBackColToStatus(dpe, this.name, exceptionInfo);

}

/** This function controls the background colour of the specified shape.
   See fwColour_connectItemBackColToStatus for details


   @param dpe data point element
   @param shapeName name of the shape
   @param exceptionInfo  details of any exceptions are placed in here.
 */
void fwColour_connectShapeBackColToStatus(string dpe, string shapeName, dyn_string &exceptionInfo)
{
	int configType;
	string elementColour;
	shape shp = getShape(shapeName);

	mapping parameters;

	parameters["shapeName"] = shapeName;

	if (!dpExists(dpe)) {
		fwException_raise(      exceptionInfo,
								"ERROR",
								"fwColour_connectToStatus(): The data point element\n\"" + dpe + "\" does not exist",
								"");
		shp.backCol("DpDoesNotExist");
		shp.foreCol("DpDoesNotExist");
		return;
	}

	dpGet(dpe + ":_alert_hdl.._type", configType);

	switch (configType) {
	  case DPCONFIG_SUM_ALERT:
		if (dpConnectUserData(   "_fwCalculateColourWithSummaryAlertCB", parameters,
								 dpe + ":_alert_hdl.._act_state_color",
								 dpe + ":_alert_hdl.._active") == -1) {
			fwException_raise(      exceptionInfo,
									"INFO",
									"fwColour_connectToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
									"");
			shp.backCol("DpDoesNotExist");
			shp.foreCol("DpDoesNotExist");
		}
		break;

	  case DPCONFIG_NONE:
		if (dpElementType(dpe) == DPEL_STRUCT) {
			//fwColour_convertStatusToColour(elementColour, "", FALSE, FALSE, exceptionInfo);
			elementColour = "_3DFace";
			shp.backCol(elementColour);
		} else {
			if (dpConnectUserData(   "_fwCalculateColourWithoutAlertCB", parameters,
									 dpe + ":_original.._invalid") == -1) {
				fwException_raise(      exceptionInfo,
										"INFO",
										"fwColour_connectToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
										"");
				shp.backCol("DpDoesNotExist");
				shp.foreCol("DpDoesNotExist");
			}
		}
		break;
	  default:
		if (dpConnectUserData(   "_fwCalculateColourWithAlertCB", parameters,
								 dpe + ":_alert_hdl.._act_state_color",
								 dpe + ":_alert_hdl.._active",
								 dpe + ":_original.._invalid") == -1) {
			fwException_raise(      exceptionInfo,
									"INFO",
									"fwColour_connectToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
									"");
			shp.backCol("DpDoesNotExist");
			shp.foreCol("DpDoesNotExist");
		}
		break;
	}
}

/** @internal @private

   This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
        The function then set the background colour of graphical item "this" to that colour.

   @par Constraints
        This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param userData contains a mapping with the shapeName
   @param dpe1 data point element
   @param alertColour a string containing the name of the current alert colour
   @param dpe2 data point element
   @param alarmActive a bit to represent if alert handling is active or not (TRUE = active, FALSE = inactive)
   @param dpe3 data point element
   @param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)

   @reviewed 2018-07-25 @whitelisted{Callback}
 */
void _fwCalculateColourWithAlertCB(mapping userData, string dpe1, string alertColour, string dpe2, bool alarmActive, string dpe3, bool dataInvalid)
{
	string elementColour;
	dyn_string exceptionInfo;

	fwColour_convertStatusToColour(elementColour, alertColour, !alarmActive, dataInvalid, exceptionInfo);
	string shapeName = userData["shapeName"];

	setValue(shapeName, "backCol", elementColour);
}

/** @internal @private

	This functions takes the given state of a summary alert and calls a function which calculates the relevant colour.
        The function then set the background colour of graphical item "this" to that colour.

   @par Constraints
        This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param userData contains a mapping with the shapeName
   @param dpe1 data point element
   @param alertColour a string containing the name of the current alert colour
   @param dpe2 data point element
   @param alarmActive a bit to represent if alert handling is active or not (TRUE = active, FALSE = inactive)

   @reviewed 2018-07-25 @whitelisted{Callback}
 */
void _fwCalculateColourWithSummaryAlertCB(mapping userData, string dpe1, string alertColour, string dpe2, bool alarmActive)
{

	string elementColour;
	dyn_string exceptionInfo;

	fwColour_convertStatusToColour(elementColour, alertColour, !alarmActive, FALSE, exceptionInfo);
	string shapeName = userData["shapeName"];

	setValue(shapeName, "backCol", elementColour);
}

/** @internal @private
	This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
        The function then set the background colour of graphical item "this" to that colour.

   @par Constraints
        This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param userData contains a mapping with the shapeName
   @param dpe1 data point element
   @param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)

   @reviewed 2018-07-25 @whitelisted{Callback}
 */
void _fwCalculateColourWithoutAlertCB(mapping userData, string dpe1, bool dataInvalid)
{
	string elementColour;
	dyn_string exceptionInfo;

	fwColour_convertStatusToColour(elementColour, "", 0, dataInvalid, exceptionInfo);
	string shapeName = userData["shapeName"];
	setValue(shapeName, "backCol", elementColour);
}

/** @internal @private
	This functions takes the given states of a data point element and calculates the appropriate colour which
        summarises its status.

   @par Constraints
        None

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param elementColour the calculated status colour is returned here.
   @param alertColour a string containing the name of the current alert colour
   @param masked a bit to represent if alert is maksed or not (TRUE = masked, FALSE = unmasked)
   @param invalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)
   @param exceptionInfo details of any exceptions are placed in here.
 */
void fwColour_convertStatusToColour(string &elementColour, string alertColour, bool masked, bool invalid, dyn_string &exceptionInfo)
{

//	DebugN(alertColour, masked, invalid);

	if (invalid) {
		elementColour = "FwDead";
	} else
	if ((masked) && (alertColour == "FwStateOKPhysics" || alertColour == "")) {
		elementColour = "FwAlarmMasked";
	} else
	if (alertColour == "") {
		elementColour = "FwStateOKPhysics";
	} else {
		elementColour = alertColour;
	}
}



/** The function returns the current color to be used to display dpe with the same logic of fwColour_connectShapeBackColToStatus

   @par Constraints
        None

   @par Usage
   Public

   @par PVSS managers
        VISION

   @param dpe data point element
   @return color
 */
string fwColour_getColourForDpe(string dpe)
{
	dpe = dpSubStr(dpe, DPSUB_SYS_DP_EL);

	dyn_string exceptionInfo;
	string alertColour; bool masked;
	string elementColour;
	int configType;
	bool dataInvalid;


	if (!dpExists(dpe))
		return "DpDoesNotExist";

	dpGet(dpe + ":_alert_hdl.._type", configType);

	switch (configType) {
	  case DPCONFIG_SUM_ALERT:
		if (dpGet(                                      dpe + ":_alert_hdl.._act_state_color", alertColour,
														dpe + ":_alert_hdl.._active", masked) == -1) {

			DebugTN("fwColour_getColourForDpe(): Getting the  status of the data point element\n\"" + dpe + "\" was unsuccessful");
			return "DpDoesNotExist";
		}

		fwColour_convertStatusToColour(elementColour, alertColour, masked, false, exceptionInfo);
		return elementColour;
		break;

	  case DPCONFIG_NONE:
		if (dpElementType(dpe) == DPEL_STRUCT) {
			//fwColour_convertStatusToColour(elementColour, "", FALSE, FALSE, exceptionInfo);
			elementColour = "_3DFace";

		} else {
			if (dpGet(               dpe + ":_original.._invalid", dataInvalid) == -1) {
				DebugTN("fwColour_getColourForDpe(): Getting the  status of the data point element\n\"" + dpe + "\" was unsuccessful");
				return "DpDoesNotExist";
			}
			fwColour_convertStatusToColour(elementColour, "", 0, dataInvalid, exceptionInfo);
		}
		break;
	  default:
		if (dpGet(                               dpe + ":_alert_hdl.._act_state_color", alertColour,
												 dpe + ":_alert_hdl.._active", masked,
												 dpe + ":_original.._invalid", dataInvalid) == -1) {
			DebugTN("fwColour_getColourForDpe(): Getting the  status of the data point element\n\"" + dpe + "\" was unsuccessful");
			return "DpDoesNotExist";
		}

		fwColour_convertStatusToColour(elementColour, alertColour, masked, dataInvalid, exceptionInfo);


		break;

	}

	return elementColour;

}

//@}
