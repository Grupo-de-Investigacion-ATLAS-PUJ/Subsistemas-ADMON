/**@name LIBRARY: unDistributedControl.ctl

@file
This library contains functions for the unDistributedControl component. The DistributedControl component checks if the 
remote PVSS systems defined in the config file are connected or not. The result of this check can be used to set 
the graphical characteristics of a component, send a message to the operator, send email, send an SMS, etc.

@author: Herve Milcent (LHC-IAS)

Creation Date: 31/04/2002

@internal
Modification History: 
  04/05/2011: Herve
  - IS-534: unDistributedControl: use the same notation as the installotion tool for the distPeer config (hostname in upper case and port number)
	06/07/2004: Herve
		- add unDistributedControl_getAllDeviceConfig: get the config of all the declared _UnDistribtuedControl
		- add unDistributedControl_setDeviceConfig: set the config of the _UnDistribtuedControl_systemName
		- add unDistributedControl_checkCreateDp: to check if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, 
				if not it creates it, remove the dpSet connected to false: so during the creation it is set to false, and anytime after 
				the connected state is set by the unDistributedControl script.


External Functions: 
	. unDistributedControl_register: to register a call back function to the unDistributedControl component
	. unDistributedControl_deregister: to deregister a call back function to the unDistributedControl component
	. unDistributedControl_isRemote: to check if a given PVSS system name is a remote system
	. unDistributedControl_isConnected: to check if the PVSS system is connected
	. unDistributedControl_checkCreateDp: to check if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, 
				if not it creates it.
	. unDistributedControl_getAllConfigDevice: get the config of all the declared _UnDistribtuedControl


Internal Functions: 
	

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI (WCCOAUI)

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
@endinternal
*/
// contsant declaration
const string c_unDistributedControl_dpType = "_UnDistributedControl";
const string c_unDistributedControl_dpName = "_unDistributedControl_";
const string c_unDistributedControl_dpElementName=".connected";
const string c_unDistributedControl_dpConfigElementName=".config";
const string c_unDistributedControl_separator=";";
const string UNDISTRIBUTEDCONTROL_DEFAULT_DIST_PORT = "4777";

const int UN_DISTRIBUTED_CONTROL_SYSTEM_NAME = 1;
const int UN_DISTRIBUTED_CONTROL_SYSTEM_NUMBER = 2;
const int UN_DISTRIBUTED_CONTROL_SYSTEM_HOST = 3;
const int UN_DISTRIBUTED_CONTROL_SYSTEM_PORT = 4;
const int UN_DISTRIBUTED_CONTROL_SYSTEM_REDU_HOST = 5;


// end of constant declaration

//@{

void unDistributedControl_addSystem(dyn_mixed systemInfo, dyn_string &exception)
{
  unDistributedControl_checkCreateDp(c_unDistributedControl_dpName+systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_NAME], exception);
	if(dynlen(exception) <= 0) {
		unDistributedControl_checkSetAlias(c_unDistributedControl_dpName+systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_NAME], systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_NAME], exception);
		unDistributedControl_setDeviceConfig(systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_NAME], systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_NUMBER], systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_HOST], systemInfo[UN_DISTRIBUTED_CONTROL_SYSTEM_PORT],exception);
  }
  
  return;
}




