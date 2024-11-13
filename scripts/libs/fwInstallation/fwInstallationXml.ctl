// $License: NOLICENSE
/**@file
 *
 * This package contains functions to manipulate the component XML description files
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */
#uses "CtrlXml"
#uses "fwInstallation/fwInstallation.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installation tool
 * Please do not edit it manually
 * @ingroup Constants
*/
const string csFwInstallationXmlLibVersion = "9.1.3";
const string csFwInstallationXmlLibTag = "";

/** Constant used in the mapping that identifies the node-type of the node in question
 * @ingroup Constants
*/
const string fwInstallation_Xml_CHILDNODESTYPE = "fwXml_ChildNodesType";
/** Constant used in the mapping that identifies the node-identifier of the node in question
 * @ingroup Constants
*/
const string fwInstallation_Xml_CHILDSUBTREEID = "fwXml_ChildSubTreeId";

/**
 * @name fwInstallation.ctl: Definition of constants

   The following constants define the indeces of the different elements 
   in the component XML file when passed as a dyn_dyn_mixed matrix

 * @{
 */
const int FW_INSTALLATION_XML_COMPONENT_NAME = 1;
const int FW_INSTALLATION_XML_COMPONENT_VERSION = 2;
const int FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT = 3;
const int FW_INSTALLATION_XML_COMPONENT_DATE = 4;
const int FW_INSTALLATION_XML_COMPONENT_HELP_FILE = 5;
const int FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS = 6;
const int FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES = 7;
const int FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS = 8;
const int FW_INSTALLATION_XML_COMPONENT_COMMENTS = 9;
const int FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS = 10;
const int FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS = 11;
const int FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS = 12;
const int FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS = 13;
const int FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES = 14;
const int FW_INSTALLATION_XML_COMPONENT_PANEL_FILES = 15;
const int FW_INSTALLATION_XML_COMPONENT_LIBRARY_FILES = 16;
const int FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES = 17;
const int FW_INSTALLATION_XML_COMPONENT_OTHER_FILES = 18;
const int FW_INSTALLATION_XML_DESC_FILE = 19;
const int FW_INSTALLATION_XML_COMPONENT_DONT_RESTART = 20;
const int FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS = 21;
const int FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX = 22;
const int FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION = 23;
const int FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION = 24;
const int FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH = 25;
const int FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS = 26;
const int FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES = 27;
const int FW_INSTALLATION_XML_COMPONENT_FILES = 28;
const int FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS_CURRENT = 29; //
const int FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS_CURRENT = 30;
const int FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION = 31;
const int FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION = 32;
const int FW_INSTALLATION_XML_COMPONENT_DESCRIPTION = 33;
const int FW_INSTALLATION_XML_COMPONENT_IS_HIDDEN_COMPONENT = 34;
const int FW_INSTALLATION_XML_COMPONENT_BIN_FILES = 35;
const int FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES = 36;

const string FW_INSTALLATION_XML_TAG_ROOT_COMPONENT = "component";

//@} // end of constants

/** 'fwInstallation_xmlChildNodesContent()' this function is a copy of 
 'fwXml_childNodesContent'  and it should be eventually replace once the fwXml.ctl is widely distributed.
 It returns tags, attributes and contained data of all children

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param doc               input, the document identifier
@param node              input, the node identifier of the parent element-node container
@param node_names        output, the node-names or tag-names for element-nodes
@param attributes        output, the attributes of element-nodes and added infomation
@param nodevalues        output, the node-values or values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, the combined types of the type of children which data is returned
        
@par When used for simple Xml-file structures
If the function returns '0' (zero), then the child-nodes are all element-nodes
which contain at most one text-node as their child.  The following is returned via
the three output-parameters: 'node_names' returns the tag-names of the element-nodes, 
'attributes' returns all the attributes of the element-nodes, 'nodevalues' returns 
the value (character-data) of the contained text-node if present, otherwise it returns 
the empty string.

@par
A typical example is included in the example-panel "xmlChildNodesContentExample.pnl"
(first push-button).  The Xml-file "xmlExampleFlatListing.xml" can be completely 
read by issuing one single call to this function - specify for the 'node' variable 
the node-identifier of the element-node called "<room>".

@par
Note that this function was created especially for users who want to parse Xml-files
of a structure which corresponds to the above description.  Only read further if you
want to use this function to parse more complex Xml-file structures.

@par When used for complex Xml-file structures
If any of the child-nodes is different from an element-node which contains at most one
text-node as its child, then the return-code will be different from '0' and will be
more specific the bitwise OR-ed values which are obtained by shifting the value '1' 
to the left by a number of places which corresponds to the internal enumerated value 
of the node-type.

@par
An example will illustrate this much easier.  Refer again to the example-panel
"xmlChildNodesContentExample.pnl" (second push-button).  The Xml-file corresponds
this time to "xmlExampleGreatText.xml".  In this example there is in addition to 
the above at least one text-node as a direct child (not as a child of an element-node).
In that case, the return-code is '8' - this is obtained by shifting '1' to the left 
by XML_TEXT_NODE places (1<<XML_TEXT_NODE) [1<<3].  

@par
For nodes which are not element-nodes, the returned values are: 'node_names' returns 
the node-name of the node as queried by 'xmlNodeName', 'attributes' returns a single 
mapping "[fwInstallation_Xml_CHILDNODESTYPE;(int)<node-type>]" which indicates the node-type of the 
node, 'nodevalues' returns the node-value of the node as queried by 'xmlNodeValue'.

@par
If there is additionally at least one child-node with more than one child or with 
a child which is not a text-node then the return-code will have the bit-value '2'
also set.  The same example-panel "xmlChildNodesContentExample.pnl" illustrates
this.  Third button parses the "xmlExampleHierarchical.xml" Xml-file - return-code 
corresponds to '2' (1<<XML_ELEMENT_NODE) [1<<1]. Fourth button parses the Xml-file
"xmlExampleMoreComplex.xml"  - return-code corresponds to '10' - obtained by bitwise 
OR-ing of (1<<XML_ELEMENT_NODE) and (1<<XML_TEXT_NODE) which is [(1<<1)|(1<<3)].

@par
For element-nodes with more than one child or with a child which is not a text-node, 
the returned values are: 'node_names' returns the tag-name of the node, 'attributes' 
returns all the attributes of the element-nodes with additionally the two following 
added mappings "[fwInstallation_Xml_CHILDNODESTYPE;(int)XML_ELEMENT_NODE]" which is the node-type 
and "[fwInstallation_Xml_CHILDSUBTREEID;(int)<element-node-identifier>]", 'nodevalues' returns 
the empty string.
*/

