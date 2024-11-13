/** @file FwTree.ctl
    Object-Oriented API for the JCOP Framework Tree.

    The library delivers the implementation of the FwTreeNode class which
    provides the API to access and manipulate the JCOP Framework Tree information,
    and forms an alternative to the original function-based interface provided by
    the @ref fwTree.ctl library.

    The two libraries operate on the same underlying data stored in the datapoints
    of type _FwTreeNode; they are fully independent and could be used simultaneously.

    For more information please refer to the description provided by the manual
    of the FwTree component.
*/

#uses "classes/fwStdLib/FwException.ctl"

struct FwTreeNode;
using  FwTreeNodePtr = shared_ptr<FwTreeNode>; ///< shareable instances of FwTreeNode
using  FwTreeNodePVec = vector<FwTreeNodePtr> ; ///< vector of sharable instances of fwTreeNode

/**
    @todo consider better functions to search for nodes, something like
        public static FwTreeNodePtr findNode(string nodeName, bool excOnNoUniqueFound=true)
        public static FwTreeNodePVecfind(string nodeName, string treeType, string sysName="", bool excOnNotFound=false)
    For completeness: we already have the ::get(string treeNodeDP) and FwTree_Repository::findBy(string memberName, mixed value, ...)

    @todo: consider implementing the method to clone a node or subtree:
        public FwTreeNodePtr clone(string newName="", bool recursiveClone=true)

    @todo: consider a method that could create a complete path
    @todo: consider a method that returns the path to the node
 */


/** FwTreeNode is the public, object-oriented interface to access the JCOP Framework Tree data.

  It models a node in the tree, with identifiers, pointers to parent and child nodes
  (which define the actual dynamic tree structure) as well as attached properties
  (such as node type, attached object, user data, etc).

  The instances of the class may not be instantiated directly using the constructor, but rather
  through one of the "factory" methods: ref FwTreeNode::get or FwTreeNode::create.
  This is to guarantee that the API is used with "shareable" instances (shared_ptr<FwTreeNode>),
  which is essential for proper modelling of references to parent and child nodes, and functioning
  of the event-based notification system.
  For code clarity and convenience, the following type-aliases are also declared (with the `using` keyword)
  and used systematically in the API:
    - @ref FwTreeNodePtr - equivalent to @c shared_ptr<FwTreeNode>
    - @ref FwTreeNodePVec - equivalent to @c vector<FwTreeNodePtr>
    .
  It is recommended to employ these standard type-aliases when using the FwTreeNode API.

  The identity of each tree node is determined by its unique "ID" (accessible via getID(),
  or getDP() methods), which stores the name of the datapoint which persists the tree node.

  Certain properties of a tree node reflect its origins in the "FSM" component of the JCOP Framework,
  notably the notion of being a "master" (or "CU"), having an attached object (also called a "device")
  and user data.

  At the technical level, the FwTreeNode class defines the complete public interface which is abstract.
  The implementation is provided by internal classes: FwTreeNodeImpl, FwTree_Repository and
  FwTree_RepositoryImpl. The user is not supposed to ever refer to these internal classes directly:
  they are loaded and instantiated as needed to implement the functionality.
  In particular, the instances of shared_ptr<FwTreeNode> being actually manipulated are of type
  shared_ptr<FwTreeNodeImpl> (FwTreeNodeImpl is derived from the FwTreeNode "interface" class).
  The separation of the "interface" and "implementation" classes allows to properly resolve the
  challenges related to circular dependency between the classes, addressing also the use case
  of the classes being parsed for syntax-highlighting in the GEDI script editor.
  The implementation of the methods of FwTreeNode is therefore dummy, and actual implementation
  is provided by the FwTreeNodeImpl class derived from it.

  FwTreeNode has been implemented as a @c struct rather than a @c class,
  with all the members directly accessible for flexibility of its integration
  with the tree display panel (objects/fwTree/fwTree.pnl). However, to guarantee
  future compatibility as for convenience it is strongly recommended NOT to use
  the member variables directly but rather the dedicated "getter" and "setter" methods.

  The FwTreeNode objects are "live-connected" to the underlying datapoints in WinCC OA,
  and react to the changes in both: the data included in the elements as well as to
  the changes in instances (ie. datapoints being created/deleted, tree nodes being renamed).
  The underlying caching mechanism is implemented by the FwTree_DpObserver internal class,
  which should not ever be manipulated directly.
  The caching mechanism observes all connected dist systems and provisions instances of
  shared_ptr<FwTreeNode> referring to them. It reacts to connection/disconnection of systems,
  creating new instances or setting the _disconnected data member accordingly (and notifying
  about this fact using the event described below).

  FwTreeNode defines the @c evModified event which could be subscribed to if one wants to
  get asynchronous notifications about any change in the instance; separate subscription per
  every instance should be established using the `classConnect()` or `classConnectUserData()`
  functions.


  Some of the functionality that the user may be interested in is implemented in the
  @ref FwTree_Repository class, notably the notification about dist system connections,
  availability of new nodes, renames, etc. There are believed to be of rather rare use,
  unless one would like to implement a custom tree display panel.

  The rendering and interactions offered by the standard reference panel object,
  `objects/fwTree/fwTree.pnl` is customizable using the "tree delegate" classes.
  An instance of such class, derived from the @ref FwTreeNodeDelegate , may be
  passed to the above reference object using the `setTreeItemDelegate` method of
  the reference object panel instance. Please, refer to the documentation of the
  @ref FwTreeNodeDelegate class for more information.

  @nosubgrouping

  */
