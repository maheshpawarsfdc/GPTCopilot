public with sharing class OrgMetadatUtilityClass {
    
    @AuraEnabled
    public static Integer getApexClassCount() {
        try {
            // Query to get the count of Apex classes
            Integer count = [SELECT Count() FROM ApexClass];
            return count;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Apex Class count: ' + e.getMessage());   
        }
    }

    @AuraEnabled
    public static String getApexClass() {
        try {
            List<ApexClass> cls = [SELECT Name FROM ApexClass];
            List<String> classNames = new List<String>();
            for(ApexClass c : cls) {
                classNames.add(c.Name);
            }
            return String.join(classNames, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Apex Class: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer getApexTriggerCount() {
        try {
            // Query to get the count of Apex triggers
            Integer count = [SELECT Count() FROM ApexTrigger];
            return count;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Apex Trigger count: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> getRecordDetails(String objectApiName, String criteria) {
        // Validate if object exists and is accessible
        if (!Schema.getGlobalDescribe().containsKey(objectApiName)) {
            throw new AuraHandledException('Invalid object: ' + objectApiName);
        }

        DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        if (!describeResult.isAccessible()) {
            throw new AuraHandledException('No access to object: ' + objectApiName);
        }

        // Get all fields from the object dynamically
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        List<String> fieldNames = new List<String>();
        for (String fieldName : fieldsMap.keySet()) {
            fieldNames.add(fieldName);
        }
        
        // Construct dynamic SOQL with all fields
        String soqlQuery = 'SELECT ' + String.join(fieldNames, ', ') + 
                           ' FROM ' + objectApiName + 
                           ' WHERE Name = :criteria';  // Assuming 'Name' is the search field; this can be made dynamic if needed
        
        List<SObject> records = Database.query(soqlQuery);

        if (records.isEmpty()) {
            return new Map<String, Object>{'Message' => 'No records found'};
        } else {
            // Return the first record's fields as a Map
            return records[0].getPopulatedFieldsAsMap();
        }
    }
}