int fwInstallationXml_childNodesContent ( unsigned doc , int node ,
              dyn_string &node_names , dyn_anytype &attributes , dyn_string &nodevalues ,
              dyn_string &exceptionInfo )
{
  int rtn_code;
  int node_typ;
  mapping node_att;
  string node_nam, node_val;
  dyn_int children, subnodes;
  int child_types = 0;

  node_names = makeDynString();
  attributes = makeDynAnytype();
  nodevalues = makeDynString();
  
  rtn_code = xmlChildNodes ( doc , node , children );
  if ( rtn_code != 0 ) return ( rtn_code );
  
  for ( int idx = 1 ; idx <= dynlen(children) ; ++idx )
  {
    node_typ = xmlNodeType ( doc , children[idx] );
    node_nam = xmlNodeName ( doc , children[idx] );
    
    mappingClear ( node_att );
    
    if ( node_typ == XML_ELEMENT_NODE )
    {
      node_att = xmlElementAttributes ( doc , children[idx] );
      
      rtn_code = xmlChildNodes ( doc , children[idx] , subnodes );
      if ( dynlen(subnodes) == 0 )
         { node_val = ""; }
      else if (  ( dynlen(subnodes) == 1 )
              && ( xmlNodeType ( doc , subnodes[1] ) == XML_TEXT_NODE ) )
         { node_val = xmlNodeValue ( doc , subnodes[1] ); }
      else
      {
        node_val = "";
        node_att[fwInstallation_Xml_CHILDNODESTYPE] = node_typ;
        node_att[fwInstallation_Xml_CHILDSUBTREEID] = children[idx];
        child_types |= ( 1 << node_typ );
      }
    }
    else
    {
      node_val = xmlNodeValue ( doc , children[idx] );
      node_att[fwInstallation_Xml_CHILDNODESTYPE] = node_typ;
      child_types |= ( 1 << node_typ );
    }
    
    dynAppend ( node_names , node_nam );
    dynAppend ( attributes , node_att );
    dynAppend ( nodevalues , node_val );
  }
  
  return ( child_types );
}
//@}

