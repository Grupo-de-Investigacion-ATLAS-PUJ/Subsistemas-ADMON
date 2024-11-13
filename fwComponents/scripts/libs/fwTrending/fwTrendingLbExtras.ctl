private const bool fwTrendingLbExtras_lbTrendingLoaded = fwGeneral_loadCtrlLib("lbTrending/lbTrending.ctl",false);
// FWTRENDING_LBEXTRAS flag:
// 0 means Don't use any LHCb Extras
// 1 means Use LHCb Extras: "link Axxiis" and "Browse tree pages"
// 2 means use ALL LHCb features: needs lbTrending Component and the #uses above
int FWTRENDING_LBEXTRAS = 0;

int MAX_COLS = 2;
int MAX_ROWS = 3;

int fwTrending_getLbExtras()
{
  return FWTRENDING_LBEXTRAS;
}

string fwTrending_createNode(string parent, string node, string mode, string dev = "")
{
	dyn_string ret, items, exInfo;
	string templateParameters, type, label, sys, full_label;
	int isnode, ref;
  dyn_dyn_string pageData;

DebugTN("createNode", parent, node, mode);
  items = strsplit(parent,":");
  if(dynlen(items) >= 2)
    parent = items[2];
  items = strsplit(node,":");
  label = node;
  if(dynlen(items) >= 2)
    label = items[2];
				label = fwTree_createNode(parent, label, exInfo);
				if(node != "")
				{
					sys = fwFsm_getSystem(node);
					if(sys == "")
					{
						sys = fwFsm_getSystemName();
//						node = sys+":"+node;
					}
           full_label = sys+":"+label;
				}
//				fwTree_setNodeDevice(label, node, type, exInfo);
				if(mode != "addnode")
				{
				  if(mode == "addpage")
				  {
        	  fwTrending_createPage(label, exInfo);
            fwTrending_getPage(full_label, pageData, exInfo);
//DebugN("Renamed",node, new_node, pageData[fwTrending_PAGE_OBJECT_TITLE]);
            pageData[fwTrending_PAGE_OBJECT_TITLE] = node;
            fwTrending_setPage(full_label, pageData, exInfo);

  			    if(dynlen(exInfo) > 0)
			      {
			        fwExceptionHandling_display(exInfo);
				      return "";
			      }
           }
           else if(mode == "addexisting")
           {
             full_label = dev;
           }
DebugTN("createNode1", full_label);
					fwTrendingTree_getTemplateParameters(full_label, templateParameters, exInfo);
					fwTree_setNodeUserData(label, templateParameters, exInfo);
				}
DebugTN("createNode2", label, full_label, type);
				fwTree_setNodeDevice(label, full_label, type, exInfo);
  return label;
}

fwTrending_refreshPage(string pageName)
{
  if(shapeExists("PageConf"))
    removeSymbol(myModuleName(),myPanelName(),"PageConf");
  addSymbol(myModuleName(),myPanelName(),"lbTrending/lbTrendingPlotsPage.pnl", "PageConf",
           makeDynString("$Command:edit", "$sDpName:" + pageName, "$dsShowButtons:" + makeDynString("apply")),
           600,60,0,1,1);
}

fwTrending_clearPage()
{
  int i, j;

  if(shapeExists("PageConf"))
    removeSymbol(myModuleName(),myPanelName(),"PageConf");
  for(i=1; i<=MAX_COLS; i++)
  {
    for(j=1; j<=MAX_ROWS; j++)
    {
      if(shapeExists("Plot_" + i + "_" + j))
	      removeSymbol(myModuleName(), myPanelName(), "Plot_" + i + "_" + j);
    }
  }
}

dyn_string fwTrending_getNodePages(string node)
{
  dyn_string nodes, pages, ret, exInfo;
  string device, type;
  int i;

//  DebugN(node);
  fwTree_getNodeDevice(node, device, type, exInfo);
  if(type == fwTrending_PAGE)
  {
    dynAppend(pages, device);
  }
  fwTree_getChildren(node, nodes, exInfo);
  for(i = 1; i <= dynlen(nodes); i++)
  {
    ret = fwTrending_getNodePages(nodes[i]);
    dynAppend(pages, ret);
  }
  return pages;
}

