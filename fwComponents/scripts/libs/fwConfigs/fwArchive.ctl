/**@file

@addtogroup fwArchiveConfig fwArchive config library
@{
@since Creation Date 28/03/2000
@author Marco Boccioli, Piotr Golonka, Oliver Holme, Niko Karlson, Herve Milcent, Sascha Schmeling, Fernando Varela
@brief The library to handle WinCC OA archiving.
@par Modification History
    - up to date list to be seen it Jira, http://its.cern.ch

@section fwArchiveConfig_Description Description
The fwArchiveConfig library provides a set of functions to configure and manipulate the archiving.
Both, the value archive as well as Oracle RDB Archive and NextGeneration Archiver are supported.

@section fwArchiveConfig_Constants Constants used by fwArchiveConfig library

@subsection fwArchiveConfig_Constants_ArchiveType Constants for archive type
The following WinCC OA builtin constants (of type int) are used to specify the type of archiving:
 - @c DPATTR_ARCH_PROC_VALARCH: standard archiving with no smoothing,
 - @c DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing

@subsection fwArchiveConfig_Constants_Smoothing Constants for archive smoothing procedure
The following WinCC OA builtin constants (of type int) are used in the functions
to refer to various smoothing procedures:
 - @c DPATTR_VALUE_SMOOTH            	: value dependent,
 - @c DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
 - @c DPATTR_TIME_SMOOTH             	: time dependent,
 - @c DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
 - @c DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
 - @c DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
 - @c DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
 - @c DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
 - @c DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
 - @c DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time

@}
*/

#uses "fwConfigs/fwConfigConstants.ctl"
#uses "classes/fwGeneral/FwException.ctl"

/** \addtogroup fwArchiveConfig
 * @{
 */
//constants
const int fwArchive_CLASS_STOPPED     = 0;
const int fwArchive_CLASS_ONLINE      = 1;
const int fwArchive_CLASS_SWAPPED_OUT = 2;
const int fwArchive_CLASS_DELETED     = 3;

const string fwArchive_VALARCH_CLASS_DPTYPE = "_ValueArchive";
const string fwArchive_RDB_CLASS_DPTYPE = "_RDBArchiveGroups";
const string fwArchive_NGA_CLASS_DPTYPE = "_NGA_Group";

const int fwArchive_MANAGER_NUMBER_OFFSET = 2;

//global for monitoring class stats refresh
private global bool fwArchive_REFRESH_IN_PROGRESS = FALSE;


/** Deletes the archive config for the given data point elements

@param dpes		list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
    _fwConfigs_delete(dpes, fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}


/** Deletes the archive config for the given data point elements


@param dpes		list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_deleteMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}


/** Deletes the archive config for the given data point element

@param dpe		data point element
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_delete(string dpe, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(makeDynString(dpe), fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}

/** Sets archive config for the given dp elements with the option to start or not start the archiving

@param dpes			list of data point elements
@param startArchiving		true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param configureOnly		(optional, default false); if set to true, the archiving will be started/stopped according to the startArchive parameter
				otherwise only configuration will be changed (e.g. for smoothing); for all DPEs that do not have the archiving
				configured, the value of startArchive parameter will be taken.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
_fwArchive_setOrConfig(dyn_string dpes, bool startArchiving, dyn_string archiveClassDpName, dyn_int archiveType, dyn_int smoothProcedure,
			        dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, bool configureOnly = FALSE, int procedureIdx = 1)
{
	int i, length, classCounter = 1;
	mapping classPositions;
	dyn_string localClassStore;
	dyn_dyn_string sortedClassDpes;

	if(checkClass)
	{
		length = dynlen(dpes);
		for(i = 1; i <= length; i++)
		{
			if(!mappingHasKey(classPositions, archiveClassDpName[i]))
			{
				classPositions[archiveClassDpName[i]] = classCounter;
				classCounter++;
			}

			dynAppend(sortedClassDpes[classPositions[archiveClassDpName[i]]], dpes[i]);

		}

		localClassStore = archiveClassDpName;
		length = dynUnique(localClassStore);
		for(i = 1; i <= length; i++)
		{
			if(localClassStore == fwArchive_VALARCH_CLASS_DPTYPE)
			{
				fwArchive_checkClass(localClassStore[i], sortedClassDpes[classPositions[localClassStore[i]]], exceptionInfo);
				if(dynlen(exceptionInfo) > 0)
				{
					return;
				}
			}
		}
	}

	_fwArchive_setMany(dpes, startArchiving, archiveClassDpName, archiveType, smoothProcedure, deadband, timeInterval, exceptionInfo, configureOnly, procedureIdx);
}

/** Sets archive config for the given dp elements and start the archiving

@param dpes			list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param activateArchiving	Optional parameter. Default value TRUE. Determines if archiving should be activated.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_setMultiple(dyn_string dpes, string archiveClassName, int archiveType, int smoothProcedure,
			      float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, bool activateArchiving = TRUE, int procedureIdx = 1)
{
	int i, length;
	dyn_string dsArchiveClassName;
	dyn_int diArchiveType, diSmoothProcedure;
	dyn_float dfDeadband, dfTimeInterval;
	string classDpName;

	length = dynlen(dpes);
	for(i = 1; i <= length; i++)
	{
		dynAppend(dsArchiveClassName, archiveClassName);
		dynAppend(diArchiveType, archiveType);
		dynAppend(diSmoothProcedure, smoothProcedure);
		dynAppend(dfDeadband, deadband);
		dynAppend(dfTimeInterval, timeInterval);

	}

	fwArchive_setMany(dpes, dsArchiveClassName, diArchiveType, diSmoothProcedure,
				   dfDeadband, dfTimeInterval, exceptionInfo, checkClass, activateArchiving, false, procedureIdx);
}


/** Sets archive config for the given dp elements and start the archiving

@param dpes			list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband.
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param activateArchiving	Optional parameter. For internal use - to configure but not start archiving, please use fwArchive_configMany.
					Default value = TRUE, archiving is started immediately.
					Else if set to FALSE archiving is configured but not started.
@param configureOnly		(optional, default false); if set to true, the archiving will be started/stopped according to the activateArchiving,
				otherwise only configuration will be changed (e.g. for smoothing); for all DPEs that do not have the archiving
				configured, the value of activateArchiving parameter will be taken.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_setMany(dyn_string dpes, dyn_string archiveClassName, dyn_int archiveType, dyn_int smoothProcedure,
		        dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE,
		        bool activateArchiving = TRUE, bool configureOnly = false, int procedureIdx = 1)
{
  dyn_string classDpNames;
  _fwArchive_convertManyArchiveClassNamesToDpNames(dpes, archiveClassName, classDpNames, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  _fwArchive_setOrConfig(dpes, activateArchiving, classDpNames, archiveType, smoothProcedure,
                         deadband, timeInterval, exceptionInfo, checkClass, configureOnly, procedureIdx);
}


/** Gets archive class DPs for a list of DPEs and their archive class names

@param dpes			list of DPEs
@param archiveClassNames             names of archive classes
@param archiveClassDps               archive class DPs for dpes are returned here
@param exceptionInfo		details of errors are returned here
*/
_fwArchive_convertManyArchiveClassNamesToDpNames(dyn_string dpes, dyn_string archiveClassNames, dyn_string &archiveClassDps,
                                                 dyn_string &exceptionInfo)
{
  dyn_string systems;
  mapping classNameDpTranslator;

	const int dpesLen = dynlen(dpes);
	for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++)
	{
		systems[dpeIdx] = dpSubStr(dpes[dpeIdx], DPSUB_SYS);
	}

	for(int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++)
	{
		if(!mappingHasKey(classNameDpTranslator, archiveClassNames[dpeIdx] + systems[dpeIdx]))
		{
              string classDpName;
			fwArchive_convertClassNameToDpName(archiveClassNames[dpeIdx], classDpName, exceptionInfo, systems[dpeIdx]);
			classNameDpTranslator[archiveClassNames[dpeIdx] + systems[dpeIdx]] = classDpName;
			if(dynlen(exceptionInfo) > 0)
			{
				return;
			}
		}
	}

	const int archGroupLen = dynlen(archiveClassNames);
	for(int archGroupIdx = 1; archGroupIdx <= archGroupLen; archGroupIdx++)
	{
		archiveClassDps[archGroupIdx] = classNameDpTranslator[archiveClassNames[archGroupIdx] + systems[archGroupIdx]];
	}
}


