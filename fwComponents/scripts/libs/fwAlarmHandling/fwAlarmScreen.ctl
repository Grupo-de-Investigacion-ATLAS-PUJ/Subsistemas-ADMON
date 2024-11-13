/**
  @file fwAlarmScreen.ctl

  @par Description:
  This library contains all the functions used by the JCOP alarm screen.
  Most of the code comes from the former fwAlarmHandling libraries but has been rearranged and cleaned.

  Throughout the whole library, a dyn_dyn_anytype is used to describe a filter. It's indexes can be accessed via the variables xxx_CONFIG_OBJECT_FILTER_xxx.


  @par Creation Date
	08/02/2013

  @par Modification History
  24/05/2017 Adrian Crestar Santome
  - New function 'fwAlarmScreen_setAesColumnsVisibility" that is called when the user
    modifies the column visibility and saves the configuration.
    It will check which columns are part of the 'Showable Columns' in the table
    (see the function 'fwAlarmScreen_getShowableColumns') and modify the Properties
    DP accordingly.
  - The functions 'fwAlarmScreen_showHideColumn' and 'fwAlarmScreen_showHideColumns'
    have been modified to update the Properties DP cache.
    Otherwise, the columns will be hidden again until the Alarm Screen is re-opened
    and the cache is updated.

  @author
	Cyril Caillaba (EN-ICE-SCD)
*/

// Library with function for groups.
#uses "fwAlarmHandling/fwAlarmScreenGroups.ctl"
// conditionally load fwTrending used in  _fwAlarmScreen_createPlotDp
private const bool fwAlarmScreen_fwTrendingLibLoaded = fwGeneral_loadCtrlLib("fwTrending/fwTrending.ctl",false);


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// -------------------------------- CONSTANTS------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME 			        = 1;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS 			      = 2;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE 			        = 3;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_LIST 			        = 4;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM 				      = 5;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL      = 6;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY			        = 7;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT		        = 8;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION		      = 9;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_SUMMARIES			      = 10;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE			    = 11;

const unsigned  fwAlarmScreen_CONFIG_OBJECT_FILTER_SIZE 					      = 10;

const unsigned  fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE 						      = 1;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME 		        = 2;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME 			        = 3;
const unsigned  fwAlarmScreen_CONFIG_OBJECT_MODE_MAX_LINES 			        = 4;

const unsigned  fwAlarmScreen_CONFIG_OBJECT_MODE_SIZE 						      = 3;

const unsigned  fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING			      = 1;
const unsigned  fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR				      = 2;
const unsigned  fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL				      = 3;

const unsigned  fwAlarmScreen_ACCESS_ACKNOWLEDGE                        = 1;
const unsigned  fwAlarmScreen_ACCESS_COMMENT                            = 2;
const unsigned  fwAlarmScreen_ACCESS_RIGHT_CLICK                        = 3;
const unsigned  fwAlarmScreen_ACCESS_FILTER                             = 4;
const unsigned  fwAlarmScreen_ACCESS_MANAGE_DISPLAY                     = 5;
const unsigned  fwAlarmScreen_ACCESS_HIDE_ACCESS_CONTROL                = 6;

const string    fwAlarmScreen_CONFIG_DP_FILTER_DP_NAME				          = ".filter.dpName";
const string    fwAlarmScreen_CONFIG_DP_FILTER_DP_ALIAS			            = ".filter.dpAlias";
const string    fwAlarmScreen_CONFIG_DP_FILTER_DP_TYPE				          = ".filter.dpType";
const string    fwAlarmScreen_CONFIG_DP_FILTER_SYSTEM				            = ".filter.systems";
const string    fwAlarmScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL				  = ".filter.severity.localOrGlobal";
const string    fwAlarmScreen_CONFIG_DP_FILTER_WARNING				          = ".filter.severity.warning";
const string    fwAlarmScreen_CONFIG_DP_FILTER_ERROR					          = ".filter.severity.error";
const string    fwAlarmScreen_CONFIG_DP_FILTER_FATAL					          = ".filter.severity.fatal";
const string    fwAlarmScreen_CONFIG_DP_FILTER_ALERT_TEXT		            = ".filter.alertText";
const string    fwAlarmScreen_CONFIG_DP_FILTER_DESCRIPTION		          = ".filter.description";
const string    fwAlarmScreen_CONFIG_DP_FILTER_SUMMARIES			          = ".filter.summaries";
const string    fwAlarmScreen_CONFIG_DP_FILTER_ALERT_STATE			        = ".filter.alertState";
const string    fwAlarmScreen_CONFIG_DP_FILTER_QUICK_FILTER			        = ".showAsQuickFilter";
const string    fwAlarmScreen_CONFIG_DP_FILTER_ACCESS_RIGHT			        = ".quickFilterAccessRight";

const string    fwAlarmScreen_PVSS_DP_FILTER_SHORTCUT				            = ".Alerts.Filter.Shortcut";
const string    fwAlarmScreen_PVSS_DP_FILTER_PRIORITY				            = ".Alerts.Filter.Prio";
const string    fwAlarmScreen_PVSS_DP_FILTER_DP_LIST					          = ".Alerts.Filter.DpList";
const string    fwAlarmScreen_PVSS_DP_FILTER_ALERT_TEXT			            = ".Alerts.Filter.AlertText";
const string    fwAlarmScreen_PVSS_DP_FILTER_COMMENT					          = ".Alerts.Filter.DpComment";
const string    fwAlarmScreen_PVSS_DP_FILTER_LOGIC						          = ".Alerts.Filter.LogicalCombine";
const string    fwAlarmScreen_PVSS_DP_FILTER_SUMMARIES				          = ".Alerts.FilterTypes.AlertSummary";
const string    fwAlarmScreen_PVSS_DP_FILTER_SYSTEMS					          = ".Both.Systems.Selections";
const string    fwAlarmScreen_PVSS_DP_FILTER_ALL_SYSTEMS			          = ".Both.Systems.CheckAllSystems";
const string    fwAlarmScreen_PVSS_DP_FILTER_ALERT_STATE			          = ".Alerts.FilterState.State";
const string    fwAlarmScreen_PVSS_DP_FILTER_ONE_ROW			              = ".Alerts.FilterState.OneRowPerAlert";

const string    fwAlarmScreen_PVSS_CONFIG_DP                            = "_AESConfig";
const string    fwAlarmScreen_PVSS_CONFIG_COLUMN_NAMES                  = ".tables.alertTable.columns.name";
const string    fwAlarmScreen_PVSS_CONFIG_COLUMN_FUNCTIONS              = ".tables.alertTable.columns.value.functionName";
const string    fwAlarmScreen_PVSS_CONFIG_COLUMN_BACKCOL                = ".tables.alertTable.columns.useAlertClassBackColor";

const string    fwAlarmScreen_PVSS_PROPERTIES_DP                        = "fwAES_Alerts";

const string    fwAlarmScreen_HISTORICAL_TIME_FORMAT                    = "%d/%m/%Y %H:%M:%S";
const string    fwAlarmScreen_ENABLED_BUTTON                            = "_ButtonShadow";
const string    fwAlarmScreen_DISABLED_BUTTON                           = "_3DFace";


const string    fwAlarmScreen_DPE_LIST_DIVIDER                          = ",";
const string    fwAlarmScreen_PANEL_NAME                                = "fwAlarmHandling/fwAlarmScreen.pnl";

const int       fwAlarmScreen_BEHAVIOUR_DESCRIPTION_ONLY                = 0;
const int       fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_DP_NAME          = 1;
const int       fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME = 2;

const int       fwAlarmScreen_BEHAVIOUR_TIME_CAME_WENT                  = 0;
const int       fwAlarmScreen_BEHAVIOUR_TIME_ALWAYS_CAME                = 1;

const int       fwAlarmScreen_COLUMN_ID_DP_NAME                         = 1;
const int       fwAlarmScreen_COLUMN_ID_LOGICAL_NAME                    = 2;
const int       fwAlarmScreen_COLUMN_ID_DESCRIPTION                     = 3;
const int       fwAlarmScreen_COLUMN_ID_ALERT_VALUE                     = 4;
const int       fwAlarmScreen_COLUMN_ID_ONLINE_VALUE                    = 5;
const int       fwAlarmScreen_COLUMN_ID_TIME_STANDARD                   = 6;
const int       fwAlarmScreen_COLUMN_ID_TIME_CAME                       = 7;



const string    fwAlarmScreen_COLUMN_SHORT_SIGN                         = "abbreviation";
const string    fwAlarmScreen_COLUMN_PRIORITY                           = "priority";
const string    fwAlarmScreen_COLUMN_DP_NAME                            = "elementName";
const string    fwAlarmScreen_COLUMN_LOGICAL_NAME                       = "logicalName";
const string    fwAlarmScreen_COLUMN_DESCRIPTION                        = "description";
const string    fwAlarmScreen_COLUMN_ALERT_TEXT                         = "alertText";
const string    fwAlarmScreen_COLUMN_DIRECTION                          = "direction";
const string    fwAlarmScreen_COLUMN_ONLINE_VALUE                       = "onlineValue";
const string    fwAlarmScreen_COLUMN_ALERT_VALUE                        = "value";
const string    fwAlarmScreen_COLUMN_ACKNOWLEDGE                        = "acknowledge";
const string    fwAlarmScreen_COLUMN_TIME_STANDARD                      = "timeStr";
const string    fwAlarmScreen_COLUMN_TIME_CAME                          = "cameTime";
const string    fwAlarmScreen_COLUMN_ACK_CAME                           = "ackTime";
const string    fwAlarmScreen_COLUMN_COMMENT                            = "nofComments";
const string    fwAlarmScreen_COLUMN_ALERT_PANEL                        = "alertPanel";
const string    fwAlarmScreen_COLUMN_DETAIL                             = "detail";
const string    fwAlarmScreen_COLUMN_SYSTEM_NAME                        = "__V_sysName";
const string    fwAlarmScreen_COLUMN_ACKABLE                            = "__V_ackable";
const string    fwAlarmScreen_COLUMN_DP_ID                              = "__V_dpid";

const int       fwAlarmScreen_COLUMN_DEFAULT_WIDTH                      = 200;


const string    fwAlarmScreen_GROUP_ALARM_TABLE                         = "tableGroupAlarms";

const string    fwAlarmScreen_PROPERTIES_DP                             = "_AESProperties_fwAes";

const string    fwAlarmScreen_FILTER_DP_TYPE                            = "_FwAesConfig";
const string    fwAlarmScreen_FILTER_DP_PREFIX                          = "_FwAesConfig_";

const int       fwAlarmScreen_HELP_DEVICE_ELEMENT                       = 1;
const int       fwAlarmScreen_HELP_DEVICE                               = 2;
const int       fwAlarmScreen_HELP_DEVICE_TYPE_ELEMENT                  = 3;
const int       fwAlarmScreen_HELP_DEVICE_TYPE                          = 4;
const int       fwAlarmScreen_HELP_DEFAULT                              = 5;

const string    fwAlarmScreen_HELP_PATH_ROOT                            = "AlarmHelp/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT      = "DeviceDescriptionDPE/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION              = "DeviceDescription/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_ALIAS_ELEMENT            = "DeviceDescriptionDPE/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_ALIAS                    = "DeviceDescription/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_ELEMENT                  = "DeviceDPE/";
const string    fwAlarmScreen_HELP_PATH_DEVICE                          = "Device/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_TYPE_ELEMENT             = "DeviceTypeDPE/";
const string    fwAlarmScreen_HELP_PATH_DEVICE_TYPE                     = "DeviceType/";
const string    fwAlarmScreen_HELP_FILE_DEFAULT                         = "fwAlarmHandlingDefault.xml";

const string    fwAlarmScreen_HELP_FORMAT_EXTENSIONS                    = "_FwAlarmHelpSettings.fileExtensions";
const string    fwAlarmScreen_HELP_FORMAT_COMMANDS_WINDOWS              = "_FwAlarmHelpSettings.openCommand.windows";
const string    fwAlarmScreen_HELP_FORMAT_COMMANDS_LINUX                = "_FwAlarmHelpSettings.openCommand.linux";

const string    fwAlarmScreen_HELP_LOADER_PANEL		                      = "fwAlarmHandling/fwAlarmHandlingHelpLoader.pnl";
const string    fwAlarmScreen_HELP_PATH_ATTRIBUTE	                      = ".._string_05";



const int       FWALARMSCREEN_HEADER_HEIGHT                             = 118;
const int       FWALARMSCREEN_INFO_HEIGHT                               = 60;
const int       FWALARMSCREEN_ALERTFILTER_HEIGHT                        = 159;
const int       FWALARMSCREEN_TABLEFILTER_HEIGHT                        = 123;

const int       FWALARMSCREEN_DELAY_QUICK                               = 20;   // Milliseconds
const int       FWALARMSCREEN_DELAY_SHORT                               = 100;  // Milliseconds
const int       FWALARMSCREEN_DELAY_LONG                                = 500;  // Milliseconds
const int       FWALARMSCREEN_DELAY_TIME_OUT_STOP                       = 10;   // Seconds

const string    FWALARMSCREEN_ACTIVE_FILTER_LABEL                       = "Some alarms might be hidden";

const string    FWALARMSCREEN_DATETIMEPICKER_PANELNAME                  = "DATE_TIME_WIDGET"; //name of the panel used with addSymbol to add the date time picker
const string    FWALARMSCREEN_DATETIMEPICKER_WIDGETNAME1                = "startTimeField" ; //name of a widget of date/time picker to check if the ref panel is present or not


/**
  @par Description:
  Init the widgets inside the panel (show, fill, ...).

  @par Usage:
  Internal.
*/
void fwAlarmScreen_initUIElements()
{
	dyn_string dsExceptions;
	int iXPos, iYPos;

	dyn_string dsAccessRights;
	fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

	// Display access control if available
	if (!dsAccessRights[fwAlarmScreen_ACCESS_HIDE_ACCESS_CONTROL])
	{
		int iAccessControlX;
		int iAccessControlY;
		getValue("acNotAvailable", "position", iAccessControlX, iAccessControlY);
		if(getPath(PANELS_REL_PATH, "objects/fwAccessControl/fwAccessControl_CurrentUser.pnl") != "")
		{
			addSymbol(
				myModuleName(),
				myPanelName(),
				"objects/fwAccessControl/fwAccessControl_CurrentUser.pnl",
				"currentUserAC",
				makeDynString(),
				iAccessControlX - 10, // The widget is not located in position 0:0 but 10:15 in the add symbol...
				iAccessControlY - 15,
				0,
				1,
				1
			);
		}
		else
		{
			acNotAvailable.visible = TRUE;
		}
	}
	else
	{
		acNotAvailable.position(-3000, -3000); // Hide forever, no risk to be shown again
	}

	// Display date time picker
	getValue("dateTimeWidgetPlaceholder", "position", iXPos, iYPos);

	addSymbol(
		myModuleName(),
		myPanelName(),
		"fwGeneral/fwGeneralDateTimeWidget.pnl",
		FWALARMSCREEN_DATETIMEPICKER_PANELNAME,
		makeDynString("$sStartDate:", "$sEndDate:",
					  "$sStartTime:", "$sEndTime:",
					  "$bDateAndTime:TRUE", "$bShowTimeZone:TRUE", "$sTimeZone:",
					  "$iTimePeriod:600", "$bEnabled:" + false),
		iXPos,
		iYPos,
		0,
		1,
		1
	);

	if (fwAlarmScreenGeneric_isAlarmFilterReduced())
	{
		delay(0, 100); // necessary to wait until date time widget is completely initialised
		fwGeneral_dateTimeWidget_setVisible(FALSE);
	}

	// Load device types
	dyn_dyn_string ddsTypes;
	fwDevice_getAllTypes(ddsTypes, dsExceptions);
	string sType = deviceType.text;

	dynInsertAt(ddsTypes[1], "*", 1);
	dynInsertAt(ddsTypes[2], "*", 1);
	deviceType.items = ddsTypes[1];

	if(strpos(sType, "Loading") == 0)
	{
		deviceType.selectedPos = 1;
	}

	dpTypeList.items = ddsTypes[2];


	// Problem when starting with the screen expanded: the widgets in the bottom right are not moved.
	// We can not use the event system to make them move because un-authorized users would still have the problem.
	// Solution: move them manually.
	fwAlarmScreen_resizePanel();
}

