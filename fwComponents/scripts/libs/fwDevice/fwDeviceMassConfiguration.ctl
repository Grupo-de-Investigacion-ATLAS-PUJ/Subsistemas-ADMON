/**@file

NOTE: This file is not automatically loaded by fwCore.ctl and needs to be loaded explicitely, if needed

This library contains functions to do mass configuration operations on WinCC OA datapoints.
The library contains code moved from the fwDeviceMassConfiguration panel and it is extensively called
from there.

@par Creation Date
	22/07/14

@par Modification History

@par Constraints


@author
	Manuel Gonzalez Berges (EN-ICE)
*/

//@{

/** Loads all devices that match the selection parameters and shows them in the "search result" table.

@par Constraints
  None

@par Usage

@par PVSS managers
*/
void fwDeviceMassConfiguration_getListOfDevices(dyn_dyn_string &listOfDevices, string deviceDpNamePattern, string deviceDpAliasPattern,
												string deviceDpType, string deviceDpDescriptionPattern, dyn_string &exceptionInfo)
{
	int result;
	string deviceType;
	string deviceModel;
	string deviceName;
	dyn_bool matches;
	dyn_string	dps;
	dyn_string 	aliases;
	dyn_string 	dpsNameAndType;
	dyn_string 	dpsNameAndDescription;
	dyn_string 	dsDeviceComments;

	// adapt name pattern to dpgetalldescriptions
	if(deviceDpNamePattern != "*" && deviceDpNamePattern != "")
	{
		deviceDpNamePattern = deviceDpNamePattern + ".";
	}

	// apply filter with dp name and description
	result = dpGetAllDescriptions(dpsNameAndDescription, dsDeviceComments, deviceDpDescriptionPattern, deviceDpNamePattern);

	// if type was specified, apply type filter
	if(deviceDpType != "*")
	{
		dpsNameAndType = dpNames(deviceNameText.text, deviceDpType);   // need to make sure name doesn't have .??'
		for(int i = 1; i <= dynlen(dpsNameAndType); i++)
		{
			dpsNameAndType[i] = dpsNameAndType[i] + ".";
		}
		dps = dynIntersect(dpsNameAndType, dpsNameAndDescription);
	}
	else
	{
		dps = dpsNameAndDescription;
	}

	// apply dp alias filter
	aliases = dpGetAlias(dps);
	matches = patternMatch(deviceDpAliasPattern, aliases);

	for(int i = 1; i <= dynlen(dps); i++)
	{
		if(matches[i] == TRUE)
		{
			deviceDpType = dpTypeName(dps[i]);

			// consider only Framework devices (dps that have a device definition)
			if(dynContains(g_dsDpTypes, deviceDpType) > 0)			// NEEDS CORRECTION !!!!!!!!!
			{
				fwDevice_getType(deviceDpType, deviceType, exceptionInfo);
				if(deviceType == "")
				{
					deviceType = deviceDpType;
				}

				deviceName = strrtrim(dps[i], ".");
                dyn_string device = makeDynString();

                device[fwDevice_DP_NAME] = deviceName;
                device[fwDevice_DP_ALIAS] = aliases[i];
                device[fwDevice_TYPE] = deviceType;
                device[fwDevice_COMMENT] = dpGetComment(dps[i]);
                fwDevice_getModel(makeDynString(deviceName), deviceModel, exceptionInfo);
                device[fwDevice_MODEL] = deviceModel;
                dynAppend(listOfDevices, device);
			}
		}
	}

}


/** Gets the summary for hardware, alarms, addresses and dpfunction configurations

@par Constraints
  None

@par Usage
	Private to the library

@param deviceDpNames		input, list of datapoint names
@param configIndex				input, config index as defined in fwDevice.ctl (e.g. fwDevice_ADDRESS_INDEX, fwDevice_ALERT_INDEX, etc)
@param exceptionInfo				output, returns details of any exceptionInfo

@return returns the parameters of the requested config in configIndex for all the requested devices (datapoints)

@return Array of string, the configurations of the given devices
*/
dyn_string _fwDeviceMassConfiguration_getConfigsForDevices(dyn_string deviceDpNames, int configIndex, dyn_string &exceptionInfo)
{
	dyn_string dsConfigs;

	for(int i = 1; i <= dynlen(deviceDpNames); i++)
		dynAppend(dsConfigs, _fwDeviceMassConfiguration_getSingleConfig(deviceDpNames[i], configIndex, exceptionInfo));

	return dsConfigs;
}

/** Gets information for a single config.

@par Constraints
  None

@par Usage
	Private to the library

@param deviceDpNames     input, name of one datapoint
@param qType             input, ordering integer

@return String, the configuration of one given device
*/
string _fwDeviceMassConfiguration_getSingleConfig(string deviceDpName, int index, dyn_string &exceptionInfo)
{
	int 	configType,
			configN,
			configY;
	string definitionDp,
				config,
				model;
	dyn_bool canHave;
	dyn_string elements;
	dyn_dyn_string elementsAndProperties;

	switch(index)
	{
		case fwDevice_ADDRESS_INDEX:
			config = "address";
			fwDevice_getDefinitionDp(makeDynString(deviceDpName), definitionDp, exceptionInfo);
			dpGet(definitionDp + ".properties.dpes", elements,
						definitionDp + ".configuration.address.canHave", canHave);
			break;
	case fwDevice_ALERT_INDEX:
			config = "alert_hdl";
			fwDevice_getModel(makeDynString(deviceDpName), model, exceptionInfo);
			fwDevice_getConfigElements(dpTypeName(deviceDpName), index, elementsAndProperties, exceptionInfo, model);
			elements = elementsAndProperties[1];
			break;
    case fwDevice_ARCHIVE_INDEX:
			config = "archive";
			fwDevice_getModel(makeDynString(deviceDpName), model, exceptionInfo);
			fwDevice_getConfigElements(dpTypeName(deviceDpName), index, elementsAndProperties, exceptionInfo, model);
			elements = elementsAndProperties[1];
			break;
	case fwDevice_DPFUNCTION_INDEX:
			config = "dp_fct";
			fwDevice_getModel(makeDynString(deviceDpName), model, exceptionInfo);
			fwDevice_getConfigElements(dpTypeName(deviceDpName), index, elementsAndProperties, exceptionInfo, model);
			elements = elementsAndProperties[1];
			break;
    default:
			break;
	}

	 dyn_string dps;
	 dyn_anytype result;
	 int numElements = dynlen(elements);
	 for (int i = 1; i <= numElements; i++) {
	 	if(index == fwDevice_ADDRESS_INDEX)
			if(!canHave[i])
				continue;
	   	dynAppend(dps, deviceDpName + elements[i] + ":_" + config + ".._type");
	 }

	if (dynlen(dps) > 0) {
		 dpGet(dps, result);
		 int numResults = dynlen(result);
		 for (int i = 1; i <= numResults; i++) {
		   if (result[i] == DPCONFIG_NONE) {
		     configN++;
		   } else {
		     configY++;
		   }
		 }
	}

	if(configN == 0 && configY > 0)
		return "Yes";
	else if(configY == 0 && configN > 0)
		return "No";
	else if(configY==0 && configN==0)
		return "-";
	else
		return configY + "/" + (configY + configN);
}

//@}
