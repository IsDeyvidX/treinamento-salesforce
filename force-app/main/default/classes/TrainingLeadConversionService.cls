/** Valida elegibilidade no servidor e converte o Lead (US-03). */
public with sharing class TrainingLeadConversionService {
    public static Id convertLead(Id leadId) {
        Lead l = loadLead(leadId);
        assertEligible(l);

        Savepoint sp = Database.setSavepoint();
        try {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertedStatus());
            lc.setDoNotCreateOpportunity(true); // Opportunity nasce na US-04, pela Account
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.duplicateRuleHeader.allowSave = true;
            opts.optAllOrNone = true;
            Database.LeadConvertResult result = Database.convertLead(lc, opts);

            Id accountId = result.getAccountId();
            copyFieldsToAccount(l, accountId);
            return accountId;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
            throw new TrainingException('Não foi possível converter o Lead. Tente novamente ou contate o administrador.');
        }
    }

    private static Lead loadLead(Id leadId) {
        List<Lead> leads = [
            SELECT Id, IsConverted, Status, Email, Phone, Street, City, State, StateCode,
                   Country, CountryCode, PostalCode,
                   TipoDocumento__c, Documento__c, NumeroEndereco__c, Bairro__c, Complemento__c,
                   EnderecoValidado__c, Score__c, AptoConversao__c
            FROM Lead WHERE Id = :leadId LIMIT 1
        ];
        if (leads.isEmpty()) throw new TrainingException('Lead não encontrado.');
        return leads[0];
    }

    private static void assertEligible(Lead l) {
        if (l.IsConverted) {
            throw new TrainingException('Este Lead já foi convertido.');
        }
        Boolean eligible = DocumentValidator.isValid(l.TipoDocumento__c, l.Documento__c)
            && l.EnderecoValidado__c == true
            && TrainingLeadHelper.calculateScore(l) == TrainingLeadHelper.TARGET_SCORE
            && l.AptoConversao__c == true
            && l.Status == TrainingLeadHelper.STATUS_QUALIFIED;
        if (!eligible) {
            throw new TrainingException(
                'Lead não elegível para conversão. É necessário documento válido, endereço validado, e-mail, telefone e status Qualificado.'
            );
        }
    }

    private static String convertedStatus() {
        List<LeadStatus> st = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        if (st.isEmpty()) throw new TrainingException('Status de conversão não configurado. Contate o administrador.');
        return st[0].MasterLabel;
    }

    /** Garante o mapeamento Lead -> Account (campos customizados e endereço de cobrança). */
    private static void copyFieldsToAccount(Lead l, Id accountId) {
        Account a = new Account(
            Id = accountId,
            Documento__c = l.Documento__c,
            TipoDocumento__c = l.TipoDocumento__c,
            Bairro__c = l.Bairro__c,
            NumeroEndereco__c = l.NumeroEndereco__c,
            Complemento__c = l.Complemento__c,
            BillingPostalCode = l.PostalCode,
            BillingStreet = l.Street,
            BillingCity = l.City
        );
        if (!Account.BillingCountryCode.getDescribe().getPicklistValues().isEmpty()) {
            a.put('BillingCountryCode', l.get('CountryCode'));
            a.put('BillingStateCode', l.get('StateCode'));
        } else {
            a.BillingState = l.State;
        }
        update a;
    }
}
