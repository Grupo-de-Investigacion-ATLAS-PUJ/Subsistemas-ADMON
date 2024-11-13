// SPDX-FileCopyrightText: © 2015 CERN <mail-TTO@cern.ch>

/**@file
 * @brief The library to handle DPE locks (@ref FwDPELockingManual).
 *
 * This library contains a set of functions that handle DPE Locks:
 * lock, unlock, check the state of locking, as well as a lock-monitor
 * that guards that the locked datapoints will not remain locked unnecessarily.
 * You may want to look at the @ref FwDPELockingManual manual.
 *
 * @author Piotr Golonka
 * @date 2015
 *
 * @copyright Copyright CERN 2015, All Rights Reserved 
 *
 * @par Constraints
 *  - It is not (yet) guaranteed that this version works across distributed systems.
 *  - It is not (yet) guaranteed that this version works in redundant systems.
**/

#uses "fwGeneral/fwManager.ctl"
#uses "fwGeneral/fwException.ctl"

// values extracted from the main WinCC OA error message catalogue:
const int fwDPELock_ERR_DPE_DOES_NOT_EXIST=8;
const int fwDPELock_ERR_CONFIG_DOES_NOT_EXIST=9;

const int fwDPELock_LOCK_MANAGER_DETAIL = 1;
const int fwDPELock_LOCK_USER_NAME      = 2;
const int fwDPELock_LOCK_MANAGER_TYPE   = 3;
const int fwDPELock_LOCK_MANAGER_NUMBER = 4;
const int fwDPELock_LOCK_MANAGER_SYSTEM = 5;
const int fwDPELock_LOCK_MANAGER_HOST   = 6;
const int fwDPELock_LOCK_MANAGER_REPLICA    = 7; // which of redu systems
const int fwDPELock_LOCK_MANAGER_MANID      = 8;
const int fwDPELock_LOCK_USER_ID        = 9;
const int fwDPELock_LOCK_TYPE           = 10;

/** 
 * @internal
 * @private
 * Finds the lock config element
 *
 * The function looks up the lock config element for a specified DPE, 
 * and optionally a config. It properly recognizes the cases where
 * the system is specified without a config, and a config specified without a system
 *
 * Use: internally by other functions in fwDPELock.
 *
 * @param dpeWithConfig (input): the DP Element, optionally with a config, 
 * 				for which the lock config element is looked up.
 *				If config is not specified, the _original is
 *				assumed.
 * @returns the name of the lock config element
 * @throws exceptions when DPE or config do not exist
 **/
string _fwDPELock_getLockConfig(string dpeWithConfig)
{
    string dpe    = dpSubStr(dpeWithConfig,DPSUB_SYS_DP_EL);
    string config = strltrim(dpSubStr(dpeWithConfig,DPSUB_CONF), ":");


    // check whether the config was actually passed to us or not
    // we check it by looking at number of ":" chars in dpeWithConfig
    dyn_string ds=strsplit(dpeWithConfig,":");
    if (dynlen(ds)==3) {
	// we have everything we need
    } else if (dynlen(ds)==2) {
	// special cases to consider and identify
	// SYS:DPE and DPE:CONFIG
	string sys = dpSubStr(dpeWithConfig,DPSUB_SYS);
	if (sys!="") config="_original";
    } else if (dynlen(ds)==1) {
	config="_original";
    } else {
	throw(makeError("",PRIO_SEVERE,ERR_PARAM,fwDPELock_ERR_DPE_DOES_NOT_EXIST,"getLockConfig fails",dpeWithConfig));
    }


   if (dpe=="")    throw(makeError("",PRIO_SEVERE,ERR_PARAM,fwDPELock_ERR_DPE_DOES_NOT_EXIST   ,"getLockConfig fails",dpeWithConfig));
   if (config=="") throw(makeError("",PRIO_SEVERE,ERR_PARAM,fwDPELock_ERR_CONFIG_DOES_NOT_EXIST,"getLockConfig fails",dpeWithConfig));

   string lockConfig = dpe + ":_lock." + config;

   if (!dpExists(lockConfig)) throw(makeError("",PRIO_SEVERE,ERR_PARAM,fwDPELock_ERR_CONFIG_DOES_NOT_EXIST,"getLockConfig fails",dpeWithConfig));

   return lockConfig;
}

