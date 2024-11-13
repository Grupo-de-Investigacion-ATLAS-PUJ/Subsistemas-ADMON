// SPDX-FileCopyrightText: © 2022 CERN <mail-TTO@cern.ch>

/** @file
*  @brief The library implements the FwPanel class to make working with OO-panels easier.
*
* @author Piotr Golonka, CERN BE-ICS
* @date 2023
* @copyright (c) CERN All rights reserved
*/

#uses "fwGeneral/fwPanelUtils.ctl"
#uses "classes/fwStdLib/FwException.ctl"

/** Wrapper over WinCC OA panels and modules

    Note: this class should support the panels that could
        be opened in various contexts
        - as standalone panels
        - as reference panels
        - as panels embedded e.g. in a tab widget with
            embedded modules
*/
class FwPanel
{
    // to avoid ambiguity such as this.panelName (which might suggest the use of shape property or object member), members names start with "_"
    string _panelName;        // by default: myPanelName()
    string _moduleName;       // by default: myModuleName()
    string _pnlFileName;  // the file of the panel
    string _refName;      // reference name; it prefixes the names of shapes inside references; empty for non-refs
    shape _pnlShape;          // use whenever possible; allows to work with "self" e.g. for tabs, where module/panel name are invalid

    int _debugLevel;

    public string getPanelName()  { return _panelName;}
    public string getModuleName() { return _moduleName;}
    public string getRefName()        { return _refName;}
    public string getPnlFileName() { return _pnlFileName;}
    public shape  getPnlShape()   { return _pnlShape;}

    public int    getDebugLevel() {return _debugLevel;}
    public void   setDebugLevel(int lvl) {_debugLevel=lvl;}

    // NOTE! For certain cases such as the TAB widget, the actual
    // shape of the panel cannot be addressed by module/panel names.
    // The myPanelName() in it would indicate the shape in which the
    // tab widget is... The only way to access it properly is to
    // use the "self" keyword, passed to the constructor of FwPanel.
    //
    // For other cases, use the factory methods below
    public FwPanel(shape panelShape = 0)
    {
        if (panelShape == 0) return; // the case for default constructor

        // sanity check if we have a panel shape...
        dyn_string scriptables;
        getValue(panelShape, "scriptables", scriptables);
        FwException::assert(scriptables.contains("A panelFileName(string)") || scriptables.contains("R panelFileName(string)"), "The shape passed to FwPanel constructor is probably not a panel (missing panelFileName property)");
        this._pnlShape  = panelShape;

        // note! For RefPanel shapes we will not be able to get the moduleName as the property does not exist
        // the best we could do is to tell that this is the current module...
        if (dynContains(scriptables, "R moduleName(string)")) {
            getValue(panelShape, "moduleName", this._moduleName);
        } else {
            this._moduleName = myModuleName();
        }

        if (dynContains(scriptables, "R refName(string)")) {
            string rName;
            getValue(panelShape, "refName", this._refName);
        }

        this._panelName = myPanelName();

        getValue(panelShape, "panelFileName", this._pnlFileName);
    }

    public void panelOff()
    {
        if (isPanelOpen(this._panelName, this._moduleName)) PanelOffModule(this._panelName, this._moduleName);

        this._panelName = "";
        this._moduleName = "";
        this._pnlFileName = "";
        this._refName = "";
        this._pnlShape = 0;
    }

    public static shared_ptr<FwPanel> getFromNames(string aPanelName = "", string aPnlFileName = "", string aModuleName = "", string aRefName = "")
    {

        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be instantiated in the UI manager");

        shared_ptr<FwPanel> newPnl = new FwPanel();

        newPnl._panelName   = (aPanelName != "")   ? aPanelName   : myPanelName();
        newPnl._moduleName  = (aModuleName != "")  ? aModuleName  : myModuleName();
        newPnl._refName     = aRefName;
        newPnl._pnlFileName = aPnlFileName;

        if (waitPanelOpen(newPnl._panelName, newPnl._moduleName, 0)) {
            // check if panel is already open...
            newPnl._pnlShape    = getShape(newPnl._moduleName + "." + newPnl._panelName + ":");
            if (aPnlFileName == "") getValue(newPnl._pnlShape, "panelFileName", newPnl._pnlFileName);
            if (aRefName != "") {
                // validate refName -> there needs to be shapes such as "MyRef.something"
                dyn_string allShapeNames = getShapes(newPnl._moduleName, newPnl._panelName, "visible", true);
                FwException::assertDynNotEmpty(dynPatternMatch(aRefName + "."), "Reference " + aRefName + " not found in panel " + aPnlFileName + "(" + aModuleName + "." + aPanelName + ")");
            }
        }
        return newPnl;
    }

    public static shared_ptr<FwPanel> openRootPanel(string aPanelName, string aPnlFileName,
                                                    string aModuleName = "", dyn_string dollarParams = makeDynString())
    {
        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be used in the UI manager");

        if (aModuleName == "") aModuleName = myModuleName();

        waitModuleOpen(aModuleName);
        RootPanelOnModule(aPnlFileName, aPanelName, aModuleName, dollarParams);
        bool isPanelOpen = waitPanelOpen(aPanelName, aModuleName);
        FwException::assert(isPanelOpen, "Time out on opening panel " + aPanelName + " in module " + aModuleName);

        shared_ptr<FwPanel> pnl = getFromNames(aPanelName, aPnlFileName, aModuleName);
        return pnl;
    }

