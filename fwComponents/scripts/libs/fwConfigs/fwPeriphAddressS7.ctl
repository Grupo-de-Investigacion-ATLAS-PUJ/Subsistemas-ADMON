
/**@file
********************************************************************************
This library contains function associated with S7 addressing.
Functions are provided to set, get and delete the addressing for a dpe

@par Creation Date
	24/04/2005

@par Modification History

  09/07/2014 Marco Boccioli
 	- @jira{FWCORE-3183} Periphery address: add convertsion types DATETIME and BLOB for S7 device.
	fwPeriphAddress_checkS7Parameters(): dataType upper limit changed from 708 to 710

  09/07/2014 Marco Boccioli
 	- @jira{FWCORE-3175}: Error when modifying S7 non-polling address
  if the address is not in polling mode, don't set the polling group

  01/08/2014 Marco Boccioli
	- @jira{FWCORE-3150} : S7 Config addresses pollgroups. Added if (pollGroup == "_") pollGroup = "";  to _fwPeriphAddressS7_set()

  12/11/2012 Marco Boccioli
	- @jira{FWCORE-3128} : Modified line on _fwPeriphAddressS7_set() :
	if(strlen(pollGroup)>0 && strpos(pollGroup,"_")!=0 && dpSubStr(pollGroup,DPSUB_SYS)==0)

  12/11/2012 Marco Boccioli
	- @jira{FWCORE-3101} : Modified line on _fwPeriphAddressS7_set() :
	if(strlen(pollGroup) && strpos(pollGroup,"_")!=0) pollGroup = "_"+pollGroup;

  13/09/2011 Marco Boccioli
  - @sav{49981}: Poll groups for S7 driver: inconsistency in poll group name.
    On _fwPeriphAddressS7_set(), the leading "_" is now added automatically if not specified.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author
	Enrique BLANCO (AB-CO)

********************************************************************************
*/

// ================================================================


//@{
//definition of constants

// definition moved to the main fwPeriphAddress
//const string fwPeriphAddress_TYPE_S7 = "S7";

const unsigned fwPeriphAddress_S7_LOWLEVEL	= 11;
const unsigned fwPeriphAddress_S7_SUBINDEX = 12;
const unsigned fwPeriphAddress_S7_START = 13;
const unsigned fwPeriphAddress_S7_INTERVAL = 14;
const unsigned fwPeriphAddress_S7_POLL_GROUP = 15;

const string UN_S7_FORMAT_BIT = "DBX";		// bit format
const string UN_S7_FORMAT_BYTE = "DBB";		// byte format
const string UN_S7_FORMAT_WORD = "DBW";   // word format
const string UN_S7_FORMAT_DOUBLE = "DBD"; // double format

// Mode (existing in PVSS)
//DPATTR_ADDR_MODE_INPUT_POLL
const unsigned UN_S7_ADDR_MODE_INOUT_TSPP = 6;
const unsigned UN_S7_ADDR_MODE_INOUT_POLL = 7;	// IN/OUT polling
const unsigned UN_S7_ADDR_MODE_INOUT_SQ = 8;
// FWCORE-3337 support for "Poll on Use" addresses; WinCC OA existing constants
// DPATTR_ADDR_MODE_INPUT_CYCLIC_ON_USE // IN/OUT polling on use (11)
// DPATTR_ADDR_MODE_IO_CYCLIC_ON_USE // IN/OUT polling on use (13)

// PLC S7 Communication internal data points
const string S7_PLC_INT_DPTYPE_CONN = "_S7_Conn";

// S7 data types constants
const int fwPeriphAddress_S7_TYPE_MIN = 700;
const int fwPeriphAddress_S7_TYPE_UNDEFINED = 700;
const int fwPeriphAddress_S7_TYPE_INT16 = 701;
const int fwPeriphAddress_S7_TYPE_INT32 = 702;
const int fwPeriphAddress_S7_TYPE_UINT16 = 703;
const int fwPeriphAddress_S7_TYPE_BYTE = 704;
const int fwPeriphAddress_S7_TYPE_FLOAT = 705;
const int fwPeriphAddress_S7_TYPE_BIT = 706;
const int fwPeriphAddress_S7_TYPE_STRING = 707;
const int fwPeriphAddress_S7_TYPE_UINT32 = 708;
const int fwPeriphAddress_S7_TYPE_DATETIME = 709;
const int fwPeriphAddress_S7_TYPE_BLOB = 710;
const int fwPeriphAddress_S7_TYPE_MAX = 710;


// Exception definitiion constants: must be matched with error catalogue(!)
const int EXC_S7ADDR_WRONG_NUM_PARAM=1;
const int EXC_S7ADDR_WRONG_ADDRTYPE=2;
const int EXC_S7ADDR_WRONG_DRIVER_NUMBER=3;
const int EXC_S7ADDR_WRONG_DATA_TYPE=4;
const int EXC_S7ADDR_WRONG_MODE=5;
const int EXC_S7ADDR_WRONG_INTERVAL=6;
const int EXC_S7ADDR_WRONG_ACTIVE=7;
const int EXC_S7ADDR_WRONG_LOWLEVEL=8;
const int EXC_S7ADDR_EMPTY=10;
const int EXC_S7ADDR_TOO_MANY_COLONS=11;
const int EXC_S7ADDR_BAD_NUM_OF_GROUPS=12;
const int EXC_S7ADDR_BAD_DATALEN=13;
const int EXC_S7ADDR_DBX_BADZBIT=21;
const int EXC_S7ADDR_DBX_BADDBXY=22;
const int EXC_S7ADDR_DBX_BADYNUMBER=23;
const int EXC_S7ADDR_DBX_BADDBX=24;
const int EXC_S7ADDR_DBX_BADXNUMBER=25;
const int EXC_S7ADDR_DBX_BADTZNUMBER=26;
const int EXC_S7ADDR_DBX_FNOTALLOWED=27;

const int EXC_S7PARSEINT=99;

//@}