/**
 * Checks if DPElement (optionally with config) is locked,
 * with handling of errors through exceptions;
 * Note that it does not check if the owner of the lock is the current manager.
 *
 * @param dpeWithConfig (input) the DP Element (optionally with a config) being checked
 * @returns true is the DPE is locked, false otherwise;
 * @throws exceptions if dpeWithConfig is invalid, or if the state of locking could not be determined
 *
*/
bool fwDPELock_isLocked(string dpeWithConfig)
{
    bool isLocked = false;

    string lockAttribute=_fwDPELock_getLockConfig(dpeWithConfig)+"._locked";

    dpGet(lockAttribute, isLocked);
    dyn_errClass err=getLastError();
    if (dynlen(err)) throw(err);

    return isLocked;

}


/**
 * Checks the state of the lock on a given DPElement
 *
 * the function checks whether the DPElement (optionally with a config) is locked,
 * and if it is, then it returns the details of who owns the lock.
 *
 * @param dpeWithConfig : the name of the dp element, optionally with the config name
 * @param lockDetails	if the config is locked, the details of the lock are returned here
 *			  lockDetails[fwDPELock_LOCK_MANAGER_DETAIL]	- The name of the manager that has control of the config
 *			  lockDetails[fwDPELock_LOCK_USER_NAME]		- The name of the user who has control of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_TYPE]	- The type of manager that has control of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_NUMBER]	- Manager number of manager that has contol of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_SYSTEM]	- System name of manager that has contol of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_HOST]	- The host of the manager that has control of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_REPLICA]	- The redundant system replica number of the manager that has control of the config
 *			  lockDetails[fwDPELock_LOCK_MANAGER_MANID]	- The ManId (internal WinCC OA id) of the manager that has control of the config
 *			  lockDetails[fwDPELock_LOCK_USER_ID]		- User name of user who has control of the config
 *			  lockDetails[fwDPELock_LOCK_TYPE]		- Type of lock on the config
 * @param exceptionInfo	details of any errors are returned here
 *
 * @returns true if locked, false otherwise
 *
 * @throws : nothing; errors are handled through the exceptionInfo variable
**/
bool fwDPELock_getLocked(string dpeWithConfig, dyn_string &lockDetails, dyn_string &exceptionInfo)
{

    bool isLocked = false;
    string lockConfig;
    string exceptionText;

    // clear up the lockDetails and make sure it has proper length...
    dynClear(lockDetails);
    lockDetails[fwDPELock_LOCK_TYPE]="";


    try {
	lockConfig = _fwDPELock_getLockConfig(dpeWithConfig);
	dpGet(lockConfig+"._locked", isLocked);
  
	if(isLocked) {
	    int tempNumber, tempType, tempSystem, tempReplica,manId;

	    dpGet(lockConfig + "._locked", isLocked, 
	          lockConfig + "._man_id",  manId,
	          lockConfig + "._type",    lockDetails[fwDPELock_LOCK_TYPE],
	          lockConfig + "._user_id", lockDetails[fwDPELock_LOCK_USER_ID]);
	    // if in a meantime this got unlocked...
	    if (! isLocked) return false;

	    lockDetails[fwDPELock_LOCK_MANAGER_MANID] = manId;
	    getManIdFromInt(manId, tempType, tempNumber, tempSystem,tempReplica);
	    lockDetails[fwDPELock_LOCK_MANAGER_NUMBER] = tempNumber;
	    lockDetails[fwDPELock_LOCK_MANAGER_TYPE] = tempType;
	    lockDetails[fwDPELock_LOCK_MANAGER_SYSTEM] = getSystemName(tempSystem);
	    lockDetails[fwDPELock_LOCK_MANAGER_REPLICA] = tempReplica;

	    convManIntToName(manId, lockDetails[fwDPELock_LOCK_MANAGER_DETAIL]);
	    dyn_string excInfoTmp;
	    lockDetails[fwDPELock_LOCK_MANAGER_HOST]=fwManager_getManagerHostname(manId,excInfoTmp);
	    if (dynlen(excInfoTmp)) { DebugTN(__FUNCTION__,"Could not get manager hostname for "+manId);}
	    lockDetails[fwDPELock_LOCK_USER_NAME] = getUserName(lockDetails[fwDPELock_LOCK_USER_ID]);
	    return true;
	}

	return false;

    } catch {
	dyn_errClass exc=getLastException();
	exceptionText=getErrorText(exc);
    } finally {
	if (exceptionText!="") {
	    fwException_raise(exceptionInfo, "ERROR",exceptionText,"");
	    return false;
	}
    }

    return false;
}


