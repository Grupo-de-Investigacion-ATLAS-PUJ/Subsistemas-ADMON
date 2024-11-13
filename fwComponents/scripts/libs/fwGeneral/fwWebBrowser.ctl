// SPDX-FileCopyrightText: © 2017 CERN <mail-TTO@cern.ch>
/**@file

   This library provides functions for opening the fwWebBrowser: a web browser based
   on the WinCCOA's (and Qt's) built-in webview widget. This browser has basic
   navigation functionality and features tabbed view.
 */

/** @internal @private
	Load fwViewer/fwViewer_API, if it is present in the system ignore if it is not...
*/
private const bool _fwViewerLoaded = fwGeneral_loadCtrlLib("fwViewer/fwViewer_API.ctl",false);


/**
    Opens a new web browser as a child panel, with a specified URL

    @param sLink specifies the URL to open
    @param sLabel (optional) allows to define the name of the tab in which the URL is open
    @param sWindowName (optional) allows to define the window name (it will appear in the task bar)
    @param bNavigationButton (optional) if true, navigation buttons will be shown
    @param bUrlBarVisibility (optional) if true, URL bar will be displayed
    @param bAddressEditable (optional) if true, the address in URL bar may be edited
    @param bNewTabButton (optional) if true, a button to open a new tab will be shown
    @param sDefaultPage (optional) declares the default (home) page
    @param bOpenInNewModule (optional) if true, it will be opened in a new module
    @param[out] exceptionInfo standard exception handling variable
 */
void fwWebBrowser_showStandaloneWindow(string sLink, dyn_string &exceptionInfo,
									   string sLabel = "",
									   string sWindowName = "",
									   bool bNavigationButton = 1,
									   bool bUrlBarVisibility = 1,
									   bool bAddressEditable = 1,
									   bool bNewTabButton = 1,
									   string sDefaultPage = "http://home.cern",
									   bool bOpenInNewModule = 1)
{
	bool hasFwViewer = isFunctionDefined("fwViewer_showStandaloneWindow");

	// fwViewer lib, if existing, should have been loaded (see _fwViewerLoaded on the top of file)

	if (hasFwViewer) {
		fwViewer_showStandaloneWindow(sLink, exceptionInfo, sLabel, sWindowName, bNavigationButton, bUrlBarVisibility, bAddressEditable, bNewTabButton, sDefaultPage, bOpenInNewModule);
	} else {
		fwGeneral_openInExternalBrowser(sLink, exceptionInfo);
	}
}

