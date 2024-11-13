// SPDX-FileCopyrightText: © 2022 CERN <mail-TTO@cern.ch>
/** @file 
	A library of utilities related to the use of WinCC OA panels.
 */

/** Open a OO-panel and invoke its method with a parameter, get the return value
	
	The function opens the specified OO-panel as a child-panel and then invokes the specified
	public method of it, passing the parameter and optionally returning a value,
	Effectively, this allows to use OO-panels without
	dollar-parameters, but rather have them set-up through the public method.
	
	The function will wait until the module and panel are actually open and available before invoking
	the method. It also ensures that the PanelName is unique - if necessary generates a new one.
	
	@param panelFile - the file name of the panel
	@param panelName - the name of the panel (used to refer to it uniquely and defining its title)
	@param pnlMethod - the name of the public method of the panel that should be called
	@param data      - data that should be passed to the method; note that only a single parameter for method is supported.
						if more parameters needs to be passed, consider refactoring the method such that all of them
						could be transferred in e.g. a mapping, dyn_mixed, object or vector.
	@param expectRetval - should be set to @c true if the method returns a value (ie. has a non-void return type);
	
	@returns the value returned by the method (if @c expectRetval is set to true) or zero for methods that are of @c void return-type
	
	@throws exceptions if any of the parameters are wrong (refObject not found in the panel, panel file missing, method not being available)
*/
public mixed fwOOPanelOpen(string panelFile, string panelName, string pnlMethod, mixed data=nullptr, bool expectRetval=false)
{
	string refObj="";// means: the method of the panel itself should be used
	return _fwOOPanelOpen(myModuleName(), panelFile, panelName, refObj, pnlMethod, data, expectRetval);
}

/** @internal @private
	Internal functionality for opening a OO-panel as a child panel, with invocation of its method

	@param refObj may specify the reference-object that is embedded in the panel, on which the method should be called.
			If it is empty then it is assumed that the panel itself is the OO-panel, and its method should be invoked.
*/
mixed _fwOOPanelOpen(string moduleName, string panelFile, string panelName, string refObject, string pnlMethod, mixed methodData=nullptr, bool expectRetval=false)
{
	if (moduleName=="") moduleName=myModuleName();
	if (moduleName!=myModuleName()) throw(makeError("",PRIO_INFO,ERR_PARAM,0,__FUNCTION__,"functionality for non-own module not fully yet tested"));

	if (getPath(PANELS_REL_PATH,panelFile)=="") throw(makeError("",PRIO_SEVERE,ERR_PARAM,0,__FUNCTION__,"Invalid panel file:"+panelFile));

	const int maxRetries=100;

	// wait for module to be open...
	for (int i=0;i<maxRetries;i++) {
		if (isModuleOpen(moduleName)) break;
		delay(0,50);
	}

	if (!isModuleOpen(moduleName)) throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,"Module not open:"+moduleName));

	// make sure we have a unique panel name
	if (isPanelOpen(panelName)) {
		// we need to generate a new, unique panel name...
		for (int i=2;i<=1000;i++) {
			string newPanelName=panelName+" "+i;
			if (!isPanelOpen(newPanelName)) {
				panelName=newPanelName; 
				break;
			}
		}
	}

	// open the panel and wait for it to be open before we invoke the method...
	ChildPanelOnCentral(panelFile, panelName, moduleName,makeDynString());
	for (int i=0;i<maxRetries;i++) {
		if (isPanelOpen(panelName,moduleName)) break;
		delay(0,50);
	}

	if (!isPanelOpen(panelName,moduleName)) throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,"Panel opening times out:"+panelName));

	if (pnlMethod=="") return 0; // nothing more to do...

	return fwOOPanelInvokeMethod(pnlMethod, methodData, expectRetval, panelName, moduleName, refObject);

}

/** Invoke a method on the already open OO-panel, passing parameters, and getting the return value.

	The function works with specified module/panel names, allowing for effective use with
	e.g. embedded modules or splitters.

	The function will wait until the module and panel are actually open and available before invoking
	the method.

	@param pnlMethod - the name of the public method of the panel that should be called
	@param data      - data that should be passed to the method; note that only a single parameter for method is supported.
						if more parameters needs to be passed, consider refactoring the method such that all of them
						could be transferred in e.g. a mapping, dyn_mixed, object or vector.
	@param expectRetval - should be set to @c true if the method returns a value (ie. has a non-void return type);
	@param panelName - the name of the panel on which the method should be invoked (optional - defaults to the own panel)
	@param moduleName - the name of the module for the panel on which the method is to be invoked (optional - defaults to the own module)
	@param refObject - the name of the reference-object in the panel on which the method should be called. It could be left empty,
						meaning that we want to call the method of the panel specified in @c panelName and not one of its objects.

	@returns the value returned by the method (if @c expectRetval is set to true) or zero for methods that are of @c void return-type

	@throws exceptions if any of the parameters are wrong (refObject not found in the panel, method not being available)
*/
mixed fwOOPanelInvokeMethod(string pnlMethod, mixed methodData=nullptr, bool expectRetval=false, string panelName="", string moduleName="", string refObject="")
{
	if (moduleName=="") moduleName=myModuleName();
	if (panelName=="")  panelName=myPanelName();

	const int maxRetries=100;

	// wait for module to be open...
	for (int i=0;i<maxRetries;i++) {
		if (isModuleOpen(moduleName)) break;
		delay(0,50);
	}

	if (!isModuleOpen(moduleName)) throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,"Module not open:"+moduleName));

	for (int i=0;i<maxRetries;i++) {
		if (isPanelOpen(panelName, moduleName)) break;
		delay(0,50);
	}

	if (!isPanelOpen(panelName, moduleName)) throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,"Panel opening times out:"+panelName));

	// in the mode where refObject is specified, check if it exists and wait until it is mapped...
	if (refObject!="") {
		for (int i=0;i<maxRetries;i++) {
			if (shapeExists(moduleName+"."+panelName+":"+refObject)) break;
			delay(0,50);
		}
		if (!shapeExists(moduleName+"."+panelName+":"+refObject)) throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,"Missing RefObject "+refObject+" in panel "+panelName));
	}
	// NOTE! The getShape() below works as expected even without the refObject!
	// In this case it returns the shape representing the panel itself!
	shape pnlShape=getShape(moduleName+"."+panelName+":"+refObject);

	if (pnlShape==0) {
		string errMsg="Could not get the panel shape for "+panelName;
		if (refObject!="") errMsg+=" RefObj "+refObject;
		throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,errMsg));
	}

	if (!hasMethod(pnlShape, pnlMethod)) {
		string errMsg="Method "+pnlMethod+" invalid in the panel "+panelName;
		if (refObject!="") errMsg+=" RefObj "+refObject;
		throw(makeError("",PRIO_SEVERE,ERR_CONTROL,0,__FUNCTION__,errMsg));
	}

	mixed retval=0;
	if (expectRetval) {
		retval=invokeMethod(pnlShape, pnlMethod, methodData);
	} else {
		invokeMethod(pnlShape, pnlMethod, methodData);
	}
	return retval;
}