/** Sets archive config for the given dp element and start the archiving
@param dpe			data point element
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_set(string dpe, string archiveClassName, int archiveType, int smoothProcedure,
		    float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, int procedureIdx = 1)
{
	dyn_string dpes, archiveClassNames;
	dyn_int archiveTypes, smoothProcedures;
	dyn_float deadbands, timeIntervals;

	dpes[1] = dpe;
	archiveClassNames[1] = archiveClassName;
	archiveTypes[1] = archiveType;
	smoothProcedures[1] = smoothProcedure;
	deadbands[1] = deadband;
	timeIntervals[1] = timeInterval;
	fwArchive_setMany(dpes, archiveClassNames, archiveTypes, smoothProcedures,
			        deadbands, timeIntervals, exceptionInfo, checkClass, true, false, procedureIdx);
}


/** Sets archive config for the given dp elements without starting the archiving
@param dpes			list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_configMultiple(dyn_string dpes, string archiveClassName, int archiveType, int smoothProcedure,
				    float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, int procedureIdx = 1)
{
  	int i, length;
	dyn_string dsArchiveClassName;
	dyn_int diArchiveType, diSmoothProcedure;
	dyn_float dfDeadband, dfTimeInterval;
	string classDpName;

	length = dynlen(dpes);
	for(i = 1; i <= length; i++)
	{
		dynAppend(dsArchiveClassName, archiveClassName);
		dynAppend(diArchiveType, archiveType);
		dynAppend(diSmoothProcedure, smoothProcedure);
		dynAppend(dfDeadband, deadband);
		dynAppend(dfTimeInterval, timeInterval);

	}

	fwArchive_setMany(dpes, dsArchiveClassName, diArchiveType, diSmoothProcedure,
				   dfDeadband, dfTimeInterval, exceptionInfo, checkClass, false, true, procedureIdx);

}


/** Sets archive config for the given dp elements without enabling or disabling the archive

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_configMany(dyn_string dpes, dyn_string archiveClassName, dyn_int archiveType, dyn_int smoothProcedure,
			      dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, int procedureIdx = 1)
{
	fwArchive_setMany(dpes, archiveClassName, archiveType, smoothProcedure,
			        deadband, timeInterval, exceptionInfo, checkClass, FALSE, TRUE, procedureIdx);
}


/** Sets archive config for the given dp element without starting the archiving

@param dpe			data point element
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param checkClass		Optional parameter. Default value TRUE.
					If TRUE, check class is not deleted and has enough free space.
					If FALSE skip checks.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_config(string dpe, string archiveClassName, int archiveType, int smoothProcedure,
		       float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, int procedureIdx = 1)
{
	fwArchive_configMany(makeDynString(dpe), makeDynString(archiveClassName), makeDynInt(archiveType), makeDynInt(smoothProcedure),
					makeDynFloat(deadband), makeDynFloat(timeInterval), exceptionInfo, checkClass, procedureIdx);
}


/** Returns details of the archive config on the given list of dp elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			the list of data point elements.
@param configExists			TRUE - archive config existing,
                   			FALSE - archive config is not existing
@param archiveClass		name of the archive class for the config (not archive class dp name)
@param archiveType		specify whether archive smoothing shold be enabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param isActive			TRUE if archiving of this dpe is active, else FALSE
@param exceptionInfo		details of any errors are returned here
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_getMany(dyn_string dpes, dyn_bool &configExists, dyn_string &archiveClass, dyn_int &archiveType, dyn_int &smoothProcedure,
			   dyn_float &deadband, dyn_float &timeInterval, dyn_bool &isActive, dyn_string &exceptionInfo, int procedureIdx = 1)
{
	dyn_string localException;
	dyn_int diTmpSmoothProcedure;
	dyn_string dsDpAttr, dsAttrVal, dsTypesAttr, dsTypesVal, dsTempVal, dsDpesWithConfig;
	dyn_float dfTmpDeadband, dfTmpTimeInterval;
	int i, j, k, length;
	string configString;
	int ret;
    dyn_string localExceptionInfo;

	configExists = FALSE;
	archiveClass = "";
	archiveType = 0;
	smoothProcedure = 0;
	deadband = 0;
	timeInterval = 0;
	length = dynlen(dpes);

    //get the types of all the dpes:
	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ARCHIVE, dsTypesVal, localExceptionInfo);
    if (dynlen(localExceptionInfo)) {
        fwException_raise(localExceptionInfo, "ERROR", "fwArchive_getMany(): Could not get some of the attributes. Function aborted.", "");
		return;
    }

	//select only the configured dpes:
	for(i = 1 ; i <= length ; i++)
	{
		if(dsTypesVal[i] == DPCONFIG_DB_ARCHIVEINFO)
		{
			dynAppend(dsDpesWithConfig, dpes[i]);
		}
	}

	//for the configured dpes, get smoothing params:
     if(dynlen(dsDpesWithConfig)) {
		_fwSmoothing_getParameters(dsDpesWithConfig, true, diTmpSmoothProcedure,
						       dfTmpDeadband, dfTmpTimeInterval, exceptionInfo, procedureIdx);
     }

	//for the configured dpes, get the other parameters:
	for(i = 1 ; i <= length ; i++)
	{
		switch(dsTypesVal[i])
		{
			case DPCONFIG_DB_ARCHIVEINFO:
				dynAppend(dsDpAttr, dpes[i] + ":_archive.._archive");
				dynAppend(dsDpAttr, dpes[i] + ":_archive." + (string)procedureIdx + "._type");
				dynAppend(dsDpAttr, dpes[i] + ":_archive." + (string)procedureIdx + "._class");
				break;

			case DPCONFIG_NONE:
				configExists[i] = false;
				smoothProcedure[i] = 0;
				deadband[i] = 0;
				timeInterval[i] = 0;
				break;
		}
		if((dynlen(dsDpAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDpAttr) > 0))
		{
			ret = dpGet(dsDpAttr, dsTempVal);

			if(dynlen(dsTempVal) < 1)
			{
				//a problem occurred: one or more dpes have incomplete smoothing settings
				//as fallback, get the dpes one by one, and report the misconfigured one(s).
				dynClear(dsTempVal);
				for(j = 1 ; j <= dynlen(dsDpAttr) ; j++)
				{
					dsTempVal[j] = "";
					if(dpExists(dsDpAttr[j]))
					{
						ret = dpGet(dsDpAttr[j], dsTempVal[j]);
					}
					else
					{
						fwException_raise(exceptionInfo, "WARNING",
										  "fwArchive_getMany(): Could not get the setting " + dsDpAttr[j] + ". Arch setting for the dpe will be flagged as none", "");
					}
					if(ret != 0)
						fwException_raise(exceptionInfo, "WARNING",
										  "fwArchive_getMany(): Could not get the setting " + dsDpAttr[j] + ". Arch setting for the dpe will be flagged as none", "");
				}
			}




			dynAppend(dsAttrVal, dsTempVal);
			dynClear(dsDpAttr);
			if(ret != 0)
			{
				fwException_raise(exceptionInfo, "ERROR",
								  "fwArchive_getMany(): Could not get the smoothing procedure for one or more dpes. See dpe list dump.", "");
				DebugTN(exceptionInfo, "Dpe list dump:", dsDpAttr);
				return;
			}
		}
	}

	//write the parameters to the return variables:
	k = 1;
	j = 1;
	for(i = 1 ; i <= length ; i++)
	{
		switch(dsTypesVal[i])
		{
			case DPCONFIG_DB_ARCHIVEINFO:
				configExists[i] = true;
				isActive[i] = dsAttrVal[k];
				k++;
				archiveType[i] = dsAttrVal[k];
				k++;
				archiveClass[i] = dsAttrVal[k];
				k++;
				smoothProcedure[i] = diTmpSmoothProcedure[j];
				deadband[i] = dfTmpDeadband[j];
				timeInterval[i] = dfTmpTimeInterval[j];
				fwArchive_convertDpNameToClassName(archiveClass[i], archiveClass[i], localException);
				if(dynlen(localException) > 0)
				{
					if(archiveClass != "")
					{
						fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
					}
				}
				j++;
				break;

			case DPCONFIG_NONE:
				configExists[i] = false;
				isActive[i] = 0;
				archiveType[i] = 0;
				archiveClass[i] = "";
				smoothProcedure[i] = 0;
				deadband[i] = 0;
				timeInterval[i] = 0;
				break;

			default:
				fwException_raise(exceptionInfo, "ERROR", "fwArchive_getMany(): Archive config type (" + dsTypesVal[i] + ") for dpe '" + dpes[i] + "' not suppported", "");
				break;
		}
	}

}

/** Returns details of the archive config on the given dp element
@param dpe		data point element
@param configExists		TRUE - archive config existing,
                   		FALSE - archive config is not existing
@param archiveClass	name of the archive class for the config (not archive class dp name)
@param archiveType	specifies whether archive smoothing is active (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband		archive deadband
@param timeInterval	archive time interval
@param isActive		TRUE if archiving of this dpe is active, else FALSE
@param exceptionInfo	details of any errors are returned here
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
fwArchive_get(string dpe, bool &configExists, string &archiveClass, int &archiveType, int &smoothProcedure, float &deadband,
              float &timeInterval, bool &isActive, dyn_string &exceptionInfo, int procedureIdx = 1)
{
	int configType;
	dyn_string localException;
	dyn_int diTmpSmoothProcedure;
	dyn_float dfTmpDeadband, dfTmpTimeInterval;

	configExists = FALSE;
	archiveClass = "";
	archiveType = 0;
	smoothProcedure = 0;
	deadband = 0;
	timeInterval = 0;
    isActive = FALSE;

	dpGet(dpe + ":_archive.._type", configType);

	switch(configType)
	{
		case DPCONFIG_DB_ARCHIVEINFO:
			configExists = TRUE;

			dpGet(	dpe + ":_archive.._archive", isActive,
					dpe + ":_archive." + (string)procedureIdx + "._type", archiveType,
					dpe + ":_archive." + (string)procedureIdx + "._class", archiveClass);

			_fwSmoothing_getParameters(dpe, TRUE, diTmpSmoothProcedure, dfTmpDeadband, dfTmpTimeInterval, exceptionInfo, procedureIdx);
			smoothProcedure = diTmpSmoothProcedure[1];
			deadband = dfTmpDeadband[1];
			timeInterval = dfTmpTimeInterval[1];

			if(strlen(archiveClass))
			{
				fwArchive_convertDpNameToClassName(archiveClass, archiveClass, localException);
			}
			if(dynlen(localException) > 0)
			{
				if(archiveClass != "")
				{
					fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
				}
			}
			break;

		case DPCONFIG_NONE:
			break;

		default:
			fwException_raise(exceptionInfo, "ERROR", "fwArchive_get(): Archive config type (" + configType + ") not suppported", "");
			break;
	}
}


/** Starts archiving for the given dp elements

@param dpes		list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_startMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_bool value;

	length = dynlen(dpes);
	for(i = 1; i <= length; i++)
	{
		dynAppend(value, TRUE);
	}

	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_ARCHIVE, value, exceptionInfo, ".._archive");
}


/** Starts archiving for the given dp element

@param dpe		data point element
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_start(string dpe, dyn_string &exceptionInfo)
{
	fwArchive_startMultiple(makeDynString(dpe), exceptionInfo);
}


/** Stops archiving for the given dp elements

@param dpes		list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_stopMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
    // because of ETM-1298 (DPEs wiped our from the ELEMENTS table in RDB,
    // if setting FALSE on the _archive.._archive that is already FALSE
    // we need to check before setting...

    int length = dynlen(dpes);

    dyn_string checkArchiveActiveDPEs;
    dyn_bool archiveActive;
    //for (int i=1;i<=length;i++) dynAppend(checkArchiveActiveDPEs,dpes[i]+":_archive.._archive");
    //dpGet(checkArchiveActiveDPEs, archiveActive);

    fwConfigs_dpGetMany(dpes, archiveActive, exceptionInfo, "_archive.._archive");
    if (dynlen(exceptionInfo)) return;

    // form a list of DPEs that actually need to be deactivate, then flush it all in one dpSet
    dyn_string archiveDeactivateDPEs;
    dyn_bool   archiveDeactivateFlags;
    for (int i=1;i<=length;i++) {
	if (archiveActive[i]) {
	    dynAppend(archiveDeactivateDPEs,dpes[i]);
	    dynAppend(archiveDeactivateFlags,false);
	}
    }

    if (dynlen(archiveDeactivateDPEs)) {
	_fwConfigs_setConfigTypeAttribute(archiveDeactivateDPEs, fwConfigs_PVSS_ARCHIVE, archiveDeactivateFlags, exceptionInfo, ".._archive");
    }

}


/** Stops archiving for the given dp element

@param dpe		data point element
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_stop(string dpe, dyn_string &exceptionInfo)
{
	fwArchive_stopMultiple(makeDynString(dpe), exceptionInfo);
}


/** Sets archive config for the given dp element
NOTE: This function requires the dp name of the archiving class.  It will not perform the search for the dp name from a given archive class name.
NOTE: This function does not check that the chosen archive class has enough free space, nor if the class has been deleted

@par Usage
	Internal

@param dpe			data point element
@param startArchive		true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType		specifies whether archive smoothing should be ebabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
*/
_fwArchive_set(string dpe, bool startArchive, string archiveClassDpName, int archiveType, int smoothProcedure, float deadband, float timeInterval, dyn_string &exceptionInfo)
{
	_fwArchive_setMany(makeDynString(dpe), startArchive, makeDynString(archiveClassDpName), makeDynInt(archiveType),
					   makeDynInt(smoothProcedure), makeDynFloat(deadband), makeDynFloat(timeInterval), exceptionInfo);
}