/**
 * Try to acquire a lock on specified DPE, waiting for it to be free and assuring that it is unlocked
 *
 * The function attempts to lock the specified DPElement (optionally, with specified config).
 * In case the lock is held by other manager, it (optionally) retries for up to the lockTimeout seconds.
 * The lock is (optionally) monitored with a timer mechanism: if it is not explicitely released within
 * lockLifetime seconds, then the lock monitor will force-release it. This is particularly useful
 * if the function is executed within child panels which may be closed before the corresponding unlock
 * code is executed.
 *
 * If the manager executing this code is already owning the lock, the function returns true, and
 * the lock-monitoring timeout is reset.
 *
 * In any case one should use the @ref fwDPELock_unlock to release the lock acquired by this function.
 *
 * @param dpeWithConfig (input) the DP Element (may also include the config) to be locked;
 *		      if no config is specified, then the _original config will be locked
 * @param exceptionInfo (output) standard exception-handling variable
 * @param lockTimeout (input) the time (in seconds) for which the function will wait for the lock, default 1 second;
 *                         @li 0  - do not wait for lock at all (will exit with failure if the DPE is already locked)
 *                         @li <0 - wait with no limit until the lock is obtained.
 * @param lockLifetime (input) the maximum time for which the lock will be kept (default 5 seconds); if the lock
 *                         is not released within the lockLifeTime, then it will be force-unlocked by the 
 *                         lock manager. Specifying the value of zero will disable the lock-monitoring mechanism
 *                         for this call.
 *
 * @returns true if the lock was obtained successfully (or if this manager was already holding the lock)
 *          false if the lock was not obtained (because it was locked and timed out, or because of errors)
 *
 * @throws nothing - all errors handled with the exceptionInfo variable
 *
 */
