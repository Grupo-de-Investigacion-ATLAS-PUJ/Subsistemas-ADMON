// SPDX-FileCopyrightText: © 2022 CERN <mail-TTO@cern.ch>

/** @file
 *  @brief The library implements the FwException class (@ref FwExceptionsClassManual)
 *
 * @author Piotr Golonka, CERN BE-ICS
 * @date 2022
 * @copyright (c) CERN All rights reserved
*/


// #uses "CtrlOOUtils": provides the fwThrowWithStackTrace() and fwRethrow which we optionally used (if CtrlOOUtils is present)
// to generate exceptions with corrected stack trace.
// However, we need only a "soft" dependency on CtrlOOUtils, hence we will dynamically-load it in the
// initialization of FwException::_useCtrlUtils static member

#uses "fwGeneral/fwPanelUtils.ctl"

struct _FwExceptionHelper {
    static const mapping severityTexts   = makeMapping (	PRIO_FATAL,     "FATAL",
															PRIO_SEVERE,    "ERROR",
															PRIO_WARNING,   "WARNING",
															PRIO_INFO,      "INFORMATION"); 				///< @internal

    static const mapping severityColors  = makeMapping (	PRIO_FATAL,		"FwAlarmFatalAck",
															PRIO_SEVERE,	"FwAlarmErrorAck",
															PRIO_WARNING,	"FwAlarmWarnAck",
															PRIO_INFO,		"FwStateOKPhysics");	///< @internal

    static const mapping errTypeTexts	=	makeMapping(    ERR_IMPL, 		"Implementation",
														    ERR_PARAM, 		"Parameterisation",
														    ERR_SYSTEM, 	"SYSTEM",
														    ERR_CONTROL, 	"CTRL Execution",
														    ERR_REDUNDANCY,	"Redundancy");			///< @internal
    public static int decodeSeverity(string severity) {

		if (severity=="INFO") severity="INFORMATION";

        int iSeverity = PRIO_SEVERE;
        for (int i=0;i<severityTexts.count();i++){
			if (severityTexts.valueAt(i) == severity) {
                iSeverity = severityTexts.keyAt(i);
                break;
            }
		}
        return iSeverity;
    }
};

/** The FwException class

	This is the JCOP Framework exceptions class.
*/
class FwException {

	/// @private @internal
	// trigger an attempt to load the CtrlOOUtils; public and non-const so that we could run the test cases
	public static bool _useCtrlUtils = fwGeneral_loadCtrlLib("CtrlOOUtils",false,true);

	private dyn_errClass _exc; 												///< the errClass containing the exception
	private time _t;            											///< the timestamp

	public static const dyn_errClass s_emptyException; 						///< instance to use as an empty exception
	public static dyn_string THROWS=makeDynString("THROW_EXCEPTION","",""); ///< instance used for @ref FwException::bridge

	/// pointer to the exception handler;
	/// by default it is @ref FwException::handleException()
	public static function_ptr s_handler=handleException;

	//--------------------------------------------------------------------------

	/** @brief The constructor

		Create a new FwException object that wraps the errClass variable specified
		in the @c err variable; sets the timestamp to the current timestamp.

		Consider using the @ref FwException::make() factory method as a more
		convenient method to create the object (without acually throwing it).

		To create and throw the exception consider using @ref FwException::raise()
		or one of the FwException::assert...() methods.

		@param[in] err - (optional) the dyn_errClass variable for which the
			FwException is created; by default - an empty exception.
	*/
	public FwException(dyn_errClass err=s_emptyException) {
		_exc=err;
		_t=getCurrentTime();
	}

	/** @brief returns the timestamp part of the FwException
	*/
	public time getTimestamp() { return _t;}

	/** @brief returns (a copy of) the errClass variable stored in this FwException
	*/
	public dyn_errClass getErrClass() { return _exc;}