//@{
/** Set the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_set instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param addressConfig	input, object containing address configuration details
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo, bool setWait=true)
{
	dyn_errClass errors;

	int driverNum, addressSubindex, mode, intervalTime, dataType;
	bool active, lowLevel;
	string addressReference, typeDriver, pollGroup, sSystemName;
	time startingTime;
	int dir;
	int iRes;
	bool failed = false;
	dyn_errClass error;

	// DebugN("FUNCTION: _fwPeriphAddressS7_set");
	// DebugN("--------------------------------");
	// DebugN(dpe, addressConfig);
	// DebugN("--------------------------------");
	fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
	if(sSystemName == "") sSystemName = getSystemName();

	// 1. Get input data
	driverNum = addressConfig[FW_PARAMETER_FIELD_DRIVER];
	addressReference = addressConfig[FW_PARAMETER_FIELD_ADDRESS];
	addressSubindex = addressConfig[FW_PARAMETER_FIELD_SUBINDEX];
	mode = addressConfig[FW_PARAMETER_FIELD_MODE];
	startingTime = addressConfig[FW_PARAMETER_FIELD_START];
	intervalTime = addressConfig[FW_PARAMETER_FIELD_INTERVAL];
	dataType = addressConfig[FW_PARAMETER_FIELD_DATATYPE];
	active = addressConfig[FW_PARAMETER_FIELD_ACTIVE];
	lowLevel = addressConfig[FW_PARAMETER_FIELD_LOWLEVEL];
	typeDriver = addressConfig[fwPeriphAddress_TYPE];
	pollGroup = addressConfig[fwPeriphAddress_S7_POLL_GROUP];


	if (pollGroup!="") {
	    // ENS-14096/FWCORE-3206: poll group internal DP should be from the same system as the one of the DPE
	    string pollGroupNoSN;
	    fwGeneral_getNameWithoutSN(pollGroup, pollGroupNoSN,exceptionInfo);
	    if (pollGroupNoSN[0]!='_') pollGroupNoSN = "_" + pollGroupNoSN;
	    pollGroup=sSystemName+pollGroupNoSN;
	}


//2. Check contents of addressConfig is consistent/coherent plus any data manipulation
	fwPeriphAddress_checkS7Parameters(addressConfig, exceptionInfo);

	dir = mode;
	if ( (dir == DPATTR_ADDR_MODE_INPUT_POLL) ||
	     (dir == UN_S7_ADDR_MODE_INOUT_POLL)  ||
	     (dir == DPATTR_ADDR_MODE_INPUT_CYCLIC_ON_USE)  ||
	     (dir == DPATTR_ADDR_MODE_IO_CYCLIC_ON_USE )
	   )
	{
		if(!dpExists(pollGroup)) {
			fwException_raise(exceptionInfo, "ERROR", "Polling group does not exist: " + pollGroup, "");
			return;
		}
	}

	if (lowLevel)
	{
		mode = mode + PVSS_ADDRESS_LOWLEVEL_TO_MODE;
	}

	//3. Set the distrib config	and driver number
	//The driver will already have been checked to see that it is running, so just dpSet/dpSetWait
	if (setWait)
	    dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
		      dpe + ":_distrib.._driver", driverNum);
	else
	    dpSet(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
		  dpe + ":_distrib.._driver", driverNum);
	errors = getLastError();
	if(dynlen(errors) > 0)
	{
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not create the distrib config.", "");
		return;
	}

	//4. Set the addressConfig data to the config
	if ((dir == DPATTR_ADDR_MODE_INPUT_POLL) ||
	     (dir == UN_S7_ADDR_MODE_INOUT_POLL) ||
	     (dir == DPATTR_ADDR_MODE_INPUT_CYCLIC_ON_USE)  ||
	     (dir == DPATTR_ADDR_MODE_IO_CYCLIC_ON_USE )
	   )
	{
		if (setWait)
		    dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				  dpe + ":_address.._reference", addressReference,
				  dpe + ":_address.._subindex", addressSubindex,
				  dpe + ":_address.._mode", mode,
				  dpe + ":_address.._start", startingTime,
				  dpe + ":_address.._interval", intervalTime / 1000.0,
				  dpe + ":_address.._datatype", dataType,
				  dpe + ":_address.._drv_ident", typeDriver,
				  dpe + ":_address.._direction", dir,
				  dpe + ":_address.._internal", false,
				  dpe + ":_address.._lowlevel", lowLevel,
				  dpe + ":_address.._poll_group", pollGroup,
				  dpe + ":_address.._active", active);  //active
		else
		    dpSet(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				  dpe + ":_address.._reference", addressReference,
				  dpe + ":_address.._subindex", addressSubindex,
				  dpe + ":_address.._mode", mode,
				  dpe + ":_address.._start", startingTime,
				  dpe + ":_address.._interval", intervalTime / 1000.0,
				  dpe + ":_address.._datatype", dataType,
				  dpe + ":_address.._drv_ident", typeDriver,
				  dpe + ":_address.._direction", dir,
				  dpe + ":_address.._internal", false,
				  dpe + ":_address.._lowlevel", lowLevel,
				  dpe + ":_address.._poll_group", pollGroup,
				  dpe + ":_address.._active", active);  //active
	}
	else
	{
		if (setWait)
		    dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				  dpe + ":_address.._reference", addressReference,
				  dpe + ":_address.._subindex", addressSubindex,
				  dpe + ":_address.._mode", mode,
				  dpe + ":_address.._start", startingTime,
				  dpe + ":_address.._interval", intervalTime / 1000.0,
				  dpe + ":_address.._datatype", dataType,
				  dpe + ":_address.._drv_ident", typeDriver,
				  dpe + ":_address.._direction", dir,
				  dpe + ":_address.._internal", false,
				  dpe + ":_address.._lowlevel", lowLevel,
				  dpe + ":_address.._active", active);  //active
		else
		    dpSet(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
				  dpe + ":_address.._reference", addressReference,
				  dpe + ":_address.._subindex", addressSubindex,
				  dpe + ":_address.._mode", mode,
				  dpe + ":_address.._start", startingTime,
				  dpe + ":_address.._interval", intervalTime / 1000.0,
				  dpe + ":_address.._datatype", dataType,
				  dpe + ":_address.._drv_ident", typeDriver,
				  dpe + ":_address.._direction", dir,
				  dpe + ":_address.._internal", false,
				  dpe + ":_address.._lowlevel", lowLevel,
				  dpe + ":_address.._active", active);  //active
	}

	errors = getLastError();
	if(dynlen(errors) > 0)
	{
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not set the " + fwPeriphAddress_TYPE_S7 + " address config.", "");
	}
}


//------------------------------------------------------------------------
/* Internal function to parse a string to integer with exceptions

  it uses(sscanf %d) and throw an exception if failed

@param[in] parsedString  - string to be parsed
@param[in] errCode - definition of the exception that should be raised;
		    by default, a generic "ParseInt error" exception
@param[in] startPos - position in the string from which the parsing should
		    start; default:0 (beginning of the string)
		    note that the fitst character is at position zero.
		    negative number specifies the position counting
		    from the end of the string
@param[in] length - length of the string that is to be parsed;
	    default: 0 means the whole string is parsed

@returns the parsed integer

@throws exception if parsing fails

Example:
@code
    try {
	string s=fwPeriphAddressS7_parseInt("a13b",EXC_S7PARSEINT,1,2);
    } catch {
	dyn_errClass e=getLastException();
	string excText=getErrorText(e);
	DebugTN("Exception encountered",excText);
    } finally {
	// cleanup
    }
@endcode

*/
int fwPeriphAddressS7_parseInt(string parsedString, int errCode=EXC_S7PARSEINT, int startPos=0, int length=0)
{
    string errCat="fwPeriphAddressS7";

    int retval;

    if (parsedString=="") throw(makeError(errCat,PRIO_SEVERE,ERR_PARAM,errCode,"parseInt empty string"));
    if (length<0) throw(makeError(errCat,PRIO_SEVERE,ERR_PARAM,errCode,"parseInt wrong string length",length));

    if (startPos<0) startPos=strlen(parsedString)+startPos;
    // now after recalculation, check if it is valid
    if ( (startPos<0) || (startPos>=strlen(parsedString)) ) throw(makeError(errCat,PRIO_SEVERE,ERR_PARAM,errCode,"parseInt wrong startPos/length",parsedString+":"+startPos+"/"+strlen(parsedString)));

    if ( (startPos != 0) || (length!=0) ) { // ie. non-default mode
	if (length == 0) {
	    parsedString=substr(parsedString,startPos);
	} else {
	    parsedString=substr(parsedString,startPos,length);
	}
    }
    int rc=sscanf(parsedString,"%d",retval);
    if (rc<=0) throw(makeError(errCat,PRIO_SEVERE,ERR_PARAM,errCode,"parseInt wrong format",parsedString));

    return retval;
}

