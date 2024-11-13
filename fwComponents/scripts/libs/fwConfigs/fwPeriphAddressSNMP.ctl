const string   fwPeriphAddress_TYPE_SNMP = "SNMP";

const unsigned fwPeriphAddress_SNMP_POLL_GROUP      = 11;
const unsigned fwPeriphAddress_SNMP_SUBINDEX        = 12;
const unsigned fwPeriphAddress_SNMP_AGENT_ID	      = 13;
const unsigned fwPeriphAddress_SNMP_AGENT_VERSION	  = 14;

const unsigned fwPeriphAddress_SNMP_OBJECT_SIZE     = 14;


/** 
@brief Internal function to setup the SNMP addressing
  
@par Constraints
  Should only be called from fwPeriphAddress_set

@param dpe	Datapoint element to act on
@param addressConfig		Address object is passed here:														                            \n\n
			- addressConfig[FW_PARAMETER_FIELD_DRIVER] contains driver number		      								              \n
			- addressConfig[FW_PARAMETER_FIELD_ADDRESS] contains the SNMP OID (starting with "1.3.6.1")	              \n
			- addressConfig[FW_PARAMETER_FIELD_SUBINDEX] contains the subindex		      								            \n
			- addressConfig[FW_PARAMETER_FIELD_DATATYPE] contains the translation datatype		      								\n
			- addressConfig[FW_PARAMETER_FIELD_COMMUNICATION] should be equal to fwPeriphAddress_TYPE_SNMP ("SNMP")	\n
			- addressConfig[FW_PARAMETER_FIELD_MODE] contains the communication direction and type from the list:		\n
			  -- DPATTR_ADDR_MODE_INPUT_SPONT		                                                                    \n
			  -- DPATTR_ADDR_MODE_INPUT_SQUERY		                                                                  \n
			  -- DPATTR_ADDR_MODE_INPUT_POLL		                                                                    \n
			  -- DPATTR_ADDR_MODE_IO_SQUERY		                                                                      \n
			  -- DPATTR_ADDR_MODE_IO_POLL		                                                                        \n
			  -- DPATTR_ADDR_MODE_OUTPUT_SINGLE		                                                                  \n
			- addressConfig[FW_PARAMETER_FIELD_ACTIVE] contains whether or not the address is active	  						\n
			- addressConfig[fwPeriphAddress_SNMP_AGENT_ID] contains the WinCC OA ID number of the SNMP Agent     		\n
			- addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] is the SNMP agent version (V1/V2 or V3)             \n
			- addressConfig[fwPeriphAddress_SNMP_POLL_GROUP] is the nameof the poll group DP        								\n
@param exceptionInfo		Details of any errors are returned here
*/
_fwPeriphAddressSNMP_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
  dyn_errClass errors;
  
	fwPeriphAddressSNMP_check(addressConfig, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
    return;

  dpSetWait(dpe + ":_distrib.._type",     DPCONFIG_DISTRIBUTION_INFO,
						dpe + ":_distrib.._driver",   (int)addressConfig[FW_PARAMETER_FIELD_DRIVER]);

  errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not create the distrib config.", "");
		return;
	}

  string reference = addressConfig[fwPeriphAddress_SNMP_AGENT_ID] + "_" + addressConfig[FW_PARAMETER_FIELD_ADDRESS];
  
  if(strtoupper(addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION]) == "V3")
    reference = "A" + reference;

	dpSetWait(dpe + ":_address.._type",       DPCONFIG_PERIPH_ADDR_MAIN,
						dpe + ":_address.._reference",  reference, 
						dpe + ":_address.._subindex",   addressConfig[fwPeriphAddress_SNMP_SUBINDEX],  
						dpe + ":_address.._datatype",   addressConfig[FW_PARAMETER_FIELD_DATATYPE],  
						dpe + ":_address.._drv_ident",  addressConfig[FW_PARAMETER_FIELD_COMMUNICATION],
						dpe + ":_address.._direction",  (int)addressConfig[FW_PARAMETER_FIELD_MODE],
						dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_SNMP_POLL_GROUP],
						dpe + ":_address.._active",     addressConfig[FW_PARAMETER_FIELD_ACTIVE]);							
						
	errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not create the address config.", "");
	}
}