struct FwTreeNode {


    string _dp;           // unique ID - the DP name
    string name;          // readable, non-unique, generated from DP name
    dyn_string _children; // .children
    string _parent;       // .parent
    bool isMaster;        // .cu
    string linkedObj;     // .device
    string type;          // .type
    dyn_string userData;  // .userdata
    bool _disconnected=true; // internal, set to false once data connection is valid, reset to true e.g. if dist system disconnects
    bool _invalid=true;    // internal, used to maintain object/datapoint lifetime; set to true if the object is invalid (should not be used)


     /// @name Events
     /// FwTreeNode objects emit the following class events which could be subscribed to:
     /// @{

    /// @fn FwTreeNode::evModified(shared_ptr<FwTreeNode> tn)
    #event evModified(shared_ptr<FwTreeNode> tn)

    /// @}

    ///@name Getters and Setters
    /// The following methods allow to access and manipulate the member variables
    /// (properties) of the FwTreeNode objects
    ///@{

    /** Returns the ID (datapoint) of the tree node; @sa getDP()  @ingroup gettersSetters */
    public string     getID()          { return _dp;}

    /** Returns the datapoint (ID) corresponding to the tree node; @sa getID() */
    public string     getDP()           { return _dp;}
    public string     getName()         { return name;}
    public bool       getIsMaster()     { return isMaster;}
    public bool       getIsCU()         { return isMaster;}
    public string     getNodeType()     { return type;}
    public string     getLinkedObj()    { return linkedObj;}
    public string     getDevice()       { return linkedObj;}
    public dyn_string getUserData()     { return userData;}
    public bool       getInvalid()      { return _invalid;}
    public bool       getDisconnected() { return _disconnected;}

    /** Returns the properties of the tree node into the parameters passed in the call

          @param[out] aNodeType      - will contain the node type
          @param[out] aLinkedObject  - will contain the linkedObject information
          @param[out] aIsMaster      - will contain the isMaster (or isCU) information
          @param[out] aUserData      - will contain the userData
      */
    public void       getProps(string &aNodeType, string &aLinkedObject, bool &aIsMaster, dyn_string &aUserData)
    {
        aNodeType=aNodeType; aLinkedObject=linkedObj; aIsMaster=isMaster; aUserData=userData;
    }

    ///@}


    /// @name Factories
    /// @{
    /** Get the shared-pointer (FwTreeNodePtr) of this object
      */
    public FwTreeNodePtr selfPtr() { return get(_dp);} // get a shared pointer to ourselves

    /// @}



    /// @name Getters and Setters
    /// @{
    public void setIsCU(bool bIsCU)             { setIsMaster(bIsCU);}
    public void setDevice(string sDevice)       { setLinkedObj(sDevice); }
    public void setIsMaster(bool bIsMaster)     { this.isMaster  = bIsMaster;   _doSet();}