/**
  @par Description:
  Initialize the AES. Load settings and start alarm monitoring.

  @par Usage:
  Internal.

  @param[in]  sLoadFilter string, The filter to load on initialization.
*/
void fwAlarmScreen_initAES(string sLoadFilter = "")
{
  // Reset runtime column visibility settings (saved column configuration will be applied)
  _fwAlarmScreenGeneric_config_set(FWALARMSCREEN_GENERIC_CONFIGURATION_RUNTIME_COLUMNS_VISIBILITY, makeDynString());
  
	dyn_string dsExceptions;
	string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);

	bool bOk;

	// -----------------------------------
	// 1) Wait for AES table to be ready
	// -----------------------------------
	while(!dpExists(sPropertiesDp))
	{
		delay(0, FWALARMSCREEN_DELAY_QUICK);
	}
	while(!reg_main.visible)
	{
		delay(0, FWALARMSCREEN_DELAY_QUICK);
	}
	reg_main.visible(false);
	while(!table_top.visible)
	{
		delay(0, FWALARMSCREEN_DELAY_QUICK);
	}

	// -----------------------------------
	// 2) Check if the AES is configured for JCOP. If not, configure it.
	// -----------------------------------
	if (!fwAlarmScreen_checkAESConfig())
	{
		fwGeneral_openMessagePanel("The Alarm Screen configuration is not for JCOP.\nJCOP configuration will be loaded.", bOk, dsExceptions, "Alert Screen Configuration");
		if(bOk)
		{
			fwOpenProgressBar("Alarm Screen config", "Loading Alarm Screen config, please wait...", 1);
			fwAlarmScreen_makeAESConfig(dsExceptions);
			fwCloseProgressBar();
			fwGeneral_openMessagePanel("JCOP configuration was loaded.\nPlease restart the Alarm Screen.", bOk, dsExceptions, "Alert Screen Configuration", true);
			PanelOff();
		}
	}

	// -----------------------------------
	// 3) Connect to busy CB
	// -----------------------------------
	dpConnect("fwAlarmScreen_busyCallBack", true, sPropertiesDp + ".Settings.BusyTrigger" + AES_ORIVAL);


	// -----------------------------------
	// 4) Connect to running CB
	// -----------------------------------
	dpConnect("fwAlarmScreen_runningStateCallback", true, sPropertiesDp + ".Settings.RunMode" + AES_ONLVAL);

	// -----------------------------------
	// 5) Show or hide the remote system state widget
	// -----------------------------------
	bool bDisplaySystems;
	fwAlarmScreen_getDistSystemDisplayOption(bDisplaySystems, dsExceptions);
	setValue(FW_ALARM_GENERIC_WIDGET_SYSTEM_STATE, "visible", bDisplaySystems);

	// -----------------------------------
	// 6) Init filter
	// -----------------------------------
	dyn_anytype aesMode;
	dyn_dyn_anytype aesFilter;

	fwAlarmScreen_initFields(aesMode, aesFilter, dsExceptions);
	fwAlarmScreen_showMode(aesMode, dsExceptions);
	fwAlarmScreen_applyMode(sPropertiesDp, aesMode, dsExceptions, false);
	fwAlarmScreen_showFilter(aesFilter, dsExceptions);
	fwAlarmScreen_applyFilter(sPropertiesDp, aesFilter, dsExceptions, false);

	// Summary mode
	int iSummaryMode;
	fwAlarmScreen_getReductionMode(fwAlarmScreen_PROPERTIES_DP, iSummaryMode, dsExceptions);
	int iCurrentSummaryMode;
	fwAlarmScreen_getReductionMode(sPropertiesDp, iCurrentSummaryMode, dsExceptions);
	if (iSummaryMode != iCurrentSummaryMode)
	{
		fwAlarmScreen_setReductionMode(sPropertiesDp, iSummaryMode, dsExceptions);
	}

	// -----------------------------------
	// 7) Start AES
	// -----------------------------------
	aes_doStart(sPropertiesDp);

	// -----------------------------------
	// 8) Create plot DP
	// -----------------------------------
	if(!dpExists("_FwAlarmScreenPlot"))
	{
		_fwAlarmScreen_createPlotDp("_FwAlarmScreenPlot");
	}

	// -----------------------------------
	// 9) Init UI for current user.
	// -----------------------------------
	fwAlarmScreen_userChanged(getUserName());

	// -----------------------------------
	// 10) Wait for columns to be ready
	// -----------------------------------
	while(1)
	{
		dyn_bool dbColumnsVisible;
		dyn_int diColumnWidths;
		dyn_string dsColumnNames;
		fwAlarmScreen_getColumnWidths(dsColumnNames, dbColumnsVisible, diColumnWidths, dsExceptions);

		if (dynContains(dsColumnNames, fwAlarmScreen_COLUMN_ALERT_VALUE) > 0)
		{
			break;
		}

		delay(0, FWALARMSCREEN_DELAY_QUICK);
	}

	// -----------------------------------
	// 11) Start idle time-out check thread.
	// -----------------------------------
	int iIdleTimeout;
	fwAlarmScreen_getIdleTimeout(iIdleTimeout, dsExceptions);
	idleTimeoutValue.text = iIdleTimeout;
	startThread("fwAlarmScreen_idleCheck");

	// -----------------------------------
	// 12) Start online value update thread
	// -----------------------------------
	int iUpdateRate;
	dpGet("_FwAesSetup.onlineValueUpdateRate", iUpdateRate);
	onlineUpdateRate.text = iUpdateRate;
	startThread("fwAlarmScreen_updateOnlineValues");

	// -----------------------------------
	// 13)  Resize the table
	// -----------------------------------
	fwAlarmScreenGeneric_resizeTable();
}

/**
  @par Description:
  Check if the AES is configured for JCOP.

  @par Usage:
  Public.

  @return True if the AES is configured for JCOP, false otherwise.
*/
bool fwAlarmScreen_checkAESConfig()
{
	bool bReturn;
	dyn_string dsExtFunc;
	string sAES = "_AESConfig.functions.alerts.extFunc";

	if(!dpExists(sAES))
	{
		return false;
	}

	dpGet(sAES, dsExtFunc);

	if(dynlen(dsExtFunc))
	{
		if(patternMatch("fwAlarmHandling*", dsExtFunc[1]))
		{
			bReturn = true;
		}
	}

	// Check if Screen is correct.
	dyn_string dsDpList = dpNames("*", "_AEScreen");
	int iLength = dynlen(dsDpList);
	bool bThereIsDefault = false;
	for (int i = 1; i <= iLength; i++)
	{
		bool bDefault;
		dpGet(dsDpList[i] + ".UseAsDefault", bDefault);
		if (bDefault)
		{
			if (getSystemName() +  "_AEScreen_fwAes" != dsDpList[i])
			{
				return false;
			}
			else
			{
				bThereIsDefault = true;
			}
		}
	}

	return bReturn && bThereIsDefault;
}

/**
  @par Description:
  Configure the AES for JCOP.

  @par Usage:
  Public.

  @param[out] dsExceptions  string, A list of errors that happened during execution.
*/
void fwAlarmScreen_makeAESConfig(dyn_string &dsExceptions)
{
	string sDpSource = "_AESConfig_fwAes";
	string sDpDest = "_AESConfig";

	// Set alarm panel config
	if(!aes_copyDp(sDpSource, sDpDest))
	{
		fwException_raise(
			dsExceptions,
			"fwAlarmScreen_makeAESConfig - ERROR in copying the dp from " + sDpSource + " to " + sDpDest
		);
	}

	// Set alarm row config
	sDpSource = "_AESConfigRowRestore";
	sDpDest = "_AESConfigRow";

	if(!aes_copyDp(sDpSource, sDpDest))
	{
		fwException_raise(
			dsExceptions,
			"fwAlarmScreen_makeAESConfig - ERROR in copying the dp from " + sDpSource + " to " + sDpDest
		);
	}

	// Set Screen dp
	dyn_string dsDpList = dpNames("*", "_AEScreen");
	int iLength = dynlen(dsDpList);
	for (int i = 1; i <= iLength; i++)
	{
		dpSetWait(dsDpList[i] + ".UseAsDefault", false);
	}
	dpSetWait("_AEScreen_fwAes" + ".UseAsDefault", true);
}

/**
  @par Description:
  Checks if the current user has administration rights. Called from fwAlarmScreenGeneric.

  @par Usage:
  Internal.

  @return True if the current user has administration rights.
*/
bool        fwAlarmScreen_isAdmin()
{
	bool bGranted;
	dyn_string dsAccessRights;
	dyn_string dsExceptions;

	fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

	bGranted = true;

	if (dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY] != "")
	{
		fwAccessControl_isGranted(dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY], bGranted, dsExceptions);
	}

	return bGranted;
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ---------------------------- FILTERING FUNCTIONS -----------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Apply the given filter options to the given PVSS runtime properties DP.
  The given PVSS runtime DP should be the one that corresponds to the alarm screen display you want to update.
  This can be obtained using "aes_getPropDpName()" and the DP should be of type "_AESProperties".

  @par Usage
	Public

  @param pvssAesPropertiesDp  string input,	          The PVSS runtime properties DP for the given alarm screen
  @param ddaAesFilter         dyn_dyn_anytype input,  The filter object with the filter data is passed here
  @param dsExceptions         dyn_string output,      List of exceptions that occurred during execution.
  @param updateAes		        bool input,             Do or not do aes_doRestart after setting the new filter (default do)
*/
void      fwAlarmScreen_applyFilter(string pvssAesPropertiesDp, dyn_dyn_anytype ddaAesFilter, dyn_string &dsExceptions, bool bUpdateAes = true)
{
	string sSeverityFilter;
	dyn_uint duSystemIds;
	dyn_string dsSystemNames;
	dyn_string dsDpList;

	bool bDefaultFilter;

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM], "*") > 0)
	{
		getSystemNames(dsSystemNames, duSystemIds);
	}
	else
	{
		dsSystemNames = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM];
	}

	dyn_dyn_anytype ddaDefaultFilter;
	_fwAlarmScreen_getDefaultFilter(ddaDefaultFilter, dsExceptions);
	if (ddaAesFilter == ddaDefaultFilter)
	{
		bDefaultFilter = true;
	}


	// Sets any "*" filters to "".  The PVSS alarm screen requires "" instead of "*" to mean ALL for some filtering criteria.
	// If any other criteria are given as well as a "*", then they are ignored as everything will already meet the "*" criteria.

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM] = makeDynString();
	}

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME] = makeDynString();
	}

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS] = makeDynString();
	}

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE] = makeDynString();
	}

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT] = makeDynString();
	}

	if(dynContains(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION], "*") > 0)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION] = makeDynString();
	}



	fwAlarmScreen_evaluateDpFilter(ddaAesFilter, dsDpList, dsExceptions);
	fwAlarmScreen_evaluateSeverityFilter(ddaAesFilter, sSeverityFilter, dsExceptions, ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1]);

  //FWAH-361 Applying the mode and the filter with dpSetCache should be done at the same time
  dyn_string dsExceptions;  
  dyn_anytype aesMode;
	fwAlarmScreen_readMode(aesMode, dsExceptions);
  
	dpSetCache(
		pvssAesPropertiesDp + ".Settings.Config",                               fwAlarmScreen_PVSS_PROPERTIES_DP,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_DP_LIST, 	  dsDpList,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_ALERT_TEXT,  ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_COMMENT, 	  ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_LOGIC,	      1,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_PRIORITY,	  sSeverityFilter,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_SYSTEMS,	    dsSystemNames,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_ALL_SYSTEMS,	false,
		pvssAesPropertiesDp + fwAlarmScreen_PVSS_DP_FILTER_ALERT_STATE,	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1],
    
		pvssAesPropertiesDp + ".Both.Timerange.Type", 		  aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE],
		pvssAesPropertiesDp + ".Both.Timerange.Begin",	    aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME],
		pvssAesPropertiesDp + ".Both.Timerange.End",        aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME],
		pvssAesPropertiesDp + ".Both.Timerange.MaxLines", 	aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_MAX_LINES],
		pvssAesPropertiesDp + ".Both.Timerange.Selection",  6,
		pvssAesPropertiesDp + ".Both.Timerange.Shift", 		  1
	);

	dyn_errClass deErrors = getLastError();
	if(dynlen(deErrors) > 0)
	{
		throwError(deErrors);
		fwException_raise(dsExceptions, "ERROR", "fwAlarmScreen_applyFilter(): Could not apply the alarm screen filter.", "");
		fwExceptionHandling_display(dsExceptions);
		return;
	}
  


	if (bDefaultFilter)
	{
		fwAlarmScreenGeneric_setActiveFilter("");
	}
	else
	{
		fwAlarmScreenGeneric_setActiveFilter(FWALARMSCREEN_ACTIVE_FILTER_LABEL);
	}
  
	if(bUpdateAes)
	{
    aes_doStop(pvssAesPropertiesDp);
    delay(1);
		aes_doStart(pvssAesPropertiesDp);  
    delay(0, 500);
    _fwAlarmScreenGeneric_setColumnsVisibility(true);
	}
}

// ----------------------------
// ---------- Filter ----------
// ----------------------------

/**
  @par Description:
  Reads the filter options from the alarm screen filter graphical objects.

  @par Usage:
	Public

  @param ddaAesFilter dyn_dyn_anytype output, The filter object is returned here with the filter as defined in the graphical objects.
  @param dsExceptions dyn_string output,      List of exceptions that occurred during execution.
*/
fwAlarmScreen_readFilter(dyn_dyn_anytype &ddaAesFilter, dyn_string &dsExceptions)
{
	dyn_uint duSystemIds;

	dyn_string dsSelectedSystemNames;
	dyn_string dsSystemNames;
	dyn_string dsAllDpTypes = dpTypeList.items;

	string sDeviceNames;
	string sDeviceAlias;

	getSystemNames(dsSystemNames, duSystemIds);

	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE] = dsAllDpTypes[deviceType.selectedPos];
	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1] = alarmState.selectedPos - 1;

	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM] = makeDynAnytype();

	for(int i = 0; i < deviceSystemTable.lineCount(); i++)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM][i + 1] = deviceSystemTable.cellValueRC(i, "systemName");
	}

	dsSelectedSystemNames = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM];
	if(dsSelectedSystemNames == dsSystemNames)
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM] = "*";
	}

	sDeviceAlias = (deviceAlias.text == "") ? "*" : deviceAlias.text;

	fwGeneral_stringToDynString(
		sDeviceAlias,
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
		fwAlarmScreen_DPE_LIST_DIVIDER,
		false,
		true
	);

	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION] = (deviceDescription.text == "") ? "*" : deviceDescription.text;
	fwGeneral_stringToDynString(
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		fwGeneral_DYN_STRING_DEFAULT_SEPARATOR,
		false,
		true
	);

	if(deviceName.text == "")
	{
		sDeviceNames = "*";
	}

	sDeviceNames = (deviceName.text == "") ? "*" : deviceName.text;
	fwGeneral_stringToDynString(
		sDeviceNames,
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME],
		fwAlarmScreen_DPE_LIST_DIVIDER,
		false,
		true
	);

	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT] = (alarmText.text == "") ? "*" : alarmText.text;
	fwGeneral_stringToDynString(
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		fwGeneral_DYN_STRING_DEFAULT_SEPARATOR,
		false,
		true
	);

	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING] = showWarnings.toggleState;
	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR] = showErrors.toggleState;
	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL] = showFatals.toggleState;
	ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] = (showLocalOrGlobal.selectedPos - 1);
}

/**
  @par Description:
  Shows the given filter options in the alarm screen filter graphical objects.

  @par Usage:
	Public.

  @param ddaAesFilter dyn_dyn_anytype input,  The filter object with the filter data to display in the graphical objects.
  @param dsExceptions dyn_string output,  	  List of errors that occurred during execution.
*/
fwAlarmScreen_showFilter(dyn_dyn_anytype ddaAesFilter, dyn_string &dsExceptions)
{
	// Fill system list
	deviceSystemTable.deleteAllLines();

	deviceSystemTable.appendLines(
		dynlen(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM]),
		"systemName",
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM]
	);
	deviceSystemTable.lineVisible = 0;

	// Fill device alias field ("Logical name")
	string sDeviceAlias = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS];
	strreplace(sDeviceAlias, " | ", fwAlarmScreen_DPE_LIST_DIVIDER);
	deviceAlias.text = sDeviceAlias;

	// Fill device description field
	deviceDescription.text = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION];

	// Fill device name field
	string sDeviceNames = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME];
	strreplace(sDeviceNames, " | ", fwAlarmScreen_DPE_LIST_DIVIDER);
	deviceName.text = sDeviceNames;

	// Fill device type field
	dyn_string dsAllDpTypes = dpTypeList.items;
	deviceType.selectedPos = dynContains(dsAllDpTypes, ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE][1]);

	// Fill alarm text field
	alarmText.text = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT];

	// Fill alarm state field
	alarmState.selectedPos = (int)ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1] + 1;

	// Check/uncheck warning symbol
	showWarnings.toggleState = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING];

	// Check/uncheck error symbol
	showErrors.toggleState = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR];

	// Check/uncheck fatal symbol
	showFatals.toggleState = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL];

	// Fill global/local alarm field
	showLocalOrGlobal.selectedPos = ((int)ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] + 1);
}

/**
  @par Description:
  Save the filter options to the given filter configuration data point.

  @par Usage:
	Public.

  @param sFwAesConfigDp		The filter configuration data point to write to
  @param aesFilter		The filter object with the filter data is passed here. Use the fwAlarmScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
  @param exceptionInfo		Details of any exceptions are returned here
*/
void fwAlarmScreen_saveFilter(string sFwAesConfigDp, dyn_dyn_anytype aesFilter, dyn_string &exceptionInfo)
{
	dyn_errClass errors;

	if(!dpExists(sFwAesConfigDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "The alarm screen config dp \"" + sFwAesConfigDp + "\" does not exist", "");
		return;
	}

	dpSetWait(
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_NAME, 	        aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_ALIAS, 	      aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_TYPE, 	        aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_SYSTEM, 		      aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL,  aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_WARNING, 	        aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ERROR, 		        aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_FATAL, 		        aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ALERT_TEXT, 	    aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DESCRIPTION, 	    aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_SUMMARIES, 	      2,
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ALERT_STATE, 	    aesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]
	);

	errors = getLastError();
	if(dynlen(errors) > 0)
	{
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "fwAlarmScreen_saveFilter(): Could not save the alarm screen filter.", "");
	}
}

/**
  @par Description:
  Read the filter options from the given filter configuration data point.

  @par Usage
	Public

  @param sFwAesConfigDp string input,           The filter configuration data point to read from.
  @param ddaAesFilter   dyn_dyn_anytype output, The filter with the loaded data.
  @param dsExceptions   dyn_string output,      List of errors that occurred during execution.
*/
fwAlarmScreen_loadFilter(string sFwAesConfigDp, dyn_dyn_anytype &ddaAesFilter, dyn_string &dsExceptions)
{
	if(!dpExists(sFwAesConfigDp))
	{
		fwException_raise(dsExceptions, "ERROR", "The alarm screen config dp \"" + sFwAesConfigDp + "\" does not exist", "");
		return;
	}

	dpGet(
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_NAME, 	       ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_ALIAS, 	     ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DP_TYPE, 	       ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_SYSTEM, 		     ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL, ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_WARNING, 	       ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ERROR, 		       ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_FATAL, 		       ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ALERT_TEXT, 	   ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_DESCRIPTION, 	   ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_SUMMARIES, 	     ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SUMMARIES],
		sFwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ALERT_STATE, 	   ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]
	);
}

/**
  @par Description:
  Build a filter object configured with the default filter criteria (display all alarms).

  @par Usage
	Internal.

  @param ddaAesFilter dyn_dyn_anytype output, Filter displaying all alarms.
  @param dsExceptions dyn_string output,      List of errors that occurred during execution.
*/
_fwAlarmScreen_getDefaultFilter(dyn_dyn_anytype &ddaAesFilter, dyn_string &dsExceptions)
{
	string sDefaultFilterName;

	dpGet("_FwAesSetup.defaultFilter", sDefaultFilterName);
	if(sDefaultFilterName != "")
	{
		fwAlarmScreen_loadFilter(sDefaultFilterName, ddaAesFilter, dsExceptions);
	}
	else
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM]             = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS]           = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION]        = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME]            = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE]            = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT]         = "*";
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]     = 0;
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] = 0;
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING] = true;
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR] = true;
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL] = true;
	}
}

