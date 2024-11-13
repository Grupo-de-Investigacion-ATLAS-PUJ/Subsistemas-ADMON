//  @Author: Fernando Varela Rodriguez
//  @Date: 18th of March, 2004
//  @Description:
//
//  This library provides functions that may be used in user panels and scripts
//  to create CAN buses, ELMBs and inputs and outputs. Some utility functions
//  are also provided.
//
//  @Limitations: None
//  @Bugs and fixes: Fernando.Varela.Rodriguez@cern.ch.
//
// User functions:  fwElmbUser_checkDefaultDriver
//                  fwElmbUser_checkStateOperational
//                  fwElmbUser_createCANbus
//                  fwElmbUser_createElmb
//                  fwElmbUser_createSensor
//                  fwElmbUser_createAnalogOutput
//                  fwElmbUser_createDigital
//                  fwElmbUser_createSPI
//                  fwElmbUser_createOPCFile
//                  fwElmbUser_readSPIValue
//                  fwElmbUser_monitorAll
//                  fwElmbUser_monitorElmb
//                  fwElmbUser_monitorOpc
//                  fwElmbUser_setDoBit
//                  fwElmbUser_setDoBits
//                  fwElmbUser_setDoByte
//                  fwElmbUser_setDoBytes
//                  fwElmbUser_getDoByte
//                  fwElmbUser_getDoBytes
//                  fwElmbUser_synchronizeDoBytes
//                  fwElmbUser_updateFirmwareInfo

//*****************************************************************************
// @name Function: fwElmbUser_checkDefaultDriver
//
// Checks whether the driver (OPC Client) or simulator with the correct number
// is running for the ELMB component
//
// @param argiDriverNumber:   The default driver number for the ELMB is returned
//                            here
// @param argdsExceptionInfo: Exception handler information returned here
// @param argsDpTypeName:     A datapoint type name may be given here, otherwise
//                            the CANbus type is used by default
// @param argsSystemName:     Optional system name if checking a remote system
//
// Modification History: None
//
// Constraints:
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************

#uses "CtrlXml"
#uses "fwElmb/fwElmbUtils.ctl"
#uses "fwGeneral/fwGeneral.ctl"
#uses "fwElmb/fwElmb.ctl"
#uses "fwDevice/fwDevice.ctl"
#uses "fwGeneral/fwException.ctl"
#uses "fwElmb/fwElmbMonitorLib.ctl"
#uses "fwConfigs/fwAlertConfig.ctl"
#uses "fwConfigs/fwPeriphAddress.ctl"


global int g_fwElmbUserSetting_useBusNameInSubscription=-1; //-1 not set, 0 no, 1 yes

bool fwElmbUser_checkDefaultDriver(int &argiDriverNumber,
                                   dyn_string &argdsExceptionInfo,
                                   string argsDpTypeName = ELMB_CAN_BUS_TYPE_NAME,
                                   string argsSystemName = "")
{
// Local Variables
// ---------------
  bool bIsRunning = false;

  dyn_string dsAddressParameters;

// Executable Code
// ---------------
  // Just to make sure that everything is properly
  // initialized even if the function is not called from the FW
  fwDevice_initialize();

  // Initialise driver number return value
  argiDriverNumber = 0;

  // Check is DPT given (this allows the default driver number to be found)
  if (strlen(argsDpTypeName) == 0)
    argsDpTypeName = ELMB_CAN_BUS_TYPE_NAME;

  // Check if a system name is given, if not, default to local system
  if (strlen(argsSystemName) == 0)
    argsSystemName = getSystemName();

  // Get address parameters to obtain driver number used
  fwDevice_getAddressDefaultParamsOPCUA(argsDpTypeName,
                                      dsAddressParameters,
                                      argdsExceptionInfo);

  if (dynlen(argdsExceptionInfo) > 0) {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_checkDefaultDriver(): Problem reading the\ndefault OPC address parameters. Aborting action...",
                      "");
  } else {
    // Set driver number return value
    argiDriverNumber = dsAddressParameters[fwDevice_ADDRESS_DRIVER_NUMBER];

    // Check driver is running
    fwPeriphAddress_checkIsDriverRunning(argiDriverNumber,
                                         bIsRunning,
                                         argdsExceptionInfo,
                                         argsSystemName);
  }

  // Return to calling routine
  return (bIsRunning);
}

//*****************************************************************************
// @name Function: fwElmbUser_checkStateOperational
//
// Checks whether the ELMB specified is in the operational state or not.
//
// @param argsElmb: DP name of ELMB to check
// @param argdsExceptionInfo: Exception handler information returned here
//
// Modification History: None
//
// Constraints:
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
bool fwElmbUser_checkStateOperational(string argsElmb,
                                      dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  bool bIsOperational = false;

  unsigned uState;

//  string sNgDpe;

//  dyn_string dsTemp;

// Executable Code
// ---------------
  // Ensure system name given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Get the datapoint name of the associated bus
  /* JRC not implemented yet. This should check that last update was within nodeguardinterval
  dsTemp = strsplit(argsElmb, fwDevice_HIERARCHY_SEPARATOR);
  if (dynlen(dsTemp) == 3)
    sNgDpe = dsTemp[1] + fwDevice_HIERARCHY_SEPARATOR + dsTemp[2] + ".nodeGuardInterval";
    */

  // Get required values
  dpGet(argsElmb + ".state.value", uState);
  if ((uState & 0x7f) == 5)
    bIsOperational = true;

  // Return to calling routine
  return (bIsOperational);
}

