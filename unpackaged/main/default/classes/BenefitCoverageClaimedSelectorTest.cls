@isTest
public class BenefitCoverageClaimedSelectorTest {
  @TestSetup
  static void makeData() {
    Test.startTest();

    User u = [
      SELECT id, name, email
      FROM User
      WHERE id = :UserInfo.getUserId()
    ];

    System.runAs(u) {
      // we don't need any of the other classes' logic here, just "do our calls
      // return the records we expect?"
      TestUtils.killCustomTriggers();
    }

    Account acc = (Account) new TestAccountBuilder().buildAndInsert();
    SObject grp = new TestGroupBuilder()
      .withMasterGroupId(acc.Id)
      .buildAndInsert();

    cve__Product__c product = new cve__Product__c(
      Name = 'testProduct',
      cve__Status__c = 'Active',
      cve__Effective__c = Date.newInstance(2010, 1, 1)
    );
    insert product;

    cve__Policy__c policyA = new TestPolicy(product)
      .withName('Test Policy A')
      .build();
    cve__Policy__c policyB = new TestPolicy(product)
      .withName('Test Policy B')
      .build();
    List<cve__Policy__c> policyList = new List<cve__Policy__c>{
      policyA,
      policyB
    };
    insert policyList;

    cve__Benefit__c benefitA1 = new TestBenefit(product).withName('A1').build();
    cve__Benefit__c benefitA2 = new TestBenefit(product).withName('A2').build();
    cve__Benefit__c benefitB1 = new TestBenefit(product).withName('B1').build();
    cve__Benefit__c benefitB2 = new TestBenefit(product).withName('B2').build();
    List<cve__Benefit__c> benefitList = new List<cve__Benefit__c>{
      benefitA1,
      benefitA2,
      benefitB1,
      benefitB2
    };
    insert benefitList;

    cve__Coverage__c coverageA1a = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitA1)
      .withName('A1a')
      .build();
    cve__Coverage__c coverageA1b = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitA1)
      .withName('A1b')
      .build();
    cve__Coverage__c coverageB1a = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitB1)
      .withName('B1a')
      .build();
    cve__Coverage__c coverageB1b = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitB1)
      .withName('B1b')
      .build();
    cve__Coverage__c coverageA2a = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitA2)
      .withName('A2a')
      .build();
    cve__Coverage__c coverageA2b = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitA2)
      .withName('A2b')
      .build();
    cve__Coverage__c coverageB2a = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitB2)
      .withName('B2a')
      .build();
    cve__Coverage__c coverageB2b = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitB2)
      .withName('B2b')
      .build();
    List<cve__Coverage__c> coverages = new List<cve__Coverage__c>{
      coverageA1a,
      coverageA1b,
      coverageA2a,
      coverageA2b,
      coverageB1a,
      coverageB1b,
      coverageB2a,
      coverageB2b
    };
    insert coverages;

    Contact conA1 = new TestContact(acc, grp).withIdentifier('A1').build();
    Contact conB1 = new TestContact(acc, grp).withIdentifier('B1').build();
    Contact conA2 = new TestContact(acc, grp).withIdentifier('A2').build();
    Contact conB2 = new TestContact(acc, grp).withIdentifier('B2').build();
    Contact conA = new TestContact(acc, grp).withIdentifier('A').build();
    Contact conB = new TestContact(acc, grp).withIdentifier('B').build();
    Contact con1 = new TestContact(acc, grp)
      .withIdentifier('Contact 1')
      .build();
    Contact con2 = new TestContact(acc, grp)
      .withIdentifier('Contact 2')
      .build();
    Contact conAD = new TestContact(acc, grp).withIdentifier('AD').build();
    Contact conBD = new TestContact(acc, grp).withIdentifier('BD').build();
    List<Contact> contacts = new List<Contact>{
      conA1,
      conB1,
      conA2,
      conB2,
      conA,
      conB,
      con1,
      con2,
      conAD,
      conBD
    };
    insert contacts;

    List<TestEnrollment> enrollments = new List<TestEnrollment>();
    enrollments.add(
      new TestEnrollment(conA1)
        .withBenefit(benefitA1)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conB1)
        .withBenefit(benefitB1)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conA2)
        .withBenefit(benefitA2)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conB2)
        .withBenefit(benefitB2)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conA)
        .withBenefit(benefitA1)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conA)
        .withBenefit(benefitA2)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conB)
        .withBenefit(benefitB1)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conB)
        .withBenefit(benefitB2)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(con1)
        .withBenefit(benefitA1)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(con1)
        .withBenefit(benefitB1)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(con2)
        .withBenefit(benefitA2)
        .withPolicy(policyA)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(con2)
        .withBenefit(benefitB2)
        .withPolicy(policyB)
        .withPolicyRelationshipType('PolicyHolder')
    );
    enrollments.add(
      new TestEnrollment(conAD)
        .withBenefit(benefitA1)
        .withPolicy(policyA)
        .withPolicyRelationshipType('Dependent')
    );
    enrollments.add(
      new TestEnrollment(conBD)
        .withBenefit(benefitB1)
        .withPolicy(policyB)
        .withPolicyRelationshipType('Dependent')
    );
    TestEnrollment.insertEnrollments(enrollments);

    List<cve__PolicyRelationship__c> policyRelationships = [
      SELECT Id
      FROM cve__PolicyRelationship__c
      WHERE cve__Contact__c = :conA1.Id AND cve__Policy__c = :policyA.Id
      LIMIT 1
    ];

    Test.stopTest();
  }

  @isTest
  static void getPreexistingCoveragesClaimed_returns_only_expected_coveragesClaimed() {
    Contact conA1 = getContactByIdentifier('A1');
    Contact conA = getContactByIdentifier('Contact A');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Benefit__c benefitA2 = getBenefitByIdentifier('A2');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    cve__Coverage__c coverageA1b = getCoverageByIdentifier('A1b');
    cve__Coverage__c coverageA2a = getCoverageByIdentifier('A2a');

    Claim claim1 = new Claim()
      .withContact(conA1)
      .withPolicy(policyA)
      .withBenefit(benefitA1)
      .withCoverages(new List<cve__Coverage__c>{ coverageA1a });

    Claim claim2 = new Claim()
      .withContact(conA)
      .withPolicy(policyA)
      .withBenefit(benefitA1)
      .withCoverages(new List<cve__Coverage__c>{ coverageA1a, coverageA1b });

    Claim claim2a = new Claim()
      .withContact(conA)
      .withPolicy(policyA)
      .withBenefit(benefitA1)
      .withCoverages(new List<cve__Coverage__c>{ coverageA1b });

    Claim claim3 = new Claim()
      .withContact(conA)
      .withPolicy(policyA)
      .withBenefit(benefitA2)
      .withCoverages(new List<cve__Coverage__c>{ coverageA2a });

    insertClaimsWithCoveragesClaimed(
      new List<Claim>{ claim1, claim2, claim2a, claim3 }
    );

    Claim newClaimA1b = new Claim()
      .withContact(conA)
      .withPolicy(policyA)
      .withBenefit(benefitA1)
      .withCoverages(new List<cve__Coverage__c>{ coverageA1b });

    Claim newClaimA2a = new Claim()
      .withContact(conA)
      .withPolicy(policyA)
      .withBenefit(benefitA2)
      .withCoverages(new List<cve__Coverage__c>{ coverageA2a });

    List<cve__CoverageClaimed__c> coveragesClaimed = getCoveragesClaimed(
      Claim.insertClaims(new List<Claim>{ newClaimA1b, newClaimA2a })
    );

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, List<cve__CoverageClaimed__c>> ccMap = selector.getPreexistingCoveragesClaimed(
      coveragesClaimed
    );
    List<cve__CoverageClaimed__c> preexistingCoverages = (List<cve__CoverageClaimed__c>) TestUtils.flattenNestedList(
      ccMap.values()
    );

    Test.stopTest();

    for (cve__CoverageClaimed__c cc : preexistingCoverages) {
      Assert.areNotEqual(
        conA1.Id,
        cc.cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        'Returned preexisting CoverageClaimed for a Policyholder without a new CoverageClaimed'
      );

      Assert.areEqual(
        conA.Id,
        cc.cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        'CoveragesClaimed for an unexpected Policyholder were returned'
      );

      Assert.areEqual(
        4,
        ccMap.get(newClaimA1b.coveragesClaimed[0]).size(),
        'Unexpected number of pre-existing claims found for ConA, ContactId ' +
        conA.Id
      );

      Assert.areEqual(
        8,
        preexistingCoverages.size(),
        'Unexpected number of Preexisting CoveragesClaimed found'
      );
    }
  }

  @isTest
  static void getBenefitsCoveragesClaimed_returns_expected_records() {
    Contact conB1 = getContactByIdentifier('B1');
    Contact conB = getContactByIdentifier('Contact B');
    Contact con2 = getContactByIdentifier('Contact 2');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Policy__c policyB = getPolicyByIdentifier('B');
    cve__Benefit__c benefitA2 = getBenefitByIdentifier('A2');
    cve__Benefit__c benefitB1 = getBenefitByIdentifier('B1');
    cve__Benefit__c benefitB2 = getBenefitByIdentifier('B2');
    cve__Coverage__c coverageA2b = getCoverageByIdentifier('A2b');
    cve__Coverage__c coverageB1a = getCoverageByIdentifier('B1a');
    cve__Coverage__c coverageB1b = getCoverageByIdentifier('B1b');
    cve__Coverage__c coverageB2a = getCoverageByIdentifier('B2a');

    Claim claim0 = new Claim()
      .withContact(con2)
      .withPolicy(policyA)
      .withBenefit(benefitA2)
      .withCoverages(new List<cve__Coverage__c>{ coverageA2b });

    Claim claim1 = new Claim()
      .withContact(conB1)
      .withPolicy(policyB)
      .withBenefit(benefitB1)
      .withCoverages(new List<cve__Coverage__c>{ coverageB1a, coverageB1b });

    Claim claim2 = new Claim()
      .withContact(conB)
      .withPolicy(policyB)
      .withBenefit(benefitB1)
      .withCoverages(new List<cve__Coverage__c>{ coverageB1b });

    Claim claim3 = new Claim()
      .withContact(conB)
      .withPolicy(policyB)
      .withBenefit(benefitB2)
      .withCoverages(new List<cve__Coverage__c>{ coverageB2a });

    List<cve__CoverageClaimed__c> coveragesClaimed = getCoveragesClaimed(
      insertClaimsWithCoveragesClaimed(new List<Claim>{ claim0, claim1 })
    );

    insertClaimsWithCoveragesClaimed(new List<Claim>{ claim2, claim3 });

    List<cve__BenefitClaimed__c> bcsToQuery = new List<cve__BenefitClaimed__c>();
    for (cve__CoverageClaimed__c cc : coveragesClaimed) {
      bcsToQuery.add(
        new cve__BenefitClaimed__c(Id = cc.cve__BenefitClaimed__c)
      );
    }

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<Id, cve__BenefitClaimed__c> returnedBenefitsClaimed = selector.getBenefitsCoveragesClaimed(
      bcsToQuery
    );

    Test.stopTest();

    Assert.areEqual(
      2,
      returnedBenefitsClaimed.size(),
      'Unexpected number of BenefitsClaimed returned'
    );
    Assert.isTrue(
      returnedBenefitsClaimed.containsKey(claim0.bc.Id),
      'Expected to find Benefit Claimed Id ' +
        claim0.bc.Id +
        'among returnedBenefitsClaimed, but did not'
    );
    Assert.isTrue(
      returnedBenefitsClaimed.containsKey(claim1.bc.Id),
      'Expected to find Benefit Claimed Id ' +
        claim1.bc.Id +
        'among returnedBenefitsClaimed, but did not'
    );
    Assert.areEqual(
      1,
      returnedBenefitsClaimed.get(claim0.bc.Id).cve__CoveragesClaimed__r.size(),
      'Unexpected number of coveragesClaimed found on BenefitClaimed Id ' +
      claim0.bc.Id
    );
    Assert.areEqual(
      2,
      returnedBenefitsClaimed.get(claim1.bc.Id).cve__CoveragesClaimed__r.size(),
      'Unexpected number of coveragesClaimed found on BenefitClaimed Id ' +
      claim1.bc.Id
    );
    Assert.areEqual(
      con2.Id,
      returnedBenefitsClaimed.get(claim0.bc.Id)
        .cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
      'Did not find expected ContactId for Policyholder for BenefitClaimed Id + claim0.bc.Id'
    );
    Assert.areEqual(
      conB1.Id,
      returnedBenefitsClaimed.get(claim1.bc.Id)
        .cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
      'Did not find expected ContactId for Policyholder for BenefitClaimed Id + claim1.bc.Id'
    );
  }

  @isTest
  static void getMemberBenefits_selects_correct_mb() {
    Contact conA1 = getContactByIdentifier('A1');
    Contact conA = getContactByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Benefit__c benefitA2 = getBenefitByIdentifier('A2');
    cve__Policy__c policyA = getPolicyByIdentifier('A');

    List<usal__MemberBenefit__c> memberBenefits = [
      SELECT Id, usal__ContactId__c, usal__BenefitId__c
      FROM usal__MemberBenefit__c
      WHERE
        (usal__ContactId__c = :conA1.Id
        AND usal__BenefitId__c = :benefitA1.Id)
        OR (usal__ContactId__c = :conA.Id
        AND usal__BenefitId__c = :benefitA2.Id)
    ];

    Date startDate1 = Date.newInstance(2021, 1, 1);
    Date endDate1 = Date.newInstance(2021, 12, 31);
    Date startDate2 = Date.newInstance(2022, 1, 1);
    Date endDate2 = Date.newInstance(2022, 12, 31);

    List<usal__MemberBenefit__c> upsertMBs = new List<usal__MemberBenefit__c>();

    for (usal__MemberBenefit__c mb : memberBenefits) {
      mb.usal__StartDate__c = startDate1;
      mb.usal__EndDate__c = endDate1;
      upsertMBs.add(mb);
      upsertMBs.add(
        new usal__MemberBenefit__c(
          usal__ContactId__c = mb.usal__ContactId__c,
          usal__BenefitId__c = mb.usal__BenefitId__c,
          usal__StartDate__c = startDate2,
          usal__EndDate__c = endDate2
        )
      );
    }
    upsert upsertMBs;

    Claim claim1 = new Claim()
      .withBenefit(benefitA1)
      .withPolicy(policyA)
      .withContact(conA1);
    Claim claim2 = new Claim()
      .withBenefit(benefitA1)
      .withPolicy(policyA)
      .withContact(conA1);
    Claim claim3 = new Claim()
      .withBenefit(benefitA2)
      .withPolicy(policyA)
      .withContact(conA);

    Claim.insertClaims(new List<Claim>{ claim1, claim2, claim3 });

    claim1.bc.cve__DateOfDisability__c = Date.newInstance(2022, 6, 1);
    claim2.bc.cve__DateOfDisability__c = Date.newInstance(2021, 6, 1);
    claim3.bc.cve__DateOfDisability__c = Date.newInstance(2021, 6, 1);

    cve__BenefitClaimed__c bc1 = claim1.bc;
    cve__BenefitClaimed__c bc2 = claim2.bc;
    cve__BenefitClaimed__c bc3 = claim3.bc;
    List<cve__BenefitClaimed__c> bcs = new List<cve__BenefitClaimed__c>{
      bc1,
      bc2,
      bc3
    };

    Id stdBenefitClaimedRecordType = cve__BenefitClaimed__c.getSObjectType()
      .getDescribe()
      .getRecordTypeInfosByDeveloperName()
      .get('ShortTermDisability')
      .getRecordTypeId();

    for (cve__BenefitClaimed__c bc : bcs) {
      bc.IncurredDate__c = null;
      bc.RecordTypeId = stdBenefitClaimedRecordType;
    }
    update bcs;

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<Id, usal__MemberBenefit__c> actualResults = selector.getMemberBenefits(
      bcs
    );

    Test.stopTest();

    List<usal__MemberBenefit__c> expectedMb1 = [
      SELECT
        Id,
        usal__ContactId__r.LastName,
        usal__BenefitId__r.Name,
        usal__ContactId__c,
        usal__BenefitId__c,
        usal__StartDate__c,
        usal__EndDate__c
      FROM usal__MemberBenefit__c
      WHERE
        usal__EndDate__c = :endDate2
        AND usal__BenefitId__c = :benefitA1.Id
        AND usal__ContactId__c = :conA1.Id
    ];
    List<usal__MemberBenefit__c> expectedMb2 = [
      SELECT
        Id,
        usal__ContactId__r.LastName,
        usal__BenefitId__r.Name,
        usal__ContactId__c,
        usal__BenefitId__c,
        usal__StartDate__c,
        usal__EndDate__c
      FROM usal__MemberBenefit__c
      WHERE
        usal__EndDate__c = :endDate1
        AND usal__BenefitId__c = :benefitA1.Id
        AND usal__ContactId__c = :conA1.Id
    ];
    List<usal__MemberBenefit__c> expectedMb3 = [
      SELECT
        Id,
        usal__ContactId__r.LastName,
        usal__BenefitId__r.Name,
        usal__ContactId__c,
        usal__BenefitId__c,
        usal__StartDate__c,
        usal__EndDate__c
      FROM usal__MemberBenefit__c
      WHERE
        usal__EndDate__c = :endDate1
        AND usal__BenefitId__c = :benefitA2.Id
        AND usal__ContactId__c = :conA.Id
    ];

    Assert.areEqual(
      1,
      expectedMb1.size(),
      'Unexpected number of matching MemberBenefits found'
    );

    Assert.areEqual(
      1,
      expectedMb2.size(),
      'Unexpected number of matching MemberBenefits found'
    );

    Assert.areEqual(
      1,
      expectedMb3.size(),
      'Unexpected number of matching MemberBenefits found'
    );

    Assert.areEqual(
      expectedMb1[0].Id,
      actualResults.get(bc1.Id).Id,
      'Unexpected MemberBenefit found mapped to BenefitClaimed'
    );

    Assert.areEqual(
      expectedMb2[0].Id,
      actualResults.get(bc2.Id).Id,
      'Unexpected MemberBenefit found mapped to BenefitClaimed'
    );

    Assert.areEqual(
      expectedMb3[0].Id,
      actualResults.get(bc3.Id).Id,
      'Unexpected MemberBenefit found mapped to BenefitClaimed'
    );
  }

  @isTest
  static void getCoverageLimitations_returns_expected_results() {
    Contact conA1 = getContactByIdentifier('A1');
    Contact conA2 = getContactByIdentifier('A2');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Benefit__c benefitA2 = getBenefitByIdentifier('A2');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    cve__Coverage__c coverageA1b = getCoverageByIdentifier('A1b');
    cve__Coverage__c coverageA2a = getCoverageByIdentifier('A2a');

    Claim claim1 = new Claim()
      .withContact(conA1)
      .withBenefit(benefitA1)
      .withPolicy(policyA)
      .withCoverages(new List<cve__Coverage__c>{ coverageA1a, coverageA1b });
    Claim claim2 = new Claim()
      .withContact(conA2)
      .withBenefit(benefitA2)
      .withPolicy(policyA)
      .withCoverages(new List<cve__Coverage__c>{ coverageA2a });
    List<Claim> claims = insertClaimsWithCoveragesClaimed(
      new List<Claim>{ claim1, claim2 }
    );

    usal__CoverageLimitation__c limitationA1bi = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1b.Id
    );
    usal__CoverageLimitation__c limitationA1bii = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1b.Id
    );
    usal__CoverageLimitation__c limitationA2ai = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA2a.Id
    );
    insert new List<usal__CoverageLimitation__c>{
      limitationA1bi,
      limitationA1bii,
      limitationA2ai
    };

    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>();
    for (Claim claim : claims) {
      coveragesClaimed.addAll(claim.coveragesClaimed);
    }

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, List<usal__CoverageLimitation__c>> limitationsMap = selector.getCoverageLimitations(
      coveragesClaimed
    );

    Test.stopTest();

    List<usal__CoverageLimitation__c> coverageLimitations = TestUtils.flattenNestedList(
      limitationsMap.values()
    );

    Assert.areEqual(
      3,
      coverageLimitations.size(),
      'Unexpected number of CoverageLimitations returned'
    );

    for (cve__CoverageClaimed__c cc : claim1.coveragesClaimed) {
      Integer limitationsCount = limitationsMap?.get(cc)?.size();
      Assert.isTrue(
        limitationsCount == null || limitationsCount == 2,
        'Unexpected number of CoverageLimitations found for a CoverageClaimed on Claim1'
      );

      if (limitationsCount == 2) {
        for (usal__CoverageLimitation__c cl : limitationsMap.get(cc)) {
          Assert.isTrue(
            cl.Id == limitationA1bi.Id || cl.Id == limitationA1bii.Id,
            'Unexpected CoverageLimitation(s) found on Claim1'
          );
        }
      }
    }

    Assert.areEqual(
      1,
      limitationsMap.get(claim2.coveragesClaimed[0]).size(),
      'Unexpected number of CoverageLimitations found for Claim2'
    );

    Assert.areEqual(
      limitationA2ai.Id,
      limitationsMap.get(claim2.coveragesClaimed[0])[0].Id,
      'Unexpected CoverageLimiation found on Claim2'
    );
  }

  @isTest
  static void filter_on_scope_calendaryear() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    Date startDate = Date.newInstance(2024, 1, 1);
    Date priorYearDate = Date.newInstance(2023, 12, 31);

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Calendar Year'
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    claim1.coveragesClaimed[0].cve__Start__c = startDate;
    claim2.coveragesClaimed[0].cve__Start__c = priorYearDate;
    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>{
      claim1.coveragesClaimed[0],
      claim2.coveragesClaimed[0]
    };
    update coveragesClaimed;

    Claim claim3 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    newCoverageClaimed.cve__Start__c = Date.newInstance(2024, 1, 2);
    update newCoverageClaimed;

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        startDate,
        ccList[0].cve__Start__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  @isTest
  static void filter_on_scope_policyyear() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    Date startDate = Date.newInstance(2024, 3, 2);
    Date priorYearDate = Date.newInstance(2023, 2, 29);

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Policy Year'
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(startDate + 15)
      }
    )[0];

    cve__CoverageClaimed__c cc1 = claim1.coveragesClaimed[0];
    cc1.cve__Start__c = startDate + 15;
    update cc1;

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(priorYearDate)
      }
    )[0];

    cve__CoverageClaimed__c cc2 = claim2.coveragesClaimed[0];
    cc2.cve__Start__c = priorYearDate;
    update cc2;

    policyA.cve__Effective__c = Date.newInstance(2023, 3, 1);
    update policyA;

    Claim claim3 = insertClaims(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(Date.newInstance(2024, 2, 15))
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    newCoverageClaimed.cve__Start__c = Date.newInstance(2024, 2, 15);
    upsert newCoverageClaimed;
    newCoverageClaimed = getCoverageClaimed(newCoverageClaimed.id);

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        priorYearDate,
        ccList[0].cve__Start__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  @isTest
  static void filter_on_scope_accidentdate() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    Date matchingDate = Date.newInstance(2024, 1, 1);
    Date nonMatchingDate = Date.newInstance(2023, 12, 31);

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Accident Date'
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(matchingDate)
      }
    )[0];

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(nonMatchingDate)
      }
    )[0];

    claim1.coveragesClaimed[0].cve__Start__c = matchingDate;
    claim2.coveragesClaimed[0].cve__Start__c = nonMatchingDate;
    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>{
      claim1.coveragesClaimed[0],
      claim2.coveragesClaimed[0]
    };
    update coveragesClaimed;

    Claim claim3 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(matchingDate)
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    newCoverageClaimed.cve__Start__c = matchingDate;
    update newCoverageClaimed;

    newCoverageClaimed = getCoverageClaimed(newCoverageClaimed.id);
    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        matchingDate,
        ccList[0].cve__Start__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  @isTest
  static void filter_on_scope_policy() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    Date matchingDate = Date.newInstance(2024, 1, 1);
    Date nonMatchingDate = Date.newInstance(2023, 12, 31);

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Policy'
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    claim1.coveragesClaimed[0].cve__Start__c = matchingDate;
    claim2.coveragesClaimed[0].cve__Start__c = nonMatchingDate;
    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>{
      claim1.coveragesClaimed[0],
      claim2.coveragesClaimed[0]
    };
    update coveragesClaimed;

    Claim claim3 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    update newCoverageClaimed;

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        2,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );
    }
  }

  @isTest
  static void filter_on_scope_claimant() {
    Contact conA1 = getContactByIdentifier('A1');
    Contact conAD = getContactByIdentifier('AD');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Claimant'
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conAD)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withRelationshipType('Dependent')
      }
    )[0];

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    List<cve__PolicyRelationship__c> policyRelationships = [
      SELECT Id
      FROM cve__PolicyRelationship__c
      WHERE cve__Contact__c = :conA1.Id AND cve__Policy__c = :policyA.Id
      LIMIT 1
    ];

    claim1.cveClaim.cve__PolicyRelationship__c = policyRelationships[0].Id;

    update claim1.cveClaim;

    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>{
      claim1.coveragesClaimed[0],
      claim2.coveragesClaimed[0]
    };
    update coveragesClaimed;

    Claim claim3 = insertClaims(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    upsert newCoverageClaimed;
    System.debug('newCoverageClaimed :- ' + newCoverageClaimed);
    System.debug('claim :- ' + claim3);

    newCoverageClaimed = getCoverageClaimed(newCoverageClaimed.id);
    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        claim2.bc.Id,
        ccList[0].cve__BenefitClaimed__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  @isTest
  static void filter_on_scope_period() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    Date matchingDate = Date.newInstance(2024, 2, 1);

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1a.Id,
      usal__Scopes__c = 'Per Period (Days)',
      usal__PeriodLengthDays__c = 30
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(matchingDate - 10)
      }
    )[0];

    cve__CoverageClaimed__c cc1 = claim1.coveragesClaimed[0];
    cc1.cve__Start__c = matchingDate - 10;
    update cc1;

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(matchingDate - 45)
      }
    )[0];

    cve__CoverageClaimed__c cc2 = claim2.coveragesClaimed[0];
    cc2.cve__Start__c = matchingDate - 45;
    update cc2;

    Claim claim3 = insertClaims(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
          .withBCDates(matchingDate)
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];
    newCoverageClaimed.cve__Start__c = matchingDate;
    upsert newCoverageClaimed;
    newCoverageClaimed = getCoverageClaimed(newCoverageClaimed.id);

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        matchingDate - 10,
        ccList[0].cve__Start__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  @isTest
  static void filter_by_category() {
    Contact conA1 = getContactByIdentifier('A1');
    cve__Policy__c policyA = getPolicyByIdentifier('A');
    cve__Benefit__c benefitA1 = getBenefitByIdentifier('A1');
    cve__Coverage__c coverageA1a = getCoverageByIdentifier('A1a');
    cve__Coverage__c coverageA1b = getCoverageByIdentifier('A1b');
    cve__Coverage__c coverageA1c = (cve__Coverage__c) new TestCoverageBuilder()
      .withBenefit(benefitA1)
      .withName('A1c')
      .build();
    String categoryA = 'Ambulance';
    String categoryB = 'Burns';
    coverageA1a.cve__Category__c = categoryA;
    coverageA1b.cve__Category__c = categoryB;
    coverageA1c.cve__Category__c = categoryA;
    upsert new List<cve__Coverage__c>{ coverageA1a, coverageA1b, coverageA1c };

    usal__CoverageLimitation__c cl = new usal__CoverageLimitation__c(
      usal__Coverage__c = coverageA1c.Id,
      usal__ByCategory__c = true
    );
    insert cl;

    Claim claim1 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1a })
      }
    )[0];

    Claim claim2 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1b })
      }
    )[0];

    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>{
      claim1.coveragesClaimed[0],
      claim2.coveragesClaimed[0]
    };
    update coveragesClaimed;

    Claim claim3 = insertClaimsWithCoveragesClaimed(
      new List<Claim>{
        new Claim()
          .withBenefit(benefitA1)
          .withContact(conA1)
          .withPolicy(policyA)
          .withCoverages(new List<cve__Coverage__c>{ coverageA1c })
      }
    )[0];

    cve__CoverageClaimed__c newCoverageClaimed = claim3.coveragesClaimed[0];

    Test.startTest();

    BenefitCoverageClaimedSelector selector = BenefitCoverageClaimedSelector.getInstance();
    Map<cve__CoverageClaimed__c, Map<usal__CoverageLimitation__c, List<cve__CoverageClaimed__c>>> filteredMap = selector.filterCoveragesClaimedByCoverageLimitations(
      new List<cve__CoverageClaimed__c>{ newCoverageClaimed }
    );

    Test.stopTest();

    Assert.areEqual(
      1,
      filteredMap.size(),
      'Unexpected number of CoverageLimitations returned'
    );
    for (
      List<cve__CoverageClaimed__c> ccList : filteredMap.get(newCoverageClaimed)
        .values()
    ) {
      Assert.areEqual(
        1,
        ccList.size(),
        'Unexpected number of CoveragesClaimed returned'
      );

      Assert.areEqual(
        categoryA,
        ccList[0].cve__Coverage__r.cve__Category__c,
        'Found unexpected Preexisting CoverageClaimed'
      );
    }
  }

  static Contact getContactByIdentifier(String identifier) {
    String likeIdentifier = '% ' + identifier;
    return [SELECT Id FROM Contact WHERE LastName LIKE :likeIdentifier LIMIT 1];
  }

  static cve__Benefit__c getBenefitByIdentifier(String identifier) {
    String likeIdentifier = '% ' + identifier;
    return [
      SELECT Id
      FROM cve__Benefit__c
      WHERE Name LIKE :likeIdentifier
      LIMIT 1
    ];
  }

  static cve__Policy__c getPolicyByIdentifier(String identifier) {
    String likeIdentifier = '% ' + identifier;
    return [
      SELECT Id
      FROM cve__Policy__c
      WHERE Name LIKE :likeIdentifier
      LIMIT 1
    ];
  }

  static cve__Coverage__c getCoverageByIdentifier(String identifier) {
    return [
      SELECT Id
      FROM cve__Coverage__c
      WHERE Name = :identifier
      LIMIT 1
    ];
  }

  static List<Claim> insertClaims(List<Claim> claims) {
    List<cve__Claim__c> cveClaims = new List<cve__Claim__c>();
    List<cve__BenefitClaimed__c> bcs = new List<cve__BenefitClaimed__c>();

    for (Claim claim : claims) {
      claim.cveClaim = (cve__Claim__c) new TestClaimBuilder()
        .withPolicyRelationship(claim.policy, claim.con, claim.relationshipType)
        .withClaimantInsured(claim.con)
        .build();
      cveClaims.add(claim.cveClaim);
    }
    insert cveClaims;

    Integer month = 0;
    for (Claim claim : claims) {
      month += 1;
      claim.bc = (cve__BenefitClaimed__c) new TestBenefitClaimedBuilder()
        .withClaim(claim.cveClaim)
        .withDates(claim.disabilityIncurredDate)
        .withStatus('Approved')
        .withRecordTypeDeveloperName('CriticalIllness')
        .withBenefit(claim.benefit)
        .build();
      bcs.add(claim.bc);
    }
    insert bcs;

    for (Claim claim : claims) {
      if (claim.coverages == null || claim.coverages.isEmpty()) {
        continue;
      }

      for (cve__Coverage__c coverage : claim.coverages) {
        if (claim.coveragesClaimed == null) {
          claim.coveragesClaimed = new List<cve__CoverageClaimed__c>();
        }

        claim.coveragesClaimed.add(
          (cve__CoverageClaimed__c) new TestCoverageClaimedBuilder()
            .withCoverage(coverage)
            .withBenefitClaimed(claim.bc)
            .withStartDate(claim.bc.IncurredDate__c)
            .withAmountFields(100)
            .build()
        );
      }
    }

    return claims;
  }

  static List<Claim> insertClaimsWithCoveragesClaimed(List<Claim> claims) {
    List<Claim> insertedClaims = insertClaims(claims);
    List<cve__CoverageClaimed__c> coveragesClaimed = new List<cve__CoverageClaimed__c>();

    for (Claim insertedClaim : insertedClaims) {
      coveragesClaimed.addAll(insertedClaim.coveragesClaimed);
    }

    insert coveragesClaimed;

    return insertedClaims;
  }

  static List<cve__CoverageClaimed__c> getCoveragesClaimed(
    List<BenefitCoverageClaimedSelectorTest.Claim> claims
  ) {
    List<cve__CoverageClaimed__c> ccs = new List<cve__CoverageClaimed__c>();

    for (Claim claim : claims) {
      ccs.addAll(claim.coveragesClaimed);
    }

    return ccs;
  }

  class Claim {
    Contact con;
    cve__Policy__c policy;
    cve__Claim__c cveClaim;
    cve__Benefit__c benefit;
    cve__BenefitClaimed__c bc;
    List<cve__Coverage__c> coverages;
    List<cve__CoverageClaimed__c> coveragesClaimed;
    String relationshipType;
    Date disabilityIncurredDate;

    public cve__BenefitClaimed__c getBenefitClaimed() {
      return bc;
    }

    public Claim withContact(Contact con) {
      this.con = con;
      return this;
    }

    public Claim withPolicy(cve__Policy__c policy) {
      this.policy = policy;
      return this;
    }

    public Claim withRelationshipType(String relationshipType) {
      this.relationshipType = relationshipType;
      return this;
    }

    public Claim withBenefit(cve__Benefit__c benefit) {
      this.benefit = benefit;
      return this;
    }

    public Claim withCoverages(List<cve__Coverage__c> coverages) {
      this.coverages = coverages;
      return this;
    }

    public Claim withBCDates(Date disabilityIncurredDate) {
      this.disabilityIncurredDate = disabilityIncurredDate;
      return this;
    }
  }

  class TestPolicy {
    cve__Policy__c policy;
    cve__Product__c product;

    public TestPolicy(cve__Product__c product) {
      this.product = product;
      this.policy = new cve__Policy__c(
        cve__Effective__c = Date.newInstance(2010, 1, 1),
        cve__Status__c = 'Active',
        cve__Product__c = this.product.Id,
        cve__Version__c = '1'
      );
    }

    public TestPolicy withName(String name) {
      policy.Name = name;
      return this;
    }

    public TestPolicy withProduct(cve__Product__c product) {
      policy.cve__Product__c = product.Id;
      return this;
    }

    public cve__Policy__c build() {
      return policy;
    }
  }

  class TestBenefit {
    cve__Benefit__c benefit;
    cve__Product__c product;

    public TestBenefit(cve__Product__c product) {
      Schema.RecordTypeInfo criticalIllnessBenefitRecordType = cve__Benefit__c.getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('CriticalIllness');

      this.product = product;
      this.benefit = new cve__Benefit__c(
        RecordTypeId = criticalIllnessBenefitRecordType.getRecordTypeId(),
        cve__Product__c = this.product.Id
      );
    }

    public TestBenefit withName(String name) {
      benefit.Name = 'Test Benefit ' + name;
      return this;
    }

    public TestBenefit withProduct(cve__Product__c product) {
      benefit.cve__Product__c = product.Id;
      return this;
    }

    public cve__Benefit__c build() {
      return benefit;
    }
  }

  class TestContact {
    TestContactBuilder conBuilder;
    public SObject grp; // must be an SObject -- Group__c is not packaged so can't be compile-time error
    public Account acc;

    public TestContact(Account acc, SObject grp) {
      this.conBuilder = new TestContactBuilder()
        .withAccountId(acc.Id)
        .withGroupId(grp.Id);
    }

    public TestContact withIdentifier(String identifier) {
      conBuilder = conBuilder.withLastName('Test Contact ' + identifier);
      return this;
    }

    public Contact build() {
      return (Contact) conBuilder.build();
    }
  }

  private static cve__CoverageClaimed__c getCoverageClaimed(Id ccId) {
    return [
      SELECT
        Id,
        Name,
        cve__BenefitClaimed__c,
        cve__BenefitName__c,
        cve__ClaimId__c,
        cve__Amount__c,
        cve__Units__c,
        cve__BenefitClaimed__r.RecordTypeId,
        cve__BenefitClaimed__r.IncurredDate__c,
        cve__BenefitClaimed__r.cve__DateOfDisability__c,
        cve__BenefitClaimed__r.cve__Benefit__r.cve__CoverageAmount__c,
        cve__BenefitClaimed__r.cve__Benefit__c,
        cve__BenefitClaimed__r.cve__Claim__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__Policy__r.cve__Effective__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__c,
        cve__BenefitClaimed__r.cve__Claim__r.IncurredDate__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__ClaimantInsured__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Contact__c,
        cve__BenefitClaimed__r.cve__Claim__r.cve__PolicyRelationship__r.cve__Policy__c,
        cve__BenefitClaimed__r.cve__ClaimantInsured__c,
        cve__Coverage__r.cve__Category__c,
        cve__Coverage__c,
        cve__Coverage__r.RecordTypeId,
        cve__Coverage__r.cve__Amount__c,
        cve__Coverage__r.cve__AmountPerUnit__c,
        cve__Coverage__r.cve__Percentage__c,
        cve__Coverage__r.cve__PercentageOf__c,
        cve__Coverage__r.cve__PercentageOf__r.cve__Amount__c,
        cve__CoverageAmount__c,
        cve__CoverageRelationshipToPolicyholder__c,
        cve__EffectiveDateOfCoverage__c,
        cve__InvoiceLineItem__c,
        cve__PayableAmount__c,
        cve__PayableUnits__c,
        cve__Start__c
      FROM cve__CoverageClaimed__c
      WHERE id = :ccId
    ];
  }
}
/*
VAR:  Map<cve_CoverageClaimed_c, List<cve_CoverageClaimed_c>> preexistingCoveragesClaimedﾠ
(maps a CoverageClaimed to a list of CoveragesClaimed already in the database)
METHOD:  getPreexistingCoveragesClaimed(List<cve_CoverageClaimed_c> coveragesClaimed)
See "Coverage Limit Query Logic" for information on the query's design
TO TEST:
With 2 coveragesclaimed, and 2 historical coverageclaimed for each (same policy/holder, same coverage, different claims/BCs), mapping should be correct
With 2 coveragesClaimed and 1 historical coveragesClaimed for each, and a 3rd historicalcoverageClaimed not associated with either coverageClaimed, the 3rd historicalcoverageClaimed should not be returned
With 2 coveragesClaimed and 1 historical coveragesClaimed for each, and a 3rd coverageClaimed not associated with any historicalCoverageClaimed, the 3rd coverageClaimed should be returned with an empty list
  - Test with 1 contact (2 BCs + 2 coverages), test with 1 coverage (2 contacts + 2 BCs), 1 contact and 1 coverage (2 BCs)
Create an Account/Product/Policy + 2 Benefits w/ 1 Coverage each
Create 2 Contacts

VAR:  Map<Id, cve_BenefitClaimed_c> benefitsCoveragesClaimed 
(map of BenefitClaimed Id => BenefitClaimed)
METHOD: getBenefitsCoveragesClaimed(List<cve_BenefitClaimed_c> benefitsClaimed)
Get fields on the BenefitClaimed, INCLUDING a child query to return all CoveragesClaimed under the BenefitClaimed

VAR:  Map<Id, MemberBenefit_c> memberBenefitsﾠ
(maps a BenefitClaimed Id to a corresponding MemberBenefit)
METHOD: getMemberBenefits(List<cve_BenefitClaimed_c> benefitsClaimed)
The Claimant/Insured may have one or more records of a custom junction object, MemberBenefit_c.ﾠ 
This object links a Contact to a cve_Benefit_c, and is used to overwrite CV-calculated Benefit Claimed 
Amounts / Base Coverage Amounts with values calculated in USAble's Policy Admin system (Compass).ﾠ 
This query must select the correct MemberBenefit record, i.e. the record that links the Claimant to 
the Benefit Claimed's Benefit, where:
MemberBenefit_c.StartDate_c <= benefitClaimed.cve_Claim_r.IncurredDate_c < MemberBenefit_c.EndDate_c

VAR:  Map<cve_CoverageClaimed_c, List<CoverageLimitation_c>> coverageLimitations 
(maps a CoverageClaimed to a list of the CoverageLimitations that apply to its Coverage)
METHOD: getCoverageLimitations(List<cve_CoverageClaimed_c> coveragesClaimed)
return all CoverageLimitation_c objects for the CoverageClaimed's Coverage

VAR:  Map<CoverageLimitation_c, List<cve_CoverageClaimed_c>> coveragesClaimedByCoverageLimitation 
(maps a CoverageLimitation to a list of the CoveragesClaimed that match its filter criteria)
METHOD:  filterCoveragesClaimedByCoverageLimitations(List<cve_CoverageClaimed_c> coveragesClaimed)
for each CoverageLimitation for the CoverageClaimed, build a list of Pre-existing CoveragesClaimed 
that meet the Scopes (i.e. filter critera) for the CoverageLimitation (see Design Document section 
on filter logic for information about how to match based on Scopes).
*/