    public static shared_ptr<FwPanel> openChildPanel(string aPanelName, string aPnlFileName,
                                                     string aModuleName = "", dyn_string dollarParams = makeDynString())
    {
        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be used in the UI manager");

        string modName = aModuleName;
        if (modName == "") modName = myModuleName();

        waitModuleOpen(modName);

        // guarantee the unique name for the panel...
        if (isPanelOpen(aPanelName, modName)) {
            for (int i = 2; i <= 1000; i++) {
                string newPanelName = aPanelName + " " + i;
                if (!isPanelOpen(newPanelName)) {
                    aPanelName = newPanelName;
                    break;
                }
            }
        }

        if (aModuleName == "") {
            ChildPanelOnCentral(aPnlFileName, aPanelName, dollarParams);
        } else {
            // we emulate the "Central" option for the module, based on
            // the code of ChildPanelOnCentral();
            //---------------------
            dyn_int di = getPanelSize(aPnlFileName);
            float factor, initFactor;
            int pBreite, pHoehe;
            getZoomFactor(factor, modName);
            panelSize(myPanelName(), pBreite, pHoehe, (factor == 1)); // current module... best we could do :-(
            getInitialZoomFactor(initFactor);
            int x = ((pBreite) - (di[1] * initFactor / factor)) / 2;
            int y = ((pHoehe) - (di[2] * initFactor / factor) - 20) / 2;
            //--------------------
            ChildPanelOnModule(aPnlFileName, aPanelName, modName, dollarParams, x, y);
        }

        bool isOpen = waitPanelOpen(aPanelName, modName);
        FwException::assert(isOpen, "Time out on opening panel " + aPanelName + " in module " + modName);

        shared_ptr<FwPanel> pnl = getFromNames(aPanelName, aPnlFileName, modName);
        return pnl;
    }

    /* Opend a child panel waiting for the return value; it works in the current module/panel

       @returns false if the dialog panel was closed (cancelled) without returning a value
     **/
    public static bool openDialogReturnData(string aPanelName, string aPnlFileName, dyn_string dollarParams, dyn_float &df, dyn_string &ds)
    {
        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be used in the UI manager");

        string modName = myModuleName();

        // guarantee the unique name for the panel...
        if (isPanelOpen(aPanelName, modName)) {
            for (int i = 2; i <= 1000; i++) {
                string newPanelName = aPanelName + " " + i;
                if (!isPanelOpen(newPanelName)) {
                    aPanelName = newPanelName;
                    break;
                }
            }
        }
        ChildPanelOnCentralReturn(aPnlFileName, aPanelName, dollarParams, df, ds);
        return (df.count() > 0 || ds.count()>0);
    }

    public static bool openDialogReturnBool(string aPanelName, string aPnlFileName, dyn_string dollarParams)
    {
        dyn_float df;
        dyn_string ds;
        bool gotData=openDialogReturnData(aPanelName, aPnlFileName, dollarParams, df, ds);
        if (!gotData) return false;
        return (df.first() > 0.0);
    }

    public static string openDialogReturnText(string aPanelName, string aPnlFileName, dyn_string dollarParams)
    {
        dyn_float df;
        dyn_string ds;
        bool gotData=openDialogReturnData(aPanelName, aPnlFileName, dollarParams, df, ds);
        if (!gotData) return "";
        return strjoin(ds, ","); // just in case we have a ds filled with data...
    }

    public static float openDialogReturnNum(string aPanelName, string aPnlFileName, dyn_string dollarParams)
    {
        dyn_float df;
        dyn_string ds;
        bool gotData=openDialogReturnData(aPanelName, aPnlFileName, dollarParams, df, ds);
        if (!gotData) return 0;
        return df.first();
    }


    public mixed callWithReturn(string pnlMethod, ...)
    {
        va_list vaParams;
        vector<void> params;
        int nParams = va_start(vaParams);

        for (int i = 0; i < nParams; i++) params.append(va_arg(vaParams));

        va_end(vaParams);
        return invokeMethod(pnlMethod, params, true);
    }

    public void call(string pnlMethod, ...)
    {
        va_list vaParams;
        vector<void> params;
        int nParams = va_start(vaParams);

        for (int i = 0; i < nParams; i++) params.append(va_arg(vaParams));

        va_end(vaParams);
        invokeMethod(pnlMethod, params, false);
    }

