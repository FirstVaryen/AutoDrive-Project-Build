trigger OpportunityCarAssign on Opportunity (before insert, before update) {
    OpportunityCarAssign.nameFromModel(Trigger.new, Trigger.oldMap);
    OpportunityCarAssign.assign(Trigger.new, Trigger.oldMap);
}
