/** @file

*/

#uses "classes/fwStdLib/FwException.ctl"
#uses "classes/fwStdUi/FwPanel.ctl"
#uses "classes/fwStdUi/FwStdUi.ctl"
#uses "classes/fwTree/FwTree.ctl"


struct FwTreeViewItemData {
    // MANDATORY properties
    bool isVisible = true; // if we need to exclude a node from being shown, we set this to false;
    string name;
    string icon;
    string tooltip;
    bool isExpandable;
    bool isEnabled=true;

    // OPTIONAL properties
    bool hasOptionalProperties=false;
    string bgColor;
    string fgColor;
    string font;
};



class FwTreeNodeDelegate;
using FwTreeNodeDelegatePtr = shared_ptr<FwTreeNodeDelegate>;

/** FwTreeNodeDelegate class defines rendering and interactions in the fwTree display panel

*/
class FwTreeNodeDelegate
{

    protected unsigned uiDensity=1; // 0=small/dense , 1=normal, 2=big, 3=large; maybe ENUM one day..

    public void setUiDensity( unsigned density)
    {
      uiDensity=density;
    }

    public unsigned getUiDensity() { return uiDensity;}

    public FwTreeViewItemData getTreeItemData(FwTreeNodePtr tn)
    {
        FwTreeViewItemData data;

        data.name=tn.name;
        data.isExpandable=(!tn._children.isEmpty());

        if (tn.isClipboard()) {
            data.name="Clipboard";
            data.icon="fwStdUi/UI/clipboard.svg";
            //data.isExpandable=false;
        } else if (tn._parent=="") {
            // this is the top node; render it as the system
            data.name=fwSysName(tn._dp);
            data.icon="dptree/system.png";
            string tooltip=tn._dp;
            if (tn._disconnected) tooltip+=" <disconnected>";
            data.tooltip=tooltip;
        } else {
            string tooltip="["+tn.getID()+"]";
            if (tn.type!="") {
                tooltip+=": "+tn.type;
                if (tn.linkedObj!="") tooltip+=" -> "+tn.linkedObj;
            }
            data.tooltip=tooltip;
        }
        if (tn._disconnected) {
            data.icon="disconnected.png";
            data.isExpandable=false;
            data.isEnabled=false;
        }
        return data;
    }

    // you could use @c nodeType to e.g. create trend page/plot nodes, etc.
    // by invoking this handled from your own TreeDelegate
    public static void actionAddNode(FwTreeNodePtr curNode, string nodeType="", string linkedObj="")
    {
        string msg="Enter the name for the new";
        if (nodeType!="") msg+=" "+nodeType;
        if (msg.endsWith("tree") || msg.endsWith("Tree")) msg.chop(4); // do not repeat "tree" in the name.
        msg+=" tree node created under "+curNode.getName();

        string newNodeName = FwStdUi::dialogInputString(msg,"Create tree node","");
        if (newNodeName=="") return; // dialog was cancelled...
        curNode.addChild(newNodeName,nodeType,linkedObj);

        // tell the tree to expand our node so the new node is visible...
        delay(0,100);
        FwPanel myTreeRefPanel=FwPanel(self);
        myTreeRefPanel.invokeMethod("expandNode", makeVector(curNode), false);

    }

    public static void actionReorderChildren(FwTreeNodePtr curNode)
    {
        FwException::assert(curNode.hasChildren(),"The node "+curNode.getName()+" has no children");
        FwTreeNodePVec children=curNode.getChildren(); // we will pass it as reference!
        bool modified=FwStdUi::dialogReorderList("Reorder children of tree node "+curNode.getName(), children,"name","Reorder tree nodes");
        if (!modified) return;
        curNode.reorderChildren(children,"name");
        // tell the tree to expand our node so the new node is visible...
        delay(0,100);
        FwPanel myTreeRefPanel=FwPanel(self);
        //myTreeRefPanel.invokeMethod("expandNode", makeVector(curNode), false);
        myTreeRefPanel.invokeMethod("expandNode", curNode, false);

    }
    public static void actionRenameNode(FwTreeNodePtr curNode)
    {
        string newNodeName = FwStdUi::dialogInputString("Enter new name for node "+curNode.getName(),"Rename tree node",curNode.getName());
        if (newNodeName==curNode.getName()) return; // dialog was cancelled...
        curNode.renameNode(newNodeName);
    }
    public static void actionDeleteNode(FwTreeNodePtr curNode)
    {
        string message = "Do you want to delete the tree node "+curNode.getName();
        string sysName=fwSysName(curNode.getID(),true);
        if (sysName!="" && sysName!=getSystemName()) message+=" in remote system "+sysName;
        if (curNode.hasChildren()) message+=" and its subtree";
        message += "?";
        bool doDelete = FwStdUi::dialogConfirm(message);
        if (doDelete) curNode.removeMe(true);
    }