    /* Invokes a method of the OO-panel.

      @param[in] pnlMethod: the name of a public method of the OO panel
      @param[in] params : specifies the parameters to be passed to the method.
          by default (or passing empty vector made with makeVec()) call will be
          issued with no parameters.
          If one wants to pass more parameters, they should be put into a
          vector<void>, ie. using makeVector() - up to 5 parameters are supported.



    **/
    public mixed invokeMethod(string pnlMethod, mixed params = makeVector(), bool wantRetVal = false)
    {

        FwException::assert(_pnlShape != 0, "Panel shape not initialized");
        FwException::assert(hasMethod(_pnlShape, pnlMethod), "Panel " + this._panelName + " has no method " + pnlMethod);

        // we use eval/execScript to be able to treat "any" number of parameters passed in the vector...
        string theScript;
        theScript   += "mixed main(shape pnlObj, string pnlMethod, mixed params)";
        theScript   += "{              ";
        theScript   += "  mixed retVal;";
        theScript   += "  try {";
        if (wantRetVal) {
            theScript += "    retVal = ";
        }
        theScript   += "    invokeMethod( pnlObj ";
        theScript   += "	    ,\"" + pnlMethod + "\"";

        if (getType(params) != VECTOR_VAR) {
            theScript += "    ,params";   // pass params as they are
        } else {
            if (getTypeName(params) != "vector<void>") {
                theScript += "  ,params";   // pass params as they are
            } else {
                for (int i = 0; i < params.count(); i++) {
                    theScript += ",params.at(" + i + ")";
                }
            }
        }
        theScript    +=  "     );";
        theScript    +=  "  } catch { ";
        theScript    +=  "      retVal=getLastException();";
        theScript    +=  "  } finally {";
        theScript    +=  "    return retVal;";
        theScript    +=  "  }";
        theScript    +=  "}";

        mixed retVal;
        //DebugTN(__FUNCTION__,"SCRIPT IS",theScript);
        evalScript(retVal, theScript, makeDynString(), this._pnlShape, pnlMethod, params);

        if (getType(retVal) == DYN_ERRCLASS_VAR) {
            dyn_string stkTrace = getErrorStackTrace(retVal);
            dynAppend(stkTrace, " -- VIRTUAL STACK TRACE--- at invokeMethod()");
            dynAppend(stkTrace, getStackTrace());
            fwThrowWithStackTrace(retVal, stkTrace);
        }

        if (wantRetVal) return retVal;

        // else:
        return 0; // success...
    }

    public void connectFuncName(string eventName, string cbFunction,  mixed userData = nullptr)
    {
        if (getType(userData) == POINTER_VAR && equalPtr(userData, nullptr)) {
            uiConnect(cbFunction, this._pnlShape, eventName);
        } else {
            uiConnectUserData(cbFunction, userData, this._pnlShape, eventName);
        }
    }

    public void connect(string eventName, function_ptr cbFunction,  mixed userData = nullptr)
    {
        if (getType(userData) == POINTER_VAR && equalPtr(userData, nullptr)) {
            uiConnect(cbFunction, this._pnlShape, eventName);
        } else {
            uiConnectUserData(cbFunction, userData, this._pnlShape, eventName);
        }
    }

    public void connectObject(string eventName, mixed cbObject, function_ptr cbMethod, mixed userData = nullptr)
    {
        if (getType(userData) == POINTER_VAR && equalPtr(userData, nullptr)) {
            uiConnect(cbObject, cbMethod, this._pnlShape, eventName);
        } else {
            uiConnectUserData(cbObject, cbMethod, userData, this._pnlShape, eventName);
        }
    }

    public void setFocus(string shapeName)
    {
        setInputFocus(this._moduleName, this._panelName, shapeName);
    }

    /* Wait for module to open

    **/
    public static bool waitModuleOpen(string aModuleName, int waitMsec = 3000)
    {
        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be used in the UI manager");

        for (int i = 0; i < waitMsec / 50; i++) {
            if (isModuleOpen(aModuleName)) return true;
            delay(0, 50);
        }
        return (isModuleOpen(aModuleName));
    }

    public static bool waitPanelOpen(string aPanelName, string aModuleName = myModuleName(), int waitMsec = 3000)
    {
        FwException::assert(myManType() == UI_MAN, "FwPanel class may only be used in the UI manager");
        bool moduleIsOpen = waitModuleOpen(aModuleName, waitMsec);
        FwException::assert(moduleIsOpen, "Module " + aModuleName + " is not open");

        for (int i = 0; i < waitMsec / 50; i++) {
            if (isPanelOpen(aPanelName, aModuleName)) return true;
            delay(0, 50);
        }
        return (isPanelOpen(aPanelName, aModuleName));
    }