/** 
@brief Internal function to get the SNMP addressing
  
@par Constraints
  Should only be called from fwPeriphAddress_get

@param dpe	          Datapoint element to read from
@param addressConfig	Address object is returned here (configParameters). See description for addressConfig on _fwPeriphAddressSNMP_set()
@param isActive				TRUE if address config is active, else FALSE 
@param exceptionInfo	Details of any errors are returned here
*/
_fwPeriphAddressSNMP_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
  addressConfig = makeDynAnytype();
  addressConfig[fwPeriphAddress_SNMP_OBJECT_SIZE] = "";
  
  int driverNumber, mode;
  string reference;  
  
  dpGet(dpe + ":_distrib.._driver",     driverNumber,
        dpe + ":_address.._reference",  reference, 
        dpe + ":_address.._subindex",   addressConfig[fwPeriphAddress_SNMP_SUBINDEX],  
        dpe + ":_address.._datatype",   addressConfig[FW_PARAMETER_FIELD_DATATYPE],  
        dpe + ":_address.._drv_ident",  addressConfig[FW_PARAMETER_FIELD_COMMUNICATION],
        dpe + ":_address.._direction",  mode,
        dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_SNMP_POLL_GROUP],
        dpe + ":_address.._active",     addressConfig[FW_PARAMETER_FIELD_ACTIVE]);

  addressConfig[FW_PARAMETER_FIELD_DRIVER] = driverNumber;
  addressConfig[FW_PARAMETER_FIELD_MODE] = mode;
  addressConfig[fwPeriphAddress_SNMP_POLL_GROUP] = dpSubStr(addressConfig[fwPeriphAddress_SNMP_POLL_GROUP], DPSUB_DP);
  
  if(strpos(reference, "A") == 0)
  {
    addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] = "V3";
    reference = substr(reference, 1);
  }
  else
    addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] = "V1/V2";

  dyn_string parts = strsplit(reference, "_");
  addressConfig[fwPeriphAddress_SNMP_AGENT_ID] = (int)parts[1];
  addressConfig[FW_PARAMETER_FIELD_ADDRESS] = parts[2];
  
  isActive = addressConfig[fwPeriphAddress_ACTIVE];
}


/** 
@brief Internal function to cleanup before deleting the SNMP _address and _distrib configs
  
@par Constraints
  Should only be called from fwPeriphAddress_delete \n
  This function currently does nothing because the SNMP addressing can be deleted by simply removing the _address and _distrib configs

@param dpe	          Datapoint element to read from
@param exceptionInfo	Details of any errors are returned here
*/
_fwPeriphAddressSNMP_delete(string dpe, dyn_string &exceptionInfo)
{
}


/** 
@brief Function to check SNMP address configurtion parameters before attempting to save them to the DP element
  
@param addressConfig	The address configuration object is passed here. In some cases, an amended (fixed) version may be returned here
@param exceptionInfo	Details of errors in the address configuration are returned here
*/
fwPeriphAddressSNMP_check(dyn_anytype &addressConfig, dyn_string &exceptionInfo)
{
	string pollGroup = addressConfig[fwPeriphAddress_SNMP_POLL_GROUP];
  
  switch(addressConfig[FW_PARAMETER_FIELD_MODE])
  {
    case DPATTR_ADDR_MODE_INPUT_POLL:
    case DPATTR_ADDR_MODE_IO_POLL:
      if(strlen(pollGroup) == 0)
    		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddressSNMP_check: " +
                                                  "A poll group must be defined for polled input configurations", "");
      else
      {
        //if poll group is defined, does not being with a "_" and does not specify the system name, then prepend the "_"
        if(strpos(pollGroup,"_")!=0 && strpos(pollGroup,":")<0)
          pollGroup = "_"+pollGroup;
    
        if(!dpExists(pollGroup))
      		fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddressSNMP_check: " +
                                                    "The poll group \"" + pollGroup + "\" does not exist", "");
      }      
      break;
    case DPATTR_ADDR_MODE_INPUT_SPONT:
    case DPATTR_ADDR_MODE_INPUT_SQUERY:
    case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
    case DPATTR_ADDR_MODE_IO_SQUERY:
      pollGroup = ""; //clear poll group because it is not needed
      break;
    default:
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressSNMP_check: " +
                                              "Mode " + addressConfig[FW_PARAMETER_FIELD_MODE] + " is not supported","");
      break;
  }

  addressConfig[fwPeriphAddress_SNMP_POLL_GROUP] = pollGroup;

  if(fwPeriphAddressSNMP_dataTypeIntToString(addressConfig[FW_PARAMETER_FIELD_DATATYPE]) == -1)
  {
  	fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressSNMP_check: " +
                                            "Data type " + addressConfig[FW_PARAMETER_FIELD_DATATYPE] + " is not supported","");
  }
  
  switch(strtoupper(addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION]))
  {
    case "V1":
    case "V2":
    case "V1/V2":
    case "V3":
      break;
    default:
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressSNMP_check: " +
                                              "Agent version " + addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] + " is not support (must be V1, V2, V1/V2 or V3)","");
      break;
  }

  if(strpos(addressConfig[FW_PARAMETER_FIELD_ADDRESS], "1.3.6.1") != 0)
  	fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressSNMP_check: " + 
                                              "Invalid OID \"" + addressConfig[FW_PARAMETER_FIELD_ADDRESS] + "\". OIDs must always begin with \"1.3.6.1\"","");
}