bool fwDPELock_tryLock (string dpeWithConfig, dyn_string &exceptionInfo, int lockTimeout=1, int lockLifetime=5)
{
    string exceptionText;
    bool ok=false;
    try {
	string lockConfig = _fwDPELock_getLockConfig(dpeWithConfig);
	int myself = myManId();
	long tStart = period(getCurrentTime ());
	do {
	    dyn_string lockDetails;
	    bool isLocked;
	    int manId;
	    unsigned userId;
	    dpGet(lockConfig + "._locked", isLocked,
	          lockConfig + "._man_id", manId,
	          lockConfig + "._user_id",userId);
	    // FWCORE-3285
	    dyn_errClass err=getLastError();
	    if (dynlen(err)) {
		throwError(makeError("",PRIO_WARNING,ERR_CONTROL,0,"fwDPELock_tryLock failed to dpGet the lock config "+lockConfig,getErrorText(err)));
		fwException_raise(exceptionInfo,"ERROR", "Could not dpGet lock info for: "+dpeWithConfig+";"+getErrorText(err),"");
		return false;
	    }
	    if (isLocked == 0) {
		// Try to acquire the lock
		int rc = dpSetWait(lockConfig+"._locked",true);
		dyn_errClass err=getLastError();
		if (rc < 0 || dynlen(err)) {

		    if(getErrorCode(getLastError()) == 24) { 
			// We did not get the lock, someone else got it. Continue trying.
			clearLastError();
			continue;
		    } else {
			// Error is not about being locked
			throwError(makeError("",PRIO_WARNING,ERR_CONTROL,0,"fwDPELock_tryLock failed for "+dpeWithConfig,getErrorText(err)));
	    		fwException_raise(exceptionInfo,"ERROR", "Error while locking: "+
						dpeWithConfig+" ,"+(string)err,"");
	    		return false;
		    }
		} else {
		    ok=true;
		    break;
		}
	    } else { // already locked...
		if (manId == myself ) { // we already possess the lock
		    // still, check that maybe we need to relock it,..
		    if (userId==getUserId()) {
			ok=true;
			break;
		    } else {
		        throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_tryLock changing lock ownership from "+getUserName(userId)+" to "+getUserName(),lockConfig));

			_fwDPELock_sudoUnlock(lockConfig, exceptionInfo);
			if (dynlen(exceptionInfo)) return false;
			dpSetWait(lockConfig+"._locked",true);
			dyn_errClass err=getLastError();
			if (dynlen(err)) {
			    fwException_raise(exceptionInfo,"ERROR", "Could not re-lock: "+dpeWithConfig+";"+getErrorText(err),"");
			    DebugTN(err);
			    ok=false;
			} else {
			ok=true;
			}
			break;
		    }
		}

	    }

    	    delay(0,100);
	} while (   (lockTimeout<0) || (period(getCurrentTime()) < (tStart+lockTimeout))   );

	if (ok) {
	    if (lockLifetime > 0) fwDPELock_lockGuard(lockConfig,lockLifetime);
	    return true;
	} else if (!ok) {
	    dyn_string lockDetails;
	    fwDPELock_getLocked(dpeWithConfig, lockDetails, exceptionInfo);
	    if (dynlen(exceptionInfo)) return false;

	    string whoLocks=lockDetails[fwDPELock_LOCK_MANAGER_DETAIL]  + " #"+
			lockDetails[fwDPELock_LOCK_MANAGER_REPLICA] + " @"+
			lockDetails[fwDPELock_LOCK_MANAGER_HOST];
    	    fwException_raise(exceptionInfo,"ERROR", "Cannot lock: "+
						dpeWithConfig+" already locked by "+whoLocks,"");
    	return false;
	}

	return true;

    } catch {
	dyn_errClass exc=getLastException();
	exceptionText=getErrorText(exc);
    } finally {
	if (exceptionText!="") {
	    fwException_raise(exceptionInfo, "ERROR",exceptionText,"");
	    return false;
	}
    }

    return false;

}

/**
 * Unlocks the specified DP Element
 *
 * This function allows to unlock the specified DP Element (optionally, with a config).
 * It is possible to force-unlock a locked DPE, even if it was locked by another manager.
 * @param dpeWithConfig (input) the DP Element (optionally with config) to be unlocked
 * @param exceptionInfo (output) standard exception-handling variable
 * @param force (input) if true, it allows to unlock the DPEs locked by other managers;
 *                      default is false (ie. only allow to unlock own locks)
 * @throws nothing - all exceptions handled through the exceptionInfo variable
 *
 */