    /** Returns the refShapes of this panel (visible ones)
          the mapping key's are names,
          the mapping values are refPanel shapes

          Note that you could instantiate a FwPanel based on the obtained
          shape and e.g. invoke its methods.
    */
    public mapping getRefShapes()
    {
        // out of the list of all shapes returned by getShapes(), we will derive the references
        // by finding those that have a child shape (separated by a dot); there seems to be
        // no other practical way to detect them, unfortunately.
        // We need to treat being INSIDE a reference already and then strip our own reference
        // name from the reported shape name, such that we report only the "local" name addressable
        // from our panel ("global" addressing may be impossible for OO panels, etc).

        //DebugTN(__FUNCTION__);
        dyn_string shapeNames = getShapes(this._moduleName, this._panelName, "visible", true);
        //DebugTN("OUR refName is", this._refName);
        //DebugTN("SHAPE NAMES", shapeNames);

        mapping refShapes;

        for (int i = 0; i < shapeNames.count(); i++) {
            string shName = shapeNames.at(i);

            // if we are inside a reference panel we need to strip our refName from the
            // complete shape and address with solely the "local" name.
            if (_refName != "") {
                int idx = shName.indexOf(_refName + ".");

                if (idx >= 0) {
                    shName = shName.mid(_refName.length() + 1); // truncate our refName...
                } else {
                    // the prefix was not found, which means the shape is not in our REF
                    continue  ;
                }
            }

            // Out of the rest we will find the refs by knowing they contain a dot,
            // and then we will know that the thing before the dot is our ref name
            //DebugTN("###Processing",shapeNames.at(i),shName);
            int idx = shName.indexOf(".");

            if (idx < 0) continue; // no child element -> it is not a reference.

            string refName = shName.left(idx);

            if (refShapes.contains(refName)) continue; // skip if we already have it

            // under normal circumstances it should be found just by the local name...
            // it also applies if we are in a reference, as we cut this part already.
            // but this will only work for our own module/panel, and not across
            if (shapeExists(refName)) {
                refShapes[refName] = getShape(refName);
            } else if (this._refName != "") {
                // NEEDS A REVIEW - NOT SURE IF WE COULD HAVE ANY OF THESE CASES
                if (shapeExists(this._moduleName + "." + this._panelName + ":" + this._refName + "." + refName)) {
                    // the case for reference inside a reference...
                    // it may indeed be nested or it could be flat in our panel (because it is not a fully OO-REF?)
                    refShapes[refName] = getShape(this._moduleName + "." + this._panelName + ":" + this._refName + "." + refName);
                } else {
                    //DebugTN("WARNING IN "+__FUNCTION__,"Case of ref-in-ref for this._refName="+this._refName+",refName="+refName+", but shape does not exist:"+this._moduleName+"."+this._panelName+":"+this._refName+"."+refName);
                    // we may then actually want to skip the this._refName!
                    if (shapeExists(this._moduleName + "." + this._panelName + ":" + refName)) {
                        //DebugTN("BUT WE HAVE",this._moduleName+"."+this._panelName+":"+refName);
                        refShapes[refName] = getShape(this._moduleName + "." + this._panelName + ":" + refName);
                    }
                }
            } else {
                // NEEDS A REVIEW - probably needed to address across the modules/panels
                refShapes[refName] = getShape(this._moduleName + "." + this._panelName + ":" + refName);
            }
        }
        return refShapes;
    }

    /** Returns all the shapes of this panel not being references. One may filter for the
      shapes of particular type

      @returns the mapping key's are names, the mapping values are shape-vars

      Note that if this is a refPanel then the returned shapes are of type PanelRefShape,
      which means a reference to _any_ other shape. This means that one may still invoke
      e.g. ``` getValue(shape,"shapeType")``` and get the actual type, or perform any
      supported getValue/setValue call to any property or method.

      @param shapeTypeFilter allows to search for shapes of particular types; a comma-separated list of names
          may be specified, or "*" meaning all known
    */
    public mapping getStdShapes(string shapeTypeFilter = "*")
    {
        mapping stdShapes;

        const dyn_string knownShapeTypes = makeDynString("PRIMITIVE_TEXT", "LINE", "RECTANGLE", "ELLIPSE", "ARC", "POLYGON", "PUSH_BUTTON", "TEXT_FIELD", "CLOCK", "SELECTION_LIST",
                                                         "RADIO_BOX", "CHECK_BOX", "SPIN_BUTTON", "COMBO_BOX", "TREND", "TABLE", "CASCADE_BUTTON", "BAR_TREND", "TAB", "ACTIVE_X",
                                                         "FRAME", "PIPE", "DP_TREE", "TEXT_EDIT", "SLIDER", "THUMB_WHEEL", "PROGRESS_BAR", "TREE", "DPTYPE", "LCD", "ZOOM_NAVIGATOR",
                                                         "EMBEDDED_MODULE", "SCHEDULER_EWO", "Label", "Calendar", "ScriptEdit", "AttentionEffect_ewo", "BarChart3D_ewo", "DateTimeEdit_ewo",
                                                         "DialGauge_ewo", "GisViewer_ewo", "PictureFlow_ewo", "Scheduler_ewo", "ToggleSwitch_ewo", "WebView_ewo");
        dyn_string selectedShapeTypes = strsplit(shapeTypeFilter, ",");

        if (shapeTypeFilter == "*") selectedShapeTypes = knownShapeTypes;

        for (int i = 0; i < selectedShapeTypes.count(); i++) {
            string shType = selectedShapeTypes.at(i);
            FwException::assertInSet(shType, knownShapeTypes, "Invalid shape type:" + shType);
            // get all the shapes of the particular type...
            dyn_string matchingShapes = getShapes(this._moduleName, this._panelName, "shapeType", shType);

            for (int j = 0; j < matchingShapes.count(); j++) {
                shape s = 0;
                string shName = matchingShapes.at(j);

                if (this._refName != "") {
                    s = getShape(this._moduleName, this._panelName, shName);
                    // strip the prefixing refName to make things easier...
                    shName.replace(this._refName + ".", "");
                } else {
                    s = getShape(this._pnlShape, shName);
                }
                stdShapes[shName] = s;
            }
        }
        return stdShapes;
    }