/** Parse the DBx part of the address, throwing exceptions as necessary

*/
private void fwPeriphAddress_parseS7Address_DBx(string addr)
{
    // second group (it must be DBx where x=[1..32767]

    if (strlen(addr) < 3 ) throwS7Exception(EXC_S7ADDR_DBX_BADDBX);

    int numberS7=fwPeriphAddressS7_parseInt(addr,EXC_S7ADDR_DBX_BADXNUMBER,2);
    if ((numberS7 < 1) || (numberS7 > 32767)) throwS7Exception(EXC_S7ADDR_DBX_BADXNUMBER);

}

/**
Allowed patterns
    {T,Z}y
    {DBx.DBX , M , E , I , A , Q}y[.z]
    {DBx.DB,   M , E , I , A , Q}{B,W,D}y
    {DBx.DB,   M}DyF

Note that "DB*y" are supposed to be already truncated to "B*y"
and bit-included "Qy.z" are converted to "Q#y.z" (actually "Q#y"),
and "DBXy.z" into "X#y.z" (actually "X#y").
similarly Ty and Zy were changed to T#y and Z#y

In short: the "addr" will always have two letters: either padded with "#" on 2nd char,
or DBX truncated to BX
*/
private void fwPeriphAddress_parseS7Address_main(string addr)
{

    int len=strlen(addr);

    if (addr[0]=='T' || addr[0]=='Z' ) {
	int tz = fwPeriphAddressS7_parseInt(addr,EXC_S7ADDR_DBX_BADTZNUMBER,2);
	if (tz < 1 || tz > 65535 ) throwS7Exception(EXC_S7ADDR_DBX_BADTZNUMBER,tz);
	return;
    }

    if (len<3) throwS7Exception(EXC_S7ADDR_DBX_BADDBXY);

    const dyn_char validFirstChars  = makeDynString('X','B','M','E','I','A','Q');
    const dyn_char validSecondChars = makeDynString('#','B','W','D');


    if (!dynContains(validFirstChars, addr[0]))  throwS7Exception(EXC_S7ADDR_DBX_BADDBXY);
    if (!dynContains(validSecondChars,addr[1])) throwS7Exception(EXC_S7ADDR_DBX_BADDBXY);


    // treat the special case of MDyF and DBDyF (floating-point indicator)
    // we will simply cut it away from the address string
    if (addr[len-1]=='F') {
	if ( addr[1]=='D' && (addr[0]=='M' || addr[0]=='B') ) {
	    addr=substr(addr,0,len-1);
	    len--;
	} else {
	    throwS7Exception(EXC_S7ADDR_DBX_FNOTALLOWED);
	}
    }
    int numberS7=fwPeriphAddressS7_parseInt(addr,EXC_S7ADDR_DBX_BADYNUMBER , 2);
    if ((numberS7 < 0) || (numberS7 > 65535)) throwS7Exception(EXC_S7ADDR_DBX_BADYNUMBER);

}


//------------------------------------------------------------------------

private errClass throwS7Exception(int errCode, string errTxt="")
{
    if (errTxt) throw (makeError("fwPeriphAddressS7",PRIO_SEVERE,ERR_PARAM,errCode,errTxt));
    else        throw (makeError("fwPeriphAddressS7",PRIO_SEVERE,ERR_PARAM,errCode));
}


