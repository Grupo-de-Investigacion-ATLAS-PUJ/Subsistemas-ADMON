/**@file

This library contains the functions required by the Trending Tree

@par Creation Date
  04/11/04

@par Modification History
  None

@par Constraints
  Some functions rely on the fwTree and some require the Trending Editor and Navigator panel

@par Usage
  Internal

@par PVSS managers
  VISION

@author
  Oliver Holme (IT-CO), Marco Boccioli (EN-ICE), Jonas Arroyo (EN-ICE)
*/

#uses "fwGeneral/fwGeneral.ctl"
#uses "fwTree/fwTree.ctl"
#uses "fwTree/fwTreeUtil.ctl"
#uses "fwTrending/fwTrending.ctl"

#uses "classes/fwTrending/FwTrendingTree_PanelDelegateA.ctl"
#uses "classes/fwTrending/FwTrendingTreeMode.ctl"


//@{
const string fwTrendingTree_TREE_NAME            = "TrendTree";
const int    fwTrendingTree_USER_DATA_PARAMETERS = 1;

global bool isTrendEdit;
//@}



//@{
/** TrendTree_navigator_selected

Function that is called when the user selects an item in the Trend Tree (Navigator mode)
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_navigator_selected(string sNode, string sParent)
{
    FwTrendingTree_PanelDelegateA::getInstance().showNodeInfo(sNode, FwTrendingTreeMode::navigator);
}// TrendTree_navigator_selected()



/** TrendTree_editor_selected
Function that is called when the user selects an item in the Trend Tree (Editor mode)
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_editor_selected(string sNode, string sParent)
{
    FwTrendingTree_PanelDelegateA::getInstance().showNodeInfo(sNode, FwTrendingTreeMode::editor);
}// TrendTree_editor_selected()




/** Function that is called when the user chooses to Add an item in the Trend Tree (Editor mode)

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
  Uses global variables: FwTreeTypes[], FwTreeNames[], FwActiveTrees[] and CurrTreeIndex

@par Usage
  Internal

@par PVSS managers
  VISION

@param sParent    input, name of the parent of the node to be created
@param sMode      input, the type of addition.  Can be one of:
                     - "addnode"      Add an emtpy node to the tree
                     - "addnew"       Create a new device (plot or page) and create a new node to add it in the tree
                     - "addexisting"  Create a new node to link to an existing device (plot or page)
@param iDone      output, value is 1 if the node was created, 0 if the process was stopped before creation
*/

