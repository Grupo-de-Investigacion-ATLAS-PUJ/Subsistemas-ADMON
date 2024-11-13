/**
@file fwAlarmScreenGeneric.ctl
New version of the alarm panel.
The goal is to have a single panel (instead of one for JCOP, one for UNICOS, one for anything else).

----------------------
--- Customization: ---
----------------------
The panel is made of the AES table and 4 customisable widgets:
 - A header.
 - A filter on the alarm (AES internally managed).
 - A filter on the table (just locally hide lines).
 - One to add any other information you would like to.

However, you can use each widget to put anything you want, the list is just based on what is commonly needed in an alarm panel.

Each of those widget is independent from the main panel, so that you can change them at your will.
However, certain rules must be followed when creating a custom alert panel.
 - You need to identify your panel (e.g. "fwAlarmScreen") and pass this identifier by the $parameter $sAlarmType.
 - You need to define a set of functions with a specific name "xxAlarm_function" where "xxAlarm" refers to the identifier mentioned above (e.g. "fwAlarmScreen").
   The constants FW_ALARM_GENERIC_FUNCTION_XXX give a list of available functions. Some of them are mandatory, without them the alarm panel will not work.
   The mandatory functions are those concerning those 4 widgets. However, they are mandatory only if the concerned widgets exist.



-------------------------
--- Event management: ---
-------------------------
Any alarm panel can send different events (see FWALARMSCREEN_GENERIC_CONFIG_EVENT_***).
To handle those events, a function xxAlarm_eventHandler(string, int) must be defined. Event handling is implemented through the WinCC OA callback feature.
Each time an event is triggered, this function will be called with the event as second parameter.
Like this, it is possible to add a custom behaviour when the configuration changes, when the screen is expanded, etc.

If you wish to use custom events, start after 100.

------------------------
---- Configuration: ----
------------------------
A button is already in place to open a configuration panel where we define things for the current alarm screen like:
 - Custom right-click menu entries
 - Column visibility and width
 - Access control set-up
 - ...

By default, only the basic settings can be changed (i.e. the UI ones). It is possible to extend this by providing a function xxAlarm_getConfigPanels().
This function has to return a dyn_string, each element following this format: PanelFile;PanelTitle;$P1:XXX;$P2:YYY--... where
  - PanelFile is the path to the configuration panel (e.g. "vision/myAlarm/myConfigPanel.pnl"). The size of the panel must be 600x500 to fit the main config panel.
  - PanelTitle is the text to display for this configuration panel (e.g. "MyAlarm configuration")
  - $Pxxx are all the dollar parameters to pass to the config panel (and their value)
  - The ; is defined through FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR, use this instead of plain text.
For each line in the returned dyn_string a new configuration panel will be added.
When everything is closed, the event FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_CHANGED is triggered.

Note that the user must be authorized to write datapoints in order to save any configuration.

-------------------------------------------
---- Custom right click configuration: ----
-------------------------------------------
The user can save a set of custom right click menu entries to be added dynamically to a panel.
To each new right click entry you must provide a function to call.
This function has to take the following parameters (in the following order):
  - string sAlarmDpe          : The DPE in alarm.
  - atime atAlertTime         : The ID of the alarm.
  - anytype aCellValue        : The content of the cell that was clicked.
  - string sClickedColumnName : The name of the clicked column.
  - int iClickedRow           : The clicked row.

-----------------------
--- Access control: ---
-----------------------
If access control is set up (i.e. fwAccessControl is installed), a function xxAlarm_userChanged(string sUser) can be defined.
If defined, this function will be called every time a new user logs in. Remember that this function will be called from the reference panel so all variables defined in the scopelib of your alarm panel will not be visible.


------------------------
---- Busy callback: ----
------------------------
If defined, the function xxAlarm_busyStateChanged(int iState) will be called every time the busy state of the alarm changes.


------------------------------
---- Distributed control: ----
------------------------------
The "systemInfo" widget provides help with distributed system monitoring. You don't need to worry about how to manage your system connections any-more.
If defined, the function xxxAlarm_systemConnected(string sSystemName) will be called when a system comes online. The parameter is the name of this new system.
The function xxxAlarm_systemDisconnected(string sSystemName) will be called when a system goes offline. The parameter is the name of this system.



  @par Creation Date
  07/01/2013

  @par Modification History
  24/05/2017 Adrian Crestar Santome
  - There are certain columns that have to be "enabled" via the "AE-Row/Screen" config panel in order
    to be shown in the AlarmScreen.
    For example, by default, the "alarmPanel" column is not enabled, so even if the user wants to show it,
    it will get hidden again automatically.
    In order to make it visible permanently, these columns will be added to the PropertiesDP ".Both.Visible.VisibleColumns"
    element when the user decides to save the column configuration.
    
    - The DPE FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY is connected to a function from 'fwAlarmScreen.ctl'.
      Every time there is a change in that DPE, the function will be called to update the ".Both.Visible.VisibleColumns"
      element in the AES Properties DP.
      
  19/05/2017 Adrian Crestar Santome
  - @jira{FWAH-355}: Button in the 'Options' panel to save the column configuration.
    - The columns visibility and the width are stored in the DP via this button.
      Any change done in the column configuration without "saving" it, will be available
      only during runtime.
    - In 'fwAlarmScreenGenericConfigSubPanel.pnl":
      - The checkboxes for "column visibility" and "save width" were removed.
      - Their functionality is now provided via the "Save" button.
    - In this file:
      - New DPE: ".runtime.columnsVisibility" to store the visibility without making it "permanent".
        (.global.columnsVisibility).
      - The function "fwAlarmScreenGeneric_config_save" has a new parameter, bSaveToDisk, which
        defaults to false. When calling this function with it set to true, it will store
        the column configuration in the "global" config of the DP.
      - The function "fwAlarmScreenGeneric_saveColumnsWidth" will set the flag "SAVE_COLUMNS_WIDTH" to false.
        This flag is set to true only when saving the column configuration via the 'Save' button.
      - The function 'fwAlarmScreenGeneric_setColumnVisibility" now has an input parameter to decide
        whether to load the "runtime" visibilitly or the "persistent" one.
      - The "fwAlarmScreenGeneric_openConfigPanel" function will:
        - Update the runtime visibility to the current one.
        - And, when closing the config panel:
          - Save the columns width (instead of doing it when closing the alarm screen).
          - Set the column visibility from the runtime configuration.

    05/04/2017: Adrian Crestar Santome
      - @jira{FWAH-359} Put text counter in black if 0 alarms are in the lists.
	  - Two new constants, FW_ALARM_GENERIC_EMPTY_ALARM_COUNTER_COLOR and FW_ALARM_GENERIC_NOT_EMPTY_ALARM_COUNTER_COLOR,
	    to define the text counter colors when the alarm list is empty or not.
	  - In _fwAlarmScreenGeneric_alarmCount: set the foreground color of the text counters.

  @author
	Cyril Caillaba (EN-ICE-SCD)
*/

// due to ETM-1385 we needed to declare dyn_string g_counterConnectId ourselves; no need anymore as it is in aes.ctl now.
#uses "aes.ctl" 
#uses "unDistributedControl/unDistributedControl.ctl"

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// -------------------------------- CONSTANTS -----------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

// Functions called with execScript.
const string  FW_ALARM_GENERIC_FUNCTION_CLOSE_PANEL             = "_closePanel";                          // Called when the panel is closed.
const string  FW_ALARM_GENERIC_FUNCTION_HEADER_GET_HEIGHT       = "_getHeaderHeight";                     // Get the height of the header rectangle.
const string  FW_ALARM_GENERIC_FUNCTION_HEADER_SHOW             = "_showHeader";                          // Show/hide the header content.
const string  FW_ALARM_GENERIC_FUNCTION_INFO_GET_HEIGHT         = "_getInfoHeight";                       // Get the height of the info rectangle.
const string  FW_ALARM_GENERIC_FUNCTION_INFO_MOVE               = "_moveInfo";                            // Move the info rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_INFO_SHOW               = "_showInfo";                            // Show/hide the info rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_GET_HEIGHT = "_getTableFilterHeight";                // Get the height of the table filter rectangle.
const string  FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_MOVE       = "_moveTableFilter";                     // Move the table filter rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_SHOW       = "_showTableFilter";                     // Show/hide the table filter rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_GET_HEIGHT  = "_getAlertFilterHeight";                // Get the height of the alarm filter rectangle.
const string  FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_MOVE        = "_moveAlertFilter";                     // Move the alarm filter rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_SHOW        = "_showAlertFilter";                     // Show/hide the alarm filter rectangle content.
const string  FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING          = "_eventHandler";                        // Treat any event.
const string  FW_ALARM_GENERIC_FUNCTION_GET_CONFIG_PANEL        = "_getConfigPanels";                     // Get configuration panel(s).
const string  FW_ALARM_GENERIC_FUNCTION_GET_SHOWABLE_COLUMNS    = "_getShowableColumns";                  // Get showable/hiddable columns.
const string  FW_ALARM_GENERIC_FUNCTION_USER_CHANGED            = "_userChanged";                         // Treat a change of user.
const string  FW_ALARM_GENERIC_FUNCTION_BUSY_STATE_CHANGED      = "_busyStateChanged";                    // Treat a change of busy state.
const string  FW_ALARM_GENERIC_FUNCTION_INVOKED_AES_USER_FUNC   = "_invokedAESUserFunc";                  // Invoked AES user function (for aesuser.ctl merge FWAH-256).
const string  FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_MENU        = "_getRightClickMenuOptions";            // Treat a right click on any alarm.
const string  FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_EXEC        = "_treatRightClickAnswer";               // Treat the right click menu option selected.
const string  FW_ALARM_GENERIC_FUNCTION_ON_RIGHT_CLICK          = "_onTableRightClick";                   // Treat a right click on any alarm.
const string  FW_ALARM_GENERIC_FUNCTION_IS_ADMIN                = "_isAdmin";                             // Check if the current user has admin rights or not.
const string  FW_ALARM_GENERIC_FUNCTION_SYSTEM_CONNECTED        = "_systemConnected";                     // Treat the connection of a system.
const string  FW_ALARM_GENERIC_FUNCTION_SYSTEM_DISCONNECTED     = "_systemDisconnected";                  // Treat the disconnection of a system.
const string  FW_ALARM_GENERIC_FUNCTION_ACKNOWLEDGE             = "_acknowledgeAll";                      // Acknowledge all the alarm of the given table.

// Widget sizes and position informations
const int     FW_ALARM_GENERIC_FRAME_SPACE                      = 10;                                     // The space between two rectangle.
const int     FW_ALARM_GENERIC_FRAME_WIDTH                      = 1249;                                   // The default with of a rectangle.
const int     FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT             = 23;                                     // The default height of a rectangle.
const int     FW_ALARM_GENERIC_PANEL_BOTTOM                     = 900;                                    // The default position of the bottom indicator line.
const string  FW_ALARM_GENERIC_FRAME_NAME_HEADER                = "";

// Widgets
const string  FW_ALARM_GENERIC_HEADER_FRAME                     = "frameHeader";
const string  FW_ALARM_GENERIC_HEADER_TITLE                     = "frameHeaderTitle";
const string  FW_ALARM_GENERIC_HEADER_REDUCED                   = "frameHeaderReduced";
const string  FW_ALARM_GENERIC_HEADER_EXPANDED                  = "frameHeaderExpanded";
const string  FW_ALARM_GENERIC_HEADER_HIGHLIGHT                 = "frameHeaderHighlight";

const string  FW_ALARM_GENERIC_INFO_FRAME                       = "frameInfo";
const string  FW_ALARM_GENERIC_INFO_TITLE                       = "frameInfoTitle";
const string  FW_ALARM_GENERIC_INFO_REDUCED                     = "frameInfoReduced";
const string  FW_ALARM_GENERIC_INFO_EXPANDED                    = "frameInfoExpanded";
const string  FW_ALARM_GENERIC_INFO_HIGHLIGHT                   = "frameInfoHighlight";

const string  FW_ALARM_GENERIC_TABLE_FILTER_FRAME               = "frameTableFilter";
const string  FW_ALARM_GENERIC_TABLE_FILTER_TITLE               = "frameTableFilterTitle";
const string  FW_ALARM_GENERIC_TABLE_FILTER_REDUCED             = "frameTableFilterReduced";
const string  FW_ALARM_GENERIC_TABLE_FILTER_EXPANDED            = "frameTableFilterExpanded";
const string  FW_ALARM_GENERIC_TABLE_FILTER_HIGHLIGHT           = "frameTableFilterHighlight";

const string  FW_ALARM_GENERIC_ALERT_FILTER_FRAME               = "frameAlertFilter";
const string  FW_ALARM_GENERIC_ALERT_FILTER_TITLE               = "frameAlertFilterTitle";
const string  FW_ALARM_GENERIC_ALERT_FILTER_REDUCED             = "frameAlertFilterReduced";
const string  FW_ALARM_GENERIC_ALERT_FILTER_EXPANDED            = "frameAlertFilterExpanded";
const string  FW_ALARM_GENERIC_ALERT_FILTER_HIGHLIGHT           = "frameAlertFilterHighlight";


// References to the added widgets.
const string  FW_ALARM_GENERIC_REF_HEADER                       = "refHeader";                            // The reference to the symbol in the header section.
const string  FW_ALARM_GENERIC_REF_INFO                         = "refInfo";                              // The reference to the symbol in the info section.
const string  FW_ALARM_GENERIC_REF_TABLE_FILTER                 = "refTableFilter";                       // The reference to the symbol in the table filter section.
const string  FW_ALARM_GENERIC_REF_ALERT_FILTER                 = "refAlertFilter";                       // The reference to the symbol in the alarm filter section.
const string  FW_ALARM_GENERIC_SCREEN_READY                     = "READY";                                // Content of the text-field fwAlarmScreenReadyCheck when the panel is ready.
const string  FW_ALARM_GENERIC_NO_USER                          = "";                                     // Current user name when no user is logged in.
const string  FW_ALARM_GENERIC_WIDGET_SYSTEM_STATE              = "fwAlarmScreenGeneric_systemInfoLabel"; // Widget showing the state of remote systems
const string  FW_ALARM_GENERIC_WIDGET_SYSTEM_INFO_REF           = "fwAlarmScreenGeneric_refSystemInfo";   // Reference of the widget showing the state of remote systems

// Constants for index in hidden check-boxes storing states of menu items
const int     FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX            = 0;
const int     FW_ALARM_GENERIC_INFO_EXPANDED_INDEX              = 1;
const int     FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX       = 2;
const int     FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX       = 3;

// Other
const int     FW_ALARM_GENERIC_DATA_UPDATE_RATE                 = 2;                                      // Delay to wait before counting the alarms.
const string  FW_ALARM_GENERIC_ALARM_NOT_ACKNOWLEDGED_LABEL     = " !!! ";                                // Label of the "ack" column when the alarm is not acknowledged.
const int     FW_ALARM_GENERIC_RIGHT_CLICK_CUSTOM_MENU_MIN      = 100000;                                 // Index of the answer to the first right click menu custom entry.
const string  FW_ALARM_GENERIC_EMPTY_ALARM_COUNTER_COLOR        = "black";                                // Color of the text counter if there are no alarms in the list.
const string  FW_ALARM_GENERIC_NOT_EMPTY_ALARM_COUNTER_COLOR    = "red";                                  // Color of the text counter if there are alarms in the list.

// ------------------------------------------------------------------------------
// ------------------- Global Variables -----------------------------------------
// ------------------------------------------------------------------------------


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------------- ACTION FUNCTIONS -------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

