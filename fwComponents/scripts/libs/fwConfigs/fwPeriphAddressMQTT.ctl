/** @file This library contains function associated with MQTT addressing.

*/

#uses "mqttDrvPara.ctl"


const unsigned fwPeriphAddress_MQTT_LOWLEVEL 	= 11;
const unsigned fwPeriphAddress_MQTT_CONNECTION 	= 12;
const unsigned fwPeriphAddress_MQTT_QOS			= 13;
const unsigned fwPeriphAddress_MQTT_RETAIN		= 14;
const unsigned fwPeriphAddress_MQTT_ONUSE		= 15;
const unsigned fwPeriphAddress_MQTT_OBJECT_SIZE = 15;


const int fwPeriphAddress_MQTT_TYPE_PLAIN_STRING	= 1001;
const int fwPeriphAddress_MQTT_TYPE_JSON_VAL		= 1002;         // JSON Profile Value
const int fwPeriphAddress_MQTT_TYPE_JSON_VAL_TS		= 1003;      // JSON Profile Value/Timestamp
const int fwPeriphAddress_MQTT_TYPE_JSON_VAL_TS_STAT= 1004; // JSON Profile Value/Timestamp/Status

const unsigned fwPeriphAddress_MQTT_QOS_AT_MOST_ONCE	= 0;
const unsigned fwPeriphAddress_MQTT_QOS_AT_LEAST_ONCE	= 1;
const unsigned fwPeriphAddress_MQTT_QOS_EXACTLY_ONCE	= 2;

const unsigned fwPeriphAddress_MQTT_DIR_PUB		= 0;
const unsigned fwPeriphAddress_MQTT_DIR_SUB		= 1;
const unsigned fwPeriphAddress_MQTT_DIR_PUBSUB	= 2;

/** Set up a MQTT address

 @par dpe          : DP Element on which the address will be set

 @par adressConfig : data to configure the address; the following indices have specific meaning
      - [fwPeriphAddress_TYPE]   : address type, i.e. "MQTT"
      - [fwPeriphAddress_DRIVER_NUMBER] : driver number
      - [fwPeriphAddress_REFERENCE] : the name of the topic
      - [fwPeriphAddress_DIRECTION] : direction - one of
         - fwPeriphAddress_MQTT_DIR_PUB
         - fwPeriphAddress_MQTT_DIR_SUB
         - fwPeriphAddress_MQTT_DIR_PUBSUB
      - [fwPeriphAddress_DATATYPE] : data type/transformation - one of
         - fwPeriphAddress_MQTT_TYPE_PLAIN_STRING
         - fwPeriphAddress_MQTT_TYPE_JSON_VAL
         - fwPeriphAddress_MQTT_TYPE_JSON_VAL_TS
         - fwPeriphAddress_MQTT_TYPE_JSON_VAL_TS_STAT
      - [fwPeriphAddress_ACTIVE]          : whether the address is active
      - [fwPeriphAddress_MQTT_LOWLEVEL]   : enable/disable the low-level comparison
      - [fwPeriphAddress_MQTT_CONNECTION] : the name of MQTT connection that should already exist
      - [fwPeriphAddress_MQTT_QOS]        : Quality of Service - one of
         - fwPeriphAddress_MQTT_QOS_AT_MOST_ONCE
         - fwPeriphAddress_MQTT_QOS_AT_LEAST_ONCE
         - fwPeriphAddress_MQTT_QOS_EXACTLY_ONCE
      - [fwPeriphAddress_MQTT_RETAIN]     : Data retain bit
      - [fwPeriphAddress_MQTT_ONUSE]     : Poll data only if used (e.g. dpConnect'ed)

 @par exceptionInfo: standard exception-handling variable

 */
