THIS VERSION IS FWELMB8.4.0 CORRECTED BY CRISTINA VAZQUEZ following:
https://its.cern.ch/jira/browse/OPCUA-1901


ELMB FW v8.3.1
---------------

** VERY IMPORTANT **
====================

IMPORTANT: This version of the ELMB framework can only be used with ELMB128. If you are still using the
old version of the ELMB (Atmega 103) you should get in touch with the ATLAS DCS group
(Piotr.Nikiel@cern.ch, Stefan.Schlenker.cern.ch)

Change Log
==========
v3.0.1 27/09/2004 - Change log introduced.
       Bug Fixes: Custom sensor types can now be created successfully
                  Warnings for 'Constants already defined' shown in log viewer no longer exist
                  User entered prefix for sensor name (at creation time) now taken into account properly

       Additions: Custom sensor types can now be edited and/or deleted
                  New 'Standard' sensor types included for use with the Rack Control
                  'Standard' sensor types cannot be edited or deleted

v3.0.2 03/11/2004
       Bug Fixes: When configuring the ELMB ADC settings, the ELMB was not correctly set back into
                  the operational state. This has been rectified.
                  The formulas for the standard sensors for the rack control project have been corrected.

v3.0.2 03/11/2004
       Internal release only. Never released to the public

v3.0.4 15/11/2004
       Additions: Various changes have been made for use with the ELMB PSU component that is under development

v3.0.5 19/11/2004
       Internal release only. Never released to the public

v3.0.6 08/02/2005
       Additions: First prototype of ELMB monitoring included

v3.0.7 15/03/2005
       Additions: Online documentation added for most panels
       Bug Fixes: Errors in device definition causing problems creating devices
                  Errors in FwCore also created problems, so this release coincided with a FwCore release

v3.0.8 27/06/2005
       Additions: User functions added in FwElmbUser.ctl
                  Improved functionality when creating multiple ELMBs
       Bug Fixes: Minor bugs in prototype of ELMB monitoring fixed

v3.0.9 23/08/2005
       Bug Fixes: Minor bugs in FwElmbUser.ctl for user functions fixed.
                  Sensor parameter descriptions did not have any spaces (and so were difficult to read)
                  Creation of OPC configuration file bug fixed when 'e' notation used (e.g. 1e-006)

v3.0.10 01/09/2005
       Bug Fixes: Definition of a constant had been overlooked in previous versions

v3.1.0 16/01/2006
       Additions: On installation of the ELMB component, a Simulation Manager and an OPC Client
                  with the correct number is now entered into the list of managers in the console.
                  Updates to Device Definitions for all ELMB related datapoints to allow the
                  Configuration Database tool to be used properly with the ELMB.
                  When creating an analog input, a choice can be made for whether the channel
                  number is appended to the sensor name or not.

       Bug Fixes: Small bugs fixed in the library FwElmbUser.ctl causing an error when certain
                  functions returned after an exception was caught.
                  State Timer for OPC Server is now set to 10 seconds to remove a warning message
                  from the log viewer when the OPC Client is started.

v3.2.0 07.02.2006
       Additions: Possibility to define custom PDOs to be used for analog inputs.
                  Possibility to define a sensor as a 'raw value' sensor.
                  Hidden buttons for the ELMB monitoring until more development done (more a deletion!)

       Bug Fixes: Names in device definition for some DPTs where more than 32 characters, meaning
                  that they could not be stored correctly with the configuration database tool. This
                  has been rectified.

v3.2.1 16.02.2006
       Additions: Update to user function for creating a sensor so that the parameters for the function
                  can be taken from the definition of the sensor (rather than being supplied by user).
                  Increased use of constants defined for the ELMB component to aid in consistency.

v3.2.2 08.03.2006
       Additions: Minor updates to configuration panels for AI, DI and DO for consistency.
                  Addition of help to DI and DO configuration panels.

       Bug Fixes: Fixed bug in digital input and output creation panels which did not allow the selection
                  of port A unless all bits of port F (for DI) or port C (for DO) were already created.
                  Installation procedure improved to handle already existing custom sensors.
                  Removed references to libraries for other framework components in configuration file
                  entries, which caused problems when upgrading from older versions of the framework.