synchronized void fwAlarmScreenGeneric_onTableRightClick(int iRow, string sColumn)
{
	if (iRow < 0)
	{
		return;
	}

	dyn_string dsMenuCustom = _fwAlarmScreenGeneric_config_getCustomMenu();
	dynAppend(dsMenuCustom, "SEPARATOR");

	if (isFunctionDefined(fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_MENU))
	{
		dyn_string dsMenuTemp;
		evalScript(
			dsMenuTemp,
			"dyn_string main()" +
			"{" +
			"  return " + fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_MENU + "(" + iRow + ",\"" + sColumn + "\");"
			+"}",
			makeDynString()
		);

		dynAppend(dsMenuCustom, dsMenuTemp);

	}

	int iAnswer;
	popupMenu(dsMenuCustom, iAnswer);

	if (iAnswer > FW_ALARM_GENERIC_RIGHT_CLICK_CUSTOM_MENU_MIN)
	{
		_fwAlarmScreenGeneric_config_proceedCustomMenuAnswer(iRow, sColumn, iAnswer);
	}
	else
	{
		if (isFunctionDefined(fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_EXEC))
		{
			execScript(
				"main(dyn_string dsMenu)" +
				"{" +
				fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_RIGHT_CLICK_EXEC + "(" + iAnswer + "," + iRow + ",\"" + sColumn + "\", dsMenu);"
				+"}",
				makeDynString(dsMenuCustom)
			);
		}
	}
}

void fwAlarmScreenGeneric_initScreen()
{
	int iHeaderWidth;
	int iHeaderHeight;

	table_top.visible(false);
	dyn_string dsExceptions;

	// -------------------------------------------------------------------
	// ---- 1) Global
	// -------------------------------------------------------------------
	if (isDollarDefined("$sWindowTitle"))
	{
		myModuleName($sWindowTitle);
		alarmTitle.text($sWindowTitle);
	}

	// Hide main frame?
	if (isDollarDefined("$bHideMainFrame"))
	{
		bool bHideMainFrame = $bHideMainFrame;
		if (bHideMainFrame)
		{
			alarmTitle.visible(false);
			backgroundRectangle.visible(false);
		}
	}

	// -------------------------------------------------------------------
	// ---- 2) Info
	// -------------------------------------------------------------------

	// Set info frame title
	if (isDollarDefined("$sInfoTitle") && ("" != $sInfoTitle))
	{
		fwAlarmScreenGeneric_sInfoFrameTitle = $sInfoTitle;
		frameInfoTitle.text(fwAlarmScreenGeneric_sInfoFrameTitle);
	}
	else
	{
		fwAlarmScreenGeneric_sInfoFrameTitle = frameInfoTitle.text();
		frameInfoTitle.text(fwAlarmScreenGeneric_sInfoFrameTitle);
	}

	// Add info panel if defined
	int iInfoWidth;
	int iInfoHeight;
	getValue("frameInfo", "size", iInfoWidth, iInfoHeight);
	if ((isDollarDefined("$sInfoPanel")) && ("" != $sInfoPanel))
	{
		int iX;
		int iY;
		getValue("frameInfo", "position", iX, iY);
		// Get new header size
		int iNewInfoHeight = _fwAlarmScreenGeneric_getInfoHeight();

		// Show header
		setValue("frameInfo", "size", iInfoWidth, iNewInfoHeight);
		addSymbol(
			myModuleName(),
			myPanelName(),
			$sInfoPanel,
			FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_REF_INFO,
			makeDynString(),
			iX,
			iY,
			0,
			1,
			1
		);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_INFO_EXPANDED_INDEX, TRUE);
	}
	else
	{
		// Otherwise hide info frame
		frameInfo.visible(false);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_INFO_EXPANDED_INDEX, FALSE);
		setValue("frameInfoTitle", "visible", FALSE);
		setValue("frameInfoReduced", "visible", FALSE);
		setValue("frameInfoExpanded", "visible", FALSE);
		setValue("frameInfoHighlight", "visible", FALSE);
	}


	// -------------------------------------------------------------------
	// ---- 3) Table filter
	// -------------------------------------------------------------------

  
	// Set table filter frame title
	if (isDollarDefined("$sTableFilterTitle") && ("" != $sTableFilterTitle))
	{
		fwAlarmScreenGeneric_sTableFilterFrameTitle = $sTableFilterTitle;
		frameTableFilterTitle.text(fwAlarmScreenGeneric_sTableFilterFrameTitle);
	}
	else
	{
		fwAlarmScreenGeneric_sTableFilterFrameTitle = frameTableFilterTitle.text();
		frameTableFilterTitle.text(fwAlarmScreenGeneric_sTableFilterFrameTitle);
	}

  
	// Add TableFilter panel if defined
	int iTableFilterWidth;
	int iTableFilterHeight;
	getValue("frameTableFilter", "size", iTableFilterWidth, iTableFilterHeight);
  
	if ((isDollarDefined("$sTableFilterPanel")) && ("" != $sTableFilterPanel))
	{    

		int iX;
		int iY;
		getValue("frameTableFilter", "position", iX, iY);
		// Get new header size
    
		int iNewTableFilterHeight = _fwAlarmScreenGeneric_getTableFilterHeight();

		// Show header
		setValue("frameTableFilter", "size", iTableFilterWidth, iNewTableFilterHeight);
		addSymbol(
			myModuleName(),
			myPanelName(),
			$sTableFilterPanel,
			FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_REF_TABLE_FILTER,
			makeDynString(),
			iX,
			iY,
			0,
			1,
			1
		);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX, TRUE);  
	}
	else
	{ 
   	// Otherwise hide info frame
		frameTableFilter.visible(false);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX, FALSE);
		setValue("frameTableFilterTitle", "visible", FALSE);
		setValue("frameTableFilterReduced", "visible", FALSE);
		setValue("frameTableFilterExpanded", "visible", FALSE);
		setValue("frameTableFilterHighlight", "visible", FALSE);
	}

  
	// -------------------------------------------------------------------
	// ---- 4) Alarm filter
	// -------------------------------------------------------------------

	// Set Alert filter frame title
	getValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iHeaderWidth, iHeaderHeight);
	if (isDollarDefined("$sAlertFilterTitle") && ("" != $sAlertFilterTitle))
	{
		fwAlarmScreenGeneric_sAlarmFilterFrameTitle = $sAlertFilterTitle;
		frameAlertFilterTitle.text(fwAlarmScreenGeneric_sAlarmFilterFrameTitle);
	}
	else
	{
		fwAlarmScreenGeneric_sAlarmFilterFrameTitle = frameAlertFilterTitle.text();
		frameAlertFilterTitle.text(fwAlarmScreenGeneric_sAlarmFilterFrameTitle);
	}

	// Add Alert Filter panel if defined
	int iAlertFilterWidth;
	int iAlertFilterHeight;
	getValue("frameInfo", "size", iAlertFilterWidth, iAlertFilterHeight);
	if ((isDollarDefined("$sAlertFilterPanel")) && ("" != $sAlertFilterPanel))
	{

		int iX;
		int iY;
		getValue("frameAlertFilter", "position", iX, iY);

		// Get new alert filter size
		int iNewAlertFilterHeight = _fwAlarmScreenGeneric_getAlertFilterHeight();

		// Show alert filter panel
		setValue("frameAlertFilter", "size", iAlertFilterWidth, iNewAlertFilterHeight);
		addSymbol(
			myModuleName(),
			myPanelName(),
			$sAlertFilterPanel,
			FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_REF_ALERT_FILTER,
			makeDynString(),
			iX,
			iY,
			0,
			1,
			1
		);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX, TRUE);
		// It is the last frame so no need to move anything below
  
	}
	else
	{
		// Otherwise hide Alert filter frame and move up the others
		frameAlertFilter.visible(false);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX, FALSE);
		setValue("frameAlertFilterTitle", "visible", FALSE);
		setValue("frameAlertFilterReduced", "visible", FALSE);
		setValue("frameAlertFilterExpanded", "visible", FALSE);
		setValue("frameAlertFilterHighlight", "visible", FALSE);
	}

	// -------------------------------------------------------------------
	// ---- 5) Header
	// -------------------------------------------------------------------

	// Set header frame title
	if (isDollarDefined("$sHeaderTitle") && ("" != $sHeaderTitle))
	{
		fwAlarmScreenGeneric_sHeaderFrameTitle = $sHeaderTitle;
		frameHeaderTitle.text(fwAlarmScreenGeneric_sHeaderFrameTitle);
	}
	else
	{
		fwAlarmScreenGeneric_sHeaderFrameTitle = frameHeaderTitle.text();
		frameHeaderTitle.text(fwAlarmScreenGeneric_sHeaderFrameTitle);
	}

	// Add header panel if defined

	getValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iHeaderWidth, iHeaderHeight);
	if ((isDollarDefined("$sHeaderPanel")) && ("" != $sHeaderPanel))
	{
		int iX;
		int iY;
		getValue(FW_ALARM_GENERIC_HEADER_FRAME, "position", iX, iY);
		// Get new header size
		int iNewHeaderHeight = _fwAlarmScreenGeneric_getHeaderHeight();

		// Show header
		setValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iHeaderWidth, iNewHeaderHeight);
		addSymbol(
			myModuleName(),
			myPanelName(),
			$sHeaderPanel,
			FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_REF_HEADER,
			makeDynString(),
			iX,
			iY,
			0,
			1,
			1
		);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX, TRUE);
	}
	else
	{
		// Otherwise hide header frame
		frameHeader.visible(false);
		isExpandedCheckbox.state(FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX, FALSE);
		setValue("frameHeaderTitle", "visible", FALSE);
		setValue("frameHeaderReduced", "visible", FALSE);
		setValue("frameHeaderExpanded", "visible", FALSE);
		setValue("frameHeaderHighlight", "visible", FALSE);
	}

	// -------------------------------------------------------------------
	// ---- 6) Re-organize the view to look cleaner
	// -------------------------------------------------------------------

	_fwAlarmScreenGeneric_rearrangeScreen();

	// Hide the useless rectangle at the bottom of the AES panel
	setValue("RECTANGLE1", "visible", false);


	// -------------------------------------------------------------------
	// ---- 7) Callbacks
	// -------------------------------------------------------------------
	string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);
	while (!dpExists(sPropertiesDp))
	{
		delay(0, 1);
	}
	dpConnect("fwAlarmScreenGeneric_busyCallBack", false, sPropertiesDp + ".Settings.BusyTrigger" + AES_ORIVAL);

	if(isFunctionDefined("fwAccessControl_setupPanel")) // i.e. if access control is installed
	{
		sCurrentUser = getUserName();
		fwAccessControl_setupPanel("fwAlarmScreenGeneric_accessControlCB", dsExceptions);
	}

	// -------------------------------------------------------------------
	// ---- 8) Event handling
	// -------------------------------------------------------------------
	if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING))
	{
		_fwAlarmScreenGeneric_config_connectEvent(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING);
	}

	// -------------------------------------------------------------------
	// ---- 9) Init system info widget
	// -------------------------------------------------------------------
	fwAlarmScreenGeneric_initSystemInfo();

	// -------------------------------------------------------------------
	// ---- 10) Load config
	// -------------------------------------------------------------------
	// Wait for table to be ready = wait for at least one line or 1 second
	bool bReady = false;
	time tBefore = getCurrentTime();

	table_top.visible(true);
	while (!bReady)
	{
		if (table_top.lineCount() > 0 || period(getCurrentTime() - tBefore) > 1)
		{
			bReady = true;
		}
		else
		{
			delay(0, 20);
		}
	}

	fwAlarmScreenGeneric_config_load();

	// The screen is ready!
	pushButtonGenericSettings.enabled(true);
	pushButtonExpand.enabled(true);

	frameHeader.enabled(true);
	frameHeaderTitle.enabled(true);
	frameHeaderExpanded.enabled(true);
	frameHeaderReduced.enabled(true);

	frameInfo.enabled(true);
	frameInfoTitle.enabled(true);
	frameInfoExpanded.enabled(true);
	frameInfoReduced.enabled(true);

	frameTableFilter.enabled(true);
	frameTableFilterTitle.enabled(true);
	frameTableFilterExpanded.enabled(true);
	frameTableFilterReduced.enabled(true);

	frameAlertFilter.enabled(true);
	frameAlertFilterTitle.enabled(true);
	frameAlertFilterExpanded.enabled(true);
	frameAlertFilterReduced.enabled(true);

	_fwAlarmScreenGeneric_disableActions();

	fwAlarmScreenReadyCheck.text(FW_ALARM_GENERIC_SCREEN_READY);
	fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_INITIALIZED);
  
  if(isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + "_setAesColumnVisibility")) {
    const string sDp = _fwAlarmScreenGeneric_config_getDpName();
    dpConnect(FW_ALARM_GENERIC_ALARM_CLASS + "_setAesColumnVisibility", false, sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY);
  }
}



// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------- ALARM COUNTER WIDGET FUNCTIONS -----------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

const string FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET = "fwAlarmScreenGeneric_alarmInfo_activeFilter";  // Text widget to show the current filter.
const string FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_GROUP_WIDGET  = "fwAlarmScreenGeneric_alarmInfo_activeGroup";   // Text widget to show the current group.

void fwAlarmScreenGeneric_setActiveFilter(const string sFilterLabel)
{
	setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET, "text", sFilterLabel);
	setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET, "visible", "" != sFilterLabel);
}

void fwAlarmScreenGeneric_setActiveGroup(const string sGroupLabel)
{
	setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_GROUP_WIDGET, "text", sGroupLabel);
	setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_GROUP_WIDGET, "visible", "" != sGroupLabel);

	// When hiding the group, show the active filter if necessary.
	if ("" == sGroupLabel)
	{
		string sActiveFilter;
		getValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET, "text", sActiveFilter);

		setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET, "visible", "" != sActiveFilter);
	}
	else
	{
		setValue(FW_ALARM_GENERIC_ALARM_INFO_ACTIVE_FILTER_WIDGET, "visible", false);
	}
}

/**
  @par Description:
  Initialize the widget that counts how many alarms are in the table and how many of them are not acknowledged.

  @par Usage:
  Public.
*/
void fwAlarmScreenGeneric_initAlarmCounter()
{
	startThread("_fwAlarmScreenGeneric_alarmCount");
}

/**
  @par Description:
  Infinite loop that counts the alarms in the table to display them in the appropriate widget.

  @par Usage:
  Internal.
*/
void _fwAlarmScreenGeneric_alarmCount()
{
	// Warning, this can sometimes start too fast and the table is not ready yet.
	// That's why we first wait until the column exists.
	int iAckColumnIndex = -1;
	while (iAckColumnIndex < 0)
	{
		delay(FW_ALARM_GENERIC_DATA_UPDATE_RATE);

		int iColumnCount;
		getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);

		for (int i = 0 ; i < iColumnCount ; i++)
		{
			string sColumnName;
			getValue(AES_TABLENAME_TOP, "columnName", i, sColumnName);

			if ("acknowledge" == sColumnName)
			{
				iAckColumnIndex = i;
				break;
			}
		}
	}


	while(1)
	{
		delay(FW_ALARM_GENERIC_DATA_UPDATE_RATE);

		int iAckable = 0;
		int iLineCount = 0;

		// Get all alarms
		getValue(AES_TABLENAME_TOP, "lineCount", iLineCount);

		// Get unacked alarms.
		dyn_string dsAckState;
		getValue(AES_TABLENAME_TOP, "getColumnN", iAckColumnIndex, dsAckState);

		int iLength = dynlen(dsAckState);
		for (int i = 1 ; i <= iLength ; i++)
		{
			if (FW_ALARM_GENERIC_ALARM_NOT_ACKNOWLEDGED_LABEL == dsAckState[i])
			{
				iAckable++;
			}
		}

		alarmTableLines.text = iLineCount;
		unackedAlarms.text = iAckable;

		alarmTableLines.foreCol = (0 == iLineCount)?FW_ALARM_GENERIC_EMPTY_ALARM_COUNTER_COLOR:FW_ALARM_GENERIC_NOT_EMPTY_ALARM_COUNTER_COLOR;
		unackedAlarms.foreCol = (0 == iAckable)?FW_ALARM_GENERIC_EMPTY_ALARM_COUNTER_COLOR:FW_ALARM_GENERIC_NOT_EMPTY_ALARM_COUNTER_COLOR;
	}
}

