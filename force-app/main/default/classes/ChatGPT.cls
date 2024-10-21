public class ChatGPT {
    private static final String NAMED_CREDENTIAL = 'LLM_API'; // Use your Named Credential name

    @AuraEnabled
    public static List<Map<String, Object>> processQuery(String userQuery) {
        System.debug('User Query: ' + userQuery); // Log the user query

        // Call LLM and get the response
        String llmResponse = getResponseFromLLM(userQuery);
        System.debug('LLM Response: ' + llmResponse); // Log the response from LLM

        // Extract the full query from the LLM response
        String extractedQuery = extractQueryFromContent(llmResponse);
        System.debug('Extracted Query: ' + extractedQuery); // Log the extracted query

        // If the extracted query is empty, throw an exception
        if (String.isEmpty(extractedQuery)) {
            throw new AuraHandledException('No valid query extracted from LLM response.');
        }

        // Check if it's a SOQL or SOSL query
        if (extractedQuery.toLowerCase().startsWith('select')) {
            // Execute the SOQL query
            if (!isValidSOQLQuery(extractedQuery)) {
                throw new AuraHandledException('Invalid SOQL query format.');
            }
            return executeSoqlQuery(extractedQuery);
        } else if (extractedQuery.toLowerCase().startsWith('find')) {
            // Execute the SOSL query
            return executeSoslQuery(extractedQuery);
        } else {
            throw new AuraHandledException('Unsupported query type returned from LLM.');
        }
    }

    private static String getResponseFromLLM(String userQuery) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL); // Adjust the path to your LLM endpoint
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + System.Label.Chat_GPT_API_Key);

        Map<String, Object> requestBody = new Map<String, Object>();
        List<Map<String, String>> messagesList = new List<Map<String, String>>();

        String prompt = 'You are a Salesforce expert. Based on the user question, generate ONLY a valid SOQL query to retrieve data from Salesforce, using standard or custom objects if applicable. ' +
            'Include commonly accessed fields like Id, Name, and IsDeleted when relevant. If the user asks for filtering, sorting, or counting, add WHERE, ORDER BY, or COUNT clauses as needed. ' +
            'Ensure the output starts with SELECT or FIND and ends with the appropriate SOQL or SOSL structure. Do NOT add any extra explanation, comments, or symbols after the query. ' +
            'The generated query should be compatible with the Salesforce query editor. Example scenarios include: ' +
            '1. User: Show me all open cases. Assistant: SELECT Id, Subject, Status, IsDeleted FROM Case WHERE Status = \'Open\'. ' +
            '2. User: List opportunities closed this year. Assistant: SELECT Id, Name, CloseDate, IsDeleted FROM Opportunity WHERE CloseDate = THIS_YEAR. ' +
            '3. User: Get all accounts in New York. Assistant: SELECT Id, Name, BillingState, IsDeleted FROM Account WHERE BillingState = \'NY\'. ' +
            '4. User: How many contacts are there in the system? Assistant: SELECT COUNT() FROM Contact. ' +
            '5. User: Count all closed won opportunities this quarter. Assistant: SELECT COUNT() FROM Opportunity WHERE IsWon = TRUE AND CloseDate = THIS_QUARTER. ' +
            '6. User: Get the total number of leads created this month. Assistant: SELECT COUNT() FROM Lead WHERE CreatedDate = THIS_MONTH. ' +
            '7. User: List accounts and sort them by last modified date. Assistant: SELECT Id, Name, LastModifiedDate, IsDeleted FROM Account ORDER BY LastModifiedDate DESC. ' +
            'Question: ' + userQuery;

        // Add user message with prompt
        messagesList.add(new Map<String, String>{ 'role' => 'user', 'content' => prompt });

        requestBody.put('messages', messagesList);
        requestBody.put('model', 'llama3-8b-8192');  // Adjust model if necessary

        String reqBody = JSON.serialize(requestBody);
        request.setBody(reqBody);
        request.setMethod('POST');

        System.debug('Request body for LLM: ' + reqBody);

        Http http = new Http();
        HttpResponse resp;
        try {
            resp = http.send(request);
            System.debug('LLM Response Status Code: ' + resp.getStatusCode());
            System.debug('LLM Response Body: ' + resp.getBody());

            if (resp.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                List<Object> choicesList = (List<Object>) responseMap.get('choices');
                if (!choicesList.isEmpty()) {
                    Map<String, Object> firstChoice = (Map<String, Object>) choicesList[0];
                    Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                    return (String) message.get('content');
                } else {
                    throw new AuraHandledException('No valid response from LLM.');
                }
            } else {
                throw new AuraHandledException('API Error: ' + resp.getStatusCode() + ' - ' + resp.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error in GPT API request: ' + e.getMessage());
        }
    }

    private static String extractQueryFromContent(String llmResponse) {
        // Assuming the response is a plain text string that contains the query
        // You may want to apply additional parsing logic based on your LLM's response structure
        return llmResponse; // Modify as per the actual response format
    }

    private static Boolean isSalesforceSpecific(String response) {
        String lowerCaseResponse = response.toLowerCase();
        return lowerCaseResponse.contains('select') || lowerCaseResponse.contains('find');
    }

    private static List<Map<String, Object>> executeSoqlQuery(String content) {
        System.debug('Executing SOQL Query: ' + content);
        List<SObject> records;
        try {
            records = Database.query(content);
            System.debug('Number of records returned: ' + records.size());
        } catch (QueryException e) {
            throw new AuraHandledException('Error executing SOQL query: ' + e.getMessage());
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            for (String fieldName : record.getSObjectType().getDescribe().fields.getMap().keySet()) {
                try {
                    recordMap.put(fieldName, record.get(fieldName));
                } catch (Exception e) {
                    // Optionally handle inaccessible fields differently
                }
            }
            result.add(recordMap);
        }

        return result;
    }

    private static Boolean isValidSOQLQuery(String query) {
        String lowerCaseQuery = query.toLowerCase().trim();
        return lowerCaseQuery.startsWith('select') && lowerCaseQuery.contains('from');
    }

    private static List<Map<String, Object>> executeSoslQuery(String soslQuery) {
        List<List<SObject>> searchResults;
        try {
            searchResults = Search.query(soslQuery);
            if (searchResults.isEmpty()) {
                throw new AuraHandledException('No results found for the SOSL query.');
            }
        } catch (SearchException e) {
            throw new AuraHandledException('Error executing SOSL query: ' + e.getMessage());
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : searchResults[0]) {
            Map<String, Object> recordMap = new Map<String, Object>();
            for (String fieldName : record.getSObjectType().getDescribe().fields.getMap().keySet()) {
                try {
                    recordMap.put(fieldName, record.get(fieldName));
                } catch (Exception e) {
                    // Optionally handle inaccessible fields differently
                }
            }
            result.add(recordMap);
        }

        return result;
    }

    private static List<Map<String, Object>> handleGeneralQuery(String userResponse) {
        System.debug('Handling general response: ' + userResponse);
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        Map<String, Object> generalResponse = new Map<String, Object>();
        generalResponse.put('response', 'General response: ' + userResponse);
        response.add(generalResponse);
        return response;
    }
}
