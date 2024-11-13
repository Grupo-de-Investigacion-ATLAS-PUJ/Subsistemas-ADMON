#uses "classes/fwTrending/FwTrendingTreeMode.ctl"


class FwTrendingTree_PanelDelegateA{
    static mapping _myInstancesMap;

    protected FwTrendingTree_PanelDelegateA(){}

    // Concrete implementation to be provided in derived class
    public void showNodeMenu(string itemId, FwTrendingTreeMode mode){ return; }

    // Concrete implementation to be provided in derived class
    public void showNodeInfo(string itemId, FwTrendingTreeMode mode){ return; }

    // Concrete implementation to be provided in derived class
    public void openTrendManager(){ return; }

    public string getTreeName(){
        return "TrendTree";
    }

    public static shared_ptr<FwTrendingTree_PanelDelegateA> getInstance(){
        string key = getInstancesMapKey();
        if(!_myInstancesMap.contains(key)){
            //throwError
            return nullptr;
        }
        return _myInstancesMap[key];
    }

    protected static void setInstance(shared_ptr<FwTrendingTree_PanelDelegateA> newInstance){
        release();
        _myInstancesMap[getInstancesMapKey()] = newInstance;
    }

    public static void release(){
        string key = getInstancesMapKey();
        if(_myInstancesMap.contains(key)){
            _myInstancesMap.remove(key);
        }
    }

    static string getInstancesMapKey(string moduleName = myModuleName(),
                                     string panelName = myPanelName()){
        return moduleName + "." + panelName + ":";
    }
};
