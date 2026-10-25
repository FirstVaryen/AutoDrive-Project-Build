trigger PaymentChanges on Payment__c (after insert, after update, after delete) {
    Set<Date> days = new Set<Date>();
    Set<Id> opps = new Set<Id>();
    for (Payment__c p : Trigger.isDelete ? Trigger.old : Trigger.new) { days.add(p.Paid_On__c); opps.add(p.Opportunity__c); }
    if (Trigger.isUpdate) for (Payment__c p : Trigger.old) days.add(p.Paid_On__c);
    Reconciliation.touchDays(days);
    // the down payment changes what a plan is waiting for
    Set<Id> plans = new Set<Id>();
    for (Instalment_Plan__c p : [SELECT Id FROM Instalment_Plan__c WHERE Opportunity__c IN :opps]) plans.add(p.Id);
    PlanProgress.touch(plans);
}
