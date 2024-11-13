/** @file fwPeriphAddressBACnet.ctl
 * 
 * Functions to set _address config for datapoint for BACnet driver.
 * 
 * Naming: when possible names used in WinCC OA help are used
 * (e.g. "reference" is preferred over "address").
 * FW_PARAMETER_FIELD_AAABBB constants are used, not the fwPeriphAddress_AAABBB
 * (who know which one is correct?).
 * TODO: it would be better to switch to fwPeriphAddress_AAABBB as
 * everybody else is using it.
 *
 * Note that config identifier is "BACnet", but the driver uses "BACNET",
 * in some cases it might cause confusion, that's why there are wrapper
 * functions using "BACNET" have been added. Probably it was better to
 * use "BACNET" from the start even though it's not correct...
 * 
 * Initial code was written based on WinCC OA help file on BACnet
 * and _address config entry. Other things were taken from BACnet
 * examples (BACnet_Samples.dpl in dplist directory of BACnet directory
 * in WinCC OA installation, look for "PeriphAddrMain"). Also
 * panels:
 * - panels/para/address_bacnet.pnl (used to set _address),
 * - panels/para/bacnet.pnl (to create/setup a device; might not be used here).
 * Note: version WinCC OA 3.11 was used.
 * 
 * Table for _datatype. Help only defines 800, but these values were used
 * in various places:
 * 800 default  
 * 801 Boolean  
 * 802 UnsignedInteger  
 * 803 SignedInteger  
 * 804 Real   
 * 805 Double   
 * 809 Enumerated  806 skipped, see bacnetDrvPara.ctl, line 740
 * Valid IDs: 800-899.
 * 
 * Code based on other fwPeriphAddressAAABB.ctl files.
 * 
 * Note that setting _address is not enough to make it work
 * appriopriate BACnet device datapoint has to exist (_BacnetDevice).
 * 
 * Changelog (put only important stuff here):
 * - 2016-01-12: added wrappers for BACNET (lgoralcz & msudera)
 * - 2015-12-08: fixes (lgoralcz)
 * - 2015-11-30: initial creation (lgoralcz)
 * 
 */

const string fwPeriphAddress_TYPE_BACNET = "BACnet"; // Identifier used outside, note that this identifier
                                                     // is used to create function names that are called
                                                     // _get, _set, if you change function names change this
                                                     // well
const string fwPeriphAddress_DRVID_BACNET = "BACNET"; // Driver itself requires it to be all uppercase

// Where are other indexes? See fwPeriphAddress.ctl & FW_PARAMETER_FIELD_AAABBBCCC
const unsigned fwPeriphAddress_BACNET_POLL_GROUP      = 12;
const unsigned fwPeriphAddress_BACNET_OBJECT_SIZE     = 12;

const string fwPeriphAddress_BACNET_REF_SEPARATOR = "."; /// Separator used in reference _address field
const int fwPeriphAddress_BACNET_REF_MIN_ELEM_NO = 4; /// Minimum number of elements in reference _address field
const int fwPeriphAddress_BACNET_REF_MAX_ELEM_NO = 5; /// Maximum number of elements in reference _address field
const int fwPeriphAddress_BACNET_REF_DEV_IDX = 1;  /// Index for device name in peripheral address
const int fwPeriphAddress_BACNET_REF_OBJ_TYPE_IDX = 2; /// Index for object type in peripheral address
const int fwPeriphAddress_BACNET_REF_OBJ_ID_IDX = 3; /// Index for object id in peripheral address
const int fwPeriphAddress_BACNET_REF_PROP_IDX = 4; /// Index for property in peripheral address
const int fwPeriphAddress_BACNET_REF_IDX_IDX = 5; /// Index for property's index in peripheral address

// _datatype possible values are listed here
const int fwPeriphAddress_BACNET_TYPE_DEFAULT = 800; /// Default 
const int fwPeriphAddress_BACNET_TYPE_BOOL = 801; /// Boolean
const int fwPeriphAddress_BACNET_TYPE_UINT = 802; /// Unsigned Integer
const int fwPeriphAddress_BACNET_TYPE_INT = 803; /// Signed Integer
const int fwPeriphAddress_BACNET_TYPE_REAL = 804; /// Real
const int fwPeriphAddress_BACNET_TYPE_DOUBLE = 805; /// Double
const int fwPeriphAddress_BACNET_TYPE_ENUM = 809; /// Enumerated
// In case you need a list of valid _datatypes
const dyn_int fwPeriphAddress_BACNET_TYPES = makeDynInt(
  fwPeriphAddress_BACNET_TYPE_DEFAULT,
  fwPeriphAddress_BACNET_TYPE_BOOL,
  fwPeriphAddress_BACNET_TYPE_UINT,
  fwPeriphAddress_BACNET_TYPE_INT,
  fwPeriphAddress_BACNET_TYPE_REAL,
  fwPeriphAddress_BACNET_TYPE_DOUBLE,
  fwPeriphAddress_BACNET_TYPE_ENUM
);


