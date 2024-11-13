/**
  @file fwAlarmScreen.ctl

  @par Description:
  This library contains all the functions used by the groups in the JCOP alarm panel.
  Lot of this code has been adapted from the former JCOP panel dedicated to groups only. It has been fully included to the normal JCOP alarm panel.

  @par Creation Date:
	08/02/2013

  @par Modification history:

  @author
	Cyril Caillaba (EN-ICE-SCD)
*/

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// -------------------------------- CONSTANTS------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

// -----------------------------
// ---- Alarm group content ----
// -----------------------------
const int       fwAlarmScreen_groups_GROUP_INDEX_DPE          = 1;                                      // Group datapoint - string.
const int       fwAlarmScreen_groups_GROUP_INDEX_ID           = 2;                                      // Group title - string.
const int       fwAlarmScreen_groups_GROUP_INDEX_DESCR        = 3;                                      // Group description - string.
const int       fwAlarmScreen_groups_GROUP_INDEX_SYSTEMS      = 4;                                      // Group systems - mapping - key = system name, values = dyn_dyn_strings.
const int       fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES  = 1;                                      // Group alias list for one system - dyn_string.
const int       fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES     = 2;                                      // Group DPE list for one system - dyn_string.
const int       fwAlarmScreen_groups_GROUP_INDEX_SUBMAP       = 5;                                      // Remain from old code, maybe someone knows exactly what is inside... - dyn_anytype.
const unsigned  fwAlarmScreen_groups_AlertNumber              = 1;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_UnAckNumber              = 2;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_LastAlert                = 3;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_Severity                 = 4;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_Blinking                 = 5;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_Colour                   = 6;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_Ack                      = 7;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_Direction                = 8;                                      // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const unsigned  fwAlarmScreen_groups_COLOUR_INDEX             = 99;                                     // Part of submap. Remain from old code, maybe someone knows exactly what is inside...
const int       fwAlarmScreen_groups_GROUP_INDEX_ALARMS       = 6;                                      // Group alarms to display - dyn_dyn_anytype.


// -----------------------------
// ----- Groups parameters -----
// -----------------------------
const string    fwAlarmScreen_groups_SETUP_DPTYPE             = "_FwAesGroupsSetup";                    // Groups panel settings DP type.
const string    fwAlarmScreen_groups_SETUP_DP                 = "_fwAesGroupsSetup";                    // Groups panel settings DP.
const string    fwAlarmScreen_groups_ORDER_DP                 = "_fwAesGroupsSetup.groups";             // Group list ordered customly.
const string    fwAlarmScreen_groups_ORDERMODE_DP             = "_fwAesGroupsSetup.customOrder";        // Whether or not use a custom oder (default: alphabetical order).
const string    fwAlarmScreen_groups_SOUNDENABLED_DP          = "_fwAesGroupsSetup.sound.enabled";      // Whether or not use a sound when a new alarm appears.
const string    fwAlarmScreen_groups_SOUNDSOURCE_DP           = "_fwAesGroupsSetup.sound.playSource";   // Source to play a sound from, beep or file.
const int       fwAlarmScreen_groups_SOUNDSOURCE_PCSPEAKER    = 0;                                      // Play a beep.
const int       fwAlarmScreen_groups_SOUNDSOURCE_FILE         = 1;                                      // Play a file.
const string    fwAlarmScreen_groups_SOUNDFILE_DP             = "_fwAesGroupsSetup.sound.fileName";     // File to play a sound from.
const string    fwAlarmScreen_groups_SOUNDINHIBIT_DP          = "_fwAesGroupsSetup.sound.inhibitSec";   // Time to wait before playing another sound.
const string    fwAlarmScreen_groups_ALARM_SHOW_MODE_DP       = "_fwAesGroupsSetup.showMode";           // Indicates whether to show an alarm in all groups or only the first one.
const int       fwAlarmScreen_groups_ALARM_SHOW_MODE_FIRST    = 0;                                      // Show in the first group
const int       fwAlarmScreen_groups_ALARM_SHOW_MODE_ALL      = 1;                                      // Show in all groups

// -------------------------------
// ------- Group datapoint -------
// -------------------------------
const string    fwAlarmScreen_groups_CONFIG_DPTYPE            = "_FwAesGroupsConfig";                   // Group parameters DP type.
const string    fwAlarmScreen_groups_CONFIG_DP                = "_fwAesGroupsConfig_";                  // Group parameters DP.

// --------------------------------
// ------------ Labels ------------
// --------------------------------
const string    fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY     = "Show group in current alarm screen";                       // Group button text to show group alarms.
const string 	fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY_NEW = "Show group in a new alarm screen";                       // Group button text to show group alarms in new screen.
const string    fwAlarmScreen_groups_BUTTON_LABEL_HIDE        = "Unselect group filter";                          // Group button text to clear group alarms.
const string    fwAlarmScreen_groups_GROUP_SELECTED_LABEL     = "----- ACTIVE ----";                    // Text to put in the active group field once the alarms of one group are shown.
const string    fwAlarmScreen_groups_ROW_BREAK_LABEL          = "------ROW_BREAK-----";                 // Text to display in the group edition window to represent a row break

// --------------------------------
// --------- UI constants ---------
// --------------------------------
const string    fwAlarmScreen_groups_GROUPS_DISABLED_WIDGET   = "fwAlarmScreen_groups_groupsDisabled";  // Text indicating that groups are disabled.
const int       fwAlarmScreen_groups_GROUPS_DISABLED_HEIGHT   = 70;
const string    fwAlarmScreen_groups_GROUP_ACTIVE_LABEL       = "Displayed group: %s";




