#uses "fwConfigs/fwConfigsDeprecated.ctl"

/**@file


/**
@defgroup fwPeripheryAddress fwPeripheryAddress
@brief This library contains function associated with the address config.
Functions are provided for getting the current settings, deleting the config
and setting the config

@par Creation Date
	28/03/2000

@par Modification History

  14/07/2014 Jean-Charles Tournier
  - @jira{FWCORE-3112} support for IEC configuration to detect active address

  09/04/2014 Marco Boccioli
  - @jira{FWCORE-3157} improve delete performance for DIP: fwPeriphAddress_deleteDIPMultiple() created

  31/03/2014 Marco Boccioli
  - @jira{FWCORE-3155} fwPeriphAddress_set() throw an error with data of fwPeriphAddress_get() (problem with polling setting)

  22/11/2013 Marco Boccioli, Alexey Merezhin
  - @jira{FWCORE-3147} Modify $param for option to avoid configuring periphery address if driver is running

  12/11/2013 Marco Boccioli
  - @jira{FWCORE-3146} Option to avoid configuring periphery address if driver is running:
	added to fwPeriphAddress_set() the check isDollarDefined()
	this check is done in order to make UNICOS CPC skip the set of periphery address in case the driver is running.

  09/09/2013 Marco Boccioli
  - @jira{FWCORE-3141} fwPeriphAddress_setOPCUA: single-query mode should not need polling group

  18/07/2013 Marco Boccioli
  - @jira{FWCORE-3110} support for redundancy

  18/02/2013 Jean-Charles Tournier
  - @jira{FWCORE-3112} add support for IEC addresses

  15/01/2013 Marco Boccioli
  - @jira{FWCORE-3102}: Add OPC UA. Improved documentation.

  12/08/2011 Marco Boccioli
  - @sav{87992}, @jira{ENS-3952}: fwPeriphAddress_getMany(): no results after a dpe with no configuration.

  12/08/2011 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
  - @sav{85466}: Improve performance for fwPeriphAddress_getMany().

  27/04/2010	Frederic Bernard (EN-ICE) update Exception management in fwPeriphAddress_setModbus()

  15/01/2004	Oliver Holme (IT-CO) Modified library to match functionality of other config libs

@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions
    		in a working function called by a PVSS (dpConnect) or in a calling function

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author
	Geraldine Thomas, Oliver Holme (IT-CO)
*/

#uses "fwGeneral/fwGeneral.ctl"
#uses "fwConfigs/fwConfigConstants.ctl"
#uses "fwConfigs/fwPeriphAddressBACnet.ctl"
#uses "fwConfigs/fwPeriphAddressCMW.ctl"
#uses "fwConfigs/fwPeriphAddressOPCUA.ctl"
#uses "fwConfigs/fwPeriphAddressS7.ctl"
#uses "fwConfigs/fwPeriphAddressSNMP.ctl"
#uses "fwConfigs/fwPeriphAddressMQTT.ctl"

// The following libraries need to be loaded conditionally, if components are installed...
private const bool fwPeriphAddress_fwDIMLoaded = fwGeneral_loadCtrlLib("fwDIM/fwDIM.ctl",false);
private const bool fwPeriphAddress_fwDIPLoaded = fwGeneral_loadCtrlLib("fwDIP/fwDIP.ctl",false);

// constants definition
/**
 *
 */
/** @name Types of periphery addresses
*/
///@{
const string fwPeriphAddress_TYPE_OPC = "OPC";
const string fwPeriphAddress_TYPE_OPCCLIENT = "OPCCLIENT";
const string fwPeriphAddress_TYPE_OPCSERVER = "OPCSERVER";
const string fwPeriphAddress_TYPE_OPCUA = "OPCUA";
const string fwPeriphAddress_TYPE_OPCUACLIENT = "OPCUA";
const string fwPeriphAddress_TYPE_DIM = "DIM";
const string fwPeriphAddress_TYPE_DIMCLIENT = "DIMCLIENT";
const string fwPeriphAddress_TYPE_DIMSERVER = "DIMSERVER";
const string fwPeriphAddress_TYPE_MODBUS = "MODBUS";
const string fwPeriphAddress_TYPE_DIP = "DIP";
const string fwPeriphAddress_TYPE_NONE = "None";
const string fwPeriphAddress_TYPE_IEC = "IEC";
const string fwPeriphAddress_TYPE_S7 = "S7";
const string fwPeriphAddress_TYPE_MQTT = "MQTT";
//@}
/** @name Common address object
*/
///@{
const unsigned fwPeriphAddress_TYPE 			= 1;
const unsigned fwPeriphAddress_DRIVER_NUMBER 	= 2;
const unsigned fwPeriphAddress_REFERENCE		= 3;
const unsigned fwPeriphAddress_DIRECTION		= 4;
const unsigned fwPeriphAddress_DATATYPE			= 5;
const unsigned fwPeriphAddress_ACTIVE 			= 6;
//@}

const unsigned fwPeriphAddress_ROOT_NAME		= 3;//!<replaced by _REFERENCE but kept for compatibility

/** @name JCOP fw Address reference
*/
///@{
const unsigned FW_PARAMETER_FIELD_COMMUNICATION 	= 1;	//!< Type of communication. ex : "MODBUS"
const unsigned FW_PARAMETER_FIELD_DRIVER 			= 2;	//!< Driver number
const unsigned FW_PARAMETER_FIELD_ADDRESS 			= 3;	//!< Address reference
const unsigned FW_PARAMETER_FIELD_MODE 				= 4;	//!< Mode
const unsigned FW_PARAMETER_FIELD_DATATYPE 			= 5;	//!< Type of data (see constants below)
const unsigned FW_PARAMETER_FIELD_ACTIVE 			= 6;	//!< Is address active
const unsigned FW_PARAMETER_FIELD_LOWLEVEL 	= 11;		//!< Is low level config used
const unsigned FW_PARAMETER_FIELD_SUBINDEX 	= 12;		//!< Address subindex
const unsigned FW_PARAMETER_FIELD_START 	= 13;		//!< Starting time
const unsigned FW_PARAMETER_FIELD_INTERVAL 	= 14;		//!< Interval time
const unsigned FW_PARAMETER_FIELD_NUMBER 	= 15;		//!< Number of parameters
//@}
/** @name IEC address object
*/
///@{
const unsigned fwPeriphAddress_IEC_SUBINDEX = 12;
//@}
/** @name MODBUS address object
*/
///@{
const unsigned fwPeriphAddress_MODBUS_LOWLEVEL 		= 11;
const unsigned fwPeriphAddress_MODBUS_SUBINDEX 		= 12;
const unsigned fwPeriphAddress_MODBUS_START 		= 13;
const unsigned fwPeriphAddress_MODBUS_INTERVAL 		= 14;
const unsigned fwPeriphAddress_MODBUS_POLL_GROUP	= 15;
const unsigned fwPeriphAddress_MODBUS_OBJECT_SIZE	= 15;
//@}
/** @name OPC DA address object
*/
///@{
const unsigned fwPeriphAddress_OPC_LOWLEVEL 	= 11;
const unsigned fwPeriphAddress_OPC_SUBINDEX 	= 12;
const unsigned fwPeriphAddress_OPC_SERVER_NAME 	= 13;
const unsigned fwPeriphAddress_OPC_GROUP_IN 	= 14;
const unsigned fwPeriphAddress_OPC_GROUP_OUT 	= 15;
const unsigned fwPeriphAddress_OPC_OBJECT_SIZE	= 15;
//@}
/** @name OPC UA address object
*/
///@{
const unsigned fwPeriphAddress_OPCUA_LOWLEVEL 	= 11; //!<Low level comparison
const unsigned fwPeriphAddress_OPCUA_SERVER_NAME 	= 12;//!<OPC UA Server name
const unsigned fwPeriphAddress_OPCUA_SUBSCRIPTION 	= 13;//!<Subscription name
const unsigned fwPeriphAddress_OPCUA_KIND 	= 14;//!<Kind (1=Value; 2=Event; 3=Alarm)
const unsigned fwPeriphAddress_OPCUA_VARIANT	= 15;//!<Variant (1=Node ID; 2=Browse Path)
const unsigned fwPeriphAddress_OPCUA_POLL_GROUP	= 16;//!<Polling group name
const unsigned fwPeriphAddress_OPCUA_OBJECT_SIZE	= 16;
//@}
/** @name DIM address object
*/
///@{
const unsigned fwPeriphAddress_DIM_CONFIG_DP	 			= 11;
const unsigned fwPeriphAddress_DIM_DEFAULT_VALUE 		= 12;
const unsigned fwPeriphAddress_DIM_TIMEOUT					= 13;
const unsigned fwPeriphAddress_DIM_FLAG				 			= 14;
const unsigned fwPeriphAddress_DIM_IMMEDIATE_UPDATE	= 15;
const unsigned fwPeriphAddress_DIM_OBJECT_SIZE	= 15;
const unsigned fwPeriphAddress_DIM_DRIVER_NUMBER = 1;
//@}
/** @name DIP address object
*/
///@{
const unsigned fwPeriphAddress_DIP_CONFIG_DP 	= 11;
const unsigned fwPeriphAddress_DIP_BUFFER_TIME 	= 12;
//@}

// Misc
const int PVSS_ADDRESS_LOWLEVEL_TO_MODE = 64;

// Data type
const int PVSS_MODBUS_INT16 = 561;
const int PVSS_MODBUS_INT32 = 562;
const int PVSS_MODBUS_UINT16 = 563;
const int PVSS_MODBUS_BOOL = 567;
const int PVSS_MODBUS_FLOAT = 566;


const int fwPeriphAddress_PANEL_MODE_OBJECT	= 1;
const int fwPeriphAddress_PANEL_MODE_SINGLE_DPE		= 2;
const int fwPeriphAddress_PANEL_MODE_MULTIPLE_DPES	= 3;

/** @name Basic Functions
 */