/** 
 * @brief Internal function to setup the BACnet addressing
 *   
 * @par Constraints
 * Should only be called from fwPeriphAddress_set
 * 
 * @reviewed 2018-06-21 @whitelisted{fwPeriphAddressExtension}
 * 
 * @param dpe  Datapoint element to act on
 * @param addressConfig    Address object is passed here:                                                        \n\n
 * 
 * @param exceptionInfo    Details of any errors are returned here
*/
void _fwPeriphAddressBACnet_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
  dyn_errClass errors;
  
  // Check if the structure passed is valid (also, correct if necessary)
  _fwPeriphAddressBACnet_check(addressConfig, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
  {
    return;
  }

  // Set driver number (in case of BACnet there can be only one)
  int driverNum = addressConfig[FW_PARAMETER_FIELD_DRIVER];
  dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
            dpe + ":_distrib.._driver", driverNum);
  errors = getLastError();
  if(dynlen(errors) > 0)
  {
    DebugTN(errors);
    throwError(errors);
    fwException_raise(exceptionInfo, "ERROR", "Could not set the driver number.", "");
    return;
  }

  if(addressConfig[FW_PARAMETER_FIELD_LOWLEVEL])
  {
    addressConfig[FW_PARAMETER_FIELD_MODE] += PVSS_ADDRESS_LOWLEVEL_TO_MODE;
  }

  // Set the address config, for reference see scripts/libs/para.ctl
  // function paDpSetAddress(), line 7919. Order, most probably, is important
  dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
            dpe + ":_address.._reference", addressConfig[FW_PARAMETER_FIELD_ADDRESS], // BACnet address string
            dpe + ":_address.._mode", (int) addressConfig[FW_PARAMETER_FIELD_MODE], // Explicit conversion to int
                                                                                    // (some internal type mismatch?)
            dpe + ":_address.._datatype", addressConfig[FW_PARAMETER_FIELD_DATATYPE], // 800 - 899, see ETM-1292
            dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_BACNET_POLL_GROUP],
            dpe + ":_address.._drv_ident", fwPeriphAddress_DRVID_BACNET, // This should always be "BACNET"
            dpe + ":_address.._active", addressConfig[FW_PARAMETER_FIELD_ACTIVE]); // Is this configuration active or not?

  // Any problems?
  errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
    throwError(errors);
    fwException_raise(exceptionInfo, "ERROR", "Could not create the address config.", "");
  }
  
  return;
}


/** This is to fix problem with different config type identifier ("BACnet") and
 * different driver identifier ("BACNET"). This function is just a wrapper around
 * "proper" function.
 * Proper BACnet name is "BACnet", but for whatever reason driver uses (and some
 * of our panels use this information /fwPeriphAddress.pnl/) "BACNET".
 */
void _fwPeriphAddressBACNET_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
  _fwPeriphAddressBACnet_set(dpe, addressConfig, exceptionInfo);
}


/**
 * @brief Retrieve configuration from _address config for BACnet.
 *   
 * @par Constraints
 * Should only be called from fwPeriphAddress_get
 * 
 * @reviewed 2018-06-21 @whitelisted{fwPeriphAddressExtension}
 * 
 * @param dpe            Datapoint element to read from
 * @param addressConfig  Address object is returned here (configParameters). @sa _fwPeriphAddressBACnet_set()
 * @param isActive       TRUE if address config is active, else FALSE 
 * @param exceptionInfo  Details of any errors are returned here
*/
void _fwPeriphAddressBACnet_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
  addressConfig = makeDynAnytype();
  addressConfig[fwPeriphAddress_BACNET_OBJECT_SIZE] = ""; // Force size on list (create it with a given size)
  
  // FWCORE-3486: driver number and direction/mode needs to be of type int in the addressConfig var, whereas it is char
  int drvNumber, drvMode;
  
  // For description of these fields see either WinCC OA help (see _address) or _fwPeriphAddressBACnet_set()
  dpGet(dpe + ":_distrib.._driver", drvNumber,
        dpe + ":_address.._reference", addressConfig[FW_PARAMETER_FIELD_ADDRESS],
        dpe + ":_address.._mode", drvMode,
        dpe + ":_address.._datatype", addressConfig[FW_PARAMETER_FIELD_DATATYPE],
        dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_BACNET_POLL_GROUP],
        dpe + ":_address.._active", addressConfig[FW_PARAMETER_FIELD_ACTIVE]);

  // Any problems?
  dyn_errClass errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
    throwError(errors);
    fwException_raise(exceptionInfo, "ERROR", "Could not get address config for " + dpe + ".", "");
    return;
  }

  addressConfig[FW_PARAMETER_FIELD_DRIVER] = drvNumber;
  addressConfig[FW_PARAMETER_FIELD_MODE] = drvMode;
  // Detect low level
  if(addressConfig[FW_PARAMETER_FIELD_MODE] >= PVSS_ADDRESS_LOWLEVEL_TO_MODE)
  {
    addressConfig[FW_PARAMETER_FIELD_LOWLEVEL] = true;
  }
  
  // Set driver identification manually, we are using "BACnet", but the driver uses "BACNET"
  addressConfig[FW_PARAMETER_FIELD_COMMUNICATION] = fwPeriphAddress_TYPE_BACNET;
  
  isActive = addressConfig[FW_PARAMETER_FIELD_ACTIVE];
}


