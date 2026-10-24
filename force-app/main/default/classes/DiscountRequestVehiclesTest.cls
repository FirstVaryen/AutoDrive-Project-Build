@IsTest
private class DiscountRequestVehiclesTest {
    @IsTest static void listsEachVehicleWithItsPriceAndTotal() {
        Id fleetRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Fleet_Corporate'].Id;
        Account a = new Account(Name = 'Test Fleet Co', RecordTypeId = fleetRt, Agreed_Discount_Rate__c = 10); insert a;
        Opportunity o = new Opportunity(Name = 'Fleet test', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(10));
        insert o;
        List<Vehicle_Model__c> ms = new List<Vehicle_Model__c>{ new Vehicle_Model__c(Name = 'Type A', List_Price__c = 1000),
                                                                new Vehicle_Model__c(Name = 'Type B', List_Price__c = 2500) };
        insert ms;
        List<Vehicle__c> cars = new List<Vehicle__c>{ new Vehicle__c(Name = 'Car A', Model__c = ms[0].Id, Status__c = 'Available', Chassis_Number__c = 'DRVA1'),
                                                      new Vehicle__c(Name = 'Car B', Model__c = ms[1].Id, Status__c = 'Available', Chassis_Number__c = 'DRVB1') };
        insert cars;
        insert new List<Sale_Vehicle__c>{ new Sale_Vehicle__c(Opportunity__c = o.Id, Vehicle__c = cars[0].Id, Vehicle_Model__c = ms[0].Id, Sale_Price__c = 1000),
                                          new Sale_Vehicle__c(Opportunity__c = o.Id, Vehicle__c = cars[1].Id, Vehicle_Model__c = ms[1].Id, Sale_Price__c = 2500) };
        Discount_Request__c d = new Discount_Request__c(Opportunity__c = o.Id);
        DiscountRequestVehicles.fill(new List<Discount_Request__c>{ d });
        System.assert(d.Vehicle_List__c.contains('Car A'), d.Vehicle_List__c);
        System.assert(d.Vehicle_List__c.contains('2,500'), d.Vehicle_List__c);
        System.assert(d.Vehicle_List__c.contains('Total for 2 vehicles: USD 3,500'), d.Vehicle_List__c);
    }
}