/** Check if data is Ok to set a S7 address

The address is generally a dot-separated string, with:
 - the first item: the name of the S7 Connections as configured in WinCC OA
 - the second item: the identification of the data block (DBx)
 - the third item: the starting address of the data inside the data block,
    plus some typing information
 - optionally, the fourth: the bit number inside a byte variable
In addition, there may be a colon plus a number, telling the length of the
 (blob) variable.
Note that in the PLC-world, the addressing would be the tokens 2,3 (and eventually 4).

There may also be the symbolic addressing. Again, the first item (before the dot)
is the connection name, while the second has some specific formatting.

It may also be a timer or a counter, in which name there are again only 2 items.

Alarm addresses ("TestS7.:1:2:3") are not supported.


Here are a couple of examples:

* MyS7Connection.DB498.DBB512:200 - data block 498, start at byte 512, take a blob,
				    and extract 200 bytes; the connection is defined
				    as "MyS7Connection" inside WinCC OA

* MyS7Connection.DB1.DBX30.3	- data block 1, start at byte 30, take bit 3 in "MyS7Connection"

* MyS7Connection.T5		- timer 5

* MyS7Connection.Z3		- counter 3

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error. If a parameter is incorrect, exceptionInfo is not empty !
*/
fwPeriphAddress_checkS7Parameters(dyn_string dsParameters, dyn_string &exceptionInfo)
{
    int driverNum, addressSubindex, mode, intervalTime, dataType, iTemp;
    string active, lowLevel;
    string addressReference;
    time startingTime;
    dyn_string addressSplit;
    bool badAddress;

    int tot_len;
    string formatS7, lastF;
    string zoneS7, sizeS7;
    int numberS7;

    // DebugN("FUNCTION: fwPeriphAddress_checkS7Parameters");
    // DebugN("--------------------------------");
    // DebugN(dsParameters);
    // DebugN("--------------------------------");


try {



    // 0. Overall format of inpur data in dsParameters
    if (dynlen(dsParameters) != FW_PARAMETER_FIELD_NUMBER) throwS7Exception(EXC_S7ADDR_WRONG_NUM_PARAM,dynlen(dsParameters));

    // 1. Type indicator
    if (dsParameters[FW_PARAMETER_FIELD_COMMUNICATION] != "S7") throwS7Exception(EXC_S7ADDR_WRONG_ADDRTYPE,dsParameters[FW_PARAMETER_FIELD_COMMUNICATION]);

    // 2. Driver number
    driverNum = fwPeriphAddressS7_parseInt(dsParameters[FW_PARAMETER_FIELD_DRIVER], EXC_S7ADDR_WRONG_DRIVER_NUMBER);
    if (driverNum < 1 || driverNum > 255) throwS7Exception(EXC_S7ADDR_WRONG_DRIVER_NUMBER,driverNum);

    // 3. Address reference

    addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
    // treat the case of having the length after the ":"
    string dataLength="";
    dyn_string ds=strsplit(addressReference,":");
    if (dynlen(ds)>2) throwS7Exception(EXC_S7ADDR_TOO_MANY_COLONS);

    if (dynlen(ds)==2) {
	addressReference=ds[1];
	dataLength=ds[2];
    }

    if (dataLength!="") {
	int len=fwPeriphAddressS7_parseInt(dataLength,EXC_S7ADDR_BAD_DATALEN);
	if (len<0 || len > 65535) throwS7Exception(EXC_S7ADDR_BAD_DATALEN,dataLength);
    }

    if (addressReference=="") throwS7Exception(EXC_S7ADDR_EMPTY);


    // if there is a dot at the end, then this means that bit specification is missing
    // and moreover, strsplit will not detect this next token
    if ( addressReference[strlen(addressReference)-1] == '.') throwS7Exception(EXC_S7ADDR_DBX_BADZBIT);


    addressSplit = strsplit(addressReference, ".");

    int numGroups=dynlen(addressSplit);
    if ( numGroups < 2 || numGroups > 4 ) throwS7Exception(EXC_S7ADDR_BAD_NUM_OF_GROUPS);

    if ( numGroups ==4 &&  ( (substr(addressSplit[2],0,2)!="DB") || (substr(addressSplit[3],0,3)!="DBX") ) ) throwS7Exception(EXC_S7ADDR_BAD_NUM_OF_GROUPS);

    if ( numGroups >=3 && substr(addressSplit[2],0,2) != "DB"  && substr(addressSplit[3],0,2) == "DB") throwS7Exception(EXC_S7ADDR_DBX_BADDBX);


    //DebugTN("addressSplit #= "+dynlen(addressSplit),addressReference);

    // let's firtly assume that we have something without a data block,
    // such as MyConnection.MBy or (with bits) MyConnection.MBy.z
    string bitPart="";
    string addrPart=addressSplit[2]; // we assume that we have something like "MBy"
    if (numGroups==3) bitPart=addressSplit[3];
    // however, if we have a data-component (DBx.DB*), we need to adjust
    if (substr(addressSplit[2],0,2) == "DB") {
	fwPeriphAddress_parseS7Address_DBx(addressSplit[2]);
	if (numGroups == 4) {
	    if (substr(addressSplit[3],0,3)!="DBX") throwS7Exception(EXC_S7ADDR_DBX_BADDBXY);
	    bitPart=addressSplit[4];
	    addrPart=substr(addressSplit[3],2); //we will replace "DBXy" into "Xy" for easier parsing logic (see also below! [***]
	    if (strlen(addrPart)<2) throwS7Exception(EXC_S7ADDR_DBX_BADYNUMBER); // it is 2 because it is the shorter address [***]
	} else {
	    // DBx.DBXy with missing z-group?
	    if (substr(addressSplit[3],0,3)=="DBX") throwS7Exception(EXC_S7ADDR_DBX_BADZBIT);

	    bitPart="";
	    addrPart=substr(addressSplit[3],1); // we will replace "DB*y" into "B*y" for easier parsing logic
	    if (strlen(addrPart)<3) throwS7Exception(EXC_S7ADDR_DBX_BADYNUMBER);
	}
    } else {
	if (strlen(addrPart)<2)  throwS7Exception(EXC_S7ADDR_DBX_BADDBXY);
	// catch the Ey.z without the z part...
	if (addrPart[0]=='M' || addrPart[0]=='E' || addrPart[0]=='I' || addrPart[0]=='A' || addrPart[0]=='Q') {
	    if (addrPart[1]!='B' && addrPart[1]!='W' && addrPart[1]!='D')
		if (numGroups!=3) throwS7Exception(EXC_S7ADDR_DBX_BADZBIT);
	}

	if ( (addrPart[0]=='T' || addrPart[0]=='Z') && numGroups!=2 ) throwS7Exception(EXC_S7ADDR_BAD_NUM_OF_GROUPS);

    }

    // [***] in case we have bits, we fill the address with "#" on the 2nd char so that it makes parsing easier
    // "My.z" -> "M#y.z" (resembles MBy)
    // and we do the same for timers and counters T5-> T#5
    if (bitPart!="" || addrPart[0]=='T' || addrPart[0]=='Z') addrPart=substr(addrPart,0,1) + "#" + substr(addrPart,1);


    fwPeriphAddress_parseS7Address_main( addrPart);

    // finnish off the bits, if they exist
    if (bitPart!="") {
	iTemp=fwPeriphAddressS7_parseInt(bitPart,EXC_S7ADDR_DBX_BADZBIT);
	if (iTemp < 0 || iTemp > 7) throwS7Exception(EXC_S7ADDR_DBX_BADZBIT);
    }

    // 4  Subindex

    // 5. Mode
    mode = fwPeriphAddressS7_parseInt(dsParameters[FW_PARAMETER_FIELD_MODE],EXC_S7ADDR_WRONG_MODE);

    // 6. Starting time : no check
    //startingTime = dsParameters[FW_PARAMETER_FIELD_START];

    // 7. Interval Time
    intervalTime = fwPeriphAddressS7_parseInt(dsParameters[FW_PARAMETER_FIELD_INTERVAL],EXC_S7ADDR_WRONG_INTERVAL);

    // 8. Data type
    dataType = fwPeriphAddressS7_parseInt(dsParameters[FW_PARAMETER_FIELD_DATATYPE],EXC_S7ADDR_WRONG_DATA_TYPE);
    if (dataType < fwPeriphAddress_S7_TYPE_MIN || dataType > fwPeriphAddress_S7_TYPE_MAX) throwS7Exception(EXC_S7ADDR_WRONG_DATA_TYPE,dataType);

    // 9. Address active
    active = dsParameters[FW_PARAMETER_FIELD_ACTIVE];
    if ((active != "FALSE") && (active != "TRUE") && (active != "0") && (active != "1"))  throwS7Exception(EXC_S7ADDR_WRONG_ACTIVE,active);

    // 10. Lowlevel
    lowLevel = dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
    if ((lowLevel != "FALSE") && (lowLevel != "TRUE") && (lowLevel != "0") && (lowLevel != "1")) throwS7Exception(EXC_S7ADDR_WRONG_LOWLEVEL,lowLevel);

} catch {

    string errMsg="fwPeriphAddress_checkS7Parameters: "+getErrorText(getLastException());
    // complement the error message so that we know for which address the exception appeared
    if ( dynlen(dsParameters)>=FW_PARAMETER_FIELD_ADDRESS && dsParameters[FW_PARAMETER_FIELD_ADDRESS]!="") errMsg+="; while checking "+dsParameters[FW_PARAMETER_FIELD_ADDRESS];

    fwException_raise(exceptionInfo, "ERROR", errMsg, "");
    return;
}
}