v3.3.0 30.06.2006
	Additions:	Inclusion of SPI into ELMB component
			Confirmation questions are now given before deleting any device in the ELMB component
			All scripts and libraries are now in subfolders called 'fwElmb' (you should manually
			  delete any old scripts and/or libraries starting with the prefix 'fwElmb').

	Bug Fixes:	Fixed bug that occurred if a user defined sensor did not contain any 'variable constants'

v3.3.1 05.09.2006
	Additions:	Comment for devices is now displayed in panels
			Valid, Invalid or Alert is now displayed in panels for analog/digital inputs/outputs
			Can now choose node IDs greater than 63 (for custom ELMB firmware)
			Buses that do not have any elements addressed are not output to OPC configuration
			  file, nor any devices lower in the hierarchy

	Bug Fixes:	Custom PDOs did not have COB-ID calculated correctly when more than one node (using
			  the same custom PDO) was declared

v3.3.2 03.11.2006
	Bug Fixes:	OPC Configuration file can now be created in other drives (e.g. D:\)
			Fixed issues with Digital Input and Output creation for PVSS 3.6

v3.3.3 05.12.2006
	Additions:	Simple monitoring of ELMB now included. Sets analog input channels to invalid
			  if state pre-operational or stopped, or if OPC connection lost, or if emergency
			  message for analog input timeout received.
			All emergency messages received are now entered into a string DPE within the 
			  FwElmbNode DPT. This contains emergency error code, all fields and a timestamp.

	Bug Fixes:	Emergency message now shown correctly in Node Operation panel

v3.3.4 15.03.2007
	Additions:  Input channels which are invalid are shown as bold/italic in the panels. This has
                    been added as the framework colour for came/went unacknowleged is the same as
                    when the value is invalid. Therefore, it was not easy to tell whether a value is
                    invalid, or whether the alert had just been unacknowledged.
                  A new item has been added which 'removes' the toggle bit from the state.value. This
                    allows alert handling to be added for a state which is not Operational. A default
                    alert handling for this item (state.noToggle) has also been added.
                  The timeout for reading the ADC configuration settings has been increased and the
                    mechanism for checking whether the reading has been successful has been improved.
                    This has been done as when there are many ELMBs on a bus, the previous timeout was
                    found to sometimes be too small.

v3.3.5 16.05.2007
      Additions:  May now format values shown in the table on the ELMB Node Operation Panel.
                  May select whether to filter out analog input channels that have already been assigned
                    with input sensors or not. This is for specific and advanced use-cases (only for experts).
                  Additions to handle better the sign within the sensor formula when the constants are
                    negative (or different than the sign in the formula itself).

	Bug Fixes:	Corrected the OPC Group configuration for Analog and Digital Inputs and Outputs to read
                    from the cache (rather than device).

v3.4.0 10.07.2007
      NOTE:       When updating to this version from an older version, when the post installation script
      -----         is run, error messages may be shown in the log viewer. This is only the case if the 
                    Control Manager with option '-f fwScripts.lst' starts before the Simulation Driver
                    with option '-num 7'. The exceptions seen will all be regarding functions with the
                    prefix 'fwPeriphAddress_' and can be ignored. The addressing is set as required even
                    though these errors are displayed.

                  If you wish to avoid these errors, ensure the the Simulation Driver with option '-num 7'
                    starts before the post installation scripts.

      Additions:  Digital outputs are now handled completely differently. The only addressed item is for
                    digital output bytes and the individual bits do not have addressing. Setting a value
                    into a datapoint element of a digital output bit will have no effect. Functions have
                    been created which should be used instead (available in fwElmbbUser.ctl).
                  Digital input configuration information has been extended to allow for Port A input enable
                    mask and the interrupt enable masks for both Ports A and F to be modified.
                  Minor version of the ELMB firmware can now be read out.
                  Output ports A and C may now be read (used to keep consistency between hardware and
                    software).
                  
      Bug Fixes:  The state.noToggle datapoint function is now added to each node (which was only done when
                    the ELMB was created previously).
                  The first time the OPC Server configuration file is created, it could only be saved to the
                    root C:\ drive. It may now be created in any folder.
                  Corrections made to OPC Server configuration file for when Port A has any bits defined as
                    inputs.

