// Creates a fresh set of Sales Rep test records so the Sales Rep tests in docs/AutoDrive_Test_Plan.md can be re-run.
// Closed sales are locked for everyone, so instead of resetting old records this makes new ones, named
// "AD Rerun <MMdd-HHmm> ...". Run as many times as needed:
//   sf apex run -o autodrive-dev -f scripts/apex/fresh_sales_test_records.apex
// Creates (owner: TestSales Rep):
//   1. Customer "AD Rerun <stamp> Individual" from a converted Lead, with an open Full Payment sale at Offer and an available car  (close test, discount tests)
//   2. A second open Full Payment sale for the same customer with a 7.5% discount already approved through the real 3-step chain  (switch-to-instalment test)
//   3. A sale for an account that never came from a Lead  (blocked-close test)
//   4. An open Lead at New with phone, purpose and vehicle  (qualify / convert tests)

String stamp = Datetime.now().format('MMdd-HHmm');
Id salesRep = [SELECT Id FROM User WHERE Username = 'test.salesrep@autodrive.group3sb.test'].Id;
Id leadRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'AutoDrive_Lead'].Id;
Id oppRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'AutoDrive_Sale'].Id;
Id individualRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual'].Id;
Id camry = [SELECT Id FROM Vehicle_Model__c WHERE Name = 'AD Test - Toyota Camry'].Id;

List<Vehicle__c> cars = [SELECT Id, Name FROM Vehicle__c WHERE Status__c = 'Available' AND Id NOT IN (SELECT Vehicle__c FROM Opportunity WHERE IsClosed = false AND Vehicle__c != null) ORDER BY Name LIMIT 3];
if (cars.size() < 3) {
    // Not enough free cars: add new ones to the showroom (capacity permitting).
    for (Integer i = cars.size(); i < 3; i++) {
        Vehicle__c v = new Vehicle__c(Name = 'AD Rerun ' + stamp + ' Camry ' + i, Model__c = camry, Status__c = 'Available', Year__c = 2026, Colour__c = 'White', Chassis_Number__c = 'ADRERUN' + stamp.replace('-', '') + i);
        insert v;
        cars.add(v);
    }
}

// 1. Customer from a converted Lead + open sale at Offer.
Lead l = new Lead(RecordTypeId = leadRt, FirstName = 'Rerun', LastName = 'AD Rerun ' + stamp + ' Individual', Company = 'AD Rerun ' + stamp + ' Individual',
    Customer_Type__c = 'Individual', Visit_Purpose__c = 'Purchase', Vehicle_Model_Of_Interest__c = camry, Channel__c = 'Walk-in',
    Phone = '+23480' + stamp.replace('-', ''), Status = 'Qualified', OwnerId = salesRep);
insert l;
Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(l.Id);
lc.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true AND MasterLabel = 'Converted' LIMIT 1].MasterLabel);
lc.setOwnerId(salesRep);
lc.setOpportunityName('AD Rerun ' + stamp + ' Sale 1 (open)');
Database.LeadConvertResult r = Database.convertLead(lc);
update new Account(Id = r.getAccountId(), RecordTypeId = individualRt);
update new Opportunity(Id = r.getOpportunityId(), RecordTypeId = oppRt, StageName = 'Offer', CloseDate = Date.today().addDays(14),
    Payment_Mode__c = 'Full Payment', Vehicle__c = cars[0].Id, Amount = 32000000, Sale_Price__c = 32000000);

// 2. Second sale with a 7.5% discount approved through Showroom Manager -> Finance -> Head Office.
Opportunity o2 = new Opportunity(RecordTypeId = oppRt, Name = 'AD Rerun ' + stamp + ' Sale 2 (discount approved)', AccountId = r.getAccountId(), OwnerId = salesRep,
    StageName = 'Offer', CloseDate = Date.today().addDays(14), Payment_Mode__c = 'Full Payment', Vehicle__c = cars[1].Id, Amount = 32000000, Sale_Price__c = 32000000);
insert o2;
Discount_Request__c d = new Discount_Request__c(Opportunity__c = o2.Id, Discount_Rate__c = '7.5%', Reason__c = 'Rerun test discount');
insert d;
for (Integer i = 0; i < 3; i++) {
    List<ProcessInstanceWorkitem> wi = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :d.Id];
    if (wi.isEmpty()) break;
    Approval.ProcessWorkitemRequest a = new Approval.ProcessWorkitemRequest();
    a.setWorkitemId(wi[0].Id);
    a.setAction('Approve');
    Approval.process(a);
}

// 3. Account that never came from a Lead.
Account direct = new Account(Name = 'AD Rerun ' + stamp + ' No Lead', RecordTypeId = individualRt, OwnerId = salesRep);
insert direct;
insert new Opportunity(RecordTypeId = oppRt, Name = 'AD Rerun ' + stamp + ' Sale 3 (no Lead)', AccountId = direct.Id, OwnerId = salesRep,
    StageName = 'Offer', CloseDate = Date.today().addDays(14), Payment_Mode__c = 'Full Payment', Vehicle__c = cars[2].Id, Amount = 32000000, Sale_Price__c = 32000000);

// 4. Open lead at New.
insert new Lead(RecordTypeId = leadRt, FirstName = 'Open', LastName = 'AD Rerun ' + stamp + ' Lead', Company = 'AD Rerun ' + stamp + ' Lead',
    Customer_Type__c = 'Individual', Visit_Purpose__c = 'Enquiry', Vehicle_Model_Of_Interest__c = camry, Channel__c = 'Web',
    Email = 'rerun' + stamp.replace('-', '') + '@example.com', OwnerId = salesRep);

System.debug('AD Rerun ' + stamp + ' created: step after approvals = ' + [SELECT Current_Step__c FROM Discount_Request__c WHERE Id = :d.Id].Current_Step__c);
