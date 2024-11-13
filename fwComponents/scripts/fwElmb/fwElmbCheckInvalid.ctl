#uses "fwElmb/fwElmbUser.ctl"

#uses "fwElmb/fwElmb.ctl"

// Only relevant to ELMBs which have DI configured and didn't yet set any DI readout method
// Assumption: DI transmission was refreshed
void guessInitialDiReadoutMethod ()
{
  // the readout method is per-ELMB
  dyn_string dsElmbs = dpNames(getSystemName()+"*", ELMB_TYPE_NAME);
  for (int i=1; i<=dynlen(dsElmbs); i++)
  {
    // check if this ELMB actually has DI
    if (dpExists( dsElmbs[i]+"/"+ELMB_DI_CONFIG_NAME))
    {
      time t;
      bool invalid;
      dpGet (dsElmbs[i]+"/"+ELMB_DI_CONFIG_NAME+".readoutMethod:_online.._stime", t,
             dsElmbs[i]+"/"+ELMB_DI_CONFIG_NAME+".transmissionType.read:_online.._invalid", invalid);
      if (year(t) == 1970)
      {
        if (!invalid)
        {
          // infer which DI readout method to set basing on current transmission type
          int transmissionType;
          dpGet (dsElmbs[i]+"/"+ELMB_DI_CONFIG_NAME+".transmissionType.read", transmissionType );
          DebugN ("ELMB "+dsElmbs[i]+" inferring DI config");
          if (transmissionType == 1)
          {
            // after SYNC -> high confidence that ONSYNC is appropriate
            dyn_string dsExceptions;
            fwElmbUser_setElmbDiReadoutMethod( dsElmbs[i], FWELMB_DI_READOUT_ONSYNC, dsExceptions);
            if (dynlen(dsExceptions) > 0)
             DebugTN ("Failed to set DI readout method (function fwElmbUser_setElmbDiReadoutMethod failed)");
            else
             DebugTN ("ELMB "+dsElmbs[i]+" inferred DI readout method: ONSYNC");
          }
          else if (transmissionType == 255)
          {
            // after RTR -> this is much less confident, so a guess is proposed
            dyn_string dsExceptions;
            fwElmbUser_setElmbDiReadoutMethod( dsElmbs[i], FWELMB_DI_READOUT_ONCHANGE, dsExceptions); 
            if (dynlen(dsExceptions) > 0)
             DebugTN ("Failed to set DI readout method (function fwElmbUser_setElmbDiReadoutMethod failed)");
            else
             DebugTN ("ELMB "+dsElmbs[i]+" inferred DI readout method: ONCHANGE");
          }
          else
            DebugTN ("Unable to infer DI readout method for ELMB="+dsElmbs[i]+": transmissionType is unknown: "+transmissionType);
        }
        else
          DebugTN ("Note: DI readout method for ELMB="+dsElmbs[i]+" could not be inferred automatically. Please use DI config panel and set it up manually."); 
      }
    }    
  }
}  

main()
{
  fwElmb_cachedCreate ();
  fwElmb_pollChannelsActive (); // the first run is needed for monitorInvalid; next runs are from infinite loop
  fwElmbUser_monitorInvalid();
  
  /* Create manager-global data for keeping nodes' states*/
  addGlobal ("gFwElmb_statesOfNodesNoToggle", MAPPING_VAR);
  
  // State and E.O. monitoring is new since 5.2.0, and shall be backwards compatible for OPC DA, see run it only with OPC UA
  if (fwElmb_getMiddlewareKind() == FWELMB_MIDDLEWARE_OPCUA)
  {
    fwElmbUser_monitorStateAndEmergencyObjects (); 
    fwElmb_monitorOpcUaConnectionState ();
    dyn_string dsExceptions;
    fwElmb_refreshElmbConfiguration (dsExceptions);
    if (dynlen(dsExceptions))
    {
      DebugTN ("Errors: ", dsExceptions );
    }
    guessInitialDiReadoutMethod ();
    
    while (true)
    {
      fwElmb_pollChannelsActive ();
      delay (15);
      bool afterOpcUaReconnectFlag;
      dpGet("_FwElmbGlobal.afterOpcUaReconnectFlag", afterOpcUaReconnectFlag);
      if (afterOpcUaReconnectFlag)
      {
        dpSet("_FwElmbGlobal.afterOpcUaReconnectFlag", false);
        DebugTN ("Rereading ELMB configuration (due to OPC UA Reconnect)");
        dsExceptions = makeDynString();
        fwElmb_refreshElmbConfiguration (dsExceptions);
        if (dynlen(dsExceptions))
        {
          DebugTN ("Exceptions thrown while handling re-read", dsExceptions);
        }        
      }
    }
  } 
  else
  {
    /* for DA projects just do nothing -- otherwise PVSS complaints about 'manager restarting too rapidly' */
    while (true)
    {
      delay (30);
    }
    
  }
  
}