///@{
/**
@ingroup fwPeripheryAddress
@brief Get the address config of a datapoint element.

The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.

@par Examples
get the address of a dpe
\snippet fwPeriphAddress_Examples.ctl Example: get a periphery address configuration

@par Constraints
	Currently only supports MODBUS, OPCCLIENT, OPC UA, DIP and DIMCLIENT address types

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe	datapoint element to read from
@param configExists				TRUE if address config exists, else FALSE
@param config		Address object is returned here (configParameters). See description for configParameters on fwPeriphAddress_set()
@param isActive				TRUE is address config is active, else FALSE
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_get(string dpe, bool &configExists, dyn_anytype &config, bool &isActive, dyn_string &exceptionInfo)
{
	bool isRunning;
	int res, configType, datatype, mode, driverNumber, result, position;
	string reference;
	dyn_string configTypeData, referenceParts;
	dyn_errClass err;
	dyn_int timeouts, flags, immediateUpdates;
	dyn_string defaultValues, dimList, dpeList, systems;
	dyn_dyn_anytype returnValue;

	config = makeDynString();
	configExists = FALSE;
	isActive = FALSE;
	config[fwPeriphAddress_DIRECTION] = 0;
	config[fwPeriphAddress_DRIVER_NUMBER] = 0;

	dpGet(dpe + ":_distrib.._type", configType,
		  dpe + ":_distrib.._driver", driverNumber);
	config[fwPeriphAddress_DRIVER_NUMBER] = driverNumber;
	_fwConfigs_getSystemsInDpeList(makeDynString(dpe), systems, exceptionInfo);
	fwPeriphAddress_checkIsDriverRunning(driverNumber, isRunning, exceptionInfo, systems[1]);

 //DebugN("configType: ", configType, "driverNumber: ", driverNumber);

	if(configType == DPCONFIG_NONE)
	{
		return;
	}
	else if(!isRunning)
	{
		configExists = TRUE;
		fwException_raise(exceptionInfo, "ERROR", "Could not access address config (Make sure driver number " + driverNumber + " is running)", driverNumber);
		return;
	}

	dpGet(dpe + ":_address.._type",	configType);
	if(configType != DPCONFIG_NONE)
	{
		dpGet(dpe + ":_address.._drv_ident",	config[fwPeriphAddress_TYPE]);

		configTypeData = strsplit(config[fwPeriphAddress_TYPE], "/");
		switch(configTypeData[1])
		{
			case fwPeriphAddress_TYPE_IEC:
				dpGet(  dpe + ":_address.._reference", 	config[fwPeriphAddress_ROOT_NAME],
						dpe + ":_address.._subindex", 	config[fwPeriphAddress_IEC_SUBINDEX],
						dpe + ":_address.._datatype",	        config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._active", 	        config[fwPeriphAddress_ACTIVE]);
				configExists = TRUE;
				break;
			case fwPeriphAddress_TYPE_MODBUS:
				dpGet(  dpe + ":_address.._reference", 	config[fwPeriphAddress_ROOT_NAME],
						dpe + ":_address.._subindex", 	config[fwPeriphAddress_MODBUS_SUBINDEX],
						dpe + ":_address.._start", 		config[fwPeriphAddress_MODBUS_START],
						dpe + ":_address.._interval", 	config[fwPeriphAddress_MODBUS_INTERVAL],
						dpe + ":_address.._datatype",	config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._lowlevel", 	config[fwPeriphAddress_MODBUS_LOWLEVEL],
						dpe + ":_address.._poll_group", config[fwPeriphAddress_MODBUS_POLL_GROUP],
						dpe + ":_address.._active", 	config[fwPeriphAddress_ACTIVE]);
				isActive = config[fwPeriphAddress_ACTIVE];
				configExists = TRUE;
				break;

			case fwPeriphAddress_TYPE_OPCCLIENT:
				dpGet(  dpe + ":_address.._reference", 	reference,
						dpe + ":_address.._datatype",	config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._subindex", 	config[fwPeriphAddress_OPC_SUBINDEX],
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._lowlevel", 	config[fwPeriphAddress_OPC_LOWLEVEL],
						dpe + ":_address.._active", 	config[fwPeriphAddress_ACTIVE]);
				referenceParts = strsplit(reference, "$");
				//OPC DA
				//referenceParts must be like Server$Group$Item
				if(dynlen(referenceParts) != 3)
				{
					referenceParts[3] = "";
					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): OPC address is invalid", "");
				}
				config[fwPeriphAddress_OPC_SERVER_NAME] = referenceParts[1];
				config[fwPeriphAddress_ROOT_NAME] = referenceParts[3];

				if(config[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
				{
					config[fwPeriphAddress_OPC_GROUP_OUT] = referenceParts[2];
					config[fwPeriphAddress_OPC_GROUP_IN] = "";
				}
				else
				{
					config[fwPeriphAddress_OPC_GROUP_IN] = referenceParts[2];
					config[fwPeriphAddress_OPC_GROUP_OUT] = "";
				}
				isActive = config[fwPeriphAddress_ACTIVE];
				configExists = TRUE;
				break;

			case fwPeriphAddress_TYPE_OPCUACLIENT:
				dpGet(  dpe + ":_address.._reference", 	reference,
						dpe + ":_address.._datatype",	config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._lowlevel", 	config[fwPeriphAddress_OPC_LOWLEVEL],
						dpe + ":_address.._poll_group", config[fwPeriphAddress_OPCUA_POLL_GROUP],
						dpe + ":_address.._active", 	config[fwPeriphAddress_ACTIVE]);

				referenceParts = strsplit(reference, "$");

				/*OPC UA
				referenceParts must be like:
				Server$Subscription$Kind$Variant$Item
				 or like:
				Server$$Variant$Item */
 //DebugN("reference: "+reference);
 //DebugN("referenceParts: ",referenceParts);

				switch(dynlen(referenceParts))
				{
					case 5:
						break;
					case 4:
      referenceParts[5] = "";//item is empty string
						break;
					default:
						referenceParts[5] = "";
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): OPC UA address is invalid (address " + reference + " does not comply with any of the patterns Server$Subscription$Kind$Variant$Item, Server$$Variant$Item", "");
				}
				config[fwPeriphAddress_OPCUA_SERVER_NAME] = referenceParts[1];
				config[fwPeriphAddress_OPCUA_SUBSCRIPTION] = referenceParts[2];
				config[fwPeriphAddress_OPCUA_KIND] = referenceParts[3];
				config[fwPeriphAddress_OPCUA_VARIANT] = referenceParts[4];
				config[fwPeriphAddress_ROOT_NAME] = referenceParts[5];

				isActive = config[fwPeriphAddress_ACTIVE];
				configExists = TRUE;
				break;

			case fwPeriphAddress_TYPE_DIM:
			case fwPeriphAddress_TYPE_DIMCLIENT:
				if (dynlen(dpTypes("_FwDimConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
				    fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): Can not read the DIM config.  The DIM framework component is not installed.", "");
				    return;
				}

				//DIM functions only support local systems so remove sys name
				dpe = dpSubStr(dpe, DPSUB_DP_EL);
				config[fwPeriphAddress_TYPE] = configTypeData[1];
				if(dynlen(configTypeData) > 1)
				{
					config[fwPeriphAddress_DIM_CONFIG_DP] = configTypeData[2];
				}

				fwDim_getSubscribedCommands(config[fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList, flags);
				position = dynContains(dpeList, dpe);
				if(position <= 0)
				{
					fwDim_getSubscribedServices(config[fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList,
												defaultValues, timeouts, flags, immediateUpdates);
					position = dynContains(dpeList, dpe);
					if(position > 0)
					{
						configExists = TRUE;
						isActive = TRUE;
						config[fwPeriphAddress_ACTIVE] = isActive;
						config[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_SPONT;
						config[fwPeriphAddress_ROOT_NAME] = dimList[position];
						config[fwPeriphAddress_DIM_DEFAULT_VALUE] = defaultValues[position];
						config[fwPeriphAddress_DIM_TIMEOUT] = timeouts[position];
						config[fwPeriphAddress_DIM_FLAG] = flags[position];
						config[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] = immediateUpdates[position];
					}
				}
				else
				{
					configExists = TRUE;
					isActive = TRUE;
					config[fwPeriphAddress_ACTIVE] = isActive;
					config[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_OUTPUT_SINGLE;
					config[fwPeriphAddress_ROOT_NAME] = dimList[position];
				}
				break;
			case fwPeriphAddress_TYPE_DIP:
				if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
				    fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): Can not read the DIP config.  The DIP framework component is not installed.", "");
				    return;
				}
				fwDIP_getDpeSubscription(dpe, configExists, config[fwPeriphAddress_DIP_CONFIG_DP], config[fwPeriphAddress_ROOT_NAME], exceptionInfo);
				isActive = TRUE;
				break;
			case "0":
//DebugN("Empty address config case");
				configExists = TRUE;
				break;
			default:
				config = makeDynAnytype(configTypeData[1]);
				if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_get"))
				{
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_get");
					res = evalScript(returnValue, "dyn_dyn_anytype main(string dpe, dyn_string exInfo)"
									 + "{ "
									 + " bool active;"
									 + " dyn_anytype addressConfig;"
									 + " dyn_dyn_anytype returnValue;"
									 + " _fwPeriphAddress" + configTypeData[1] + "_get(dpe, addressConfig, active, exInfo);"
									 + " returnValue[1] = addressConfig;"
									 + " returnValue[2][1] = active;"
									 + " returnValue[3] = exInfo;"
									 + " return returnValue;"
									 + "}", makeDynString(), dpe, exceptionInfo);
					config = returnValue[1];
					isActive = returnValue[2][1];
					exceptionInfo = returnValue[3];
					configExists = TRUE;
//DebugN(isActive, config, exceptionInfo);
				}
				else
				{
					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): Unsupported peripheral address type.  Could not retreive full configuration.", "");
					configExists = TRUE;
				}
				break;
		}
	}
}