/**
  @par Description:
  Acknowledge all the alarms in the table.

  @par Usage:
  Internal.

  @param[in]  bVisibleRangeOnly bool, True to acknowledge only the alarm in the visible range of the table.
*/
void _fwAlarmScreenGeneric_acknowledgeAll(bool bVisibleRangeOnly = false)
{
	const string sTable = AES_TABLENAME_TOP;
	// Ack everything.

	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();
	if (isFunctionDefined(sAlarmClass + FW_ALARM_GENERIC_FUNCTION_ACKNOWLEDGE))
	{
		// An exec script prevents from using threads inside the called function.
		// Acknowledging is more efficient done in parallel so we use a startThread to allow using threads inside the thread (threadception!)
		startThread(sAlarmClass + FW_ALARM_GENERIC_FUNCTION_ACKNOWLEDGE, sTable, bVisibleRangeOnly);
	}
	else
	{
		mapping m;
		if (bVisibleRangeOnly)
		{
			aes_prepareForTableAcknowledge(AES_CHANGED_ACKALLVIS, AESTAB_TOP, m);
			aes_changedAcknowledgeWithRowData(AES_CHANGED_ACKALLVIS, AESTAB_TOP, m);
		}
		else
		{
			aes_prepareForTableAcknowledge(AES_CHANGED_ACKALL, AESTAB_TOP, m);
			aes_changedAcknowledgeWithRowData(AES_CHANGED_ACKALL, AESTAB_TOP, m);
		}
	}
}



// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------- SYSTEM STATE WIDGET FUNCTIONS ------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Get the list of systems connected to the local system. Local system is included.

  @par Usage:
  Public.

  @return The list of connected systems.
*/
dyn_string fwAlarmScreenGeneric_getConnectedSystems()
{
	return fwAlarmScreenGeneric_onlineSystemList.items();
}

/**
  @par Description:
  Initialize the widget that displays the state of the connected systems.

  @par Usage:
  Public.
*/
void fwAlarmScreenGeneric_initSystemInfo()
{
	dyn_string dsExceptions;

	// --- 1) Connect all the system state callbacks (triggered when a system connects/disconnects

	dyn_string dsSystemNames;
	dyn_int diSystemIds;
	dyn_string dsHostNames;
	dyn_int diPortNumbers;
	unDistributedControl_getAllDeviceConfig(dsSystemNames, diSystemIds, dsHostNames, diPortNumbers);


	string sSystemName = getSystemName();
	fwAlarmScreenGeneric_onlineSystemList.appendItem(strrtrim(sSystemName, ":"));

	for (int i = 1 ; i <= dynlen(dsSystemNames) ; i++)
	{
		if (dsSystemNames[i] == strrtrim(getSystemName(), ":") || ("" == dsSystemNames[i]))
		{
			continue;
		}

		bool bRes;
		bool bConnected;
		unDistributedControl_register("_fwAlarmScreenGeneric_systemStateCB", bRes, bConnected, dsSystemNames[i] + ":", dsExceptions);
	}

	// --- 2) Connect the callback to the filtered systems list
	string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);
	while (!dpExists(sPropertiesDp))
	{
		delay(0, 50);
	}

	dpConnect("_fwAlarmScreenGeneric_filteredSystemsCB", true, sPropertiesDp + ".Both.Systems.Selections");


	// --- 3) Display errors
	if (dynlen(dsExceptions) > 0)
	{
		fwExceptionHandling_display(dsExceptions);
	}
}

/**
  @par Description:
  Callback triggered when a system changes its connection state.

  @par Usage:
  Internal:

  @param  sDpe    string input, The system DPE that triggered the CB.
  @param  bState  bool input,   The state of this system: true for connected, false for disconnected.
*/
void _fwAlarmScreenGeneric_systemStateCB(string sDpe, bool bState)
{
	dyn_string dsConnectedSystemsOld = fwAlarmScreenGeneric_onlineSystemList.items();
	dyn_string dsDisconnectedSystemsOld = fwAlarmScreenGeneric_offlineSystemList.items();

	string sSystemName = dpSubStr(sDpe, DPSUB_DP);
	strreplace(sSystemName, c_unDistributedControl_dpName, "");

	// Sometimes the name is empty
	if ("" == sSystemName)
	{
		return;
	}

	// Local system is always connected
	if (sSystemName + ":" == getSystemName())
	{
		bState = true;
	}

	dyn_string dsConnectedSystems     = fwAlarmScreenGeneric_onlineSystemList.items();
	dyn_string dsDisconnectedSystems  = fwAlarmScreenGeneric_offlineSystemList.items();

	int iConnectedPos = dynContains(dsConnectedSystems, sSystemName);
	int iDisconnectedPos = dynContains(dsDisconnectedSystems, sSystemName);

	// Already connected: no change
	if ((iConnectedPos > 0) && bState)
	{
		return;
	}

	// Already disconnected: no change
	if ((iDisconnectedPos > 0) && !bState)
	{
		return;
	}


	if (iConnectedPos > 0)
	{
		dynRemove(dsConnectedSystems, iConnectedPos);
	}

	if (iDisconnectedPos > 0)
	{
		dynRemove(dsDisconnectedSystems, iDisconnectedPos);
	}

	if (bState)
	{
		dynAppend(dsConnectedSystems, sSystemName);
	}
	else
	{
		dynAppend(dsDisconnectedSystems, sSystemName);
	}

	dynUnique(dsConnectedSystems);
	dynUnique(dsDisconnectedSystems);

	fwAlarmScreenGeneric_onlineSystemList.deleteAllItems();
	fwAlarmScreenGeneric_offlineSystemList.deleteAllItems();

	fwAlarmScreenGeneric_onlineSystemList.items(dsConnectedSystems);
	fwAlarmScreenGeneric_offlineSystemList.items(dsDisconnectedSystems);

	_fwAlarmScreenGeneric_updateSystemState();


	// If something has changed, notify it.
	// Ignore if it is the first time, i.e. when both lists are empty (local system is always in connected list, so empty means <= 1).
	if ((dynlen(dsConnectedSystemsOld) > 1) || (dynlen(dsDisconnectedSystemsOld) > 0))
	{
		dyn_string dsConnectedSystems = fwAlarmScreenGeneric_onlineSystemList.items();
		dyn_string dsDisconnectedSystems = fwAlarmScreenGeneric_offlineSystemList.items();

		// New system connected?
		for (int i = 1 ; i <= dynlen(dsConnectedSystems) ; i++)
		{
			if (dynContains(dsConnectedSystemsOld, dsConnectedSystems[i]) < 1)
			{
				_fwAlarmScreenGeneric_systemConnected(dsConnectedSystems[i]);
			}
		}

		// System disconnected?
		for (int i = 1 ; i <= dynlen(dsDisconnectedSystems) ; i++)
		{
			if (dynContains(dsDisconnectedSystemsOld, dsDisconnectedSystems[i]) < 1)
			{
				_fwAlarmScreenGeneric_systemDisconnected(dsDisconnectedSystems[i]);
			}
		}
	}
}

/**
  @par Description:
  Callback triggered when the AES system filter changes.

  @par Usage:
  Internal:

  @param  sDpe      string input,     The system DPE that triggered the CB.
  @param  dsSystems dyn_string input, The list of systems currently included in the filter.
*/
void _fwAlarmScreenGeneric_filteredSystemsCB(string sDpe, dyn_string dsSystems)
{
	fwAlarmScreenGeneric_filteredSystemList.deleteAllItems();
	fwAlarmScreenGeneric_filteredSystemList.items(dsSystems);

	_fwAlarmScreenGeneric_updateSystemState();
}

/**
  @par Description:
  Update the display of the state of the filtered systems.

  @par Usage:
  Internal.
*/
void _fwAlarmScreenGeneric_updateSystemState()
{
	dyn_string dsConnectedSystems     = fwAlarmScreenGeneric_onlineSystemList.items();
	dyn_string dsDisconnectedSystems  = fwAlarmScreenGeneric_offlineSystemList.items();
	dyn_string dsFilteredSystems      = fwAlarmScreenGeneric_filteredSystemList.items();

	bool bAllSytemsOk = true;
	dyn_string dsMissingSystems;
	for (int i = 1 ; i <= dynlen(dsFilteredSystems) ; i++)
	{
		if (dynContains(dsDisconnectedSystems, dsFilteredSystems[i]) > 0)
		{
			bAllSytemsOk = false;
			dynAppend(dsMissingSystems, dsFilteredSystems[i]);
		}
	}

	string sLabel;
	string sToolTip;
	if (bAllSytemsOk)
	{
		fwAlarmScreenGeneric_systemInfoLabel.foreCol("FwStateOKPhysics");
		fwAlarmScreenGeneric_systemInfoLabel.backCol("white");
		sLabel = "  All selected systems online";
		sToolTip = "All the systems in the current filter are connected";
	}
	else
	{
		fwAlarmScreenGeneric_systemInfoLabel.foreCol("_3DText");
		fwAlarmScreenGeneric_systemInfoLabel.backCol("FwAlarmFatalUnack");
		sToolTip = "Some systems in the current filter are disconnected";
		sLabel = "  ";
		for (int i = 1 ; i <= dynlen(dsMissingSystems) ; i++)
		{
			sLabel += dsMissingSystems[i];

			if (i != dynlen(dsMissingSystems))
			{
				sLabel += ", ";
			}
		}

		sLabel += ": offline";
	}

	fwAlarmScreenGeneric_systemInfoLabel.text(sLabel);
	fwAlarmScreenGeneric_systemInfoLabel.toolTipText(sToolTip);
}

void _fwAlarmScreenGeneric_systemConnected(const string sSystem)
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	if (isFunctionDefined(sAlarmClass + FW_ALARM_GENERIC_FUNCTION_SYSTEM_CONNECTED))
	{
		execScript(
			"main(string sSystemName)" +
			"{" +
			"  " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_SYSTEM_CONNECTED + "(sSystemName);" +
			"}",
			makeDynString(),
			sSystem
		);
	}
}

void _fwAlarmScreenGeneric_systemDisconnected(const string sSystem)
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	if (isFunctionDefined(sAlarmClass + FW_ALARM_GENERIC_FUNCTION_SYSTEM_DISCONNECTED))
	{
		execScript(
			"main(string sSystemName)" +
			"{" +
			"  " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_SYSTEM_DISCONNECTED + "(sSystemName);" +
			"}",
			makeDynString(),
			sSystem
		);
	}
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------ CONFIGURATION ---------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
/*
Each panel has its appearance saved as soon as modified. This will be loaded when the panel is opened again later.
There is one configuration for each panel class and for each user.

The parameters saved are:
  - State of each part of the UI: reduced or expanded.
  - State of the whole window: reduced or expanded.
  - ...
*/

// Datapoints
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_DPTYPE                  = "_FwAlarmPanelConfig";        // The DP type of a configuration.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_DP_PREFIX               = "_fwAlarmPanelConfig_";       // The prefix of each datapoint created.
const string  FWALARMSCREEN_GENERIC_SETTINGS_DPTYPE                       = "_FwAlarmPanelSettings";      // The DP type of the settings DP.
const string  FWALARMSCREEN_GENERIC_SETTINGS_DP                           = "_fwAlarmPanelSettings";      // The settings DP.

// Categories
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_HEADER                  = ".header";                    // Parameters for the header widget.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_INFO                    = ".info";                      // Parameters for the info widget.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_TABLE_FILTER            = ".tableFilter";               // Parameters for the table filter widget.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_ALARM_FILTER            = ".alarmFilter";               // Parameters for the alarm filter widget.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL                  = ".global";                    // Parameters for the whole panel.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME                 = ".runtime";                   // Parameters "alive" only during runtime.

// Parameters
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED                 = ".reduced";                   // Whether or not the widget is reduced.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_WIDTH           = ".global.columnsWidth";       // Width of each column. dyn_string of columnName;width.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SAVE_WIDTH      = ".global.saveWidth";          // Whether or not the with should be saved.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SAVE_VISIBILITY = ".global.saveVisibility";     // Whether or not the with should be saved.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY      = ".global.columnsVisibility";  // Visibility of each column. dyn_string of columnName;visible.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR       = ";";                          // Whether or not the with should be saved.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_USE_PERSISTANCE         = ".global.usePersistance";     // Whether or not to load the configuration at start up.
const string  FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY = FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME + ".columnsVisibility";   // Visibility at runtime.

const string  FWALARMSCREEN_GENERIC_CONFIGURATION_EVENT                   = ".event";                     // To pass any event

const string  FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR         = ";";


// List of predefined events within the fwAlarmScreenGeneric panel
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_WHOLE             = 1;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_HEADER            = 2;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_INFO              = 3;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_TABLE_FILTER      = 4;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_ALARM_FILTER      = 5;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_INITIALIZED              = 6;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_CHANGED           = 7;
const int     FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_LOADED            = 8;


// ----------------------------
// ---------- Global ----------
// ----------------------------

/**
  @par Description:
  Open the configuration panel.

  @par Usage:
  Internal.

*/
void    fwAlarmScreenGeneric_config_openConfigPanel()
{
	// Config parameters.
	// Each element should be:
	// $i:PanelFile;PanelTitle;$P1:XXX;$P2:YYY--...
	dyn_string dsParameters;
	int iParamIndex = 0;

	// Alarm class
	dynAppend(dsParameters, "$sAlarmClass:" + FW_ALARM_GENERIC_ALARM_CLASS);

	// Which columns are showable for this current instance of the generic panel?
	dyn_string dsShowableColumns;
	if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_GET_SHOWABLE_COLUMNS))
	{
		evalScript(
			dsShowableColumns,
			"dyn_string main()" +
			"{" +
			"  return " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_GET_SHOWABLE_COLUMNS + "();"
			"}",
			makeDynString()
		);
	}

	dyn_string dsColumnNames;
	dyn_int diColumnWidth;
	dyn_bool dbColumnVisibility;
	dyn_string dsColumnHeader;
	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);

    /* When opening the AlarmScreen without persistence,
     * we need to update the runtime visibility.
     * Otherwise, when closing the panel it will apply the "previous" one.
     */
    dyn_string dsRuntimeColumnVisibility;

	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;
		bool bColumnVisible;
		string sColumnHeader;

		getValue(AES_TABLENAME_TOP, "columnName", i, sColumnName);
		getValue(AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth);
		getValue(AES_TABLENAME_TOP, "columnVisibility", i, bColumnVisible);
		getValue(AES_TABLENAME_TOP, "columnHeader", i, sColumnHeader);

		// When the visibility of a column is set to false, internally its size is set to 0 and visibility stays at true.
		if (0 == iColumnWidth)
		{
			bColumnVisible = false;
		}

		if (dynContains(dsShowableColumns, sColumnName) > 0)
		{
			dynAppend(dsColumnNames, sColumnName);
			dynAppend(diColumnWidth, iColumnWidth);
			dynAppend(dbColumnVisibility, bColumnVisible);
			dynAppend(dsColumnHeader, sColumnHeader);
      dynAppend(dsRuntimeColumnVisibility, sColumnName + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR + bColumnVisible);
		}
	}

  _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY, dsRuntimeColumnVisibility);

	dynAppend(dsParameters,
			  "$" + iParamIndex++ + ":fwAlarmHandling/fwAlarmScreenGenericConfigSubPanel.pnl"  + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "Custom appearance"                                                                   + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "$sAlarmClass:" + FW_ALARM_GENERIC_ALARM_CLASS                                        + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "$dsColumnNames:" + dsColumnNames                                                     + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "$diColumnWidth:" + diColumnWidth                                                     + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "$dsColumnHeader:" + dsColumnHeader                                                   + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			  "$dbColumnVisibility:" + dbColumnVisibility
			 );

	if (_fwAlarmScreenGeneric_config_isAdmin())
	{
		dynAppend(dsParameters,
				  "$" + iParamIndex++     + ":fwAlarmHandling/fwAlarmScreenGenericConfigSubPanel_userConfig.pnl" + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "Monitor user rights"                                                                               + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$sHeaderName:"         + fwAlarmScreenGeneric_sHeaderFrameTitle                                    + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$sInfoName:"           + fwAlarmScreenGeneric_sInfoFrameTitle                                      + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$sTableFilterName:"    + fwAlarmScreenGeneric_sTableFilterFrameTitle                               + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$sAlarmFilterName:"    + fwAlarmScreenGeneric_sAlarmFilterFrameTitle                               + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$bHeaderExists:"       + frameHeaderTitle.visible()                                                + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$bInfoExists:"         + frameInfoTitle.visible()                                                  + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$bTableFilterExists:"  + frameTableFilterTitle.visible()                                           + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "$bAlarmFilterExists:"  + frameAlertFilterTitle.visible()
				 );


		dynAppend(dsParameters,
				  "$" + iParamIndex++     + ":fwAlarmHandling/fwAlarmScreenGenericConfigSubPanel_rightClickMenu.pnl" + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
				  "Right-click menu"                                                                                      + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR
				 );
	}


	// Get the list of configuration sub-panels that need to be shown in the list on the left side of the main alarm-screen-configuration panel.
	if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_GET_CONFIG_PANEL))
	{
		dyn_string dsParametersTemp;
		evalScript(
			dsParametersTemp,
			"dyn_string main()" +
			"{" +
			"  return " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_GET_CONFIG_PANEL + "();"
			"}",
			makeDynString()
		);

		for (int i = 1 ; i <= dynlen(dsParametersTemp) ; i++)
		{
			dynAppend(dsParameters, "$" + iParamIndex++ + ":" + dsParametersTemp[i]);
		}
	}

	dyn_float dfReturn;
	dyn_string dsReturn;
	ChildPanelOnCentralModalReturn(
		"fwAlarmHandling/fwAlarmScreenGenericConfig.pnl",
		"Settings",
		dsParameters,
		dfReturn,
		dsReturn
	); // "Return" to block execution

	_fwAlarmScreenGeneric_setColumnsVisibility(true);
    _fwAlarmScreenGeneric_saveColumnsSize();

	fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_CHANGED);
}