/** Sets archive config for the given dp elements
NOTE: This function requires the dp name of the archiving class.  It will not perform the search for the dp name from a given archive class name.
NOTE: This function does not check that the chosen archive class has enough free space, nor if the class has been deleted

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes			data point elements
@param startArchive		true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType		specifies whether archive smoothing should be ebabled (using @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedure		list of smoothing procedures; use constants declared in @ref fwArchiveConfig_Constants_Smoothing
@param deadband			archive deadband
@param timeInterval		archive time interval
@param exceptionInfo		details of any errors are returned here
@param configureOnly		(optional, default false); if set to true, the archiving will be started/stopped according to the startArchive parameter
				otherwise only configuration will be changed (e.g. for smoothing); for all DPEs that do not have the archiving
				configured, the value of startArchive parameter will be taken.
@param procedureIdx                  (optional, default 1) - archiving procedure index (detail in the archive config),
                                     should always be set to 1 unless NGA archiving is used.
*/
_fwArchive_setMany(dyn_string dpes, bool startArchive, dyn_string archiveClassDpName, dyn_int archiveType, dyn_int smoothProcedure,
                   dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool configureOnly = false, int procedureIdx = 1)
{
	int length, numberOfAttributes;
	string dpeSystem;
	dyn_errClass errors;
	dyn_string attributesToSet, smoothingDpes;
	dyn_anytype valuesToSet;
	dyn_int smoothingProcedures;
	dyn_float smoothingDeadbands, smoothingTimeIntervals;

	// Three-pass procedure
	// 1: check/create non-existing archive configs, and then configure alarm classes (also for existing ones)
	// 2: configure smoothing parameters
	// 3: enable/disable archiving as appropriate (on the configs that already exist at this step)
	//    this way we could act on _archive.1._archive bit, and avoid the race condition in RDB archive
	//    when adding/removing ELEMENTS


	length = dynlen(dpes);

	// check which DPEs already have a archive config
	dyn_string checkArchiveTypeDPEs;
	dyn_int arcTypes;

	fwConfigs_dpGetMany(dpes, arcTypes, exceptionInfo, "_archive.._type");
	if(dynlen(exceptionInfo))
     {
         return;
     }

     dyn_int numProcs;
     if(procedureIdx > 1)
     {
       fwConfigs_dpGetMany(dpes, numProcs, exceptionInfo, "_archive.._num_proc");
       if(dynlen(exceptionInfo))
       {
           return;
       }
     }

     dyn_int correctedGroupNumbers;

	for(int i = 1; i <= length; i++) {
	    if (arcTypes[i] == DPCONFIG_NONE) {
		// config does not exist yet; create it
		dynAppend(attributesToSet, dpes[i] + ":_archive.._type");
		dynAppend(valuesToSet, DPCONFIG_DB_ARCHIVEINFO);

		dynAppend(attributesToSet, dpes[i] + ":_archive.._archive");
		dynAppend(valuesToSet, startArchive);
	    }

         int changedDetail = procedureIdx;
         if(procedureIdx > 1)
         {
           if(procedureIdx > numProcs[i] + 1)
           {
             changedDetail = numProcs[i] + 1;
           }
         }
         correctedGroupNumbers[i] = changedDetail;

	    dpeSystem = dpSubStr(dpes[i], DPSUB_SYS);
	    if(strpos(archiveClassDpName[i], dpeSystem) != 0)
         {
           archiveClassDpName[i] = dpeSystem + archiveClassDpName[i];
         }

	    dynAppend(attributesToSet, dpes[i] + ":_archive." + (string)changedDetail + "._class");
	    dynAppend(valuesToSet, archiveClassDpName[i]);

	    dynAppend(attributesToSet, dpes[i] + ":_archive." + (string)changedDetail + "._type");
	    dynAppend(valuesToSet, archiveType[i]);

	    numberOfAttributes=dynlen(valuesToSet);
		if(archiveType[i] == DPATTR_ARCH_PROC_SIMPLESM)
		{
			dynAppend(smoothingDpes, dpes[i]);
			dynAppend(smoothingProcedures, smoothProcedure[i]);
			dynAppend(smoothingDeadbands, deadband[i]);
			dynAppend(smoothingTimeIntervals, timeInterval[i]);
		}

		if((numberOfAttributes > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
			dpSetWait(attributesToSet, valuesToSet);
			errors = getLastError();
			if(dynlen(errors) > 0)
			{
				throwError(errors);
				fwException_raise(exceptionInfo, "ERROR", "_fwArchive_setMany(): Could not create archiving configs", "");
			}
			dynClear(attributesToSet);
			dynClear(valuesToSet);
		}
	}

    _fwSmoothing_setParameters(smoothingDpes, TRUE, smoothingProcedures, smoothingDeadbands, smoothingTimeIntervals, exceptionInfo, true, correctedGroupNumbers);

    if (!configureOnly) {
	if (startArchive) fwArchive_startMultiple(dpes, exceptionInfo);
	else fwArchive_stopMultiple(dpes, exceptionInfo);
    }
}


/** Finds the _ValueArchive DP name corresponding to the given archive class name

@param archiveClassName		name of the archive class
@param archiveDpName		dp name of the archive class _ValueArchive data point is returned here
@param exceptionInfo		details of any errors are returned here
@param searchSystem		OPTIONAL PARAMETER - default value is "" (search local system)
				The system on which to perform the lookup of the archive class name
*/
fwArchive_convertClassNameToDpName(string archiveClassName, string &archiveDpName, dyn_string &exceptionInfo, string searchSystem = "")
{
	int i, length;
	string query, dpName;
	dyn_string localException;
	dyn_dyn_anytype queryResult;

	archiveDpName = "";

	if(searchSystem == "")
	{
		searchSystem = getSystemName();
	}

	if(strpos(searchSystem, ":") != (strlen(searchSystem) - 1))
	{
		searchSystem += ":";
	}

	if(strpos(archiveClassName, "RDB") == 0)
	{
		fwArchive_convertRDBClassNameToDpName(archiveClassName, archiveDpName, localException, searchSystem);
	}

     if(strpos(archiveClassName, "NGA") == 0)
     {
         fwArchive_convertNGAClassNameToDpName(archiveClassName, archiveDpName, localException, searchSystem);
     }

	if(archiveDpName != "")
	{
		if(dynlen(localException) > 0)
		{
			fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
		}
		return;
	}

	query = "SELECT '.general.arName:_online.._value', '.state:_online.._value' FROM '*' REMOTE '" + searchSystem + "' WHERE _DPT = \""
			+ fwArchive_VALARCH_CLASS_DPTYPE + "\" AND '.general.arName:_online.._value' LIKE \""
			+ archiveClassName + "\"" + " AND '.state:_online.._value' != " + fwArchive_CLASS_DELETED;

	dpQuery(query, queryResult);

	for(i = 2; i <= dynlen(queryResult); i++)
	{
		if(isReduDp(queryResult[i][1]))
		{
			dynRemove(queryResult, i);
			i--;
		}
	}

	length = dynlen(queryResult);
	if(length > 2)
	{
		fwException_raise(exceptionInfo, "WARNING", "Could not determine a unique Archive Class data point name.", "");
	}
	else if(length < 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "Could not find an Archive Class data point for the class \"" + archiveClassName +  "\".", "");
		return;
	}

	archiveDpName = queryResult[2][1];
}

