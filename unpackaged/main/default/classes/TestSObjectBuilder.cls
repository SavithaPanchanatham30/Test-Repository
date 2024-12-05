public abstract without sharing class TestSObjectBuilder {
  // Contains a map of SObject FieldNames and Values
  protected Map<String, Object> values = new Map<String, Object>();

  protected String SOBJECT_TYPE;
  protected String DEFAULT_SOBJECT_RECORD_TYPE;

  protected Map<String, Schema.RecordTypeInfo> recordTypes = new Map<String, Schema.RecordTypeInfo>();

  protected abstract TestSObjectBuilder cloneBuilder();
  protected abstract void addDefaultFieldsToValuesMap();
  protected abstract void iterate();

  // inherited logic
  public SObject build() {
    SObject sObj = convertValuesToSObject();
    iterate();

    return sObj;
  }

  protected SObject convertValuesToSObject() {
    SObject sobj = (SObject) JSON.deserialize(
      JSON.serialize(values, true),
      Type.forName(SOBJECT_TYPE)
    );
    return sobj;
  }

  public SObject buildAndInsert() {
    SObject sObj = this.build();
    insert sObj;
    return sObj;
  }

  protected void setSObjectAndDefaultRecordType(
    String sObjectType,
    String defaultRecordTypeName
  ) {
    SOBJECT_TYPE = sObjectType;
    DEFAULT_SOBJECT_RECORD_TYPE = defaultRecordTypeName;
  }

  protected void retrieveRecordtypes() {
    if (recordTypes.size() == 0) {
      recordTypes = Schema.describeSObjects(
          new List<String>{ SOBJECT_TYPE },
          SObjectDescribeOptions.DEFERRED
        )[0]
        .getRecordTypeInfosByDeveloperName();
    }
  }

  protected Id getRecordTypeIdByName(String rtName) {
    Schema.RecordTypeInfo rt;

    if (rtName != null && recordTypes?.get(rtName) != null) {
      rt = recordTypes.get(rtName);
    } else {
      //return default ('master') recordtypeId
      rt = recordTypes.values()[0];
    }
    return rt.getRecordTypeId();
  }

  protected Id getDefaultRecordTypeId() {
    Id defaultRecordTypeId = getRecordTypeIdByName(DEFAULT_SOBJECT_RECORD_TYPE);

    return defaultRecordTypeId;
  }
}