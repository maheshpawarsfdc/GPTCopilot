public class ChatGPT {
    private static final String NAMED_CREDENTIAL = 'LLM_API'; // Use your Named Credential name

    @AuraEnabled
    public static List<Map<String, Object>> processQuery(String userQuery) {
        System.debug('User Query: ' + userQuery); // Log the user query

        // Call LLM and get the response
        String llmResponse = getResponseFromLLM(userQuery);
        System.debug('LLM Response: ' + llmResponse); // Log the response from LLM

        // Check if the response indicates a Salesforce-specific query
        if (isSalesforceSpecific(llmResponse)) {
            // Extract the SOQL query from the LLM's response
            String soqlQuery = extractSOQLFromContent(llmResponse);
            System.debug('Generated SOQL Query: ' + soqlQuery); // Log the generated SOQL query

            if (String.isEmpty(soqlQuery)) {
                System.debug('SOQL query is empty, cannot execute.'); // Log empty SOQL query scenario
                throw new AuraHandledException('No valid SOQL query returned from LLM.');
            }
            // Validate the SOQL query before execution
            if (!isValidSOQLQuery(soqlQuery)) {
                throw new AuraHandledException('Invalid SOQL query format.');
            }

            // Execute the SOQL query and convert it to a list of maps
            return executeSoqlQuery(soqlQuery);
        } else {
            System.debug('Handling as a general query'); // Log handling general response
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
        String prompt = 'You are a Salesforce expert. Based on the user question, respond with ONLY a valid SOQL query if the question is about Salesforce data retrieval. Include commonly accessed fields like IsDeleted if relevant. Do NOT add any extra explanation. For example: User: Can you give me the details of the accounts in Salesforce? Assistant: SELECT Id, Name, IsDeleted, Industry FROM Account. Make SOQL OR SOSL query based on condition. AND dont put any extra symbols after the query. it should be compatible enough to use in query editor. Question: ' + userQuery;

        // Add user message with prompt
        messagesList.add(new Map<String, String>{ 'role' => 'user', 'content' => prompt });

        requestBody.put('messages', messagesList);
        requestBody.put('model', 'llama3-8b-8192');  // Adjust model if necessary

        String reqBody = JSON.serialize(requestBody);
        request.setBody(reqBody);
        request.setMethod('POST');

        System.debug('Request body for LLM: ' + reqBody); // Log the request body

        Http http = new Http();
        HttpResponse resp;

        try {
            resp = http.send(request);
            System.debug('LLM Response Status Code: ' + resp.getStatusCode()); // Log status code
            System.debug('LLM Response Body: ' + resp.getBody()); // Log the response body

            if (resp.getStatusCode() == 200) {
               // Parse the JSON response to extract the content
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            List<Object> choicesList = (List<Object>) responseMap.get('choices');

            if (!choicesList.isEmpty()) {

                Map<String, Object> firstChoice = (Map<String, Object>) choicesList[0];
                Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                String content = (String) message.get('content'); // Extracting the content

                // Extract only the SOQL query from the content
                String soqlQuery = extractSOQLFromContent(content);
                return soqlQuery; // Return the extracted SOQL query
            } else {
                System.debug('No choices found in the LLM response.');
                throw new AuraHandledException('No valid response from LLM.');
            }
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
        String lowerCaseResponse = response.toLowerCase();
        return lowerCaseResponse.contains('soql') || lowerCaseResponse.contains('account') ||
        lowerCaseResponse.contains('contact') || lowerCaseResponse.contains('lead') ||
        lowerCaseResponse.contains('case'); // Add more keywords as necessary
    }

    private static String extractSOQLFromContent(String content) {
        System.debug('Extracting SOQL Query from LLM Response: ' + content); // Log the LLM response before processing
    
        
        Pattern soqlPattern = Pattern.compile('(?i)(select\\s+.*?\\s+from\\s+\\w+)(\\s+where\\s+.*)?');
        Matcher matcher = soqlPattern.matcher(content.trim());
        
    
        if (matcher.find()) {
            String baseQuery = matcher.group(1).trim(); // Get the matched SOQL query
            String whereClause = matcher.group(2) != null ? matcher.group(2).trim() : ''; // Get the WHERE clause if present
    
            // Combine base query with the WHERE clause if it exists
            return baseQuery + (String.isEmpty(whereClause) ? '' : ' ' + whereClause);
        } else {
            System.debug('No valid SOQL query found in the response content.');
            throw new AuraHandledException('No valid SOQL query returned from LLM content.');
        }
    }

private static Boolean isValidSOQLQuery(String query) {
    // Basic validation to check if the query starts with SELECT and contains FROM
    String lowerCaseQuery = query.toLowerCase().trim();
    return lowerCaseQuery.startsWith('select') && lowerCaseQuery.contains('from');
}
    

    private static List<Map<String, Object>> executeSoqlQuery(String soqlQuery) {
        if (String.isEmpty(soqlQuery)) {
            System.debug('No valid SOQL query could be extracted. LLM response might be conversational.');
            throw new AuraHandledException('The generated SOQL query is empty.');
        }

        List<SObject> records;
        try {
            records = Database.query(soqlQuery);
            System.debug('Number of records returned: ' + records.size()); // Log the number of records returned
        } catch (QueryException e) {
            System.debug('Error executing SOQL query: ' + e.getMessage()); // Log query execution error
            throw new AuraHandledException('Error executing SOQL query: ' + e.getMessage());
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            for (String fieldName : record.getSObjectType().getDescribe().fields.getMap().keySet()) {
                try {
                    recordMap.put(fieldName, record.get(fieldName));
                } catch (Exception e) {
                    System.debug('Field access error: ' + e.getMessage() + ' for field: ' + fieldName);
                    // Optionally, skip this field or handle it differently
                }
            }
            result.add(recordMap);
        }

        return result;
    }

    private static List<Map<String, Object>> handleGeneralQuery(String userResponse) {
        System.debug('Handling general response: ' + userResponse); // Log the general response handling
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        Map<String, Object> generalResponse = new Map<String, Object>();
        generalResponse.put('response', 'General response: ' + userResponse);
        response.add(generalResponse);
        return response;
    }
}
