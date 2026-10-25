@IsTest
private class PlanProgressTest {
    @IsTest static void lateMonthShowsInProgressAndNextStep() {
        Account a = new Account(Name = 'Test Buyer'); insert a;
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'Test Type', List_Price__c = 1000); insert m;
        Vehicle__c car = new Vehicle__c(Name = 'Car P', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'PPT01'); insert car;
        Opportunity o = new Opportunity(Name = 'Plan test', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(10), Vehicle__c = car.Id);
        insert o;
        Guarantor__c g = new Guarantor__c(Name = 'Test Guarantor', Income_Check_Done__c = true); insert g;
        Instalment_Plan__c p = new Instalment_Plan__c(Name = 'x', Opportunity__c = o.Id, Guarantor__c = g.Id, Term_in_Months__c = 2,
                                                      Down_Payment_Amount__c = 300, Down_Payment_Percent__c = 30);
        insert p;
        delete [SELECT Id FROM Instalment__c WHERE Instalment_Plan__c = :p.Id];
        insert new List<Instalment__c>{
            new Instalment__c(Name = 'Test Buyer - Month 1 of 2', Instalment_Plan__c = p.Id, Amount_Due__c = 350, Amount_Paid__c = 350, Due_Date__c = Date.today().addDays(-40), Status__c = 'Paid'),
            new Instalment__c(Name = 'Test Buyer - Month 2 of 2', Instalment_Plan__c = p.Id, Amount_Due__c = 350, Due_Date__c = Date.today().addDays(-5), Status__c = 'Late') };
        Test.startTest();
        update new Instalment_Plan__c(Id = p.Id, Head_of_Finance_Sign_off__c = true);
        Test.stopTest();
        p = [SELECT Progress__c, Next_Step__c FROM Instalment_Plan__c WHERE Id = :p.Id];
        System.assert(p.Progress__c.contains('Month 1 of 2') && p.Progress__c.contains('PAID'), p.Progress__c);
        System.assert(p.Progress__c.contains('LATE by 5 days'), p.Progress__c);
        System.assert(p.Next_Step__c.contains('5 days late'), p.Next_Step__c);
        new PlanProgress().execute(null);
    }

    @IsTest static void unmatchedDayIsFlaggedAndMatchedDayIsMatched() {
        Reconciliation_Entry__c e = new Reconciliation_Entry__c(Date__c = Date.newInstance(2001, 1, 1), Bank_Total__c = 500);
        insert e;
        e = [SELECT Recorded_Total__c, Status__c FROM Reconciliation_Entry__c WHERE Id = :e.Id];
        System.assertEquals(0, e.Recorded_Total__c);
        System.assertEquals('Flagged', e.Status__c);
        update new Reconciliation_Entry__c(Id = e.Id, Bank_Total__c = 0);
        System.assertEquals('Matched', [SELECT Status__c FROM Reconciliation_Entry__c WHERE Id = :e.Id].Status__c);
        Reconciliation.touchDays(new Set<Date>{ Date.newInstance(2001, 1, 1) });
    }
}
