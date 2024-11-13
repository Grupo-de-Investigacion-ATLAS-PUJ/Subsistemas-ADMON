// SPDX-FileCopyrightText: © 2000 CERN <mail-TTO@cern.ch>

/** @file 
	@brief The library for handling the legacy exceptionInfo exceptions ((@ref FwExceptionInfoManual).

	@date Creation Date 4/12/00
	@author JCOP Framework Team
 */
 
 
/** Displays the exception in the popup panel.

	The set of exceptions passed in the @c exceptionInfo variable is displayed
	in the modal dialog box, and then the variable
	is cleared. If more than one exception is stacked in the @c exceptionInfo,
	then it is possible to page through the exceptions.

	If the @c exceptionInfo is empty, the function returns silently.
	
	@remark may only be used in the code that runs in the UI manager, otherwise
	it will cause the execution error. Please refer to @ref FwExceptionsManual
	for more information.



	@public
	@param[in,out] exceptionInfo standard exception-handling variable; 
					it is cleared before return
 */
void fwExceptionHandling_display(dyn_string &exceptionInfo)
{
	if (dynlen(exceptionInfo) <= 0) return;

	if (!globalExists("g_fwExceptionHandlingDisplay")) _fwExceptionHandling_initialise();
	if (!g_fwExceptionHandlingDisplay) return;

	// there seems to be a race condition if the function is called many times, which
	// causes modal dialog boxes to be popped up in parallel that leads to UI lockups
	// (ETM-1607).
	// Therefore we make a blocking dialog-box, and only a single one

	dyn_float df;
	dyn_string ds;
	ChildPanelOnCentralModalReturn("fwGeneral/fwExceptionDisplay.pnl",
								   "Exception Details",
								   makeDynString("$asExceptionInfo:" + exceptionInfo),
								   df, ds
								   );
	dynClear(exceptionInfo);
}

/** Appends the exception information to the list widget.

	The function should be called from a panel having a list-widget
	that is supposed to present the log of messages.
	If more than one exception is stacked in the @c exceptionInfo,
	all of them are appended to the list widget.
	
	The function will return silently if @c exceptionInfo is empty.
	
	@public

	@remark The function may only be used in the code that
		is executed in the UI manager, and have the list widget
		specified in the @c listName parameter in its scope.
	
	@warning The name of the function may imply that the message would
		be printed to the WinCC OA log, which is not the case. The functionality
		of having @c exceptionInfo stored in WinCC OA log is implemented
		by @ref fwException_raise(), and may be configured further. Please,
		refer to @ref FwExceptionsManual for more details.

	@param[in,out] 	exceptionInfo 	standard framework exceptions variable; 
									cleared before return
	@param[in] 		listName 		the name of the selection list widget 
									used to display log messages
 */
void fwExceptionHandling_log(dyn_string &exceptionInfo, string listName)
{
	int i;
	string exceptionDetails;

	if (dynlen(exceptionInfo) <= 0)
		return;

	for (i = 1; i <= (dynlen(exceptionInfo)); i += 3) {
		exceptionDetails = exceptionInfo[i] + ": " + exceptionInfo[i + 1] + ", Code: " + exceptionInfo[i + 2];
		setValue(listName, "appendItem", exceptionDetails);
	}
	exceptionInfo = makeDynString();
}

/** @internal @private
 */
void _fwExceptionHandling_initialise()
{
	bool inhibitDisplayExceptions;

	addGlobal("g_fwExceptionHandlingDisplay", BOOL_VAR);

	if (dpExists(fwException_SETTINGS_DP)) {
		dpGet(fwException_SETTINGS_DP + ".inhibitDisplayWindow", inhibitDisplayExceptions);
	} else {
		inhibitDisplayExceptions = FALSE;
	}

	g_fwExceptionHandlingDisplay = !inhibitDisplayExceptions;
}