/** Finds the archive class name corresponding to the given _ValueArchive DP

@param archiveDpName		dp name of the archive class _ValueArchive data point
@param archiveClassName		name of the archive class is returned here
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_convertDpNameToClassName(string archiveDpName, string &archiveClassName, dyn_string &exceptionInfo)
{
	dyn_string localException;

          archiveClassName = "";
	if(archiveDpName == "")
	{
		return;
          }

	if(dpTypeName(archiveDpName) == "_RDBArchiveGroups")
	{
		fwArchive_convertDpNameToRDBClassName(archiveDpName, archiveClassName, localException);
	}
           if(dpTypeName(archiveDpName) == "_NGA_Group")
           {
                fwArchive_convertDpNameToNGAClassName(archiveDpName, archiveClassName, localException);
           }
	if(archiveClassName != "")
	{
		if(dynlen(localException) > 0)
		{
			fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
		}
		return;
	}

	if(dpExists(archiveDpName + ".general.arName"))
	{
		dpGet(archiveDpName + ".general.arName", archiveClassName);
	}
	else
	{
		archiveClassName = "";
		fwException_raise(exceptionInfo, "ERROR",
						  "fwArchive_convertDpNameToClassName(): Archive class not found for dp " + archiveDpName, "");
	}
}


/** Checks the given archive class to ensure the class has not been deleted and has enough free
space to configure a given number of archiving configs

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName	dp name of the archive class _ValueArchive data point to check
@param dpesToAdd		a list of data point elements you wish to configure with the given class
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_checkClass(string archiveClassDpName, const dyn_string &dpesToAdd, dyn_string &exceptionInfo)
{
	dyn_bool areArchived;
	int state, freeSpace, numberOfDpesToAdd;
	string stateText;

	numberOfDpesToAdd = dynlen(dpesToAdd);

	fwArchive_getClassState(archiveClassDpName, state, stateText, exceptionInfo);
	if(dynlen(exceptionInfo) > 0)
	{
		return;
	}

	if(state == fwArchive_CLASS_DELETED)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwArchive_checkClass: Archive Class (" + archiveClassDpName + ") has been deleted", "");
		return;
	}

	fwArchive_getClassFreeSpace(archiveClassDpName, freeSpace, exceptionInfo);
	if(dynlen(exceptionInfo) > 0)
	{
		return;
	}

	if(freeSpace < numberOfDpesToAdd)
	{
		fwArchive_checkDpesArchived(archiveClassDpName, dpesToAdd, areArchived, exceptionInfo);
		if(dynContains(areArchived, FALSE))
		{
			fwException_raise(exceptionInfo, "ERROR", "fwArchive_checkClass: Archive Class (" + archiveClassDpName + ") does not have enough free space", "");
			return;
		}
	}
}


/** Gets the state of the given archive class

@param archiveClassDpName	dp name of the archive class _ValueArchive data point to check
@param archiveState		the archive state is returned here
					fwArchive_CLASS_STOPPED		= Archive manager not running
					fwArchive_CLASS_ONLINE		= Archive manager running
					fwArchive_CLASS_SWAPPED_OUT	= Archive is currently swapped out
					fwArchive_CLASS_DELETED		= Archive has been deleted
@param archiveStateText		a text representation of the state is returned here
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_getClassState(string archiveClassDpName, int &archiveState, string &archiveStateText, dyn_string &exceptionInfo)
{
	archiveClassDpName = fwInstallationRedu_getLocalDp(archiveClassDpName);
	if(dpExists(archiveClassDpName + ".state"))
	{
		dpGet(archiveClassDpName + ".state", archiveState);

		switch(archiveState)
		{
			case fwArchive_CLASS_STOPPED:
				archiveStateText = "Stopped";
				break;
			case fwArchive_CLASS_ONLINE:
				archiveStateText = "Online";
				break;
			case fwArchive_CLASS_SWAPPED_OUT:
				archiveStateText = "Swapped Out";
				break;
			case fwArchive_CLASS_DELETED:
				archiveStateText = "Deleted";
				break;
			default:
				archiveStateText = "Unknown";
				break;
		}
	}
	else
	{
		archiveState = 0;
		archiveStateText = "";
		fwException_raise(exceptionInfo, "ERROR",
						  "fwArchive_getClassState(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}

/** Gets the statistics of the given archive class

@param archiveClassDpName	dp name of the archive class _ValueArchive data point to check
@param currentDpes		the number of dpes currently in the archive is returned here
@param dpesAfterFileSwitch	the number of dpes that will be in the archive after a file switch is returned here
@param maximumDpes		the maximum number of dpes for this class is returned here
@param exceptionInfo		details of any errors are returned here
@param refreshClass		Optional parameter.  Default value TRUE.
					If TRUE, force class to refresh statistics before getting values (maybe slow)
					If FALSE, get current values which may be out of date
*/
fwArchive_getClassStatistics(string archiveClassDpName, int &currentDpes, int &dpesAfterFileSwitch,
					   int &maximumDpes, dyn_string &exceptionInfo, bool refreshClass = TRUE)
{
	int i = 0, currentNumber, state;
	dyn_string ds;
	string stateText;
	//gt the local dp (if redundant system, might be dp or dp_2)
	archiveClassDpName = fwInstallationRedu_getLocalDp(archiveClassDpName);
	fwArchive_getClassState(archiveClassDpName, state, stateText, exceptionInfo);
	if(state == fwArchive_CLASS_STOPPED)
	{
		refreshClass = FALSE;
		fwException_raise(exceptionInfo, "WARNING",
						  "fwArchive_getClassStatistics(): Archive manager is stopped.  Could not update class statistics.", "");
	}

	if(dpExists(archiveClassDpName + ".statistics.dpElements"))
	{
		if(refreshClass)
		{
			fwArchive_REFRESH_IN_PROGRESS = FALSE;
			dpConnect("_fwArchive_flagEndOfRefresh", FALSE, archiveClassDpName + ".statistics.dpElements:_online.._stime");

			dpGet(archiveClassDpName + ".files.fileName", ds);
			dpSet(archiveClassDpName + ".statistics.index", dynlen(ds));

			for(i = 0; (i <= 100) && (fwArchive_REFRESH_IN_PROGRESS == FALSE); i++)
			{
				delay(0, 100);
			}

			if(i >= 100)
			{
				fwException_raise(exceptionInfo, "WARNING",
								  "fwArchive_getClassStatistics(): Update of archive items timed out.  Statistics may not be up to date.", "");
			}
		}

		dpGet(archiveClassDpName + ".statistics.dpValues", ds,
			  archiveClassDpName + ".size.maxDpElGet", maximumDpes,
			  archiveClassDpName + ".statistics.dpElementCount", currentDpes);

		dpesAfterFileSwitch = dynlen(ds);
	}
	else
	{
		//freeSpace = 0;
		fwException_raise(exceptionInfo, "ERROR",
						  "fwArchive_getClassStatistics(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}


/** Gets the amount of additional data point elements that can be added to a given archive class
The value returned is based on the number of dpes in the archive currently, not the number after the next file switch

@param archiveClassDpName	dp name of the archive class _ValueArchive data point to check
@param freeSpace		the number of dpes that can be added to the archive is returned here
@param exceptionInfo		details of any errors are returned here
@param refreshClass		Optional parameter.  Default value TRUE.
					If TRUE, force class to refresh statistics before getting values (maybe slow)
					If FALSE, get current values which may be out of date
*/
fwArchive_getClassFreeSpace(string archiveClassDpName, int &freeSpace, dyn_string &exceptionInfo, bool refreshClass = TRUE)
{
	int currentNumber, afterFileSwitchNumber, maxSize;

	fwArchive_getClassStatistics(archiveClassDpName, currentNumber, afterFileSwitchNumber, maxSize, exceptionInfo, refreshClass);

	freeSpace = maxSize - currentNumber;
}


/** This function can be used to check if a given list of dpes are correctly configured to be archived by a given archive manager.
Sometimes, if an archive class is full and more data point elements are added without checking for errors, the additional data points
are not added to the archive class (even though the config appears correct) and only a log messages indicates this failure.
This function can be used to check that the data point elements are really going to be archived.


@param archiveClassDpName	dp name of the archive class _ValueArchive data point to check
@param dpesToCheck		the list of dpes that you wish to check are correctly configured for the given archive class
@param areArchived		list of booleans relating to dpes in dpesToCheck.  TRUE = archived, FALSE = not archived
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_checkDpesArchived(string archiveClassDpName, dyn_string dpesToCheck, dyn_bool &areArchived, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string currentDpes;
	//gt the local dp (if redundant system, might be dp or dp_2)
	archiveClassDpName = fwInstallationRedu_getLocalDp(archiveClassDpName);
	if(dpExists(archiveClassDpName + ".statistics.dpElements"))
	{
		dpGet(archiveClassDpName + ".statistics.dpElements", currentDpes);

		length = dynlen(dpesToCheck);
		for(i = 1; i <= length; i++)
		{
			dpesToCheck[i] = dpSubStr(dpesToCheck[i], DPSUB_SYS) + dpSubStr(dpesToCheck[i], DPSUB_DP_EL);
			areArchived[i] = (dynContains(currentDpes, dpesToCheck[i]) > 0);
		}
	}
	else
	{
		dynClear(areArchived);
		fwException_raise(exceptionInfo, "ERROR",
						  "fwArchive_checkDpesArchived(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}


/** Work function used to flag the end of a refresh of the archive class statistics

@par Usage
	Internal

@param dpe	name of the data point element connected to (archiveClassDpName + ".statistics.dpElements:_online.._stime")
@param value	the time of the latest update of the datapoint element connected to
*/
_fwArchive_flagEndOfRefresh(string dpe, anytype value)
{
	string dpName;

	fwArchive_REFRESH_IN_PROGRESS = TRUE;

	dpName = dpSubStr(dpe, DPSUB_SYS_DP);
	dpDisconnect("_fwArchive_flagEndOfRefresh", dpName + ".statistics.dpElements:_online.._stime");
}


/** Finds the RDB archive class name corresponding to the given _RDBArchiveGroups DP

The default RDB Archive class is called "RDB-99) EVENT"

@param rdbArchiveGroupDpName	dp name of the RDB archive group _RDBArchiveGroups data point
@param rdbClassName		name of the archive class is returned here
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_convertDpNameToRDBClassName(string rdbArchiveGroupDpName, string &rdbClassName, dyn_string &exceptionInfo)
{
	bool isAlert;
	int managerNumber;
	string className;
	dyn_string rdbDpTypes;

	rdbClassName = "";

	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	}

	if(!dpExists(rdbArchiveGroupDpName))
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + rdbArchiveGroupDpName + "\" does not exist.", "");
		return;
	}

	if(dpTypeName(rdbArchiveGroupDpName) != fwArchive_RDB_CLASS_DPTYPE)
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + rdbArchiveGroupDpName + "\" is not of type \"" + fwArchive_RDB_CLASS_DPTYPE + "\".", "");
		return;
	}

	dpGet(rdbArchiveGroupDpName + ".isAlert", isAlert,
		  rdbArchiveGroupDpName + ".managerNr", managerNumber,
		  rdbArchiveGroupDpName + ".groupName", className);

	rdbClassName = "RDB-" + (managerNumber + fwArchive_MANAGER_NUMBER_OFFSET) + ") " + className;

	if(isAlert)
	{
		fwException_raise(exceptionInfo, "WARNING", "The data point \"" + rdbArchiveGroupDpName + "\" is an alert archiving group.", "");
	}
}


/** Finds the _RDBArchiveGroups DP name corresponding to the given RDB archive class name

@par Constraints
	Only works for RDB archiving classes - not traditional _ValueArchive classes
	The RDB archive class name must be given as displayed in the PVSS panels - e.g.  RDB-XX) GroupName

@param rdbClassName		name of the RDB archive class
@param rdbArchiveGroupDpName	dp name of the RDB archive group _RDBArchiveGroups data point is returned here
@param exceptionInfo		details of any errors are returned here
@param searchSystem		OPTIONAL PARAMETER - default value is "" (search local system)
					The system on which to perform the lookup of the archive class name
*/
fwArchive_convertRDBClassNameToDpName(string rdbClassName, string &rdbArchiveGroupDpName, dyn_string &exceptionInfo, string searchSystem = "")
{
	bool isAlert;
	int pos1, pos2, managerNumber, length;
	string query, className;
	dyn_string rdbDpTypes;
	dyn_dyn_anytype queryResult;

	rdbArchiveGroupDpName = "";

	if(searchSystem == "")
	{
		searchSystem = getSystemName();
	}

	if(strpos(searchSystem, ":") != (strlen(searchSystem) - 1))
	{
		searchSystem += ":";
	}

	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	}

	if(rdbClassName == "")
	{
		fwException_raise(exceptionInfo, "ERROR", "You must specify an RDB archive class name.", "");
		return;
	}

	pos1 = strpos(rdbClassName, " ");
	if(pos1 == 7) //expected place of space in the string
	{
		className = substr(rdbClassName, pos1 + 1);
	}
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class must be in the form \"RDB-XX) GroupName\".", "");
		return;
	}

	pos1 = strpos(rdbClassName, "-");
	pos2 = strpos(rdbClassName, ")");
	if((pos1 == 3) && (pos2 == 6)) //expected pos of - and ) in the string
	{
		managerNumber = (int)substr(rdbClassName, pos1 + 1, pos2 + 1);
	}
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class must be in the form \"RDB-XX) GroupName\".", "");
		return;
	}

	managerNumber -= fwArchive_MANAGER_NUMBER_OFFSET;

	query = "SELECT '.managerNr:_online.._value', '.groupName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '"
			+ searchSystem + "' WHERE _DPT = \"" + fwArchive_RDB_CLASS_DPTYPE
			+ "\" AND '.managerNr:_online.._value' == " + managerNumber
			+ " AND '.groupName:_online.._value' == \"" + className + "\"";

	dpQuery(query, queryResult);

	length = dynlen(queryResult);
	if(length > 2)
	{
		fwException_raise(exceptionInfo, "WARNING", "Could not determine a unique RDB Archive Group data point name.", "");
	}
	else if(length < 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class \"" + rdbClassName +  "\" does not exist.", "");
		return;
	}

	rdbArchiveGroupDpName = queryResult[2][1];
	isAlert = queryResult[2][4];
	if(isAlert)
	{
		fwException_raise(exceptionInfo, "WARNING", "The RDB class \"" + rdbClassName + "\" is an alert archiving group.", "");
	}
}


/** Finds all the NOT DELETED Value Archive classes and
		returns the class names (for display) and the class dps (for writing to the config)

@par PVSS managers
	VISION, CTRL

@param readFromSystems		The systems to read from - the list of classes returned is only those classes
				that are available on every one of the named systems
@param archiveClasses		The list of archive class names is returned here
@param archiveClassDps		The list of _ValueArchive data point names is returned here
@param exceptionInfo		Details of any errors are returned here
*/
fwArchive_getAllValueArchiveClasses(dyn_string readFromSystems, dyn_string &archiveClasses, dyn_string &archiveClassDps, dyn_string &exceptionInfo)
{
	int i, j, numberOfResults, length;
	string query;
	dyn_dyn_anytype queryResult;
	dyn_dyn_string allClasses, allDps;

	archiveClasses = makeDynString();
	archiveClassDps = makeDynString();

	length = dynlen(readFromSystems);
	if(length == 0)
	{
		length = dynAppend(readFromSystems, getSystemName());
	}

	for(i = 1; i <= length; i++)
	{
		allDps[i] = makeDynString();
		allClasses[i] = makeDynString();

		if(strpos(readFromSystems[i], ":") != (strlen(readFromSystems[i]) - 1))
		{
			readFromSystems[i] += ":";
		}

		if(dynlen(dpNames(readFromSystems[i] + "*", fwArchive_VALARCH_CLASS_DPTYPE)) == 0)
		{
			continue;
		}

		query = "SELECT '.general.arName:_online.._value', '.state:_online.._value' FROM '*' REMOTE '"
				+ readFromSystems[i] + "' WHERE _DPT = \""
				+ fwArchive_VALARCH_CLASS_DPTYPE + "\" AND '.state:_online.._value' != " + fwArchive_CLASS_DELETED;

		dpQuery(query, queryResult);

		numberOfResults = dynlen(queryResult);
		for(j = 2; j <= numberOfResults; j++)
		{
			if(!isReduDp(queryResult[j][1]))
			{
				if(length == 1)
				{
					dynAppend(allDps[i], queryResult[j][1]);
				}
				else
				{
					dynAppend(allDps[i], dpSubStr(queryResult[j][1], DPSUB_DP));
				}

				dynAppend(allClasses[i], queryResult[j][2]);
			}
		}
	}

	for(i = 2; i <= length; i++)
	{
		allDps[1] = dynIntersect(allDps[1], allDps[i]);
		allClasses[1] = dynIntersect(allClasses[1], allClasses[i]);
	}

	archiveClasses = allClasses[1];
	archiveClassDps = allDps[1];
}