//*****************************************************************************
// @name Function: fwElmbUser_createCANbus
//
// Creates a CANbus datapoint ands sets various parts of the required
// information to the datapoint elements
//
// @param argsUserName: Name (string) of bus to create, not including system
//                      name or any framework hierarchy information
// @param argsComment: Any comment to be applied to the datapoint
// @param argsPort: Port identifier (string). Must include 'can' prefix for
//                  National Intruments ports.
// @param argsCard: Name of card interface (string). There are constants
//                  defined in the file fwElmbConstants.ctl for:
//                    Kvaser card - ELMB_CAN_CARD_KVASER
//                    NICAN card - ELMB_CAN_CARD_NICAN
// @param argiBusSpeed: Bus speed (integer) in bits/s
// @param argbDefaultAddressing: True is default OPC addressing should be applied
// @param argdsExceptionInfo: Exception handler information returned here
//
// Modification History: None
//
// Constraints:
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Fernando Varela
// @author Piotr Nikiel
//*****************************************************************************
fwElmbUser_createCANbus(string argsUserName,
                        string argsComment,
                        string argsPort,
                        string argsCard,
                        int argiBusSpeed,
                        bool argbDefaultAddressing,
                        dyn_string &argdsExceptionInfo)
{

//To be done:  1- Check if card info is correct, i.e. if the can card and port are free

// Local Variables
// ---------------
  int i;
  int iManagement = 0;
  int iSyncInterval = 0;
  int iNodeGuardInterval = 0;
  int isRunning;

  string sDpName;

  dyn_string dsAvailablePortListKVASER, dsAvailablePortListNICAN;
  dyn_string dsAddressParameters;

// Executable Code
// ---------------
  // Just to make sure that everything is properly
  // initialized even if the function is not called from the FW
  fwDevice_initialize();

   // Warning for empty user name field
   if ((argsUserName == "")) {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "Empty or invalid CANbus name. Aborting action...",
                      "");
    return;
  }

  // Get a FW complient DP name from the User Name
  fwElmb_getFwName(argsUserName, VENDOR_NAME, sDpName);

  // Create CAN bus
  fwElmb_createCANbus(sDpName,
                      argdsExceptionInfo);
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  // If we have arrived to this point, it means no error => Right moment to set
  // the values to the dpe in the CANbus structure
  fwElmb_setValuesToCANbus(sDpName,
                           argsComment,
                           argsPort,
                           argsCard,
                           argiBusSpeed,
                           iManagement,
                           iSyncInterval,
                           iNodeGuardInterval,
                           argdsExceptionInfo);

  // Check if exception has been raised:
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  // Now we want to create the dps for the OPC groups that are required
  fwElmb_createOpcUaSubscription(ELMB_CAN_BUS_TYPE_NAME, argsUserName, argdsExceptionInfo);
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  // If default OPC addressing selected -> address items
  if (argbDefaultAddressing)
    fwDevice_setAddress(sDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  // Initialise the monitoring information
  fwElmbMonitorLib_setupMonitor(sDpName);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_createElmb
//
// Creates a ELMB node data-point, from the information provided in the
// arguments
//
// @param argsUserName: Name (string) of ELMB node to create, not including
//                      system name or any framework hierarchy information
// @param argsComment: Any comment to be applied to the datapoint
// @param argsBusName: Name of the CANbus this ELMB is connected to. System
//                      name and framework hierarchy information is optional
// @param argsNodeID:  Value (string) containing the nodeId in decimal
// @param argbDefaultAddressing: True is default OPC addressing should be applied
// @param argdsExceptionInfo: Exception handler information returned here
//
// Modification History: None
//
// Constraints:
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Fernando Varela
//*****************************************************************************
fwElmbUser_createElmb(string argsUserName,
                      string argsComment,
                      string argsBusName,
                      string argsNodeID,
                      bool argbDefaultAddressing,
                      dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  bool isRunning;

  int iManagement;

  string sDpName;

  dyn_string dsAddressParameters;

// Executable Code
// ---------------
  // Makes sure function works if it is not called from the FwDEN
  fwDevice_initialize();

  if ((argsUserName == "") || (argsNodeID == ""))
    return;

  // Check if bus name contains any hierarchy information
  if (patternMatch("*" + VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR + "*", argsBusName)) {
    // Framework hierarchy information is included, remove system name if given
    argsBusName = dpSubStr(argsBusName, DPSUB_DP);
  } else {
    // Framework hierarchy information NOT included (therefore system name cannot be there)
    argsBusName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR + argsBusName;
  }

  // Get a FW complient DP name from the User Name
  fwElmb_getFwName(argsUserName, argsBusName, sDpName);

  // Check DPT is of correct type and create DP
  fwElmb_createNode(sDpName, argdsExceptionInfo);

  // Check for any errors
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  //We have arrived to this point? Right moment to set values to the ELMB dpes
  fwElmb_setValuesToElmb(sDpName,
                         argsComment,
                         argsNodeID,
                         argdsExceptionInfo);
  // Check for any errors
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  // new OPC addressing code
  if (argbDefaultAddressing)
    fwDevice_setAddress(sDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  // Initialise the monitoring information
  fwElmbMonitorLib_setupMonitor(sDpName);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_createSensor
//
// Creates an analog input sensor data-point from the information provided in
// the arguments. The actual name of the datapoint created is given as a return
// to the function if successful.
//
// @param argsUserName: Name (string) of sensor to create, not including
//                      system name or any framework hierarchy information
// @param argsBusName: Name (string) of CANbus the ELMB to which the sensor
//                      should be created is connected to. System name and
//                      framework hierarchy information is optional
// @param argsElmbName: Name of the ELMB this sensor will be connected to.
//                      System name and framework hierarchy information is
//                      optional
// @param argsComment: Comment for the sensor
// @param argdsChannelNumber: List of channel numbers used by this sensor
// @param argssSensorType: Name of the sensor type as set in the Sensor Info
//                          datapoint
// @param argdfParameters: List of parameter values (i.e. these will replace
//                          the markers %x1, ..., %xn that are defined in the
//                          formula for the sensor type). If no parameters are
//                          given, but the formula needs them, the default values
//                          defined for the sensor are used.
// @param argbDefaultAddressing: True is default OPC addressing is to be applied
// @param argdsExceptionInfo: Exception handler information returned here
// @param argsFctTemplate: [Optional] Sensor function template (e.g. %c1+3.5/%x1).
//                          Only required if formula defined in Sensor Info
//                          datapoint for this type is to be over-ridden
// @param argsOpcItem: [Optional] Name of the OPC item corresponding to this
//                      sensor. Only needed if default OPC item should be
//                      over-ridden.
//
// Modification History: None
//
// Constraints:
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Fernando Varela
//*****************************************************************************
string fwElmbUser_createSensor(string argsUserName,
                               string argsBusName,
                               string argsElmbName,
                               string argsComment,
                               dyn_string argdsChannelNumber,
                               string argsSensorType,
                               dyn_float argdfParameters,
                               bool argbDefaultAddressing,
                               dyn_string &argdsExceptionInfo,
                               string argsFctTemplate = "",
                               string argsOpcItem = "")
{
// Local Variables
// ---------------
  int i, j;
  int iPos;

  string sElmbName;
  string sSensorName = "";
  string sConfigName;
  string sOpcItemName;
  string sFct;
  string sFctTemplate;
  string sSensorPrefix;
  string sProfile;
  string sParameters;

  dyn_bool dbIsRaw;

  dyn_string dsChannelOpcItems;
  dyn_string dsAddressParameters;
  dyn_string dsSensorTypes;
  dyn_string dsFunctionTemplate;
  dyn_string dsPDOdps;
  dyn_string dsTemp;

// Executable Code
// ---------------
  // Makes sure it works even if not called from the FwDEN
  fwDevice_initialize();

  // Remove any system name and/or framework hierarchy information from the bus
  dsTemp = strsplit(argsBusName, fwDevice_HIERARCHY_SEPARATOR);
  argsBusName = dsTemp[dynlen(dsTemp)];

  // Remove any system name and/or framework hierarchy information from the ELMB
  dsTemp = strsplit(argsElmbName, fwDevice_HIERARCHY_SEPARATOR);
  argsElmbName = dsTemp[dynlen(dsTemp)];

  // Build up ELMB name
  sElmbName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR +
              argsBusName + fwDevice_HIERARCHY_SEPARATOR +
              argsElmbName;

  // Create OPC item name, first checking if item has been given
  if (argsOpcItem == "") {
    // Use same name as user name for item
    sOpcItemName = argsBusName + OPC_DELIMETER + argsElmbName + OPC_DELIMETER + argsUserName;
  } else {
    // Use item name given
    sOpcItemName = argsBusName + OPC_DELIMETER + argsElmbName + OPC_DELIMETER + argsOpcItem;
  }

  // Check for a raw value sensor
  dpGet(ELMB_SENSOR_INFO_NAME + ".types", dsSensorTypes,
        ELMB_SENSOR_INFO_NAME + ".isRaw", dbIsRaw,
        ELMB_SENSOR_INFO_NAME + ".pdoDp", dsPDOdps);

  // Find the index of this sensor type
  iPos = dynContains(dsSensorTypes, argsSensorType);
  if (iPos <= 0)
    return ("");

  if (dbIsRaw[iPos]) {
    sFct = ELMB_NO_INFO;
  } else {
    // Check whether sensor uses custom PDO and get prefix if so
    if (dsPDOdps[iPos] == ELMB_NO_INFO) {
      sSensorPrefix = ELMB_AI_PREFIX;
      sProfile = "404";
    } else {
      dpGet(dsPDOdps[iPos] + ".name", sSensorPrefix,
            dsPDOdps[iPos] + ".profile", sProfile);
    }

    // Set the input channels
    if ((sProfile == "404") || (sProfile == "LMB")) {
      for(i = 1; i <= dynlen(argdsChannelNumber); i++) {
        dsChannelOpcItems[i] =   argsBusName + OPC_DELIMETER +
                                argsElmbName + OPC_DELIMETER +
                                sSensorPrefix + argdsChannelNumber[i];
      }
    } else {
      // Channel number does not apply
      dsChannelOpcItems = makeDynString(argsBusName + OPC_DELIMETER +
                                        argsElmbName + OPC_DELIMETER +
                                        sSensorPrefix);
    }

    // Check if a function template has been given
    if (argsFctTemplate == "") {
      // Get information from internal DP
      dpGet(ELMB_SENSOR_INFO_NAME + ".functions", dsFunctionTemplate);

      // Set the template to use
      sFctTemplate = dsFunctionTemplate[iPos];
    } else {
      sFctTemplate = argsFctTemplate;
    }

    // Check if parameters have been given, and if not, get defaults from
    // sensor definition
    if (dynlen(argdfParameters) == 0) {
      dpGet(ELMB_SENSOR_INFO_NAME + ".parameters", dsTemp);
      if (dsTemp[iPos] == ELMB_NO_INFO)
        dynClear(argdfParameters);
      else
        fwGeneral_stringToDynString(dsTemp[iPos], argdfParameters);
    }

    // Create the required function
    fwElmb_getUserDefinedFct(sFctTemplate,
                             dsChannelOpcItems,
                             argdfParameters,
                             sFct,
                             argdsExceptionInfo);

    if (dynlen(argdsExceptionInfo) > 0)
      return ("");

    sFct = sOpcItemName + " = " + sFct;
  }

  //Check if the config for that channel already exists.
  sConfigName = sElmbName + fwDevice_HIERARCHY_SEPARATOR + ELMB_AI_CONFIG_NAME;
  if (!dpExists(sConfigName + ".")) {
    fwElmb_createConfig(sConfigName,
                        ELMB_AI_CONFIG_TYPE_NAME,
                        argdsExceptionInfo);

    if (dynlen(argdsExceptionInfo) > 0)
      return ("");

    // Set OPC address
     if (argbDefaultAddressing)
    fwDevice_setAddress(sConfigName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  //Build up the sensor name from the config name
  sSensorName = sConfigName + fwDevice_HIERARCHY_SEPARATOR + argsUserName;

  fwElmb_createChannel(sSensorName,
                       argsComment,
                       ELMB_AI_TYPE_NAME,
                       argsSensorType,
                       argdsChannelNumber,
                       sFct,
                       argdsExceptionInfo);

  // Check for errors
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Create any OPC group(s) necessary
  fwElmb_createOpcUaSubscription(ELMB_AI_TYPE_NAME, argsBusName, argdsExceptionInfo);

  if (argbDefaultAddressing)
    fwDevice_setAddress(sSensorName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  // Return to calling routine
  return (sSensorName);
}

//*****************************************************************************
// @name Function: fwElmbUser_createAnalogInputSDO
//
// Creates an analog input for SDO for an existing Elmb. The actual name of
// the datapoint created is given as a return to the function if successful.
//
// @param argsBusName: Name of bus (string) that Elmb is connected to. System
//                      name and framework hierarchy information is optional
// @param argsElmbName: Name of Elmb (string) to create analog input on. System
//                      name and framework hierarchy information is optional
// @param argsComment: Comment (string) for the analog input
// @param argiChannel: Channel number (int) for the analog input
// @param argbOPCAddressing: Should default OPC addressing be configured
// @param argdsExceptionInfo: Any exceptions are returned here
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
string fwElmbUser_createAnalogInputSDO(string argsBusName,
                                       string argsElmbName,
                                       string argsComment,
                                       int argiChannel,
                                       bool argbOPCAddressing,
                                       dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sElmbName;
  string sChannelName;
  string sConfigDpName;

  dyn_string dsIds;
  dyn_string dsTemp;

// Executable Code
// ---------------
  // Makes sure it works even if not called from the FwDEN
  fwDevice_initialize();

  // Remove any system name and/or framework hierarchy information from the bus
  dsTemp = strsplit(argsBusName, fwDevice_HIERARCHY_SEPARATOR);
  argsBusName = dsTemp[dynlen(dsTemp)];

  // Remove any system name and/or framework hierarchy information from the ELMB
  dsTemp = strsplit(argsElmbName, fwDevice_HIERARCHY_SEPARATOR);
  argsElmbName = dsTemp[dynlen(dsTemp)];

  // Check channel value is valid
  if ((argiChannel < 0) || (argiChannel >= ELMB_MAX_CHANNEL)) {
    // Raise an exception
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createAnalogInputSDO(): Channel \"" + argiChannel + "\" is an invalid value",
                      "");
    return ("");
  }

  // Build up ELMB name
  sElmbName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR +
              argsBusName + fwDevice_HIERARCHY_SEPARATOR +
              argsElmbName;

  // Set the ID
  dsIds = makeDynString(argiChannel);

  fwElmb_getChannelName(ELMB_AI_SDO_PREFIX + argiChannel,
                        sElmbName,
                        ELMB_AI_SDO_TYPE_NAME,
                        sChannelName,
                        argdsExceptionInfo);

  // Check for success
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Before creating the sensor we have to look if the config for that channel already exists.
  sConfigDpName = sElmbName + fwDevice_HIERARCHY_SEPARATOR + ELMB_AI_CONFIG_NAME;
  if (!dpExists(sConfigDpName + ".")) {
    fwElmb_createConfig(sConfigDpName,
                        ELMB_AI_CONFIG_TYPE_NAME,
                        argdsExceptionInfo);
    if (dynlen(argdsExceptionInfo) > 0)
      return ("");

    // OPC addressing code
    if (argbOPCAddressing)
      fwDevice_setAddress(sConfigDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  // Create the digital line
  fwElmb_createChannel(sChannelName,
                       argsComment,
                       ELMB_AI_SDO_TYPE_NAME,
                       "",
                       dsIds,
                       "",
                       argdsExceptionInfo);

  // Check for errors
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Create any OPC group(s) necessary
  fwElmb_createOpcUaSubscription(ELMB_AI_SDO_TYPE_NAME, argsBusName, argdsExceptionInfo);

  // Check for whether to apply OPC addressing
  if (argbOPCAddressing)
    fwDevice_setAddress(sChannelName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  // Return to calling routine
  return (sChannelName);
}

//*****************************************************************************
// @name Function: fwElmbUser_createDigital
//
// Creates a digital input or output for an existing Elmb. The actual name of
// the datapoint created is given as a return to the function if successful.
//
// @param argsBusName: Name of bus (string) that Elmb is connected to. System
//                      name and framework hierarchy information is optional
// @param argsElmbName: Name of Elmb (string) to create digital line on. System
//                      name and framework hierarchy information is optional
// @param argsComment: Comment (string) for the digital line
// @param argsPort: Port letter (string) for the digital line
// @param argiBit: Bit number (int) in the digital byte (port)
// @param argbDigitalInput: True of digital input to be created,
//                          False to create digital output
// @param argbOPCAddressing: Should default OPC addressing be configured
// @param argdsExceptionInfo: Any exceptions are returned here
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
string fwElmbUser_createDigital(string argsBusName,
                                string argsElmbName,
                                string argsComment,
                                string argsPort,
                                int argiBit,
                                bool argbDigitalInput,
                                bool argbOPCAddressing,
                                dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  bool bStatus = false;
  bool bActivate;

  string sDigitalTypeName;
  string sDigitalConfigName;
  string sDigitalConfigTypeName;
  string sElmbName;
  string sSensorName;
  string sChannelName;
  string sConfigDpName;

  dyn_string dsIds;
  dyn_string dsAddressParameters;
  dyn_string dsTemp;

// Executable Code
// ---------------
  // Makes sure it works even if not called from the FwDEN
  fwDevice_initialize();

  // Remove any system name and/or framework hierarchy information from the bus
  dsTemp = strsplit(argsBusName, fwDevice_HIERARCHY_SEPARATOR);
  argsBusName = dsTemp[dynlen(dsTemp)];

  // Remove any system name and/or framework hierarchy information from the ELMB
  dsTemp = strsplit(argsElmbName, fwDevice_HIERARCHY_SEPARATOR);
  argsElmbName = dsTemp[dynlen(dsTemp)];

  // Check for digital input or output
  if (argbDigitalInput) {
    sDigitalTypeName = ELMB_DI_TYPE_NAME;
    sDigitalConfigName = ELMB_DI_CONFIG_NAME;
    sDigitalConfigTypeName = ELMB_DI_CONFIG_TYPE_NAME;

    // Check the port is correct for input
    if ((argsPort != "F") && (argsPort != "A") && (argsPort != "D") && (argsPort != "E") && (argsPort != "C")) {
      // Raise an exception
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "fwElmbUser_createDigital(): Port \"" + argsPort + "\" is not an input port",
                        "");
    } else {
      // Create sensor name
      sSensorName = ELMB_DI_PREFIX + argsPort + "_" + argiBit;
    }
  } else {
    sDigitalTypeName = ELMB_DO_TYPE_NAME;
    sDigitalConfigName = ELMB_DO_CONFIG_NAME;
    sDigitalConfigTypeName = ELMB_DO_CONFIG_TYPE_NAME;

    // Check the port is correct for output
    if ((argsPort != "C") && (argsPort != "A")) {
      // Raise an exception
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "fwElmbUser_createDigital(): Port \"" + argsPort + "\" is not an output port",
                        "");
    } else {
      // Create sensor name
      sSensorName = ELMB_DO_PREFIX + argsPort + "_" + argiBit;
    }
  }

  // Check for exceptions
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Check bit value is valid
  if ((argiBit < 0) || (argiBit > 7)) {
    // Raise an exception
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createDigital(): Bit \"" + argiBit + "\" is an invalid value",
                      "");
    return ("");
  }

  // Build up ELMB name
  sElmbName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR +
              argsBusName + fwDevice_HIERARCHY_SEPARATOR +
              argsElmbName;

  // Set the ID
  dsIds = makeDynString(argsPort + ";" + argiBit);

  fwElmb_getChannelName(sSensorName,
                        sElmbName,
                        sDigitalTypeName,
                        sChannelName,
                        argdsExceptionInfo);

  // Check for success
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Before creating the sensor we have to look if the config for that channel already exists.
  sConfigDpName = sElmbName + fwDevice_HIERARCHY_SEPARATOR + sDigitalConfigName;
  if (!dpExists(sConfigDpName + ".")) {
    fwElmb_createConfig(sConfigDpName,
                        sDigitalConfigTypeName,
                        argdsExceptionInfo);
    if (dynlen(argdsExceptionInfo) > 0)
      return ("");

    // OPC addressing code
    if (argbOPCAddressing)
      fwDevice_setAddress(sConfigDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  // Create the digital line
  fwElmb_createChannel(sChannelName,
                       argsComment,
                       sDigitalTypeName,
                       "",
                       dsIds,
                       "",
                       argdsExceptionInfo);

  // Check for errors
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Create any OPC group(s) necessary
  fwElmb_createOpcUaSubscription(sDigitalTypeName, argsBusName, argdsExceptionInfo);

  // Digital outputs need some special handling to be able to read the digital outputs
  // for hardware/software consistency
  if (sDigitalTypeName == ELMB_DO_TYPE_NAME) {

    fwElmb_createDigitalBytes(sElmbName, argbOPCAddressing, argdsExceptionInfo);

  } else if (argbOPCAddressing) {
    fwDevice_setAddress(sChannelName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  if (sDigitalTypeName == ELMB_DI_TYPE_NAME)
  {
    // TODO: (pnikiel) This is probably very redundant. Address should be already active.
    fwElmb_activatePortAMasks(sElmbName, argdsExceptionInfo, true);
  }

  // Return to calling routine
  return (sChannelName);
}

//*****************************************************************************
// @name Function: fwElmbUser_createAnalogOutput
//
// Creates an analog output for an existing Elmb. The actual name of
// the datapoint created is given as a return to the function if successful.
//
// @param argsBusName: Name of bus (string) that Elmb is connected to. System
//                      name and framework hierarchy information is optional
// @param argsElmbName: Name of Elmb (string) to create analog output on. System
//                      name and framework hierarchy information is optional
// @param argsComment: Comment (string) for the analog output
// @param argiChannel: Channel number (int) for the analog output
// @param argbOPCAddressing: Should default OPC addressing be configured
// @param argdsExceptionInfo: Any exceptions are returned here
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
string fwElmbUser_createAnalogOutput(string argsBusName,
                                     string argsElmbName,
                                     string argsComment,
                                     int argiChannel,
                                     bool argbOPCAddressing,
                                     dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sElmbName;
  string sChannelName;
  string sConfigDpName;

  dyn_string dsIds;
  dyn_string dsTemp;

// Executable Code
// ---------------
  // Makes sure it works even if not called from the FwDEN
  fwDevice_initialize();

  // Remove any system name and/or framework hierarchy information from the bus
  dsTemp = strsplit(argsBusName, fwDevice_HIERARCHY_SEPARATOR);
  argsBusName = dsTemp[dynlen(dsTemp)];

  // Remove any system name and/or framework hierarchy information from the ELMB
  dsTemp = strsplit(argsElmbName, fwDevice_HIERARCHY_SEPARATOR);
  argsElmbName = dsTemp[dynlen(dsTemp)];

  // Check channel value is valid
  if ((argiChannel < 0) || (argiChannel >= ELMB_MAX_CHANNEL)) {
    // Raise an exception
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createAnalogOutput(): Channel \"" + argiChannel + "\" is an invalid value",
                      "");
    return ("");
  }

  // Build up ELMB name
  sElmbName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR +
              argsBusName + fwDevice_HIERARCHY_SEPARATOR +
              argsElmbName;

  // Set the ID
  dsIds = makeDynString(argiChannel);

  fwElmb_getChannelName(ELMB_AO_PREFIX + argiChannel,
                        sElmbName,
                        ELMB_AO_TYPE_NAME,
                        sChannelName,
                        argdsExceptionInfo);

  // Check for success
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Before creating the sensor we have to look if the config for that channel already exists.
  sConfigDpName = sElmbName + fwDevice_HIERARCHY_SEPARATOR + ELMB_AO_CONFIG_NAME;
  if (!dpExists(sConfigDpName + ".")) {
    fwElmb_createConfig(sConfigDpName,
                        ELMB_AO_CONFIG_TYPE_NAME,
                        argdsExceptionInfo);
    if (dynlen(argdsExceptionInfo) > 0)
      return ("");

    // OPC addressing code
    if (argbOPCAddressing)
      fwDevice_setAddress(sConfigDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  // Create the digital line
  fwElmb_createChannel(sChannelName,
                       argsComment,
                       ELMB_AO_TYPE_NAME,
                       "",
                       dsIds,
                       "",
                       argdsExceptionInfo);

  // Check for errors
  if (dynlen(argdsExceptionInfo) > 0)
    return ("");

  // Create any OPC group(s) necessary
  fwElmb_createOpcUaSubscription(ELMB_AO_TYPE_NAME, argsBusName, argdsExceptionInfo);

  // Check for whether to apply OPC addressing
  if (argbOPCAddressing)
    fwDevice_setAddress(sChannelName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  // Return to calling routine
  return (sChannelName);
}

//*****************************************************************************
// @name Function: fwElmbUser_createSPI
//
// Creates SPI comunication information for an existing Elmb. The actual name of
// the datapoint created is given as a return to the function if successful.
//
// @param argsBusName: Name of bus (string) that Elmb is connected to. System
//                      name and framework hierarchy information is optional
// @param argsElmbName: Name of Elmb (string) to create digital line on. System
//                      name and framework hierarchy information is optional
// @param argsComment: Comment (string) for the digital line
// @param argbOPCAddressing: Should default OPC addressing be configured
// @param argdsExceptionInfo: Any exceptions are returned here
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
string fwElmbUser_createSPI(string argsBusName,
                            string argsElmbName,
                            string argsComment,
                            bool argbOPCAddressing,
                            dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  bool bStatus = false;

  string sDpName;

  dyn_string dsAddressParameters;
  dyn_string dsTemp;

// Executable Code
// ---------------
  // Makes sure it works even if not called from the FwDEN
  fwDevice_initialize();

  // Remove any system name and/or framework hierarchy information from the bus
  dsTemp = strsplit(argsBusName, fwDevice_HIERARCHY_SEPARATOR);
  argsBusName = dsTemp[dynlen(dsTemp)];

  // Remove any system name and/or framework hierarchy information from the ELMB
  dsTemp = strsplit(argsElmbName, fwDevice_HIERARCHY_SEPARATOR);
  argsElmbName = dsTemp[dynlen(dsTemp)];

  // Build up DP name
  sDpName = VENDOR_NAME + fwDevice_HIERARCHY_SEPARATOR +
            argsBusName + fwDevice_HIERARCHY_SEPARATOR +
            argsElmbName + fwDevice_HIERARCHY_SEPARATOR +
            ELMB_SPI_CONFIG_NAME;

  // Create the SPI configuration/operation DP
  dpCreate(sDpName, ELMB_SPI_TYPE_NAME);

  // OPC addressing code
  if (argbOPCAddressing)
    fwDevice_setAddress(sDpName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);

  if (!patternMatch("*.*", sDpName) || !patternMatch("*.", sDpName))
    dpSetComment(sDpName + ".", argsComment);
  else
    dpSetComment(sDpName, argsComment);

  // Return to calling routine
  return (sDpName);
}

//*****************************************************************************
//@name Function: fwElmbUser_createOPCuaXMLFile
//
//Creates XML configuration file for OPC UA server
//
// @param argdsBuses: DP names of buses (dyn_string) that should have
//                    configuration information in file
// @param argsFilename: Name of file (string) including path, to be created
// @param argbUseNodeGuarding: Should node guard flags be used
// @param argAdcStatus: whether to use new OPC UA feature of mapping ELMB ADC status into invalids
// @param argdsExceptionInfo: Any exceptions are returned here
//
//Contact: atlas-dcs@cern.ch
//*****************************************************************************
void fwElmbUser_createOPCuaXMLFile(dyn_string argdsBuses,
                                   string argsFilename,
                                   bool argbUseNodeGuarding,
                                   string card,
                                   bool argAdcStatus,
                                   dyn_string &argdsExceptionInfo)
{
  // Check if information is valid
  if (dynlen(argdsBuses) == 0) {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createOPCuaXMLFile(): No buses given",
                      "");
    return;
  } else if (strlen(argsFilename) == 0) {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createOPCuaXMLFile(): Filename given is invalid",
                      "");
    return;
  }

  //Update CAN interface info
  for(int i = 1; i <= dynlen(argdsBuses); i++){
    dpSet(argdsBuses[i] + ".id",card);
  }

  int docNum = xmlNewDocument();
  //Header
  int node = xmlAppendChild(docNum,-1, XML_PROCESSING_INSTRUCTION_NODE,"xml version=\"1.0\" encoding=\"UTF-8\"");
  xmlAppendChild(docNum, -1, XML_COMMENT_NODE, "ELMB OPC UA configuration file");
  time t = getCurrentTime();
  string sTime = (string)t;
  xmlAppendChild(docNum, -1, XML_COMMENT_NODE, "Generated for system " + getSystemName() + " at " + sTime);
  string fwConfigPath = getPath(CONFIG_REL_PATH,"fwElmb/");
  string userConfigPath = getPath(CONFIG_REL_PATH,"userElmbDef/");



  node = xmlAppendChild(docNum, -1, XML_ELEMENT_NODE, "CanOpenOpcServerConfig");
  string xsdPath;
  if (_UNIX)
      xsdPath="/opt/OpcUaCanOpenServer/bin/";
  else
    xsdPath="C:/Program Files/OpcUaCanOpenServer/bin/"; // TODO -- location of CanOpenOPC installation path is not yet known
  xmlSetElementAttribute(docNum, node, "xsi:noNamespaceSchemaLocation", xsdPath+"CANOpenServerConfig.xsd");
  xmlSetElementAttribute(docNum, node, "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");



 //log Info
  string generalLogLevel="WRN";
  dyn_string components=makeDynString("PdoMessage","SdoMessage","SegSdoMessage","NGMessage","EmergMessage","NMTMessage","CanTrace","Pdo1Message","Pdo2Message","Pdo3Message","Pdo4Message");
  dyn_string componentLogLevel=makeDynString("WRN",       "WRN",          "WRN",      "WRN",         "WRN",       "WRN",     "WRN",        "WRN",        "WRN",        "WRN",        "WRN");

  int metaData = xmlAppendChild(docNum, node, XML_ELEMENT_NODE, "StandardMetaData");
  int nodeLog = xmlAppendChild(docNum, metaData, XML_ELEMENT_NODE, "Log");

  int auxNodeLog = xmlAppendChild(docNum, nodeLog, XML_ELEMENT_NODE, "GeneralLogLevel");
  xmlSetElementAttribute(docNum, auxNodeLog, "logLevel", generalLogLevel);

  nodeLog = xmlAppendChild(docNum, nodeLog, XML_ELEMENT_NODE, "ComponentLogLevels");
  for (int i=1;i<=dynlen(components);i++) {
    auxNodeLog = xmlAppendChild(docNum, nodeLog, XML_ELEMENT_NODE, "ComponentLogLevel");
    xmlSetElementAttribute(docNum, auxNodeLog, "logLevel", componentLogLevel[i]);
    xmlSetElementAttribute(docNum, auxNodeLog, "componentName", components[i]);
  }





  //Iterate through all CAN buses and ELMBs, declare all parameters up to sensor level
  int canbusNode = fwElmbUser_appendCanbusToXML(docNum,node,argdsBuses,argbUseNodeGuarding, argAdcStatus, argdsExceptionInfo);

  //Add calculated items
  dyn_string calculatedItemsDps = dpNames(getSystemName()+"*", "FwElmbCalculatedItems");
  for(int i = 1; i <= dynlen(calculatedItemsDps); i++)
  {
    string name;
    dpGet( calculatedItemsDps[i]+".name", name );
    xmlAppendChild( docNum, node, XML_ENTITY_REFERENCE_NODE, name );

  }



  //Write to file and clean memory
  // Bug fix: path should not be taken from fwElmbUser_getOPCUAConfigPath because it may not be writable location
  // Create exactly where sFileName points to

  string path = dirName(argsFilename);
  int fileWritten = xmlDocumentToFile(docNum,path + "temp.xml");
  if(fileWritten == -1)
  {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_createOPCuaXMLFile(): XML not written to file",
                      "");
    return;
  }
  xmlCloseDocument(docNum);

  fwElmbUser_insertDoctypeToXML(argsFilename,argdsExceptionInfo);
}

void fwElmbUser_insertDoctypeToXML(string argsFilename,dyn_string &argdsExceptionInfo)
{
  //Search for elmbTypes in the FwElmbNode DP structure
  dyn_string elmbList = dpNames(getSystemName()+"*","FwElmbNode");
  dyn_string elmbTypesInSystem,elmbTypes;

  dyn_string elmbTypesDps = dpNames(getSystemName()+"*","FwElmbType");
  if (dynlen(elmbTypesDps) > 0)
    for (int i=1; i<=dynlen(elmbTypesDps); i++)
    {
      string type;
      dpGet (elmbTypesDps[i]+".name", type);
      dynAppend (elmbTypesInSystem, type);
    }


  if(dynlen(elmbList)>0){
    for(int i = 1; i <= dynlen(elmbList); i++){
      string type;
      dpGet(elmbList[i]+ ".type",type);
      if(dynContains(elmbTypesInSystem,type) <= 0){

        fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_insertDocTypeToXML(): A node with DP="+elmbList[i]+" is of type= " + type + " but corresponding FwElmbType doesn't exist .",
                      "");
        return;
      }
    }
  }

  dyn_string calculatedItemsDps = dpNames(getSystemName()+"*", "FwElmbCalculatedItems");
  dyn_string calculatedItemsPaths;
  dyn_string calculatedItemsNames;
  for(int i = 1; i <= dynlen(calculatedItemsDps); i++)
  {
    string path, name;
    dpGet( calculatedItemsDps[i]+".path", path, calculatedItemsDps[i]+".name", name );
    dynAppend( calculatedItemsPaths, path );
    dynAppend( calculatedItemsNames, name );
  }

  file g = fopen(argsFilename,"w");
  if (g==0)
  {
    // Couldnt create file
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_insertDocTypeToXML(): Couldnt open file for writing.",
                      "");
        return;
  }
  //DebugTN(path + "temp.xml");
  file f = fopen(dirName(argsFilename) + "temp.xml","r");
  string str;
  dyn_string nodeTypes = dpNames ("*", "FwElmbType");
  string name,path;
  while(feof(f) == 0)
  {
    fgets(str,999,f);
    if(strpos(str,"<CanOpenOpcServerConfig") != -1)
    {
      fputs("<!DOCTYPE CanOpenOpcServerConfig [\n",g);

      if (dynlen(nodeTypes) > 0)
        for (int i=1; i<=dynlen(nodeTypes); i++)
        {
          name=""; path="";
          dpGet (nodeTypes[i]+".name", name);
          dpGet (nodeTypes[i]+".path", path);
          fputs("<!ENTITY "+name+" SYSTEM \"" + path + "\">\n",g);
        }
        for (int i=1; i<=dynlen(calculatedItemsPaths); i++)
        {
          fputs("<!ENTITY "+calculatedItemsNames[i]+" SYSTEM \"" + calculatedItemsPaths[i] + "\">\n", g);
        }
      fputs("]>\n",g);
      fputs(str,g);
    }
    else if (strpos(str,"</StandardMetaData>")>=0) {
        fputs(str,g);
        if (dynlen(nodeTypes) > 0)
        for (int i=1; i<=dynlen(nodeTypes); i++)
        {
          name="";
          dpGet (nodeTypes[i]+".name", name);
          fputs("&"+name + ";\n",g);
        }

    }
    else
      fputs(str,g);
  }
  fclose(f);
  fclose(g);
  remove(f);
}

int fwElmbUser_appendCanbusToXML(int docNum,int node,dyn_string canbusList, bool isNodeguard,  bool argAdcStatus, dyn_string &argdsExceptionInfo)
{
  int canNode = 0;
  int subNode = 0;
  int itemNode = 0;

  if(dynlen(canbusList) > 0){
   for(int i = 1; i <= dynlen(canbusList);i++){
     string sId,sPort,sCanName,sType,sManagementOnServerStart;
     int iSync,iNGuard,iSpeed;
     sCanName = strsplit(canbusList[i],fwDevice_HIERARCHY_SEPARATOR)[dynlen(strsplit(canbusList[i],fwDevice_HIERARCHY_SEPARATOR))];
     if(_UNIX)
       sType = "sock";
     else{
      dpGet(canbusList[i] + ".id",sId);
      if(sId == ELMB_CAN_CARD_KVASER){sType = "kv";}
      else if(sId == ELMB_CAN_CARD_SYSTEC){sType = "st";}
      else{
       fwException_raise(argdsExceptionInfo,
                         "ERROR",
                         "fwElmbUser_createOPCuaXMLFile(): Unknown interface card type found\n" + sId + "\nBus " + canbusList[i] + " not written to file",
                         "");
        return -1;
      }
    }
     dpGet(canbusList[i] + ".interfacePort",sPort);
     dpGet(canbusList[i] + ".syncInterval",iSync);
     dpGet(canbusList[i] + ".nodeGuardInterval",iNGuard);
     dpGet(canbusList[i] + ".busSpeed",iSpeed);
     dpGet(canbusList[i] + ".managementOnServerStart", sManagementOnServerStart);

     if(sManagementOnServerStart == "START")
       sManagementOnServerStart = "start";
     else if (sManagementOnServerStart == "STOP")
       sManagementOnServerStart = "stop";
     else if (sManagementOnServerStart == "RESET")
       sManagementOnServerStart = "reset";
     else
       sManagementOnServerStart = "";


     canNode = xmlAppendChild(docNum,node,XML_ELEMENT_NODE,"CANBUS");
     xmlSetElementAttribute(docNum,canNode,"name",sCanName);
     xmlSetElementAttribute(docNum,canNode,"type",sType);
     xmlSetElementAttribute(docNum,canNode,"speed",iSpeed);
     xmlSetElementAttribute(docNum,canNode,"port","can"+sPort);
     if (sManagementOnServerStart != "")
       xmlSetElementAttribute(docNum,canNode,"nmt",sManagementOnServerStart);
     if(isNodeguard){
       subNode = xmlAppendChild(docNum,canNode,XML_ELEMENT_NODE,"NODEGUARD");
       xmlSetElementAttribute(docNum,subNode,"interval",iNGuard);
     }
     subNode = xmlAppendChild(docNum,canNode,XML_ELEMENT_NODE,"SYNC");
     xmlSetElementAttribute(docNum,subNode,"interval",iSync);

     //Append ELMBs
     dyn_string elmbList = dpNames(getSystemName() + "*",ELMB_TYPE_NAME);
     string type;// = VENDOR_NAME;
     if(dynlen(elmbList) > 0){
       for(int j = 1; j <= dynlen(elmbList); j++){
         string elmbName;
         if(strpos(elmbList[j],fwDevice_HIERARCHY_SEPARATOR+sCanName+fwDevice_HIERARCHY_SEPARATOR) != -1){
           elmbName = strsplit(elmbList[j],fwDevice_HIERARCHY_SEPARATOR)[dynlen(strsplit(elmbList[j],fwDevice_HIERARCHY_SEPARATOR))];
           dpGet(elmbList[j] + ".type",type);
           fwElmbUser_appendElmbNodeToXML(docNum,canNode,canbusList[i],sCanName,elmbList[j],elmbName,type,  argAdcStatus, argdsExceptionInfo);
         }
       }
     }
   }
 }
  return canNode;
}

bool fwElmbUser_showErrorAskToContinue (string msg)
{
  dyn_string ds;
  dyn_float df;
 	ChildPanelOnCentralReturn("vision/MessageInfo",
																"Error -- continue?",
																makeDynString(msg, "Continue converting", "Abort"),
																df, ds);
  if (df[1]==1)
    return true;
  else
    return false;
}

void fwElmbUser_appendElmbNodeToXML(int docNum, int canNode, string canbusDp, string canbusName, string elmbDp, string elmbName, string type,  bool argAdcStatus, dyn_string &argdsExceptionInfo)
{
  int elmbNode = 0;
  int id;
  string sManagementOnServerStart;
  dpGet(elmbDp + ".id",id);
  elmbNode = xmlAppendChild(docNum,canNode,XML_ELEMENT_NODE,"NODE");
  xmlSetElementAttribute(docNum,elmbNode,"name",elmbName);
  xmlSetElementAttribute(docNum,elmbNode,"type",type);
  xmlSetElementAttribute(docNum,elmbNode,"nodeid",id);

  dpGet(elmbDp + ".managementOnServerStart", sManagementOnServerStart);

     if(sManagementOnServerStart == "START")
       sManagementOnServerStart = "start";
     else if (sManagementOnServerStart == "STOP")
       sManagementOnServerStart = "stop";
     else if (sManagementOnServerStart == "RESET")
       sManagementOnServerStart = "reset";
     else
       sManagementOnServerStart = "";
   if (sManagementOnServerStart != "")
     xmlSetElementAttribute(docNum,elmbNode,"nmt",sManagementOnServerStart);


  if (dpExists(elmbDp + "/DI.readoutMethod"))
  {
    // If this node Digital Input style should be on-change based
    uint diReadoutMethod = 0;
    dpGet( elmbDp + "/DI.readoutMethod", diReadoutMethod );
    if (diReadoutMethod == FWELMB_DI_READOUT_ONCHANGE)
    {
      int executeNode = xmlAppendChild( docNum, elmbNode, XML_ELEMENT_NODE, "atStartup");
      xmlSetElementAttribute( docNum, executeNode, "command", "TPDO1.RTR" );
    }
  }

  //Add any analog input item if exist
  dyn_string itemList = dpNames(elmbDp + "/*",ELMB_AI_TYPE_NAME);
  if(dynlen(itemList) > 0)
  {
    for(int i = 1; i <= dynlen(itemList); i++)
    {
      string name = strsplit(itemList[i],fwDevice_HIERARCHY_SEPARATOR)[dynlen(strsplit(itemList[i],fwDevice_HIERARCHY_SEPARATOR))];
      string function;
      int itemNode = 0;
      dpGet(itemList[i] + ".function",function);
      if(function != ELMB_NO_INFO)
      {
        int lastEqualSign = dynlen(strsplit(function, "="));
        if (lastEqualSign >= 1)
        {
          function = strsplit(function, "=")[lastEqualSign]; //takes only the value of the function
          if(strpos(function,canbusName+"."+elmbName+"."+ELMB_AI_PREFIX) != -1)
            strreplace(function,canbusName+"."+elmbName+"."+ELMB_AI_PREFIX,"TPDO3.Value_"); //New convention in UA
          itemNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"ITEM");
          xmlSetElementAttribute(docNum,itemNode,"name",name);
          xmlSetElementAttribute(docNum,itemNode,"value",function);
          if ( argAdcStatus )
          {
            // get list of all channels participating in this formula.
            // the final status of the value is good when ALL participating items are good
            dyn_int diChannelInt;
            dpGet( itemList[i]+".channel", diChannelInt );

            string status = "";
            for (int ii=1; ii<=dynlen(diChannelInt); ii++)
            {
              status += "TPDO3.Flag_"+diChannelInt[ii]+"<128 ";
              if (ii < dynlen(diChannelInt))
              {
                status += " && ";
              }
            }
            xmlSetElementAttribute( docNum, itemNode, "status", status);
          }
        }
        else
        {
          string msg = "appendElmbNodeToXML: function doesnt contain equal sign, can't generate OPC Config item for "+canbusDp+"/"+elmbName+"/"+name;
          if (!fwElmbUser_showErrorAskToContinue(msg))
          {
            fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      msg,
                      0);
            return;
          }
        }
      }
      else
      { /* There is no formula for this item */
        string sensorType;
        dpGet( itemList[i] + ".type", sensorType);
        if (sensorType == "Raw ADC Value")
        {
          /* NO FORMULA is actually okay for "Raw" sensors -- we do nothing here */
        }
        else
        {
          string msg = "appendElmbNodeToXML: function type is ELMB_NO_INFO, can't generate OPC Config item for "+canbusDp+"/"+elmbName+"/"+name;
          if (!fwElmbUser_showErrorAskToContinue(msg))
          {
            fwException_raise(argdsExceptionInfo,
                          "ERROR",
                          msg,
                          0);
            return;
          }
        }
      }
    }
  }
}

void fwElmbUser_appendSDOItemToXML(int docNum,int node,string name,string type,string acces,string subindex,string index)
{
  node = xmlAppendChild(docNum,node,XML_ELEMENT_NODE,"SDOITEM");
  if(name != ""){xmlSetElementAttribute(docNum,node,"name",name);}
  if(type != ""){xmlSetElementAttribute(docNum,node,"type",type);}
  if(acces != ""){xmlSetElementAttribute(docNum,node,"access",acces);}
  if(subindex != ""){xmlSetElementAttribute(docNum,node,"subindex",subindex);}
  if(index != ""){xmlSetElementAttribute(docNum,node,"index",index);}
  return;
}

void fwElmbUser_appendPDOItemToXML(int docNum,int node,string name,string type,string byteindex,string bit)
{
  node = xmlAppendChild(docNum,node,XML_ELEMENT_NODE,"PDOITEM");
  if(name != ""){xmlSetElementAttribute(docNum,node,"name",name);}
  if(type != ""){xmlSetElementAttribute(docNum,node,"type",type);}
  if(byteindex != ""){xmlSetElementAttribute(docNum,node,"byteindex",byteindex);}
  if(bit != ""){xmlSetElementAttribute(docNum,node,"bit",bit);}
  return;
}
void fwElmbUser_appendElmbRefsToXML(int docNum,dyn_string elmbTypes,int &node)
{
  int refNode;
  if(dynlen(elmbTypes) > 0){
    for(int i = 1; i <= dynlen(elmbTypes); i++){
      refNode = xmlAppendChild(docNum,node,XML_ENTITY_REFERENCE_NODE,elmbTypes[i]);
      refNode = xmlAppendChild(docNum,node,XML_COMMENT_NODE,"Definition of type " + elmbTypes[i]);

    }
  }
}
void fwElmbUser_appendElmbDefinitionsToXML(int docNum, dyn_string elmbTypes, int &node)
{
  int elmbNode = 0;
  int sdoNode = 0;
  int pdoNode = 0;
  if(dynlen(elmbTypes) > 0){
    for(int i = 1; i <= dynlen(elmbTypes);i++){
      elmbNode = xmlAppendChild(docNum,node,XML_ELEMENT_NODE,"NODETYPE");
      xmlSetElementAttribute(docNum,elmbNode,"name",elmbTypes[i]);
      // SDO section
      fwElmbUser_appendSDOItemToXML(docNum,elmbNode,"NodeError","byte","R","0","1001");

      //ADC settings
      sdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"SDO");
      xmlSetElementAttribute(docNum,sdoNode,"name","ADC Settings");
      xmlSetElementAttribute(docNum,sdoNode,"index","2100");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"Channel number","byte","RW","1","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"Rate","byte","RW","2","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"Range","byte","RW","3","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"Mode","byte","RW","4","");

      //AI sdo section
      if(elmbTypes[i] == "ELMBAIsdo"){
        sdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"SDOITEMARRAY");
        xmlSetElementAttribute(docNum,sdoNode,"name","AISDO");
        xmlSetElementAttribute(docNum,sdoNode,"index","6404");
        xmlSetElementAttribute(docNum,sdoNode,"type","int32");
        xmlSetElementAttribute(docNum,sdoNode,"access","R");
        xmlSetElementAttribute(docNum,sdoNode,"number","64");
      }

      //DAC settings
      sdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"SDO");
      xmlSetElementAttribute(docNum,sdoNode,"name","DAC Settings");
      xmlSetElementAttribute(docNum,sdoNode,"index","2500");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"Number of outputs","byte","R","1","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"DAC type","bool","RW","2","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"SPI clock period","byte","RW","3","");

      //SPI port
      sdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"SDO");
      xmlSetElementAttribute(docNum,sdoNode,"name","SPI");
      xmlSetElementAttribute(docNum,sdoNode,"index","2600");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"RW 1 byte","uint32","RW","1","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"RW 2 byte","uint32","RW","2","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"RW 3 byte","uint32","RW","3","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"RW 4 byte","uint32","RW","4","");

      fwElmbUser_appendSDOItemToXML(docNum,elmbNode,"SPI CS","byte","RW","0","2601");

      sdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"SDO");
      xmlSetElementAttribute(docNum,sdoNode,"name","SPI config");
      xmlSetElementAttribute(docNum,sdoNode,"index","2602");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"SPI clock period","byte","RW","1","");
      fwElmbUser_appendSDOItemToXML(docNum,sdoNode,"SPI edge","bool","RW","2","");


      // PDO section

      // DI/DO if not AI only
      if(elmbTypes[i] != "ELMBAIonly" && elmbTypes[i] != "ELMBAIsdo" ){
        pdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"TPDO1");
        xmlSetElementAttribute(docNum,pdoNode,"name","TPDO1");
        xmlSetElementAttribute(docNum,pdoNode,"access","R");
        xmlSetElementAttribute(docNum,pdoNode,"cobid","180");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"PORTC","byte","0","");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"PORTA","byte","1","");
        for(int k = 0; k <= 7; k++)
          fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"DI_C"+(string)k,"bit","0",(string)k);
        for(int k = 0; k <= 7; k++)
          fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"DI_A"+(string)k,"bit","1",(string)k);
        pdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"RPDO1");
        xmlSetElementAttribute(docNum,pdoNode,"name","RPDO1");
        xmlSetElementAttribute(docNum,pdoNode,"access","R");
        xmlSetElementAttribute(docNum,pdoNode,"cobid","200");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"PORTF","byte","0","");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"PORTA","byte","1","");
        for(int k = 0; k <= 7; k++)
          fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"DO_F"+(string)k,"bit","0",(string)k);
        for(int k = 0; k <= 7; k++)
          fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"DO_A"+(string)k,"bit","1",(string)k);

        //Analog outputs
        pdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"RPDO2");
        xmlSetElementAttribute(docNum,pdoNode,"name","RPDO2");
        xmlSetElementAttribute(docNum,pdoNode,"access","W");
        xmlSetElementAttribute(docNum,pdoNode,"cobid","300");
        //xmlSetElementAttribute(docNum,pdoNode,"numch","64");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"Flag","byte","1","");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"Value","byte","2","");
      }

      // Analog inputs PDO
      if(elmbTypes[i] != "ELMBAIsdo"){
        pdoNode = xmlAppendChild(docNum,elmbNode,XML_ELEMENT_NODE,"TPDO3");
        xmlSetElementAttribute(docNum,pdoNode,"name","TPDO3");
        xmlSetElementAttribute(docNum,pdoNode,"access","R");
        xmlSetElementAttribute(docNum,pdoNode,"cobid","380");
        xmlSetElementAttribute(docNum,pdoNode,"numch","64");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"Flag","byte","1","");
        fwElmbUser_appendPDOItemToXML(docNum,pdoNode,"Value","byte","2","");
      }
    }
  }
  else{
    return;
  }
}