void fwTrendingTree_addToTree(string sParent, string sMode, int &iDone)
{
  int iCU;
  string sTemplateParameters, sType, sDevice, sLabel, sSystem, sRefParent, sTreeNode;
  dyn_string dsReturn, exceptionInfo;
  dyn_float dfReturn;


  iDone = 0;  // Mark process as free.

  if( fwTreeUtil_isObjectReference(sParent) )
  {
    sRefParent = "&";
  }
  sRefParent += fwTree_getNodeDisplayName(sParent, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  ChildPanelOnReturn("fwTrending/fwTrendingAddToTree.pnl",
                     "Add...",
                     makeDynString(sParent,
                                   sRefParent,
                                   FwTreeTypes[CurrTreeIndex],
                                   FwTreeNames[CurrTreeIndex],
                                   "$mode:" + sMode),
                     100, 60,
                     dfReturn, dsReturn);


  if( dfReturn[1] )
  {
    iDone  = 1;           // Mark process as busy.

    // Show progress bar
    if (isFunctionDefined("fwUi_informUserProgress")) fwUi_informUserProgress("Please Wait - Creating Nodes ...", 100, 60);

    sType   = dsReturn[1];      // Type of trend to add: FwTrendingPlot or FwTrendingPage
    iCU     = (int)dsReturn[2]; // Always 0 = no control unit node
    sDevice = dsReturn[3];      // FwTrending[Plot/Page]Dp
    sLabel  = dsReturn[4];      // fwTT_node [node/plot/page]



//CG
    if(fwTrending_getLbExtras() == 2)
    {
      if(sMode == "addexisting")
        sTreeNode = fwTrending_createNode(sParent, sLabel, sMode, sDevice);
      else
        sTreeNode = fwTrending_createNode(sParent, sLabel, sMode);
    }
    else
    {
    // Create a Tree node fwTT_[LABEL]
    sTreeNode = fwTree_createNode(sParent, sLabel, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }


    // Create properly device DP with system name
    if( sDevice != "" )
    {
      // If is a Local system, add it to device DP name
      sSystem = fwSysName(sDevice);
      if( sSystem == "" )
      {
        sDevice   = getSystemName() + sDevice;
      }
    }

    // Configure Tree node with the device (plot or page)
    fwTree_setNodeDevice(sTreeNode, sDevice, sType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    if( sMode != "addnode" )
    {
      // Get any template parameter
      fwTrendingTree_getTemplateParameters(sDevice, sTemplateParameters, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      // Set Tree node .userdata with template parameter translation
      fwTree_setNodeUserData(sTreeNode, makeDynString(sTemplateParameters), exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }
    }
    }
//end CG
    // Configure tree node NOT as Control Unit
    fwTree_setNodeCU(sTreeNode, iCU, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    // If function is defined: "TrendTree_nodeAdded" launch it
    fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodeAdded",
                            sTreeNode,
                            sParent);
  }

}// fwTrendingTree_addToTree()







/** Function that displays the information about the currently selected node in the Trending Editor & Navigator

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void fwTrendingTree_showItemInfo(string sNode, string sParent)
{
  string sDevice, sDeviceType, sDeviceName;
  dyn_string exceptionInfo;

//CG
  if(fwTrending_getLbExtras())
  {
	  fwTrending_clearPage();
  }
//end CG
  if( (sNode != "") && (sDeviceName != fwTrendingTree_TREE_NAME) )
  {
    // Get Tree node: device and type
    fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    // Get device type name associated with sDeviceType
    fwDevice_getType(sDeviceType, sDeviceName, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }


    // FWTREND-990
    if( ((sDevice == "") && (sDeviceType == " ")) ||
        ((sDevice == "") && (sDeviceType == ""))     )
    {
//CG
      if(fwTrending_getLbExtras())
      {
	  	  sDevice = fwTree_getNodeSys(sNode, exceptionInfo)+":"+sNode;
      }
//end CG
      sDeviceName = "Trending Tree Node";
    }
  }

  itemDpName.text = sDevice;
  itemDpType.text = sDeviceName;

//CG
  if(fwTrending_getLbExtras())
  {
	  if(sDeviceName == "Trending Page")
	  {
		  fwTrending_refreshPage(sDevice);
	  }
  }
//end CG
}



/** TrendTree_navigator_entered
Function that is called when the user right-clicks an item in the Trend Tree (Navigator mode)
It displays a contextual menu with the ncessary options for the selected device in the current mode.

Adapted from generic function in fwTreeDisplay.ctl
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_navigator_entered(string sNode, string sParent)
{
    FwTrendingTree_PanelDelegateA::getInstance().showNodeMenu(sNode, FwTrendingTreeMode::navigator);
}// TrendTree_navigator_entered()



/** fwTrendingTree_menuNavigator
Function that displays a contextual menu with the necessary options for the device (trend)
in Trend Tree in Navigator mode.
Called when FwTrendingTree_PanelDelegatePresent is loaded in TrendTree panel

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void fwTrendingTree_menuNavigator(string sNode, string sParent)
{
  int iAnswer;
  string sDevice, sDeviceType;
  dyn_string dsMenu, exceptionInfo;


  // If none none node has been selected
  if( (sNode == "") && (sParent == "") )
  {
    return;
  }

  // Create menu to display
  if( !fwTree_isRoot(sNode, exceptionInfo) )
  {
    // Case non root node selected
    fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    // Enable only view button if is a PLOT or a PAGE. Not in case of a node.
    if( (sDeviceType == fwTrending_PLOT) || (sDeviceType == fwTrending_PAGE) )
    {
      dynAppend(dsMenu, "PUSH_BUTTON, View, 1, 1");
    }
    else
    {
//CG
      if(!fwTrending_getLbExtras())
      {
        dynAppend(dsMenu, "PUSH_BUTTON, View, 1, 0");
      }
      else
      {
			  dynAppend(dsMenu, "PUSH_BUTTON, View, 1, 1");
      }
//end CG
    }
  }
  else
  {
    // Case root node selected
    dynAppend(dsMenu, "PUSH_BUTTON, Manage Plots and Pages..., 8, 1");
  }



  // Show menu
  popupMenu(dsMenu, iAnswer);

  switch( iAnswer )
  {
    case 1:
      fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodeView", sNode, sParent);
      break;

    case 8:
      fwTrendingTree_manageTrendingDevices(sNode);
      break;

    default:
      return;
      break;
  }

}// fwTrendingTree_menuNavigator()



/** TrendTree_editor_entered
Function that is called when the user right-clicks an item in the Trend Tree (Editor mode)
It displays a contextual menu with the ncessary options for the selected device in the current mode.

Adapted from generic function in fwTreeDisplay.ctl
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_editor_entered(string sNode, string sParent)
{
    FwTrendingTree_PanelDelegateA::getInstance().showNodeMenu(sNode, FwTrendingTreeMode::editor);
}// TrendTree_editor_entered()



/** fwTrendingTree_menuEditor
Function that displays a contextual menu with the necessary options for the device (trend)
in Trend Tree in Editor mode.
Called when FwTrendingTree_PanelDelegatePresent is loaded in TrendTree panel

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void fwTrendingTree_menuEditor(string sNode, string sParent)
{
  bool bNeeds, bIsRoot, bIsClipBoard;
  int iAnswer, iPasteFlag, iRedo, iWait;
  string sTree, sDevice, sDeviceType;
  dyn_string dsMenu, exceptionInfo;


  if( (sNode == "") && (sParent == "") )
    return;


  iWait = 0;
  iRedo = 0;

  if(PasteNode == "")
    iPasteFlag = 0;
  else
    iPasteFlag = 1;


  // Getting common inputs
  bIsRoot = (bool) fwTree_isRoot (sNode, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  bIsClipBoard = (bool) fwTree_isClipboard(sNode, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }


  // Create right click menu
  if( !bIsClipBoard )
    dynAppend(dsMenu, "CASCADE_BUTTON, Add, 1");

  dynAppend(dsMenu, "PUSH_BUTTON, Remove..., 2, 1");
  dynAppend(dsMenu, "SEPARATOR");

  if( (!bIsRoot) && (!bIsClipBoard) )
    dynAppend(dsMenu, "PUSH_BUTTON, Cut, 3, 1");

  dynAppend(dsMenu, "PUSH_BUTTON, Paste, 4, " + iPasteFlag);
  dynAppend(dsMenu, "SEPARATOR");

  if( (!bIsRoot) && (!bIsClipBoard) )
    dynAppend(dsMenu, "PUSH_BUTTON, Rename, 5, 1");

  dynAppend(dsMenu, "PUSH_BUTTON, Reorder, 6, 1");

//CG
  if(fwTrending_getLbExtras() == 2)
  {
	  dynAppend(dsMenu,"SEPARATOR");
	  dynAppend(dsMenu,"PUSH_BUTTON, Change Plot Legends..., 20, 1");
	  dynAppend(dsMenu,"PUSH_BUTTON, Change Plot Properties..., 22, 1");
	  dynAppend(dsMenu,"PUSH_BUTTON, Duplicate SubTree..., 21, 1");
  }
//end CG
  if( (!bIsRoot) && (!bIsClipBoard) )
  {
    fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    if( (sDeviceType == fwTrending_PLOT) || (sDeviceType == fwTrending_PAGE) )
    {
      dynAppend(dsMenu, "SEPARATOR");
      dynAppend(dsMenu, "PUSH_BUTTON, Settings, 7, 1");

      fwTrendingTree_checkIfNeedsTemplateParameters(sNode, sDevice, sDeviceType, bNeeds, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      if(bNeeds)
        dynAppend(dsMenu, "PUSH_BUTTON, Template Parameters, 8, 1");
      else
        dynAppend(dsMenu, "PUSH_BUTTON, Template Parameters, 8, 0");
    }
    else
    {
      dynAppend(dsMenu, "SEPARATOR");
      dynAppend(dsMenu, "PUSH_BUTTON, Settings, 7, 0");
      dynAppend(dsMenu, "PUSH_BUTTON, Template Parameters, 8, 0");
    }
  }

  if(bIsRoot)
  {
    dynAppend(dsMenu, "SEPARATOR");
    dynAppend(dsMenu, "PUSH_BUTTON, Manage Plots and Pages..., 9, 1");
  }

  if(!bIsClipBoard)
  {
    dynAppend(dsMenu, "Add");
    dynAppend(dsMenu, "PUSH_BUTTON, Add Node..., 11, 1");
//CG
    if(fwTrending_getLbExtras() == 2)
    {
		  dynAppend(dsMenu,"PUSH_BUTTON, Add Page..., 14, 1");
    }
    else
    {
      dynAppend(dsMenu, "PUSH_BUTTON, Add New Plot/Page..., 12, 1");
    }
//end CG
    dynAppend(dsMenu, "PUSH_BUTTON, Add Existing Plot/Page..., 13, 1");
  }


  // Show Menu and do actions
  popupMenu(dsMenu, iAnswer);

  switch( iAnswer )
  {
    case 1: // Add node
      fwTrendingTree_addToTree(sNode, "", iRedo);
      break;

    case 2: // Remove node
      fwTreeDisplay_askRemoveNodeStd(sParent, sNode, iRedo);
      break;

    case 3: // Cut node
      if (isFunctionDefined("fwUi_informUserProgress")) fwUi_informUserProgress("Please wait - Cutting Nodes ...", 100, 60);

      PasteNode = sNode;
      fwTree_cutNode(sParent, PasteNode, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodeCut", PasteNode, sParent);
      iRedo = 1;
      break;

    case 4: // Paste node
      if (isFunctionDefined("fwUi_informUserProgress")) fwUi_informUserProgress("Please wait - Pasting Nodes ...", 100, 60);

      fwTree_pasteNode(sNode, PasteNode, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodePasted", PasteNode, sNode);

      PasteNode = "";
      iRedo = 1;
      break;

    case 5: // Rename node
      fwTreeDisplay_askRenameNodeStd(sNode, 1, iRedo);
      break;

    case 6: // Reorder node
      fwTreeDisplay_askReorderNodeStd(sNode, iRedo);
      break;

    case 7: // Configure node
      fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodeSettings", sNode, sParent);
      break;

    case 8: // Configure template parameters
      fwTreeDisplay_callUser2(FwActiveTrees[CurrTreeIndex] + "_nodeParameters", sNode, sParent);
      break;

    case 9: // Manage plots and pages
      fwTrendingTree_manageTrendingDevices(sNode);
      break;

    case 11: // Add new node
      fwTrendingTree_addToTree(sNode, "addnode", iRedo);
      break;

    case 12: // Add new plote/page
      fwTrendingTree_addToTree(sNode, "addnew", iRedo);
      break;

    case 13: // Add existing Plot / Page
      fwTrendingTree_addToTree(sNode, "addexisting", iRedo);
      break;

//CG
    case 14: // Add new Page
  		fwTrendingTree_addToTree(sNode, "addpage", iRedo);
      break;

    case 20:
      fwTrendingTree_changePlotLegends(sNode);
      break;

    case 21:
      fwTrendingTree_copySubTree(sParent, sNode);
      break;

    case 22:
      fwTrendingTree_changePlotProperties(sNode);
      break;
//end CG

    default:
      return;
      break;

  }

  if( iRedo )
  {
    fwTreeDisplay_setRedoTree(FwActiveTrees[CurrTreeIndex]);
  }

  fwTree_getTreeName(sParent, sTree, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  if(sTree == "FSM")
  {
    iWait = 1;
  }

  if (isFunctionDefined("fwUi_uninformUserProgress")) fwUi_uninformUserProgress(iWait);

}// fwTrendingTree_menuEditor()






/** Function that is called when the user selects View from the contextual menu in the Trend Tree (Navigator mode)

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_nodeView(string sNode, string sParent)
{
  string sDevice, sDeviceType;
  dyn_string exceptionInfo;

  fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

//CG
  //DebugTN("TrendTree_nodeView", sNode, sParent, sDevice, sDeviceType);
  if(fwTrending_getLbExtras())
  {
    if( ((sDevice == "") && (sDeviceType == " ")) ||
        ((sDevice == "") && (sDeviceType == ""))     )
    {
        sDevice = getSystemName()+sNode;
    }
  }
//end CG
  fwTrendingTree_displayNode(sNode, sDevice, sDeviceType, FALSE);

}// TrendTree_nodeView()






/** TrendTree_nodeSettings
Function that is called when the user selects Settings from the contextual menu in the Trend Tree (Editor mode)

Adapted from generic function in fwTreeDisplay.ctl
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_nodeSettings(string sNode, string sParent)
{
  string sDevice, sDeviceType;
  dyn_string exceptionInfo;

  fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  fwTrendingTree_displayNode(sNode, sDevice, sDeviceType, TRUE);

}// TrendTree_nodeSettings()





/** TrendTree_nodeParameters
Function that is called when the user selects Template Parameters from the contextual menu in the Trend Tree (Editor mode)
Reads any existing settings from the node user data and then lets the user modify the values for any required parameters.
This modified value is then saved back to the user data.
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_nodeParameters(string sNode, string sParent)
{
  string sDevice, sDeviceType;
  dyn_string dsUserData, exceptionInfo;
  dyn_dyn_string ddsConfigData;

  // Getting device and type node
  fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  // Getting template parameters from user data DPE
  fwTree_getNodeUserData(sNode, dsUserData, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }


  switch( sDeviceType )
  {
    case fwTrending_PAGE:
      fwTrending_getPage(sDevice, ddsConfigData, exceptionInfo);
      break;

    case fwTrending_PLOT:
      fwTrending_getPlot(sDevice, ddsConfigData, exceptionInfo);
      break;

    default:
      return;
      break;
  }

  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  fwTrending_modifyAllTemplateParameters(fwTrendingTree_TREE_NAME,
                                         ddsConfigData,
                                         sDeviceType,
                                         dsUserData[fwTrendingTree_USER_DATA_PARAMETERS],
                                         exceptionInfo,
                                         TRUE);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  fwTree_setNodeUserData(sNode, dsUserData, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

}// TrendTree_nodeParameters()





/** Checks if any template parameters are mentioned in the configuration for the given node/device in the tree.

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode          input, name of the selected node
@param sDevice        input, name of the device attached to the node
@param sDeviceType    input, dp type of the device attached to the node
@param bIsNeeded      output, TRUE if any template parameters are mentioned in configuration, else FALSE
@param exceptionInfo  Any exceptions are returned here
*/
void fwTrendingTree_checkIfNeedsTemplateParameters(string sNode, string sDevice, string sDeviceType, bool &bIsNeeded, dyn_string &exceptionInfo)
{
  bool bIsConnected;
  dyn_string dsParameters;
  dyn_dyn_string ddsConfigData;

  if( !dpExists(sDevice) )
  {
    bIsNeeded = FALSE;
    return;
  }

  _fwTrending_isSystemForDpeConnected(sDevice, bIsConnected, exceptionInfo);
  if( !bIsConnected )
  {
    bIsNeeded = FALSE;
    return;
  }

  switch( sDeviceType )
  {
    case fwTrending_PAGE:
      fwTrending_getPage(sDevice, ddsConfigData, exceptionInfo);
      break;

    case fwTrending_PLOT:
      fwTrending_getPlot(sDevice, ddsConfigData, exceptionInfo);
      break;

    default:
      return;
      break;
  }


  fwTrending_getAllTemplateParametersForConfiguration(ddsConfigData, sDeviceType, dsParameters, exceptionInfo);
  if( dynlen(dsParameters) > 0 )
  {
    bIsNeeded = TRUE;
  }
  else
  {
    bIsNeeded = FALSE;
  }

}





/** Function that is called when the user selects "Manage Plots and Pages..." from the contextual menu in the Trend Tree (Editor mode)

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, used to determine the panel title and also passed as $ parameter to panel (but this is not used by the panel)
*/
void fwTrendingTree_manageTrendingDevices(string sNode)
{
  ChildPanelOnCentral("fwTrending/fwTrendingManageChildren.pnl",
                      "Manage Plots and Pages: " + sNode,
                      makeDynString("$sDpName:"  + sNode,
                                    "$sParentReference:"));

}// fwTrendingTree_manageTrendingDevices()





/** Function that is used to show either the editor or navigator panel for a specific tree node

@par Constraints
  Only works for devices other than tree nodes (i.e. TrendingPages or TrendingPlots)

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode          input, the currently selected node in the tree
@param sDevice        input, the name of the device attached to the selected node
@param sDeviceType    input, the dpType of the device attached to the selected node
@param bEditorMode    Optional parameter, default value TRUE.  TRUE to display editor panel, FALSE to show navigator panel.
*/
void fwTrendingTree_displayNode(string sNode, string sDevice, string sDeviceType, bool bEditorMode = TRUE)
{
  dyn_string dsUserData, exceptionInfo;

  if( bEditorMode )
  {
    if( dpExists(sDevice) )
    {
      fwTrendingTree_showEditorPanel(sDevice, sDeviceType, exceptionInfo);
    }
    else
    {
      fwException_raise(exceptionInfo, "ERROR", "The device connected to this node does not exist.", "");
      fwExceptionHandling_display(exceptionInfo);
    }
  }
  else
  {
    fwTree_getNodeUserData(sNode, dsUserData, exceptionInfo);
    if( dynlen(dsUserData) >= fwTrendingTree_USER_DATA_PARAMETERS )
    {
      fwTrendingTree_showNavigatorPanel(sDevice, sDeviceType, dsUserData[fwTrendingTree_USER_DATA_PARAMETERS], exceptionInfo);
    }
    else
    {
      fwTrendingTree_showNavigatorPanel(sDevice, sDeviceType, "", exceptionInfo);
    }
  }
}





/*
Function used to synchronise all the node names that are attached to the same device
The name is read from the dpe specified in the tree config for which to use as the name of a node.
The device is then found throughout the tree and each node is renamed to match the value in the dpe.

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param tree    input, name of the tree to synchronise
@param dp      input, the dp which to synchronise the labels for

fwTrendingTree_updateLabelsForDp(string tree, string dp)
{
  int position, i;
  string dpeForName, device, deviceType, newLabel, nodeTypes, nodeNames;
  dyn_string dsNodeTypes, dsNodeNames, nodeList, exceptionInfo;

  deviceType = dpTypeName(dp);

  nodeTypes = fwTreeDisplay_getNodeTypes(tree);
  nodeNames = fwTreeDisplay_getNodeNames(tree);

  dsNodeTypes = strsplit(nodeTypes, ",");
  dsNodeNames = strsplit(nodeNames, ",");

  position = dynContains(dsNodeTypes, deviceType);
  dpeForName = dsNodeNames[position];
  strreplace(dpeForName, "DP", dp);

  if( (dpeForName != "") && (dpExists(dpeForName)) )
  {
    dpGet(dpeForName, newLabel);
  }
  else
  {
    DebugTN("Error in fwTrendingTree.ctl -> fwTrendingTree_updateLabelsForDp() -> dpeForName is empty or doesn't exist: " + dpeForName);
    return;
  }

  fwTree_getAllTreeNodes(tree, nodeList, exceptionInfo);

  for(i=1; i<=dynlen(nodeList); i++)
  {
    fwTree_getNodeDevice(nodeList[i], device, deviceType, exceptionInfo);
    if(device == dp)
      fwTree_renameNode(nodeList[i], newLabel, exceptionInfo);
  }

    fwTreeDisplay_setRedoTree(tree);

}
*/





/** Finds all the occurences of a given device tree

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sDevice        input, the device to search for
@param sParents       input, a list of parents of the nodes to which the device is attached
@param sNodes         input, a list of the nodes to which the device is attached
@param exceptionInfo  Any exceptions are returned here
*/
void fwTrendingTree_findInTree(string sDevice, dyn_string &dsParents, dyn_string &dsNodes, dyn_string &exceptionInfo)
{
  int iLoop, iLength, iLoopInt, iLengthInt;
  dyn_uint duSystemNumber;
  dyn_string dsSystemName;
  dyn_dyn_anytype ddaQuery;

  dsParents = makeDynString();
  dsNodes   = makeDynString();

  getSystemNames(dsSystemName, duSystemNumber);

  iLength = dynlen(dsSystemName);
  for( iLoop = 1 ; iLoop <= iLength ; iLoop++ )
  {
    dpQuery("SELECT '.parent:_online.._value'  FROM '*' REMOTE '" + dsSystemName[iLoop] +
            ":' WHERE _DPT = \"_FwTreeNode\" AND '.device:_online.._value' == \"" + sDevice + "\"",
            ddaQuery);

    iLengthInt = dynlen(ddaQuery);
    if( iLengthInt > 1 )
    {
      for( iLoopInt = 2 ; iLoopInt <= iLengthInt ; iLoopInt++ )
      {
        dynAppend(dsNodes,   ddaQuery[iLoopInt][1]);
        dynAppend(dsParents, dsSystemName[iLoop] + ":" + ddaQuery[iLoopInt][2]);
      }

    }
  }

}// fwTrendingTree_findInTree()





/** Shows the editor panel for the given device (panel to be shown is read from device definitions)

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sDevice          input, the device to open the panel for
@param sDeviceType      input, the dpType of the device
@param exceptionInfo    Any exceptions are returned here
*/
void fwTrendingTree_showEditorPanel(string sDevice, string sDeviceType, dyn_string &exceptionInfo)
{
  string sDeviceTypeName, sModel;
  dyn_float dfResult;
  dyn_string dsPanelsList, dsResult;


  fwDevice_getModel(makeDynString(sDevice), sModel, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  fwDevice_getDefaultConfigurationPanels(sDeviceType, dsPanelsList, exceptionInfo, sModel);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  fwDevice_getType(sDeviceType, sDeviceTypeName, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  ChildPanelOnCentralReturn(dsPanelsList[1] + ".pnl",
                            sDeviceTypeName + " configuration: " + sDevice,
                            makeDynString("$sDpName:" + sDevice,
                                          "$Command:edit",
                                          "$sParentReference:"),
                            dfResult, dsResult);

}// fwTrendingTree_showEditorPanel()





/** Shows the navigator panel for the given device (panel to be shown is read from device definitions)

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sDevice                  input, the device to open the panel for
@param sDeviceType              input, the dpType of the device
@param sTemplateParameters      input, any template parameters for the device are passed here
@param exceptionInfo            Any exceptions are returned here
*/
void fwTrendingTree_showNavigatorPanel(string sDevice, string sDeviceType, string sTemplateParameters, dyn_string &exceptionInfo)
{
  string sModel;
  dyn_string dsPanelsList;
  dyn_dyn_string ddsData;

  // Get plot model
//CG
  if(!fwTrending_getLbExtras())
  {
  fwDevice_getModel(makeDynString(sDevice), sModel, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  // Get default panel from fwDeviceDefinition to open
  fwDevice_getDefaultOperationPanels(sDeviceType, dsPanelsList, exceptionInfo, sModel);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }
  }
//end CG
  // Actions in case device is Page or Plot
  switch( sDeviceType )
  {
    case fwTrending_PAGE:
      if( dpExists(sDevice) )
      {
        fwTrending_getPage(sDevice, ddsData, exceptionInfo);
        if( dynlen(exceptionInfo) > 0 )
        {
          fwExceptionHandling_display(exceptionInfo);
          return;
        }
      }
      else
      {
        ddsData[fwTrending_PAGE_OBJECT_TITLE] = "Page";
      }

//CG
      if(!fwTrending_getLbExtras())
      {
        ChildPanelOn(dsPanelsList[1] + ".pnl",
                     "Trending Page: " + (string)ddsData[fwTrending_PAGE_OBJECT_TITLE],
                     makeDynString("$PageName:"           + sDevice,
                                   "$OpenPageName:"       + sDevice,
                                   "$bEdit:",
                                   "$templateParameters:" + sTemplateParameters),
                     0, 0);
      }
      else
      {
        fwTrending_openPage(sDevice, 0);
      }
//end CG
      break;


    case fwTrending_PLOT:
      if( dpExists(sDevice) )
      {
        fwTrending_getPlot(sDevice, ddsData, exceptionInfo);
        if( dynlen(exceptionInfo) > 0 )
        {
          fwExceptionHandling_display(exceptionInfo);
          return;
        }
      }
      else
      {
        ddsData[fwTrending_PLOT_OBJECT_TITLE] = "Plot";
      }

      ChildPanelOn(dsPanelsList[1] + ".pnl",
                   "Single Trend: " + (string)ddsData[fwTrending_PLOT_OBJECT_TITLE],
                   makeDynString("$PageName:"           + "",
                                 "$OpenPageName:"       + "",
                                 "$PlotName:"           + sDevice,
                                 "$bEdit:",
                                 "$templateParameters:" + sTemplateParameters),
                   0, 0);
      break;


    default:
//CG
      if(!fwTrending_getLbExtras())
      {
        return;
      }
      else
      {
        fwTrending_openPage(sDevice, 1);
        break;
      }
//end CG
  }

}// fwTrendingTree_showNavigatorPanel()





/** Adds a clipboard to the Trend Tree

@par Constraints
  Only needs to be run once

@par Usage
  Internal

@par PVSS managers
  VISION
*/
void _fwTrendingTree_addClipboard()
{
  dyn_string exceptionInfo;

  fwTree_addNode(fwTrendingTree_TREE_NAME, "---Clipboard" + fwTrendingTree_TREE_NAME + "---", exceptionInfo);

}// _fwTrendingTree_addClipboard()





/** Upgrades old trees to the new format of tree (new format as of fwTrending2.3)

@par Constraints
  Should only be run once

@par Usage
  Internal

@par PVSS managers
  VISION
*/
void _fwTrendingTree_upgradeTree(dyn_string & exceptionInfo)
{
  int iLoop, iCU, iLen;
  dyn_string dsNodes;


  fwTree_getRootNodes(dsNodes, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    return;
  }


  iLen = dynlen(dsNodes);
  for( iLoop = 1 ; iLoop <= iLen ; iLoop++ )
  {
    fwTree_getNodeCU(dsNodes[iLoop], iCU, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      return;
    }


    if(!iCU)
    {
      if( (strpos(dsNodes[iLoop], "WindowTree")             == 0) ||
          (strpos(dsNodes[iLoop], "---Clipboard")           == 0) ||
          (strpos(dsNodes[iLoop], "FSM")                    == 0) ||
          (strpos(dsNodes[iLoop], fwTrendingTree_TREE_NAME) == 0)    )
      {
        continue;
      }

      fwTree_addNode(fwTrendingTree_TREE_NAME, dsNodes[iLoop], exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        return;
      }
    }

  }

}// _fwTrendingTree_upgradeTree()





/** Goes through old trees and adds the system name to any device references that do not contain the system name

@par Constraints
  If not system name is specified, it is assumed that the device is on the local system

@par Usage
  Internal

@par PVSS managers
  VISION, CTRL

@param node    Used to recursively work through the tree.  Give the name of the top node of the tree
*/
void _fwTrendingTree_addSystemNameRecursive(string sNode , dyn_string & exceptionInfo)
{
  int iLoop, iLen;
  string sDevice, sType;
  dyn_string dsChildren;


  fwTree_getChildren(sNode, dsChildren, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    return;
  }

  iLen = dynlen(dsChildren);
  for( iLoop = 1 ; iLoop <= iLen ; iLoop++ )
  {
    fwTree_getNodeDevice(dsChildren[iLoop], sDevice, sType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      return;
    }

    if( (sDevice != "") && (strpos(sDevice, ":") < 0) )
    {
      fwTree_setNodeDevice(dsChildren[iLoop], getSystemName() + sDevice, sType, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        return;
      }
    }

    // Recursive call
    _fwTrendingTree_addSystemNameRecursive(dsChildren[iLoop], exceptionInfo);

  }

}// _fwTrendingTree_addSystemNameRecursive()





/** For a given device connected to a tree node, this function will check if any template parameters are required.
If so, a dialog is shown and the user can enter values for the template parameters (or choose not to).
This string is then returned by the function, and the value should then be stored in the userData of the relevant data.

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param device                  input, the device to look at for template parameters
@param parameterString        output, any template parameters that were configured by the user are returned here
@param exceptionInfo          Any exceptions are returned here
*/
void fwTrendingTree_getTemplateParameters(string sDevice, string &sParameterString, dyn_string &exceptionInfo)
{
  string sDpType;
  dyn_dyn_string ddsConfigurationData;


  sParameterString = "";

  sDpType = dpTypeName(sDevice);
  switch(sDpType)
  {
    case fwTrending_PAGE:
      fwTrending_getPage(sDevice, ddsConfigurationData, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      fwTrending_checkAndGetAllTemplateParameters(fwTrendingTree_TREE_NAME, ddsConfigurationData, sDpType, sParameterString, exceptionInfo, TRUE);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }
      break;


    case fwTrending_PLOT:
      fwTrending_getPlot(sDevice, ddsConfigurationData, exceptionInfo);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }

      fwTrending_checkAndGetAllTemplateParameters(fwTrendingTree_TREE_NAME, ddsConfigurationData, sDpType, sParameterString, exceptionInfo, TRUE);
      if( dynlen(exceptionInfo) > 0 )
      {
        fwExceptionHandling_display(exceptionInfo);
        return;
      }
      break;


    default:
      break;
  }

}// fwTrendingTree_getTemplateParameters()






/** TrendTree_save_as_selected
Function that is called when the user clicks on an item in the Trend Tree (save_as mode)
It will check if node tree selected is a Trending node (neither Plot or Page), and will selected it.
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_save_as_selected(string sNode, string sParent)
{
  bool bIsClipBoard;
  int iTreeIndex;
  string sDevice, sDeviceType;
  dyn_string exceptionInfo;

  iTreeIndex = fwTreeDisplay_getTreeIndex();

  if( sNode != FwTreeTops[iTreeIndex] )
  {
    fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      // Clic on expand/collect node
      return;
    }
  }

  bIsClipBoard = (bool) fwTree_isClipboard(sNode, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }

  // Check if it is a Trending node to select it.
  if( ((sNode == FwTreeTops[iTreeIndex])         ||
       ((sDevice == "") && (sDeviceType == " ")) ||
       ((sDevice == "") && (sDeviceType == ""))    ) &&
       !bIsClipBoard                                    )
  {
    FwTreeSelects[iTreeIndex] = sNode;
    setMultiValue("TEXT_FIELD_SELECTED_NODE", "text",    sNode,
                  "PUSH_BUTTON_OK",           "enabled", TRUE);
  }
  else
  {
    FwTreeSelects[iTreeIndex] = "";
    setMultiValue("TEXT_FIELD_SELECTED_NODE", "text",    "",
                  "PUSH_BUTTON_OK",           "enabled", FALSE);
  }

}




/** TrendTree_save_as_entered
Function that is called when the user right-clicks an item in the Trend Tree (save_as mode)
It displays a contextual menu with the ncessary options for the selected device in the current mode.
@reviewed 2018-06-22 @whitelisted{Callback}

@par Constraints
  None

@par Usage
  Internal

@par PVSS managers
  VISION

@param sNode      input, name of the selected node
@param sParent    input, name of the parent of the selected node
*/
void TrendTree_save_as_entered(string sNode, string sParent)
{
//  bool bIsRoot, bIsClipBoard;
  bool bIsClipBoard;
  int iAnswer, iWait, iTreeIndex;
  string sDevice, sDeviceType;
  dyn_string dsMenu, dsChildrenNodes, dsChildrenNodeAdded, exceptionInfo;


  // Get Tree index from global variable
  iTreeIndex = fwTreeDisplay_getTreeIndex();

  if( (sNode == "") && (sParent == "") )
  {
    DebugTN("TrendTree_save_as_entered() -> sNode = sParent = empty -> return");
    return;
  }


//   bIsRoot = (bool) fwTree_isRoot (sNode, exceptionInfo);
//   if( dynlen(exceptionInfo) > 0 )
//   {
//     fwExceptionHandling_display(exceptionInfo);
//     return;
//   }

  bIsClipBoard = (bool) fwTree_isClipboard(sNode, exceptionInfo);
  if( dynlen(exceptionInfo) > 0 )
  {
    fwExceptionHandling_display(exceptionInfo);
    return;
  }


//  if( !bIsRoot && !bIsClipBoard )
  if( !bIsClipBoard )
  {
    // Case non root node selected
    fwTree_getNodeDevice(sNode, sDevice, sDeviceType, exceptionInfo);
    if( dynlen(exceptionInfo) > 0 )
    {
      fwExceptionHandling_display(exceptionInfo);
      return;
    }

    // Enable only view button if is a PLOT or a PAGE. Not in case of a node.
    if( (sDeviceType == fwTrending_PLOT) || (sDeviceType == fwTrending_PAGE) )
      dynAppend(dsMenu, "PUSH_BUTTON, View, 1, 1");
    else
      dynAppend(dsMenu, "PUSH_BUTTON, View, 1, 0");

    dynAppend(dsMenu, "PUSH_BUTTON, Add node, 2, 1");
  }
  else
    return;


  // Show Menu and do actions
  popupMenu(dsMenu, iAnswer);
  switch( iAnswer )
  {
    case 0: // No option selected
      break;


    case 1: // View
      TrendTree_nodeView(sNode, sParent);
      break;


    case 2: // Add new node
      // Get all children before and after create new node to select it.
      fwTree_getChildren(sNode, dsChildrenNodes, exceptionInfo);
      fwTrendingTree_addToTree(sNode, "addnode", iWait);
      fwTree_getChildren(sNode, dsChildrenNodeAdded, exceptionInfo);
      TrendTree_searchNewNode(dsChildrenNodes, dsChildrenNodeAdded);
      if( dynlen(dsChildrenNodeAdded) == 1 )
      {
        // Node added

        iWait = 0;
        if (isFunctionDefined("fwUi_uninformUserProgress")) fwUi_uninformUserProgress(iWait);

        // Expand node
        dynAppend(FwTreeExpands[iTreeIndex], sNode);

        // Select new node created
        FwTreeSelects[iTreeIndex] = dsChildrenNodeAdded[1];
        setMultiValue("TEXT_FIELD_SELECTED_NODE", "text",    dsChildrenNodeAdded[1],
                      "PUSH_BUTTON_OK",           "enabled", TRUE);
      }
      break;

    default:
      DebugTN("TrendTree_save_entered() -> Error: answer unknown: " + iAnswer);
      setMultiValue("TEXT_FIELD_SELECTED_NODE", "text",    "",
                    "PUSH_BUTTON_OK",           "enabled", FALSE);
      return;
      break;
  }

}


void TrendTree_searchNewNode(dyn_string dsNodesBefore, dyn_string &dsNodesAfter)
{
  int iLoop, iLen, iPos;

  iLen = dynlen(dsNodesBefore);
  for( iLoop = 1 ; iLoop <= iLen ; iLoop++ )
  {
    iPos = dynContains(dsNodesAfter, dsNodesBefore[iLoop]);
    if( iPos > 0 )
    {
      dynRemove(dsNodesAfter, iPos);
    }
  }

}


//@}
