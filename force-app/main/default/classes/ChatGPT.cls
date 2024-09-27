public class ChatGPT {
    private static final String ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions'; 
    
    @AuraEnabled
    public static string getChatGPTResult(String searchTerm) {
        System.debug('Received search term: ' + searchTerm); // Debug the input search term
        String searchQueryEscape = String.isNotBlank(searchTerm) ? searchTerm.trim() : '';
        System.debug('Search term after escaping: ' + searchQueryEscape);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT);
        request.setHeader('Authorization', 'Bearer ' + System.Label.Chat_GPT_API_Key);
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>(); 
        List<Map<String, String>> messagesList = new List<Map<String, String>>();
        
        Map<String, String> message = new Map<String, String>();
        message.put('role', 'user');
        message.put('content', searchQueryEscape);
        messagesList.add(message);

        requestBody.put('messages', messagesList);
        requestBody.put('model', 'llama3-8b-8192'); 

        String reqBody = JSON.serialize(requestBody);
        System.debug('Request body being sent to GPT API: ' + reqBody); // Debug the request body

        request.setBody(reqBody);
        request.setMethod('POST');

        Http http = new Http();
        HttpResponse resp;
        try {
            resp = http.send(request);
            System.debug('Received GPT Response: ' + resp.getBody()); // Debug the API response
        } catch (Exception e) {
            System.debug('Error sending request to GPT API: ' + e.getMessage());
            return 'Error in GPT API request: ' + e.getMessage();
        }
        
        return resp.getBody();  
    }
}