/** Finds all the RDB Archiving Group classes and
		returns the class names (for display) and the group dps (for writing to the config)

@par PVSS managers
	VISION, CTRL

@param readFromSystems		The systems to read from - the list of classes returned is only those classes
				that are available on every one of the named systems
@param archiveClasses		The list of RDB archive group names is returned here
@param archiveGroupDps		The list of _RDBArchiveGroups data point names is returned here
@param exceptionInfo		Details of any errors are returned here
@param includeAlertGroups	OPTIONAL PARAMETER - default value = FALSE
					If set to FALSE, only EVENT archive groups are returned
					If set to TRUE, both EVENT and ALERT archive groups are returned
*/
fwArchive_getAllRDBArchiveClasses(dyn_string readFromSystems, dyn_string &archiveClasses, dyn_string &archiveGroupDps, dyn_string &exceptionInfo, bool includeAlertGroups = FALSE)
{
	int i, j, numberOfResults, length;
	string query;
	dyn_string rdbDpTypes;
	dyn_dyn_anytype queryResult;
	dyn_dyn_string allClasses, allDps;

	archiveClasses = makeDynString();
	archiveGroupDps = makeDynString();

	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	}

	length = dynlen(readFromSystems);
	if(length == 0)
	{
		length = dynAppend(readFromSystems, getSystemName());
	}

	for(i = 1; i <= length; i++)
	{
		allDps[i] = makeDynString();
		allClasses[i] = makeDynString();

		if(strpos(readFromSystems[i], ":") != (strlen(readFromSystems[i]) - 1))
		{
			readFromSystems[i] += ":";
		}

		if(dynlen(dpNames(readFromSystems[i] + "*", fwArchive_RDB_CLASS_DPTYPE)) == 0)
		{
			continue;
		}

		query = "SELECT '.managerNr:_online.._value', '.groupName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '"
				+ readFromSystems[i] + "' WHERE _DPT = \""
				+ fwArchive_RDB_CLASS_DPTYPE + "\"";

		if(!includeAlertGroups)
		{
			query += " AND '.isAlert:_online.._value' == 0";
		}

		dpQuery(query, queryResult);

		numberOfResults = dynlen(queryResult);
		for(j = 2; j <= numberOfResults; j++)
		{
			if(length == 1)
			{
				dynAppend(allDps[i], queryResult[j][1]);
			}
			else
			{
				dynAppend(allDps[i], dpSubStr(queryResult[j][1], DPSUB_DP));
			}

			dynAppend(allClasses[i], "RDB-" + (queryResult[j][2] + fwArchive_MANAGER_NUMBER_OFFSET) + ") " + queryResult[j][3]);
		}
	}

	for(i = 2; i <= length; i++)
	{
		allDps[1] = dynIntersect(allDps[1], allDps[i]);
		allClasses[1] = dynIntersect(allClasses[1], allClasses[i]);
	}

	archiveClasses = allClasses[1];
	archiveGroupDps = allDps[1];
}

/** Checks if the NGA is enabled in the local system

@return true if the NGA is enabled, false otherwise
*/
bool fwArchive_useNGA()
{
  if(isFunctionDefined("useNGA")) {
    return useNGA();
  } else {
    return false;
  }
}

/** Checks if a system uses the NGA

@param sysName   name of the system to check
@return          true if the system uses the NGA, false otherwise
*/
bool fwArchive_checkIfSystemUsesNGA(string sysName, dyn_string &exceptionInfo)
{
  if (strpos(sysName, ":") != (strlen(sysName) - 1)) {
    sysName += ":";
  }

  const string usesNgaDpe = sysName + "_DataManager.UseNextGenArch";
  const bool sysUses316 = !dpExists(usesNgaDpe);
  if (sysUses316) {
    return _fwArchive_checkIf316SystemUsesNGA(sysName, exceptionInfo);
  } else {
    bool usesNgaVal;
    try {
      dpGet(usesNgaDpe, usesNgaVal);
      FwException::checkLastError();
      return usesNgaVal;
    } catch {
      FwException::bridge(exceptionInfo);
      return false;
    }
  }
}

/** Checks if a system uses the NGA - implementation for earlier WinCC OA versions (3.16)
  that do not have the _DataManager.UseNextGenArch DPE.

@param sysName   name of the system to check
@return          true if the system uses the NGA, false otherwise
*/
bool _fwArchive_checkIf316SystemUsesNGA(string sysName, dyn_string &exceptionInfo)
{
  const string ngaIdp = sysName + "_NGA";
  if (!dpExists(ngaIdp)) {
    return false;
  }

  const string dpeToCheck = sysName + "_Event.Heartbeat";
  if (dpElementType(dpeToCheck) == -1) {
   fwException_raise(exceptionInfo, "ERROR", "Could not access the " + dpeToCheck + " DPE", "");
    return false;
  }

  anytype proc, numProc;
  dpGet(dpeToCheck + ":_archive.._num_proc", numProc,
        dpeToCheck + ":_archive.._proc", proc);
  if (getType(proc) == ANYTYPE_VAR &&
      getType(numProc) == ANYTYPE_VAR) {
    return false;
  } else {
    return true;
  }
}

/** Checks if systems uses the same type of archiving (NGA or RDB/VALARCH) based on how they handle _archive configs and presence of
  _NGA internal datapoint

@param sysNames       names of the systems to check
@param sysUsesNga     true if the corresponding system uses the NGA, false otherwise
@return               true if all the systems uses the same type of archiving, false otherwise
*/
bool _fwArchive_checkIfSameArchivingIsUsed(const dyn_string &sysNames, dyn_bool &sysUsesNga, dyn_string &exceptionInfo)
{
  dynClear(sysUsesNga);

  bool lastSysUsedNga = false;
  for (int sysIdx = 1; sysIdx <= dynlen(sysNames); sysIdx++) {
    bool thisSysUsesNga = fwArchive_checkIfSystemUsesNGA(sysNames[sysIdx], exceptionInfo);
    if (dynlen(exceptionInfo) > 0) {
      return false;
    }
    sysUsesNga[sysIdx] = thisSysUsesNga;

    if ((thisSysUsesNga != lastSysUsedNga) && sysIdx > 1) {
      return false;
    }
    lastSysUsedNga = thisSysUsesNga;
  }

  return true;
}



/** Finds all the NGA Archiving Group classes and returns the class names (for display) and the group dps (for writing to the config)

@param readFromSystems		The systems to read from - the list of classes returned is only those classes
				that are available on every one of the named systems
@param archiveClasses		The list of NGA archive group names is returned here
@param archiveGroupDps		The list of _NGA_Group data point names is returned here
@param exceptionInfo		Details of any errors are returned here
@param includeAlertGroups	OPTIONAL PARAMETER - default value = FALSE
					If set to FALSE, only EVENT archive groups are returned
					If set to TRUE, both EVENT and ALERT archive groups are returned
*/
fwArchive_getAllNGAArchiveClasses(dyn_string readFromSystems, dyn_string &archiveClasses, dyn_string &archiveGroupDps, dyn_string &exceptionInfo, bool includeAlertGroups = FALSE)
{
	dyn_dyn_string allClasses, allDps;

	archiveClasses = makeDynString();
	archiveGroupDps = makeDynString();

	int length = dynlen(readFromSystems);
	if(length == 0)
	{
		length = dynAppend(readFromSystems, getSystemName());
	}

	for(int i = 1; i <= length; i++)
	{
		allDps[i] = makeDynString();
		allClasses[i] = makeDynString();

		if(strpos(readFromSystems[i], ":") != (strlen(readFromSystems[i]) - 1))
		{
			readFromSystems[i] += ":";
		}

                     dyn_string ngaDpTypesInSystem = dpTypes(fwArchive_NGA_CLASS_DPTYPE, getSystemId(readFromSystems[i]));
              	if(dynlen(ngaDpTypesInSystem) <= 0)
              	{
              		continue;
              	}

		if(dynlen(dpNames(readFromSystems[i] + "*", fwArchive_NGA_CLASS_DPTYPE)) == 0)
		{
			continue;
		}

		string query = "SELECT '.displayName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '"
				+ readFromSystems[i] + "' WHERE _DPT = \""
				+ fwArchive_NGA_CLASS_DPTYPE + "\" AND _DP NOT LIKE \"*_2\"";

		if(!includeAlertGroups)
		{
			query += " AND '.isAlert:_online.._value' == 0";
		}

                         dyn_dyn_anytype queryResult;
		dpQuery(query, queryResult);

		int numberOfResults = dynlen(queryResult);
		for(int j = 2; j <= numberOfResults; j++)
		{
			if (!isReduDp(queryResult[j][1]))
			{
				if(length == 1)
				{
					dynAppend(allDps[i], queryResult[j][1]);
				}
				else
				{
					dynAppend(allDps[i], dpSubStr(queryResult[j][1], DPSUB_DP));
				}

				dynAppend(allClasses[i], "NGA) " + queryResult[j][2]);
			}
		}
	}

	for(int i = 2; i <= length; i++)
	{
		allDps[1] = dynIntersect(allDps[1], allDps[i]);
		allClasses[1] = dynIntersect(allClasses[1], allClasses[i]);
	}

	archiveClasses = allClasses[1];
	archiveGroupDps = allDps[1];
}