/**
  @par Description:
  Get the list of available quick filters.

  @par Usage:
	Public.

  @param dsQuickFilter  dyn_string output,  The list of quick filters.
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void fwAlarmScreen_getQuickFilterList(dyn_string &dsQuickFilter, dyn_string &dsExceptions)
{
	bool bGrandted;
	string sAccessRight;
	dyn_dyn_anytype ddaQueryResults;

	dpQuery(
		"SELECT '_online.._value' " +
		"FROM '" + fwAlarmScreen_FILTER_DP_PREFIX + "*" + fwAlarmScreen_CONFIG_DP_FILTER_QUICK_FILTER +
		"' WHERE '_online.._value' == 1",
		ddaQueryResults
	);

	if(dynlen(ddaQueryResults) <= 1)
	{
		dsQuickFilter = makeDynString();
		return;
	}

	if(isFunctionDefined("fwAccessControl_isGranted"))
	{
		for(int i = 2; i <= dynlen(ddaQueryResults); i++)
		{
			string dpName = dpSubStr(ddaQueryResults[i][1], DPSUB_DP);
			strreplace(dpName, fwAlarmScreen_FILTER_DP_PREFIX, "");

			dpGet(dpSubStr(ddaQueryResults[i][1], DPSUB_DP) + fwAlarmScreen_CONFIG_DP_FILTER_ACCESS_RIGHT, sAccessRight);
			if(sAccessRight == "")
			{
				dynAppend(dsQuickFilter, dpName);
			}
			else
			{
				fwAccessControl_isGranted(sAccessRight, bGrandted, dsExceptions);
				if(bGrandted)
				{
					dynAppend(dsQuickFilter, dpName);
				}
			}
		}
	}
	else
	{
		for(int i = 2; i <= dynlen(ddaQueryResults); i++)
		{
			string dpName = dpSubStr(ddaQueryResults[i][1], DPSUB_DP);
			strreplace(dpName, fwAlarmScreen_FILTER_DP_PREFIX, "");
			dynAppend(dsQuickFilter, dpName);
		}
	}
}

/**
  @par Description:
  Load the quick filter list and show it in the appropriate combo-box.

  @par Usage:
  Public.
*/
void fwAlarmScreen_reloadQuickFilterList()
{
	dyn_string dsQuickFilterList;
	dyn_string dsExceptions;
	fwAlarmScreen_getQuickFilterList(dsQuickFilterList, dsExceptions);

	if(dynlen(dsQuickFilterList) == 0)
	{
		quickFilterList.items = makeDynString("None available");
		quickFilterList.enabled = false;
	}
	else
	{
		dynInsertAt(dsQuickFilterList, "", 1);
		quickFilterList.items = dsQuickFilterList;
		quickFilterList.enabled = true;
		currentFilter.text = quickFilterList.text;
	}
}

/**
  @par Description:
  Save the current filter to the quick-list.
*/
void fwAlarmScreen_saveQuickFilterOptions(string fwAesConfigDp, bool isQuickFilter, string accessRight, dyn_string &exceptionInfo)
{
	dpSetWait(
		fwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_QUICK_FILTER, isQuickFilter,
		fwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ACCESS_RIGHT, accessRight
	);
}
/**
  @par Description:
  Load a filter from the quick-list.
*/
void fwAlarmScreen_loadQuickFilterOptions(string fwAesConfigDp, bool &isQuickFilter, string &accessRight, dyn_string &exceptionInfo)
{
	dpGet(
		fwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_QUICK_FILTER, isQuickFilter,
		fwAesConfigDp + fwAlarmScreen_CONFIG_DP_FILTER_ACCESS_RIGHT, accessRight
	);
}

/**
  @par Description:
  Get the name of the default filter.

  @par Usage:
  Public.

  @param[out] defaultFilter string, The default filter name.
  @param[out] exceptionInfo	string,	Details of any exceptions are returned here.
*/
void fwAlarmScreen_getDefaultFilterName(string &defaultFilter, dyn_string &exceptionInfo)
{
	dpGet("_FwAesSetup.defaultFilter", defaultFilter);
}

// ----------------------------
// ----------- Mode -----------
// ----------------------------

/**
  @par Description:
  Read the mode options from the alarm screen widgets.

  @par Usage:
	Public.

  @param daAesMode    dyn_anytype output,	The mode object is returned here with the mode criteria as defined in the graphical objects
  @param dsExceptions dyn_string output,  List of exceptions that occurred during execution.
*/
fwAlarmScreen_readMode(dyn_anytype &daAesMode, dyn_string &dsExceptions)
{
	bool bTimeOk;

	time tStartTime = fwGeneral_dateTimeWidget_getStartDateTime(bTimeOk, dsExceptions);
	if (!bTimeOk)
	{
		return;
	}

	time tEndTime = fwGeneral_dateTimeWidget_getEndDateTime(bTimeOk, dsExceptions);
	if (!bTimeOk)
	{
		return;
	}

	if (!fwGeneral_dateTimeWidget_positivePeriodSelected(dsExceptions))
	{
		return;
	}


	int iMaxLines;

	fwAlarmScreen_getHistoricalMaxLines(iMaxLines, dsExceptions);

	if(aesModeSelector.number == 0)
	{
		daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] = AES_MODE_CURRENT;
	}
	else
	{
		daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] = AES_MODE_CLOSED;
	}

	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME] = tStartTime;
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME] = tEndTime;
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_MAX_LINES] = iMaxLines;
}

/**
  @par Descriptions:
  Shows the given mode options in the alarm screen mode graphical objects.

  @par Usage
	Public

  @param daAesMode    dyn_anytype output, The mode object with the mode data to display in the graphical objects.
  @param dsExceptions dyn_string output,	List of errors that occurred during execution.
*/
fwAlarmScreen_showMode(dyn_anytype &daAesMode, dyn_string &dsExceptions)
{
	if(daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] == AES_MODE_CURRENT)
	{
		aesModeSelector.number = 0;
		fwGeneral_dateTimeWidget_setEnabled(FALSE);
	}
	else
	{
		aesModeSelector.number = 1;
		fwGeneral_dateTimeWidget_setEnabled(TRUE);
	}

	fwGeneral_dateTimeWidget_setStartDateTime(daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME]);
	fwGeneral_dateTimeWidget_setEndDateTime(daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME]);
}

/**
  @par Description:
  Apply the given mode options to the given PVSS runtime properties dp.
  The given PVSS runtime dp should be the one that corresponds to the alarm screen display you want to update.
  This can be obtained using "aes_getPropDpName()" and the dp should be of type "_AESProperties".

  @par Usage:
	Public.

  @param pvssAesPropertiesDp	sring input,        The PVSS runtime properties dp for the given alarm screen.
  @param aesMode              dyn_anytype input,  The mode object with the mode data is passed here.
  @param dsExceptions		      dyn_string output,  List of errors that occurred during execution.
  @param updateAes		        boolean input,      Indicates whether or not to perform an aes_doRestart after setting the new mode. Default: do.
*/
fwAlarmScreen_applyMode(string sPropertiesDp, dyn_anytype aesMode, dyn_string &dsExceptions, bool updateAes = true)
{
	dpSetCache(
		sPropertiesDp + ".Settings.Config", 		      fwAlarmScreen_PVSS_PROPERTIES_DP,
		sPropertiesDp + ".Both.Timerange.Type", 		  aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE],
		sPropertiesDp + ".Both.Timerange.Begin",	    aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME],
		sPropertiesDp + ".Both.Timerange.End",        aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME],
		sPropertiesDp + ".Both.Timerange.MaxLines", 	aesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_MAX_LINES],
		sPropertiesDp + ".Both.Timerange.Selection",  6,
		sPropertiesDp + ".Both.Timerange.Shift", 		  1
	);

	dyn_errClass deErrors = getLastError();
	if(dynlen(deErrors) > 0)
	{
		throwError(deErrors);
		fwException_raise(dsExceptions, "ERROR", "fwAlarmScreen_applyMode(): Could not set the alarm screen configuration mode.", "");
	}

	if(updateAes)
	{
		aes_doStop(sPropertiesDp);
    delay(1); //do the same as in aes.ctl
		aes_doStart(sPropertiesDp);  
    delay(0, 500);
    _fwAlarmScreenGeneric_setColumnsVisibility(true);
	}

}

/**
  @par Description:
  Get a mode object configured with the default mode options for the alarm screen.

  @par Usage
	Internal.

  @param daAesMode    dyn_anytype output, The mode object is returned here with the default filter criteria.
  @param dsExceptions dyn_string output,  List of errors that occurred during execution.
*/
_fwAlarmScreen_getDefaultMode(dyn_anytype &daAesMode, dyn_string &dsExceptions)
{
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE]        = AES_MODE_CURRENT;
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_START_TIME]  = getCurrentTime() - 3600;
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_END_TIME]    = getCurrentTime();
	daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_MAX_LINES]   = 0;
}



// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------------- UTILITY FUNCTIONS ------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Build a filter from dollar parameters. Any non dollar-defined parameters will be replaced by a default value.

  @par Usage:
  Public.

  @param daAesMode    dyn_anytype output,     The loaded AES mode.
  @param ddaAesFilter dyn_dyn_anytype output, The generated filter.
  @param dsExceptions dyn_string output,      List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_initFields(dyn_anytype &daAesMode, dyn_dyn_anytype &ddaAesFilter, dyn_string &dsExceptions)
{
	dyn_uint sysIds;
	dyn_string sysNames;

	bool isQuickFilter;

	_fwAlarmScreen_getDefaultMode(daAesMode, dsExceptions);
	_fwAlarmScreen_getDefaultFilter(ddaAesFilter, dsExceptions);

	if(isDollarDefined("$sDeviceNameFilter"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME] = $sDeviceNameFilter;
	}
	if(isDollarDefined("$sDeviceAliasFilter"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS] = $sDeviceAliasFilter;
	}
	if(isDollarDefined("$sDeviceTypeFilter"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE] = $sDeviceTypeFilter;
	}
	if(isDollarDefined("$sDeviceDescriptionFilter"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DESCRIPTION] = $sDeviceDescriptionFilter;
	}
	if(isDollarDefined("$sAlertTextFilter"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT] = $sAlertTextFilter;
	}
	if(isDollarDefined("$dsSystemNames"))
	{
		fwGeneral_stringToDynString($dsSystemNames, ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM], "|", TRUE);
	}
	if(isDollarDefined("$bShowWarnings"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING] = (bool)$bShowWarnings;
	}
	if(isDollarDefined("$bShowErrors"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR] = (bool)$bShowErrors;
	}
	if(isDollarDefined("$bShowFatals"))
	{
		ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL] = (bool)$bShowFatals;
	}

	if(isDollarDefined("$sFilterName")) // If a quick filter was loaded, show it on the box
	{
		string sFilterName = getDollarValue("$sFilterName");

		// Load quick filter options
		dpGet(sFilterName + fwAlarmScreen_CONFIG_DP_FILTER_QUICK_FILTER, isQuickFilter);
		if(isQuickFilter)
		{
			strreplace(sFilterName, fwAlarmScreen_FILTER_DP_PREFIX, "");
			quickFilterList.text = sFilterName;
		}
	}
	
	if(isDollarDefined("$sGroupName"))
	{
		DebugTN(__FUNCTION__, "Set group name", $sGroupName);
		string sGroupName = getDollarValue("$sGroupName");	
		textFieldSelectedGroup.text(sGroupName);
	} 
	
	
}

/**
  @par Description:
  Returns a list of data points that match the given criteria.
  The result returned is as follows: result = ((dps that meet ALL DP name filter) && (dps that meet ALL DP alias filters)) of ANY specified type, on ANY specified system

  @par Usage:
	Public

  @param dsSystemNameFilters  dyn_string input,   A list of systems to search in.  The criteria are OR'ed
  @param dpNameFilters        dyn_string input,   A list of criteria to filter on the dp name.  The criteria are AND'ed.
  @param dpAliasFilters		    dyn_string input,   A list of criteria to filter on the dp alias.  The criteria are AND'ed.
  @param dpTypeFilters		    dyn_string input,   A list of data point types to search.  The criteria are ORed.
  @param matchingDps		      dyn_string output,  The list of matching dps is returned here.
  @param dsExceptions		      dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getDpsMatchingCriteria(dyn_string dsSystemNameFilters, dyn_string dpNameFilters, dyn_string dpAliasFilters, dyn_string dpTypeFilters, dyn_string &matchingDps, dyn_string &dsExceptions)
{
	dyn_string dsSearchResult;
	dyn_string dsDps;
	dyn_string dsAliases;
	string sDpPattern;

	if(dynlen(dsSystemNameFilters) == 0)
	{
		dsSystemNameFilters[1] = "*:";
	}

	if(dynlen(dpNameFilters) == 0)
	{
		dpNameFilters[1] = "*";
	}

	if(dynlen(dpTypeFilters) == 0)
	{
		dpTypeFilters[1] = "";
	}


	for(int i = 1; i <= dynlen(dsSystemNameFilters); i++)
	{
		if(strpos(dsSystemNameFilters[i], ":") != (strlen(dsSystemNameFilters[i]) - 1))
		{
			dsSystemNameFilters[i] = dsSystemNameFilters[i] += ":";
		}

		for(int j = 1 ; j <= dynlen(dpTypeFilters) ; j++)
		{
			for(int k = 1 ; k <= dynlen(dpNameFilters) ; k++)
			{
				if(dpSubStr(dpNameFilters[k], DPSUB_SYS) == "")
				{
					sDpPattern = dsSystemNameFilters[i] + dpNameFilters[k];
				}
				else
				{
					sDpPattern = dpNameFilters[k];
				}

				dsSearchResult = dpNames(sDpPattern, dpTypeFilters[j]);

				if(k == 1)
				{
					dsDps = dsSearchResult;
				}
				else
				{
					dynAppend(dsDps, dsSearchResult);
				}
			}

			for(int k = 1 ; k <= dynlen(dpAliasFilters) ; k++)
			{
				dsSearchResult = dpNames(dsSystemNameFilters[i] + "@" + dpAliasFilters[k], dpTypeFilters[j]);

				if(k == 1)
				{
					dsAliases = dsSearchResult;
				}
				else
				{
					dynAppend(dsAliases, dsSearchResult);
				}
			}

			for(int k = 1 ; k <= dynlen(dsAliases) ; k++)
			{
				dsAliases[k] = strrtrim(dsAliases[k], ".");
			}

			dynUnique(dsAliases);

			if(dynlen(dpAliasFilters) == 0)
			{
				dynAppend(matchingDps, dsDps);
			}
			else
			{
				dynAppend(matchingDps, dsAliases);
			}
		}
	}

	dynUnique(matchingDps);
}

/**
  @par Description:
  Calculates from the given filter options, the most compact filter to pass to the PVSS runtime properties dp.
  For simple filters, this could involve just the DP name filter - e.g. "CAEN/*".
  However, for more complex filters, it will usually be a list of DPs that match all the filter criteria.

  @par Usage
	Public

  @param ddaAesFilter       dyn_dyn_anytype input,  The filter object with the filter data is passed here.
  @param dsEvaluatedFilter  dyn_string output,      The most compact form to express the result of the filter is returned here.
  @param dsExceptions       dyn_string output,      List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_evaluateDpFilter(dyn_dyn_anytype ddaAesFilter, dyn_string &dsEvaluatedFilter, dyn_string &dsExceptions)
{
	int iDpNameFilters;
	int iDpAliasFilters;

	iDpNameFilters = dynlen(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME]);
	iDpAliasFilters = dynlen(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS]);

	if(dynlen(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE]) == 0)
	{
		if((iDpNameFilters == 0) && (iDpAliasFilters == 0))
		{
			dsEvaluatedFilter = makeDynString();
		}
		else if((iDpNameFilters == 1) && (iDpAliasFilters == 0))
		{
			dsEvaluatedFilter[1] = ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME][1];

			if(strpos(dsEvaluatedFilter[1], ":") < 0)
			{
				dsEvaluatedFilter[1] = "*:" + dsEvaluatedFilter[1];
			}
		}

		else
		{
			fwAlarmScreen_getDpsMatchingCriteria(
				ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM],
				ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME],
				ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
				ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
				dsEvaluatedFilter,
				dsExceptions
			);

			if(dynlen(dsEvaluatedFilter) == 0)
			{
				dsEvaluatedFilter[1] = "/";
			}
		}
	}
	else
	{
		fwAlarmScreen_getDpsMatchingCriteria(
			ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SYSTEM],
			ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_NAME],
			ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
			ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
			dsEvaluatedFilter,
			dsExceptions
		);

		if(dynlen(dsEvaluatedFilter) == 0)
		{
			dsEvaluatedFilter[1] = "/";
		}
	}
}

/**
  @par Description:
  Calculates from the given filter options, the priority filter which needs to be passed to the PVSS runtime properties dp.
  This function basically converts from FW severity (W,E,F) to PVSS priorities (40-59,60-79,80-255)

  @par Usage:
	Public

  @param ddaAesFilter     dyn_dyn_anytype input,  The filter object with the filter data is passed here
  @param sEvaluatedFilter dyn_string output,		  The priority filter for the PVSS alarm screen is returned here
  @param dsExceptions     dyn_string output,      List of exceptions that occurred during execution.
  @param iLocalOrGlobal   int input,              Optional parameter - default value 0
      If 0, show all alerts in ranges (e.g. 40-59 for WARNING)
      If 1, show upper part of ranges - assumed to be global alerts (e.g. 50-59 for WARNING)
      If 2, show lower part of ranges - assumed to be local alerts (e.g. 40-49 for WARNING)
*/
void  fwAlarmScreen_evaluateSeverityFilter(dyn_dyn_anytype ddaAesFilter, string &sEvaluatedFilter, dyn_string &dsExceptions, int iLocalOrGlobal = 0)
{
	const int GLOBAL_ONLY = 1, LOCAL_ONLY = 2;
	const bool bInvertPriorities = fwAlarmScreen_getInvertPriorities();
	string filterPart;

	sEvaluatedFilter = "";

	if(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_WARNING])
	{
		switch(iLocalOrGlobal)
		{
			case GLOBAL_ONLY:
				filterPart = bInvertPriorities ? "1,40-49" : "1,50-59";
				break;
			case LOCAL_ONLY:
				filterPart = bInvertPriorities ? "1,50-59" : "1,40-49";
				break;
			default:
				filterPart = "1,40-59";
				break;
		}

		sEvaluatedFilter += (filterPart + ",");
	}

	if(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_ERROR])
	{
		switch(iLocalOrGlobal)
		{
			case GLOBAL_ONLY:
				filterPart = bInvertPriorities ? "1,60-69" : "1,70-79";
				break;
			case LOCAL_ONLY:
				filterPart = bInvertPriorities ? "1,70-79" : "1,60-69";
				break;
			default:
				filterPart = "1,60-79";
				break;
		}

		sEvaluatedFilter += (filterPart + ",");
	}

	if(ddaAesFilter[fwAlarmScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmScreen_SEVERITY_FILTER_OBJECT_FATAL])
	{
		switch(iLocalOrGlobal)
		{
			case GLOBAL_ONLY:
				filterPart = bInvertPriorities ? "1,80-89" : "1,90-255";
				break;
			case LOCAL_ONLY:
				filterPart = bInvertPriorities ? "1,90-255" : "1,80-89";
				break;
			default:
				filterPart = "1,80-255";
				break;
		}

		sEvaluatedFilter += (filterPart + ",");
	}

	if(strlen(sEvaluatedFilter) == 0)
	{
		sEvaluatedFilter = 255;
	}

	sEvaluatedFilter = strrtrim(sEvaluatedFilter, ",");
}

