#uses "fwGeneral/fwGeneral.ctl"
#uses "fwTree/fwTree.ctl"


int fwTreeUtil_isObjectReference(string obj)
{
	string obj_name;
	dyn_string children, exInfo;
	string parent, sys, dev, type;
	int cu;
	obj_name = fwTree_getNodeDisplayName(obj, exInfo);
	if(obj_name == obj)
		return 0;
	sys = fwTree_getNodeSys(obj, exInfo);
	if(strpos(obj, sys+":") == 0)
	{
		fwTree_getNodeCUDevice(obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(obj, dev, type, exInfo);
	}
	else
	{
		fwTree_getNodeCUDevice(sys+":"+obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(sys+":"+obj, dev, type, exInfo);
	}
//	if(cu)
//	{
//		fwTree_getChildren(obj, children, exInfo);
//		if(!dynlen(children))
//			return 1;
//	}
	if((cu) || (strpos(dev,"::") >= 0))
		return 1;
	return(0);
}

int fwTreeUtil_isObjectReferenceCU(string obj, int &isCu)
{
	string obj_name;
	dyn_string children, exInfo;
	string parent, sys, dev, type;
	int cu;
	obj_name = fwTree_getNodeDisplayName(obj, exInfo);
	if(obj_name == obj)
		return 0;
	sys = fwTree_getNodeSys(obj, exInfo);
	if(strpos(obj, sys+":") == 0)
	{
		fwTree_getNodeCUDevice(obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(obj, dev, type, exInfo);
	}
	else
	{
		fwTree_getNodeCUDevice(sys+":"+obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(sys+":"+obj, dev, type, exInfo);
	}
//	if(cu)
//	{
//		fwTree_getChildren(obj, children, exInfo);
//		if(!dynlen(children))
//			return 1;
//	}
	isCu = cu;
	if((cu) || (strpos(dev,"::") >= 0))
		return 1;
	return(0);
}

/*
	@deprecated 2019-11-11, FWFSM-121: Convenience function likely not used anywhere
*/
string fwTreeUtil_getLogicalDeviceName(string pdev)
{
string ldev, pdev1;

	if(strpos(pdev,".") >= 0)
		pdev1 = pdev;
	else
		pdev1 = pdev+".";
	ldev = dpGetAlias(pdev1);
//DebugN("getLogical",pdev, pdev1, ldev);
	pdev = fwNoSysName(pdev);
	if(ldev == "")
		ldev = pdev;
	return ldev;
}

/*
	@deprecated 2019-11-11, FWFSM-121: Convenience function likely not used anywhere
*/
string fwTreeUtil_getPhysicalDeviceName(string ldev)
{
string pdev, pdev1;
int pos;

	pdev = dpAliasToName(ldev);
	ldev = fwNoSysName(ldev);
	if(pdev == "")
		pdev = ldev;
	else
		pdev = fwNoSysName(pdev);
//	pdev1 = dpSubStr(pdev, DPSUB_DP_EL);
	pdev1 = strrtrim(pdev,".");
//DebugN("getPhysicalDevName",ldev, pdev, pdev1);
	if(pdev1 != "")
		pdev = pdev1;
	return pdev;
}

/*
	@deprecated 2019-11-11, FWFSM-121: Convenience function likely not used anywhere
*/
int fwTreeUtil_isLogicalDeviceName(string ldev)
{
string pdev, pdev1;


	pdev = dpAliasToName(ldev);
	ldev = fwSysName(ldev);
	if(pdev != "")
	{
		pdev1 = dpSubStr(pdev, DPSUB_DP);
		if((pdev1 != "") && (pdev1 != ldev))
			return 1;
	}
	return 0;
}

dyn_string fwTreeUtil_getDps(string search, string type)
{
int i;
dyn_string dps;

	dps = dpNames(search,type);
	for(i = 1; i <= dynlen(dps) ; i++)
	{
		dps[i] = fwNoSysName(dps[i]);
	}
	return(dps);
}

/*
	@deprecated 2019-11-11, FWFSM-121: Convenience function likely not used anywhere
*/
dyn_string fwTreeUtil_getDpsSys(string search, string type, dyn_string &systems)
{
int i;
dyn_string dps;

	dynClear(systems);
	dps = dpNames(search,type);
	for(i = 1; i <= dynlen(dps) ; i++)
	{
		systems[i] = fwSysName(dps[i]);
		dps[i] = fwNoSysName(dps[i]);
	}
	return(dps);
}

/*
	@deprecated 2019-11-11, FWFSM-121: Convenience function likely not used anywhere
*/
void fwTreeUtil_getObjectReferences(string obj, dyn_string &refs, dyn_string &syss)
{
string ref, sys, parent, local_dev, local_type, local_sys, dev, type, obj_name;
int i, index, cu;
dyn_string nodes, exInfo;

	dynClear(refs);

	sys = fwTree_getNodeSys(obj, exInfo);
	fwTree_getCUName(sys+":"+obj, parent, exInfo);
	fwTree_getNodeDevice(sys+":"+obj, local_dev, local_type, exInfo);
	local_sys = fwSysName(local_dev);
	local_dev = fwNoSysName(local_dev);

	nodes = fwTree_getNamedNodes(obj, exInfo);
//DebugN("In Get refs", obj, nodes, parent, exInfo);
	if((index = dynContains(nodes, obj)))
	{
		dynRemove(nodes, index);
	}
	for(i = 1; i <= dynlen(nodes); i++)
	{
		if(fwTreeUtil_isObjectReference(nodes[i]))
		{
//DebugN(nodes[i], "is ref");
		ref = nodes[i];
		if((sys = fwTree_getNodeSys(ref, exInfo)) != "")
		{
//DebugN(ref, "sys", sys);
			fwTree_getNodeCU(sys+":"+ref, cu, exInfo);
			if(cu)
			{
				if(local_dev != "")
				{
					fwTree_getNodeDevice(sys+":"+ref, dev, type, exInfo);
					if(dev == local_sys+":"+local_dev)
					{
						dynAppend(refs, ref);
						dynAppend(syss, sys);
					}
				}
				else
				{
					dynAppend(refs, ref);
					dynAppend(syss, sys);
				}
			}
			else
			{
				fwTree_getNodeDevice(sys+":"+ref, dev, type, exInfo);
//DebugN(dev, local_sys+":"+parent+"::"+local_dev);
				if(dev == local_sys+":"+parent+"::"+local_dev)
				{
					dynAppend(refs, ref);
					dynAppend(syss, sys);
				}
			}
		}
		}
	}
}

void fwTreeUtil_getObjectReferenceSystem(string node, string &sys)
{
string dev, type;
dyn_string exInfo;

	if(node == "")
		sys = strrtrim(getSystemName(),":");
	else
	{
		fwTree_getNodeDevice(node, dev, type,exInfo);
 		sys = fwSysName(dev);
	}
}

string fwTreeUtil_getReferencedObjectDevice(string ref)
{
string dev, type, sys, mysys;
dyn_string exInfo;


	mysys = strrtrim(getSystemName(),":");
	fwTree_getNodeDevice(ref, dev, type, exInfo);
 	sys = fwSysName(dev);
	if(sys == mysys)
		dev = fwNoSysName(dev);
	return dev;
}


// a copy of fwFsmTree_getNodeLabel => refactor on FSM side!
string fwTreeUtil_getNodeLabel(string node)
{
string label;
dyn_string udata, exInfo;
    
    fwTree_getNodeUserData(node, udata, exInfo);
    label = udata[3];
    return label;
}
