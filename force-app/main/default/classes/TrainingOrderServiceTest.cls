@IsTest
private class TrainingOrderServiceTest {
    private static TrainingOpportunityRequest req(Id accountId) {
        TrainingOpportunityRequest r = new TrainingOpportunityRequest();
        r.accountId = accountId; r.name = 'Venda'; r.produto = 'Plano Básico';
        r.valorEstimado = 100; r.quantidade = 1; r.closeDate = Date.today().addDays(5);
        return r;
    }

    @IsTest static void createsOrderRelatedToOpportunity() {
        Account a = new Account(Name = 'Cliente');
        insert a;
        Id oppId = TrainingOpportunityService.createOpportunity(req(a.Id));
        Order o = [SELECT AccountId, OpportunityId, Status, EffectiveDate FROM Order WHERE OpportunityId = :oppId];
        Assert.areEqual(a.Id, o.AccountId);
        Assert.areEqual('Draft', o.Status);
        Assert.areEqual(Date.today(), o.EffectiveDate);
    }

    @IsTest static void orderFailureRollsBackOpportunity() {
        Account a = new Account(Name = 'Cliente');
        insert a;
        TrainingOrderService.forceFailure = true;
        try {
            TrainingOpportunityService.createOpportunity(req(a.Id));
            Assert.fail('Deveria ter falhado');
        } catch (TrainingException e) {
            Assert.isTrue(e.getMessage().contains('Nenhum dado foi salvo'));
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Opportunity deve ser revertida');
        Assert.areEqual(0, [SELECT COUNT() FROM Order]);
    }
}