/**
  @par Description:
  Initialize the group part of the alarm screen.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_init()
{
	while( fwAlarmScreenGeneric_screenReady() == false) delay(0,500);
	if (fwAlarmScreen_groups_show())
	{
		fwAlarmScreen_groups_startLoop();
	}
}

/**
  @par Description:
  Count how many lines will be necessary to show all the groups buttons with the current size of the panel.

  @par Usage:
  Public.
*/
int fwAlarmScreen_groups_countLines()
{
	dyn_dyn_anytype ddaAllGroups = fwAlarmScreen_groups_getAll();

	// Position to start adding groups from.
	int iXOrig;
	int iYOrig;
	const string sTemplatePanel = "templateGroupButton";
	if (!shapeExists(sTemplatePanel))
	{
		return 1;
	}
	getValue(sTemplatePanel, "position", iXOrig, iYOrig);

	// Size of the panel to add.
	const string sGroupPanel = "fwAlarmHandling/fwAlarmScreenGroupWidget.pnl";
	dyn_int diGroupSize = getPanelSize(sGroupPanel);


	const string fwAlarmScreen_groups_GROUPS_FRAME = "frameTableFilter";

	// Max X position before switching to new line:
	// The frame fwAlarmScreen_groups_GROUPS_FRAME marks the limit. Its size is not fixed, it can be extended or reduced.
	int iFrameX;
	int iFrameY;
	getValue(fwAlarmScreen_groups_GROUPS_FRAME, "position", iFrameX, iFrameY);

	int iFrameWidth;
	int iFrameHeight;
	getValue(fwAlarmScreen_groups_GROUPS_FRAME, "size", iFrameWidth, iFrameHeight);

	const int iMaxX = iFrameX + iFrameWidth - diGroupSize[1] - 5; // -5 to leave a bit of space.


	// Count how many lines are used to rearrange the layout.
	int iLines = 1;


	// Position to add the next group.
	int iCurrentX = iXOrig;
	int iCurrentY = iYOrig;
	for (int i = 1 ; i <= dynlen(ddaAllGroups) ; i++)
	{

		dyn_anytype daGroup = ddaAllGroups[i];

		if (fwAlarmScreen_groups_ROW_BREAK_LABEL == daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]) // Row break?
		{
			iCurrentX = iXOrig;
			iCurrentY += diGroupSize[2];
			if (i != dynlen(ddaAllGroups)) // Don't count a new line if it is the last group
			{
				iLines++;
			}
		}
		else
		{
			iCurrentX += diGroupSize[1];
			if (iCurrentX > iMaxX)
			{
				iCurrentX = iXOrig;
				iCurrentY += diGroupSize[2];
				if (i != dynlen(ddaAllGroups)) // Don't count a new line if it is the last group
				{
					iLines++;
				}
			}
		}


	}

	return iLines;
}

/**
  @par Description:
  Show all the alarm group buttons.

  @par Usage:
  Public.

  @return True if the groups are shown, false otherwise.
*/
bool fwAlarmScreen_groups_show()
{
	bool bGroupsEnabled = fwAlarmScreen_getEnableGroups();

	const string fwAlarmScreen_groups_GROUPS_FRAME = "frameTableFilter";
	int iFrameWidth;
	int iFrameHeight;
	getValue(fwAlarmScreen_groups_GROUPS_FRAME, "size", iFrameWidth, iFrameHeight);

	if (bGroupsEnabled)
	{
		dyn_dyn_anytype ddaAllGroups = fwAlarmScreen_groups_getAll();
		int iNewFrameHeight;

		// Position to start adding groups from.
		int iXOrig;
		int iYOrig;
		const string sTemplatePanel = "templateGroupButton";
		getValue(sTemplatePanel, "position", iXOrig, iYOrig);

		// Size of the panel to add.
		const string sGroupPanel = "fwAlarmHandling/fwAlarmScreenGroupWidget.pnl";
		dyn_int diGroupSize = getPanelSize(sGroupPanel);



		// Max X position before switching to new line:
		// The frame fwAlarmScreen_groups_GROUPS_FRAME marks the limit. Its size is not fixed, it can be extended or reduced.
		int iFrameX;
		int iFrameY;
		getValue(fwAlarmScreen_groups_GROUPS_FRAME, "position", iFrameX, iFrameY);

		const int iMaxX = iFrameX + iFrameWidth - diGroupSize[1] - 8; // 8px space to the right border


		// Count how many lines are used to rearrange the layout.
		int iLines = 1;


		// Position to add the next group.
		int iCurrentX = iXOrig;
		int iCurrentY = iYOrig;
		for (int i = 1 ; i <= dynlen(ddaAllGroups) ; i++)
		{
			dyn_anytype daGroup = ddaAllGroups[i];

			if (fwAlarmScreen_groups_ROW_BREAK_LABEL == daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]) // Row break?
			{
				iCurrentX = iXOrig;
				iCurrentY = iCurrentY + diGroupSize[2] + 3;
				if (i != dynlen(ddaAllGroups))
				{
					iLines++;
				}
			}
			else
			{
				addSymbol(
					myModuleName(),
					myPanelName(),
					sGroupPanel,
					daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID],
					makeDynString(
						"$name:" + daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID],
						"$pos:" + i,
						"$xzoom:" + diGroupSize[1],
						"$description:" + daGroup[fwAlarmScreen_groups_GROUP_INDEX_DESCR]
					),
					iCurrentX,
					iCurrentY,
					0,
					0,
					0
				);

				iCurrentX += diGroupSize[1];
			}

			if (iCurrentX > iMaxX)
			{
				iCurrentX = iXOrig;
				iCurrentY = iCurrentY + diGroupSize[2] + 3;
				if (i != dynlen(ddaAllGroups))
				{
					iLines++;
				}
			}
		}

		setValue(fwAlarmScreen_groups_GROUPS_DISABLED_WIDGET, "visible", false);
		setValue("pushButtonGroupsSetup", "visible", true);

		setValue(fwAlarmScreen_groups_GROUPS_FRAME, "size", iFrameWidth, fwAlarmScreen_getTableFilterHeight());
	}
	else
	{
		setValue("pushButtonGroupsSetup", "visible", false);
		fwAlarmScreenGeneric_showTableFilter(false);
	}

	_fwAlarmScreenGeneric_rearrangeScreen();

	return bGroupsEnabled;
}

