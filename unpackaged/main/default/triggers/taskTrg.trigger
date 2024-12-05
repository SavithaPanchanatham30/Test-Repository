/*
Purpose : Task Trigger (Before delete) 
          1)Stops user to delete task if user profile is not system admin
          
Created Date : 2014-03-05
Modified Date: 
Author : Muhammad Asif (Sakonent)
Modify By : 
Version : 1.0

*/

trigger taskTrg on Task (before delete) {
    if(Trigger.isDelete) {
        
        List<Profile> lstProfile = [select Name from profile WHERE Name Like '%Administrator%'  
                                                        AND id = :userinfo.getProfileId() limit 1];         
        for (Task tsk: Trigger.old){
            if (lstProfile.size() == 0){
                tsk.addError('<br/><strong><span style=\'font-size:24px;color:red\'>Only a system administrator can delete task(s). Please contact your system administrator for assistance.</span>');
            } 
        }               
    }
}