#uses "fwDevice/fwDevice.ctl"

/**@file

Deprecated functions of fwDevice component.

*/

/** Returns the starting number to be used when numbering child devices
in the given device.

@par Constraints
        None

@par Usage
        Public

@par PVSS managers
        VISION, CTRL

@param device                   device object. Either the device datapoint name or the device dp type and the model are required.
@param startingNumber   number to start default naming
@param exceptionInfo    details of any exceptions

@deprecated 2018-06-22
*/
fwDevice_getStartingNumber(dyn_string device, int &startingNumber, dyn_string &exceptionInfo)
{
        FWDEPRECATED();

        int length = dynlen(exceptionInfo);
        string type;

        fwDevice_getModelStartingNumber(device, startingNumber, exceptionInfo);

        // if no error returned, the starting number could be retrieved for the model
        if(dynlen(exceptionInfo) != length)
                return;

        // get the starting number for the device type
        fwDevice_fillDpType(device, exceptionInfo);
        if(device[fwDevice_DP_TYPE] != "")
                dpGet(device[fwDevice_DP_TYPE] + fwDevice_DEFINITION_SUFIX + ".general.startingNumber", startingNumber);
}




/** Initializes a device object with empty fields.

@par Constraints
        None

@par Usage
        Public

@par PVSS managers
        VISION, CTRL

@param device                   the device object
@param exceptionInfo    details of any exceptions are returned here

@deprecated 2018-06-22

*/
fwDevice_createObject(dyn_string &device, dyn_string &exceptionInfo)
{
        FWDEPRECATED();
        for(int i = 1; i <= fwDevice_OBJECT_MAX_INDEX; i++)
                device[i] = "";
}



/** This function is used to process a template string and substitute
some tokens related to model information. The tokens have to be appended
by a number to indicate a position in the hierarchy. The numbering starts
with 1 referencing the current device, 2 referencing the parent and so on.
The possible tokens are:

@li model: references a device model (e.g. \%model2% references the
              model of the parent of the given device)

@par Constraints
        None

@par Usage
        JCOP Framework internal

@par PVSS managers
        VISION, CTRL

@param deviceDpName     device to which the template belongs (e.g. CAEN/crate003/board07/channel005)
@param templateString   template to be processed
@param finalString      result of the processing
@param exceptionInfo    details of any exceptions


@deprecated 2018-06-22

*/
fwDevice_processModelTemplate(  string deviceDpName, string templateString, string &finalString, dyn_string &exceptionInfo)
{
        FWDEPRECATED();
        int i;
        string model;
        dyn_string hierarchyDevices = strsplit(deviceDpName, fwDevice_HIERARCHY_SEPARATOR);

        for(i = 2; i <= dynlen(hierarchyDevices); i++)
        {
                deviceDpName = strrtrim(deviceDpName, fwDevice_HIERARCHY_SEPARATOR +
                                                                hierarchyDevices[dynlen(hierarchyDevices) + 2 - i]);
                fwDevice_getModel(makeDynString(deviceDpName), model, exceptionInfo);
                strreplace(templateString, "%model" + i + "%", model);
        }
        finalString = templateString;
}




/** Opens the corresponding operation panel when an item in the table is double clicked.

@par Constraints
        Must be called from within the double click code of table widget.\n
        It is used by the panels fwTableStatus or fwTableValueStatus.

@par Usage
        JCOP Framework internal

@par PVSS managers
        VISION


@deprecated 2018-06-22
*/
fwDevice_doubleClickViewTable()
{
        FWDEPRECATED();

        int row, col;
        string dpName, dpType, operationPanel;
        dyn_int selectedLine;
        dyn_string exceptionInfo, panelList;

        //DebugN("In    fwDevice_doubleClickViewTable()");
        selectedLine = this.getSelectedLines();
        getValue("", "currentCell", row, col);
        dpName = this.cellValueRC(row, "element");

        if(dpName == "" )
                return;

        if(dpExists(dpName))
        {
                dpType = dpTypeName(dpName);

                fwDevice_getDefaultOperationPanels(dpType, panelList, exceptionInfo);
                operationPanel = panelList[1];

                if(getPath(PANELS_REL_PATH, operationPanel + ".pnl") == "")
                {
                        fwException_raise(exceptionInfo,
                                                        "WARNING",
                                                        "The panel \"" + operationPanel + ".pnl" + "\" could not be found",
                                                        "");
                        fwExceptionHandling_display(exceptionInfo);
                        return;
                }

                if(!isModuleOpen(operationPanel))
                {
                        ModuleOn(operationPanel, 100, 100, 100, 100, 1, 1, 1, "");
                }

                RootPanelOnModule(operationPanel + ".pnl",                                                      // file name
                                                dpName,                                                                                 // panel name
                                                operationPanel,                                                                 // module name
                                                makeDynString("$sDpName:" + dpName,                             // parameters
                                                                                "$bHierarchyBrowser:" + FALSE));
        }
}



/**

@par Constraints
        None

@par Usage
        Public

@par PVSS managers
        VISION, CTRL

@param deviceDpType             device datapoint type (e.g. FwCaenBoard)
@param nameRoot                 root name used to name devices of the type deviceDpType
@param exceptionInfo    details of any exceptions

@deprecated 2018-06-22
*/
fwDevice_getNameRoot(string deviceDpType, string &nameRoot, dyn_string &exceptionInfo)
{
        FWDEPRECATED();
        nameRoot = "";
        dpGet(deviceDpType + fwDevice_DEFINITION_SUFIX + ".general.nameRoot", nameRoot);
}




/** Get all the logical children devices of a device

@par Constraints
        None

@par Usage
        Public

@par PVSS managers
        VISION, CTRL

@param deviceDpAlias    name of the device
@param children                 list of child devices
@param exceptionInfo    details of any exception

@deprecated 2018-06-22 One should use @ref fwDevice_getChildren with type="LOGICAL" instead

*/
fwDevice_getChildrenLogical(string deviceDpAlias, dyn_string &children, dyn_string exceptionInfo)
{
        int i, length;
        string  systemName, pattern;
        dyn_string rawResult;

        children = makeDynString();

        pattern = deviceDpAlias + fwDevice_HIERARCHY_SEPARATOR + "*";

        rawResult = dpAliases(pattern);
        length = dynlen(rawResult);
        pattern = pattern + fwDevice_HIERARCHY_SEPARATOR + "*";
        for(i = 1; i <= length; i++)
        {
                if(!(patternMatch(pattern, rawResult[i])))
                {
                        //DebugN("Pattern didn't match " + rawResult[i]);
                        dynAppend(children, rawResult[i]);
                }
        }
}
