/**@file

This library contains the functions needed by the Device Editor and Navigator.
The tool displays all the devices of the system in a hierarchical way. It also
allows to browse through them to display operation and configuration information.

@par Creation Date
	31/10/2001

@author Manuel Gonzalez Berges (IT-CO)

*/
#uses "fwDeviceEditorNavigator/fwDeviceEditorNavigatorDeprecated.ctl"

//@{

// Constants
const string fwDEN_DEVICE_MODULE	= "DEVICE_MODULE";

// Constants to define running modes
const string fwDEN_MODE_NAVIGATOR 		= "MODE_NAVIGATOR";
const string fwDEN_MODE_EDITOR 			= "MODE_EDITOR";
const string fwDEN_MODE_SAME 			= "MODE_SAME";
const string fwDEN_MODE_SWITCH 			= "MODE_SWITCH";

// Indexes for array with statuses
const int fwDEN_STATUS_LOCAL	= 1;
const int fwDEN_STATUS_EDIT	= 2;

// Commands through right click
const int fwDEN_CANCEL			= 0;
const int fwDEN_COPY_LEAFS		= 1;
const int fwDEN_COPY_DEVICE		= 2;
const int fwDEN_CLIPBOARD_PASTE = 3;

// Tabs
const int fwDEN_TAB_INDEX_HARDWARE	= 0;
const int fwDEN_TAB_INDEX_LOGICAL	= 1;

// relative positin of the trees in the DEN
const int fwDEN_TREE_RELATIVE_X = 0;
const int fwDEN_TREE_RELATIVE_Y = 0;

// global variables

// default mode when starting
// cannot put directly fwDEN_MODE_NAVIGATOR because it is not evaluated (will be possible in 3.0?)
global string g_fwDEN_mode = "NAVIGATOR";

global string g_fwDEN_selectedDevice = "";
global string g_fwDEN_currentHierarchyType = "";

// mapping of tree types to level 1 node types
global mapping g_fwDEN_treeToNodeType;

// whether to display panels for a specific hierarchy type
global mapping g_fwDEN_displayDevicePanel;

// mapping of tress to hardware or logical hierarchies (the only real ones with children, etc)
global mapping g_fwDEN_treeToHierarchy;

// selected system (used for hardware select)
global string g_fwDEN_selectedSystem = "";


_fwDeviceEditorNavigator_init()
{

	fwDevice_initialize();

  // hardware tree
  g_fwDEN_displayDevicePanel[fwDevice_HARDWARE] 	= TRUE;
  g_fwDEN_treeToNodeType[fwDevice_HARDWARE]		= fwNode_TYPE_VENDOR;
  g_fwDEN_treeToHierarchy[fwDevice_HARDWARE] 		= fwDevice_HARDWARE;
  //g_fwDEN_tabIndexToReference[fwDEN_TAB_INDEX_HARDWARE] = "hardwareTree.";

  // hardware select tree
  g_fwDEN_displayDevicePanel[fwDevice_HARDWARE_SELECT]	= FALSE;
  g_fwDEN_treeToNodeType[fwDevice_HARDWARE_SELECT]	= fwNode_TYPE_VENDOR;
  g_fwDEN_treeToHierarchy[fwDevice_HARDWARE_SELECT]	= fwDevice_HARDWARE;

  // logical tree
  g_fwDEN_displayDevicePanel[fwDevice_LOGICAL] 	        = TRUE;
  g_fwDEN_treeToNodeType[fwDevice_LOGICAL]		= fwNode_TYPE_LOGICAL_ROOT;
  g_fwDEN_treeToHierarchy[fwDevice_LOGICAL]		= fwDevice_LOGICAL;
  //g_fwDEN_tabIndexToReference[fwDEN_TAB_INDEX_LOGICAL]	= "logicalTree.";

  // logical clipboard tree
  g_fwDEN_displayDevicePanel[fwDevice_LOGICAL_CLIPBOARD] 	= false;
  g_fwDEN_treeToNodeType[fwDevice_LOGICAL_CLIPBOARD]		= fwNode_TYPE_LOGICAL_DELETED_ROOT;
  g_fwDEN_treeToHierarchy[fwDevice_LOGICAL_CLIPBOARD]		= fwDevice_LOGICAL;
  //g_fwDEN_tabIndexToReference[fwDevice_LOGICAL_CLIPBOARD]	= "clipboard.";
}