/** Finds the NGA archive class name corresponding to the given _NGA_Group DP

@param ngaArchiveGroupDpName	dp name of the NGA archive group _NGA_Group data point
@param ngaClassName		name of the archive class is returned here
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_convertDpNameToNGAClassName(string ngaArchiveGroupDpName, string &ngaClassName, dyn_string &exceptionInfo)
{
	bool isAlert;
	int managerNumber;
	string className;
	dyn_string ngaDpTypes;

	ngaClassName = "";

           string sysName = dpSubStr(ngaArchiveGroupDpName, DPSUB_SYS);
	dyn_string ngaDpTypes = dpTypes(fwArchive_NGA_CLASS_DPTYPE, getSystemId(sysName));
	if(dynlen(ngaDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The NGA Archive Group data point type does not exist.", "");
		return;
	}

	if(!dpExists(ngaArchiveGroupDpName))
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + ngaArchiveGroupDpName + "\" does not exist.", "");
		return;
	}

	if(dpTypeName(ngaArchiveGroupDpName) != fwArchive_NGA_CLASS_DPTYPE)
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + ngaArchiveGroupDpName + "\" is not of type \"" + fwArchive_NGA_CLASS_DPTYPE + "\".", "");
		return;
	}

	dpGet(ngaArchiveGroupDpName + ".isAlert", isAlert,
		 ngaArchiveGroupDpName + ".displayName", className);

	ngaClassName = "NGA) " + className;

	if(isAlert)
	{
		fwException_raise(exceptionInfo, "WARNING", "The data point \"" + ngaArchiveGroupDpName + "\" is an alert archiving group.", "");
	}
}


/** Finds the _NGA_Group DP name corresponding to the given NGA archive class name

@par Constraints
	Only works for NGA archiving classes - not traditional Value Archive or RDB Archive classes
	The NGA archive class name must be given as displayed in the PVSS panels - e.g.  NGA) GroupName

@param ngaClassName		name of the NGA archive class
@param ngaArchiveGroupDpName	dp name of the NGA archive group _NGA_Group data point is returned here
@param exceptionInfo		details of any errors are returned here
@param searchSystem		OPTIONAL PARAMETER - default value is "" (search local system)
			The system on which to perform the lookup of the archive class name
*/
fwArchive_convertNGAClassNameToDpName(string ngaClassName, string &ngaArchiveGroupDpName, dyn_string &exceptionInfo, string searchSystem = "")
{
	bool isAlert;
	int pos1, pos2, length;
	string query, className;
	dyn_string ngaDpTypes;
	dyn_dyn_anytype queryResult;

	ngaArchiveGroupDpName = "";

	if(searchSystem == "")
	{
		searchSystem = getSystemName();
	}

	if(strpos(searchSystem, ":") != (strlen(searchSystem) - 1))
	{
		searchSystem += ":";
	}

	ngaDpTypes = dpTypes(fwArchive_NGA_CLASS_DPTYPE, getSystemId(searchSystem));
	if(dynlen(ngaDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The NGA Archive Group data point type does not exist.", "");
		return;
	}

	if(ngaClassName == "")
	{
		fwException_raise(exceptionInfo, "ERROR", "You must specify an NGA archive class name.", "");
		return;
	}

	pos1 = strpos(ngaClassName, " ");
	if(pos1 == 4) //expected place of space in the string
	{
		className = substr(ngaClassName, pos1 + 1);
	}
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "The NGA Class must be in the form \"NGA) GroupName\".", "");
		return;
	}

	query = "SELECT '.displayName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '"
			+ searchSystem + "' WHERE _DPT = \"" + fwArchive_NGA_CLASS_DPTYPE + "\"" +
			+ " AND '.displayName:_online.._value' == \"" + className + "\" AND _DP NOT LIKE \"*_2\"";

	dpQuery(query, queryResult);

	for(int i = 2; i <= dynlen(queryResult); i++)
	{
		if(isReduDp(queryResult[i][1]))
		{
			dynRemove(queryResult, i);
			i--;
		}
	}

	length = dynlen(queryResult);
	if(length > 2)
	{
		fwException_raise(exceptionInfo, "WARNING", "Could not determine a unique NGA Archive Group data point name.", "");
	}
	else if(length < 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "The NGA Class \"" + ngaClassName +  "\" does not exist.", "");
		return;
	}

	ngaArchiveGroupDpName = queryResult[2][1];
	isAlert = queryResult[2][3];
	if(isAlert)
	{
		fwException_raise(exceptionInfo, "WARNING", "The NGA class \"" + ngaClassName + "\" is an alert archiving group.", "");
	}
}


/** Returns the NGA archive class name from displayed name (prefixed with "NGA) ")

@param ngaClassName        displayed archive class name
@return                    archive class name without the NGA) prefix
*/
string _fwArchive_convertNGAClassNameToInternalName(const string &ngaClassName)
{
  const int prefixLen = 4;
  return substr(ngaClassName, prefixLen + 1);
}


/** Checks if the displayed archive class name is prefixed with "NGA) "

@param archClassName        displayed archive class name
@return                     true if "NGA) " prefix is present, false otherwise
*/
bool _fwArchive_isArchiveClassNameNga(const string &archClassName)
{
  return (strpos(archClassName, "NGA) ") == 0);
}


/** Returns the numbers of archiving procedures for passed DPEs.
  Note: the function will fail if any of the passed DPEs does not have an _archive config.

@param dpes                   DPEs to check
@param numbersOfProcedures    numbers of configured archiving procedures for DPEs are returned here
@param exceptionInfo          details of errors are returned here
*/
_fwArchive_getNumberOfArchivingProcedures(const dyn_string &dpes, dyn_int &numbersOfProcedures, dyn_string &exceptionInfo)
{
  numbersOfProcedures = makeDynInt();
  fwConfigs_dpGetMany(dpes, numbersOfProcedures, exceptionInfo, "_archive.._num_proc");
  if (dynlen(exceptionInfo) > 0) {
    return;
  }
}


/** Checks if archive configs are present for passed DPEs

@param dpes                   DPEs to check
@param configsPresent         config presences for DPEs are returned here
@param exceptionInfo          details of errors are returned here
*/
_fwArchive_getDpeArchiveConfigsPresent(const dyn_string &dpes, dyn_bool &configsPresent, dyn_string &exceptionInfo)
{
  configsPresent = makeDynBool();
  fwConfigs_dpGetMany(dpes, configsPresent, exceptionInfo, "_archive.._type");
  if (dynlen(exceptionInfo) > 0) {
    return;
  }
}


/** Checks if archive configs are active for passed DPEs

@param dpes                   DPEs to check
@param configsEnabled         config active states for DPEs are returned here
@param exceptionInfo          details of errors are returned here
*/
_fwArchive_getDpeArchiveConfigsEnabled(const dyn_string &dpes, dyn_bool &configsEnabled, dyn_string &exceptionInfo)
{
  configsEnabled = makeDynBool();
  fwConfigs_dpGetMany(dpes, configsEnabled, exceptionInfo, "_archive.._archive");
  if (dynlen(exceptionInfo) > 0) {
    return;
  }
}

/** Checks if archive configs for passed DPEs exist, are active and their number of archiving procedures,
    depending on the mode selected

@param dpes                   DPEs to check
@param configExists           true if an archive config exists
@param configActive           true if the config is active
@param procNumber             number of configured archive procedures
@param getActive              if true, it is checked if configs are active (otherwise configActive is filled with false)
@param getProcNumber          if true, archiving procedure numbers are retrieved (otherwise procNumber is filled with 0s)
@param exceptionInfo          details of errors are returned here
*/
_fwArchive_getDpeArchivingConfiguredActiveProcedureNumbers(const dyn_string &dpes, dyn_int &configExists, dyn_bool &configActive, dyn_int &procNumber,
                                                           bool getActive, bool getProcNumber, dyn_string &exceptionInfo)
{
  dynClear(configExists);
  dynClear(configActive);
  dynClear(procNumber);

  _fwArchive_getDpeArchiveConfigsPresent(dpes, configExists, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_string dpesWithArchiveConfigs;
  dyn_int idxsOfDpesWithArchiveConfigs;
  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    if (configExists[dpeIdx]) {
      dynAppend(dpesWithArchiveConfigs, dpes[dpeIdx]);
      dynAppend(idxsOfDpesWithArchiveConfigs, dpeIdx);
    }
  }

  dyn_bool tempConfigActive;
  if (getActive) {
    _fwArchive_getDpeArchiveConfigsEnabled(dpesWithArchiveConfigs, tempConfigActive, exceptionInfo);
    if (dynlen(exceptionInfo) > 0) {
      return;
    }
  }

  dyn_int tempNumbersOfProcedures;
  if (getProcNumber) {
    _fwArchive_getNumberOfArchivingProcedures(dpesWithArchiveConfigs, tempNumbersOfProcedures, exceptionInfo);
    if (dynlen(exceptionInfo) > 0) {
      return;
    }
  }

  if (getActive) {
    configActive[dpesLen] = false;
  }
  if (getProcNumber) {
    procNumber[dpesLen] = 0;
  }
  for (int i = 1; i <= dynlen(idxsOfDpesWithArchiveConfigs); i++) {
    if (getActive) {
      configActive[idxsOfDpesWithArchiveConfigs[i]] = tempConfigActive[i];
    }
    if (getProcNumber) {
      procNumber[idxsOfDpesWithArchiveConfigs[i]] = tempNumbersOfProcedures[i];
    }
  }
}


/** Checks if passed archiving procedure settings are correct. Note that this function does not perform all the checks and does
    not guarantee that applying the passed settings will not fail e.g. at the step of calling dpSetWait().

@param dpes                  DPEs to which the settings will be applied
@param procedureIndexes      indexes of archiving procedures
@param archiveClasses	     names of archive classes
@param archiveTypes          types of archive smoothing; use constants from @ref fwArchiveConfig_Constants_ArchiveType
@param smoothProcedures      smoothing procedures; use constants from @ref fwArchiveConfig_Constants_Smoothing
@param deadbands             deadband settings
@param timeIntervals         archiving time intervals
@param activateArchiving     true if archiving should be active, false otherwise
@param exceptionInfo         details of any errors are returned here
@return                      true if settings are correct, false otherwise
*/
bool _fwArchive_checkSettings(const dyn_string &dpes, const dyn_dyn_int &procedureIndexes, const dyn_dyn_string &archiveClasses,
                              const dyn_dyn_int &archiveTypes, const dyn_dyn_int &smoothProcedures, const dyn_dyn_float &deadbands,
                              const dyn_dyn_float &timeIntervals, const dyn_bool &activateArchiving, dyn_string &exceptionInfo,
                              bool applyFirstSettingsToAllDpes = false)
{
  const string errPrefix = __FUNCTION__ + "(): Incorrect parameters passed to the function - ";
  bool allParamsOfSameLen = dynlen(procedureIndexes) == dynlen(archiveClasses) &&
                            dynlen(archiveClasses) == dynlen(archiveTypes) &&
                            dynlen(archiveTypes) == dynlen(smoothProcedures) &&
                            dynlen(smoothProcedures) == dynlen(deadbands) &&
                            dynlen(deadbands) == dynlen(timeIntervals);

  bool firstParamsModeOk = allParamsOfSameLen && dynlen(procedureIndexes) == 1;
  bool normalModeOk = allParamsOfSameLen && dynlen(dpes) == dynlen(procedureIndexes);

  if (applyFirstSettingsToAllDpes && !firstParamsModeOk ||
      !applyFirstSettingsToAllDpes && !normalModeOk) {
    fwException_raise(exceptionInfo, "ERROR", errPrefix + "Mismatch in lengths of settings vectors", "");
    return false;
  }

  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    if (!(dynlen(archiveClasses[dpeIdx]) == dynlen(archiveTypes[dpeIdx]) &&
        dynlen(archiveTypes[dpeIdx]) == dynlen(smoothProcedures[dpeIdx]) &&
        dynlen(smoothProcedures[dpeIdx]) == dynlen(deadbands[dpeIdx]) &&
        dynlen(deadbands[dpeIdx]) == dynlen(timeIntervals[dpeIdx]))) {
      fwException_raise(exceptionInfo, "ERROR", errPrefix + "Mismatch in lengths of settings vectors", "");
      return false;
    }

    const int archiveClassesLen = dynlen(archiveClasses[dpeIdx]);
    if (archiveClassesLen > 1) {
      for (int procIdx = 1; procIdx <= archiveClassesLen; procIdx++) {
        const string archClassName = archiveClasses[dpeIdx][procIdx];
        if (!_fwArchive_isArchiveClassNameNga(archClassName) && archClassName != "") {
          fwException_raise(exceptionInfo, "ERROR", errPrefix + "Only NGA archive classes can be used in configuration with multiple archiving procedures - "
                            "Encountered wrong archive class " + archClassName + " for DPE " + dpes[dpeIdx], "");
          return false;
        }
      }
    }
  }

  return true;
}

