public with sharing class BenefitClaimedTriggerHelper {
  public Map<Id, String> benefitClaimExplanationString = new Map<Id, String>();
  public Map<Id, cve__BenefitClaimed__c> benefitClaimedById = new Map<Id, cve__BenefitClaimed__c>();
  private static final String CRITICAL_ILLNESS = 'CriticalIllness';
  private static final String SHORT_TERM_DISABILITY = 'ShortTermDisability';
  private static final String PENDING = 'Pending';
  private static final String APPROVED = 'Approved';
  private static final String DENIED = 'Denied';
  private static Map<String, Id> benefitClaimedRecordTypeIdsByDeveloperName = new Map<String, Id>();
  private final string cancelled = 'Cancelled';

  private BenefitClaimedTriggerHandler.ContextVariables contxtVars;

  BenefitCoverageClaimedSelector selector;

  public BenefitClaimedTriggerHelper setBenefitCoverageClaimedSelector(
    BenefitCoverageClaimedSelector selector
  ) {
    this.selector = selector;
    return this;
  }

  public static BenefitClaimedTriggerHelper getInstance() {
    return new BenefitClaimedTriggerHelper()
      .setBenefitCoverageClaimedSelector(
        BenefitCoverageClaimedSelector.getInstance()
      );
  }

  public BenefitClaimedTriggerHelper withContextVars(
    BenefitClaimedTriggerHandler.ContextVariables contxtVars
  ) {
    this.contxtVars = contxtVars;
    return this;
  }

  public void updateBenefitClaimed(
    Map<Id, List<usal__MemberBenefit__c>> claimantIdMemberBenefitsMap
  ) {
    try {
      List<cve__BenefitClaimed__c> benefitClaimedNewList = contxtVars.newList;
      for (cve__BenefitClaimed__c bc : benefitClaimedNewList) {
        if (
          claimantIdMemberBenefitsMap.containsKey(bc.cve__ClaimantInsured__c) &&
          claimantIdMemberBenefitsMap.get(bc.cve__ClaimantInsured__c) != null
        ) {
          updateSTDBenefitClaimed(
            bc,
            claimantIdMemberBenefitsMap.get(bc.cve__ClaimantInsured__c)
          );
          updateIllnessBenefitClaimed(
            bc,
            claimantIdMemberBenefitsMap.get(bc.cve__ClaimantInsured__c)
          );
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }
  }

  public void updateSTDBenefitClaimed(
    cve__BenefitClaimed__c benefitClaimed,
    List<usal__MemberBenefit__c> claimantMemberBenefits
  ) {
    String stdRecordTypeID = getRecordTypeId(SHORT_TERM_DISABILITY);
    for (usal__MemberBenefit__c mb : claimantMemberBenefits) {
      if (
        benefitClaimed.RecordTypeId == stdRecordTypeID &&
        benefitClaimed.cve__Benefit__c == mb.usal__BenefitId__c &&
        ((mb.usal__StartDate__c != null &&
        mb.usal__EndDate__c == null &&
        benefitClaimed.cve__DateOfDisability__c >= mb.usal__StartDate__c) ||
        (mb.usal__StartDate__c == null &&
        mb.usal__EndDate__c != null &&
        benefitClaimed.cve__DateOfDisability__c <= mb.usal__EndDate__c) ||
        (benefitClaimed.cve__DateOfDisability__c >= mb.usal__StartDate__c &&
        benefitClaimed.cve__DateOfDisability__c <= mb.usal__EndDate__c))
      ) {
        benefitClaimed.cve__BenefitAmount__c = mb.usal__Amount__c;
      }
    }
  }

  public void updateIllnessBenefitClaimed(
    cve__BenefitClaimed__c benefitClaimed,
    List<usal__MemberBenefit__c> claimantMemberBenefits
  ) {
    String critIllnessRecordTypeID = getRecordTypeId(CRITICAL_ILLNESS);
    for (usal__MemberBenefit__c mb : claimantMemberBenefits) {
      if (
        benefitClaimed.RecordTypeId == critIllnessRecordTypeID &&
        benefitClaimed.cve__Benefit__c == mb.usal__BenefitId__c &&
        ((mb.usal__StartDate__c != null &&
        mb.usal__EndDate__c == null &&
        benefitClaimed.IncurredDate__c >= mb.usal__StartDate__c) ||
        (mb.usal__StartDate__c == null &&
        mb.usal__EndDate__c != null &&
        benefitClaimed.IncurredDate__c <= mb.usal__EndDate__c) ||
        (benefitClaimed.IncurredDate__c >= mb.usal__StartDate__c &&
        benefitClaimed.IncurredDate__c <= mb.usal__EndDate__c))
      ) {
        benefitClaimed.cve__BaseCoverageAmount__c = mb.usal__Amount__c;
      }
    }
  }

  public Map<Id, List<usal__MemberBenefit__c>> processBenefitClaimed() {
    List<cve__BenefitClaimed__c> benefitClaimedNewList = contxtVars.newList;
    List<cve__BenefitClaimed__c> filteredBenefitClaimed = new List<cve__BenefitClaimed__c>();
    Map<Id, List<usal__MemberBenefit__c>> claimantIdMemberBenefitsMap = new Map<Id, List<usal__MemberBenefit__c>>();
    String stdRecordTypeID = getRecordTypeId(SHORT_TERM_DISABILITY);
    String critIllnessRecordTypeID = getRecordTypeId(CRITICAL_ILLNESS);

    for (cve__BenefitClaimed__c bc : benefitClaimedNewList) {
      if (
        bc.RecordTypeId == stdRecordTypeID ||
        bc.RecordTypeId == critIllnessRecordTypeID
      ) {
        filteredBenefitClaimed.add(bc);
      }
    }

    List<usal__MemberBenefit__c> mbList = selector.getMemberBenefits(
        filteredBenefitClaimed
      )
      .values();

    if (mbList != null && !mbList.isEmpty()) {
      for (usal__MemberBenefit__c mb : mbList) {
        if (claimantIdMemberBenefitsMap.containsKey(mb.usal__ContactId__c)) {
          claimantIdMemberBenefitsMap.get(mb.usal__ContactId__c).add(mb);
        } else {
          claimantIdMemberBenefitsMap.put(
            mb.usal__ContactId__c,
            new List<usal__MemberBenefit__c>{ mb }
          );
        }
      }
    }

    return claimantIdMemberBenefitsMap;
  }

  public string getRecordTypeId(String developerName) {
    if (
      benefitClaimedRecordTypeIdsByDeveloperName?.get(developerName) == null
    ) {
      benefitClaimedRecordTypeIdsByDeveloperName.put(
        developerName,
        Schema.SObjectType.cve__BenefitClaimed__c.getRecordTypeInfosByDeveloperName()
          .get(developerName)
          .getRecordTypeId()
      );
    }
    return benefitClaimedRecordTypeIdsByDeveloperName.get(developerName);
  }

  public class CustomException extends Exception {
  }

  public void getTotalCoveragesClaimedPayableAmounts() {
    Map<Id, usal__MemberBenefit__c> memberBenefits = selector.getMemberBenefits(
      contxtVars.newList
    );

    Map<Id, List<cve__CoverageClaimed__c>> benefitCoverageClaimedMap = getCoverageClaimed();
    Map<Id, Decimal> sumOfCoverageClaimed = getSumofCoverageClaimed(
      benefitCoverageClaimedMap
    );
    if (contxtVars.oldList != null) {
      benefitClaimExplanationString = getExplanationString(
        benefitCoverageClaimedMap
      );
    }

    updateFields(sumOfCoverageClaimed, memberBenefits, contxtVars.newList);
  }

  public Map<Id, List<cve__CoverageClaimed__c>> getCoverageClaimed() {
    Map<Id, List<cve__CoverageClaimed__c>> benefitCoverageClaimedMap = new Map<Id, List<cve__CoverageClaimed__c>>();
    benefitClaimedById = selector.getBenefitsCoveragesClaimed(
      contxtVars.newList
    );
    for (cve__BenefitClaimed__c bc : benefitClaimedById.values()) {
      if (
        bc.cve__CoveragesClaimed__r == null ||
        bc.cve__CoveragesClaimed__r.size() == 0
      ) {
        continue;
      }

      benefitCoverageClaimedMap.put(bc.id, bc.cve__CoveragesClaimed__r);
    }
    return benefitCoverageClaimedMap;
  }

  public Map<Id, Decimal> getSumOfCoverageClaimed(
    Map<Id, List<cve__CoverageClaimed__c>> benefitCoverageClaimedMap
  ) {
    Map<Id, Decimal> sumofcoverageclaimed = new Map<Id, Decimal>();
    for (Id id : benefitCoverageClaimedMap.keyset()) {
      Decimal sum;
      List<cve__CoverageClaimed__c> coverageClaimedList = benefitCoverageClaimedMap.get(
        id
      );
      for (cve__CoverageClaimed__c coverageClaimed : coverageClaimedList) {
        if (coverageClaimed.cve__PayableAmount__c != null) {
          if (sum == null) {
            sum = coverageClaimed.cve__PayableAmount__c;
          } else {
            sum = sum + coverageClaimed.cve__PayableAmount__c;
          }
        }
      }

      sumofcoverageclaimed.put(id, sum);
    }
    return sumofcoverageclaimed;
  }

  public Map<Id, String> getExplanationString(
    Map<Id, List<cve__CoverageClaimed__c>> benefitCoverageClaimedMap
  ) {
    Map<Id, String> benefitClaimExplanationString = new Map<Id, String>();
    for (Id id : benefitCoverageClaimedMap.keyset()) {
      Map<String, String> coverageNamebyAmount = new Map<String, String>();
      String oldExpString = contxtVars.oldMap.get(id).cve__Explanation2__c;

      if (oldExpString != null) {
        for (
          cve__CoverageClaimed__c coverageClaimed : benefitCoverageClaimedMap.get(
            id
          )
        ) {
          String coverageExplanation;
          if (
            coverageClaimed.cve__CalculatedAmount__c <=
            coverageClaimed.cve__PayableAmount__c
          ) {
            coverageExplanation =
              '<b>Coverage Amount</b> incremented by ' +
              coverageClaimed.cve__PayableAmount__c +
              ' as Coverage <b>' +
              coverageClaimed.cve__Coverage__r.Name +
              '</b> applies.';
          } else if (
            coverageClaimed.cve__CalculatedAmount__c >
            coverageClaimed.cve__PayableAmount__c
          ) {
            coverageExplanation =
              '<b>Coverage Amount</b> incremented by ' +
              coverageClaimed.cve__PayableAmount__c +
              ' (reduced from ' +
              coverageClaimed.cve__CalculatedAmount__c +
              ') as Coverage <b>' +
              coverageClaimed.cve__Coverage__r.Name +
              '</b> applies.';
          }
          coverageNamebyAmount.put(
            coverageClaimed.cve__Coverage__r.Name,
            coverageExplanation
          );
        }
        String newExplanation = '';
        for (String s : oldExpString.Split('<li>')) {
          String ce;
          if (s.contains('incremented by')) {
            for (String name : coverageNamebyAmount.keyset()) {
              if (s.contains(name)) {
                ce = coverageNamebyAmount.get(name);
              }
            }
          } else {
            ce = s;
          }
          newexplanation += newexplanation == '' ? ce : +'<li>' + ce + '</li>';
        }
        if (!newexplanation.contains('Calculated at') && newexplanation != '') {
          newexplanation =
            newexplanation +
            '<br>Calculated at ' +
            DateTime.now().format('MM/dd/YYYY hh:mm a') +
            '.</br>';
        }
        benefitClaimExplanationString.put(id, newexplanation);
      }
    }
    return benefitClaimExplanationString;
  }

  public void updateFields(
    Map<Id, Decimal> sumofcoverageclaimed,
    Map<Id, usal__MemberBenefit__c> benefitIdwithmemberBenefitMap,
    List<cve__BenefitClaimed__c> newList
  ) {
    for (cve__BenefitClaimed__c newbc : newList) {
      usal__MemberBenefit__c mb;
      Decimal sum;
      if (benefitIdwithmemberBenefitMap != null) {
        mb = benefitIdwithmemberBenefitMap.get(newbc.Id);
      }
      if (sumofcoverageclaimed != null) {
        sum = sumofcoverageclaimed.get(newbc.Id);
      }

      newbc.cve__CoverageAmount__c = sum;
      if (
        benefitClaimExplanationString.get(newbc.Id) != null &&
        (!String.isEmpty(benefitClaimExplanationString.get(newbc.Id)))
      ) {
        newbc.cve__Explanation2__c = benefitClaimExplanationString.get(
          newbc.Id
        );
      }
    }
  }

  public Map<Id, cve__Benefit__c> getBenefit() {
    Set<Id> benefitIds = new Set<Id>();
    for (cve__BenefitClaimed__c bc : contxtVars.newList) {
      benefitIds.add(bc.cve__Benefit__c);
    }

    Map<Id, cve__Benefit__c> benefitsById = new Map<Id, cve__Benefit__c>(
      [
        SELECT Id, cve__CoverageAmount__c
        FROM cve__Benefit__c
        WHERE id IN :benefitIds
      ]
    );
    return benefitsById;
  }

  public List<Task> getTasks(List<cve__BenefitClaimed__c> bcRecords) {
    List<Task> associatedTasks = new List<Task>();
    Set<Id> bcIds = new Set<Id>();

    for (cve__BenefitClaimed__c bcClaim : bcRecords) {
      if (bcClaim.cve__status__C == cancelled) {
        bcIds.add(bcClaim.id);
      }
    }

    if (!bcIds.isEmpty() && bcIds != null) {
      List<Task> tlist = [
        SELECT id, Status
        FROM Task
        WHERE WhatId IN :bcIds
      ];
      for (task t : tlist) {
        Task newtask = new task();
        newtask.id = t.Id;
        newtask.Status = cancelled;
        associatedTasks.add(newtask);
      }
    }
    return associatedTasks;
  }

  public void addValidationforRejectBenefitClaim() {
    Map<Id, cve__BenefitClaimed__c> benefitClaimedByIdforDenied = new Map<Id, cve__BenefitClaimed__c>{};
    for (cve__BenefitClaimed__c bc : contxtVars.newList) {
      if (bc.cve__Status__c == 'Denied') {
        benefitClaimedByIdforDenied.put(bc.Id, bc);
      }
    }
    if (benefitClaimedByIdforDenied.isEmpty()) {
      return;
    }

    List<Id> processInstanceIds = new List<Id>{};

    for (cve__BenefitClaimed__c bc : [
      SELECT
        (
          SELECT ID
          FROM ProcessInstances
          ORDER BY CreatedDate DESC
          LIMIT 1
        )
      FROM cve__BenefitClaimed__c
      WHERE ID IN :benefitClaimedByIdforDenied.keySet()
    ]) {
      if (bc.ProcessInstances != null && bc.ProcessInstances.size() > 0) {
        processInstanceIds.add(bc.ProcessInstances[0].Id);
      }
    }

    for (ProcessInstance pi : [
      SELECT
        TargetObjectId,
        (
          SELECT Id, StepStatus, Comments, OriginalActorId
          FROM Steps
          ORDER BY CreatedDate DESC
          LIMIT 1
        )
      FROM ProcessInstance
      WHERE Id IN :processInstanceIds
      ORDER BY CreatedDate DESC
    ]) {
      if (pi.Steps != null && pi.Steps.size() > 0) {
        if (
          (pi.Steps[0].Comments == null ||
          pi.Steps[0].Comments.trim().length() == 0)
        ) {
          benefitClaimedByIdforDenied.get(pi.TargetObjectId)
            .addError(
              'Operation Cancelled: Please provide a reason ' +
              'for your rejection!'
            );
        }
      }
    }
  }
  public List<cve__Claim__c> benefitClaimedTATcalculation(
    List<cve__BenefitClaimed__c> newList,
    Map<Id, cve__BenefitClaimed__c> oldMap
  ) {
    List<cve__Claim__c> cveClaimsToUpdate = new List<cve__Claim__c>();
    try {
      for (cve__BenefitClaimed__c bc : [
        SELECT
          Id,
          cve__Status__c,
          cve__Claim__r.StatusChangedDate__c,
          cve__Claim__r.FinalStatusChangedDate__c,
          cve__Claim__r.BCInitialDecisionDate__c,
          cve__Claim__r.BCFinalDecisionDate__c
        FROM cve__BenefitClaimed__c
        WHERE Id IN :newList
      ]) {
        if (oldMap.get(bc.Id).cve__Status__c != bc.cve__Status__c) {
          cveClaimsToUpdate = benefitClaimedCveClaimCreation(bc, oldMap);
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }
    return cveClaimsToUpdate;
  }

  public List<cve__Claim__c> benefitClaimedCveClaimCreation(
    cve__BenefitClaimed__c bc,
    Map<Id, cve__BenefitClaimed__c> oldMap
  ) {
    Set<String> bcStatusSet = new Set<String>{ APPROVED, DENIED };
    List<cve__Claim__c> cveClaimsList = new List<cve__Claim__c>();

    Date initialDecisionDate = bc.cve__Claim__r.BCInitialDecisionDate__c;
    Date finalDecisionDate = bc.cve__Claim__r.BCFinalDecisionDate__c;
    cve__Claim__c claim = new cve__Claim__c(Id = bc.cve__Claim__c);
    claim.BCInitialDecisionDate__c = (bc.cve__Claim__r.StatusChangedDate__c ==
      null &&
      initialDecisionDate == null)
      ? system.today()
      : initialDecisionDate;
    claim.BCFinalDecisionDate__c = (bc.cve__Claim__r.FinalStatusChangedDate__c ==
      null &&
      bcStatusSet.contains(bc.cve__Status__c) &&
      finalDecisionDate == null)
      ? system.today()
      : finalDecisionDate;
    cveClaimsList.add(claim);
    return cveClaimsList;
  }

  public ReturnValues deleteRecoupment(
    List<cve__BenefitClaimed__c> newList,
    Map<Id, cve__BenefitClaimed__c> oldMap
  ) {
    Set<Id> bcIds = new Set<Id>();
    Set<Id> upayIds = new Set<Id>();
    Set<Id> priorIds = new Set<Id>();
    ReturnValues values = new ReturnValues();

    for (cve__BenefitClaimed__c bc : newList) {
      cve__BenefitClaimed__c oldBc = oldMap.get(bc.id);
      if (
        bc.cve__Status__c != oldBc.cve__Status__c &&
        (bc.cve__Status__c == 'Denied' ||
        bc.cve__Status__c == 'Cancelled')
      ) {
        bcIds.add(bc.id);
      }
    }

    if (bcIds.size() == 0) {
      return values;
    }

    Set<Id> psIds = new Map<Id, cve__PaymentSpecification__c>(
        [
          SELECT id
          FROM cve__PaymentSpecification__c
          WHERE cve__BenefitClaimed__c IN :bcIds
        ]
      )
      .keySet();

    List<cve__Adjustment__c> adjList = [
      SELECT id, PriorPaymentSpecs__c, UnallocatedPayment__c
      FROM cve__Adjustment__c
      WHERE
        cve__Type__c = 'Recoup Overpayment (Pre-Tax)'
        AND cve__PaymentSpecification__c IN :psIds
    ];

    if (adjList == null || (adjList != null && adjList.size() == 0)) {
      return values;
    }
    for (cve__Adjustment__c adj : adjList) {
      if (adj.UnallocatedPayment__c != null) {
        upayIds.add(adj.UnallocatedPayment__c);
      }
      if (adj.PriorPaymentSpecs__c != null) {
        priorIds.add(adj.PriorPaymentSpecs__c);
      }
    }

    List<cve__UnallocatedPayment__c> upList = [
      SELECT id
      FROM cve__UnallocatedPayment__c
      WHERE id IN :upayIds
    ];

    List<RecalculatePayments__e> eventList = new List<RecalculatePayments__e>();

    for (Id psId : psIds) {
      eventList.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = psId)
      );
    }

    for (Id psId : priorIds) {
      eventList.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = psId)
      );
    }

    values.adjList.addAll(adjList);
    values.upayList.addAll(upList);
    values.eventList.addAll(eventList);

    return values;
  }

  //set status reason field
  public List<cve__BenefitClaimed__c> updateBcStatusReason(
    List<cve__BenefitClaimed__c> newList,
    Map<Id, cve__BenefitClaimed__c> oldMap
  ) {
    List<cve__BenefitClaimed__c> cveClaimsToUpdate = new List<cve__BenefitClaimed__c>();

    try {
      for (cve__BenefitClaimed__c bc : newList) {
        cve__BenefitClaimed__c oldBc = oldMap.get(bc.Id);

        if (
          (oldBc.cve__StatusReason__c != 'Additional Information Needed') &&
          (bc.cve__Status__c == 'Pending' ||
          bc.cve__Status__c == 'Suspended')
        ) {
          cve__BenefitClaimed__c obj = new cve__BenefitClaimed__c();
          obj.Id = bc.id;

          obj.cve__StatusReason__c = 'Additional Information Needed';

          cveClaimsToUpdate.add(obj);
        }
      }
    } catch (Exception e) {
      System.debug(
        'Exception caught at :: ' + e.getLineNumber() + ' :: ' + e.getMessage()
      );
    }

    return cveClaimsToUpdate;
  }

  public class ReturnValues {
    public List<cve__UnallocatedPayment__c> upayList;
    public List<cve__Adjustment__c> adjList;
    public List<RecalculatePayments__e> eventList;

    public ReturnValues() {
      this.upayList = new List<cve__UnallocatedPayment__c>();
      this.adjList = new List<cve__Adjustment__c>();
      this.eventList = new List<RecalculatePayments__e>();
    }
  }
}