	/** @brief returns the severity text of this FwException

		The returned text is one of "FATAL", "ERROR", "WARNING", "INFORMATION" that correspond
		to the severity of WinCC OA errors/exceptions, or the "EXCEPTION" if it cannot be mapped.
	*/
	public string getSeverityText() { return _FwExceptionHelper::severityTexts.value(getErrorPriority(_exc),"EXCEPTION"); }

	/** @brief returns the colour corresponding to the severity of this FwException

		The	mapping of colors is hardcoded and based on the JCOP Framework conventions. The returned colour
		names are suitable to set the _background_ colour of widgets, rather than the foreground,
	*/
	public string getSeverityColor() { return _FwExceptionHelper::severityColors.value(getErrorPriority(_exc),"_Window"); }

	/** @brief returnd the text corresponding to the error type of this FwException

		The returned text is one of "Implementation", "Parameterisation", "SYSTEM", "CTRL Execution", "Redundancy" or "UNKNOWN:x"
		corresponding to constants used e.g. in the @ref makeError()
	 */
	public string getTypeText() { return _FwExceptionHelper::errTypeTexts.value(getErrorType(_exc),"UNKNOWN:"+getErrorType(_exc)); }

	/** @brief returns the exception code of this FwException as a string

		The returned value makes sense when dealing with exceptions that make use
		of error catalogues (ie. either thrown by WinCC OA itself, in which case the
		main @c _err catalogue is used, or custom ones when FwException::make() is used).
		In this case the returned string value is a combination of the name of the
		error catalogue and the error code, separated by the "/" character e.g. "fwCore/10000".

		If the errorCatalogue is empty, yet still the errorCode is non-zero, the returned
		string is the errorCode.

		If the error catalogue is empty and the errorCode is zero (which is a typical case
		when FwException class is used with its assert...() methods or FwException::make(),
		then an empty string is returned.

		The exception code is supposed to be used to identify the well-known exception
		(ie. ones defined in the error catalogues) inside the @c catch{} blocks, without
		the need for string comparison of the exception text, etc.
	*/
	public string getCodeText() {
		string excCode;
		int iCode=getErrorCode(_exc);
		string sErrCat=getErrorCatalog(_exc);
		if (sErrCat=="") {
			if (iCode!=0) excCode=iCode;
		} else {
			excCode+=sErrCat+"/"+iCode;
		}
		return excCode;
	}

	/** @brief returs the stack trace part of this FwException

		Note that the stack traces generated by FwException are different
		where @c CtrlOOUtils is available (they are more readable). For
		details plese refer to @ref FwExceptionsManual

	*/
	public dyn_string getStackTrace() { return getErrorStackTrace(_exc); }

	/** @brief returns the complete exception text, including details

		The returned value contains the whole exception text, including
		the details, and the part that comes from the error catalogue
		(if present). The parts are separated by the ", " string, following
		the conventions of WinCC OA.

		@sa FwException::getExcText()
		@sa FwException::getExcDetails()
	*/
	public string getText() {
		// treat the case where we have no error from the errCat
		// in which case the text starts with a " ," string...

		string errTxt=getErrorText(_exc);
		errTxt=strltrim(errTxt,", ");
		return errTxt;
	}

	/** @brief returns the details part of the exception text

		The returned value contains only the "detail" part of the exception
		text, ie. with the main exception text stripped-out. The resulting
		@c dyn_string list comes from the splitting of the the details string
		by their separator: ", ",

		@sa FwException::getExcText()
		@sa FwException::getText()
	*/
	public dyn_string getExcDetails() {
		// we take into account the case where the text error does not come from the errCat!
		string errTxt=getText();
		dyn_string ds=errTxt.split(", ");
		if (ds.count()>=1) ds.takeFirst(); // take out the main text
		return ds;
	}

	/** @brief returns the main exception text, without details

		The returned value contains only the "main" part of the exception
		text, ie. with all the details (separated by the ", " string)
		stripped-out.

		@sa FwException::getExcDetails()
		@sa FwException::getText()
	*/
	public string getExcText() {
		string errTxt=getText();
		dyn_string ds=errTxt.split(", ");
		if (ds.count()>=1) return ds.first(); // only the main text
		return errTxt;
	}

