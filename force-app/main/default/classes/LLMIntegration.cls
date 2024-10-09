public with sharing class LLMIntegration {
    private static final String API_KEY = System.Label.Chat_GPT_API_Key ; 
    private static final String ENDPOINT_URL = 'https://api.groq.com/openai/v1/chat/completions'; 
    private static final String NAMED_CREDENTIAL = 'LLMNamedCredential' ; // Update with your Named Credential name
    

    @AuraEnabled
    public static string generateResponse(String messageText){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT_URL);
        req.setMethod('POST');
        req.setTimeout(1000*120);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + API_KEY);

        String prompt = 'You are a helpful assistant. Your job is to connect to a salesforce org and queries and updates data according to instructions.\nUSer:' + messageText + '\nAssistant:';
        System.debug(prompt);

        Map<String, Object> PromptBody = new Map<String,Object>();
        PromptBody.put('role','user');
        PromptBody.put('content', messageText);

        List <Object> lstPrompts = new List<Object>();
        lstPrompts.add(PromptBody);

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('messages', lstPrompts);
        requestBody.put('model', 'llama3-8b-8192');

        req.setBody(JSON.serialize(requestBody));
        System.debug('Request Body: ' + req.getBody());

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode()== 200 ){
            System.debug(res.getBody());

            Map<String,Object> responseBody = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            List <Object> choices = (List<Object>)responseBody.get('choices');
            if (choices.size() > 0) {
                Map<String, Object> choice = (Map<String, Object>)choices.get(0);
                Map<String,Object> mpMessages = (Map<String,Object>)choice.get('message');

                String responseText = (String)mpMessages.get('content');

                // Check if the response indicates a Salesforce-related action
                if (isSalesforceRelated(responseText)) {
                    return fetchDataFromSalesforce(responseText);
                }
                
                return responseText.trim();
            }
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' ' + res.getStatus());
            throw new ChatGPTException('Error: Unable to generate response from ChatGPT.');
        }

        return '';
    }

    private static Boolean isSalesforceRelated(String query) {
        // Implement your logic to determine if the query is related to Salesforce data
        return query.toLowerCase().contains('salesforce');
    }
    private static String fetchDataFromSalesforce(String query) {
        // Modify the query to match Salesforce's SOQL query language
        String soqlQuery = convertToSOQL(query);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/services/data/v61.0/query?q=' + EncodingUtil.urlEncode(soqlQuery, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody(); // Return the response from Salesforce API
        } else {
            throw new APIException('Failed to fetch org data: ' + res.getStatus());
        }
    }

    private static String convertToSOQL(String query) {
        // Implement logic to convert natural language query to SOQL
        // Example: return 'SELECT Id, Name FROM Account WHERE Name = \'' + query + '\'';
        return 'SELECT Id, Name FROM Account'; // Dummy implementation, replace with actual logic
    }

    public class ChatGPTException extends Exception {}
    public class APIException extends Exception {}


/*
    private static final String CLIENT_ID = '3MVG9pRzvMkjMb6lKfD.pVWEhSm8gMi4QTKpCrXxY6v_hygUG9bpl8WboMFjRcTbEtXsTsGDJ_36FSbjCMglJ'; // Replace with Connected App Client ID
    private static final String CLIENT_SECRET = 'E5BC09F89FCE49016108E8CA723B89BF01258FE40BC4F69EDFEA49969E7E9CB0'; // Replace with Connected App Client Secret
    private static final String CALLBACK_URL = 'https://www.google.co.in/'; // callback URL
    private static final String AUTH_URL = 'https://login.salesforce.com/services/oauth2/token'; // Authorization URL

    // To handle authentication, store the access token and refresh token
    private static String accessToken;
    private static String refreshToken;

    // Method to get access token
    @AuraEnabled
    public static String authenticateToSalesforce() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Prepare OAuth request body
        String requestBody = 'grant_type=password'
            + '&client_id=' + CLIENT_ID
            + '&client_secret=' + CLIENT_SECRET
            + '&username=' + 'YOUR_SALESFORCE_USERNAME' // Salesforce Username
            + '&password=' + 'YOUR_SALESFORCE_PASSWORD' + 'YOUR_SECURITY_TOKEN'; // Salesforce Password + Security Token
        
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            // Parse the response to get the access token
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            accessToken = (String) responseMap.get('access_token');
            refreshToken = (String) responseMap.get('refresh_token');
            return accessToken;
        } else {
            throw new OAuthException('Failed to authenticate with Salesforce: ' + res.getStatus());
        }
    }
    // Method to fetch Salesforce org data/metadata using REST API
    @AuraEnabled
    public static String fetchOrgData(String query) {
        if (accessToken == null) {
            authenticateToSalesforce();
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://your-instance.salesforce.com/services/data/vXX.X/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8')); // Change instance URL and API version
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new APIException('Failed to fetch org data: ' + res.getStatus());
        }
    }

    public class OAuthException extends Exception {}
    public class APIException extends Exception {}
    */
}