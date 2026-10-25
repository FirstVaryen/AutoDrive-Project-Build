trigger PlanProgressInstalment on Instalment__c (after insert, after update, after delete) {
    Set<Id> plans = new Set<Id>();
    for (Instalment__c i : Trigger.isDelete ? Trigger.old : Trigger.new) plans.add(i.Instalment_Plan__c);
    PlanProgress.touch(plans);
}
