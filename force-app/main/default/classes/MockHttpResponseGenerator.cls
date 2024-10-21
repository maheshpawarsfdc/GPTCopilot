public class MockHttpResponseGenerator implements HttpCalloutMock {
    private Boolean isSOQL;
    private Boolean shouldFail;

    public MockHttpResponseGenerator(Boolean isSOQL, Boolean shouldFail) {
        this.isSOQL = isSOQL;
        this.shouldFail = shouldFail;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        if (shouldFail) {
            res.setStatusCode(400);
            res.setBody('{"error": "API Error"}');
        } else {
            res.setStatusCode(200);
            if (isSOQL) {
                res.setBody('{"choices": [{"message": {"content": "SELECT Id, Name FROM Account"}}]}');
            } else {
                res.setBody('{"choices": [{"message": {"content": "FIND \'John\' IN ALL FIELDS RETURNING Contact(Id, LastName)"}}]}');
            }
        }
        return res;
    }
}
