public with sharing class TrainingOpportunityRequest {
    @AuraEnabled public Id accountId;
    @AuraEnabled public String name;
    @AuraEnabled public Date closeDate;
    @AuraEnabled public String observacao;
    @AuraEnabled public Id pricebookId; // opcional: sem valor, usa a Standard Price Book
    @AuraEnabled public List<TrainingOpportunityItemRequest> itens;
}
