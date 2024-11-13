
// Definition of constants used for the ELMB
const int ELMB_MAX_CHANNEL = 64;

const int ELMB_SAVE_EEPROM = 1702257011;

const string VENDOR_NAME = "ELMB";

const string OPC_DELIMETER = ".";

// remove it, prepare one for OPC-UA
const string ELMB_OPC_SERVER = "_OPCCANopen";

// PiotrTODO: remove (not needed)
const string OPC_GROUPS_TYPE_NAME = "_OPCGroup";

const string ELMB_CAN_CARD_NICAN = "NICAN";
const string ELMB_CAN_CARD_KVASER = "Kvaser";
const string ELMB_CAN_CARD_SYSTEC = "Systec";

const string ELMB_NO_INFO = "EMPTY";
const string ELMB_CHANNEL_NA = "N/A";

const string ELMB_CAN_SYSTEM_VIEW_NAME = "fwElmbCANSystemView";
const string ELMB_CAN_BUS_TYPE_NAME = "FwElmbCANbus";
const string ELMB_TYPE_NAME = "FwElmbNode";
const string ELMB_SENSOR_INFO_TYPE_NAME = "_FwElmbSensorInfo";
const string ELMB_SENSOR_INFO_NAME = "fwElmbSensorInfo";
const string ELMB_PDO_INFO_TYPE_NAME = "_FwElmbPDOInfo";
const string ELMB_AI_CONFIG_NAME = "AI";
const string ELMB_AO_CONFIG_NAME = "AO";
const string ELMB_DI_CONFIG_NAME = "DI";
const string ELMB_DO_CONFIG_NAME = "DO";
const string ELMB_SPI_CONFIG_NAME = "SPI";
const string ELMB_AI_PREFIX = "ai_";
const string ELMB_AI_SDO_PREFIX = "aisdo_";
const string ELMB_AO_PREFIX = "ao_";
const string ELMB_DI_PREFIX = "di_";
const string ELMB_DO_PREFIX = "do_";
const string ELMB_AI_CONFIG_TYPE_NAME = "FwElmbAiConfig";
const string ELMB_AO_CONFIG_TYPE_NAME = "FwElmbAoConfig";
const string ELMB_DI_CONFIG_TYPE_NAME = "FwElmbDiConfig";
const string ELMB_DO_CONFIG_TYPE_NAME = "FwElmbDoConfig";
const string ELMB_AI_TYPE_NAME = "FwElmbAi";
const string ELMB_AI_SDO_TYPE_NAME = "FwElmbAiSDO";
const string ELMB_AO_TYPE_NAME = "FwElmbAo";
const string ELMB_DI_TYPE_NAME = "FwElmbDi";
const string ELMB_DO_TYPE_NAME = "FwElmbDo";
const string ELMB_DO_BYTES_TYPE_NAME = "FwElmbDoBytes";
const string ELMB_SPI_TYPE_NAME = "FwElmbSPI";

const string FWELMB_MIDDLEWARE_OPCDA = "OPCDA";
const string FWELMB_MIDDLEWARE_OPCUA = "OPCUA";

const int FWELMB_CACHED_OFFSET_INVALID = 1;
const int FWELMB_CACHED_OFFSET_ACTIVE = 2;

const uint FWELMB_DI_READOUT_ONSYNC = 0;
const uint FWELMB_DI_READOUT_ONCHANGE = 1;
