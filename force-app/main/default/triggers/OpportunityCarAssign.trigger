trigger OpportunityCarAssign on Opportunity (before insert, before update) {
    OpportunityCarAssign.assign(Trigger.new, Trigger.oldMap);
}
