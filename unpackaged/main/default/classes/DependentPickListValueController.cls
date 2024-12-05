public class DependentPickListValueController{
    public  DependentPickListValueController(){}
    public  static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        //get the type being dealt with
        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //get the control values   
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        //iterate through the values and get the ones valid for the controlling field name
        PickListUtils.Bitset objBitSet = new PickListUtils.Bitset();
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){            
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<String>());
        }
        //check the dependent values
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){            
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            //get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);                
            PickListUtils.PicklistDetails objDepPLE = (PickListUtils.PicklistDetails)JSON.deserialize(pEntryStructure, PickListUtils.PicklistDetails.class);
            //iterate through the controlling values
            for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){    
                if (objBitSet.fitBit(objDepPLE.validFor,pControllingIndex)){                    
                    //get the label
                    String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                    objResults.get(pControllingLabel).add(objDepPLE.label);
                }
            }
        } 
        return objResults;
    }
}