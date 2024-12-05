public class AdditionalIncomeOffsetTriggerHelper {
  public static final String PFML_ADJUSTMENT_TYPE = 'PFML Income Offset (Pre-Tax)';
  public static final String STD_ADJUSTMENT_TYPE = 'STD Income Offset (Pre-Tax)';
  public static final String ADDITIONAL_INCOME_ADJUSTMENT_TYPE = 'Additional Income (Pre-Tax)';
  public static final String ADDITIONAL_INCOME_OFFSET_ADJUSTMENT_TYPE = 'Additional Income Offset (Pre-Tax)';
  public static final Set<String> ADJUSTMENT_TYPES = new Set<String>{
    PFML_ADJUSTMENT_TYPE,
    STD_ADJUSTMENT_TYPE,
    ADDITIONAL_INCOME_ADJUSTMENT_TYPE,
    ADDITIONAL_INCOME_OFFSET_ADJUSTMENT_TYPE
  };

  public static final String PFML_INCOME_TYPE = 'PFML Income';
  public static final String STD_INCOME_TYPE = 'STD Income';
  public static final String STRAIGHT_OFFSET_INCOME_TYPE = 'Straight Offset';
  public static final String PREDISABILITY_EARNINGS_INCOME_TYPE = 'Pre-Disability Earnings';

  private Set<Id> cveClaimIds;
  private Set<Id> cvabClaimIds;
  private Map<Id, cve__PaymentSpecification__c> cvePaymentSpecs;
  private Map<Id, cve__PaymentSpecification__c> cvabPaymentSpecs;

  public static AdditionalIncomeOffsetTriggerHelper getInstance() {
    return new AdditionalIncomeOffsetTriggerHelper();
  }

  public List<OffsetEvent> deserializePayload(
    List<AdditionalIncomeOffset__e> eventList
  ) {
    List<OffsetEvent> eventPayload = new List<OffsetEvent>();
    for (AdditionalIncomeOffset__e event : eventList) {
      eventPayload.add(
        (OffsetEvent) JSON.deserialize(
          event.OffsetIncomeData__c,
          OffsetEvent.class
        )
      );
    }
    return eventPayload;
  }

  public List<cve__Adjustment__c> selectPreExistingAdjustments(
    List<OffsetEvent> payloadList
  ) {
    List<cve__Adjustment__c> adjustmentsToDelete = new List<cve__Adjustment__c>();

    cveClaimIds = new Set<Id>();
    cvabClaimIds = new Set<Id>();

    for (OffsetEvent payload : payloadList) {
      if (payload.cveClaim != null) {
        cveClaimIds.add(payload.cveClaim.id);
      }
      if (payload.cvabClaim != null) {
        cvabClaimIds.add(payload.cvabClaim.id);
      }
    }
    cvePaymentSpecs = getAllCvePaymentSpecs(cveClaimIds);
    cvabPaymentSpecs = getAllCvabPaymentSpecs(cvabClaimIds);
    if (!cvePaymentSpecs.isEmpty()) {
      adjustmentsToDelete.addAll(
        selectAdjustmentsForDelete(cvePaymentSpecs.keySet())
      );
    }
    if (!cvabPaymentSpecs.isEmpty()) {
      adjustmentsToDelete.addAll(
        selectAdjustmentsForDelete(cvabPaymentSpecs.keySet())
      );
    }

    return adjustmentsToDelete;
  }

  public Map<Id, List<cve__Adjustment__c>> generateNewAdjustments(
    List<OffsetEvent> payloadList
  ) {
    Map<Id, List<cve__Adjustment__c>> result = new Map<Id, List<cve__Adjustment__c>>();
    for (OffsetEvent payload : payloadList) {
      if (payload.cveClaim != null && payload.cvabClaim != null) {
        List<AdditionalIncome__c> pfmlAdditionalIncome = getAllPFMLAdditionalIncomes(
          payload.additionalIncomeList
        );
        List<AdditionalIncome__c> stdAdditionalIncome = getAllSTDAdditionalIncomes(
          payload.additionalIncomeList
        );
        List<AdditionalIncome__c> otherAdditionalIncome = getAllOtherAdditionalIncomes(
          payload.additionalIncomeList
        );

        if (pfmlAdditionalIncome.size() > 0) {
          List<cve__PaymentSpecification__c> paymentSpecs = getAllRelatedCvePaymentSpec(
            payload.cveClaim.id,
            cvePaymentSpecs.values()
          );
          for (cve__PaymentSpecification__c ps : paymentSpecs) {
            result.put(ps.id, processPFMLIncomes(ps.id, pfmlAdditionalIncome));
          }
        }

        if (stdAdditionalIncome.size() > 0) {
          List<cve__PaymentSpecification__c> paymentSpecs = getAllRelatedCvabPaymentSpec(
            payload.cvabClaim.id,
            cvabPaymentSpecs.values()
          );
          for (cve__PaymentSpecification__c ps : paymentSpecs) {
            result.put(ps.id, processSTDIncomes(ps.id, stdAdditionalIncome));
          }
        }

        if (otherAdditionalIncome.size() > 0) {
          List<cve__PaymentSpecification__c> paymentSpecs = getAllRelatedCvabPaymentSpec(
            payload.cvabClaim.id,
            cvabPaymentSpecs.values()
          );
          paymentSpecs.addAll(
            getAllRelatedCvePaymentSpec(
              payload.cveClaim.id,
              cvePaymentSpecs.values()
            )
          );
          for (cve__PaymentSpecification__c ps : paymentSpecs) {
            if (result.containsKey(ps.id)) {
              List<cve__Adjustment__c> priorList = result.get(ps.id);
              priorList.addAll(
                processOtherIncomes(ps.id, otherAdditionalIncome)
              );
              result.put(ps.id, priorList);
            } else {
              result.put(
                ps.id,
                processOtherIncomes(ps.id, otherAdditionalIncome)
              );
            }
          }
        }
      } else {
        if (payload.cveClaim != null) {
          List<cve__PaymentSpecification__c> paymentSpecs = getAllRelatedCvePaymentSpec(
            payload.cveClaim.id,
            cvePaymentSpecs.values()
          );
          for (cve__PaymentSpecification__c ps : paymentSpecs) {
            result.put(
              ps.id,
              processOtherIncomes(ps.id, payload.additionalIncomeList)
            );
          }
        } else if (payload.cvabClaim != null) {
          List<cve__PaymentSpecification__c> paymentSpecs = getAllRelatedCvabPaymentSpec(
            payload.cvabClaim.id,
            cvabPaymentSpecs.values()
          );
          for (cve__PaymentSpecification__c ps : paymentSpecs) {
            result.put(
              ps.id,
              processOtherIncomes(ps.id, payload.additionalIncomeList)
            );
          }
        }
      }
    }
    return result;
  }

  public List<cve__PaymentSpecification__c> getAllRelatedCvePaymentSpec(
    Id claimId,
    List<cve__PaymentSpecification__c> paymentSpecs
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    for (cve__PaymentSpecification__c ps : paymentSpecs) {
      if (ps.cve__Claim__c == claimId) {
        result.add(ps);
      }
    }
    return result;
  }

  public List<cve__PaymentSpecification__c> getAllRelatedCvabPaymentSpec(
    Id claimId,
    List<cve__PaymentSpecification__c> paymentSpecs
  ) {
    List<cve__PaymentSpecification__c> result = new List<cve__PaymentSpecification__c>();
    for (cve__PaymentSpecification__c ps : paymentSpecs) {
      if (ps.cvint__AbsenceClaim__c == claimId) {
        result.add(ps);
      }
    }
    return result;
  }

  public Map<Id, cve__PaymentSpecification__c> getAllCvePaymentSpecs(
    Set<Id> cveClaimIds
  ) {
    return new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id, cve__Claim__c, cvint__AbsenceClaim__c
        FROM cve__PaymentSpecification__c
        WHERE cve__Claim__c IN :cveClaimIds
      ]
    );
  }

  public Map<Id, cve__PaymentSpecification__c> getAllCvabPaymentSpecs(
    Set<Id> cvabClaimIds
  ) {
    return new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT id, cve__Claim__c, cvint__AbsenceClaim__c
        FROM cve__PaymentSpecification__c
        WHERE cvint__AbsenceClaim__c IN :cvabClaimIds
      ]
    );
  }

  public List<cve__Adjustment__c> selectAdjustmentsForDelete(
    Set<Id> paymentSpecIds
  ) {
    List<cve__Adjustment__c> adjustmentsToBeDeleted = [
      SELECT id
      FROM cve__Adjustment__c
      WHERE
        cve__PaymentSpecification__c IN :paymentSpecIds
        AND cve__Type__c IN :ADJUSTMENT_TYPES
    ];

    return adjustmentsToBeDeleted;
  }

  public List<AdditionalIncome__c> getAllPFMLAdditionalIncomes(
    List<AdditionalIncome__c> incomeList
  ) {
    List<AdditionalIncome__c> result = new List<AdditionalIncome__c>();
    for (AdditionalIncome__c income : incomeList) {
      if (income.IncomeType__c == PFML_INCOME_TYPE) {
        result.add(income);
      }
    }
    return result;
  }

  public List<AdditionalIncome__c> getAllSTDAdditionalIncomes(
    List<AdditionalIncome__c> incomeList
  ) {
    List<AdditionalIncome__c> result = new List<AdditionalIncome__c>();
    for (AdditionalIncome__c income : incomeList) {
      if (income.IncomeType__c == STD_INCOME_TYPE) {
        result.add(income);
      }
    }
    return result;
  }

  public List<AdditionalIncome__c> getAllOtherAdditionalIncomes(
    List<AdditionalIncome__c> incomeList
  ) {
    List<AdditionalIncome__c> result = new List<AdditionalIncome__c>();
    for (AdditionalIncome__c income : incomeList) {
      if (
        income.IncomeType__c != STD_INCOME_TYPE &&
        income.IncomeType__c != PFML_INCOME_TYPE
      ) {
        result.add(income);
      }
    }
    return result;
  }

  public List<cve__Adjustment__c> processPFMLIncomes(
    Id paymentSpecId,
    List<AdditionalIncome__c> incomeList
  ) {
    List<cve__Adjustment__c> resultList = new List<cve__Adjustment__c>();
    for (AdditionalIncome__c income : incomeList) {
      cve__Adjustment__c result = new cve__Adjustment__c();
      result.cve__Start__c = income.StartDate__c;
      result.cve__Through__c = income.EndDate__c;
      result.cve__Period__c = income.Period__c;
      result.cve__Amount__c = income.Amount__c;
      result.cve__PaymentSpecification__c = paymentSpecId;
      result.cve__Type__c = PFML_ADJUSTMENT_TYPE;
      resultList.add(result);
    }
    return resultList;
  }

  public List<cve__Adjustment__c> processSTDIncomes(
    Id paymentSpecId,
    List<AdditionalIncome__c> incomeList
  ) {
    List<cve__Adjustment__c> resultList = new List<cve__Adjustment__c>();
    for (AdditionalIncome__c income : incomeList) {
      cve__Adjustment__c result = new cve__Adjustment__c();
      result.cve__Start__c = income.StartDate__c;
      result.cve__Through__c = income.EndDate__c;
      result.cve__Period__c = income.Period__c;
      result.cve__Amount__c = income.Amount__c;
      result.cve__PaymentSpecification__c = paymentSpecId;
      result.cve__Type__c = STD_ADJUSTMENT_TYPE;
      resultList.add(result);
    }
    return resultList;
  }

  public List<cve__Adjustment__c> processOtherIncomes(
    Id paymentSpecId,
    List<AdditionalIncome__c> incomeList
  ) {
    List<cve__Adjustment__c> resultList = new List<cve__Adjustment__c>();
    for (AdditionalIncome__c income : incomeList) {
      cve__Adjustment__c result = new cve__Adjustment__c();
      String offsetType = determineOffsetType(income);
      result.cve__Start__c = income.StartDate__c;
      result.cve__Through__c = income.EndDate__c;
      result.cve__Period__c = income.Period__c;
      result.cve__PaymentSpecification__c = paymentSpecId;
      if (offsetType == PREDISABILITY_EARNINGS_INCOME_TYPE) {
        result.cve__Amount__c = income.Amount__c * -1;
        result.cve__Type__c = ADDITIONAL_INCOME_ADJUSTMENT_TYPE;
      } else if (offsetType == STRAIGHT_OFFSET_INCOME_TYPE) {
        result.cve__Amount__c = income.Amount__c;
        result.cve__Type__c = ADDITIONAL_INCOME_OFFSET_ADJUSTMENT_TYPE;
      } else {
        system.debug('Offset Type not Found');
      }

      resultList.add(result);
    }
    return resultList;
  }

  public String determineOffsetType(AdditionalIncome__c income) {
    List<OffsetCalculationApplicableIncomes__mdt> metadataValues = OffsetCalculationApplicableIncomes__mdt.getAll()
      .values();
    for (OffsetCalculationApplicableIncomes__mdt metaData : metadataValues) {
      List<String> incomeTypes = metaData.ApplicableTypes__c.split(',');
      if (incomeTypes.contains(income.IncomeType__c)) {
        return metaData.OffsetCalculation__c;
      }
    }
    return '';
  }

  public List<RecalculatePayments__e> generateEvents(Set<Id> paymentSpecIds) {
    List<RecalculatePayments__e> result = new List<RecalculatePayments__e>();
    for (Id paymentId : paymentSpecIds) {
      result.add(
        new RecalculatePayments__e(PaymentSpecificationId__c = paymentId)
      );
    }
    return result;
  }
}