/**
  @par Description:
  Get the configuration datapoint for the current user and the current panel.

  @par Usage:
  Internal.
*/
string  _fwAlarmScreenGeneric_config_getDpName()
{
	string sUser = getUserName();
	string sDp = FWALARMSCREEN_GENERIC_CONFIGURATION_DP_PREFIX + fwAlarmScreenGenericAlarmClass.text() + "_" + sUser;

	if ((FW_ALARM_GENERIC_NO_USER == sUser) || (!_fwAlarmScreenGeneric_config_authorizedUser() && !dpExists(sDp)))
	{
		return "";
	}

	return sDp;
}

/**
  @par Description:
  Initialize the configuration for the current user and the current panel.

  @par Usage:
  Internal.
*/
void    _fwAlarmScreenGeneric_config_init(const string sDp)
{
	dpCreate(sDp, FWALARMSCREEN_GENERIC_CONFIGURATION_DPTYPE);

	dpSet(
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_HEADER          + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED,  false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_INFO            + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED,  false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_TABLE_FILTER    + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED,  false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_ALARM_FILTER    + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED,  false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL          + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED,  false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_USE_PERSISTANCE,                                                false,
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_WIDTH,                                                  makeDynString(),
		sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY,                                             makeDynString(),
    sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY,                                     makeDynString()
	);

}

/**
  @par Description:
  Set a configuration element to the given value.

  @par Usage:
  Internal.

  @param  sParameter  string input,   The parameter to set (see constants FWALARMSCREEN_GENERIC_CONFIGURATION_xxx).
  @param  aValue      anytype input,  The value to assign to this parameter.
*/
void    _fwAlarmScreenGeneric_config_set(const string sParameter, const anytype aValue)
{
	if (!_fwAlarmScreenGeneric_config_authorizedUser())
	{
		return;
	}

	string sDp = _fwAlarmScreenGeneric_config_getDpName();

	if ("" == sDp)
	{
		return;
	}

	if (!dpExists(sDp))
	{
		_fwAlarmScreenGeneric_config_init(sDp);
	}

	dpSetWait(sDp + sParameter, aValue);
}

/**
  @par Description:
  Get the value of the given parameter.

  @par Usage:
  Internal.

  @param  sParameter  string input,   The parameter to set (see constants FWALARMSCREEN_GENERIC_CONFIGURATION_xxx).

  @return The current value of this parameter.
*/
anytype _fwAlarmScreenGeneric_config_get(const string sParameter)
{
	string sDp = _fwAlarmScreenGeneric_config_getDpName();

	anytype aValue;

	if ("" == sDp)
	{
		return aValue;
	}

	if (!dpExists(sDp))
	{
		_fwAlarmScreenGeneric_config_init(sDp);
	}


	dpGet(sDp + sParameter, aValue);

	return aValue;
}

// ------------------------------------
// ---------- Access control ----------
// ------------------------------------
/**
  @par Description:
  Check if the current user is allowed to write datapoints.

  @par Usage:
  Internal.

  @return True if he can, false otherwise.
*/
bool    _fwAlarmScreenGeneric_config_authorizedUser()
{
	return getUserPermission(4);
}

/**
  @par Description:
  Check if the current user has admin rights.
  If the function xxAlarm_isAdmin() is defined the result will come from it. Otherwise, by default it corresponds to user level 4.

  @par Usage:
  Internal.

  @return True if the current user has admin rights, false otherwise.
*/
bool    _fwAlarmScreenGeneric_config_isAdmin()
{
	if (isFunctionDefined(fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_IS_ADMIN))
	{
		bool bIsAdmin;
		evalScript(
			bIsAdmin,
			"bool main()" +
			"{" +
			"  return " + fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_IS_ADMIN + "();"
			"}",
			makeDynString()
		);

		return bIsAdmin;
	}
	else
	{
		return _fwAlarmScreenGeneric_config_authorizedUser();
	}
}

// --------------------------------------
// ---------- Event management ----------
// --------------------------------------

/**
  @par Description:
  Trigger an event.

  @par Usage:
  Public.

  @param  iEvent  int input,  The event to trigger (see constants FWALARMSCREEN_GENERIC_CONFIG_EVENT_xxx).
*/
void    fwAlarmScreenGeneric_config_triggerEvent(const int iEvent)
{
	_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_EVENT, iEvent);
}

/**
  @par Description:
  Connect the given callback to function to be triggered on any event.

  @par Usage:
  Internal.

  @param  sWork string input, The callback function.
*/
void    _fwAlarmScreenGeneric_config_connectEvent(const string sWork)
{
	string sUser = getUserName();

	if (FW_ALARM_GENERIC_NO_USER == sUser)
	{
		return;
	}

	string sDp = _fwAlarmScreenGeneric_config_getDpName();

	if ("" == sDp)
	{
		return;
	}

	if (!dpExists(sDp))
	{
		_fwAlarmScreenGeneric_config_init(sDp);
	}

	dpConnect(sWork, false, sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_EVENT);
}

/**
  @par Description:
  Disconnect the given callback to function to be triggered on any event for the given user.

  @par Usage:
  Internal.

  @param  sWork string input, The callback function.
  @param  sUser string input, The user to disconnect for.
*/
void    _fwAlarmScreenGeneric_config_disconnectEvent(const string sWork, string sUser)
{
	string sDp = FWALARMSCREEN_GENERIC_CONFIGURATION_DP_PREFIX + FW_ALARM_GENERIC_ALARM_CLASS + "_" + sUser;

	if (FW_ALARM_GENERIC_NO_USER == sUser || "" == sUser)
	{
		return;
	}

	if (!dpExists(sDp))
	{
		return;
	}

	dpDisconnect(sWork, sDp + FWALARMSCREEN_GENERIC_CONFIGURATION_EVENT);
}

// --------------------------------------
// ---------- Right click menu ----------
// --------------------------------------
// In the future, it could be possible to add other custom menu entries than simple function calls.
// The constants FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_TYPE_xxx define those possible types.
// A custom parameter list can be added for any type of action.
const string  FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS        = ".customMenu.labels";         // The custom right click options labels.
const string  FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES         = ".customMenu.types";          // The custom right click options types.
const string  FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS        = ".customMenu.params";         // The custom right click options parameters.
const int     FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_TYPE_FUNC_CALL   = 0;
const int     FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_TYPE_DPSET       = 1;
const string  FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_PARAM_SEPARATOR  = "~";


dyn_string _fwAlarmScreenGeneric_config_getCustomMenu()
{
	int iMenuOptionIndex = FW_ALARM_GENERIC_RIGHT_CLICK_CUSTOM_MENU_MIN + 1;

	dyn_string dsEntryLabels;

	dpGet(FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels);


	dyn_string dsMenu;

	for (int i = 1 ; i <= dynlen(dsEntryLabels) ; i++)
	{
		dynAppend(dsMenu,
				  "PUSH_BUTTON, " + dsEntryLabels[i] + ", "  + iMenuOptionIndex++ + ", 1"
				 );
	}

	return dsMenu;
}

void _fwAlarmScreenGeneric_config_proceedCustomMenuAnswer(const int iRow, const string sColumn, int iAnswer)
{
	int iIndex = iAnswer - FW_ALARM_GENERIC_RIGHT_CLICK_CUSTOM_MENU_MIN;

	dyn_string dsEntryLabels;
	dyn_int diEntryTypes;
	dyn_string dsEntryParams;

	dpGet(
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES,  diEntryTypes,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS, dsEntryParams
	);

	if (dynlen(dsEntryLabels) >= iIndex)
	{
		switch (diEntryTypes[iIndex])
		{
			case FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_TYPE_FUNC_CALL:
			{
				dyn_string dsParams = strsplit(dsEntryParams[iIndex], FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_PARAM_SEPARATOR);
				if (dynlen(dsParams) > 0)
				{
					string sFunctionCall = dsParams[1];

					if (!isFunctionDefined(sFunctionCall))
					{
						return;
					}


					string sClickedColumnName = sColumn;
					int iClickedRow = iRow;
					anytype aCellValue;
					string sAlarmDpe;
					atime atAlertTime;
					getMultiValue(
						AES_TABLENAME_TOP, "cellValueRC", iClickedRow, sClickedColumnName, aCellValue,
						AES_TABLENAME_TOP, "cellValueRC", iClickedRow, _DPID_, sAlarmDpe,
						AES_TABLENAME_TOP, "cellValueRC", iClickedRow, _TIME_, atAlertTime
					);

					sAlarmDpe = dpSubStr(sAlarmDpe, DPSUB_SYS_DP_EL);

					execScript(
						"main(string sAlarmDpe, atime atAlertTime, anytype aCellValue, string sClickedColumnName, int iClickedRow)" +
						"{" +
						sFunctionCall + "(sAlarmDpe, atAlertTime, aCellValue, sClickedColumnName, iClickedRow);"
						"}",
						makeDynString(),
						sAlarmDpe,
						atAlertTime,
						aCellValue,
						sClickedColumnName,
						iClickedRow
					);

				}
			}
			default:
			{
				break;
			}
		}
	}
}

void _fwAlarmScreenGeneric_config_addCustomMenuEntry(const string sMenuEntryLabel, const int iEntryType, const dyn_string dsParameters)
{
	dyn_string dsEntryLabels;
	dyn_int diEntryTypes;
	dyn_string dsEntryParams;

	dpGet(
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES,  diEntryTypes,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS, dsEntryParams
	);

	string sStringParams;
	for (int i = 1 ; i <= dynlen(dsParameters) ; i++)
	{
		sStringParams += dsParameters[i];
		if (i != dynlen(dsParameters))
		{
			sStringParams += FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_PARAM_SEPARATOR;
		}
	}

	// Replace entry if it exists
	int iPos = dynContains(dsEntryLabels, sMenuEntryLabel);
	if (iPos > 0)
	{
		dsEntryLabels[iPos] = sMenuEntryLabel;
		diEntryTypes[iPos] = iEntryType;
		dsEntryParams[iPos] = sStringParams;
	}
	else
	{
		dynAppend(dsEntryLabels, sMenuEntryLabel);
		dynAppend(diEntryTypes, iEntryType);
		dynAppend(dsEntryParams, sStringParams);
	}


	dpSetWait(
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES,  diEntryTypes,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS, dsEntryParams
	);


	return;
	switch(iEntryType)
	{
		case FWALARMSCREEN_GENERIC_SETTINGS_CUSTOM_MENU_TYPE_FUNC_CALL:
		{

			break;
		}
		default:
		{
			break;
		}
	}
}

void _fwAlarmScreenGeneric_config_deleteCustomMenuEntry(const string sMenuEntryLabel)
{

	dyn_string dsEntryLabels;
	dyn_int diEntryTypes;
	dyn_string dsEntryParams;

	dpGet(
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES,  diEntryTypes,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS, dsEntryParams
	);

	for (int i = 1 ; i <= dynlen(dsEntryLabels) ; i++)
	{
		int iPos = dynContains(dsEntryLabels, sMenuEntryLabel);
		if (iPos > 0)
		{
			dynRemove(dsEntryLabels, iPos);
			dynRemove(diEntryTypes, iPos);
			dynRemove(dsEntryParams, iPos);

			break;
		}
	}

	dpSetWait(
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_LABELS, dsEntryLabels,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_TYPES,  diEntryTypes,
		FWALARMSCREEN_GENERIC_SETTINGS_DP + FWALARMSCREEN_GENERIC_SETTINGS_DP_CUSTOM_MENU_PARAMS, dsEntryParams
	);
}
// ---------------------------------
// ---------- UI settings ----------
// ---------------------------------

/**
  @par Description:
  Save the configuration. Can be called ONLY from the config panel.

  @par Usage:
  Internal.
*/
void fwAlarmScreenGeneric_config_save(const bool bSaveToDisk = false)
{
	// Reload panel on start-up?
	_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_USE_PERSISTANCE, checkBoxReloadOnStartup.state(0));

	// Visibility
	dyn_string dsColumnVisibility;

	// Visible
	dyn_string dsVisibleItems = listVisibleColumns.items();
	for (int i = 1 ; i <= dynlen(dsVisibleItems) ; i++)
	{
		dynAppend(dsColumnVisibility, mHeaderToName[dsVisibleItems[i]] + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR + true);
	}

	// Hidden.
	dyn_string dsHiddenItems = listHiddenColumns.items();
	for (int i = 1 ; i <= dynlen(dsHiddenItems) ; i++)
	{
		dynAppend(dsColumnVisibility, mHeaderToName[dsHiddenItems[i]] + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR + false);
	}

  _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY, dsColumnVisibility);

  if(bSaveToDisk) {
 	  _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY, dsColumnVisibility);
    _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SAVE_WIDTH, true);
  }
}