    /**

      @param bindOptions - list of instructions for binding. Each of binding has a format
          "{memberSpec} => {target}". If target is ommitted (together with the "=>" part) then
          the binding will happen to the default property of widget, based
          on its type; for ref panels it will attempt to call the setData() method.
          The "{memberSpec}" may have the following formats:
          - "member1" - auto-bind the field "member1" following default conventions
          - "!member1" - exclude the field "member1" - to be combined with "*"
          - "@TYPE=TEXT_FIELD" - bind all the members correspoding to widgets of type TEXT_FIELD
          - "*"       - auto-bind everything (except those excluded)
          The {target} is either the name of the property, which will be set through setValue, or
          if it includes the "()" after the name then it is the function

          - "@ALL" as member spec passes the whole data "as is" (see note below)

          ?? maybe we could also allow to bind with some literals (evalScript then?)


      Example: not everything implemented just yet...
      ```{.ctl}
          dyn_string bindOptions = makeDynString (
              "@TYPE=TEXT_FIELD => .text", // bind .text for all the textfields (default would do this anyway
              "!@TYPE=COMBO_BOX",         // remove all that would point to combo box
              "!_id",                     // exclude the _id, even if it would be bound by @TYPE or *
              "_tag =>",                  // exclude the _tag, ie. bind to nothing
              "_alarmColor => user.backCol", // map the _alarmColor to a particular widget's background!
              "expList => experiments.items", // map the expList to the item of the comboBox
              "exp => experiment.text", // set the value of the combo box...
              "userId => setUser()", // userId will be set by invoking the setUser(userId) method of the panel
              "*", // for all remaining ones, use the default
              "prop1,prop2,prop3 => setData(prop1,prop2,prop3)", // bind three members to one invocation of setData.
              "@START => table.deleteAllRows()",  // clear the table at the beginning
              "@START => table.enabled(false)",   // and disable it
              "@END => table.enabled(true)        // and at the end enable it...
              "@ALL => myRef.setData() // pass the complete data through setData() method of a refObject
          );
      ```

      for @TYPE we have a special value PANEL_REF which is not a recognized WinCC OA shape type, yet we treat it

      The instructions given in bindOptions should be executed in sequence


    Note that function supports "typed" nullptr passed as obj
    and clears the matching widgets in this case
    **/
    public void setWidgetsFromObject(mixed obj, dyn_string bindOptions = makeDynString("*"))
    {
        // NOTE: We may not use const mixed& here as it will cause a type mismatch...

        // 1) obj may not be shared_ptr<void> because we would loose the "typed-null" information! must be mixed!
        // 2) we should check it this is actual a shared_ptr or a object and act accordingly!
        // 3) we may also try to support e.g. mapping at the same time!

        // FWCORE-3546
        // REFACTOR: CtrlOOUtils fwGetClass() should implement getting the
        //           type for "typed nullptr"; getTypeName() does it...
        string className = getTypeName(obj); // returns eg. "shared_ptr<MyObject>"
        strreplace(className, "shared_ptr", "");
        strreplace(className, "vector", "");
        strreplace(className, "<", "");
        strreplace(className, ">", "");
        //
        FwException::assert(className != "void", "object mut be passed through fully-typed pointer, not shared_ptr<void>");
        FwException::assert(className != "mixed", "obj must have a concrete type (not mixed); maybe wanted ::clearPanel() instead?");

        dyn_string bindInstructions = expandBindOptionsToInstructions(bindOptions, className, "set");

        if (this._debugLevel & 4) {
            DebugTN("----BIND INSTRUCTION----");
            DebugTN(bindInstructions);
            DebugTN("-----------------");
        }
        mapping refShapes = this.getRefShapes();

        // and now execute the bind instructions...
        for (int i = 0; i < bindInstructions.count(); i++) {
            string instr = bindInstructions.at(i);
            vector<string> instrParts = instr.split(":");
            string member = instrParts.first();
            string property = instrParts.last();
            // support for chekboxes, etc that need an extra "index" - separated by #
            // eg. bind instruction _connected:state#0 referring to 0'th index of a checkbox
            string extraIdx = "";
            int idx = property.indexOf("#");

            if (idx >= 0) {
                extraIdx = property.mid(idx + 1);
                property = property.left(idx);
            }

            shape widget;
            int idx = property.indexOf(".");
            string widgetName;
            bool widgetIsRefPanel = false;

            if (idx < 0) {
                // property name matching the widget name
                widgetName = member;
                widget = getShape(this._moduleName, this._panelName, widgetName);
            } else {
                // widget is in the prefix!
                vector<string> targetVec = property.split(".");
                string widgetName = targetVec.first();

                if (refShapes.contains(widgetName)) {
                    widget = refShapes[widgetName];
                    widgetIsRefPanel = true;
                } else {
                    widget = getShape(this._moduleName, this._panelName, widgetName);
                }

                property = targetVec.last();
            }

            mixed value;

            if (getType(obj) != POINTER_VAR || !equalPtr(obj, nullptr)) {
                value = fwGetMember(obj, member);
            } else {
                // lists, etc may require this to be a dyn_ list
                if (property == "items") value = makeDynMixed();
            }

            if (property.endsWith("()")) {
                string pnlMethod = property;
                strreplace(pnlMethod, "()", "");

                //widget=refShapes[member];
                if (widgetIsRefPanel) {
                    FwPanel refPnl = FwPanel(widget);
                    //DebugTN("###### callREF",refPnl,pnlMethod,value);
                    refPnl.call(pnlMethod, value);
                } else {
                    //DebugTN("######( call",pnlMethod,value);
                    this.call(pnlMethod, value);
                }
            } else {
                if (extraIdx == "") {
//                        DebugTN("###### setValue",widgetName,widget,property,value);
                    setValue(widget, property, value);
                } else {
//                        DebugTN("###### setValue",widgetName,widget,property,extraIdx,value);
                    setValue(widget, property, extraIdx, value);
                }
            }
        }

    }