/** Sets many archiving procedures for many DPEs to the given settings

  Archiving configuration is applied in the following way: for every element in dpes, properties passed in dyn_dyn_* arguments are applied to
  archive procedures at indexes specified by @ref procedureIndexes argument.

  In contrast to @ref fwArchive_replaceManyArchivingProcedures, this function does not erase all procedure indexes that are not passed in procedureIndexes,
  making it useful for applying isolated changes to archive configs with many procedures defined and when most of them should be kept unchanged.

  Note that gaps in archive procedure indexes are not allowed, e.g. if an archive config has only one procedure already defined,
  trying to set archive procedure at index 3 will fail.

  This function can also be used for non-NGA archiving that does not support multiple archiving procedures. In such case
  only one procedure with index 1 should be used.

@param dpes                  DPEs to which the settings will be applied
@param procedureIndexes      indexes of archiving procedures; if empty dyn value is passed here, then the natural order of procedure settings
                             in other arguments is assumed
@param archiveClasses	     names of archive classes
@param archiveTypes          types of archive smoothing; use constants from @ref fwArchiveConfig_Constants_ArchiveType
@param smoothProcedures      smoothing procedures; use constants from @ref fwArchiveConfig_Constants_Smoothing
@param deadbands             deadband settings
@param timeIntervals         archiving time intervals
@param activateArchiving     true if archiving should be active, false otherwise
@param exceptionInfo         details of any errors are returned here
@param checkClass            optional parameter, default value is true - check if class is not deleted and has enough free space. If false, the checks will be skipped.
@param applyFirstSettingsToAllDpes  optional parameter, default value is false. When set to true, settings at index 1 will be applied to all DPEs
*/
fwArchive_setManyArchivingProcedures(const dyn_string &dpes, const dyn_dyn_int &procedureIndexes, const dyn_dyn_string &archiveClasses,
                                     const dyn_dyn_int &archiveTypes, const dyn_dyn_int &smoothProcedures, const dyn_dyn_float &deadbands,
                                     const dyn_dyn_float &timeIntervals, const dyn_bool &activateArchiving, dyn_string &exceptionInfo,
                                     bool checkClass = true, bool applyFirstSettingsToAllDpes = false)
{
  if (!_fwArchive_checkSettings(dpes, procedureIndexes, archiveClasses, archiveTypes, smoothProcedures, deadbands,
                                timeIntervals, activateArchiving, exceptionInfo)) {
    return;
  }

  dyn_int archiveConfigTypes;
  fwConfigs_dpGetMany(dpes, archiveConfigTypes, exceptionInfo, "_archive.._type");
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_dyn_string archiveClassDps;
  _fwArchive_convertManyArchiveClassNamesToDpNamesMultipleArchiveProcedures(dpes, archiveClasses, archiveClassDps, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  bool useProcedureIndexesFromArgument = dynlen(procedureIndexes) > 0;
  dyn_string batchWhatToSet;
  dyn_anytype batchValuesToSet;
  int batchCounter = 0;
  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    const int settingsDpeIdx = applyFirstSettingsToAllDpes ? 1 : dpeIdx;
    if (archiveConfigTypes[settingsDpeIdx] == DPCONFIG_NONE) {
      dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive.._type");
      dynAppend(batchValuesToSet, DPCONFIG_DB_ARCHIVEINFO);
    }

    const int numberOfProceduresToSet = useProcedureIndexesFromArgument ? dynlen(procedureIndexes[settingsDpeIdx]) : dynlen(archiveClassDps[settingsDpeIdx]);
    for (int archProcIdx = 1; archProcIdx <= numberOfProceduresToSet; archProcIdx++) {
      string procIdxStr = useProcedureIndexesFromArgument ? (string)procedureIndexes[settingsDpeIdx][archProcIdx] : (string)archProcIdx;
      if (archiveTypes[settingsDpeIdx][archProcIdx] == DPCONFIG_NONE) {
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._type");
        dynAppend(batchValuesToSet, DPCONFIG_NONE);
        batchCounter++;
      } else {
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._class");
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._type");
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._std_type");
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._std_tol");
        dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive." + procIdxStr + "._std_time");

        dynAppend(batchValuesToSet, archiveClassDps[settingsDpeIdx][archProcIdx]);
        dynAppend(batchValuesToSet, archiveTypes[settingsDpeIdx][archProcIdx]);
        dynAppend(batchValuesToSet, smoothProcedures[settingsDpeIdx][archProcIdx]);
        dynAppend(batchValuesToSet, deadbands[settingsDpeIdx][archProcIdx]);
        dynAppend(batchValuesToSet, timeIntervals[settingsDpeIdx][archProcIdx]);

        batchCounter = batchCounter + 5;
      }
    }

    if (dynlen(activateArchiving) > 0) {
      dynAppend(batchWhatToSet, dpes[dpeIdx] + ":_archive.._archive");
      dynAppend(batchValuesToSet, activateArchiving[settingsDpeIdx]);
    }

    if (batchCounter >= fwConfigs_OPTIMUM_DP_SET_SIZE || (dpeIdx == dpesLen && batchCounter > 0)) {
      int rc = dpSetWait(batchWhatToSet, batchValuesToSet);
      dyn_errClass lastErrors = getLastError();
      if (rc != 0 || dynlen(lastErrors) > 0) {
        throwError(lastErrors);
        fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): Could not create archiving configs - " + getErrorText(lastErrors), "");
        return;
      }

      batchWhatToSet = makeDynString();
      batchValuesToSet = makeDynAnytype();
      batchCounter = 0;
    }
  }
}

/** Replaces archiving procedures for many DPEs with the given ones

  Archiving configuration is applied in the following way: for every element in dpes, properties from the corresponding indexes in settings arguments are
  applied to the subsequent archiving procedures. All existing archiving procedues are deleted.

  This function can also be used for non-NGA archiving that does not support multiple archiving procedures. In such case only a single single archiving
  procedure can be passed per DPE.

@param dpes                  DPEs to which the settings will be applied
@param archiveClasses	     names of archive classes
@param archiveTypes          types of archive smoothing; use constants from @ref fwArchiveConfig_Constants_ArchiveType
@param smoothProcedures      smoothing procedures; use constants from @ref fwArchiveConfig_Constants_Smoothing
@param deadbands             deadband settings
@param timeIntervals         archiving time intervals
@param activateArchiving     true if archiving should be active, false otherwise
@param exceptionInfo         details of any errors are returned here
@param checkClass            optional parameter, default value is true - check if class is not deleted and has enough free space. If false, the checks will be skipped.
@param applyFirstSettingsToAllDpes  optional parameter, default value is false. When set to true, settings at index 1 will be applied to all DPEs
*/
fwArchive_replaceManyArchivingProcedures(const dyn_string &dpes, const dyn_dyn_string &archiveClasses,
                                         const dyn_dyn_int &archiveTypes, const dyn_dyn_int &smoothProcedures, const dyn_dyn_float &deadbands,
                                         const dyn_dyn_float &timeIntervals, const dyn_bool &activateArchiving, dyn_string &exceptionInfo,
                                         bool checkClass = true, bool applyFirstSettingsToAllDpes = false)
{
  dyn_int numbersOfProcedures;
  dyn_int present, active;
  _fwArchive_getDpeArchivingConfiguredActiveProcedureNumbers(dpes, present, active,
                                                             numbersOfProcedures, false, true, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_dyn_int procedureIndexes;
  dyn_dyn_string modifArchiveClasses;
  dyn_dyn_int modifArchiveTypes;
  dyn_dyn_int modifSmoothProcedures;
  dyn_dyn_float modifDeadbands;
  dyn_dyn_float modifTimeIntervals;
  dyn_bool modifActivateArchiving;

  int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    const int settingsDpeIdx = applyFirstSettingsToAllDpes ? 1 : dpeIdx;
    const int newProceduresLen = dynlen(archiveClasses[settingsDpeIdx]);
    const int oldProceduresLen = numbersOfProcedures[dpeIdx];
    const int maxProcIdx = newProceduresLen > oldProceduresLen ? newProceduresLen : oldProceduresLen;
    modifActivateArchiving[dpeIdx] = activateArchiving[settingsDpeIdx];
    int numberOfProcMarkedForDeletion = 0;
    for (int archProcIdx = 1; archProcIdx <= maxProcIdx; archProcIdx++) {
      const bool idxToBeRemoved = archProcIdx > newProceduresLen;
      if (idxToBeRemoved) {
        procedureIndexes[dpeIdx][archProcIdx] = maxProcIdx - numberOfProcMarkedForDeletion;
        numberOfProcMarkedForDeletion++;
      } else {
        procedureIndexes[dpeIdx][archProcIdx] = archProcIdx;
      }
      modifArchiveClasses[dpeIdx][archProcIdx] = idxToBeRemoved ? "" : archiveClasses[settingsDpeIdx][archProcIdx];
      modifArchiveTypes[dpeIdx][archProcIdx] = idxToBeRemoved ? 0 : archiveTypes[settingsDpeIdx][archProcIdx];
      modifSmoothProcedures[dpeIdx][archProcIdx] = idxToBeRemoved ? 0 : smoothProcedures[settingsDpeIdx][archProcIdx];
      modifDeadbands[dpeIdx][archProcIdx] = idxToBeRemoved ? 0 : deadbands[settingsDpeIdx][archProcIdx];
      modifTimeIntervals[dpeIdx][archProcIdx] = idxToBeRemoved ? 0 : timeIntervals[settingsDpeIdx][archProcIdx];
    }
  }

  fwArchive_setManyArchivingProcedures(dpes, procedureIndexes, modifArchiveClasses, modifArchiveTypes, modifSmoothProcedures, modifDeadbands,
                                       modifTimeIntervals, modifActivateArchiving, exceptionInfo, checkClass, false);
}

/** Appends many archiving procedures to many DPEs

@param dpes                  DPEs to which the procedures will be appended
@param archiveClasses	     names of archive classes
@param archiveTypes          types of archive smoothing; use constants from @ref fwArchiveConfig_Constants_ArchiveType
@param smoothProcedures      smoothing procedures; use constants from @ref fwArchiveConfig_Constants_Smoothing
@param deadbands             deadband settings
@param timeIntervals         archiving time intervals
@param exceptionInfo         details of any errors are returned here
@param checkClass            optional parameter, default value is true - check if class is not deleted and has enough free space. If false, the checks will be skipped.
@param applyFirstSettingsToAllDpes  optional parameter, default value is false. When set to true, settings at index 1 will be applied to all DPEs
*/
fwArchive_appendManyArchivingProcedures(const dyn_string &dpes, const dyn_dyn_string &archiveClasses,
                                        const dyn_dyn_int &archiveTypes, const dyn_dyn_int &smoothProcedures, const dyn_dyn_float &deadbands,
                                        const dyn_dyn_float &timeIntervals, dyn_string &exceptionInfo,
                                        bool checkClass = true, bool applyFirstSettingsToAllDpes = false)
{
  dyn_int numbersOfProcedures;
  dyn_int present, active;
  _fwArchive_getDpeArchivingConfiguredActiveProcedureNumbers(dpes, present, active,
                                                             numbersOfProcedures, false, true, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_dyn_int procedureIndexes;

  int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    for (int archProcIdx = 1; archProcIdx <= dynlen(archiveClasses[dpeIdx]); archProcIdx++) {
      const int appendedProcIdx = numbersOfProcedures[dpeIdx] + archProcIdx;
      dynAppend(procedureIndexes[dpeIdx], appendedProcIdx);
    }
  }

  fwArchive_setManyArchivingProcedures(dpes, procedureIndexes, archiveClasses, archiveTypes, smoothProcedures, deadbands,
                                       timeIntervals, makeDynBool(), exceptionInfo, applyFirstSettingsToAllDpes);
}