/**
  @par Description:
  Load the configuration. To be used at startup (or when user changes).

  @par Usage:
  Public.

*/
void fwAlarmScreenGeneric_config_load()
{
	// Maybe the user doesn't want his settings to be reloaded.
	bool bLoadConfig = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_USE_PERSISTANCE);
	if (!bLoadConfig)
	{
		// Reset window state
		_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, !bExpanded);
		return;
	}

	// Expand window?
	bool bReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);
	if (bReduced && bExpanded)
	{
		_fwAlarmScreenGeneric_reduceWindow();
		fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_WHOLE);
	}
	else if (!bReduced && !bExpanded)
	{
		_fwAlarmScreenGeneric_expandWindow();
		fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_WHOLE);
	}

	// Reduce header?
	if (frameHeader.visible())
	{
		bool bHeaderReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_HEADER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);
		setValue("isExpandedCheckbox", "state", FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX, bHeaderReduced);
		if (bHeaderReduced)
		{
			_fwAlarmScreenGeneric_reduceFrame(FW_ALARM_GENERIC_HEADER_FRAME);
		}
		else
		{
			_fwAlarmScreenGeneric_expandFrame(FW_ALARM_GENERIC_HEADER_FRAME);
		}
	}

	// Reduce info?
	if (frameInfo.visible())
	{
		bool bInfoReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_INFO + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);
		setValue("isExpandedCheckbox", "state", FW_ALARM_GENERIC_INFO_EXPANDED_INDEX, bInfoReduced);
		if (bInfoReduced)
		{
			_fwAlarmScreenGeneric_reduceFrame("frameInfo");
		}
		else
		{
			_fwAlarmScreenGeneric_expandFrame("frameInfo");
		}
	}

	// Reduce table filter?
	if (frameTableFilter.visible())
	{
		bool bTableFilterReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_TABLE_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);
		setValue("isExpandedCheckbox", "state", FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX, bTableFilterReduced);
		if (bTableFilterReduced)
		{
			_fwAlarmScreenGeneric_reduceFrame("frameTableFilter");
		}
		else
		{
			_fwAlarmScreenGeneric_expandFrame("frameTableFilter");
		}
	}

	// Reduce alarm filter?
	if (frameAlertFilter.visible())
	{
		bool bAlarmFilterReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_ALARM_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);
		setValue("isExpandedCheckbox", "state", FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX, bAlarmFilterReduced);
		if (bAlarmFilterReduced)
		{
			_fwAlarmScreenGeneric_reduceFrame("frameAlertFilter");
		}
		else
		{
			_fwAlarmScreenGeneric_expandFrame("frameAlertFilter");
		}
	}

	_fwAlarmScreenGeneric_resizeColumns();

	// Column visibility
	_fwAlarmScreenGeneric_setColumnsVisibility();


	fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_LOADED);
}

/**
  @par Description:
  Save the config when given widget is reduced.

  @par Usage:
  Public.

  @param  sWidget string input, The reduced widget.
*/
void fwAlarmScreenGeneric_config_reduce(const string sWidget)
{
	switch(sWidget)
	{
		case fwAlarmScreenGeneric_sHeaderFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_HEADER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, true);
			break;
		}
		case fwAlarmScreenGeneric_sInfoFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_INFO + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, true);
			break;
		}
		case fwAlarmScreenGeneric_sTableFilterFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_TABLE_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, true);
			break;
		}
		case fwAlarmScreenGeneric_sAlarmFilterFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_ALARM_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, true);
			break;
		}
		default:
		{
			break;
		}
	}
}

/**
  @par Description:
  Save the config when given widget is expanded.

  @par Usage:
  Public.

  @param  sWidget string input, The expanded widget.
*/
void fwAlarmScreenGeneric_config_expand(const string sWidget)
{
	switch(sWidget)
	{
		case fwAlarmScreenGeneric_sHeaderFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_HEADER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, false);
			break;
		}
		case fwAlarmScreenGeneric_sInfoFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_INFO + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, false);
			break;
		}
		case fwAlarmScreenGeneric_sTableFilterFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_TABLE_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, false);
			break;
		}
		case fwAlarmScreenGeneric_sAlarmFilterFrameTitle:
		{
			_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_ALARM_FILTER + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, false);
			break;
		}
		default:
		{
			break;
		}
	}
}

void _fwAlarmScreenGeneric_saveColumnsSize()
{
	// Save the width?
	bool bSaveWidth = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SAVE_WIDTH);
	if (!bSaveWidth)
	{
		return;
	}


	dyn_string dsColumnWidth;

	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		getValue(AES_TABLENAME_TOP, "columnName", i, sColumnName);

		int iColumnWidth;
		getValue(AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth);

		if (iColumnWidth > 0)
		{
			dynAppend(dsColumnWidth, sColumnName + FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR + iColumnWidth);
		}
	}

	_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_WIDTH, dsColumnWidth);
    _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SAVE_WIDTH, false);
}

void _fwAlarmScreenGeneric_resizeColumns()
{
	dyn_string dsColumnWidth = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_WIDTH);
	for (int i = 1 ; i <= dynlen(dsColumnWidth) ; i++)
	{
		dyn_string dsColumn = strsplit(dsColumnWidth[i], FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR);
		string sColumnName = dsColumn[1];
		int iColumnWidth = dsColumn[2];
		setValue(AES_TABLENAME_TOP, "namedColumnWidth", sColumnName, iColumnWidth);
	}
}

void _fwAlarmScreenGeneric_setColumnsVisibility(const bool bRuntime = false)
{
  dyn_string dsColumnVisibility;
  if(bRuntime) {
    dsColumnVisibility = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY);
    if(dynlen(dsColumnVisibility) == 0) {
      return;
    }
  } else {
    dsColumnVisibility = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_VISIBILITY);
  }

	for (int i = 1 ; i <= dynlen(dsColumnVisibility) ; i++)
	{
		dyn_string dsColumn = strsplit(dsColumnVisibility[i], FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR);
		string sColumnName = dsColumn[1];
		bool bColumnVisible = dsColumn[2];

		setValue(AES_TABLENAME_TOP, "namedColumnVisibility", sColumnName, bColumnVisible);
		// If the column is now visible, sometimes its size can be 0. In this case, force to a non null value.
		if (bColumnVisible)
		{
			int iWidth;
			getValue(AES_TABLENAME_TOP, "namedColumnWidth", sColumnName, iWidth);
			if (0 == iWidth)
			{
				setValue(AES_TABLENAME_TOP, "namedColumnWidth", sColumnName, 50);
			}
		}
	}
}


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------- CB FUNCTIONS----------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

void fwAlarmScreenGeneric_busyCallBack(string sDpe, const int iBusyState)
{
	// When AES is restarted (new filter applied) the column are reset to default.
	// This trick will prevent this.
	if(iBusyState == AES_BUSY_START)
	{
		dynClear(diColumnsSize);
		int iColumnCount;
		getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
		for (int i = 0 ; i < iColumnCount ; i++)
		{
			int iColumnWidth;
			getValue(AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth);
			dynAppend(diColumnsSize, iColumnWidth);
		}
	}
	else if(iBusyState == AES_BUSY_STOP)
	{
		int iColumnCount;
		getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
		for (int i = 1 ; i <= dynlen(diColumnsSize) ; i++)
		{
			setValue(AES_TABLENAME_TOP, "columnWidth", i - 1, diColumnsSize[i]);
		}
	}



	if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_BUSY_STATE_CHANGED))
	{
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_BUSY_STATE_CHANGED + "(" + iBusyState + ");" +
			"}",
			makeDynString()
		);
	}
}

void fwAlarmScreenGeneric_accessControlCB(string sDp, string sValue)
{
	if (sValue != sCurrentUser)
	{
		if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING))
		{
			_fwAlarmScreenGeneric_config_disconnectEvent(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING, sCurrentUser);
			_fwAlarmScreenGeneric_config_connectEvent(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_EVENT_HANDLING);
		}

		sCurrentUser = sValue;
		_fwAlarmScreenGeneric_disableActions();
		fwAlarmScreenGeneric_config_load();

		if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_USER_CHANGED))
		{
			execScript(
				"main()" +
				"{" +
				"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_USER_CHANGED + "(\"" + sCurrentUser + "\");" +
				"}",
				makeDynString()
			);
		}
	}
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------- UI FUNCTIONS----------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

// -----------------------------------------
// ------- Combo-check-box functions -------
// -----------------------------------------
/**
  Functions to show and use several check-boxes instead of a combo-box wherever it is possible. This panel is intended for alarm/event list use, but could actually be adapted to be used anywhere.

  Since the table containing all the check-boxes has to be on top of any other widget, it is added dynamically.
  Because of that there is a problem when several of this widget are on the same panel. One widget can write inside another.
  That is why the variable g_sReferenceName is used before access to UI elements. It is defined both in the main panel and in the reference one (containing only a table).
*/
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE                = "fwAlarmScreenGeneric_combochecktable";
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON               = "fwAlarmScreenGeneric_combo_button";
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD           = "fwAlarmScreenGeneric_combo_filterFieldEdit";
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS           = "fwAlarmScreenGeneric_combo_elementList";
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_SELECTED_ITEMS  = "fwAlarmScreenGeneric_combo_selectedElementList";
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER       = "fwAlarmScreenGeneric_combo_currentFilter";                           // Text field containing the current filter applied on the table.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_SELECTION    = "fwAlarmScreenGeneric_combo_currentSelectionLabel";                   // Text field containing the content of the main text field before clicking on it (click erases it).
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_CHECKBOX_ACTION      = "fwAlarmScreenGeneric_combo_actionDone";                              // Check-box indicating if any action has been done after showing the table.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_CHECKBOX_MOUSE_OVER  = "fwAlarmScreenGeneric_combo_mouseOverTable";                          // Check-box indicating if the mouse is over the text field or the table.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF            = "fwAlarmScreenGeneric_combo_referenceTable";                          // Reference under which the table is added.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_REFERENCE_NAME       = "fwAlarmScreenGeneric_combo_refName";                                 // Text field containing the name of the reference with which the widget was added.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF_PANEL      = "fwAlarmHandling/fwAlarmScreenGeneric_combocheckbox_table.pnl";  // Panel containing the table to add dynamically.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK    = "CHECK";    // Name of the table column containing check state of the items.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT  = "ELEMENT";  // Name of the table column containing the items.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_LABEL_ALL      = "All";      // Label to show for the item that selects all available elements.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL           = "*";        // Label to show when all items are selected.
const string  FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_LIST          = "List...";  // Label to show when a list of items is selected.
const int     FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_ROW_HEIGHT     = 20;   // Height of a table row.
const int     FW_ALARM_GENERIC_COMBOCHECKBOX_MAX_ELEMENT_SCROLL   = 15;   // Max number of element visible without scrolling.
const int     FW_ALARM_GENERIC_COMBOCHECKBOX_MOUSEOVER_TIMEOUT    = 500;  // Milliseconds to wait on mouse-over text edit or table before hiding the table.

/**
  @par Description:
  Set the item list for the given widget.

  @par Usage:
  Public.

  @param  sReference  string input,     The name given to the reference when the widget was added.
  @param  dsElements  dyn_string input, The list of items to show. Duplicate items are removed.
*/
void fwAlarmScreenGeneric_combocheckbox_setItems(const string sReference, dyn_string dsElementList)
{
	// Ignore if the reference doesn't exist.
	if (!shapeExists(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS))
	{
		return;
	}

	dynUnique(dsElementList);
	setValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElementList);
	setValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL);

	string sRefName;
	getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_REFERENCE_NAME, "text", sRefName);
	if (shapeExists(sRefName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
	{
		removeSymbol(myModuleName(), myPanelName(), sRefName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF);
	}
}

/**
  @par Description:
  Get the item list of the given widget.

  @par Usage:
  Public.

  @param  sReference  string input,     The name given to the reference when the widget was added.

  @return The list of elements that can be selected.
*/
dyn_string fwAlarmScreenGeneric_combocheckbox_getItems(const string sReference)
{
	dyn_string dsElements;
	getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElements);
	return dsElements;
}

/**
  @par Description:
  Set the selected items list of the given widget.

  @par Usage:
  Public.

  @param  sReference      string input,         The name given to the reference when the widget was added.
  @param  dsSelectedItemList  dyn_string input, The list of items to select. No check if all items exist in the list.
  @param  bAllAreSelected bool output,          Indicates whether or not all the items are selected.
*/
dyn_string fwAlarmScreenGeneric_combocheckbox_setSelectedItems(const string sReference, const dyn_string dsSelectedItemList, bool bAllAreSelected = false)
{
	dyn_string dsSelectedItemListLocal;

	if (bAllAreSelected)
	{
		dyn_string dsElementList;
		getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElementList);
		dsSelectedItemListLocal = dsElementList;
	}
	else
	{
		dsSelectedItemListLocal = dsSelectedItemList;
	}

	_fwAlarmScreenGeneric_combocheckbox_saveSelection(dsSelectedItemListLocal, (dynlen(dsSelectedItemListLocal) == 1) && !bAllAreSelected, sReference);
}

/**
  @par Description:
  Get the selected items list of the given widget.

  @par Usage:
  Public.

  @param  sReference      string input, The name given to the reference when the widget was added.
  @param  bAllAreSelected bool output,  Indicates whether or not all the items are selected.

  @return The list of elements that can have been selected.
*/
dyn_string fwAlarmScreenGeneric_combocheckbox_getSelectedItems(const string sReference, bool &bAllAreSelected)
{
	string sLabel;
	dyn_string dsSelectedElements;
	dyn_string dsElements;
	getMultiValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_SELECTED_ITEMS, "items", dsSelectedElements,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElements,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", sLabel
	);

	bAllAreSelected = FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL == sLabel;

	if (bAllAreSelected)
	{
		return dsElements;
	}
	else
	{
		return dsSelectedElements;
	}
}

/**
  @par Description:
  Show/hide the entire widget. Use this instead of setValue(REF, "visible", true/false).

  @par Usage:
  Public.

  @param  sReference  string input, The reference of the widget to hide.
  @param  bShow       bool input,   True to show, false to hide.
*/
void fwAlarmScreenGeneric_combocheckbox_showWidget(const string sReference, const bool bShow)
{
	// Ignore if the reference doesn't exist.
	if (!shapeExists(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD))
	{
		return;
	}

	setMultiValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "visible", bShow,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON,               "visible", bShow
	);

	if (!bShow)
	{
		string sTableReference;
		getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_REFERENCE_NAME, "text", sTableReference);
		if (shapeExists(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
		{
			setValue(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF, "visible", bShow);
		}
	}
}

