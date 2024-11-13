/**
* This file contains OPCUA specific functions for fwPeriphAddress.
*/

/**
* Get a list of subscriptions on the system for the given server.
*
* @param sSystem        The system.
* @param sServer        The server.
* @param &exceptionInfo Exceptions.
*
* @return dyn_string A list of subscriptions.
*/
public dyn_string fwPeriphAddressOPCUA_getSubscriptions(string sSystem, string sServer, dyn_string &exceptionInfo)
{
  int iRetVal, iLen, iLoop;
  string sDpe;
  dyn_string dsSubscription;


  if( strlen(sSystem) == 0 )
  {
    fwException_raise(exceptionInfo, "ERROR", "No system", "");
    return makeDynString();
  }

  sDpe = sSystem + "_" + sServer + ".Config.Subscriptions:_original.._value";
  if( !dpExists(sDpe) )
  {
    if( strlen(sServer) == 0 )
    {
      fwException_raise(exceptionInfo, "ERROR", "No OPCUA server", "");
      return dsSubscription;
    }
    fwException_raise(exceptionInfo, "ERROR", "Subscriptions DPE does not exist", "");
    return dsSubscription;
  }

  iRetVal = dpGet(sDpe, dsSubscription);
  if( iRetVal == -1 )
  {
    fwException_raise(exceptionInfo, "ERROR", "Could not get subscriptions: dpGet(" + sDpe + ") failed", "");
    return dsSubscription;
  }

  iLen = dynlen(dsSubscription);
  for( iLoop = 1 ; iLoop <= iLen ; iLoop++ )
  {
    dsSubscription[iLoop] = dpSubStr(dsSubscription[iLoop], DPSUB_DP);
    dsSubscription[iLoop] = substr(dsSubscription[iLoop], 1, strlen(dsSubscription[iLoop]) - 1);
  }
  dynSortAsc(dsSubscription);

  return dsSubscription;
}



/**
* Get the type for the given subscription.
*
* @param sSys          The system.
* @param sSubscription The subscription.
*
* @return int The type or -1 on error.
*/
public int fwPeriphAddressOPCUA_getSubscriptionType(string sSystem, string sSubscription, dyn_string &exceptionInfo)
{
  int iType, iRetVal;
  string sDpe;


  if( strlen(sSystem) == 0 )
  {
    fwException_raise(exceptionInfo, "ERROR", "No system", "");
    return -1;
  }


  sDpe = sSystem + "_" + sSubscription + ".Config.SubscriptionType";
  if( !dpExists(sDpe) )
  {
    if( strlen(sSubscription) == 0 )
    {
      fwException_raise(exceptionInfo, "ERROR", "No subscription", "");
      return -1;
    }

    fwException_raise(exceptionInfo, "ERROR", "Subscription type DPE does not exist", "");
    return -1;
  }

  iRetVal = dpGet(sDpe, iType);
  if( iRetVal == -1 )
  {
    fwException_raise(exceptionInfo, "ERROR", "Could not get subscription type: dpGet(" + sDpe + ") failed", "");
    return -1;
  }

  return iType;
}





/**
* Get a list of servers on the given system.
*
* @return dyn_string List of servers.
*/
public dyn_string fwPeriphAddressOPCUA_getServers(string sys, dyn_string &exceptionInfo) {
  if (strlen(sys) == 0) {
     fwException_raise(exceptionInfo, "ERROR", "No system","");
     return makeDynString();
  }

  dyn_string dsEqu = dpNames(sys+"*", "_OPCUAServer");

  int len = dynlen(dsEqu);

  for (int i = len; i > 0; i--) {
    // don't display redundant datapoints
    if (isReduDp(dsEqu[i])) {
      dynRemove(dsEqu, i);
    }
  }
  len = dynlen(dsEqu);
  if (len > 0) {
    for (int i = 1; i <= len; i++) {
      dsEqu[i] = dpSubStr(dsEqu[i], DPSUB_DP);
      dsEqu[i] = substr(dsEqu[i], 1, strlen(dsEqu[i]) - 1);
    }
  }

  return dsEqu;
}
