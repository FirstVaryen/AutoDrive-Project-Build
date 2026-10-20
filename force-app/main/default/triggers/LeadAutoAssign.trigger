// When a lead lands in a queue, try to give it to an online team member straight away (AutoAssigner).
trigger LeadAutoAssign on Lead (after insert, after update) {
    for (Lead l : Trigger.new) {
        if (String.valueOf(l.OwnerId).startsWith('00G') && (Trigger.isInsert || Trigger.oldMap.get(l.Id).OwnerId != l.OwnerId)) { AutoAssigner.enqueue(); break; }
    }
}
