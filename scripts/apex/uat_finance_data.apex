// UAT test data for the Finance tests in docs/AutoDrive_UAT.md. Safe to run more than once.
//   sf apex run -o <alias> -f scripts/apex/uat_finance_data.apex
// Creates: customer Grace Okon with an instalment opportunity at Payment Arranged (6 months, 30% down payment), no plan yet,
// and guarantor Peter Okon (income check done) for Finance to choose.

Id rep = [SELECT Id FROM User WHERE Username LIKE 'test.salesrep@%' AND IsActive = true LIMIT 1].Id;
Id leadRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'AutoDrive_Lead'].Id;
Id oppRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'AutoDrive_Sale'].Id;
Id individualRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual'].Id;
Id model = [SELECT Id FROM Vehicle_Model__c WHERE Name = 'Toyota Camry 2026 White' LIMIT 1].Id;
String oppName = 'Grace Okon - Toyota Camry 2026 White';

if ([SELECT COUNT() FROM Guarantor__c WHERE Name = 'Peter Okon'] == 0)
    insert new Guarantor__c(Name = 'Peter Okon', Phone__c = '08031110030', Income_Check_Done__c = true);

if ([SELECT COUNT() FROM Opportunity WHERE Name = :oppName] == 0) {
    Lead l = new Lead(RecordTypeId = leadRt, FirstName = 'Grace', LastName = 'Okon', Company = 'Grace Okon', Phone = '08031110031',
        Channel__c = 'Walk-in', Visit_Purpose__c = 'Purchase', Customer_Type__c = 'Individual', Vehicle_Model_Of_Interest__c = model,
        Status = 'Contacted', OwnerId = rep);
    insert l;
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id);
    lc.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
    lc.setOwnerId(rep);
    lc.setOpportunityName(oppName);
    Database.LeadConvertResult r = Database.convertLead(lc);
    update new Account(Id = r.getAccountId(), RecordTypeId = individualRt);
    update new Opportunity(Id = r.getOpportunityId(), RecordTypeId = oppRt, StageName = 'Offer', CloseDate = Date.today().addDays(30),
        Vehicle_Model_Wanted__c = model, Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = 6);
    update new Opportunity(Id = r.getOpportunityId(), StageName = 'Payment Arranged');
}
Opportunity o = [SELECT Name, StageName, Sale_Price__c, Instalment_Down_Payment__c, Monthly_Instalment__c, Vehicle__r.Name FROM Opportunity WHERE Name = :oppName];
System.debug('UAT FIN ' + o.Name + ' | ' + o.StageName + ' | price ' + o.Sale_Price__c + ' | down ' + o.Instalment_Down_Payment__c + ' | monthly ' + o.Monthly_Instalment__c + ' | ' + o.Vehicle__r.Name);
