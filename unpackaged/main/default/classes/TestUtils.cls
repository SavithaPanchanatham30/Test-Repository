@isTest
public class TestUtils {
  public static void killCustomTriggers() {
    CVCustomSwitches__c cvcs = new CVCustomSwitches__c(
      DisableCVCustomTriggers__c = true
    );
    insert cvcs;
  }

  public static List<SObject> flattenNestedList(
    List<List<SObject>> nestedList
  ) {
    List<SObject> objs = new List<SObject>();
    for (List<SObject> objList : nestedList) {
      objs.addAll(objList);
    }

    return objs;
  }

  public static void assignPermissionSetsToUser(
    User u,
    List<String> permissionSetNames
  ) {
    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    List<PermissionSet> permSets = [
      SELECT Id
      FROM PermissionSet
      WHERE Name IN :permissionSetNames
    ];

    List<PermissionSetAssignment> preexistingPSAs = [
      SELECT PermissionSetId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :u.Id AND PermissionSetId IN :permsets
    ];

    List<String> psaIdentifiers = new List<String>();
    for (PermissionSetAssignment psa : preexistingPSAs) {
      psaIdentifiers.add(psa.PermissionSetId);
    }

    for (PermissionSet permset : permsets) {
      if (psaIdentifiers.contains(permset.Id)) {
        continue;
      }

      psas.add(
        new PermissionSetAssignment(
          AssigneeId = u.Id,
          PermissionSetId = permset.Id
        )
      );
    }

    insert psas;
  }

  public static void debugObject(String objTitle, Object obj) {
    String objJson = '>>>>>' + objTitle + ':\n' + JSON.serializePretty(obj);
    System.debug(objJson); // NOPMD : explicitly used for debugging tests

    String breakPointLocationAfterDebugLoop = ''; // NOPMD : explicitly used for debugging tests
  }

  public static void debugLoop(String objsTitle, List<Object> objs) {
    if (objs == null) {
      System.debug('>>>>>' + objsTitle + ' returned null');
    } else {
      for (Integer i = 0; i < objs.size(); i++) {
        String objJson =
          '>>>>>' +
          objsTitle +
          ': Iteration ' +
          i +
          ':\n' +
          JSON.serializePretty(objs[i]);
        System.debug(objJson); // NOPMD : explicitly used for debugging tests
      }

      String breakPointLocationAfterDebugLoop = ''; // NOPMD : explicitly used for debugging tests
    }
  }
}