_fwPeriphAddressSNMP_initPanel(string dpe, dyn_string &exceptionInfo)
{
  bool exists, active;
  dyn_anytype addressConfig;
  
  cmbPollGroupSNMP.items = _fwPeriphAddressSNMP_getPollGroups();

  fwPeriphAddress_get(dpe, exists, addressConfig, active, exceptionInfo);
  
  if(exists && addressConfig[FW_PARAMETER_FIELD_COMMUNICATION] == fwPeriphAddress_TYPE_SNMP)
  {
  	driverNumberSelectorSNMP.text = addressConfig[FW_PARAMETER_FIELD_DRIVER];		
  	oidSNMP.text = addressConfig[FW_PARAMETER_FIELD_ADDRESS];
  	subindexSNMP.text = addressConfig[FW_PARAMETER_FIELD_SUBINDEX];
  	agentIdSNMP.text = addressConfig[fwPeriphAddress_SNMP_AGENT_ID];		
  	versionSNMP.number = (addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] == "V3");
  	cmbPollGroupSNMP.text = strltrim(dpSubStr(addressConfig[fwPeriphAddress_SNMP_POLL_GROUP], DPSUB_DP), "_");
    addressActiveSNMP.state(0) = addressConfig[FW_PARAMETER_FIELD_ACTIVE];		

    _fwPeriphAddressSNMP_showModeInPanel(addressConfig[FW_PARAMETER_FIELD_MODE]);
  
  	transformSNMP.text = fwPeriphAddressSNMP_dataTypeIntToString(addressConfig[FW_PARAMETER_FIELD_DATATYPE]);
  }
  else
  {
    addressActiveSNMP.state(0) = true;		
  }
  
  _fwPeriphAddressSNMP_updatePanel();
}

_fwPeriphAddressSNMP_saveFromPanel(string dpe, dyn_string &exceptionInfo)
{
	dyn_anytype addressConfig;

  int mode = _fwPeriphAddressSNMP_readModeFromPanel(); 
  
	addressConfig[FW_PARAMETER_FIELD_DRIVER] = (int)driverNumberSelectorSNMP.text;		
	addressConfig[FW_PARAMETER_FIELD_ADDRESS] = oidSNMP.text;
	addressConfig[FW_PARAMETER_FIELD_SUBINDEX] = subindexSNMP.text;
	addressConfig[FW_PARAMETER_FIELD_DATATYPE] = fwPeriphAddressSNMP_dataTypeStringToInt(transformSNMP.text);
	addressConfig[FW_PARAMETER_FIELD_COMMUNICATION] = fwPeriphAddress_TYPE_SNMP;
	addressConfig[FW_PARAMETER_FIELD_MODE]= mode;
	addressConfig[FW_PARAMETER_FIELD_ACTIVE] = addressActiveSNMP.state(0);		
	addressConfig[fwPeriphAddress_SNMP_AGENT_ID] = (int)agentIdSNMP.text;		
	addressConfig[fwPeriphAddress_SNMP_AGENT_VERSION] = (versionSNMP.number==0)?"V1/V2":"V3";		
	addressConfig[fwPeriphAddress_SNMP_POLL_GROUP] = (mode == DPATTR_ADDR_MODE_INPUT_POLL || mode == DPATTR_ADDR_MODE_IO_POLL)?"_"+cmbPollGroupSNMP.text:"";	
	
	fwPeriphAddress_set(dpe, addressConfig, exceptionInfo, TRUE);
}

//This function could be made into a general JCOP FW tool as it is not specific to SNMP
dyn_string _fwPeriphAddressSNMP_getPollGroups(string systemName = "")
{
  dyn_string pollGroups = dpNames(systemName + "*","_PollGroup");

	for ( int i = dynlen(pollGroups); i > 0; i-- )
  {
    if ( i > 1 && strpos(pollGroups[i],"_2") == strlen(pollGroups[i]) - 2 && pollGroups[i] == pollGroups[i-1] + "_2" )
    {
      dynRemove(pollGroups, i);
    }

    if ( i <= dynlen(pollGroups) )
    {
      pollGroups[i] = dpSubStr(pollGroups[i],DPSUB_DP);
      if ( pollGroups[i][0] == "_" )
        pollGroups[i] = substr(pollGroups[i], 1, strlen(pollGroups[i])-1);
    }
  }
  
  return pollGroups;
}