/**  This function retrieves the contents of an XML file
  @param docPath (in) XML file to be parsed
  @param tags (out) XML tags in the file as an dyn_string array
  @param values (out) values of the XML tags
  @param attribs (out) tag attributes
  @return 0 if OK, -1 if error, -2 when not a component file
*/
int fwInstallationXml_get(string docPath, 
                          dyn_string &tags, 
                          dyn_string &values, 
                          dyn_anytype &attribs)
{     
  string errMsg, errLin, errCol;
  int docum;
  int ident;
  string element;
  dyn_string exInfo;
  
  dynClear(values);
  dynClear(attribs);
  
  docum = xmlDocumentFromFile (docPath, errMsg, errLin, errCol);
  if ( docum < 0 )
  {
    fwInstallation_throw( "ERROR: fwInstallationXml_get() -> Parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol, "ERROR", 1 );
    return -1;
  }
    
  ident = xmlFirstChild ( docum );
  while ( xmlNodeType ( docum , ident ) != XML_ELEMENT_NODE )
    ident = xmlNextSibling ( docum , ident );

  element = xmlNodeName (docum, ident);
  if(element != FW_INSTALLATION_XML_TAG_ROOT_COMPONENT)
    return -2;//not a component file
  
  int ret = fwInstallationXml_childNodesContent(docum, ident, tags, attribs, values, exInfo);
  if(ret != 0 && ret != 256) // ret != 256 is required to account for comments in XML files
  {
  	xmlCloseDocument(docum);
    fwInstallation_throw( "ERROR: fwInstallationXml_get() -> Error reading XML children content", "ERROR", 1); 
    return -1;
  }
    
  if(xmlCloseDocument(docum))
  {
    fwInstallation_throw("WARNING: fwInstallationXml_get() -> Error closing the XML document", "WARNING", 1); 
    return -1;
  }
  //DebugN("dyn_string &tags, dyn_string &values", tags, values);
  return 0;
}

/**  This function the value and attributes of all entries in a XML file for a particular tag
  @param docPath (in) XML file to be parsed
  @param tag (in) XML tag to look for
  @param FilteredValues (out) values of the XML tags
  @param FilteredAttribs (out) tag attributes
  @return 0 if OK, -1 if error, -2 if not a component file
*/
int fwInstallationXml_getTag(string docPath, 
                             string tag, 
                             dyn_string &FilteredValues, 
                             dyn_anytype &FilteredAttribs)
{
  string errMsg, errLin, errCol;
  int docum;
  int ident;
  dyn_string tags;
  dyn_string values;
  dyn_anytype attribs;
  string element;
  
  int retVal = fwInstallationXml_get(docPath, tags, values, attribs);
  if(retVal == -2)
    return -2;
  if(retVal != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationXml_getTag() -> Could not parse XML file: " + docPath, "ERROR", 4); 
    return -1;
  }
  for (int idx=1 ;idx<=dynlen(tags) ;++idx )
  {
    if(tags[idx]==tag)
    {
      dynAppend(FilteredValues, values[idx]);
      dynAppend(FilteredAttribs, attribs[idx]);
    }
  }
  
  return 0;
}


/** This function creates a component description file (xml).

@param pathName						(in) path for the output file {if empty, only create xmlDesc}
@param componentInfo					(in) dyn_dyn_mixed containing the contents of the XML file to be created
@return 0 - xml file created, -1 - file creation failed, -2 - parameters missing
@author Fernando Varela.
*/
    
    
int fwInstallationXml_createComponentFile(string pathName, dyn_dyn_mixed componentInfo)
{
  //old variables:
   string componentName = componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
   string componentVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
   string componentDate = componentInfo[FW_INSTALLATION_XML_COMPONENT_DATE];
   dyn_string requiredComponents = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS];
   bool isSubComponent = componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT][1];
   dyn_string initScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
   dyn_string deleteScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
   dyn_string postInstallScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS];
   dyn_string postDeleteScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS];
   dyn_string configFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
   dyn_string asciiFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
   dyn_string panelFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_PANEL_FILES];
   dyn_string scriptFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
   dyn_string libraryFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_LIBRARY_FILES];
   dyn_string otherFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_OTHER_FILES];
   string dontRestartProject = componentInfo[FW_INSTALLATION_XML_COMPONENT_DONT_RESTART];
   
   //new variables:
    string helpFile = componentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE];
    dyn_string subComponents = componentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS];
    dyn_string comments = componentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS];
    string requiredPvssVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION];
    bool strictPvssVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION][1];    
    string requiredPvssPatch = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH];
    dyn_string preInitScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS];
    bool updateDPTs  = componentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES][1];    
    string requiredInstallerVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION];
    bool strictInstallerVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION][1];

    string description  = "";
    if(dynlen(componentInfo) >= FW_INSTALLATION_XML_COMPONENT_DESCRIPTION)    
      description = componentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION];

    bool isHiddenComponent = false;
    if(dynlen(componentInfo) >= FW_INSTALLATION_XML_COMPONENT_IS_HIDDEN_COMPONENT)
     isHiddenComponent = componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_HIDDEN_COMPONENT][1];
    
    dyn_string binFiles;
    if(dynlen(componentInfo) >= FW_INSTALLATION_XML_COMPONENT_BIN_FILES)
      binFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES];

    dyn_string qtHelpFiles;
    if(dynlen(componentInfo) >= FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES){
      qtHelpFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES];
    }

  	dyn_mixed xmlDesc;
	
 	time now = getCurrentTime();
	
	dynClear(xmlDesc);

	if(requiredComponents =="")
		dynClear(requiredComponents);
	if(initScripts =="")
		dynClear(initScripts);
	if(deleteScripts =="")
		dynClear(deleteScripts);
	if(postInstallScripts =="")
		dynClear(postInstallScripts);
	if(postDeleteScripts =="")
		dynClear(postDeleteScripts);
	if(configFiles =="")
		dynClear(configFiles);
	if(asciiFiles =="")
		dynClear(asciiFiles);
	if(panelFiles =="")
		dynClear(panelFiles);
	if(scriptFiles =="")
		dynClear(scriptFiles);
	if(libraryFiles =="")
		dynClear(libraryFiles);
	if(otherFiles =="")
		dynClear(otherFiles);

	if(componentName == "")
	{
		DebugTN("Your component should have a name!");
		return -2;		
	}
	if(componentVersion == "")
	{
		DebugTN("Your component should have a version number!");
		return -2;
	}

// build xml code	
	dynAppend(xmlDesc, "<component>");
// component name
	dynAppend(xmlDesc, "<name>" + componentName + "</name>");

  if(description != "") 
    dynAppend(xmlDesc, "<description>" + description + "</description>");
  
// component version
	dynAppend(xmlDesc, "<version>" + componentVersion + "</version>");
// release date
	if(componentDate == "")
		componentDate = year(now)+"/"+month(now)+"/"+day(now);
	dynAppend(xmlDesc, "<date>" + componentDate + "</date>");

// required components
	if(dynlen(requiredComponents) > 0)
		for(int i=1; i<=dynlen(requiredComponents); i++)
			dynAppend(xmlDesc, "<required>"+requiredComponents[i]+"</required>");

