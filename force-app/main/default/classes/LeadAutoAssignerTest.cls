@IsTest
private class LeadAutoAssignerTest {
    static List<User> makeReps(Integer n) {
        Id prof = [SELECT Id FROM Profile WHERE Name = :LeadAutoAssigner.REP_PROFILE].Id;
        List<User> reps = new List<User>();
        for (Integer i = 0; i < n; i++) {
            String u = 'adrr' + i + '.' + Crypto.getRandomInteger() + '@autodrive.test';
            reps.add(new User(ProfileId = prof, Username = u, Email = u, LastName = 'Rep' + i, Alias = 'adrr' + i,
                TimeZoneSidKey = 'Africa/Lagos', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'));
        }
        insert reps;
        return reps;
    }

    static List<Lead> queueLeads(Integer n) {
        Id q = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :LeadAutoAssigner.QUEUE_NAME].Id;
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < n; i++) leads.add(new Lead(LastName = 'Web ' + i, Company = 'Web ' + i, Email = 'web' + i + '@example.com', Channel__c = 'Web', OwnerId = q));
        insert leads;
        return leads;
    }

    @IsTest static void roundRobinOnlyToOnlineRepsAndCapAtFive() {
        List<User> reps = makeReps(3);
        LeadAutoAssigner.onlineOverride = new Set<Id>{ reps[0].Id, reps[1].Id }; // reps[2] is offline
        List<Lead> leads = queueLeads(12);

        Test.startTest();
        Integer n = LeadAutoAssigner.assignWaitingLeads();
        Test.stopTest();

        Map<Id, Integer> perRep = new Map<Id, Integer>();
        for (Lead l : [SELECT OwnerId FROM Lead WHERE Id IN :leads]) {
            perRep.put(l.OwnerId, (perRep.containsKey(l.OwnerId) ? perRep.get(l.OwnerId) : 0) + 1);
        }
        System.assertEquals(10, n, 'two online reps x 5 each');
        System.assertEquals(5, perRep.get(reps[0].Id));
        System.assertEquals(5, perRep.get(reps[1].Id));
        System.assert(!perRep.containsKey(reps[2].Id), 'offline rep gets nothing');
    }

    @IsTest static void nobodyOnlineLeavesLeadsInQueue() {
        makeReps(1);
        LeadAutoAssigner.onlineOverride = new Set<Id>();
        queueLeads(2);
        System.assertEquals(0, LeadAutoAssigner.assignWaitingLeads());
    }

    @IsTest static void scheduleAndQueueableRun() {
        Test.startTest();
        for (CronTrigger c : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AD Lead Auto Assign%']) System.abortJob(c.Id); // the real jobs are visible in tests
        LeadAutoAssigner.scheduleEvery5Minutes();
        System.enqueueJob(new LeadAutoAssigner());
        Test.stopTest();
        System.assertEquals(12, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AD Lead Auto Assign%']);
    }
}