/**
  @par Description:
  Remove all the alarm group buttons.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_remove()
{
	dyn_dyn_anytype ddaAllGroups = fwAlarmScreen_groups_getAll();

	for (int i = 1 ; i <= dynlen(ddaAllGroups) ; i++)
	{
		dyn_anytype daGroup = ddaAllGroups[i];
		if (shapeExists(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]))
		{
			removeSymbol(myModuleName(), myPanelName(), daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]);
		}
	}
}

/**
  @par Description:
  Start the loop that will check the groups for new alarms.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_startLoop()
{
	startThread("_fwAlarmScreen_groups_loop");
}

/**
  @par Description:
  Infinite loop that checks for new alarms every 2 seconds.

  @par Usage:
  Internal.
*/
void _fwAlarmScreen_groups_loop()
{
	dyn_dyn_anytype ddaAlarmTableRows;
	dyn_string dsAlarmColour;
	dyn_int diColumnIndexes;
	dyn_string dsExceptions;
	int iPlaySound;

	bool bSoundEnabled;
	int iSoundType;
	int iSoundInhibit;
	time tLastSoundPlayed;
	string sSoundPath;
	bool bShowAlarmsInAllGroups;

	if(dpExists(fwAlarmScreen_groups_SOUNDENABLED_DP))
	{
		dpGet(fwAlarmScreen_groups_SOUNDENABLED_DP, bSoundEnabled);

		if(bSoundEnabled)
		{
			dpGet(fwAlarmScreen_groups_SOUNDINHIBIT_DP, iSoundInhibit);
			dpGet(fwAlarmScreen_groups_SOUNDSOURCE_DP, iSoundType);

			if(iSoundType == fwAlarmScreen_groups_SOUNDSOURCE_FILE) // File
			{
				dpGet(fwAlarmScreen_groups_SOUNDFILE_DP, sSoundPath);

				if(!isfile(sSoundPath))
				{
					sSoundPath = fwAlarmScreen_groups_getDefaultSoundPath();
				}

				if(!isfile(sSoundPath))
				{
					iSoundType = fwAlarmScreen_groups_SOUNDSOURCE_FILE; // Wav file not found -> use beep
				}
			}
		}
	}
	else
	{
		bSoundEnabled = false;
	}

	if (dpExists(fwAlarmScreen_groups_ALARM_SHOW_MODE_DP))
	{
		int iShowMode;
		dpGet(fwAlarmScreen_groups_ALARM_SHOW_MODE_DP, iShowMode);
		if (fwAlarmScreen_groups_ALARM_SHOW_MODE_FIRST == iShowMode)
		{
			bShowAlarmsInAllGroups = false;
		}
		else
		{
			bShowAlarmsInAllGroups = true;
		}
	}
	else
	{
		bShowAlarmsInAllGroups = false;
	}

	int iAlarmCount;

	do
	{
		_fwAlarmScreen_groups_getTablerows(ddaAlarmTableRows, dsAlarmColour);
		iAlarmCount = dynlen(ddaAlarmTableRows);

		delay(0, 100);
	}
	while (!dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_SHORT_SIGN));



	diColumnIndexes[1]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_SHORT_SIGN    ); // Severity
	diColumnIndexes[2]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_SYSTEM_NAME   ); // System
	diColumnIndexes[3]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_TIME_STANDARD ); // Time
	diColumnIndexes[4]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_ACKABLE       ); // Ackable
	diColumnIndexes[5]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_DIRECTION     ); // Direction
	diColumnIndexes[6]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_DP_NAME       ); // Datapoint
	diColumnIndexes[7]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_COMMENT       ); // Number of comments
	diColumnIndexes[8]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_LOGICAL_NAME  ); // Alias
	diColumnIndexes[9]  = dynContains(ddaAlarmTableRows[iAlarmCount], fwAlarmScreen_COLUMN_PRIORITY      ); // Priority
	diColumnIndexes[10] = fwAlarmScreen_groups_COLOUR_INDEX;                                                // Background colour. It is not a standard column, but needed for the groups colour

	int iPlaySound = iAlarmCount;

	dyn_dyn_anytype ddaAllGroups = fwAlarmScreen_groups_getAll();

	string sPreviousSelectedGroup = ""; //use to check if the selected group has changed between two iterations to see if the table needs to be udpated
	dyn_anytype daGroupPrevious; //use to check if the group currently shown has different alarms to see it needs to be updated

	bool bNeverStop = true; //work around for the eclipse plugin to not put the whole while loop in warning
	while(bNeverStop)
	{
		if (0 == dynlen(ddaAllGroups))
		{
			delay(2); // Every two sec
			ddaAllGroups = fwAlarmScreen_groups_getAll();
		}

		for(int i = 1 ; i < dynlen(ddaAlarmTableRows) ; i++)
		{
			if(diColumnIndexes[2] > 0)
			{
				_fwAlarmScreen_groups_updateMap(ddaAllGroups, ddaAlarmTableRows[i], diColumnIndexes, bShowAlarmsInAllGroups);
			}
		}

		// ------------------------------------
		// ------------ Show group alarms
		// ------------------------------------
		bool bSelectedGroupExists = false;
		for (int i = 1 ; i <= dynlen(ddaAllGroups) ; i++)
		{
			dyn_anytype daGroup = ddaAllGroups[i];


			if (fwAlarmScreen_groups_ROW_BREAK_LABEL == daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID])
			{
				continue;
			}
			string sShapeSub = daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".SUB";
			string sShapeInfo = daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".INFO";


			// If this group is selected, display its alarms if it is the first time the group is selected or if its alarms have changed
			if (daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] == textFieldSelectedGroup.text())
			{
				bSelectedGroupExists = true;
				if (textFieldSelectedGroup.text() != sPreviousSelectedGroup || daGroup != daGroupPrevious)
				{
					fwAlarmScreen_groups_showGroupAlarms(daGroup);
					string sActiveGroupLabel;
					sprintf(sActiveGroupLabel, fwAlarmScreen_groups_GROUP_ACTIVE_LABEL, daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]);
					fwAlarmScreenGeneric_setActiveGroup(sActiveGroupLabel);
					sPreviousSelectedGroup = textFieldSelectedGroup.text();
					daGroupPrevious = daGroup;
				} 
				
			} 

			// If this group has to be acked
			if (daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] == textFieldGroupAck.text())
			{
				fwAlarmScreen_groups_acknowledgeGroupAlarms(daGroup);
			}


			if (shapeExists(sShapeSub) && shapeExists(sShapeInfo))
			{

				// Set button color according to alarm
				string sColor;
				if
				(
					(dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP]) >= fwAlarmScreen_groups_AlertNumber) &&
					(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_AlertNumber] > 0)
				)
				{
					sColor = daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Colour];
				}
				else
				{
					sColor = "FwStateOKPhysics";
				}

				setValue(sShapeSub, "backCol", sColor);

				// Display button summary
				if (dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP]) > 2)
				{
					string sGroupText = (string) daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_AlertNumber] + " alerts\n";

					if(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_AlertNumber] > 0)
					{
						sGroupText += (string) daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_UnAckNumber] + " unack; ";

						if(dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP]) >= 5)
						{
							sGroupText = sGroupText + "" + (string) daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Blinking] + " new\n";
						}
						else
						{
							sGroupText = sGroupText + "0 new\n";
						}

						if(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_AlertNumber] > 0)
						{
							string sTimeStamp = daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_LastAlert];

							if(strpos(sTimeStamp, ".", strlen(sTimeStamp) - 4))
							{
								sTimeStamp = substr(sTimeStamp, 0, strpos(sTimeStamp, ".", strlen(sTimeStamp) - 4));
							}

							sGroupText += sTimeStamp;
						}
					}


					setValue(sShapeInfo, "text", sGroupText);

					setValue(sShapeSub, "enableItemId", 1, true);
					setValue(sShapeSub, "enableItemId", 2, true);
				}
				else
				{
					setValue(sShapeInfo, "text", "0 alerts\n0 unack; 0 new");

					setValue(sShapeSub, "enableItemId", 1, false);
					setValue(sShapeSub, "enableItemId", 2, false);
				}
			}



		}

		//if no group is selected, we clear the group and reset the guard variable for the group update
		if (!bSelectedGroupExists )
		{
			fwAlarmScreen_groups_clearGroupAlarms();
			sPreviousSelectedGroup = "";
			daGroupPrevious = makeDynAnytype();
		} 

		delay(2); // Every two sec

		ddaAllGroups = fwAlarmScreen_groups_getAll();
		_fwAlarmScreen_groups_getTablerows(ddaAlarmTableRows, dsAlarmColour);

		// New alarm? Play a sound if necessary.
		if((dynlen(ddaAlarmTableRows) > iPlaySound) && bSoundEnabled)
		{
			if((getCurrentTime() - tLastSoundPlayed) > iSoundInhibit)
			{
				if (fwAlarmScreen_groups_SOUNDSOURCE_FILE == iSoundType)
				{
					startSound(sSoundPath);
				}
				else
				{
					beep(250, 250);
				}

				tLastSoundPlayed = getCurrentTime();
			}
		}


		iPlaySound = dynlen(ddaAlarmTableRows);
	}
}

