public without sharing class CASE_Hierarchy {

    public sObject obj;
    public String objId;
    public String url;    
    public Set<Id> objIdSet;
    public List<CASE_Hierarchy> children;
    
    CASE_Hierarchy(sObject obj){
        this.obj = obj;
        this.objId = obj.ID; 
        this.url = '/'+obj.ID;         
    }
    
    private void addChildren(CASE_Hierarchy child){
        if(children == null){
            children = new List<CASE_Hierarchy>();
        }
        children.add(child);
    }
 
    public static List<Schema.FieldSetMember> getFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
    
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));
    
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);  
        return fieldSetObj.getFields(); 
    } 
    
    @AuraEnabled
    public static String getColumnJSON(String fieldSetName, String objectName, Boolean isConsoleLayout){
        
        List<Schema.FieldSetMember> fieldSetMemberList = getFieldSet(fieldSetName, objectName);
        
        List<Column> columns = new List<Column>();
        Integer i = 0;
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
        {
            //LowerCamelCase - String fieldPath = fieldSetMemberObj.getFieldPath().substring(0, 1).toLowerCase() + fieldSetMemberObj.getFieldPath().substring(1);
            String fieldPath = fieldSetMemberObj.getFieldPath();
            Column c = new Column();
            if(i == 0){
                if(isConsoleLayout){
                    c.type = 'text';
                    c.initialWidth = 220;
                    c.fieldName = fieldPath;
                }else{
                    c.type = 'url';
                    TypeAttributes ta = new TypeAttributes();
                    Label l = new Label();
                    l.fieldName = fieldPath;
                    ta.label = l;
                    c.typeAttributes = ta;
                    c.fieldName = 'url';
                }

            }else if(fieldSetMemberObj.getRequired()){
                if(isConsoleLayout){
                    c.type = 'button'; 
                    c.fieldName = 'objId';
                }else{
                    c.type = 'url';
                    c.fieldName = 'url';
                }
                    TypeAttributes ta = new TypeAttributes();
                    Label l = new Label();
                    l.fieldName = fieldPath;
                    ta.label = l;
                    c.typeAttributes = ta;

            }else{
                c.type = 'text'; 
                c.fieldName = fieldPath;
                                
            }
            
            c.title = fieldPath;
            c.label = fieldSetMemberObj.getLabel();  
            columns.add(c);
            i++;
        }

        String json = JSON.serialize(columns, true);
        system.debug('JSON generated: '+json);
        
        return json;
    }
    

        
    // Add child nodes
    private static void addChildren(List<sObject> objList, Map<Id,CASE_Hierarchy> nodes, Set<Id> parent_obj_ids, Set<Id> objIdSet) {
        
        for (sObject obj : objList) {
            CASE_Hierarchy ref_case = nodes.get((Id)obj.get('ParentId'));
            CASE_Hierarchy new_case = new CASE_Hierarchy(obj);
            
            objIdSet.add(obj.id);
            new_case.objIdSet = objIdSet;
            system.debug('objIdSet: '+objIdSet);
            nodes.put(obj.id, new_case);
            if (ref_case != null) {
                ref_case.addChildren(new_case);                
            }
            if (parent_obj_ids != null) {
                parent_obj_ids.add(obj.id);
            }
        }
    }

    @AuraEnabled
    public static String getHierarchiesQuickById(Id sObjId, String sObjName) {
        System.debug('CASE_Hierarchy.getHierarchiesQuickById(sObjId, sObjName) '+sObjId+','+sObjName);
        
        Set<Id> sObjIdSet = new Set<Id>();
        
        Set<Id> parent_obj_ids = new Set<Id>();
        Id top_obj = getFirstParent(sObjId, sObjName);
        parent_obj_ids.add(top_obj);
        
        Map<Id,CASE_Hierarchy> mapHierarchy = getHierarchiesQuick(parent_obj_ids, sObjIdSet, sObjName);
        
        CASE_Hierarchy hierarchyTree = mapHierarchy.get(top_obj);
        List<CASE_Hierarchy> hierarchyTreeList = new List<CASE_Hierarchy>();
        hierarchyTreeList.add(hierarchyTree);
        
        String json = JSON.serialize(hierarchyTreeList, true);
        json = convertChildrenFormat(json);
        system.debug('json: '+json);
        return json;
        
    }
    
    
    @AuraEnabled
    public static Map<Id,CASE_Hierarchy> getHierarchiesQuick(List<sObject> top_objs, String sObjName) {
        System.debug('CASE_Hierarchy.getHierarchiesQuick(List<sObject>) '+top_objs);
        
        Set<Id> objIdSet = new Set<Id>();
        
        Set<Id> parent_obj_ids = new Set<Id>();
        for (sObject a : top_objs) {
            parent_obj_ids.add(a.Id);
        }
        return getHierarchiesQuick(parent_obj_ids, objIdSet, sObjName);
    }
 
    
    private static String getQuery(String fieldSetName, String sObjName){
        
        List<Schema.FieldSetMember> fieldSetMemberList = getFieldSet(fieldSetName, sObjName);
        
        
        String query = 'SELECT ';
        
        for(Schema.FieldSetMember f : fieldSetMemberList) {
            query += f.getFieldPath() + ', ';
        }
        
        query += 'Id, ParentID, Parent.ParentID, Parent.Parent.ParentID, Parent.Parent.Parent.ParentID FROM '
                    +sObjName
                    +' WHERE (Id IN :parent_obj_ids) OR '
                    +'(ParentId IN :parent_obj_ids) OR '
                    +'(Parent.ParentId IN :parent_obj_ids) OR '
                    +'(Parent.Parent.ParentId IN :parent_obj_ids) OR '
                    +'(Parent.Parent.Parent.ParentId IN :parent_obj_ids)';
        
        return query;
        
    }
    
    
    
    // Get complete account hierarchies, e.g. read all child accounts given
    // a list of top account ids. Read accounts 4 levels at a time to speed
    // up the reading and save valuable SOQL-queries
    public static Map<Id,CASE_Hierarchy> getHierarchiesQuick(Set<Id> top_obj_ids, Set<Id> objIdSet, String sObjName) {
        Map<Id,CASE_Hierarchy> nodes = new Map<Id,CASE_Hierarchy>();
        Set<Id> parent_obj_ids = top_obj_ids;
     
        while (parent_obj_ids.size() > 0) {
            
            List<sObject> subordinate_obj = Database.query(getQuery('CASE_Hierarchy',sObjName));
                 
            List<sObject> level0_accs = new List<sObject>();
            List<sObject> level1_accs = new List<sObject>();
            List<sObject> level2_accs = new List<sObject>();
            List<sObject> level3_accs = new List<sObject>();
            List<sObject> level4_accs = new List<sObject>();
     
            // Split accounts in levels
            for (sObject acc : subordinate_obj) {
                if (acc.get('ParentId') != null) {
                    if (parent_obj_ids.contains((Id)acc.get('ParentId'))) {
                        level1_accs.add(acc);
                    }
                    else if (acc.getSObject('Parent').get('ParentId') != null) {
                        if (parent_obj_ids.contains((Id)acc.getSObject('Parent').get('ParentId'))) {
                            level2_accs.add(acc);
                        }
                        else if (acc.getSObject('Parent').getSObject('Parent').get('ParentId') != null) {
                            if (parent_obj_ids.contains((Id)acc.getSObject('Parent').getSObject('Parent').get('ParentId'))) {
                                level3_accs.add(acc);
                            }
                            else if (acc.getSObject('Parent').getSObject('Parent').getSObject('Parent').get('ParentId') != null) {
                                if (parent_obj_ids.contains((Id)acc.getSObject('Parent').getSObject('Parent').getSObject('Parent').get('ParentId'))) {
                                    level4_accs.add(acc);
                                }
                            }
                        }
                    }
                }else{
                    level0_accs.add(acc);
                }
            }
     
            Set<Id> next_parent_obj_ids = new Set<Id>();
            
            // Add children on all levels found, one level at a time
            addChildren(level0_accs, nodes, null, objIdSet);
            addChildren(level1_accs, nodes, null, objIdSet);
            addChildren(level2_accs, nodes, null, objIdSet);
            addChildren(level3_accs, nodes, null, objIdSet);
            addChildren(level4_accs, nodes, next_parent_obj_ids, objIdSet);
     
            // Use lowest level of account ids for next SOQL query
            parent_obj_ids = next_parent_obj_ids;
        }
        system.debug('NODES: '+nodes);

        return nodes;
    }
    
    
    //Return the First Parent for one Id of some Object 
    public static Id getFirstParent(Id objId, String objName){
        
        String query = 'SELECT Id, ParentID, Parent.ParentID, Parent.Parent.ParentID, Parent.Parent.Parent.ParentID FROM '+objName+' WHERE Id = :objId LIMIT 1';
        sObject result = Database.query(query);
        
        if (result.getSObject('Parent') == null 
            || result.getSObject('Parent').getSObject('Parent') == null 
            || result.getSObject('Parent').getSObject('Parent').getSObject('Parent') == null 
            || result.getSObject('Parent').getSObject('Parent').getSObject('Parent').get('ParentId') == null) {
                
                if (result.getSObject('Parent') != null 
                    && result.getSObject('Parent').getSObject('Parent') != null 
                    && result.getSObject('Parent').getSObject('Parent').get('ParentId') != null) {
                        
                        return (Id)result.getSObject('Parent').getSObject('Parent').get('ParentId');
                        
                }else if (result.getSObject('Parent') != null 
                    && result.getSObject('Parent').get('ParentId') != null) {
                    
                        return (Id)result.getSObject('Parent').get('ParentId');
                        
                }else if (result.get('ParentId') != null) {
                    
                        return (Id)result.get('ParentId');
                    
                }else{
                    //You are the first father
                    return result.ID;
                }         
        }else{
            
            return getFirstParent((Id)result.getSObject('Parent').getSObject('Parent').getSObject('Parent').get('ParentId'), objName);
            
        }
        
    }
    
    private static String convertChildrenFormat(String str){
        return str.replace('"children":', '"_children":');
    }

    public class Column{
        
        String type;
        String fieldName;
        String title;
        String label;
        Integer initialWidth;
        TypeAttributes typeAttributes;
                    
    }
    
    public class TypeAttributes{
        Label label; 
        String name = 'openCase';
        String variant = 'Base';
        String target = 'blank';
    }
    
    public class Label{
        String fieldName;
    }
    
}