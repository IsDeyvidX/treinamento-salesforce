public with sharing class TrainingOpportunityRequest {
    @AuraEnabled public Id accountId;
    @AuraEnabled public String name;
    @AuraEnabled public String produto;
    @AuraEnabled public Decimal valorEstimado;
    @AuraEnabled public Integer quantidade;
    @AuraEnabled public Date closeDate;
    @AuraEnabled public String observacao;
}
