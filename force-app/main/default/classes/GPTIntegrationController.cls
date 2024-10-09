public with sharing class GPTIntegrationController { 

    @AuraEnabled
    public static Object processQuery(String userQuery, String conversationHistory) {  // Change return type to Object for flexibility
        try {// Check for specific Salesforce-related queries
            if (userQuery.toLowerCase().contains('apex classes') || userQuery.toLowerCase().contains('apex triggers')) {
                return getMetadataInfo(userQuery);
            } else if (userQuery.toLowerCase().contains('fetch details for') || userQuery.toLowerCase().contains('get details for')) {
                return getRecordDetails(userQuery);
            } else {
                // Keep the existing functionality
                return getGPTResponse(userQuery, conversationHistory);
            }
        } catch (Exception e) {
            return 'Error processing query: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String getMetadataInfo(String query) {
        try {
            if (query.toLowerCase().contains('how many apex classes')) {
                Integer classCount = OrgMetadatUtilityClass.getApexClassCount();
                return 'There are ' + classCount + ' apex classes in your org.';
            } else if (query.toLowerCase().contains('all apex classes')) {
                return OrgMetadatUtilityClass.getApexClass();
            } else if (query.toLowerCase().contains('how many apex triggers')) {
                Integer triggerCount = OrgMetadatUtilityClass.getApexTriggerCount();
                return 'There are ' + triggerCount + ' apex triggers in your org.';
            } else {
                return 'I cannot find information related to your query.';
            }
        } catch (Exception e) {
            return 'Error fetching metadata info: ' + e.getMessage();
        }
    }

    @AuraEnabled
public static String getRecordDetails(String query) {
    String response = '';  // Initialize response as an empty string

    try {
        // Updated regex pattern for capturing object, field, and value
        Pattern pattern = Pattern.compile('(?i)(fetch|get) details for (\\w+) with (\\w+)=(.+)');
        Matcher matcher = pattern.matcher(query);

        if (matcher.find()) {
            String objectApiName = matcher.group(2);  // Object name
            String fieldName = matcher.group(3);      // Field name
            String fieldValue = matcher.group(4).trim();  // Field value

            // Validate the object name
            if (!isValidObject(objectApiName)) {
                return 'Invalid object name: ' + objectApiName;
            }

            // Get the fields of the object dynamically
            DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            
            // Create a list of all field names
            List<String> fieldNames = new List<String>();
            for (String key : fieldsMap.keySet()) {
                fieldNames.add(key);
            }
            
            // Build the SOQL query with all fields
            String soqlQuery = 'SELECT ' + String.join(fieldNames, ', ') + 
                               ' FROM ' + objectApiName + 
                               ' WHERE ' + fieldName + ' = :fieldValue';

            // Execute the query
            List<SObject> records = Database.query(soqlQuery);

            if (records.isEmpty()) {
                return 'No records found for ' + objectApiName + ' where ' + fieldName + ' = ' + fieldValue;
            } else {
                response += 'Record Details:\n';

                // Loop through all records and format each record's fields
                for (SObject record : records) {
                    Map<String, Object> recordDetails = record.getPopulatedFieldsAsMap();

                    // Loop through each field and its value in the record
                    for (String fieldKey : recordDetails.keySet()) {
                        String fieldLabel = fieldsMap.get(fieldKey).getDescribe().getLabel();
                        Object fieldValueOutput = recordDetails.get(fieldKey);
                        response += fieldLabel + ': ' + fieldValueOutput + '\n'; // Use string concatenation
                    }

                    response += '\n';  // Add a blank line between records
                }


                
                return response.trim(); // Return the formatted response string
            }
        } else {
            return 'Could not parse the query. Please use the format: "Fetch details for [Object] with [Field]=[Value]"';
        }
    } catch (Exception e) {
        return 'Error fetching record details: ' + e.getMessage();
    }
}


    // Use Schema to validate object names dynamically
    private static Boolean isValidObject(String objectApiName) {
        Map<String, Schema.SObjectType> sObjectTypes = Schema.getGlobalDescribe();
        return sObjectTypes.containsKey(objectApiName);
    }

    // Use Schema to validate field names dynamically
    private static Boolean isValidField(String objectApiName, String fieldName) {
        Map<String, Schema.SObjectType> sObjectTypes = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescribe = sObjectTypes.get(objectApiName).getDescribe();
        Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();
        return fields.containsKey(fieldName);
    }

    @AuraEnabled
    public static String getGPTResponse(String userQuery, String conversationHistory) {
        try {
            return ChatGPT.getChatGPTResult(userQuery, conversationHistory);
        } catch (Exception e) {
            return 'Error processing GPT response: ' + e.getMessage();
        }
    }
}