// sub-component?
	if(isSubComponent == TRUE)
		dynAppend(xmlDesc, "<subComponent>yes</subComponent>");
  
// hidden component?
  if(isHiddenComponent)
    dynAppend(xmlDesc, "<hiddenComponent>yes</hiddenComponent>");

//avoid project restart:
	if(strtolower(dontRestartProject) == "yes")
		dynAppend(xmlDesc, "<dontRestartProject>yes</dontRestartProject>");

 if(helpFile != "")
   dynAppend(xmlDesc, "<help>" + helpFile + "</help>");
 
 
  if(!updateDPTs) 
  	dynAppend(xmlDesc, "<update_types>no</update_types>");
 
  if(requiredPvssVersion != "") 
  {
    if(strictPvssVersion)
    {
      dynAppend(xmlDesc, "<required_pvss_version strict=\"yes\">"+requiredPvssVersion+"</required_pvss_version>");
    }
    else
    {
      dynAppend(xmlDesc, "<required_pvss_version>"+requiredPvssVersion+"</required_pvss_version>");
    }
  }

  
  if(requiredPvssPatch != "") 
  {
    dynAppend(xmlDesc, "<required_pvss_patch>"+requiredPvssVersion+"</required_pvss_patch>");
  }
  
  if(requiredInstallerVersion != "") 
  {
    if(strictInstallerVersion)
    {
      dynAppend(xmlDesc, "<required_installer_version strict=\"yes\">"+requiredInstallerVersion+"</required_installer_version>");
    }
    else
    {
      dynAppend(xmlDesc, "<required_installer_version>"+requiredInstallerVersion+"</required_installer_version>");
    }
  }
  
////////////////FVR: Move init and post install scripts to scripts folder according to the FW Guidelines.
//Pre-init scripts
  for(int i=1; i<=dynlen(preInitScripts); i++)
  {
    if(!patternMatch("./scripts/" + componentName + "/*", preInitScripts[i]))
    {
      dynAppend(xmlDesc, "<preinit>./scripts/" + componentName + "/" + preInitScripts[i]+"</preinit>");
    }
    else
    {
      dynAppend(xmlDesc, "<preinit>" + preInitScripts[i]+"</preinit>");
    }
  }

  for(int i=1; i<=dynlen(subComponents); i++)
  {
    dynAppend(xmlDesc, "<includeComponent>" + subComponents[i]+"</includeComponent>");
  }
  
  
  //Comments 
  for(int i=1; i<=dynlen(comments); i++)
  {
    dynAppend(xmlDesc, "<comment>"+comments[i]+"</comment>");
  }
 
 // init script(s)
	if(dynlen(initScripts) > 0)
          		for(int i=1; i<=dynlen(initScripts); i++){
			  //dynAppend(xmlDesc, "<init>./config/"+initScripts[i]+"</init>");
    if(!patternMatch("./scripts/" + componentName + "/*", initScripts[i]))
      dynAppend(xmlDesc, "<init>./scripts/" + componentName + "/" + initScripts[i]+"</init>");
    else
      dynAppend(xmlDesc, "<init>" + initScripts[i]+"</init>");
      
                      }
// delete script(s)
	if(dynlen(deleteScripts) > 0)
          		for(int i=1; i<=dynlen(deleteScripts); i++){
			  //dynAppend(xmlDesc, "<delete>./config/"+deleteScripts[i]+"</delete>");
    if(!patternMatch("./scripts/" + componentName + "/*", deleteScripts[i]))
      dynAppend(xmlDesc, "<delete>./scripts/" + componentName + "/" + deleteScripts[i]+"</delete>");
    else
      dynAppend(xmlDesc, "<delete>" + deleteScripts[i]+"</delete>");
                        }
// postInstall script(s)
	if(dynlen(postInstallScripts)> 0)
          		for(int i=1; i<=dynlen(postInstallScripts); i++){
			  //dynAppend(xmlDesc, "<postInstall>./config/"+postInstallScripts[i]+"</postInstall>");
    if(!patternMatch("./scripts/" + componentName + "/*", postInstallScripts[i]))
      dynAppend(xmlDesc, "<postInstall>./scripts/" + componentName + "/" + postInstallScripts[i]+"</postInstall>");
    else
      dynAppend(xmlDesc, "<postInstall>" + postInstallScripts[i]+"</postInstall>");
                        }

// postDelete script(s)
	if(dynlen(postDeleteScripts) > 0)
          		for(int i=1; i<=dynlen(postDeleteScripts); i++){
			//dynAppend(xmlDesc, "<postDelete>./config/"+postDeleteScripts[i]+"</postDelete>");
    if(!patternMatch("./scripts/" + componentName + "/*", postDeleteScripts[i]))
      dynAppend(xmlDesc, "<postDelete>./scripts/" + componentName + "/" + postDeleteScripts[i]+"</postDelete>");
    else
      dynAppend(xmlDesc, "<postDelete>" + postDeleteScripts[i]+"</postDelete>");
      
                      }
/////////////////FVR
        