/**
  @par Description:
  Move the entire widget. Use this instead of setValue(REF, "visible", true/false).
  The parameters are NOT the new position but the delta compared to the initial position

  @par Usage:
  Public.

  @param  sReference             string input, The reference of the widget to move.
  @param  iDeltaX, iDeltaY       int input,   move the widgets by X and Y pixels (can be <0)
*/
void fwAlarmScreenGeneric_combocheckbox_moveWidget(const string sReference, const int iDeltaX, const int iDeltaY)
{
  int iOldX, iOldY;
	// Ignore if the reference doesn't exist.
	if (!shapeExists(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD))
	{
		return;
	}

  getValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "position", iOldX, iOldY
	);
  setValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "position", iOldX+iDeltaX, iOldY+iDeltaY
	);
  
	getValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON,               "position", iOldX, iOldY
	);
  setValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON,               "position", iOldX+iDeltaX, iOldY+iDeltaY
	);

	
	string sTableReference;
	getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_REFERENCE_NAME, "text", sTableReference);
	if (shapeExists(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
	{
		getValue(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF, "position", iOldX, iOldY);
		setValue(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF, "position", iOldX+iDeltaX, iOldY+iDeltaY);      
	}
}

/**
  @par Description:
  Enable/disable the entire widget. Use this instead of setValue(REF, "enabled", true/false).

  @par Usage:
  Public.

  @param  sReference  string input, The reference of the widget to hide.
  @param  bEnabled    bool input,   True to enable, false to disable.
*/
void fwAlarmScreenGeneric_combocheckbox_enableWidget(const string sReference, const bool bEnabled)
{
	// Ignore if the reference doesn't exist.
	if (!shapeExists(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD))
	{
		return;
	}

	setMultiValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "enabled", bEnabled,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON,               "enabled", bEnabled
	);

	if (!bEnabled)
	{
		string sTableReference;
		getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_REFERENCE_NAME, "text", sTableReference);
		if (shapeExists(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
		{
			setValue(sTableReference + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF, "visible", bEnabled);
		}
	}
}

/**
  @par Description:
  Show the table with all the elements. If some elements had been selected previously, they are selected again on loading.

  @par Usage:
  Internal.

  @param  sElementListNameParam         string input, The widget with list of elements to show in the table. Operation cancelled if does not exist.
  @param  sSelectedElementListNameParam string input, The widget with list of elements already selected. Operation cancelled if does not exist.
*/
void _fwAlarmScreenGeneric_combocheckbox_show()
{
	if (!shapeExists(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
	{
		addSymbol(myModuleName(), myPanelName(), FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF_PANEL, g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF, makeDynString("$sReferenceName:" + g_sReferenceName), 0, 0, 0, 1, 1);
		while (!shapeExists(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE))
		{
			delay(0, 20); // s,millisec
		}

		// Hide columns headers
		// Set height
		// Set selection by column and multiple lines
		// Empty the table
		setMultiValue(
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "columnHeaderVisibility", false,
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "rowHeight", FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_ROW_HEIGHT,
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "selectByClick", TABLE_SELECT_LINE_COLUMN,
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "tableMode", TABLE_SELECT_MULTIPLE,
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "deleteAllLines"
		);

		dyn_string dsElementList;
		getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElementList);

		// The size of the table is the size of the text field and the button (represented by its background rectangle)
		int iTextX;
		int iTextY;
		int iTextHeight;
		int iTextWidth;
		int iRectangleHeight;
		int iRectangleWidth;
		getMultiValue(
			FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "size",     iTextWidth, iTextHeight,
			FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "position",  iTextX, iTextY,
			FW_ALARM_GENERIC_COMBOCHECKBOX_BUTTON, "size",      iRectangleWidth, iRectangleHeight
		);
		int iTableWidth = iTextWidth + iRectangleWidth - 2; // -2 pixel for margin reasons

		// The table can display X items. Below X, the table size is reduced to the minimum possible without scrolling bar. Above X the scrolling bar has to be used.
		int iTableHeight;
		if (dynlen(dsElementList) < FW_ALARM_GENERIC_COMBOCHECKBOX_MAX_ELEMENT_SCROLL)
		{
			iTableHeight = FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_ROW_HEIGHT * (dynlen(dsElementList) + 1 /* "All" line */) + dynlen(dsElementList) + 1 /* For the width of the grid */ ;
		}
		else
		{
			iTableHeight = 10 * FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_ROW_HEIGHT;
		}

		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "size", iTableWidth, iTableHeight);

		// Append an "All" element.
		dynInsertAt(dsElementList, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_LABEL_ALL, 1);

		// Move the table just below the text field.
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "position", iTextX, iTextY + iTextHeight);

		// Fill the table.
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "appendLines", dynlen(dsElementList), FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, dsElementList);

		// Adjust column size to fit the widest entry
		// Need to adjust the table size to match the columns.
		int iElementColumnLengthBefore;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "namedColumnWidth", FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, iElementColumnLengthBefore);

		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "adjustColumn", 1);

		int iElementColumnLength;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "namedColumnWidth", FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, iElementColumnLength);

		if (iElementColumnLength <= iElementColumnLengthBefore) // Never below the default value
		{
			iElementColumnLength = iElementColumnLengthBefore;
		}
		else
		{
			int iWidthDiff = iElementColumnLength - iElementColumnLengthBefore;
			iTableWidth += iWidthDiff;
		}

		// WinCC bug? adjustColumn will increase the size of the column but this change is never visible. Forcing again to the same value seems to solve the problem.
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "namedColumnWidth", FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, iElementColumnLength);
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "size", iTableWidth, iTableHeight);

		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL);
	}

	string sTextFieldContent;
	getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", sTextFieldContent);


	// If the table was already visible, hide it and leave.
	bool bTableVisible;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", bTableVisible);
	if (bTableVisible)
	{
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", false);
		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "editable", false);
		string sPreviousSelection;
		getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_SELECTION, "text", sPreviousSelection);
		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", sPreviousSelection);

		return;
	}

	setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_SELECTION, "text", sTextFieldContent);
	setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", "");

	// If no elements (or only "All") in the table, ignore.
	int iLineCount;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineCount", iLineCount);
	if (iLineCount <= 1)
	{
		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL);
		return;
	}

	dyn_string dsAlreadySelectedElements;
	getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_SELECTED_ITEMS, "items", dsAlreadySelectedElements);

	// Make the text field editable to filter the table.
	setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "editable", true);

	// Check already selected elements
	for (int i = 1 ; i < iLineCount ; i++)
	{
		string sElement;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, sElement);
		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, dynContains(dsAlreadySelectedElements, sElement) > 0);
	}

	// Check "All" if all elements are selected.
	_fwAlarmScreenGeneric_combocheckbox_checkAll();

	// Show the table and put it at the right position
	int iTextWidth;
	int iTextHeight;
	int iTextX;
	int iTextY;
	getMultiValue(
		FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "size",     iTextWidth, iTextHeight,
		FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD,           "position",  iTextX, iTextY
	);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "position", iTextX, iTextY + iTextHeight);


	// Reset action count.
	setValue(g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_CHECKBOX_ACTION, "state", 0, false);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", true);

	// Set the view to the top of the list
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineVisible", 0);
}

/**
  @par Description:
  Save the selected element(s) and display the appropriate label depending if none, one, several or all are selected.

  @par Usage:
  Internal.

  @param  dsSelectedElementList dyn_string input, The list of elements that have been selected.
  @param  bForceSingle          bool input,       If one specific row was clicked force the value to this one only, even if there is only one item in the list (otherwise it would go as "All").
*/
void _fwAlarmScreenGeneric_combocheckbox_saveSelection(const dyn_string dsSelectedElementList, const bool bForceSingle, const string sReferenceParam = "")
{
	string sReference = sReferenceParam;
	if ("" == sReference)
	{
		sReference = g_sReferenceName;
	}

	string sLabel;
	string sBackColor;
	string sToolTip;

	dyn_string dsElementList;
	getValue(sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_ITEMS, "items", dsElementList);
	if ((dynlen(dsSelectedElementList) == 1) || bForceSingle)
	{
		sLabel = dsSelectedElementList[1];
	}
	else if (dynlen(dsSelectedElementList) == dynlen(dsElementList))
	{
		sLabel = FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL;
	}
	else if (dynlen(dsSelectedElementList) > 1)
	{
		sLabel = FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_LIST;
	}
	else
	{
		sLabel = FW_ALARM_GENERIC_COMBOCHECKBOX_FILTER_ALL;
	}

	for (int i = 1 ; i <= dynlen(dsSelectedElementList) ; i++)
	{
		sToolTip += dsSelectedElementList[i] + ", ";
	}
	sToolTip = strrtrim(sToolTip, ",");

	setMultiValue(
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_LIST_SELECTED_ITEMS, "items", dsSelectedElementList,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", sLabel,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "editable", false,
		sReference + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "toolTipText", sToolTip
	);
}

/**
  @par Description:
  Action on hiding the table: Save the element that was clicked or save all the checked elements.
  NB This routine will be called either when clicking on one single element or on mouse-over out of the table.

  @param iClickedRow  int input,  The row of the element clicked. By default -1 if table hidden by mouse-over out.
*/
void _fwAlarmScreenGeneric_combocheckbox_hideTable(const int iClickedRow = -1)
{
	// If the table is not visible it means we got to this function when forcing to hide it.
	// In that case everything was already done so we just ignore it.
	bool bTableVisible;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", bTableVisible);
	if (!bTableVisible)
	{
		return;
	}


	// Check if an action has been done.
	// If not, ignore. Close and set the text back to previous value.
	bool bActionDone;
	getValue(g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_CHECKBOX_ACTION, "state", 0, bActionDone);
	if (!bActionDone)
	{
		string sPreviousSelection;
		getValue(g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_SELECTION, "text", sPreviousSelection);
		setValue(g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TEXT_FIELD, "text", sPreviousSelection);

		setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", false);
		return;
	}



	dyn_string dsSelectedElementList;
	bool bForceSingle = false; // If one specific row was clicked, force the value to this one even if there is only one item in the list (otherwise it would go as "All").

	int iLineCount;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineCount", iLineCount);

	// If a row was clicked, only this one will be selected (unless it's "All")
	// Note: the variable bForceHidden (saved in a check-box) is used to differentiate when the list is hidden with visible(false) instead of mouse-over out, which has a different meaning.
	if (iClickedRow != -1)
	{
		if (0 == iClickedRow) // All
		{
			_fwAlarmScreenGeneric_combocheckbox_selectAll(true);
		}
		else
		{
			for (int i = 0 ; i < iLineCount ; i++)
			{
				setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, false);
			}
			setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", iClickedRow, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, true);
			delay(0, 300); // Delay to show the users everything was unselected

			bForceSingle = true;
		}
	}

	for (int i = 1 ; i < iLineCount ; i++) // Start from 1 to ignore the "All" line
	{
		bool bChecked;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, bChecked);
		if (bChecked)
		{
			string sClickedElement;
			getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, sClickedElement);
			dynAppend(dsSelectedElementList, sClickedElement);
		}
	}


	_fwAlarmScreenGeneric_combocheckbox_saveSelection(dsSelectedElementList, bForceSingle);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", false);
}

/**
  @par Description:
  Filter the content of the table to hide lines that do not match the pattern.

  @par Usage:
  Internal.

  @param  sFilter string input, The pattern to check. Ignored if empty.
*/
void _fwAlarmScreenGeneric_combocheckbox_filterTable(const string sFilter)
{
	if (!shapeExists(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
	{
		return;
	}

	string sLocalFilter = sFilter;
	if ("" == sFilter)
	{
		string sCurrentFilter;
		getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", sCurrentFilter);

		if ("" == sCurrentFilter) // Already no filter.
		{
			return;
		}
		else
		{
			sLocalFilter = "*";
		}

		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", "");
	}
	else
	{
		sLocalFilter =  "*" + sLocalFilter + "*";
		setValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", sLocalFilter);
	}

	// Problem: "All" is not visible any more.
	// Solution: delete and add it again.
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "deleteLineN", 0);

	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "filterRows", makeDynString(FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT), makeDynString(sLocalFilter), true);

	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "insertLineN", 0);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", 0, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_LABEL_ALL);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", 0, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, false);
	_fwAlarmScreenGeneric_combocheckbox_checkAll();
}

/**
  @par Description:
  Select all the elements in the table.

  @par Usage:
  Internal.

  @param  bSelect bool input, True to select, false to unselect.
*/
void _fwAlarmScreenGeneric_combocheckbox_selectAll(const bool bSelect)
{
	int iLineCount;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineCount", iLineCount);

	string sCurrentFilter;
	getValue(g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", sCurrentFilter);

	// Note: table.isRowHidden(i) is bugged and doesn't return the proper value.
	// Instead, the current filter is tested on each line.
	for (int i = 0 ; i < iLineCount ; i++)
	{
		string sItem;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, sItem);

		if (patternMatch(sCurrentFilter, sItem) || (FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_LABEL_ALL == sItem) || ("" == sCurrentFilter))
		{
			setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, bSelect);
		}
	}
}

/**
  @par Description:
  Check if all the visible elements are selected. If they are, check the "All" box.

  @par Usage:
  Internal.
*/
void _fwAlarmScreenGeneric_combocheckbox_checkAll()
{
	if (!shapeExists(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF))
	{
		return;
	}

	int iLineCount;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineCount", iLineCount);

	bool bAllCheched = true;

	shape shTable = getShape(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE);
	for (int i = 1 ; i < iLineCount ; i++)
	{
		string sItem;
		string sCurrentFilter;
		getMultiValue(
			g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, sItem,
			g_sReferenceName + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", sCurrentFilter
		);

		if (patternMatch(sCurrentFilter, sItem) || (FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_LABEL_ALL == sItem) || ("" == sCurrentFilter))
		{
			bool bChecked;
			getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, bChecked);
			if (!bChecked)
			{
				bAllCheched = false;
				break;
			}
		}
	}

	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", 0, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_CHECK, bAllCheched);
}

/**
  @par Description:
  Set all visible items as current selection.

  @par Usage:
  Internal.
*/
void _fwAlarmScreenGeneric_combocheckbox_chooseAllVisible()
{
	dyn_string dsSelectedItems;

	int iLineCount;
	getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "lineCount", iLineCount);

	string sFilter;
	getValue(FW_ALARM_GENERIC_COMBOCHECKBOX_CURRENT_FILTER, "text", sFilter);
	// Note: table.isRowHidden(i) is bugged and doesn't return the proper value.
	// Instead, the current filter is tested on each line.
	// Start from one to ignore "All"
	for (int i = 1 ; i < iLineCount ; i++)
	{
		string sItem;
		getValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "cellValueRC", i, FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_INDEX_ELEMENT, sItem);

		if (patternMatch(sFilter, sItem) || ("" == sFilter))
		{
			dynAppend(dsSelectedItems, sItem);
		}
	}

	_fwAlarmScreenGeneric_combocheckbox_saveSelection(dsSelectedItems, true);
	setValue(g_sReferenceName + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE_REF + "." + FW_ALARM_GENERIC_COMBOCHECKBOX_TABLE, "visible", false);
}

// -----------------------------
// ------- Direct action -------
// -----------------------------

/**
  @par Description:
  Rearrange the panel layout to move all widget to their expected position.

  @Par Usage:
  Public.
*/
void _fwAlarmScreenGeneric_rearrangeScreen()
{
	// For each block, move it up 10 pixels below the first visible one above.
	string sMoveBelowMe;

	// Header block is never moved

	// Info block
	if (frameInfo.visible())
	{
		if (frameHeader.visible())
		{
			sMoveBelowMe = frameHeader.name();
		}
		else
		{
			sMoveBelowMe = lineTopLimit.name();
		}

		int iOldX;
		int iOldY;
		getValue("frameInfo", "position", iOldX, iOldY);
		_fwAlarmScreenGeneric_moveBelow(frameInfo.name(), sMoveBelowMe);

		int iNewX;
		int iNewY;
		getValue("frameInfo", "position", iNewX, iNewY);

		int iYDiff = iNewY - iOldY;
		// Move all the widget like the frame
		_fwAlarmScreenGeneric_moveInfo(iYDiff);
	}

	// Table filter block
	if (frameTableFilter.visible())
	{
		if (frameInfo.visible())
		{
			sMoveBelowMe = frameInfo.name();
		}
		else if (frameHeader.visible())
		{
			sMoveBelowMe = frameHeader.name();
		}
		else
		{
			sMoveBelowMe = lineTopLimit.name();
		}

		int iOldX;
		int iOldY;
		getValue("frameTableFilter", "position", iOldX, iOldY);

		_fwAlarmScreenGeneric_moveBelow(frameTableFilter.name(), sMoveBelowMe);

		int iNewX;
		int iNewY;
		getValue("frameTableFilter", "position", iNewX, iNewY);

		int iYDiff = iNewY - iOldY;
		// Move all the widget like the frame

		_fwAlarmScreenGeneric_moveTableFilter(iYDiff);
	}


	// Alarm filter block
	if (frameAlertFilter.visible())
	{
		if (frameTableFilter.visible())
		{
			sMoveBelowMe = frameTableFilter.name();
		}
		else if (frameInfo.visible())
		{
			sMoveBelowMe = frameInfo.name();
		}
		else if (frameHeader.visible())
		{
			sMoveBelowMe = frameHeader.name();
		}
		else
		{
			sMoveBelowMe = lineTopLimit.name();
		}

		int iOldX;
		int iOldY;
		getValue("frameAlertFilter", "position", iOldX, iOldY);

		_fwAlarmScreenGeneric_moveBelow(frameAlertFilter.name(), sMoveBelowMe);

		int iNewX;
		int iNewY;
		getValue("frameAlertFilter", "position", iNewX, iNewY);

		int iYDiff = iNewY - iOldY;
		// Move all the widget like the frame
		_fwAlarmScreenGeneric_moveAlertFilter(iYDiff);
	}

	// Resize and move table
	fwAlarmScreenGeneric_resizeTable();
}

/**
  @par Description:
  Disable all the widgets to prevent an unauthorized user to change anything.

  @par Usage:
  Internal.
*/
void _fwAlarmScreenGeneric_disableActions()
{
	pushButtonGenericSettings.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	pushButtonExpand.enabled(_fwAlarmScreenGeneric_config_authorizedUser());

	frameHeaderHighlight.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameHeaderTitle.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameHeaderReduced.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameHeaderExpanded.enabled(_fwAlarmScreenGeneric_config_authorizedUser());

	frameInfoHighlight.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameInfoTitle.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameInfoReduced.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameInfoExpanded.enabled(_fwAlarmScreenGeneric_config_authorizedUser());

	frameTableFilterHighlight.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameTableFilterTitle.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameTableFilterReduced.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameTableFilterExpanded.enabled(_fwAlarmScreenGeneric_config_authorizedUser());

	frameAlertFilterHighlight.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameAlertFilterTitle.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameAlertFilterReduced.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
	frameAlertFilterExpanded.enabled(_fwAlarmScreenGeneric_config_authorizedUser());
}