    public void setNodeType(string sNodeType)   { this.type      = sNodeType;   _doSet();}
    public void setLinkedObj(string sLinkedObj) { this.linkedObj = sLinkedObj;  _doSet();}
    public void setUserData(dyn_string uData)   { this.userData  = uData;       _doSet();}

    /** Sets the properties of the tree node

        The new values will be set immediately in the object and also persisted in the datapoint

      @param[in] newNodeType     - the new value for the node type property
      @param[in] newLinkedObject - the new value for the linkedObject property
      @param[in] newUserData     - the new value for the userData property; for convenience this
                                      parameter is optional with default value of empty dyn_string
      @param[in] newIsMaster     - the new value for the isMaster (isCU) property; for convenience this
                                      parameter is optional with default value of false
      */
    public void setProps(string newNodeType, string newLinkedObject, dyn_string newUserData=makeDynString(), bool newIsMaster=false) {}
    /// @}

    /// @name Hierarchy modification
    /// @{
    /** Create a new tree node as a child of this node

      The new node is created with ID which is generated following the internal convention and corresponding
        to the name specified in the @c aName parameter, hence the tree display will present the name as
        specified, while a unique ID will be generated.
        The current node will be modified immediately to have the new node set as a child, and the information
        will be persisted in the datapoint (for this object having a new child, and for the newly created tree node).

      @returns the FwTreeNodePtr object corresponding to the new node.
      @throws an exception on invalid node name

      @param[in] aName          - the name of the new node
      @param[in] aType          - the node type; for convenience this is an optional parameter with
                                    default value set to empty string
      @param[in] aLinkedObject  - the value for the linked object property; for convenience this is an optional parameter with
                                    default value set to empty string
      @param[in] aUserData      - the value for the user data property; for convenience this is an optional parameter with
                                    default value set to empty dyn_string
      @param[in] aIsMaster      - the value for the isMaster property; for convenience this is an optional parameter with
                                    default value set to false
      */
    public FwTreeNodePtr addChild(string aName, string aType="", string aLinkedObject="", dyn_string aUserData=makeDynString(), bool aIsMaster=false) {return nullptr;}

    ///@}

    // INTERNAL: get the pointer to the repository object
    // this one is tricky from the point of view of circular dependencies,
    // because at this point the FwTree_Repository class is not yet known
    // (only through its forward declaration).
    protected static mixed _getRepo()
    {
        if (!fwClassExists("FwTree_Repository")) fwGeneral_loadCtrlLib("classes/fwTree/FwTree_Repository.ctl",true,true);
        mixed repo=callFunction(fwGetFuncPtr("FwTree_Repository::getInstance"));
        return repo;
    }

    // INTERNAL: triggers the setting to the DP via the repo and fires all the classConnect'ed events
    protected void _doSet() { evModified(selfPtr()); _getRepo().setFromObject(selfPtr());}


    /// @name Factories
    /// @{

    /** Retrieves the FwTreeNodePtr object for a tree node with given ID

      @param[in] treeNodeID - specifies the ID (ie. datapoint name) for the tree node;
                                  note that the ID starts with "fwTN_" and may be prefixed
                                  with the system name
      @returns the tree node that was found
      @throws exception if a tree node with the specified treeNodeID does not exist or may
                  not be accessed (e.g. dist system not yet connected)
      */
    public static FwTreeNodePtr get(string treeNodeID)
    {
        // We need to work around the circular dependency with the FwTree_Repository
        // because it is a static method
        mixed repo=_getRepo();
        return repo.get(treeNodeID);
    }

