#uses "fwInstallation/fwInstallationRedu.ctl"
#uses "fwDevice/fwDevice.ctl"
#uses "fwGeneral/fwException.ctl"
#uses "fwConfigs/fwAlertConfig.ctl"
#uses "fwConfigs/fwPeriphAddress.ctl"

/**@name LIBRARY: fwElmb.ctl

This library contains function associated with the ELMB component.
Functions are provided for creating and deleting DPs of this type.
Also, templates for functions to configure this device are supplied.

Creation Date: 18.06.2003

Modification History: 14.06.2004 fwElmb_create renamed to fwElmb_createNode
                                  for easier searching
                      06.02.2006 Addition of fwElmb_aiChannelFilter dedicated
                                  to handle the analog input channels available
                                  due to the process being more complicated
                      2013-      For modification history please refer to the fwElmb readme file

External function list: fwElmb_channelFilter
                        fwElmb_aiChannelFilter
                        fwElmb_getFwName
                        fwElmb_getChannelName
                        fwElmb_checkSensorPrefix
                        fwElmb_getRawSensors
                        fwElmb_getUserDefinedFct
                        fwElmb_getAvailableNodeIdList
                        fwElmb_getAvailableBitList
                        fwElmb_setValuesToCANbus
                        fwElmb_setValuesToElmb
                        fwElmb_createCANbus
                        fwElmb_createNode (Check usage)
                        fwElmb_createConfig
                        fwElmb_createChannel
                        fwElmb_elementSQ
                        fwElmb_monitorElmbStateCbk
                        fwElmb_monitorElmbEMCbk
                        fwElmb_monitorOpcCbk
                        fwElmb_activatePortAMasks

Constraints: None

Usage: Public

PVSS manager usage: VISION, CTRL

@author Fernando Varela (EP-ATI)
*/

#uses "fwElmb/fwElmbUser.ctl"
#uses "fwElmb/fwElmbConstants.ctl"
#uses "fwElmb/fwElmbUtils.ctl"
#uses "fwElmb/fwElmbMonitorLib.ctl"
#uses "fwElmb/fwElmbMonitorConstants.ctl"


global int g_fwElmb_isUsingBusNameInSubscription=-1;