unDistributedControl_addToConfigFile(dyn_string &exceptionInfo)
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
	int i, length;
	string sHostName, sPortNumber;
	dyn_string dsSystemName, dsHostName;
	dyn_int diSystemId, diPortNumber;
	int res;
	dyn_string dsSection;
  dyn_string exception;
	
  if(isFunctionDefined("unMessageText_sendException"))
  {
    string maxBcmBufferSize, bcmBufferLimitTimeout;
    paCfgReadValue(filename, "dist", "maxBcmBufferSize", maxBcmBufferSize);
    if(maxBcmBufferSize == ""){      
  	  dynAppend(dsSection, "maxBcmBufferSize = 120000");
    }
    
    paCfgReadValue(filename, "dist", "bcmBufferLimitTimeout", bcmBufferLimitTimeout);
    if(bcmBufferLimitTimeout == ""){      
  	  dynAppend(dsSection, "bcmBufferLimitTimeout = 120");
    }
  }
  
  // get current configs from dps
	unDistributedControl_getAllDeviceConfig(dsSystemName, diSystemId, dsHostName, diPortNumber);
  
  //get current list of distPeers from config file:

	length = dynlen(dsSystemName);
	for(i=1; i<=length;i++) {
    
		if(dsSystemName[i]+":" == getSystemName()) { //this is about the dist port. To be corrected
      string fileDistPort = "";
      paCfgReadValue(filename, "dist", "distPort", fileDistPort);
      if(fileDistPort == (string) diPortNumber[i]){
        DebugN("Dist port info matches that of the config file");    
      }
      else if(fileDistPort != "")
      {
        fwException_raise(exception, "ERROR", "distPort: in config file does not match the value passed. Config file info will be preserved", 99);
      }  
      else if(diPortNumber[i] > 0) {
//				DebugN("distPort = " + diPortNumber[i]);
				dynAppend(dsSection, "distPort = " + diPortNumber[i]);
			}
      
		}//end of if system = localsystem
		else {
      bool infoMatches = false;
      bool presentInFile = unDistributedControl_isSystemInFile(diSystemId[i], dsHostName[i], diPortNumber[i], "", infoMatches, exception);
      
      if(presentInFile && infoMatches)
      {
DebugN("System " + diSystemId[i], dsHostName[i], diPortNumber[i] + " already in file and info correct. Nothing to be done!");        
      }
      else if(presentInFile && !infoMatches)
      {
  	    fwException_raise(exception, "ERROR", "System: " + diSystemId[i] + " already in config file but information does not match. Config file info will be preserved", 99);
      }
      else //the distpeer is not yet in the config file:
      {
  			if(diPortNumber[i] > 0)
  				sPortNumber = ":"+diPortNumber[i];
  			else
  				sPortNumber = "";
        
  			if(dsHostName[i] == "")
  				sHostName = "localhost";
  			else
  				sHostName = dsHostName[i];
        
  			dynAppend(dsSection, "distPeer = \"" + sHostName + sPortNumber + "\" "+  diSystemId[i]);
  			DebugN("Appending to config file distPeer = \"" + sHostName + sPortNumber + "\" "+  diSystemId[i], dsHostName[i]);
      }
		}
	}
	dynAppend(dsSection, "");
	res = fwInstallation_addToSection("dist", dsSection);
//DebugN(res);
	if(res < 0)
		fwException_raise(exceptionInfo, "ERROR", "saving unDistribtuedControl configuration: cannot write config file", "");
}


bool unDistributedControl_systemDpExists(int systemNumber, string host, int port, string reduHost, bool &infoMatches, dyn_string &exception)
{
  dyn_int diSystemId;
  dyn_string diSystemName;
  dyn_string dsHostName;
  dyn_int diPortNumber;
  dyn_string dsReduHostName;
  
  unDistributedControl_getAllDeviceConfig(diSystemName, diSystemId,  dsHostName,  diPortNumber); 
  int pos = dynContains(diSystemId, systemNumber); 
      
  if(pos > 0)
  {
    if(port == 0){port = 4777;}
    
    if(diPortNumber[pos] == 0){diPortNumber[pos] = 4777;}
    
    if(dsHostName[pos] == host &&
       diPortNumber[pos] == port
       )//all info matches
    {
      infoMatches = true;
      return true;  
    }
    else
    {
      fwException_raise(exception, "WARNING", "System " + systemNumber + " is defined in the config file but its values do not match", 99);
      fwException_raise(exception, "WARNING", "System " + systemNumber + " info in life system follows - Name: " + diSystemName[pos] + ", Host: "+host + ", port:" + port, 99);
      fwException_raise(exception, "WARNING", "System " + systemNumber + " info in config file follows - Host: "+dsHostName[pos]+ ", port:" + diPortNumber[pos], 99);
      infoMatches = false;
      return true;  
    }
  }
  else
  {
    infoMatches = false;
    return false;  
  }
}




