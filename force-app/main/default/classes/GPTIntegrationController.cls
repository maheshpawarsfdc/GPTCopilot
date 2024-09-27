public with sharing class GPTIntegrationController {

    @AuraEnabled
    public static String processQuery(String userQuery) {
        System.debug('Received Query: ' + userQuery); // Debug to check received query
        String response;
        
        try {
            // Determine if the query is related to Salesforce metadata or objects
            if (userQuery.contains('Apex classes') || userQuery.contains('Apex triggers')) {
                response = getMetadataInfo(userQuery);
            } else if (userQuery.toLowerCase().contains('fetch details for') || userQuery.toLowerCase().contains('get details for')) {
                response = getRecordDetails(userQuery);
            } else {
                // Call LLM API to process general NLP queries
                response = getGPTResponse(userQuery);
            }
        } catch (Exception e) {
            System.debug('Error in processQuery: ' + e.getMessage());
            return 'Error processing query: ' + e.getMessage();
        }
        
        System.debug('Returning Response: ' + response); // Debug the final response
        return response;
    }
    
    @AuraEnabled
    public static String getMetadataInfo(String query) {
        System.debug('Metadata Query Received: ' + query);
        try {
            if (query.contains('How many Apex classes')) {
                Integer classCount = OrgMetadatUtilityClass.getApexClassCount();
                return 'There are ' + classCount + ' Apex classes in your org.';
            } else if (query.contains('all Apex classes')) {
                String cls = OrgMetadatUtilityClass.getApexClass();
                return cls;
            } else if (query.contains('How many Apex triggers')) {
                Integer triggerCount = OrgMetadatUtilityClass.getApexTriggerCount();
                return 'There are ' + triggerCount + ' Apex triggers in your org.';
            } else {
                return 'I cannot find information related to your query.';
            }
        } catch (Exception e) {
            System.debug('Error in getMetadataInfo: ' + e.getMessage());
            return 'Error fetching metadata info: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String getRecordDetails(String query) {
        System.debug('Record Query Received: ' + query);
        try {
            // Extract object and criteria using regex
            Pattern pattern = Pattern.compile('(?i)(fetch|get) details for (\\w+) with (.+)');  // Using (?i) for case insensitivity
            Matcher matcher = pattern.matcher(query);
            
            if (matcher.find()) {
                String objectApiName = matcher.group(2);  // Extracted object name
                String criteria = matcher.group(3).trim();        // Extracted criteria
                // Remove quotes from criteria if they exist
            if (criteria.startsWith('"') && criteria.endsWith('"')) {
                criteria = criteria.substring(1, criteria.length() - 1);
            }
    
                System.debug('Fetching record for Object: ' + objectApiName + ', Criteria: ' + criteria);
    
                // Validate the object API name
                if (!isValidObject(objectApiName)) {
                    return 'Invalid object name: ' + objectApiName;
                }
    
                // Fetch record details based on the extracted criteria
                Map<String, Object> record = OrgMetadatUtilityClass.getRecordDetails(objectApiName, criteria);
                System.debug('Record Fetched: ' + JSON.serializePretty(record));
                return 'Record Details: ' + JSON.serializePretty(record);
            } else {
                return 'Could not parse the query. Please specify in the format: "Fetch details for [Object] with [Criteria]"';
            }
        } catch (Exception e) {
            System.debug('Error in getRecordDetails: ' + e.getMessage());
            return 'Error fetching record details: ' + e.getMessage();
        }
    }
    
    // Helper method to validate if the object is a valid Salesforce object
    private static Boolean isValidObject(String objectApiName) {
        // You can implement logic to check if the objectApiName is a valid Salesforce object
        Set<String> validObjects = new Set<String>{'Account', 'Opportunity', 'Contact', 'Lead'}; // Extend this as needed
        return validObjects.contains(objectApiName);
    }
    

    @AuraEnabled
    public static String getGPTResponse(String userQuery) {
        System.debug('GPT Query Received: ' + userQuery);
        try {
            String gptResult = ChatGPT.getChatGPTResult(userQuery);
            System.debug('GPT Result: ' + gptResult);
            return gptResult;
        } catch (Exception e) {
            System.debug('Error in getGPTResponse: ' + e.getMessage());
            return 'Error processing GPT response: ' + e.getMessage();
        }
    }
}