/** This is to fix problem with different config type identifier ("BACnet") and
 * different driver identifier ("BACNET"). This function is just a wrapper around
 * "proper" function.
 * Proper BACnet name is "BACnet", but for whatever reason driver uses (and some
 * of our panels use this information /fwPeriphAddress.pnl/) "BACNET".
 */
void _fwPeriphAddressBACNET_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
  _fwPeriphAddressBACnet_get(dpe, addressConfig, isActive, exceptionInfo);
}


/**
 * @brief Internal function to cleanup before deleting the BACnet _address and _distrib configs
 * TODO: create function body
 * @par Constraints
 * Should only be called from fwPeriphAddress_delete \n
 * 
 * @reviewed 2018-06-21 @whitelisted{fwPeriphAddressExtension}
 *
 * @param dpe            Datapoint element to read from
 * @param exceptionInfo  Details of any errors are returned here 
 */ 
_fwPeriphAddressBACnet_delete(string dpe, dyn_string &exceptionInfo)
{
  DebugTN("_fwPeriphAddressBACnet_delete(): not implemented");
  
  return;
}


/** 
 * @brief Function to check and correct BACnet address configuration parameters before
 *        attempting to save them to the DP element.
 * 
 * Note: in other cases this function is public (no "_" prefix), but there's no reason
 *       why to make it private.
 *
 * @param addressConfig The address configuration object is passed here. In some cases, an
 *                      amended (fixed) version may be returned here
 * @param exceptionInfo Details of errors in the address configuration are returned here
*/
void _fwPeriphAddressBACnet_check(dyn_anytype &addressConfig, dyn_string &exceptionInfo)
{
  // Check size...
  if(dynlen(addressConfig) != fwPeriphAddress_BACNET_OBJECT_SIZE)
  {
    fwException_raise(exceptionInfo, "WARNING", "_fwPeriphAddressBACnet_check: " +
                                                "bad size of config structure", "");

    // Return, config is not reliable (possible problems with out-of-range)
    return;
  }

  // Is this a BACnet config?
  if(addressConfig[FW_PARAMETER_FIELD_COMMUNICATION] != fwPeriphAddress_TYPE_BACNET)
  {
    fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                              "this seems not to be a BACnet config", "");
  }
  
  // Check _datatype
  if(!_fwPeriphAddressBACnet_isDataTypeValid(addressConfig[FW_PARAMETER_FIELD_DATATYPE]))
  {
    fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                              "not a valid _datatype (not 800-899)", "");
  }

  // Check reference field
  if(!_fwPeriphAddressBACnet_isReferenceValid(addressConfig[FW_PARAMETER_FIELD_ADDRESS]))
  {
    fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                              "reference address is invalid", "");
  }

  // TODO: chcek with standard BACnet address set panel
  string pollGroup = addressConfig[fwPeriphAddress_BACNET_POLL_GROUP];
  
  switch(addressConfig[FW_PARAMETER_FIELD_MODE])
  {
    case DPATTR_ADDR_MODE_INPUT_POLL:
    case DPATTR_ADDR_MODE_IO_POLL:
      if(strlen(pollGroup) == 0)
      {
        fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                                  "A poll group must be defined for polled input configurations", "");
      }
      else
      {
        //if poll group is defined, does not being with a "_" and does not specify the system name, then prepend the "_"
        if(strpos(pollGroup,"_")!=0 && strpos(pollGroup,":")<0)
          pollGroup = "_"+pollGroup;
    
        if(!dpExists(pollGroup))
          fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                                    "The poll group \"" + pollGroup + "\" does not exist", "");
      }      
      break;
    case DPATTR_ADDR_MODE_INPUT_SPONT:
    case DPATTR_ADDR_MODE_INPUT_SQUERY:
    case DPATTR_ADDR_MODE_OUTPUT:
    case DPATTR_ADDR_MODE_IO_SQUERY:
    case DPATTR_ADDR_MODE_IO_SPONT:
      pollGroup = ""; //clear poll group because it is not needed
      break;
    default:
      fwException_raise(exceptionInfo, "ERROR", "_fwPeriphAddressBACnet_check: " +
                                                "Mode " + addressConfig[FW_PARAMETER_FIELD_MODE] + " is not supported", "");
      break;
  }
  // Update poll group, in some cases it might be corrected
  addressConfig[fwPeriphAddress_BACNET_POLL_GROUP] = pollGroup;

  // TODO: anything else?
}