/**
@ingroup fwPeripheryAddress
@brief Get the address config of a datapoint element.

The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.

@par Constraints
	Currently only supports MODBUS, OPCCLIENT, DIP and DIMCLIENT address types

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@see fwPeriphAddress_get()

@param dpes	datapoint element to read from. Passed as reference for performance reasons. Not modified.
@param configExists				TRUE if address config exists, else FALSE
@param config		address object is returned here. See fwPeriphAddress_get() for details on the addess object.
@param isActive				TRUE is address config is active, else FALSE
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_getMany(dyn_string &dpes, dyn_bool &configExists, dyn_dyn_anytype &config, dyn_bool &isActive, dyn_string &exceptionInfo)
{
	bool isRunning;
	int res, configType, datatype, mode, driverNumber, result, position;
	string reference, dpe;
	dyn_string configTypeData, referenceParts;
	dyn_errClass err;
	dyn_int timeouts, flags, immediateUpdates;
	dyn_string defaultValues, dimList, dpeList, systems;
	dyn_dyn_anytype returnValue;

	dyn_string dsDpAttr, dsTypesAttr, dsDriveAttr, dsDriveVal, dsAddressTypeAttr, dsAddressTypeVal, dsAddressAttr, dsDistDriveAttr;
	dyn_int diTypesVal, diTempVal, diDistDriveVal;
	dyn_mixed dsAttrVal, dmTempVal, dsAddressVal;
	int i, j, k, n, o;//yes we need all those indexes...
	int length, iAttrsLen, iTemp;
	int ret;
	dyn_string dsTempVal;
	dyn_int diDriverNum;

	config = makeDynString();
	length = dynlen(dpes);
// DebugN("len: "+length);

	//get the info on drivers type and number, store them into dsTypesAttr.
	for(i = 1 ; i <= length ; i++)
	{
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
		dynAppend(dsTypesAttr , dpes[i] + ":_distrib.._type");
		if((dynlen(dsTypesAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsTypesAttr) > 0))
		{
			dpGet(dsTypesAttr, diTempVal);
			dynAppend(diTypesVal, diTempVal);
// DebugN("dsTypesAttr: ",dsTypesAttr);
			dynClear(dsTypesAttr);
		}
	}
// DebugN("dsTypesVal: ",diTypesVal);

	//get the info on drivers type and number, store them into dsTypesAttr.
	for(i = 1 ; i <= length ; i++)
	{
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
		if(diTypesVal[i] != DPCONFIG_NONE)
		{
			dynAppend(dsDistDriveAttr , dpes[i] + ":_distrib.._driver");
		}
		if((dynlen(dsDistDriveAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDistDriveAttr) > 0))
		{
			dpGet(dsDistDriveAttr, diTempVal);
			dynAppend(diDistDriveVal, diTempVal);
// DebugN("dsDistDriveAttr: ",dsDistDriveAttr);
			dynClear(dsDistDriveAttr);
		}
	}
// DebugN("diDistDriveVal: ",diDistDriveVal);

	mapping checkedSystems;
	j = 1; //:_distrib.._driver
	for(i = 1 ; i <= length ; i++)
	{
		if(diTypesVal[i] != DPCONFIG_NONE)
		{
			_fwConfigs_getSystemsInDpeList(dpes[i], systems, exceptionInfo);
			config[i][fwPeriphAddress_DRIVER_NUMBER] = diDistDriveVal[j];
			driverNumber = diDistDriveVal[j];
			string key= driverNumber + "_" + systems[1];
			if (mappingHasKey(checkedSystems,key)) {
			    j++;
			    continue;
			}
			checkedSystems[key]=true;
			fwPeriphAddress_checkIsDriverRunning(driverNumber, isRunning, exceptionInfo, systems[1]);
// DebugN("check driver for: "+ dpes[i],"diDistDriveVal[j]: ", diDistDriveVal[j], "driverNumber: ",driverNumber, "isRunning: ", isRunning, "exceptionInfo:", exceptionInfo, "systems[1]: ",systems[1]);
			if(!isRunning)
			{
				configExists[i] = TRUE;
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Could not access address config for dpe '" + dpes[i] + "' (Make sure driver number " + driverNumber + " is running)", driverNumber);
				return;
			}
			j++;//:_distrib.._driver
		}
		else
		{
			configExists[i] = FALSE;
			isActive[i] = FALSE;
			config[i][fwPeriphAddress_DIRECTION] = 0;
			config[i][fwPeriphAddress_DRIVER_NUMBER] = 0;
		}

	}

	//get the :_address.._type, store all the values into dsAddressTypeAttr
	for(i = 1 ; i <= length ; i++)
	{
		dynAppend(dsAddressTypeAttr , dpes[i] + ":_address.._type");
		if((dynlen(dsAddressTypeAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsAddressTypeAttr) > 0))
		{
			dpGet(dsAddressTypeAttr, dsTempVal);
			dynAppend(dsAddressTypeVal, dsTempVal);
// DebugN("dsAddressTypeAttr:",dsAddressTypeAttr);
			dynClear(dsAddressTypeAttr);
		}
	}
// DebugN("dsAddressTypeVal:",dsAddressTypeVal);

	//get the _address.._drv_ident, store it into dsDriveVal
	for(i = 1 ; i <= length ; i++)
	{
		if(dsAddressTypeVal[i] != DPCONFIG_NONE)//check if _address.._type is non-null
		{
			dynAppend(dsDriveAttr, dpes[i] + ":_address.._drv_ident");
		}
		if((dynlen(dsDriveAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDriveAttr) > 0))
		{
			dpGet(dsDriveAttr, dsTempVal);
			dynAppend(dsDriveVal, dsTempVal);
// DebugN("dsDriveAttr:",dsDriveAttr);
			dynClear(dsDriveAttr);
		}
	}
// DebugN("dsDriveVal:",dsDriveVal);

	//get all the other attributes, store them into dsAddressVal
	iAttrsLen = dynlen(dsDriveVal);
	o = 1; //:_address.._type in dsAddressTypeVal
	n = 1; //:_address.._drv_ident in dsDriveVal
// DebugN("length:",length);
// DebugN("dsAddressTypeVal:",dsAddressTypeVal);
// DebugN("dsDriveVal:",dsDriveVal);
	for(i = 1 ; i <= length ; i++)
	{
// DebugN("diTypesVal[i]:",diTypesVal[i]);
		if(diTypesVal[i] != DPCONFIG_NONE)
		{
// DebugN("dsAddressTypeVal["+o+"] :",dsAddressTypeVal[o] );
			if(dsAddressTypeVal[o] != DPCONFIG_NONE)
			{
				config[i][fwPeriphAddress_TYPE] = dsDriveVal[n];
				configTypeData = strsplit(config[i][fwPeriphAddress_TYPE], "/");
// DebugN("config[i][fwPeriphAddress_TYPE]: "+config[i][fwPeriphAddress_TYPE]);
				switch(configTypeData[1])
				{
					case fwPeriphAddress_TYPE_IEC:
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._reference");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._subindex");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._datatype");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._direction");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._active");
						break;
					case fwPeriphAddress_TYPE_MODBUS:
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._reference");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._subindex");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._start");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._interval");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._datatype");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._direction");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._lowlevel");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._poll_group");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._active");
						break;
					case fwPeriphAddress_TYPE_OPCCLIENT:
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._reference");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._datatype");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._subindex");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._direction");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._lowlevel");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._active");
						break;
					case fwPeriphAddress_TYPE_OPCUACLIENT:
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._reference");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._datatype");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._direction");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._lowlevel");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._active");
						dynAppend(dsAddressAttr, dpes[i] + ":_address.._poll_group");
						break;
					case fwPeriphAddress_TYPE_DIM:
					case fwPeriphAddress_TYPE_DIMCLIENT:
						break;
					default:
						break;
				}
				n++;
			}

		}
		o++;
		if((dynlen(dsAddressAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsAddressAttr) > 0))
		{
			dpGet(dsAddressAttr, dmTempVal);
			dynAppend(dsAddressVal, dmTempVal);
// DebugN("dsAddressAttr:",dsAddressAttr);
			dynClear(dsAddressAttr);
		}
	}
	//make type conversion
	for(i = 1 ; i <= dynlen(dsAddressVal) ; i++)
	{
		if(getType(dsAddressVal[i]) == CHAR_VAR && (dsAddressVal[i] == '\02' || dsAddressVal[i] == '\04'))
		{
			iTemp = dsAddressVal[i];
			dsAddressVal[i] = iTemp;
		}
	}
// DebugN("dsAddressVal:",dsAddressVal);
	//arrange attributes values into configuration variables
	k = 1; //:_distrib.._type in diTypesVal
	j = 1; //:_distrib.._type in dsAddressTypeVal
	n = 1; //:_address.._drv_ident in dsDriveVal
	o = 1; //:_address.._type in dsAddressVal
	for(i = 1 ; i <= length ; i++)
	{
		configExists[i] = FALSE;
		isActive[i] = FALSE;
		config[i][fwPeriphAddress_DIRECTION] = 0;
// DebugN("diTypesVal["+k+"]:",diTypesVal[k]);
		if(diTypesVal[k] != DPCONFIG_NONE)
		{
// DebugN("dsAddressTypeVal["+j+"]:",dsAddressTypeVal[j]);
			if(dsAddressTypeVal[j] != DPCONFIG_NONE)
			{
				config[i][fwPeriphAddress_TYPE] = dsDriveVal[n];
				configTypeData = strsplit(config[i][fwPeriphAddress_TYPE], "/");
// DebugN("configTypeData[1]:",configTypeData[1]);
				switch(configTypeData[1])
				{
					case fwPeriphAddress_TYPE_IEC:
						config[i][fwPeriphAddress_ROOT_NAME] = dsAddressVal[o];
						o++; //_address.._reference
						config[i][fwPeriphAddress_IEC_SUBINDEX] = dsAddressVal[o];
						o++; //_address.._subindex
						config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o];
						o++; //_address.._datatype
						config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o];
						o++; //_address.._direction
						config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o];
						o++; //_address.._active
						isActive[i] = config[i][fwPeriphAddress_ACTIVE];
						configExists[i] = TRUE;
						break;
					case fwPeriphAddress_TYPE_MODBUS:
						config[i][fwPeriphAddress_ROOT_NAME] = dsAddressVal[o];
						o++; //_address.._reference
						config[i][fwPeriphAddress_MODBUS_SUBINDEX] = dsAddressVal[o];
						o++; //_address.._subindex
						config[i][fwPeriphAddress_MODBUS_START] = (time)dsAddressVal[o];
						o++; //_address.._start
						config[i][fwPeriphAddress_MODBUS_INTERVAL] = (time)dsAddressVal[o];
						o++; //_address.._interval
						config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o];
						o++; //_address.._datatype
						config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o];
						o++; //_address.._direction
						config[i][fwPeriphAddress_MODBUS_LOWLEVEL] = dsAddressVal[o];
						o++; //_address.._lowlevel
						config[i][fwPeriphAddress_MODBUS_POLL_GROUP] = dsAddressVal[o];
						o++; //_address.._poll_group
						config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o];
						o++; //_address.._active
						isActive[i] = config[i][fwPeriphAddress_ACTIVE];
						configExists[i] = TRUE;
						break;
					case fwPeriphAddress_TYPE_OPCCLIENT:
						reference = dsAddressVal[o];
						o++; //_address.._reference
						config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o];
						o++; //_address.._datatype
						config[i][fwPeriphAddress_OPC_SUBINDEX] = dsAddressVal[o];
						o++; //_address.._subindex
						config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o];
						o++; //_address.._direction
						config[i][fwPeriphAddress_OPC_LOWLEVEL] = dsAddressVal[o];
						o++; //_address.._lowlevel
						config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o];
						o++; //_address.._active

						referenceParts = strsplit(reference, "$");
						if(dynlen(referenceParts) != 3)
						{
							referenceParts[3] = "";
							fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): OPC address (" + reference + ") is invalid on dpe '" + dpes[i] + "'", "");
						}
						config[i][fwPeriphAddress_OPC_SERVER_NAME] = referenceParts[1];
						config[i][fwPeriphAddress_ROOT_NAME] = referenceParts[3];

						if(config[i][fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
						{
							config[i][fwPeriphAddress_OPC_GROUP_OUT] = referenceParts[2];
							config[i][fwPeriphAddress_OPC_GROUP_IN] = "";
						}
						else
						{
							config[i][fwPeriphAddress_OPC_GROUP_IN] = referenceParts[2];
							config[i][fwPeriphAddress_OPC_GROUP_OUT] = "";
						}
						isActive[i] = config[i][fwPeriphAddress_ACTIVE];
						configExists[i] = TRUE;
						break;

					case fwPeriphAddress_TYPE_OPCUACLIENT:
						/*OPC UA1
						 referenceParts must be like:
						 Server$Subscription$Kind$Variant$Item
						  or like:
						 Server$$Variant$Item */
						reference = dsAddressVal[o];
						o++; //_address.._reference
						config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o];
						o++; //_address.._datatype
						config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o];
						o++; //_address.._direction
						config[i][fwPeriphAddress_OPCUA_LOWLEVEL] = dsAddressVal[o];
						o++; //_address.._lowlevel
						config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o];
						o++; //_address.._active
						config[i][fwPeriphAddress_OPCUA_POLL_GROUP] = dsAddressVal[o];
						o++; //_address.._poll_group
						referenceParts = strsplit(reference, "$");