	/** @brief returns a FwException correspoing to the last raised exception

		This method is supposed to be used in the @c catch{} block to
		get a handle to the exception. Internally it calls the
		@ref getLastException() function, and wraps it into a FwException object.
		Then, this object could be conveniently interrogated by the methods
		of the @ref FwException class.
	 */
	public static FwException last() { return FwException(getLastException()); }

	/** @brief checks the lastError and throws it as exception

		This method provides a convenient way for checking the CTRL error
		stack (@sa getLastError() ) and if it is not empty than throw it
		as an exception.

		Functionality-wise it provides an alternative to setThrowErrorAsException() .

		However, unlike the latter, it properly handles the specific behaviour
		of functions related to datapoints (dpGet() , dpSet() , dpConnect() , etc),
		described further in the @ref FwExceptionsForDpGetSet chapter.

		@throws the content of the last error
	*/
	public static void checkLastError() {
		dyn_errClass err=getLastError();
		if (!dynlen(err)) return;
		if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(err[1], -1); else throw (err[1]);
	}

	/** @brief Create a FwException object with a specified content

		Creates a FwException object which contains an errClass with specific content.

		With the use of optional parameters @c errCat, @c errCode one may use the error
		texts and codes defined in the error catalogues.

		@param[in] severity	(string) 	the severity of exception; one of
										"SEVERE", "ERROR", "WARNING", "INFO" (or "INFORMATION")
		@param[in] excText 	(string) 	specifies the primary part of the exception text
		@param[in] detail 	(string)	(optional) additional details for the exception
		@param[in] errCat	(string)	(optional) the name of error catalogue
		@param[in] errCode	(int)		(optional) the error code inside the error catalogue
		@param[in] errType	(int)		(optional) the error type, following the constants used
										by WinCC OA - see @ref makeError()
	*/
	public static FwException make(string severity, string excText, string detail="", string errCat="", int errCode=0, int errType=ERR_CONTROL) {
		FwException fe;
		int iSeverity=_FwExceptionHelper::decodeSeverity(severity);
		if (detail=="") {
			fe._exc=makeError(errCat, iSeverity, errType, errCode, excText);
		} else {
			fe._exc=makeError(errCat, iSeverity, errType, errCode, excText, detail);
		}
		return fe;
	}

	/** @brief Throws the content of this FwException as a WinCC OA exception.

		Note that if CtrlOOUtils is used then the resulting strack trace is more readable,
		as its top points to the actual place from which the FwException::throwMe() was called,
		and not the FwException::throwMe() itself.

		@sa @ref throw()

	 */
	public void throwMe() {
		if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(_exc, -1); else throw (_exc);
	}

	/** @brief Returns a printable string representation of this FwException

		@param[in] withStackTrace	(optional) if set to @c true then the returned
									text will contain the stack trace
		@param[in] withExcCode		(optional) if set to @c true then the returned
									text will contain the exception code

		@sa FwException::print()
		@sa FwException::getCodeText()
	 */
	public string ls(bool withStackTrace=false, bool withExcCode=false) {
		string s;
		s+="Exception ["+this.getSeverityText()+"]: "+this.getText();
		if (withExcCode) s+= " ("+this.getCodeText()+")";
		if (withStackTrace) {
			dyn_string stk=this.getStackTrace();
			for (int i=0;i<stk.count();i++) {
				s+="\n  ["+i+"]: "+stk.at(i);
			}
		}
		return s;
	}

