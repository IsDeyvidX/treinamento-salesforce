@IsTest
private class ViaCepServiceTest {
    private static final String FOUND =
        '{"cep":"01001-000","logradouro":"Praça da Sé","bairro":"Sé","localidade":"São Paulo","uf":"SP"}';

    @IsTest static void returnsAddress() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(200, FOUND));
        ViaCepDTO d = ViaCepService.lookup('01001-000');
        Assert.areEqual('Praça da Sé', d.logradouro);
        Assert.areEqual('Sé', d.bairro);
        Assert.areEqual('São Paulo', d.cidade);
        Assert.areEqual('SP', d.uf);
    }
    @IsTest static void cepNotFound() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(200, '{"erro": true}'));
        assertMessage('99999999', ViaCepService.MSG_NOT_FOUND);
    }
    @IsTest static void serviceUnavailable() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(500, 'Internal Server Error'));
        assertMessage('01001000', ViaCepService.MSG_UNAVAILABLE);
    }
    @IsTest static void invalidCepNeverCallsService() {
        assertMessage('123', ViaCepService.MSG_INVALID);
    }

    private static void assertMessage(String cep, String expected) {
        try {
            ViaCepService.lookup(cep);
            Assert.fail('Deveria ter lançado exceção');
        } catch (TrainingException e) {
            Assert.areEqual(expected, e.getMessage());
        }
    }
}
