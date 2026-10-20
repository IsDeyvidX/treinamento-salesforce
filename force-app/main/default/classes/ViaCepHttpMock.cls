@IsTest
public class ViaCepHttpMock implements HttpCalloutMock {
    private Integer status;
    private String body;

    public ViaCepHttpMock(Integer status, String body) {
        this.status = status;
        this.body = body;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(status);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }
}
