#uses "fwTrending/fwTrendingTree.ctl"
#uses "classes/fwTrending/FwTrendingTree_PanelDelegateA.ctl"


class FwTrendingTree_PanelDelegatePresent : FwTrendingTree_PanelDelegateA{

    public void showNodeMenu(string itemId, FwTrendingTreeMode mode){
        dyn_string exceptionInfo;
        string parentItemId;
        bool isRoot = (fwTree_isRoot(itemId, exceptionInfo) == 1);
        if(!exceptionInfo.isEmpty()){
            fwExceptionHandling_display(exceptionInfo);
            return;
        }
        if(isRoot){
            parentItemId = itemId;
        }else{
            fwTree_getParent(itemId, parentItemId, exceptionInfo);
            if(!exceptionInfo.isEmpty()){
                fwExceptionHandling_display(exceptionInfo);
                return;
            }
        }
        switch(mode){
            case FwTrendingTreeMode::navigator:
                fwTrendingTree_menuNavigator(itemId, parentItemId);
                break;
            case FwTrendingTreeMode::editor:
                fwTrendingTree_menuEditor(itemId, parentItemId);
                break;
        }
    }

    public void showNodeInfo(string itemId, FwTrendingTreeMode mode){
        fwTrendingTree_showItemInfo(itemId, "");
    }

    public void openTrendManager(){ fwTrendingTree_manageTrendingDevices(getTreeName()); }

    public static void use(){
        FwTrendingTree_PanelDelegateA::setInstance(
                 new FwTrendingTree_PanelDelegatePresent());
    }
};