    public void setObjectFromWidgets(mixed &obj, dyn_string bindOptions = makeDynString("*"))
    {

        //DebugTN(__FUNCTION__);
        string className = getTypeName(obj); // returns eg. "shared_ptr<MyObject>"
        strreplace(className, "shared_ptr", "");
        strreplace(className, "vector", "");
        strreplace(className, "<", "");
        strreplace(className, ">", "");
        //
        FwException::assert(className != "void", "object mut be passed through fully-typed pointer, not shared_ptr<void>");
        dyn_string bindInstructions = expandBindOptionsToInstructions(bindOptions, className, "get");

//      DebugTN("----BIND INSTRUCTION----");
//      DebugTN(bindInstructions);
//      DebugTN("-----------------");

        mapping refShapes = this.getRefShapes();

        // and now execute the bind instructions...
        for (int i = 0; i < bindInstructions.count(); i++) {
            string instr = bindInstructions.at(i);
            vector<string> instrParts = instr.split(":");
            string member = instrParts.first();
            string property = instrParts.last();
            // support for chekboxes, etc that need an extra "index" - separated by #
            // eg. bind instruction _connected:state#0 referring to 0'th index of a checkbox
            string extraIdx = "";
            int idx = property.indexOf("#");

            if (idx >= 0) {
                extraIdx = property.mid(idx + 1);
                property = property.left(idx);
            }

            shape widget;
            int idx = property.indexOf(".");
            string widgetName;
            bool widgetIsRefPanel = false;

            if (idx < 0) {
                // property name matching the widget name
                widgetName = member;
                widget = getShape(this._moduleName, this._panelName, widgetName);
            } else {
                // widget is in the prefix!
                vector<string> targetVec = property.split(".");
                string widgetName = targetVec.first();

                if (refShapes.contains(widgetName)) {
                    widget = refShapes[widgetName];
                    widgetIsRefPanel = true;
                } else {
                    widget = getShape(this._moduleName, this._panelName, widgetName);
                }

                property = targetVec.last();
            }

            mixed value;

            if (property.endsWith("()")) {
                string pnlMethod = property;
                strreplace(pnlMethod, "()", "");

                //widget=refShapes[member];
                if (widgetIsRefPanel) {
                    FwPanel refPnl = FwPanel(widget);
//                  DebugTN("###### callREF",refPnl,pnlMethod,value);
                    refPnl.call(pnlMethod, value);
                } else {
//                  DebugTN("######(DISABLED) call",pnlMethod,value);
//                  this.call(pnlMethod,value);
                }
            } else {
                if (extraIdx == "") {
//                        DebugTN("###### getValue",widgetName,widget,property,value);
                    getValue(widget, property, value);
                } else {
//                        DebugTN("###### getValue",widgetName,widget,property,extraIdx,value);
                    getValue(widget, property, extraIdx, value);
                }
            }

            fwSetMember(obj, member, value);
        }
    }


//----------------------------------------------------------------------
    /** Used internally by @ref setObjectFromWidgets and @ref setWidgetsFromObject

      On input it receives the bindOptions: a list of declarative bindings,
      and the name of the class for the viewModel (or model) so that to retrieve
      all its members.

      Returns the list of "bind instructions" in form of "MEMBER:WIDGETPROP",
      in an expanded form, ready to be processed one by one.

          @param mode - specifies the direction (namely to determine setData() /getData()),
              could be either "get" or "set"

    */
    protected dyn_string expandBindOptionsToInstructions(dyn_string bindOptions, string className, string mode)
    {
        FwException::assert((mode == "get" || mode == "set"), "wrong mode:" + mode + ", supported are get or set");
        // FWCORE-3545: until it is fixed, we need to recurse the complete class hierarchy ourselves to look for members
        string classToScan = className;
        dyn_string allMembers;

        while (classToScan != "") {
            dyn_string memberNames = fwClassMemberVars(classToScan);
            dynAppend(allMembers, memberNames);
            classToScan = fwGetBaseClass(classToScan);
        }

//DebugTN("[#]"+__FUNCTION__,bindOptions,this);


//DebugTN("MEMBER VARS:",allMembers);
//DebugTN(obj);
        mapping refShapes = this.getRefShapes();

        //dyn_string allShapes=getShapes(this._moduleName, this._panelName,"visible",true);
        dyn_string allShapes = getShapes(this._moduleName, this._panelName, "", true);

//DebugTN("ALL SHAPES:",allShapes);
//DebugTN("RefShapes",refShapes);
        // build the list of wildcards and their exclusions

        // explicit wildcard (*)
        dyn_string membersWithDefaults;
        int idx = bindOptions.indexOf("*");

        if (idx >= 0) {
            membersWithDefaults = allMembers;
            bindOptions.removeAt(idx);
        }

        // explicit inclusions with @TYPE
        for (int i = 0; i < dynlen(bindOptions); i++) {
            string opt = bindOptions.at(i);
            strreplace(opt, " ", "");

            if (!opt.startsWith("@TYPE=")) continue;

            if (opt.contains("=>")) continue; // skip one with generic instructions

            strreplace(opt, "@TYPE=", "");

            // what we have in the opt is the SHAPE_TYPE...
            // Special treatment for PanelRef:
            if (opt == "PANEL_REF") {
                dyn_string refShapeNames = mappingKeys(refShapes);

                for (int j = 1; j <= dynlen(refShapeNames); j++) {
                    if (allMembers.contains(refShapeNames[j])) dynAppend(membersWithDefaults, refShapeNames[j]);
                }
            } else {

                // get all the shapes of the particular type...
                mapping shapesOfType = getStdShapes(opt);
                dyn_string matchingShapeNames = mappingKeys(shapesOfType);

                for (int j = 1; j <= dynlen(matchingShapeNames); j++) {
                    if (allMembers.contains(matchingShapeNames[j])) dynAppend(membersWithDefaults, matchingShapeNames[j]);
                }
            }

            bindOptions.removeAt(i--);
        }

        // explicit exclusions with "!"
        for (int i = 0; i < dynlen(bindOptions); i++) {
            string opt = strltrim(strrtrim(bindOptions.at(i)));

            if (opt.startsWith("!")) {
                string member = strltrim(opt, "!");
                int idx = membersWithDefaults.indexOf(member);

                if (idx >= 0) membersWithDefaults.removeAt(idx);

                bindOptions.removeAt(i--);
            }
        }

        // explicit exclusions with !@TYPE
        for (int i = 0; i < dynlen(bindOptions); i++) {
            string opt = bindOptions.at(i);
            strreplace(opt, " ", "");

            if (!opt.startsWith("!@TYPE=")) continue;

            //if (opt.contains("=>")) continue; // skip one with generic instructions
            strreplace(opt, "!@TYPE=", "");

            // what we have in the opt is the SHAPE_TYPE...
            // Special treatment for PanelRef:
            if (opt == "PANEL_REF") {
                dyn_string refShapeNames = mappingKeys(refShapes);

                for (int j = 1; j <= dynlen(refShapeNames); j++) {
                    if (allMembers.contains(refShapeNames[j])) {
                        idx = membersWithDefaults.indexOf(refShapeNames[j]);
                        if (idx >= 0) membersWithDefaults.removeAt(idx);
                    }
                }
            } else {
                mapping shapesOfType = getStdShapes(opt);
                dyn_string matchingShapeNames = mappingKeys(shapesOfType);

                for (int j = 1; j <= dynlen(matchingShapeNames); j++) {
                    if (allMembers.contains(matchingShapeNames[j])) {
                        int idx = membersWithDefaults.indexOf(matchingShapeNames[j]);
                        if (idx >= 0) membersWithDefaults.removeAt(idx);
                    }
                }
            }

            bindOptions.removeAt(i--);
        }

        // explicit inclusion by name, yet with no particular instructions
        for (int i = 0; i < dynlen(bindOptions); i++) {
            string opt = bindOptions.at(i);
            strreplace(opt, " ", "");

            if (opt.contains("=>")) continue;

            membersWithDefaults.append(opt);
            bindOptions.removeAt(i--);
        }

        dyn_string bindInstructions;

        // Process all the default bindings...
        for (int i = 1; i <= dynlen(membersWithDefaults); i++) {
            string member = membersWithDefaults[i];

            if (refShapes.contains(member)) {
//DebugTN("###REF: "+__FUNCTION__,mode,"->",member);
                // we found a refShape
                string method = (mode == "set") ? "setData" : "getData";

//DebugTN(method);
                if (hasMethod(refShapes[member], method)) dynAppend(bindInstructions, "" + member + ":" + member + "." + method + "()");

                continue;
            }

            shape s = 0;

            if (this._refName != "") {
                if (! allShapes.contains(this._refName + "." + member)) {
                    //DebugTN("Skipping "+member+" in "+this._refName);
                    continue;
                }

                s = getShape(this._moduleName, this._panelName, this._refName + "." + member);
                //DebugTN("Got member "+member+" for my ref "+this._refName,s);
            } else {
                if (! allShapes.contains(member)) continue;
                s = getShape(this._pnlShape, member);
            }

            if (s != 0) {
                // we found a shape that matches
                string shType = s.shapeType();

                switch (s.shapeType) {
                    case "TEXT_FIELD":
                    case "TEXT_EDIT":
                    case "PRIMITIVE_TEXT":
                    case "CASCADE_BUTTON":
                    case "Label":
                    case "COMBO_BOX":
                        dynAppend(bindInstructions, "" + member + ":" + "text");
                        break;

                    case "SPIN_BUTTON":
                        dynAppend(bindInstructions, "" + member + ":" + "value");
                        break;

                    case "DateTimeEdit_ewo":
                        dynAppend(bindInstructions, "" + member + ":" + "date");
                        break;

                    case "SELECTION_LIST":
                        dynAppend(bindInstructions, "" + member + ":" + "items");
                        break;

                    case "CHECK_BOX":
                    case "RADIO_BOX":
                        dynAppend(bindInstructions, "" + member + ":" + "state#0");
                        break;

                    default:
                        DebugTN(__FUNCTION__, "No default handling for shape " + member + " (" + shType + ")");
                        break;
                }

                //DebugTN("####",this._pnlShape,member,s);
            }
        }

        // only now we should process the specific instructions and replace the entries given above...
        for (int i = 0; i < dynlen(bindOptions); i++) {
            string opt = bindOptions.at(i);
            strreplace(opt, " ", "");
            vector<string> bindOptPair = opt.split("=>");
            string member = bindOptPair.first();
            string target = bindOptPair.last();
            /////////  WE SHOULD REPLACE THE DEFAULTS, BUT APPEND NEW ONES
            dynAppend(bindInstructions, "" + member + ":" + target);
            bindOptions.removeAt(i--);
        }

        return bindInstructions;
    }


