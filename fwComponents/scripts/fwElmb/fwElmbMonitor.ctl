#uses "fwElmb/fwElmbMonitorLib.ctl"

main()
{
// Local Variables
// ---------------
	bool bExit;
	bool bActive;
	bool bWasActive;
	bool bRefresh = true;
	bool bTimeout = false;
	
	int i;
	
	time tTimeout = 60;
	
	dyn_string dsBusesToMonitor;
	dyn_string dsBusesMonitored;
	dyn_string dsBusesToStopMonitoring;
	dyn_string dsBusesToStartMonitoring;
	dyn_string dsElmbsToMonitor;
	dyn_string dsElmbsMonitored;
	dyn_string dsElmbsToStopMonitoring;
	dyn_string dsElmbsToStartMonitoring;
	dyn_string dsDpNamesToWaitFor;
	dyn_string dsDpNamesReturn;
	
	dyn_anytype daConditions;
	dyn_anytype daReturnedValues;

// Executable Code
// ---------------
	// Set flag to indicate script is running
	dpSet(ELMB_MONITOR_DPNAME + ".running", true);
	
	// Get flag and check that this is meant to be running
	dpGet(ELMB_MONITOR_DPNAME + ".exit", bExit,
				ELMB_MONITOR_DPNAME + ".active", bActive);
				
	// Check if this script should continue to run
	if (!bExit) {
		// Initialise the 'before' state
		bWasActive = bActive;
	
		// Loop until flag indicates that it should stop
		while (!bExit) {
									
			// Check whether timeout has expired
			if (!bTimeout) {
				
				// Check for refresh first
				if (bRefresh) {
						
					// Refresh all monitor information
					dsBusesMonitored = dsBusesToMonitor;
					dsElmbsMonitored = dsElmbsToMonitor;
					fwElmbMonitor_refresh(dsBusesToMonitor, dsElmbsToMonitor);
						
					// For new Buses to monitor, we need those in the array dsBusesToMonitor
					// that do NOT appear in the array dsBusesMonitored
					dynClear(dsBusesToStartMonitoring);
					for (i = 1; i <= dynlen(dsBusesToMonitor); i++) {
						if (dynContains(dsBusesMonitored, dsBusesToMonitor[i]) == 0)
							dynAppend(dsBusesToStartMonitoring, dsBusesToMonitor[i]);
					}

					// For Buses to stop monitoring, we need those in the array dsBusesMonitored
					// that do NOT appear in the array dsBusesToMonitor
					dynClear(dsBusesToStopMonitoring);
					for (i = 1; i <= dynlen(dsBusesMonitored); i++) {
						if (dynContains(dsBusesToMonitor, dsBusesMonitored[i]) == 0)
							dynAppend(dsBusesToStopMonitoring, dsBusesMonitored[i]);
					}
						
					// For new ELMBs to monitor, we need those in the array dsElmbsToMonitor
					// that do NOT appear in the array dsElmbsMonitored
					dynClear(dsElmbsToStartMonitoring);
					for (i = 1; i <= dynlen(dsElmbsToMonitor); i++) {
						if (dynContains(dsElmbsMonitored, dsElmbsToMonitor[i]) == 0)
							dynAppend(dsElmbsToStartMonitoring, dsElmbsToMonitor[i]);
					}

					// For ELMBs to stop monitoring, we need those in the array dsElmbsMonitored
					// that do NOT appear in the array dsElmbsToMonitor
					dynClear(dsElmbsToStopMonitoring);
					for (i = 1; i <= dynlen(dsElmbsMonitored); i++) {
						if (dynContains(dsElmbsToMonitor, dsElmbsMonitored[i]) == 0)
							dynAppend(dsElmbsToStopMonitoring, dsElmbsMonitored[i]);
					}
		
					// Start the monitoring if set to active
					if (bActive) {
						if (bWasActive) {
							DebugTN("ELMB Monitoring activated (following refresh)...");
				
							// Manage the changes in bus monitoring
							for (i = 1; i <= dynlen(dsBusesToStartMonitoring); i++)
								fwElmbMonitorLib_connectToBus(dsBusesToStartMonitoring[i]);
				
							for (i = 1; i <= dynlen(dsBusesToStopMonitoring); i++)
								fwElmbMonitorLib_disconnectFromBus(dsBusesToStopMonitoring[i]);
				
							// Manage the changes in ELMB monitoring
							for (i = 1; i <= dynlen(dsElmbsToStartMonitoring); i++)
								fwElmbMonitorLib_connectToELMB(dsElmbsToStartMonitoring[i]);
				
							for (i = 1; i <= dynlen(dsElmbsToStopMonitoring); i++)
								fwElmbMonitorLib_disconnectFromELMB(dsElmbsToStopMonitoring[i]);
						}
						
						// Now update list of those currently monitored
						dsElmbsMonitored = dsElmbsToMonitor;
						dsBusesMonitored = dsBusesToMonitor;
					}
					
				}	// End of refresh
					
				// Now check whether the active state has changed
				if (bActive && !bWasActive) {
					
					// Start the monitoring
					DebugTN("ELMB Monitoring activated...");
					for (i = 1; i <= dynlen(dsBusesToMonitor); i++)
						fwElmbMonitorLib_connectToBus(dsBusesToMonitor[i]);
					for (i = 1; i <= dynlen(dsElmbsToMonitor); i++)
						fwElmbMonitorLib_connectToELMB(dsElmbsToMonitor[i]);
						
				} else if (!bActive && bWasActive) {
				
					// Stop monitoring
					DebugTN("ELMB Monitoring deactivated...");
					for (i = 1; i <= dynlen(dsBusesMonitored); i++)
						fwElmbMonitorLib_disconnectFromBus(dsBusesMonitored[i]);
					for (i = 1; i <= dynlen(dsElmbsMonitored); i++)
						fwElmbMonitorLib_disconnectFromELMB(dsElmbsMonitored[i]);
					
				}
					
				// Set the 'past' active state to the current
				bWasActive = bActive;
				
			}	// End of timeout check

			// Set up parameters to wait for the any changes
			dsDpNamesToWaitFor = makeDynString(	ELMB_MONITOR_DPNAME + ".exit:_online.._value",
																					ELMB_MONITOR_DPNAME + ".active:_online.._value",
																					ELMB_MONITOR_DPNAME + ".refresh:_online.._value");
			dsDpNamesReturn = dsDpNamesToWaitFor;
		
			// Wait for changes. Realistically, there shouldn't be a need for
			// a timeout. However, a long timeout is added for 'safety'
			dpWaitForValue(	dsDpNamesToWaitFor,
											daConditions,
											dsDpNamesReturn,
											daReturnedValues,
											tTimeout,
											bTimeout);
			if (!bTimeout) {
				// Check the values, as something must have changed
				bExit = daReturnedValues[1];
				bActive = daReturnedValues[2];
				bRefresh = daReturnedValues[3];
			}
			
		} // End of while loop
	}
	
	// Disconnect from all monitored ELMBs before exiting
	for (i = 1; i <= dynlen(dsBusesMonitored); i++) {
		fwElmbMonitorLib_disconnectFromBus(dsBusesMonitored[i]);
	}
	for (i = 1; i <= dynlen(dsElmbsMonitored); i++) {
		fwElmbMonitorLib_disconnectFromELMB(dsElmbsMonitored[i]);
	}
	
	// Indicate that the control script is exiting
	DebugTN("ELMB Monitoring control script exiting...");
	
	// Set exit flag to false for next startup, and running flag to false (as it's stopping)
	dpSet(ELMB_MONITOR_DPNAME + ".exit", false,
				ELMB_MONITOR_DPNAME + ".running", false);

	// Exit
	return;
}

