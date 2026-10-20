/** Converte qualquer exceção em AuraHandledException sem vazar detalhes técnicos. */
public with sharing class TrainingErrors {
    public static final String GENERIC_MESSAGE =
        'Não foi possível concluir a operação. Tente novamente ou contate o administrador.';

    public static AuraHandledException wrap(Exception e) {
        Boolean isBusiness = e instanceof TrainingException;
        String msg = isBusiness ? e.getMessage() : GENERIC_MESSAGE;
        if (!isBusiness) {
            // Detalhe técnico vai só para o log, nunca para a tela.
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        AuraHandledException ex = new AuraHandledException(msg);
        ex.setMessage(msg);
        return ex;
    }
}
