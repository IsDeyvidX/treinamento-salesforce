@IsTest
private class TrainingOpportunityControllerTest {
    @TestSetup
    static void setup() {
        TrainingTestDataFactory.createAccount();
        TrainingTestDataFactory.createStandardEntry(
            TrainingTestDataFactory.createProduct('Produto A', 'A-1', true), 250);
    }

    @IsTest
    static void createsOpportunityFromJson() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        PricebookEntry entry = [SELECT Id FROM PricebookEntry LIMIT 1];
        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => a.Id,
            'name' => 'Venda via controller',
            'closeDate' => String.valueOf(Date.today().addDays(3)),
            'observacao' => 'teste',
            'itens' => new List<Object>{
                new Map<String, Object>{ 'pricebookEntryId' => entry.Id, 'quantidade' => 2 }
            }
        };

        Id oppId = TrainingOpportunityController.createOpportunity(JSON.serialize(payload));

        Opportunity opp = [SELECT AccountId, Name, Amount, Quantidade__c FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(a.Id, opp.AccountId);
        Assert.areEqual('Venda via controller', opp.Name);
        Assert.areEqual(500, opp.Amount);
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

    @IsTest
    static void returnsGenericErrorWhenJsonIsMalformed() {
        try {
            TrainingOpportunityController.createOpportunity('{isto não é json');
            Assert.fail('Deveria lançar erro.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Não foi possível concluir a operação.'));
        }
    }

    @IsTest
    static void getProductOptionsFailsWhenStandardPricebookIsInactive() {
        update new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = false);
        try {
            TrainingOpportunityController.getProductOptions();
            Assert.fail('Deveria lançar erro de negócio.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Lista de preços inválida ou inativa.'));
        }
    }

    @IsTest
    static void getProductOptionsReturnsOnlyActiveOrdered() {
        Product2 inactive = TrainingTestDataFactory.createProduct('Inativo', 'I-1', true);
        TrainingTestDataFactory.createStandardEntry(inactive, 5);
        update new Product2(Id = inactive.Id, IsActive = false);
        TrainingTestDataFactory.createStandardEntry(
            TrainingTestDataFactory.createProduct('Antes de A', 'Z-1', true), 7);

        List<TrainingProductOption> options = TrainingOpportunityController.getProductOptions();

        Assert.areEqual(2, options.size());
        Assert.areEqual('Antes de A', options[0].name);
        Assert.areEqual('Produto A', options[1].name);
        Assert.areEqual(250, options[1].unitPrice);
        Assert.areEqual('A-1', options[1].productCode);
    }
}