v3.4.1 06.08.2007

      Bug Fixes:  Fixed bug with digital outputs that made it seem like setting a digital output on one ELMB
                    also changed digital outputs on other ELMBs (though this was not actually the case)

v3.5.0 25.01.2008

      Additions:  Analog outputs have been added to the ELMB framework component.
                  New entry added to CANbus operation panel to manage ALL buses on the system.
                  Addition of panel (fwElmb\objects\fwElmbManageOpcGroups.pnl) to aid the management of unused
                    OPC groups (possibly due to a CANbus being removed from the system).

      Bug Fixes:  Fixed bug for querying SDO item values from a remote system.

v3.5.1 29.04.2008

      Additions:  Analog inputs which use SDOs for the values have now been included. This is mainly for
                    use by the radiation monitoring sensors, and probably is not much use to other applications.
                  OPC groups are now created 'on demand', that is, the group used by analog inputs is
                    created when the first analog input is created.
                  Digital input lines on ports D and E may now be created. Note that the usage of these ports
                    requires custom firmware, which is not officially supported.

      Bug Fixes:  Checking whether the OPC client is running now checks remote system if necessary.
                  Fixed (random) bug seen during installation on some systems, where the FwElmbNode DPT was
                    not correctly updated.

v3.5.2 24.06.2008

      Additions:  New datapoint element added to FwElmbNode to indicate whether ANY analog input channel is
                    marked as invalid. This boolean value may then be used to show an alert. The new DPE is
                    updated only if the script 'fwElmb/fwElmbCheckInvalid.ctl' is running.

v3.5.2 24.06.2008

      Bug Fixes:  If the event timer was used (instead of SYNC Interval), the requested value for the timer
                    interval was set as milliseconds (instead of seconds) and therefore was 1000 times to big.



v3.5.3 2009 


v3.5.4 
      Bug Fixes:  Logical View available


      		  If the event timer was used (instead of SYNC Interval), the requested value for the timer
                    interval was set as milliseconds (instead of seconds) and therefore was 1000 times to big.

v3.5.5
      Bug Fixes:  Update of Digital Ouputs on the restart of the ELMB


v3.5.6
      Bug Fixes:  formula for NTC measurements modified. Regeneration of OPC config file and restart of OPC Server needed.
                  fixes for error messages which appeared on the log during installation (see postinstall)


v3.5.7
      Bug Fixes:  Configure Digital Input settings from fwDeviceEditorNavigator (bug introduced in v3.5.6).
		

v4.0.0
      Additions:  new string DPE .model for all DPTs, for compatibility with UNICOS.

      Bug Fixes:  timeout error messages in logViewer with usage of function fwElmb_elementSQ().

v4.1.0
      Bug Fixes: fwElmbUser_setDoBits: Output bytes not set if reading failed + synchronization mechanism 
		
      Additions: Mutex functions for 'synchronization'
		 fwElmbUser_setDoBitsSynchronized() 

v4.2.2
       Additions: additon of an 'UserDefined' DP element for all DPTs
		  increase limitation of Mutex (from 10 to 12)

v4.2.3
      Bug Fixes: fwElmbUser_monitorInvalid: fix + include SDO channels
		 userDefined init
		 fwElmb_elementSQ(): dpSetWait  

v4.3.0
      Bug Fixes: bug fix propsoed for the '_Do_read' OPC group configs, to avoid message conflicts with polling mode. 
		 check in the postInstall and expert panel fwElmb/fwElmbModifyOPCconfigs.pnl available.