//DebugN("dpe: " +dpes[i]+"  reference: "+reference);
						switch(dynlen(referenceParts))
						{
							case 5:
								break;
							case 4:
								break;
							default:
								referenceParts[5] = "";
								fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): OPC UA address is invalid for dpe " + dpes[i] + " (address " + reference + " does not comply with any of the patterns Server$Subscription$Kind$Variant$Item, Server$$Variant$Item", "");
						}
						config[i][fwPeriphAddress_OPCUA_SERVER_NAME] = referenceParts[1];
						if(dynlen(referenceParts) == 5) //Subscription name defined
						{
							config[i][fwPeriphAddress_OPCUA_SUBSCRIPTION] = referenceParts[2];
							config[i][fwPeriphAddress_OPCUA_KIND] = referenceParts[3];
							config[i][fwPeriphAddress_OPCUA_VARIANT] = referenceParts[4];
							config[i][fwPeriphAddress_ROOT_NAME] = referenceParts[5];
						}
						else//Subscription name not defined
						{
							config[i][fwPeriphAddress_OPCUA_SUBSCRIPTION] = referenceParts[2];
							config[i][fwPeriphAddress_OPCUA_KIND] = "";
							config[fwPeriphAddress_OPCUA_VARIANT] = referenceParts[3];
							config[i][fwPeriphAddress_ROOT_NAME] = referenceParts[4];
						}
						isActive[i] = config[i][fwPeriphAddress_ACTIVE];
						configExists[i] = TRUE;
						break;

					case fwPeriphAddress_TYPE_DIM:
					case fwPeriphAddress_TYPE_DIMCLIENT:
						if (dynlen(dpTypes("_FwDimConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
						    fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Can not read the DIM config for dpe '" + dpes[i] + "'.  The DIM framework component is not installed.", "");
						    return;
						}
						//DIM functions only support local systems so remove sys name
						dpe = dpSubStr(dpes[i], DPSUB_DP_EL);
						config[i][fwPeriphAddress_TYPE] = configTypeData[1];
						if(dynlen(configTypeData) > 1)
						{
							config[i][fwPeriphAddress_DIM_CONFIG_DP] = configTypeData[2];
						}

						fwDim_getSubscribedCommands(config[i][fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList, flags);
						position = dynContains(dpeList, dpe);
						if(position <= 0)
						{
							fwDim_getSubscribedServices(config[i][fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList,
														defaultValues, timeouts, flags, immediateUpdates);
							position = dynContains(dpeList, dpe);
							if(position > 0)
							{
								configExists[i] = TRUE;
								isActive[i] = TRUE;
								config[i][fwPeriphAddress_ACTIVE] = isActive[i];
								config[i][fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_SPONT;
								config[i][fwPeriphAddress_ROOT_NAME] = dimList[position];
								config[i][fwPeriphAddress_DIM_DEFAULT_VALUE] = defaultValues[position];
								config[i][fwPeriphAddress_DIM_TIMEOUT] = timeouts[position];
								config[i][fwPeriphAddress_DIM_FLAG] = flags[position];
								config[i][fwPeriphAddress_DIM_IMMEDIATE_UPDATE] = immediateUpdates[position];
							}
						}
						else
						{
							configExists[i] = TRUE;
							isActive[i] = TRUE;
							config[i][fwPeriphAddress_ACTIVE] = isActive[i];
							config[i][fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_OUTPUT_SINGLE;
							config[i][fwPeriphAddress_ROOT_NAME] = dimList[position];
						}
						break;
					case fwPeriphAddress_TYPE_DIP:
						if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
						    fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Can not read the DIP config for dpe '" + dpes[i] + "'.  The DIP framework component is not installed.", "");
						    return;
						}

						fwDIP_getDpeSubscription(dpes[i], configExists[i], config[i][fwPeriphAddress_DIP_CONFIG_DP], config[i][fwPeriphAddress_ROOT_NAME], exceptionInfo);
						isActive[i] = TRUE;
						break;
					case "0":
						//DebugN("Empty address config case");
						configExists[i] = TRUE;
						break;
					default:
						config[i] = makeDynAnytype(configTypeData[1]);
						if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_get"))
						{
							dpe = dpes[i];
							//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_get");
							res = evalScript(returnValue, "dyn_dyn_anytype main(string dpe, dyn_string exInfo)"
											 + "{ "
											 + " bool active;"
											 + " dyn_anytype addressConfig;"
											 + " dyn_dyn_anytype returnValue;"
											 + " _fwPeriphAddress" + configTypeData[1] + "_get(dpe, addressConfig, active, exInfo);"
											 + " returnValue[1] = addressConfig;"
											 + " returnValue[2][1] = active;"
											 + " returnValue[3] = exInfo;"
											 + " return returnValue;"
											 + "}", makeDynString(), dpe, exceptionInfo);
							config[i] = returnValue[1];
							isActive[i] = returnValue[2][1];
							exceptionInfo = returnValue[3];
							configExists[i] = TRUE;
						}
						else
						{
							fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Unsupported peripheral address type (" + configTypeData[1] + ") for dpe '" + dpes[i] + "'.  Could not retreive full configuration.", "");
							configExists[i] = TRUE;
						}
						break;
				}
				n++;//:_address.._drv_ident in dsDriveVal
			}
		}
		j++;//:_address.._type in dsAddressTypeVal
		k++;//item in diTypesVal is a :_distrib.._type
	}
// DebugN("configExists:",configExists);
}


/**
@ingroup fwPeripheryAddress
@brief Set the address config for a given data point element

@par Constraints
	Currently supports S7, MODBUS, OPCCLIENT, OPC UA, DIP and DIMCLIENT address types

@par Examples

  Example: S7.\n
  It connects the dpe sys_1:testPerAddr.input to the element DB81.DBD0F.
  The PLC connection is defined on Test_PLC.
\snippet fwPeriphAddress_Examples.ctl Example: create S7 periphery address

  Example: OPC UA. \n
  It connects the dpe sys_1:testPerAddr.input to the element OPCUAConnection1$subscription2$1$1$item1.
  The OPC UA Client connection is defined on OPCUAConnection1.
\snippet fwPeriphAddress_Examples.ctl Example: create OPC UA periphery address

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe	datapoint element to act on
@param configParameters		Address object is passed here:														\n\n
			- configParameters[fwPeriphAddress_TYPE] contains type of addressing:										\n
				-- fwPeriphAddress_TYPE_OPCCLIENT															\n
				-- fwPeriphAddress_TYPE_OPCUACLIENT															\n
				-- fwPeriphAddress_TYPE_DIMCLIENT															\n
				-- fwPeriphAddress_TYPE_DIP																\n
				-- fwPeriphAddress_TYPE_MODBUS																\n
				-- fwPeriphAddress_TYPE_S7																	\n
				-- fwPeriphAddress_TYPE_CMW																\n
			- configParameters[fwPeriphAddress_DRIVER_NUMBER] contains driver number										\n
			- configParameters[fwPeriphAddress_ROOT_NAME] 	contains address string										\n
			- configParameters[fwPeriphAddress_DIRECTION] 	contains direction of address for dpe:							\n
				-- DPATTR_ADDR_MODE_OUTPUT_SINGLE															\n
				-- DPATTR_ADDR_MODE_INPUT_SPONT																\n
				-- 6 for in/out (no PVSS constant available yet)												\n
			- configParameters[fwPeriphAddress_DATATYPE] 		contains the translation datatype							\n
			- configParameters[fwPeriphAddress_ACTIVE] 		contains whether or not the address is active						\n
											Note: This active parameter is ignored if using DIM (always active)		\n
\n
			- MODBUS Specific entries in address object:														\n
				-- configParameters[fwPeriphAddress_MODBUS_LOWLEVEL] 												\n
				-- configParameters[fwPeriphAddress_MODBUS_SUBINDEX] 												\n
				-- configParameters[fwPeriphAddress_MODBUS_START] 													\n
				-- configParameters[fwPeriphAddress_MODBUS_INTERVAL]												\n
				-- configParameters[fwPeriphAddress_POLL_GROUP]												\n
\n
			- OPC Specific entries in address object:															\n
				-- configParameters[fwPeriphAddress_OPC_LOWLEVEL] 	contains is lowlevel comparison is enabled (output only)			\n
				-- configParameters[fwPeriphAddress_OPC_SUBINDEX] 	contains subindex if datatype = 'bitstring'					\n
				-- configParameters[fwPeriphAddress_OPC_SERVER_NAME] contains OPC server name								\n
				-- configParameters[fwPeriphAddress_OPC_GROUP_IN] contains OPC group for input address configs only				\n
				-- configParameters[fwPeriphAddress_OPC_GROUP_OUT] contains OPC group for output address configs only				\n
\n
			- OPC UA Specific entries in address object:															\n
				-- configParameters[fwPeriphAddress_OPCUA_LOWLEVEL] 	contains is lowlevel comparison is enabled (output only)			\n
				-- configParameters[fwPeriphAddress_OPCUA_SERVER_NAME] contains OPC server name								\n
				-- configParameters[fwPeriphAddress_OPCUA_SUBSCRIPTION] contains OPC UA subscription name				\n
				-- configParameters[fwPeriphAddress_OPCUA_KIND] contains OPC UA kind				\n
				-- configParameters[fwPeriphAddress_OPCUA_VARIANT] contains OPC UA variant 				\n
 				-- configParameters[fwPeriphAddress_OPCUA_POLL_GROUP] contains polling group name (including system name). Compulsory in case no subscription is specified 				\n
\n
			- DIM Client Service Specific entries in address object:												\n
				-- configParameters[fwPeriphAddress_DIM_CONFIG_DP]  the DIM config data point to which the config is saved			\n
				-- configParameters[fwPeriphAddress_DIM_DEFAULT_VALUE] 	default value setting								\n
				-- configParameters[fwPeriphAddress_DIM_TIMEOUT]		timeout setting									\n
				-- configParameters[fwPeriphAddress_DIM_FLAG]			flag setting								\n
				-- configParameters[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] 	immediate update setting						\n
\n
			- DIP Client Specific entries in address object:														\n
				-- configParameters[fwPeriphAddress_DIP_CONFIG_DP]  the DIP config data point to which the config is saved			\n
\n
			- S7 Specific entries in address object:															\n
				--  configParameters[fwPeriphAddress_S7_LOWLEVEL]													\n
				-- configParameters[fwPeriphAddress_S7_SUBINDEX]													\n
				-- configParameters[fwPeriphAddress_S7_START]													\n
				-- configParameters[fwPeriphAddress_S7_INTERVAL]													\n
				-- configParameters[fwPeriphAddress_S7_POLL_GROUP]													\n
\n8
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
												The necessary driver number must be running in order to successfully create config
@param setWait		determines if dpSetWait or dpSet should be used
*/
fwPeriphAddress_set(string dpe, dyn_anytype configParameters, dyn_string& exceptionInfo, bool runDriverCheck = FALSE, bool setWait = TRUE)
{
	if (isDollarDefined("$bIgnoreDriverRelatedConfigs"))   	//this check is done in order to make UNICOS CPC skip the set
	{
		if (getDollarValue("$bIgnoreDriverRelatedConfigs"))   //of periphery address in case the driver is running. bIgnoreDriverRelatedConfigs=true exits the function
		{
			fwException_raise(exceptionInfo, "INFO", "fwPeriphAddress_set(): dpe " + dpe + " won't be configured (due to parameter bIgnoreDriverRelatedConfigs)", "");
			return ;
		}
	}
	bool isRunning, inputOk = true;
	bool lowLevel;
	int res, oldLength, groupType, direction, result;
	string dipItem, dipTag, dipConfigDp, dimConfigDp, errorString;
	dyn_string configTypeData, systems;
	dyn_errClass err;

	if((configParameters[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIM) || (configParameters[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIMCLIENT))
	{
		configParameters[fwPeriphAddress_DRIVER_NUMBER] = fwPeriphAddress_DIM_DRIVER_NUMBER;
	}

	if(runDriverCheck)
	{
		_fwConfigs_getSystemsInDpeList(makeDynString(dpe), systems, exceptionInfo);
		fwPeriphAddress_checkIsDriverRunning(configParameters[fwPeriphAddress_DRIVER_NUMBER], isRunning, exceptionInfo, systems[1]);
		if(!isRunning)
		{
			errorString = getCatStr("fwPeriphAddress", "ERROR_DRIVERNOTRUNNING");
			strreplace(errorString, "<driver>", configParameters[fwPeriphAddress_DRIVER_NUMBER]);
			fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): " + errorString, "");
			return;
		}
	}

	oldLength = dynlen(exceptionInfo);
	if (dpExists(dpe))
	{
		if (dynlen(configParameters) >= 1)
		{
			switch (configParameters[fwPeriphAddress_TYPE])
			{
				case fwPeriphAddress_TYPE_S7:
					// S7 often used; avoid calling through evalScript
					_fwPeriphAddressS7_set(dpe, configParameters, exceptionInfo, setWait);
					break;
				case fwPeriphAddress_TYPE_IEC:
					fwPeriphAddress_setIEC(dpe, configParameters, exceptionInfo, setWait);
					break;
				case fwPeriphAddress_TYPE_MODBUS:
					if (dynlen(configParameters) == FW_PARAMETER_FIELD_NUMBER)
					{
						fwPeriphAddress_setModbus(dpe, configParameters, exceptionInfo, setWait);
					}
					else
					{
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The address configuration data for dpe '" + dpe + "'is not valid: incorrect number of parameters.", "");
					}
					break;

				case fwPeriphAddress_TYPE_OPC:
				case fwPeriphAddress_TYPE_OPCCLIENT:
					if(configParameters[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
					{
						groupType = fwPeriphAddress_OPC_GROUP_OUT;
					}
					else
					{
						groupType = fwPeriphAddress_OPC_GROUP_IN;
					}

					lowLevel = configParameters[fwPeriphAddress_OPC_LOWLEVEL];
					direction = configParameters[fwPeriphAddress_DIRECTION];

					//DebugN(lowLevel, configParameters[fwPeriphAddress_DIRECTION]);
					fwPeriphAddress_setOPC(dpe, configParameters[fwPeriphAddress_OPC_SERVER_NAME],
										   configParameters[fwPeriphAddress_DRIVER_NUMBER],
										   configParameters[fwPeriphAddress_ROOT_NAME],
										   configParameters[groupType],
										   configParameters[fwPeriphAddress_DATATYPE],
										   direction + (PVSS_ADDRESS_LOWLEVEL_TO_MODE * lowLevel),
										   configParameters[fwPeriphAddress_OPC_SUBINDEX],
										   exceptionInfo, setWait);

					if (dynlen(exceptionInfo) == oldLength)
					{
					    if (setWait)
						dpSetWait(dpe + ":_address.._active", configParameters[fwPeriphAddress_ACTIVE]);
					    else
						dpSet(dpe + ":_address.._active", configParameters[fwPeriphAddress_ACTIVE]);
					}

					err = getLastError();
					if(dynlen(err) > 0)
					{
						throwError(err);
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): Could not set active attribute for dpe '" + dpe + "'", "");
					}
					break;

				case fwPeriphAddress_TYPE_OPCUA:
				case fwPeriphAddress_TYPE_OPCUACLIENT:
					lowLevel = configParameters[fwPeriphAddress_OPCUA_LOWLEVEL];
					direction = configParameters[fwPeriphAddress_DIRECTION];

					fwPeriphAddress_setOPCUA(dpe,
											 configParameters[fwPeriphAddress_OPCUA_SERVER_NAME],
											 configParameters[fwPeriphAddress_DRIVER_NUMBER],
											 configParameters[fwPeriphAddress_ROOT_NAME],
											 configParameters[fwPeriphAddress_OPCUA_SUBSCRIPTION],
											 configParameters[fwPeriphAddress_OPCUA_KIND],
											 configParameters[fwPeriphAddress_OPCUA_VARIANT],
											 configParameters[fwPeriphAddress_DATATYPE],
											 direction + (PVSS_ADDRESS_LOWLEVEL_TO_MODE * lowLevel),
											 configParameters[fwPeriphAddress_OPCUA_POLL_GROUP],
											 exceptionInfo, setWait);

					if (dynlen(exceptionInfo) == oldLength)
					{
					    if (setWait)
						dpSetWait(dpe + ":_address.._active", configParameters[fwPeriphAddress_ACTIVE]);
					    else
						dpSet(dpe + ":_address.._active", configParameters[fwPeriphAddress_ACTIVE]);
					}

					err = getLastError();
					if(dynlen(err) > 0)
					{
						throwError(err);
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): Could not set active attribute for dpe '" + dpe + "'", "");
					}
					break;

				case fwPeriphAddress_TYPE_DIM:
				case fwPeriphAddress_TYPE_DIMCLIENT:
				    if (dynlen(dpTypes("_FwDimConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): Can not configure DIM addresses.  The DIM framework component is not installed.", "");
					return;
				    }

					dpe = dpSubStr(dpe, DPSUB_DP_EL);
					dimConfigDp = dpSubStr(configParameters[fwPeriphAddress_DIM_CONFIG_DP], DPSUB_DP);

					if(dpExists(dimConfigDp))
					{
						if(dpTypeName(dimConfigDp) == "_FwDimConfig")
						{
							configParameters[fwPeriphAddress_DIM_CONFIG_DP] = dimConfigDp;
						}
						else
						{
							fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The specified DP (" + dimConfigDp + ") is not a DIM config DP", "");
							return;
						}
					}
					else
					{
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The specified DIM config DP (" + dimConfigDp + ") does not exist", "");
						return;
					}

					//temporary code
					if (setWait)
					    dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
						      dpe + ":_distrib.._driver", fwPeriphAddress_DIM_DRIVER_NUMBER);
					else
					    dpSet(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
						  dpe + ":_distrib.._driver", fwPeriphAddress_DIM_DRIVER_NUMBER);
					_fwDim_setDpConfig(dpe, configParameters[fwPeriphAddress_DIM_CONFIG_DP]);
					//end of temporary code

					switch(configParameters[fwPeriphAddress_DIRECTION])
					{
						case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
							fwDim_subscribeCommand(configParameters[fwPeriphAddress_DIM_CONFIG_DP], configParameters[fwPeriphAddress_ROOT_NAME], dpe, 1);
							break;
						case DPATTR_ADDR_MODE_INPUT_SPONT:
							fwDim_subscribeService(configParameters[fwPeriphAddress_DIM_CONFIG_DP], configParameters[fwPeriphAddress_ROOT_NAME], dpe,
												   configParameters[fwPeriphAddress_DIM_DEFAULT_VALUE], configParameters[fwPeriphAddress_DIM_TIMEOUT],
												   configParameters[fwPeriphAddress_DIM_FLAG], configParameters[fwPeriphAddress_DIM_IMMEDIATE_UPDATE], 1);
							break;
					}
					break;
				case fwPeriphAddress_TYPE_DIP:
					if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): Can not set the DIP config.  The DIP framework component is not installed.", "");
						return;
					}
					dipConfigDp = configParameters[fwPeriphAddress_DIP_CONFIG_DP];
					if(dpExists(dipConfigDp)) {
					    if(dpTypeName(dipConfigDp) == "_FwDipConfig") {
						_fwDIP_splitAddress(configParameters[fwPeriphAddress_ROOT_NAME], dipItem, dipTag, exceptionInfo);
						fwDIP_subscribe(dpe, configParameters[fwPeriphAddress_DIP_CONFIG_DP], dipItem, dipTag, exceptionInfo, TRUE);
					    } else {
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The specified DP (" + dipConfigDp + ") is not a DIP config DP", "");
						return;
					    }
					} else {
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The specified DIP config DP (" + dipConfigDp + ") does not exist", "");
						return;
					}

					break;
				default:
					configTypeData = strsplit(configParameters[fwPeriphAddress_TYPE], "/");
					if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_set"))
					{
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_set");
						res = evalScript(exceptionInfo, "dyn_string main(string dpe, dyn_anytype addressConfig, dyn_string exInfo)"
										 + "{ "
										 + " _fwPeriphAddress" + configTypeData[1] + "_set(dpe, addressConfig, exInfo);"
										 + " return exInfo;"
										 + "}", makeDynString(), dpe, configParameters, exceptionInfo);
//DebugN(exceptionInfo);
					}
					else
					{
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set: " + getCatStr("fwPeriphAddress", "UNKNOWNCOMM"), "");
					}
					break;
			}
		}
		else
		{
			inputOk = false;
		}
	}
	else
	{
		inputOk = false;
	}
	if (!inputOk)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set: " + getCatStr("fwPeriphAddress", "BADINPUT"), "");
	}
}

