@IsTest
private class TrainingLeadServiceTest {
    private static final String FOUND =
        '{"cep":"01001-000","logradouro":"Praça da Sé","bairro":"Sé","localidade":"São Paulo","uf":"SP"}';

    private static TrainingLeadRequest validRequest() {
        TrainingLeadRequest r = new TrainingLeadRequest();
        r.firstName = 'Maria'; r.lastName = 'Silva'; r.email = 'maria@teste.com'; r.telefone = '11999990000';
        r.tipoPessoa = 'CPF'; r.documento = '529.982.247-25'; r.cep = '01001-000';
        r.logradouro = 'Praça da Sé'; r.numero = '100'; r.bairro = 'Sé'; r.cidade = 'São Paulo'; r.uf = 'SP';
        return r;
    }

    @IsTest static void createsLeadWithSanitizedDocument() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(200, FOUND));
        Id id = TrainingLeadService.createLead(validRequest());
        Lead l = [SELECT Documento__c, LeadSource, EnderecoValidado__c, Score__c, AptoConversao__c, Status FROM Lead WHERE Id = :id];
        Assert.areEqual('52998224725', l.Documento__c);
        Assert.areEqual('Treinamento LWC', l.LeadSource);
        Assert.isTrue(l.EnderecoValidado__c);
        Assert.areEqual(100, l.Score__c);
        Assert.isTrue(l.AptoConversao__c);
        Assert.areEqual('Qualificado', l.Status, 'A trigger qualifica o Lead completo');
    }

    @IsTest static void createsLeadWithCnpj() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(200, FOUND));
        TrainingLeadRequest r = validRequest();
        r.tipoPessoa = 'CNPJ'; r.documento = '11.222.333/0001-81';
        Id id = TrainingLeadService.createLead(r);
        Assert.areEqual('11222333000181', [SELECT Documento__c FROM Lead WHERE Id = :id].Documento__c);
    }

    @IsTest static void viaCepDownStillCreatesLeadWithoutValidatedAddress() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(500, ''));
        Id id = TrainingLeadService.createLead(validRequest());
        Lead l = [SELECT EnderecoValidado__c, Score__c, AptoConversao__c FROM Lead WHERE Id = :id];
        Assert.isFalse(l.EnderecoValidado__c);
        Assert.areEqual(70, l.Score__c);
        Assert.isFalse(l.AptoConversao__c);
    }

    @IsTest static void blocksMissingRequiredField() {
        TrainingLeadRequest r = validRequest();
        r.email = '';
        assertBlocked(r, 'Preencha os campos obrigatorios: E-mail.');
    }

    @IsTest static void blocksInvalidDocument() {
        TrainingLeadRequest r = validRequest();
        r.documento = '529.982.247-26';
        assertBlocked(r, 'CPF inválido.');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
    }

    @IsTest static void blocksDuplicateAccount() {
        insert new Account(Name = 'Cliente Existente', Documento__c = '52998224725');
        assertBlocked(validRequest(), 'Já existe um Lead ou Cliente cadastrado com este documento.');
    }

    @IsTest static void blocksDuplicateLead() {
        Test.setMock(HttpCalloutMock.class, new ViaCepHttpMock(200, FOUND));
        TrainingLeadService.createLead(validRequest());
        assertBlocked(validRequest(), 'Já existe um Lead ou Cliente cadastrado com este documento.');
        Assert.areEqual(1, [SELECT COUNT() FROM Lead]);
    }

    private static void assertBlocked(TrainingLeadRequest r, String expected) {
        try {
            TrainingLeadService.createLead(r);
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.areEqual(expected, e.getMessage());
        }
    }
}