/**
  @par Description:
  Read the column names, visibility and widths of the alarm screen table in the current panel.

  @par Usage:
	Public

  @param dsColumnName     dyn_string output,  The list of names of the columns that are in the current alarm screen table.
  @param dbColumnVisible  dyn_bool output,    The visibility of each column. True visible, false invisible.
  @param diColumnWidth    dyn_int output,     The width of each column.
  @param dsExceptions     dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getColumnWidths(dyn_string &dsColumnName, dyn_bool &dbColumnVisible, dyn_int &diColumnWidth, dyn_string &dsExceptions)
{
	int iColumnCount;
	getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);

	for(int i = 0 ; i < iColumnCount ; i++)
	{
		string sColumnName;
		int iColumnWidth;
		bool bColumVisibility;

		getValue(AES_TABLENAME_TOP, "columnName", i, sColumnName);
		getValue(AES_TABLENAME_TOP, "columnWidth", i, iColumnWidth);
		getValue(AES_TABLENAME_TOP, "columnVisibility", i, bColumVisibility);

		dsColumnName[i + 1] = sColumnName;
		diColumnWidth[i + 1] = iColumnWidth;
		dbColumnVisible[i + 1] = bColumVisibility;
	}
}

/**
  @par Description:
  Set the view back to default filter and apply if necessary.

  @par Usage:
	Public
*/
void  fwAlarmScreen_returnToDefaultView()
{
	bool bNeedToReset = false;
	dyn_string dsExceptions;
	dyn_dyn_anytype ddaAesFilter;
	dyn_dyn_anytype ddaVisibleFilter;
	dyn_anytype daAesMode;
	dyn_anytype daVisibleMode;

	_fwAlarmScreen_getDefaultFilter(ddaAesFilter, dsExceptions);
	_fwAlarmScreen_getDefaultMode(daAesMode, dsExceptions);

	fwAlarmScreen_readMode(daVisibleMode, dsExceptions);
	fwAlarmScreen_readFilter(ddaVisibleFilter, dsExceptions);

	if((daVisibleMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] == AES_MODE_CURRENT) && g_bModeChanged.text)
	{
		bNeedToReset = true;
	}

	if(daVisibleMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] == AES_MODE_CLOSED)
	{
		bNeedToReset = true;
	}

	if((ddaVisibleFilter != ddaAesFilter))
	{
		bNeedToReset = true;
	}

	fwAlarmScreen_showMode(daAesMode, dsExceptions);
	fwAlarmScreen_showFilter(ddaAesFilter, dsExceptions);

	if(bNeedToReset)
	{
		string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);
		aes_doStop(sPropertiesDp);
		fwAlarmScreen_applyMode(sPropertiesDp, daAesMode, dsExceptions, false);
		fwAlarmScreen_applyFilter(sPropertiesDp, ddaAesFilter, dsExceptions, false);
		aes_doStart(sPropertiesDp);
    delay(0, 500);
    _fwAlarmScreenGeneric_setColumnsVisibility(true);
	}

	inClosedMode.state(0, daAesMode[fwAlarmScreen_CONFIG_OBJECT_MODE_TYPE] == AES_MODE_CLOSED);
	currentMode.text = aesModeSelector.number;

	if(quickFilterList.text != "None available")
	{
		quickFilterList.text = "";
	}

	currentFilter.text = "";
	pushButtonApplyFilter.backCol = "_3DFace";
}

/**
  @par Description:
  Get the access rights for all possible actions.

  @par Usage:
	Public.

  @param dsAccessRights dyn_string output,  The access rights.
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getAccessControlOptions(dyn_string &dsAccessRights, dyn_string &dsExceptions)
{
	dpGet(
		"_FwAesSetup.accessControl.acknowledge",        dsAccessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE],
		"_FwAesSetup.accessControl.comment",            dsAccessRights[fwAlarmScreen_ACCESS_COMMENT],
		"_FwAesSetup.accessControl.rightClick",         dsAccessRights[fwAlarmScreen_ACCESS_RIGHT_CLICK],
		"_FwAesSetup.accessControl.filters",            dsAccessRights[fwAlarmScreen_ACCESS_FILTER],
		"_FwAesSetup.accessControl.manageDisplay",      dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY],
		"_FwAesSetup.accessControl.hideAccessControl",  dsAccessRights[fwAlarmScreen_ACCESS_HIDE_ACCESS_CONTROL]
	);
}

/**
  @par Description:
  Set the access rights for all possible actions.

  @par Usage:
	Public.

  @param dsAccessRights dyn_string input,   The access rights.
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_setAccessControlOptions(dyn_string dsAccessRights, dyn_string &exceptionInfo)
{
	dpSetWait(
		"_FwAesSetup.accessControl.acknowledge",        dsAccessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE],
		"_FwAesSetup.accessControl.comment",            dsAccessRights[fwAlarmScreen_ACCESS_COMMENT],
		"_FwAesSetup.accessControl.rightClick",         dsAccessRights[fwAlarmScreen_ACCESS_RIGHT_CLICK],
		"_FwAesSetup.accessControl.filters",            dsAccessRights[fwAlarmScreen_ACCESS_FILTER],
		"_FwAesSetup.accessControl.manageDisplay",      dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY],
		"_FwAesSetup.accessControl.hideAccessControl",  dsAccessRights[fwAlarmScreen_ACCESS_HIDE_ACCESS_CONTROL]
	);
}

/**
  @par Description:
  Enable or disable buttons depending on user rights.

  @par Usage:
	Public.
*/
void  fwAlarmScreen_limitButtonAccess()
{
	bool isGranted;
	dyn_string accessRights, exceptionInfo;

	if(isFunctionDefined("fwAccessControl_isGranted"))
	{
		fwAlarmScreen_getAccessControlOptions(accessRights, exceptionInfo);

		if(accessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY] != "")
		{
			fwAccessControl_isGranted(accessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY], isGranted, exceptionInfo);
		}
		else
		{
			isGranted = true;
		}


		if(accessRights[fwAlarmScreen_ACCESS_FILTER] != "")
		{
			fwAccessControl_isGranted(accessRights[fwAlarmScreen_ACCESS_FILTER], isGranted, exceptionInfo);
		}
		else
		{
			isGranted = true;
		}

		pushButtonApplyFilter.enabled = isGranted;
		aesModeSelector.enabled = isGranted;
		clearFilter.enabled = isGranted;

		if(accessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE] != "")
		{
			fwAccessControl_isGranted(accessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE], isGranted, exceptionInfo);
		}
		else
		{
			isGranted = true;
		}

		acknowledgeButton.enabled = isGranted;
	}
	else
	{
		pushButtonApplyFilter.enabled = true;
		aesModeSelector.enabled = true;
		clearFilter.enabled = true;
		acknowledgeButton.enabled = true;
	}
}

/**
  @par Description:
  Get the current behaviour of the description column.
  If no description exists on the alarm dpe, or the root dpe of the dp, then either an empty string or the dpe name can be shown.

  @par Usage:
	Public.

  @param iColumnBehaviour	int output,	any of the constants fwAlarmScreen_BEHAVIOUR_...
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getDescriptionColumnBehaviour(int &iColumnBehaviour, dyn_string &dsExceptions)
{
	int iPos;
	dyn_string dsColumnNames;
	dyn_string dsColumnFunctions;

	dpGet(
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_NAMES,      dsColumnNames,
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_FUNCTIONS,  dsColumnFunctions
	);

	iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_DESCRIPTION);
	if(iPos > 0)
	{
		if(dsColumnFunctions[iPos] == "fwAlarmHandling_tabUtilGetDescriptionOrAliasOrDpe")
		{
			iColumnBehaviour = fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME;
		}
		else if(dsColumnFunctions[iPos] == "fwAlarmHandling_tabUtilGetDescriptionOrDpe")
		{
			iColumnBehaviour = fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_DP_NAME;
		}
		else
		{
			iColumnBehaviour = fwAlarmScreen_BEHAVIOUR_DESCRIPTION_ONLY;
		}
	}
	else
	{
		fwException_raise(
			dsExceptions,
			"ERROR",
			"The description column could not be found in the AES Config.",
			""
		);
	}
}

/**
  @par Description:
  Indicate whether or not the whole row should be coloured.

  @par Usage:
	Public.

  @param bColorWholeRow bool output,        True : do colour the row. False don't.
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getRowColourBehaviour(bool &bColorWholeRow, dyn_string &dsExceptions)
{
	dyn_bool dbUseAlertClassColor;
	dyn_string dsColumnNames;

	dpGet(
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_NAMES, dsColumnNames,
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_BACKCOL, dbUseAlertClassColor
	);

	int iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_DESCRIPTION);
	if(iPos > 0)
	{
		bColorWholeRow = dbUseAlertClassColor[iPos];
	}
	else
	{
		fwException_raise(
			dsExceptions,
			"ERROR",
			"The row colour information could not be found in the AES Config.",
			""
		);
	}
}

/**
  @par Description:
  Sets the behaviour of the description column.  If no description exists on the alarm dpe, or the root dpe of the dp, then either an empty string or the dpe name can be shown.

  @par Usage:
	Public.

  @param iColumnBehaviour int input,          Any of the constants fwAlarmScreen_BEHAVIOUR_...
  @param dsExceptions     dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_setDescriptionColumnBehaviour(int iColumnBehaviour, dyn_string &dsExceptions)
{
	dyn_string dsColumnNames;
	dyn_string dsColumnFunctions;

	dpGet(
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_NAMES, dsColumnNames,
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_FUNCTIONS, dsColumnFunctions
	);

	int iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_DESCRIPTION);
	if(iPos > 0)
	{
		if(iColumnBehaviour == fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME)
		{
			dsColumnFunctions[iPos] = "fwAlarmHandling_tabUtilGetDescriptionOrAliasOrDpe";
		}
		else if(iColumnBehaviour == fwAlarmScreen_BEHAVIOUR_DESCRIPTION_OR_DP_NAME)
		{
			dsColumnFunctions[iPos] = "fwAlarmHandling_tabUtilGetDescriptionOrDpe";
		}
		else
		{
			dsColumnFunctions[iPos] = "fwAlarmHandling_tabUtilGetDescription";
		}

		dpSetWait(fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_FUNCTIONS, dsColumnFunctions);
	}
	else
	{
		fwException_raise(
			dsExceptions,
			"ERROR",
			"The description column could not be found in the AES Config.",
			""
		);
	}
}

/**
  @par Description:
  Set wether or not the whole row should be colored.

  @par Usage:
	Public.

  @param bColorWholeRow bool intput,        True : do color the row. False don't.
  @param dsExceptions   dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_setRowColourBehaviour(bool bColorWholeRow, dyn_string &dsExceptions)
{
	int iPos;
	dyn_bool dbUseAlertClassCOlor;
	dyn_string dsColumnNames;

	dpGet(
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_NAMES, dsColumnNames,
		fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_BACKCOL, dbUseAlertClassCOlor
	);

	for(int i = 1 ; i <= dynlen(dbUseAlertClassCOlor) ; i++)
	{
		dbUseAlertClassCOlor[i] = bColorWholeRow;
	}

	iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_SHORT_SIGN);
	if(iPos > 0)
	{
		dbUseAlertClassCOlor[iPos] = TRUE;
	}
	else
	{
		fwException_raise(dsExceptions, "ERROR", "The short sign column could not be found in the AES Config.", "");
	}

	iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_PRIORITY);
	if(iPos > 0)
	{
		dbUseAlertClassCOlor[iPos] = TRUE;
	}
	else
	{
		fwException_raise(dsExceptions, "ERROR", "The priority column could not be found in the AES Config.", "");
	}

	iPos = dynContains(dsColumnNames, fwAlarmScreen_COLUMN_ACKNOWLEDGE);
	if(iPos > 0)
	{
		dbUseAlertClassCOlor[iPos] = FALSE;
	}
	else
	{
		fwException_raise(dsExceptions, "ERROR", "The priority column could not be found in the AES Config.", "");
	}

	dpSetWait(fwAlarmScreen_PVSS_CONFIG_DP + fwAlarmScreen_PVSS_CONFIG_COLUMN_BACKCOL, dbUseAlertClassCOlor);
}

/**
  @par Description:
  Change the visibility of the named column in the Alarm Screen.
  The given PVSS runtime dp should be the one that corresponds to the alarm screen display you want to update.

  @par Usage:
	Internal.


  @param sPvssAesPropertiesDp string input,       The PVSS runtime properties dp for the given alarm screen.
  @param sColumnName          string input,       The name of the column to be hidden/shown.
  @param bVisible             bool input,         True to show the designated column, false to hide it.
  @param dsExceptions         dyn_string output,  List of exceptions that occurred during execution.
  @param bUpdateAes           bool input,         True to perform an aes_doRestart after the operation, false not to perform it.
*/
void  fwAlarmScreen_showHideColumn(string sPvssAesPropertiesDp, string sColumnName, bool bVisible, dyn_string &dsExceptions, bool bUpdateAes = FALSE)
{
	dyn_string dsVisibleColumns;

	dpGet(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);
	int iPos = dynContains(dsVisibleColumns, sColumnName);

	if(bVisible)
	{
		if(iPos <= 0)
		{
			dynAppend(dsVisibleColumns, sColumnName);
		}
	}
	else
	{
		if(iPos > 0)
		{
			dynRemove(dsVisibleColumns, iPos);
		}
	}

	dpSetWait(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);
  	dpSetCache(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);

	if(bUpdateAes)
	{
		aes_doRestart(sPvssAesPropertiesDp, FALSE);
	}
}

/**
  @par Description:
  Get the visibility of the named column in the Alarm Screen.
  The given PVSS runtime DP should be the one that corresponds to the alarm screen display you want to update.

  @par Usage:
	Internal.


  @param sPvssAesPropertiesDp string input,       The PVSS runtime properties DP for the given alarm screen.
  @param sColumnName          string input,       The name of the column to be hidden/shown.
  @param bVisible             bool output,        True to show the designated column, false to hide it.
  @param dsExceptions         dyn_string output,  List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_getShowHideColumn(string sPvssAesPropertiesDp, string sColumnName, bool &bVisible, dyn_string &dsExceptions)
{
	dyn_string dsVisibleColumns;

	dpGet(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);
	int iPos = dynContains(dsVisibleColumns, sColumnName);


	if(iPos <= 0)
	{
		bVisible = false;
	}
	if(iPos > 0)
	{
		bVisible = true;
	}
}

/**
  @par Description:
  Callback that will be triggered when the user modifies the visibility of the table
  columns AND saves the configuration.
  It will update the runtime properties DP to chane the visibility of the named columns in the Alarm Screen

  @par Usage:
	Internal.


  @param sDpe string input,       The DPE that was modified and triggered this callback.
*/
void fwAlarmScreen_setAesColumnVisibility(const string& sDpe)
{
  const string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);
  const dyn_string dsShowableColumns = fwAlarmScreen_getShowableColumns();
    
  dyn_string dsColumnVisibility;
  dpGet(sDpe, dsColumnVisibility);
  
  dyn_string dsColumnNames;
  dyn_bool   dbVisibility;

  bool bVisible = false;  
  dyn_string dsTokens;
  for(int i = 1; i <= dynlen(dsColumnVisibility); i++) {
    dsTokens = strsplit(dsColumnVisibility[i], FWALARMSCREEN_GENERIC_CONFIGURATION_COLUMNS_SEPARATOR);
    
    if(dynContains(dsShowableColumns, dsTokens[1]) > 0) {
      bVisible = ("TRUE" == dsTokens[2])?true:false;
      
      dynAppend(dsColumnNames, dsTokens[1]);
      dynAppend(dbVisibility, bVisible);
    }
  }
  
  dyn_string dsExceptions;
  fwAlarmScreen_showHideColumns(sPropertiesDp, dsColumnNames, dbVisibility, dsExceptions, true);
  /*
   * Update also the fwAlarmSreen_PROPERTIES_DP to load the changes again when
   * re-opening the alarm screen.
   */
  fwAlarmScreen_showHideColumns(fwAlarmScreen_PROPERTIES_DP, dsColumnNames, dbVisibility, dsExceptions, true);
}

/**
  @par Description:
  Change the visibility of the named columns in the Alarm Screen.

  @par Usage:
	Internal.

  @param sPvssAesPropertiesDp string input,       The PVSS runtime properties dp for the given alarm screen.
  @param dsColumnName         dyn_string input,   The names of the columns to be hidden/shown.
  @param dbVisible            dyn_bool input,     True to show the corresponding column, false to hide it.
  @param dsExceptions         dyn_string output,  List of exceptions that occurred during execution.
  @param bUpdateAes           bool input,         True to perform an aes_doRestart after the operation, false not to perform it.
*/
void  fwAlarmScreen_showHideColumns(string sPvssAesPropertiesDp, dyn_string dsColumnName, dyn_bool dbVisible, dyn_string &dsExceptions, bool bUpdateAes = FALSE)
{
	dyn_string dsVisibleColumns;

	dpGet(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);

	for(int i = 1 ; i <= dynlen(dbVisible) ; i++)
	{
		int iPos = dynContains(dsVisibleColumns, dsColumnName[i]);

		if(dbVisible[i])
		{
			if(iPos <= 0)
			{
				dynAppend(dsVisibleColumns, dsColumnName[i]);
			}
		}
		else
		{
			if(iPos > 0)
			{
				dynRemove(dsVisibleColumns, iPos);
			}
		}
	}

	dpSetWait(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);
  	dpSetCache(sPvssAesPropertiesDp + ".Both.Visible.VisibleColumns", dsVisibleColumns);

	if(bUpdateAes)
	{
		aes_doRestart(sPvssAesPropertiesDp, FALSE);
	}
}