/**
@ingroup fwPeripheryAddress
@brief Sets the address config for a given set of data point elements
See fwPeriphAddress_set() for an example.
@see fwPeriphAddress_set()
@param dpes	list of datapoint elements to act on
@param configParameters		Address objects are passed here, one per dpe. See fwPeriphAddress_set() for details.
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
												The necessary driver number must be running in order to successfully create config

 **/
fwPeriphAddress_setMany(dyn_string &dpes, dyn_dyn_anytype &configParameters, dyn_string& exceptionInfo, bool runDriverCheck = FALSE, bool setWait = TRUE)
{
	int i, length;
    bool _setWait;
    mapping checkedSystems;

    length = dynlen(dpes);
    if(runDriverCheck) {
	for(i = 1; i <= length; i++) {
	    dyn_string configTypeData, systems;
	    bool isRunning;
	    _fwConfigs_getSystemsInDpeList(makeDynString(dpes[i]), systems, exceptionInfo);
	    string key = configParameters[i][fwPeriphAddress_DRIVER_NUMBER] + "_" + systems[1];
	    if (mappingHasKey(checkedSystems,key)) continue;
	    checkedSystems[key]=true;
	    fwPeriphAddress_checkIsDriverRunning(configParameters[i][fwPeriphAddress_DRIVER_NUMBER], isRunning, exceptionInfo, systems[1]);
	    if (!isRunning) {
		string errorString = getCatStr("fwPeriphAddress", "ERROR_DRIVERNOTRUNNING");
		strreplace(errorString, "<driver>", configParameters[fwPeriphAddress_DRIVER_NUMBER]);
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): " + errorString, "");
		return;
	    }
	}
    }

    //using DIP setMany for DIP address type
    int dipResult = -1;
    mapping dip_configs = makeMapping();
    for(i = 1; i <= length; i++) {
	if (configParameters[i][fwPeriphAddress_TYPE]==fwPeriphAddress_TYPE_DIP) {
	if (dipResult==-1) {
	    //check once
	    if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setMany(): Can not set the DIP config.  The DIP framework component is not installed.", "");
		continue;
	    }
	}
	if (dipResult==0) continue;

	string dipItem,dipTag;
	string dipConfigDp = configParameters[i][fwPeriphAddress_DIP_CONFIG_DP];
	string root_name = configParameters[i][fwPeriphAddress_ROOT_NAME];

	if (!mappingHasKey(dip_configs,dipConfigDp)) //initialize
	{
	    if(!dpExists(dipConfigDp)) {
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setMany(): The specified DIP config DP (" + dipConfigDp + ") does not exist", "");
		continue;
	    }
	    if(dpTypeName(dipConfigDp) != "_FwDipConfig") {
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setMany(): The specified DP (" + dipConfigDp + ") is not a DIP config DP", "");
		continue;
	    }
	    dip_configs[dipConfigDp]=makeDynMixed(makeDynString(),makeDynString(),makeDynString());
        }
	_fwDIP_splitAddress(root_name, dipItem, dipTag, exceptionInfo);
	dynAppend(dip_configs[dipConfigDp][1],dpes[i]);
	dynAppend(dip_configs[dipConfigDp][2],dipItem);
	dynAppend(dip_configs[dipConfigDp][3],dipTag);
	}
    }

    //call setMany for each DIP config map
    dyn_string dip_cfgnames = mappingKeys(dip_configs);
    for (int i=1;i<=dynlen(dip_cfgnames);i++) {
	string name = dip_cfgnames[i];
	//DebugTN("call fwDIP_subscribeMany! " + name + " " + dynlen(dip_configs[name][1]) + " " + dynlen(dip_configs[name][2]) + " " + dynlen(dip_configs[name][3]));
	fwDIP_subscribeMany(dip_configs[name][1], name, dip_configs[name][2], dip_configs[name][3],exceptionInfo,TRUE);
	//DebugTN("end of call fwDIP_subscribeMany");
    }

    for(i = 1; i <= length; i++)
    {
	//skip any non-DIP address
	if (configParameters[i][fwPeriphAddress_TYPE]==fwPeriphAddress_TYPE_DIP) continue;
	//always use dpSet except for the last item with wait setting
	if (i<length)
	    _setWait=false;
	else
	    _setWait=setWait;
	fwPeriphAddress_set(dpes[i], configParameters[i], exceptionInfo, false, _setWait);
    }
}

