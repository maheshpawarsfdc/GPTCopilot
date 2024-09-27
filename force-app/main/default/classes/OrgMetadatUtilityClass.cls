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
public static String getApexClass(){
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
    // Convert the criteria to the appropriate field to query against (Name by default)
    String queryField = 'Name'; // Assuming you want to search by Name

    // Safely construct the dynamic SOQL query with escaped criteria
    String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE ' + queryField + ' = \'' + String.escapeSingleQuotes(criteria) + '\'';

    List<SObject> records = Database.query(query);

    if (records.isEmpty()) {
        return new Map<String, Object>{'Message' => 'No records found'};
    } else {
        return records[0].getPopulatedFieldsAsMap(); // Return the first record's fields as a Map
    }
}

    
}