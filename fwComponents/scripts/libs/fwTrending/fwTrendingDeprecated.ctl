/** Copies all the configuration data from a source page to a target page that already exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@deprecated 2018-06-25

@param _from		the data point name of the source page
@param _to			the data point name of the target page
*/
void fwTrending_copyPageData(string _from, string _to)
{

  FWDEPRECATED();

	dyn_string exceptionInfo;
	dyn_dyn_string data;

	fwTrending_getPage(_from, data, exceptionInfo);
	fwTrending_setPage(_to, data, exceptionInfo);
}




/** Delete a curve configuration from the specified curve position of a plot configuration data point.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@deprecated 2018-06-25

@param plotDp					input, the name of the plot configuration data point
@param curveToDelete			input, the position of the curve to delete
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_deleteCurve(string plotDp, int curveToDelete, dyn_string &exceptionInfo)
{

  FWDEPRECATED();

	fwTrending_deleteManyCurves(plotDp, makeDynInt(curveToDelete), exceptionInfo);
}





/** Purpose: disconnect the curves of the active trend, this function is called when switching from standard to log and vice-versa,
the non active trend is disconnected to the DPEs

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25


@par PVSS managers
	VISION

@param dsCurveDPE		input, list of 8 DPEs connected to the curves of the plot
@param activeTrend		input, name of the active trend graphical element (with any reference name included e.g. ref.standardTrend)
*/
fwTrending_disconnectActiveTrend(dyn_string dsCurveDPE, string activeTrend)
{

  FWDEPRECATED();

	string sCurveDPE1, sCurveDPE2, sCurveDPE3;
	shape activeTrendShape;
	int i;

	activeTrendShape = getShape(activeTrend);

	// disconnect all the curves
	for(i = 1; i <= fwTrending_TRENDING_MAX_CURVE; i++)
	{
		if(dsCurveDPE[i] != "")
		{
			activeTrendShape.disconnectDirectly("curve_" + i);
		}
	}
}




/** Open a configuration panel to edit the given page

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	VISION

@param sDpName		input, the data point name of the the page to configure
*/
fwTrending_editPage(string sDpName)
{

  FWDEPRECATED();

	dyn_string panelsList, exceptionInfo, ds;
	dyn_float df;

	fwDevice_getDefaultConfigurationPanels(fwTrending_PAGE, panelsList, exceptionInfo);

	ChildPanelOnModalReturn(panelsList[1] + ".pnl", "Page Configuration",
							makeDynString("$Command:edit", "$sDpName:" + sDpName, "$WorkPageName:"), 0, 0, df, ds);
}





/** Open a configuration panel to edit the given plot

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	VISION

@param sDpName		input, the data point name of the the plot to configure
*/
fwTrending_editPlot(string sDpName)
{

  FWDEPRECATED();

	dyn_string panelsList, exceptionInfo, ds;
	dyn_float df;

	fwDevice_getDefaultConfigurationPanels(fwTrending_PLOT, panelsList, exceptionInfo);

	ChildPanelOnModalReturn(panelsList[1] + ".pnl", "Plot Configuration",
							makeDynString("$Command:edit", "$sDpName:" + sDpName), 0, 0, df, ds);
}



/** Get the list of plot dps that belong to a page

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	VISION, CTRL

@param sPageName		input, the page DP name
@param dsPlotDps		output, the list of plot DP Names of type FwTrendingPlot
						the dps are ordered by column: plots of column 1, followed by plots of column 2, etc. with no "" between
*/
fwTrending_getPagePlotDps(string sPageName, dyn_string &dsPlotDps)
{

  FWDEPRECATED();

	dyn_string exceptionInfo;
	dyn_dyn_string pageData;

	fwTrending_getPage(sPageName, pageData, exceptionInfo);
	fwTrending_simplifyPagePlotList(pageData[fwTrending_PAGE_OBJECT_PLOTS],
									pageData[fwTrending_PAGE_OBJECT_NROWS][1],
									pageData[fwTrending_PAGE_OBJECT_NCOLS][1], dsPlotDps, exceptionInfo);
}




/** Inserts a given curve configuration to a certain curve position of a plot configuration data point.
The previous curve from that position and curves from later positions are moved one position along to provide space
for the new curve. Similar in concept to dynInsertAt().

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	VISION, CTRL

@param plotDp				input, the name of the plot configuration data point
@param curveData			input, a curve data object (as defined by fwTrending_CURVE_OBJECT_... constants)
@param position				input, the position in which to insert this curve
@param exceptionInfo		output, details of any exceptions are returned here
@param forceInsert			OPTIONAL PARAMETER - default value FALSE
							If TRUE, if the 8th curve is in use, it will be lost when the new curve is inserted
							If FALSE, if the 8th curve is in use, an exception will be raised and no curve inserted
*/
fwTrending_insertCurveAt(string plotDp, dyn_string curveData, int position, dyn_string &exceptionInfo,
						 bool forceInsert = FALSE)
{

  FWDEPRECATED();

	int i, length, objectSize;
	dyn_int positions, curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string plotData;

	if(!forceInsert)
	{
		fwTrending_getFreeCurves(plotDp, positions, exceptionInfo);
		if(dynMax(positions) != fwTrending_MAX_NUM_CURVES)
		{
			fwException_raise(exceptionInfo, "ERROR", "Insertion of curve failed. " +
							  + "There is a curve in the final curve position, so inserting a new curve would cause the existing curve to be lost.", "");
			return;
		}
	}

	fwTrending_getPlot(plotDp, plotData, exceptionInfo);

	_fwTrending_checkCurveData(curveData, position, exceptionInfo);
	if(dynlen(exceptionInfo) > 0)
	{
		return;
	}

	objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
	for(i = 1; i <= objectSize; i++)
	{
		length = dynInsertAt(plotData[plotObjectIndexes[i]], curveData[curveObjectIndexes[i]], position);
		while(length > fwTrending_MAX_NUM_CURVES)
		{
			dynRemove(plotData[plotObjectIndexes[i]], length);
			length = dynlen(plotData[plotObjectIndexes[i]]);
		}
	}

	fwTrending_setPlot(plotDp, plotData, exceptionInfo);
}






/** Writes the given plot name to the dyn_string containing a list of the plots on a page by giving the column and row of the plot.

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	VISION, CTRL

@param plotsList		the list of plots on a page is passed here and is updated by the function
@param column			input, the column of the plot to read
@param row				input, the row of the plot to read
@param plotName			input, the name of the plot to add in the list of plots on a page
*/
void fwTrending_setColRow(dyn_string &plotsList, int column, int row, string plotName)
{

  FWDEPRECATED();

	plotsList[fwTrending_MAX_ROWS * (row - 1) + column] = plotName;
}




