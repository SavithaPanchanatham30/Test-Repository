public class GetObjectNameById {
  @invocableMethod(
    label='Get Object by Id'
    category='All'
    description='return object from Id'
  )
  public static List<String> getObjectTypeById(List<String> recordId) {
    String recId = recordId.get(0);
    Id myId = Id.valueOf(recId);
    String sObjName = myId.getSObjectType().getDescribe().getName();
    List<String> results = new List<String>{ sObjName };
    return results;
  }
}