trigger LeadCreatorAccess on Lead (after insert) {
    LeadCreatorAccess.grant(Trigger.new);
}