_fwPeriphAddressSNMP_updatePanel()
{
  switch(directionSNMP.number)
  {
    case 0:
      modeSNMP.enabled = false;
      break;
    case 1:
      modeSNMP.enabled = true;
      modeSNMP.itemEnabled(0, true);
      break;
    case 2:
      modeSNMP.enabled = true;
      modeSNMP.itemEnabled(0, false);
      if(modeSNMP.number == 0)
        modeSNMP.number = 1;
      break;
  }
  
  cmbPollGroupSNMP.enabled = (modeSNMP.enabled && modeSNMP.number == 2);
  cmdPollGroupSNMP.enabled = (modeSNMP.enabled && modeSNMP.number == 2);
}

string fwPeriphAddressSNMP_dataTypeIntToString(int type)
{
 	mapping dataTypes;
  
  dataTypes[660] = "undefined";
  dataTypes[661] = "integer32";
  dataTypes[662] = "unsigned32";
  dataTypes[663] = "unsigned64";
  dataTypes[664] = "objectID";
  dataTypes[665] = "octet";
  dataTypes[666] = "visible string";
  dataTypes[667] = "date time";
  dataTypes[668] = "MAC address";
  dataTypes[669] = "IP address";
  dataTypes[670] = "bit string (only SNMP v2)";
  dataTypes[673] = "visible string hex";  
  
  if(mappingHasKey(dataTypes, type))
    return dataTypes[type];
  else
    return -1;
}

int fwPeriphAddressSNMP_dataTypeStringToInt(string type)
{
	mapping dataTypes;
  
  dataTypes["undefined"] = 660;
  dataTypes["integer32"] = 661;
  dataTypes["unsigned32"] =662;
  dataTypes["unsigned64"] = 663;
  dataTypes["objectID"] = 664;
  dataTypes["octet"] = 665;
  dataTypes["visible string"] = 666;
  dataTypes["date time"] = 667;
  dataTypes["MAC address"] = 668;
  dataTypes["IP address"] = 669;
  dataTypes["bit string (only SNMP v2)"] = 670;
  dataTypes["visible string hex"] = 673;

  if(mappingHasKey(dataTypes, type))
    return dataTypes[type];
  else
    return -1;
}

_fwPeriphAddressSNMP_showModeInPanel(int mode)
{
  switch(mode)
  {
    case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
      directionSNMP.number = 0;
      break;
    case DPATTR_ADDR_MODE_INPUT_SPONT:
      directionSNMP.number = 1;
      modeSNMP.number = 0;
      break;
    case DPATTR_ADDR_MODE_INPUT_SQUERY:
      directionSNMP.number = 1;
      modeSNMP.number = 1;
      break;
    case DPATTR_ADDR_MODE_INPUT_POLL:
      directionSNMP.number = 1;
      modeSNMP.number = 2;
      break;
    case DPATTR_ADDR_MODE_IO_SQUERY:
      directionSNMP.number = 2;
      modeSNMP.number = 1;
      break;
    case DPATTR_ADDR_MODE_IO_POLL:
      directionSNMP.number = 2;
      modeSNMP.number = 2;
      break;
  }  
}

int _fwPeriphAddressSNMP_readModeFromPanel()
{
  int mode;
  
  if(directionSNMP.number == 0)
    mode = DPATTR_ADDR_MODE_OUTPUT_SINGLE;
  else if(directionSNMP.number == 1 && modeSNMP.number == 0)
    mode = DPATTR_ADDR_MODE_INPUT_SPONT;
  else if(directionSNMP.number == 1 && modeSNMP.number == 1)
    mode = DPATTR_ADDR_MODE_INPUT_SQUERY;
  else if(directionSNMP.number == 1 && modeSNMP.number == 2)
    mode = DPATTR_ADDR_MODE_INPUT_POLL;
  else if(directionSNMP.number == 2 && modeSNMP.number == 1)
    mode = DPATTR_ADDR_MODE_IO_SQUERY;
  else if(directionSNMP.number == 2 && modeSNMP.number == 2)
    mode = DPATTR_ADDR_MODE_IO_POLL;
  
  return mode;
}