/**
  @par Description:
  Relics of former panel. Get alarm table content.

  @par Usage:
  Internal.

  @param  ddaRows       dyn_dyn_anytype output, The content of each line of the table.
  @param  dsAlarmColour dyn_string output,      The alarm color of each line.
*/
int _fwAlarmScreen_groups_getTablerows(dyn_dyn_anytype &ddaRows, dyn_string &dsAlarmColour)
{
	dynClear(ddaRows);
	dynClear(dsAlarmColour);


	dyn_string temp;
	string colour;

	int iLineCount;
	getValue(AES_TABLENAME_TOP, "lineCount", iLineCount);
	for(int i = 0 ; i < iLineCount; i++)
	{
		dyn_anytype daLineContent;
		string sColour;

		getValue(AES_TABLENAME_TOP, "getLineN", i, daLineContent);
		getValue (AES_TABLENAME_TOP, "cellBackColRC", i, "abbreviation", sColour);

		daLineContent[fwAlarmScreen_groups_COLOUR_INDEX] = sColour;

		dynAppend(ddaRows, daLineContent);
		dynAppend(dsAlarmColour, sColour);

		getValue(AES_TABLENAME_TOP, "lineCount", iLineCount);
	}

	int iColumnCount;
	getValue (AES_TABLENAME_TOP, "columnCount", iColumnCount);

	dyn_string dsColumns;
	for(int i = 0; i < iColumnCount ; i++)
	{
		string sColumnName;
		getValue(AES_TABLENAME_TOP, "columnName", i, sColumnName) ;
		dynAppend(dsColumns, sColumnName);
	}


	dynAppend(ddaRows, dsColumns);
}

