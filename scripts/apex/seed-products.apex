/**
 * Seed idempotente (Nível 2): 4 produtos e suas PricebookEntry na Standard Price Book.
 * Executar: sf apex run --file scripts/apex/seed-products.apex --target-org <alias>
 */
Id standardId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

Map<String, Decimal> catalog = new Map<String, Decimal>{
    'TRN-001' => 10.50,
    'TRN-002' => 20.00,
    'TRN-003' => 149.90,
    'TRN-004' => 999.00
};
Map<String, String> names = new Map<String, String>{
    'TRN-001' => 'Plano Básico',
    'TRN-002' => 'Plano Pro',
    'TRN-003' => 'Suporte Premium',
    'TRN-004' => 'Consultoria Implantação'
};

Map<String, Product2> products = new Map<String, Product2>();
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :catalog.keySet()]) {
    products.put(p.ProductCode, p);
}
List<Product2> newProducts = new List<Product2>();
for (String code : catalog.keySet()) {
    if (!products.containsKey(code)) {
        Product2 p = new Product2(Name = names.get(code), ProductCode = code, IsActive = true);
        newProducts.add(p);
        products.put(code, p);
    }
}
insert newProducts;

Set<Id> productIds = new Set<Id>();
for (Product2 p : products.values()) {
    productIds.add(p.Id);
}
Set<Id> withEntry = new Set<Id>();
for (PricebookEntry e : [SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :standardId AND Product2Id IN :productIds]) {
    withEntry.add(e.Product2Id);
}
List<PricebookEntry> newEntries = new List<PricebookEntry>();
for (String code : catalog.keySet()) {
    Product2 p = products.get(code);
    if (!withEntry.contains(p.Id)) {
        newEntries.add(new PricebookEntry(
            Pricebook2Id = standardId, Product2Id = p.Id, UnitPrice = catalog.get(code), IsActive = true
        ));
    }
}
insert newEntries;
System.debug('Seed concluído. Produtos novos: ' + newProducts.size() + ', entradas novas: ' + newEntries.size());
