// SPDX-FileCopyrightText: © 2014 CERN <mail-TTO@cern.ch>
/**@file

   This library is used to take a screen shot of the current module and panel and either save it or send it by email.
   It also provides the functions to export the content of a table to file or by email.

   The two functions fwScreenShot_exportTableContentUserMenu and fwScreenShot_screenShotUserMenu are selfcontained
   and be called directly from any panel. It will proposed a dropdown menu allowing the user to choose what action
   he wants to do, i.e. send by email or save to disk.

   @par Creation Date
        23/06/14


   @par Modification History
        23/06/14 Jean-Charles Tournier - Initial implementation

   @par Constraints

   @author
        Jean-Charles Tournier (EN-ICE-SCD)
 */

//panel used to send email
const string FWSCREENSHOT_EMAILPANEL = "objects/fwGeneral/fwSendEmail.pnl";

//character used to delimit the column when exporting the table content to a csv file
const string FWSCREENSHOT_CSV_DELIMITER = ";";

//global variable to make each Send Email panel unique so as to be able to open several simultaneously
global int gNumEmailSent = 1;

/**
   Open an popup menu for the user to decide if he wants to save the screenshot to disk
   or to send it by mail and perform the actions

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[out] exceptionInfo 	Details of errors/exceptions returns here
   @param[in] sModuleName 		name of the module which will be screenshoted. By default myModuleName is considered
   @param[in] sPanelName 		name of the panel which will be screenshoted. By default myPanelName is considered
 **/
void fwScreenShot_screenShotUserMenu(dyn_string &exceptionInfo, string sModuleName = "", string sPanelName = "")
{
	dyn_string dsMenu;
	int answer;
	string fileName;

	dsMenu = makeDynString("PUSH_BUTTON, Save screenshot to disk, 1, 1",
						   "PUSH_BUTTON, Send screenshot by e-mail, 2, 1"
						   );

	popupMenu(dsMenu, answer);

	if ( answer == 1) {
		fwScreenShot_saveScreenShotToFile( exceptionInfo, sModuleName, sPanelName);
	} else if ( answer == 2) {
		fwScreenShot_sendScreenShotByEmail( exceptionInfo, sModuleName, sPanelName);
	}
}

/**
   Open an popup menu for the user to decide if he wants to save the content of a table to disk
   or to send it by mail and perform the actions

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[in]  sTableName		name of the table shape for which the content need to be exported
   @param[out] exceptionInfo	Details of errors/exceptions returns here
 **/
void fwScreenShot_exportTableContentUserMenu(string sTableName, dyn_string &exceptionInfo)
{

	if ( shapeExists(sTableName) == false) {
		fwException_raise(exceptionInfo, "ERROR", "Shape does not exists: " + sTableName + " when exporting the table content.", "");
		return;
	}

	dyn_string dsMenu;
	int answer;
	string fileName;

	dsMenu = makeDynString("PUSH_BUTTON, Save table content to disk, 1, 1",
						   "PUSH_BUTTON, Send table content by e-mail, 2, 1"
						   );

	popupMenu(dsMenu, answer);

	if ( answer == 1) {
		fwScreenShot_saveTableContentToFile( sTableName, exceptionInfo);
	} else if ( answer == 2) {
		fwScreenShot_sendTableContentByEmail( sTableName, exceptionInfo);
	}
}

/** @internal @private
   Take a screenshot of a given panel and module and save it to a file

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[in] sFileName 		name of the file (absolute path) to which the screenshot will be saved
   @param[out] exceptionInfo	Details of errors/exceptions returns here
   @param[in] sModuleName 		name of the module which will be screenshoted. By default myModuleName is considered
   @param[in] sPanelName 		name of the panel which will be screenshoted. By default myPanelName is considered
 **/