    // IT THROWS! REMEMBER TO TRY-CATCH!
    // but not yet fully implemented
    public void setEditableWidgets(dyn_string widgetNames = makeDynString())
    {
        string supportedShapeTypes = "TEXT_FIELD,TEXT_EDIT,COMBO_BOX,DateTimeEdit_ewo";
        mapping allShapes = this.getStdShapes(supportedShapeTypes);
        dyn_string allShapeNames = mappingKeys(allShapes);
        // prepare the list of *all* relevant shapes in the panel
        // everything that is a part of a refPanel is excluded -> should be treated by the refPanel itself...
        dyn_string shapes;
        dyn_string propNames;
        dyn_mixed propValues;

        for (int i = 0; i < allShapes.count(); i++) {
            string shName = mappingGetKey(allShapes, i + 1);

            if (shName.contains(".")) continue; // skip shapes within ref objects

            dynAppend(shapes, shName);
            shape s = allShapes[shName];
            string shType;
            getValue(s, "shapeType", shType);
            FwException::assertInSet(shType, strsplit(supportedShapeTypes, ','), "Unsupported shape type " + shType + " for shape" + shName);

            switch (shType) {
                case "TEXT_FIELD":
                case "COMBO_BOX" : propNames.append("editable"); propValues.append(true); break;

                case "TEXT_EDIT" : propNames.append("readOnly"); propValues.append(false); break;

                case "DateTimeEdit_ewo" : propNames.append("readOnly"); propValues.append(false); break;

                default          : propNames.append("");         propValues.append(true); break; // should anyway be catched by the assert above...
            }
        }

//DebugTN(__FUNCTION__,"SHAPES",shapes);
//DebugTN(__FUNCTION__,"WIDGETS",widgetNames);
        // start with making everything NON-EDITABLE first (we invert what we have in propValues)
        for (int i = 0; i < shapes.count(); i++) {
            if (propNames.at(i) == "") continue;

            bool val = propValues.at(i);

            // if it is not in the list of widgetNames then disable rather than enable
            if (!widgetNames.contains(shapes.at(i))) val = (!val);

            //DebugTN(__FUNCTION__,_moduleName,_panelName,shapes.at(i), propNames.at(i),val);
            setValue(shapes.at(i), propNames.at(i), val);
        }
    }