// config files
	if(dynlen(configFiles) > 0)
		for(int i=1; i<=dynlen(configFiles); i++)
			if(strpos(configFiles[i], ".windows") > 0)
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config_windows>./config/"+configFiles[i]+"</config_windows>");
      else
  				dynAppend(xmlDesc, "<config_windows>"+configFiles[i]+"</config_windows>");
        
			else if(strpos(configFiles[i], ".linux") > 0)
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config_linux>./config/"+configFiles[i]+"</config_linux>");
      else
  				dynAppend(xmlDesc, "<config_linux>"+configFiles[i]+"</config_linux>");
        
			else 
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config>./config/"+configFiles[i]+"</config>");
      else
  				dynAppend(xmlDesc, "<config>"+configFiles[i]+"</config>");
        

// ascii import files
	if(dynlen(asciiFiles) > 0)
		for(int i=1; i<=dynlen(asciiFiles); i++)
    if(!patternMatch("./dplist/*", asciiFiles[i]))
  			dynAppend(xmlDesc, "<dplist>./dplist/"+asciiFiles[i]+"</dplist>");
    else
  			dynAppend(xmlDesc, "<dplist>"+asciiFiles[i]+"</dplist>");
      

// panel files
	if(dynlen(panelFiles) > 0)
		for(int i=1; i<=dynlen(panelFiles); i++)
    if(!patternMatch("./panels/*", panelFiles[i]))
			dynAppend(xmlDesc, "<file>./panels/"+panelFiles[i]+"</file>");
    else
  	   dynAppend(xmlDesc, "<file>"+panelFiles[i]+"</file>");
      
// script files		
	if(dynlen(scriptFiles) > 0)
		for(int i=1; i<=dynlen(scriptFiles); i++)
    if(!patternMatch("./scripts/*", scriptFiles[i]))
  			dynAppend(xmlDesc, "<file>./scripts/"+scriptFiles[i]+"</file>");
    else
  			dynAppend(xmlDesc, "<file>"+scriptFiles[i]+"</file>");
      
// library files
	if(dynlen(libraryFiles) > 0)
		for(int i=1; i<=dynlen(libraryFiles); i++)
    if(!patternMatch("./scripts/libs/*", libraryFiles[i]))
  			dynAppend(xmlDesc, "<file>./scripts/libs/"+libraryFiles[i]+"</file>");
    else
  			dynAppend(xmlDesc, "<file>"+libraryFiles[i]+"</file>");
      
// misc files
	if(dynlen(otherFiles) > 0)
		for(int i=1; i<=dynlen(otherFiles); i++)
      if(!patternMatch("./*", otherFiles[i]))
        dynAppend(xmlDesc, "<file>./"+otherFiles[i]+"</file>");
      else
        dynAppend(xmlDesc, "<file>"+otherFiles[i]+"</file>");
      
// binary files
  if(dynlen(binFiles) > 0){
    for(int i=1;i<=dynlen(binFiles);i++)
      if(!patternMatch("./*", binFiles[i]))
        dynAppend(xmlDesc, "<bin>./"+binFiles[i]+"</bin>");
      else
        dynAppend(xmlDesc, "<bin>"+binFiles[i]+"</bin>");
  }
  // qt help files
  if(dynlen(qtHelpFiles) > 0){
    for(int i=1;i<=dynlen(qtHelpFiles);i++){
      if(!patternMatch("./*", qtHelpFiles[i])){
        dynAppend(xmlDesc, "<qtHelp>./" + qtHelpFiles[i] + "</qtHelp>");
      }else{
        dynAppend(xmlDesc, "<qtHelp>" + qtHelpFiles[i] + "</qtHelp>");
      }
    }
  }

//	DebugTN(otherFiles, componentName+ ".xml", dynContains(otherFiles, componentName+ ".xml"), xmlDesc);
	
	if(dynContains(xmlDesc, "<file>./"+componentName+ ".xml</file>") <= 0)
	  dynAppend(xmlDesc, "<file>./"+componentName+ ".xml</file>");


	dynAppend(xmlDesc, "</component>");
        
// write xmlFile
	if(pathName != "")
	{
		file xmlText = fopen(pathName+"/"+componentName+".xml", "w");
		if(ferror(xmlText) != 0)
		{
			fclose(xmlText);
			return -1;
		}
		if(dynlen(xmlDesc) > 0)
		{
			for(int i=1; i<=dynlen(xmlDesc); i++)
				fputs(xmlDesc[i]+"\n", xmlText);
		}
		fclose(xmlText);
	}
  
  return 0;
}





//////////////////////////////////////////////////////////