    public static void actionCutToClipboard(FwTreeNodePtr curNode)
    {
      curNode.move(curNode.getClipboard());
    }

    public static void actionPasteFromClipboard(FwTreeNodePtr curNode)
    {
      FwTreeNodePVec clipboardContent = curNode.getClipboard().getChildren();
      for (int i=0;i<clipboardContent.count();i++) {
        clipboardContent.at(i).move(curNode);
      }
    }

    // MAYBE WE COULD HAVE A HIGHER ABSTRACTION, ie. we pass the allowed list of dpTypes, etc...
    // or somehow make it possible to parameterize this with specific info from the e.g. Trending tree...
    public static void actionSetLinkedObject(FwTreeNodePtr tn, string linkedObject, string type)
    {
      DebugTN(__FUNCTION__,tn._dp,linkedObject,type);
      string message = "Do you want to link the "+type+" "+linkedObject+" to the tree node "+tn.getName()+" ?";
      if (tn.getLinkedObj()!="") {
        DebugTN("CUR LINK",tn.getLinkedObj(),tn.getNodeType());
        message = "Do you want to replace the linked object for tree node "+tn.getName()+" with "+type+" "+linkedObject+"?";
      }
      bool doLink = FwStdUi::dialogConfirm(message);
      if (doLink) tn.setProps(type,linkedObject);
    }

    public static void actionUnlinkObject(FwTreeNodePtr tn)
    {
      if (tn.getLinkedObj()=="" && tn.getNodeType()=="") return;
      if (tn.getLinkedObj()!="") {
        bool doUnlink=FwStdUi::dialogConfirm("Do you want to unlink "+tn.getNodeType()+" "+tn.getLinkedObj()+" from tree node "+tn.getName()+" ?");
        if (!doUnlink) return;
      }
      tn.setProps("","");
    }

    public void handleLeftClick(FwTreeNodePtr tn) {}

    public void handleRightClick(FwTreeNodePtr tn)
    {
        if (equalPtr(tn,nullptr)) return; // clicked on the canvas with no selected tree node
        int notRootNode= ( tn.isRoot() ? 0:1);

        dyn_string menu;
        dynAppend(menu, "PUSH_BUTTON,Add node,1,1");
        dynAppend(menu, "PUSH_BUTTON,Reorder children,2,"+(tn.hasChildren() ? "1": "0"));
        dynAppend(menu, "PUSH_BUTTON,Rename,3,"+notRootNode);
        dynAppend(menu, "PUSH_BUTTON,Delete,4,"+notRootNode);
        dynAppend(menu, "PUSH_BUTTON,Cut,5,"+(notRootNode && !tn.isClipboard()));
        dynAppend(menu, "PUSH_BUTTON,Paste,6,"+(notRootNode && !tn.isClipboard()));
        int answer;
        popupMenu(menu, answer);
        switch (answer) {
            case 0: break; // menu was cancelled
            case 1: actionAddNode(tn); break;
            case 2: actionReorderChildren(tn); break;
            case 3: actionRenameNode(tn); break;
            case 4: actionDeleteNode(tn); break;
            default:DebugTN(__FUNCTION__, "Unhandled option "+answer); break;
        }

        /*
        // this shows how we could invoke the method of our tree and pass
        // some arguments
        FwPanel myTreeRefPanel=FwPanel(self);
        myTreeRefPanel.invokeMethod("createNode", makeVector(tn, "NewTreeNode"), false);
        */

        //     tn.create("new name","FwTrendingPlot2",makeDynString("user","data"));

    }

    public void handleDoubleClick(FwTreeNodePtr tn) {}

    public void handleDrop(FwTreeNodePtr droppedOn, string payload)
    {
      DebugTN(__FUNCTION__, droppedOn._dp, payload);
    }
};