//@}


/** @name Other Functions
 */
//@{
/**
Add an address config for an OPC Item

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element
@param opcServerName		data point name of the OPC Server wihtout system name and "_"
@param driverNum				driver number
@param OPCItemName			opc item name
@param OPCGroup					opc group name
@param datatype					translation datatype for address (0 gives automatic translation)
@param mode							DPATTR_ADDR_MODE_INPUT_SPONT: spontaneous input
												DPATTR_ADDR_MODE_INPUT_SPONT+64: spontaneous input and old/new comparison
												DPATTR_ADDR_MODE_OUTPUT_SINGLE: output
												DPATTR_ADDR_MODE_OUTPUT_SINGLE+64: output and old/new comparison
@param subindex					used where datatype is set to 'bitstring'.  Subindex gives the position of the desired bit.
@param exceptionInfo		details of any errors are returned here
@param setWait		determines if dpSetWait or dpSet should be used
*/
fwPeriphAddress_setOPC(	string dpe, string opcServerName, int driverNum, string OPCItemName, string OPCGroup,
						int datatype, int mode, unsigned subindex, dyn_string &exceptionInfo, bool setWait = TRUE)
{
	int dataType;
	string ref, systemName, errorText, opc, group;
	dyn_errClass err;

	fwGeneral_getSystemName(dpe, systemName, exceptionInfo);

	// OPC server
	opc = systemName + "_" + opcServerName;
	if(!dpExists(opc))
	{
		errorText = "fwPeriphAddress_setOPC(): OPC Server: " + opcServerName + " not existing";
		fwException_raise(exceptionInfo, "ERROR", errorText, "");
		return;
	}

	// OPC group
	group = systemName + "_" + OPCGroup;
	if (!dpExists(group))
	{
		errorText = "fwPeriphAddress_setOPC(): OPC group " + OPCGroup + " not existing";
		fwException_raise(exceptionInfo, "ERROR", errorText, "");
		return;
	}

	ref = opcServerName + "$" + OPCGroup + "$" + OPCItemName;

	switch(mode)
	{
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
		case DPATTR_ADDR_MODE_INPUT_SPONT:
		case DPATTR_ADDR_MODE_INPUT_SPONT + 64:
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE + 64:
		case 6: //in/out
		case 6 + 64:
		    if (setWait)
			dpSetWait( dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
				   dpe + ":_distrib.._driver", driverNum);
		    else
			dpSet( dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
			       dpe + ":_distrib.._driver", driverNum);

			err = getLastError();
			if(dynlen(err) > 0)
			{
				throwError(err);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setOPC(): Error while creating the address config", "");
			}

			//fwPeriphAddress_getDataType(dataType, dpe, "OPC");
			//DebugN(dataType);

			switch(datatype)
			{
				//for most recognised data types, make sure subindex is set to 0
				case 480:
				case 481:
				case 482:
				case 483:
				case 484:
				case 485:
				case 486:
				case 487:
				case 488:
				case 489:
				case 490:
					subindex = 0;
					break;
				//if bitstring do nothing
				case 491:
					break;
				//if unknown or invalid use 0 (default)
				default:
					subindex = 0;
					datatype = 0;
					break;
		    }

		    if (setWait)
			dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				  dpe + ":_address.._reference", ref,
				  dpe + ":_address.._datatype", datatype,
				  dpe + ":_address.._mode", mode,
				  dpe + ":_address.._subindex", subindex,
				  dpe + ":_address.._drv_ident", "OPCCLIENT");
		    else
			dpSet(	dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				dpe + ":_address.._reference", ref,
				dpe + ":_address.._datatype", datatype,
				dpe + ":_address.._mode", mode,
				dpe + ":_address.._subindex", subindex,
				dpe + ":_address.._drv_ident", "OPCCLIENT");

			err = getLastError();
			if(dynlen(err) > 0)
			{
				throwError(err);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setOPC(): Error while configuring the peripheral address", "");
			}
			break;
		default:
			errorText = "fwPeriphAddress_setOPC(): the selected mode " + mode + " is unknown";
			fwException_raise(exceptionInfo, "ERROR", errorText, "");
			return;
	}
}


/**
Add an address config for an OPC UA Item.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							      data point element
@param opcServerName		 data point name of the OPC Server wihtout system name and "_"
@param driverNum				   driver number
@param opcItemName			  opc item name
@param opcSubscription	opc subscription name
@param opcKind					    opc kind
@param opcVariant					 opc variant
@param datatype					   translation datatype for address (0 gives automatic translation).
                       See WinCC OA help on _address for a list of data type translations
@param mode							     DPATTR_ADDR_MODE_INPUT_SPONT: spontaneous input
      												     DPATTR_ADDR_MODE_INPUT_SPONT+64: spontaneous input and old/new comparison
      												     DPATTR_ADDR_MODE_OUTPUT_SINGLE: output
      												     DPATTR_ADDR_MODE_OUTPUT_SINGLE+64: output and old/new comparison
                       DPATTR_ADDR_MODE_IO_POLL: in/out with polling mode
      		               DPATTR_ADDR_MODE_IO_SQUERY: in/out with  single query
      		               DPATTR_ADDR_MODE_INPUT_POLL: input with polling mode
      		               DPATTR_ADDR_MODE_INPUT_SQUERY: input with  single query
@param pollGroup					  polling group name (used only if no subscription name is specified)
@param exceptionInfo		 details of any errors are returned here
@param setWait		determines if dpSetWait or dpSet should be used
*/
fwPeriphAddress_setOPCUA(	string dpe,
							string opcServerName,
							int driverNum,
							string opcItemName,
							string opcSubscription,
							string opcKind,
							string opcVariant,
							int datatype,
							int mode,
							string pollGroup,
							dyn_string &exceptionInfo,
							bool setWait = TRUE) {
 DebugFTN("FW_INFO", "fwPeriphAddress_setOPCUA(" + dpe + "):" + __LINE__);
	string ref, systemName, errorText, opc, group;
	dyn_errClass err;

	fwGeneral_getSystemName(dpe, systemName, exceptionInfo);
  if( systemName == "" )
  {
    // DPE in local project
    systemName = getSystemName();
  }

	if(strlen(pollGroup) && strpos(pollGroup, "_") != 0 && systemName != dpSubStr(pollGroup, DPSUB_SYS))	{
		pollGroup = "_" + pollGroup;
	}

 DebugFTN("FW_INFO", "fwPeriphAddress_setOPCUA:pollGroup = " + pollGroup, systemName, dpSubStr(pollGroup, DPSUB_SYS));

	// OPC server
	opc = "_" + opcServerName;
	if(!dpExists(opc)) {
  DebugFTN("FW_INFO", "opc " + opc + " does not exist " + __LINE__);
		errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - OPC UA Server: " + opcServerName + " not existing";
		fwException_raise(exceptionInfo, "ERROR", errorText, "");
		return;
	}
	// OPC subscription
	if(strlen(opcSubscription) > 0) {
		group = systemName + "_" + opcSubscription;
		if (!dpExists(group)) {
   DebugFTN("FW_INFO", "group " + group + " does not exist " + __LINE__);
			errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - OPC UA subscription " + opcSubscription + " not existing";
			fwException_raise(exceptionInfo, "ERROR", errorText, "");
			return;
		}
		// OPC kind
		if(strlen(opcKind) == 0) {
    DebugFTN("FW_INFO", "opcKind " + opcKind + " does not exist " + __LINE__);
			errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - OPC UA kind must be specified";
			fwException_raise(exceptionInfo, "ERROR", errorText, "");
			return;
		}
	} else if (mode == DPATTR_ADDR_MODE_INPUT_POLL || mode == DPATTR_ADDR_MODE_IO_POLL ||
			 mode == DPATTR_ADDR_MODE_INPUT_POLL + 64 || mode == DPATTR_ADDR_MODE_IO_POLL + 64) {
    // polling group
  		if(strlen(pollGroup) == 0) {
     DebugFTN("FW_INFO", "pollGroup " + pollGroup + " emtpy " + __LINE__);
  			errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - OPC UA with no subscription must have a polling group defined";
  			fwException_raise(exceptionInfo, "ERROR", errorText, "");
  			return;
  		} else	{
  			if (!dpExists(pollGroup) && strpos(pollGroup, "_") != 0) {
  				pollGroup = "_" + pollGroup;
  			}
  			if (!dpExists(pollGroup)) {
      DebugFTN("FW_INFO", pollGroup + " does not exist " + __LINE__);
  				errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - polling group " + pollGroup + " not existing";
  				fwException_raise(exceptionInfo, "ERROR", errorText, "");
  				return;
  			}
  		}
	}
 DebugFTN("FW_INFO", "fwPeriphAddress_setOPCUA(" + dpe + ") before switch(" + datatype + ")");
 switch(datatype) {
     case 750://default
  			case 751://boolean
  			case 752://sbyte
  			case 753://byte
  			case 754://int16
  			case 755://uint16
  			case 756://int32
  			case 757://uint32
  			case 758://int64
  			case 759://uint64
  			case 760://float
  			case 761://double
  			case 762://string
  			case 763://date time
  			case 764://guid
  			case 765://byte string
  			case 766://xml element
  			case 767://node id
  			case 768://localized text
       //all OK
  				break;
     default: //unknown, so use default
  				datatype = 750;
 }
	ref = opcServerName + "$" + opcSubscription + "$" + opcKind + "$" + opcVariant + "$" + opcItemName;
 DebugFTN("FW_INFO","fwPeriphAddress.ctl:after switch: ref = ", ref);
 DebugFTN("FW_INFO","fwPeriphAddress.ctl:switch(" + mode + ")");
	switch(mode) {
		case DPATTR_ADDR_MODE_IO_SPONT:
		case DPATTR_ADDR_MODE_IO_POLL:
		case DPATTR_ADDR_MODE_IO_POLL + 64: //+lowlevel
		case DPATTR_ADDR_MODE_IO_SQUERY:
		case DPATTR_ADDR_MODE_INPUT_POLL:
		case DPATTR_ADDR_MODE_INPUT_POLL + 64: //+lowlevel
		case DPATTR_ADDR_MODE_INPUT_SQUERY:
		case DPATTR_ADDR_MODE_INPUT_SPONT:
		case DPATTR_ADDR_MODE_INPUT_SPONT + 64: //+lowlevel
		case DPATTR_ADDR_MODE_OUTPUT:
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE + 64: //+lowlevel
		case 9: //DPATTR_ADDR_MODE_AM_ALERT
		case 6: //in/out
		case 6 + 64: //+lowlevel
			if (setWait)
			    dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
				      dpe + ":_distrib.._driver", driverNum);
			else
			    dpSet(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
				  dpe + ":_distrib.._driver", driverNum);
			err = getLastError();
			if(dynlen(err) > 0) {
				throwError(err);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - Error while creating the address config", "");
			}

   DebugFTN("FW_INFO", "fwPeriphAddress_setOPCUA::setting address for " + dpe);
			if (setWait)
			    dpSetWait(		dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						dpe + ":_address.._reference", ref,
						dpe + ":_address.._datatype", datatype,
						dpe + ":_address.._mode", mode,
						dpe + ":_address.._drv_ident", fwPeriphAddress_TYPE_OPCUA);
			else
			    dpSet(		dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						dpe + ":_address.._reference", ref,
						dpe + ":_address.._datatype", datatype,
						dpe + ":_address.._mode", mode,
						dpe + ":_address.._drv_ident", fwPeriphAddress_TYPE_OPCUA);


   if (strlen(pollGroup) != 0) {
     DebugFTN("FW_INFO", "setting pollGroup to " + pollGroup);
     if (setWait)
        dpSetWait(dpe + ":_address.._poll_group", pollGroup);
     else
        dpSet(dpe + ":_address.._poll_group", pollGroup);
   }

			err = getLastError();
			if(dynlen(err) > 0) {
    DebugFTN("FW_INFO", "error setting address", err);
				throwError(err);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - Error while configuring the peripheral address:\n " + err, "");
			}
			break;
		default:
			errorText = "fwPeriphAddress_setOPCUA(): problem on dpe " + dpe + " - the selected mode " + mode + " is unknown";
			fwException_raise(exceptionInfo, "ERROR", errorText, "");
			return;
	}
}

