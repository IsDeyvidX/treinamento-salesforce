@IsTest
private class TrainingProductServiceTest {
    @IsTest
    static void bulkWith20ItemsKeepsLimitsLow() {
        Account a = TrainingTestDataFactory.createAccount();
        List<TrainingOpportunityItemRequest> itens = new List<TrainingOpportunityItemRequest>();
        for (Integer i = 0; i < TrainingProductService.MAX_ITEMS; i++) {
            Product2 p = TrainingTestDataFactory.createProduct('Produto ' + i, 'P-' + i, true);
            itens.add(TrainingTestDataFactory.item(TrainingTestDataFactory.createStandardEntry(p, 10 + i).Id, 1 + i));
        }

        Test.startTest();
        Id oppId = TrainingOpportunityService.createOpportunity(TrainingTestDataFactory.request(a.Id, itens));
        Integer queries = Limits.getQueries();
        Integer dmls = Limits.getDmlStatements();
        Test.stopTest();

        // 20 itens: sem SOQL/DML em loop (pricebook + entries + 1 DML por objeto + savepoint).
        Assert.isTrue(queries <= 5, 'SOQL usados: ' + queries);
        Assert.isTrue(dmls <= 8, 'DML usados: ' + dmls);
        Assert.areEqual(20, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :oppId]);
        Assert.areEqual(20, [SELECT COUNT() FROM OrderItem WHERE Order.OpportunityId = :oppId]);
    }

    @IsTest
    static void calculateTotalRoundsToTwoDecimals() {
        Product2 p = TrainingTestDataFactory.createProduct('Produto', 'X-1', true);
        PricebookEntry e = TrainingTestDataFactory.createStandardEntry(p, 0.335);
        Decimal total = TrainingProductService.calculateTotal(
            new List<TrainingOpportunityItemRequest>{ TrainingTestDataFactory.item(e.Id, 3) },
            new Map<Id, PricebookEntry>{ e.Id => e });
        Assert.areEqual(1.01, total);
    }
}