bool unDistributedControl_isSystemInFile(int systemNumber, string host, int port, string reduHost, bool &infoMatches, dyn_string &exception)
{
  dyn_int diFileSystemId;
  dyn_string dsFileHostName;
  dyn_int diFilePortNumber;
  dyn_string dsFileReduHostName;
  
  unDistributedControl_getAllDeviceConfigFromFile(diFileSystemId,  dsFileHostName,  diFilePortNumber,  dsFileReduHostName, exception); 
  int pos = dynContains(diFileSystemId, systemNumber); 
      
  if(pos > 0)
  {
    if(port == 0){port = 4777;}
    
    if(diFilePortNumber[pos] == 0){diFilePortNumber[pos] = 4777;}

    if(dsFileHostName[pos] == host &&
       diFilePortNumber[pos] == port &&
       dsFileReduHostName[pos] == reduHost
       )//all info matches
    {
      infoMatches = true;
      return true;  
    }
    else
    {
      fwException_raise(exception, "WARNING", "System " + systemNumber + " is defined in the config file but its values do not match", 99);
      fwException_raise(exception, "WARNING", "System " + systemNumber + " info in life system follows - Host: "+host + ", port:" + port +", reduHost: " + reduHost, 99);
      fwException_raise(exception, "WARNING", "System " + systemNumber + " info in config file follows - Host: "+dsFileHostName[pos]+ ", port:" + diFilePortNumber[pos]+", reduHost: " + dsFileReduHostName[pos], 99);
      infoMatches = false;
      return true;  
    }
  }
  else
  {
    infoMatches = false;
    return false;  
  }
   
}

// NOTE that the function is not really fully redu-compliant as it only gets the host name of the redu pair, and not its port...
// Refactor to have it supported correctly. For now we simply return the port number of the first peer
// (and probably the underlying code assumes this is the same port in the 2nd peer...)
void unDistributedControl_getAllDeviceConfigFromFile(dyn_int &diFileSystemId, dyn_string &dsFileHostName, dyn_int &diFilePortNumber, dyn_string &dsFileReduHostName, dyn_string &exception)
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
  dyn_string systemsInfo;  
  string host, reduHost;
  int port;
  
  paCfgReadValueList(filename, "dist", "distPeer", systemsInfo);
  
  // Check/protect againts duplicate entries (make them unique)
  int distCount = dynlen(systemsInfo);
  int uniqueCount = dynUnique(systemsInfo); // Note: this will change the list *inline*.
  if(distCount != uniqueCount)
  {
  	fwException_raise(exception, "WARNING", "Duplicate distributed connections entries detected in configuration file, please inspect the problem", 99);
  }
  
  int n = dynlen(systemsInfo);
  for(int i = 1; i <= n; i++)
  {
	string hostPortLine=systemsInfo[i];
	dyn_dyn_string distPeerHosts;
	dyn_dyn_int    distPeerPorts;
	int rc=fwInstallation_config_parseDistPeer(strtoupper(hostPortLine), distPeerHosts,distPeerPorts);
	if (rc<0) { 
		fwException_raise(exception,"ERROR", __FUNCTION__+"(): Could not parse the distPeer part of the config file","");
		return;
	}
    dynAppend(diFileSystemId,   rc);
    dynAppend(dsFileHostName,   distPeerHosts[1][1]);
    dynAppend(diFilePortNumber, distPeerPorts[1][1]);
    reduHost="" ;// empty for non-redu
	if (dynlen(distPeerHosts)>=2) reduHost=distPeerHosts[2][1];
	dynAppend(dsFileReduHostName, reduHost);
  }
}