	/** @brief Prints the content of this FwException to the WinCC OA log

		The printout is done using the @ref DebugTN function, and uses
		the FwException::ls() for formating.
		It is on purpose that this printout is different than a direct
		printout of the errClass variable (which becomes coloured/formatted
		by the WinCC OA log viewer), hence more convenient for debugging
		purposes.

		@param[in] withStackTrace	(optional) if set to @c true then the printout
									will contain the stack trace
		@param[in] withExcCode		(optional) if set to @c true then the printout
									will contain the exception code


		@sa FwException::ls()

	 */
	public void print(bool withStackTrace=false, bool withExcCode=false) {
		string s=ls(withStackTrace, withExcCode);
		DebugTN(s);
	}

	/** @brief handle the exception - use in the catch{} block

		This method provide the quick way to have the default (configurable)
		exception handling in the catch{} block.

		It fetches the last raised exception and then invokes the configured
		excepion handler - by default the FwException::handleException().

		@sa FwException::handleException()
		@sa FwExceprion::handle()
		@sa FwException::setExceptionHandler()
	*/
	public static void handleLast() {
		FwException exc=last();
		exc.handle();
	}

	/** @brief invokes the configured exception handler for this FwException

		@sa FwExceprion::handleLast()
		@sa FwException::handleException()
		@sa FwException::setExceptionHandler()

	*/
	public void handle() {
		callFunction(s_handler,this);
	}

	/** @brief Default exception handler

		The default exception handler is invoked with an instance
		of FwException. On the UI Manager it displays the dedicated
		exception handling panel with the content of the FwException.
		When executed in other managers (CTRL or EVENT) it will throw
		the contect of FwException to the WinCC OA log using the
		@ref throwError().

		@par[in] exc	the exception object to be handled

		@sa FwException::handle()
		@sa FwException::handleLast()
		@sa FwException::setExceptionHandler()
	*/
	public static void handleException(const FwException &exc) {
		if (myManType()==UI_MAN) {
			mixed rc=fwOOPanelOpen("fwStdLib/fwExceptionHandle.pnl", "Exception",  "init", exc, false);
		} else {
			throwError(exc._exc);
		}
	}

	/** @brief Set the new exception handler

		The method allows to hook the new exception handler function for FwException.
		By default, if not changed explicitly, the @ref FwException::handleException is used
		to handle exceptions.

		This method returns the function pointer to the previously used exception handler. This
		could be used to implenent the "cascading" of handlers, ie. the new handler could
		be told to invoke the previous handler. Refer to @ref FwExceptionsManual for more details.

		@returns the function pointer to the old exception handler

		@sa FwException::handle()
		@sa FwException::handleLast()
		@sa FwException::handleException()

	*/
	public static function_ptr setExceptionHandler(function_ptr newExceptionHandler) {
		function_ptr oldExceptionHandler = s_handler;
		s_handler=newExceptionHandler;
		return oldExceptionHandler;
	}


	/** @brief check the @c exceptionInfo and raise a FwException

		This method provides the way to bridge the legacy functions that
		still use @c exceptionInfo mechanisms to the exceptions-based programming.

		This method is supposed to be called after any call to a function that
		could populate the @c exceptionInfo. If @c exceptionInfo is not empty,
		then the information from it will be extracted and an exception will
		be raised.

		@param[in] exceptionInfo	the legacy, standard  exceptionInfo variable

	*/
	public static void checkRaise(const dyn_string &exceptionInfo) {

		if (exceptionInfo.isEmpty()) return;

        int iSeverity = _FwExceptionHelper::decodeSeverity(exceptionInfo[1]);

		errClass exc;
		if (exceptionInfo[3]=="") {
			exc=makeError("",iSeverity,ERR_CONTROL,0,exceptionInfo[2]);
		} else {
			exc=makeError("",iSeverity,ERR_CONTROL,0,exceptionInfo[2], exceptionInfo[3]);
		}

		if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
	}

