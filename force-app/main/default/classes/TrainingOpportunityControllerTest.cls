@IsTest
private class TrainingOpportunityControllerTest {
    @IsTest
    static void createsOpportunityFromJson() {
        Account a = new Account(Name = 'Cliente JSON');
        insert a;

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => a.Id,
            'name' => 'Venda via controller',
            'produto' => 'Plano Pro',
            'valorEstimado' => 250,
            'quantidade' => 2,
            'closeDate' => String.valueOf(Date.today().addDays(3)),
            'observacao' => 'teste'
        };

        Id oppId = TrainingOpportunityController.createOpportunity(JSON.serialize(payload));

        Opportunity opp = [SELECT AccountId, Name, Produto__c, Quantidade__c FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(a.Id, opp.AccountId);
        Assert.areEqual('Venda via controller', opp.Name);
        Assert.areEqual('Plano Pro', opp.Produto__c);
        Assert.areEqual(2, opp.Quantidade__c);
    }

    @IsTest
    static void returnsBusinessErrorWhenJsonIsBlank() {
        try {
            TrainingOpportunityController.createOpportunity(null);
            Assert.fail('Deveria lançar erro de negócio.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Conta inválida.'));
        }
    }
}