void fwElmbUser_createUASubscription(string prefix, string busName)
{

// identify if using busName in subscription or not by checking the Device Definition (-1 not evaluated, 0 no, 1 yes)
  if (g_fwElmb_isUsingBusNameInSubscription<0) g_fwElmb_isUsingBusNameInSubscription=fwElmb_checkSubscriptionBusNameConvention();

  string dp;
  if (g_fwElmb_isUsingBusNameInSubscription>0) dp= "_" + prefix + busName;
  else dp="_OPCUACANOPENSERVER_"+prefix;

  dpCreate(dp,"_OPCUASubscription");
  if (isRedundant())   dpCreate(dp+"_2","_OPCUASubscription");
  dpSetWait(dp + ".Config.RequestedLifetimeCount",100);
  dpSetWait(dp + ".Config.RequestedMaxKeepAliveCount",10);
  dpSetWait(dp + ".Config.PublishingEnabled",TRUE);
  dpSetWait(dp + ".Config.Priority",0);
  dpSetWait(dp + ".Config.SubscriptionType",1);
  dpSetWait(dp + ".Config.MonitoredItems.TimestampsToReturn",1);
  dpSetWait(dp + ".Config.MonitoredItems.QueueSize",20);
  dpSetWait(dp + ".Config.MonitoredItems.DiscardOldest",TRUE);
  dpSetWait(dp + ".Config.MonitoredItems.SamplingInterval",2000);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.Trigger",1);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.DeadbandType",0);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.DeadbandValue",0.000);
  dpSetWait(dp + ".Config.RequestedPublishingInterval",500);

  //Add it to OPC UA config
  dyn_anytype subscriptions;
  dpGet("_OPCUACANOPENSERVER.Config.Subscriptions",subscriptions);
  if(!dynContains(subscriptions,dp)){
    dynAppend(subscriptions,dp);
    dpSetWait("_OPCUACANOPENSERVER.Config.Subscriptions",subscriptions);
  }

  DebugTN("fwElmb - Subscription " + prefix + busName + " does not exists - creating it");
}