    /** Create a new tree node with aribitrary parent node

        This is a static method, ie. it could be used without any instance of FwTreeNode.

        The new node is created with ID which is generated following the internal convention and corresponding
        to the name specified in the @c aName parameter, hence the tree display will present the name as
        specified, while a unique ID will be generated.

        The parent node specified in @c theParent must exist, and it will be modified immediately to have the
        new node set as a child, and the information will be persisted in the datapoints
        (for the parent having a new child, and for the newly created tree node).

        Note that it is not possible to create a root node of a tree using this function (design decision).
        One should use the dedicated method FwTree_Repository::createRootNode instead

      @returns the FwTreeNodePtr object corresponding to the new node.
      @throws an exception on invalid node name or non-existing/invalid parent, or if multiple clipboard creation is requested

      @param[in] aName          - the name of the new node
      @param[in,out] theParent  - the parent node; its list of children will be modified to contain the new node at the end
      @param[in] aType          - the node type; for convenience this is an optional parameter with
                                    default value set to empty string
      @param[in] aLinkedObject  - the value for the linked object property; for convenience this is an optional parameter with
                                    default value set to empty string
      @param[in] aUserData      - the value for the user data property; for convenience this is an optional parameter with
                                    default value set to empty dyn_string
      @param[in] aIsMaster      - the value for the isMaster property; for convenience this is an optional parameter with
                                    default value set to false

      */
    public static FwTreeNodePtr create(string aName, FwTreeNodePtr theParent, string aType="", string aLinkedObject="", dyn_string aUserData=makeDynString(), bool aIsMaster=false)
    {
        if (aName.contains("---Clipboard")) {  // check if this tree already has a clipbord...
            FwException::assert(!equalPtr(theParent,nullptr),"Cannot create a clipboard node as a root node");
            FwException::assert(equalPtr(theParent.getRootNode().getClipboard(),nullptr),"Clipboard already exists in the tree to which the "+this.name+" belongs");
        }

        // We need to work around the circular dependency with the FwTree_Repository
        // because it is a static method
        mixed repo=_getRepo();
        return repo.create(aName, theParent, aType, aLinkedObject, aUserData, aIsMaster);
    }

    /// @}

    /// @name Tree navigation
    /// @{

    /** Get the list of children tree nodes.

      If the invoking object corresponds to the tree node on a remote dist system, the function
      takes care of retrieving the FwTreeNodePtr corresponding for this system (even though the
      datapoint does not have them prefixed with the system name).
      It also skips the clipboard node, which may be obtained via the @ref FwTreeNode::getClipboard
      or FwTreeNode::getClipboardForTreeType methods.

      @sa FwTreeNode::getAllChildren()

      @returns the vector containing FwTreeNodePtr objects being direct children of this node;
                  the vector is empty if the node has no children.
     */
    public FwTreeNodePVec getChildren()
    {
        FwTreeNodePVec childNodes;
        return childNodes;
    }

    /** Get list of all direct and non-direct children (recursively).

      @sa FwTreeNode::getChildren()
      */
    public FwTreeNodePVec getAllChildren()
    {
        FwTreeNodePVec allChildren;
        return allChildren;
    }

    /**
      Returns the parent tree node.

      @returns the FwTreeNodePtr to the parent, or a nullptr if this is a root node
    */
    public FwTreeNodePtr getParent() { return nullptr; }

    /// @}

    /// @name Factories
    /// @{

    /** Constructor is restricted. Use the factory methods to get the instances.
    */
    protected FwTreeNode() {}

    /// @}

    /// @name Hierarchy modification
    /// @{
    /** Change the order of children

      The new list of children must contain all and only the current children

      @exception Exception is thrown if the new list of children does not contain all the
                  tree nodes of the current children list, or contains new ones

      @param[in,out] newChildrenList - the list of children in the order they should be set

    */
    public void reorderChildren(FwTreeNodePVec newChildrenList) {}

    /** Move this node to another place in the tree

      The data in all affected nodes (this one, the new parent, and all the direct
        child nodes will be modified immediately and persisted in their datapoints.

      @throws Exception if the new parent is invalid

      @param[in,out] newParent - the new parent tree node
      @param[in] beforeTN - specifies the place at which it will be inserted in
                    the list of children of the new parent. It will be inserted
                    in the place before the specified node.
                    Specifying nullptr (default) means that it will be appended
                    at the end of the children list

      */
    public void move(FwTreeNodePtr newParent, FwTreeNodePtr beforeTN=nullptr) {}

    /** Drops the specified tree node

          This is a static method that could be called without an instance of FwTreeNode.

          After the call to the function the specified FwTreeNodePtr object becomes invalid
          and should never be used.

          @throws Exception if specified tree node does not exist
          @throws Exception if the specified node has children and @c recursively not set to true

          @param[in,out] tn      - the tree node to be dropped.
          @param[in] recursively - should be set to true if the subtree starting at @c tn should
                          be recursively dropped
      */
    public static void drop(FwTreeNodePtr tn, bool recursively) {}

