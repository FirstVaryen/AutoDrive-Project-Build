trigger LeadCreatorAccess on Lead (before update, after insert, after update) {
    if (Trigger.isBefore) LeadCreatorAccess.routeHighProfile(Trigger.new, Trigger.oldMap);
    else if (Trigger.isInsert) LeadCreatorAccess.grant(Trigger.new);
    else {
        // only leads whose owner changed
        List<Lead> moved = new List<Lead>();
        for (Lead l : Trigger.new) if (l.OwnerId != Trigger.oldMap.get(l.Id).OwnerId) moved.add(l);
        if (!moved.isEmpty()) LeadCreatorAccess.grant(moved, Trigger.oldMap);
    }
}
