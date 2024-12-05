@isTest
public class CveClaimTriggerTest {
  @TestSetup
  static void makeData() {
    cve__Claim__c disability = new cve__Claim__c();
    insert disability;

    List<cve__Claim__c> clmList = new List<cve__Claim__c>();
    for (integer i = 0; i < 200; i++) {
      clmList.add(new cve__Claim__c());
    }
    insert clmList;

    cve__Claim__c disability1 = new cve__Claim__c();
    disability1.Autopay__c = true;
    insert disability1;

    // inserting to test event publishing
    cve__PaymentSpecification__c ps = new cve__PaymentSpecification__c(
      cve__Claim__c = disability.Id,
      cve__Amount__c = 800,
      cve__Start__c = Date.newInstance(2015, 1, 1),
      cve__Through__c = Date.newInstance(2015, 3, 30),
      cve__Period__c = 'Monthly',
      cve__AmountPeriod__c = 'Monthly'
    );
    insert ps;

    cve__PaymentSpecification__c ps1 = new cve__PaymentSpecification__c(
      cve__Claim__c = disability.Id,
      cve__Amount__c = 800,
      cve__Start__c = Date.newInstance(2015, 4, 1),
      cve__Through__c = Date.newInstance(2015, 6, 31),
      cve__Period__c = 'Monthly',
      cve__AmountPeriod__c = 'Monthly'
    );
    insert ps1;
  }

