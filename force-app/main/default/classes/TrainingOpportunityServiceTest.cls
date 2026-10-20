@IsTest
private class TrainingOpportunityServiceTest {
    private static TrainingOpportunityRequest req(Id accountId) {
        TrainingOpportunityRequest r = new TrainingOpportunityRequest();
        r.accountId = accountId; r.name = 'Venda Plano Pro'; r.produto = 'Plano Pro';
        r.valorEstimado = 1500; r.quantidade = 3; r.closeDate = Date.today().addDays(10);
        r.observacao = 'Teste';
        return r;
    }
    private static Account acc() {
        Account a = new Account(Name = 'Cliente Teste');
        insert a;
        return a;
    }

    @IsTest static void createsOpportunityLinkedToAccount() {
        Account a = acc();
        Id oppId = TrainingOpportunityService.createOpportunity(req(a.Id));
        Opportunity o = [SELECT AccountId, StageName, Amount, Quantidade__c, Produto__c FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(a.Id, o.AccountId);
        Assert.areEqual('Prospecting', o.StageName);
        Assert.areEqual(1500, o.Amount);
        Assert.areEqual(3, o.Quantidade__c);
    }

    @IsTest static void blocksZeroValue() {
        TrainingOpportunityRequest r = req(acc().Id); r.valorEstimado = 0;
        assertBlocked(r, 'O valor estimado deve ser maior que zero.');
    }
    @IsTest static void blocksZeroQuantity() {
        TrainingOpportunityRequest r = req(acc().Id); r.quantidade = 0;
        assertBlocked(r, 'A quantidade deve ser um inteiro maior que zero.');
    }
    @IsTest static void blocksPastCloseDate() {
        TrainingOpportunityRequest r = req(acc().Id); r.closeDate = Date.today().addDays(-1);
        assertBlocked(r, 'A data de fechamento não pode ser anterior a hoje.');
    }
    @IsTest static void blocksEmptyName() {
        TrainingOpportunityRequest r = req(acc().Id); r.name = ' ';
        assertBlocked(r, 'Informe o nome da oportunidade.');
    }

    private static void assertBlocked(TrainingOpportunityRequest r, String expected) {
        try {
            TrainingOpportunityService.createOpportunity(r);
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.areEqual(expected, e.getMessage());
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
    }
}
