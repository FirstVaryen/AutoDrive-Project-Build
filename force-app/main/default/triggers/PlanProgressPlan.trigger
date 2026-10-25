trigger PlanProgressPlan on Instalment_Plan__c (before update) {
    PlanProgress.fill(Trigger.new);
}
