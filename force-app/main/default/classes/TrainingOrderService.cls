/** Cria o Order e os OrderItems a partir da Opportunity e dos itens negociados (US-05 e Nível 2). */
public with sharing class TrainingOrderService {
    public static final String INITIAL_STATUS = 'Draft';

    // Permitem que o teste force falhas para provar o rollback.
    @TestVisible private static Boolean forceFailure = false;
    @TestVisible private static Boolean forceItemFailure = false;

    public static Id createFromOpportunity(
        Opportunity opp,
        List<OpportunityLineItem> lines,
        Map<Id, PricebookEntry> entries
    ) {
        if (forceFailure) {
            throw new TrainingException('Falha simulada na criação do pedido.');
        }
        assertPricebookConsistency(opp.Pricebook2Id, opp.Pricebook2Id, lines, entries);

        // Pricebook2Id precisa estar no insert do Order, antes dos OrderItems.
        Order o = new Order(
            AccountId = opp.AccountId,
            OpportunityId = opp.Id,
            Pricebook2Id = opp.Pricebook2Id,
            Status = INITIAL_STATUS,
            EffectiveDate = Date.today()
        );
        insert o;

        if (forceItemFailure) {
            throw new TrainingException('Falha simulada na criação dos itens do pedido.');
        }
        List<OrderItem> items = new List<OrderItem>();
        for (OpportunityLineItem line : lines) {
            items.add(new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = line.PricebookEntryId,
                Quantity = line.Quantity,
                UnitPrice = line.UnitPrice
            ));
        }
        insert items;
        return o.Id;
    }

    /** Order e Opportunity devem usar a mesma Pricebook, e todo item deve pertencer a ela. */
    @TestVisible
    private static void assertPricebookConsistency(
        Id opportunityPricebookId,
        Id orderPricebookId,
        List<OpportunityLineItem> lines,
        Map<Id, PricebookEntry> entries
    ) {
        if (opportunityPricebookId == null || opportunityPricebookId != orderPricebookId) {
            throw new TrainingException('A lista de preços do pedido deve ser a mesma da oportunidade.');
        }
        for (OpportunityLineItem line : lines) {
            PricebookEntry entry = entries.get(line.PricebookEntryId);
            if (entry == null || entry.Pricebook2Id != orderPricebookId) {
                throw new TrainingException('Há produtos que não pertencem à lista de preços do pedido.');
            }
        }
    }
}