//*****************************************************************************
// @name Function: fwElmbUser_readSPIValue
//
// Reads a value from the SPI bus of a value of the current SPI configuration
// and returns the value.
//
// @param argsElmb: DP name of ELMB or of SPI configuration DP (string) to
//                  read from. Hierarchy information is required, but system
//                  name is optional
// @param argsValueToRead: Name of element to read (string)
// @param argdsExceptionInfo: Any exceptions are returned here
// @param argtTimeout: Optional argument for timeout (default is 2 seconds)
// @param argbSetPreop: Optional argument for whether to set ELMB to
//                      pre-operational before any SDOs sent (default is true)
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
int fwElmbUser_readSPIValue(string argsElmb,
                            string argsValueToRead,
                            dyn_string &argdsExceptionInfo,
                            time argtTimeout = 2,
                            bool argbSetPreop = true)
{
// Local Variables
// ---------------
  bool bIsRunning;
  bool bTimeout;
  bool bRemote = false;

  int iDriverNumber;
  int iResult = 0;
  int i;

  unsigned uState;

  string sDpe;
  string sType;
  string sElmbDpName;
  string sSystem;

  anytype aValue;

  dyn_string dsDpNamesToWaitFor;
  dyn_string dsDpNamesReturn;
  dyn_string dsTemp;

  dyn_anytype daConditions;
  dyn_anytype daReturnedValues;

  time tTimeNow;

// Executable Code
// ---------------
  // Check for remote system
  sSystem = dpSubStr(argsElmb, DPSUB_SYS);
  if (sSystem != getSystemName())
    bRemote = true;

  // Check if driver is running and get driver number
  bIsRunning = fwElmbUser_checkDefaultDriver(iDriverNumber, argdsExceptionInfo, ELMB_CAN_BUS_TYPE_NAME, sSystem);
  if (dynlen(argdsExceptionInfo) == 0) {
    if (!bIsRunning) {
      // Raise an exception
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "OPC Client with '-num " + iDriverNumber + " is not running" + (bRemote ? " on remote system" : ""),
                        "");
    } else {
      // Check DPT of argument given
      sType = dpTypeName(argsElmb);
      if (sType == ELMB_SPI_TYPE_NAME) {
        sDpe = argsElmb + "." + argsValueToRead;
        dsTemp = strsplit(argsElmb, fwDevice_HIERARCHY_SEPARATOR);
        sElmbDpName = dsTemp[1];
        for (i = 2; i < dynlen(dsTemp); i++)
          sElmbDpName += fwDevice_HIERARCHY_SEPARATOR + dsTemp[i];
      } else if (sType == ELMB_TYPE_NAME) {
        sElmbDpName = argsElmb;
        sDpe = argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_SPI_CONFIG_NAME + "." + argsValueToRead;
      } else {
        fwException_raise(argdsExceptionInfo,
                          "ERROR",
                          "fwElmbUser_readSPIValue: Wrong device type given - " + sType,
                          "");
        return (0);
      }

      if (argbSetPreop) {
        // Get current state of ELMB
        dpGet(sElmbDpName + ".state.value", uState);

        // Set ELMB to preoperational
        dpSet(sElmbDpName + ".management", 128);
      }

      // Action a Single Query on the required DPE to obtain the value
      fwElmb_elementSQ(sDpe,
                       argtTimeout,
                       aValue,
                       argdsExceptionInfo);

      if (dynlen(argdsExceptionInfo) == 0)
        iResult = aValue;

      // Check whether state had been changed (and therefore needs to be set back)
      if (argbSetPreop) {
        // Set the ELMB back to it's original state, but only if it was stopped
        // or operational. Otherwise, leave it as preoperational
        if ((uState == 0x84) || (uState == 0x04))
          dpSet(sElmbDpName + ".management", 2);
        else if ((uState  == 0x85) || (uState == 0x05))
          dpSet(sElmbDpName + ".management", 1);
      }
    }
  }

  // Return to calling routine
  return (iResult);
}