/** This is to fix problem with different config type identifier ("BACnet") and
 * different driver identifier ("BACNET"). This function is just a wrapper around
 * "proper" function.
 * Proper BACnet name is "BACnet", but for whatever reason driver uses (and some
 * of our panels use this information /fwPeriphAddress.pnl/) "BACNET".
 *
 * @reviewed 2018-06-21 @whitelisted{fwPeriphAddressExtension}
 */
void _fwPeriphAddressBACNET_check(dyn_anytype &addressConfig, dyn_string &exceptionInfo)
{
  _fwPeriphAddressBACnet_check(addressConfig, exceptionInfo);
}


/** Validate datatype.
 * 
 * @param dataType	(string)	IN datatype (as string), ex. "800". 
 * @return value of type 'bool' true if datatype is acceptable, false if not
 */
 bool _fwPeriphAddressBACnet_isDataTypeValid(string dataType)
 {
   int dt = (int) dataType; // Convert to int
   
   return dynContains(fwPeriphAddress_BACNET_TYPES, dt) > 0;
 }


/** Validate BACnet address reference. 
 * 
 * Example reference: "Device_6789.AnalogInput.1.Min_Pres_Value"
 * or: "Device_6789.BinaryValue.3.Reliability.2".
 * Note: last element is optional.
 * 
 * <Device>.<Object_Type>.<Object_Id>.<Property>.<Index /optional/>
 * 
 * @param reference	(string)	IN BACnet address reference
 * @return value of type 'bool' true if address is valid, false otherwise
 */
bool _fwPeriphAddressBACnet_isReferenceValid(string reference)
{
  dyn_string elements = _fwPeriphAddressBACnet_explodeReference(reference);
  int elemCount = dynlen(elements);
  if(elemCount == 0)
  {
    return false;
  }
  
  string device = elements[fwPeriphAddress_BACNET_REF_DEV_IDX];
  string objectType = elements[fwPeriphAddress_BACNET_REF_OBJ_TYPE_IDX];
  string objectId = elements[fwPeriphAddress_BACNET_REF_OBJ_ID_IDX];
  string property = elements[fwPeriphAddress_BACNET_REF_PROP_IDX];
  string index = "";
  // This one is optional
  if(elemCount > fwPeriphAddress_BACNET_REF_MIN_ELEM_NO)
  {
    index = elements[fwPeriphAddress_BACNET_REF_IDX_IDX];
  }
  
  // Now check each element
  bool isValid = _fwPeriphAddressBACnet_isDeviceValid(device) &&
                 _fwPeriphAddressBACnet_isObjecTypeValid(objectType) &&
                 _fwPeriphAddressBACnet_isObjectIdValid(objectId) &&
                 _fwPeriphAddressBACnet_isPropertyValid(objectType, property);
  if(index != "")
  {
    isValid = isValid && _fwPeriphAddressBACnet_isIndexValid(index);
  }

  return isValid;
}


/** Explodes string representing BACnet reference. * 
 * 
 * @param reference	(string)	IN BACnet reference string, ex. " 
 * @return value of type 'dyn_string' List of elements (ex. BACnet device, object id, etc.) or
 *                                    empty list if string was invalid
 * 
 */
dyn_string _fwPeriphAddressBACnet_explodeReference(string reference)
{
  // Quote from WinCC OA help on BACnet
  // <Device>.<Object_Type>.<Object_Id>.<Property>.<Index>
  // From examples last element is optional
  dyn_string elements = strsplit(reference, fwPeriphAddress_BACNET_REF_SEPARATOR);
  int elemCount = dynlen(elements);
  
  if((elemCount > fwPeriphAddress_BACNET_REF_MAX_ELEM_NO) ||
     (elemCount < fwPeriphAddress_BACNET_REF_MIN_ELEM_NO))
  {
    // Invalid number of elements, explicitly clear output list
    DebugTN("Invalid BACnet reference string given, number of elements (" +
            elemCount + ") not in range (" + fwPeriphAddress_BACNET_REF_MIN_ELEM_NO +
            " - " + fwPeriphAddress_BACNET_REF_MAX_ELEM_NO + ").");
    dynClear(elements);
  }
  
  return elements;
}


/** Check if a given BACnet device exists in the configuration.
 * 
 * This function simply check if a datapoint of a given name
 * and type "_BacnetDevice" exists. 
 * 
 * TODO: stub, returns always true
 * 
 * @param device	(string)	IN BACnet device name
 * @return value of type 'bool' True if device exits, false if BACnet device doesn't exist
 */
bool _fwPeriphAddressBACnet_isDeviceValid(string device)
{
  return true;
}

