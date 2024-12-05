public with sharing class AdjustmentTriggerHelper {
  private static AdjustmentTriggerHelper instance;
  private AdjustmentTriggerHandler.ContextVariables contxt;

  private Map<Id, cve__PaymentSpecification__c> psMap;
  private Map<Id, Id> psToContactIds;
  private Map<Id, Contact> contactsMap;
  private Map<Id, TaxabilityOverride> taxabilityOverrideObjects;

  public static AdjustmentTriggerHelper getInstance() {
    if (instance == null) {
      instance = new AdjustmentTriggerHelper();
    }
    return instance;
  }

  private AdjustmentTriggerHelper() {
  }

  public AdjustmentTriggerHelper withContextVariables(
    AdjustmentTriggerHandler.ContextVariables contextVars
  ) {
    this.contxt = contextVars;
    return this;
  }

  public void updateTaxabilityOverride() {
    createTaxabilityOverrideObjects();
    adjustTaxability();
  }

  public void createTaxabilityOverrideObjects() {
    getPaymentSpecs();
    queryContacts();
    mapTaxabilityOverrides();
  }

  private void getPaymentSpecs() {
    Set<Id> psIds = new Set<Id>();
    psToContactIds = new Map<Id, Id>();

    for (cve__Adjustment__c adjustment : contxt.newList) {
      if (
        adjustment.cve__Type__c == 'FICA Tax' ||
        adjustment.cve__Type__c == 'Medicare Tax'
      ) {
        psIds.add(adjustment.cve__PaymentSpecification__c);
      }
    }

    psMap = new Map<Id, cve__PaymentSpecification__c>(
      [
        SELECT
          Id,
          Claimant__c,
          cvint__AbsenceClaim__c,
          cve__DisabledAutomatedAdjustmentTypes__c,
          (SELECT cve__Type__c, cve__Percentage__c FROM cve__Adjustments__r)
        FROM cve__PaymentSpecification__c
        WHERE Id IN :psIds
      ]
    );

    for (Id psId : psIds) {
      psToContactIds.put(psId, psMap.get(psId).Claimant__c);
    }
  }

  private void queryContacts() {
    contactsMap = new Map<Id, Contact>(
      [
        SELECT
          Id,
          FICATaxabilityAbsence__c,
          FICATaxabilityDisability__c,
          MedicareTaxabilityAbsence__c,
          MedicareTaxabilityDisability__c,
          AccountId,
          Account.FICATaxabilityAbsence__c,
          Account.FICATaxabilityDisability__c,
          Account.MedicareTaxabilityAbsence__c,
          Account.MedicareTaxabilityDisability__c,
          (
            SELECT
              Id,
              cve__Class__r.FICATaxabilityAbsence__c,
              cve__Class__r.FICATaxabilityDisability__c,
              cve__Class__r.MedicareTaxabilityAbsence__c,
              cve__Class__r.MedicareTaxabilityDisability__c
            FROM cve__ClassRelationships__r
          )
        FROM Contact
        WHERE Id IN :psToContactIds.values()
      ]
    );
  }

  private void mapTaxabilityOverrides() {
    taxabilityOverrideObjects = new Map<Id, TaxabilityOverride>();
    for (cve__PaymentSpecification__c ps : psMap.values()) {
      Contact con = contactsMap.get(ps.Claimant__c);

      if (con != null) {
        taxabilityOverrideObjects.put(ps.Id, new TaxabilityOverride(ps, con));
      }
    }
  }

  private void adjustTaxability() {
    for (cve__Adjustment__c adjustment : contxt.newList) {
      if (
        (adjustment.cve__Type__c != 'FICA Tax' &&
        adjustment.cve__Type__c != 'Medicare Tax') ||
        !adjustment.cve__Automated__c
      ) {
        continue;
      }

      TaxabilityOverride to = taxabilityOverrideObjects.get(
        adjustment.cve__PaymentSpecification__c
      );
      if (to == null) {
        return;
      }

      calculatePercentage(adjustment, to);
    }
  }

  private void calculatePercentage(
    cve__Adjustment__c adjustment,
    TaxabilityOverride to
  ) {
    switch on adjustment.cve__Type__c {
      when 'FICA Tax' {
        adjustment.cve__Percentage__c *= to.ficaOverride == null
          ? 1
          : to.ficaOverride * .01;
      }
      when 'Medicare Tax' {
        adjustment.cve__Percentage__c *= to.medicareOverride == null
          ? 1
          : to.medicareOverride * .01;
      }
    }
  }

  class TaxabilityOverride {
    cve__PaymentSpecification__c ps;
    Contact con;
    Account acc;
    Decimal ficaOverride;
    Decimal medicareOverride;
    Boolean isDisability;

    TaxabilityOverride(cve__PaymentSpecification__c ps, Contact con) {
      this.ps = ps;
      this.con = con;
      this.acc = con.Account;
      this.isDisability = ps.cvint__AbsenceClaim__c == null;
      getOverrides();
    }

    private void getOverrides() {
      String ficaField = buildTaxabilityFieldName('FICA');
      String medicareField = buildTaxabilityFieldName('Medicare');
      ficaOverride = (Decimal) con.get(ficaField);
      medicareOverride = (Decimal) con.get(medicareField);

      if (
        ficaOverride == null &&
        con.cve__ClassRelationships__r != null &&
        con.cve__ClassRelationships__r.size() > 0
      ) {
        ficaOverride = (Decimal) getClassOverride(ficaField);
      }
      if (
        medicareOverride == null &&
        con.cve__ClassRelationships__r != null &&
        con.cve__ClassRelationships__r.size() > 0
      ) {
        medicareOverride = (Decimal) getClassOverride(medicareField);
      }

      if (ficaOverride == null) {
        ficaOverride = (Decimal) acc.get(ficaField);
      }
      if (medicareOverride == null) {
        medicareOverride = (Decimal) acc.get(medicareField);
      }
    }

    private String buildTaxabilityFieldName(String taxType) {
      String productType = isDisability ? 'Disability' : 'Absence';
      return taxType + 'Taxability' + productType + '__c';
    }

    private Object getClassOverride(String fieldName) {
      Decimal taxability;

      for (cve__ClassRelationship__c cr : con.cve__ClassRelationships__r) {
        cve__Class__c cveClass = cr.cve__Class__r;
        Decimal classOverride = (Decimal) cveClass.get(fieldName);

        if (taxability == null || classOverride <= taxability) {
          taxability = classOverride;
        }
      }
      return taxability;
    }
  }
}