/**
  @par Description:
  Relics of former panel. Fill the content of groups with the given alarm if it matches.

  @par Usage:
  Internal.

  @param  ddaAllGroups    dyn_anytype input output, All the alarm groups.
  @param  daAlarmRow      dyn_anytype input,        An alarm line.
  @param  diColumnIndexes dyn_int input,            The indexes of the alarm columns.
*/
void _fwAlarmScreen_groups_updateMap(dyn_dyn_anytype &ddaAllGroups, dyn_anytype daAlarmRow, dyn_int diColumnIndexes, bool bShowAlarmsInAllGroups)
{
	for (int i = 1 ; i <= dynlen(ddaAllGroups) ; i++)
	{
		if (fwAlarmScreen_groups_ROW_BREAK_LABEL == ddaAllGroups[i][fwAlarmScreen_groups_GROUP_INDEX_ID])
		{
			continue;
		}

		mapping mGroupSystems = ddaAllGroups[i][fwAlarmScreen_groups_GROUP_INDEX_SYSTEMS];
		for (int j = 1 ; j <= mappinglen(mGroupSystems) ; j++)
		{
			const string sMappingKeySystem = mappingGetKey(mGroupSystems, j);
			if(patternMatch(sMappingKeySystem, daAlarmRow[diColumnIndexes[2]]))
			{
				dyn_string dsDpePatterns = mappingGetValue(mGroupSystems, j)[fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES];
				dyn_string dsAliases = mappingGetValue(mGroupSystems, j)[fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES];
				// Check if each DPE is to be filtered.
				for(int k = 1 ; k <= dynlen(dsDpePatterns) ; k++)
				{
					// Check if the alarm dpe belongs to the group name
					string sPattern;
					dyn_string dsExceptions;
					fwGeneral_getNameWithoutSN(dsDpePatterns[k], sPattern, dsExceptions);
					if(dsDpePatterns[k] == sPattern) // No system name in the pattern: add it
					{
						dsDpePatterns[k] = sMappingKeySystem + dsDpePatterns[k];
					}

					if(patternMatch(dsDpePatterns[k], daAlarmRow[diColumnIndexes[6]]))
					{
						// Pass the group name and the alarm line
						_fwAlarmScreen_groups_handleGroup(daAlarmRow, diColumnIndexes, ddaAllGroups[i]);


						dynClear(dsDpePatterns);
						dynClear(dsAliases);

						mGroupSystems[sMappingKeySystem][fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES] = dsDpePatterns;
						mGroupSystems[sMappingKeySystem][fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES] = dsAliases;

						if (!bShowAlarmsInAllGroups)
						{
							return;
						}
					}
				}

				// If dp pattern did not match, try with alias pattern
				for(int k = 1; k <= dynlen(dsAliases) ; k++)
				{
					// Check if the alarm dpe belongs to the group name
					if(strlen(daAlarmRow[diColumnIndexes[8]]) && strlen(dsAliases[k]) && patternMatch(dsAliases[k], daAlarmRow[diColumnIndexes[8]]))
					{
						// Pass the group name and the alarm line
						_fwAlarmScreen_groups_handleGroup(daAlarmRow, diColumnIndexes, ddaAllGroups[i]);
						dynClear(ddaAllGroups[i][mappingGetValue(mGroupSystems, j)][fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES]);
						dynClear(ddaAllGroups[i][mappingGetValue(mGroupSystems, j)][fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES]);

						if (!bShowAlarmsInAllGroups)
						{
							return;
						}
					}
				}
			}
		}
	}
}

/**
  @par Description:
  Save an alarm line to the given group.

  @par Usage:
  Internal.

  @param  daAlarmRow      dyn_anytype input,        The content of an alarm line.
  @param  diColumnIndexes dyn_int input,            The indexes of the alarm columns.
  @param  daGroup         dyn_anytype input ouput,  The group to add the line to.
*/
void _fwAlarmScreen_groups_handleGroup(dyn_anytype daAlarmRow, dyn_int diColumnIndexes, dyn_anytype &daGroup)
{
	const string sAck = daAlarmRow[diColumnIndexes[4]];   // Alarm ackable or not
	const string sTime = daAlarmRow[diColumnIndexes[3]];  // Alarm time
	string sDirection = daAlarmRow[diColumnIndexes[5]];   // Alarm direction
	strreplace(sDirection, " ", "");
	const int iPriority = daAlarmRow[diColumnIndexes[9]]; // Alarm priority

	daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS][dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS]) + 1] = daAlarmRow;


	if(dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP]) < 2)
	{
		dyn_anytype daTempSubMap;

		daTempSubMap[fwAlarmScreen_groups_AlertNumber]  = 1;
		daTempSubMap[fwAlarmScreen_groups_UnAckNumber]  = (sAck == "FALSE") ? 0 : 1;
		daTempSubMap[fwAlarmScreen_groups_LastAlert]    = sTime;
		daTempSubMap[fwAlarmScreen_groups_Severity]     = iPriority;
		daTempSubMap[fwAlarmScreen_groups_Colour]       = daAlarmRow[diColumnIndexes[10]];
		daTempSubMap[fwAlarmScreen_groups_Ack]          = sAck;
		daTempSubMap[fwAlarmScreen_groups_Direction]    = sDirection;

		daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP] = daTempSubMap;
	}
	else
	{
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_AlertNumber]++;

		if(sTime > daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_LastAlert])
		{
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_LastAlert] = sTime;
		}

		const int iGroupPriority = daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Severity];
		const string sGroupDirection = daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Direction];

		if
		(
			(sDirection=="CAME" && sGroupDirection=="WENT") ||  
			(sDirection=="CAME" && sGroupDirection=="CAME" && iPriority>iGroupPriority ) ||
			(sDirection=="WENT" && sGroupDirection=="WENT" && iPriority>iGroupPriority )
		)
		{
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Severity] = iPriority;
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Colour] = daAlarmRow[diColumnIndexes[10]];
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Ack] = sAck;
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Direction] = sDirection;
		}

		if(sAck == "TRUE")
		{
			daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_UnAckNumber]++;
		}
	}

	// Blinking
	if((daAlarmRow[diColumnIndexes[7]] == "") && (daAlarmRow[diColumnIndexes[5]][0] != "W"))
	{
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP][fwAlarmScreen_groups_Blinking]++;
	}
}