/**
  @par Description:
  Expand or reduce any section of the panel.

  @par Usage:
  Public.

  @param  sFrame  string input, The frame of the section to reduce/expand.
*/
void fwAlarmScreenGeneric_expandOrReduceFrame(string sFrame)
{
	bool bFrameReduced;
	getValue(sFrame + "Reduced", "visible", bFrameReduced);

	if(bFrameReduced)
	{
		// Expand
		_fwAlarmScreenGeneric_expandFrame(sFrame);
	}
	else
	{
		// Reduce
		_fwAlarmScreenGeneric_reduceFrame(sFrame);
	}

}

/**
  @par Description:
  Resize the table (heigth) to fit just in between the lowest frame and the bottom of the screen.

  @par Usage:
  Public.
*/
void fwAlarmScreenGeneric_resizeTable()
{
	// Calculate position (Y) to place the table, regarding the size and visibility of the 4 frames.
	// The table extends to the bottom of the screen
	int iTableX;
	int iTableY;
	int iTableHeight;
	int iTableWidth;

	if (frameAlertFilter.visible())
	{
		getValue("frameAlertFilter", "position", iTableX, iTableY);
		getValue("frameAlertFilter", "size", iTableWidth, iTableHeight);

		iTableY = iTableY + iTableHeight + FW_ALARM_GENERIC_FRAME_SPACE;
	}
	else if (frameTableFilter.visible())
	{
		getValue("frameTableFilter", "position", iTableX, iTableY);
		getValue("frameTableFilter", "size", iTableWidth, iTableHeight);

		iTableY = iTableY + iTableHeight + FW_ALARM_GENERIC_FRAME_SPACE;
	}
	else if (frameInfo.visible())
	{
		getValue("frameInfo", "position", iTableX, iTableY);
		getValue("frameInfo", "size", iTableWidth, iTableHeight);

		iTableY = iTableY + iTableHeight + FW_ALARM_GENERIC_FRAME_SPACE;
	}
	else if (frameHeader.visible())
	{
		getValue(FW_ALARM_GENERIC_HEADER_FRAME, "position", iTableX, iTableY);
		getValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iTableWidth, iTableHeight);

		iTableY = iTableY + iTableHeight + FW_ALARM_GENERIC_FRAME_SPACE;
	}
	else
	{
		getValue("lineTopLimit", "position", iTableX, iTableY);
		iTableX = iTableX + FW_ALARM_GENERIC_FRAME_SPACE;
		iTableY = iTableY + 2 * FW_ALARM_GENERIC_FRAME_SPACE;
	}

	// Calculate total available space to expand the table down to the bottom of the main frame
	int iGlobalX;
	int iGlobalY;
	getValue("lineBottomLimit", "position", iGlobalX, iGlobalY);
	iTableHeight = iGlobalY - (iTableY) - 2 * FW_ALARM_GENERIC_FRAME_SPACE;

	// Keep the current width
	int iCurrentW;
	int iCurrentH;
	getValue(AES_TABLENAME_TOP, "size", iCurrentW, iCurrentH);



	// It looks like sometimes the size is not correct.
	// In that case, resize until it is.

	int iNewW;
	int iNewH;

	int iNewX;
	int iNewY;

	// Note: touching the table will reset column sizes.
	// They have to be saved beforehand and set back after.
	mapping mColumSizes;
	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		mColumSizes[sColumnName] = iColumnWidth;
	}

	do
	{
		setValue(AES_TABLENAME_TOP, "size", iCurrentW, iTableHeight);
		setValue(AES_TABLENAME_TOP, "position", iTableX, iTableY);

		delay(0, 10);

		getValue(AES_TABLENAME_TOP, "size", iNewW, iNewH);
		getValue(AES_TABLENAME_TOP, "position", iNewX, iNewY);

	}
	while ((iNewW != iCurrentW) && (iTableY != iNewY));


	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		if (mappingHasKey(mColumSizes, sColumnName) && (mColumSizes[sColumnName] != iColumnWidth))
		{
			setValue(AES_TABLENAME_TOP, "columnWidth", i, mColumSizes[sColumnName]);
		}
	}

}

/**
  @par Description:
  Expand/reduce the whole panel to fit the size of the screen.
  Note: cannot expand to the entire screen size because the panel will appear bigger than the screen in that case (because of OS task bar and PVSS top part of a panel).

  @par Usage:
  Public.
*/
void fwAlarmScreenGeneric_expand()
{
	bool bReduced = _fwAlarmScreenGeneric_config_get(FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED);

	if (!bReduced) // Already expanded, reduce to default size
	{
		_fwAlarmScreenGeneric_reduceWindow();
	}
	else // Expand
	{
		_fwAlarmScreenGeneric_expandWindow();
	}

	fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_WHOLE);

	_fwAlarmScreenGeneric_rearrangeScreen(); // To extend the table to the top of the screen

}

/**
  @par Description:
  Close the panel.
  Call a custom close function if it exists for the current alarm panel, otherwise just close the window.

  @par Usage:
  Public.
*/
void fwAlarmScreenGeneric_closePanel()
{
	_fwAlarmScreenGeneric_saveColumnsSize();

	if (isFunctionDefined(FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_CLOSE_PANEL))
	{
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_CLOSE_PANEL + "();" +
			"}",
			makeDynString()
		);
	}
	else
	{
		PanelOff();
	}
}

// -----------------------------
// ------ Internal action ------
// -----------------------------

/**
  @par Description:
  Move one widget to the position of another widget.

  @par Usage:
  Private

  @param sShape1 string input, widget to move.
  @param sShape2 string input, widget to move to.
*/
void  _fwAlarmScreenGeneric_moveWidgetTo(string sShape1, string sShape2)
{
	int iShapeX;
	int iShapeY;
	getValue(sShape2, "position", iShapeX, iShapeY);
	setValue(sShape1, "position", iShapeX, iShapeY);
	setValue(sShape1 + "Title", "position", iShapeX + 35, iShapeY + 4);
	setValue(sShape1 + "Expanded", "position", iShapeX + 10, iShapeY + 3);
	setValue(sShape1 + "Reduced", "position", iShapeX + 10, iShapeY + 3);
	setValue(sShape1 + "Highlight", "position", iShapeX, iShapeY);
}

void  _fwAlarmScreenGeneric_showBlock(string sFrame, bool bShow, int &iNewHeight)
{
	string sFrameText;

	getValue(sFrame + "Title", "text", sFrameText);

	if (0 == strpos(sFrameText, fwAlarmScreenGeneric_sHeaderFrameTitle))
	{
		// Header
		iNewHeight = bShow ? _fwAlarmScreenGeneric_getHeaderHeight() : FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT;
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_HEADER_SHOW + "(" + bShow + ");" +
			"}",
			makeDynString()
		);

		if (bShow)
		{
			fwAlarmScreenGeneric_config_expand(fwAlarmScreenGeneric_sHeaderFrameTitle);
		}
		else
		{
			fwAlarmScreenGeneric_config_reduce(fwAlarmScreenGeneric_sHeaderFrameTitle);
		}
	}
	else if (0 == strpos(sFrameText, fwAlarmScreenGeneric_sInfoFrameTitle))
	{
		// Info block
		iNewHeight = bShow ? _fwAlarmScreenGeneric_getInfoHeight() : FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT;
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_INFO_SHOW + "(" + bShow + ");" +
			"}",
			makeDynString()
		);

		if (bShow)
		{
			fwAlarmScreenGeneric_config_expand(fwAlarmScreenGeneric_sInfoFrameTitle);
		}
		else
		{
			fwAlarmScreenGeneric_config_reduce(fwAlarmScreenGeneric_sInfoFrameTitle);
		}
	}
	else if (0 == strpos(sFrameText, fwAlarmScreenGeneric_sTableFilterFrameTitle))
	{
		// Table filter block
		iNewHeight = bShow ? _fwAlarmScreenGeneric_getTableFilterHeight() : FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT;
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_SHOW + "(" + bShow + ");" +
			"}",
			makeDynString()
		);

		if (bShow)
		{
			fwAlarmScreenGeneric_config_expand(fwAlarmScreenGeneric_sTableFilterFrameTitle);
		}
		else
		{
			fwAlarmScreenGeneric_config_reduce(fwAlarmScreenGeneric_sTableFilterFrameTitle);
		}
	}
	else if (0 == strpos(sFrameText, fwAlarmScreenGeneric_sAlarmFilterFrameTitle))
	{
		// Alert filter
		iNewHeight = bShow ? _fwAlarmScreenGeneric_getAlertFilterHeight() : FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT;
		execScript(
			"main()" +
			"{" +
			"  " + FW_ALARM_GENERIC_ALARM_CLASS + FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_SHOW + "(" + bShow + ");" +
			"}",
			makeDynString()
		);

		if (bShow)
		{
			fwAlarmScreenGeneric_config_expand(fwAlarmScreenGeneric_sAlarmFilterFrameTitle);
		}
		else
		{
			fwAlarmScreenGeneric_config_reduce(fwAlarmScreenGeneric_sAlarmFilterFrameTitle);
		}
	}
}

void  _fwAlarmScreenGeneric_moveBelow(string sShapeToMove, string sShapeToMoveTo)
{
	int iXTo;
	int iYTo;
	int iXFrom;
	int iYFrom;
	int iWidthTo;
	int iHeightTo;
	getValue(sShapeToMoveTo, "position", iXTo, iYTo);
	getValue(sShapeToMove, "position", iXFrom, iYFrom);
	getValue(sShapeToMoveTo, "size", iWidthTo, iHeightTo);

	if (sShapeToMoveTo == lineTopLimit.name())
	{
		iXTo = iXFrom;
		iYTo = iYTo + FW_ALARM_GENERIC_FRAME_SPACE;
	}
	else
	{
		iYTo = iYTo + iHeightTo + FW_ALARM_GENERIC_FRAME_SPACE;
	}

	setValue(sShapeToMove, "position", iXTo, iYTo);
	setValue(sShapeToMove + "Title", "position", iXTo + 35, iYTo + 4);
	setValue(sShapeToMove + "Expanded", "position", iXTo + 10, iYTo + 3);
	setValue(sShapeToMove + "Reduced", "position", iXTo + 10, iYTo + 3);
	setValue(sShapeToMove + "Highlight", "position", iXTo, iYTo);
}

void  _fwAlarmScreenGeneric_expandFrame(string sFrame)
{
	// Get right size and widget to show
	int iHeight;
	int iWidth;
	getValue(sFrame, "size", iWidth, iHeight);

	int iNewHeight;

	_fwAlarmScreenGeneric_simulateButtonClick(sFrame);
	_fwAlarmScreenGeneric_showBlock(sFrame, true, iNewHeight);

	setValue(sFrame, "size", iWidth, iNewHeight);

	// Rearrange view
	_fwAlarmScreenGeneric_rearrangeScreen();




	// Trigger expand/reduce event
	switch(sFrame)
	{
		case FW_ALARM_GENERIC_HEADER_FRAME:
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_HEADER);
			break;
		}
		case "frameInfo":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_INFO);
			break;
		}
		case "frameTableFilter":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_TABLE_FILTER);
			break;
		}
		case "frameAlertFilter":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_ALARM_FILTER);
			break;
		}
	}
}

void  _fwAlarmScreenGeneric_reduceFrame(string sFrame)
{
	// Get right size and widget to show
	int iHeight;
	int iWidth;
	getValue(sFrame, "size", iWidth, iHeight);

	int iNewHeight;

	_fwAlarmScreenGeneric_simulateButtonClick(sFrame);
	_fwAlarmScreenGeneric_showBlock(sFrame, false, iNewHeight);

	setValue(sFrame, "size", iWidth, iNewHeight);

	// Rearrange view
	_fwAlarmScreenGeneric_rearrangeScreen();





	// Trigger expand/reduce event
	switch(sFrame)
	{
		case FW_ALARM_GENERIC_HEADER_FRAME:
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_HEADER);
			break;
		}
		case "frameInfo":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_INFO);
			break;
		}
		case "frameTableFilter":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_TABLE_FILTER);
			break;
		}
		case "frameAlertFilter":
		{
			fwAlarmScreenGeneric_config_triggerEvent(FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_ALARM_FILTER);
			break;
		}
	}
}

void  _fwAlarmScreenGeneric_simulateButtonClick(string sFrame)
{
	bool bExpanded;
	int index = -1;

	// determine the constant for the menu item that triggered this function
	switch(sFrame)
	{
		case FW_ALARM_GENERIC_HEADER_FRAME:
			index = FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX;
			break;
		case "frameInfo":
			index = FW_ALARM_GENERIC_INFO_EXPANDED_INDEX;
			break;
		case "frameTableFilter":
			index = FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX;
			break;
		case "frameAlertFilter":
			index = FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX;
			break;
		default:
			break;
	}

	if(index > -1)
	{
		bExpanded = isExpandedCheckbox.state(index);

		setValue(sFrame + "Reduced", "visible", bExpanded);
		setValue(sFrame + "Expanded", "visible", !bExpanded);

		isExpandedCheckbox.state(index, !bExpanded);
	}
}

void  _fwAlarmScreenGeneric_expandWindow()
{
	float fXRatio;
	float fYRatio;

	int iWidth;
	int iHeight;
	int iStartX;
	int iStartY;

	int iWidth2;
	int iHeight2;

	int iNewWidth;

	panelSize("", iWidth2, iHeight2);
	getScreenSize(iWidth, iHeight, iStartX, iStartY, getPrimaryScreen());

	iWidth = 0.9 * iWidth;
	iHeight = 0.9 * iHeight;

	fYRatio = (float) iWidth / (float) iWidth2;
	fXRatio = (float) iHeight / (float) iHeight2;

	setPanelSize(myModuleName(), myPanelName(), false, iWidth, iHeight);
	moveModule(myModuleName(), iStartX, iStartY);

	// Expand header rectangle
	setValue("backgroundRectangle", "size", iWidth + 2, 31);

	// Move buttons
	setValue("pushButtonExpand", "position", iWidth - 35, 2);
	setValue("pushButtonGenericSettings", "position", iWidth - 65, 2);

	// Resize every frame
	iNewWidth = iWidth - 20;
	getValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iWidth, iHeight);

	setValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iNewWidth, iHeight);
	setValue("frameHeaderHighlight", "size", iNewWidth, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameInfo", "size", iWidth, iHeight);
	setValue("frameInfo", "size", iNewWidth, iHeight);
	setValue("frameInfoHighlight", "size", iNewWidth, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameTableFilter", "size", iWidth, iHeight);
	setValue("frameTableFilter", "size", iNewWidth, iHeight);
	setValue("frameTableFilterHighlight", "size", iNewWidth, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameAlertFilter", "size", iWidth, iHeight);
	setValue("frameAlertFilter", "size", iNewWidth, iHeight);
	setValue("frameAlertFilterHighlight", "size", iNewWidth, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	int iX;
	int iY;
	getValue("lineRightLimit", "position", iX, iY);
	setValue("lineRightLimit", "position", iX * fYRatio, iY);

	getValue("lineBottomLimit", "position", iX, iY);
	setValue("lineBottomLimit", "position", iX, iY * fXRatio);

	// Resize and move wait bar position
	getValue("lineBottomLimit", "position", iX, iY);
	setValue("rectangleBusyBar", "position", 10, iY - 20);
	setValue("rectangleBusyBar", "size", iNewWidth, 10);

	// Move alarm info widget
	setValue("alarmInfoWidget", "position", 10, iY);

	// Move system info widget
	panelSize("", iWidth, iHeight);
	setValue(FW_ALARM_GENERIC_WIDGET_SYSTEM_INFO_REF, "position", iWidth - 501, iY + 1);

	// Note: touching the table will reset column sizes.
	// They have to be saved beforehand and set back after.
	mapping mColumSizes;
	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		mColumSizes[sColumnName] = iColumnWidth;
	}

	getValue(AES_TABLENAME_TOP, "size", iWidth, iHeight);
	setValue(AES_TABLENAME_TOP, "size", iNewWidth, iHeight);

	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		if (mColumSizes[sColumnName] != iColumnWidth)
		{
			setValue(AES_TABLENAME_TOP, "columnWidth", i, mColumSizes[sColumnName]);
		}
	}

	setValue("pushButtonExpand", "fill", "[pattern,[tile,xpm,reduce.png]]");
	setValue("pushButtonExpand", "toolTipText", "Reduce");

	bExpanded = true;

	_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, false);
}