/**
  @par Description:
  Set the default filter to be loaded when the panel starts.

  @par Usage:
	Internal.

  @param sDefaultFilter string input,     The PVSS runtime properties dp for the given alarm screen.
  @param dsExceptions  dyn_string output, List of exceptions that occurred during execution.
*/
void  fwAlarmScreen_setDefaultFilterName(string sDefaultFilter, dyn_string &dsExceptions)
{
	if(strlen(sDefaultFilter) != 0)
	{
		if(strpos(sDefaultFilter, fwAlarmScreen_FILTER_DP_PREFIX) != 0)
		{
			sDefaultFilter = fwAlarmScreen_FILTER_DP_PREFIX + sDefaultFilter;
		}
	}

	dpSetWait("_FwAesSetup.defaultFilter", sDefaultFilter);
}

// ----------------------------------------------------------------------------
// --------------------------------- Settings ---------------------------------
// ----------------------------------------------------------------------------
// Functions to set or get the settings configurable in the options panel.

void fwAlarmScreen_setReductionMode(string pvssAesPropertiesDp, int reductionMode, dyn_string &exceptionInfo)
{
	dpSetWait(pvssAesPropertiesDp + ".Alerts.FilterTypes.AlertSummary", reductionMode);
}

void fwAlarmScreen_getReductionMode(string sPropertiesDp, int &reductionMode, dyn_string &exceptionInfo)
{
	dpGet(sPropertiesDp + ".Alerts.FilterTypes.AlertSummary", reductionMode);
}

void fwAlarmScreen_setOnlineValueUpdateRate(float updateRate, dyn_string &exceptionInfo)
{
	dpSetWait("_FwAesSetup.onlineValueUpdateRate", updateRate);
}

void fwAlarmScreen_getOnlineValueUpdateRate(float &updateRate, dyn_string &exceptionInfo)
{
	dpGet("_FwAesSetup.onlineValueUpdateRate", updateRate);
}

void  fwAlarmScreen_setDistSystemDisplayOption(bool displayDetails, dyn_string &exceptionInfo)
{
	dpSetWait("_FwAesSetup.displayDistSystemDetails", displayDetails);
}

void  fwAlarmScreen_getDistSystemDisplayOption(bool &displayDetails, dyn_string &exceptionInfo)
{
	dpGet("_FwAesSetup.displayDistSystemDetails", displayDetails);
}

void  fwAlarmScreen_setScrollLockTimeout(int scrollLockTimeout, dyn_string &exceptionInfo)
{
	dpSetWait("_Config.TimeoutJumping", scrollLockTimeout);
}

void  fwAlarmScreen_getScrollLockTimeout(int &scrollLockTimeout, dyn_string &exceptionInfo)
{
	dpGet("_Config.TimeoutJumping", scrollLockTimeout);
}

void  fwAlarmScreen_setHistoricalMaxLines(int maxLines, dyn_string &exceptionInfo)
{
	dpSetWait("_FwAesSetup.historicalMaxLines", maxLines);
}

void  fwAlarmScreen_getHistoricalMaxLines(int &iMaxLines, dyn_string &exceptionInfo)
{
	if(dpExists("_FwAesSetup.historicalMaxLines"))
	{
		dpGet("_FwAesSetup.historicalMaxLines", iMaxLines);
		if(iMaxLines == 0)
		{
			iMaxLines = 100;
			dpSet("_FwAesSetup.historicalMaxLines", iMaxLines);
		}
	}
	else
	{
		iMaxLines = 0;
		fwException_raise(exceptionInfo, "WARNING", "fwAlarmScreen.ctl: could not find the dpe _FwAesSetup.historicalMaxLines", "");
	}
}

void  fwAlarmScreen_setIdleTimeout(float idleTimeout, dyn_string &exceptionInfo)
{
	dpSetWait("_FwAesSetup.idleTimeoutMinutes", idleTimeout);
}

void  fwAlarmScreen_getIdleTimeout(int &idleTimeout, dyn_string &exceptionInfo)
{
	dpGet("_FwAesSetup.idleTimeoutMinutes", idleTimeout);
}

void  fwAlarmScreen_setHelpFileFormats(dyn_string fileExtensions, dyn_string windowsCommand, dyn_string linuxCommand, dyn_string &exceptionInfo)
{
	dpSetWait(
		fwAlarmScreen_HELP_FORMAT_EXTENSIONS, fileExtensions,
		fwAlarmScreen_HELP_FORMAT_COMMANDS_WINDOWS, windowsCommand,
		fwAlarmScreen_HELP_FORMAT_COMMANDS_LINUX, linuxCommand
	);
}

void  fwAlarmScreen_getHelpFileFormats(dyn_string &fileExtensions, dyn_string &windowsCommand, dyn_string &linuxCommand, dyn_string &exceptionInfo)
{
	int numberOfExtensions;

	dpGet(
		fwAlarmScreen_HELP_FORMAT_EXTENSIONS, fileExtensions,
		fwAlarmScreen_HELP_FORMAT_COMMANDS_WINDOWS, windowsCommand,
		fwAlarmScreen_HELP_FORMAT_COMMANDS_LINUX, linuxCommand
	);

	numberOfExtensions = dynlen(fileExtensions);

	if(dynlen(windowsCommand) < numberOfExtensions)
	{
		windowsCommand[numberOfExtensions] = "";
	}
	if(dynlen(linuxCommand) < numberOfExtensions)
	{
		linuxCommand[numberOfExtensions] = "";
	}
}

void  fwAlarmScreen_setEnableGroups(bool bEnable)
{
	dpSetWait("_FwAesSetup.enableGroups", bEnable);
}

void  fwAlarmScreen_setEnableAlarmFilter(bool bEnable)
{
	dpSetWait("_FwAesSetup.enableAlarmFilter", bEnable);
}

bool  fwAlarmScreen_getEnableGroups()
{
	bool bEnabled;
	dpGet("_FwAesSetup.enableGroups", bEnabled);

	return bEnabled;
}

bool  fwAlarmScreen_getEnableAlarmFilter()
{
	bool bEnabled;
	dpGet("_FwAesSetup.enableAlarmFilter", bEnabled);

	return bEnabled;
}


void  fwAlarmScreen_setInvertPriorities(bool bInvert)
{
	dpSetWait("_FwAesSetup.invertPriorities", bInvert);
}

bool  fwAlarmScreen_getInvertPriorities()
{
	bool bInvert;
	dpGet("_FwAesSetup.invertPriorities", bInvert);

	return bInvert;
}

void  _fwAlarmScreen_createPlotDp(string plotName)
{
	dyn_string exceptionInfo;
	dyn_dyn_anytype plotData;

	if(!isFunctionDefined("fwTrending_createPlot"))
	{
		return;
	}

	if(!dpExists(plotName))
	{
		plotData[fwTrending_PLOT_OBJECT_MODEL][1]               = fwTrending_YT_PLOT_MODEL;
		plotData[fwTrending_PLOT_OBJECT_TITLE][1]               = "Settings for Alarm Screen Plot";
		plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1]           = FALSE;
		plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1]          = "FwTrendingTrendBackground";
		plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1]          = "FwTrendingTrendForeground";
		plotData[fwTrending_PLOT_OBJECT_DPES]                   = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}");
		plotData[fwTrending_PLOT_OBJECT_DPES_X]                 = makeDynString();
		plotData[fwTrending_PLOT_OBJECT_LEGENDS]                = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}");
		plotData[fwTrending_PLOT_OBJECT_LEGENDS_X]              = makeDynString();
		plotData[fwTrending_PLOT_OBJECT_COLORS]                 = makeDynString("FwTrendingCurve2", "FwTrendingCurve3", "FwTrendingCurve4", "FwTrendingCurve5", "FwTrendingCurve7", "FwTrendingCurve1", "FwTrendingCurve6", "FwTrendingCurve8");
		plotData[fwTrending_PLOT_OBJECT_AXII]                   = makeDynBool(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);
		plotData[fwTrending_PLOT_OBJECT_AXII_X]                 = makeDynBool();
		plotData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1]         = FALSE;
		plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN]          = makeDynBool(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);;
		plotData[fwTrending_PLOT_OBJECT_RANGES_MIN]             = makeDynInt(0, 0, 0, 0, 0, 0, 0, 0);
		plotData[fwTrending_PLOT_OBJECT_RANGES_MAX]             = makeDynInt(0, 0, 0, 0, 0, 0, 0, 0);
		plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X]           = makeDynInt();
		plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X]           = makeDynInt();
		plotData[fwTrending_PLOT_OBJECT_TYPE][1]                = fwTrending_PLOT_TYPE_STEPS;
		plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1]          = 3600;
		plotData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1]       = "";
		plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1]      = FALSE;
		plotData[fwTrending_PLOT_OBJECT_GRID][1]                = TRUE;
		plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES]            = makeDynInt(
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS
				);
		plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1]         = fwTrending_MARKER_TYPE_FILLED_CIRCLE;
		plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1] = "";
		plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]      = makeDynString(1, 0, 0, 0, 0, 0, 0, 0);
		plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1]      = 3;
		plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]        = fwTrending_DEFAULT_FONT;
		plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]         = "[solid,oneColor,JoinMiter,CapButt,2]";

		fwTrending_createPlot(plotName, exceptionInfo);

		if(dynlen(exceptionInfo) == 0)
		{
			while(!dpExists(plotName))
			{
				delay(0, 100);
			}
		}
	}
	else
	{
		fwTrending_getPlot(plotName, plotData, exceptionInfo);
		plotData[fwTrending_PLOT_OBJECT_TYPE][1]            = fwTrending_PLOT_TYPE_STEPS;
		plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES]        = makeDynInt(
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS,
					fwTrending_PLOT_TYPE_STEPS
				);
		plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]  = makeDynString(1, 0, 0, 0, 0, 0, 0, 0);
		plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1]  = 3;
		plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]    = fwTrending_DEFAULT_FONT;
		plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]     = "[solid,oneColor,JoinMiter,CapButt,2]";
	}

	fwTrending_setPlot(plotName, plotData, exceptionInfo);
}


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// --------------------------- RIGHT CLICK FUNCTIONS-----------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Get the name of the currently active alarm table.  
  We need this to get the right data when right clicking on an alarm.  
  When selecting an alarm group we take table fwAlarmScreen_GROUP_ALARM_TABLE
  otherwise we take standard alarm table AES_TABLENAME_TOP.

  @par Usage:
  Internal.

  @return  string, The name of the active alarm table
*/
private string _fwAlarmScreen_getAlarmTableName() {          
	// textFieldSelectedGroup is even present and being written, if alarm groups are disabled.
	// So we don't have to check for 'fwAlarmScreen_getEnableGroups' and shapeExists("textFieldSelectedGroup"
	if(textFieldSelectedGroup.text != "") { // A group is selected
		return fwAlarmScreen_GROUP_ALARM_TABLE;   
	}            
	return AES_TABLENAME_TOP;
}

/**
  @par Description:
  Return the list of possible right click menu options for line iRow and column sColumn.

  @par Usage:
  Internal.

  @param[in]  iRow    int,    The line that was right-clicked.
  @param[in]  sColumn string, The column that was right-clicked.
*/
dyn_string fwAlarmScreen_getRightClickMenuOptions(int iRow, string sColumn)
{
	dyn_string dsAccessRights;
	dyn_string dsMenuConfig;
	dyn_string dsMenuItems;
	dyn_string dsMenuFunctions;
	dyn_string dsMenuAlertTypes;
	dyn_string dsExceptions;

	bool bIsGranted = true;

	mapping mRowHeaderMapping;

	int iAlertType;

	if(isFunctionDefined("fwAccessControl_isGranted"))
	{
		fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

		if(dsAccessRights[fwAlarmScreen_ACCESS_RIGHT_CLICK] != "")
		{
			fwAccessControl_isGranted(dsAccessRights[fwAlarmScreen_ACCESS_RIGHT_CLICK], bIsGranted, dsExceptions);
		}
		else
		{
			bIsGranted = true;
		}
	}

	string sAlarmTable = _fwAlarmScreen_getAlarmTableName(); 

	setInputFocus(myModuleName(), myPanelName(), sAlarmTable);

	dyn_anytype daAlertRow;
	getValue(sAlarmTable, "getLineN", iRow, daAlertRow);
	for(int i = 1; i <= dynlen(daAlertRow) ; i++)
	{
		string sColumnName;
		getValue(sAlarmTable, "columnName", i - 1, sColumnName);

		mRowHeaderMapping[sColumnName] = daAlertRow[i];
	}

	if("" == mRowHeaderMapping[_DPID_])
	{
		return dsMenuConfig;
	}

	dpGet(dpSubStr(mRowHeaderMapping[_DPID_], DPSUB_SYS_DP_EL) + ":_alert_hdl.._type", iAlertType);

	fwAlarmScreen_getRightClickConfig(dsMenuItems, dsMenuFunctions, dsMenuAlertTypes, dsExceptions);

	if(0 == dynlen(dsMenuItems))
	{
		return dsMenuConfig;
	}

	for(int i = 1; i <= dynlen(dsMenuItems); i++)
	{
		bool bEnableOption = true;
		if(!bIsGranted)
		{
			bEnableOption = false;
		}
		else if((iAlertType == DPCONFIG_SUM_ALERT) && (dsMenuAlertTypes[i] == "NO_SUMMARY"))
		{
			bEnableOption = false;
		}
		else if((iAlertType != DPCONFIG_SUM_ALERT) && (dsMenuAlertTypes[i] == "ONLY_SUMMARY"))
		{
			bEnableOption = false;
		}

		// Special option to disable default trending option is trending not installed
		if((dsMenuItems[i] == "Trend") && (getPath(PANELS_REL_PATH, "fwTrending/fwTrendingZoomedWindow.pnl") == ""))
		{
			bEnableOption = false;
		}

		dynAppend(dsMenuConfig, "PUSH_BUTTON," + dsMenuItems[i] + ", " + i + ", " + (int) bEnableOption);
	}


	return dsMenuConfig;
}

/**
  @par Description:
  Action on right-click menu selection.

  @par Usage:
  Internal.

  @param[in]  iAnswer int,    The ID of the element of the menu clicked.
  @param[in]  iRow    int,    The row that was right-clicked.
  @param[in]  sColumn string, The column that was right-clicked.
*/
void fwAlarmScreen_treatRightClickAnswer(int iAnswer, int iRow, string sColumn)
{
	const string sPropertiesDp = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);
	mapping mRowHeaderMapping;
	dyn_anytype daAlertRow;
	string sAlarmTable = _fwAlarmScreen_getAlarmTableName();
	getValue(sAlarmTable, "getLineN", iRow, daAlertRow);
	for(int i = 1; i <= dynlen(daAlertRow) ; i++)
	{
		string sColumnName;
		getValue(sAlarmTable, "columnName", i - 1, sColumnName);

		mRowHeaderMapping[sColumnName] = daAlertRow[i];
	}

	dyn_string dsMenuItems;
	dyn_string dsMenuFunctions;
	dyn_string dsMenuAlertTypes;
	dyn_string dsExceptions;
	fwAlarmScreen_getRightClickConfig(dsMenuItems, dsMenuFunctions, dsMenuAlertTypes, dsExceptions);

	if(iAnswer != 0)
	{
		evalScript(
			dsExceptions,
			"dyn_string main(mapping mRowHeaderMapping, int row, string sPropertiesDp, int iTabType, string sTableName, dyn_string exInfo)" +
			"{  " +
			"  " + dsMenuFunctions[iAnswer] + "(mRowHeaderMapping, row, sPropertiesDp, iTabType, sTableName, exInfo);" +
			"  return exInfo;" +
			"}",
			makeDynString(),
			mRowHeaderMapping,
			iRow,
			sPropertiesDp,
			AESTAB_TOP,
			sAlarmTable,
			dsExceptions
		);
	}

	if(dynlen(dsExceptions) > 0)
	{
		fwExceptionHandling_display(dsExceptions);
	}
}

/**
  @par Description:
  Action on right-click => "Show trend".

  @par Usage:
  Internal.

  @param[in]  mRowHeaderMapping mapping,    Content of the right-clicked line. Key: column name, value: cell value.
  @param[in]  iRow              int,        The row that was right-clicked.
  @param[in]  sPropertiesDp     string,     The AES properties DP for the current panel.
  @param[in]  iTabType          int,        Irrelevant (backward compatibility remain).
  @param[in]  sTableName        string,     The table that was clicked.
  @param[out] dsExceptions      dyn_string, A list of errors that happened during the execution of the function.
*/
void _fwAlarmScreen_showTrend(mapping mRowHeaderMapping, int iRow, string sPropertiesDp, int iTabType, string sTableName, dyn_string &dsExceptions)
{
	string sDpId = mRowHeaderMapping[_DPID_];
	string sDpe = dpSubStr(sDpId, DPSUB_SYS_DP_EL);

	if(isFunctionDefined("fwAlarmScreenUser_showTrend"))
	{
		fwAlarmScreenUser_showTrend(sDpId, sTableName, iRow, dsExceptions);
	}
	else
	{
		ChildPanelOnCentral(
			"fwAlarmHandling/fwAlarmScreenTrend.pnl",
			"Trend for " + sDpe,
			makeDynString("$sDpe:" + sDpe)
		);
	}
}

