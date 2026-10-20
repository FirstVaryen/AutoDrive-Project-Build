/**
 * Gives website leads waiting in the AD Website Leads queue to Sales Reps automatically (US-11, US-30).
 * - Only reps whose Omni-Channel status is Available get leads (Offline reps get none).
 * - A rep with 5 or more open leads gets no more until one is converted or closed.
 * - The rep with the fewest open leads gets the next one; ties go to whoever was given a lead longest ago (round robin).
 * - Leads nobody can take stay in the queue; the scheduled run (every 5 minutes) tries again.
 * Runs from the Lead trigger (straight after a lead lands in the queue) and on a schedule.
 */
public without sharing class LeadAutoAssigner implements Queueable {
    public static final Integer MAX_OPEN_LEADS = 5;
    public static final String QUEUE_NAME = 'AD_Web_Leads';
    public static final String REP_PROFILE = 'AutoDrive Sales Rep';
    public static final Set<String> AVAILABLE_STATUSES = new Set<String>{ 'AD_Leads_Available', 'AD_Available' };
    @TestVisible static Set<Id> onlineOverride;

    public void execute(QueueableContext ctx) { assignWaitingLeads(); }
    /** The 5-minute retry. (Salesforce does not allow one class to be both Queueable and Schedulable.) */
    public class Retry implements Schedulable {
        public void execute(SchedulableContext ctx) { assignWaitingLeads(); }
    }

    /** Schedules the 5-minute retry (twelve hourly jobs). Run once: LeadAutoAssigner.scheduleEvery5Minutes(); */
    public static void scheduleEvery5Minutes() {
        for (Integer m = 0; m < 60; m += 5) {
            System.schedule('AD Lead Auto Assign :' + String.valueOf(m).leftPad(2, '0'), '0 ' + m + ' * * * ?', new LeadAutoAssigner.Retry());
        }
    }

    public static Integer assignWaitingLeads() {
        List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :QUEUE_NAME LIMIT 1];
        if (queues.isEmpty()) return 0;
        List<Lead> waiting = [SELECT Id FROM Lead WHERE OwnerId = :queues[0].Id AND IsConverted = false ORDER BY CreatedDate LIMIT 200];
        if (waiting.isEmpty()) return 0;

        Set<Id> online = onlineReps();
        if (online.isEmpty()) return 0;

        Map<Id, Integer> openCount = new Map<Id, Integer>();
        Map<Id, Datetime> lastGiven = new Map<Id, Datetime>();
        for (Id u : online) { openCount.put(u, 0); lastGiven.put(u, Datetime.newInstance(2000, 1, 1)); }
        for (AggregateResult ar : [SELECT OwnerId o, COUNT(Id) n, MAX(Auto_Assigned_At__c) lastAt FROM Lead
                                   WHERE OwnerId IN :online AND IsConverted = false GROUP BY OwnerId]) {
            openCount.put((Id) ar.get('o'), (Integer) ar.get('n'));
            if (ar.get('lastAt') != null) lastGiven.put((Id) ar.get('o'), (Datetime) ar.get('lastAt'));
        }

        List<Lead> updates = new List<Lead>();
        Datetime now = System.now();
        for (Lead l : waiting) {
            Id pick;
            for (Id u : online) {
                if (openCount.get(u) >= MAX_OPEN_LEADS) continue;
                if (pick == null || openCount.get(u) < openCount.get(pick)
                    || (openCount.get(u) == openCount.get(pick) && lastGiven.get(u) < lastGiven.get(pick))) pick = u;
            }
            if (pick == null) break; // everyone online is full; the rest wait in the queue
            now = now.addSeconds(1); // keeps the round-robin order inside one run
            updates.add(new Lead(Id = l.Id, OwnerId = pick, Auto_Assigned_At__c = now));
            openCount.put(pick, openCount.get(pick) + 1);
            lastGiven.put(pick, now);
        }
        if (!updates.isEmpty()) {
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.EmailHeader.triggerUserEmail = true; // the rep gets the standard "lead assigned to you" email
            Database.update(updates, opts);
        }
        return updates.size();
    }

    /** Active Sales Reps whose Omni-Channel status is Available right now. */
    static Set<Id> onlineReps() {
        Set<Id> reps = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = true AND Profile.Name = :REP_PROFILE]).keySet();
        if (Test.isRunningTest() && onlineOverride != null) { reps = new Set<Id>(reps); reps.retainAll(onlineOverride); return reps; }
        Set<Id> online = new Set<Id>();
        for (UserServicePresence p : [SELECT UserId FROM UserServicePresence
                                      WHERE UserId IN :reps AND IsCurrentState = true AND ServicePresenceStatus.DeveloperName IN :AVAILABLE_STATUSES]) {
            online.add(p.UserId);
        }
        return online;
    }
}
