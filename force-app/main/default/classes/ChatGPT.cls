public class ChatGPT {
    private static final String NAMED_CREDENTIAL = 'LLM_API'; // Use your Named Credential name

    @AuraEnabled
    public static List<Map<String, Object>> processQuery(String userQuery) {
        System.debug('User Query: ' + userQuery); // Log the user query

        // Call LLM and get the response
        String llmResponse = getResponseFromLLM(userQuery);
        
        // Check if the response indicates a Salesforce-specific query
        if (isSalesforceSpecific(llmResponse)) {
            // Extract the SOQL query from the LLM's response
            String soqlQuery = extractSOQLQuery(llmResponse);
            System.debug('Generated SOQL Query: ' + soqlQuery); // Log the generated SOQL query

            if (String.isEmpty(soqlQuery)) {
                throw new AuraHandledException('No valid SOQL query returned from LLM.');
            }

            // Execute the SOQL query and convert it to a list of maps
            return executeSoqlQuery(soqlQuery);
        } else {
            // Handle general queries
            return handleGeneralQuery(llmResponse);
        }
    }

    private static String getResponseFromLLM(String userQuery) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL); // Adjust the path to your LLM endpoint
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + System.Label.Chat_GPT_API_Key);

        Map<String, Object> requestBody = new Map<String, Object>();
        List<Map<String, String>> messagesList = new List<Map<String, String>>();

        // Improved prompt with context and user query
        String prompt = 'You are a Salesforce expert. Based on the user\'s question, provide either a valid SOQL query or a general response. For example: User: Can you give me the details of the accounts in Salesforce? Assistant: Here is the SOQL query to retrieve all account details: SELECT Id, Name, Industry FROM Account. Question: ' + userQuery;

        // Add user message with prompt
        Map<String, String> message = new Map<String, String>();
        message.put('role', 'user');
        message.put('content', prompt);
        messagesList.add(message);

        requestBody.put('messages', messagesList);
        requestBody.put('model', 'llama3-8b-8192');  // Adjust model if necessary

        String reqBody = JSON.serialize(requestBody);
        request.setBody(reqBody);
        request.setMethod('POST');

        Http http = new Http();
        HttpResponse resp;

        try {
            resp = http.send(request);
            if (resp.getStatusCode() == 200) {
                return resp.getBody(); // Return the full response for processing
            } else {
                System.debug('API Error: ' + resp.getStatusCode() + ' - ' + resp.getBody()); // Log API error
                throw new AuraHandledException('API Error: ' + resp.getStatusCode() + ' - ' + resp.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in GPT API request: ' + e.getMessage()); // Log exception message
            throw new AuraHandledException('Error in GPT API request: ' + e.getMessage());
        }
    }

    private static Boolean isSalesforceSpecific(String response) {
        // Check for keywords or patterns indicating Salesforce specificity
        String lowerCaseResponse = response.toLowerCase();
        return lowerCaseResponse.contains('soql') || lowerCaseResponse.contains('account') ||
               lowerCaseResponse.contains('contact') || lowerCaseResponse.contains('lead') ||
               lowerCaseResponse.contains('case'); // Add more keywords as necessary
    }

    private static String extractSOQLQuery(String response) {
        // Parse the response to extract the SOQL query
        String soqlQuery = ''; // Initialize empty SOQL query

        // Basic extraction logic (you may need to adjust this based on your LLM response structure)
        // Assuming the response is formatted like: "Assistant: Here is the SOQL query: SELECT Id, Name FROM Account"
        Pattern soqlPattern = Pattern.compile('Assistant: Here is the SOQL query: (SELECT .*?)(?=\\.|$)'); // Removed flags
        Matcher matcher = soqlPattern.matcher(response);
        
        if (matcher.find()) {
            soqlQuery = matcher.group(1).trim(); // Get the matched SOQL query
        }

        if (String.isEmpty(soqlQuery)) {
            System.debug('No valid SOQL query extracted from response: ' + response); // Log invalid response
        }

        return soqlQuery;
    }

    private static List<Map<String, Object>> executeSoqlQuery(String soqlQuery) {
        if (String.isEmpty(soqlQuery)) {
            throw new AuraHandledException('The generated SOQL query is empty.');
        }

        List<SObject> records;
        try {
            records = Database.query(soqlQuery);
        } catch (QueryException e) {
            System.debug('Error executing SOQL query: ' + e.getMessage()); // Log query execution error
            throw new AuraHandledException('Error executing SOQL query: ' + e.getMessage());
        }

        // Convert the SObject records to a List<Map<String, Object>>
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            for (String fieldName : record.getSObjectType().getDescribe().fields.getMap().keySet()) {
                recordMap.put(fieldName, record.get(fieldName));
            }
            result.add(recordMap);
        }

        return result; // Return the list of maps
    }

    // Handle general queries
    private static List<Map<String, Object>> handleGeneralQuery(String userResponse) {
        // Here, you could return a static message or implement logic to provide general responses
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        Map<String, Object> generalResponse = new Map<String, Object>();
        generalResponse.put('response', 'General response: ' + userResponse);
        response.add(generalResponse);
        return response;
    }
}