void _fwScreenShot_takeScreenShotToFile( string sFileName, dyn_string &exceptionInfo, string sModuleName = "", string sPanelName = "")
{
	if (sModuleName == "")
		sModuleName = myModuleName();

	if (sPanelName == "")
		sPanelName = myPanelName();

	bool bIsFileWrittable = _fwScreenShot_isFileWritable( sFileName, exceptionInfo);
	if ( bIsFileWrittable == false) {
		fwException_raise(exceptionInfo, "ERROR", "Could not save screenshot to the file: " + sFileName, "");
		return;
	}

	setValue(sModuleName + "." + sPanelName + ":", "imageToFile", sFileName);
}

/** @internal @private
   Take a screenshot of a given panel and module and save it to a file

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[in]	sTableName		name of the table shape which content needs to be exported
   @param[in]	sFileName		name of the file (absolute path) to which the screenshot will be saved
   @param[out]	exceptionInfo	Details of errors/exceptions returns here
 **/
void _fwScreenShot_takeTableContentToFile( string sTableName, string sFileName, dyn_string &exceptionInfo)
{
	bool bIsFileWrittable = _fwScreenShot_isFileWritable( sFileName, exceptionInfo);

	if ( bIsFileWrittable == false) {
		fwException_raise(exceptionInfo, "ERROR", "Could not save the table content to the file: " + sFileName, "");
		return;
	}
	setValue( sTableName, "writeToFile", sFileName, TABLE_WRITE_ALL_COLUMNS | TABLE_WRITE_COLUMN_HEADER,  FWSCREENSHOT_CSV_DELIMITER);
}


/**
   Take a screenshot of a given panel and module and send it by email
   To send a screenshot by email, a file containing the screenshot must be
   created first. The function will first try to find a place where to
   create this file, but in case of failure it will ask the user to choose
   a writtable folder where the screenshot can be saved.

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[out]	exceptionInfo	Details of errors/exceptions returns here
   @param[in] 	sModuleName		name of the module which will be screenshoted. By default myModuleName is considered
   @param[in]	sPanelName		name of the panel which will be screenshoted. By default myPanelName is considered
 **/
