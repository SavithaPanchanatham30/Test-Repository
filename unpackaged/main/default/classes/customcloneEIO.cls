public class customcloneEIO{
private Enrollment_Implementation__c l;
public customcloneEIO(apexpages.standardcontroller std){
this.l = (Enrollment_Implementation__c)std.getrecord();
}

public PageReference cloneEIO(){
Enrollment_Implementation__c l1 = new  Enrollment_Implementation__c();
Try {
l1 =l.clone();

insert l1;}
//in case of exception, throw an error
        catch(Exception exc) {
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed Only One EIO Per Case'));
          return Null;
  }
PageReference reRend = new PageReference('/'+ l1.ID);
        reRend.setRedirect(true);
   
        return reRend;
 
}
  
        
        
        }