[--- missing changelog up to version 5.0.4 -- it was never written---]

v5.0.5
	OPC DA and UA drivers were moves from postInstall script to init script.

v5.0.6
	Bugfixes for the release:	
	- [FIXED] no dependency on fwAtlas specified, which is needed in certain
	  basic features like OPC config generation (functions like e.g. fwAtlas_getSubdetectorId)
	- [FIXED FOR LINUX ONLY] path to XSD file in generated OPC configuration for OPC UA Server is
	  not specified, and manual fixing is necessary 
	- [FIXED] a freshly created ELMB's type (in FwElmbNode DP) is not defaulted to
	  'ELMB' so manual fixing is necessary
	- [FIXED] a subscription is used for both Direct ADC Voltage and Raw ADC
	  sensor types, but this seems buggy as subscriptions are only
	  supported for plain PDOs not items. Fixed by using polling for
	  anything else than Raw ADC value
	
v5.0.7
	fwAtlas dependency introduced in 5.0.6 removed - users of fwElmb
	should not necessarily depend on fwAtlas. Instead isFunctionDefined is used to determine if
	getSubdetectorId can be called
	OPC UA Address Conversion is cleaned up and fixed in multiple places:
	- none of SDO-based items is using subscriptions anymore - PVSS will
	  not complain about BadInternalError of OPC UA server
	- Subscription creation is cleaned up
	- Since this version the conversion script will stop when any
	  inconsistency is observed. Before It'd create erroneus subscription
	  if data points were not ok.
	Bug fixes for the release:
	- [FIXED] OPC UA Config file generator would crash when no equal sign
	  was present in the formula (which is stored in FwElmbAi .function)
	- [FIXED] Digital Output type was byte instead of Uint16. This was
	  compatible with old ELMBs but restricted functionalities of modern
          ELMBs which have two DO ports instead of one. 
	- [FIXED] TPDO3 type was unsigned so (rare) negative values were
	  handled improperly. It is now signed.

v5.0.8
	OPC UA Address Conversion is further cleaned up, that is doInitHigh
        and do_read_A and do_read_C are not into subscriptions anymore so
        client won't complain (because they are SDO items therefore can't be
        subscribed to).
	More over new function (in the conversion panel) is implemented:
	setting all subscriptions' data change triggers from "Value,State" to
	"Value,State,Timestamp". Thanks to that one can get noticable refresh of
	datapoint not only when value changed but also when value didn't change but
	timestamp did. 
	Also now address setup procedure will continue with next address to
	convert if a wrong one is found.
v5.0.9
	Bug fixes:
	1) for non-ATLAS users: information() function (specific to ATLAS) is 
	no longer referenced. That prevented to create OPC UA XML config file.
	2) When running OPC UA Setup, created polling groups will have default
	polling interval of 5 seconds (on default, in previous releases, that 
	was 0 which is incorrect). Also, workaround polling groups for single 
	queries will be deactivated (they are not supposed to be polling
	anything either way, they are just workaround fakes).
	3) New functionality in the conversion panel - ability to setup
	polling interval of all OPC UA polling groups at once.
v5.0.10
	1) FwElmbCANbus DPT - added attribute "managementOnServerStartup".
	This differs from "management", as the latter is for provoking current 
	operations (Start/Stop/Reset) only, and the former should be persistent system parameter.
	Adequate control added for edition of CANbus in DEN.
	Parameter is used for OPC UA Config file generation.
	2) FwElmbNode DPT - identical changes but for Node level.
	3) FwElmbType - new DPT introduced. Contains known ELMB types, every
	type has a path defined to its NodeType XML file.
	4) Fixed a problem that temporary file for OPC UA config  was created
	in predefined location and not in the directory that user chosen. Some of
	those predefined location turned out to be read-only.
	5) Added ASCII Manager configuration to export fwElmb-repated DPs and
	DPTs in future.
	6) Much better error handling in the OPC UA Conversion scripts.
	7) Copying of a Server's generated certificate to the OPC UA Client
	certificate repository.
	