/** Get the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_get instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to read
@param addressConfig	output, object containing address configuration details
@param isActive		output, TRUE is addressing is active, else FALSE
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
	// DebugN("FUNCTION: _fwPeriphAddressS7_get");
	// DebugN("--------------------------------");
	// DebugN(dpe,addressConfig,isActive);
	// DebugN("--------------------------------");
	int					iDriver, iDirection;

	//1. Get the driver number and address config contents
	//It will already be known that the config exists so you can just do dpGet
	dpGet(		dpe + ":_address.._drv_ident", addressConfig[fwPeriphAddress_TYPE],
				dpe + ":_distrib.._driver", iDriver,
				dpe + ":_address.._reference", addressConfig[fwPeriphAddress_REFERENCE],
				// dpe + ":_address.._mode", addressConfig[fwPeriphAddress_DIRECTION],
				dpe + ":_address.._direction", iDirection,
				dpe + ":_address.._start", addressConfig[fwPeriphAddress_S7_START],
				dpe + ":_address.._interval", addressConfig[fwPeriphAddress_S7_INTERVAL],
				dpe + ":_address.._datatype", addressConfig[fwPeriphAddress_DATATYPE],
				dpe + ":_address.._subindex", addressConfig[fwPeriphAddress_S7_SUBINDEX],
				dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_S7_POLL_GROUP],
				dpe + ":_address.._lowlevel", addressConfig[fwPeriphAddress_S7_LOWLEVEL],
				dpe + ":_address.._active", addressConfig[fwPeriphAddress_ACTIVE]);

	addressConfig[fwPeriphAddress_DRIVER_NUMBER] = iDriver;
	addressConfig[fwPeriphAddress_DIRECTION] = iDirection;

	//2. Do any necessary manipulation of the data that was read
	// DebugN("_fwPeriphAddressS7_get() ...> addressConfig= ",addressConfig);
	//3. Set the isActive value - by default this will be the same as addressConfig[fwPeriphAddress_ACTIVE]
	isActive = addressConfig[fwPeriphAddress_ACTIVE];
}

/** Delete the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_delete instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_delete(string dpe, dyn_string &exceptionInfo)
{
	//1. If only the address and distrib config need deleting then do nothing here.
	//NOTE: This function is called BEFORE the address config is deleted.
	// DebugN("FUNCTION: _fwPeriphAddressS7_delete");
	// DebugN("--------------------------------");
	// DebugN(dpe);
	// DebugN("--------------------------------");
}


/** Initialise the graphics of the address panel symbol.
Note: This function should only be called from fwPeriphAddres.pnl.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param dpe						input, data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_initPanel(string dpe, dyn_string &exceptionInfo)
{

	int i;

	bool configExists, isActive;
	dyn_anytype addressConfig;

	string transf_ini = "default"; 	// transformation mode
	int dirMode_ini = 1;	 // directionMode
	int recMode_ini = 1; // receiveMode
	bool active_ini = 1;		// active
	bool lowlevel_ini = 0;	// lowlevel
	string pollGroup_ini = "";
	string reference1_ini;		// only possible ini afterwards
	string reference2_ini = "MW0";
	int driverNum_ini = 2;
	string sSystemName;
	dyn_string s7Connections; // available S7 connections already defined
	dyn_string dsPlc;

	// DebugN("FUNCTION: _fwPeriphAddressS7_initPanel");
	// DebugN("--------------------------------");
	// DebugN(dpe);
	// DebugN("--------------------------------");

	fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
	if(sSystemName == "")
	{
		sSystemName = getSystemName();
	}

	//1. Get the current config
	fwPeriphAddress_get(dpe, configExists, addressConfig, isActive, exceptionInfo);
	if(dynlen(exceptionInfo) > 0)
	{
		return;
	}

	dsPlc = dpNames(sSystemName + "*", "_PollGroup");
	for ( i = dynlen(dsPlc); i > 0; i-- )
	{
		// don't display redundant datapoints
		if ( i > 1 &&
				strpos(dsPlc[i], "_2") == strlen(dsPlc[i]) - 2 &&
				dsPlc[i] == dsPlc[i - 1] + "_2"
		   )
		{
			dynRemove(dsPlc, i);
		}

//    if ( dpSubStr(dsPlc[i],DPSUB_SYS) == "System1:" ) // NoCheckWarning
		if ( i <= dynlen(dsPlc) )
		{
			dsPlc[i] = dpSubStr(dsPlc[i], DPSUB_DP);
			if ( dsPlc[i][0] == "_" )
			{
				dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i]) - 1);
			}
		}
	}
	cmbPollGroupS7.items = dsPlc;

	if(configExists && addressConfig[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_S7)
	{
		//2. If the config exists, and it is of the required addressing type, display the current information
		// DebugN("FUNCTION: CONFIG EXISTS !!!! _fwPeriphAddressS7_initPanel: configtype= "+addressConfig[fwPeriphAddress_TYPE]);
// 		if(addressConfig[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_S7)
//			{
		switch(addressConfig[fwPeriphAddress_DATATYPE])
		{
			case fwPeriphAddress_S7_TYPE_UNDEFINED:
				transf_ini = "default";
				break;
			case fwPeriphAddress_S7_TYPE_INT16:
				transf_ini = "int 16";
				break;
			case fwPeriphAddress_S7_TYPE_INT32:
				transf_ini = "int 32";
				break;
			case fwPeriphAddress_S7_TYPE_UINT16:
				transf_ini = "uint 16";
				break;
			case fwPeriphAddress_S7_TYPE_BYTE:
				transf_ini = "byte";
				break;
			case fwPeriphAddress_S7_TYPE_FLOAT:
				transf_ini = "float";
				break;
			case fwPeriphAddress_S7_TYPE_BIT:
				transf_ini = "boolean";
				break;
			case fwPeriphAddress_S7_TYPE_STRING:
				transf_ini = "string";
				break;
			case fwPeriphAddress_S7_TYPE_UINT32:
				transf_ini = "uint 32";
				break;
			case fwPeriphAddress_S7_TYPE_DATETIME:
				transf_ini = "dateTime";
				break;
			case fwPeriphAddress_S7_TYPE_BLOB:
				transf_ini = "blob";
				break;
			default:
				transf_ini = "default";
		}

		// DebugN("dataType= "+transf_ini);
		switch (addressConfig[fwPeriphAddress_DIRECTION])
		{
			case DPATTR_ADDR_MODE_OUTPUT:
				dirMode_ini = 0;
				break;
			case DPATTR_ADDR_MODE_INPUT_SPONT:
				dirMode_ini = 1;
				recMode_ini = 0;
				break;
			case DPATTR_ADDR_MODE_INPUT_POLL:
				dirMode_ini = 1;
				recMode_ini = 1;
				break;
			case DPATTR_ADDR_MODE_INPUT_SQUERY:
				dirMode_ini = 1;
				recMode_ini = 2;
				break;
			case 6:
				dirMode_ini = 2;
				recMode_ini = 0;
				break;
			case 7:
				dirMode_ini = 2;
				recMode_ini = 1;
				break;
			case 8:
				dirMode_ini = 2;
				recMode_ini = 2;
				break;
			case DPATTR_ADDR_MODE_UNDEFINED:
				dirMode_ini = 0;
				break;
			default:
				dirMode_ini = 0;
		}

		// DebugN("dirMode_ini= "+dirMode_ini+" recMode_ini= "+recMode_ini);
		// Active
		// active_ini=addressConfig[fwPeriphAddress_ACTIVE];
		active_ini = isActive;
		// Lowlevel
		lowlevel_ini = addressConfig[FW_PARAMETER_FIELD_LOWLEVEL];

		// DebugN("active_ini= "+active_ini+" lowlevel_ini= "+lowlevel_ini);
		// driver number
		driverNum_ini = addressConfig[fwPeriphAddress_DRIVER_NUMBER];
		// DebugN("--> Driver number (Existing) = "+driverNum_ini);




		// poll group
		pollGroup_ini = addressConfig[fwPeriphAddress_S7_POLL_GROUP];
		if (pollGroup_ini!="") {
		    // ENS-14096/FWCORE-3206: poll group internal DP should be from the same system as the one of the DPE
		    string pollGroupNoSN;
		    fwGeneral_getNameWithoutSN(pollGroup_ini, pollGroup_ini,exceptionInfo);
		    if (pollGroup_ini[0]=='_') pollGroup_ini = substr(pollGroup_ini,1);
		}



//				DebugN("driverNum_ini= "+driverNum_ini+" pollGroup_ini= "+pollGroup_ini);

		// Reference:  Format: S7conn.reference  : i.e.: S7_PLC1.DB20.DBW10
		reference1_ini = substr(addressConfig[fwPeriphAddress_REFERENCE], 0, strpos(addressConfig[fwPeriphAddress_REFERENCE], "."));
		reference2_ini = substr(addressConfig[fwPeriphAddress_REFERENCE], strpos(addressConfig[fwPeriphAddress_REFERENCE], ".") + 1);
		// DebugN("reference1_ini= "+reference1_ini);
		// DebugN("reference2_ini= "+reference2_ini);

		// Initial values get from provided DPE
		setMultiValue("s7ConnNames", "text", reference1_ini,
					  "directionModeS7", "number", dirMode_ini,
					  "receiveMode", "number", recMode_ini,
					  "lowlevelS7", "state", 0, lowlevel_ini,
					  "addressActiveS7", "state", 0, active_ini,
					  "driverNumberSelectorS7", "text", driverNum_ini,
					  "cmbPollGroupS7", "text", pollGroup_ini,
					  "trans_art", "text", transf_ini);

		setValue("var_name", "text", s7ConnNames.text + "." + reference2_ini);
		// DebugN("var_name= "+s7ConnNames.text +"."+reference2_ini);



		// just set the S7 values
		reference2_ini = _fwPeriphAddressS7_setValuesFromRef(reference2_ini, sSystemName);
	}
	else
	{
		//3. If the config does not exist, set a clean default for the user to start entering data
		// DebugN("FUNCTION: _fwPeriphAddressS7_initPanel: config type does not exists");
		// look for the defined S7 connections
		s7Connections = dpNames(sSystemName + "*", S7_PLC_INT_DPTYPE_CONN);
		for ( i = dynlen(s7Connections); i > 0; i-- )
		{
			// don't display redundant datapoints
			if ( isReduDp( s7Connections[i] ))
			{
				dynRemove(s7Connections, i);
			}
		}
		if ( dynlen(s7Connections) > 0 )
			for ( i = 1; i <= dynlen(s7Connections); i++ )
			{
				s7Connections[i] = dpSubStr(s7Connections[i], DPSUB_DP);
				s7Connections[i] = substr(s7Connections[i], 1, strlen(s7Connections[i]) - 1);
			}
		else
		{
			fwException_raise(exceptionInfo, "WARNING", "fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7", "S7NOTDEFCONNS"), "");
			// DebugN("No S7 Connection defined, please define it before....");
		}

		// Set
		// Initial values get from provided DPE
		setMultiValue("directionModeS7", "number", dirMode_ini,
					  "receiveMode", "number", recMode_ini,
					  "lowlevelS7", "state", 0, lowlevel_ini,
					  "addressActiveS7", "state", 0, active_ini,
					  "driverNumberSelectorS7", "text", driverNum_ini,
					  // "s7ConnNames","text",reference1_ini,
					  // "cmbPollGroupS7", "text",pollGroup_ini,
					  "trans_art", "text", transf_ini);

		setValue("var_name", "text", s7ConnNames.text + "." + reference2_ini);
		cmbPollGroupS7.selectedPos = 1;
		// just set the S7 values
		reference2_ini = _fwPeriphAddressS7_setValuesFromRef(reference2_ini, sSystemName);
	}

	//4. It may also be necessary to hide some of the graphical objects in the symbol
	//NOTE: By default, all the graphical objects will be visible before this function is called.

	// Polling config visible or not
	_fwPeriphAddressS7_setIOMode(directionModeS7.number, receiveMode.number, sSystemName);
}


// --------------------- SUPPORT FUNCTIONS -------------------------


/** Set S7 panel values
Note: This function fills the panel fields in funciton of the REFERENCE selected by the user in several fields
			of the fwPeriphAddressS7.pnl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param reference		input, user introduced reference
@param sSystemName				input, system name
@return			output, encoded S7 address
*/
string _fwPeriphAddressS7_setValuesFromRef(string reference, string sSystemName)
{
	string  typ;     // Bausteintyp
	int     nr;      // Bausteinnr
	int     adr;     // Adresse fuer DB
	string  fmt;     // Datenformat
	int     i, j;    // ne variable halt
	string s1, s2, s3, s4;
	int i1, i2, i3;
	int x, y, z, n;
	string symb;
	string transformation;

	// DebugN("FUNCTION: _fwPeriphAddressS7_setValuesFromRef(), reference= "+reference);

	transformation = trans_art.text	;

	if (reference == "" || reference == "0")
	{
		reference = "DB1DW0";
	}

	sscanf(reference, "%[^0-9]%d%[^0-9]%d%[^0-9]%d%[^0-9]", s1, i1, s2, i2, s3, i3, s4);
	// DebugN("FUNCTION: _fwPeriphAddressS7_setValuesFromRef(), s1= "+s1+" i1= "+i1+" s2= "+s2+" i2= "+i2+" s3= "+s3+" i3= "+i3+" s4= "+s4 );

	pa_x.text = 1;
	pa_x.sbMinimum = 1;
	pa_x.sbMaximum = 32767;
	pa_y.text = 0;
	pa_y.sbMinimum = 0;
	pa_y.sbMaximum = 65535;
	pa_z.text = 0;
	pa_z.sbMinimum = 0;
	pa_z.sbMaximum = 7;
	pa_n.text = 0;
	pa_n.sbMinimum = 0;
	pa_n.sbMaximum = 127;

	if ( s1 == "M" )
	{
		if ( transformation != "boolean" && transformation != "string" && transformation != "default")
		{
			transformation =  "boolean";
		}

		y = i1;
		z = i2;

		pa_typ.selectedPos(1);
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = TRUE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		// DebugN("pa_y.text= "+y+ "pa_z.text= "+z);
		pa_y.text = y;
		pa_z.text = z;
	}
	else if ( s1 == "DB" && s2 == ".DBX")
	{
		if ( transformation != "boolean" && transformation != "string" && transformation != "default")
		{
			transformation =  "boolean";
		}
		x = i1;
		y = i2;
		z = i3;
		pa_x.sbMaximum = 8191;
		pa_typ.selectedPos(2);
		pa_x.visible	= TRUE;
		pa_y.visible	= TRUE;
		pa_z.visible = TRUE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_x.text = x;
		pa_y.text = y;
		pa_z.text = z;
	}
	else if ( s1 == "E" || s1 == "I")
	{
		if ( transformation != "boolean" && transformation != "string" && transformation != "default")
		{
			transformation = "boolean";
		}
		y = i1;
		z = i2;
		if (s1 == "E")
		{
			pa_typ.selectedPos(3);
		}
		else
		{
			pa_typ.selectedPos(4);
		}
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = TRUE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= FALSE;
		pa_y.text = y;
		pa_z.text = z;
		_fwPeriphAddressS7_setIOMode(1, 0, sSystemName);

	}
	else if ( (s1 == "A" || s1 == "Q") && s2 == ".")
	{
		if ( transformation != "boolean" && transformation != "string" && transformation != "default")
		{
			transformation =  "boolean";
		}
		y = i2;
		z = i3;
		if (s1 == "A")
		{
			pa_typ.selectedPos(5);
		}
		else
		{
			pa_typ.selectedPos(6);
		}

		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = TRUE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
		pa_z.text = z;
	}
	else if ( s1 == "MB" && s2 == "")
	{
		if ( transformation != "byte" && transformation != "string" && transformation != "default" && transformation != "boolean")
		{
			transformation = "byte";
		}
		y = i1;
		pa_typ.selectedPos(7);
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "DB" && s2 == ".DBB")
	{
		if ( transformation != "byte" && transformation != "string" && transformation != "default" && transformation != "boolean")
		{
			transformation =  "byte";
		}
		x = i1;
		y = i2;
		pa_typ.selectedPos(8);
		pa_x.visible	= TRUE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_x.text = x;
		pa_y.text = y;
	}
	else if ( s1 == "EB" || s1 == "IB")
	{
		if ( transformation != "byte" && transformation != "string" && transformation != "default" && transformation != "boolean")
		{
			transformation =  "byte";
		}
		y = i1;
		if (s1 == "EB")
		{
			pa_typ.selectedPos(9);
		}
		else
		{
			pa_typ.selectedPos(10);
		}

		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= FALSE;
		pa_y.text = y;
		_fwPeriphAddressS7_setIOMode(1, 0, sSystemName);
	}
	else if ( s1 == "AB" || s1 == "QB")
	{
		if ( transformation != "byte" && transformation != "string" && transformation != "default" && transformation != "boolean")
		{
			transformation = "byte";
		}
		y = i1;
		if (s1 == "AB")
		{
			pa_typ.selectedPos(11);
		}
		else
		{
			pa_typ.selectedPos(12);
		}

		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "MW")
	{
		if ( transformation != "int 16" && transformation != "default")
		{
			transformation = "int 16";
		}
		y = i1;
		pa_typ.selectedPos(13);
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "DB" && s2 == ".DBW")
	{
		if ( transformation != "int 16" && transformation != "default")
		{
			transformation = "int 16";
		}
		x = i1;
		y = i2;
		pa_typ.selectedPos(14);
		pa_x.visible	= TRUE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_x.text = x;
		pa_y.text = y;
	}
	else if ( s1 == "EW" || s1 == "IW")
	{
		if ( transformation != "int 16" && transformation != "default")
		{
			transformation = "int 16";
		}
		y = i1;
		if (s1 == "EW")
		{
			pa_typ.selectedPos(15);
		}
		else
		{
			pa_typ.selectedPos(16);
		}
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= FALSE;
		pa_y.text = y;
		_fwPeriphAddressS7_setIOMode(1, 0, sSystemName);
	}
	else if ( s1 == "AW" || s1 == "QW")
	{
		if ( transformation != "int 16" && transformation != "default")
		{
			transformation = "int 16";
		}
		y = i1;
		if (s1 == "E")
		{
			pa_typ.selectedPos(17);
		}
		else
		{
			pa_typ.selectedPos(18);
		}
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "MD" && s2 == "")
	{
		if ( transformation != "int 32" && transformation != "default" && transformation != "uint 32")
		{
			transformation = "int 32";
		}
		y = i1;
		pa_typ.selectedPos(19);
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "DB" && s2 == ".DBD" && s3 == "")
	{
		if ( transformation != "int 32" && transformation != "default" && transformation != "uint 32")
		{
			transformation = "int 32";
		}
		x = i1;
		y = i2;
		pa_typ.selectedPos(20);
		pa_x.visible	= TRUE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_x.text = x;
		pa_y.text = y;
	}
	else if ( s1 == "MD" && s2 == "F")
	{
		if ( transformation != "float" && transformation != "default")
		{
			transformation = "float";
		}
		y = i1;
		pa_typ.selectedPos(21);
		pa_x.visible	= FALSE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_y.text = y;
	}
	else if ( s1 == "DB" && s2 == ".DBD" && s3 == "F")
	{
		if ( transformation != "float" && transformation != "default")
		{
			transformation = "float";
		}
		x = i1;
		y = i2;
		pa_typ.selectedPos(22);
		pa_x.visible	= TRUE;
		pa_y.visible	= TRUE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_x.text = x;
		pa_y.text = y;
	}
	else if ( s1 == "T")
	{
		if ( transformation != "uint 16" && transformation != "default")
		{
			transformation = "uint 16";
		}
		n = i1;
		pa_typ.selectedPos(23);
		pa_x.visible	= FALSE;
		pa_y.visible	= FALSE;
		pa_z.visible = FALSE;
		pa_n.visible = TRUE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_n.text = n;
	}
	else if ( s1 == "Z")
	{
		if ( transformation != "uint 16" && transformation != "default")
		{
			transformation = "uint 16";
		}
		n = i1;
		pa_typ.selectedPos(24);
		pa_x.visible	= FALSE;
		pa_y.visible	= FALSE;
		pa_z.visible = FALSE;
		pa_n.visible = TRUE;
		pa_symb.visible = FALSE;
		directionModeS7.enabled	= TRUE;
		pa_n.text = n;
	}
	else
	{
		symb = s1;
		pa_typ.selectedPos(25);
		pa_x.visible	= FALSE;
		pa_y.visible	= FALSE;
		pa_z.visible = FALSE;
		pa_n.visible = FALSE;
		pa_symb.visible = TRUE;
		directionModeS7.enabled	= TRUE;
		pa_symb.text = symb;
	}


	trans_art.text = transformation	;
	txt_x.visible	= pa_x.visible;
	txt_y.visible	= pa_y.visible;
	txt_z.visible	= pa_z.visible;
	txt_n.visible	= pa_n.visible;
	txt_symb.visible	= pa_symb.visible;
	bu_symb.visible	= pa_symb.visible;

	return _fwPeriphAddressS7_encodeAddress();
}