fwTrendingTree_changePlotLegends(string node)
{
  dyn_string plots;

  plots = lbTrending_changePlotLegends(node);
  ChildPanelOn("lbTrending/lbTrendingChangePlotLegends.pnl","Change Plot Legends",
               makeDynString(node, plots), 100, 100);
}

fwTrendingTree_changePlotProperties(string node)
{
  dyn_string plots;

  plots = lbTrending_changePlotLegends(node);
  ChildPanelOn("lbTrending/lbTrendingChangePlotProperties.pnl","Change Time Range",
               makeDynString(node, plots), 100, 100);
}

fwTrendingTree_copySubTree(string parent, string node)
{
//  dyn_string plots;
  dyn_float res;
  dyn_string ret;

//  plots = lbTrending_changePlotLegends(node);
  ChildPanelOnReturn("lbTrending/lbTrendingCopySubTree.pnl","CopySubTree",
               makeDynString(node), 100, 100, res, ret);
  if(res[1])
  {
//    DebugN(ret);
    lbTrending_copySubTree(parent, node, ret[3], ret[1], ret[2]);
  }
}

fwTrending_openPage(string device, int folder = 0)
{
  int index = 1;

  while(isModuleOpen("TrendingPage"+index))
    index++;
  ModuleOnWithPanel("TrendingPage"+index,0, 20, 1267, 885, 1, 1, "Scale",
                    "fwTrending/fwTrendingPageLb.pnl",
										"TrendingPage",
										makeDynString(device, folder, index));
}

global mapping LinkedAxiis;
global string PlotOwner;

fwTrending_timeAxisOwner(string plotName)
{
  PlotOwner = plotName+"trend.standardTrend";
//DebugTN("PlotOwner", plotName, PlotOwner);
}

fwTrending_timeAxisChanged(string plotName, time start, time span)
{
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
  time tBegin, tEnd, tInterval;
  string trend;
  int i;

  string owner = myModuleName();
  if(!mappingHasKey(LinkedAxiis,owner))
    return;

DebugTN("timeAxiisChanged",myModuleName(), plotName, PlotOwner);
  if(!LinkedAxiis[owner])
    return;
  trend = plotName+"trend.standardTrend";
  if(trend != PlotOwner)
    return;
//DebugTN("timeAxisChanged", plotName, trend, start, span, LinkedAxiis);
	getValue(trend, "visibleTimeRange", 0, tBegin, tEnd);
DebugTN("timeAxiisChanged1",trend, tBegin, tEnd);
	// get the time interval
//	getValue(trend, "timeInterval", tInterval);
//DebugTN("timeAxisChanged now", tBegin, tEnd, tInterval);
//	getValue(trend, "timeBegin", tBegin);
//DebugTN("timeAxisChanged now1", tBegin, g_dsReference);
  for(i = 1; i <= 6; i++)
  {
    if(i == plotName)
      continue;
    if(shapeExists(i+"trend"))
    {
      trend = i+"trend.standardTrend";
    	  setValue(trend, "visibleTimeRange", 0, tBegin, tEnd);
DebugTN("timeAxisChanged Other now", trend, tBegin, tEnd, tInterval);
    }
    else
      DebugTN("timeAxisChanged - shape does not exist",i+"trend",trend);
  }
}

fwTrending_linkAxiis(int flag)
{
  string owner = myModuleName();
//DebugTN("linkAxiisChanged",myModuleName());
  LinkedAxiis[owner] = flag;
}
/*
int lbTrending_getLinkAxiis()
{
  string owner = myModuleName();
  if(!mappingHasKey(LinkedAxiis,owner))
    return 0;
  return LinkedAxiis[owner];
}
*/