/**
  @par Description:
  Action on right-click => "Show FSM panel".

  @par Usage:
  Internal.

  @param[in]  mRowHeaderMapping mapping,    Content of the right-clicked line. Key: column name, value: cell value.
  @param[in]  iRow              int,        The row that was right-clicked.
  @param[in]  sPropertiesDp     string,     The AES properties DP for the current panel.
  @param[in]  iTabType          int,        Irrelevant (backward compatibility remain).
  @param[in]  sTableName        string,     The table that was clicked.
  @param[out] dsExceptions      dyn_string, A list of errors that happened during the execution of the function.
*/
void _fwAlarmScreen_showFsmPanel(mapping mRowHeaderMapping, int iRow, string sPropertiesDp, int iTabType, string sTableName, dyn_string &dsExceptions)
{
	string sDpId = mRowHeaderMapping[_DPID_];
	string dpName, dpSystem, nodeName = "";
	dyn_string parts;
	dyn_dyn_anytype queryResult;

	if(isFunctionDefined("fwAlarmScreenUser_showFsmPanel"))
	{
		fwAlarmScreenUser_showFsmPanel(sDpId, sTableName, iRow, dsExceptions);
		return;
	}

	dpName = dpSubStr(sDpId, DPSUB_SYS_DP);
	dpSystem = dpSubStr(sDpId, DPSUB_SYS);

	if(dpTypeName(dpName) == "_FwFsmObject")
	{
		parts = strsplit(dpName, "|");
		if(dynlen(parts) > 2)
		{
			nodeName = parts[2] + "::" + parts[3];
		}
		else
		{
			nodeName = parts[2];
		}
	}
	else
	{
		dpQuery("SELECT '_original.._value' FROM '*.tnode' REMOTE '" + dpSystem + "' WHERE '_original.._value' == \"" + dpName + "\"", queryResult);

		if(dynlen(queryResult) >= 2)
		{
			nodeName = dpSubStr(queryResult[2][1], DPSUB_DP);
			strreplace(nodeName, "|", "::");
		}
	}

	if(nodeName != "")
	{
		fwCU_view(nodeName);
	}
	else
	{
		fwException_raise(dsExceptions, "ERROR", "The corresponding FSM object could not be found", "");
	}
}

/**
  @par Description:
  Action on right-click => "Show details".

  @par Usage:
  Internal.

  @param[in]  mRowHeaderMapping mapping,    Content of the right-clicked line. Key: column name, value: cell value.
  @param[in]  iRow              int,        The row that was right-clicked.
  @param[in]  sPropertiesDp     string,     The AES properties DP for the current panel.
  @param[in]  iTabType          int,        Irrelevant (backward compatibility remain).
  @param[in]  sTableName        string,     The table that was clicked.
  @param[out] dsExceptions      dyn_string, A list of errors that happened during the execution of the function.
*/
void _fwAlarmScreen_showDetails(mapping mRowHeaderMapping, int iRow, string sPropertiesDp, int iTabType, string sTableName, dyn_string &dsExceptions)
{
	string sDpId = mRowHeaderMapping[_DPID_];
	mapping mTableMultipleRows;

	mTableMultipleRows[iRow] = mRowHeaderMapping;

	if(isFunctionDefined("fwAlarmScreenUser_showDetails"))
	{
		fwAlarmScreenUser_showDetails(sDpId, sTableName, iRow, dsExceptions);
	}
	else
	{
		aes_displayDetails(iTabType, iRow, sPropertiesDp, mTableMultipleRows[iRow]);
	}
}


/**
  @par Description:
  Action on right-click => "Show Comment Panel".

  @par Usage:
  Internal.

  @param[in]  mRowHeaderMapping mapping,    Content of the right-clicked line. Key: column name, value: cell value.
  @param[in]  iRow              int,        The row that was right-clicked.
  @param[in]  sPropertiesDp     string,     The AES properties DP for the current panel.
  @param[in]  iTabType          int,        Irrelevant (backward compatibility remain).
  @param[in]  sTableName        string,     The table that was clicked.
  @param[out] dsExceptions      dyn_string, A list of errors that happened during the execution of the function.
*/
void _fwAlarmScreen_showCommentPanel(mapping mRowHeaderMapping, int iRow, string sPropertiesDp, int iTabType, string sTableName, dyn_string &dsExceptions)
{
  string sFunctionInsertComment = "aes_insertComment";
  if ( isFunctionDefined(sFunctionInsertComment))
  {
    callFunction( sFunctionInsertComment, iRow,  mRowHeaderMapping);
  } else
  {
    ChildPanelOnCentralModal("vision/MessageWarning", __FUNCTION__, 
      makeDynString( "$1:" + "Unable to open comment panel.\nFunction does not exist: "+sFunctionInsertComment ));
  }
}

/**
  @par Description:
  Action on right-click => "Show help".

  @par Usage:
  Internal.

  @param[in]  mRowHeaderMapping mapping,    Content of the right-clicked line. Key: column name, value: cell value.
  @param[in]  iRow              int,        The row that was right-clicked.
  @param[in]  sPropertiesDp     string,     The AES properties DP for the current panel.
  @param[in]  iTabType          int,        Irrelevant (backward compatibility remain).
  @param[in]  sTableName        string,     The table that was clicked.
  @param[out] dsExceptions      dyn_string, A list of errors that happened during the execution of the function.
*/
void _fwAlarmScreen_showHelp(mapping mRowHeaderMapping, int iRow, string sPropertiesDp, int iTabType, string sTableName, dyn_string &dsExceptions)
{
	string fileName;
	string dpId = mRowHeaderMapping[_DPID_];
	string dpe = dpSubStr(dpId, DPSUB_SYS_DP_EL);

	_fwAlarmScreen_addHelpOpenComment(dpId, sTableName, iRow, dsExceptions);
	if(isFunctionDefined("fwAlarmScreenUser_showHelp"))
	{
		fwAlarmScreenUser_showHelp(dpId, sTableName, iRow, dsExceptions);
	}
	else
	{
		fwAlarmScreen_findHelpFile(dpe, fileName, dsExceptions);
		fwAlarmScreen_openHelpFile(fileName, dsExceptions);
	}
}


// Functions internally used in the right-click functions above.

/**
  @par Description:
  Get the right-click menu:
    - Item labels.
    - Item action function.
    - Item alert type: which alarm type this item can act on (summary, non summary, all).

  @par Usage:
  Internal.

  @param[out] menuItems       dyn_string, The list of menu entries labels.
  @param[out] menuFunctions   dyn_string, The list of menu entries action functions.
  @param[out] menuAlertTypes  dyn_string, The list of menu entries alert types.
  @param[out] exceptionInfo   dyn_string, A list of errors that happened during the execution of the function.
*/
void fwAlarmScreen_getRightClickConfig(dyn_string &menuItems, dyn_string &menuFunctions, dyn_string &menuAlertTypes, dyn_string &exceptionInfo)
{
	dpGet(
		"_FwAesSetup.rightClickMenu.items", menuItems,
		"_FwAesSetup.rightClickMenu.functions", menuFunctions,
		"_FwAesSetup.rightClickMenu.alertTypes", menuAlertTypes
	);
}

void fwAlarmScreen_findHelpFile(string dpe, string &fileName, dyn_string &exceptionInfo)
{
	dyn_string searchPatterns, searchDirectories, fileSuffix;
	string fileNameToCheck, dpType, dpElement, dpSystem, dpName, dpAlias, dpElementAlias, dpDescription, dpElementDescription;

	dpSystem = dpSubStr(dpe, DPSUB_SYS);

	dpName = dpSubStr(dpe, DPSUB_SYS_DP);
	dpType = dpTypeName(dpName);
	dpAlias = dpGetAlias(dpName);
	dpDescription = dpGetDescription(dpName);

	dpElement = dpSubStr(dpe, DPSUB_SYS_DP_EL);
	strreplace(dpElement, dpSubStr(dpe, DPSUB_SYS_DP), "");
	dpElementAlias = dpGetAlias(dpName + dpElement);
	dpElementDescription = dpGetDescription(dpName + dpElement);

	dpGet(fwAlarmScreen_HELP_FORMAT_EXTENSIONS, fileSuffix);
	dynAppend(fileSuffix, "");

	searchPatterns = makeDynString(
						 // DP descriptions
						 dpSystem + dpElementDescription + dpElement, dpElementDescription + dpElement,
						 dpSystem + dpDescription + dpElement, dpDescription + dpElement,

						 // DP aliases
						 dpSystem + dpElementAlias + dpElement, dpElementAlias + dpElement,
						 dpSystem + dpAlias + dpElement, dpAlias + dpElement,

						 // DP names
						 dpSubStr(dpe, DPSUB_SYS_DP_EL), dpSubStr(dpe, DPSUB_DP_EL),
						 dpSubStr(dpe, DPSUB_SYS_DP), dpSubStr(dpe, DPSUB_DP),

						 // DP types
						 dpSystem + dpType + dpElement, dpType + dpElement,
						 dpSystem + dpType, dpType
					 );

	searchDirectories = makeDynString(
							// DP escriptions
							fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT, fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT,
							fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION, fwAlarmScreen_HELP_PATH_DEVICE_DESCRIPTION,

							// DP aliases
							fwAlarmScreen_HELP_PATH_DEVICE_ALIAS_ELEMENT, fwAlarmScreen_HELP_PATH_DEVICE_ALIAS_ELEMENT,
							fwAlarmScreen_HELP_PATH_DEVICE_ALIAS, fwAlarmScreen_HELP_PATH_DEVICE_ALIAS,

							// DP names
							fwAlarmScreen_HELP_PATH_DEVICE_ELEMENT, fwAlarmScreen_HELP_PATH_DEVICE_ELEMENT,
							fwAlarmScreen_HELP_PATH_DEVICE, fwAlarmScreen_HELP_PATH_DEVICE,

							// DP types
							fwAlarmScreen_HELP_PATH_DEVICE_TYPE_ELEMENT, fwAlarmScreen_HELP_PATH_DEVICE_TYPE_ELEMENT,
							fwAlarmScreen_HELP_PATH_DEVICE_TYPE, fwAlarmScreen_HELP_PATH_DEVICE_TYPE
						);

	if(fwAlarmScreen_getCustomHelpFile(dpe, fileName, exceptionInfo))
	{
		return;
	}

	for(int i = 1; i <= dynlen(searchPatterns); i++)
	{
		strreplace(searchPatterns[i], fwDevice_HIERARCHY_SEPARATOR, "_");
		strreplace(searchPatterns[i], ":", "_");
		fileNameToCheck = dpName;

		for(int j = 1; j <= dynlen(fileSuffix); j++)
		{
			fileName = getPath(HELP_REL_PATH, fwAlarmScreen_HELP_PATH_ROOT + searchDirectories[i] + fileNameToCheck + fileSuffix[j]);

			if(fileName != "")
			{
				return;
			}
		}
	}

	fileName = getPath(HELP_REL_PATH, fwAlarmScreen_HELP_PATH_ROOT + fwAlarmScreen_HELP_FILE_DEFAULT);
}

bool fwAlarmScreen_getCustomHelpFile(string dpe, string &helpFilePath, dyn_string &exceptionInfo)
{
	dyn_bool result;
	dyn_string helpStrings;

	result = fwAlarmScreen_getManyCustomHelpFile(makeDynString(dpe), helpStrings, exceptionInfo);
	helpFilePath = helpStrings[1];
	return result[1];
}

dyn_bool fwAlarmScreen_getManyCustomHelpFile(dyn_string dpes, dyn_string &helpFilePaths, dyn_string &exceptionInfo)
{
	int length, position;
	dyn_bool result;
	dyn_int configTypes;
	dyn_string helpStringsToRead, helpStrings;

	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_GENERAL, configTypes, exceptionInfo);

	length = dynlen(dpes);
	for(int i = 1; i <= length; i++)
	{
		if(configTypes[i] != DPCONFIG_NONE)
		{
			dynAppend(helpStringsToRead, dpes[i]);
		}
	}

	if(dynlen(helpStringsToRead) > 0)
	{
		_fwConfigs_getConfigTypeAttribute(helpStringsToRead, fwConfigs_PVSS_GENERAL, helpStrings, exceptionInfo, fwAlarmScreen_HELP_PATH_ATTRIBUTE);
	}

	for(int i = 1; i <= length; i++)
	{
		position = dynContains(helpStringsToRead, dpes[i]);
		if(position > 0)
		{
			helpFilePaths[i] = helpStrings[position];
		}
		else
		{
			helpFilePaths[i] = "";
		}

		result[i] = (helpFilePaths[i] != "");
	}

	return result;
}

void fwAlarmScreen_openHelpFile(string fileName, dyn_string &exceptionInfo)
{
	int replaced, position;
	string openCommand, suffix;
	dyn_string fileNameParts, fileExtensions, windowsCommand, linuxCommand;

	//check if this is a relative path or absolute path
	if((strpos(fileName, ":") < 0) && (strpos(fileName, "/") != 0) && (strpos(fileName, "\\") != 0))
	{
		fileName = getPath(HELP_REL_PATH, fwAlarmScreen_HELP_PATH_ROOT + fileName);
	}

	if(fileName == "")
	{
		fwException_raise(exceptionInfo, "ERROR", "No valid file name for an alarm help file", "");
		return;
	}

	//if not http then assume it is a file
	if((strpos(fileName, "http://") != 0) && (strpos(fileName, "https://") != 0))
	{
		//check file is accessible
		if(access(fileName, F_OK) != 0)
		{
			fwException_raise(exceptionInfo, "ERROR", "The help file could not be found: " + fileName, "");
			return;
		}
	}

	//find file suffix
	fileNameParts = strsplit(fileName, ".");
	suffix = fileNameParts[dynlen(fileNameParts)];

	//find command to use to open the file
	fwAlarmScreen_getHelpFileFormats(fileExtensions, windowsCommand, linuxCommand, exceptionInfo);
	position = dynContains(fileExtensions, "." + suffix);
	if(position > 0)
	{
		if(_WIN32)
		{
			openCommand = windowsCommand[position];
		}
		else
		{
			openCommand = linuxCommand[position];
		}
	}

	if((position <= 0) || (openCommand == ""))
	{
		if(_WIN32)
		{
			dpGet("fwGeneral.help.helpBrowserCommandWindows", openCommand);
		}
		else
		{
			dpGet("fwGeneral.help.helpBrowserCommandLinux", openCommand);
		}
	}

	replaced = strreplace(openCommand, "$1", fileName);

	if(replaced == 0)
	{
		openCommand = openCommand + " " + fileName;
	}

	system(openCommand);
}

void _fwAlarmScreen_addHelpOpenComment(string dpId, string tableName, int row, dyn_string& exceptionInfo)
{
	string dpType, dpElement;
	dyn_string exc;
	int ncols;
	string column;
	string columnName;
	int comCol, timeCol, colAtime;

	dpType = dpTypeName(dpId);
	dpElement = dpSubStr(dpId, DPSUB_DP_EL);

	getValue(tableName, "columnCount", ncols);
	for (int i = 0; i < ncols ; i++)
	{
		getValue(tableName, "columnHeader" , i , column);
		getValue(tableName, "columnName" , i , columnName);
		if(columnName == "__V_time")
		{
			colAtime = i;
		}
		{
			switch (column)
			{
				case "Comment":
				{
					comCol = i;
					break;
				}
				case "Time":
				{
					timeCol = i;
					break;
				}
			}
		}
	}

	string value, text, comment, alTime;
	dyn_anytype tableRow;
	getValue(tableName, "getLineN", row, tableRow);
	alTime = tableRow[timeCol + 1];
	comment = tableRow[comCol + 1];

	//writing on comment field
	dpElement = dpSubStr(dpId, DPSUB_SYS_DP_EL);
	dyn_dyn_anytype tab;
	string query;
	if(dpSubStr(dpId, DPSUB_SYS) != getSystemName())
	{
		query = "SELECT ALERT '_alert_hdl.._value' FROM '*' REMOTE '" + dpSubStr(dpId, DPSUB_SYS) + "' WHERE _DPT = \"" + dpType + "\"";

		dpQuery( query, tab);
		if(dynlen(tab) < 2)
		{
			//Try with less tight conditions
			query = "SELECT ALERT '_alert_hdl.._value' FROM '*' REMOTE '" + dpSubStr(dpId, DPSUB_SYS) + "'";
			dpQuery( query, tab);

		}
	}
	else
	{
		query = "SELECT ALERT '_alert_hdl.._value' FROM '*' WHERE  _DPT = \"" + dpType + "\"";
		dpQuery( query, tab);
		if(dynlen(tab) < 2)
		{
			//Try with less tight conditions
			query = "SELECT ALERT '_alert_hdl.._value' FROM '*'";
			dpQuery( query, tab);

		}
	}

	atime t1 ;
	int i, count, len = dynlen(tab);

	for(i = len ; i > 0 ; i--)
	{
		if((tab[i][1] == dpElement) && (tab[i][2] == tableRow[colAtime + 1]))
		{
			//get timestamp of the alarm (it is in the element 2 of tab)
			t1 = tab[i][2];
			break;
		}
	}

	if(i <= len + 1)
	{

		int count = getACount(t1);
		int ret;
		if(comment == "")
		{
			time t = t1;
			ret = alertSet(t, count, dpSubStr(getAIdentifier(t1), DPSUB_SYS_DP_EL_CONF_DET) + "._comment", formatTime("%x %H:%M:%S", getCurrentTime()));
		}
	}
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ----------------------------- THREADED FUNCTIONS -----------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Function started in a thread when the AES stops.
  It leave enough time for the alarm to restart by itself.  If it restart the thread will be stopped before it ends.

  @par Usage:
  Internal.
*/
void _fwAlarmScreen_countDownToShowStopped()
{
	delay(FWALARMSCREEN_DELAY_TIME_OUT_STOP);

	g_stoppedTimeThread = -1;

	// If the screen was stopped, restart it
	dyn_string dsExceptions;
	fwException_raise(dsExceptions, "INFO", "The alarm screen stopped. Restarting it...", "");
	aes_doStart(aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false));
  
  delay(0, 500);
  _fwAlarmScreenGeneric_setColumnsVisibility(true);
}

/**
  @par Description:
  Infinite loop thread that checks if the user is still active. If not, the alarm screen is set back to default view.

  @par Usage:
  Internal.
*/
void fwAlarmScreen_idleCheck()
{
	const int iTimerIncrement = 5;
	int iIdleCounter = 0;

	dyn_anytype daIdleCheck;
	while(1)
	{
		if(idleTimeoutValue.text != 0)
		{
			int iX;
			int iY;
			getCursorPosition(iX, iY);

			int iRow;
			int iColumn;
			getValue(AES_TABLENAME_TOP, "currentCell", iRow, iColumn);

			dyn_anytype daCurrentState = makeDynAnytype(iX, iY, iRow, iColumn, shapeWithFocus.text());
			if(daCurrentState == daIdleCheck)
			{
				iIdleCounter += iTimerIncrement;
			}
			else
			{
				iIdleCounter = 0;
				daIdleCheck = daCurrentState;
			}
		}
		else
		{
			iIdleCounter = 0;
		}

		if(iIdleCounter > (60 * (int) idleTimeoutValue.text))
		{
			fwAlarmScreen_returnToDefaultView();
			fwAlarmScreen_groups_clearGroupAlarms();
			iIdleCounter = 0;
		}

		delay(iTimerIncrement);
	}
}

