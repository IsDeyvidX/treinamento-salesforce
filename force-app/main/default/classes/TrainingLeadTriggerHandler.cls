/** Orquestra o contexto da trigger e delega a regra ao Helper. */
public with sharing class TrainingLeadTriggerHandler {
    public static void run() {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            TrainingLeadHelper.qualify((List<Lead>) Trigger.new);
        }
    }
}
