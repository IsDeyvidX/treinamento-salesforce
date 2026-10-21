/** Item enviado pelo LWC: só o id da PricebookEntry e a quantidade. O preço vem sempre do servidor. */
public with sharing class TrainingOpportunityItemRequest {
    @AuraEnabled public Id pricebookEntryId;
    @AuraEnabled public Integer quantidade;
}