bool _fwPeriphAddressBACnet_isObjecTypeValid(string objectType)
{
  // Taken from catalog file BACnetGeneral.cat
  dyn_string validObjTypes = makeDynString(
    "AnalogInput",
    "AnalogOutput",
    "AnalogValue",
    "BinaryInput",
    "BinaryOutput",
    "BinaryValue",
    "Calendar",
    "Device",
    "MultistateInput",
    "MultistateOutput",
    "NotificationClass",
    "Schedule",
    "MultistateValue",
    "TrendLog",
    "Command",
    "EventEnrolment",
    "File",
    "Group",
    "Loop",
    "Program",
    "Averaging",
    "LifeSafetyPoint",
    "LifeSafetyZone",
    "Accumulator",
    "PulseConverter");

  return dynContains(validObjTypes, objectType) > 0;
}


/** Check if BACnet object ID is valid for _reference element.
 * 
 * Note, this does not check if an object id really exists in
 * the device, only if it is correct, i.e. a number. 
 * 
 * @param objectId	(string)	IN BACnet object id
 * @return value of type 'bool' true if valid BACnet object id, false if not valid
 */
bool _fwPeriphAddressBACnet_isObjectIdValid(string objectId)
{
  return true;
}


/** Check if BACnet object's property is valid for _reference element. 
 *
 * Note1: that cat file that is being used is not the same cat file that
 * is used to store translated messages ("msg" directory).
 * Note2: code based on one of the WinCC OA BACnet libraries.
 * 
 * @param property	(string)	IN BACnet object's property
 * @return value of type 'bool' true if property is valid, false otherwise
 */
bool _fwPeriphAddressBACnet_isPropertyValid(string object, string property)
{
  string sContent, sFilePath, sType;
  const string OBJTYPEMAPPING = "bacnet/BACNet_objecttype_mapping.cat";
  file fFile;
  dyn_string dsRows;
  int err;
  
  sFilePath = getPath(DATA_REL_PATH, OBJTYPEMAPPING);
  if(sFilePath == "")
  {
    // File can not be found, this means broken installation
    DebugTN("Error: couldn't locate file: " + OBJTYPEMAPPING + ", it means your BACnet installation " +
            "is not complete, this is needed by _fwPeriphAddressBACnet_isPropertyValid(), ignoring validation " +
            "(returning true/passed)");

    return true;
  }

  fFile = fopen(sFilePath,"r");
  if((err=ferror(fFile)) != 0)
  {
    DebugTN("Error " + err + " opening file " + sFilePath + ". Warning: Property cannot be validated." +
            " _fwPeriphAddressBACnet_isPropertyValid() return true");
    return true;
  }

  fileToString(sFilePath, sContent);
  dsRows = strsplit(sContent, "\n");  
  for (int i = 1; i <= dynlen(dsRows); i++)
  {
    if(dsRows[i][0] != "-" && dsRows[i] != "")
    {
      dyn_string dsRow = strsplit(dsRows[i], ",");
      if(dsRow[1] == object)
      {
        i++;
        while((dynlen(dsRows) >= i) && (dsRows[i][0] == "-"))
        {
          if(strltrim(dsRows[i], "-") == property)
          {
            fclose(fFile);
            return true;
          }
          i++;
        }
        break;
      }
    }
  }
  fclose(fFile);
  
  return false;
}


/** Check if given BACnet object's property index is valid.
 * 
 * @param index	(string)	IN object's property index
 * @return value of type 'bool' true if BACnet object's property index is valid, false otherwise
 */
bool _fwPeriphAddressBACnet_isIndexValid(string index)
{
  return true;
}




/**********************************************************************************
 *                           Panel functions 
 **********************************************************************************/


#uses "bacnetDrvPara.ctl" //contains function to read mapping of properties of object types from file