16/1/2014 -commited in trunk:
          added functionality concerning the alert handling of noToggle.state
          - in scripts/libs/fwElmb/fwElmb.ctl, the function fwElmb_createNodeAlertHandling()
          Now during the creation of an ELMB node, the alert handling is automaticaly created too.
	    - in panels,   panels/fwElmb/fwElmbNodeManage.pnl updated with a button that applies
          alert handling in the ELMB nodes that do not have it.

17/1/2014 -commited in trunk:
          added functionality concerning the alert handling of _OPCUACANOPENSERVER.State.ConnState
          - in scripts/libs/fwElmb/fwElmb.ctl, the function fwElmb_createUaServerAlertHandling()
	  - in .postinstall, this funciton is called so after the installation of fwElmb the alert
	  will be present


23/1/2014 -commited in trunk:
          - fwElmb_createUaServerAlertHandling() has changed to fwElmb_createOpcServerAlertHandling
          (now it covers the DA case)
	  - added the function fwElmb_createNodesAlertHandling() which creates alert handling for 
	  all ELMB nodes
          - in .postinstall are called the functions
 	  fwElmb_createOpcServerAlertHandling()
          fwElmb_createNodesAlertHandling()


v5.1.0 24-Jan-2014 pnikiel,tsarouch
	Includes all three changes listed above, plus:
	1) .userDefined DPTs are no longer included in the dplists, so no risk of overwriting user data
	2) automatic DA/UA detection done in the postInstall if not previously defined
	3) new functions fwElmb_getMiddlewareKind() and fwElmb_setMiddlewareKind() for handling of DA/UA switch
	4) Address Setup window now features a checkbox that configures Analog Inputs to go through subscriptions
	5) Automatic address resetup using fwDeviceDefinitions is only activated in postInstall when middleware kind is DA
	6) check of OPC alert configuration during conversion script

v5.2.0 8-Apr-2014 pnikiel
	1) By default, emergency objects and disconnected state handling is
	included in the FwElmb (will set invalid bits)
	2) a workaround is provided to imitate writable FwElmbNode.emergency
	3) better error handling when OPC UA config file can't be created
	4) type=ELMB set by default to all empty type ELMB nodes in
	AddressSetup (conversion) panel
	5) AddressSetup panel now defaults subscription to TimeStamps
	6) RTR trigger is now exposed to datapoints (so we can issue RTR
	directly from WCCOA)
	7) Additional options are added to OPC UA conversion dialog window
	- skipping DP if address config is already configured
	- keeping address active state consistent after conversion
	
v5.2.1 6-Jun-2014 pnikiel
	1) Automatic certificate deployment now works fine (but remember:
		at least May2014 version of the OPC UA client is needed for
		that)
	2) check invalid script now respects address active flag for given
	channels (that is, when address is not active, the potentially bad channel
	will not be taken into account for marking ELMB's channelInvalid) 

v5.2.2 18-Jun-2014 pnikiel
	1) address conversion panel: now using subscriptions for calculated
        items is the default choice
	2) checkInvalid mechanisms completely redesigned (e.g. 5.2.1 wouldn't
	nicely work with channels whose names wouldnt contain ELMB channel
	number as suffix) 

v5.2.3 04-Sep-2014 pnikiel
	1) fixed unmeaningful alert texts
	2) added alert for CanBus.portError and to
	Elmb.emergencyWritable.emergencyErrorCode
	3) the default nodetype file now includes AiSDO and SPI items
	4) fwElmb check invalid will now not restart infinitely in OPC-DA
projects

v5.2.4 09-Sep-2014 pnikiel
	1) New mutex mechanism for synchronising DO. The old mechanism had a
	max of 12 ELMB at a time to synchronize, and would fail in really
	massive FSM actions. The current one has no such limitation.

v.5.2.5 09-Oct-2014 pnikiel
	1) Fixed a problem of version 5.2.3 in address setup panel which would
	render SPI addresses incorrect
 