/**
  @par Description:
  Show the alarm of the selected group.

  @par Usage:
  Public.

  @param  daGroup dyn_anytype input,  The group from which to show the active alarms.
*/
void fwAlarmScreen_groups_showGroupAlarms(dyn_anytype daGroup)
{
	// Init table style
	fwAlarmScreen_copyTableStyle(AES_TABLENAME_TOP, fwAlarmScreen_GROUP_ALARM_TABLE);

//   setValue("pushButtonClearGroupAlarms", "visible", true);
	setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "visible", true);
	setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "deleteAllLines");


	// Clear former selection
	dyn_string dsInfoWidgets = dynPatternMatch("*.INFO", getShapes(myModuleName(), myPanelName(), ""));
	dyn_string dsSubWidgets = dynPatternMatch("*.SUB", getShapes(myModuleName(), myPanelName(), ""));
	for (int i = 1 ; i <= dynlen(dsInfoWidgets) ; i++) // There will always be as many infos as subs widgets
	{
		setValue(dsInfoWidgets[i], "backCol", "_Transparent");
		setValue(dsSubWidgets[i], "textItemId", 2, fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY);
		setValue(dsSubWidgets[i], "textItemId", 3, fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY_NEW);
	}


	// Append all alarms
	for (int i = 1 ; i <= dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS]) ; i++)
	{
		setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "appendLines", 1);

		dyn_anytype daAlarmLine = daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS][i];

		int iColumnCount;
		getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);

		for (int j = 0 ; j < iColumnCount ; j++)
		{
			string sColumnName;
			getValue(AES_TABLENAME_TOP, "columnName", j, sColumnName);

			setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "cellValueRC", i - 1, sColumnName, daAlarmLine[j + 1]);

		}

		// Set color
		setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "cellBackColRC", i - 1, fwAlarmScreen_COLUMN_SHORT_SIGN, daAlarmLine[fwAlarmScreen_groups_COLOUR_INDEX]);
	}

	if (shapeExists(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".INFO")) // There will always be as many infos as subs widgets
	{
		setValue(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".INFO", "backCol", "_Window");
		setValue(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".SUB", "textItemId", 2, fwAlarmScreen_groups_BUTTON_LABEL_HIDE);
		setValue(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] + ".SUB", "textItemId", 3, fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY_NEW);
	}

	textSelectedGroup.text("Alarm table shows: " + daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]);
	textSelectedGroup.visible(true);
	textFieldCurrentGroup.text(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID]);
	fwAlarmScreen_groups_adjustTableSize();
}

/**
  @par Description:
  Clear the group selection and display all alarms again.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_clearGroupAlarms()
{
	setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "visible", false);
	setValue("pushButtonClearGroupAlarms", "visible", false);
	setValue("textFieldSelectedGroup", "text", "");

	// Reset color
	dyn_string dsInfoWidgets = dynPatternMatch("*.INFO", getShapes(myModuleName(), myPanelName(), ""));
	dyn_string dsSubWidgets = dynPatternMatch("*.SUB", getShapes(myModuleName(), myPanelName(), ""));
	for (int i = 1 ; i <= dynlen(dsInfoWidgets) ; i++)
	{
		setValue(dsInfoWidgets[i], "backCol", "_Transparent");
		setValue(dsSubWidgets[i], "textItemId", 2, fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY);
		setValue(dsSubWidgets[i], "textItemId", 3, fwAlarmScreen_groups_BUTTON_LABEL_DISPLAY_NEW);
	}

	textSelectedGroup.visible(false);
	fwAlarmScreenGeneric_setActiveGroup("");
	fwAlarmScreen_groups_adjustTableSize();
}

/**
  @par Description:
  Set the size of the group alarms table to the same as the default AES one.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_adjustTableSize()
{
	int iTableX;
	int iTableY;
	int iTableWidth;
	int iTableHeight;

	getValue(AES_TABLENAME_TOP, "position", iTableX, iTableY);
	getValue(AES_TABLENAME_TOP, "size", iTableWidth, iTableHeight);

	setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "position", iTableX, iTableY);
	setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "size", iTableWidth, iTableHeight);
}

/**
  @par Description:
  Acknowledge all alarms of the selected group.

  @par Usage:
  Public.

  @param  daGroup dyn_anytype input,  The group from which alarms must be acknowledged.
*/
void fwAlarmScreen_groups_acknowledgeGroupAlarms(dyn_anytype daGroup)
{
	setValue("textFieldGroupAck", "text", "");
	dyn_string dsExceptions;

	for (int i = 1 ; i <= dynlen(daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS]) ; i++)
	{
		setValue(fwAlarmScreen_GROUP_ALARM_TABLE, "appendLines", 1);

		dyn_anytype daAlarmLine = daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS][i];

		int iColumnCount;
		getValue(AES_TABLENAME_TOP, "columnCount", iColumnCount);

		for (int j = 0 ; j < iColumnCount ; j++)
		{
			string sColumnName;
			getValue(AES_TABLENAME_TOP, "columnName", j, sColumnName);

			if (fwAlarmScreen_COLUMN_DP_ID == sColumnName)
			{
				fwAlertConfig_acknowledge(dpSubStr(daAlarmLine[j + 1], DPSUB_SYS_DP_EL), dsExceptions);
			}
		}
	}
}

