@IsTest
private class TrainingLeadConversionServiceTest {
    private static Lead makeLead(Boolean eligible) {
        Lead l = new Lead(FirstName = 'Ana', LastName = 'Souza', Company = 'Ana Souza',
            Email = 'ana@teste.com', Phone = eligible ? '11999990000' : null,
            TipoDocumento__c = 'CPF', Documento__c = '52998224725', EnderecoValidado__c = true,
            Street = 'Praça da Sé', City = 'São Paulo', PostalCode = '01001000',
            Bairro__c = 'Sé', NumeroEndereco__c = '100', Complemento__c = 'Sala 1');
        if (!Lead.CountryCode.getDescribe().getPicklistValues().isEmpty()) {
            l.put('CountryCode', 'BR');
            l.put('StateCode', 'SP');
        } else {
            l.State = 'SP';
        }
        insert l;
        return l;
    }

    @IsTest static void convertsEligibleLeadWithoutOpportunity() {
        Lead l = makeLead(true);
        Id accountId = TrainingLeadConversionService.convertLead(l.Id);

        Account a = [SELECT Documento__c, TipoDocumento__c, Bairro__c, NumeroEndereco__c, Complemento__c, BillingCity
                     FROM Account WHERE Id = :accountId];
        Assert.areEqual('52998224725', a.Documento__c);
        Assert.areEqual('CPF', a.TipoDocumento__c);
        Assert.areEqual('Sé', a.Bairro__c);
        Assert.areEqual('100', a.NumeroEndereco__c);
        Assert.areEqual('Sala 1', a.Complemento__c);
        Assert.areEqual('São Paulo', a.BillingCity);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE AccountId = :accountId]);
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity WHERE AccountId = :accountId]);
        Assert.isTrue([SELECT IsConverted FROM Lead WHERE Id = :l.Id].IsConverted);
    }

    @IsTest static void blocksIneligibleLead() {
        Lead l = makeLead(false);
        try {
            TrainingLeadConversionService.convertLead(l.Id);
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.isTrue(e.getMessage().contains('não elegível'));
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Account]);
    }

    @IsTest static void blocksAlreadyConvertedLead() {
        Lead l = makeLead(true);
        TrainingLeadConversionService.convertLead(l.Id);
        try {
            TrainingLeadConversionService.convertLead(l.Id);
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.areEqual('Este Lead já foi convertido.', e.getMessage());
        }
    }
}
