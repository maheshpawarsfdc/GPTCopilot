public class ChatGPT {
    private static final String ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions'; 

    @AuraEnabled
    public static string getChatGPTResult(String searchTerm) {
        String searchQueryEscape = String.isNotBlank(searchTerm) ? searchTerm.trim() : '';

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
        requestBody.put('model', 'llama3-8b-8192');  // Adjust model if necessary

        String reqBody = JSON.serialize(requestBody);
        request.setBody(reqBody);
        request.setMethod('POST');

        Http http = new Http();
        HttpResponse resp;

        try {
            resp = http.send(request);
            if (resp.getStatusCode() == 200) {
                return parseResponse(resp.getBody()); // Parse and return natural language response
            } else if (resp.getStatusCode() == 429) {  // API rate limit
                return 'API rate limit exceeded. Please try again later.';
            } else {
                return 'API Error: ' + resp.getStatusCode() + ' - ' + resp.getBody();
            }
        } catch (Exception e) {
            return 'Error in GPT API request: ' + e.getMessage();
        }
    }

    private static String parseResponse(String responseBody) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        if (jsonResponse.containsKey('choices')) {
            List<Object> choices = (List<Object>) jsonResponse.get('choices');
            if (!choices.isEmpty()) {
                Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                if (firstChoice.containsKey('message')) {
                    Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                    return (String) message.get('content');  // Return message content
                }
            }
        }
        return 'No valid response from API.';
    }
}
