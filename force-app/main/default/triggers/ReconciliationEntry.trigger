trigger ReconciliationEntry on Reconciliation_Entry__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) Reconciliation.fill(Trigger.new);
    else Reconciliation.alert(Trigger.new, Trigger.oldMap);
}