void fwDPELock_unlock(string dpeWithConfig, dyn_string &exceptionInfo, bool force=false)
{
    string exceptionText;

    try {
	string lockConfig = _fwDPELock_getLockConfig(dpeWithConfig);
	bool isLocked;
	int manId;
	dpGet(lockConfig + "._locked",isLocked,
	      lockConfig + "._man_id",  manId);
	if (!isLocked) return;	
	if ( (!force) && (manId!=myManId()) ) {
	
	    dyn_string lockDetails;
	    dyn_string exceptionInfo2;
	    isLocked=fwDPELock_getLocked(dpeWithConfig, lockDetails, exceptionInfo2);
	    if (!isLocked) return; // maybe it got unlocked in a meantime...
	    string whoLocks=lockDetails[fwDPELock_LOCK_MANAGER_DETAIL]  + " #"+
	          	    lockDetails[fwDPELock_LOCK_MANAGER_REPLICA] + " @"+
		            lockDetails[fwDPELock_LOCK_MANAGER_HOST];
	    fwException_raise(exceptionInfo,"ERROR","Could not unlock: "+dpeWithConfig+" another manager is keeping the lock: "+ whoLocks,"");
	    return;
	}

	// Try to release the lock
	int rc = dpSetWait(lockConfig+"._locked",false);
	dyn_errClass err=getLastError();

  	if ( dynlen(err)) {
      if (getErrorCode(err)==25) { //ignore the "Config is not locked", FWCORE-3222
        throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_unlock() DPE was already unlocked",lockConfig));
      } else if (getErrorCode(err)==26) {
        // need for sudo unlock
	throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_unlock: forcing open a lock owned by other user",lockConfig));
        _fwDPELock_sudoUnlock(lockConfig, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
      } else {
    	    fwException_raise(exceptionInfo,"ERROR", "Error while unlocking: "+
						dpeWithConfig+" ,"+(string)err,"");
    	    return;
      }
	  }

    } catch {
	dyn_errClass exc=getLastException();
	exceptionText=getErrorText(exc);
    } finally {
	if (exceptionText!="") {
	    fwException_raise(exceptionInfo, "ERROR",exceptionText,"");
	    return;
	}
    }

}


//-----------------------------------------------------------------

/** @internal @private
 *
 * "Lock manager" feature: allows to make sure that the lock
 * does not get stuck and force-unlocks the managed locks
 * after a specified timeout.
 *
 * For that we need 
 * - threads that run without being terminated by the panel being closed
 *   (this is provided by the @ref fwDPELock_startFunctionWithParams)
 * - a list of monitored locks, with a thread that will force-unlock them
 *   after a timeout; this thread is running only if necessary (ie. when
 *   there are some monitoried locks present), and restarted if necessary
 * - a dpConnect to the _lock config of datapoints that are monitored so that 
 *   we know when it gets unlocked or re-locked; we assume that it will often
 *   be the same datapoints being locked, so that we establish a permanent
 *   dpConnect, and we keep the list of "traced" locks.
 *
 */
global private bool _fwDPELock_lockManagerRunning=false;

/* @internal @private
 	The list of locks being monitored.
	the layout of rows(!) is the following
	- [1][i] (string) DPE on which the lock is
	- [2][i] (time) the time when the lock was issued 
	- [3][i] (time) the time when the lock needs to be released
	- [4][i] (string) who issued the lock (function name), obtained through stack trace

**/
global private dyn_dyn_mixed _fwDPELock_dpLockList;

/** @internal @private
 */ 
private void _fwDPELock_checkStartLockManager()
{
    if (_fwDPELock_lockManagerRunning) return;

    // start a parallel script that works in the context of the manager itself, rather than the current window,
    // and hence does not terminate when it is closed; see ETM-1253
    fwDPELock_startFunctionWithParams("_fwDPELock_dpLockManager", "");

    // make sure that it actually started
    for (int i=1;i<=10;i++){
	if (_fwDPELock_lockManagerRunning) break;
	delay(0,100);
    }
    if (!_fwDPELock_lockManagerRunning) throwError(makeError("",PRIO_SEVERE,ERR_CONTROL,0,"fwDPELock_dpLockManager could not be started"));

}


/** @internal @private
 */ 
void fwDPELock_lockGuard(string lockConfig, unsigned timeout=5)
{
    _fwDPELock_checkStartLockManager();

    lockConfig=dpSubStr(lockConfig,DPSUB_SYS_DP_EL_CONF_DET);
    synchronized(_fwDPELock_dpLockList) {
	int idx=dynContains(_fwDPELock_dpLockList[1],lockConfig);
	if (idx<=0) {
	    idx=dynlen(_fwDPELock_dpLockList[1])+1;
	}
	
	dyn_string stackTrace=getStackTrace();
	_fwDPELock_dpLockList[1][idx]=lockConfig;
	_fwDPELock_dpLockList[2][idx]=getCurrentTime();
	_fwDPELock_dpLockList[3][idx]=getCurrentTime()+timeout;
	_fwDPELock_dpLockList[4][idx]=(string) stackTrace[2];
    }
    fwDPELock_startFunctionWithParams("_fwDPELock_traceLockDPE",lockConfig);
}

/** @internal @private
 */
global mixed g_fwDPELock_startScriptParams;

/** @internal @private
 *    uses startScript() to start a detached thread, 
 *    and calls a specific function, passing the parameters.
 *    Note that the function may have only one parameter of type mixed.
 */
private void fwDPELock_startFunctionWithParams(string function, mixed params)
{
    synchronized(g_fwDPELock_startScriptParams) {
	g_fwDPELock_startScriptParams=params;
	startScript("main() { "+function+"(g_fwDPELock_startScriptParams);} ");
    }
}

/** @internal @private
 */
global dyn_string g_fwDPELock_traceLockDPE_list;

/** @internal @private
 * @reviewed 2018-06-21 @whitelisted{#BackgroundProcessing}
 */
void _fwDPELock_traceLockDPE(mixed params)
{
    string lockConfig=params;
    synchronized(g_fwDPELock_traceLockDPE_list) {
	if (!dynContains(g_fwDPELock_traceLockDPE_list,lockConfig)) {
	    dynAppend(g_fwDPELock_traceLockDPE_list,lockConfig);
	    dpConnect("fwDPELock_traceLockDPE_callback",lockConfig+"._locked");
	}
    }
}

/* @internal @private
 * @reviewed 2018-06-21 @whitelisted{#BackgroundProcessing}
**/
void fwDPELock_traceLockDPE_callback(string where, bool value)
{
    //DebugTN("LockedCB",where,value);
    // we want it without system name!
    string lockConfig=dpSubStr(where,DPSUB_SYS_DP_EL_CONF_DET);
    if (value==false) {
	synchronized(_fwDPELock_dpLockList) {
	    int idx=dynContains(_fwDPELock_dpLockList,lockConfig);
	    if (idx>0) {
		//DebugTN("Apparently someone unlocked our dpe",lockConfig);
		dynRemove(_fwDPELock_dpLockList[1],idx);
		dynRemove(_fwDPELock_dpLockList[2],idx);
		dynRemove(_fwDPELock_dpLockList[3],idx);
		dynRemove(_fwDPELock_dpLockList[4],idx);
	    }
	}
    } else {
	//DebugTN("Apparently someone (re?)locked our dpe",lockConfig);
    }
}

/** @internal @private
 * @reviewed 2018-06-21 @whitelisted{#BackgroundProcessing}
 *
 */
void _fwDPELock_dpLockManager(string dummyParam)
//note! the function may not be declared as private... 
{

    if (_fwDPELock_lockManagerRunning) {
	throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"LockManager already running"));
	return;
    }


    // check if someone called me directly (should not do...)
    // to do that: nspect the stackTrace and check who called me
    bool startedWithStartScript=false;
    dyn_string st=getStackTrace();
    if (dynlen(st)==2 && st[2]=="void main() at startScript:1") startedWithStartScript=true;
    if (!startedWithStartScript) {
	// we redirect to proper startup procedure
	_fwDPELock_checkStartLockManager();
	return;
    }


