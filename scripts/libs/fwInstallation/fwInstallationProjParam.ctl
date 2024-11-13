#uses "fwInstallation/fwInstallation.ctl"

/** @file fwInstallationProjParam.ctl
  *
  * This library contains functions to store and read project-specific parameters from DB (ConfigurationDBSystemInformation).
  * Project parameter's value is stored under the specified namespace and key. Internally, inside the DB, "parameter name" is
  * used which combines key and namespace into one identifier. Existence of namespaces is to allow same keynames to exists.
  * For each project and parameter name (namespace-key pair) one project parameter value can exists.
  *
  * User can register its own keys and namespaces.
  * The key can be freely named although it is not recommended to use special characters (underscore and dash are allowed).
  * The default namespace exists however it is advised to use the unique name to avoid repetitions of parameter name.
  * It is suggested to use, as the namespace, the name of the component that uses this library to store its parameters.
  * This guarantees the unique namespaces for each component and makes the the developer of the component responsible
  * for keeping the unique key names only.
  * For namespace name it is forbidden to use slash '/' as it is used as namespace-key separator. For other characters
  * the same restrictions as for key name are applied.
  *
  * Usage:
  * Before first usage of the key it has to be registered. There are 2 functions that allow it:
  * fwInstallationProjParam_registerKey() and fwInstallationProjParam_registerKeyValue().
  * The first one only registers the key with given properties in provided namespace with no value assigned.
  * The second one allows also to register a value for specified project in one go.
  * Both functions returns success if key is already registered (they do not change key's properties),
  * so there is no need to check before if key is already registered.
  *
  *   int retVal = fwInstallationProjParam_registerKey("myKey", "fwInstallation",
  *                                                    FW_INSTALLATION_PROJ_PARAM_DEFAULT_KEY_TYPE, "This is my dummy key");
  * or
  *   int retVal = fwInstallationProjParam_registerKeyValue("myKey", "myValue", "fwInstallation",
  *                                                         FW_INSTALLATION_PROJ_PARAM_DEFAULT_KEY_TYPE, "This is my dummy key");
  *
  * To register a value or to change already set value for a given key, namespace and project, a fwInstallationProjParam_setValue()
  * function can be used.
  *
  *   // Assuming at this moment that key is already registered so it is not neccessary to check it, if this assumption
  *   // is wrong then error code is assigned to retVal
  *   int retVal = fwInstallationProjParam_setValue("myKey",  "myValue", "fwInstallation");
  *
  * To get value for a given key, namespace and project use fwInstallationProjParam_getValue(). In case a requested
  * key doesn't exists - function will return an error (there's a function to check existence of a key).
  *
  *   bool exists = false;
  *   string value;
  *   int retVal1 = fwInstallationProjParam_valueExists("myKey", exists, "fwInstallation");
  *   if(exists && !retVal1)
  *     int retVal2 = fwInstallationProjParam_getValue("myKey", value, "fwInstallation");
  *
  * To get all registered key - value pairs for given namespace and project one can use
  * fwInstallationProjParam_getKeyValueMapping() function. Registered key - value pairs are returned as a mapping.
  *
  *  mapping keyValMapping;
  *  int retVal = fwInstallationProjParam_getKeyValueMapping(keyValMapping, "fwInstallation");
  *
  * Note: "fwInstallation" in examples above should be replaced by the name of component that uses these functions.
  */

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationProjParamLibVersion = "9.1.3";
const string csFwInstallationProjParamLibTag = "";

/**** Constants declaration ****/

const string FW_INSTALLATION_PROJ_PARAM_KEY_NAMESPACE_SEPARATOR = "/";
const string FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE = "_default";
/// type/storage-type, other examples: test/encrypted, password/encrypted, etc.
const string FW_INSTALLATION_PROJ_PARAM_DEFAULT_KEY_TYPE = "text/plain";

/**** Private functions ****/

/** Returns the parameter name from provided key and namespace
  * @param key (in)  Name of the key
  * @param nameSpace (in)  Name of the namespace
  * @return parameter name: "namespace/key"
  */
private string fwInstallationProjParam_getParamName(string key, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE)
{
  return nameSpace + FW_INSTALLATION_PROJ_PARAM_KEY_NAMESPACE_SEPARATOR + key;
}

/** Returns key extracted from parameter name
  * @param paramName (in)  Parameter name
  * @return Key name or empty string in case the paramName has wrong pattern
  */
private string fwInstallationProjParam_extractKeyFromParamName(string paramName)
{
  int separatorPos = strpos(paramName, FW_INSTALLATION_PROJ_PARAM_KEY_NAMESPACE_SEPARATOR);
  if(separatorPos < 0)
    return "";
  return substr(paramName, separatorPos + 1);
}

