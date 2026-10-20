trigger TrainingLeadTrigger on Lead (before insert, before update) {
    TrainingLeadTriggerHandler.run();
}
