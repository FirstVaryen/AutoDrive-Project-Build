// Go-live UAT data, step 1 of 5 (Group3Prod): the showroom, the vehicle types and the customers the
// Sales Rep tests open directly. Cars are added in step 2. Stops if it has already run.
//   sf apex run -o autodrive-prod -f scripts/apex/prod/01_showroom_models_customers.apex

if ([SELECT COUNT() FROM Vehicle_Model__c] > 0) { System.debug('PROD DATA step 1 already done'); return; }
Id rep = [SELECT Id FROM User WHERE Username = 'henry.salesrep@autodrive.group3prod'].Id;
Id leadRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'AutoDrive_Lead'].Id;
Id oppRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'AutoDrive_Sale'].Id;
Id individualRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual'].Id;
Id fleetRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Fleet_Corporate'].Id;
String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;

insert new Showroom__c(Name = 'AutoDrive Motors - Lagos Showroom', Capacity__c = 200);

// name, list price, low-stock threshold
List<List<Object>> types = new List<List<Object>>{
    new List<Object>{ 'Honda CR-V 2026 Silver', 38000000, 2 }, new List<Object>{ 'Honda CR-V 2026 White', 38000000, 2 },
    new List<Object>{ 'Kia Sportage 2026 Black', 29000000, 2 }, new List<Object>{ 'Kia Sportage 2026 Blue', 29000000, 2 },
    new List<Object>{ 'Kia Sportage 2026 White', 29000000, 2 }, new List<Object>{ 'Toyota Camry 2026 Black', 32000000, 2 },
    new List<Object>{ 'Toyota Camry 2026 Blue', 32000000, 2 }, new List<Object>{ 'Toyota Camry 2026 Grey', 32000000, 2 },
    new List<Object>{ 'Toyota Camry 2026 Red', 32000000, 2 }, new List<Object>{ 'Toyota Camry 2026 White', 32000000, 2 },
    new List<Object>{ 'Toyota Corolla 2026 Silver', 25000000, 2 }, new List<Object>{ 'Toyota Corolla 2026 White', 25000000, 2 },
    new List<Object>{ 'Toyota Hilux 2026 Grey', 45000000, 2 }, new List<Object>{ 'Toyota Hilux 2026 Red', 45000000, 2 },
    new List<Object>{ 'Toyota Hilux 2026 Silver', 45000000, 2 }, new List<Object>{ 'Toyota Hilux 2026 White', 45000000, 2 },
    new List<Object>{ 'Toyota Land Cruiser 2026 Black', 120000000, 1 }
};
List<Vehicle_Model__c> models = new List<Vehicle_Model__c>();
for (List<Object> t : types)
    models.add(new Vehicle_Model__c(Name = (String) t[0], List_Price__c = (Integer) t[1], Low_stock_Threshold__c = (Integer) t[2]));
insert models;

Database.DMLOptions dupOk = new Database.DMLOptions();
dupOk.DuplicateRuleHeader.allowSave = true;

// customers created from a lead, as the showroom does it: name, phone, email, account type
Map<String, Id> model = new Map<String, Id>();
for (Vehicle_Model__c m : models) model.put(m.Name, m.Id);
List<List<Object>> people = new List<List<Object>>{
    new List<Object>{ 'Daniel', 'Okoro', 'Daniel Okoro', '+2348010180943', 'Toyota Hilux 2026 White', individualRt },
    new List<Object>{ 'Zainab', 'Bello', 'Zainab Bello', '08031110016', 'Honda CR-V 2026 White', individualRt },
    new List<Object>{ 'Kemi', 'Lawal', 'Lagos Ride Hailing Ltd', '08031110020', 'Toyota Hilux 2026 White', fleetRt }
};
Map<String, Database.LeadConvertResult> made = new Map<String, Database.LeadConvertResult>();
for (List<Object> p : people) {
    Lead l = new Lead(RecordTypeId = leadRt, FirstName = (String) p[0], LastName = (String) p[1], Company = (String) p[2], Phone = (String) p[3],
        Channel__c = 'Walk-in', Visit_Purpose__c = 'Purchase', Customer_Type__c = p[5] == fleetRt ? 'Fleet/Corporate' : 'Individual',
        Qualification_Answers__c = 'Budget agreed; wants to buy soon', Vehicle_Model_Of_Interest__c = model.get((String) p[4]),
        Status = 'Contacted', OwnerId = rep);
    Database.insert(l, dupOk);
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id); lc.setConvertedStatus(convertedStatus); lc.setOwnerId(rep);
    lc.setOpportunityName((String) p[2] + ' - ' + (String) p[4]);
    Database.LeadConvertResult r = Database.convertLead(lc, dupOk);
    update new Account(Id = r.getAccountId(), RecordTypeId = (Id) p[5]);
    made.put((String) p[2], r);
}
// Daniel: an earlier full-payment purchase still open at Offer
update new Opportunity(Id = made.get('Daniel Okoro').getOpportunityId(), RecordTypeId = oppRt, StageName = 'Offer', CloseDate = Date.today().addDays(30),
    Payment_Mode__c = 'Full Payment', Vehicle_Model_Wanted__c = model.get('Toyota Hilux 2026 White'));
// Zainab: instalment over 6 months, down payment not yet paid
update new Opportunity(Id = made.get('Zainab Bello').getOpportunityId(), RecordTypeId = oppRt, StageName = 'Offer', CloseDate = Date.today().addDays(30),
    Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = 6, Instalment_Down_Payment__c = 11400000, Vehicle_Model_Wanted__c = model.get('Honda CR-V 2026 White'));
update new Opportunity(Id = made.get('Zainab Bello').getOpportunityId(), StageName = 'Payment Arranged');
// Lagos Ride Hailing: the fleet opportunity, agreed discount rate 5%; fleet cars are added during the test
update new Opportunity(Id = made.get('Lagos Ride Hailing Ltd').getOpportunityId(), RecordTypeId = oppRt, Name = 'Lagos Ride Hailing Ltd - Fleet',
    StageName = 'Offer', CloseDate = Date.today().addDays(30), Payment_Mode__c = 'Full Payment', Vehicle_Model_Wanted__c = null, Vehicle__c = null);
update new Account(Id = made.get('Lagos Ride Hailing Ltd').getAccountId(), Agreed_Discount_Rate__c = 5);
update new Contact(Id = made.get('Lagos Ride Hailing Ltd').getContactId(), Title = 'Fleet Manager');
System.debug('PROD DATA step 1: ' + models.size() + ' vehicle types, customers ' + made.keySet());