/**** Public functions ****/

/** Checks if given parameter name (key - namespace pair) is already registered in DB.
  * @param key (in)  Key name
  * @param exists (out)  Flag that indicates if a parameter exists in DB, note: this flag is changed only when success code is returned
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @return 0 when checking was peformed succesfully, -1 if an error occured (failed to check if parameter is registered)
  */
int fwInstallationProjParam_keyExists(string key, bool &exists, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE)
{
  int paramTypeId;
  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  if(fwInstallationDB_isParamTypeRegistered(paramTypeId, paramName) != 0)
  {
    fwInstallation_throw("fwInstallationProjParam_keyExists() -> Failed to check if key: " + key + " in namespace: " + nameSpace + " is registered in DB");
    return -1;
  }
  exists = false;
  if(paramTypeId >= 0)
    exists = true;
  return 0;
}

/** This function allows to register new key for storing projects' parameter in DB.
  * Note: This function must be called before first usage of the key.
  * Note2: If key is already registered for given namespace then function does nothing and returns success code, thus it
  * is possible to call this function multiple times, on different projects with the same result (success) so then user
  * script can proceed without any errors.
  * @param key (in)  Key name
  * @param nameSpace (in)  Namespace, default value: '_default' (user should define own namespace, it is recommended to
  *                        use component name as the namespace, using default namespace causes risk of key name clash)
  * @param dataType (in)  Type (description) of data stored under given key, default value: 'text/plain'. Note: It is
  *                       not the data type in the sense of ctrl variable type (int, string, etc.) - in this sense
  *                       stored data is always of type 'string'
  * @param description (in)  Key description, optional, default value is empty
  * @param family (in)  Family of key, optional, default value is empty
  * @return 0 when key was registered succesfully or given key already exists in DB, -1 if errors occured (unable
  *         to register or verify if key is registered already)
  */
int fwInstallationProjParam_registerKey(string key, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE,
                                        string dataType = FW_INSTALLATION_PROJ_PARAM_DEFAULT_KEY_TYPE, string description = "", string family = "")
{
  dyn_mixed paramTypeProperties;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_NAME] = fwInstallationProjParam_getParamName(key, nameSpace);
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_DATATYPE] = dataType;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_DESCRIPTION] = description;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_FAMILY] = family;

  if(fwInstallationDB_registerParamType(paramTypeProperties) != 0)
  {
    fwInstallation_throw("fwInstallationProjParam_registerKey() -> Failed to register key: " + key + " in namespace: " + nameSpace + " in DB");
    return -1;
  }
  return 0;
}

/** @NOTE: NOT IMPLEMENTED YET, DO NOT USE THIS FUNCTION
  * Removes given parameter (key - namespace pair) from DB.
  * @note Parameter removal affects all projects that store values under specified key and namespace. After removal all
  *       values stored under this parameter by different projects are no longer accessible.
  * @param key (in)  Key name
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @return 0 when parameter was removed successfully, -1 if an error occured ()
  */
int fwInstallationProjParam_removeKey(string key, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE)
{
  bool isKeyExists = false;
  if(fwInstallationProjParam_keyExists(key, isKeyExists, nameSpace) != 0)
  {
    //
    return -1;
  }
  if(!isKeyExists)
  {
    //
    return -1;
  }
  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  if(fwInstallationDB_removeParamType(paramName) != 0)
  {
    fwInstallation_throw("fwInstallationProjParam_removeKey() -> Failed to remove key: " + key + " in namespace: " + nameSpace + " from DB");
    return -1;
  }
  return 0;
}


/** This function checks if for given key, namespace, project and host a value exists.
  * Note: function will return error if a key doesn't exist (is not registered).
  * @param key (in)  Key name
  * @param exists (out)  Flag that indicates if a value exists in DB for given key, namespace and project,
  *                      Note: it is changed only when function returns success code
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when checking was peformed succesfully, -1 if an error occured (failed to check if key in given namespace
  *         is registered or failed to check if value is registered)
  */