/**
  @par Description:
  Infinite loop that updates the content of the "Online value" column of the table if it is visible.

  @par Usage:
  Internal.
*/
void fwAlarmScreen_updateOnlineValues()
{
	int iTimer = onlineUpdateRate.text;

	int iOnlineValueColumn;
	int iPreviousStartRow = -1;

	int iLineCount;

	// Locate online value column in table
	getValue(AES_TABLENAME_TOP, "nameToColumn", fwAlarmScreen_COLUMN_ONLINE_VALUE, iOnlineValueColumn);

	while(1)
	{
		if(onlineUpdateRate.text == "0")
		{
			delay(1);
			continue;
		}

		// If column is invisible, just wait again, in case it becomes visible
		bool bVisible;
		getValue(AES_TABLENAME_TOP, "columnVisibility", iOnlineValueColumn, bVisible);

		if(bVisible)
		{
			// If column is visible, get visible rows
			bool bDoUpdate = true;
			int iStartRow;
			int iEndRow;
			getValue(AES_TABLENAME_TOP, "lineRangeVisible", iStartRow, iEndRow);

			if(iStartRow == iPreviousStartRow)
			{
				iTimer--;
				if(iTimer > 0)
				{
					bDoUpdate = false;
				}
				else
				{
					iTimer = onlineUpdateRate.text;
				}
			}

			if(bDoUpdate)
			{
				setValue(AES_TABLENAME_TOP, "stop", true);
			}

			for(int i = iStartRow; i > 0 &&  iEndRow > 0 && bDoUpdate && (i <= iEndRow); i++)
			{
				int alertType;
				anytype onlineValue;
				string dpAttribute, checkDpAttribute, dpeName;

				// For each row, read the dp name
				getValue(AES_TABLENAME_TOP, "cellValueRC", i, _DPID_, dpAttribute);
				if(dpAttribute == "")
				{
					break;
				}
				if(!dpExists(dpAttribute))
				{
					continue;
				}

				dpeName = dpSubStr(dpAttribute, DPSUB_SYS_DP_EL);

				// Check the alert type, if summary then skip to next for loop iteration
				dpGet(dpeName + ":_alert_hdl.._type", alertType);
				if(alertType == DPCONFIG_SUM_ALERT)
				{
					continue;
				}

				// If not summary, then get the value and write it to the cell
				dpGet(dpeName + ":_online.._value", onlineValue);
				getValue(AES_TABLENAME_TOP, "lineCount", iLineCount);
				if (i >= iLineCount)
				{
					break;
				}
				getValue(AES_TABLENAME_TOP, "cellValueRC", i, _DPID_, checkDpAttribute);
				if(dpAttribute != checkDpAttribute)
				{
					break;
				}

				setValue(AES_TABLENAME_TOP, "cellValueRC", i, fwAlarmScreen_COLUMN_ONLINE_VALUE, dpValToString(dpeName, onlineValue));


				getValue(AES_TABLENAME_TOP, "lineRangeVisible", iStartRow, iEndRow);
			}

			if(bDoUpdate)
			{
				setValue(AES_TABLENAME_TOP, "stop", false);
			}

			iPreviousStartRow = iStartRow;
		}

		// Run every second.
		delay(1);
	}
}

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------- CB FUNCTIONS----------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

/**
  @par Description:
  Callback triggered when a new user logs in.
  Connection is internal (fwAlarmScreenGeneric).

  @par Usage:
  Public.

  @param  sUser string input, The user that just logged in.
*/
void fwAlarmScreen_userChanged(const string sUser)
{
	int iCurrentUser = currentUser.text();
	if(iCurrentUser == -1)
	{
		iCurrentUser = getUserId();
	}

	if(iCurrentUser != getUserId())
	{
		if(fwAlarmScreen_watchUser.state(0))
		{
			fwAlarmScreen_returnToDefaultView();
		}
	}

	fwAlarmScreen_reloadQuickFilterList();

	fwAlarmScreen_limitButtonAccess();

	currentUser.text(getUserId());

	bool isGranted = true;
	dyn_string accessRights, dsExceptions;
	isGranted = TRUE;

	fwAlarmScreen_getAccessControlOptions(accessRights, dsExceptions);
	if(accessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY] != "")
	{
		fwAccessControl_isGranted(accessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY], isGranted, dsExceptions);
	}

	pushButtonGroupsSetup.enabled = isGranted;

	fwAlarmScreen_resizePanel();
}

/**
  @par Description:
  Callback triggered when the busy state of the AES changes.

  @par Usage:
  Public.

  @param  sDpe        string input, The DPE that triggered the callback.
  @param  iBusyState  int input,    The new busy state (AES_BUSY_START or AES_BUSY_STOP).
*/
void fwAlarmScreen_busyCallBack(string sDpe, const int iBusyState)
{
	if(iBusyState == AES_BUSY_START)
	{
		fwAlarmScreen_watchUser.state(0) = false;
		fwAlarmScreenGeneric_wait(true);
	}
	else if(iBusyState == AES_BUSY_STOP)
	{
		fwAlarmScreen_watchUser.state(0) = true;
		fwAlarmScreenGeneric_wait(false);
    
    delay(0, 200);
    _fwAlarmScreenGeneric_setColumnsVisibility(true);
  }
}

/**
  @par Description:
  Callback triggered when the AES stops without reason.
  If it is isn't restarted within the next X seconds, it will restart it.

  @par Usage:
  Internal.

  @param[in]  sDpe      string,   Irrelevant.
  @param[in]  uRunMode  unsigned, The new run mode.
*/
void fwAlarmScreen_runningStateCallback(string sDpe, unsigned uRunMode)
{
	if(uRunMode == AES_RUNMODE_STOPPED)
	{
		if (-1 == g_stoppedTimeThread)
		{
			g_stoppedTimeThread = startThread("_fwAlarmScreen_countDownToShowStopped");
		}
	}
	else
	{
		if(-1 != g_stoppedTimeThread)
		{
			stopThread(g_stoppedTimeThread);
			g_stoppedTimeThread = -1;
		}
	}
}

/**
  @par Description:
  Callback triggered on custom or generic alarm screen event.

  @par Usage:
  Internal.

  @param  sDp     string input, The DPE that triggered the callback.
  @param  iEvent  int input,    The event. See constants FWALARMSCREEN_GENERIC_CONFIG_EVENT_xxx or custom events.
*/
void fwAlarmScreen_eventHandler(const string sDp, const int iEvent)
{
	switch(iEvent)
	{
		case FWALARMSCREEN_GENERIC_CONFIG_EVENT_EXPAND_WHOLE:
		{
			fwAlarmScreen_resizePanel();
			break;
		}
		case FWALARMSCREEN_GENERIC_CONFIG_EVENT_CONFIG_CHANGED:
		{
			fwAlarmScreen_reloadConfig();
			break;
		}
		default:
		{
			break;
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

/**
  @par Description:
  Copy the formatting of a table to another one. This includes the colours and the columns (name, header, size, visibility, ...).

  @par Usage:
  Public.

  @param  sTableSource  string input, The table to copy the parameters from.
  @param  sTableDest    string input, The table to copy the parameters to.
*/
void fwAlarmScreen_copyTableStyle(const string sTableSource, const string sTableDest)
{
	// Remove all columns and lines
	int iColumnCount;
	getValue(sTableDest, "columnCount", iColumnCount);
	for (int i = iColumnCount - 1  ; i >= 0 ; i--)
	{
		setValue(sTableDest, "deleteColumn", i);
	}

	setValue(sTableDest, "deleteAllLines");


	// Copy background colour
	string sBackGroundColor;
	getValue(sTableSource, "cellBackCol", sBackGroundColor);
	setValue(sTableDest, "cellBackCol", sBackGroundColor);

	// Copy grid colour
	string sGridColor;
	getValue(sTableSource, "gridColor", sGridColor);
	setValue(sTableDest, "gridColor", sGridColor);

	// Copy the font
	string sFont;
	getValue(sTableSource, "font", sFont);
	setValue(sTableDest, "font", sFont);

	getValue(sTableSource, "columnCount", iColumnCount);
	for (int i = 0 ; i < iColumnCount ; i++)
	{
		// Insert column
		setValue(sTableDest, "insertColumn", i);

		// Copy column name
		string sColumnName;
		getValue(sTableSource, "columnName", i, sColumnName);
		setValue(sTableDest, "columnName", i, sColumnName);

		// Copy column header
		string sColumnHeader;
		getValue(sTableSource, "namedColumnHeader", sColumnName, sColumnHeader);
		setValue(sTableDest, "namedColumnHeader", sColumnName, sColumnHeader);

		// Copy column visibility
		bool bColumnVisible;
		getValue(sTableSource, "namedColumnVisibility", sColumnName, bColumnVisible);
		setValue(sTableDest, "namedColumnVisibility", sColumnName, bColumnVisible);

		// Copy column width
		int iColumnWidth;
		getValue(sTableSource, "namedColumnWidth", sColumnName, iColumnWidth);
		setValue(sTableDest, "namedColumnWidth", sColumnName, iColumnWidth);

		// Copy column format
		string sColumnFormat;
		getValue(sTableSource, "columnFormat", sColumnName, sColumnFormat);
		setValue(sTableDest, "columnFormat", sColumnName, sColumnFormat);
	}

	// Copy row size
	int iRowHeight;
	getValue(sTableSource, "rowHeight", iRowHeight);
	setValue(sTableDest, "rowHeight", iRowHeight);
}

/**
  @par Description:
  Resize the main panel to properly show the footer. To be called on expanding event.

  @par Usage:
  Public.
*/
void fwAlarmScreen_resizePanel()
{
	int iOldX;
	int iOldY;
	int iNewX;
	int iLineX;
	int iLineY;
	int iPanelWidth;
	int iPanelHeight;

	getValue("lineBottomLimit", "position", iLineX, iLineY);
	panelSize("", iPanelWidth, iPanelHeight);

	// Move down the footer widgets
	if(shapeExists("unselectRow"))
	{
		getValue("unselectRow", "position", iOldX, iOldY);
		iNewX = iPanelWidth - 241;
		setValue("unselectRow", "position", iNewX, iLineY);
	}

	if(shapeExists("printButton"))
	{
		getValue("printButton", "position", iOldX, iOldY);
		iNewX = iPanelWidth - 131;
		setValue("printButton", "position", iNewX, iLineY);
	}

	if(shapeExists("closeButton"))
	{
		getValue("closeButton", "position", iOldX, iOldY);
		iNewX = iPanelWidth - 85;
		setValue("closeButton", "position", iNewX, iLineY);
	}
}

/**
  @par Description:
  Save the panel configuration. To be called from fwAlarmScreenOptions panel.

  @par Usage:
  Internal.
*/
void fwAlarmScreen_saveConfig()
{
	// This function can be triggered when filling the panel, we don't want that.
	// g_bInitialized is defined in the config panel scopelib, set to true at the end of the initialize function.
	if (!g_bInitialized)
	{
		return;
	}

	dyn_string dsExceptions;
	dyn_string dsColumnsName;
	dyn_string dsSaveColumnsName;
	dyn_string dsColumnsVisible;

	// Save column visibility
	bool bAlwaysShowCameTime = cameWentTimeSelection.text == "CAME timestamp";
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_DP_NAME,       columnVisibleOptions.state(0),  dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_LOGICAL_NAME,  columnVisibleOptions.state(1),  dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_DESCRIPTION,   columnVisibleOptions.state(2),  dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_ALERT_VALUE,   columnValueOptions.state(0),    dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_ONLINE_VALUE,  columnValueOptions.state(1),    dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_TIME_STANDARD, !bAlwaysShowCameTime,           dsExceptions, false);
	fwAlarmScreen_showHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_TIME_CAME,     bAlwaysShowCameTime,            dsExceptions, false);

	// Save summary mode
	int iSummaryMode;
	switch(summariesMode.number)
	{
		case 0:
		{
			iSummaryMode = AES_SUMALERTS_BOTH;
			break;
		}
		case 1:
		{
			iSummaryMode = AES_SUMALERTS_FILTERED;
			break;
		}
		case 2:
		{
			iSummaryMode = AES_SUMALERTS_NO;
			break;
		}
	}

	fwAlarmScreen_setDescriptionColumnBehaviour(showDpeInDescription.number, dsExceptions);
	fwAlarmScreen_setRowColourBehaviour(colourWholeRow.state(0), dsExceptions);
	fwAlarmScreen_setOnlineValueUpdateRate(onlineValueUpdateRate.text, dsExceptions);
	fwAlarmScreen_setDistSystemDisplayOption(showDistSystemDetails.state(0), dsExceptions);
	fwAlarmScreen_setReductionMode(fwAlarmScreen_PROPERTIES_DP, iSummaryMode, dsExceptions);
	fwAlarmScreen_setScrollLockTimeout(scrollLock.state(0) ? scrollLockValue.text : 0, dsExceptions);
	fwAlarmScreen_setHistoricalMaxLines(historicalMaxLineslValue.text, dsExceptions);


	// Save idle timer
	int iIdleTimer;
	if(idleTimeout.state(0))
	{
		iIdleTimer = idleTimeoutValue.text;
	}
	else
	{
		iIdleTimer = 0;
	}

	fwAlarmScreen_setIdleTimeout(iIdleTimer, dsExceptions);

	// Save default/idle filter
	string sDefaultFilter;
	if(savedFilterList.selectedPos == 1)
	{
		sDefaultFilter = "";
	}
	else
	{
		sDefaultFilter = savedFilterList.text;
	}
	fwAlarmScreen_setDefaultFilterName(sDefaultFilter, dsExceptions);

	// Save enable groups
	bool bEnableGroups = checkBoxShowGroups.state(0);
	fwAlarmScreen_setEnableGroups(bEnableGroups);
 
 // Save alarm filter 
	bool bEnableAlarmFilter = checkBoxShowAlarmFilter.state(0);
	fwAlarmScreen_setEnableAlarmFilter(bEnableAlarmFilter);

	// Save inter priorities
	bool bInvertPriorities = checkboxInvertPriorities.state(0);
	fwAlarmScreen_setInvertPriorities(bInvertPriorities);


	if(dynlen(dsExceptions) > 0)
	{
		fwExceptionHandling_display(dsExceptions);
	}
}

/**
  @par Description:
  Get the list of configuration panels to be show in the main configuration window.

  @par Usage:
  Internal.

  @return The list of configuration panels to be show in the main configuration window.
*/
dyn_string fwAlarmScreen_getConfigPanels()
{
	dyn_string dsPanels;

	// Check if the user has access to the configuration first.
	bool bAccessGranted;
	dyn_string dsAccessRights;
	dyn_string dsExceptions;

	if(isFunctionDefined("fwAccessControl_isGranted"))
	{
		fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

		if(dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY] != "")
		{
			fwAccessControl_isGranted(dsAccessRights[fwAlarmScreen_ACCESS_MANAGE_DISPLAY], bAccessGranted, dsExceptions);
		}
		else
		{
			bAccessGranted = true;
		}
	}
	else
	{
		bAccessGranted = true;
	}

	// If he doesn't, return empty list.
	if (bAccessGranted)
	{
		// Alarm panel setup
		string sPanel =
			"fwAlarmHandling/fwAlarmScreenOptions.pnl"        + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			"JCOP alarm settings"                           + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR
			;

		dynAppend(dsPanels, sPanel);

		// Access control setup
		sPanel =
			"fwAlarmHandling/fwAlarmScreenOptions_AccessControl.pnl"  + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			"Access control"                                  + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR
			;
		dynAppend(dsPanels, sPanel);


		// Alarm help file types
		sPanel =
			"fwAlarmHandling/fwAlarmScreenOptions_HelpFileSetup.pnl"  + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR +
			"Help file types"                         + FWALARMSCREEN_GENERIC_CONFIGURATION_PANEL_SEPARATOR
			;
		dynAppend(dsPanels, sPanel);
	}

	return dsPanels;
}

/**
  @par Description:
  Get the list of columns that can be shown/hidden.

  @par Usage:
  Internal.

  @return The list of columns that can be shown/hidden.
*/
dyn_string fwAlarmScreen_getShowableColumns()
{
	// Some columns are managed in JCOP options, they should never be changed by any other mean. They have been removed from this list.
	return makeDynString(
			   fwAlarmScreen_COLUMN_PRIORITY     ,
			   fwAlarmScreen_COLUMN_ALERT_TEXT   ,
			   fwAlarmScreen_COLUMN_DIRECTION    ,
			   fwAlarmScreen_COLUMN_ACKNOWLEDGE  ,
			   fwAlarmScreen_COLUMN_ACK_CAME     ,
			   fwAlarmScreen_COLUMN_COMMENT      ,
			   fwAlarmScreen_COLUMN_ALERT_PANEL  ,
			   fwAlarmScreen_COLUMN_DETAIL
		   );
}