/**
Deletes the address config of the given dp elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	int i, length, iDipConfigCount, dpeCount;
	dyn_bool dbIsConfigured, dbIsActive, dbIsAccessible;
	dyn_dyn_anytype ddaConfigData;
	dyn_string localException;

	length = dynlen(dpes);
	//check if all dpes addresses are configured as DIP
	fwPeriphAddress_getMany(dpes, dbIsConfigured, ddaConfigData, dbIsActive, localException);
	for(i = 1 ; i <= length ; i++)
	{
		if(ddaConfigData[i][fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIP)
		{
			iDipConfigCount++;
		}
	}
	if(iDipConfigCount == length)
	{
		//DebugN("fwPeriphAddress_deleteMultiple - all DIP!");
		_fwPeriphAddress_deleteDIPMultiple(dpes, exceptionInfo);
	}
	else //for any other type of dpe
	{
		for(i = 1; i <= length; i++)
		{
			fwPeriphAddress_delete(dpes[i], exceptionInfo);
		}
	}
}


/**
Deletes the address config of the given dp element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_delete(string dpe, dyn_string &exceptionInfo)
{
	bool isConfigured, isActive, isAccessible;
	int res, addr, dist, result = 1;
	string configDp, addressType;
	dyn_int requiredDrivers;
	dyn_anytype configData;
	dyn_errClass err;
	dyn_string localException, configTypeData;
	string errorText, errorString;

	fwPeriphAddress_get(dpe, isConfigured, configData, isActive, localException);
	//if address type was read but some other error occured, continue
	if(dynlen(localException) > 0)
	{
		if(configData[fwPeriphAddress_TYPE] != "")
		{
			dynClear(localException);
		}
		else
		{
			//else return with the exception that was returned
			dynAppend(exceptionInfo, localException);
			return;
		}
	}

	if(!isConfigured)
	{
		return;
	}

	if(configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIP)
	{
	    if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
			fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_delete(): Can not delete the DIP config.  The DIP framework component is not installed.", "");
			return;
		}
	}

	configTypeData = strsplit(configData[fwPeriphAddress_TYPE], "/");
	if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_delete"))
	{
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_delete");
		res = evalScript(exceptionInfo, "dyn_string main(string dpe, dyn_string exInfo)"
						 + "{ "
						 + " _fwPeriphAddress" + configTypeData[1] + "_delete(dpe, exInfo);"
						 + " return exInfo;"
						 + "}", makeDynString(), dpe, exceptionInfo);
//DebugN(exceptionInfo);
	}

	dpSetWait( dpe + ":_distrib.._type", DPCONFIG_NONE);
	err = getLastError();
	if(dynlen(err) > 0)
	{
		throwError(err);
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_delete(): Error while deleting the address config", "");
		return;
	}

	if((configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIM) || (configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIMCLIENT))
	{
		//temporary code
		_fwDim_unSetDpConfig(dpe);
		//end of temporary code

		dpe = dpSubStr(dpe, DPSUB_DP_EL);
		if(configData[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
		{
			fwDim_unSubscribeCommandsByDp(configData[fwPeriphAddress_DIM_CONFIG_DP], dpe, 1);
		}
		else
		{
			fwDim_unSubscribeServicesByDp(configData[fwPeriphAddress_DIM_CONFIG_DP], dpe, 1);
		}
	}

	if(configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIP)
	{
		_fwDIP_removeSubscription(makeDynString(dpe), exceptionInfo);
	}
}


/**
Deletes the DIP address config of the given dp elements

@par Constraints
	all dpes passed must have a periphery address of type DIP

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
_fwPeriphAddress_deleteDIPMultiple(dyn_string dpe, dyn_string &exceptionInfo)
{
	int result = 1;
	dyn_dyn_anytype configData;
	dyn_errClass err;
	dyn_int diConfigNone;
	int i;

	if(dynlen(dpe) < 1)
	{
		return;
	}

	if (dynlen(dpTypes("_FwDipConfig"))<1) { // checking of type is much faster than check of component installation - no dpGet there
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_delete(): Can not delete the DIP config.  The DIP framework component is not installed.", "");
		return;
	}

	for(i = 1 ; i <= dynlen(dpe) ; i++)
	{
		dpe[i] = dpe[i] + ":_distrib.._type";
		diConfigNone[i] = DPCONFIG_NONE;
	}

	dpSetWait( dpe, diConfigNone);
	err = getLastError();
	if(dynlen(err) > 0)
	{
		throwError(err);
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_deleteDIPMultiple(): Error while deleting some address config", "");
		fwException_raise(exceptionInfo, "INFO", "fwPeriphAddress_deleteDIPMultiple(): Now trying again in order to identify the dpe originating the error...", "");
		//re-do the dpSet one by one, to check which dpe is the guilty one
		for(i = 1 ; i <= dynlen(dpe) ; i++)
		{
			dpSetWait( dpe[i], diConfigNone[i]);
			err = getLastError();
			if(dynlen(err) > 0)
			{
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_deleteDIPMultiple(): Error while deleting the address config for " + dpe[i], "");
				//remove the dpe from the list, because it cannot be passed to _fwDIP_removeSubscription()
				dynRemove(dpe, i);
				dynRemove(diConfigNone, i);
				i--;
			}
		}
	}

	_fwDIP_removeSubscription(dpe, exceptionInfo);

}




/**
This function is used to read the address configuration parameters that
can be entered in the panels fwPeriphAddressDIM.pnl and fwPeriphAddressOPC.pnl.
It can be extended to support other address formats.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param referencePanel		the name of the reference panel to read from
@param addressParam			the address parameterization that was entered in the panel
@param exceptionInfo		details of any exceptions are returned here
*/
fwPeriphAddress_readSettings(string referencePanel, dyn_string &addressParam, dyn_string &exceptionInfo)
{
	bool timeStamp, updateOnConnect;
	int driverNumber, timeInterval;
	string addressType, name, server, inGroup, outGroup, defaultValue, dimConfigDp;

	getValue(referencePanel + ".addressType", "text", addressType);

	// Common parameters
	getValue(referencePanel + ".name", "text", name);

	if(strpos(name, " ") >= 0)
	{
		fwException_raise(	exceptionInfo,
							"ERROR",
							"fwPeriphAddress_readSettings(): The name can not contain the ' ' character",
							"");
		return;
	}

	/*if(name == "")
	{
		fwException_raise(	exceptionInfo,
							"ERROR",
							"fwPeriphAddress_readSettings(): The name can not be empty",
							"");
		return;
	}*/

	// Parameters specific to an address type
	switch(strtoupper(addressType))
	{
		case "OPC":
			getValue(referencePanel + ".driverNumber", "text", driverNumber);
			getValue(referencePanel + ".server", "text", server);
			getValue(referencePanel + ".inGroup", "text", inGroup);
			getValue(referencePanel + ".outGroup", "text", outGroup);

			addressParam[fwDevice_ADDRESS_TYPE]		= fwPeriphAddress_TYPE_OPC;
			addressParam[fwDevice_ADDRESS_DRIVER_NUMBER]	= driverNumber;
			addressParam[fwDevice_ADDRESS_ROOT_NAME]	= name;
			addressParam[fwDevice_ADDRESS_OPC_SERVER_NAME]	= server;
			addressParam[fwDevice_ADDRESS_OPC_GROUP_IN]	= inGroup;
			addressParam[fwDevice_ADDRESS_OPC_GROUP_OUT]	= outGroup;
			break;
		case "DIM":

			getValue(referencePanel + ".tStamp", "state", 0, timeStamp);
			getValue(referencePanel + ".dimUpdate", "state", 0, updateOnConnect);
			getValue(referencePanel + ".dimDefaultValue", "text", defaultValue);
			getValue(referencePanel + ".dimUpdateInterval", "text", timeInterval);
			getValue(referencePanel + ".dimConfigDpList", "text", dimConfigDp);

			addressParam[fwDevice_ADDRESS_TYPE]			= fwPeriphAddress_TYPE_DIM;
			addressParam[fwPeriphAddress_DIM_CONFIG_DP] 		= dimConfigDp;
			addressParam[fwPeriphAddress_DIM_DEFAULT_VALUE] 	= defaultValue;
			addressParam[fwPeriphAddress_DIM_TIMEOUT] 		= timeInterval;
			addressParam[fwPeriphAddress_DIM_FLAG] 			= (int)timeStamp;
			addressParam[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] 	= (int)updateOnConnect;
			addressParam[fwDevice_ADDRESS_ROOT_NAME] 		= name;
			addressParam[fwDevice_ADDRESS_DRIVER_NUMBER] 		= fwPeriphAddress_DIM_DRIVER_NUMBER;
			break;
		default:
			fwException_raise(	exceptionInfo,
								"ERROR",
								"fwPeriphAddress_readSettings(): " + addressType + " is not a supported address type.",
								"");
			break;
	}
}


/**
Set IEC address

@par Constraints
	In this function, we suppose that variable dsParameters is well formatted.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						datapoint element whose address have to be set
@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error...
@param setWait		determines if dpSetWait or dpSet should be used
*/
fwPeriphAddress_setIEC(string dpe, dyn_string dsParameters, dyn_string& exceptionInfo, bool setWait=true)
{
	int driverNum, addressSubindex, dataType;
	bool active;
	string addressReference, systemName;
	int dir;
	int iRes;
	bool failed = false;
	dyn_errClass error;

	// 1. Get input data
	driverNum = (int)dsParameters[FW_PARAMETER_FIELD_DRIVER];
	addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
	dir = (int)dsParameters[FW_PARAMETER_FIELD_MODE];
	dataType = (int)dsParameters[FW_PARAMETER_FIELD_DATATYPE];
	active = (bool)dsParameters[FW_PARAMETER_FIELD_ACTIVE];
	addressSubindex = (int)dsParameters[FW_PARAMETER_FIELD_SUBINDEX];

	// 2. Set _address config
	if (setWait)
	    iRes = dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
			   dpe + ":_distrib.._driver", driverNum);
	else
	    iRes = dpSet(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
			   dpe + ":_distrib.._driver", driverNum);

	if (iRes >= 0)
	{
		iRes = -1;
		if (setWait)
		    iRes = dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference,
						 dpe + ":_address.._datatype", dataType,
						 dpe + ":_address.._drv_ident", "IEC",
						 dpe + ":_address.._subindex", addressSubindex,
						 dpe + ":_address.._direction", dir
						);
		else
		    iRes = dpSet(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference,
						 dpe + ":_address.._datatype", dataType,
						 dpe + ":_address.._drv_ident", "IEC",
						 dpe + ":_address.._subindex", addressSubindex,
						 dpe + ":_address.._direction", dir
						);
		error = getLastError();
		if (iRes < 0)
		{
			if (dynlen(error) > 0)
			{
				throwError(error);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setIEC: invalid address", "");
			}
		}
		else
		{
			if (dynlen(error) > 0)
			{
				throwError(error);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setIEC: invalid address", "");
			}
			else
			{
				iRes = -1;
				if (setWait)
				    iRes = dpSetWait(dpe + ":_address.._active", active);
				else
				    iRes = dpSet(dpe + ":_address.._active", active);
				if (iRes < 0)
				{
					failed = true;
				}
			}
		}
	}
	else
	{
		failed = true;
	}

	if (failed)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setIEC: cant set IEC address", "");
	}
}