v.5.2.6 28-Oct-2014 pnikiel
	1) now ELMBs' states are monitored not only when entering DISCONNECTED
        but also when leaving DISCONNECTED to any or {PREOP/OP/STOP}. Then it
        is checked whether existing emergency error is that of bootloader,
        which doesnt signal real emergency (it is informative, not an error).
        If it is the case, emergencyWritable is cleared.
        2) Alert handling is much much cleaned from previous implementation.
        3) Alert descriptions for nodes and buses have been corrected to match
        common style e.g. "CIC CanMonitoring UXDET FPIAA5 ELMB_17 state" or so
	4) TPDO2-based AI config is now exposed in the default nodeType.
	(there is no GUI support in FwElmb yet)

v.5.2.7 31-Oct-2014 pnikiel
	1) heavy rework of alert and comments handling for nodes and buses.
	2) the check_invalid manager will now be fully OK when no AI channels
	at all exist on given ELMB

v.5.2.8 02-Dec-2014 pnikiel
 	1) names validation both in OPC UA config file creation and in
	separate panel
	2) added functions to clean power-up related emergency error messages
	and suppressed previous implementation (automatic cleaning)
	3) added fwElmbUtils.ctl library
	4) fixed incorrect listing of buses when name of a bus was a substring
	of another bus
	5) "Address Setup" script will reconfigure Digital Input subscriptions
	for sampling interval of 100 ms

v.5.2.9 20-Jan-2015 pnikiel
	1) fixing bug related to "Raw ADC Value" sensor type in OPC UA address
	config setup and config file generation

v.5.2.10 4-Feb-2015 pnikiel
	1) Fixes setting proper DP description on OPC UA Connection State

v.5.2.11 4-Feb-2015 pnikiel
	1) Fixes a fix from 5.2.10 ;-) 

v.5.2.12 6-Feb-2015 pnikiel
        1) Adds ADC conversion -> invalid bits mapping as an experimental
        feature. Activation requires setting up the OPC UA addresses through
        the panel (with checkbox to use ADC flags checked) and regenration of
        OPC UA Config file (with the flag to use ADC flags checked).
 
v.5.2.13 11-Feb-2015 pnikiel
	1) Every ELMB which has DI configured has a new setting which is
	readoutMethod. It can be either on-sync or on-change. The setting can
	be changed in DI config window. According to the setting:
	- alerts will be configured on DI config elements
	- RTR will be sent when ELMB quits DISCONNECTED state
	- CANopen server config file will have appropriate EXECUTE node to
	  read by RTR on-change configured digital inputs (therefore it is no
	longer necessary to redefine the standard nodetype xml)
	2) FwElmbCheckInvalid script will refresh the configuration of ELMBs
	when started
	3) double dpConnects on .state.value are now avoided by calling
	cbkDOinitialisation from fwElmbUser_monitorStateDisconnectedCbk. This
	should make code cleaner
	4) Alert is installed on TimeoutError of OPC UA connection
	5) Setting element is appended automatically to the config file, to
	be able to enable logging out-of-the-box


v.5.2.14 16-Mar-2015 pnikiel
	1) On OPC UA re-connection settings of ELMBs are requested
	2) On OPC UA connection lost, all channels are (by default)
invalidated (this setting can be changed in _FwElmbGlobal DP)
	3) Due to renaming of "EXECUTE" item into "atStartup" at the CANopen
server 2.1.8-... appropriate change followed 

v.5.2.15 23-Apr-2015 pnikiel
	1) Inside OPC UA address setup, all emergency error-related entities
have INPUT peripheral address instead of IN/OUT previously
	2) Every time FwElmbCheckInvalid.ctl is started, it will attempt to
"guess" DI Readout Method for all ELMBs that have DI configured and their DI
Readout Method has not been set yet.

v.5.2.16 12-Jun-2015 pnikiel
	1) Fixed double space present in comment(DPE description) of DPEs to
which FwElmb adds alarms and comments (e.g. channel invalid). 

v.5.2.17 17-Jun-2015 pnikiel
    1) Fixed minor bug in which some (unjustified) complaints were produced