	/** @brief Raise a "SEVERE" exception with specific text

		This is a convenience method to quickly raise an exception
		(with "SEVERE" severity), specific text and optionally details.
		For more ways to create/raise an exception refer to the
		family of the @c FwException::assert...() methods and
		to @ref FwException::make()

		@param[in] excText	specifies the exception text
		@param[in] details	(optional) allow to specify a list of details;
							they will be concatenated with the @c excText
							using the standard ", " separator used by WinCC OA.

		@sa FwException::make()
		@sa FwException::throwMe()
		@sa FwException::assert()

	*/
	public static void raise(string excText,dyn_string details=makeDynString()) {
		errClass exc;
		if (details.isEmpty()) {
			exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,excText);
		} else {
			string sDetails=details;
			sDetails.replace(" | ",", ");
			exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,excText,sDetails);
		}
		if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
	}

	/** @brief raise an exception if condition not met

		This convenience method allow to raise an exception when the boolean condition is not met.

		@param[in] condition	the boolean referring to the condition that is checked
		@param[in] what			the descriptive text that will be used in the exception when condition
								is not met

	 */
	public static void assert(bool condition, string what) {
		if (condition) return;
		errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what);
		if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
	}

	/** @brief raise an exception if datapoint does not exist or is of wrong dpType

		This convenience method allow to raise an exception when a datapoint specified in the
		@c dpName parameter does not exist, and (optionally) also check if it is of specified
		datapoint-type.


		@param[in] dpName	the name of the datapoint to be checked
		@param[in] dpType	(optional) the name of the datapoint type; no checking is done if empty
		@param[in] what		(optional) the descriptive text that will be used in the exception when conditions
							are not met; if empty, then a generic predefined text will be used.

	*/
	public static void assertDP(string dpName, string dpType="", string what="") {
		if (!dpExists(dpName)) {
			string excDetail="Datapoint does not exist";
			if (what=="") {
				what=excDetail;
				excDetail=dpName;
			}
			errClass exc=makeError("",PRIO_SEVERE, ERR_CONTROL,0,what, excDetail);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
		if (dpType!="" && dpTypeName(dpName)!=dpType) {
			string excDetail="Incorrect DataPoint Type for Datapoint: "+dpName;
			if (what=="") {
				what=excDetail;
				excDetail="Expected:"+dpType+", Actual:"+dpTypeName(dpName);
			}
			errClass exc=makeError("",PRIO_SEVERE, ERR_CONTROL,0,what, excDetail);

			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief raise an exception if a value does not belong to a set

		This convenience method allow to raise an exception when the value specified
		in the @c value parameter does not match any of the values specified in the
		@c valueSet.
		Notably, it could be used to check against a list of available options.


		@param[in] value	the value to be checked
		@param[in] valueSet	the list of permitted values
		@param[in] what		(optional) the descriptive text that will be used in the value was
							not found in the set ; if empty, then a generic predefined text will be used.

	*/
	public static void assertInSet(const mixed &value, const dyn_mixed &valueSet, string what="") {
		if (!dynContains(valueSet,value)) {
			string sSet=valueSet;
			strreplace(sSet," | ",",");
			string excDetail="Missing/Invalid value";
			if (what=="") {
				what=excDetail;
				excDetail=value;
			}
			excDetail+=", Available:, "+sSet;
			errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what,excDetail);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief raise an exception if a shared pointer is null

		@param[in] ptr		the shared_ptr to be checked
		@param[in] what		(optional) the descriptive text that will be used if the ptr is null;
							if empty, then a generic predefined text will be used.

	 */
	public static void assertNotNull(const shared_ptr<void> ptr, string what="") {
		if (equalPtr(ptr,nullptr)) {
			if (what=="") what="Null object encountered";
			errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief raise an exception if the values are not equal

		@param[in] val1		the first (reference) value
		@param[in] val2		the second (checked) value
		@param[in] what		(optional) the descriptive text that will be used if the values differ;
							if empty, then a generic predefined text will be used.

	 */
	public static void assertEqual(const mixed &val1, const mixed &val2, string what="") {
		if (val1!=val2) {
			if (what=="") what="Values differ";
			errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what,val1,val2);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief raise an exception if a vector is empty

		@param[in] vec		the vector to be checked
		@param[in] what		(optional) the descriptive text that will be used if the vector is empty;
							if empty, then a generic predefined text will be used.

	 */
	public static void assertNotEmpty(const vector<void> &vec, string what="") {
		if (vec.isEmpty()) {
			if (what=="") what="List is empty";
			errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief raise an exception if a dyn_ array is empty

		@param[in] dm		the dyn_ variable to be checked
		@param[in] what		(optional) the descriptive text that will be used if the dyn_ variable is empty;
							if empty, then a generic predefined text will be used.

	 */
	public static void assertDynNotEmpty(const dyn_mixed &dm, string what="") {
		if (dm.isEmpty()) {
			if (what=="") what="List is empty";
			errClass exc=makeError("",PRIO_SEVERE,ERR_CONTROL,0,what);
			if (_useCtrlUtils && isFunctionDefined("fwThrowWithStackTrace")) fwThrowWithStackTrace(exc, -1); else throw (exc);
		}
	}

	/** @brief conerts this @c FwException to a @c exceptionInfo

		This method allows to bridge the new FwException-based code
		with the code that uses the legacy exceptionInfo for exception handling.

		@returns 	a dyn_string in the standard @c exceptionInfo format corresponding
					to this FwException
	*/
	public dyn_string toExceptionInfo() {
		// extract the 1st line of stack trace to get function name:
		string fnName;
		dyn_string stkTrace=getStackTrace();
		if (dynlen(stkTrace)) fnName=stkTrace.first();
		fnName=substr(fnName, 0,strpos(fnName,"("))+"()";
		dyn_string exceptionInfo=makeDynString(getSeverityText(), fnName+": "+getText(),"");

		return exceptionInfo;
	}

	/** @brief returns last exception as @c exceptionInfo

		This method is expected to be used in the @c catch{} block
		to retrieve the last exception and convert it to the standard
		@c exceptionInfo format.

		@sa FwException::toExceptionInfo()
		@sa FwException::last()
	 */
	public static dyn_string lastAsExceptionInfo() {
		FwException exc=last();
		dyn_string exceptionInfo=exc.toExceptionInfo();
		return exceptionInfo;
	}

	/** @brief rethrows the current exception

		This method is supposed to be used in the @c catch{} block
		to rethrow the current exception.

		Note that if CtrlOOUtils is used then the stack trace of
		the original exception will be preserved (ie. it would not
		contain the frame related to the catch block, making it
		easier to interpret).
	 */
	public static void rethrow() {

		if (_useCtrlUtils && isFunctionDefined("fwRethrow")) {
           fwRethrow();
		} else {
			dyn_errClass _excList=getLastException();
			if (!_excList.isEmpty()) {
				errClass _lastExc=_excList.first();
				throw(_lastExc);
			}
		}
	}

    /** @brief Bridge with the exceptionInfo-based handling.

		This method allows to bridge the code that uses
		the legacy @c exceptionInfo with the new exceptions
		and it is supposed to be used in fuctions that should
		support both methods of exception signaling: the
		legacy exceptionInfo-based and the exception-based.

		The method should be called from the @c catch{}
		block of the function, and Its functioning depends on
		the content of the @c exceptionInfo parameter that is passed.

		If the predefined FwException::THROWS is passed to it, then
		this is the signal that native exceptions should be employed,
		and hence the current exception (in the @c catch{} block) will
		be rethrown.

		Otherwise, if anything else is passed, then it is assumed
		that the legacy mode should be used, and the @c exceptionInfo
		is populated with the content of the current exception.

		Please refer to the example in the @ref FwExceptionsClassManual.
    */
	public static void bridge(dyn_string &exceptionInfo) {

        FwException exc = last();
        THROWS = makeDynString("THROW_EXCEPTION","",""); // RESET/RECOVER
       	if (exceptionInfo==THROWS) rethrow();
        // otherwise, put it into the exceptionInfo
		exceptionInfo = exc.toExceptionInfo();
	}

};
