// When a lead lands in the AD Website Leads queue, try to give it to an online Sales Rep straight away (LeadAutoAssigner).
trigger LeadAutoAssign on Lead (after insert, after update) {
    Boolean inQueue = false;
    for (Lead l : Trigger.new) {
        if (String.valueOf(l.OwnerId).startsWith('00G') && (Trigger.isInsert || Trigger.oldMap.get(l.Id).OwnerId != l.OwnerId)) inQueue = true;
    }
    if (inQueue && !System.isQueueable() && !System.isBatch() && !System.isFuture()
        && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
        System.enqueueJob(new LeadAutoAssigner());
    }
}
