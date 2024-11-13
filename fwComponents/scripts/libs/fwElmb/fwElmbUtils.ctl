// @author Piotr Nikiel
// @date 13 Nov 2014
// numerous utils functions which may be user by fwElmb_*, fwElmbUser_* and external functions
 


/** 
  @param input 
  @param fullName - false if you just want given part of name (e.g. just bus name), true if you want whole name up to that part 
  @param whichChunk - which part of name will be the last included in resulting name
  @param result - a result string
  @param withSystemName - false if the name should get system name stripped
  @return true when successful, false otherwise
  
  Examples:
  fwElmbUtils_getNameChunk ("Systemx:ELMB/CanBus2/Node1", false, 2, result, false) gives "CanBus2"
  fwElmbUtils_getNameChunk ("Systemx:ELMB/CanBus2/Node1", true, 2, result, false) gives "ELMB/CanBus2"
  fwElmbUtils_getNameChunk ("Systemx:ELMB/CanBus2/Node1", true, 2, result, true) gives "Systemx:ELMB/CanBus2"
*/
bool fwElmbUtils_getNameChunk (string input, bool fullName, int whichChunk, string &result, bool withSystemName=false)
{
  string givenDp;
  /* Cut off system's name if user doesnt want it */
  if (withSystemName)
    givenDp = dpSubStr( input, DPSUB_SYS_DP );
  else
    givenDp = dpSubStr( input, DPSUB_DP );
  if (givenDp == "")
  {
    DebugN("dpSubStr failed, probably wrong input or nonexistent DP? Input was'"+input+"'");
    return false;
  }
  dyn_string chunks = strsplit( givenDp, fwDevice_HIERARCHY_SEPARATOR );
  /* Basic validation */
  if (whichChunk > dynlen(chunks))
  { 
    /* The name doesnt have enough chunks! */
    DebugTN ("Given input="+input+" doesnt have hierarchy chunk number "+whichChunk);
    return false;
  }
  /* Check if all chunks are non-empty strings */
  for (int i=1; i<=dynlen(chunks); i++)
  {
    if (chunks[i] == "")
    {
      DebugTN ("One chunk is empty!");
      return false;
    }
  }
  /* Now either pick just that part of name, or a fragment from beginning up to chosen chunk */
  if ( fullName )
    for (int i=1; i<=whichChunk ; i++)
    {
      result = result+chunks[i];
      if (i < whichChunk)
        result = result+fwDevice_HIERARCHY_SEPARATOR;
    }
  else
    result = chunks[dynlen(chunks)];
  return true;   
}



// look at fwElmbUtils_getNameChunk documentation
bool fwElmbUtils_getCanBusName (string input, bool fullName, string &result, bool withSystemName=false)
{
  return fwElmbUtils_getNameChunk ( input, fullName, 2, result, withSystemName); 
}

// look at fwElmbUtils_getNameChunk documentation
bool fwElmbUtils_getNodeName (string input, bool fullName, string &result, bool withSystemName=false)
{
  return fwElmbUtils_getNameChunk ( input, fullName, 3, result, withSystemName); 
}


  
/** Checks whether fwElmb entity name (bus, node, aichannel...) matches recommended pattern
  @param n - entity name to be checked
  @return true - when matches the recommended pattern
*/
bool fwElmbUtils_isNameOk (string n)
{
  /* YES I know (Piotr) this implementation looks stupid, but PVSS doesnt have any decent regular expressions.
     patternMatch function is unusable -- there isnt even a repetition of a group of characters...... */
  if (strlen(n)<1)
    return false;
  for (int i=0; i<strlen(n); i++)
  {
    string s=substr (n, i, 1);
    if (strpos ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_", s) <0 )
    {
      DebugN("This character is wrong: "+s);
      return false;
    }
      
  }
  return true;
}

bool fwElmbUtils_checkAllChunks (string n, dyn_dyn_string &results)
{
  n=dpSubStr(n, DPSUB_DP);
  dyn_string chunks = strsplit(n, fwDevice_HIERARCHY_SEPARATOR);
  for (int i=1; i<=dynlen(chunks); i++)
  {
    if (!fwElmbUtils_isNameOk(chunks[i]))
    {
      dynAppend(results, makeDynString(n, " found chunk which doesnt match recommended name pattern: "+chunks[i]));
    }
  }
}

int fwElmbUtils_getNumChunks (string n)
{
  return dynlen(strsplit( n, fwDevice_HIERARCHY_SEPARATOR ));
}

/** fwElmbUser_validateNames
  Use this function to validate correctness of names of CAN buses, ELMBs and AI channels.
  Some names are not tolerated by the CANopen server and should not be used.
  @return dyn_dyn_string - a dynamic list of pairs [dp, description] which describe encountered problems 
*/
bool fwElmbUtils_validateNames (dyn_dyn_string &result)
{
  dyn_string dsBuses, dsNodes, dsAIs;
  dsBuses = dpNames(getSystemName()+"*", ELMB_CAN_BUS_TYPE_NAME);
  dsNodes = dpNames(getSystemName()+"*", ELMB_TYPE_NAME);
  dsAIs = dpNames(getSystemName()+"*", ELMB_AI_TYPE_NAME);

  for (int i=1; i<=dynlen(dsBuses); i++)
  {
    string n = dsBuses[i];
    fwElmbUtils_checkAllChunks( n, result );
    int chunkNo = fwElmbUtils_getNumChunks (n);
    if ( chunkNo != 2)
         dynAppend (result, makeDynString(n, " wrong number of chunks: "+chunkNo));
  }

  for (int i=1; i<=dynlen(dsNodes); i++)
  {
    string n = dsNodes[i];
    fwElmbUtils_checkAllChunks( n, result );
    int chunkNo = fwElmbUtils_getNumChunks (n);
    if ( fwElmbUtils_getNumChunks (n) != 3)
         dynAppend (result, makeDynString(n, " wrong number of chunks: "+chunkNo));
  }

  for (int i=1; i<=dynlen(dsAIs); i++)
  {
    string n = dsAIs[i];
    fwElmbUtils_checkAllChunks( n, result );
    int chunkNo = fwElmbUtils_getNumChunks (n);
    if ( fwElmbUtils_getNumChunks (n) != 5)
         dynAppend (result, makeDynString(n, " wrong number of chunks: "+chunkNo));
  }  
  
  if (dynlen(result)>0)
    return false;
  else
    return true;
}

/** 
  @param stateValue state value as in CANopen
  @return string with textual representation
  @author pnikiel
  @date 02-Sep-2016
*/
string fwElmbUtils_stateValueToText( int stateValue )
{
  if (stateValue < 0 || stateValue > 255)
    return "??? "+stateValue;
  stateValue = stateValue & 0x7f;
  switch (stateValue)
  {
    case 1:    return "DISCONNECTED";
    case 4:    return "STOPPED";
    case 5:    return "OPERATIONAL";
    case 127:  return "PREOPERATIONAL";
    default:   return "???";
  }
  
}
