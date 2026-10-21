/** Valida, cria a Opportunity e o Order como UMA operação lógica (US-04 + US-05). */
public with sharing class TrainingOpportunityService {
    public static final String INITIAL_STAGE = 'Prospecting';

    public static Id createOpportunity(TrainingOpportunityRequest r) {
        validate(r);
        Id pricebookId = TrainingProductService.resolvePricebookId(r.pricebookId);
        Map<Id, PricebookEntry> entries = TrainingProductService.loadValidatedEntries(pricebookId, r.itens);
        if (TrainingProductService.calculateTotal(r.itens, entries) <= 0) {
            throw new TrainingException('O valor total da oportunidade deve ser maior que zero.');
        }

        Integer totalQuantity = 0;
        for (TrainingOpportunityItemRequest item : r.itens) {
            totalQuantity += item.quantidade;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            // Amount não é informado: o Salesforce o recalcula a partir dos OpportunityLineItems.
            Opportunity opp = new Opportunity(
                Name = r.name.trim(),
                AccountId = r.accountId,
                StageName = INITIAL_STAGE,
                CloseDate = r.closeDate,
                Pricebook2Id = pricebookId,
                Quantidade__c = totalQuantity,
                Description = r.observacao
            );
            insert opp;

            List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
            for (TrainingOpportunityItemRequest item : r.itens) {
                lines.add(new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    PricebookEntryId = item.pricebookEntryId,
                    Quantity = item.quantidade,
                    UnitPrice = entries.get(item.pricebookEntryId).UnitPrice
                ));
            }
            insert lines;

            TrainingOrderService.createFromOpportunity(opp, lines, entries);
            return opp.Id;
        } catch (Exception e) {
            // Se o Order falhar, a Opportunity criada neste fluxo é desfeita.
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
            throw new TrainingException('Não foi possível criar a oportunidade e o pedido. Nenhum dado foi salvo.');
        }
    }

    private static void validate(TrainingOpportunityRequest r) {
        if (r == null || r.accountId == null) throw new TrainingException('Conta inválida.');
        if ([SELECT COUNT() FROM Account WHERE Id = :r.accountId] == 0) throw new TrainingException('Conta inválida.');
        if (String.isBlank(r.name)) throw new TrainingException('Informe o nome da oportunidade.');
        if (r.closeDate == null || r.closeDate < Date.today()) throw new TrainingException('A data de fechamento não pode ser anterior a hoje.');
    }
}
