@IsTest
private class AutoAssignerTest {
    static List<User> makeUsers(String profileName, Integer n) {
        Id prof = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        List<User> us = new List<User>();
        for (Integer i = 0; i < n; i++) {
            String u = 'adaa' + i + '.' + Crypto.getRandomInteger() + '@autodrive.test';
            us.add(new User(ProfileId = prof, Username = u, Email = u, LastName = 'Member' + i, Alias = 'adaa' + i,
                TimeZoneSidKey = 'Africa/Lagos', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'));
        }
        insert us;
        return us;
    }
    static Id queueId(String name) { return [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :name].Id; }

    @IsTest static void leadsRoundRobinOnlyToOnlineRepsCapFive() {
        List<User> reps = makeUsers('AutoDrive Sales Rep', 3);
        AutoAssigner.onlineOverride = new Set<Id>{ reps[0].Id, reps[1].Id }; // reps[2] is logged out
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 12; i++) leads.add(new Lead(LastName = 'Web ' + i, Company = 'Web ' + i, Email = 'web' + i + '@example.com', Channel__c = 'Web', OwnerId = queueId('AD_Web_Leads')));
        System.runAs(new User(Id = UserInfo.getUserId())) { insert leads; }
        Test.startTest();
        Integer n = AutoAssigner.assign(AutoAssigner.TEAMS[0]);
        Test.stopTest();
        Map<Id, Integer> per = new Map<Id, Integer>();
        for (Lead l : [SELECT OwnerId FROM Lead WHERE Id IN :leads]) per.put(l.OwnerId, (per.containsKey(l.OwnerId) ? per.get(l.OwnerId) : 0) + 1);
        System.assertEquals(10, n);
        System.assertEquals(5, per.get(reps[0].Id));
        System.assertEquals(5, per.get(reps[1].Id));
        System.assert(!per.containsKey(reps[2].Id), 'logged-out rep gets nothing');
    }

    @IsTest static void financeCaseGoesToOnlineFinanceUser() {
        List<User> fin = makeUsers('AutoDrive Finance Team', 1);
        AutoAssigner.onlineOverride = new Set<Id>{ fin[0].Id };
        Case c = new Case(Subject = 'Pay', Type = 'Payment');
        System.runAs(new User(Id = UserInfo.getUserId())) { insert c; } // Case_Routing puts it in AD Finance Cases
        Test.startTest();
        AutoAssigner.assignAll();
        Test.stopTest();
        System.assertEquals(fin[0].Id, [SELECT OwnerId FROM Case WHERE Id = :c.Id].OwnerId);
    }

    @IsTest static void nobodyOnlineLeavesWorkWaiting() {
        AutoAssigner.onlineOverride = new Set<Id>();
        System.assertEquals(0, AutoAssigner.assignAll());
    }

    @IsTest static void scheduleAndQueueable() {
        for (CronTrigger c : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AD Auto Assign%']) System.abortJob(c.Id);
        Test.startTest();
        AutoAssigner.scheduleEvery5Minutes();
        AutoAssigner.enqueue();
        Test.stopTest();
        System.assertEquals(12, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AD Auto Assign%']);
    }
}
