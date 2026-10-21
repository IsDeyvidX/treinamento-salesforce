public with sharing class TrainingOpportunityController {
    @AuraEnabled
    public static Id createOpportunity(String requestJson) {
        try {
            TrainingOpportunityRequest request = String.isBlank(requestJson)
                ? null
                : (TrainingOpportunityRequest) JSON.deserialize(requestJson, TrainingOpportunityRequest.class);
            return TrainingOpportunityService.createOpportunity(request);
        } catch (Exception e) {
            throw TrainingErrors.wrap(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TrainingProductOption> getProductOptions() {
        try {
            return TrainingProductService.listAvailableProducts(null);
        } catch (Exception e) {
            throw TrainingErrors.wrap(e);
        }
    }
}