/** Recuperate transformation type
Note: This function recuperates the selected trasnforamtion type selected by the user in several fields
			of the fwPeriphAddressS7.pnl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@return	output, transformation type: i.e.: "701 --> int 16"
*/
int _fwPeriphAddressS7_getTransfo()
{
	string item;

	getValue("trans_art", "text", item);
	switch (item) {
	    case "default": return fwPeriphAddress_S7_TYPE_UNDEFINED;
	    case "int 16":  return fwPeriphAddress_S7_TYPE_INT16;
	    case "int 32":  return fwPeriphAddress_S7_TYPE_INT32;
	    case "uint 16": return fwPeriphAddress_S7_TYPE_UINT16;
	    case "byte":    return fwPeriphAddress_S7_TYPE_BYTE;
	    case "float":   return fwPeriphAddress_S7_TYPE_FLOAT;
	    case "boolean": return fwPeriphAddress_S7_TYPE_BIT;
	    case "string":  return fwPeriphAddress_S7_TYPE_STRING;
	    case "uint 32": return fwPeriphAddress_S7_TYPE_UINT32;
	    case "dateTime":return fwPeriphAddress_S7_TYPE_DATETIME;
	    case "blob":    return fwPeriphAddress_S7_TYPE_BLOB;
	    default:        return fwPeriphAddress_S7_TYPE_UNDEFINED;
	}
}