//*****************************************************************************
// @name Function: fwElmb_channelFilter
//
// Returns a dynamic array of channels still available for the Elmb Node given.
// At present, this only works correctly if ALL channels assigned are of the
// Elmb specific Analog/Digital input/output type.
//
// @param argsDpName: DP name of Elmb to get list of non-allocated channels
//                    for.
// @param argsDpType: DP type name for channel/port type to filter for
// @param argdsAvailableChannels: List of available ports/channels are
//                                returned here
// @param argdsExceptionInfo: Details of any exceptions are returned here
// @param argsPDOdp: Optional argument giving the PDO DP to check for. If
//                   not given, the default PDO is assumed. This value is
//                   (currently) only checked for analog inputs
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
void fwElmb_channelFilter(string argsDpName,
                          string argsDpType,
                          dyn_string &argdsAvailableChannels,
                          dyn_string &argdsExceptionInfo,
                          string argsPDOdp = "",
                          bool argbFilter = true)
{
// Local Variables
// ---------------
  int i;

  string sElement;

  dyn_string dsChildren;
  dyn_string dsChannels;
  dyn_string dsAllocatedChannelIDs;
  dyn_string dsTypes;
  dyn_string dsTemp;

  const dyn_string ELMB_DI_CHANNELS = makeDynString("F;0", "F;1", "F;2", "F;3", "F;4", "F;5", "F;6", "F;7",
                                                    "A;0", "A;1", "A;2", "A;3", "A;4", "A;5", "A;6", "A;7",
                                                    "D;0", "D;1", "D;2", "D;3", "D;4", "D;5", "D;6", "D;7",
                                                    "E;0", "E;1", "E;2", "E;3", "E;4", "E;5", "E;6", "E;7",
                                                    "C;0", "C;1", "C;2", "C;3", "C;4", "C;5", "C;6", "C;7");
  const dyn_string ELMB_DO_CHANNELS = makeDynString("C;0", "C;1", "C;2", "C;3", "C;4", "C;5", "C;6", "C;7",
                                                    "A;0", "A;1", "A;2", "A;3", "A;4", "A;5", "A;6", "A;7");
  const dyn_string ELMB_AI_SDO_CHANNELS = makeDynString("0","1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16",
                                                        "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32",
                                                        "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48",
                                                        "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "63");
  const dyn_string ELMB_AO_CHANNELS = makeDynString("0","1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16",
                                                    "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32",
                                                    "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48",
                                                    "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "63");

// Executable Code
// ---------------
  // Set some base information
  if (argsDpType == ELMB_AI_TYPE_NAME) {
    // Easier to handle these with dedicated function due to complications
    fwElmb_aiChannelFilter(argsDpName, argdsAvailableChannels, argdsExceptionInfo, argsPDOdp, argbFilter);
    return;
  } else if (argsDpType == ELMB_AI_SDO_TYPE_NAME) {
    sElement = ".channel";
    argdsAvailableChannels = ELMB_AI_SDO_CHANNELS;
    dsTypes = makeDynString(ELMB_AI_SDO_TYPE_NAME);
  } else if (argsDpType == ELMB_AO_TYPE_NAME) {
    sElement = ".channel";
    argdsAvailableChannels = ELMB_AO_CHANNELS;
    dsTypes = makeDynString(ELMB_AO_TYPE_NAME);
  } else if ((argsDpType == ELMB_DI_TYPE_NAME) || (argsDpType == ELMB_DO_TYPE_NAME)) {
    sElement = ".id";
    dsTypes = makeDynString(ELMB_DI_TYPE_NAME, ELMB_DO_TYPE_NAME);
    if (argsDpType == ELMB_DI_TYPE_NAME)
      argdsAvailableChannels = ELMB_DI_CHANNELS;
    else
      argdsAvailableChannels = ELMB_DO_CHANNELS;
  } else {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "fwElmb_channelFilter(): Must filter using Elmb specific channel type",
                      "");
    return;
  }

  // Obtain all children of the given Elmb Config(s)
  dynClear(dsChildren);
  for (i = 1; i <= dynlen(dsTypes); i++) {
    dsTemp = dpNames(argsDpName + "*", dsTypes[i]);
    dynAppend(dsChildren, dsTemp);
  }

  // Loop through all children, finding the allocated IDs for the correct PDO type
  for (i = 1; i <= dynlen(dsChildren); i++) {
    dpGet(dsChildren[i] + sElement, dsChannels);
    dynAppend(dsAllocatedChannelIDs, dsChannels);
  }

  // Loop through all allocated channels, removing them from the list
  for (i = 1; i <= dynlen(dsAllocatedChannelIDs); i++)
    dynRemove(argdsAvailableChannels, dynContains(argdsAvailableChannels, dsAllocatedChannelIDs[i]));

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_aiChannelFilter
//
// Returns a dynamic array of analog input channels still available for the
// Elmb Node given.
//
// @param argsDpName: DP name of Elmb to get list of non-allocated channels
//                    for.
// @param argdsAvailableChannels: List of available channels are returned here
// @param argdsExceptionInfo: Details of any exceptions are returned here
// @param argsPDOdp: Optional argument giving the PDO DP to check for. If
//                   not given, the default PDO is assumed.
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
void fwElmb_aiChannelFilter(string argsDpName,
                            dyn_string &argdsAvailableChannels,
                            dyn_string &argdsExceptionInfo,
                            string argsPDOdp = "",
                            bool argbFilter = true)
{
// Local Variables
// ---------------
  bool bMuxAll;

  int i;
  int iMaxChannels;
  int iChannelNumber;

  string sProfile;
  string sTemp;

  dyn_string dsChildren;
  dyn_string dsChannels;
  dyn_string dsAllocatedChannelIDs;
  dyn_string dsTypes;
  dyn_string dsPDOdps;
  dyn_string dsTemp;

  const dyn_string ELMB_AI_CHANNELS = makeDynString("0","1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16",
                                                    "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32",
                                                    "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48",
                                                    "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63");

// Executable Code
// ---------------
  // Check which PDO DP to check for
  if ((argsPDOdp == "") || (argsPDOdp == ELMB_NO_INFO)) {
    argsPDOdp = ELMB_NO_INFO;
    argdsAvailableChannels = ELMB_AI_CHANNELS;
  } else {
    // Get required information for this PDO
    dpGet(argsPDOdp + ".profile", sProfile,
          argsPDOdp + ".mux.timesMuxed", iMaxChannels,
          argsPDOdp + ".mux.all", bMuxAll,
          argsPDOdp + ".mux.number", iChannelNumber);
    if ((sProfile == "404") || (sProfile == "LMB")) {
      if (bMuxAll) {
        for (i = 0; i < iMaxChannels; i++)
          dynAppend(argdsAvailableChannels, i);
      } else {
        // Only a single channel is available
        argdsAvailableChannels = makeDynString(iChannelNumber);
      }
    } else {
      // Channel number does not apply to profile 401
      argdsAvailableChannels = makeDynString(ELMB_CHANNEL_NA);
    }
  }

  if (argbFilter) {
    // Get all sensors using this PDO
    dpGet(ELMB_SENSOR_INFO_NAME + ".types", dsTemp,
          ELMB_SENSOR_INFO_NAME + ".pdoDp", dsPDOdps);
    for (i = 1; i <= dynlen(dsPDOdps); i++) {
      if (dsPDOdps[i] == argsPDOdp)
        dynAppend(dsTypes, dsTemp[i]);
  }

  // Obtain all children of the given Elmb Config(s) using any of the relevant sensors
  dynClear(dsChildren);
  dsTemp = dpNames(argsDpName + "*", ELMB_AI_TYPE_NAME);
  for (i = 1; i <= dynlen(dsTemp); i++) {
    dpGet(dsTemp[i] + ".type", sTemp);
    if (dynContains(dsTypes, sTemp) > 0)
      dynAppend(dsChildren, dsTemp[i]);
  }

  // Loop through all children, finding the allocated IDs for the correct PDO type
  for (i = 1; i <= dynlen(dsChildren); i++) {
    dpGet(dsChildren[i] + ".channel", dsChannels);
    dynAppend(dsAllocatedChannelIDs, dsChannels);
  }

  // Loop through all allocated channels, removing them from the list
  for (i = 1; i <= dynlen(dsAllocatedChannelIDs); i++)
    dynRemove(argdsAvailableChannels, dynContains(argdsAvailableChannels, dsAllocatedChannelIDs[i]));
  }
  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_getFwName
//
// Returns a name which takes into account the FW naming convention for the HW
// devices
//
// @param argsCANbusName: To be done...
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Fernando Varela
//*****************************************************************************
void fwElmb_getFwName(string argsUserName,
                      string argsDpParentName,
                      string &argsDpName)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Create framework name
  argsDpName = argsDpParentName + fwDevice_HIERARCHY_SEPARATOR + argsUserName;

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_getChannelName
//
// Returns the fully qualified framework path name for an Elmb channel. The
// channel can be analog or digital, input or output.
//
// @param argsUserName: Lowest level part of name (string) for the channel. This
//                      must not include the framework 'path'
// @param argsParentName: Name of datapoint that the channel will be created
//                        under. This datapoint must be of either Elmb node type
//                        or the relevant configuration type (i.e. A/D i/p)
// @param argsChannelType: Datapoint type name of channel to get full name for
// @param argsChannelName: The fully qualified framework path name for the
//                          channel requested
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_getChannelName(string argsUserName,
                           string argsParentName,
                           string argsChannelType,
                           string &argsChannelName,
                           dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sConfigSeparator;
  string sParentType;

  dyn_string dsTmp;

// Executable Code
// ---------------
  // Get parent type
  sParentType = dpTypeName(argsParentName);

  // Check which channel type is being created
  if (argsChannelType == ELMB_AI_TYPE_NAME) {
    sConfigSeparator = ELMB_AI_CONFIG_NAME;
  } else if (argsChannelType == ELMB_AI_SDO_TYPE_NAME) {
    sConfigSeparator = ELMB_AI_CONFIG_NAME;
  } else if (argsChannelType == ELMB_AO_TYPE_NAME) {
    sConfigSeparator = ELMB_AO_CONFIG_NAME;
  } else if (argsChannelType == ELMB_DI_TYPE_NAME) {
    sConfigSeparator = ELMB_DI_CONFIG_NAME;
  } else if (argsChannelType == ELMB_DO_TYPE_NAME) {
    sConfigSeparator = ELMB_DO_CONFIG_NAME;
  } else {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_getChannelName(): Unknown channel type requested, \"" + argsChannelType,
          "");
    return;
  }

  if (ELMB_TYPE_NAME == sParentType) {
    argsChannelName = argsParentName + fwDevice_HIERARCHY_SEPARATOR +
                      sConfigSeparator + fwDevice_HIERARCHY_SEPARATOR +
                      argsUserName;
  } else if ((ELMB_AI_CONFIG_TYPE_NAME == sParentType) ||
             (ELMB_AO_CONFIG_TYPE_NAME == sParentType) ||
             (ELMB_DI_CONFIG_TYPE_NAME == sParentType) ||
             (ELMB_DO_CONFIG_TYPE_NAME == sParentType)) {
    argsChannelName = argsParentName + fwDevice_HIERARCHY_SEPARATOR +
                      argsUserName;
  } else {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_getChannelName(): Parent given is invalid for this function, \"" + argsParentName,
          "");
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_checkSensorPrefix
//
// Returns whether the sensor prefix given is valid or not, taking into account
// whether the text given has already been defined for a raw sensor (which
// means that an OPC item will be defined with that name, and therefore a
// conflict would occur).
//
// @param sSensorName: Prefix of sensor to check
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
bool fwElmb_checkSensorPrefix(string sSensorName)
{
// Local Variables
// ---------------
  bool bValid = false;

  dyn_string dsPDOdps;
  dyn_string dsPDONames;

// Executable Code
// ---------------
  // Get all raw value sensor PDOs
  fwElmb_getRawSensors(dsPDONames, dsPDOdps);

  // Check for reserved name
  if (dynContains(dsPDONames, sSensorName) == 0)
    bValid = true;

  // Return to calling routine
  return (bValid);
}

//*****************************************************************************
// @name Function: fwElmb_getRawSensors
//
// Returns the names and corresponding informational DPs for any raw sensors
// defined in the system. The raw sensors are basically custom defined PDOs.
//
// @param dsRawSensorNames: The names of the raw sensors are returned here
// @param dsPDOInfoDps: The Info DPs for the raw sensors are returned here
// @param sDirection: (Optional) Can be "IN", "OUT" or "BOTH". If not "BOTH"
//                    then only raw sensors for the given direction are returned
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
void fwElmb_getRawSensors(dyn_string &dsRawSensorNames,
                          dyn_string &dsPDOInfoDps,
                          string sDirection = "BOTH")
{
// Local Variables
// ---------------
  int i;

  string sName;
  string sDir;

  dyn_string dsInPDOs;
  dyn_string dsOutPDOs;
  dyn_string dsInNames;
  dyn_string dsOutNames;
  dyn_string dsPDOdps;

// Executable Code
// ---------------
  // Get all raw value sensor PDOs
  dsPDOdps = dpNames("*", ELMB_PDO_INFO_TYPE_NAME);

  // Get the variables for return
  dynClear(dsRawSensorNames);
  dynClear(dsPDOInfoDps);

  // Loop through all raw sensors defined
  for (i = 1; i <= dynlen(dsPDOdps); i++) {
    dpGet(dsPDOdps[i] + ".name", sName,
          dsPDOdps[i] + ".direction", sDir);
    if (sDir == "IN") {
      dynAppend(dsInNames, sName);
      dynAppend(dsInPDOs, dsPDOdps[i]);
    } else if (sDir == "OUT") {
      dynAppend(dsOutNames, sName);
      dynAppend(dsOutPDOs, dsPDOdps[i]);
    }
  }

  // Depending on requested operation, setup return values
  if (sDirection != "OUT") {
    // Assume either "IN" or "BOTH" requested, so add inputs with default at start
    dynAppend(dsRawSensorNames, ELMB_AI_PREFIX);
    dynAppend(dsPDOInfoDps, ELMB_NO_INFO);  // There isn't a DP for the default
    dynAppend(dsRawSensorNames, dsInNames);
    dynAppend(dsPDOInfoDps, dsInPDOs);
  }

  if (sDirection != "IN") {
    // Assume either "OUT" or "BOTH" requested, so add outputs with default at start
    dynAppend(dsRawSensorNames, ELMB_AO_PREFIX);
    dynAppend(dsPDOInfoDps, ELMB_NO_INFO);  // There isn't a DP for the default
    dynAppend(dsRawSensorNames, dsOutNames);
    dynAppend(dsPDOInfoDps, dsOutPDOs);
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_getUserDefinedFct
//
// Returns the function for an ELMB sensor from the function template, the list
// of ELMB channels and the parameters
//
// @param argsFctTemplate: Function template
// @param argdsChannelNumber: List of ELMB channels used in the function template
// @param argdfParameters: list of parameters used in the function template
// @param argsFct: Returned function
// @param argdsExceptionInfo: Exception handler
// @param argbOnlyChannels: Flag to indicate whether to only substitute channels
//                          and not parameters (Optional, default is false)
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
void fwElmb_getUserDefinedFct(  string argsFctTemplate,
                               dyn_string argdsChannelNumber,
                               dyn_float argdfParameters,
                               string &argsFct,
                               dyn_string &argdsExceptionInfo,
                               bool argbOnlyChannels = false)
{
// Local Variables
// ---------------
  int i;

  string sChannelToReplace;
  string sParameterToReplace;
  string sParameterFormatted;

  dyn_string dsTemp;

// Executable Code
// ---------------
  argsFct = argsFctTemplate;

  // Find out how many channels were are using.
  for (i = 1; i <= dynlen(argdsChannelNumber); i++) {
    sChannelToReplace = "%c" + i;

    if (!patternMatch("*" + sChannelToReplace + "*", argsFctTemplate)) {
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "Inconsistency: The number of channels given do\nnot match the formula template. Aborting action...",
                        "");
      return;
    }

    // Enter the actual channel values into the function
    strreplace(argsFct, sChannelToReplace, argdsChannelNumber[i]);
  }

  if (!argbOnlyChannels) {
    for(i = 1; i <= dynlen(argdfParameters); i++) {
      sParameterToReplace = "%x" + i;

      if (!patternMatch("*" + sParameterToReplace + "*", argsFctTemplate)) {
        fwException_raise(argdsExceptionInfo,
                          "ERROR",
                          "Inconsistency: The number of parameters given do\nnot match the formula template. Aborting action...",
                          "");
        return;
      }
      sParameterFormatted = argdfParameters[i];

      // Check for 'e' notation
      dsTemp = strsplit(sParameterFormatted, "e");
      if (dynlen(dsTemp) < 2)
        dsTemp = strsplit(sParameterFormatted, "E");

      if (dynlen(dsTemp) > 1) {
        // Check for decimal point
        if (strpos(dsTemp[1], ".") < 0)
          sParameterFormatted = dsTemp[1] + ".e" + dsTemp[2];
      }

      // Enter the actual parameter values into the function
      strreplace(argsFct, sParameterToReplace, sParameterFormatted);
    }

    // Remove any and all spaces
    strreplace(argsFct, " ", "");

    // Replace any double minus with plus
    strreplace(argsFct, "--", "+");

    // Replace any double plus with plus
    strreplace(argsFct, "++", "+");

    // Replace any plus/minus with minus
    strreplace(argsFct, "+-", "-");

    // Replace any minus/plus with minus
    strreplace(argsFct, "-+", "-");
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_getAvailableNodeIdList
//
// Returns available node IDs for a given bus in last argument.
//
// @param argsCANbusDpName: DP name of CAN bus datapoint, string
// @param argdsAvailableNodeIds: Node IDs available are returned here, dyn_string
// @param argbStandardElmb: (Optional) States whether to limit node IDs to <= 63
//                          or to allow max for 7-bit CANopen (default is to limit to 63)
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
void fwElmb_getAvailableNodeIdList(  string argsCANbusDpName,
                                    dyn_string &argdsAvailableNodeIds,
                                    bool argbStandardElmb = true)
{
// Local Variables
// ---------------
  int i;
  int iMaxNodeId = 63;

  string sElement = ".id";
  string sTemp;

  dyn_string dsChildren;
  dyn_string dsAllocatedNodeIds;

// Executable Code
// ---------------
  // Clear any existing information
  dynClear(argdsAvailableNodeIds);

  // Get all children
  dsChildren = dpNames($sDpName + "*" + sElement , ELMB_TYPE_NAME);

  // Check if any children exist
  if (dynlen(dsChildren) > 0) {
    // Get all allocated node IDs
    dpGet(dsChildren, dsAllocatedNodeIds);
  }

  // Check if standard ELMB node IDs are to be used
  if (!argbStandardElmb)
    iMaxNodeId = 127;  // Otherwise use max allowed for 7-bit CANopen

  // Create array of remaining node IDs
  for (i = 1; i <= iMaxNodeId; i++) {
    sprintf(sTemp, "%d", i);
    if (dynContains(dsAllocatedNodeIds, sTemp) == 0)
      dynAppend(argdsAvailableNodeIds, sTemp);
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_getAvailableBitList
//
// Gets the list of all available bits in a given port for a particular ELMB
// in a bus
//
// @param argsCANbusDpName: ...to be done
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
fwElmb_getAvailableBitList(  string argsElmbName,
                            string argsChannelType,
                            string argsDigitalPort,
                            dyn_string &argdsBitList,
                            dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  int i;

  dyn_string dsChannelList;
  dyn_string dsExceptionInfo;
  dyn_string dsTmp;

// Executable Code
// ---------------
  // Initialization of arrays:
  dynClear(argdsBitList);

  // Obtain all available children of the parent datapoint, i.e. all ELMB channel configs
  fwElmb_channelFilter(  argsElmbName,
                        argsChannelType,
                        dsChannelList,
                        dsExceptionInfo);

  for (i = 1; i <= dynlen(dsChannelList); i++) {

    // We assume that the ids are of the type "port;bit", e.g. A;3
     // First we check that we are dealing with the right ELMB port
    if (patternMatch(argsDigitalPort + ";*", dsChannelList[i])) {

      // If it is the good port, we split the id to extract the bit number
      dsTmp = strsplit(dsChannelList[i], ";");

      // Add this bit number to the available bit number list
      dynAppend(argdsBitList, dsTmp[2]);
    }
  } //End of loop for i over the channel list

  // Return to calling routine
  return;
}



/**
  @param dp internal dp of the subscriptions
  @param argdsExceptionInfo

  By P.Nikiel Mar 2016
  based on fwElmbUser_createUaSubscription
*/
void fwElmb_configureUaSubscription (string dp, mapping specialSettings, dyn_string& argdsExceptionInfo)
{
  dpSetWait(dp + ".Config.RequestedLifetimeCount",100);
  dpSetWait(dp + ".Config.RequestedMaxKeepAliveCount",10);
  dpSetWait(dp + ".Config.PublishingEnabled",TRUE);
  dpSetWait(dp + ".Config.Priority",0);
  dpSetWait(dp + ".Config.SubscriptionType",1);
  dpSetWait(dp + ".Config.MonitoredItems.TimestampsToReturn",1);
  dpSetWait(dp + ".Config.MonitoredItems.QueueSize",20);
  dpSetWait(dp + ".Config.MonitoredItems.DiscardOldest",TRUE);
  dpSetWait(dp + ".Config.MonitoredItems.SamplingInterval",2000);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.Trigger",2);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.DeadbandType",0);
  dpSetWait(dp + ".Config.MonitoredItems.DataChangeFilter.DeadbandValue",0.000);
  dpSetWait(dp + ".Config.RequestedPublishingInterval",500);

  for (int i=1; i<=mappinglen(specialSettings); i++)
  {
    dpSetWait(dp + mappingGetKey(specialSettings, i), mappingGetValue(specialSettings, i));
  }

  // Link it with respective OPC UA server
  dyn_anytype subscriptions;
  dpGet("_OPCUACANOPENSERVER.Config.Subscriptions",subscriptions);
  if(!dynContains(subscriptions,dp))
  {
    dynAppend(subscriptions,dp);
    dpSetWait("_OPCUACANOPENSERVER.Config.Subscriptions",subscriptions);
  }

}

//*****************************************************************************
// @name Function: fwElmb_createOpcUaSubscription
// based on fwElmb_createOPCGroup which was used for OPC DA group creation.
//*****************************************************************************
void fwElmb_createOpcUaSubscription(string argsForType,
                           string argsBus,
                           dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------

  dyn_string dsOPCGroups;

  mapping specialSubscriptionSettings;


// identify if using busName in subscription or not by checking the Device Definition (-1 not evaluated, 0 not using it, 1 usint it)
  if (g_fwElmb_isUsingBusNameInSubscription<0) g_fwElmb_isUsingBusNameInSubscription=fwElmb_checkSubscriptionBusNameConvention();

// Executable Code
// ---------------
  // Get which type is given, and select the correct OPC groups to create
  if (argsForType == ELMB_CAN_BUS_TYPE_NAME) {
    dsOPCGroups = makeDynString("_CmdReadBack", "_Value");
  } else if (argsForType == ELMB_AI_TYPE_NAME ) {
    dsOPCGroups = makeDynString("_Ai");
  } else if (argsForType == ELMB_AI_SDO_TYPE_NAME) {
  // dsOPCGroups = makeDynString("_AiSdo");
  } else if (argsForType == ELMB_AO_TYPE_NAME) {
  //  dsOPCGroups = makeDynString("_Ao");
  } else if (argsForType == ELMB_DI_TYPE_NAME)
  {
    dsOPCGroups = makeDynString("_Di");
    // Digital Inputs have special settings to profit from the "non-sampling" mode of OPC-UA
    specialSubscriptionSettings[".Config.MonitoredItems.SamplingInterval"] = 0;
    specialSubscriptionSettings[".Config.MonitoredItems.QueueSize"] = 1000;
  } else if (argsForType == ELMB_DO_TYPE_NAME) {
   // dsOPCGroups = makeDynString("_Do");
  }

  if (dynlen(dsOPCGroups) > 0) {
    string uaSubscriptionDp;
    for (int i = 1; i <= dynlen(dsOPCGroups); i++)
    {
       if (g_fwElmb_isUsingBusNameInSubscription>0) uaSubscriptionDp= "_UAsub" + dsOPCGroups[i] + "_" + argsBus;
       else uaSubscriptionDp= "_OPCUACANOPENSERVER" + dsOPCGroups[i];
      if (!dpExists(uaSubscriptionDp))
      {
        dpCreate(uaSubscriptionDp, "_OPCUASubscription");
        if (isRedundant())         dpCreate(uaSubscriptionDp+"_2", "_OPCUASubscription");
        fwElmb_configureUaSubscription(uaSubscriptionDp, specialSubscriptionSettings, argdsExceptionInfo);
      }
    }
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_setValuesToCANbus
//
// Sets initial values to the data points for a given CANbus
//
// @param argsCANbusName: Name (string) of the ELMB CAN bus to be configured
// @param argsComment: A comment/description (string) for the CAN bus
// @param argsInterfacePort: Name (string) of the interface port used
// @param argsInterfaceCard: Name (string) of the interface card type
// @param argiBusSpeed: Bus Speed in bits/s (int)
// @param argiManagement: Value (int) for bus management (NMT)
// @param argiSyncInterval: Value (int) of SYNC Interval
// @param argiNodeGuardInterval: Value (int) of Node Guard Interval
// @param argdsExceptionInfo: Dynamic string containing any and all exceptions
//                            that may have occurred during execution
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
void fwElmb_setValuesToCANbus(string argsCANbusName,
                              string argsComment,
                              string argsInterfacePort,
                              string argsInterfaceCard,
                              int argiBusSpeed,
                              int argiManagement,
                              int argiSyncInterval,
                              int argiNodeGuardInterval,
                              dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sDpeInterfaceCard = ".id";
  string sDpeInterfacePort = ".interfacePort";
  string sDpeBusSpeed = ".busSpeed";
  string sDpeManagement = ".management";
  string sDpeSyncInterval = ".syncInterval";
  string sDpeNodeGuardInterval = ".nodeGuardInterval";

// Executable Code
// ---------------
  // Check if dp does not exist
  if (!dpExists(argsCANbusName)) {
    fwException_raise(argdsExceptionInfo,
              "ERROR", "fwElmb_setValuesToCANbus(): The data point \"" + argsCANbusName + "\" does not exist",
              "");
    return;
  }

  // If no problem, set values to dpes
  dpSet(argsCANbusName + sDpeInterfacePort, argsInterfacePort,
        argsCANbusName + sDpeInterfaceCard, argsInterfaceCard,
        argsCANbusName + sDpeBusSpeed, argiBusSpeed,
        argsCANbusName + sDpeManagement, argiManagement,
        argsCANbusName + sDpeSyncInterval, argiSyncInterval,
        argsCANbusName + sDpeNodeGuardInterval, argiNodeGuardInterval);

  // Check for correct dpname
  if (!patternMatch("*.*", argsCANbusName) || !patternMatch("*.", argsCANbusName))
    argsCANbusName = argsCANbusName + ".";

  // Set the comment
  dpSetComment(argsCANbusName, argsComment);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_setValuesToElmb
//
// Sets initial values to the data points for a given ELMB
// NOTE:  Only the node Id and the management dpe are set. It does not set
//        configuration for the ADC, DAC or any other
//
// @param argsElmbName: Name (string) of the ELMB to be configured
// @param argsComment: A comment/description (string) for the ELMB
// @param argsNodeId: Value (string) containing the nodeId in decimal
// @param argdsExceptionInfo: Dynamic string containing all exceptions occurred during execution
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
void fwElmb_setValuesToElmb(string argsElmbName,
                            string argsComment,
                            string argsNodeId,
                            dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Check if dp does not exist
  if (!dpExists(argsElmbName)) {
    fwException_raise(argdsExceptionInfo,
              "ERROR", "fwElmb_setValuesToElmb(): The data point \"" + argsElmbName + "\" does not exist",
              "");
    return;
  }

  // If no problem, set values to dpes
  dpSet(argsElmbName + ".id", argsNodeId);

  // Check for correct dp name
  if (!patternMatch("*.*", argsElmbName) || !patternMatch("*.", argsElmbName))
    argsElmbName = argsElmbName + ".";

  // Set the comment
  dpSetComment(argsElmbName, argsComment);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_createCANbus
//
// Creates a DP for an Elmb/CAN Bus
//
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_createCANbus(string argsDpName,
                         dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sSystemName;
  string sDpName;

  dyn_string dsTemp;

// Executable Code
// ---------------
  // Check new dp name is not empty
  if (argsDpName == "") {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createCANBus(): The data point name must not be empty",
          "");
    return;
  }

  // Check dp does not already exist
  if (dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createCANBus(): The data point \"" + argsDpName + "\" already exists",
          "");
    return;
  }

  // Check if a system name has been given
  if (strpos(argsDpName, ":") >= 0) {
    // System name has been included, so split it out
    dsTemp = strsplit(argsDpName, ":");

    // System name may be used in future to allow Dps to be created in other systems
    sSystemName = dsTemp[1];
    sDpName = dsTemp[2];
  } else {
    sDpName = argsDpName;
  }

  // Create dp
  dpCreate(sDpName, ELMB_CAN_BUS_TYPE_NAME);

  // Check dp was created successfully
  if (!dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createCANBus(): The data point \"" + argsDpName + "\" was not\nsuccessfully created",
          "");
    return;
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_createNode
//
// Creates a dp of type Elmb.
//
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_createNode(string argsDpName,
                       dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sSystemName;
  string sDpName;

  dyn_string dsTemp;

// Executable Code
// ---------------
  // Check argument given is valid
  if (strlen(argsDpName) == 0) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createNode(): The data point name must not be empty",
          "");
    return;
  }

  // Check dp does not already exist
  if (dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createNode(): The data point\n\"" + argsDpName + "\"\nalready exists",
          "");
    return;
  }

  // Check if a system name has been given
  if (strpos(argsDpName, ":") >= 0) {
    // System name has been included, so split it out
    dsTemp = strsplit(argsDpName, ":");

    // System name may be used in future to allow Dps to be created in other systems
    sSystemName = dsTemp[1];
    sDpName = dsTemp[2];
  } else {
    sDpName = argsDpName;
  }

  // Create dp
  dpCreate(sDpName, ELMB_TYPE_NAME);

  // Check dp was created successfully
  if (dpExists(argsDpName)) {
    // Set default DP functions required
    fwDevice_setDpFunction(argsDpName, fwDevice_DPFUNCTION_SET, argdsExceptionInfo);
  } else {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createNode():  The data point\n\"" + argsDpName + "\"\nwas not successfully created",
          "");
    return;
  }

  // Set default type of the newly created node to 'ELMB'
  dpSetWait(sDpName+".type","ELMB");

  // Return to calling routine
  return;
}

/* This is internal function to generate DP comment that matches common format e.g.
   CIC CanMonitoring UXDET FPIAA5 ELMB_17
   @author P.Nikiel
 */
string fwElmb_getDpCommentNode (string sDpName)
{
  string comment;
  if (isFunctionDefined("fwAtlas_getSubdetectorId"))
  {
    string systemName = substr(getSystemName (), 0, strlen(getSystemName()) -1 );
    /* this is ATLAS , we have the convention */
    string subdet = fwAtlas_getSubdetectorId(systemName);
    // generate system name without ATL and subdetecctor name
    // check if this is standard ATLAS machine name
    string systemNameAbbrev;
    if (substr(systemName, 0, 3)=="ATL" && substr(systemName, 3,3)==subdet)
    {
      systemNameAbbrev = substr( systemName, 6);
    }
    else
      systemNameAbbrev = systemName;
    dyn_string dsTemp = strsplit(sDpName, "/");
    comment = subdet + " CanMonitoring " + systemNameAbbrev;
    for (int j=2; j<=dynlen(dsTemp); j++)
      comment +=  " " + dsTemp[j];
  }
  else
  {
    string dpel = sDpName;
    //check if description exists
    string sys =dpSubStr(dpel,DPSUB_SYS);
    string commentPre = dpGetComment(dpel);
    dyn_string elmbNodeParts;
    if (commentPre=="" || commentPre==" " || commentPre == sys+dpel )
    {
    comment+=substr(sys,0,strlen(sys)-1);
    elmbNodeParts = strsplit(sDpName,"/");
    for (int j=2;j<=dynlen(elmbNodeParts);j++)  comment+=" "+elmbNodeParts[j];
    }
  }
  return comment;

}

//*****************************************************************************
// @name Function: fwElmb_isAlertDefined
//
// Checks if alert config exists for given DPE.
// @author Piotr Nikiel
//*****************************************************************************
bool fwElmb_isAlertDefined (string dpel, dyn_string & argdsExceptionInfo)
{
  dyn_mixed alertConfigObject;
  bool isActive;
  int alertType;
  //get alert object and check if alert type exists
  fwAlertConfig_objectGet(dpel, alertConfigObject, argdsExceptionInfo);
  fwAlertConfig_objectExtractType(alertConfigObject, alertType, isActive, argdsExceptionInfo);
  return alertType!=DPCONFIG_NONE;
}


/** Returns a list of DP-Comments applicable to FwElmbNode
  @author Piotr Nikiel
*/
dyn_dyn_string fwElmb_getStandardNodeCommentsTable ()
{
  dyn_dyn_string result;
  dynAppend( result, makeDynString(".state.noToggle", "state"));
  dynAppend( result, makeDynString(".emergencyWritable.emergencyErrorCode", "emergency"));
  dynAppend( result, makeDynString(".channelInvalid", "channelValidity"));
  return result;
}

/** Returns a list of DP-Comments applicable to FwElmbCANBus
  @author Piotr Nikiel
*/
dyn_dyn_string fwElmb_getStandardBusCommentsTable ()
{
  dyn_dyn_string result;
  dynAppend( result, makeDynString(".portError", "CAN_port error"));
  return result;
}

/** Returns a list of DP-Comments applicable to FwElmbDiConfig
  @author Piotr Nikiel
*/
dyn_dyn_string fwElmb_getStandardDiConfigCommentsTable ()
{
  dyn_dyn_string result;
  dynAppend( result, makeDynString(".enable.read", "DigitalInputs Config Interrupts Enable"));
  dynAppend( result, makeDynString(".transmissionType.read", "DigitalInputs Config Transmission Type"));
  dynAppend( result, makeDynString(".eventTimer.read", "DigitalInputs Config Event Timer"));
  return result;
}

/* When standard FwElmbNode DPE' comments are empty, this will set them.
   Leaves untouched if comments are already set. */
/* TODO: this works alreay for bus and node. Just clean it up */
void fwElmb_addDpeComments (string nodeDp)
{
  dyn_dyn_string standardComments;
  if (dpTypeName(nodeDp) == ELMB_CAN_BUS_TYPE_NAME)
    standardComments = fwElmb_getStandardBusCommentsTable ();
  else if (dpTypeName(nodeDp) == ELMB_TYPE_NAME)
    standardComments = fwElmb_getStandardNodeCommentsTable ();
  else if (dpTypeName(nodeDp) == ELMB_DI_CONFIG_TYPE_NAME)
    standardComments = fwElmb_getStandardDiConfigCommentsTable ();
  else
  {
    DebugTN ("fwElmb_addDpeComments() called for incorrect type.");
    return;
  }
  for (int i=1; i<=dynlen(standardComments); i++)
  {
    string dpe = nodeDp+standardComments[i][1];
    string comment;
    if (dpGetComment( dpe, comment ) != 0)
    {
      DebugTN ("dpGetComment failed on "+dpe);
      return;
    }
    if (comment=="" || comment==" ")
    { /* ok no comment -- go ahead and set one */
      string prefix = fwElmb_getDpCommentNode (nodeDp);
      if (dpSetComment (dpe, prefix + " " + standardComments[i][2] ) != 0)
      {
        DebugTN ("Adding standard comment on "+dpe+" failed.");
        return;
      }
    }
    else
      DebugTN ("Not adding standard comment on "+dpe+" -- it already exists ");
  }
}

/* Removes (sets to empty) DPE comments on FwElmbNode for DPEs on which FWElmb normally sets comment (state.noToggle etc) */
/* @author Piotr Nikiel */
void fwElmb_deleteDpeComments (string nodeDp)
{
  dyn_dyn_string standardComments;
  if (dpTypeName(nodeDp) == ELMB_CAN_BUS_TYPE_NAME)
    standardComments = fwElmb_getStandardBusCommentsTable ();
  else if (dpTypeName(nodeDp) == ELMB_TYPE_NAME)
    standardComments = fwElmb_getStandardNodeCommentsTable ();
  for (int i=1; i<=dynlen(standardComments); i++)
  {
    if (dpSetComment (nodeDp+standardComments[i][1], "") != 0)
    {
      DebugTN ("Deleting comment on "+nodeDp+" failed.");
      return;
    }
  }
}

//*****************************************************************************
// @name Function: fwElmb_createNodeAlert
//
// A function to apply alert to any FwElmbNode's attribute if it doesnt yet exist
// @param argsDpName: FwElmbNode DP.
// @param dpeSuffix: a suffix to append to argsDpName to make intended DPE on which alert would be installed
// @param dpeDescription: a short string that describes on which fuctionality of FwElmbNode this alert is installed
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: FwElmb
// PVSS manager usage: VISION, CTRL
// @author Piotr Nikiel
//*****************************************************************************
void fwElmb_createNodeAlert (string argsDpName, string dpeSuffix, dyn_mixed alarmObject, dyn_string &argdsExceptionInfo)
{
  argsDpName = dpSubStr( argsDpName, DPSUB_DP_EL );
  string dpe = argsDpName + dpeSuffix;

  if (fwElmb_isAlertDefined( dpe, argdsExceptionInfo ) || dynlen(argdsExceptionInfo)>0)
  {
    DebugTN("Alert configuration for dp element: "+dpe+" already exists or error occured.");
    return;
  }

  fwAlertConfig_objectSet(dpe, alarmObject, argdsExceptionInfo);
  fwAlertConfig_activate(dpe, argdsExceptionInfo);

}

//*****************************************************************************
// @name Function: fwElmb_createNodeAlertHandlingStateNoToggle
//
// Creates alert handling of the ELMB's state
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: FwElmb
// PVSS manager usage: VISION, CTRL
// @author Charilaos Tsarouchas
// @author Piotr Nikiel
//*****************************************************************************
void fwElmb_createNodeAlertHandlingStateNoToggle(string argsDpName, dyn_string &argdsExceptionInfo)
{
  dyn_mixed alarmObject;

  fwAlertConfig_objectCreateDiscrete(
                alarmObject, //the object that will contain the alarm settings
                makeDynString("ok","ELMB not OPERATIONAL"),
                makeDynString("*","5"),
                makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                "", //alarm panel, if necessary
                makeDynString(""), //$-params to pass to the alarm panel, if necessary
                "", //alarm help, if needed
                false, //impulse alarm
                makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                "", //state bits that must also match for the alarm
                makeDynString("",""), //state bits that must match for each range
                argdsExceptionInfo, //exception info returned here
                FALSE,
                FALSE,
                "",
                FALSE /* store in param history */
                );

  fwElmb_createNodeAlert( argsDpName, ".state.noToggle", alarmObject, argdsExceptionInfo);
}




//*****************************************************************************
// @name Function: fwElmb_createNodeAlertHandlingEmergencyWritable
//
// Creates alert handling of the ELMB's emergencyWritable.errorCode
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: FwElmb
// PVSS manager usage: VISION, CTRL
// @author Charilaos Tsarouchas
// @author Piotr Nikiel
//*****************************************************************************
void fwElmb_createNodeAlertHandlingEmergencyWritable(string argsDpName, dyn_string &argdsExceptionInfo)
{

  dyn_mixed alarmObject;
  fwAlertConfig_objectCreateDiscrete(
                alarmObject, //the object that will contain the alarm settings
                makeDynString("ok","emergency received"),
                makeDynString("*","0"),
                makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                "", //alarm panel, if necessary
                makeDynString(""), //$-params to pass to the alarm panel, if necessary
                "", //alarm help, if needed
                false, //impulse alarm
                makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                "", //state bits that must also match for the alarm
                makeDynString("",""), //state bits that must match for each range
                argdsExceptionInfo, //exception info returned here
                  FALSE,
                FALSE,
                "",
                FALSE /* store in param history */
                 );

  fwElmb_createNodeAlert( argsDpName, ".emergencyWritable.emergencyErrorCode",  alarmObject, argdsExceptionInfo);
}

//*****************************************************************************
// @name Function: fwElmb_createNodeAlertHandlingChannelInvalid
//
// Creates alert handling of the ELMB's emergencyWritable.errorCode
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: Public
// PVSS manager usage: VISION, CTRL
// @author Charilaos Tsarouchas
// @author Piotr Nikiel
//*****************************************************************************
void fwElmb_createNodeAlertHandlingChannelInvalid (string argsDpName, dyn_string &argdsExceptionInfo)
{
  dyn_mixed alarmObject;
  fwAlertConfig_objectCreateDiscrete(
                alarmObject, //the object that will contain the alarm settings
                makeDynString("ok","channel invalid"),
                makeDynString("*","0"),
                makeDynString("","_fwWarningNack."), //classes (the 1st one must always be the good one)
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
  fwElmb_createNodeAlert( argsDpName, ".channelInvalid", alarmObject, argdsExceptionInfo);
}

void fwElmb_createNodeAlertHandling(string argsDpName, dyn_string &argdsExceptionInfo)
{
  fwElmb_createNodeAlertHandlingStateNoToggle (argsDpName, argdsExceptionInfo);
  if (dynlen(argdsExceptionInfo)>0)
    return;
  fwElmb_createNodeAlertHandlingEmergencyWritable (argsDpName, argdsExceptionInfo);
  if (dynlen(argdsExceptionInfo)>0)
    return;
  fwElmb_createNodeAlertHandlingChannelInvalid (argsDpName, argdsExceptionInfo);
  if (dynlen(argdsExceptionInfo)>0)
    return;
}

void fwElmb_removeNodeAlertHandling(string nodeDp)
{
  dyn_string exception;
  fwAlertConfig_delete(nodeDp+".state.noToggle", exception, "", false);
  fwAlertConfig_delete(nodeDp+".channelInvalid", exception, "", false);
  fwAlertConfig_delete(nodeDp+".emergencyWritable.emergencyErrorCode", exception, "", false);
}

void fwElmb_removeBusAlertHandling(string nodeDp)
{
  dyn_string exception;
  fwAlertConfig_delete(nodeDp+".portError", exception, "", false);
}

void fwElmb_createNodesAlertHandling( dyn_string &argdsExceptionInfo)
{

  dyn_string elmbNodes = dpNames(getSystemName()+"*",ELMB_TYPE_NAME);

  for(int i=1;i<=dynlen(elmbNodes);i++)
  {
   fwElmb_createNodeAlertHandling(elmbNodes[i], argdsExceptionInfo);
   if(dynlen(argdsExceptionInfo)>0) DebugTN(argdsExceptionInfo);
  }
}

void fwElmb_createDescriptionAtServerLevel( string dpel, string description)
{
  string comment;
  comment = dpGetDescription( dpel );
  // strpos below is used to handle a freshly created DPs when they have a dp name as a comment
  if (comment=="" || comment==" " || strpos(comment, dpel) >=0 )
  {
    if (isFunctionDefined("fwAtlas_getSubdetectorId"))
    {      /* this is ATLAS , we have the convention of naming systems */
      string systemName = substr(getSystemName (), 0, strlen(getSystemName()) -1 );
      string subdet = fwAtlas_getSubdetectorId(systemName);
      // generate system name without ATL and subdetecctor name
      // check if this is standard ATLAS machine name
      string systemNameAbbrev;
      if (substr(systemName, 0, 3)=="ATL" && substr(systemName, 3,3)==subdet)
      {
        systemNameAbbrev = substr( systemName, 6);
      }
      else
        systemNameAbbrev = systemName;
      comment = subdet + " CanMonitoring " + systemNameAbbrev + " " + description;
    }
    else
      comment = description;
    DebugN( "Setting comment on "+dpel);
    dpSetComment( dpel, comment );
  }
}

void fwElmb_createOpcUaConnectionStateAlert(dyn_string & argdsExceptionInfo)
{
  string dpel = "_OPCUACANOPENSERVER.State.ConnState";
  if (fwElmb_isAlertDefined(dpel, argdsExceptionInfo))
  {
    DebugTN("Alert configuration for dp element: "+dpel+" already exists.");
  }
  else
  { /* Alert on ConnState doesnt exist */
      //check if alarm config exists - if not create it
    dyn_mixed alarmObject;
    fwAlertConfig_objectCreateDiscrete(
                  alarmObject, //the object that will contain the alarm settings
                  makeDynString("ok","No OPC UA connection"),
                  makeDynString("*","1"),
                  makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                  "", //alarm panel, if necessary
                  makeDynString(""), //$-params to pass to the alarm panel, if necessary
                  "", //alarm help, if needed
                  false, //impulse alarm
                  makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                  "", //state bits that must also match for the alarm
                  makeDynString("",""), //state bits that must match for each range
                  argdsExceptionInfo ); //exception info returned here

    fwAlertConfig_objectSet(dpel, alarmObject, argdsExceptionInfo);
    if(fwElmb_getMiddlewareKind()== FWELMB_MIDDLEWARE_OPCUA)
      fwAlertConfig_activate(dpel, argdsExceptionInfo);
  }

  if (isRedundant()) {
   dpel = "_OPCUACANOPENSERVER_2.State.ConnState";
  if (fwElmb_isAlertDefined(dpel, argdsExceptionInfo))
  {
    DebugTN("Alert configuration for dp element: "+dpel+" already exists.");
  }
  else
  { /* Alert on ConnState doesnt exist */
      //check if alarm config exists - if not create it
    dyn_mixed alarmObject;
    fwAlertConfig_objectCreateDiscrete(
                  alarmObject, //the object that will contain the alarm settings
                  makeDynString("ok","No OPC UA connection"),
                  makeDynString("*","1"),
                  makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                  "", //alarm panel, if necessary
                  makeDynString(""), //$-params to pass to the alarm panel, if necessary
                  "", //alarm help, if needed
                  false, //impulse alarm
                  makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                  "", //state bits that must also match for the alarm
                  makeDynString("",""), //state bits that must match for each range
                  argdsExceptionInfo ); //exception info returned here

    fwAlertConfig_objectSet(dpel, alarmObject, argdsExceptionInfo);
    if(fwElmb_getMiddlewareKind()== FWELMB_MIDDLEWARE_OPCUA)
      fwAlertConfig_activate(dpel, argdsExceptionInfo);
  }


  }
}


// @author Piotr Nikiel
// @date 10 Feb 2015
// Introduced fwElmb 5.2.13
void fwElmb_createOpcUaTimeoutAlert(dyn_string & argdsExceptionInfo)
{
  string dpel = "_OPCUACANOPENSERVER.State.TimeoutError";
  if (fwElmb_isAlertDefined(dpel, argdsExceptionInfo))
  {
    DebugTN("Alert configuration for dp element: "+dpel+" already exists.");
  }
  else
  { /* Alert on ConnState doesnt exist */
      //check if alarm config exists - if not create it
    dyn_mixed alarmObject;
    fwAlertConfig_objectCreateDiscrete(
                  alarmObject, //the object that will contain the alarm settings
                  makeDynString("ok","Timeout"),
                  makeDynString("0","0"),
                  makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                  "", //alarm panel, if necessary
                  makeDynString(""), //$-params to pass to the alarm panel, if necessary
                  "", //alarm help, if needed
                  false, //impulse alarm
                  makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                  "", //state bits that must also match for the alarm
                  makeDynString("",""), //state bits that must match for each range
                  argdsExceptionInfo ); //exception info returned here

    fwAlertConfig_objectSet(dpel, alarmObject, argdsExceptionInfo);
    if(fwElmb_getMiddlewareKind()== FWELMB_MIDDLEWARE_OPCUA)
      fwAlertConfig_activate(dpel, argdsExceptionInfo);
  }

  if (isRedundant()) {
    dpel = "_OPCUACANOPENSERVER_2.State.TimeoutError";
  if (fwElmb_isAlertDefined(dpel, argdsExceptionInfo))
  {
    DebugTN("Alert configuration for dp element: "+dpel+" already exists.");
  }
  else
  { /* Alert on ConnState doesnt exist */
      //check if alarm config exists - if not create it
    dyn_mixed alarmObject;
    fwAlertConfig_objectCreateDiscrete(
                  alarmObject, //the object that will contain the alarm settings
                  makeDynString("ok","Timeout"),
                  makeDynString("0","0"),
                  makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                  "", //alarm panel, if necessary
                  makeDynString(""), //$-params to pass to the alarm panel, if necessary
                  "", //alarm help, if needed
                  false, //impulse alarm
                  makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                  "", //state bits that must also match for the alarm
                  makeDynString("",""), //state bits that must match for each range
                  argdsExceptionInfo ); //exception info returned here

    fwAlertConfig_objectSet(dpel, alarmObject, argdsExceptionInfo);
    if(fwElmb_getMiddlewareKind()== FWELMB_MIDDLEWARE_OPCUA)
      fwAlertConfig_activate(dpel, argdsExceptionInfo);
  }


  }
}

//*****************************************************************************
// @name Function: fwElmb_createOpcServerAlertHandling
//
// Creates alert handling of the OPCUAServer internal dp item(s)
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: Public
// PVSS manager usage: VISION, CTRL
// @author Charilaos Tsarouchas
//*****************************************************************************
void fwElmb_createOpcServerAlertHandling(string systemName, dyn_string &argdsExceptionInfo)
{

  fwElmb_createOpcUaConnectionStateAlert(argdsExceptionInfo);
  fwElmb_createDescriptionAtServerLevel("_OPCUACANOPENSERVER.State.ConnState", "OPC UA Connection state");
  if (isRedundant())   fwElmb_createDescriptionAtServerLevel("_OPCUACANOPENSERVER_2.State.ConnState", "OPC UA Connection state");

  fwElmb_createOpcUaTimeoutAlert(argdsExceptionInfo);
  fwElmb_createDescriptionAtServerLevel("_OPCUACANOPENSERVER.State.TimeoutError", "OPC UA Timeout");
  if (isRedundant())   fwElmb_createDescriptionAtServerLevel("_OPCUACANOPENSERVER_2.State.TimeoutError", "OPC UA Timeout");

}



//*****************************************************************************
// @name Function: fwElmb_createBusAlertHandling
//
// Creates alert handling of the portError attribute of a CAN bus.
// @param argsDpName: A name for the new data point. System name not required
// @param argdsExceptionInfo: Details of any exceptions are returned here
// Constraints:
// Usage: Public
// PVSS manager usage: VISION, CTRL
// @author Charilaos Tsarouchas, Piotr Nikiel
//*****************************************************************************
void fwElmb_createBusAlertHandling(string argsDpName="", dyn_string &argdsExceptionInfo)
{
  string sSystemName;
  string sDpName;

  dyn_string dsTemp;



  // Check argument given is valid
  if (strlen(argsDpName) == 0)
    {
      fwException_raise(argdsExceptionInfo,  "ERROR","fwElmb_createBusAlertHandling(): The data point name must not be empty", "");
      return;
    }


  // Check if a system name has been given
  if (strpos(argsDpName, ":") >= 0)
    {
    dsTemp = strsplit(argsDpName, ":");
    sSystemName = dsTemp[1];
    sDpName = dsTemp[2];
    }
    else
    sDpName = argsDpName;

  //Create the alert config
  string dpel = sDpName+".portError";

 if (fwElmb_isAlertDefined( dpel, argdsExceptionInfo ))
  {
    DebugTN("Alert configuration for dp element: "+dpel+" already exists.");
    return;
  }

  //check if alarm config exists - if not create it
  dyn_mixed alertConfigObject;

  //Create the alert config
  
  //check if alarm config exists - if not create it
  dyn_mixed alarmObject;
  fwAlertConfig_objectCreateDiscrete(
                alarmObject, //the object that will contain the alarm settings
                makeDynString("ok","CAN port error"),
                makeDynString("*","0"),
                makeDynString("","_fwErrorNack."), //classes (the 1st one must always be the good one)
                "", //alarm panel, if necessary
                makeDynString(""), //$-params to pass to the alarm panel, if necessary
                "", //alarm help, if needed
                false, //impulse alarm
                makeDynBool(0,1), //negation of the matching (0 means "=", 1 means "!=")
                "", //state bits that must also match for the alarm
                makeDynString("",""), //state bits that must match for each range
                argdsExceptionInfo, //exception info returned here  ,
                FALSE,
                FALSE,
                "",
                FALSE /* store in param history */
                );


  fwAlertConfig_objectSet(dpel, alarmObject, argdsExceptionInfo);
  fwAlertConfig_activate(dpel, argdsExceptionInfo);


}

void fwElmb_createBusesAlertHandling (dyn_string &argdsExceptionInfo)
{
   dyn_string buses = dpNames(getSystemName()+"*",ELMB_CAN_BUS_TYPE_NAME);

  for(int i=1;i<=dynlen(buses);i++)
  {
   fwElmb_createBusAlertHandling(buses[i], argdsExceptionInfo);
   if(dynlen(argdsExceptionInfo)>0) DebugTN(argdsExceptionInfo);
  }
}


//*****************************************************************************
// @name Function: fwElmb_createConfig
//
// Creates a dp for configuration of Elmb settings.
//
// @param argsDpName: A name for the new data point. System name not required
// @param argsDpType: Exact DP type to create. Different types exist for
//                    Analog/Digital input/output
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_createConfig(  string argsDpName,
                          string argsDpType,
                          dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Check new dp name is not empty
  if (argsDpName == "") {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createConfig(): The data point name must not be empty",
          "");
    return;
  }

  // Check dp does not already exist
  if (dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createConfig(): The data point \"" + argsDpName + "\" already exists",
          "");
    return;
  }

  // Create dp
  dpCreate(argsDpName, argsDpType);

  // Check dp was created successfully
  if (dpExists(argsDpName)) {
    // Set default DP functions, only for analog input config
    if (argsDpType == ELMB_AI_CONFIG_TYPE_NAME)
      fwDevice_setDpFunction(argsDpName, fwDevice_DPFUNCTION_SET, argdsExceptionInfo);
  } else {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createConfig():  The data point \"" + argsDpName + "\" was not\nsuccessfully created",
          "");
    return;
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_createChannel
//
// Creates a DP for an Elmb channel
//
// @param argsDpName: A name for the new data point. System name not required
// @param argsComment: A comment (string) that will be applied to the DP and
//                      the 'value' DPE
// @param argsDpType: Exact DP type to create (string). Different types exist
//                    for Analog/Digital input/output
// @param argsSensorType: A value (string) that is the sensor type for this
//                        channel
// @param argdsChannelID: The channel(s) (dyn_string) that this sensor
//                        uses
// @param argsFct: The function (string) which will be used in the OPC Server
//                  configuration file in the [ITEM] section
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_createChannel(string argsDpName,
                          string argsComment,
                          string argsDpType,
                          string argsSensorType,
                          dyn_string argdsChannelID,
                          string argsFct,
                          dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
// None

// Executable Code
// ---------------
  // Check new dp name is not empty
  if (argsDpName == "") {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createChannel(): The data point name must not be empty",
          "");
    return;
  }

  // Check dp does not already exist
  if (dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createChannel(): The data point \"" + argsDpName + "\" already exists",
          "");
    return;
  }

  // Create dp
  dpCreate(argsDpName, argsDpType);

  // Check dp was created successfully
  if (!dpExists(argsDpName)) {
    fwException_raise(argdsExceptionInfo,
          "ERROR",
          "fwElmb_createChannel():  The data point \"" + argsDpName + "\" was not\nsuccessfully created",
          "");
    return;
  }

  // If everything ok, we set dp Comment:
  if (!patternMatch("*.*", argsDpName) || !patternMatch("*.", argsDpName))
    argsDpName = argsDpName + ".";
  dpSetComment(argsDpName, argsComment);

  // Check if type is Elmb specific
  if (argsDpType == ELMB_AI_TYPE_NAME) {
    // Set Analog input channel ID and other information
    dpSet(argsDpName + "channel", argdsChannelID,
          argsDpName + "function", argsFct,
          argsDpName + "type", argsSensorType);

    // Set comment on value DPE also
    dpSetComment(argsDpName + "value", argsComment);

  } else if (argsDpType == ELMB_AI_SDO_TYPE_NAME) {
    // Set SDO Analog input channel ID
    dpSet(argsDpName + "channel", argdsChannelID[1]);

    // Set comment on value DPE also
    dpSetComment(argsDpName + "value", argsComment);

    // Set up the DP functions required (firstly removing any trailing '.')
    argsDpName = dpSubStr(argsDpName, DPSUB_DP);
    fwDevice_setDpFunction(argsDpName, fwDevice_DPFUNCTION_SET, argdsExceptionInfo);

  } else if (argsDpType == ELMB_AO_TYPE_NAME) {
    // Set Analog output channel ID
    dpSet(argsDpName + "channel", argdsChannelID[1]);

    // Set comment on value DPE also
    dpSetComment(argsDpName + "value", argsComment);

  } else if ((argsDpType == ELMB_DI_TYPE_NAME) ||
             (argsDpType == ELMB_DO_TYPE_NAME)) {
    // Set Digital ID
    dpSet(argsDpName + "id", argdsChannelID[1]);

    // Set comment on value DPE also
    dpSetComment(argsDpName + "value", argsComment);
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_createDigitalBytes
//
// Creates a DP for Elmb digital output bytes
//
// @param argsElmb: Datapoint name of ELMB to create digital output bytes for
// @param argbOPCAddressing: Flag to indicate whether to address the datapoint
//                           created or not
// @param argdsExceptionInfo: Details of any exceptions are returned here
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
void fwElmb_createDigitalBytes(string argsElmb,
                               bool argbOPCAddressing,
                               dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  string sChannelName;
  string sOPCGroup;
  string sBus;

  dyn_string dsTemp;

// Executable Code
// ---------------
  // Digital output sensors require some extra datapoints for hardware/software consistency
  sChannelName = dpSubStr(argsElmb, DPSUB_DP) + fwDevice_HIERARCHY_SEPARATOR +
                 ELMB_DO_CONFIG_NAME + fwDevice_HIERARCHY_SEPARATOR +
                 ELMB_DO_PREFIX + "Bytes";

  if (!dpExists(sChannelName + ".")) {
    dpCreate(sChannelName, ELMB_DO_BYTES_TYPE_NAME);

    // Check dp was created successfully
    if (!dpExists(sChannelName)) {
      fwException_raise(argdsExceptionInfo,
                        "ERROR",
                        "fwElmb_createDigital():  The data point \"" + sChannelName + "\" was not\nsuccessfully created",
                        "");
      return;
    }
  }

  // OPC addressing code
  if (argbOPCAddressing)
  {
    dsTemp = strsplit(argsElmb, fwDevice_HIERARCHY_SEPARATOR);
    sBus = dsTemp[2];
    fwElmb_createOpcUaSubscription(ELMB_DO_BYTES_TYPE_NAME, sBus, argdsExceptionInfo);
    fwDevice_setAddress(sChannelName, makeDynString(fwDevice_ADDRESS_DEFAULT), argdsExceptionInfo);
  }

  // Return to calling routine
  return;
}


//*****************************************************************************
// @name Function: fwElmb_activatePortAMasks
//
// Function used to activate (or deactivate) the address config for Port A
// digital input interrupt enable and input enable masks. This is required as
// these masks are only entered into the OPC Server configuration file if needed,
// though the addressing is always present (deactivating the address stops
// any error messages)
//
// @param argsElmb: DP name of ELMB to (de)activate masks for
// @param argdsExceptionInfo: Any exceptions are returned here
// @param argbActivate: Optional argument for whether to activate or deactivate
//                      the address config. Default is true (activate)
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
void fwElmb_activatePortAMasks(string argsElmb,
                               dyn_string &argdsExceptionInfo,
                               bool argbActivate = true)
{
// Local Variables
// ---------------
  int i;
  int iType;

  dyn_string dsMaskDpes;

// Executable Code
// ---------------
  // Ensure ELMB DP name has system name
  argsElmb = dpSubStr(argsElmb, DPSUB_SYS_DP);

  // Create the DPE names required
  dsMaskDpes = makeDynString(argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DI_CONFIG_NAME + ".portAInterruptMask.read",
                             argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DI_CONFIG_NAME + ".portAInterruptMask.write",
                             argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DI_CONFIG_NAME + ".portAInEnMask.read",
                             argsElmb + fwDevice_HIERARCHY_SEPARATOR + ELMB_DI_CONFIG_NAME + ".portAInEnMask.write");

  // Loop through the DPEs and do the necessary actions
  for (i = 1; i <= dynlen(dsMaskDpes); i++) {
    dpGet(dsMaskDpes[i] + ":_address.._type", iType);
    if (iType != DPCONFIG_NONE)
      dpSet(dsMaskDpes[i] + ":_address.._active", argbActivate);
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_elementSQ
//
// Function used to single query a given DPE. There is no check that the driver
// is running.
//
// @param argsDPE: Full name of DPE to Single Query
// @param argtTimeout: Value of timeout to wait for expected response
// @param argaReadValue: The read value is returned here
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
void fwElmb_elementSQ(string argsDPE,
                      time argtTimeout,
                      anytype &argaReadValue,
                      dyn_string &argdsExceptionInfo)
{
// Local Variables
// ---------------
  bool bTimeout;
  bool bIsRunning;
  bool bRemote = false;

  int iDriverNumber;

  time tTimeNow;

  string sSystem;

  dyn_string dsDpNamesToWaitFor;
  dyn_string dsDpNamesReturn;

  dyn_anytype daConditions;
  dyn_anytype daReturnedValues;

// Executable Code
// ---------------
  // Ensure the DPE does not contain any config information
  argsDPE = dpSubStr(argsDPE, DPSUB_SYS_DP_EL);

  // Get the system name only and check for remote system
  sSystem = dpSubStr(argsDPE, DPSUB_SYS);
  if (sSystem != getSystemName())
    bRemote = true;

  // Get the driver number
  dpGet(argsDPE + ":_distrib.._driver", iDriverNumber);

  // Check if driver is running
  fwPeriphAddress_checkIsDriverRunning(iDriverNumber,
                                       bIsRunning,
                                       argdsExceptionInfo,
                                       sSystem);
  if (dynlen(argdsExceptionInfo) > 0) {
    return;
  } else if (!bIsRunning) {
    // Raise an exception
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "Driver with '-num " + iDriverNumber + "' is not running" + (bRemote ? " on remote system" : ""),
                      "");
    return;
  }

  // Set up parameters to wait for the value to be updated
  dsDpNamesToWaitFor = makeDynString(argsDPE + ":_online.._value",
                                     argsDPE + ":_online.._stime",
                                     argsDPE + ":_online.._invalid");

  dsDpNamesReturn = dsDpNamesToWaitFor;

  // Get time now
  tTimeNow = getCurrentTime();

  // For scattered systems, timing of PCs may be slightly out, therefore this is a fix
  // to try and compensate
  // tTimeNow = tTimeNow - 1;//

  // Request the required data
  dpSet(sSystem + "_Driver" + iDriverNumber + ".SQ", argsDPE);

  // Wait for up to the timeout for a value to be updated
  dpWaitForValue(dsDpNamesToWaitFor,
                 daConditions,
                 dsDpNamesReturn,
                 daReturnedValues,
                 argtTimeout,
                 bTimeout);

  // Check whether timeout has expired or value updated
  if (bTimeout) {
    fwException_raise(argdsExceptionInfo,
                      "ERROR",
                      "Value for '" + argsDPE + "', was not updated due to timeout",
                      "");
        dpSetWait(argsDPE + ":_online.._invalid", true);

  } else {
//    if (dynlen(daReturnedValues) > 1) {
//      if (daReturnedValues[2] >= tTimeNow) {
        argaReadValue = daReturnedValues[1];
        if (daReturnedValues[3])
          fwException_raise(argdsExceptionInfo,
                            "ERROR",
                            "Value for '" + argsDPE + "', is invalid",
                            "");
//      } // else {//
        // fwException_raise(argdsExceptionInfo,//
        //                  "ERROR",//
        //                  "Value for '" + argsDPE + "', was not updated",//
        //                  "");//
     // }//
//    }
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_monitorElmbStateCbk
//
// Callback used to check for certain states and then set analog input channels
// invalid if required
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
void fwElmb_monitorElmbStateCbk(string sDpState, unsigned uValueState)
{
// Local Variables
// ---------------
  bool bInvalid;

  int i;

  string sDpName;

  dyn_string dsAIs;

// Executable Code
// ---------------
  // Check for state which would not give analog input channel updates
  uValueState &= 0x7f;
  if ((uValueState == 0x04) || (uValueState == 0x7f)) {

    // Get the name of the DP from the DPE name
    sDpName = dpSubStr(sDpState, DPSUB_SYS_DP);

    // Get all analog inputs for this ELMB
    dsAIs = dpNames(sDpName + fwDevice_HIERARCHY_SEPARATOR + ELMB_AI_CONFIG_NAME + fwDevice_HIERARCHY_SEPARATOR + "*.value:_original.._aut_inv", ELMB_AI_TYPE_NAME);
    dpGet(dsAIs[1], bInvalid);
    if (!bInvalid) {
      for (i = 1; i <= dynlen(dsAIs); i++)
        dpSet(dsAIs[i], true);
    }
  }

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_monitorElmbEMCbk
//
// Callback used to check for certain emergency messages and then set analog\
// input channels invalid if required
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
void fwElmb_monitorElmbEMCbk(  string sDpErrorCode, int iValueErrorCode,
                              string sDpErrorByte1, char cValueErrorByte1,
                              string sDpErrorByte2, char cValueErrorByte2,
                              string sDpErrorByte3, char cValueErrorByte3,
                              string sDpErrorByte4, char cValueErrorByte4,
                              string sDpErrorByte5, char cValueErrorByte5,
                              string sTimetamp, time tTime)
{
// Local Variables
// ---------------
  bool bInvalid;

  int i;
  int iChannel;

  string sDpName;
  string sEmergencyMsg;

  dyn_string dsAIs;
  dyn_string dsChannels;

// Executable Code
// ---------------
  // Get the name of the DP from the DPE name
  sDpName = dpSubStr(sDpErrorCode, DPSUB_SYS_DP);

  // Check for emergency message 0x5000 0x01
  if ((iValueErrorCode == 0x5000) && (cValueErrorByte1 == 1)) {

    // Get all analog inputs for this ELMB
    dsAIs = dpNames(sDpName + fwDevice_HIERARCHY_SEPARATOR + ELMB_AI_CONFIG_NAME + fwDevice_HIERARCHY_SEPARATOR + "*", ELMB_AI_TYPE_NAME);
    dpGet(dsAIs[1], bInvalid);
    if (!bInvalid) {
      // Set all necessary channels invalid (simulating 'invalid by driver',
      // just as OPC server would do)
      for (i = 1; i <= dynlen(dsAIs); i++) {
        dpGet(dsAIs[i] + ".channel", dsChannels);
        iChannel = dsChannels[1];
        if (iChannel >= cValueErrorByte2)
          dpSet(dsAIs[i] + ".value:_original.._aut_inv", true);
      }
    }

/*
    // Cannot set 'online_value', so remove it (then dpSet uses default of 'original_value')
    strreplace(sDpErrorCode, ":_online.._value", "");
    strreplace(sDpErrorByte1, ":_online.._value", "");
    strreplace(sDpErrorByte2, ":_online.._value", "");
    strreplace(sDpErrorByte3, ":_online.._value", "");
    strreplace(sDpErrorByte4, ":_online.._value", "");
    strreplace(sDpErrorByte5, ":_online.._value", "");

    // Zero these parts of the emergenecy message
    // These parts of the emergency message are zeroed so that if another emergency message
    // with the same values is received, we still capture it
    dpSet(sDpErrorCode, 0,
          sDpErrorByte1, 0,
          sDpErrorByte2, 0,
          sDpErrorByte3, 0,
          sDpErrorByte4, 0,
          sDpErrorByte5, 0);
*/
  }
  sprintf(sEmergencyMsg, "0x%04x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x @ %s",
          iValueErrorCode & 0xffff,
          cValueErrorByte1,
          cValueErrorByte2,
          cValueErrorByte3,
          cValueErrorByte4,
          cValueErrorByte5,
          formatTime("%d.%m.%Y %H:%M:%S", tTime, ".%03d"));
  dpSet(sDpName + ".monitoring.emergencyMessage.fullText", sEmergencyMsg);

  // Return to calling routine
  return;
}

//*****************************************************************************
// @name Function: fwElmb_monitorOpcCbk
//
// Callback used to check for certain states and then set analog input channels
// invalid if required
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
void fwElmb_monitorOpcCbk(string sDpServerConnected, bool bServerConnected)
{
// Local Variables
// ---------------
  bool bInvalid;

  int i, j;

  dyn_string dsAIs;
  dyn_string dsElmbs;

// Executable Code
// ---------------
  if (!bServerConnected) {

    // Get all ELMBs in the system
    dsElmbs = dpNames(getSystemName() + "*", ELMB_TYPE_NAME);

    // Loop through the ELMBs found
    for (i = 1; i <= dynlen(dsElmbs); i++) {

      // Get all analog inputs for this ELMB and set them invalid
      dsAIs = dpNames(dsElmbs[i] + fwDevice_HIERARCHY_SEPARATOR + ELMB_AI_CONFIG_NAME + fwDevice_HIERARCHY_SEPARATOR + "*.value:_original.._aut_inv", ELMB_AI_TYPE_NAME);
      dpGet(dsAIs[1], bInvalid);
      for (j = 1; j <= dynlen(dsAIs); j++)
        dpSet(dsAIs[j], true);
    }
  }

  // Return to calling routine
  return;
}


//*****************************************************************************
// @name Function: fwElmb_cbkDOinitialisation
// fwElmb 5.2.13: to avoid unnecessary double dpConnect on .state, this callback will be now called
// from fwElmbUser_monitorStateDisconnectedCbk
//
// Callback used to check if any ELMB that has DO defined became operationnal
// In this case, fwElmbUser_synchronizeDoBytes() executed.
//
//
// Modification History: fwelmb 5.2.13
//
// Constraints: None
// @param: sDp ELMB's DP
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Olivier Gutzwiller
// @author Piotr Nikiel
//*****************************************************************************
fwElmb_cbkDOinitialisation(string sDp, int iNewValue, int iOldValue)
  {
  // Local Variables
  // ---------------
  dyn_string argdsExceptionInfo;
  iNewValue &= 0x7f;
  iOldValue &= 0x7f;
  if ((iNewValue == 0x05) && (iOldValue != 0x05))
    fwElmbUser_synchronizeDoBytes(sDp, argdsExceptionInfo);
  return;
}


//*********************************************************************************
// Correction of constant parameters for temperature calculation of NTC sensors
// Target component : FwElmb (any version)
// Date : 14/12/09
// @author Sebastien Franz, Olivier Gutzwiller
//
// Note from P.Nikiel 08/04/2016: The function below is buggy because it ignores the preresistance (blindly assuming 1MOhm)
// Since fwElmb 5.3.1 it won't be used - it stays here for potential fix in future.
//*********************************************************************************

fwElmb_updateNTC()
{
  //temperature calculation formula (Steinhart and Hart):
  // T = 1/(a + b*Ln(R) + c*(Ln(R))^3)
  string a = "1.129241e-3";
  string b = "2.341077e-4";
  string c = "8.775468e-8";

  string dpType,fct,sensorStr,aiStr,channel;
  dyn_string dplist;

  //Get all NTC DP of type FwElmbAi in the system
  dyn_string dpELMBai = dpNames(getSystemName() + "*","FwElmbAi");
  for(int i = 1; i <= dynlen(dpELMBai); i++)
  {
    dpGet(dpELMBai[i] + ".type",dpType);
    if(dpType == "NTC 10 kOhm")
      dynAppend(dplist,dpELMBai[i]);
  }
  DebugTN("Found " + dynlen(dplist) + " NTC in system " + getSystemName());

  //Replace formula with new constant parameters
  for(int i = 1; i <= dynlen(dplist); i++)
  {
    dpGet(dplist[i] + ".channel",channel);
    //DebugN("channel " + channel);
    sensorStr = strsplit(dplist[i],"/")[2] + "." +
                strsplit(dplist[i],"/")[3] + "." +
                strsplit(dplist[i],"/")[5];
    aiStr = strsplit(dplist[i],"/")[2] + "." +
            strsplit(dplist[i],"/")[3] + "." +
            "ai_" + channel;
    fct = sensorStr + " = 1/(" + a + " + " + b +
          "*log(1.e-6*"+ aiStr + "*1000000/(2.5-1.e-6*" +
          aiStr + "))+" + c + "*pow(log(1000000*1.e-6*" +
          aiStr + "/(2.5-1.e-6*" + aiStr + ")),3))-273.15";
    dpSet(dplist[i] + ".function",fct);
    DebugTN("NTC " + dplist[i] + " updated!");
  }
  DebugN("NTC update done!");
}

string fwElmb_getMiddlewareKind ()
{
  if (!dpExists ("_FwElmbGlobal"))
    return FWELMB_MIDDLEWARE_OPCDA;
  else
  {
    string kind;
    dpGet ("_FwElmbGlobal.middlewareKind", kind);
    if (kind == FWELMB_MIDDLEWARE_OPCDA || kind == FWELMB_MIDDLEWARE_OPCUA)
      return kind;
    else
    {
      DebugTN("ERROR fwElmb_getMiddlewareKind: strange value at _FwElmbGlobal.middlewareKind");
      return FWELMB_MIDDLEWARE_OPCDA;
    }
  }
}

void fwElmb_setMiddlewareKind(string kind)
{
  if (kind!=FWELMB_MIDDLEWARE_OPCDA && kind!=FWELMB_MIDDLEWARE_OPCUA)
    return;
  if (!dpExists ("_FwElmbGlobal"))
  {
    dpCreate ("_FwElmbGlobal", "_FwElmbGlobal");
  }
  dpSet ("_FwElmbGlobal.middlewareKind", kind);

}

/* New mutex functions - 09-Sep-2014 */
/* @author Piotr Nikiel */

int OP_LOCK = 1;
int OP_UNLOCK = 2;

/* This function is internal */
synchronized bool _fwElmb_lock_op (string name, int op)
{
  if (!globalExists("gElmbLocks"))
  {
    DebugN ("Adding global: gElmbLocks");
    addGlobal("gElmbLocks", MAPPING_VAR);
  }
  if (!mappingHasKey (gElmbLocks, name))
  {
    switch (op)
    {
      case OP_LOCK:
         if (mappinglen(gElmbLocks)>1000)
         {
           DebugTN ("fwElmb: _fwElmb_lock_op: WARNING. More than 1000 mutexes used already (unusually high number). Your system may suffer performance loss.");
         }
         gElmbLocks[name] = true;
         return true;
         break;
      case OP_UNLOCK:
         DebugTN ("_fwElmb_lock_op PROBLEM: unlock called on a resource that was NOT previously locked.");
         return false;
    }
  }
  else /* an information in the mapping exists */
  {
    switch (op)
    {
      case OP_LOCK:
        if (gElmbLocks[name] == true)
        {
          return false; /* locked by someone else*/
        }
        else
        {
          gElmbLocks[name] = true;
          return true; /* successfully locked */
        }
        break;
      case OP_UNLOCK:
        gElmbLocks[name] = false;
        return true;
    }
  }
}


bool fwElmb_lock(string name)
{
  int attempt=0;
  //DebugTN ("fwElmb_lock: entering for "+name);
  while (_fwElmb_lock_op(name, OP_LOCK) != true)
  {
    attempt++;
    if (attempt > 600) /* 60 secs */
    {
      //DebugTN ("fwElmb_lock: Locking failed: timeout for "+name);
      return false;
    }
    delay (0,100);
  }
  ///DebugTN ("fwElmb_lock: lock acquired for "+name);
  return true;
}

void fwElmb_unlock(string name)
{
  _fwElmb_lock_op (name, OP_UNLOCK);
  //DebugTN ("fwElmb_unlock: unlocked "+name);
}


/////// channelInvalid handling functions
// Hint: to cache channel's active and invalid state such memory structure is stored: (in C++ parlance ;-) )
// mapping < string,  mapping < string,  dyn_bool > >
// ^maps elmb name    ^maps channel      ^keeps invalid (at 1) and active (at 2)
// ^to its channels   ^name to its
//                    ^state
//
// gFwElmb_cachedChannels - at this global the cached state is stored

void fwElmb_cachedCreate ()
{
  if (!globalExists("gFwElmb_cachedChannels"))
  {
    addGlobal ("gFwElmb_cachedChannels", MAPPING_VAR);
  }
}

// Make sure proper layout exists; if create=true then also create if it doesnt
// Returns false when create=false and the structure doesnt exist
bool fwElmb_cachedEnsure (string elmbName, string channelName, bool create)
{
  elmbName = dpSubStr (elmbName, DPSUB_DP);
  channelName = dpSubStr (channelName, DPSUB_DP);
  if (! mappingHasKey (gFwElmb_cachedChannels, elmbName) )
  {
    if (create)
    {
      DebugN ("cached: Creating ELMB entry for "+elmbName);
      mapping m;
      gFwElmb_cachedChannels[ elmbName ] = m;
    }
    else
      return false;
  }

  if (! mappingHasKey (gFwElmb_cachedChannels[elmbName], channelName) )
  {
    if (create)
    {
      DebugN ("cached: Creating channel entry for "+channelName);
      dyn_bool db = makeDynBool (false, false);
      db [ FWELMB_CACHED_OFFSET_INVALID ] = false;
      db [ FWELMB_CACHED_OFFSET_ACTIVE ] = true;
      gFwElmb_cachedChannels[elmbName][channelName] = db;
    }
    else
      return false;
  }
  return true;

}

void fwElmb_cachedSetChannelActive (string elmbName, string channelName, bool active)
{
   elmbName = dpSubStr (elmbName, DPSUB_DP);
   channelName = dpSubStr (channelName, DPSUB_DP);
   fwElmb_cachedEnsure (elmbName, channelName, true);
//   DebugN ("Setting active for "+ elmbName+" "+channelName+" to "+active);
   gFwElmb_cachedChannels[elmbName][channelName][ FWELMB_CACHED_OFFSET_ACTIVE ] = active;
}

bool fwElmb_cachedGetChannelActive (string elmbName, string channelName, bool &active)
{
  if (! fwElmb_cachedEnsure (elmbName, channelName, false))
    return false;
   elmbName = dpSubStr (elmbName, DPSUB_DP);
   channelName = dpSubStr (channelName, DPSUB_DP);
   active = gFwElmb_cachedChannels[elmbName][channelName][ FWELMB_CACHED_OFFSET_ACTIVE ];
//   DebugN ("Getting  active for "+ elmbName+" "+channelName+" is " + active);
   return true;
}

void fwElmb_cachedSetChannelInvalid (string elmbName, string channelName, bool invalid)
{
   elmbName = dpSubStr (elmbName, DPSUB_DP);
   channelName = dpSubStr (channelName, DPSUB_DP);
   fwElmb_cachedEnsure (elmbName, channelName, true);
   gFwElmb_cachedChannels[elmbName][channelName][ FWELMB_CACHED_OFFSET_INVALID ] = invalid;
}



// Compute FwElmbNode's channelInvalid
// Returns sucess, and inside out returns computed value of channelInvalid
bool fwElmb_cachedComputeNode (string elmbName, bool& out)
{
  elmbName = dpSubStr (elmbName, DPSUB_DP);
  if (! mappingHasKey (gFwElmb_cachedChannels, elmbName) )
    return false;
  out = false; // the default value
  mapping channels = gFwElmb_cachedChannels[elmbName];
  for (int i=1; i<=mappinglen(channels); i++)
  {
    dyn_bool state = mappingGetValue (channels, i);
    if (state[ FWELMB_CACHED_OFFSET_ACTIVE ] && state [ FWELMB_CACHED_OFFSET_INVALID ])
    {
      out = true;
      return true; // no point if looking further when we found an active channel which is invalid
    }
  }
  return true;
}

//*****************************************************************************
// @name Function: fwElmb_monitorInvalid
//
// Callback used to check for any channel being invalid. A DPE is set to true
// if any channel is found to be invalid to allow for an alert to be signalled.
//
// @param dsValidList: List of channels
// @param dbIsInvalid: boolean values indicating whether channel is invalid or not
//
// Modification History: None
//
// Constraints: None
//
// Usage: Public
//
// PVSS manager usage: VISION, CTRL
//
// @author Jim Cook, Piotr Nikiel, Stefan Schlenker
//*****************************************************************************
void fwElmb_cbkMonitorInvalid(string dpeAi,
                              bool aiIsInvalid)
{
  dyn_string nameSplit = strsplit (dpeAi, fwDevice_HIERARCHY_SEPARATOR);
    // first three parts corespond to ELMB name
  if (dynlen(nameSplit) < 5)
  {
    DebugTN ("ERROR: DP name format of the channel="+dpeAi+" is not correct");
    return;
  }
  string elmbName = nameSplit[1] + fwDevice_HIERARCHY_SEPARATOR +
                    nameSplit[2] + fwDevice_HIERARCHY_SEPARATOR +
                    nameSplit[3];

    if (! fwElmb_cachedEnsure( elmbName, dpeAi, false) )
    {
      /* A serious problem. */
      DebugTN ("ERROR: callback received for channel="+dpeAi+" but the channel not cached. If you changed the config, restart fwElmbCheckInvalid script. ");
      DebugTN ("Marking this ELMB invalid.");
      dpSet( elmbName+".channelInvalid", true );
      return;
    }

    /* Now update the map of channel invalid flags with current information. */
    fwElmb_cachedSetChannelInvalid (elmbName, dpeAi, aiIsInvalid);
    bool out_invalid;
    bool success = fwElmb_cachedComputeNode (elmbName, out_invalid);
    if (!success)
    {
      DebugN ("ERROR: fwElmb_cachedComputeNode was not successful. Marking this ELMB invalid.");
       dpSet( elmbName+".channelInvalid", true );
    }
    else
      dpSet( elmbName+".channelInvalid", out_invalid );

}

/* Author: Piotr Nikiel
   Introduced in fwElmb 5.2.1
   This function is part of fwElmb error handling mechanisms.
   Since one can't connect to address active config this information has to be polled regularly.
   The information is necessary to set FwElmbNode's channelInvalid attribute accordingly
   Changed in fwElmb 5.2.7
*/
void fwElmb_pollChannelsActive ()
{

  // iterate over all ELMBs, iterate all their channels and mark their activity accordingly
  dyn_string dsElmbs = dpNames (getSystemName()+"*", "FwElmbNode");
  for (int i=1; i<=dynlen(dsElmbs); i++)
  {
    dyn_string dsChannels = dpNames(dsElmbs[i]+"*", "FwElmbAi");
    dyn_string dsChannelsSDO = dpNames(dsElmbs[i]+"*", "FwElmbAiSDO");
    dyn_string dsChannelsAddressActive = dsChannels;
    dyn_string dsChannelsSDOAddressActive = dsChannelsSDO;
    for (int j=1; j<=dynlen(dsChannels); j++)
      dsChannelsAddressActive[j] = dsChannelsAddressActive[j]+".value:_address.._active";
    for (int j=1; j<=dynlen(dsChannelsSDO); j++)
      dsChannelsSDOAddressActive[j] = dsChannelsSDOAddressActive[j]+".rawValue:_address.._active";
    dynAppend(dsChannels, dsChannelsSDO);
    if (dynlen(dsChannels) < 1)
    {
      /* No channels for this ELMB, just make sure invalidChannels is OK */
      dpSet (dsElmbs[i]+".channelInvalid", false);
      continue;
    }
    dynAppend(dsChannelsAddressActive, dsChannelsSDOAddressActive);
    dyn_bool channelsActive;
    dpGet (dsChannelsAddressActive, channelsActive) ;
    if (dynlen(getLastError())>0)
    {
      DebugN ("dpGet problem - can't get AddressActive for ELMB="+dsElmbs[i]+", maybe client not running! I will set channelInvalid on this ELMBs and continue running.");
      dpSet (dsElmbs[i]+".channelInvalid", true);
      continue;
    }
    //DebugN("sizeof(active)="+sizeof(active));
    for (int j=1; j<=dynlen(dsChannels); j++)
    {
      fwElmb_cachedEnsure( dsElmbs[i], dsChannels[j], true);
      //DebugN ("ch# "+channelNumber+" active bitmap value="+bitmapActive[j]);
      bool activeChanged = false;
      bool active;
      fwElmb_cachedGetChannelActive (dsElmbs[i], dsChannels[j], active);
      if (active != channelsActive[j])
        activeChanged = true;
      if (activeChanged)
      {
        fwElmb_cachedSetChannelActive ( dsElmbs[i], dsChannels[j], channelsActive[j]);
        DebugN ("Active changed for "+dsChannels[j]+", will force cbkMonitorInvalid");
        bool isValid;
        dpGet (dsChannels[j]+".value:_online.._invalid", isValid);
        fwElmb_cbkMonitorInvalid (dsChannels[j]+".value:_online.._invalid",  isValid);
      }
    }
  }
}




void fwElmb_refreshElmbConfiguration (dyn_string & dsExceptions)
{
  dyn_string dpes = makeDynString("/DI.enable.read",
                                  "/DI.transmissionType.read",
                                  "/DI.eventTimer.read" );
  dyn_string dsElmbs = dpNames( getSystemName()+"*", ELMB_TYPE_NAME );
  for (int i=1; i<=dynlen(dsElmbs); i++)
  {
    string sElmb = dsElmbs[i];
    uint state;  // for skipping issuing SDOs on ELMBs that are not operational
    dpGet( sElmb+".state", state);
    if (state != 1) /* It is NOT disconnected */
    {
      for (int j=1; j<=dynlen(dpes); j++)
      {
        dyn_anytype aValue;
        dyn_string chunks = strsplit( dpes[j], "." );
        if (dpExists( sElmb+chunks[1] ))
          fwElmb_elementSQ( sElmb+dpes[j], 2, aValue, dsExceptions );
        delay( 0, 100 ); // TODO
      }
    }
  }
  // go through all ELMBs, scan them

}

void fwElmb_cbkOpcUaConnectionState ( string dp, uint state )
{
  if (state != 1)
  {
    // means no OPC UA connection for CANopen OPC UA srv
    // check if invalidation of channels is enabled for this project
    bool invalidateChannels = true;
    dpGet ( "_FwElmbGlobal.opcUaConnectionLostInvalidatesChannels", invalidateChannels);
    if (invalidateChannels)
    {
      DebugN ("fwElmb: Invalidating channels of all ELMBs because of OPC UA connection lost.");
      dyn_string dsElmbs = dpNames(getSystemName()+"*", ELMB_TYPE_NAME);
      for (int i=1; i<=dynlen(dsElmbs); i++)
      {
        fwElmbUser_setInvalidAllChannelsOfElmb( dsElmbs[i] );
      }

    }
  }
  if (state == 1)
  {
    /* OPC UA Reconnected -- notify check invalid manager to reload ELMB config */
    dpSet("_FwElmbGlobal.afterOpcUaReconnectFlag", true);
  }
}

void fwElmb_monitorOpcUaConnectionState ()
{
  if (!isRedundant()) dpConnect( "fwElmb_cbkOpcUaConnectionState" ,  "_OPCUACANOPENSERVER.State.ConnState");
  else dpConnect("fwElmb_cbkOpcUaConnectionState",fwInstallationRedu_resolveDp("_OPCUACANOPENSERVER")+".State.ConnState");

}

//Check device definition to determine if BusName is subscriptions are being created using the BusName or _OPCUACANOPENSERVER is being used instead
//0: not being used (_OPCUACANOPENSERVER_Cmd/Ai/...)
//1: being used  (_UAsub_busname_Cmd/Ai
int fwElmb_checkSubscriptionBusNameConvention() {

  if (!dpExists(getSystemName()+"FwElmbCANbusInfo.configuration.address.OPCUA.subscriptions")) return -1;

  dyn_string subscriptions;
  dpGet(getSystemName()+"FwElmbCANbusInfo.configuration.address.OPCUA.subscriptions",subscriptions);
  for (int i=1;i<=dynlen(subscriptions);i++) {
    if (strpos(subscriptions[i],"OPCUACANOPENSERVER")>=0) return 0;
    else if (strpos(subscriptions[i],"UAsub")>=0) return 1;
  }
  return -1;

}


void fwElmb_adaptSubscriptionsInDeviceDefinition(int shouldUseBusName=g_fwElmbUserSetting_useBusNameInSubscription) {

  if (shouldUseBusName==-1) return; //it has not been set in fwElmb so don't change anything;

  //check which convention is being used through the device definition
  if (g_fwElmb_isUsingBusNameInSubscription<0) g_fwElmb_isUsingBusNameInSubscription=fwElmb_checkSubscriptionBusNameConvention();

  if (g_fwElmb_isUsingBusNameInSubscription==shouldUseBusName) return;

  if (shouldUseBusName==0) { //change Device Definitions
    dyn_string dp=makeDynString("FwElmbAiInfo","FwElmbDiInfo","FwElmbDoInfo","FwElmbCANbusInfo","FwElmbNodeInfo");
    dyn_string subscriptions,aux; bool changed;
    for (int i=1;i<=dynlen(dp);i++) {
      dynClear(subscriptions);
      dpGet(getSystemName()+dp[i]+".configuration.address.OPCUA.subscriptions",subscriptions);
      changed=FALSE;
      for (int j=1;j<=dynlen(subscriptions);j++) {
        if (strpos(subscriptions[j],"UAsub")>=0) {
          aux=strsplit(subscriptions[j],"_");
          if (aux[2]=="Cmd") aux[2]="CmdReadBack";
          subscriptions[j]="OPCUACANOPENSERVER_"+aux[2];
          changed=TRUE;
        }
      }
      if (changed) {
          dpSetWait(getSystemName()+dp[i]+".configuration.address.OPCUA.subscriptions",subscriptions);
//          DebugTN(getSystemName()+dp[i]+".configuration.address.OPCUA.subscriptions",subscriptions);
      }
    }
    g_fwElmb_isUsingBusNameInSubscription=shouldUseBusName;
  }



}

///////////////////////////////////////////////////////////////////////////////