//*****************************************************************************
// @name Function: fwElmbUser_setDoBit
//
// Sets the given digital output while ensuring consistency between hardware
// and software information.
//*****************************************************************************
void fwElmbUser_setDoBit(string argsElmb,
                         string argsBitId,
                         bool argbValue,
                         dyn_string &argdsExceptionInfo, bool synched = true)
{
// Local Variables
// ---------------
  dyn_bool dbValues;

  dyn_string dsBitIds;

// Executable Code
// ---------------
  // Set up as if a list and call fwElmbUser_setDoBits function
  dbValues = makeDynBool(argbValue);
  dsBitIds = makeDynString(argsBitId);

  fwElmbUser_setDoBits(argsElmb, dsBitIds, dbValues, argdsExceptionInfo, synched);


  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_setDoBitsSynchronized
//
// Sets the given digital output bits while ensuring consistency between
// hardware and software information.
//
//Created on the 20/10/10 by Olivier Gutzwiller
//-synchronized version of fwElmbUser_setDoBits() / mutex not used
//*****************************************************************************
synchronized void fwElmbUser_setDoBitsSynchronized(string argsElmb,
																									 dyn_string argdsBitIds,
																									 dyn_bool argdbValues,
																									 dyn_string &argdsExceptionInfo)
{
  DebugTN ("fwElmbUser_setDoBitsSynchronized: this function is deprecated since FwElmb 5.2.4. Please use fwElmbUser_setDoBits");
	fwElmbUser_setDoBits(argsElmb, argdsBitIds,
											 argdbValues, argdsExceptionInfo, false);
}

//*****************************************************************************
// @name Function: fwElmbUser_setDoBits
//
// Sets the given digital output bits while ensuring consistency between
// hardware and software information.
//
//Modified on the 20/10/10 by Olivier Gutzwiller
//-Do not set all output bytes if reading failed
//-Use of mutex for 'synchronization' (limited to 10 ELMBs!)
//
//Modified on 9/Sep/2014 by Piotr Nikiel - using new mutex mechanism
//*****************************************************************************
void fwElmbUser_setDoBits(string argsElmb,
                          dyn_string argdsBitIds,
                          dyn_bool argdbValues,
                          dyn_string &argdsExceptionInfo, bool synched = true)
{
// Local Variables
// ---------------
  int i;
  int iBit;

  unsigned uValueToSet, uValueSet;
  unsigned uMask;

  string sPort;

  dyn_string dsTemp;

  string lockName = argsElmb+"/DO/do_Bytes";

// Executable Code
// ---------------
  // Use of mutex to lock any other DO actions on this ELMB during executiuon time
	if (synched) {
		if (fwElmb_lock(lockName) == false)
    {
      DebugTN ("fwElmbUser_setDoBits: failed to obtain the mutex. The command was not executed.");
      return;
    }
	}

  // Ensure system name is given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Get current value
  uValueToSet = fwElmbUser_getDoBytes(argsElmb, argdsExceptionInfo);
  bit32 uValueToSetDisplayBefore = uValueToSet;
  string uValueToSetDisplayBeforeString = uValueToSetDisplayBefore;
  DebugTN("ELMB "+argsElmb+" PortA-PortC before command on bit(s) "+argdsBitIds+": "+substr(uValueToSetDisplayBeforeString, 16, 8)+"-"+substr(uValueToSetDisplayBeforeString, 24, 8));

  // Check for errors
  for (i = 1; i <= dynlen(argdsBitIds); i++) {
      dsTemp = strsplit(argdsBitIds[i], ";");
      sPort = dsTemp[1];
      iBit = dsTemp[2];
      if (sPort == "A")
        uMask = 1 << (iBit + 8);
      else if (sPort == "C")
        uMask = 1 << iBit;
      if (argdbValues[i])
        uValueToSet |= uMask;
      else
        uValueToSet &= ~uMask;
  }

  // Set all relevant output bits/bytes
  if (dynlen(argdsExceptionInfo) == 0) {
    fwElmbUser_setDoBytes(argsElmb, uValueToSet, argdsExceptionInfo);
    uValueSet = fwElmbUser_getDoBytes(argsElmb, argdsExceptionInfo);
    if (uValueSet == uValueToSet) {
      bit32 uValueToSetDisplayAfter = uValueToSet;
      string uValueToSetDisplayAfterString = uValueToSetDisplayAfter;
      DebugTN("ELMB "+argsElmb+" PortA-PortC after command on bit(s)  "+argdsBitIds+": "+substr(uValueToSetDisplayAfterString, 16, 8)+"-"+substr(uValueToSetDisplayAfterString, 24, 8));
    }
    else {
      bit32 uValueSetDisplayAfter = uValueSet;
      string uValueSetDisplayAfterString = uValueSetDisplayAfter;
      DebugTN("ELMB "+argsElmb+" PortA-PortC INCOHERENT after command on bit(s)  "+argdsBitIds+": "+substr(uValueSetDisplayAfterString, 16, 8)+"-"+substr(uValueSetDisplayAfterString, 24, 8));
    }
  }
  else {
    DebugTN("ELMB "+argsElmb+" DO command on bit(s)  "+argdsBitIds+" NOT EXECUTED ! : "+argdsExceptionInfo);
  }

  // Use of mutex to unlock DO actions on this ELMB
	if (synched) {
    		fwElmb_unlock(lockName);
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_setDoByte
//
// Sets the given digital output byte while ensuring consistency between
// hardware and software information.
//*****************************************************************************
void fwElmbUser_setDoByte(string argsElmb,
                          string argsPort,
                          unsigned arguValue,
                          dyn_string &argdsExceptionInfo,
                          time argtTimeout = 2)
{
// Local Variables
// ---------------
  unsigned uPortA;
  unsigned uPortC;
  unsigned uValueToSet;

// Executable Code
// ---------------
  // Check for valid port
  if ((argsPort == "A") || (argsPort == "C")) {
    // Ensure system name is given
    argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

    if (argsPort == "A") {
      // Get current settings for Port C and what needs to be set to Port A
      uPortC = fwElmbUser_getDoByte(argsElmb, "C", argdsExceptionInfo, argtTimeout, false);
      uPortA = arguValue;
    } else {
      // Get what needs to be set to Port C and current settings for Port A
      uPortC = arguValue;
      uPortA = fwElmbUser_getDoByte(argsElmb, "A", argdsExceptionInfo, argtTimeout, false);
    }

    // Check for errors
    if (dynlen(argdsExceptionInfo) > 0)
      return;

    // Create actual value to write
    uValueToSet = (uPortA << 8) | uPortC;

    // Set all relevant output bits/bytes
    fwElmbUser_setDoBytes(argsElmb, uValueToSet, argdsExceptionInfo);
  } else {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmbUser_setDoByte: Port '" + argsPort + "' is not a valid output port",
                      "");
    return;
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_setDoBytes
//
// Sets the 16-bit digital output while ensuring consistency between hardware
// and software information. Only the least significant 16 bits are used, and
// this is made up of (PortA << 8) && PortC
//*****************************************************************************
void fwElmbUser_setDoBytes(string argsElmb,
                           unsigned arguValue,
                           dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  int i;
  int iBit;

  string sDpe;
  string sPort;
  string sPortAInvalid;
  string sPortCInvalid;

  dyn_bool dbValues;

  dyn_string dsIdDpes;
  dyn_string dsIds;
  dyn_string dsValueDpes;
  dyn_string dsTemp;


// Executable Code
// ---------------
  // Ensure system name is given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Ensure only lowest (least significant) 16 bits are used
  arguValue &= 0xffff;

  // Set all existing outputs for consistency, starting with the only addressed element
  sDpe = argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_CONFIG_NAME +
         fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_PREFIX + "Bytes." +
         ELMB_DO_PREFIX + "write";
  dpSetWait(sDpe, arguValue);

  // Get any individual output bit datapoints
  dsIdDpes = dpNames(argsElmb + fwDevice_HIERARCHY_SEPARATOR + "*.id", ELMB_DO_TYPE_NAME);
  dsValueDpes = dpNames(argsElmb + fwDevice_HIERARCHY_SEPARATOR + "*.value", ELMB_DO_TYPE_NAME);

  // Ensure the two lists are in the same order
  dynSortAsc(dsIdDpes);
  dynSortAsc(dsValueDpes);

  // Get all the IDs so that the correct values can be set
  dpGet(dsIdDpes, dsIds);
  for (i = 1; i <= dynlen(dsIds); i++) {
    dsTemp = strsplit(dsIds[i], ";");
    sPort = dsTemp[1];
    iBit = dsTemp[2];
    if (sPort == "A") {
      dynAppend(dbValues, ((1 << (iBit + 8)) & arguValue) > 0 ? true : false);
    } else if (sPort == "C") {
      dynAppend(dbValues, ((1 << iBit) & arguValue) > 0 ? true : false);
    }
  }
  dpSetWait(dsValueDpes, dbValues);

  // The 'read' values are now possibly different to the actual values set,
  // so mark them as invalid
  sPortAInvalid = argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_CONFIG_NAME +
                  fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_PREFIX + "Bytes." +
                  ELMB_DO_PREFIX + "A" + "_read:_original.._aut_inv";
  sPortCInvalid = argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_CONFIG_NAME +
                  fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_PREFIX + "Bytes." +
                  ELMB_DO_PREFIX + "C" + "_read:_original.._aut_inv";
/*
  dpSetWait(sPortAInvalid, true,
        sPortCInvalid, true);
 */

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_getDoByte
//
// Reads value for the digtal byte of the port specified and returns the value.
//
// @param argsElmb: DP name of ELMB (string) to read from.
//                  Hierarchy information is required, but system name is optional
// @param argsPort: Port to read (string). Must be either 'A' or 'C'
// @param argdsExceptionInfo: Any exceptions are returned here
// @param argtTimeout: Optional argument for timeout (default is 2 seconds)
// @param argbSetPreop: Optional argument for whether to set ELMB to
//                      pre-operational before any SDOs sent (default is false)
//*****************************************************************************
unsigned fwElmbUser_getDoByte(string argsElmb,
                              string argsPort,
                              dyn_string &argdsExceptionInfo,
                              time argtTimeout = 2,
                              bool argbSetPreop = false)
{
// Local Variables
// ---------------
  bool bIsRunning;
  bool bTimeout;
  bool bRemote = false;

  int iDriverNumber;

  unsigned uState;
  unsigned uResult = 0;

  string sDpe;
  string sType;
  string sSystem;

  anytype aValue;

// Executable Code
// ---------------
  // Ensure system name is given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Check for remote system
  sSystem = dpSubStr(argsElmb, DPSUB_SYS);
  if (sSystem != getSystemName())
    bRemote = true;

  // Check if driver is running and get driver number
  bIsRunning = fwElmbUser_checkDefaultDriver(iDriverNumber, argdsExceptionInfo, ELMB_CAN_BUS_TYPE_NAME, sSystem);
  if (dynlen(argdsExceptionInfo) == 0) {
    if (!bIsRunning) {
      // Raise an exception
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "OPC Client with '-num " + iDriverNumber + " is not running" + (bRemote ? " on remote system" : ""),
                        "");
    } else {
      // Check DPT of argument given
      sType = dpTypeName(argsElmb);
      if (sType == ELMB_TYPE_NAME) {
        // Check port requested is valid
        if ((argsPort == "A") || (argsPort == "C")) {
          sDpe = argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_CONFIG_NAME +
                 fwDevice_HIERARCHY_SEPARATOR + ELMB_DO_PREFIX + "Bytes." +
                 ELMB_DO_PREFIX + argsPort + "_read";
          // Check if DPE exists
          if (!dpExists(sDpe)) {
            fwException_raise(argdsExceptionInfo,
                              "ERROR",
                              "fwElmbUser_getDoByte: Port '" + argsPort + "' does not exist on the specified ELMB",
                              "");
            return (0);
          }
        } else {
          fwException_raise(argdsExceptionInfo,
                            "ERROR",
                            "fwElmbUser_getDoByte: Port '" + argsPort + "' is not a valid output port",
                            "");
          return (0);
        }
      } else {
        fwException_raise(argdsExceptionInfo,
                          "ERROR",
                          "fwElmbUser_getDoByte: Wrong device type given - " + sType,
                          "");
        return (0);
      }

      if (argbSetPreop) {
        // Get current state of ELMB
        dpGet(argsElmb + ".state.value", uState);

        // Set ELMB to preoperational
        dpSet(argsElmb + ".management", 128);
      }

      // Action a Single Query on the required DPE to obtain the value
      fwElmb_elementSQ(sDpe,
                       argtTimeout,
                       aValue,
                       argdsExceptionInfo);

      if (dynlen(argdsExceptionInfo) == 0)
        uResult = aValue;

      // Check whether state had been changed (and therefore needs to be set back)
      if (argbSetPreop) {
        // Set the ELMB back to it's original state, but only if it was stopped
        // or operational. Otherwise, leave it as preoperational
        if ((uState == 0x84) || (uState == 0x04))
          dpSet(argsElmb + ".management", 2);
        else if ((uState  == 0x85) || (uState == 0x05))
          dpSet(argsElmb + ".management", 1);
      }
    }
  }

  // Ensure that any value returned is one byte max
  uResult &= 0xff;

  // Return to calling routine
  return (uResult);
}

//*****************************************************************************
// @name Function: fwElmbUser_getDoBytes
//
// Reads values of the digtal output bytes of the ELMB specified and returns
// the value. This value is returned as a two byte value and is made up of
// (PortA << 8) | PortC.
//
// @param argsElmb: DP name of ELMB (string) to read from.
//                  Hierarchy information is required, but system name is optional
// @param argdsExceptionInfo: Any exceptions are returned here
// @param argtTimeout: Optional argument for timeout (default is 2 seconds)
// @param argbSetPreop: Optional argument for whether to set ELMB to
//                      pre-operational before any SDOs sent (default is false)
//*****************************************************************************
unsigned fwElmbUser_getDoBytes(string argsElmb,
                               dyn_string &argdsExceptionInfo,
                               time argtTimeout = 2,
                               bool argbSetPreop = false)
{
// Local Variables
// ---------------
  unsigned uResult = 0;
  unsigned uPortA;
  unsigned uPortC;

  dyn_string dsExceptionInfo;

// Executable Code
// ---------------
  // Ensure system name is given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Call required functions to obtain the values
  uPortA = fwElmbUser_getDoByte(argsElmb, "A", dsExceptionInfo, argtTimeout, argbSetPreop);
  if (dynlen(dsExceptionInfo) > 0)
    dynAppend(argdsExceptionInfo, dsExceptionInfo);
  uPortC = fwElmbUser_getDoByte(argsElmb, "C", dsExceptionInfo, argtTimeout, argbSetPreop);
  if (dynlen(dsExceptionInfo) > 0)
    dynAppend(argdsExceptionInfo, dsExceptionInfo);

  // Create full value for return
  uResult = (uPortA << 8) | uPortC;

  // Return to calling routine
  return (uResult);
}

//*****************************************************************************
// @name Function: fwElmbUser_synchronizeDoBytes
//
// Reads values of the digtal output bytes of the ELMB specified and ensures
// that all 'set' values correspond correctly.
//
// @param argsElmb: DP name of ELMB (string) to synchronise.
//                  Hierarchy information is required, but system name is optional
// @param argdsExceptionInfo: Any exceptions are returned here
// @param argtTimeout: Optional argument for timeout (default is 2 seconds)
// @param argbSetPreop: Optional argument for whether to set ELMB to
//                      pre-operational before any SDOs sent (default is false)
//*****************************************************************************
void fwElmbUser_synchronizeDoBytes(string argsElmb,
                                   dyn_string &argdsExceptionInfo,
                                   time argtTimeout = 2,
                                   bool argbSetPreop = false)
{
// Local Variables
// ---------------
  unsigned uValue;

// Executable Code
// ---------------
  // Ensure system name is given
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Get current settings
  uValue = fwElmbUser_getDoBytes(argsElmb, argdsExceptionInfo, argtTimeout, argbSetPreop);

  // Check for errors
  if (dynlen(argdsExceptionInfo) > 0)
    return;

  // Set all relevant output bits/bytes
  fwElmbUser_setDoBytes(argsElmb, uValue, argdsExceptionInfo);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_updateFirmwareInfo
//
// Reads values of the firmware information for the ELMB specified. Updates the
// datapoint elements for the firmware version, software major and minor version
// and the serial number. Function starts a new thread so that it will not impact
// on the running of any other code.
//
// @param argsElmb: DP name of ELMB (string) to read.
//*****************************************************************************
void fwElmbUser_updateFirmwareInfo(string argsElmb)
{
  startThread("fwElmbUser_updateFirmwareThread", argsElmb);
}

// Actual thread function to update the firmware information
void fwElmbUser_updateFirmwareThread(string argsElmb)
{
  anytype aValue;
  dyn_string dsExceptionInfo;
  fwElmb_elementSQ(argsElmb + ".serialNumber", 2, aValue, dsExceptionInfo);
  fwElmb_elementSQ(argsElmb + ".hwVersion", 2, aValue, dsExceptionInfo);
  fwElmb_elementSQ(argsElmb + ".swVersion", 2, aValue, dsExceptionInfo);
  fwElmb_elementSQ(argsElmb + ".swMinorVersion", 2, aValue, dsExceptionInfo);
  return;
}

// ELMB Monitoring Functions
// =========================
//*****************************************************************************
// @name Function: fwElmbUser_monitorAll
//
// Connects to ALL required information in order to check for channel values which
// should be marked as invalid for all ELMBs and for OPC communication
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
void fwElmbUser_monitorAll()
{
// Local Variables
// ---------------
  int i;

  dyn_string dsElmbs;

// Executable Code
// ---------------
  // Call function to check OPC communication
  fwElmbUser_monitorOpc();

  // Get all ELMBs in the system
  dsElmbs = dpNames(getSystemName() + "*", ELMB_TYPE_NAME);

  // Loop through all ELMBs, connecting to required information
  for (i = 1; i <= dynlen(dsElmbs); i++)
    fwElmbUser_monitorElmb(dsElmbs[i]);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_monitorElmb
//
// Connects to required information in order to check for channel values which
// should be marked as invalid
//
// @param argsElmb: DP name of ELMB to monitor
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
void fwElmbUser_monitorElmb(string argsElmb)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Connect to required elements of the emergency message for each ELMB
  dpConnect("fwElmb_monitorElmbEMCbk",
            argsElmb + ".emergency.emergencyErrorCode",
            argsElmb + ".emergency.errorCodeByte1",
            argsElmb + ".emergency.errorCodeByte2",
            argsElmb + ".emergency.errorCodeByte3",
            argsElmb + ".emergency.errorCodeByte4",
            argsElmb + ".emergency.errorCodeByte5",
          argsElmb + ".emergency:_online.._stime");
  dpConnect("fwElmb_monitorElmbStateCbk",
            argsElmb + ".state.value");

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_monitorOpc
//
// Connects to required information in order to check for OPC connection for
// ELMB and marks relevant channel values as invalid if necessary
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
void fwElmbUser_monitorOpc()
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Connect to required elements for the OPC client/server
  dpConnect("fwElmb_monitorOpcCbk",
            ELMB_OPC_SERVER + ".Connected");

  // Return to calling routine
  return;
}


// Based on script by Jim Cook

bool fwElmbUser_getAddressActive(string sDpe)
{
  bool bConfigExists;
  bool bIsActive;
  dyn_anytype daConfig;
  dyn_string dsExceptionInfo;
  fwPeriphAddress_get(sDpe, bConfigExists, daConfig, bIsActive, dsExceptionInfo);
  if(dynlen(dsExceptionInfo))
  {
    DebugTN ("Script: <trtPP2ELMBcontrol>  function: <scrGetAddressActive> returned error:"+dsExceptionInfo);
    return (true);
  }
  return (bIsActive & bConfigExists);

}

/* This function is performance optimized to send one big dpSet request per ELMB */
void fwElmbUser_setInvalidAllChannelsOfElmb (string sElmbDp)
{
   dyn_string dsAIs = dpNames(sElmbDp + "/AI/*", "FwElmbAi");
   dyn_string dsAISDOs = dpNames (sElmbDp + "/AI/*", "FwElmbAiSDO");
   dynAppend (dsAIs, dsAISDOs);
   dyn_bool listOfTrue = makeDynBool();
   for (int i=1; i<=dynlen(dsAIs); i++)
   {
     dsAIs[i] = dsAIs[i]+".value:_original.._aut_inv";
     dynAppend(listOfTrue, true);
   }
   dpSet (dsAIs, listOfTrue);
}

void fwElmbUser_propagateEmergencyToInvalidBits (
                         string sDpErrorCode, int iValueErrorCode,
                         string sDpErrorByte1, unsigned uValueErrorByte1)
{
  string sDpName;
  string sTime;
  string sMessage;
  string sElmb;
  string sTemp;
  dyn_string dsAIs;
  dyn_string dsTemp;


  // Check for correct emergency message (0x5000 01|02) which relates to ADC errors
  if ((iValueErrorCode == 20480)
     &&
                          ((uValueErrorByte1 == 1) ||
                         (uValueErrorByte1 == 2)))
  {
    // Get 'nice' name of ELMB
    sTemp = dpSubStr(sDpErrorCode, DPSUB_DP);
    dsTemp = strsplit(sTemp, "/");
    sElmb = dsTemp[2] + "/" + dsTemp[3];
    // Output some information to log viewer
    sTime = getCurrentTime();
    DebugTN("Emergency Object for ELMB " + sElmb + " caught indicating ADC problem (" + sTime + ")");
    // Get the name of the DP from the DPE name
    sDpName = dpSubStr(sDpErrorCode, DPSUB_SYS_DP);
    fwElmbUser_setInvalidAllChannelsOfElmb (sDpName);



  }
  return;
}

void fwElmbUser_monitorEmergencyObjectsCbk (
                         string sDpErrorCode, int iValueErrorCode,
                         string sDpErrorByte1, unsigned uValueErrorByte1)
{
  fwElmbUser_propagateEmergencyToInvalidBits (sDpErrorCode, iValueErrorCode, sDpErrorByte1, uValueErrorByte1);
 // dp is the original update
  string substr = dpSubStr(sDpErrorCode, DPSUB_SYS_DP);
  time src, dst;
  dpGet (substr+".emergency.emergencyErrorCode:_online.._stime", src);
  dpGet (substr+".emergencyWritable.emergencyErrorCode:_online.._stime", dst);
  int tdiff = src-dst;
  if (tdiff>0)
  {
    // Copy from the original value to the cleanable one
    int val;
    if (dpGet (substr+".emergency.emergencyErrorCode:_online.._value", val) == 0)
    {
      // Successful call
       dpSet (substr+".emergencyWritable.emergencyErrorCode:_original.._value", val);
    }
  }
}

void fwElmbUser_monitorStateDisconnectedCbk (string sDpElmbState, int iElmbState)
{
  string sElmb;
  if (!fwElmbUtils_getNodeName(sDpElmbState, true, sElmb))
  {
    DebugTN ("Incorrect args "+sDpElmbState);
    return;
  }

  uint lastState;
  bool firstTime=false;
  if ( mappingHasKey(gFwElmb_statesOfNodesNoToggle, sElmb) )
    lastState = gFwElmb_statesOfNodesNoToggle[sElmb];
  else
    firstTime=true;
  uint stateNoToggle = iElmbState & 0x7f;
  gFwElmb_statesOfNodesNoToggle[sElmb] = stateNoToggle;
  if (firstTime || (lastState==1 && ( stateNoToggle == 4/*STOP*/ || stateNoToggle == 5/*OP*/ || stateNoToggle == 127/*PREOP*/ ) ))
  {
    // This ELMB has woken up from being disconnected - if configured for on-change readout, send RTR
    if (dpExists( sElmb+"/DI"))
    {
      uint diReadoutMethod;
      dpGet( sElmb+"/DI.readoutMethod", diReadoutMethod);
      if (diReadoutMethod == FWELMB_DI_READOUT_ONCHANGE)
      {
        dpSet( sElmb+".rtrCommand.digitalInputRtr", 1 );
      }
    }
  }
  // Also, run DO initialisation, if this ELMB is configured for Digital Outputs
  if (dpExists( sElmb+"/DO/do_Bytes" ))
    fwElmb_cbkDOinitialisation( sElmb, stateNoToggle, lastState);


  if (iElmbState == 1)
	{
    if (firstTime || lastState!=1) DebugTN ("State disconnected found for ELMB:"+sDpElmbState+", setting its channels to invalid");
    // Check for ELMB state: 'disconnected', state is 1
    // Get the name of the DP from the DPE name
    string sDpName = dpSubStr(sDpElmbState, DPSUB_SYS_DP);
    fwElmbUser_setInvalidAllChannelsOfElmb (sDpName);
  }
}

void fwElmbUser_monitorStateAndEmergencyObjects ()
{
    // Get name of current system (just in case this is a distributed system, and we only want ELMBs from this system)
    string sSystemName = getSystemName();
    DebugTN("fwElmb: starting monitoring of state and emergency objects in system '" + sSystemName + "'");
    // Get all ELMBs in the system
    dyn_string dsElmbs = dpNames(sSystemName + "ELMB/*", "FwElmbNode");
    for (int i = 1; i <= dynlen(dsElmbs); i++)
    {
      dpConnect("fwElmbUser_monitorEmergencyObjectsCbk",
      false, /* We dont want to trigger for some potentially very old emergency state */
      dsElmbs[i] + ".emergency.emergencyErrorCode",
      dsElmbs[i] + ".emergency.errorCodeByte1");
      dpConnect("fwElmbUser_monitorStateDisconnectedCbk", true, dsElmbs[i] + ".state.value");
    }

}


//*****************************************************************************
// @name Function: fwElmbUser_monitorInvalid
//
// Connects to required information in order to check for any channel being
// marked as invalid and sets a DPE for the respective node to allow for an
// alert to be activated.
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook
//*****************************************************************************
void fwElmbUser_monitorInvalid()
{
// Local Variables
// ---------------
  dyn_string dsElmbs;
  dyn_string dsValidList, dsValidListSDO;

// Executable Code
// ---------------
  // Get all ELMBs in this system
  dsElmbs = dpNames(getSystemName() + "*", ELMB_TYPE_NAME);

  // Get all analog input channels for each node in turn and set up the
  // connection to the invalidity flags
  for (int i = 1; i <= dynlen(dsElmbs); i++) {
    dsValidList = dpNames(dsElmbs[i] + "/*.value:_online.._invalid", ELMB_AI_TYPE_NAME);
    dsValidListSDO = dpNames(dsElmbs[i] + "/*.rawValue:_online.._invalid", ELMB_AI_SDO_TYPE_NAME);
    dynAppend(dsValidList, dsValidListSDO);
    if (dynlen(dsValidList) > 0)
    {
      for (int chNumber=1; chNumber<=dynlen(dsValidList); chNumber++)
        dpConnect("fwElmb_cbkMonitorInvalid", dsValidList[chNumber]);
    }
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmbUser_DOinitialisation
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Olivier Gutzwiller
// note: since FwElmb 5.2.13 this function will not be used from check invlaid manager
//*****************************************************************************
void fwElmbUser_DOinitialisation()
{
// Local Variables
// ---------------
dyn_string dsElmbs;
// Executable Code
// ---------------
// Get all ELMBs in this system with DO
dsElmbs = dpNames(getSystemName() + "*", ELMB_DO_BYTES_TYPE_NAME);
dyn_string argdsExceptionInfo;

for (int i = 1; i <= dynlen(dsElmbs); i++) {
	strreplace(dsElmbs[i], "/DO/do_Bytes", "");
	dpConnect("fwElmb_cbkDOinitialisation", dsElmbs[i] + ".state.value");
	}

// Return to calling routine
return;
}

//*****************************************************************************
// @name Function: fwElmbUser_modifyOPCconfigs
// sets the Digital Output Reading OPC groups with DataSource as Device and Callback Disabled
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Olivier Gutzwiller
//
// PiotrTODO: can we remove it? looks very OPCDA
//*****************************************************************************
void fwElmbUser_modifyOPCconfigs()
{
// Local Variables
// ---------------
dyn_string dsOPCgroups;
// Executable Code
// ---------------
// Get all ELMBs in this system with DO
dsOPCgroups = dpNames(getSystemName() + "_Do_Read*", OPC_GROUPS_TYPE_NAME);

for (int i = 1; i <= dynlen(dsOPCgroups); i++) {
  dpSet(dsOPCgroups[i]+".DataSourceDevice", false);
  dpSet(dsOPCgroups[i]+".EnableCallback", false);
	}
DebugTN("fwElmb - Modification applied for the _Do_Read OPC groups - Callback disabled and DataSourceDevice set to Device");

// Return to calling routine
return;
}


//
// Context: it was found out that dp_fct are massively malformed because of ASCII manager import functions
// See: https://its.cern.ch/jira/browse/OPCUA-774
// See: https://its.cern.ch/jira/browse/OPCUA-749
// This functions checks (and - if you request - fixes) the contents of those dp_fct
// Returns true if there is(was) no problem, returns false when they were some broken dp_fcts

// How to fix a broken DPFCT ... probably use the fwDevice_setDpFunction and that's it ...

bool fwElmbUser_checkOrFixAiConfigDpFct (dyn_string dsExceptions, bool recreate_dpfct=false)
{
  bool isOk = true;
  dyn_string dsAiConfigs = dpNames( getSystemName()+"*",  "FwElmbAiConfig" );
  for (int i=1; i<=dynlen(dsAiConfigs); i++ )
  {

    if (recreate_dpfct)
    {
      fwDevice_setDpFunction( dsAiConfigs[i], fwDevice_DPFUNCTION_SET, dsExceptions) ;
    }
    else
    {
      string dp_fct_id = dsAiConfigs[i]+".range.volt:_dp_fct";
      string fct;
      dyn_string param;
      dpGet( dp_fct_id + ".._fct", fct,
             dp_fct_id + ".._param", param );
      if ( dynlen(getLastError()) != 0)
      {
        isOk = false;
        DebugTN ("fwElmb: failed reading dp_fct for AI config "+dsAiConfigs[i]+"  it probably doesn't exist? It might be an ASCII Import error");
      }
      else // dp exists
      {
        if (fct != "p1==0?0.1:p1==1?0.055:p1==2?0.025:p1==3?1:p1==4?5:p1==5?2.5:0.1" )
        {
          isOk = false;
          DebugTN ("fwElmb: dp_fct probably broken! fwElmb will be unable to interpret ELMB AI range. "+dsAiConfigs[i]);
        }
        if (dynlen(param) != 1)
        {
          isOk = false;
          DebugTN ("fwElmb: dp_fct has broken list of params. Size doesn't match! It is "+dynlen(param)+" should be 1. For:"+dsAiConfigs[i] );
        }
        else
        {
          // size is good, but is the content fine?
          if( param[1] != dsAiConfigs[i]+".range.byte.read:_online.._value" )
          {
            DebugTN ("fwElmb: dp_fct has wrong param content. It is: '"+param[1]+"' For:"+dsAiConfigs[i] );
            isOk = false;
          }
        }
      }

      dp_fct_id = dsAiConfigs[i]+".rate.hz:_dp_fct";
      fct="";
      dynClear(param);
      dpGet( dp_fct_id + ".._fct", fct,
             dp_fct_id + ".._param", param );
      if ( dynlen(getLastError()) != 0)
      {
        isOk = false;
        DebugTN ("fwElmb: failed reading dp_fct for AI config "+dsAiConfigs[i]+"  it probably doesn't exist? It might be an ASCII Import error");
      }
      else // dp exists
      {
        if (fct != "p1==0?15:p1==1?30:p1==2?61.6:p1==3?84.5:p1==4?101.1:p1==5?1.88:p1==6?3.76:p1==7?7.51:15.0" )
        {
          isOk = false;
          DebugTN ("fwElmb: dp_fct probably broken! fwElmb will be unable to interpret ELMB AI range. "+dsAiConfigs[i]);
        }
        if (dynlen(param) != 1)
        {
          isOk = false;
          DebugTN ("fwElmb: dp_fct has broken list of params. Size doesn't match! It is "+dynlen(param)+" should be 1. For:"+dsAiConfigs[i] );
        }
        else
        {
          // size is good, but is the content fine?
          if( param[1] != dsAiConfigs[i]+".rate.byte.read:_online.._value" )
          {
            DebugTN ("fwElmb: dp_fct has wrong param content. It is: '"+param[1]+"' For:"+dsAiConfigs[i] );
            isOk = false;
          }
        }
      }


    }
  }
}

//*********************************************************************************
string fwElmbUser_getOPCUAConfigPath()
{
  string configPath = getPath(CONFIG_REL_PATH,""); //Default - Project path
  string repPath = getenv("DCS_REPO");
  string systemName = strsplit(getSystemName(),":")[1];
  string subdet = "";
  /* We may be in ATLAS DCS or somewhere else - check */
  if (isFunctionDefined("fwAtlas_getSubdetectorId"))
    subdet = fwAtlas_getSubdetectorId(systemName);
  if((repPath != "") && (subdet!=""))
  {
    if(isdir(repPath))
    {
      if(_UNIX)
        configPath = repPath + "/ATLAS_DCS_" + subdet + "/" + systemName + "/config/";
      else
        configPath = repPath + "\\ATLAS_DCS_" + subdet + "\\" + systemName + "\\config\\";
    }
    else
    {
      if (isFunctionDefined("information"))
        information ("fwElmb - DCS repository not accessible - falling back in project directory");
      else
        throwError( makeError("fwElmb", PRIO_INFO, ERR_CONTROL, 1001, "fwElmb - DCS repository not accessible - falling back in project directory") );
    }
  }
  else
  {
    if (isFunctionDefined("information"))
      information ("fwElmb - DCS repository not declared in environment variable or not in ATLAS - falling back in project directory");
    else
      throwError( makeError("fwElmb", PRIO_INFO, ERR_CONTROL, 1001, "fwElmb - DCS repository not declared in environment variable or not in ATLAS - falling back in project directory") );
  }
  return configPath;
}

void fwElmbUser_cleanEmergencyOfBootupInternal (string sElmb)
{
  uint emergencyErrorCode, byte1, byte2, byte3;
  delay (5);
  dpGet (sElmb + ".emergency.emergencyErrorCode", emergencyErrorCode,
         sElmb + ".emergency.errorCodeByte1", byte1,
         sElmb + ".emergency.errorCodeByte2", byte2,
         sElmb + ".emergency.errorCodeByte3", byte3);
  if ((emergencyErrorCode==20480 && byte1==254 && byte2==1 && byte3==40 /* bootloader in control*/) ||
      (emergencyErrorCode==20480 && byte1==240 /* irregular reset */))
  {
    DebugTN ("Cleaning emergency writable for ELMB="+sElmb);
    dpSet (sElmb + ".emergencyWritable.emergencyErrorCode", 0);
  }
  else
  {
    DebugTN ("fwElmbUser_cleanEmergencyOfBootupInternal(): no bootup-related emergency error code is present for ELMB "+sElmb);
  }
}

/**
  It will clean emergencyWritable if this ELMB's emergency error matches
  @param elmbDP
  @param spawnThread
  @return
*/
bool fwElmbUser_cleanEmergencyOfBootup (string elmbDP, bool spawnThread=false)
{
  string sElmb;
  if (!fwElmbUtils_getNodeName(elmbDP, true, sElmb, true))
  {
    DebugTN ("Supplied ELMB name: "+elmbDP+" is wrong");
    return false;
  }
  if (spawnThread)
  {
    startThread ("fwElmbUser_cleanEmergencyOfBootupInternal", sElmb);
  }
  else
    fwElmbUser_cleanEmergencyOfBootupInternal (sElmb);
}


/**
  @param readoutMethod - one of FWELMB_DI_READOUT_* constants
  @return String representation of the constant
  @author Piotr Nikiel
  @date FwElmb 5.2.13
*/
string fwElmbUser_diReadoutMethodToString( uint readoutMethod )
{
  switch( readoutMethod )
  {
    case FWELMB_DI_READOUT_ONSYNC:
      return "On-sync"; break;
    case FWELMB_DI_READOUT_ONCHANGE:
      return "On-change"; break;
    default:
      return "YouFoundABug!";
  }



}

/// stub function

void fwElmbUser_removeAlarm( string dpe, dyn_string argdsExceptionInfo )
{
  if (fwElmb_isAlertDefined( dpe, argdsExceptionInfo ))
  {
    fwAlertConfig_deactivate( dpe, argdsExceptionInfo, /*acknowledge*/TRUE, /*checkIfExists*/TRUE, /*storeInParamHistory*/ FALSE);
    if (dynlen( argdsExceptionInfo ) > 0)
      return;
    fwAlertConfig_delete( dpe, argdsExceptionInfo, /*removeDpeInSummary*/ "", /*storeInParamHistory*/ FALSE);
    if (dynlen( argdsExceptionInfo ) > 0)
      return;
  }
}

void fwElmbUser_setSimpleAlarm( string dpe, uint correctValue, string description, dyn_string argdsExceptionInfo)
{

  dyn_mixed alarmObject;
  fwAlertConfig_objectCreateDiscrete(
                alarmObject, //the object that will contain the alarm settings
                makeDynString("ok", description),
                makeDynString("*", correctValue),
                makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                "", //alarm panel, if necessary
                makeDynString(""), //$-params to pass to the alarm panel, if necessary
                "", //alarm help, if needed
                false, //impulse alarm
                makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                "", //state bits that must also match for the alarm
                makeDynString("",""), //state bits that must match for each range
                argdsExceptionInfo , //exception info returned here
                FALSE,
                FALSE,
                "",
                FALSE /* store in param history */
                 );

  fwElmbUser_removeAlarm( dpe, argdsExceptionInfo );

  fwAlertConfig_objectSet(dpe, alarmObject, argdsExceptionInfo);
  if (dynlen( argdsExceptionInfo ) > 0)
    return;
  fwAlertConfig_activate(dpe, argdsExceptionInfo);
  if (dynlen( argdsExceptionInfo ) > 0)
    return;


}

/**

  @param elmbDp
  @param readoutMethod
*/
void fwElmbUser_setElmbDiReadoutMethod( string elmbDp, uint readoutMethod, dyn_string argdsExceptionInfo )
{


  // set alerts

  switch (readoutMethod)
  {
    case FWELMB_DI_READOUT_ONSYNC:
    fwElmbUser_removeAlarm( elmbDp+"/DI.enable.read", argdsExceptionInfo );
    fwElmbUser_setSimpleAlarm( elmbDp+"/DI.transmissionType.read", 1, "DigitalInputs Transmission Type", argdsExceptionInfo );
    break;

    case FWELMB_DI_READOUT_ONCHANGE:
    // todo: remove alert on DI.enable.read

    fwElmbUser_setSimpleAlarm( elmbDp+"/DI.enable.read", 1, "DigitalInputs Interrupts Enable", argdsExceptionInfo );
    fwElmbUser_setSimpleAlarm( elmbDp+"/DI.transmissionType.read", 255, "DigitalInputs Transmission Type", argdsExceptionInfo );
    break;


  }

  // Make sure appropriate comments are installed
  fwElmb_addDpeComments ( elmbDp+"/DI" );

  // if successful, write out desired setting

  dpSet( elmbDp+"/DI.readoutMethod", readoutMethod );

}

bool fwElmbUser_isDiReadoutMethodWellConfigured( string elmbDp, string &description )
{
  uint enable, transmissionType, eventTimer, readoutMethod;
  dpGet( elmbDp+"/DI.enable.read", enable,
         elmbDp+"/DI.transmissionType.read", transmissionType,
         elmbDp+"/DI.eventTimer.read", eventTimer,
         elmbDp+"/DI.readoutMethod", readoutMethod );
  switch (readoutMethod)
  {
    case FWELMB_DI_READOUT_ONSYNC:
    {
      if (transmissionType != 1)
      {
        description = "transmissionType is wrong for on-sync readout; expected 1. (sync)";
        return false;
      }
    };
    break;
    case FWELMB_DI_READOUT_ONCHANGE:
    {
      if (enable != 1)
      {
        description = "enable is wrong; Global Interrupts should be set to on";
        return false;
      }
      if (transmissionType != 255 && transmissionType != 254)
      {
        description = "transmissionType is wrong for on-change readout; expected 254 or 255 (RTR)";
        return false;
      }
    }
  }
  return true;


}