/**
Set MODBUS address
@par Constraints
	. In this function, we suppose that variable dsParameters is well formatted. Before calling this function, it is recommended to
		check the parameters using the fwPeriphAddress_checkModbusParameters function.
	. In the parameters, the field addressReference could be obtain using fwPeriphAddress_getUnicosAddressReference

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						datapoint element whose address have to be set
@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error...
@param setWait		determines if dpSetWait or dpSet should be used
*/
fwPeriphAddress_setModbus(string dpe, dyn_string dsParameters, dyn_string& exceptionInfo, bool setWait=true)
{
	int driverNum, addressSubindex, mode, intervalTime, dataType;
	bool active, lowLevel;
	string addressReference, systemName, pollGroup;
	time startingTime;
	int dir;
	int iRes;
	bool failed = false;
	dyn_errClass error;

	// 1. Get input data
	driverNum = (int)dsParameters[FW_PARAMETER_FIELD_DRIVER];
	addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
	addressSubindex = (int)dsParameters[FW_PARAMETER_FIELD_SUBINDEX];
	mode = (int)dsParameters[FW_PARAMETER_FIELD_MODE];
	startingTime = dsParameters[FW_PARAMETER_FIELD_START];
	intervalTime = (int)dsParameters[FW_PARAMETER_FIELD_INTERVAL];
	dataType = (int)dsParameters[FW_PARAMETER_FIELD_DATATYPE];
	active = (bool)dsParameters[FW_PARAMETER_FIELD_ACTIVE];
	lowLevel = (bool)dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
	pollGroup=dsParameters[fwPeriphAddress_MODBUS_POLL_GROUP];

	fwGeneral_getSystemName(dpe, systemName, exceptionInfo);
	// 2. Set direction and mode and pre-process the poll group info

	dir = mode;

	// make sure that we refer to the poll group on the system for the configured DPE (ENS-14529,ENS-15685,FWCORE-3213)
	if (strpos(pollGroup,":") > 0 ) {
	    // we need to strip the system name
	    dyn_string ds=strsplit(pollGroup,":");
	    // fix FWCORE-3283, ie. when pollGroup has only system name and nothing later
	    if (dynlen(ds)==2) {
		pollGroup=ds[2];
	    } else {
		DebugTN("WARNING:",__FUNCTION__,"Suspicious poll group",pollGroup,"for DPE",dpe,"Resetting to empty.");
		pollGroup="";
	    }
	}

	// allow the case of pollGroup given without the "_" prefix...
	if(strlen(pollGroup) && pollGroup[0]!='_') pollGroup = "_" + pollGroup;

	if(dir == DPATTR_ADDR_MODE_INPUT_POLL) {
	    pollGroup = systemName + pollGroup;
	    if(!dpExists(pollGroup)) {
		fwException_raise(exceptionInfo, "ERROR", "Polling group does not exist " + pollGroup, "");
		return;
	    }
	}

	if (lowLevel)
	{
		mode = mode + PVSS_ADDRESS_LOWLEVEL_TO_MODE;
	}

	// 3. Set _address config
	if (setWait)
	    iRes = dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
					 dpe + ":_distrib.._driver", driverNum);
	else
	    iRes = dpSet(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
					 dpe + ":_distrib.._driver", driverNum);

	if (iRes >= 0)
	{
		iRes = -1;
		if (setWait)
		    iRes = dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference,
						 dpe + ":_address.._subindex", addressSubindex,
						 dpe + ":_address.._mode", mode,
						 dpe + ":_address.._start", startingTime,
						 dpe + ":_address.._interval", intervalTime / 1000.0,
						 dpe + ":_address.._datatype", dataType,
						 dpe + ":_address.._drv_ident", "MODBUS",
						 dpe + ":_address.._direction", dir,
						 dpe + ":_address.._internal", false,
						 dpe + ":_address.._lowlevel", lowLevel,
						 dpe + ":_address.._poll_group", pollGroup);
		else
		    iRes = dpSet(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference,
						 dpe + ":_address.._subindex", addressSubindex,
						 dpe + ":_address.._mode", mode,
						 dpe + ":_address.._start", startingTime,
						 dpe + ":_address.._interval", intervalTime / 1000.0,
						 dpe + ":_address.._datatype", dataType,
						 dpe + ":_address.._drv_ident", "MODBUS",
						 dpe + ":_address.._direction", dir,
						 dpe + ":_address.._internal", false,
						 dpe + ":_address.._lowlevel", lowLevel,
						 dpe + ":_address.._poll_group", pollGroup);
		error = getLastError();
		if (iRes < 0)
		{
			if (dynlen(error) > 0)
			{
				throwError(error);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress", "DUPLICATEDADDRESS"), "");
			}
		}
		else
		{
			if (dynlen(error) > 0)
			{
				throwError(error);
				fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress", "DUPLICATEDADDRESS"), "");
			}
			else
			{
				iRes = -1;
				if (setWait)
				    iRes = dpSetWait(dpe + ":_address.._active", active);
				else
				    iRes = dpSet(dpe + ":_address.._active", active);
				if (iRes < 0)
				{
					failed = true;
				}
			}
		}
	}
	else
	{
		failed = true;
	}

	if (failed)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress", "ERRORSETTINGMODBUS"), "");
	}
}




/**
Checks to see if a given driver manager is running or not

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumber		the number of the driver to check
@param isRunning			Driver state is returned here - TRUE if manager is running, else FALSE
@param exceptionInfo	if the driver is not running, an exception is returned
@param systemName			OPTIONAL PARAMETER: System name on which to check if the driver is running (e.g. dist_1:).
																					If not passed, the local system is checked.
*/
fwPeriphAddress_checkIsDriverRunning(int driverNumber, bool &isRunning, dyn_string &exceptionInfo, string systemName = "LOCAL")
{

	if (systemName=="LOCAL") systemName=""; // parameter compatibility
	isRunning = fwManager_checkDriverRunning(driverNumber,exceptionInfo,systemName);
}


/**
Checks to see if a given list of driver managers are running or not

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumbers	the numbers of the drivers to check
@param areRunning			A list of the driver states is returned here - TRUE if manager is running, else FALSE
@param exceptionInfo	if the driver is not running, an exception is returned
@param systemName			OPTIONAL PARAMETER: System name on which to check if the drivers are running (e.g. dist_1:).
																					If not passed, the local system is checked.
*/
fwPeriphAddress_checkAreDriversRunning(dyn_int driverNumbers, dyn_bool &areRunning, dyn_string &exceptionInfo, string systemName = "LOCAL")
{
	int i, length;
// 	dyn_int manNums, badNums;
// 	string errorString;

	if (systemName=="LOCAL") systemName=""; // parameter compatibility


	for(i = 1 ; i <= dynlen(driverNumbers) ; i++)
	{
		areRunning[i] = fwManager_checkDriverRunning(driverNumbers[i], exceptionInfo, systemName);
	}

}


/**
Creates the necessary PVSS internal data for a given driver number.
These are "_DriverX" and "_Stat_Configs_driver_X" where X is the driver number.

@par Constraints
	The driver number must be between 1 and 254 (PVSS limitation on driver numbers)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumber	The driver number for which you wish to create the internal PVSS dps
@param exceptionInfo	Details of any exceptions are returned here

@reviewed 2018-08-01 @whitelisted{FalsePositive}

*/
fwPeriphAddress_createPvssInternalDpsForDriver(unsigned driverNumber, dyn_string &exceptionInfo)
{
	string driverCommonDp, driverCommonDp2, driverStatsDp, driverStatsDp2;

	if((driverNumber >= 255) || (driverNumber < 1))
	{
		fwException_raise(exceptionInfo, "ERROR", "The driver number must be between 1 and 254.", "");
		return;
	}

	driverCommonDp = "_Driver" + driverNumber;
	driverStatsDp = "_Stat_Configs_driver_" + driverNumber;
	driverCommonDp2 = "_Driver" + driverNumber + "_2";
	driverStatsDp2 = "_Stat_2_Configs_driver_" + driverNumber;

	if(!dpExists(driverCommonDp))
	{
		dpCreate(driverCommonDp, "_DriverCommon");
	}
	else if(dpTypeName(driverCommonDp) != "_DriverCommon")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
						  + driverCommonDp + "\" exists already but is of the wrong data point type", "");

	if(!dpExists(driverCommonDp2))
	{
		dpCreate(driverCommonDp2, "_DriverCommon");
	}
	else if(dpTypeName(driverCommonDp2) != "_DriverCommon")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
						  + driverCommonDp2 + "\" exists already but is of the wrong data point type", "");

	if(!dpExists(driverStatsDp))
	{
		dpCreate(driverStatsDp, "_Statistics_DriverConfigs");
	}
	else if(dpTypeName(driverStatsDp) != "_Statistics_DriverConfigs")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
						  + driverStatsDp + "\" exists already but is of the wrong data point type", "");
	if(!dpExists(driverStatsDp2))
	{
		dpCreate(driverStatsDp2, "_Statistics_DriverConfigs");
	}
	else if(dpTypeName(driverStatsDp2) != "_Statistics_DriverConfigs")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
						  + driverStatsDp2 + "\" exists already but is of the wrong data point type", "");
}

/**
Changes the OPC group in the address config for the given list of dpes

@par Constraints
	The relevant SIM Manager or Driver must be running to access the address configs

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			The list of dpes to act on
@param newGroupName	The new OPC server group name
@param exceptionInfo	Details of any exceptions are returned here

@reviewed 2018-08-01 @whitelisted{FalsePositive}

*/
fwPeriphAddress_changeOpcGroups(dyn_string dpes, string newGroupName, dyn_string &exceptionInfo)
{
	int i, j, numberOfTypes, numberOfDpes;
	dyn_string references, driverTypes, referenceParts, newReference, localExceptionInfo;

	//get the driver types of all the dpes
	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, driverTypes, localExceptionInfo, ".._drv_ident");
    if (dynlen(localExceptionInfo)) {
		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_changeOpcGroups: Could not get some of the attributes. Function aborted.", "");
        dynAppend(exceptionInfo,localExceptionInfo);
		return;
	}


	//if not all OPCCLIENT then give exception
	//also if some addresses do not exist, driverTypes is empty so also give exception
	numberOfTypes = dynUnique(driverTypes);
	if((numberOfTypes == 1) && (driverTypes[1] == fwPeriphAddress_TYPE_OPCCLIENT))
	{
		//read current OPC address references
		_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, references, localExceptionInfo, ".._reference");
        if (dynlen(localExceptionInfo)) {
	    	fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_changeOpcGroups: Could not get some of the attributes. Function aborted.", "");
            dynAppend(exceptionInfo,localExceptionInfo);
	    	return;
	    }
	}
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "Not all the data point elements have accessible OPC addresses. "
						  + "No change was made to the OPC groups.", "");
	}

	if(dynlen(exceptionInfo) > 0)
	{
		return;
	}

	//go through all references to changes OPC group
	numberOfDpes = dynlen(references);
	for(i = 1; i <= numberOfDpes; i++)
	{
		referenceParts = strsplit(references[i], "$");
		referenceParts[2] = newGroupName;

		newReference = "";
		for(j = 1; j < dynlen(referenceParts); j++)
		{
			newReference += referenceParts[j] + "$";
		}
		newReference += referenceParts[j];

		references[i] = newReference;
	}

	//save new OPC groups
	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, references, exceptionInfo, ".._reference");
}
//@}