/** This function loads the contents of a component XML file into a dyn_dyn_mixed matrix
  @param fileName (in) fileName name of the component xml file
  @param componentInfo (out) XML file contents as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if error
*/
int fwInstallationXml_load(string fileName, dyn_dyn_mixed &componentInfo)
{
  dyn_string tempDynString;
  string strComponentFile, tagName, tagValue;
  dyn_string tags, values;
  dyn_anytype attribs;
  dyn_string tmpFiles;
  
  string filePath;
  string filePattern; 
  dyn_int dplAttribs;
  
  dynClear(dplAttribs);

  if(!_WIN32 && !patternMatch("/*", fileName)) //Make sure the file name under linux starts with '/'
    fileName = "/" + fileName;
  
//  strreplace(fileName, "\\", "/");
//DebugN("Loading " + fileName);
  if(fwInstallationXml_get(fileName, tags, values, attribs) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationxml_load() -> Cannot load " + fileName + " file ", "error", 4);	
    return -1;
  }

  componentInfo[FW_INSTALLATION_XML_COMPONENT_DONT_RESTART] = "no"; //This value will be overriden with the value of the tag in the xml file if defined. Otherwise ths forces the value to be "no".  
  componentInfo[FW_INSTALLATION_XML_DESC_FILE] = "./" + _fwInstallation_fileName(fileName);
  componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT] = false;
  componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_HIDDEN_COMPONENT] = false;
  componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION] = false;
  componentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS] = makeDynString(); //Make sure the array has all required elemments
  componentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES] = true;
  componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION]= "no"; //ensure array length
  componentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES] = makeDynString(); // new tag added. ensure array length.
  //loop over all elements and order them according to their tags:
  for(int k = 1; k <= dynlen(tags); k++)
  {
    tagValue = values[k];
    switch(tags[k])
    {
      case "name":
        componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME] = tagValue;
         break;
      case "version" :
        componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION] = tagValue;
         break;
      case "date" :
        componentInfo[FW_INSTALLATION_XML_COMPONENT_DATE] = tagValue;
        break;
      case "help": 
        componentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE] = tagValue;
        break;
      case "dontRestartProject" :
        componentInfo[FW_INSTALLATION_XML_COMPONENT_DONT_RESTART] = strtolower(tagValue);
        break;
      case "description" :
//DebugN("tag description found, tagValue is ", tagValue);        
        componentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION] = tagValue;
        break;
      case "required": 
        if(tagValue != "")
          dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS], tagValue);
        break;  
      case "dplist":
        dynClear(tmpFiles);
        if(strpos(tagValue, "*") > 0){
          int numFindFiles = _fwInstallationXml_FindWildcardFiles(tagValue,fileName,tmpFiles);
          for(int i=0;i<numFindFiles;i++){
            dynAppend(dplAttribs, -1); //assume that all wildcard files can't have "order" attribute 
          }
        }else{
          dynAppend(tmpFiles, tagValue);
          mapping m = attribs[k];
          dynAppend(dplAttribs, (int)m.value("order", -1));
        }  
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES], tmpFiles);
        break; 
        
      case "required_installer_version":
        componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION] = tagValue;
        mapping m = attribs[k];
        componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION] = (m.value("strict", "no") == "yes");
        break;
      case "required_pvss_version":
        componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION] = tagValue;
        mapping m = attribs[k];
        componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION] = (m.value("strict", "no") == "yes");
        break; 
      case "required_pvss_patch":
        componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH] = tagValue;
        break;
      case "update_types":
        if(tagValue == "no"){
          componentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES] = false;
        }
        break; 
      case "preinit":
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS], tagValue);
        break; 
      case "includeComponent": //strreplace(tagValue, "./", "");
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS], tagValue);
        break;   
      case "comment":
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS], tagValue);
        break;   
      case "init" :	//DebugN("processing init files");
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS], tagValue);
        break;
      case "delete" :
        if(patternMatch("*./config/*", tagValue) ||
           patternMatch("*./scripts/*", tagValue)){
          dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS], tagValue);
        }
        break;
      case "postInstall" :
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS], tagValue);
        break;
      case "postDelete" :
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS], tagValue);
        break;
      case "script" : {
	        string message = "The tag <script> in the component description file (" + fileName + ") has " +
	                         "become obsolete. Please report this to the component developer.";
	        fwInstallation_throw(message, "WARNING", 10);
	        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES], tagValue);
        }
        break;
      case "config" :
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES], tagValue);
        break;
      case "config_windows" :
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS], tagValue);
        break;
      case "config_linux" :
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX], tagValue);
        break;
      case "file" :
        dynClear(tmpFiles);
        if(strpos(tagValue, "*") > 0)
        {
          _fwInstallationXml_FindWildcardFiles(tagValue,fileName,tmpFiles);
	      }
        else 
        {	      
          dynAppend(tmpFiles, tagValue);
        }

        fwInstallation_normalizePath(tagValue);
        tempDynString = strsplit(tagValue, "/");
        
        if(dynlen(tempDynString)>0)
        {
          switch(tempDynString[1])
          {
            case "panels":
              for(int z = 1; z <= dynlen(tmpFiles);z++)
                dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_PANEL_FILES], tmpFiles[z]);
              break;
            case "scripts":
              if(tempDynString[2] == "libs")
              {
                for(int z = 1; z <= dynlen(tmpFiles);z++)
                  dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_LIBRARY_FILES], tmpFiles[z]);
              } 
              else 
              {
                for(int z = 1; z <= dynlen(tmpFiles);z++)
                  dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES], tmpFiles[z]);
              }
              break;
            default:
              for(int z = 1; z <= dynlen(tmpFiles);z++)
                dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_OTHER_FILES], tmpFiles[z]);
              break;
          }
        }
        break;
      case "bin":
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES], tagValue);
        break;
      case "qtHelp":
        dynAppend(componentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES], tagValue);
        break;
      case "hiddenComponent":
        if((strtolower(tagValue) == "yes"))
          componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_HIDDEN_COMPONENT] = true;
        break;
      case "subComponent":
        if((strtolower(tagValue) == "yes"))
          componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT] = true;
        break;
      }
  }//end of loop

  //order list of dp list files:
  componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES] = fwInstallation_orderDplFiles(componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES], dplAttribs);   
    
  return 0;
}