  @IsTest
  static void eventPublishing() {
    List<cve__Claim__c> newClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    List<cve__Claim__c> oldClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    Map<Id, cve__Claim__c> oldClaims = getMap(oldClaimsList);
    for (cve__Claim__c clm : newClaimsList) {
      clm.Autopay__c = true;
    }

    Map<Id, cve__Claim__c> newClaims = getMap(newClaimsList);

    Amoss_Instance mockEventPublisher = new Amoss_Instance(
      EventPublisher.class
    );
    mockEventPublisher.byDefaultMethodsReturn(new List<Database.SaveResult>());
    EventPublisher eventPublisherDouble = (EventPublisher) mockEventPublisher.getDouble();

    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      newClaimsList,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaims)
        .withNewMap(newClaims),
      eventPublisherDouble
    );

    Test.startTest();

    testHandler.afterUpdate();

    Test.stopTest();
    List<cve__PaymentSpecification__c> paySpecList = getPaymentSpecification();

    List<RecalculatePayments__e> expectedOutcomeList = new List<RecalculatePayments__e>();

    for (cve__PaymentSpecification__c ps : paySpecList) {
      RecalculatePayments__e expectedOutcome = new RecalculatePayments__e(
        PaymentSpecificationId__c = ps.Id
      );
      expectedOutcomeList.add(expectedOutcome);
    }

    List<RecalculatePayments__e> actualOutcome = (List<RecalculatePayments__e>) mockEventPublisher.call(
        0
      )
      .of('publish')
      .parameter('events');

    Assert.areEqual(
      expectedOutcomeList,
      actualOutcome,
      'Published event does not match the expected RecalculatePayments__e'
    );
  }

  @IsTest
  static void triggerTestOnBulk() {
    List<cve__Claim__c> claims = getClaims();

    for (cve__Claim__c clm : claims) {
      clm.AutoPay__c = true;
    }
    Boolean errorsEncountered = false;
    Test.startTest();
    try {
      update claims;
    } catch (Exception e) {
      errorsEncountered = true;
    }
    Test.StopTest();
    Assert.isFalse(errorsEncountered, 'Exception thrown during trigger');
  }

  @isTest
  static void testAutoPayfalse() {
    List<cve__Claim__c> oldClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    List<cve__Claim__c> claims = getClaims();
    Map<Id, cve__Claim__c> mapClaims = getMap(claims);

    EventPublisher eventp = EventPublisher.getInstance();

    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      claims,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(mapClaims)
        .withNewMap(mapClaims),
      eventp
    );
    Test.startTest();
    testHandler.afterUpdate();
    Test.StopTest();

    List<cve__Claim__c> actualClaims = testHandler.autoPayTrueClaims;

    Assert.areEqual(
      0,
      actualClaims.size(),
      'Getting size of claim list greater than zero '
    );
  }

  @isTest
  static void testAutoPayAlreadyTrue() {
    List<cve__Claim__c> oldClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];

    List<cve__Claim__c> claims = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE AutoPay__c = TRUE
    ];
    Map<Id, cve__Claim__c> mapClaims = getMap(claims);
    EventPublisher eventp = EventPublisher.getInstance();
    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      claims,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(mapClaims)
        .withNewMap(mapClaims),
      eventp
    );
    Test.startTest();
    testHandler.afterUpdate();

    Test.StopTest();
    List<cve__Claim__c> actualClaims = testHandler.autoPayTrueClaims;

    Assert.areEqual(
      0,
      actualClaims.size(),
      'Getting size of disability claim list greater than zero'
    );
  }

  @isTest
  public static void checkRunApprovalAsWithoutClaimBrainIntegration() {
    List<cve__Claim__c> newClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    List<cve__Claim__c> oldClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    Map<Id, cve__Claim__c> oldClaims = getMap(oldClaimsList);
    for (cve__Claim__c clm : newClaimsList) {
      clm.Autopay__c = true;
    }

    Map<Id, cve__Claim__c> newClaims = getMap(newClaimsList);

    EventPublisher eventp = EventPublisher.getInstance();
    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      newClaimsList,
      oldClaimsList, //null,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaims)
        .withNewMap(newClaims),
      eventp
    );
    Test.startTest();
    testHandler.afterUpdate();
    Test.stopTest();

    List<cve__PaymentSpecification__c> psList = getPaymentSpecificationWithUsername();
    Assert.areEqual(2, psList.size(), 'RunApprovalAs__C was not set ');
  }

  @isTest
  public static void checkRunApprovalAsWhenClaimBrainIntegration() {
    List<cve__Claim__c> newClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    List<cve__Claim__c> oldClaimsList = [
      SELECT Id, Autopay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE Autopay__c = FALSE
      LIMIT 1
    ];
    Map<Id, cve__Claim__c> oldClaims = getMap(oldClaimsList);
    for (cve__Claim__c clm : newClaimsList) {
      clm.Autopay__c = true;
    }

    Map<Id, cve__Claim__c> newClaims = getMap(newClaimsList);

    EventPublisher eventp = EventPublisher.getInstance();
    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      newClaimsList,
      oldClaimsList,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaims)
        .withNewMap(newClaims),
      eventp
    );

    updateRunApprovalAs(getPaymentSpecification());

    Test.startTest();
    testHandler.afterUpdate();
    Test.stopTest();

    List<cve__PaymentSpecification__c> psList = getPaymentSpecificationWithoutUsername();
    Assert.areEqual(2, psList.size(), 'RunApprovalAs__C was set ');
  }

  static void updateRunApprovalAs(List<cve__PaymentSpecification__c> psList) {
    for (cve__PaymentSpecification__c ps : psList) {
      ps.RunApprovalAs__c = 'ClaimBrain Integration User';
    }
    update psList;
  }

  static Map<Id, cve__Claim__c> getMap(List<cve__Claim__c> claims) {
    Map<Id, cve__Claim__c> claimMap = new Map<Id, cve__Claim__c>();
    for (cve__Claim__c clm : claims) {
      claimMap.put(clm.Id, clm);
    }
    return claimMap;
  }

  static List<cve__Claim__c> getClaims() {
    return [
      SELECT Id, AutoPay__c, cve__ClaimantInsured__c, cvint__AbsenceClaim__c
      FROM cve__Claim__c
      WHERE AutoPay__c = FALSE
    ];
  }

  static List<cve__PaymentSpecification__c> getPaymentSpecification() {
    return [
      SELECT Id, RunApprovalAs__c
      FROM cve__PaymentSpecification__c
      WHERE cve__Claim__c != NULL
    ];
  }

  static List<cve__PaymentSpecification__c> getPaymentSpecificationWithUsername() {
    return [
      SELECT Id, RunApprovalAs__c
      FROM cve__PaymentSpecification__c
      WHERE
        cve__Claim__c != NULL
        AND RunApprovalAs__c != 'ClaimBrain Integration User'
        AND RunApprovalAs__c != NULL
    ];
  }

  static List<cve__PaymentSpecification__c> getPaymentSpecificationWithoutUsername() {
    return [
      SELECT Id, RunApprovalAs__c
      FROM cve__PaymentSpecification__c
      WHERE
        cve__Claim__c != NULL
        AND RunApprovalAs__c = 'ClaimBrain Integration User'
    ];
  }

  @isTest
  static void claimTATCalculation() {
    cve__Claim__c cveClaim = new cve__Claim__c();
    cveClaim.cve__status__c = 'Open';
    insert cveClaim;

    Case cs = new Case();
    cs.CveClaim__c = cveClaim.Id;
    insert cs;

    cve__Claim__c claim = [
      SELECT
        Id,
        CaseCreatedDate__c,
        StatusChangedDate__c,
        FinalStatusChangedDate__c,
        cve__Status__c
      FROM cve__Claim__c
      WHERE cve__status__c = 'Open'
      LIMIT 1
    ];
    Map<Id, cve__Claim__c> oldClaims = getMap(new List<cve__Claim__c>{ claim });

    cveClaim.cve__status__c = 'Closed';

    Map<Id, cve__Claim__c> newClaims = getMap(
      new List<cve__Claim__c>{ cveClaim }
    );

    Test.startTest();
    CveClaimTriggerHandler testHandler = new CveClaimTriggerHandler(
      null,
      new List<cve__Claim__c>{ cveClaim },
      null,
      CveClaimTriggerHelper.getHelperInstance()
        .withOldMap(oldClaims)
        .withNewMap(newClaims),
      null
    );
    testHandler.beforeUpdate();
    Test.stopTest();

    Case csResult = [SELECT Id, CreatedDate FROM Case LIMIT 1];
    Date caseCreatedDate = Date.newInstance(
      csResult.CreatedDate.year(),
      csResult.CreatedDate.month(),
      csResult.CreatedDate.day()
    );
    Date claimCaseCreatedDate = Date.newInstance(
      cveClaim.CaseCreatedDate__c.year(),
      cveClaim.CaseCreatedDate__c.month(),
      cveClaim.CaseCreatedDate__c.day()
    );

    Assert.areEqual(
      caseCreatedDate,
      claimCaseCreatedDate,
      'Case Created date was not populated correctly'
    );
    Assert.areEqual(
      system.today(),
      cveClaim.StatusChangedDate__c,
      'Status Changed date was not populated correctly'
    );
    Assert.areEqual(
      system.today(),
      cveClaim.FinalStatusChangedDate__c,
      'Final Status Changed date was not populated correctly'
    );
  }
}