void _fwPeriphAddressBACnet_initPanel(string dpe, dyn_string &exceptionInfo)
{   
  //check if bacnet file with mapping of properties exists
  if(getPath(DATA_REL_PATH,"bacnet/BACNet_objecttype_mapping.cat") == "")
  {//if not then hide panel and inform user
    setValue("fwPeriphAddressBACnet", "visible", "false");
    DebugTN("BACnet address configuration window can not be displayed.");
    exceptionInfo = makeDynString("BACnet address configuration window can not be displayed",
                                  "One of the BACnet configuration files is missing, "
                                  "this might mean invalid or incomplete WinCC OA BACnet"
                                  "installation. Missing file: " + DATA_REL_PATH +
                                  "bacnet/BACNet_objecttype_mapping.cat");
    return;
  }
  
  //Fill in comboboxes with proper data 
  _fwPeriphAddressBACnet_showTransformationTypes();
  _fwPeriphAddressBACnet_showDevices(dpe);
  paBnSetMapping();//set mapping of properties of object types
  _fwPeriphAddressBACnet_showObjectTypes();
  _fwPeriphAddressBACnet_showPollingGroups(dpe);
  
  bool active;
  dyn_anytype addressConfig;
  bool configExists, isActive;
  fwPeriphAddress_get(dpe, configExists, addressConfig, isActive, exceptionInfo);
  
  if(configExists && (addressConfig[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_BACNET))
  {
    //show "_address" properties of given dpe on the panel
  	setValue("driverNumberSelector_BACnet", "text", addressConfig[fwPeriphAddress_DRIVER_NUMBER]);		
  	setValue("referenceField_BACnet", "text", addressConfig[fwPeriphAddress_REFERENCE]);
    dyn_string referenceElements = _fwPeriphAddressBACnet_explodeReference(addressConfig[fwPeriphAddress_REFERENCE]);
    if(dynlen(referenceElements) >= fwPeriphAddress_BACNET_REF_MIN_ELEM_NO)
    {
      //select device type in 'device_BACnet' combobox if is on the list
      dyn_string devicesBACnet;
      getValue("device_BACnet", "items", devicesBACnet);
      int devicePos = dynContains(devicesBACnet, referenceElements[fwPeriphAddress_BACNET_REF_DEV_IDX]);
      if(devicePos >= 0)
      {
        setValue("device_BACnet", "selectedPos", devicePos);
      }
        
      //select object type in 'objectType_BACnet' combobox if is on the list
      dyn_string objectTypes;
      getValue("objectType_BACnet", "items", objectTypes);
      int objectTypePos = dynContains(objectTypes, referenceElements[fwPeriphAddress_BACNET_REF_OBJ_TYPE_IDX]);
      if(objectTypePos >= 0)
      {
        setValue("objectType_BACnet", "selectedPos", objectTypePos);
      }
      //fill the 'property_BACnet' combobox according to selected object type
      string objectType;
      getValue("objectType_BACnet", "selectedText", objectType);
      _fwPeriphAddressBACnet_showObjectProperties(objectType);
        
      //show object ID
      setValue("objectIdSelector_BACnet", "text", referenceElements[fwPeriphAddress_BACNET_REF_OBJ_ID_IDX]);
        
      //select property in 'property_BACnet' combobox if is on the list
      dyn_string properties;
      getValue("property_BACnet", "items", properties);
      int propertyPos = dynContains(properties, referenceElements[fwPeriphAddress_BACNET_REF_PROP_IDX]);
      if(propertyPos >= 0)
      {
        setValue("property_BACnet", "selectedPos", propertyPos);
      }
        
      //show index if available
      if(dynlen(referenceElements) == fwPeriphAddress_BACNET_REF_IDX_IDX)
      {
        setValue("indexField_BACnet", "text", referenceElements[fwPeriphAddress_BACNET_REF_IDX_IDX]);
      }
        
    }
      
    //set state of checkboxes
    setValue("activeCheckButton_BACnet", "state", 0, addressConfig[fwPeriphAddress_ACTIVE]);	
    setValue("lowLevel_BACnet", "state", 0, addressConfig[FW_PARAMETER_FIELD_LOWLEVEL]);	
      
    //set state of radioboxes
    int directionMode, receiveMode; 
    _fwPeriphAddressBACnet_getModes(addressConfig[fwPeriphAddress_DIRECTION], directionMode, receiveMode);  
    setValue("direction_BACnet", "number", directionMode);
    setValue("mode_BACnet", "number", receiveMode);
    
    //select data transformation type in 'transformation_BACnet' combobox if is on the list
  	setValue("transformation_BACnet", "selectedPos",
             dynContains(fwPeriphAddress_BACNET_TYPES, addressConfig[fwPeriphAddress_DATATYPE]));
      
    //show device IP address and Port
    string device;
    getValue("device_BACnet", "selectedText", device);
    _fwPeriphAddressBACnet_showDeviceAddress("_" + device);
      
    //select pooling group in 'pollGroupName_BACnet' combobox if is on the list
    dyn_string poolingGroups;
    getValue("pollGroupName_BACnet", "items", poolingGroups);
    int pollGroupPos = dynContains(poolingGroups, 
                                   strltrim(dpSubStr(addressConfig[fwPeriphAddress_BACNET_POLL_GROUP],DPSUB_DP),"_"));
    if(pollGroupPos > 0)
    {
      setValue("pollGroupName_BACnet", "selectedPos", pollGroupPos);
    }
  }
    
  //enable proper objects on panel based on currently selected Direction Mode and Receive Mode
  int directionMode, receiveMode;
  getValue("direction_BACnet", "number", directionMode);
  getValue("mode_BACnet", "number", receiveMode);    
  _fwPeriphAddressBACnet_setIOMode(directionMode, receiveMode);
}

// Data Transformation types labels
const string fwPeriphAddress_BACNET_TYPE_STRING_DEFAULT = "Default";
const string fwPeriphAddress_BACNET_TYPE_STRING_BOOL = "Boolean";
const string fwPeriphAddress_BACNET_TYPE_STRING_UINT = "UnsignedInteger";
const string fwPeriphAddress_BACNET_TYPE_STRING_INT = "SignedInteger";
const string fwPeriphAddress_BACNET_TYPE_STRING_REAL = "Real";
const string fwPeriphAddress_BACNET_TYPE_STRING_DOUBLE = "Double";
const string fwPeriphAddress_BACNET_TYPE_STRING_ENUMERATED = "Enumerated";

const dyn_string fwPeriphAddress_BACNET_TYPES_STRING = makeDynString(
  fwPeriphAddress_BACNET_TYPE_STRING_DEFAULT,
  fwPeriphAddress_BACNET_TYPE_STRING_BOOL,
  fwPeriphAddress_BACNET_TYPE_STRING_UINT,
  fwPeriphAddress_BACNET_TYPE_STRING_INT,
  fwPeriphAddress_BACNET_TYPE_STRING_REAL,
  fwPeriphAddress_BACNET_TYPE_STRING_DOUBLE,
  fwPeriphAddress_BACNET_TYPE_STRING_ENUMERATED
);

/**
 * This function shows BACnet transformation types in 'transformation_BACnet' combobox.
*/
void _fwPeriphAddressBACnet_showTransformationTypes()
{
  setValue("transformation_BACnet", "items", "");
  setValue("transformation_BACnet", "items", fwPeriphAddress_BACNET_TYPES_STRING);
}

/**
 * This function finds BACnet Object Types and shows in the 'objectType_BACnet' combobox.
*/
void _fwPeriphAddressBACnet_showObjectTypes()
{
  dyn_string dsItemsObjT;
  dsItemsObjT = mappingKeys(mTypes);
  dynSortAsc(dsItemsObjT);
  if(dynlen(dsItemsObjT) > 0)
  {
    setValue("objectType_BACnet", "items", dsItemsObjT);//add object types to the combobox
    setValue("objectType_BACnet", "selectedPos", 0);
  }
}

/**
 * This function finds BACnet devices available for given DPE and shows in the 'device_BACnet' combobox.
 *
 * @param dpe Data point element for which available BACnet devices should be found
*/
void _fwPeriphAddressBACnet_showDevices(string dpe)
{
  dyn_string dsEqu = dpNames(dpSubStr(dpe, DPSUB_SYS)+"*", "_BacnetDevice");
  for(int i=dynlen(dsEqu);i>0;i--)
  {
    if(isReduDp(dsEqu[i]))
    {
      dynRemove(dsEqu, i); // don't display redundant datapoints
    }
  }
  if(dynlen(dsEqu) > 0)
  {
    for(int i=1;i<=dynlen(dsEqu);i++)
    {//get only device name
      dsEqu[i] = dpSubStr(dsEqu[i], DPSUB_DP);
      dsEqu[i] = substr(dsEqu[i], (dsEqu[i][0] == "_" ? 1 : 0), strlen(dsEqu[i]) - (dsEqu[i][0] == "_" ? 1 : 0));
    }
  }
  if(dynlen(dsEqu) > 0)
  {
    setValue("device_BACnet", "items", dsEqu);//add devices to the combobox
    setValue("device_BACnet", "selectedPos", 0);
  }
}

/**
 * This function finds the polling groups stored in dp and shows in the 'pollGroupName_BACnet' combobox.
 *
 * @param dpe Data point element with device name
*/
void _fwPeriphAddressBACnet_showPollingGroups(string dpe)
{
  string sSystemName;
  dyn_string exceptionInfo;
  dyn_string dsPlc;
  fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
  if(sSystemName == "") sSystemName = getSystemName();
  dsPlc = dpNames(sSystemName + "*", "_PollGroup");
  
  for (int i=dynlen(dsPlc);i>0;i--)
	{
    // don't display redundant datapoints
	  if (i > 1 && strpos(dsPlc[i], "_2") == strlen(dsPlc[i]) - 2 && dsPlc[i] == dsPlc[i - 1] + "_2")
		{
      dynRemove(dsPlc, i);
		}
    
    if (i <= dynlen(dsPlc))
		{
      dsPlc[i] = dpSubStr(dsPlc[i], DPSUB_DP);
			if (dsPlc[i][0] == "_")
      {
        dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i]) - 1);
			}
		}
	}
  setValue("pollGroupName_BACnet", "items", dsPlc);
}

