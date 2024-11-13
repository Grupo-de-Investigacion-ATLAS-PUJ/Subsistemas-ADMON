#uses "classes/fwTree/FwTree.ctl"
#uses "classes/fwTree/FwTree_Repository.ctl"

struct FwTreeNodeImpl: FwTreeNode {

    public void setIsCU(bool bIsCU)             { setIsMaster(bIsCU);}
    public void setDevice(string sDevice)       { setLinkedObj(sDevice); }
    public void setIsMaster(bool bIsMaster)     { this.isMaster  = bIsMaster;   _doSet();}
    public void setNodeType(string sNodeType)   { this.type      = sNodeType;   _doSet();}
    public void setLinkedObj(string sLinkedObj) { this.linkedObj = sLinkedObj;  _doSet();}
    public void setUserData(dyn_string uData)   { this.userData  = uData;       _doSet();}

    public void setProps(string newNodeType, string newLinkedObject, dyn_string newUserData=makeDynString(), bool newIsMaster=false)
    {
        this.type = newNodeType;
        this.linkedObj = newLinkedObject;
        this.userData = newUserData;
        this.isMaster = newIsMaster;
        _doSet();
    }

    public FwTreeNodePtr addChild(string aName, string aType="", string aLinkedObject="", dyn_string aUserData=makeDynString(), bool aIsMaster=false)
    {
        if (aName.contains("---Clipboard")) {  // check if this tree already has a clipbord...
            FwException::assert(equalPtr(getRootNode().getClipboard(),nullptr),"Clipboard already exists in the tree to which the "+this.name+" belongs");
        }
        return _getRepo().create(aName, selfPtr(), aType, aLinkedObject, aUserData, aIsMaster);
    }

    public FwTreeNodePVec getChildren()
    {
        FwTreeNodePVec childNodes;
        for (int i=0; i<_children.count(); i++) {
            string childID=_children.at(i);
            if (childID.contains("fwTN_---Clipboard")) continue;
            if (!childID.contains(":")) childID=fwSysName(_dp, true)+childID;
            FwTreeNodePtr childTN = get(childID);
            if (equalPtr(childTN, nullptr)) {
                DebugTN("WARNING in "+__FUNCTION__, "Cannot find child node "+childID+" for "+this._dp);
                continue;
            } else if (childTN._invalid) {
                DebugTN("Child node is invalid; skipping it", childTN._dp);
                continue;
            } else {
                childNodes.append(childTN);
            }
        }
        return childNodes;
    }

    public FwTreeNodePVec getAllChildren()
    {
        FwTreeNodePVec allChildren = getChildren();
        int direct_children_cnt=allChildren.count(); //we will keep appending beyond this index inside the loop
        for (int i=0; i<direct_children_cnt; i++) {
            FwTreeNodePVec grandChildren=allChildren.at(i).getAllChildren();
            for (int j=0; j<grandChildren.count(); j++) allChildren.append(grandChildren.at(j));
        }
        return allChildren;
    }

    public FwTreeNodePtr getParent()
    {
        if (_parent.isEmpty()) return nullptr;
        string parentID=_parent;
        if (! parentID.contains(":")) parentID=fwSysName(_dp, true)+parentID;
        return get(parentID);
    }

    protected FwTreeNodeImpl(string treeDp, bool checkDpExists=true)
    {
        string dpNoSys=fwNoSysName(treeDp);
        FwException::assert(dpNoSys.startsWith("fwTN_"), "FwTreeNodeImpl constructor: datapoint must start with fwTN_ (got "+treeDp+").");
        if (checkDpExists) {
            FwException::assertDP(treeDp, "_FwTreeNode", "FwTreeNodeImpl constructor: datapoint must exist and be of dptype _FwTreeNode ("+treeDp+")");
        }
        _dp=treeDp; // fwTN_NAME or fwTN_&0001NAME etc
        name = substr(dpNoSys, 5); // cut the leading "fwTN_"
        if (name.startsWith("&")) name=substr(name, 5); // cut the &0001
        _invalid=false;
    }

    public void reorderChildren(FwTreeNodePVec newChildrenList)
    {
        _getRepo().reorderChildren(selfPtr(), newChildrenList);
    }

    public void move(FwTreeNodePtr newParent, FwTreeNodePtr beforeTN=nullptr)
    {
        _getRepo().moveNode(selfPtr(), newParent, beforeTN);
    }

    public static void drop(FwTreeNodePtr tn, bool recursively)
    {
        _getRepo().drop(tn, recursively);
    }

    public void removeMe(bool recursively=false)
    {
        drop(get(_dp), recursively);
    }

    public void triggerModified()
    {
        FwTreeNodePtr tn = FwTree_Repository::getInstance().get(this._dp); // get the shareable instance of ourselves via the repo
        //DebugTN(__FUNCTION__,tn._dp);
        triggerClassEvent(evModified, tn);
    }

    public bool isRoot()
    {
        return _parent.isEmpty();
    }

    public bool hasChildren()
    {
        return _children!="";
    }

    public FwTreeNodePtr getRootNode()
    {
        // we may have different implementations in future,
        // e.g. every node could cache the root tree node ID
        // and resolution is traced...

        return getRootRecursively();
    }

    public FwTreeNodePtr getMasterNode()
    {
        return getMasterRecursively();
    }

    public bool isClipboard()
    {
        return fwNoSysName(_dp).startsWith("fwTN_---Clipboard");
    }

    public FwTreeNodePtr getClipboard()
    {
        FwTreeNodePtr  rootNode=getRootNode();
        dyn_string clipNodeNames=dynPatternMatch("fwTN_---Clipboard*---", rootNode._children);
        dynSort(clipNodeNames);
        if (clipNodeNames.isEmpty()) return nullptr;
        return get(fwSysName(this._dp, true)+clipNodeNames.first());
    }

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

    protected FwTreeNodePtr getRootRecursively(int recursionLevel=0)
    {

        FwTreeNodePtr parent = getParent();
        if (equalPtr(parent, nullptr)) return get(this._dp); // we are the rootNode
        FwException::assert(recursionLevel<30, "Cannot find the tree root node - too deep recusion", this._dp);
        return parent.getRootRecursively(recursionLevel+1);
    }

    protected FwTreeNodePtr getMasterRecursively(int recursionLevel=0)
    {
        if (this.isMaster) return selfPtr();
        FwTreeNodePtr parent = getParent();
        if (equalPtr(parent, nullptr)) return nullptr; // we reached the top of the tree...
        FwException::assert(recursionLevel<30, "Cannot find the tree master node - too deep recusion", this._dp);
        return parent.getMasterRecursively(recursionLevel+1);
    }

    public void renameNode(string newNodeName)
    {
        _getRepo().renameNode(selfPtr(), newNodeName);
    }

};