int fwInstallationProjParam_valueExists(string key, bool &exists, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE, string project = "", string host = "")
{
  bool isKeyExist = false;
  if(fwInstallationProjParam_keyExists(key, isKeyExist, nameSpace) != 0)
  {
    string errMsg;
    sprintf(errMsg, "Cannot check if for given key and %s a value is registered in DB", project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_valueExists() -> Failed to check if key: " + key + " in namespace: " + nameSpace + " is registered in DB. " + errMsg);
    return -1;
  }
  if(!isKeyExist)
  {
    string errMsg;
    sprintf(errMsg, "Cannot check if for given key and %s a value is registered in DB", project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_setValue() -> Key: " + key + " in namespace: " + nameSpace + " is not registered in DB. " + errMsg);
    return -1;
  }

  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  int paramId = -1;
  if(fwInstallationDB_isProjectParamRegistered(paramId, paramName, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_valueExists() -> Failed to check if for key: %s in namespace: %s and %s a value is registered in DB",
            key, nameSpace, project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  exists = false;
  if(paramId >= 0)
    exists = true;

  return 0;
}

/** This function registers new key and assigns a value.
  * Note: Either this function or fwInstallationProjParam_registerKey must be called before first usage of the key.
  * Note2: If key already exists, for given namespace, registration is skipped and only value is set.
  * @param key (in)  Key name
  * @param nameSpace (in)  Namespace, default value: '_default' (user should define own namespace, it is recommended to
  *                        use component name as the namespace, using default namespace causes risk of key name clash)
  * @param dataType (in)  Type (description) of data stored under given key, default value: 'text/plain'. Note: It is
  *                       not the data type in the sense of ctrl variable type (int, string, etc.) - in this sense
  *                       stored data is always of type 'string'
  * @param description (in)  Key description, optional, default value is empty
  * @param family (in)  Family of key, optional, default value is empty
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when key was registered succesfully or given key already exists in DB, -1 if errors occured (unable to
  *         register or verify if key is registered already)
  */
int fwInstallationProjParam_registerKeyValue(string key, string value, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE,
                                             string dataType = FW_INSTALLATION_PROJ_PARAM_DEFAULT_KEY_TYPE, string description = "", string family = "",
                                             string project = "", string host = "")
{
  dyn_mixed paramTypeProperties;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_NAME] = fwInstallationProjParam_getParamName(key, nameSpace);
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_DATATYPE] = dataType;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_DESCRIPTION] = description;
  paramTypeProperties[FW_INSTALLATION_DB_PROJ_PARAM_TYPE_FAMILY] = family;

  if(fwInstallationProjParam_registerKey(key, nameSpace, dataType, description, family) != 0)
  {
    string errMsg;
    sprintf(errMsg, "Cannot register value: %s for given key and %s", value, project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_registerKeyValue() -> Failed to register key: " + key + " in namespace: " + nameSpace + " in DB. " + errMsg);
    return -1;
  }
  if(fwInstallationProjParam_setValue(key, value, nameSpace, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "Failed to register in DB value: %s for given key and %s", value, project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_registerKeyValue() -> Key: " + key + " in namespace: " + nameSpace + " was registered in DB. " + errMsg);
    return -1;
  }
  return 0;
}


/** Sets the specified value under given key and namespace, for given project, by default the current one.
  * Note: If value did not exist before in DB for specified key, the function registers it under given key and
  *       namespace and given project.
  * @param key (in)  Key name
  * @param value (in)  Value to be set under given key and namespace, for given project
  * @param nameSpace (in)  Namespace, default value: '_default' (user should define own namespace, it is recommended to
  *                        use component name as the namespace, using default namespace causes risk of key name clash)
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when value was set successfully, -1 if an error occured (failed to set value or register it if it did
  *         not exist before)
  */
int fwInstallationProjParam_setValue(string key, string value, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE, string project = "", string host = "")
{
  bool isKeyExist = false;
  if(fwInstallationProjParam_keyExists(key, isKeyExist, nameSpace) != 0)
  {
    string errMsg;
    sprintf(errMsg, "Cannot set value: %s for given key and %s", value, project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_setValue() -> Failed to check if key: " + key + " in namespace: " + nameSpace + " is registered in DB. " + errMsg);
    return -1;
  }
  if(!isKeyExist)
  {
    string errMsg;
    sprintf(errMsg, "Cannot set value: %s for given key and %s", value, project==""?"current project":("project: " + project));
    fwInstallation_throw("fwInstallationProjParam_setValue() -> Key: " + key + " in namespace: " + nameSpace + " is not registered in DB. " + errMsg);
    return -1;
  }

  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  if(fwInstallationDB_setProjectParamValue(paramName, value, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_setValue() -> Failed to set value %s for key: %s, namespace %s and %s in DB",
            value, key, nameSpace, project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  return 0;
}

/** This function gets the value of project parameter for given namespace, key and project (by default the current one)
  * @param key (in)  Key name
  * @param value (in)  Value of project parameter
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when value was got successfully, -1 if an error occured (failed to get project parameter as for example
  *         the value for given key, namespace and project is not registered in DB or given key is not registered)
  */
int fwInstallationProjParam_getValue(string key, string &value, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE, string project = "", string host = "")
{
  bool isKeyExist = false;
  if(fwInstallationProjParam_keyExists(key, isKeyExist, nameSpace) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getValue() -> Failed to check if key: %s in namespace: %s is registered in DB. Cannot get value from DB for given parameters",
            key, nameSpace);
    fwInstallation_throw(errMsg);
    return -1;
  }
  if(!isKeyExist)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getValue() -> Key: %s in namespace: %s is not registered in DB. Cannot get value from DB for given parameters",
            key, nameSpace);
    fwInstallation_throw(errMsg);
    return -1;
  }

  bool isParamExist = false;
  if(fwInstallationProjParam_valueExists(key, isParamExist, nameSpace, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getValue() -> Failed to check if value for key: %s, namespace: %s and %s is registered in DB. Cannot get value from DB for given parameters",
            key, nameSpace,  project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  if(!isParamExist)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getValue() -> Value for key: %s, namespace: %s and %s is not registered in DB. Cannot get value from DB for given parameters",
            key, nameSpace,  project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }

  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  if(fwInstallationDB_getProjectParamValue(paramName, value, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getValue() -> Failed to get value from DB for key: %s, namespace: %s and %s",
            key, nameSpace, project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  return 0;
}

/** Removes from DB the value of project parameter for given namespace, key and project (by default the current one)
  * @param key (in)  Key name
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when value was removed successfully, -1 if an error occured (given project parameter does not exist in DB,
  *         failed to remove project parameter)
  */
int fwInstallationProjParam_removeValue(string key, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE, string project = "", string host = "")
{
  bool isParamExist = false;
  //add keyExists
  if(fwInstallationProjParam_valueExists(key, isParamExist, nameSpace, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_removeValue() -> Failed to check if value for key: %s, namespace: %s and %s is registered in DB. Cannot remove value from DB for given parameters",
            key, nameSpace,  project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  if(!isParamExist)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_removeValue() -> Value for key: %s, namespace: %s and %s is not registered in DB. Cannot remove it.",
            key, nameSpace,  project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }

  string paramName = fwInstallationProjParam_getParamName(key, nameSpace);
  if(fwInstallationDB_removeProjectParam(paramName, project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_removeValue() -> Failed to remove value from DB for key: %s, namespace: %s and %s",
            key, nameSpace, project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  return 0;
}

/** Returns all available keys along with their values for given namespace and given project (by default the current one)
  * @param keyValMapping (out)  Mapping with project parameters (keys and their values) that exist in DB for given namespace and project
  * @param nameSpace (in)  Namespace, default value: '_default'
  * @param project (in)  Project name, default value is empty (current project)
  * @param host (in)  Hostname, default value is empty (current host)
  * @return 0 when value was got successfully, -1 if an error occured
  */
int fwInstallationProjParam_getKeyValueMapping(mapping &keyValMapping, string nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE, string project = "", string host = "")
{
  const string wildcardChar = "%";
  dyn_dyn_mixed projectParamsProperites;
  strreplace(nameSpace, wildcardChar, "");//prevent using wildcards passing by the user
  if(nameSpace == "")
    nameSpace = FW_INSTALLATION_PROJ_PARAM_DEFAULT_NAMESPACE;
  string paramKeyword = fwInstallationProjParam_getParamName(wildcardChar, nameSpace);

  if(fwInstallationDB_getProjectParamsProperties(projectParamsProperites, paramKeyword,  project, host) != 0)
  {
    string errMsg;
    sprintf(errMsg, "fwInstallationProjParam_getKeyValueMapping() -> Failed to get key-value mapping for namespace: %s and %s",
            nameSpace, project==""?"current project":("project: " + project));
    fwInstallation_throw(errMsg);
    return -1;
  }
  mappingClear(keyValMapping);
  int paramsListLen = dynlen(projectParamsProperites);
  for(int i=1;i<=paramsListLen;i++)
  {
    if(dynlen(projectParamsProperites[i]) >= FW_INSTALLATION_DB_PROJECT_PARAM_VALUE)
    {
      string keyName = fwInstallationProjParam_extractKeyFromParamName(projectParamsProperites[i][FW_INSTALLATION_DB_PROJ_PARAM_TYPE_NAME]);
      keyValMapping[keyName] = projectParamsProperites[i][FW_INSTALLATION_DB_PROJECT_PARAM_VALUE];
    }
  }
  return 0;
}
