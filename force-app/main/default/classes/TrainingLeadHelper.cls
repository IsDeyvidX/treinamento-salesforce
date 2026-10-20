/** Cálculo de score e flags de qualificação do Lead (US-03). */
public with sharing class TrainingLeadHelper {
    public static final Integer TARGET_SCORE = 100;
    public static final String STATUS_QUALIFIED = 'Qualificado';
    public static final String STATUS_NEW = 'Novo';

    public static Integer calculateScore(Lead l) {
        Integer score = 0;
        if (DocumentValidator.isValid(l.TipoDocumento__c, l.Documento__c)) score += 40;
        if (l.EnderecoValidado__c == true) score += 30;
        if (String.isNotBlank(l.Email)) score += 15;
        if (String.isNotBlank(l.Phone)) score += 15;
        return score;
    }

    public static void qualify(List<Lead> leads) {
        for (Lead l : leads) {
            if (l.IsConverted) continue;
            Integer score = calculateScore(l);
            l.Score__c = score;
            l.AptoConversao__c = (score == TARGET_SCORE);
            if (l.AptoConversao__c) {
                l.Status = STATUS_QUALIFIED;
            } else if (l.Status == STATUS_QUALIFIED) {
                l.Status = STATUS_NEW;
            }
        }
    }
}
