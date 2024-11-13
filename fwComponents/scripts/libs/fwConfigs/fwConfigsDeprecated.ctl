#uses "fwGeneral/fwManager.ctl"

// original constants that were used by fwDPELock as a part of fwConfigs
// replaced by corresponding constants declared in fwDPELock.ctl
const int fwConfigs_LOCK_MANAGER_DETAIL = 1;
const int fwConfigs_LOCK_USER_NAME      = 2;
const int fwConfigs_LOCK_MANAGER_TYPE   = 3;
const int fwConfigs_LOCK_MANAGER_NUMBER = 4;
const int fwConfigs_LOCK_MANAGER_SYSTEM = 5;
const int fwConfigs_LOCK_MANAGER_HOST   = 6;
const int fwConfigs_LOCK_MANAGER_REPLICA    = 7; // which of redu systems
const int fwConfigs_LOCK_MANAGER_MANID      = 8;
const int fwConfigs_LOCK_USER_ID        = 9;
const int fwConfigs_LOCK_TYPE           = 10;

/**
Checks the type of a data point element and returns the integer used to represent this data type
	depending on the required type of peripheral address.

	NOTE: this function is mostly redundant now as OPC supports the default data transformation now.
	The results for address type DIM are also redundant now.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dataType			The integer representing the data type is returned here (returns -1 if dpe type is unsupported)
@param dpe					The data point element to check
@param addressType	The type of peripheral address (DIM or OPC)


@Deprecated 2018-08-01

*/
fwPeriphAddress_getDataType(int &dataType, string dpe, string addressType)
{

  FWDEPRECATED();

	switch(dpElementType(dpe))
	{
		case DPEL_BOOL:
			if(addressType == "OPC")
			{
				dataType = 486;
			}
			else
			{
				dataType = 2002;
			}
			break;
		case DPEL_INT:
			if(addressType == "OPC")
			{
				dataType = 481;
			}
			else
			{
				dataType = 2002;
			}
			break;
		case DPEL_STRING:
			if(addressType == "OPC")
			{
				dataType = 487;
			}
			else
			{
				dataType = 2001;
			}
			break;
		case DPEL_FLOAT:
			if(addressType == "OPC")
			{
				dataType = 484;
			}
			else
			{
				dataType = 2003;
			}
			break;
		case DPEL_DYN_BOOL:
			if(addressType == "OPC")
			{
				dataType = -1;
			}
			else
			{
				dataType = 2004;
			}
			break;
		case DPEL_DYN_FLOAT:
			if(addressType == "OPC")
			{
				dataType = -1;
			}
			else
			{
				dataType = 2005;
			}
			break;
		default:
			dataType = -1;
			break;
	}
}






/**
Get formatted address for Unicos using given parameters

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters				parameters used to build the address reference (see constants definition)
@param addressReference		address reference (empty string in case of error)

@Deprecated 2018-08-01

Implementation removed on 2021-09-08

*/
fwPeriphAddress_getUnicosAddressReference(dyn_string dsParameters, string& addressReference)
{
  DebugTN("ERROR","fwPeriphAddress_getUnicosAddressReference - DEPRECATED IMPLEMENTATION REMOVED. PLEASE USE THE CORRESPONDING UNICOS FUNCTION unConfigGenericFunctions_getUnicosAddressReference()","");
  FWDEPRECATED();
}

/**

@Deprecated 2021-09-08

Implementation removed on 2021-09-08

Please use the corresponding function in UNICOS
*/
fwPeriphAddress_checkModbusParameters(dyn_string dsParameters, dyn_string& exceptionInfo)
{
  fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters() - DEPRECATED IMPLEMENTATION REMOVED. PLEASE USE THE unConfigGenericFunctions_checkModbusParameters()","");
  FWDEPRECATED();
}

/** DEPRECATED - function to get the Unit of several dpes

Function is replaced by fwUnit_getMany

@Deprecated 2018-08-02

*/
fwUnit_getMultiple(dyn_string dsDpe, dyn_bool &dbUnitExists, dyn_string &dsUnit, dyn_string &exceptionInfo)
{

  FWDEPRECATED();

	fwUnit_getMany(dsDpe, dbUnitExists, dsUnit, exceptionInfo);
}/** DEPRECATED - function to get the Format of several dpes

Function is replaced by fwFormat_getMany

@Deprecated 2018-08-01

*/
fwFormat_getMultiple(dyn_string dsDpe, dyn_bool &dbFormatExists, dyn_string &dsFormat, dyn_string &exceptionInfo)
{

  FWDEPRECATED();

	fwFormat_getMany(dsDpe, dbFormatExists, dsFormat, exceptionInfo);
}

/** This function returns the host name where the given manager is running.  The manager id passed is
the internal PVSS manager ID as used by functions like convManIdToInt().  The function looks in the
internal PVSS _Connections DPs to find this information.

@par Constraints
    Currently only supports CTRL and UI managers (because users can lock configs from these managers)

@par Usage
    Internal

@par PVSS managers
    VISION, CTRL

@param managerId                     The manager ID for which you want to find the host name
@param managerHostname  The hostname is returned here
@param exceptionInfo       Details of any exceptions are returned here

@Deprecated 2019-07-17 replaced by fwManager_getManagerHostName from fwGeneral/fwManager.ctl

*/
void _fwConfigs_getManagerHostname(int managerId, string &managerHostname, dyn_string &exceptionInfo)
{
	FWDEPRECATED();
	
    managerHostName = fwManager_getManagerHostName(managerId, exceptionInfo);
}
