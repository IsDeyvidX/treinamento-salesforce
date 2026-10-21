/** Produto disponível para venda (PricebookEntry ativa) exibido no combobox do modal. */
public with sharing class TrainingProductOption {
    @AuraEnabled public Id pricebookEntryId;
    @AuraEnabled public Id productId;
    @AuraEnabled public String name;
    @AuraEnabled public String productCode;
    @AuraEnabled public Decimal unitPrice;

    public TrainingProductOption(PricebookEntry entry) {
        this.pricebookEntryId = entry.Id;
        this.productId = entry.Product2Id;
        this.name = entry.Product2.Name;
        this.productCode = entry.Product2.ProductCode;
        this.unitPrice = entry.UnitPrice;
    }
}