const int fwPeriphAddress_BACNET_DIRECTION_OUT = 0;
const int fwPeriphAddress_BACNET_DIRECTION_IN = 1;
const int fwPeriphAddress_BACNET_DIRECTION_INOUT = 2;

const int fwPeriphAddress_BACNET_RECEIVE_UNSOLICITED = 0;
const int fwPeriphAddress_BACNET_RECEIVE_POOLING = 1;
const int fwPeriphAddress_BACNET_RECEIVE_SINGLE = 2;
const int fwPeriphAddress_BACNET_RECEIVE_ALARM = 3;

/**
 * This function reads Direction and Receive Mode flags from the "_address.._mode" property
 *
 * @param addressMode  value of "_address.._mode" property of dpe
 * @param directionMode  returned Direction flag
 * @param receiveMode  returned Receive Mode flag
*/
void _fwPeriphAddressBACnet_getModes(int addressMode, int &directionMode, int &receiveMode)
{//Warning: if addressMode value comes from "_address.._mode" config then it has added value
 //(DPATTR_ADDR_MODE_LOW_LEVEL_FLAG = 64) when low level mode is selected!!!
 //To prevent obtaining addressMode with low level flag it should be read from "_address.._direction"
  if(addressMode > DPATTR_ADDR_MODE_LOW_LEVEL_FLAG)
  {
    addressMode -= DPATTR_ADDR_MODE_LOW_LEVEL_FLAG;
  }

  switch(addressMode)
  {
    case DPATTR_ADDR_MODE_OUTPUT:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_OUT;
      //receiveMode stay unset
      break;
    case DPATTR_ADDR_MODE_INPUT_SPONT:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_IN;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_UNSOLICITED;
      break;
    case DPATTR_ADDR_MODE_INPUT_SQUERY:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_IN;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_SINGLE;
      break;
    case DPATTR_ADDR_MODE_INPUT_POLL:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_IN;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_POOLING;
      break;
    case DPATTR_ADDR_MODE_IO_SPONT:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_INOUT;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_UNSOLICITED;
      break;
    case DPATTR_ADDR_MODE_IO_SQUERY:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_INOUT;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_SINGLE;
      break;
    case DPATTR_ADDR_MODE_IO_POLL:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_INOUT;
      receiveMode = fwPeriphAddress_BACNET_RECEIVE_POOLING;
      break;
    default:
      directionMode = fwPeriphAddress_BACNET_DIRECTION_OUT;
  }
}