/**

Modification History:

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param x calculated x coordinate of the module to be opened
@param y calculated y coordinate of the module to be opened
@param size array [w, h] of the panel to be opened in the module
*/
void fwDeviceEditorNavigator_getModulePosition(int &x, int &y, dyn_int sizeArray)
{
    float f;
    getZoomFactor(f);

    int xPos, yPos;
    panelPosition(myModuleName(), "", xPos, yPos);

    int xSize, ySize;
    panelSize(rootPanel(), xSize, ySize);

    x = xPos + (xSize + fwDEN_TREE_RELATIVE_X) * f;
    y = yPos + fwDEN_TREE_RELATIVE_Y * f;

    int screenW, screenH;
    getScreenSize(screenW, screenH);
    if(x + sizeArray[1] > screenW && xPos - sizeArray[1] > 0 || x > screenW){
        x = xPos - sizeArray[1];  // put module on the left side if does not fit on the right
    }
}



/** Returns current status of the Device Editor & Navigator.
Currently this comprises:
	-whether a local or a remote system is selected
	-whether edit is possible
Also the global variable (g_fwDEN_selectedSystem) with the
current selected system is updated.

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param device device dp name or dp alias
@param status array with current status
			-status[fwDEN_STATUS_LOCAL]: whether we are in the local system or not
			-status[fwDEN_STATUS_EDIT]: whether we are in Editor mode or not.
@param exceptionInfo details of any exceptions are returned here
*/
_fwDeviceEditorNavigator_getStatus(string device, dyn_bool &status, dyn_string &exceptionInfo)
{
	// get current system name and check if it is local
	fwGeneral_getSystemName(device, g_fwDEN_selectedSystem, exceptionInfo);
	if(g_fwDEN_selectedSystem == getSystemName())
		status[fwDEN_STATUS_LOCAL] = TRUE;
	else
		status[fwDEN_STATUS_LOCAL] = FALSE;

	if(status[fwDEN_STATUS_LOCAL] && (g_fwDEN_mode == fwDEN_MODE_EDITOR))
		status[fwDEN_STATUS_EDIT] = TRUE;
	else
		status[fwDEN_STATUS_EDIT] = FALSE;

	//DebugN(device, g_fwDEN_selectedSystem, getSystemName(), status);
}


/** Function to paste a device (pastedDevice) and its children as
child of another device (destDevice) in the logical hierarchy

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param destDevice destination device object
@param pastedDevice pasted device object
@param exceptionInfo details of any exceptions are returned here
*/
fwDeviceEditorNavigator_pasteLogical(dyn_string destDevice, dyn_string pastedDevice, dyn_string &exceptionInfo)
{
	int i, result;
	string deviceDp, dpNameWithoutSN, dpAliasWithoutSN;
	dyn_string children;
	dyn_errClass errorClass;

	//DebugN("fwDeviceEditorNavigator_pasteLogical. destDevice: " + destDevice + " pastedDevice " + pastedDevice);

	pastedDevice[fwDevice_DP_NAME] = strrtrim(dpAliasToName(pastedDevice[fwDevice_DP_ALIAS]), ".");
	fwDevice_getChildren(pastedDevice[fwDevice_DP_ALIAS], fwDevice_LOGICAL, children, exceptionInfo);

	// build new dp alias: remove character marking cut and concatenate aliases
	fwDevice_getName(pastedDevice[fwDevice_DP_ALIAS], pastedDevice[fwDevice_ALIAS], exceptionInfo);
	pastedDevice[fwDevice_ALIAS] = strltrim(pastedDevice[fwDevice_ALIAS], fwDevice_HIERARCHY_LOGICAL_CUT);
	pastedDevice[fwDevice_DP_ALIAS] = destDevice[fwDevice_DP_ALIAS] + fwDevice_HIERARCHY_SEPARATOR + pastedDevice[fwDevice_ALIAS];

	// Remove root device from clipboard (only nodes can be root)
	if(dpTypeName(pastedDevice[fwDevice_DP_NAME]) == "FwNode")
	{
		//fwDeviceEditorNavigatorClipboard_addDevice(deviceDpName, exceptionInfo);
		fwNode_getType(pastedDevice[fwDevice_DP_NAME], pastedDevice[fwDevice_MODEL], exceptionInfo);

		// if the device being pasted was a root in the clipboard, its type has to be changed
		if(pastedDevice[fwDevice_MODEL] == fwNode_TYPE_LOGICAL_DELETED_ROOT)
		{
			// if no parent was specified, then we are pasting in the system level
			fwGeneral_getNameWithoutSN(destDevice[fwDevice_DP_NAME], dpNameWithoutSN, exceptionInfo);
			fwGeneral_getNameWithoutSN(destDevice[fwDevice_DP_ALIAS], dpAliasWithoutSN, exceptionInfo);
			if((dpNameWithoutSN == "") && (dpAliasWithoutSN == ""))
			{
				fwNode_setType(pastedDevice[fwDevice_DP_NAME], fwNode_TYPE_LOGICAL_ROOT, exceptionInfo);
				// correct default dp alias because no parent was given
				pastedDevice[fwDevice_DP_ALIAS] = strltrim(pastedDevice[fwDevice_DP_ALIAS], fwDevice_HIERARCHY_SEPARATOR);
			}
			else
			{
				// pasting in another logical node
				fwNode_setType(pastedDevice[fwDevice_DP_NAME], fwNode_TYPE_LOGICAL, exceptionInfo);
			}
		}
	}


	// the function is recursive because the children also have to be pasted
	for(i = 1; i <= dynlen(children); i++)
	{
		fwDeviceEditorNavigator_pasteLogical(pastedDevice, makeDynString("", "", "", "", children[i]), exceptionInfo);
	}

	fwGeneral_getNameWithoutSN(pastedDevice[fwDevice_DP_ALIAS], dpAliasWithoutSN, exceptionInfo);
	//DebugN("Setting alias for " + pastedDevice[fwDevice_DP_NAME] + " to " + dpAliasWithoutSN);
	result = dpSetAlias(pastedDevice[fwDevice_DP_NAME] + ".", dpAliasWithoutSN);
	if(result)
	{
		errorClass = getLastError();
		//DebugN(errorClass);

		fwException_raise(exceptionInfo, "ERROR",
						  "fwDeviceEditorNavigator_pasteLogical(). Could not set alias of " + pastedDevice[fwDevice_DP_NAME] +
						  " to " + dpAliasWithoutSN,
						  "");
	}
}