void  _fwAlarmScreenGeneric_reduceWindow()
{
	int iWidth;
	int iHeight;
	panelSize("", iWidth, iHeight);

	setPanelSize(myModuleName(), myPanelName(), false, 1269, 935);

	setValue("backgroundRectangle", "size", 1271, 31);


	// Resize every frame
	getValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", iWidth, iHeight);
	setValue(FW_ALARM_GENERIC_HEADER_FRAME, "size", FW_ALARM_GENERIC_FRAME_WIDTH, iHeight);
	setValue("frameHeaderHighlight", "size", FW_ALARM_GENERIC_FRAME_WIDTH, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameInfo", "size", iWidth, iHeight);
	setValue("frameInfo", "size", FW_ALARM_GENERIC_FRAME_WIDTH, iHeight);
	setValue("frameInfoHighlight", "size", FW_ALARM_GENERIC_FRAME_WIDTH, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameTableFilter", "size", iWidth, iHeight);
	setValue("frameTableFilter", "size", FW_ALARM_GENERIC_FRAME_WIDTH, iHeight);
	setValue("frameTableFilterHighlight", "size", FW_ALARM_GENERIC_FRAME_WIDTH, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	getValue("frameAlertFilter", "size", iWidth, iHeight);
	setValue("frameAlertFilter", "size", FW_ALARM_GENERIC_FRAME_WIDTH, iHeight);
	setValue("frameAlertFilterHighlight", "size", FW_ALARM_GENERIC_FRAME_WIDTH, FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT);

	// Note: touching the table will reset column sizes.
	// They have to be saved beforehand and set back after.
	mapping mColumSizes;
	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);
	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		mColumSizes[sColumnName] = iColumnWidth;
	}

	getValue(AES_TABLENAME_TOP, "size", iWidth, iHeight);
	setValue(AES_TABLENAME_TOP, "size", FW_ALARM_GENERIC_FRAME_WIDTH, iHeight);

	for (int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;

		getMultiValue(
			AES_TABLENAME_TOP, "columnName", i, sColumnName,
			AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth
		);

		if (mColumSizes[sColumnName] != iColumnWidth)
		{
			setValue(AES_TABLENAME_TOP, "columnWidth", i, mColumSizes[sColumnName]);
		}
	}

	setValue("lineRightLimit", "position", 1269, 120);
	setValue("lineBottomLimit", "position", 180, FW_ALARM_GENERIC_PANEL_BOTTOM);

	// Resize and move wait bar position
	setValue("rectangleBusyBar", "size", FW_ALARM_GENERIC_FRAME_WIDTH, 10);
	setValue("rectangleBusyBar", "position", 10, 880);

	// Move alarm info widget
	setValue("alarmInfoWidget", "position", 10, FW_ALARM_GENERIC_PANEL_BOTTOM);

	// Move system info widget
	setValue(FW_ALARM_GENERIC_WIDGET_SYSTEM_INFO_REF, "position", 768, FW_ALARM_GENERIC_PANEL_BOTTOM + 1);

	// Move button
	setValue("pushButtonExpand", "position", 1233, 2);
	setValue("pushButtonGenericSettings", "position", 1203, 2);

	bExpanded = false;

	_fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_GLOBAL + FWALARMSCREEN_GENERIC_CONFIGURATION_REDUCED, true);

	setValue("pushButtonExpand", "fill", "[pattern,[tile,xpm,expand.png]]");
	setValue("pushButtonExpand", "toolTipText", "Expand");
}

/**
  @par Description:
  Check if the given frame is reduced.

  @par Usage:
  Internal.

  @param  sFrame, string input, The frame to check.

  @return True if the frame is reduced, false otherwise.
*/
bool  _fwAlarmScreenGeneric_isReduced(string sFrame)
{
	int iWidth;
	int iHeight;

	getValue(sFrame, "size", iWidth, iHeight);

	return FW_ALARM_GENERIC_FRAME_REDUCED_HEIGHT == iHeight;
}

int   _fwAlarmScreenGeneric_getHeaderHeight()
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();
	int iHeight;

	evalScript(
		iHeight,
		"int main()" +
		"{" +
		"  return " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_HEADER_GET_HEIGHT + "();"
		"}",
		makeDynString()
	);

	return iHeight;
}

int   _fwAlarmScreenGeneric_getInfoHeight()
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	int iHeight;
	evalScript(
		iHeight,
		"int main()" +
		"{" +
		"  return " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_INFO_GET_HEIGHT + "();"
		"}",
		makeDynString()
	);

	return iHeight;
}

void  _fwAlarmScreenGeneric_moveInfo(int iYDiff)
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	execScript(
		" main()" +
		"{" +
		"  " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_INFO_MOVE + "(" + iYDiff + ");" +
		"}",
		makeDynString()
	);
}

int   _fwAlarmScreenGeneric_getTableFilterHeight()
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	int iHeight;
	evalScript(
		iHeight,
		"int main()" +
		"{" +
		"  return " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_GET_HEIGHT + "();"
		"}",
		makeDynString()
	);

	return iHeight;
}

void  _fwAlarmScreenGeneric_moveTableFilter(int iYDiff)
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	execScript(
		" main()" +
		"{" +
		"  " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_TABLE_FILTER_MOVE + "(" + iYDiff + ");" +
		"}",
		makeDynString()
	);
}

int   _fwAlarmScreenGeneric_getAlertFilterHeight()
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	int iHeight;
	evalScript(
		iHeight,
		"int main()" +
		"{" +
		"  return " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_GET_HEIGHT + "();"
		"}",
		makeDynString()
	);

	return iHeight;
}

void  _fwAlarmScreenGeneric_moveAlertFilter(int iYDiff)
{
	string sAlarmClass = fwAlarmScreenGenericAlarmClass.text();

	execScript(
		" main()" +
		"{" +
		"  " + sAlarmClass + FW_ALARM_GENERIC_FUNCTION_ALERTFILTER_MOVE + "(" + iYDiff + ");" +
		"}",
		makeDynString()
	);
}


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------ UTILITY FUNCTIONS -----------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// Functions to be called by anyone at any time.

/**
  @par Description:
  Get what kind of alarm panel is currently in use.

  @par Usage:
  Public.

  @return The alarm panel type.
*/
string fwAlarmScreenGeneric_getAlarmClass()
{
	return fwAlarmScreenGenericAlarmClass.text();
}

/**
  @par Description:
  Show a progress bar that will move untill it is implicitely stopped.
  The bar is showed at the same position everytime: the position of the rectangleBusyBar rectangle.

  @par Usage:
  Public.

  @param  bWait bool input, True to start the loading of the bar, false to stop it (remove the bar).
*/
void fwAlarmScreenGeneric_wait(bool bWait)
{
	string sName = "FW_ALARM_WAIT_BAR";

	if (bWait) // Show progress bar
	{
		string sPath = "/fwAlarmHandling/fwAlarmScreenGenericWaitBar.pnl";

		// Calculate size and position of the progress bar (depends on the size of the main frame)
		int iBarX;
		int iBarY;
		getValue("rectangleBusyBar", "position", iBarX, iBarY);

		int iWidth;
		int iHeight;
		getValue("rectangleBusyBar", "size", iWidth, iHeight);

		addSymbol(
			myModuleName(),
			myPanelName(),
			sPath,
			sName,
			makeDynString(
				"$iBarWidth:" + iWidth
			),
			iBarX,
			iBarY,
			0,
			1,
			1
		);
	}
	else // Hide progress bar
	{
		if (shapeExists("alarmListProgressBar"))
		{
			removeSymbol(
				myModuleName(),
				myPanelName(),
				sName
			);
		}
	}
}

/**
  @par Description
  Check if the header frame is reduced.

  @par Usage:
  Public.

  @return True if it is reduced, false otherwise.
*/
bool fwAlarmScreenGeneric_isHeaderReduced()
{
	return _fwAlarmScreenGeneric_isReduced(FW_ALARM_GENERIC_HEADER_FRAME);
}

/**
  @par Description
  Check if the header frame is reduced.

  @par Usage:
  Public.

  @return True if it is reduced, false otherwise.
*/
bool fwAlarmScreenGeneric_isInfoReduced()
{
	return _fwAlarmScreenGeneric_isReduced("frameInfo");
}

/**
  @par Description
  Check if the table filter frame is reduced.

  @par Usage:
  Public.

  @return True if it is reduced, false otherwise.
*/
bool fwAlarmScreenGeneric_isTableFilterReduced()
{
	return _fwAlarmScreenGeneric_isReduced("frameTableFilter");
}

/**
  @par Description
  Check if the alarm filter frame is reduced.

  @par Usage:
  Public.

  @return True if it is reduced, false otherwise.
*/
bool fwAlarmScreenGeneric_isAlarmFilterReduced()
{
	return _fwAlarmScreenGeneric_isReduced("frameAlertFilter");
}

/**
  @par Description:
  Check if the alarm screen is ready.

  @par Usage:
  Public.

  @return Boolean,  True if the UI has finished initializing, false otherwise.
*/
bool fwAlarmScreenGeneric_screenReady()
{
	return FW_ALARM_GENERIC_SCREEN_READY == fwAlarmScreenReadyCheck.text();
}

/**
  @par Description:
  Copy the content of the given line of the given table to the clipboard.
  Only copies visible cells.

  @par Usage:
  Public.

  @param[in]  iRow        int,    The row to copy.
  @param[in]  sTableName  string, The table from which to copy.
*/
void fwAlarmScreenGeneric_copyLineToClipboard(const dyn_int diRows, const string sTableName)
{
	int iColumnCount;
	getValue(sTableName, "columnCount", iColumnCount);

	dyn_dyn_string dsLinesCells;

	for (int j = 1 ; j <= dynlen(diRows) ; j++)
	{
		int iRow = diRows[j];

		dyn_string dsCellValues;
		for (int i = 0 ; i < iColumnCount ; i++)
		{
			bool bColumnVisible;
			string sColumnName;
			int iColumnWidth;
			getMultiValue(
				sTableName, "columnVisibility", i, bColumnVisible,
				sTableName, "columnName", i, sColumnName,
				sTableName, "columnWidth", i, iColumnWidth
			);

			if (bColumnVisible && (0 != iColumnWidth))
			{
				string sValue;
				getValue(sTableName, "cellValueRC", iRow, sColumnName, sValue);
				dynAppend(dsCellValues, sValue);
			}
		}

		dynAppend(dsLinesCells, dsCellValues);
	}

	string sClipBoardText;

	for (int j = 1 ; j <= dynlen(dsLinesCells) ; j++)
	{
		for (int i = 1 ; i <= dynlen(dsLinesCells[j]) ; i++)
		{
			sClipBoardText += dsLinesCells[j][i] + "\t";
		}

		sClipBoardText = strrtrim(sClipBoardText, "\t");
		sClipBoardText += "\n";
	}

	sClipBoardText = strrtrim(sClipBoardText, "\n");

	setClipboardText(sClipBoardText);
}

/**
  @par Description:
  Show or hide the header part of the panel.

  @par Usage:
  Public.

  @param[in]  bShow bool, True to show, false to hide.
*/
void fwAlarmScreenGeneric_showHeader(const bool bShow)
{
	isExpandedCheckbox.state(FW_ALARM_GENERIC_HEADER_EXPANDED_INDEX, bShow);
	setMultiValue(
		FW_ALARM_GENERIC_HEADER_FRAME, "visible", bShow,
		FW_ALARM_GENERIC_HEADER_TITLE, "visible", bShow,
		FW_ALARM_GENERIC_HEADER_REDUCED, "visible", bShow,
		FW_ALARM_GENERIC_HEADER_EXPANDED, "visible", bShow,
		FW_ALARM_GENERIC_HEADER_HIGHLIGHT, "visible", bShow
	);
}

/**
  @par Description:
  Show or hide the info part of the panel.

  @par Usage:
  Public.

  @param[in]  bShow bool, True to show, false to hide.
*/
void fwAlarmScreenGeneric_showInfo(const bool bShow)
{
	isExpandedCheckbox.state(FW_ALARM_GENERIC_INFO_EXPANDED_INDEX, bShow);
	setMultiValue(
		FW_ALARM_GENERIC_INFO_FRAME, "visible", bShow,
		FW_ALARM_GENERIC_INFO_TITLE, "visible", bShow,
		FW_ALARM_GENERIC_INFO_REDUCED, "visible", bShow,
		FW_ALARM_GENERIC_INFO_EXPANDED, "visible", bShow,
		FW_ALARM_GENERIC_INFO_HIGHLIGHT, "visible", bShow
	);
}

/**
  @par Description:
  Show or hide the table filter part of the panel.

  @par Usage:
  Public.

  @param[in]  bShow bool, True to show, false to hide.
*/
void fwAlarmScreenGeneric_showTableFilter(const bool bShow)
{
	isExpandedCheckbox.state(FW_ALARM_GENERIC_TABLEFILTER_EXPANDED_INDEX, bShow);
	setMultiValue(
		FW_ALARM_GENERIC_TABLE_FILTER_FRAME, "visible", bShow,
		FW_ALARM_GENERIC_TABLE_FILTER_TITLE, "visible", bShow,
		FW_ALARM_GENERIC_TABLE_FILTER_REDUCED, "visible", bShow,
		FW_ALARM_GENERIC_TABLE_FILTER_EXPANDED, "visible", bShow,
		FW_ALARM_GENERIC_TABLE_FILTER_HIGHLIGHT, "visible", bShow
	);
}
/**
  @par Description:
  Show or hide the alert filter part of the panel.

  @par Usage:
  Public.

  @param[in]  bShow bool, True to show, false to hide.
*/
void fwAlarmScreenGeneric_showAlertFilter(const bool bShow)
{
	isExpandedCheckbox.state(FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX, bShow);
	setMultiValue(
		FW_ALARM_GENERIC_ALERT_FILTER_FRAME, "visible", bShow,
		FW_ALARM_GENERIC_ALERT_FILTER_TITLE, "visible", bShow,
		FW_ALARM_GENERIC_ALERT_FILTER_REDUCED, "visible", bShow,
		FW_ALARM_GENERIC_ALERT_FILTER_EXPANDED, "visible", bShow,
		FW_ALARM_GENERIC_ALERT_FILTER_HIGHLIGHT, "visible", bShow
	);
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------------- OTHER FUNCTIONS---------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

void fwAlarmScreenGeneric_invokedAESUserFunc(string sShapeName, int iScreenType, int iTabType, int iRow, int iColumn, string sValue, mapping mTableRow)
{
	if (isFunctionDefined(fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_INVOKED_AES_USER_FUNC))
	{
		execScript(
			"main(string sShapeName, int iScreenType, int iTabType, int iRow, int iColumn, string sValue, mapping mTableRow)" +
			"{" +
			"  " + fwAlarmScreenGenericAlarmClass.text() + FW_ALARM_GENERIC_FUNCTION_INVOKED_AES_USER_FUNC + "(sShapeName, iScreenType, iTabType, iRow, iColumn, sValue, mTableRow);" +
			"}",
			makeDynString(),
			sShapeName,
			iScreenType,
			iTabType,
			iRow,
			iColumn,
			sValue,
			mTableRow
		);
	}
}