//    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_dpLockManager started"));

    _fwDPELock_dpLockList=makeDynMixed(makeDynMixed(),
                                       makeDynMixed(),
                                       makeDynMixed(),
                                       makeDynMixed()); //initialize with proper structure!

    _fwDPELock_lockManagerRunning=true;

    int idleCycles=0;
    while (true) {

	int len;
	synchronized(_fwDPELock_dpLockList) {
	    if (dynlen(_fwDPELock_dpLockList[1])<1) {
		idleCycles++;
		if (idleCycles>=5) {
		    //throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_dpLockManager stops"));
		    _fwDPELock_lockManagerRunning=false;
		    return;
		}
	    } else {

		idleCycles=0;
		time tNow=getCurrentTime();

		for (int i=1;i<=dynlen(_fwDPELock_dpLockList[1]);i++) {
		    //DebugTN("Processing",i,_fwDPELock_dpLockList[1][i],_fwDPELock_dpLockList[2][i],_fwDPELock_dpLockList[3][i],_fwDPELock_dpLockList[4][i]);
		    if (_fwDPELock_dpLockList[3][i] >= tNow)  continue;

		    //DebugTN("Timeout! We may need to unlock the guy");
		    // before we unlock it, check once again, to avoid errors
		    dyn_string lockDetails, exceptionInfo;
		    bool isLockedNow=false, isInError=false;
		    string lockedDPE=dpSubStr(_fwDPELock_dpLockList[1][i], DPSUB_SYS_DP_EL);
		    if (lockedDPE=="" || !dpExists(lockedDPE)) {
			throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager: DPE does not exist; discarding it",_fwDPELock_dpLockList[1][i]));
			isInError=true;
		    } else {
			isLockedNow=fwDPELock_getLocked(dpSubStr(_fwDPELock_dpLockList[1][i], DPSUB_SYS_DP_EL), lockDetails, exceptionInfo);
			if (dynlen(exceptionInfo)) {
			    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager error; removing",_fwDPELock_dpLockList[1][i],exceptionInfo[2]));
			    isInError=true;
			}
		    }
		    
		    if (!isInError) {

			//DebugTN("isLocked",isLockedNow, lockDetails);
			if (!isLockedNow) continue;
		
			if (myManId()!=lockDetails[fwDPELock_LOCK_MANAGER_MANID]) { // make sure not to unlock someone-else's lock!
			    // just report, and fail over
			    string whoLocks=lockDetails[fwDPELock_LOCK_MANAGER_DETAIL]  + " #"+
			    		    lockDetails[fwDPELock_LOCK_MANAGER_REPLICA] + " @"+
					    lockDetails[fwDPELock_LOCK_MANAGER_HOST];
			    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager: DPE locked by someone else ("+whoLocks+")",_fwDPELock_dpLockList[1][i]));
			} else {
			    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager releases",_fwDPELock_dpLockList[1][i]));
			    dpSetWait(_fwDPELock_dpLockList[1][i]+"._locked",false);
			    dyn_errClass err=getLastError();
			    if (dynlen(err)) {
				if (getErrorCode(err)==25) { 
				    //ignore the "Config is not locked", FWCORE-3222
				    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager: config already unlocked",_fwDPELock_dpLockList[1][i]));
				} else if (getErrorCode(err)==26) { 
				    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock lock manager: sudo unlock",_fwDPELock_dpLockList[1][i]));
				    _fwDPELock_sudoUnlock(_fwDPELock_dpLockList[1][i], exceptionInfo);
				    if (dynlen(exceptionInfo)) {
					throwError(makeError("",PRIO_SEVERE,ERR_CONTROL,0,"fwDPELock lock manager: sudo unlock failed",_fwDPELock_dpLockList[1][i],exceptionInfo[2]));
					DebugTN(exceptionInfo);
				    }
				} else { 
				    throwError(makeError("",PRIO_SEVERE,ERR_CONTROL,0,"fwDPELock lock manager encountered problem unlocking",_fwDPELock_dpLockList[1][i]));
				    throwError(err);
				}
			    }
			}
		    }

		    // Remove from the watched locks: even though the removal might be done by the callback,
		    // we remove it already here, because otherwise we have some endless loops...
		    dynRemove(_fwDPELock_dpLockList[1],i);
		    dynRemove(_fwDPELock_dpLockList[2],i);
		    dynRemove(_fwDPELock_dpLockList[3],i);
		    dynRemove(_fwDPELock_dpLockList[4],i);
		    i--;
		}
	    }
	}
	delay(1,0);

    }

}