void _fwDeviceEditorNavigator_getAssociatedDevicePanel(string deviceDpName, string hierarchyType, string mode,
                                                       string &panelFile, dyn_string &exceptionInfo)
{
    dyn_string panelList;
    string deviceDpType = dpTypeName(deviceDpName);

    if(dpTypeName(deviceDpName) == "FwNode"){
        fwDevice_getInstancePanels(deviceDpName, mode, panelList, exceptionInfo);
    }else{
        string deviceModel;
        fwDevice_getModel(makeDynString(deviceDpName), deviceModel, exceptionInfo);
        if(dynlen(exceptionInfo) > 0){
            return;
        }
        switch(hierarchyType){
            case fwDevice_HARDWARE:{
                if (mode == fwDEN_MODE_NAVIGATOR)
                    fwDevice_getDefaultOperationPanels(deviceDpType, panelList, exceptionInfo, deviceModel);
                else
                    fwDevice_getDefaultConfigurationPanels(deviceDpType, panelList, exceptionInfo, deviceModel);
                break;}
            case fwDevice_LOGICAL:{
                if (mode == fwDEN_MODE_NAVIGATOR)
                    fwDevice_getDefaultOperationLogicalPanels(deviceDpType, panelList, exceptionInfo, deviceModel);
                else
                    fwDevice_getDefaultConfigurationLogicalPanels(deviceDpType, panelList, exceptionInfo, deviceModel);
                break;}
        }
    }
    if(dynlen(panelList) > 0){
        panelFile = panelList[1];
    }
}

void _fwDeviceEditorNavigator_displayAssociatedDevicePanel(string deviceDpName, string hierarchyType,
                                                           string mode, dyn_string &exceptionInfo)
{
    string panelFile;
    if(deviceDpName != ""){
        _fwDeviceEditorNavigator_getAssociatedDevicePanel(deviceDpName, hierarchyType, mode, panelFile, exceptionInfo);
    }

    if(panelFile != "" && getPath(PANELS_REL_PATH, panelFile + ".pnl") == ""){
        fwException_raise(exceptionInfo, "WARNING",
                          "The panel \"" + panelFile +".pnl" + "\" could not be found", "");
        panelFile = "";
    }

    if(dynlen(exceptionInfo) > 0){
        fwExceptionHandling_display(exceptionInfo);
    }

    if(panelFile == ""){ // no panel associated with device
        if(isModuleOpen(fwDEN_DEVICE_MODULE)){
            ModuleOff(fwDEN_DEVICE_MODULE);
        }
        return;
    }

    string panelName = panelFile + ".pnl " + deviceDpName + " in " + g_fwDEN_mode;
    dyn_string parameters = makeDynString(
            "$sDpName:" + deviceDpName,
            "$bHierarchyBrowser:" + TRUE,
            "$sParentReference:" + " ",
            "$sHierarchyType:" + hierarchyType);

    if(!isModuleOpen(fwDEN_DEVICE_MODULE)){ // open module with root panel
        dyn_int sizeArray = getPanelSize(panelFile);
        int xPos, yPos;
        fwDeviceEditorNavigator_getModulePosition(xPos, yPos, sizeArray);

        ModuleOnWithPanel(fwDEN_DEVICE_MODULE,
                          xPos, yPos, sizeArray[1], sizeArray[2],
                          1, 1, "Scale",
                          panelFile + ".pnl", panelName,
                          parameters);
    }
    else{ // change the root panel only as module already opened
        RootPanelOnModule(panelFile + ".pnl", panelName,
                          fwDEN_DEVICE_MODULE,
                          parameters);
    }
}

//@}
