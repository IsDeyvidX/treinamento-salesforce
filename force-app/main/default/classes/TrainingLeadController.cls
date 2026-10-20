/** Camada de entrada (LWC -> Apex). Sem regra de negócio: só delega e trata erro. */
public with sharing class TrainingLeadController {
    @AuraEnabled
    public static Id createLead(String leadJson) {
        try {
            TrainingLeadRequest r = String.isBlank(leadJson)
                ? null
                : (TrainingLeadRequest) JSON.deserialize(leadJson, TrainingLeadRequest.class);
            return TrainingLeadService.createLead(r);
        } catch (Exception e) {
            throw TrainingErrors.wrap(e);
        }
    }

    @AuraEnabled
    public static ViaCepDTO lookupCep(String cep) {
        try {
            return ViaCepService.lookup(cep);
        } catch (Exception e) {
            throw TrainingErrors.wrap(e);
        }
    }
}