// unDistributedControl_register
/**
Purpose:
to register a call back function to the unDistributedControl component. This function does a dpConnect of the 
sAdviseFunction call back function to the _unDistributedControl_xxx (xxx = system name of the remote PVSS system). 

In case of error, bResult is set to false and an exception is raised in exceptionInfo.

The call back function must be like:
CBFunc(string sDp, bool bConnected)
{
}
bConnected: true (the remote system is connected and synchronised)/false (the remote system is not connected)

it is recommended to do nothing if the bConnected is true. it is better to have another dpConnect function to other  
data. When a remote system is reconnected, any callback function to dp of the remot system will be called after the 
initialisation of the remote connection. Therefore the CBFunc will be called first and then any other call back 
function for the remote dp.

	@param sAdviseFunction: string, input, the name of the call back function
	@param bRes: bool, output, the result of the register call
	@param bConnected: bool, output, is the remote system connected
	@param sSystemName: string, input, the name of remote PVSS system
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_register(string sAdviseFunction, bool &bRes, bool &bConnected, string sSystemName, dyn_string &exceptionInfo)
{
	string sDistributedControlDpName;
	int iRes;
		
	bRes = false;
	bConnected = false;

	if(sAdviseFunction == "") {
		fwException_raise(exceptionInfo, "ERROR", getCatStr("unDistributedControl", "LIBREGERR"),"");
		return;
	}
	sDistributedControlDpName = "_unDistributedControl_"+substr(sSystemName, 0, strpos(sSystemName, ":"));
	if(dpExists(sDistributedControlDpName)) {
		iRes = dpConnect(sAdviseFunction, sDistributedControlDpName+c_unDistributedControl_dpElementName);
		if(iRes == -1) {
			fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBREGDPCONERR") + sAdviseFunction +", "+sDistributedControlDpName,"");
		}
		else {
			bRes = true;
			dpGet(sDistributedControlDpName+c_unDistributedControl_dpElementName, bConnected);
		}
	}
	else
		fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBREGNODP") + sDistributedControlDpName,"");
}

// unDistributedControl_deregister
/**
Purpose:
to deregister a call back function to the unDistributedControl component. This function does a dpDisconnect of the 
sAdviseFunction call back function to the _unDistributedControl_xxx (xxx = system name of the remote PVSS system). 

	@param sAdviseFunction: string, input, the name of the call back function
	@param bRes: bool, output, the result of the register call
	@param bConnected: bool, output, is the remote system connected
	@param sSystemName: string, input, the name of remote PVSS system
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_deregister(string sAdviseFunction, bool &bRes, bool &bConnected, string sSystemName, dyn_string &exceptionInfo)
{
	string sDistributedControlDpName;
	int iRes;
		
	bRes = false;
	bConnected = false;

	if(sAdviseFunction == "") {
		fwException_raise(exceptionInfo, "ERROR", getCatStr("unDistributedControl", "LIBDEREGERR"),"");
		return;
	}
	sDistributedControlDpName = "_unDistributedControl_"+substr(sSystemName, 0, strpos(sSystemName, ":"));
	if(dpExists(sDistributedControlDpName)) {
		iRes = dpDisconnect(sAdviseFunction, sDistributedControlDpName+c_unDistributedControl_dpElementName);
		if(iRes == -1) {
			fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBDEREGDPCONERR") + sAdviseFunction +", "+sDistributedControlDpName,"");
		}
	}
	else
		fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBDEREGNODP") + sDistributedControlDpName,"");
}

// unDistributedControl_isRemote
/**
Purpose:
To check if a given PVSS system name is a remote system
This function returns true if the sSystemName is the local PVSS system, i.e.: if it is the system name (getSystemName()) of 
the caller of this function. Otherwise it returns false.

	@param isRemoteSystem: bool, output, is the PVSS system a remote system
	@param sSystemName: string, input, the name of remote PVSS system

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_isRemote(bool &isRemoteSystem, string sSystemName)
{
	if(sSystemName == getSystemName()) 
		isRemoteSystem = false;
	else
		isRemoteSystem = true;
}

// unDistributedControl_isConnected
/**
Purpose:
to check if the PVSS system is connected. If the sSystemName is the local system (getSystemName()) is Connected is true.

	@param isConnected: bool, output, is the PVSS system connected
	@param sSystemName: string, input, the name of remote PVSS system

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_isConnected(bool &isConnected, string sSystemName)
{
	string sDistributedControlDpName;

	isConnected = false;
	
	if(sSystemName == getSystemName()) {
		isConnected = true;
	}
	else {
		sDistributedControlDpName = "_unDistributedControl_"+substr(sSystemName, 0, strpos(sSystemName, ":"));
		if(dpExists(sDistributedControlDpName)) {
			dpGet(sDistributedControlDpName+c_unDistributedControl_dpElementName, isConnected);
		}
	}
//	DebugN(sDistributedControlDpName, isConnected);
}

// unDistributedControl_getAllDeviceConfig
/**
Purpose:
get the config of all the declared _UnDistribtuedControl. empty field or 0 means default value.

	@param dsSystemName: dyn_string, output, list of all the PVSS systemName of the declared _UnDistribtuedControl
	@param diSystemId: dyn_int, output, list of all the PVSS system ID of the declared _UnDistribtuedControl
	@param dsHostName: dyn_string, output, list of all the hostname of the declared _UnDistribtuedControl
	@param diPortNumber: dyn_int, output, list of all the port number of the WCCILdist of the declared _UnDistribtuedControl


NOTE: the function completely lacks the diagnostic and silently skips misformatted information without any feedback.
	We need to keep this behaviour for the compatibility reasons, yet we should seriously consider refactoring into
	another function with proper warnings etc (ideally warnings printed out only once).

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_getAllDeviceConfig(dyn_string &dsSystemName, dyn_int &diSystemId, dyn_string &dsHostName, dyn_int &diPortNumber)
{
	dyn_string dsDp = dpNames(getSystemName()+c_unDistributedControl_dpName+"*", c_unDistributedControl_dpType);
	int i, len, pos;
	dyn_string systemName, hostName, dsSplit;
	dyn_int systemId, portNumber;
	string sConfig;
	len = dynlen(dsDp);
	for(i=1;i<=len;i++) {
		pos = strpos(dsDp[i], c_unDistributedControl_dpName);
		if(pos > -1) {
// correct system name
			dpGet(dsDp[i]+c_unDistributedControl_dpConfigElementName, sConfig);
			dsSplit = strsplit(sConfig, c_unDistributedControl_separator);
			if(dynlen(dsSplit) >= 3) {
				dynAppend(systemName, substr(dsDp[i], pos+strlen(c_unDistributedControl_dpName), strlen(dsDp[i])));
				dynAppend(hostName, dsSplit[1]);
				dynAppend(portNumber, dsSplit[2]);
				dynAppend(systemId, dsSplit[3]);
			}
		}
	}
	dsSystemName = systemName;
	diSystemId = systemId;
	dsHostName = hostName;
	diPortNumber = portNumber;
}

// unDistributedControl_setDeviceConfig
/**
Purpose:
set the config of all the _UnDistribtuedControl_systemName. empty field or 0 means default value.

	@param sSystemName: string, input, the PVSS systemName with or without : of the declared _UnDistribtuedControl
	@param iSystemId: int, input, the PVSS system ID of the declared _UnDistribtuedControl
	@param sHostName: string, input, the hostname of the declared _UnDistribtuedControl
	@param iPortNumber: int, input, the port number of the WCCILdist of the declared _UnDistribtuedControl
	@param exceptionInfo: dyn_string, output, the error is returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_setDeviceConfig(string sSystemName, int iSystemId, string sHostName, int iPortNumber, dyn_string &exceptionInfo)
{

	int pos;
	string systemName, hostName, sConfig, systemId, portNumber;
	
// remove the : if any	

	pos = strpos(sSystemName, ":");
	
	if(pos > 0)
		systemName = substr(sSystemName, 0, pos);
	else
		systemName = sSystemName;

	if(dpExists(c_unDistributedControl_dpName+systemName)) {
		if(sHostName == "localhost")
			hostName = "";
		else
			hostName = sHostName;
		if(iPortNumber == 0)
			portNumber = "";
		else 
			portNumber = iPortNumber;
		if(iSystemId == 0)
			systemId = "";
		else 
			systemId = iSystemId;
		sConfig=hostName+c_unDistributedControl_separator+portNumber+c_unDistributedControl_separator+systemId;
		dpSet(c_unDistributedControl_dpName+systemName+c_unDistributedControl_dpConfigElementName,sConfig);
	}
	else {
			fwException_raise(exceptionInfo, "ERROR", 
						"unDistributedControl_setDeviceConfig(): the remote system internal data point: "+systemName+" is not existing","");
	}
}

// unDistributedControl_checkCreateDp
/**
Purpose:
This function checks if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, if not it creates it.

	@param sDpName: string, input, the data point name
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
	. data point type needed: _UnDistributedControl
	. PVSS version: 3.0 
	. operating system: W2000, NT and Linux, but tested only under W2000 and Linux.
	. distributed system: yes.
*/
unDistributedControl_checkCreateDp(string sDpName, dyn_string &exceptionInfo)
{
	bool bError = false;
	
// if it is not existing creates it
	if(!dpExists(sDpName)) {
		dpCreate(sDpName, c_unDistributedControl_dpType);
// a second check is done after the creation to ensure that the data point is created (just in case of error)
// it is also a way to wait the creation which is asynchronous.
		if(!dpExists(sDpName)) {
			fwException_raise(exceptionInfo, "ERROR", 
						"unDistributedControl_checkCreateDp(): the data point: "+sDpName+" was not created","");
			bError = true;
		}
	}
}