/** This function finds all files that matches to the given pattern with wildcard (*)
  @param tagValue (in) XML tag 
  @param fileName (in) fileName name of the component xml file
  @param tmpFiles (out) list of matched files
  @return number of found files
  */
int _fwInstallationXml_FindWildcardFiles(string tagValue, string fileName, dyn_string &tmpFiles)
{
  string filePath = _fwInstallation_baseDir(tagValue);
  string filePattern = _fwInstallation_fileName(tagValue);
  string sourceDir =  _fwInstallation_baseDir(fileName);
  
  dyn_string fileNames = fwInstallation_getFileNamesRec(sourceDir + filePath, filePattern);
  
  for(int i=1; i<=dynlen(fileNames); i++)
  {
    if(!patternMatch("*/", filePath))
    {
      dynAppend(tmpFiles, filePath + "/" + fileNames[i]);
    }
    else
    {
      dynAppend(tmpFiles, filePath + fileNames[i]);
    }
  }
  return dynlen(fileNames);
}


/** This funcion parses a XML file. Contrarily to fwInstallationXML_load, this function prepends the relative destination path to the files
  @param sourceDir (in) source directory 
  @param descFile (in) XML description file 
  @param subPath (in) path to the appended to the source directory
  @param destinationDir (in) destination directory where the component will be installed
  @param parsedComponentInfo (out) resulting component info 
  @return 0 if OK, -1 if error
*/  
int fwInstallationXml_parseFile(string sourceDir, 
                                string descFile, 
                                string subPath,
				                          string destinationDir,
                                dyn_dyn_mixed &parsedComponentInfo)
{
  dyn_dyn_string componentsInfo;

  //Path manipulation:  
  //Make sure Linux paths start with "/"
  if(!_WIN32 && !patternMatch("/*", subPath))
    subPath = "/" + subPath;
  
  if(!_WIN32 && !patternMatch("/*", destinationDir))
    destinationDir = "/" + destinationDir;

  if(!_WIN32 && !patternMatch("/*", sourceDir))
    sourceDir = "/" + sourceDir;
    
  if(!_WIN32 && !patternMatch("/*", descFile))
    descFile = "/" + descFile;
  
  /*
  strreplace(subPath, "\\", "/");
  strreplace(destinationDir, "\\", "/");
  strreplace(sourceDir, "\\", "/");
  strreplace(descFile, "\\", "/");
  //try to remove double '/'
  strreplace(subPath, "//", "/" );
  strreplace(destinationDir, "//", "/" );
  strreplace(sourceDir, "//", "/" );
  strreplace(descFile, "//", "/" );
  */
  if(patternMatch(destinationDir, "/") <= 0) //force destination directory to end in '/'
   destinationDir += "/";
  //end of path manipulation
  
  dyn_dyn_mixed componentInfo;
  if(fwInstallationXml_load(descFile, componentInfo))
  {
    fwInstallation_showMessage(makeDynString("ERROR: fwInstallation_parseXmlFile() -> Cannot load " + descFile + " file "));
    return gFwInstallationError;
  }
  dyn_string postInstallScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS]; 
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS_CURRENT] = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS]; 

  dyn_string postDeleteScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS_CURRENT] = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS]; 
  dyn_string subComponents = componentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS];
  
  string xml = componentInfo[FW_INSTALLATION_XML_DESC_FILE];
  if(!patternMatch("./*", xml))
    xml = "./" + xml;

  dyn_string dynFileNames;
  dynAppend(dynFileNames, xml);		
  dyn_string inits = componentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
  dynAppend(dynFileNames, inits);
  dyn_string deletes = componentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
  dynAppend(dynFileNames, deletes);
  dyn_string cpPostInstallScripts = postInstallScripts; //Duplicate variables that we want to use later as they are wipe out by dynAppend();
  dynAppend(dynFileNames, postInstallScripts);
  dyn_string cpPostDeleteScripts = postDeleteScripts; //Duplicate variables that we want to use later as they are wipe out by dynAppend();
  dynAppend(dynFileNames, postDeleteScripts);
  dyn_string configs = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  dynAppend(dynFileNames, configs);
  dyn_string configsLinux = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX];
  dynAppend(dynFileNames, configsLinux);
  dyn_string configWindows = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS]; 
  dynAppend(dynFileNames, configWindows);
  dyn_string dplists = componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
  dynAppend(dynFileNames, dplists);
  dyn_string panels = componentInfo[FW_INSTALLATION_XML_COMPONENT_PANEL_FILES];
  dynAppend(dynFileNames, panels);
  dyn_string scripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  dynAppend(dynFileNames, scripts);
  dyn_string libs = componentInfo[FW_INSTALLATION_XML_COMPONENT_LIBRARY_FILES];
  dynAppend(dynFileNames, libs);
  dyn_string others = componentInfo[FW_INSTALLATION_XML_COMPONENT_OTHER_FILES];
  dynAppend(dynFileNames, others);  
  dyn_string preinits = componentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS];
  dynAppend(dynFileNames, preinits);
  dyn_string qtHelps = componentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES];
  dynAppend(dynFileNames, qtHelps);
  
  
  string help = componentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE] ;
  if(help != ""){
    // FWINS-2172: check if help file was also added using the <file> tag
    dyn_string dynMatchingHelpFile = dynPatternMatch("*/" + help, dynFileNames);
    dyn_string dynMatchingHelpDir = dynPatternMatch("*/help/*", dynMatchingHelpFile);
    if(dynMatchingHelpDir.count() == 0){ // help file not added with <file> tag
      // FWINS-2252: add help file to list of component files, find correct path inside help/
      const dyn_string searchHelpDirs = makeDynString("", "en_US.utf8/", "en_US.iso88591/");
      for(int i=0;i<searchHelpDirs.count();i++){
        string tmpHelpFile = sourceDir + "/help/" + searchHelpDirs.at(i) + help;
        if (access(tmpHelpFile, R_OK) == 0) {
          dynAppend(dynFileNames, "./help/" + searchHelpDirs.at(i) + help);
          break;
        }
      }
    }
  }
  
  dyn_string dynPostInstallFiles_current;

  for(int i = 1; i <= dynlen(cpPostInstallScripts); i++)
  {
    cpPostInstallScripts[i] = destinationDir + cpPostInstallScripts[i];
    dynAppend(dynPostInstallFiles_current, cpPostInstallScripts[i]);
  }
  
  //dynPostDeleteFiles
  dyn_string dynPostDeleteFiles_current;
  for(int i = 1; i <= dynlen(cpPostDeleteScripts); i++)
  {
    cpPostDeleteScripts[i] = destinationDir + "./" + strltrim(cpPostDeleteScripts[i], ".");
    dynAppend(dynPostDeleteFiles_current, cpPostDeleteScripts[i]);
  }

  //subcomponents
  dyn_string dynSubComponents;
  for(int i = 1; i <= dynlen(subComponents); i++)
  {
    strreplace(subComponents[i], "./", "");
    dynAppend(dynSubComponents, sourceDir + subPath + "/" + subComponents[i]);
  }
 
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_FILES] = dynFileNames;
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS] = dynSubComponents;
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS] = dynPostDeleteFiles_current;
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS] = dynPostInstallFiles_current;

  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_BIN_FILES];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_QT_HELP_FILES];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE] = componentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_NAME] = componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX] = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DATE] = componentInfo[FW_INSTALLATION_XML_COMPONENT_DATE];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH] = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS] = componentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES] = componentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES];  
  
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION];
  parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION] = componentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION];
  
  return 0; 
}

