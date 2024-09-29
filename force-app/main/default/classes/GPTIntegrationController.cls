public with sharing class GPTIntegrationController {

    @AuraEnabled
    public static String processQuery(String userQuery) {
        String response;

        try {
            if (userQuery.contains('Apex classes') || userQuery.contains('Apex triggers')) {
                response = getMetadataInfo(userQuery);
            } else if (userQuery.toLowerCase().contains('fetch details for') || userQuery.toLowerCase().contains('get details for')) {
                response = getRecordDetails(userQuery);
            } else {
                response = getGPTResponse(userQuery);
            }
        } catch (Exception e) {
            return 'Error processing query: ' + e.getMessage();
        }

        return response;
    }

    @AuraEnabled
    public static String getMetadataInfo(String query) {
        try {
            if (query.contains('How many Apex classes')) {
                Integer classCount = OrgMetadatUtilityClass.getApexClassCount();
                return 'There are ' + classCount + ' Apex classes in your org.';
            } else if (query.contains('all Apex classes')) {
                return OrgMetadatUtilityClass.getApexClass();
            } else if (query.contains('How many Apex triggers')) {
                Integer triggerCount = OrgMetadatUtilityClass.getApexTriggerCount();
                return 'There are ' + triggerCount + ' Apex triggers in your org.';
            } else {
                return 'I cannot find information related to your query.';
            }
        } catch (Exception e) {
            return 'Error fetching metadata info: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String getRecordDetails(String query) {
        try {
            Pattern pattern = Pattern.compile('(?i)(fetch|get) details for (\\w+) with (.+)');
            Matcher matcher = pattern.matcher(query);

            if (matcher.find()) {
                String objectApiName = matcher.group(2);
                String criteria = matcher.group(3).trim();

                if (!isValidObject(objectApiName)) {
                    return 'Invalid object name: ' + objectApiName;
                }

                Map<String, Object> record = OrgMetadatUtilityClass.getRecordDetails(objectApiName, criteria);
                return 'Record Details: ' + JSON.serializePretty(record);
            } else {
                return 'Could not parse the query. Please use the format: "Fetch details for [Object] with [Criteria]"';
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

    @AuraEnabled
    public static String getGPTResponse(String userQuery) {
        try {
            return ChatGPT.getChatGPTResult(userQuery);
        } catch (Exception e) {
            return 'Error processing GPT response: ' + e.getMessage();
        }
    }
}
