// SPDX-FileCopyrightText: © 2001 CERN <mail-TTO@cern.ch>
#uses "fwGeneral/fwGeneral.ctl"

/**Gets a list of all the data point names of dps which have a data point element
   which is a type reference to a given type and which have the given name.

   Modification History: None

   Constraints: None

   Usage: JCOP framework internal, public

   PVSS manager usage: VISION, CTRL

   @param typeRefToLookFor: The data point type reference to look for (eg. _FwDeclarations)
   @param dpElementName: The name of the data point element to search for (eg. fwDeclarations)
   @param returnList: The list of data point names is returned here
   @param exception: Details of any exceptions are returned here

   @author Herve Milcent (IT-CO)
   @deprecated 2018-08-16
 */
void fwListManipulation_getListOfDpWithRef(string typeRefToLookFor, string dpElementName,
										   dyn_string &returnList, dyn_string &exception)
{
	FWDEPRECATED();
	int i;
	dyn_string typeList, dpList, tempDpList;

	fwListManipulation_getListOfDpTypeWithRef(typeRefToLookFor, dpElementName, typeList, exception);

	for (i = 1; i <= dynlen(typeList); i++) {
		tempDpList = dpNames("*", typeList[i]);
		if (dynlen(tempDpList) > 0)
			dynAppend(dpList, tempDpList);
	}

	returnList = dpList;
}