/**
  @par Description:
  Get all alarm groups.

  @param Usage:
  Public.

  @return A list containing all the alarm groups. Their content must be accessed through the fwAlarmScreen_groups_GROUP_INDEX_xxx constants.
*/
dyn_dyn_anytype fwAlarmScreen_groups_getAll()
{
	dyn_dyn_anytype ddaAllGroups;

	bool bCustomOrder = false;
	if(dpExists(fwAlarmScreen_groups_ORDER_DP))
	{
		int iCustomOrderMode;
		dpGet(fwAlarmScreen_groups_ORDERMODE_DP, iCustomOrderMode);

		bCustomOrder = (1 == iCustomOrderMode);
	}

	string sSysName = getSystemName();

	dyn_string dsGroupsDpList;

	// Get the groups in a custom order if necessary, otherwise just alphabetical order.
	if(bCustomOrder)
	{
		dyn_string dsOrderedGroups;
		dpGet(fwAlarmScreen_groups_ORDER_DP, dsOrderedGroups);

		for(int i = 1 ; i <= dynlen(dsOrderedGroups) ; i++)
		{
			if(dpExists(sSysName + fwAlarmScreen_groups_CONFIG_DP + dsOrderedGroups[i]))
			{
				dynAppend(dsGroupsDpList, sSysName + fwAlarmScreen_groups_CONFIG_DP + dsOrderedGroups[i]);
			}
			else if (fwAlarmScreen_groups_ROW_BREAK_LABEL == dsOrderedGroups[i])
			{
				dynAppend(dsGroupsDpList, fwAlarmScreen_groups_ROW_BREAK_LABEL);
			}
		}
	}
	else
	{
		dsGroupsDpList = dpNames(sSysName + fwAlarmScreen_groups_CONFIG_DP + "*", fwAlarmScreen_groups_CONFIG_DPTYPE);
	}

	for (int i = 1 ; i <= dynlen(dsGroupsDpList) ; i++)
	{
		// Build group
		dyn_anytype daGroup = fwAlarmScreen_groups_getGroup(dsGroupsDpList[i]);

		if (dynlen(daGroup) > 0)
		{
			dynAppend(ddaAllGroups, daGroup);
		}


	}

	return ddaAllGroups;
}

/**
  @par Description
  Get the list of dpes of all the DU below the CU and the nested CUs.

  @par Usage
	Internal.

  @param  sCU string input, The Control Unit name.

  @return The DPE list.
*/
dyn_string _fwAlarmScreen_groups_getFsmDeviceDps(const string sCU)
{
	dyn_string dsFsmDeviceDps, dsChildren, dsTmp;
	dyn_int diTypes;

	string sDUdpName;
	if (isFunctionDefined("fwCU_getChildren"))
	{
		dsChildren = fwCU_getChildren(diTypes, sCU);
		for(int i = 1 ; i <= dynlen(dsChildren) ; i++)
		{
			if(diTypes[i] == 2) // Device unit
			{
				fwCU_getDevDp(sCU + "::" + dsChildren[i], sDUdpName);
				dynAppend(dsFsmDeviceDps, sDUdpName + ".*");
			}
			else // Logical units
			{
				dynAppend(dsFsmDeviceDps, _fwAlarmScreen_groups_getFsmDeviceDps(dsChildren[i]));
			}
		}
	}

	return dsFsmDeviceDps;
}

/**
  @par Description:
  Get the Group dp and return the Group name.

  @par Usage:
	Public.

  @param  sDatapointName  string input, The dp name of the group.

  @return The group name.
*/
string fwAlarmScreen_groups_getGroupId(string sDatapointName)
{
	string id;
	int pos = strpos(sDatapointName, fwAlarmScreen_groups_CONFIG_DP);
	id = substr(sDatapointName, pos);
	strreplace(id, fwAlarmScreen_groups_CONFIG_DP, "");
	return id;
}

/**
  @par Description:
  Get a group from the given datapoint.

  @par Usage:
  Public.

  @param  sDatapoint  string input, The datapoint to get the group from.

  @return The group, empty if the DP doesn't exist.
*/
dyn_anytype fwAlarmScreen_groups_getGroup(const string sDatapoint)
{
	dyn_anytype daGroup;

	if (dpExists(sDatapoint))
	{
		dyn_string dsSystems;
		dpGet(sDatapoint + ".systems", dsSystems);
		dyn_string dsDpes;
		dpGet(sDatapoint + ".dpes", dsDpes);
		dyn_string dsAliases;
		dpGet(sDatapoint + ".aliases", dsAliases);



		// Dpe
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_DPE] = sDatapoint;

		// Group Id
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] = fwAlarmScreen_groups_getGroupId(sDatapoint);

		// Description
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_DESCR] = dpGetDescription(sDatapoint + ".", -2);

		// Systems
		mapping mSystems;
		for (int j = 1 ; j <= dynlen(dsSystems) ; j++)
		{
			dyn_dyn_string ddsSystemFilters;

			if(strpos(dsSystems[j], ":") < 0)
			{
				dsSystems[j] = dsSystems[j] + ":";
			}

			// Aliases
			dyn_string dsSysAliases;
			if(dynlen(dsAliases) >= j )
			{
				if (strlen(dsAliases[j]) > 1)
				{
					dsSysAliases = strsplit(dsAliases[j], "|");
				}
				else
				{
					dsSysAliases = makeDynString("");
				}

			}
			else
			{
				dsSysAliases = makeDynString("");
			}


			// Dpes
			dyn_string dsSysDpes;
			if(dynlen(dsDpes) >= j)
			{
				if(strlen(dsDpes[j]) > 1)
				{
					dsSysDpes = strsplit(dsDpes[j], "|");
				}
				else
				{
					// If there is no dpe and no alias, set dpe to "*" (all)
					if ((dynlen(dsAliases) >= j) && (strlen(dsAliases[j]) > 0))
					{
						dsSysDpes = makeDynString("");
					}
					else
					{
						dsSysDpes = makeDynString("*");
					}
				}
			}
			else
			{
				// If there is no dpe and no alias, set dpe to "*" (all)
				if ((dynlen(dsAliases) >= j) && (strlen(dsAliases[j]) > 0))
				{
					dsSysDpes = makeDynString("");
				}
				else
				{
					dsSysDpes = makeDynString("*");
				}
			}


			ddsSystemFilters[fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES] = dsSysDpes;
			ddsSystemFilters[fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES] = dsSysAliases;


			mSystems[dsSystems[j]] = ddsSystemFilters;
		}



		// FSM cu
		dyn_string dsFsmCu;
		dpGet(sDatapoint + ".fsmCu", dsFsmCu);

		for(int j = 1 ; j <= dynlen(dsFsmCu) ; j++)
		{
			dyn_string dsFsmDeviceDps = _fwAlarmScreen_groups_getFsmDeviceDps(dsFsmCu[j]);
			dyn_string dsFsmDevicesSystems;

			for(int k = 1 ; k <= dynlen(dsFsmDeviceDps) ; k++)
			{
				dsFsmDevicesSystems[k] = "";

				dyn_string dsExceptions;
				fwGeneral_getSystemName(dsFsmDeviceDps[k], dsFsmDevicesSystems[k], dsExceptions);

				if (mappingHasKey(mSystems, dsFsmDevicesSystems[k])) // System belonging to DU is already in list: add DU dpe under the sys
				{
					dyn_string dsLocalDpes = mSystems[dsFsmDevicesSystems[k]][fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES];
					dynAppend(dsLocalDpes, dsFsmDeviceDps[k]);

					mSystems[dsFsmDevicesSystems[k]][fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES] = dsLocalDpes;
				}
				else // System belonging to DU is not in list: add new system and add DU dpe under the sys
				{
					dyn_dyn_string ddsSystemFilters;

					ddsSystemFilters[fwAlarmScreen_groups_GROUP_INDEX_SYS_DPES] = makeDynString(dsFsmDeviceDps[k]);
					ddsSystemFilters[fwAlarmScreen_groups_GROUP_INDEX_SYS_ALIASES] = makeDynString();

					mSystems[dsFsmDevicesSystems[k]] = ddsSystemFilters;
				}
			}
		}

		daGroup[fwAlarmScreen_groups_GROUP_INDEX_SYSTEMS] = mSystems;
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_SUBMAP] = makeDynAnytype();
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_ALARMS] = makeDynAnytype();
	}
	else if (fwAlarmScreen_groups_ROW_BREAK_LABEL == sDatapoint)
	{
		daGroup[fwAlarmScreen_groups_GROUP_INDEX_ID] = fwAlarmScreen_groups_ROW_BREAK_LABEL;
	}

	return daGroup;
}

