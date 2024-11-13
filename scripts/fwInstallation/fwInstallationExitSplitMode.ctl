#uses "fwInstallation/fwInstallationRedu.ctl"

main(int pairToKeep = 0) {

  if (pairToKeep == 0) {
    DebugTN("Please specify peer to keep (1 or 2) as a parameter of the script");
    exit();
  }
  if ((pairToKeep != 2) && (pairToKeep != 1) ) {
    DebugTN("Please specify peer to keep (1 or 2) as a parameter of the script");
    exit();
  }
  
  int manId = convManIdToInt(EVENT_MAN,0);
  int manId_2 = convManIdToInt(EVENT_MAN,0,0,2);
  
  bool bEventConnection = isConnOpen(manId);
  bool bEventConnection_2 = isConnOpen(manId_2);
  
  int count =0;
  while (!   (bEventConnection && bEventConnection_2)  ) {
      //DebugN("bEventConnection" ,bEventConnection);
      //DebugN("bEventConnection_2" ,bEventConnection_2);

      fwInstallation_throw("Setting split mode off. Waiting for connection...", "INFO", 10);
      delay(10);

      bEventConnection = isConnOpen(manId);
      bEventConnection_2 = isConnOpen(manId_2);
      //DebugN("bEventConnection" ,bEventConnection);
      //DebugN("bEventConnection_2" ,bEventConnection_2);
      count++;
      if (count >= 6) {
          break;
      }
  
  }
  
  if (bEventConnection && bEventConnection_2)   { // both EB running   
     fwInstallation_throw("Both EV managers are now running. Calling  reduSetSplitOff " + getSystemName() + ", " + false + ", " + pairToKeep);
       int res =  fwInstallationRedu_reduSetSplitOff(getSystemName(), false, pairToKeep);
//       DebugN("Result = " + res);      
  } else {
    fwInstallation_throw("This script must be called with -data and - event specifying both peers and both peers must be running ", "WARNING", 10);    
  }
}
