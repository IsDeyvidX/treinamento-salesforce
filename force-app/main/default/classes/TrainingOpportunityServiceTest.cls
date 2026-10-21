@IsTest
private class TrainingOpportunityServiceTest {
    private static Account acc;
    private static PricebookEntry e1050;
    private static PricebookEntry e2000;

    @TestSetup
    static void setup() {
        TrainingTestDataFactory.createAccount();
        Product2 p1 = TrainingTestDataFactory.createProduct('Produto A', 'A-1', true);
        Product2 p2 = TrainingTestDataFactory.createProduct('Produto B', 'B-1', true);
        TrainingTestDataFactory.createStandardEntry(p1, 10.50);
        TrainingTestDataFactory.createStandardEntry(p2, 20.00);
    }

    private static void load() {
        acc = [SELECT Id FROM Account LIMIT 1];
        e1050 = [SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'A-1' LIMIT 1];
        e2000 = [SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'B-1' LIMIT 1];
    }

    @IsTest static void createsWithOneItem() {
        load();
        Id oppId = TrainingOpportunityService.createOpportunity(TrainingTestDataFactory.request(
            acc.Id, new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 2) }
        ));
        Opportunity o = [SELECT AccountId, StageName, Amount, Quantidade__c, Pricebook2Id FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(acc.Id, o.AccountId);
        Assert.areEqual('Prospecting', o.StageName);
        Assert.areEqual(21.00, o.Amount);
        Assert.areEqual(2, o.Quantidade__c);
        Assert.areEqual(Test.getStandardPricebookId(), o.Pricebook2Id);
        Assert.areEqual(1, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :oppId]);
    }

    @IsTest static void calculatesTotalFromMultipleItemsAndMirrorsOrder() {
        load();
        Id oppId = TrainingOpportunityService.createOpportunity(TrainingTestDataFactory.request(
            acc.Id,
            new List<TrainingOpportunityItemRequest>{
                TrainingTestDataFactory.item(e1050.Id, 2), TrainingTestDataFactory.item(e2000.Id, 3)
            }
        ));
        Opportunity o = [SELECT Amount, Quantidade__c FROM Opportunity WHERE Id = :oppId];
        Assert.areEqual(81.00, o.Amount);
        Assert.areEqual(5, o.Quantidade__c);

        Order ord = [SELECT Id, Status, Pricebook2Id, Opportunity.Pricebook2Id FROM Order WHERE OpportunityId = :oppId];
        Assert.areEqual('Draft', ord.Status);
        Assert.areEqual(ord.Opportunity.Pricebook2Id, ord.Pricebook2Id);

        Map<Id, OpportunityLineItem> olis = new Map<Id, OpportunityLineItem>();
        for (OpportunityLineItem l : [SELECT PricebookEntryId, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :oppId]) {
            olis.put(l.PricebookEntryId, l);
        }
        List<OrderItem> items = [SELECT PricebookEntryId, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :ord.Id];
        Assert.areEqual(2, olis.size());
        Assert.areEqual(2, items.size());
        for (OrderItem oi : items) {
            OpportunityLineItem l = olis.get(oi.PricebookEntryId);
            Assert.isNotNull(l);
            Assert.areEqual(l.Quantity, oi.Quantity);
            Assert.areEqual(l.UnitPrice, oi.UnitPrice);
        }
    }

    @IsTest static void blocksPastCloseDate() {
        load();
        TrainingOpportunityRequest r = TrainingTestDataFactory.request(
            acc.Id, new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) });
        r.closeDate = Date.today().addDays(-1);
        assertBlocked(r, 'A data de fechamento não pode ser anterior a hoje.');
    }

    @IsTest static void blocksEmptyName() {
        load();
        TrainingOpportunityRequest r = TrainingTestDataFactory.request(
            acc.Id, new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) });
        r.name = ' ';
        assertBlocked(r, 'Informe o nome da oportunidade.');
    }

    @IsTest static void blocksEmptyList() {
        load();
        assertBlocked(TrainingTestDataFactory.request(acc.Id, new List<TrainingOpportunityItemRequest>()),
            'Adicione pelo menos um produto.');
    }

    @IsTest static void blocksZeroQuantity() {
        load();
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 0) }),
            'A quantidade deve ser um inteiro maior que zero.');
    }

    @IsTest static void blocksDuplicateProduct() {
        load();
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{
                TrainingTestDataFactory.item(e1050.Id, 1), TrainingTestDataFactory.item(e1050.Id, 2)
            }), 'O mesmo produto não pode ser adicionado duas vezes.');
    }

    @IsTest static void blocksInactiveEntry() {
        load();
        update new PricebookEntry(Id = e1050.Id, IsActive = false);
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) }),
            'Um ou mais produtos estão inativos ou não pertencem à lista de preços.');
    }

    @IsTest static void blocksInactiveProduct() {
        load();
        Product2 p = [SELECT Id FROM Product2 WHERE ProductCode = 'A-1'];
        update new Product2(Id = p.Id, IsActive = false);
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) }),
            'Um ou mais produtos estão inativos ou não pertencem à lista de preços.');
    }

    @IsTest static void blocksEntryFromAnotherPricebook() {
        load();
        Product2 p = [SELECT Id FROM Product2 WHERE ProductCode = 'A-1'];
        Pricebook2 other = TrainingTestDataFactory.createCustomPricebook('Outra', true);
        PricebookEntry otherEntry = TrainingTestDataFactory.createCustomEntry(other, p, 9);
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(otherEntry.Id, 1) }),
            'Um ou mais produtos estão inativos ou não pertencem à lista de preços.');
    }

    @IsTest static void blocksInactivePricebook() {
        load();
        Pricebook2 other = TrainingTestDataFactory.createCustomPricebook('Inativa', false);
        TrainingOpportunityRequest r = TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) });
        r.pricebookId = other.Id;
        assertBlocked(r, 'Lista de preços inválida ou inativa.');
    }

    @IsTest static void blocksZeroTotal() {
        load();
        update new PricebookEntry(Id = e1050.Id, UnitPrice = 0);
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) }),
            'O valor total da oportunidade deve ser maior que zero.');
    }

    @IsTest static void blocksMoreThanMaxItems() {
        load();
        List<TrainingOpportunityItemRequest> itens = new List<TrainingOpportunityItemRequest>();
        for (Integer i = 0; i < 21; i++) {
            itens.add(TrainingTestDataFactory.item(e1050.Id, 1));
        }
        assertBlocked(TrainingTestDataFactory.request(acc.Id, itens), 'Informe no máximo 20 produtos por oportunidade.');
    }

    @IsTest static void blocksMissingEntryId() {
        load();
        assertBlocked(TrainingTestDataFactory.request(acc.Id,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(null, 1) }),
            'Selecione um produto em todas as linhas.');
    }

    @IsTest static void blocksInvalidAccount() {
        load();
        assertBlocked(TrainingTestDataFactory.request(null,
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e1050.Id, 1) }),
            'Conta inválida.');
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
