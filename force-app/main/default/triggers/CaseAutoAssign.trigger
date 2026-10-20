// When a case lands in a team queue (Case_Routing), try to give it to an online team member straight away (AutoAssigner).
trigger CaseAutoAssign on Case (after insert, after update) {
    for (Case c : Trigger.new) {
        if (String.valueOf(c.OwnerId).startsWith('00G') && (Trigger.isInsert || Trigger.oldMap.get(c.Id).OwnerId != c.OwnerId)) { AutoAssigner.enqueue(); break; }
    }
}