/** This funcion parses a string representing xml element
  @param tagName (out) name of the tag
  @param tagValue (out) value of the tag
  @param strComponentFile (in) XML file parsed as a string
  @return 0 if OK, -1 if error
*/  
int fwInstallationXml_getTagFromString(string& tagName, string& tagValue, string& strComponentFile)
{
	int pos1; // contains the position of an opening tag start 
	int pos2; // contains the position of an opening tag end
	int pos3; // contains the position of a closing tag start
	int pos4; // contains the position of a closing tag end

        		
	// get the position of an opening tag start
	pos1 = strpos(strComponentFile, "<");
			
	// get the position of an opening tag end		
	pos2 = strpos(strComponentFile, ">");
	
	//	get the tag name			
	tagName = substr(strComponentFile, pos1 + 1, pos2 - (pos1 + 1));
				
	// get the position of an closing tag start
	pos3 = strpos(strComponentFile, "</" + tagName + ">");
				
	// get the position of an closing tag end
	pos4 = pos3 + strlen("</" + tagName + ">");
				
	// get the tag value
	tagValue = substr(strComponentFile, pos2+1, pos3-(pos2+1));
				
	// remove the bland spaces
  tagValue = strrtrim(strltrim(tagValue));
				
	// remove the tag and the tag value from the string
	strComponentFile = substr(strComponentFile, pos4);
				
				
  if(pos1 >=0)
	{
			return 1;
	}
	else
	{
		// return that the tag was not found ( there are no more tags )	
		return -1;
	}	  
  
  /*
  int success = -1;
  string errMsg;
  int errLine, errColumn;
  int docId = xmlDocumentFromString(strComponentFile, errMsg, errLine, errColumn);
  bool found = false;
  
  if (docId != -1)
  {
    int childId = xmlFirstChild(docId);
    if (childId != -1)
    {
      string currentTag = "";
      dyn_int grandChildrenIds;
      xmlChildNodes(docId, childId, grandChildrenIds);
      for(int i = 1; i <= dynlen(grandChildrenIds); i++)
      {
        currentTag = xmlNodeName(docId, grandChildrenIds[i]);
        if(currentTag == tagName)
        {
          int grandGrandChildId = xmlFirstChild(docId, grandChildrenIds[i]);
          tagValue = xmlNodeValue(docId, grandGrandChildId);
          // these functions return string but according to the help return -1 in case of error, I assume "-1"
          if((tagName == "-1") || (tagValue == "-1"))
          {
            fwInstallation_throw("Failed to read tag " + tagName + " from file " + strComponentFile);
            return -1;
          }
          found = true;
          break; 
        }
      }
    }
    else
    {
      fwInstallation_throw("Failed to read tag " + tagName + " from file " + strComponentFile);
      return -1;
    }
  }
  else
  {
    fwInstallation_throw("Failed to read tag " + tagName + " from file " + strComponentFile + ". Incorrect file contents");
    return -1;
  }

  if(!found)
  {
    fwInstallation_throw("Tag " + tagName + " not found in file " + strComponentFile);
  }  
  
  xmlCloseDocument(docId);
  return 0;  
  */
}