void _fwPeriphAddressMQTT_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
	if (dynlen(addressConfig)!= fwPeriphAddress_MQTT_OBJECT_SIZE) {
		fwException_raise(exceptionInfo, "ERROR",
			"_fwPeriphAddressMQTT_set(): wrong size of config structure ("+dynlen(addressConfig)+").", "");
		DebugTN(__FUNCTION__, "Invalid addressConfig structure (size!="+fwPeriphAddress_MQTT_OBJECT_SIZE+")",addressConfig);
		return;
	}

	string sConnectionDP ="_"+addressConfig[fwPeriphAddress_MQTT_CONNECTION];

	if (!dpExists(sConnectionDP)) {
		fwException_raise(exceptionInfo, "ERROR",
			"_fwPeriphAddressMQTT_set(): MQTT connection does not exist: "+addressConfig[fwPeriphAddress_MQTT_CONNECTION], "");
		return;
	}

	// create the address config and assing the driver number
	int driverNum = addressConfig[FW_PARAMETER_FIELD_DRIVER];
	dpSetWait(	dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
				dpe + ":_distrib.._driver", driverNum);
	dyn_errClass err = getLastError();
	if (dynlen(err)) {
		fwException_raise(exceptionInfo,"ERROR","Could not set driver number for the MQTT address:"+getErrorText(err),"");
		return;
	}

	// validate the topic (FWCORE-3571)
	string topic = addressConfig[fwPeriphAddress_REFERENCE];
	if (! fwPeriphAddressMQTT_checkTopic(topic, exceptionInfo)) return;

	int iOffset = 2 * (int)addressConfig[fwPeriphAddress_MQTT_QOS] + (int)addressConfig[fwPeriphAddress_MQTT_RETAIN];
	int iMode = paMqttDecodePanelToMode((int)addressConfig[fwPeriphAddress_MQTT_LOWLEVEL],
										(int)addressConfig[fwPeriphAddress_DIRECTION],
										(int)addressConfig[fwPeriphAddress_MQTT_ONUSE]);

	bool bActive = addressConfig[fwPeriphAddress_ACTIVE];

	int dataType=addressConfig[fwPeriphAddress_DATATYPE];
	if (dataType<=1000) dataType=fwPeriphAddress_MQTT_TYPE_PLAIN_STRING;

	dpSetWait(	dpe+":_address.._type", 		DPCONFIG_PERIPH_ADDR_MAIN,
				dpe+":_address.._drv_ident", 	fwPeriphAddress_TYPE_MQTT,
				dpe+":_address.._reference", 	topic,
				dpe+":_address.._mode", 		iMode,
				dpe+":_address.._datatype", 	dataType,
				dpe+":_address.._offset", 		iOffset,
				dpe+":_address.._active", 		false, // initially set to disabled; will enable (if needed) below
				dpe+":_address.._connection", 	sConnectionDP);
	err = getLastError();
	if (dynlen(err)) {
		fwException_raise(exceptionInfo,"ERROR","Could not configure MQTT address:"+getErrorText(err),"");
		return;
	}
	// now activate the address
	if (bActive) {
		dpSetWait(dpe+":_address.._active",bActive);
		if (dynlen(err)) {
			fwException_raise(exceptionInfo,"ERROR","Could not activate the MQTT address:"+getErrorText(err),"");
			return;
		}
	}
}


