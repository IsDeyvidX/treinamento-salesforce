/** Valida, cria a Opportunity e o Order como UMA operação lógica (US-04 + US-05). */
public with sharing class TrainingOpportunityService {
    public static final String INITIAL_STAGE = 'Prospecting';

    public static Id createOpportunity(TrainingOpportunityRequest r) {
        validate(r);

        Savepoint sp = Database.setSavepoint();
        try {
            Opportunity opp = new Opportunity(
                Name = r.name.trim(),
                AccountId = r.accountId,
                StageName = INITIAL_STAGE,
                CloseDate = r.closeDate,
                Amount = r.valorEstimado,
                Produto__c = r.produto,
                Quantidade__c = r.quantidade,
                Description = r.observacao
            );
            insert opp;
            TrainingOrderService.createFromOpportunity(opp);
            return opp.Id;
        } catch (Exception e) {
            // Se o Order falhar, a Opportunity criada neste fluxo é desfeita.
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
            throw new TrainingException('Não foi possível criar a oportunidade e o pedido. Nenhum dado foi salvo.');
        }
    }

    private static void validate(TrainingOpportunityRequest r) {
        if (r == null || r.accountId == null) throw new TrainingException('Conta inválida.');
        if ([SELECT COUNT() FROM Account WHERE Id = :r.accountId] == 0) throw new TrainingException('Conta inválida.');
        if (String.isBlank(r.name)) throw new TrainingException('Informe o nome da oportunidade.');
        if (String.isBlank(r.produto)) throw new TrainingException('Selecione um produto.');
        if (r.valorEstimado == null || r.valorEstimado <= 0) throw new TrainingException('O valor estimado deve ser maior que zero.');
        if (r.quantidade == null || r.quantidade <= 0) throw new TrainingException('A quantidade deve ser um inteiro maior que zero.');
        if (r.closeDate == null || r.closeDate < Date.today()) throw new TrainingException('A data de fechamento não pode ser anterior a hoje.');
    }
}