while creating the config file.

v.5.2.18 08-Sep-2015 pnikiel
	1) fwElmb postInstall appends server= statement into opcua_9 section rather than opcua
	2) running address setup deletes peripheral address from errorPassive (which normally still has OPCDA address as there is no OPCUA counterpart)
	3) New settings for DI subscriptions for no-sampling mode, including sampling interval= 0

v.5.2.19 30-Nov-2015 pnikiel
	1) No more CanTrace attribute in settings element of generated OpcUaCanOpenServer config file -- this is deprecated since server version 2.2.x
	2) Improved (100x more performant) handling mechanism for aggregating invalid bits of channels into channelInvalid ELMB's attribute
	3) Presence of .smooth attribute on FwElmbAi is checked and reported both in postInstall and address configuration. This is known to make stuck invalid bits in FwElmb-based projects

v.5.2.20 04-Dec-2015 pnikiel
	1) Device definitions for OPC UA - still not 100% perfect but OK in 95% ;-)
	
v.5.2.21 18-Jan-2016 pnikiel
	1) postInstall script fix for bug in getMiddlewareKind() function
	2) Now JCOP Framework 5.2.0+ is required because of OPC UA Device Definitions

v.5.3.0  21-Mar-2016 pnikiel     OPC-UA only release
Task
    [OPCUA-37] - Upgrade of fwElmb for OPC UA addressing - Phase2: OPC-UA only
    [OPCUA-586] - Drop polling support for OPC-UA


v.5.3.1  08-Apr-2016 pnikiel
Bug

    [OPCUA-590] - Support ELMB Port C as input (currently only output)
    [OPCUA-593] - Errors in some device definitions for FwElmb
    [OPCUA-596] - Exception when creating a digital output

Task
    [OPCUA-585] - Drop automatic NTC formula update because it ignores pre-resistance
    [OPCUA-589] - Still some remains of OPC-DA in fwElmbDriver.dpl

v.5.3.2 11-Apr-2016 pnikiel
Task
    [OPCUA-597] - Some details to iron-out for OPC-UA only fwElmb

v.5.3.3 02-Sep-2016 pnikiel
Task
    [OPCUA-648] - fwElmbUtils_stateValueToText function

v.5.3.4 11-Nov-2016 pnikiel
Bug
    [OPCUA-703] - Few address configs missing in fwElmb

Task
    [OPCUA-702] - Add number of emergencies DPE to FwElmbNode (with appropriate address config and address setup script routine)

v.8.0.0 11-Nov-2016 pnikiel
No changes wrt 5.3.3, only retagged to follow JCOP Framework 8.x.x versioning convention (for WinCC OA 3.15)

v.8.0.1 16-Dec-2016 pnikiel
Bug
    [OPCUA-712] - Extra check required for dpSubStr in fwElmbUtils_get*** functions

v.8.0.2 10-Aug-2017 pnikiel
Task
    [OPCUA-863] - fwElmb to support high port number (48010)

v.8.0.3 30-Aug-2017 pnikiel
Bug

    [OPCUA-749] - ADC Range setting misinterpreted in the AI config window?

Task

    [OPCUA-774] - Check dp_fct for evaluation of ELMB AI Config or possibly eradicate it

v.8.0.4 02-May-2018 pnikiel
Task

    [OPCUA-867] - Integrate TPDO2-based analog readout configuration to fwElmb
    [OPCUA-1047] - severe messages during installation of fwElmb

Improvement

    [OPCUA-1040] - support attaching custom, user's formulas into fwElmb generated config file

v.8.3.1 25-Oct-2019 pnikiel
Task

    [OPCUA-1116] - fwElmb: abandon config files for server= entry, move to dps

v.8.4.0 25-Feb-2020 pnikiel
Task
[OPCUA-1685] - Validate fwElmb against framework 8.4.0
[OPCUA-1729] - fwElmb.ctl to include everything else (fwElmbUser, fwElmbConstants, ...)
