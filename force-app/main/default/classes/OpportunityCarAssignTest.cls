@isTest
private class OpportunityCarAssignTest {
    @isTest static void picksAFreeCarOfTheWantedType() {
        Account a = new Account(Name = 'Car Assign Test');
        insert a;
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'Assign Model', List_Price__c = 1000);
        Vehicle_Model__c other = new Vehicle_Model__c(Name = 'Other Model', List_Price__c = 2000);
        insert new List<Vehicle_Model__c>{ m, other };
        Vehicle__c c1 = new Vehicle__c(Name = 'Assign 1', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'ASG1');
        Vehicle__c c2 = new Vehicle__c(Name = 'Assign 2', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'ASG2');
        Vehicle__c c3 = new Vehicle__c(Name = 'Other 1', Model__c = other.Id, Status__c = 'Available', Chassis_Number__c = 'OTH1');
        insert new List<Vehicle__c>{ c1, c2, c3 };

        Opportunity o1 = new Opportunity(Name = 'One', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(5), Vehicle_Model_Wanted__c = m.Id);
        Opportunity o2 = new Opportunity(Name = 'Two', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(5), Vehicle_Model_Wanted__c = m.Id);
        insert o1;
        insert o2;
        Id car1 = [SELECT Vehicle__c FROM Opportunity WHERE Id = :o1.Id].Vehicle__c;
        Id car2 = [SELECT Vehicle__c FROM Opportunity WHERE Id = :o2.Id].Vehicle__c;
        System.assertNotEquals(null, car1);
        System.assertNotEquals(null, car2);
        System.assertNotEquals(car1, car2, 'two open opportunities never hold the same car');

        // a third opportunity for the same type finds none free
        Opportunity o3 = new Opportunity(Name = 'Three', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(5), Vehicle_Model_Wanted__c = m.Id);
        insert o3;
        System.assertEquals(null, [SELECT Vehicle__c FROM Opportunity WHERE Id = :o3.Id].Vehicle__c);

        // changing the type swaps the car
        update new Opportunity(Id = o1.Id, Vehicle_Model_Wanted__c = other.Id);
        System.assertEquals(c3.Id, [SELECT Vehicle__c FROM Opportunity WHERE Id = :o1.Id].Vehicle__c);
    }
}