unDistributedControl_checkSetAlias(string sDpName, string systemName, dyn_string &exceptionInfo)
{
	if(!dpExists(sDpName)) 
  {
			fwException_raise(exceptionInfo, "ERROR", 
						"unDistributedControl_checkSetAlias(): the data point: "+sDpName+" does not exist","");
	}
  else
  {
    //ensure that the dpName ends with .
    strrtrim(sDpName, ".");
    sDpName += ".";
    string currentAlias = dpGetAlias(sDpName);
    if (currentAlias == "")
    {
      dpSetAlias(sDpName, strrtrim(systemName, ":"));
    }
  }
}

//------------------------------------------------------------------------------------------------------------------------
// unDistributedControl_convertHostPort
/** convert the hostname and port number to be copatible with the centrally managed installation tool
  
@par Constraints
  None

@par Usage
  Public

@par PVSS managers
  Ui, CTRL

@param sHostName  output, the hostname
@param sPortNumber output, the port number
*/
unDistributedControl_convertHostPort(string &sHostName, string &sPortNumber)
{
  string sTemp;
  
  sTemp = strtoupper(sHostName);
  if(sTemp == "")
    sTemp = unDistributedControl_getDSHostname();
  sHostName = sTemp;
  sTemp = sPortNumber;
  if(sTemp == "")
    sTemp = fwInstallation_getDistPort();
  sPortNumber = sTemp;
}