/** Encode the S7 address
Note: This function encodes the S7 address introduced by the user in several fields
			of the fwPeriphAddressS7.pnl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@return	correct address S7 type. i.e.: "DB100.DBX200.1"
*/
string  _fwPeriphAddressS7_encodeAddress()
{
	int    typ, x, y, z, n;
	string pa, symb;

	getMultiValue("pa_typ", "selectedPos", typ,
				  "pa_x", "text", x,
				  "pa_y", "text", y,
				  "pa_z", "text", z,
				  "pa_n", "text", n,
				  "pa_symb", "text", symb);
	switch (typ)
	{
		case 1 :
			pa = "M" + y + "." + z;
			break;
		case 2 :
			pa = "DB" + x + ".DBX" + y + "." + z;
			break;
		case 3 :
			pa = "E" + y + "." + z;
			break;
		case 4 :
			pa = "I" + y + "." + z;
			break;
		case 5 :
			pa = "A" + y + "." + z;
			break;
		case 6 :
			pa = "Q" + y + "." + z;
			break;
		case 7 :
			pa = "MB" + y ;
			break;
		case 8 :
			pa = "DB" + x + ".DBB" + y ;
			break;
		case 9 :
			pa = "EB" + y ;
			break;
		case 10:
			pa = "IB" + y ;
			break;
		case 11:
			pa = "AB" + y ;
			break;
		case 12:
			pa = "QB" + y ;
			break;
		case 13:
			pa = "MW" + y ;
			break;
		case 14:
			pa = "DB" + x + ".DBW" + y ;
			break;
		case 15:
			pa = "EW" + y ;
			break;
		case 16:
			pa = "IW" + y ;
			break;
		case 17:
			pa = "AW" + y ;
			break;
		case 18:
			pa = "QW" + y ;
			break;
		case 19:
			pa = "MD" + y ;
			break;
		case 20:
			pa = "DB" + x + ".DBD" + y;
			break;
		case 21:
			pa = "MD" + y + "F";
			break;
		case 22:
			pa = "DB" + x + ".DBD" + y + "F";
			break;
		case 23:
			pa = "T" + n;
			break;
		case 24:
			pa = "Z" + n;
			break;
		case 25:
			pa = symb;
			break;
		default:
			pa = "";
	}

	return pa;
}