/** Get the parameters of MQTT address for a DP Element

	@param dpe	         : the DP Element for which address is retrieved
	@param addressConfig : on return will contain the configuration data; see @ref _fwPeriphAddressMQTT_set
	                        for more details
	@param isActive      : on return will be set to true if address is active, false if inactive
	@param exceptionInfo : standard exception-handling variable;
*/
void _fwPeriphAddressMQTT_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
	addressConfig = makeDynAnytype();
	anytype empty;
	addressConfig[fwPeriphAddress_MQTT_OBJECT_SIZE] = empty; // Force size on list (create it with a given size)

	int drvNumber, drvMode, dataType, offset, subIndex, lowLevel, onUse, direction;
	string connection, pollGroup;

	dpGet(	dpe + ":_distrib.._driver", 	drvNumber,
			dpe + ":_address.._drv_ident", 	addressConfig[fwPeriphAddress_TYPE],
			dpe + ":_address.._mode", 		drvMode,
			dpe + ":_address.._reference", 	addressConfig[fwPeriphAddress_REFERENCE],
			dpe + ":_address.._connection", connection,
			dpe + ":_address.._active", 	isActive,
			dpe + ":_address.._offset", 	offset,
			dpe + ":_address.._subindex", 	subIndex,
			dpe + ":_address.._datatype",	dataType,
			dpe + ":_address.._poll_group",	pollGroup // do we need it?
		);
	dyn_errClass err=getLastError();
	if (dynlen(err)) {
		fwException_raise(exceptionInfo,"ERROR","Could not get MQTT address data:"+getErrorText(err),"");
		return;
	}

	addressConfig[FW_PARAMETER_FIELD_ACTIVE] = isActive;
	addressConfig[fwPeriphAddress_DRIVER_NUMBER]=drvNumber;

	connection = dpSubStr(connection,DPSUB_DP);
	connection = strltrim(connection,"_");
	addressConfig[fwPeriphAddress_MQTT_CONNECTION] = connection;

	addressConfig[FW_PARAMETER_FIELD_DATATYPE] = dataType;

	int retain = offset & 1;
	int qos = (offset - retain) / 2;

	addressConfig[fwPeriphAddress_MQTT_RETAIN]=(bool)retain;
	addressConfig[fwPeriphAddress_MQTT_QOS]=qos;

	paMqttDecodeModeToPanel(drvMode, lowLevel, direction, onUse);
	addressConfig[fwPeriphAddress_DIRECTION]=direction;
	addressConfig[fwPeriphAddress_MQTT_LOWLEVEL]=(bool)lowLevel;
	addressConfig[fwPeriphAddress_MQTT_ONUSE]=(bool)onUse;
}


/** Create a new MQTT Connection

	@param conName       : the name for the new connection (will be the DP name for it)
	@param exceptionInfo : standard exception-handling variable
	@param config        : optional: allows to specify the initial configuration for the connection;
							if not specified, defaults will be set; see @ref fwPeriphAddressMQTT_setConnection
 */
void fwPeriphAddressMQTT_createConnection(string conName, dyn_string &exceptionInfo, mapping config=makeMapping())
{
	if (conName=="") {fwException_raise(exceptionInfo,"ERROR","Cannot create MQTT connection with empty name","");return;}

	dyn_string conDpNames=makeDynString("_"+conName);
	if (isRedundant()) dynAppend(conDpNames,"_"+conName+"_2");

	for (int i=0;i<conDpNames.count();i++) {

		string conDP=conDpNames.at(i);

		if (dpExists(conDP)) {fwException_raise(exceptionInfo,"ERROR","Could not create MQTT connection - DP already exists:"+conDP,"");return;}

		dpCreate(conDP, "_MqttConnection");
		dyn_errClass err=getLastError();
		if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Could not create MQTT connection:"+getErrorText(err),"");return;}

	}
	fwPeriphAddressMQTT_setConnection(conName, config, exceptionInfo);
}