/**
  @par Description:
  Reload the config after it has changed.
*/
void fwAlarmScreen_reloadConfig()
{
	dyn_string dsExceptions;
	string sAesProperties = aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false);


	// ---------------------------------------
	// ---------- Show/hide columns ----------
	// ---------------------------------------
	// When setting visibility to true, the column width sometimes stays at 0.
	// In that case, force it to fwAlarmScreen_COLUMN_DEFAULT_WIDTH.
	// Warning: set a column visible is not effective immediately, that is why a do{} while loop is used to wait.
	bool bVisible;
	int iWidth;

	// Device name
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_DP_NAME, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_DP_NAME, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_DP_NAME, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_DP_NAME, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_DP_NAME, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Logical name
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_LOGICAL_NAME, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_LOGICAL_NAME, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_LOGICAL_NAME, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_LOGICAL_NAME, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_LOGICAL_NAME, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Description
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_DESCRIPTION, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_DESCRIPTION, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_DESCRIPTION, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_DESCRIPTION, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_DESCRIPTION, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Alarm value
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_ALERT_VALUE, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_ALERT_VALUE, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_ALERT_VALUE, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_ALERT_VALUE, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_ALERT_VALUE, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Online value
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_ONLINE_VALUE, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_ONLINE_VALUE, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_ONLINE_VALUE, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_ONLINE_VALUE, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_ONLINE_VALUE, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Time standard
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_TIME_STANDARD, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_TIME_STANDARD, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_TIME_STANDARD, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_TIME_STANDARD, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_TIME_STANDARD, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// Time came
	fwAlarmScreen_getShowHideColumn(fwAlarmScreen_PROPERTIES_DP, fwAlarmScreen_COLUMN_TIME_CAME, bVisible, dsExceptions);
	setValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_TIME_CAME, bVisible);

	if (bVisible)
	{
		bool bVisibleTemp = false;
		do
		{
			getValue(AES_TABLENAME_TOP, "namedColumnVisibility", fwAlarmScreen_COLUMN_TIME_CAME, bVisibleTemp);
		}
		while (!bVisibleTemp);

		getValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_TIME_CAME, iWidth);

		if (0 == iWidth)
		{
			setValue(AES_TABLENAME_TOP, "namedColumnWidth", fwAlarmScreen_COLUMN_TIME_CAME, fwAlarmScreen_COLUMN_DEFAULT_WIDTH);
		}
	}

	// -----------------------------------------------
	//  ---------- Online update rate value ----------
	// -----------------------------------------------
	float iOnlineUpdateValue;
	fwAlarmScreen_getOnlineValueUpdateRate(iOnlineUpdateValue, dsExceptions);
	onlineUpdateRate.text(iOnlineUpdateValue);

	// ------------------------------------------------
	// ---------- Show remote system details ----------
	// ------------------------------------------------
	bool bDisplaySystems;
	fwAlarmScreen_getDistSystemDisplayOption(bDisplaySystems, dsExceptions);
	setValue(FW_ALARM_GENERIC_WIDGET_SYSTEM_STATE, "visible", bDisplaySystems);


	// ----------------------------------
	// ---------- Summary mode ----------
	// ----------------------------------
	int iSummaryMode;
	fwAlarmScreen_getReductionMode(fwAlarmScreen_PROPERTIES_DP, iSummaryMode, dsExceptions);
	int iCurrentSummaryMode;
	fwAlarmScreen_getReductionMode(sAesProperties, iCurrentSummaryMode, dsExceptions);
	if (iSummaryMode != iCurrentSummaryMode)
	{
		fwAlarmScreen_setReductionMode(sAesProperties, iSummaryMode, dsExceptions);
		aes_doRestart(sAesProperties, false);
	}

	// Idle time-out
	int iIdleTimeout;
	fwAlarmScreen_getIdleTimeout(iIdleTimeout, dsExceptions);
	idleTimeoutValue.text(iIdleTimeout);

	// ------------------------------
	// ---------- AES mode ----------
	// ------------------------------
	dyn_anytype daAesMode;
	fwAlarmScreen_readMode(daAesMode, dsExceptions);
	fwAlarmScreen_applyMode(sAesProperties, daAesMode, dsExceptions, inClosedMode.state(0));
}

/**
  @par Description:
  Function called when closing the panel.

  @par Usage:
  Internal.
*/
void fwAlarmScreen_closePanel()
{
	aes_doStop(aes_getPropDpName(AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, false, false));
	PanelOff();
}



// ---------------------------------------
// -- Functions for header manipulation --
// ---------------------------------------

int fwAlarmScreen_getHeaderHeight()
{
	return FWALARMSCREEN_HEADER_HEIGHT;
}

dyn_string fwAlarmScreen_getHeaderWidgets()
{
	return makeDynString(
			   "fwAlarmHeaderFrame2",
			   "fwAlarmHeaderText3",
			   "fwAlarmHeaderText4",
			   "fwAlarmHeaderText5",
			   "fwAlarmHeaderText6",
			   "fwAlarmHeaderText7",
			   "fwAlarmHeaderText8",
			   "fwAlarmHeaderFrame3",

			   "pushButtonChangeDateFrom",
			   "pushButtonNowFrom",
			   "textFieldTimeFrom",
			   "textTimeFrom",
			   "pushButtonChangeDateTo",
			   "pushButtonNowTo",
			   "textFieldTimeTo",
			   "textTimeTo",
			   "acNotAvailable",
			   "currentUserAC" // Warning: added manually when initialized if fwAccessControl installed
		   );
}

void fwAlarmScreen_showHeader(bool bShow)
{
	dyn_string dsWidgets = fwAlarmScreen_getHeaderWidgets();
	for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	{
		if (shapeExists(dsWidgets[i]))
		{
			setValue(dsWidgets[i], "visible", bShow);
		}
	}


	// Hide rectangle if access control available
	dyn_string dsAccessControlWidgets = dynPatternMatch("currentUser.*", getShapes(myModuleName(), myPanelName(), ""));
	if (dynlen(dsAccessControlWidgets) > 0)
	{
		setValue("acNotAvailable", "visible", false);
	}
}



// ---------------------------------------
// -- Functions for info manipulation --
// ---------------------------------------

int fwAlarmScreen_getInfoHeight()
{
	return FWALARMSCREEN_INFO_HEIGHT;
}

dyn_string fwAlarmScreen_getInfoWidgets()
{
	return makeDynString(
		   );
}

void fwAlarmScreen_showInfo(bool bShow)
{
	// dyn_string dsWidgets = fwAlarmScreen_getInfoWidgets();
	// for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	// {
	// if (shapeExists(dsWidgets[i]))
	// {
	// setValue(dsWidgets[i], "visible", bShow);
	// }
	// }
}

void fwAlarmScreen_moveInfo(int iYDiff)
{
	// dyn_string dsWidgets = fwAlarmScreen_getInfoWidgets();
	// for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	// {
	// if (shapeExists(dsWidgets[i]))
	// {
	// int iOldX;
	// int iOldY;
	// getValue(dsWidgets[i], "position", iOldX, iOldY);

	// int iNewY = iOldY + iYDiff;
	// setValue(dsWidgets[i], "position", iOldX, iNewY);
	// }
	// }
}



// ---------------------------------------------
// -- Functions for table filter manipulation --
// ---------------------------------------------

int fwAlarmScreen_getTableFilterHeight()
{
	if (!fwAlarmScreen_getEnableGroups())
	{
		return fwAlarmScreen_groups_GROUPS_DISABLED_HEIGHT;
	}
	else
	{
		// Need to count how many lines have to be displayed
		const string sGroupPanel = "fwAlarmHandling/fwAlarmScreenGroupWidget.pnl";
		dyn_int diGroupSize = getPanelSize(sGroupPanel);

		return FWALARMSCREEN_TABLEFILTER_HEIGHT + ((diGroupSize[2] + 3) * (fwAlarmScreen_groups_countLines() - 1));
	}
}

dyn_string fwAlarmScreen_getTableFilterWidgets()
{
	return makeDynString(
			   "pushButtonGroupsSetup",
			   "templateGroupButton",
			   "templateGroupText",
			   "pushButtonClearGroupAlarms",
			   "textSelectedGroup"
		   );
}

void fwAlarmScreen_showTableFilter(bool bShow)
{
	dyn_string dsWidgets = fwAlarmScreen_getTableFilterWidgets();

	dynAppend(dsWidgets, dynPatternMatch("*.SUB", getShapes(myModuleName(), myPanelName(), "")));
	dynAppend(dsWidgets, dynPatternMatch("*.INFO", getShapes(myModuleName(), myPanelName(), "")));

	for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	{
		if (shapeExists(dsWidgets[i])
				&& ("pushButtonClearGroupAlarms" != dsWidgets[i])
				&& ("textSelectedGroup" != dsWidgets[i]))
		{
			setValue(dsWidgets[i], "visible", bShow);
		}
	}

	setMultiValue(
		"templateGroupButton", "visible", false,
		"templateGroupText", "visible", false
	);

	bool bTableVisible;
	getValue(fwAlarmScreen_GROUP_ALARM_TABLE, "visible", bTableVisible);
	setValue("pushButtonClearGroupAlarms", "visible", bTableVisible && bShow);
	if (!bShow)
	{
		setValue(fwAlarmScreen_groups_GROUPS_DISABLED_WIDGET, "visible", false);
	}
	else
	{
		bool bGroupsEnabled = fwAlarmScreen_getEnableGroups();
		if(bTableVisible) {
		  setValue(fwAlarmScreen_groups_GROUPS_DISABLED_WIDGET, "visible", !bGroupsEnabled);
		}
		setValue("pushButtonGroupsSetup", "visible", bGroupsEnabled);
	}
}

void fwAlarmScreen_moveTableFilter(int iYDiff)
{
	dyn_string dsWidgets = fwAlarmScreen_getTableFilterWidgets();

	dynAppend(dsWidgets, dynPatternMatch("*.SUB", getShapes(myModuleName(), myPanelName(), "")));
	dynAppend(dsWidgets, dynPatternMatch("*.INFO", getShapes(myModuleName(), myPanelName(), "")));
	dynAppend(dsWidgets, fwAlarmScreen_groups_GROUPS_DISABLED_WIDGET);

	for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	{
		if (shapeExists(dsWidgets[i]))
		{
			int iOldX;
			int iOldY;
			getValue(dsWidgets[i], "position", iOldX, iOldY);

			int iNewY = iOldY + iYDiff;
			setValue(dsWidgets[i], "position", iOldX, iNewY);
		}
	}
}

// ---------------------------------------------
// -- Functions for alarm filter manipulation --
// ---------------------------------------------

int fwAlarmScreen_getAlertFilterHeight()
{
	return FWALARMSCREEN_ALERTFILTER_HEIGHT;
}


dyn_string fwAlarmScreen_getAlertFilterWidgets()
{
	return makeDynString(
			   "fwAlarmScreenAlarmFilterText1",
			   "fwAlarmScreenAlarmFilterText2",
			   "fwAlarmScreenAlarmFilterText3",
			   "fwAlarmScreenAlarmFilterText4",
			   "fwAlarmScreenAlarmFilterText5",
			   "fwAlarmScreenAlarmFilterText6",
			   "fwAlarmScreenAlarmFilterText7",
			   "fwAlarmScreenAlarmFilterText8",
			   "fwAlarmScreenAlarmFilterText9",

			   "quickFilterList",
			   "pushButtonApplyFilter",
			   "clearFilter",

			   "deviceSystemTable",
			   "deviceName",
			   "deviceAlias",
			   "alarmText",
			   "showLocalOrGlobal",
			   "deviceType",
			   "deviceDescription",
			   "alarmState",
			   "showWarnings",
			   "showErrors",
			   "showFatals",

			   "openConfig",
			   "saveConfig",
			   "deleteConfig",

			   "aesModeSelector",
			   "dateTimeWidgetPlaceholder",
			   "dateTimeWidgetPlaceholderText"
         ,
			   FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".selectedTimeZone",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startNowButton",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endNowButton",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startDateChooserButton",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endDateChooserButton",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startTimeSpin",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startTimeLabel",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endTimeLabel",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startTimeField",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".startDateField",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endDateField",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endTimeSpin",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".endTimeField",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".dateTimeSeparator",
         FWALARMSCREEN_DATETIMEPICKER_PANELNAME+".timeZoneLabel"
		   );
}

void fwAlarmScreen_showAlertFilter(bool bShow)
{
	dyn_string dsWidgets = fwAlarmScreen_getAlertFilterWidgets();
	for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	{
		if (shapeExists(dsWidgets[i])
				&& (strpos(dsWidgets[i], FWALARMSCREEN_DATETIMEPICKER_PANELNAME) < 0)
				&& (strpos(dsWidgets[i], "dateTimeWidget") < 0))
		{
			setValue(dsWidgets[i], "visible", bShow);
		}
	}

	// Protection needed because of initialization order.
	if (shapeExists(FWALARMSCREEN_DATETIMEPICKER_PANELNAME+"."+FWALARMSCREEN_DATETIMEPICKER_WIDGETNAME1)) //check if any of the shape in DateTimePicker exists
	{
		fwGeneral_dateTimeWidget_setVisible(bShow);
	}
}

void fwAlarmScreen_moveAlertFilter(int iYDiff)
{
	dyn_string dsWidgets = fwAlarmScreen_getAlertFilterWidgets();
	for (int i = 1 ; i <= dynlen(dsWidgets) ; i++)
	{
		if (shapeExists(dsWidgets[i]))
		{
			int iOldX;
			int iOldY;
			getValue(dsWidgets[i], "position", iOldX, iOldY);

			int iNewY = iOldY + iYDiff;
			setValue(dsWidgets[i], "position", iOldX, iNewY);
		}
	}
}




// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------- OTHER FUNCTIONS ------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------


void fwAlarmScreen_invokedAESUserFunc(string sShapeName, int iScreenType, int iTabType, int iRow, int iColumn, string sValue, mapping mTableRow)
{
	bool isGranted;

	dyn_string dsAccessRights;
	dyn_string dsExceptions;

	fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

	string sColumnName;
  //get the columnName. Watch out the -1 as the table column starts at 0 and not 1
  getValue(sShapeName, "columnName", iColumn-1, sColumnName); 
  
  if(sColumnName == fwAlarmScreen_COLUMN_COMMENT)
	{
		isGranted = true;
		if(isFunctionDefined("fwAccessControl_isGranted"))
		{
			if(dsAccessRights[fwAlarmScreen_ACCESS_COMMENT] != "")
			{
				fwAccessControl_isGranted(dsAccessRights[fwAlarmScreen_ACCESS_COMMENT], isGranted, dsExceptions);
			}
			else
			{
				isGranted = true;
			}
		}
		if(!isGranted)
		{
			fwException_raise(dsExceptions, "ERROR", "You do not have sufficient rights to comment this alarm", "");
			fwExceptionHandling_display(dsExceptions);
			return;
		}

		aes_insertComment(iRow, mTableRow);
	}
	else if(sColumnName == fwAlarmScreen_COLUMN_ACKNOWLEDGE)
	{
		isGranted = true;
		if(isFunctionDefined("fwAccessControl_isGranted"))
		{
			if(dsAccessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE] != "")
			{
				fwAccessControl_isGranted(dsAccessRights[fwAlarmScreen_ACCESS_ACKNOWLEDGE], isGranted, dsExceptions);
			}
			else
			{
				isGranted = true;
			}
		}

		if(!isGranted)
		{
			fwException_raise(dsExceptions, "ERROR", "You do not have sufficient rights to acknowledge this alarm", "");
			fwExceptionHandling_display(dsExceptions);
			return;
		}

		string sPropertiesDp;
		string sDpId;

		bool bAckable;
		bool bAckOldest;


		unsigned uPropertiesMode;
		unsigned uRunMode;

		// Get the panelglobal propDpNames ( for top/bot ) because we have no scope to g_propDp there
		aes_getTBPropDpName(iTabType, sPropertiesDp);
		aes_getPropMode(sPropertiesDp, uPropertiesMode);

		aes_getRunMode(sPropertiesDp, uRunMode);

		bAckable    =  this.cellValueRC(iRow, _ACKABLE_);
		bAckOldest  =  this.cellValueRC(iRow, _ACK_OLD_);

		if(uPropertiesMode == AES_MODE_CLOSED && bAckable)
		{
			aec_warningDialog(AEC_WARNINGID_ACKNOTPOSSIBLE);
			return;
		}

		if(aes_getDpidFromTable(iRow, sDpId, mTableRow) != 0)
		{
			return;
		}

		if(uRunMode != AES_RUNMODE_RUNNING)
		{
			aec_warningDialog(AEC_WARNINGID_ACKNOTPOSINSTOP);
			return;
		}

		// Call single acknowledge with row information
		if(bAckable && bAckOldest)
		{
			mapping mTableMultipleRows;

			// Change format of mapping because ack supports multiple rows
			mTableMultipleRows[iRow] = mTableRow;
			aes_changedAcknowledgeWithRowData(AES_CHANGED_ACKSINGLE, iTabType, mTableMultipleRows);
		}
		else if(bAckable && !bAckOldest)
		{
			aec_warningDialog(AEC_WARNINGID_NOTTHEOLDESTALERT);
		}
	}
}



/** Opens a JCOP Alarm Screen with the specified group selected

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI


@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param sGroupName		input, the name of the group to be selected once the alarm screen is open
@param exceptionInfo		Details of any exceptions are returned here
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
*/
fwAlarmScreen_openScreenWithGroup(bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, string sGroupName, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0)
{
	dyn_string dsDollarParams = makeDynString("$sGroupName:"+sGroupName);
	fwAlarmScreen_openScreen( bAsNewModule, bStayOnTopOrModal, sModuleName, sPanelName, dsDollarParams,exceptionInfo, x, y);
}

/** Opens a JCOP Alarm Screen with dollar parameters
 

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI


@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param exceptionInfo		Details of any exceptions are returned here
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
*/
fwAlarmScreen_openScreen(bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, dyn_string dollarParams, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0)
{
	string sPanelFileName = fwAlarmScreen_PANEL_NAME;

	if(bAsNewModule)
	{
		ModuleOnWithPanel(sModuleName,
						  x, y, 0, 0, 0, 0, "",
						  sPanelFileName,
						  sPanelName,
						  dollarParams);

		stayOnTop(bStayOnTopOrModal, sModuleName);
	}
	else
	{
		if(!bStayOnTopOrModal)
		{
			ChildPanelOn(sPanelFileName,
						 sPanelName,
						 dollarParams,
						 x, y);
		}
		else
		{
			ChildPanelOnModal(sPanelFileName,
							  sPanelName,
							  dollarParams,
							  x, y);
		}
	}
	
	
}


/**
  @par Description:
  Initialize the alarm filter part of the alarm screen.

  @par Usage:
  Public.
*/
void fwAlarmScreen_alarmFilter_init()
{
	while( fwAlarmScreenGeneric_screenReady() == false) delay(0,500);
 
   
 
 //if the alarm filter should not be shown, we hide it now as by default it is displayed
 //we make sure that we can not have the groups and alarm filter disabled
	if (fwAlarmScreen_getEnableAlarmFilter() == false && fwAlarmScreen_getEnableGroups() == true)
	{  
   frameAlertFilter.visible(false);
 		isExpandedCheckbox.state(FW_ALARM_GENERIC_ALARMFILTER_EXPANDED_INDEX, FALSE);
		 setValue("frameAlertFilterTitle", "visible", FALSE);
		 setValue("frameAlertFilterReduced", "visible", FALSE);
		 setValue("frameAlertFilterExpanded", "visible", FALSE);
		 setValue("frameAlertFilterHighlight", "visible", FALSE);
   fwAlarmScreen_showAlertFilter( false);
 } else
 {
   fwAlarmScreen_setEnableAlarmFilter(true);
 }
}

