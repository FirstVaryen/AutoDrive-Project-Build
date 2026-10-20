/**
 * Gives work waiting in a team queue to a team member who is online (US-11, US-30, US-06).
 * - Online = logged in to Salesforce right now (an active login session, or an admin "Login As" them); logged out = offline.
 * - Each person holds at most a set number of open items; the one with the fewest gets the next,
 *   ties go to whoever was given work longest ago (round robin).
 * - Work nobody can take waits in the queue; the scheduled run (every 5 minutes) tries again.
 * Queues and teams:
 *   AD_Web_Leads      (Lead) -> AutoDrive Sales Rep, max 5 open leads
 *   AD_Finance_Cases  (Case) -> AutoDrive Finance Team, max 5 open cases
 *   AD_Showroom_Cases (Case) -> AutoDrive Showroom Manager, max 5 open cases
 *   Customer_Service  (Case) -> AutoDrive Customer Service Agent, max 5 open cases
 */
public without sharing class AutoAssigner implements Queueable {
    public class Team {
        public String objectName; public String queueName; public String profileName; public Integer maxOpen;
        Team(String o, String q, String p, Integer m) { objectName = o; queueName = q; profileName = p; maxOpen = m; }
    }
    public static final List<Team> TEAMS = new List<Team>{
        new Team('Lead', 'AD_Web_Leads', 'AutoDrive Sales Rep', 5),
        new Team('Case', 'AD_Finance_Cases', 'AutoDrive Finance Team', 5),
        new Team('Case', 'AD_Showroom_Cases', 'AutoDrive Showroom Manager', 5),
        new Team('Case', 'Customer_Service', 'AutoDrive Customer Service Agent', 5)
    };
    @TestVisible static Set<Id> onlineOverride;

    public void execute(QueueableContext ctx) { assignAll(); }

    /** The 5-minute retry. (A class cannot be both Queueable and Schedulable.) */
    public class Retry implements Schedulable {
        public void execute(SchedulableContext ctx) { assignAll(); }
    }

    /** Run once: AutoAssigner.scheduleEvery5Minutes(); */
    public static void scheduleEvery5Minutes() {
        for (Integer m = 0; m < 60; m += 5) {
            System.schedule('AD Auto Assign :' + String.valueOf(m).leftPad(2, '0'), '0 ' + m + ' * * * ?', new AutoAssigner.Retry());
        }
    }

    /** Enqueues one run unless already async or out of queueable jobs (called from the triggers). */
    public static void enqueue() {
        if (!System.isQueueable() && !System.isBatch() && !System.isFuture() && !System.isScheduled()
            && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new AutoAssigner());
        }
    }

    public static Integer assignAll() {
        Integer n = 0;
        for (Team t : TEAMS) n += assign(t);
        return n;
    }

    public static Integer assign(Team t) {
        List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :t.queueName LIMIT 1];
        if (queues.isEmpty()) return 0;
        Id queueId = queues[0].Id;
        String openFilter = t.objectName == 'Lead' ? 'IsConverted = false' : 'IsClosed = false';
        List<SObject> waiting = Database.query('SELECT Id FROM ' + t.objectName + ' WHERE OwnerId = :queueId AND ' + openFilter + ' ORDER BY CreatedDate LIMIT 200');
        if (waiting.isEmpty()) return 0;

        Set<Id> online = onlineMembers(t.profileName);
        if (online.isEmpty()) return 0;

        Map<Id, Integer> openCount = new Map<Id, Integer>();
        Map<Id, Datetime> lastGiven = new Map<Id, Datetime>();
        for (Id u : online) { openCount.put(u, 0); lastGiven.put(u, Datetime.newInstance(2000, 1, 1)); }
        for (AggregateResult ar : Database.query('SELECT OwnerId o, COUNT(Id) n, MAX(Auto_Assigned_At__c) lastAt FROM ' + t.objectName
                + ' WHERE OwnerId IN :online AND ' + openFilter + ' GROUP BY OwnerId')) {
            openCount.put((Id) ar.get('o'), (Integer) ar.get('n'));
            if (ar.get('lastAt') != null) lastGiven.put((Id) ar.get('o'), (Datetime) ar.get('lastAt'));
        }

        List<SObject> updates = new List<SObject>();
        Datetime now = System.now();
        for (SObject rec : waiting) {
            Id pick;
            for (Id u : online) {
                if (openCount.get(u) >= t.maxOpen) continue;
                if (pick == null || openCount.get(u) < openCount.get(pick)
                    || (openCount.get(u) == openCount.get(pick) && lastGiven.get(u) < lastGiven.get(pick))) pick = u;
            }
            if (pick == null) break; // everyone online is full; the rest wait in the queue
            now = now.addSeconds(1); // keeps the round-robin order inside one run
            SObject u = rec.getSObjectType().newSObject(rec.Id);
            u.put('OwnerId', pick);
            u.put('Auto_Assigned_At__c', now);
            updates.add(u);
            openCount.put(pick, openCount.get(pick) + 1);
            lastGiven.put(pick, now);
        }
        if (!updates.isEmpty()) {
            Database.DMLOptions opts = new Database.DMLOptions();
            opts.EmailHeader.triggerUserEmail = true; // the person gets the standard "assigned to you" email
            Database.update(updates, opts);
        }
        return updates.size();
    }

    /** Active users of the profile with a login session that has not expired (includes "Login As" sessions). */
    static Set<Id> onlineMembers(String profileName) {
        Set<Id> members = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = true AND Profile.Name = :profileName]).keySet();
        if (Test.isRunningTest() && onlineOverride != null) { members = new Set<Id>(members); members.retainAll(onlineOverride); return members; }
        Set<Id> online = new Set<Id>();
        for (AuthSession s : [SELECT UsersId, LastModifiedDate, NumSecondsValid FROM AuthSession
                              WHERE UsersId IN :members AND SessionType IN ('UI', 'SubstituteUser')]) {
            if (s.LastModifiedDate.addSeconds(s.NumSecondsValid) > System.now()) online.add(s.UsersId);
        }
        // "Login As" sessions are recorded under the admin, not the user. The audit trail logs
        // "Logged in using Login-As access for <Name>" / "Logged out using Login-As access for <Name>";
        // count anyone whose latest such event in the last 2 hours is a log-in.
        Map<String, Id> byName = new Map<String, Id>();
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :members]) byName.put(u.Name, u.Id);
        Set<String> seen = new Set<String>();
        for (SetupAuditTrail t : [SELECT Display FROM SetupAuditTrail WHERE CreatedDate >= :System.now().addHours(-2)
                                  ORDER BY CreatedDate DESC LIMIT 2000]) {
            if (t.Display == null || !t.Display.contains('using Login-As access for ')) continue;
            String name = t.Display.substringAfter('using Login-As access for ').trim();
            if (!byName.containsKey(name) || !seen.add(name)) continue;
            if (t.Display.startsWith('Logged in')) online.add(byName.get(name));
        }
        return online;
    }
}
