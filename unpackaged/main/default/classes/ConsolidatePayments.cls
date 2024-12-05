public with sharing class ConsolidatePayments {
  public static Map<String, Schema.RecordTypeInfo> paymentRecordTypes;

  public List<cve__Payment__c> consolidatePaymentsByPaymentSpecIds(
    List<Id> paySpecIds
  ) {
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, Date> issueDates = new Map<Id, Date>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    //get payments based on Payment Specification Ids
    payments = getPayments(paySpecIds);
    issueDates = getIssueDates(payments);

    paymentsPerPaySpec = paymentsPerPaymentsSpecification(payments);

    Action act;
    for (Id id : paymentsPerPaySpec.keyset()) {
      act = new ConsolidateAction(
        paymentsPerPaySpec,
        paymentsPerPaySpec.get(id),
        issueDates
      );
      String result;
      payments = paymentsPerPaySpec.get(id);
      // First pass is validation only to avoid partial updates to the in-memory objects
      for (Integer i = 0; i < payments.size(); i++) {
        result = act.validate(
          payments.get(i),
          i == 0,
          i == payments.size() - 1
        );
        if (result != null) {
          paymentsPerPaySpec.remove(id);
          payments.remove(i);
        }
      }
    }
    List<cve__Payment__c> consolidatedPayments;
    if (paymentsPerPaySpec.size() > 0 && paymentsPerPaySpec != null) {
      consolidatedPayments = doWithPayments(paymentsPerPaySpec, payments, act);
    }
    return consolidatedPayments;
  }

  public Map<Id, List<cve__Payment__c>> paymentsPerPaymentsSpecification(
    List<cve__Payment__c> payments
  ) {
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    for (cve__Payment__c p : payments) {
      if (paymentsPerPaySpec.get(p.cve__PaymentSpecification__c) == null) {
        paymentsPerPaySpec.put(
          p.cve__PaymentSpecification__c,
          new List<cve__Payment__c>()
        );
      }
      paymentsPerPaySpec.get(p.cve__PaymentSpecification__c).add(p);
    }
    return paymentsPerPaySpec;
  }

  public List<cve__Payment__c> getPayments(List<Id> paySpecIds) {
    List<cve__Payment__c> payments = [
      SELECT
        Id,
        (
          SELECT
            cve__ToPayment__r.Id,
            cve__ToPayment__r.Name,
            cve__ToPayment__r.cve__Status__c
          FROM cve__PaymentAssociationsFrom__r
        ),
        (
          SELECT
            cve__FromPayment__r.Id,
            cve__FromPayment__r.Name,
            cve__FromPayment__r.cve__Status__c
          FROM cve__PaymentAssociationsTo__r
        ),
        Name,
        cve__PaymentSpecification__c,
        cve__Status__c,
        cve__PaymentSpecification__r.cve__Period__c,
        cve__BenefitClaimed__c,
        RecordTypeId,
        cve__NetBeforeTaxes__c,
        cve__NetAfterTaxes__c,
        cve__Net__c,
        cve__FicaTaxableBenefitAmount__c,
        cve__EmployerMatchingMedicare__c,
        cve__EmployerMatchingFica__c,
        cve__IssueOverride__c,
        cve__Issue__c,
        cve__Payable__c,
        cve__Through__c,
        cve__Start__c,
        cve__PaymentMethod__c,
        cve__Account__c,
        cve__Contact__c,
        cve__Claim__c,
        cve__PayeeClaimRelationshipType__c,
        cve__PayeeName__c,
        cve__TaxIdNumber__c,
        cve__MailingStreet__c,
        cve__MailingCity__c,
        cve__MailingState__c,
        cve__MailingPostalCode__c,
        cve__MailingCountry__c,
        cve__MailingCountryCode__c,
        cve__MailingStateCode__c,
        cve__BankName__c,
        cve__BankPhone__c,
        cve__BankAccountType__c,
        cve__BankRoutingNumber__c,
        cve__BankAccountNumber__c,
        cve__UnallocatedPayment__c
      FROM cve__Payment__c
      WHERE
        cve__PaymentSpecification__c IN :paySpecIds
        AND (cve__Status__c = 'Pending'
        OR cve__Status__c = 'Approved')
        AND cve__UnallocatedPayment__c != NULL
      WITH SECURITY_ENFORCED
    ];
    return payments;
  }

  public Map<Id, Date> getIssueDates(List<cve__Payment__c> payments) {
    Map<Id, Date> issueDates = new Map<Id, Date>();
    for (cve__Payment__c p : payments) {
      issueDates.put(p.Id, Date.today());
    }
    return issueDates;
  }

  public interface Action {
    /**
     * Return null for ok else return an error message.
     */
    String validate(cve__Payment__c p, Boolean isFirst, Boolean isLast);
    /**
     * This is only invoked if validate has returned no errors for any payments.
     * Return null for ok else return an error message.
     */
    String perform(
      // cve__Payment__c p,
      Id id,
      List<cve__Payment__c> upserts,
      Map<cve__Payment__c, cve__Payment__c> existingToNew
    );
    /**
     * Called before upsert.
     */
    void beforeUpsert();
    /**
     * Called after upsert.
     */
    void afterUpsert();
    /**
     * Called once only after perform has been invoked per payment.
     */
    void performLast();
  }

  public with sharing class ConsolidateAction implements Action {
    Set<String> validStatuses = new Set<String>{
      'Pending',
      'Approved',
      'Rejected'
    };
    List<cve__Payment__c> payments = new List<cve__Payment__c>();
    Map<Id, Date> issueDates;

    Boolean isPeriodicConsolidation = false;
    Boolean isAnyLumpSum;
    cve__Payment__c newPayment;

    Boolean bulkMode;
    Date bulkIssueOverride;
    Period bulkPeriod;
    List<cve__ExplanationOfBenefit__c> performLastEobs = new List<cve__ExplanationOfBenefit__c>();
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec = new Map<Id, List<cve__Payment__c>>();
    // Constructor for interactive (one consolidation only) case
    public ConsolidateAction(
      Map<Id, List<cve__Payment__c>> paymentsPerPaySpec,
      List<cve__Payment__c> payments,
      Map<Id, Date> issueDates
    ) {
      this.payments = payments;
      this.paymentsPerPaySpec = paymentsPerPaySpec;
      this.issueDates = issueDates;
      this.bulkMode = false;

      if (ConsolidatePayments.paymentRecordTypes == null) {
        ConsolidatePayments.paymentRecordTypes = cve__Payment__c.getSObjectType()
          .getDescribe()
          .getRecordTypeInfosByName();
      }

      this.isAnyLumpSum = isAnyLumpSum();
    }

    public String validate(cve__Payment__c p, Boolean isFirst, Boolean isLast) {
      if (payments.size() == 1) {
        return p.Name +
          ' consolidate failed; multiple payments must be selected';
      }
      if (!validStatuses.contains(p.cve__Status__c)) {
        return p.Name +
          ' consolidate failed; only payments with a status of ' +
          new List<String>(validStatuses) +
          ' can be consolidated';
      }

      if (isPeriodic(p)) {
        if (!isConsecutive(p)) {
          return p.Name +
            ' consolidate failed; only consecutive periodic payments can be consolidated';
        }
        if (isAnyLumpSum) {
          return p.Name +
            ' consolidate failed; periodic payments cannot be consolidated with "Lump Sum" payments';
        }
      }
      if (!isCalculated(p) && !isLumpSum(p)) {
        return p.Name +
          ' consolidate failed; only "Calculated" or "Lump Sum" payments can be consolidated';
      }
      if (p.cve__PaymentAssociationsFrom__r.size() > 0) {
        return p.Name +
          ' consolidate failed; this payment has already been consolidated';
      }
      if (p.cve__PaymentAssociationsTo__r.size() > 0) {
        return p.Name +
          ' consolidate failed; this payment is the result of consolidating other payments and multiple levels of consolidation are not supported';
      }
      return null;
    }

    public Boolean isConsecutive(cve__Payment__c p) {
      if (p.cve__Start__c != null && p.cve__Through__c != null) {
        return compareDates(p, payments);
      }
      return false;
    }

    public Boolean compareDates(
      cve__Payment__c p,
      List<cve__Payment__c> payments
    ) {
      for (cve__Payment__c other : payments) {
        if (isCalculated(other)) {
          if (other.cve__Start__c != null && other.cve__Through__c != null) {
            if (
              p.cve__Through__c.addDays(1) == other.cve__Start__c ||
              p.cve__Start__c.addDays(-1) == other.cve__Through__c
            ) {
              return true;
            }
          }
        }
      }
      return false;
    }

    public Boolean isAnyLumpSum() {
      for (cve__Payment__c other : payments) {
        if (isLumpSum(other)) {
          return true;
        }
      }
      return false;
    }

    private Boolean isCalculated(cve__Payment__c p) {
      return p.RecordTypeId ==
        ConsolidatePayments.paymentRecordTypes.get('Calculated')
          .getRecordTypeId();
    }

    private Boolean isLumpSum(cve__Payment__c p) {
      return p.RecordTypeId ==
        ConsolidatePayments.paymentRecordTypes.get('Lump Sum')
          .getRecordTypeId();
    }

    private Boolean isPeriodic(cve__Payment__c p) {
      return isCalculated(p) &&
        isMultiple(
          bulkPeriod != null
            ? bulkPeriod
            : getPeriod(p.cve__PaymentSpecification__r.cve__Period__c)
        );
    }

    public Period getPeriod(String s) {
      if (String.isBlank(s)) {
        return null;
      }

      switch on s.toLowerCase() {
        when 'days', 'day', 'daily' {
          return Period.DAY;
        }
        when 'weeks', 'week', 'weekly' {
          return Period.WEEK;
        }
        when 'months', 'month', 'monthly' {
          return Period.MONTH;
        }
        when 'quarters', 'quarter', 'quarterly' {
          return Period.QUARTER;
        }
        when 'half-years', 'half-year', 'half-yearly' {
          return Period.HALFYEAR;
        }
        when 'years', 'year', 'yearly' {
          return Period.YEAR;
        }
        when 'hours', 'hour', 'hourly' {
          return Period.HOUR;
        }
        when 'bi-weeks', 'bi-week', 'bi-weekly', 'fortnight', 'fortnightly' {
          return Period.BIWEEK;
        }
        when 'semi-months', 'semi-month', 'semi-monthly' {
          return Period.SEMIMONTH;
        }
        when 'lump sums', 'lump sum' {
          return Period.SINGLE;
        }
      }
      return null;
    }

    /**
     * Return true if the period is other than a single period.
     */
    public Boolean isMultiple(Period p) {
      return p != null && !isSingle(p);
    }

    public Boolean isSingle(Period p) {
      return p == Period.Single;
    }

    // Called for each existing Payment being consolidated into the newPayment
    public String perform(
      // cve__Payment__c p,
      Id specId,
      List<cve__Payment__c> upserts,
      Map<cve__Payment__c, cve__Payment__c> existingToNew
    ) {
      newPayment = null;
      for (cve__Payment__c p : paymentsPerPaySpec.get(specId)) {
        // The new Payment is created on the first call
        if (newPayment == null) {
          // If any lump sums amongst the payments (i.e. manual inputs such as under/overpayments) then result is lump sum

          Id rtId = ConsolidatePayments.paymentRecordTypes.get('Calculated')
            .getRecordTypeId();
          for (cve__Payment__c payment : payments) {
            if (
              payment.RecordTypeId ==
              ConsolidatePayments.paymentRecordTypes.get('Lump Sum')
                .getRecordTypeId()
            ) {
              rtId = ConsolidatePayments.paymentRecordTypes.get('Lump Sum')
                .getRecordTypeId();
            }
            if (isPeriodic(payment)) {
              isPeriodicConsolidation = true;
            }
          }

          // Note this will not be connected to an UnallocatedPayment (as they are not consolidated)
          newPayment = new cve__Payment__c(
            RecordTypeId = rtId,
            cve__Claim__c = p.cve__Claim__c,
            cve__Contact__c = p.cve__Contact__c,
            cve__Account__c = p.cve__Account__c,
            cve__PaymentSpecification__c = p.cve__PaymentSpecification__c,
            cve__BenefitClaimed__c = getBenefitClaimedId(p),
            cve__PaymentMethod__c = p.cve__PaymentMethod__c,
            cve__Status__c = 'Approved',
            cve__Start__c = p.cve__Start__c,
            cve__Through__c = p.cve__Through__c,
            cve__Payable__c = Date.today(),
            cve__Issue__c = issueDates != null
              ? issueDates.get(p.Id)
              : p.cve__Issue__c,
            cve__IssueOverride__c = bulkMode
              ? bulkIssueOverride
              : p.cve__IssueOverride__c,
            cve__EmployerMatchingFica__c = p.cve__EmployerMatchingFica__c,
            cve__EmployerMatchingMedicare__c = p.cve__EmployerMatchingMedicare__c,
            cve__FicaTaxableBenefitAmount__c = p.cve__FicaTaxableBenefitAmount__c,
            cve__Net__c = p.cve__Net__c,
            cve__NetAfterTaxes__c = p.cve__NetAfterTaxes__c,
            cve__NetBeforeTaxes__c = p.cve__NetBeforeTaxes__c,
            cve__NumberOfPaymentsConsolidated__c = 1
          );
          copyPayee(p, newPayment);
          upserts.add(newPayment);
        } else {
          // Mins/maxs
          for (
            SObjectField f : new List<SObjectField>{
              cve__Payment__c.cve__Start__c
            }
          ) {
            if (isPeriodicConsolidation) {
              newPayment.put(f, min((Date) newPayment.get(f), (Date) p.get(f)));
            } else {
              newPayment.put(f, max((Date) newPayment.get(f), (Date) p.get(f)));
            }
          }

          // Maxs (and one optional min)
          for (
            SObjectField f : new List<SObjectField>{
              cve__Payment__c.cve__Through__c,
              cve__Payment__c.cve__Payable__c,
              cve__Payment__c.cve__Issue__c,
              cve__Payment__c.cve__IssueOverride__c
            }
          ) {
            Date d;
            if (f == cve__Payment__c.cve__Issue__c && issueDates != null) {
              // Issue date field shows override date so lookup original value
              d = issueDates.get(p.Id);
            } else if (f == cve__Payment__c.cve__IssueOverride__c && bulkMode) {
              // In bulk mode issue override is passed in
              d = bulkIssueOverride;
            } else {
              // Other fields
              d = (Date) p.get(f);
            }
            cve__PaymentCalculationOptions__c cs = cve__PaymentCalculationOptions__c.getInstance();
            Boolean isMinimum =
              f == cve__Payment__c.cve__Through__c &&
              cs.cve__ConsolidatedPayableDateIsMinimum__c;
            Date newDate = isMinimum
              ? min((Date) newPayment.get(f), d)
              : max((Date) newPayment.get(f), d);
            newPayment.put(f, newDate);
          }

          // Sums
          for (
            SObjectField f : new List<SObjectField>{
              cve__Payment__c.cve__EmployerMatchingFica__c,
              cve__Payment__c.cve__EmployerMatchingMedicare__c,
              cve__Payment__c.cve__FicaTaxableBenefitAmount__c,
              cve__Payment__c.cve__Net__c,
              cve__Payment__c.cve__NetAfterTaxes__c,
              cve__Payment__c.cve__NetBeforeTaxes__c
            }
          ) {
            newPayment.put(
              f,
              add((Decimal) newPayment.get(f), (Decimal) p.get(f))
            );
          }

          // Count
          newPayment.cve__NumberOfPaymentsConsolidated__c++;
        }

        p.cve__Status__c = 'Consolidated';
        // This one field change only
        upserts.add(
          new cve__Payment__c(Id = p.Id, cve__Status__c = p.cve__Status__c)
        );
        existingToNew.put(p, newPayment);
      }
      return null;
    }

    public void copyPayee(
      cve__Payment__c fromPayment,
      cve__Payment__c toPayment
    ) {
      if (toPayment.cve__PaymentMethod__c == 'Check') {
        throwMissingFields(validatePayee(fromPayment), toPayment.Name);
      }

      toPayment.cve__PayeeName__c = fromPayment.cve__PayeeName__c;
      toPayment.cve__PayeeClaimRelationshipType__c = fromPayment.cve__PayeeClaimRelationshipType__c;
      toPayment.cve__TaxIdNumber__c = fromPayment.cve__TaxIdNumber__c;
      toPayment.cve__MailingStreet__c = fromPayment.cve__MailingStreet__c;
      toPayment.cve__MailingCity__c = fromPayment.cve__MailingCity__c;
      toPayment.cve__MailingState__c = fromPayment.cve__MailingState__c;
      toPayment.cve__MailingPostalCode__c = fromPayment.cve__MailingPostalCode__c;
      toPayment.cve__MailingCountry__c = fromPayment.cve__MailingCountry__c;
      toPayment.cve__MailingCountryCode__c = fromPayment.cve__MailingCountryCode__c;
      toPayment.cve__MailingStateCode__c = fromPayment.cve__MailingStateCode__c;
      toPayment.cve__BankName__c = fromPayment.cve__BankName__c;
      toPayment.cve__BankPhone__c = fromPayment.cve__BankPhone__c;
      toPayment.cve__BankAccountType__c = fromPayment.cve__BankAccountType__c;
      toPayment.cve__BankRoutingNumber__c = fromPayment.cve__BankRoutingNumber__c;
      toPayment.cve__BankAccountNumber__c = fromPayment.cve__BankAccountNumber__c;

      cve__PaymentCalculationOptions__c cs = cve__PaymentCalculationOptions__c.getInstance();
      String extraContactFieldsToCopy = cs.cve__ExtraPersonFieldsToCopy__c;
      if (extraContactFieldsToCopy != null) {
        Set<String> extraContactFieldsToCopySet = new Set<String>(
          extraContactFieldsToCopy.trim().split('\\s*,\\s*')
        );
        for (String f : extraContactFieldsToCopySet) {
          toPayment.put(f, fromPayment.get(f));
        }
      }
    }

    private List<String> validatePayee(cve__Payment__c payee) {
      List<String> missingFields = new List<String>();

      if (payee.cve__MailingStreet__c == null) {
        missingFields.add(
          cve__Payment__c.cve__MailingStreet__c.getDescribe().getLabel()
        );
      }
      if (payee.cve__MailingCity__c == null) {
        missingFields.add(
          cve__Payment__c.cve__MailingCity__c.getDescribe().getLabel()
        );
      }
      if (payee.cve__MailingState__c == null) {
        missingFields.add(
          cve__Payment__c.cve__MailingState__c.getDescribe().getLabel()
        );
      }
      if (payee.cve__MailingPostalCode__c == null) {
        missingFields.add(
          cve__Payment__c.cve__MailingPostalCode__c.getDescribe().getLabel()
        );
      }
      if (payee.cve__MailingCountry__c == null) {
        missingFields.add(
          cve__Payment__c.cve__MailingCountry__c.getDescribe().getLabel()
        );
      }

      return missingFields;
    }

    private void throwMissingFields(
      List<String> missingFields,
      String copiedFromName
    ) {
      if (missingFields.isEmpty())
        return;

      String missingFieldNames = missingFields.get(0);
      for (Integer i = 1; i < missingFields.size() - 1; i++) {
        missingFieldNames += ', ';
        missingFieldNames += missingFields.get(i);
      }
      if (missingFields.size() > 1) {
        missingFieldNames += ', and ';
        missingFieldNames += missingFields.get(missingFields.size() - 1);
      }

      throw new PaymentCalculatorException(
        'Cannot create a payment with the payee, ' +
          copiedFromName +
          ', because ' +
          missingFieldNames +
          (missingFields.size() > 1 ? ' were ' : ' was ') +
          'not filled in.'
      );
    }

    public Decimal add(Decimal a, Decimal b) {
      if (a != null && b != null) {
        return a + b;
      } else if (a != null) {
        return a;
      } else if (b != null) {
        return b;
      } else {
        return null;
      }
    }

    public Date min(Date d1, Date d2) {
      if (d1 != null && d2 != null) {
        return d1 < d2 ? d1 : d2;
      }
      if (d1 != null) {
        return d1;
      }
      if (d2 != null) {
        return d2;
      }
      return null;
    }

    public Date max(Date d1, Date d2) {
      if (d1 != null && d2 != null) {
        return d1 > d2 ? d1 : d2;
      }
      if (d1 != null) {
        return d1;
      }
      if (d2 != null) {
        return d2;
      }
      return null;
    }
    private Id getBenefitClaimedId(cve__Payment__c p) {
      Id bcId = null;
      for (cve__Payment__c payment : payments) {
        if (
          p.cve__PaymentSpecification__c != null &&
          payment.cve__PaymentSpecification__c != null
        ) {
          if (
            p.cve__PaymentSpecification__c ==
            payment.cve__PaymentSpecification__c
          ) {
            bcId = payment.cve__BenefitClaimed__c;
            break;
          }
        }
      }
      return bcId;
    }

    public void beforeUpsert() {
      // Action inserts an 'Approved' payment but in this case don't want the approval process checking to be done
      // ProcessUtil.disablePaymentApprovalProcessChecking = true;
    }

    public void afterUpsert() {
      // Back to normal
      //   ProcessUtil.disablePaymentApprovalProcessChecking = false;
    }

    public void performLast() {
      List<cve__ExplanationOfBenefit__c> eobs = [
        SELECT
          id,
          isdeleted,
          name,
          recordtypeid,
          createddate,
          createdbyid,
          lastmodifieddate,
          lastmodifiedbyid,
          systemmodstamp,
          cve__payment__c,
          cve__adjustmenttype__c,
          cve__amountperiod__c,
          cve__amount__c,
          cve__code__c,
          cve__coverageclaimed__c,
          cve__description__c,
          cve__interestrate__c,
          cve__ispaymentadjustment__c,
          cve__percentage__c,
          cve__recordtypename__c,
          cve__start__c,
          cve__through__c,
          cve__adjustmentkey__c,
          cve__claimantdob__c,
          cve__claimantname__c,
          cve__note__c,
          recordtype.id,
          recordtype.developername,
          toLabel(recordtype.name)
        FROM cve__ExplanationOfBenefit__c
        WHERE cve__Payment__c IN :getIds(payments)
        WITH SECURITY_ENFORCED
      ];

      // Key is id of old EOB
      Map<Id, cve__ExplanationOfBenefit__c> newEobs = new Map<Id, cve__ExplanationOfBenefit__c>();
      cve__ExplanationOfBenefit__c newEob = new cve__ExplanationOfBenefit__c();
      for (cve__ExplanationOfBenefit__c eob : eobs) {
        if (
          newEob.RecordTypeId != eob.RecordTypeId ||
          newEob.cve__AdjustmentType__c != eob.cve__AdjustmentType__c ||
          !isAdjacent(newEob, eob)
        ) {
          // Separate EOB
          newEob = new cve__ExplanationOfBenefit__c(
            cve__AdjustmentType__c = eob.cve__AdjustmentType__c,
            cve__Amount__c = eob.cve__Amount__c,
            cve__AmountPeriod__c = eob.cve__AmountPeriod__c,
            cve__Description__c = eob.cve__Description__c,
            cve__Payment__c = newPayment.Id,
            RecordTypeId = eob.RecordTypeId,
            cve__Start__c = eob.cve__Start__c,
            cve__Through__c = eob.cve__Through__c
          );
          newEobs.put(eob.Id, newEob);
        } else {
          // Merged EOB
          newEob.cve__Amount__c = add(
            newEob.cve__Amount__c,
            eob.cve__Amount__c
          );
          newEob.cve__Through__c = max(
            newEob.cve__Through__c,
            eob.cve__Through__c
          );
        }
      }

      if (newEobs.size() > 0) {
        // Want to keep the new eobs in the same order as the old EOBs (the old EOB id is the key) so e.g. gross comes first
        List<Id> ids = new List<Id>(newEobs.keySet());
        ids.sort();
        List<cve__ExplanationOfBenefit__c> orderedNewEobs = new List<cve__ExplanationOfBenefit__c>();
        for (Id id : ids) {
          orderedNewEobs.add(newEobs.get(id));
        }
        if (bulkMode) {
          // Calling code will insert
          performLastEobs.addAll(orderedNewEobs);
        } else {
          // Do insert
          insert orderedNewEobs;
        }
      }
    }

    public List<Id> getIds(List<SObject> sobs) {
      List<Id> ids = new List<Id>();
      for (SObject sob : sobs) {
        ids.add(sob.Id);
      }
      return ids;
    }

    private Boolean isAdjacent(
      cve__ExplanationOfBenefit__c eob,
      cve__ExplanationOfBenefit__c nextEob
    ) {
      return eob.cve__Through__c != null &&
        nextEob.cve__Start__c != null &&
        eob.cve__Through__c.addDays(1) == nextEob.cve__Start__c;
    }
  }

  private static void checkForError(String error) {
    if (error != null) {
      throw new cve.Payments.PaymentsException(error);
    }
  }

  // This method is public because it's used also in Beneficiaries.voidOrStopPayments
  public cve__Payment__c[] doWithPayments(
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec,
    cve__Payment__c[] payments,
    Action action
  ) {
    cve__Payment__c[] upserts = new List<cve__Payment__c>{};
    Map<cve__Payment__c, cve__Payment__c> existingToNew = new Map<cve__Payment__c, cve__Payment__c>();
    for (Id id : paymentsPerPaySpec.keySet()) {
      // for (cve__Payment__c p : payments) {
      checkForError(action.perform(Id, upserts, existingToNew));
      //  for(cve__Payment__c p : paymentsPerPaySpec.get(id)){

      //  }
    }

    if (existingToNew.size() > 0 && existingToNew != null) {
      action.beforeUpsert();
      try {
        upsert upserts;
      } finally {
        action.afterUpsert();
      }

      // Some actions require these
      insert createPaymentAssociations(
        paymentsPerPaySpec,
        payments,
        existingToNew
      );

      // Do final operation
      action.performLast();
    }

    return upserts;
  }

  public enum Period {
    // DateUtil relies on the ordinal value of these; do not change the order
    DAY,
    WEEK,
    MONTH,
    YEAR,
    QUARTER,
    HALFYEAR,
    HOUR,
    BIWEEK,
    SEMIMONTH,
    // This represents a single, arbitrary length period; used e.g. for lump sum payments.
    SINGLE
  }

  private List<cve__PaymentAssociation__c> createPaymentAssociations(
    Map<Id, List<cve__Payment__c>> paymentsPerPaySpec,
    cve__Payment__c[] existings,
    Map<cve__Payment__c, cve__Payment__c> existingToNew
  ) {
    List<cve__PaymentAssociation__c> pas = new List<cve__PaymentAssociation__c>();

    // Keep in order by using the list
    for (Id id : paymentsPerPaySpec.keyset()) {
      for (cve__Payment__c existing : paymentsPerPaySpec.get(id)) {
        if (existingToNew.containsKey(existing)) {
          cve__Payment__c newPayment = existingToNew.get(existing);

          cve__PaymentAssociation__c pa = new cve__PaymentAssociation__c();
          pa.cve__FromPayment__c = existing.Id;
          pa.cve__ToPayment__c = newPayment.Id;
          pas.add(pa);
        }
      }
    }
    return pas;
  }
  public class PaymentCalculatorException extends Exception {
  }
}