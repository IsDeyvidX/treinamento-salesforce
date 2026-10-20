public with sharing class TrainingLeadConversionController {
    @AuraEnabled
    public static Id convertLead(Id leadId) {
        try {
            return TrainingLeadConversionService.convertLead(leadId);
        } catch (Exception e) {
            throw TrainingErrors.wrap(e);
        }
    }
}