/**
 * This function reads the IP address and port of given BACnet server (device) and shows them.
 *
 * @param dp BACnet device data point
*/
void _fwPeriphAddressBACnet_showDeviceAddress(string dp)
{
  string ipAddress, port;
  string connectionInfo;
  if(dpGet(dp + ".ConnInfo", connectionInfo) == 0)
  {
    dyn_string elements = strsplit(connectionInfo, ":");
    if(dynlen(elements) >= 3)
    {
      ipAddress = elements[2];
      port = elements[3];
    }
  }
  setValue("ipAddressField_BACnet", "text", ipAddress);
  setValue("portField_BACnet", "text", port);
}

/**
 * This function finds list of Properties for given BACnet Object Types and shows them in the property_BACnet combobox.
 *
 * @param objectType Object Type for which list of properties has to be found
*/
void _fwPeriphAddressBACnet_showObjectProperties(string objectType)
{
  if(mappingHasKey(mTypes, objectType))
  {
    setValue("property_BACnet", "deleteAllItems");
    setValue("property_BACnet", "text", "");
    setValue("property_BACnet", "items", mTypes[objectType]);   
  }
}

/** 
 * This function controls enabling of objects in Receive Mode and Polling Group frames on the panel
 * depending on the choosen Direction and Receive Mode.
 *  
 * @param directionMode direction mode (Output, Input, Input/Output)
 * @param receiveMode	receive mode (Unsolicited, Polling, Single Query, Alarm)
*/
void _fwPeriphAddressBACnet_setIOMode(int directionMode, int receiveMode)
{
  switch(directionMode)
  {
    case fwPeriphAddress_BACNET_DIRECTION_OUT:
      _fwPeriphAddressBACnet_enableReceiveMode(false);
      _fwPeriphAddressBACnet_enablePoolingGroup(false);
      break;
    case fwPeriphAddress_BACNET_DIRECTION_IN:
    case fwPeriphAddress_BACNET_DIRECTION_INOUT:
      _fwPeriphAddressBACnet_enableReceiveMode(true);
      switch(receiveMode)
      {
        case fwPeriphAddress_BACNET_RECEIVE_UNSOLICITED:
        case fwPeriphAddress_BACNET_RECEIVE_SINGLE:
        case fwPeriphAddress_BACNET_RECEIVE_ALARM:
          _fwPeriphAddressBACnet_enablePoolingGroup(false);
          break;
        case fwPeriphAddress_BACNET_RECEIVE_POOLING:
          _fwPeriphAddressBACnet_enablePoolingGroup(true);
          break;
        default:
          _fwPeriphAddressBACnet_enablePoolingGroup(false);
      }
      break;
     default:
      _fwPeriphAddressBACnet_enableReceiveMode(false);
      _fwPeriphAddressBACnet_enablePoolingGroup(false);
  }
}

void _fwPeriphAddressBACnet_enableReceiveMode(bool enabled)
{
  setValue("mode_BACnet", "enabled", enabled);
  setValue("lowLevel_BACnet", "enabled", enabled);
}

void _fwPeriphAddressBACnet_enablePoolingGroup(bool enabled)
{
  setValue("pollGroupName_BACnet", "enabled", enabled);
  setValue("btGroup_BACnet", "enabled", enabled);
}