void fwElmbMonitor_refresh(	dyn_string &argdsBusesToMonitor,
														dyn_string &argdsElmbsToMonitor)
{
// Local Variables
// ---------------
	bool bBusActive;
	bool bElmbActive;
	
	int i;
	
	dyn_string dsBuses;
	dyn_string dsElmbs;

// Executable Code
// ---------------
	// Clear the bus list
	dynClear(argdsBusesToMonitor);
	
	// Get all buses in the system
	dsBuses = dpNames("*", ELMB_CAN_BUS_TYPE_NAME);
		
	// Loop through all buses, checking whether monitoring is active or not
	for (i = 1; i <= dynlen(dsBuses); i++) {
		dpGet(dsBuses[i] + ".monitoring.active", bBusActive);
		if (bBusActive)
			dynAppend(argdsBusesToMonitor, dsBuses[i]);
	}
		
	// Now find all ELMBs
	dsElmbs = dpNames("*", ELMB_TYPE_NAME);
	
	// Clear the ELMB list
	dynClear(argdsElmbsToMonitor);
		
	// Loop through all ELMBs, checking whether monitoring is active or not
	for (i = 1; i <= dynlen(dsElmbs); i++) {
		dpGet(dsElmbs[i] + ".monitoring.active", bElmbActive);
		if (bElmbActive)
			dynAppend(argdsElmbsToMonitor, dsElmbs[i]);
	}
	
	// Reset the refresh flag to false
	dpSet(ELMB_MONITOR_DPNAME + ".refresh", false);

	// Return to calling routine
	return;
}
