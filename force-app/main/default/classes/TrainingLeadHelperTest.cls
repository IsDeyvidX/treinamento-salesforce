@IsTest
private class TrainingLeadHelperTest {
    private static Lead build(Boolean complete) {
        Lead l = new Lead(FirstName = 'Ana', LastName = 'Souza', Company = 'Ana Souza',
            TipoDocumento__c = 'CPF', Documento__c = '52998224725', Email = 'ana@teste.com');
        if (complete) {
            l.Phone = '11999990000';
            l.EnderecoValidado__c = true;
        }
        return l;
    }

    @IsTest static void partialScore() {
        Lead l = build(false);
        insert l;
        l = [SELECT Score__c, AptoConversao__c FROM Lead WHERE Id = :l.Id];
        Assert.areEqual(55, l.Score__c); // documento 40 + e-mail 15
        Assert.isFalse(l.AptoConversao__c);
    }

    @IsTest static void fullScoreQualifiesLead() {
        Lead l = build(true);
        insert l;
        l = [SELECT Score__c, AptoConversao__c, Status FROM Lead WHERE Id = :l.Id];
        Assert.areEqual(100, l.Score__c);
        Assert.isTrue(l.AptoConversao__c);
        Assert.areEqual('Qualificado', l.Status);
    }

    @IsTest static void losingDataRemovesQualification() {
        Lead l = build(true);
        insert l;
        l.Phone = null;
        update l;
        l = [SELECT Score__c, AptoConversao__c, Status FROM Lead WHERE Id = :l.Id];
        Assert.areEqual(85, l.Score__c);
        Assert.isFalse(l.AptoConversao__c);
        Assert.areEqual('Novo', l.Status);
    }
}