//------------------------------------------------------------------------------------------------------------------------
// unDistributedControl_getDSHostname
/** get the hostname of the data server
  
@par Constraints
  None

@par Usage
  Public

@par PVSS managers
  Ui, CTRL

@return the hostname of the data server
*/
string unDistributedControl_getDSHostname()
{
  dyn_string ds=dataHost();
  
  return strtoupper(ds[1]);
}

//------------------------------------------------------------------------------------------------------------------------
// unDistributedControl_saveInConfigFile
/** save the dist config in the config file
  
@par Constraints
  None

@par Usage
  Public

@par PVSS managers
  Ui, CTRL

@param exceptionInfo  output, error are returned here
*/
unDistributedControl_saveInConfigFile(dyn_string &exceptionInfo)
{
	int i, length;
	string sHostName, sPortNumber;
	dyn_string dsSystemName, dsHostName;
	dyn_int diSystemId, diPortNumber;
	int res;
	dyn_string dsSection;
	
	dynAppend(dsSection, "# limits");
	dynAppend(dsSection, "maxBcmBufferSize = 120000");
	dynAppend(dsSection, "bcmBufferLimitTimeout = 120");
        // get current configs
	unDistributedControl_getAllDeviceConfig(dsSystemName, diSystemId, dsHostName, diPortNumber);
	length = dynlen(dsSystemName);
	for(i=1; i<=length;i++) {
		if(dsSystemName[i]+":" == getSystemName()) {
			if(diPortNumber[i] > 0) {
//				DebugN("distPort = " + diPortNumber[i]);
				dynAppend(dsSection, "distPort = " + diPortNumber[i]);
			}
		}
		else {
			if(diPortNumber[i] > 0)
				sPortNumber = ":"+diPortNumber[i];
			else
				sPortNumber = "";
			if(dsHostName[i] == "")
				sHostName = "localhost";
			else
				sHostName = dsHostName[i];
			dynAppend(dsSection, "distPeer = \"" + sHostName + sPortNumber + "\" "+  diSystemId[i]);
			DebugN("distPeer = \"" + sHostName + sPortNumber + "\" "+  diSystemId[i], dsHostName[i]);
		}
	}
	dynAppend(dsSection, "");
	res = fwInstallation_setSection("dist", dsSection);
//DebugN(res);
	if(res < 0)
		fwException_raise(exceptionInfo, "ERROR", "saving unDistribtuedControl configuration: cannot write config file", "");
}

//@}