    /** Drops this tree node.

          After the call the object becomes invalid: all references to it
          must not be used anymore.

          @throws Exception if this node has children and @c recursively not set to true

          @param[in] recursively - should be set to true if the subtree starting at @c tn should
                          be recursively dropped (optional parameter, by default set to false)

    */
    public void removeMe(bool recursively=false) { drop(get(_dp), recursively);}

    ///@}


    // Trigger the event passing this object's shared_ptr as parameter. INTERNAL
    public void triggerModified() {}

    /// @name Getters and Setters
    /// @{

    public bool isRoot() { return false;}
    public bool hasChildren() { return false;}
    public bool isClipboard() { return false;}

    /// @}

    /// @name Tree navigation
    /// @{

    /** Get the root node of the tree to which this node belongs.

        Traverses the list of parents in search of the top node
          (ie one that has no parent).

        @returns FwTreeNodePtr of the root node.
            Returns self pointer if this is already the root node
      */
    public FwTreeNodePtr getRootNode() { return nullptr; }

    /** Get the master node of this node

        Returns the closest parent that is flagged as a master (or CU).

          Note that the function may return a nullptr if there is
          no master up to the root node of this tree

      */
    public FwTreeNodePtr getMasterNode() {return nullptr;}

    // returns the clipboard for the tree to which this
    // node belongs
    /** Get the clipboard node

      Returns the FwTreeNodePtr for the clipboard node that
      belongs to the same tree as this node

      @returns the clipboard node; may be nullptr if this tree has
          no clipboard node
      */
    public FwTreeNodePtr getClipboard() {return nullptr;}

    /** returns the clipboard FwTreeNode for a particular tree type

        This is a static method that does not need an instance of FwTreeNode to be invoked.

        The root node corresponding to the @c treeType is located,
          then its clipboard node is returned.

        @param treeType - the type of the tree; may be prefixed by
               the system name (with the colon)

     */
    public static FwTreeNodePtr getClipboardForTree(string treeType)
    {
        string sysName;
        if (treeType.contains(":")) {
            sysName=fwSysName(treeType, true);
            treeType = fwNoSysName(treeType);
        }
        if (sysName.isEmpty()) sysName=getSystemName();
        return get(sysName+"fwTN_---Clipboard"+treeType+"---");
    }

    /// @}

    /// @name Hierarchy modification
    /// @{
    /** Change the name of this tree node

      The FwTreeNodePtr of this object is modified immediately
      to reflect the changes (and the caching mechanism updated,
      so that eg. the FwTreeNode::get() works as expected), and then
      the change is persisted in the datapoint (though a combination
      of dpCreate/dpDelete with some extra notification) so that other
      managers making use of the FwTreeNode become aware of the change

      @throws Exception when the new node name is invalid.

      */
    public void renameNode(string newNodeName) {}
    /// @}

    /// @name Utilities
    /// @{

    /** Prints this node to log in a compact form
      */
    public void ls()
    {
        string s;
        sprintf(s, "=> %s (%s) TYPE=[:%s]", this._dp, this.name, this.type);
        if (this._invalid) s+= " #INVALID# ";
        if (this._invalid) s+= " #DISCONNECTED# ";
        s+= "  OBJ=["+this.linkedObj+"]";
        if (isMaster) s+=" MASTER ";
        s+= "\n      PARENT  :("+_parent+")";
        s+= "\n      CHILDREN:("+ strjoin(this._children, ",")+")";
        s+= "\n      DATA:    ("+strjoin(userData, ",")+")";
        DebugTN(s);
    }

    /** Prints the specified vector of FwTreeNodePtr to the log in a compact form

      This is a static method that does not need an instance of FwTreeNode to be invoked.

      @param[in] tnVec        - the vector of FwTreeNodePtr objects to be printed
      @param[in] fullPrintout - if set to false (default) then only the list of tree node
                                  IDs will be printed, otherwise the compact printout of
                                  complete information will be done (using FwTreeNode::ls)
      */
    public static void printVector(FwTreeNodePVec tnVec, bool fullPrintout=false)
    {
        DebugTN(__FUNCTION__+":");
        for (int i=0; i<tnVec.count(); i++) {
            if (fullPrintout) tnVec.at(i).ls();
            else DebugTN(" ["+i+"] => "+tnVec.at(i)._dp);
        }
    }
    /// @}
};