/* Configure a MQTT connection

	@par conName : the name of the connection (connnection must already exist)

	@par config  : configuration data; the following keys should be used:
		- ["ConnectionType"]    : connection type [uint]
		- ["ConnectionString"]  : connection string [string]
		- ["Username"]          : user name [string]
		- ["Password"]          : encrypted password [blob]
		- ["Certificate"]       : certificate [string]
		- ["EstablishmentMode"] : 0 - inactive, 1-automatically active (default) [uint]
		- ["SetInvalidBit"]     : invalid bit set on connection loss [bool]
		- ["UseUTC"]            : 0 - local timezone, 1 - UTC is written (default) [bool]
		- ["DrvNumber"]         : driver number [uint]
		- ["CheckConn"]         : if address config shell be added to check connection (default:false) [bool]
		- ["EnableStatistics"]  : enable statistics in .State.Statistics.* (default:true) [bool]
		- ["Timezone"]          : offset in min added to timestamps when local time is used [int]
		- ["LastWillTopic"]     : topic to which the last message shall be sent on connection loss [string]
		- ["LastWillMessage"]   : last message sent on connection loss [string]
		- ["LastWillQoS"]       : Quality of Service for the last will message [uint]:
	                                 fwPeriphAddress_QOS_AT_MOST_ONCE
	                                 fwPeriphAddress_QOS_AT_LEAST_ONCE
	                                 fwPeriphAddress_QOS_EXACTLY_ONCE
		- ["LastWillRetain"]    : last msg in topic kept by borker and sent to new subscribers [bool]
		- ["PersistentSession"] : [bool], default true
		- ["LifebeatTimeout"]   : [uint], default 20
		- ["ReconnectTimeout"]  : [uint], default 20
		- ["IGQ"]               : Inverse General Query (IGQ) is triggered, meaning all the output addresses are written [bool]
		- ["Enabled"]           : Connection enable command [bool]
		- ["ClientId"]          : string

	@par exceptionInfo: standard exception-handling variable

	Note that a few configuration parameters are not implemented in this mapping and set to reasonable defaults
	(see the code for details).

	When called, the connection is enabled.
**/
void fwPeriphAddressMQTT_setConnection(string conName, mapping config, dyn_string &exceptionInfo)
{
	// NOTE:
	// as we possibly need to act on the connectionDP of this system as well as the REDU replica
	// we will use the conDpNames list, that would contain the list of _MqttConnection DPs
	// that correspond to what was passed in conName (for non-redundant it will be a single element!)

	dyn_string conDpNames=makeDynString("_"+conName);
	if ( isRedundant() ) dynAppend(conDpNames,"_"+conName+"_2");

	for (int i=0;i<conDpNames.count();i++) {
		string conDP=conDpNames.at(i);
		if (!dpExists(conDP)) {fwException_raise(exceptionInfo,"ERROR","MQTT connection DP does not exist:"+conDP,"");return;}
		if (dpTypeName(conDP)!="_MqttConnection") {fwException_raise(exceptionInfo,"ERROR","Cannot set MQTT connection - DP is of wrong type:"+conDP,"");return;}
	}

	mapping addrMap = makeMapping(
							"ConnectionType" ,  (uint)config.value("ConnectionType",2),
							"ConnectionString", config.value("ConnectionString",""),
							"Username",         config.value("Username",""),
							"Password",         config.value("Password",""),
							"Certificate",      config.value("Certificate",""));

	if (config.value("ClientId","")!="") addrMap["ClientId"] = config.value("ClientId","");
	string address = jsonEncode(addrMap,0);

	string reduAddress=address;
	if (!isRedundant()) {
		// reset it to empty...
		mapping reduAddrMap = makeMapping(
							"ConnectionType" ,  config.value("ConnectionType",2),
							"ConnectionString", "",
							"Username",         "",
							"Password",         "",
							"Certificate",      "");
    	reduAddress = jsonEncode(reduAddrMap,0);
	}

	// NOTE:
	// EstablishmentMode (the term used also by the configuration of other WinCC OA drivers)
	// determines if the connection should be established automatically (made active).
	// It defaults to 1 (ie. auto) which corresponds to the fact that we need to set the
	// ".Command.Enable" to 1 (activate the connection)

	// NOTE:
	// This code is to configure a connection, hence not called very frequently or in large batches.
	// For this reason we may afford optimizing dpSet/dpSetWaits, and follow what is done in the
	// para/mqtt.pnl , including the extra delays which we found there.

	for (int i=0;i<conDpNames.count();i++) { // iterate over the connection DP and its redu replica...
		string conDP=conDpNames.at(i);
		dpSetWait(	conDP + ".Config.EstablishmentMode",	(uint)   config.value("EstablishmentMode",	1		),
					conDP + ".Config.DrvNumber",			(uint)   config.value("DrvNumber",			1		),
					conDP + ".Config.SetInvalidBit",		(bool)   config.value("SetInvalidBit",		false	),
					conDP + ".Config.UseUTC",				(bool)   config.value("UseUTC",				true	),
					conDP + ".Config.Timezone",				(uint)   config.value("Timezone",			0		),
					conDP + ".Config.EnableStatistics",		(bool)   config.value("EnableStatistics",	false	),
					conDP + ".Config.LifebeatTimeout",		(uint)   config.value("LifebeatTimeout",	20		),
					conDP + ".Config.ReconnectTimeout",		(uint)   config.value("ReconnectTimeout",	20		),
					conDP + ".Config.PersistentSession",	(bool)   config.value("PersistentSession",	true	),
					conDP + ".Config.LastWill.Topic",		(string) config.value("LastWillTopic",		""		),
					conDP + ".Config.LastWill.Message",		(string) config.value("LastWillMessage",	""		),
					conDP + ".Config.LastWill.QoS",			(uint)   config.value("LastWillQoS",		0		),
					conDP + ".Config.LastWill.Retain",		(bool)   config.value("LastWillRetain",		false	),
					conDP + ".Config.Address",				(string) address,
					conDP + ".Config.ReduAddress",			(string) reduAddress
				);
		dyn_errClass err=getLastError();
		if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Could not configure MQTT connection: "+getErrorText(err),""); return;}
	}

	// if EstablishmentMode was set, enable the connection
	if (config.value("EstablishmentMode",1)==1){
		delay(0,100);
		fwPeriphAddressMQTT_enableConnection(conName, true, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
	}
}

/* Get configuration of MQTT Connection

	@param conName       : the name (DP) of the MQTT Connection
	@param exceptionInfo : standard exception-handling variable
	@return : the configuration in a mapping variable - see
	           @ref fwPeriphAddressMQTT_getConnection for more information

**/
mapping fwPeriphAddressMQTT_getConnection(string conName, dyn_string &exceptionInfo)
{
	mapping config;

	string conDP="_"+conName;

	if (!dpExists(conDP)) {fwException_raise(exceptionInfo,"ERROR","MQTT connection DP does not exist:"+conDP,"");return makeMapping();}
	if (dpTypeName(conDP)!="_MqttConnection") {fwException_raise(exceptionInfo,"ERROR","Cannot get MQTT connection - DP is of wrong type:"+conDP,"");return makeMapping();}

	string address;

	dpGet(	conDP + ".Config.Address"          , address,
			conDP + ".Config.EstablishmentMode", config["EstablishmentMode"],
			conDP + ".Config.SetInvalidBit"    , config["SetInvalidBit"],
			conDP + ".Config.UseUTC"           , config["UseUTC"],
			conDP + ".Config.CheckConn"        , config["CheckConn"],
			conDP + ".Config.EnableStatistics" , config["EnableStatistics"],
			conDP + ".Config.Timezone"         , config["Timezone"],
			conDP + ".Config.LastWill.Topic"   , config["LastWillTopic"],
			conDP + ".Config.LastWill.Message" , config["LastWillMessage"],
			conDP + ".Config.LastWill.QoS"     , config["LastWillQoS"],
			conDP + ".Config.LastWill.Retain"  , config["LastWillRetain"],
			conDP + ".Config.LifebeatTimeout"  , config["LifebeatTimeout"],
			conDP + ".Config.ReconnectTimeout" , config["ReconnectTimeout"],
			conDP + ".Config.PersistentSession", config["PersistentSession"],
			conDP + ".Config.DrvNumber"        , config["DrvNumber"]
		);
	dyn_errClass err=getLastError();
	if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Could not retrieve MQTT Connection:"+getErrorText(err),"");return makeMapping();}

	mapping addrMap=jsonDecode(address);
	err=getLastError();
	if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Error decoding the MQTT Connection configuration:"+getErrorText(err),"");return makeMapping();}

	// copy over to the config mapping
	dyn_mixed keys=mappingKeys(addrMap);

	for (int i=0;i<keys.count();i++) {
		mixed key=keys.at(i);
		config[key]=addrMap[key];
	}

	return config;
}

/** Deletes a MQTT Connection

	@param conName       : the name (DP) of the MQTT Connection to be deleted
	@param exceptionInfo : standard exception-handling variable

 */
void fwPeriphAddressMQTT_deleteConnection(string conName, dyn_string &exceptionInfo)
{
	dyn_string conDpNames=makeDynString("_"+conName);
	if ( isRedundant() ) dynAppend(conDpNames,"_"+conName+"_2");

	for (int i=0;i<conDpNames.count();i++) {
		string conDP=conDpNames.at(i);
		if (!dpExists(conDP)) {fwException_raise(exceptionInfo,"ERROR","Cannot delete MQTT connection - DP does not exist:"+conDP,"");return;}
		if (dpTypeName(conDP)!="_MqttConnection") {fwException_raise(exceptionInfo,"ERROR","Cannot delete MQTT connection - DP is of wrong type:"+conDP,"");return;}
	}

	// disable the connection first
	fwPeriphAddressMQTT_enableConnection(conName, false, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	delay(0,100);

	for (int i=0;i<conDpNames.count();i++) {
		dpDelete(conDpNames.at(i));
		dyn_errClass err=getLastError();
		if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Cannot delete MQTT Connection - "+getErrorText(err),"");return;}
	}
}

/** Returns the list of all MQTT Connections

*/
dyn_string fwPeriphAddressMQTT_getAllConnections()
{
	dyn_string dps=dpNames("*","_MqttConnection");
	dyn_string connections;
	for (int i=1;i<=dynlen(dps);i++) {
		string dp=dpSubStr(dps[i],DPSUB_DP);
		if (dp.endsWith("_2")) continue; // skip the DPs for REDU
		dynAppend(connections,strltrim(dp,"_"));
	}
	connections.unique();
	connections.sort();
	return connections;
}

/** Enable/Disable a MQTT Connection

	@param conName       : the name (DP) of the MQTT Connection to be enabled/disabled
	@param enable        : boolean to either enable or disable the connection
	@param exceptionInfo : standard exception-handling variable

 */
void fwPeriphAddressMQTT_enableConnection(string conName, bool enable, dyn_string &exceptionInfo)
{
	dyn_string conDpNames=makeDynString("_"+conName);
	if ( isRedundant() ) dynAppend(conDpNames,"_"+conName+"_2");

	for (int i=0;i<conDpNames.count();i++) {
		string conDP=conDpNames.at(i);
		if (!dpExists(conDP)) {fwException_raise(exceptionInfo,"ERROR","MQTT connection DP does not exist:"+conDP,"");return;}
		if (dpTypeName(conDP)!="_MqttConnection") {fwException_raise(exceptionInfo,"ERROR","Cannot set MQTT connection - DP is of wrong type:"+conDP,"");return;}
	}

	for (int i=0;i<conDpNames.count();i++) {
		string conDP=conDpNames.at(i);
		dpSetWait(conDP + ".Command.Enable", enable);
		dyn_errClass err=getLastError();
		if (dynlen(err)) {fwException_raise(exceptionInfo,"ERROR","Could not enable MQTT connection:"+getErrorText(err),""); /*no return yet*/}
	}
}
/** Validate the MQTT topic

	@returns true if topic is valid
	@returns false if topic is invalid, with @c exceptionInfo describing the problem
 */
bool fwPeriphAddressMQTT_checkTopic(string topic, dyn_string &exceptionInfo)
{
	if (topic.isEmpty()) {
		fwException_raise(exceptionInfo,"ERROR","MQTT topic may not be empty","");
		return false;
	} else if (topic.contains("#") || topic.contains("+")) {
		fwException_raise(exceptionInfo,"ERROR","Wrong character in MQTT topic: "+topic,"");
		return false;
	}
	return true;
}
