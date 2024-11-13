/** @file
*/

#uses "classes/fwStdLib/FwException.ctl"
#uses "classes/fwTree/FwTree.ctl"


/** Interface class for FwTree Repository

    The class defines the interfaces for methods and provides
    the mechanism to obtain an instance of the class that implements
    this interface (using reflection functions from CtrlOOUtils).
*/
class FwTree_Repository
{
    protected static shared_ptr<FwTree_Repository> _theInstance=nullptr;

    protected FwTree_Repository() { } // restrict!

#event evTreeNodesModified(FwTreeNodePVec modifiedNodes) // alternatively, each FwTreeNode could also be connected to
#event evTreeNodeDeleted(FwTreeNodePtr deletedNode)
#event evTreeNodeRenamed(FwTreeNodePtr tn, string oldTnId)
#event evDistChanged(string sysName, bool connected)

    public static shared_ptr<FwTree_Repository> getInstance()
    {
        if (equalPtr(_theInstance, nullptr)) {
            fwGeneral_loadCtrlLib("classes/fwTree/FwTree_RepositoryImpl.ctl", true, true);
            _theInstance = fwCreateInstance("FwTree_RepositoryImpl");
            fwInvokeMethod(_theInstance, "FwTree_RepositoryImpl"); // invoke the constructor.
            fwInvokeMethod(_theInstance,"initialize");
        }
        return _theInstance;
    }

    /** Utility: get all DPs matching a node name

        @param name the name of the node to be looked up; may be prefixed with the system name and colon,
                in which case this takes precedence over the @c sysName parameter
        @param sysName specifies the system name in which to find the node;
                - empty string (default) means the current system
                - "*" means all connected systems
     */
    public dyn_string getMatchingDPs(string name, string sysName="")  { return makeDynString();}

    /** Create a new node
     */
    public FwTreeNodePtr create(string name, FwTreeNodePtr parent, string type="", string linkedObject="", dyn_string userData=makeDynString(), bool isMaster=false) { return nullptr;}

    /** Delete the new node
     */
    public void drop(FwTreeNodePtr tn, bool recursively=false) {}

    /** Initializes the repository (starts caching of values, connect to change notifications, etc)
    */
    public void initialize() {}

    /** get an instance of FwTreeNode for a particular id (FwTreeNode datapoint)
     */
    public FwTreeNodePtr get(string treeNodeDP) {return nullptr;}

    /** Find FwTreeNode instances by the value of their member

      */
    public FwTreeNodePVec findBy(string memberName, mixed value, ...) {return makeVector();}

    /** Prints the cached entries (IDs) to the log

      @par full if set then the content of cached items is printed, otherwise only
           the cache keys.
      */
    public void showCache(bool full=true) {}

    /** Clear the cache and reinitialize

     */
    public void reset() {}

    public void reorderChildren(FwTreeNodePtr parent, FwTreeNodePVec children) {}
    public void moveNode(FwTreeNodePtr tn, FwTreeNodePtr newParent, FwTreeNodePtr beforeTN=nullptr) {}

    public void renameNode(FwTreeNodePtr tn, string newNodeName) {}

    public void setFromObject(FwTreeNodePtr tn) {}

    public FwTreeNodePtr createRootNode(string name) { return nullptr;}
    public FwTreeNodePtr createDetachedNode(string name) { return nullptr;}
};



