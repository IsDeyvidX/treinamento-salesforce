/** Cria o Order a partir da Opportunity (US-05). */
public with sharing class TrainingOrderService {
    public static final String INITIAL_STATUS = 'Draft';

    // Permite que o teste force uma falha para provar o rollback.
    @TestVisible private static Boolean forceFailure = false;

    public static Id createFromOpportunity(Opportunity opp) {
        if (forceFailure) {
            throw new TrainingException('Falha simulada na criação do pedido.');
        }
        Order o = new Order(
            AccountId = opp.AccountId,
            OpportunityId = opp.Id,
            Status = INITIAL_STATUS,
            EffectiveDate = Date.today()
        );
        insert o;
        return o.Id;
    }
}
