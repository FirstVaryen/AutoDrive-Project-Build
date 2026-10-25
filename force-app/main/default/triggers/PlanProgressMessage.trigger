trigger PlanProgressMessage on Customer_Message__c (after insert) {
    Set<Id> insts = new Set<Id>();
    for (Customer_Message__c m : Trigger.new) if (m.Instalment__c != null) insts.add(m.Instalment__c);
    if (insts.isEmpty()) return;
    Set<Id> plans = new Set<Id>();
    for (Instalment__c i : [SELECT Instalment_Plan__c FROM Instalment__c WHERE Id IN :insts]) plans.add(i.Instalment_Plan__c);
    PlanProgress.touch(plans);
}
