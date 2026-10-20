@IsTest
private class SaleVehicleHandlerTest {
    @IsTest static void removeLineReleasesCarAndUpdatesSummary() {
        Id fleetRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Fleet_Corporate'].Id;
        Account a = new Account(Name = 'Test Fleet Co', RecordTypeId = fleetRt); insert a;
        Opportunity o = new Opportunity(Name = 'Fleet test', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(10));
        insert o;
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'Test Type 2026 White', List_Price__c = 1000); insert m;
        List<Vehicle__c> cars = new List<Vehicle__c>{ new Vehicle__c(Name = 'Car A', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'TSTA1'),
                                                      new Vehicle__c(Name = 'Car B', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'TSTB1') };
        insert cars;
        Sale_Vehicle__c l1 = new Sale_Vehicle__c(Opportunity__c = o.Id, Vehicle__c = cars[0].Id, Vehicle_Model__c = m.Id);
        Sale_Vehicle__c l2 = new Sale_Vehicle__c(Opportunity__c = o.Id, Vehicle__c = cars[1].Id, Vehicle_Model__c = m.Id);
        insert new List<Sale_Vehicle__c>{ l1, l2 };
        System.assert([SELECT Fleet_Summary__c FROM Opportunity WHERE Id = :o.Id].Fleet_Summary__c.startsWith('2 x Test Type 2026 White'));
        update new Vehicle__c(Id = cars[1].Id, Status__c = 'Reserved');
        Test.startTest();
        delete l2;
        Test.stopTest();
        System.assertEquals('Available', [SELECT Status__c FROM Vehicle__c WHERE Id = :cars[1].Id].Status__c);
        System.assert([SELECT Fleet_Summary__c FROM Opportunity WHERE Id = :o.Id].Fleet_Summary__c.startsWith('1 x Test Type 2026 White'));
    }
}
