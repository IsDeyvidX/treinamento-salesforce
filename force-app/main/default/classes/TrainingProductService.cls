/** Catálogo (Pricebook2/PricebookEntry): lista produtos e valida os itens negociados (Nível 2). */
public with sharing class TrainingProductService {
    public static final Integer MAX_ITEMS = 20;
    private static final Integer MAX_OPTIONS = 200;

    /** Sem id informado, usa a Standard Price Book. Exige lista existente e ativa. */
    public static Id resolvePricebookId(Id pricebookId) {
        List<Pricebook2> books = pricebookId == null
            ? [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true WITH USER_MODE LIMIT 1]
            : [SELECT Id, IsActive FROM Pricebook2 WHERE Id = :pricebookId WITH USER_MODE LIMIT 1];
        if (books.isEmpty() || !books[0].IsActive) {
            throw new TrainingException('Lista de preços inválida ou inativa.');
        }
        return books[0].Id;
    }

    public static List<TrainingProductOption> listAvailableProducts(Id pricebookId) {
        Id pricebook = resolvePricebookId(pricebookId);
        List<TrainingProductOption> options = new List<TrainingProductOption>();
        for (PricebookEntry entry : [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebook AND IsActive = true AND Product2.IsActive = true
            WITH USER_MODE
            ORDER BY Product2.Name, Id
            LIMIT :MAX_OPTIONS
        ]) {
            options.add(new TrainingProductOption(entry));
        }
        return options;
    }

    /** Valida os itens e devolve as PricebookEntry da lista (1 SOQL), indexadas por Id. */
    public static Map<Id, PricebookEntry> loadValidatedEntries(Id pricebookId, List<TrainingOpportunityItemRequest> itens) {
        if (itens == null || itens.isEmpty()) {
            throw new TrainingException('Adicione pelo menos um produto.');
        }
        if (itens.size() > MAX_ITEMS) {
            throw new TrainingException('Informe no máximo ' + MAX_ITEMS + ' produtos por oportunidade.');
        }
        Set<Id> entryIds = new Set<Id>();
        for (TrainingOpportunityItemRequest item : itens) {
            if (item == null || item.pricebookEntryId == null) {
                throw new TrainingException('Selecione um produto em todas as linhas.');
            }
            if (item.quantidade == null || item.quantidade <= 0) {
                throw new TrainingException('A quantidade deve ser um inteiro maior que zero.');
            }
            if (!entryIds.add(item.pricebookEntryId)) {
                throw new TrainingException('O mesmo produto não pode ser adicionado duas vezes.');
            }
        }
        Map<Id, PricebookEntry> entries = new Map<Id, PricebookEntry>([
            SELECT Id, Pricebook2Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Id IN :entryIds AND Pricebook2Id = :pricebookId AND IsActive = true AND Product2.IsActive = true
            WITH USER_MODE
        ]);
        if (entries.size() != entryIds.size()) {
            throw new TrainingException('Um ou mais produtos estão inativos ou não pertencem à lista de preços.');
        }
        return entries;
    }

    /** Total = soma de quantidade x preço unitário da PricebookEntry, com 2 casas decimais. */
    public static Decimal calculateTotal(List<TrainingOpportunityItemRequest> itens, Map<Id, PricebookEntry> entries) {
        Decimal total = 0;
        for (TrainingOpportunityItemRequest item : itens) {
            total += entries.get(item.pricebookEntryId).UnitPrice * item.quantidade;
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }
}