    public bool waitPanelReturnValues(dyn_float &df, dyn_string &ds)
    {
        dynClear(df);
        dynClear(ds);

        // when panel name is not set it is taken from the file name...
        string panelName=_panelName;
        if (panelName=="") panelName=_pnlFileName;

        time timeout=900L; // 86400L ?
        string myUIDP="_Ui_" + myManNum();
        dyn_string dpsWait = makeDynString(myUIDP + ".PanelOff.ModuleName:_original.._value",
                                           myUIDP + ".PanelOff.PanelName:_original.._value");
        dyn_anytype valuesWait=makeDynString(_moduleName, panelName);
        dyn_string dpsRetVals = makeDynString(myUIDP + ".ReturnValue.Float:_original.._value",
                                              myUIDP + ".ReturnValue.Text:_original.._value");
        dyn_anytype results;
        //DebugTN("We will wait for values");
        //DebugTN(dpsWait, valuesWait);
        int rc = dpWaitForValue(dpsWait, valuesWait, dpsRetVals, results, timeout);
        FwException::checkLastError();
        if (rc!=0) return false;
        if (results.count()!=2) return false;

        df=results[1];
        ds=results[2];
        return true;
    }

    public string waitPanelReturnString(string cancelValue="")
    {
        string result=cancelValue;
        dyn_float df;
        dyn_string ds;
        bool ok=waitPanelReturnValues(df, ds);
        if (ok && ds.count()>=1) result=ds.first();
        return result;
    }

    public bool waitPanelReturn()
    {
        dyn_float df;
        dyn_string ds;
        bool ok=waitPanelReturnValues(df, ds);
        if (ok && df.count()>=1) ok = (df.first()>0);
        return ok;
    }

};