/** @internal @private
    Execute DPE unlocking as root, with fwAccessControl_sudo
*/
private void _fwDPELock_sudoUnlock(string lockConfig, dyn_string &exceptionInfo)
{
    if (!isFunctionDefined("_fwAccessControl_dpSetSudoWrapper")) {
	fwException_raise(exceptionInfo,"ERROR","Sudo unlock not available; upgrade fwAccessControl","");
	return;
    }

    if (!isFunctionDefined("_fwAccessControl_sudo")) {
	fwException_raise(exceptionInfo,"ERROR","Sudo unlock not available; upgrade fwAccessControl","");
	return;
    }

    mixed params = makeDynString(lockConfig+"._locked",false);

    _fwAccessControl_sudo("_fwAccessControl_dpSetSudoWrapper",params,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dyn_errClass err=params; // on return, we get the errors here
    if (dynlen(err)) {
	if (getErrorCode(err)==25) { //ignore the "Config is not locked", FWCORE-3222
    	    throwError(makeError("",PRIO_INFO,ERR_CONTROL,0,"fwDPELock_unlock() DPE was already unlocked",lockConfig));
        } else {
    	    fwException_raise(exceptionInfo,"ERROR", "Error while sudo-unlocking: "+lockConfig+" ,"+(string)err,"");
    	    return;
        }
    }
}