/** Get the S7 IO mode
Note: This function gets the IO mode from the user selection in the _fwPeriphAddressS7.pnl.
			new constants are defined to the In/out modes

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param directionModeS7			input, direction mode (Output, Input, Input/Output)
@param receiveMode				input, type mode (TSPP, Polling, Single Query)
*/
int _fwPeriphAddressS7_getDir(int directionModeS7, int receiveMode)
{
	int address_mode;

	switch (directionModeS7)
	{
		case 0:
			address_mode = DPATTR_ADDR_MODE_OUTPUT;
			break;
		case 1:
			if 			(receiveMode == 0)
			{
				address_mode = DPATTR_ADDR_MODE_INPUT_SPONT;
			}
			else if (receiveMode == 1)
			{
				address_mode = DPATTR_ADDR_MODE_INPUT_POLL;
			}
			else if (receiveMode == 2)
			{
				address_mode = DPATTR_ADDR_MODE_INPUT_SQUERY;
			}
			break;
		case 2:
			if 			(receiveMode == 0)
			{
				address_mode = UN_S7_ADDR_MODE_INOUT_TSPP;    // In/Out TSPP
			}
			else if (receiveMode == 1)
			{
				address_mode = UN_S7_ADDR_MODE_INOUT_POLL;    // In/Out Polling
			}
			else if (receiveMode == 2)
			{
				address_mode = UN_S7_ADDR_MODE_INOUT_SQ;    // In/Out SQuery
			}
			break;
		default:
			address_mode = DPATTR_ADDR_MODE_UNDEFINED;
	}
	return address_mode;
}

/** Set the S7 IO mode
Note: This function sets the IO mode from the user selection.
			There is the case "1" which is also used to set up the INPUT mode when
			user introduce an PLC peripherial INPUT from the address field.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param io				input, direction mode (Output, Input, Input/Output)
@param im				input, type mode (TSPP, Polling, Single Query)
@param sSystemName				input, system name
*/
_fwPeriphAddressS7_setIOMode(int io, int im, string sSystemName)
{
	int i;
	dyn_string dsPlc;
	bool alreadyVisible;

	// int  im = receiveMode.number;
	// DebugN("FUNCTION: _fwPeriphAddressS7_setIOMode(io="+io+" im="+im);

	if (io == 1)												//	case selected address = input !!
	{
		directionModeS7.number = io;
	}

	// RadioButton: Should be the input + 1 to get { 1=output, 2= xx, 3 = xxx)
	io++;
	if ( io == 2 )													// modus IN TSPP
	{
		if ( im == 1 )
		{
			io = 4;    // modus: IN polling
		}
		else if ( im == 2 )
		{
			io = 3;    // modus: IN singlequery
		}
	}
	else if ( io == 3 )
	{
		if ( im == 0 )
		{
			io = 6;    // modus IN/OUT: TSPP
		}
		else if ( im == 1 )
		{
			io = 7;    // modus IN/OUT: polling
		}
		else
		{
			io = 8;    // modus IN/OUT: SQ
		}
	}

	// visibility of certain elements
	setMultiValue("text_rm", "visible", (io > 1),
				  "border_rm", "visible", (io > 1),
				  "receiveMode", "visible", (io > 1),
				  "lowlevelS7", "visible", (io > 1));

	//!!!pollgroup
	if (shapeExists("frmPollGroupS7"))
	{
		alreadyVisible = cmbPollGroupS7.visible;
		frmPollGroupS7.visible = (io == 4 || io == 7);
		txtPollGroupS7.visible = (io == 4 || io == 7);
		cmbPollGroupS7.visible = (io == 4 || io == 7);
		cmdPollGroupS7.visible = (io == 4 || io == 7) & (sSystemName == getSystemName());

		if (cmbPollGroupS7.visible)
		{
			// DebugN("Shape POLLGROUP visible");
			// Init the poll group to the first existing one (if ever exists)
			dsPlc = dpNames(sSystemName + "*", "_PollGroup");

			for ( i = dynlen(dsPlc); i > 0; i-- )
			{
				// don't display redundant datapoints
				if ( i > 1 && strpos(dsPlc[i], "_2") == strlen(dsPlc[i]) - 2 && dsPlc[i] == dsPlc[i - 1] + "_2")
				{
					dynRemove(dsPlc, i);
				}

				if ( i <= dynlen(dsPlc) )
				{
					dsPlc[i] = dpSubStr(dsPlc[i], DPSUB_DP);
					if ( dsPlc[i][0] == "_" )
					{
						dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i]) - 1);
					}
				}
			}

			cmbPollGroupS7.items = dsPlc;
			if (!alreadyVisible)
			{
				cmbPollGroupS7.selectedPos = 1;
			}
		}
	}
}

//@}