void fwScreenShot_sendScreenShotByEmail(dyn_string &exceptionInfo, string sModuleName = "", string sPanelName = "")
{
	string sFileName = _fwScreenShot_getTemporaryFileName("fwScreenShot_tmp_", "png", exceptionInfo);

	//if no file/path could be determined automatically, then ask the user
	if (dynlen(exceptionInfo)) {
		int ret = fileSelector( sFileName, PROJ_PATH, false, "*.png", false );
		if ( ret == -1) {
			dynClear(exceptionInfo);
			fwException_raise(exceptionInfo, "ERROR", "fileSelector() for *.png failed when sending the screenshot by email.", "");
			return;
		}

		//it means the user click on cancel in the file selector
		if ( sFileName == "")
			return;
	}

	//reset the exception as this point the file is correct
	dynClear(exceptionInfo);

	//check that the file name has the correct extension
	_fwScreenShot_checkFileExtension( sFileName, "png", exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//now save the screenshot to the temporary file
	_fwScreenShot_takeScreenShotToFile( sFileName, exceptionInfo, sModuleName, sPanelName);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//and open the panel to send email
	ChildPanelOn( FWSCREENSHOT_EMAILPANEL,
				  "Send e-mail " + (gNumEmailSent++),
				  makeDynString("$attach:" + sFileName),
				  300, 200);
}


/**
   Take the content of table and send it by email as an attachement
   The function will first try to find a place where to
   create this attachement, but in case of failure it will ask the user to choose
   a writtable folder where the file can be saved.

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[in]	sTableName		name of the table shape which content needs to send by email
   @param[out]	exceptionInfo	Details of errors/exceptions returns here
 **/
void fwScreenShot_sendTableContentByEmail(string sTableName, dyn_string &exceptionInfo)
{
	string sFileName = _fwScreenShot_getTemporaryFileName("fwTableContent_tmp_", "csv", exceptionInfo);

	//if no file/path could be determined automatically, then ask the user
	if (dynlen(exceptionInfo)) {
		int ret = fileSelector( sFileName, PROJ_PATH, false, "*.csv", false );
		if ( ret == -1) {
			dynClear(exceptionInfo);
			fwException_raise(exceptionInfo, "ERROR", "fileSelector() for *.csv failed when sending the table content by email.", "");
			return;
		}

		//it means the user click on cancel in the file selector
		if ( sFileName == "")
			return;
	}

	//reset the exception as this point the file is correct
	dynClear(exceptionInfo);

	//check that the file name has the correct extension
	_fwScreenShot_checkFileExtension( sFileName, "csv", exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//now save the table content to the temporary file
	_fwScreenShot_takeTableContentToFile( sTableName, sFileName, exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//and open the panel to send email
	ChildPanelOn( FWSCREENSHOT_EMAILPANEL,
				  "Send e-mail " + (gNumEmailSent++),
				  makeDynString("$attach:" + sFileName),
				  300, 200);
}

/**
   Allow the user to save the screenshot of any given module and panel to a specific file.
   By default the user will be proposed to save the file in its own directory

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[out]	exceptionInfo	Details of errors/exceptions returns here
   @param[in]	sModuleName		name of the module which will be screenshoted. By default myModuleName is considered
   @param[in]	sPanelName		name of the panel which will be screenshoted. By default myPanelName is considered
 **/
void fwScreenShot_saveScreenShotToFile(dyn_string &exceptionInfo, string sModuleName = "", string sPanelName = "")
{
	string sFileName;
	string sPath = _fwScreenShot_getUserWritableFolder(exceptionInfo);
	int ret = fileSelector( sFileName, sPath, false, "*.png", false );

	if ( ret == -1 ) {
		fwException_raise(exceptionInfo, "ERROR", "fileSelector() for *.png failed when saving screenshot to the file", "");
		return;
	}

	//if the user clicked on return
	if ( sFileName == "")
		return;

	//reset the exception as this point the file is correct
	dynClear(exceptionInfo);

	//check that the file name has the correct extension
	_fwScreenShot_checkFileExtension( sFileName, "png", exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//now save the screenshot to the temporary file
	_fwScreenShot_takeScreenShotToFile( sFileName, exceptionInfo, sModuleName, sPanelName);
	if ( dynlen(exceptionInfo)) {
		return;
	}
}

/**
   Allow the user to save the content of a table passed as parameter to a csv file.
   By default the user will be proposed to save the file in its own directory

   @par Usage
    Public

   @par WinCC OA Manager
    UI

   @param[in]	sTableName		name of the tabel shape to be exported
   @param[out]	exceptionInfo	Details of errors/exceptions returns here
 **/
void fwScreenShot_saveTableContentToFile(string sTableName, dyn_string &exceptionInfo)
{
	if (shapeExists(sTableName) == false) {
		fwException_raise(exceptionInfo, "ERROR", "Shape does not exists: " + sTableName + " when saving the table content.", "");
		return;
	}

	string sFileName;
	string sPath = _fwScreenShot_getUserWritableFolder(exceptionInfo);
	int ret = fileSelector( sFileName, sPath, false, "*.csv", false );
	if ( ret == -1 ) {
		fwException_raise(exceptionInfo, "ERROR", "fileSelector() for *.csv failed when saving the table content to the file.", "");
		return;
	}

	//if the user clicked on return
	if (sFileName == "") return;

	//reset the exception as this point the file is correct
	dynClear(exceptionInfo);

	//check that the file name has the correct extension
	_fwScreenShot_checkFileExtension( sFileName, "csv", exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}

	//now save the table content to the file
	_fwScreenShot_takeTableContentToFile( sTableName, sFileName, exceptionInfo);
	if ( dynlen(exceptionInfo)) {
		return;
	}
}


/** @internal @private
   Return the name of a file along with its path which can be used to take the screenshot
   when sending by email

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[in]	sFilePrefix 	prefix for the file name with will be build
   @param[in]	sExtension		extension used for the file name
   @param[out]	exceptionInfo Details of errors/exceptions returns here
   @return the name of the file with its path or empty in case of errors/exceptions
 **/
string _fwScreenShot_getTemporaryFileName( string sFilePrefix, string sExtension, dyn_string &exceptionInfo)
{
	string sFileName = tmpnam();                                //e.g. /tmp/file0001.tmp
	string sBaseName = baseName(sFileName);                     //e.g. file0001.tmp

	strreplace( sFileName, sBaseName, sFilePrefix + sBaseName); //e.g. /tmp/fwTableContent_tmp_file0001.tmp
	sFileName = delExt(sFileName) + "." + sExtension;           //e.g. /tmp/fwTableContent_tmp_file0001.csv


	bool bIsFileWrittable = _fwScreenShot_isFileWritable( sFileName, exceptionInfo);
	if ( bIsFileWrittable == false) {
		fwException_raise(exceptionInfo, "ERROR", "Could not create a temporary file.", "");
		return "";
	}

	return sFileName;
}


/** @internal @private
   Return the name of folder in which the user can save a file. It scans the usual
   windows folders as well as the linux folder. If no writable folder can be found,
   an empty string is returned

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[out] exceptionInfo Details of errors/exceptions returns here
   @return the name of the folder to which the user has write access
 **/
string _fwScreenShot_getUserWritableFolder( dyn_string &exceptionInfo)
{
	string sUser = getUserName();
	string sFirstLetter = sUser[0];
	dyn_string dsPossibleFolders;

	if (_WIN32) {
		dsPossibleFolders = makeDynString(
			"H:\\home-" + sFirstLetter + "\\" + sUser + "\\",
			"H:\\user\\" + sFirstLetter + "\\" + sUser + "\\",
			"G:\\Users\\" + sUser + "\\Public\\",
			"G:\\Users\\" + sUser + "\\Desktop\\",
			"G:\\Users\\" + sFirstLetter + "\\" + sUser + "\\Public\\",
			"G:\\Users\\" + sFirstLetter + "\\" + sUser + "\\Desktop\\",
			"D:\\Profiles\\" + sUser + "\\Downloads\\",
			"c:\\temp\\"
			);
	} else {
		dsPossibleFolders = makeDynString(
			"/eos/user/" + sFirstLetter + "/" + sUser,
			"/afs/cern.ch/user/" + sFirstLetter + "/" + sUser + "/public/",
			"/tmp/"
			);
	}

	for (int i = 1; i <= dynlen(dsPossibleFolders); i++) {
		if ( access(dsPossibleFolders[i], F_OK) == 0) {
			if ( access(dsPossibleFolders[i], W_OK) == 0) return dsPossibleFolders[i];
		}
	}

	return "";
}


/** @internal @private
   Check if a file can be created/written. Compared to the function access(), this
   function can handle cases where the file does not exists yet

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[in]	sFileName	absolute file name to be checked
   @param[out]	exceptionInfo Details of errors/exceptions returns here
   @return true if the file is writtable, false otherwise
 **/
bool _fwScreenShot_isFileWritable( string sFileName, dyn_string &exceptionInfo)
{
	file f;

	f = fopen(sFileName, "w");
	if ( 0 == f ) return false;
	fclose(f);
	return true;
}

/** @internal @private
   Check if a file has a particular extension. If it does not, it adds the extension
   to the name of the file

   @par Usage
    Private

   @par WinCC OA Manager
    UI

   @param[in]	sFileName 		file name to be checked
   @param[in]	sExtension 		extension to be checked without the .
   @param[out]	exceptionInfo	Details of errors/exceptions returns here
 **/
void _fwScreenShot_checkFileExtension( string &sFileName, string sExtension, dyn_string &exceptionInfo)
{
	sExtension = "." + sExtension;
	if ( strpos( strtolower(sFileName), strtolower(sExtension) ) != (strlen(sFileName) - strlen(sExtension) ) ) {
		sprintf( sFileName, "%s%s", sFileName, sExtension );
	}
}
