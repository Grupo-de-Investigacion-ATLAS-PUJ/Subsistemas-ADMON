#uses "CtrlOOUtils"
#uses "classes/fwStdLib/FwException.ctl"
#uses "classes/fwStdUi/FwPanel.ctl"

class FwStdUi
{

    public static bool dialogConfirm(string msg, string header="")
    {
        if (header=="") header="Please confirm";
        return FwPanel::openDialogReturnBool(
                   "Confirm", "fwStdUi/dlgConfirm.pnl",
                   makeDynString("$text:"+msg, "$yesButton:Confirm", "$noButton:Cancel", "$header:"+header)
               );
    }

    // returns true if modified and @c theList contains the modified list
    public static bool dialogReorderList(string msg, vector<void> &theList, string memberToDisplay="", string header="")
    {

        shared_ptr<void> returnDataPtr= new mixed;
        shared_ptr<FwPanel> dlgPnl=FwPanel::openChildPanel(
                                       "Reorder items", "fwStdUi/dlgReorderList.pnl",
                                       myModuleName(),
                                       makeDynString("$header:"+header, "$text:"+msg));

        dlgPnl.invokeMethod("setTargetDataPtr", returnDataPtr);
        dlgPnl.invokeMethod("setData", makeVector(theList, memberToDisplay));
        bool ok=dlgPnl.waitPanelReturn();

        if (ok) {
            // unfortunately direct assignment of vectors does not work here, even though the elements do match,
            // hence we assign manually (apparently limitation of vector<void>...)
            // TO REFACTOR: implement CtrlOO function to do the assignment (and also to dig into the types wrapped in shared_ptr/mixed,
            // and maybe "extracting" a target var from a mixed or shared_ptr );
            //  also consider reporting to ETM
            // ideally, the setData() should not return a separate returnDataPtr, but rather everything could be
            // done with shared_ptr (this requires digging in types nested in mixed/shared_pre

            // create the vector of the same type as input, and empty it...
            anytype returnData=theList;
            returnData.clear();
            // then assign element-by-element
            for (int i=0; i<returnDataPtr.count(); i++) returnData.append(returnDataPtr.at(i));

            theList=returnData;
        }
        return ok;
    }

    // if cancelled returns the unmodified string
    public static string dialogInputString(string msg, string header="", string curValue="")
    {
        string newValue=FwPanel::openDialogReturnText(
                            "Enter Value", "fwStdUi/dlgStringInput.pnl",
                            makeDynString("$text:"+msg, "$header:"+header, "$value:"+curValue)
                        );
        return newValue;
    }

    /** Pops up a selection list

      @par itemList - could be one of
        - dyn_string - on return the selected string is returned
        - mapping - with keys/values - the list displays the values of the mapping and returns the selected key
        - vector<obj> - requires the @c memberKey and @c memberToDisplay to be defined; returns the (copy of) the selected object
        - vector<shared_ptr<obj>> - as above, returns the actual shared_ptr to the selected object.

        Note that the key should be of type that could be asigned from/to string and must be unique within the itemList

      */
    public static mixed dialogSelectItem(mixed itemList, string msg, string header="", string memberKey="",string memberToDisplay="", string curItem="")
    {
       dyn_string ds;
       mixed m=ds;
       string itemListType = getTypeName(itemList);
       if (itemListType=="dyn_string" || itemListType=="mapping") {
         // just ok
       } else if (itemListType.startsWith("vector< shared_ptr<")) {
         itemListType="vector<objectPtr>";
       } else if (itemListType.startsWith("vector<")) {
         itemListType="vector<object>";
       } else {
         FwException::raise("Unsupported itemList type: "+itemListType);
       }
       shared_ptr<FwPanel> dlgPnl=FwPanel::openChildPanel("Select item","fwStdUi/dlgSelectionList.pnl",
                                                           myModuleName(),
                                                           makeDynString("$header:"+header,"$text:"+msg));
       dlgPnl.invokeMethod("setData",makeDynMixed(itemListType,itemList,memberKey,memberToDisplay),FALSE);
       delay(0,500);// let it settle... otherwise the table is not yet initialized...
       dlgPnl.invokeMethod("setSelectedKey",curItem);
       string selectedItem=dlgPnl.waitPanelReturnString();

       mixed retVal;
       if (itemListType=="dyn_string" || itemListType=="mapping") {
         retVal = selectedItem;
       } else if (itemListType=="vector<objectPtr>") {
         // initialize retval with null result - assign first object to set the type, then reset to the nullptr
         anytype noValue=itemList.first();
         assignPtr(noValue,nullptr);
         retVal=noValue;
         if (selectedItem!="") {
           vector<int> foundItems = itemList.indexListOf(memberKey,selectedItem);
           if (!foundItems.isEmpty()) assignPtr(retVal,itemList.at(foundItems.first()));
         }
       } else if (itemListType=="vector<object>") {
         retVal = fwCreateInstance(fwGetClass(itemList.first()));
         if (selectedItem!="") {
           vector<int> foundItems = itemList.indexListOf(memberKey,selectedItem);
           if (!foundItems.isEmpty()) retVal=itemList.at(foundItems.first());
         }
       }
       return retVal;
    }

    // due to a bug we need to have at least one non-static method declared
    // otherwise syntax-hinting and parsing fail...
    public void dummy() {}


};
