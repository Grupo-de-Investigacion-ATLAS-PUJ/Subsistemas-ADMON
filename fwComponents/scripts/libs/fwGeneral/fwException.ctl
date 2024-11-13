// SPDX-FileCopyrightText: © 2000 CERN <mail-TTO@cern.ch>

/**@file

   @brief The library for raising the legacy exceptionInfo exceptions (@ref FwExceptionInfoManual).

   @date 		Creation Date 4/12/00
   @author 		JCOP Framework Team
   @copyright 	© CERN
 */

/** @internal @private
 */
const string fwException_SETTINGS_DP = "_fwException";

/** Generate the @c exceptionInfo with provided details, and log it.

	The exception details are appended to the dyn_string which is passed
	as the first argument of this function.
    Three strings are appended to the dyn_string, firstly the exceptionType then the exceptionText
    and finally a code which is associated with the exception (exceptionCode)

	If exception logging is configured, the exception is also printed to the WinCC OA log.

	@public

	@param[in,out]	exceptionInfo exception variable to be populated with details
	@param[in]		exceptionType severity of exception - "FATAL", "ERROR", "WARNING" "INFO"
	@param[in]		exceptionText text describing the details of the exception;
					it is recommended that the text starts with the name of the function
					followed by the "(): " string, in which case the exception when displayed
					by fwExceptionHandling_display() will provide nice formatting
	@param[in]		exceptionCode a code associated with the exception; its use is not defined,
					and it is not displayed by exception handlin facilities. One should pass
					an empty string here.
 */
void fwException_raise(dyn_string &exceptionInfo, string exceptionType, string exceptionText, string exceptionCode)
{
	if (!globalExists("g_fwExceptionPriorities"))
		_fwException_initialise();

	//DebugN("Exception raised: Type = " + exceptionType + ", Text = " + exceptionText, ", Code = " + exceptionCode);
	dynAppend(exceptionInfo, makeDynString(exceptionType, exceptionText, exceptionCode));
	_fwException_writeToPvssLog(exceptionInfo);
}

/** @internal @private

*/
void _fwException_initialise()
{
	bool logExceptions;
	dyn_int processedLevels;
	dyn_string fwLevels, pvssLevels;

	addGlobal("g_fwExceptionPriorities", MAPPING_VAR);

	if (dpExists(fwException_SETTINGS_DP)) {
		dpGet(fwException_SETTINGS_DP + ".priorityMapping.fwLevels", fwLevels,
			  fwException_SETTINGS_DP + ".priorityMapping.pvssLevels", pvssLevels,
			  fwException_SETTINGS_DP + ".showInPvssLog", logExceptions);
	} else {
		fwLevels = makeDynString("FATAL", "ERROR", "WARNING", "INFO", "*");
		pvssLevels = makeDynString("PRIO_FATAL", "PRIO_SEVERE", "PRIO_WARNING", "PRIO_INFO", "PRIO_INFO");
		logExceptions = TRUE;
	}

	for (int i = 1; i <= dynlen(pvssLevels); i++) {
		if (!logExceptions || pvssLevels[i] == "") {
			processedLevels[i] = -1;
		} else {
			evalScript(processedLevels[i], "int main(){return " + pvssLevels[i] + ";}", makeDynString());
		}

		g_fwExceptionPriorities[fwLevels[i]] = processedLevels[i];
	}
}

/** @internal @private

*/
void _fwException_writeToPvssLog(dyn_string &exceptionInfo)
{

    if (!dynlen(exceptionInfo)) return;

    for (int i=1; i<=dynlen(exceptionInfo); i+=3) {

        string excInfoPrio, excInfoText, excInfoCode;
        if (dynlen(exceptionInfo) >= i) excInfoPrio = exceptionInfo[i];
        if (dynlen(exceptionInfo) >= i+1) excInfoText = exceptionInfo[i+1];
        if (dynlen(exceptionInfo) >= i+2) excInfoCode = exceptionInfo[i+2];

        int errPrio = g_fwExceptionPriorities.value(excInfoPrio, -1);
        if (errPrio==-1) errPrio = g_fwExceptionPriorities.value("*", -1);
        if (errPrio==-1) return;

        string errCat="";
        int    errCode=0;
        if (excInfoCode!="") {
            // we may have a direct code from the _err catalogue, or have a "CATALOGUE/ERRCODE"
            dyn_string ds=strsplit(excInfoCode, "/");
            if (ds.count()==2) {
                errCat=ds.first();
                errCode=(int)ds.last();
            }
        }
        throwError(makeError(errCat, errPrio,  ERR_CONTROL, errCode, excInfoText));
    }
}

/** Checks the last WinCC OA error and throws it as an exception.

	@reviewed 2018-06-22 @whitelisted{WinCCOAIntegration}

	You may want to consider also using the @ref setThrowErrorAsException() built-in function of WinCC OA.
	However, certain functions, such as @ref dpGet / @ref dpSet , may return the NO_ERR (zero) return code
	and do not raise exception, and still getLastError() would yield the reason for unexpected condition.
	In this case this function should be used.
 */
public void fwException_throwLastError()
{
    dyn_errClass errs = getLastError();

    if (dynlen(errs) > 0) {
        throw(errs[1]);
    }
}
