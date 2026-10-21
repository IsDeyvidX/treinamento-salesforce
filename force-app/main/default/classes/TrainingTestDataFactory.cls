@IsTest
public class TrainingTestDataFactory {
    public static Id standardPricebookId() {
        Id pbId = Test.getStandardPricebookId();
        update new Pricebook2(Id = pbId, IsActive = true);
        return pbId;
    }

    public static Account createAccount() {
        Account a = new Account(Name = 'Cliente Teste');
        insert a;
        return a;
    }

    public static Product2 createProduct(String name, String code, Boolean active) {
        Product2 p = new Product2(Name = name, ProductCode = code, IsActive = true);
        insert p;
        if (!active) {
            p.IsActive = false;
            update p;
        }
        return p;
    }

    /** Cria a entrada na Standard Price Book (obrigatória antes de qualquer lista customizada). */
    public static PricebookEntry createStandardEntry(Product2 product, Decimal price) {
        PricebookEntry e = new PricebookEntry(
            Pricebook2Id = standardPricebookId(), Product2Id = product.Id, UnitPrice = price, IsActive = true
        );
        insert e;
        return e;
    }

    public static Pricebook2 createCustomPricebook(String name, Boolean active) {
        Pricebook2 pb = new Pricebook2(Name = name, IsActive = active);
        insert pb;
        return pb;
    }

    public static PricebookEntry createCustomEntry(Pricebook2 pb, Product2 product, Decimal price) {
        PricebookEntry e = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = product.Id, UnitPrice = price, IsActive = true
        );
        insert e;
        return e;
    }

    public static TrainingOpportunityItemRequest item(Id entryId, Integer quantity) {
        TrainingOpportunityItemRequest i = new TrainingOpportunityItemRequest();
        i.pricebookEntryId = entryId;
        i.quantidade = quantity;
        return i;
    }

    public static TrainingOpportunityRequest request(Id accountId, List<TrainingOpportunityItemRequest> itens) {
        TrainingOpportunityRequest r = new TrainingOpportunityRequest();
        r.accountId = accountId;
        r.name = 'Venda Teste';
        r.closeDate = Date.today().addDays(10);
        r.observacao = 'Teste';
        r.itens = itens;
        return r;
    }
}