/** Deletes selected archiving procedures from many DPEs

@param dpes                          DPEs from which the procedures are deleted
@param proceduresToDelete            indexes of archiving procedures to be deleted
@param exceptionInfo                 details of errors are returned here
@param applyFirstSettingsToAllDpes   optional argument, default value is false. When set to true, the procedures with indexes
                                     in @ref proceduresToDelete[1] will be removed from all DPEs.
*/
fwArchive_deleteManyArchivingProcedures(const dyn_string &dpes, dyn_dyn_int proceduresToDelete, dyn_string &exceptionInfo,
                                        bool applyFirstSettingsToAllDpes = false)
{
  dyn_dyn_int procedureIndexes;
  dyn_dyn_int archiveTypes;

  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    dynSort(proceduresToDelete[dpeIdx], false);
    for (int archProcIdx = 1; archProcIdx <= dynlen(proceduresToDelete[dpeIdx]); archProcIdx++) {
      procedureIndexes[dpeIdx][archProcIdx] = proceduresToDelete[dpeIdx][archProcIdx];
      archiveTypes[dpeIdx][archProcIdx] = DPCONFIG_NONE;
    }
  }

  const dyn_dyn_string dds;
  const dyn_dyn_float ddf;
  const dyn_dyn_int ddi;
  fwArchive_setManyArchivingProcedures(dpes, procedureIndexes, dds, archiveTypes, ddi, ddf, ddf, makeDynBool(), exceptionInfo,
                                       false, applyFirstSettingsToAllDpes);
}


/** Gets parameters of all archiving procedures for many DPEs

    Output arguments are of dyn_* type if the property is valid for the entire _archive config (e.g. @ref configExists) and of dyn_dyn_* type
    if it is configured per archiving procedure (e.g. @ref archiveClasses).

    Archiving procedure parameters are returned in natural order, i.e. archiveClasses[DPE index][archiving procedure index], e.g.

    archiveClass[1][1] -> archive class of the first archiving procedure of the first DPE in dpes
    archiveClass[1][2] -> archive class of the second archiving procedure of the first DPE in dpes
    archiveClass[2][1] -> archive class of the first archiving procedure of the second DPE in dpes
    ...

    and so on.

@param dpes                  DPEs from which the procedures are retrieved
@param configExists          true if archive config exists, false otherwise
@param configActive          true if archive config is active, false otherwise
@param archiveClasses	     names of archive classes are returned here
@param archiveTypes          types of archive smoothing are returned here (constants from @ref fwArchiveConfig_Constants_ArchiveType)
@param smoothProcedures      smoothing procedures are returned here (constants from @ref fwArchiveConfig_Constants_Smoothing)
@param deadbands             deadband are returned here
@param timeIntervals         archiving time intervals are returned here
@param exceptionInfo         details of errors are returned here
*/
fwArchive_getManyArchivingProcedures(const dyn_string &dpes, dyn_bool &configExists, dyn_bool &configActive, dyn_dyn_string &archiveClasses,
                                     dyn_dyn_int &archiveTypes, dyn_dyn_int &smoothProcedures, dyn_dyn_float &deadbands, dyn_dyn_float &timeIntervals,
                                     dyn_string &exceptionInfo)
{
  dynClear(configExists);
  dynClear(configActive);
  dynClear(archiveClasses);
  dynClear(archiveTypes);
  dynClear(smoothProcedures);
  dynClear(deadbands);
  dynClear(timeIntervals);

  _fwArchive_getDpeArchiveConfigsPresent(dpes, configExists, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_string dpesWithArchiveConfigs;
  dyn_int idxsOfDpesWithArchiveConfigs;
  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    if (configExists[dpeIdx]) {
      dynAppend(dpesWithArchiveConfigs, dpes[dpeIdx]);
      dynAppend(idxsOfDpesWithArchiveConfigs, dpeIdx);
    }
  }

  dyn_bool tempConfigActive;
  _fwArchive_getDpeArchiveConfigsEnabled(dpesWithArchiveConfigs, tempConfigActive, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  dyn_int tempNumbersOfProcedures;
  _fwArchive_getNumberOfArchivingProcedures(dpesWithArchiveConfigs, tempNumbersOfProcedures, exceptionInfo);
  if (dynlen(exceptionInfo) > 0) {
    return;
  }

  configActive[dpesLen] = false;
  dyn_int numbersOfProcedures;
  numbersOfProcedures[dpesLen] = 0;
  for (int i = 1; i <= dynlen(idxsOfDpesWithArchiveConfigs); i++) {
    configActive[idxsOfDpesWithArchiveConfigs[i]] = tempConfigActive[i];
    numbersOfProcedures[idxsOfDpesWithArchiveConfigs[i]] = tempNumbersOfProcedures[i];
  }

  dyn_dyn_string archiveClassDps;

  dyn_string batchWhatToGet;
  dyn_int batchOriginalDpeIdxs;
  int batchCounter = 0;
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    if (numbersOfProcedures[dpeIdx] == 0) {
      dynAppend(archiveClassDps[dpeIdx], makeDynString());
      dynAppend(archiveTypes[dpeIdx], makeDynInt());
      dynAppend(smoothProcedures[dpeIdx], makeDynInt());
      dynAppend(deadbands[dpeIdx], makeDynFloat());
      dynAppend(timeIntervals[dpeIdx], makeDynFloat());
    } else {
      for (int archProcIdx = 1; archProcIdx <= numbersOfProcedures[dpeIdx]; archProcIdx++) {
        dynAppend(batchOriginalDpeIdxs, dpeIdx);
        dynAppend(batchWhatToGet, dpes[dpeIdx] + ":_archive." + (string)archProcIdx + "._class");
        dynAppend(batchWhatToGet, dpes[dpeIdx] + ":_archive." + (string)archProcIdx + "._type");
        dynAppend(batchWhatToGet, dpes[dpeIdx] + ":_archive." + (string)archProcIdx + "._std_type");
        dynAppend(batchWhatToGet, dpes[dpeIdx] + ":_archive." + (string)archProcIdx + "._std_tol");
        dynAppend(batchWhatToGet, dpes[dpeIdx] + ":_archive." + (string)archProcIdx + "._std_time");
        batchCounter = batchCounter + 5;
      }
    }

    if (batchCounter >= fwConfigs_OPTIMUM_DP_GET_SIZE || (dpeIdx == dpesLen && batchCounter > 0)) {
      dyn_anytype values;
      int rc = dpGet(batchWhatToGet, values);
      if (rc != 0 || dynlen(getLastError()) > 0) {
        return;
      }

      const int resultLen = dynlen(values);
      for (int resDpeIdx = 0; resDpeIdx < resultLen / 5; resDpeIdx++) {
        const int baseResIdx = resDpeIdx * 5;
        const int dpeIdx = batchOriginalDpeIdxs[resDpeIdx + 1];
        dynAppend(archiveClassDps[dpeIdx], values[baseResIdx + 1]);
        dynAppend(archiveTypes[dpeIdx], values[baseResIdx + 2]);
        dynAppend(smoothProcedures[dpeIdx], values[baseResIdx + 3]);
        dynAppend(deadbands[dpeIdx], values[baseResIdx + 4]);
        dynAppend(timeIntervals[dpeIdx], values[baseResIdx + 5]);
      }

      batchWhatToGet = makeDynString();
      batchOriginalDpeIdxs = makeDynInt();
      batchCounter = 0;
    }
  }

  _fwArchive_convertManyArchiveClassDpsToNamesMultipleArchiveProcedures(archiveClassDps, archiveClasses, exceptionInfo);
}


/** Gets archive class DPs for a list of DPEs and their archive class names (version supporting multiple archiving procedures)

@param dpes			list of DPEs
@param archiveClassNames             names of archive classes
@param archiveClassDps               archive class DPs for dpes are returned here
@param exceptionInfo		details of errors are returned here
*/
_fwArchive_convertManyArchiveClassNamesToDpNamesMultipleArchiveProcedures(dyn_string dpes, dyn_dyn_string archiveClassNames,
                                                                          dyn_dyn_string &archiveClassDps, dyn_string &exceptionInfo)
{
  dynClear(archiveClassDps);

  dyn_string systems;
  mapping classNameDpTranslator;

  const int dpesLen = dynlen(dpes);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    systems[dpeIdx] = dpSubStr(dpes[dpeIdx], DPSUB_SYS);
  }

  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    const int procLen = dynlen(archiveClassNames[dpeIdx]);
    for (int procIdx = 1; procIdx <= procLen; procIdx++) {
      const string nameAndSystem = archiveClassNames[dpeIdx][procIdx] + systems[dpeIdx];
      if (archiveClassNames[dpeIdx][procIdx] != "") {
        if (!mappingHasKey(classNameDpTranslator, nameAndSystem)) {
          string classDpName;
          fwArchive_convertClassNameToDpName(archiveClassNames[dpeIdx][procIdx], classDpName, exceptionInfo, systems[dpeIdx]);
          if (dynlen(exceptionInfo) > 0) {
            return;
          }
          classNameDpTranslator[nameAndSystem] = classDpName;
        }
      } else {
        classNameDpTranslator[nameAndSystem] = "";
      }
    }
  }

  const int archGroupLen = dynlen(archiveClassNames);
  for (int archGroupIdx = 1; archGroupIdx <= archGroupLen; archGroupIdx++) {
    const int procLen = dynlen(archiveClassNames[archGroupIdx]);
    for (int procIdx = 1; procIdx <= procLen; procIdx++) {
      archiveClassDps[archGroupIdx][procIdx] = classNameDpTranslator[archiveClassNames[archGroupIdx][procIdx] + systems[archGroupIdx]];
    }
  }
}

/** Gets archive class names for archive class DPs (version supporting multiple archiving procedures)

@param archiveClassDps             archive class DPs
@param archiveClassNames           archive class names are returned here
@param exceptionInfo               details of errors are returned here
*/
_fwArchive_convertManyArchiveClassDpsToNamesMultipleArchiveProcedures(dyn_dyn_string archiveClassDps, dyn_dyn_string &archiveClassNames,
                                                                      dyn_string &exceptionInfo)
{
  dynClear(archiveClassNames);

  mapping classDpNameTranslator;

  const int dpesLen = dynlen(archiveClassDps);
  for (int dpeIdx = 1; dpeIdx <= dpesLen; dpeIdx++) {
    const int procLen = dynlen(archiveClassDps[dpeIdx]);
    archiveClassNames[dpeIdx] = makeDynString();
    for (int procIdx = 1; procIdx <= procLen; procIdx++) {
      const string archClassDp = archiveClassDps[dpeIdx][procIdx];
      if (archClassDp != "") {
        if (!mappingHasKey(classDpNameTranslator, archClassDp)) {
          string className;
          fwArchive_convertDpNameToClassName(archClassDp, className, exceptionInfo);
          if (dynlen(exceptionInfo) > 0) {
            return;
          }
          classDpNameTranslator[archClassDp] = className;
        }
        archiveClassNames[dpeIdx][procIdx] = classDpNameTranslator[archClassDp];
      } else {
        classDpNameTranslator[archClassDp] = "";
        archiveClassNames[dpeIdx][procIdx] = "";
      }
    }
  }
}

/** @}*/