/**
  @par Description:
  Open the panel to configure the groups.

  @par Usage:
  Public.
*/
void fwAlarmScreen_groups_editGroups()
{
	fwAlarmScreen_groups_remove();

	dyn_float dfResult;
	dyn_string dsResult;

	ChildPanelOnCentralModalReturn(
		"fwAlarmHandling/fwAlarmScreenGroupsConfiguration.pnl",
		"Groups configuration",
		makeDynString(),
		dfResult,
		dsResult
	);

	fwAlarmScreen_groups_show();
}

/**
  @par Description:
  Get the default alarm sound to be played.

  @par Usage:
	Public.

  @return The alarm to be played.
*/
string fwAlarmScreen_groups_getDefaultSoundPath()
{
	return getPath(DATA_REL_PATH, "sounds/AlertTone.wav");
}

/**
  @par Description:
  Get the project name.

  @par Usage:
	Public

  @return The project name.
*/
string fwAlarmScreen_groups_getProjectName()
{
	string sProjName, sDir;
	dyn_string dsTemp;

	sDir = getPath(CONFIG_REL_PATH);
	dsTemp = strsplit(sDir, "/" );

	if(dynlen(dsTemp) > 2)
	{
		sProjName = dsTemp[dynlen(dsTemp) - 1];
	}

	return sProjName;
}


void fwAlarmScreen_group_groupTableAcknowledgeAlarm(const string sTable, const int iRow, const string sColumn)
{
	const string sAckedLabel = "  x  ";
	dyn_string dsAccessRights;
	dyn_string dsExceptions;

	bool isGranted;

	fwAlarmScreen_getAccessControlOptions(dsAccessRights, dsExceptions);

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

	string sAcked;
	getValue(sTable, "cellValueRC", iRow, fwAlarmScreen_COLUMN_ACKNOWLEDGE, sAcked);
	if (sAckedLabel == sAcked)
	{
		return;
	}

	anytype aDpId;
	bool bAckable;
	bool bAckOldest;
	getValue(sTable, "cellValueRC", iRow, _ACKABLE_, bAckable);
	getValue(sTable, "cellValueRC", iRow, _ACK_OLD_, bAckOldest);
	getValue(sTable, "cellValueRC", iRow, _DPID_, aDpId);
	string sDpId = dpSubStr(aDpId, DPSUB_SYS_DP_EL);

	if(bAckable && !bAckOldest)
	{
		aec_warningDialog(AEC_WARNINGID_NOTTHEOLDESTALERT);
		return;
	}

	fwAlertConfig_acknowledge(sDpId, dsExceptions);

	if (dynlen(dsExceptions) > 0)
	{
		fwExceptionHandling_display(dsExceptions);
	}
	else
	{
		// Update the line manually (no automatic update in this table)
		setValue(sTable, "cellValueRC", iRow, fwAlarmScreen_COLUMN_ACKNOWLEDGE, sAckedLabel);

		delay(1); // Leave time to propagate.
		textFieldSelectedGroup.text(textFieldCurrentGroup.text());
	}

	return;
}


void fwAlarmScreen_groups_groupTableClick(const int iRow, const string sColumn, const string sValue)
{
	if (iRow < 0)
	{
		return;
	}

	if (fwAlarmScreen_COLUMN_ACKNOWLEDGE == sColumn)
	{
		fwAlarmScreen_group_groupTableAcknowledgeAlarm(this.name(), iRow, sColumn);
	}
}
