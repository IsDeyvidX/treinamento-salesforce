@IsTest
private class TrainingOrderServiceTest {
    @TestSetup
    static void setup() {
        TrainingTestDataFactory.createAccount();
        TrainingTestDataFactory.createStandardEntry(
            TrainingTestDataFactory.createProduct('Produto A', 'A-1', true), 10.50);
    }

    private static TrainingOpportunityRequest req() {
        return TrainingTestDataFactory.request(
            [SELECT Id FROM Account LIMIT 1].Id,
            new List<TrainingOpportunityItemRequest>{
                TrainingTestDataFactory.item([SELECT Id FROM PricebookEntry LIMIT 1].Id, 1)
            }
        );
    }

    @IsTest static void createsOrderRelatedToOpportunity() {
        Id oppId = TrainingOpportunityService.createOpportunity(req());
        Order o = [SELECT AccountId, OpportunityId, Status, EffectiveDate FROM Order WHERE OpportunityId = :oppId];
        Assert.areEqual([SELECT Id FROM Account LIMIT 1].Id, o.AccountId);
        Assert.areEqual('Draft', o.Status);
        Assert.areEqual(Date.today(), o.EffectiveDate);
    }

    @IsTest static void orderFailureRollsBackEverything() {
        TrainingOrderService.forceFailure = true;
        assertRolledBack();
    }

    @IsTest static void orderItemFailureRollsBackEverything() {
        TrainingOrderService.forceItemFailure = true;
        assertRolledBack();
    }

    @IsTest static void blocksPricebookMismatchBetweenOpportunityAndOrder() {
        PricebookEntry entry = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>{
            new OpportunityLineItem(PricebookEntryId = entry.Id, Quantity = 1, UnitPrice = 1)
        };
        Map<Id, PricebookEntry> entries = new Map<Id, PricebookEntry>{ entry.Id => entry };
        Pricebook2 other = TrainingTestDataFactory.createCustomPricebook('Outra', true);
        try {
            TrainingOrderService.assertPricebookConsistency(entry.Pricebook2Id, other.Id, lines, entries);
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.areEqual('A lista de preços do pedido deve ser a mesma da oportunidade.', e.getMessage());
        }
    }

    @IsTest static void blocksItemOutsideOrderPricebook() {
        PricebookEntry entry = [SELECT Id, Pricebook2Id FROM PricebookEntry LIMIT 1];
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>{
            new OpportunityLineItem(PricebookEntryId = entry.Id, Quantity = 1, UnitPrice = 1)
        };
        Pricebook2 other = TrainingTestDataFactory.createCustomPricebook('Outra', true);
        try {
            TrainingOrderService.assertPricebookConsistency(other.Id, other.Id, lines, new Map<Id, PricebookEntry>{ entry.Id => entry });
            Assert.fail('Deveria ter bloqueado');
        } catch (TrainingException e) {
            Assert.areEqual('Há produtos que não pertencem à lista de preços do pedido.', e.getMessage());
        }
    }

    private static void assertRolledBack() {
        try {
            TrainingOpportunityService.createOpportunity(req());
            Assert.fail('Deveria ter falhado');
        } catch (TrainingException e) {
            Assert.isTrue(e.getMessage().contains('Nenhum dado foi salvo'));
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Opportunity deve ser revertida');
        Assert.areEqual(0, [SELECT COUNT() FROM OpportunityLineItem]);
        Assert.areEqual(0, [SELECT COUNT() FROM Order]);
        Assert.areEqual(0, [SELECT COUNT() FROM OrderItem]);
    }
}
