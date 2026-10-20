/** DTO de entrada do formulário de Lead (LWC -> Apex). */
public with sharing class TrainingLeadRequest {
    @AuraEnabled public String firstName;
    @AuraEnabled public String lastName;
    @AuraEnabled public String email;
    @AuraEnabled public String telefone;
    @AuraEnabled public String tipoPessoa;
    @AuraEnabled public String documento;
    @AuraEnabled public String cep;
    @AuraEnabled public String logradouro;
    @AuraEnabled public String numero;
    @AuraEnabled public String bairro;
    @AuraEnabled public String cidade;
    @AuraEnabled public String uf;
    @AuraEnabled public String complemento;
}
