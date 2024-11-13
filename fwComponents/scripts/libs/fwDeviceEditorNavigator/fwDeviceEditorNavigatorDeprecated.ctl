
// Commands for DEN "remote control" callback mechanism that is now deprecated
const string fwDEN_COMMAND_REFRESH_NODE = "COMMAND_REFRESH_POSITION";
const string fwDEN_COMMAND_UPDATE_STATUS	= "COMMAND_UPDATE_STATUS";
const string fwDEN_COMMAND_REFRESH_SELECTED	= "COMMAND_REFRESH_SELECTED";

// Commands DP pattern to establish a callback
const string fwDEN_COMMAND_DP = "fwDeviceEditorNavigator_";

// converts index of the tab to the reference name of the treeView
global mapping g_fwDEN_tabIndexToReference;

// Commands through dpConnect
const string fwDEN_COMMAND_REFRESH	= "REFRESH";

/**

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param command
@param selectedNode
@param exceptionInfo returns details of any exceptions

@deprecated 2023-07-12

@note Part of DEN "remote control" mechanism. Uses obsolete functionality that is not available
      in the framework currently, therefore entire mechanism is not functional.
*/
fwDeviceEditorNavigator_callCommand(string command, dyn_string selectedNode, dyn_string &exceptionInfo)
{
	switch(command)
	{
		case fwDEN_COMMAND_REFRESH_NODE:
		case fwDEN_COMMAND_UPDATE_STATUS:
		case fwDEN_COMMAND_REFRESH_SELECTED:

			dpSet(	fwDEN_COMMAND_DP + myManNum() + ".command", command,
					fwDEN_COMMAND_DP + myManNum() + ".selectedNode", selectedNode);
			break;
		default:
			fwException_raise(	exceptionInfo,
								"ERROR",
								"fwDeviceEditorNavigator_callCommand(): The command " + command + " is not supported",
								"");
			break;
	}
}


/**

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param dpe1
@param command
@param dpe2
@param selectedNode

@deprecated 2023-07-12
@note Part of DEN "remote control" mechanism. Uses obsolete functionality that is not available
      in the framework currently, therefore entire mechanism is not functional.
*/
fwDeviceEditorNavigator_executeCommand(string dpe1, string command, string dpe2, dyn_string selectedNode)
{
	//DebugN("fwDeviceEditorNavigator_executeCommand");
	dyn_string exceptionInfo;
	switch(command)
	{
		case fwDEN_COMMAND_REFRESH_SELECTED:
		{
			int selectedTabIndex, pos;
			getValue("", "activeRegister", selectedTabIndex);
			//DebugN("Active tab is " + selectedTabIndex);
			fwTreeView_getSelectedPosition(pos, g_fwDEN_tabIndexToReference[selectedTabIndex]);
			fwDeviceEditorNavigator_expandTree(pos, g_fwDEN_tabIndexToReference[selectedTabIndex]);
			break;
		}
		case fwDEN_COMMAND_UPDATE_STATUS:
		{
			dyn_bool status;

			// get status and update mode
			_fwDeviceEditorNavigator_getStatus(selectedNode[fwTreeView_VALUE], status, exceptionInfo);
			if(!status[fwDEN_STATUS_LOCAL])
			{
				fwDeviceEditorNavigator_setMode(fwDEN_MODE_NAVIGATOR, FALSE, exceptionInfo);
			}
			else
			{
				fwDeviceEditorNavigator_setMode(fwDEN_MODE_SAME, TRUE, exceptionInfo);
			}
			break;
		}
		case fwDEN_COMMAND_REFRESH_NODE:
			break;
		default:
			break;
	}
}
