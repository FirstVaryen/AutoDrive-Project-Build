// AutoDrive sample data for testing the build (Stage 9/14 checks, before the full Stage 11 data set).
// Run: sf apex run -o autodrive-dev -f scripts/apex/seed_test_data.apex
// Every record name starts with "AD Test" so it can be found and removed. Stops if it has already run.
// Customers are created as Leads and converted, so Closed_Won_Requires_Converted_Lead sees them as genuine.

if (![SELECT Id FROM Showroom__c WHERE Name LIKE 'AD Test%' LIMIT 1].isEmpty()) {
    System.debug('AD Test data already present - nothing done.');
    return;
}

Map<String, Id> users = new Map<String, Id>();
for (User u : [SELECT Id, Username FROM User WHERE Username LIKE 'test.%@autodrive.group3sb.test']) {
    users.put(u.Username.substringBefore('@').substringAfter('test.'), u.Id);
}
Id salesRep = users.get('salesrep');
Id showroomManager = users.get('showroommanager');
Id financeTeam = users.get('financeteam');

Map<String, Id> accountTypes = new Map<String, Id>();
for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName IN ('Individual', 'Fleet_Corporate')]) {
    accountTypes.put(rt.DeveloperName, rt.Id);
}
Map<String, Id> vehicleTypes = new Map<String, Id>();
for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Vehicle__c']) {
    vehicleTypes.put(rt.DeveloperName, rt.Id);
}

// One showroom (AutoDrive runs a single location). Capacity 25: the 20 sample vehicles minus 2 sold leaves room to test the capacity rule.
Showroom__c lagos = new Showroom__c(Name = 'AD Test - Lagos Main', City__c = 'Lagos', Capacity__c = 25);
insert lagos;

// Models: CR-V has 2 vehicles against a threshold of 5, so its page blinks; Corolla stays green.
Vehicle_Model__c corolla = new Vehicle_Model__c(Name = 'AD Test - Toyota Corolla', List_Price__c = 25000000, Low_stock_Threshold__c = 3);
Vehicle_Model__c hilux = new Vehicle_Model__c(Name = 'AD Test - Toyota Hilux', List_Price__c = 45000000, Low_stock_Threshold__c = 2);
Vehicle_Model__c crv = new Vehicle_Model__c(Name = 'AD Test - Honda CR-V', List_Price__c = 38000000, Low_stock_Threshold__c = 5);
insert new List<Vehicle_Model__c>{ corolla, hilux, crv };

List<Vehicle__c> vehicles = new List<Vehicle__c>();
Integer n = 1;
for (Vehicle_Model__c m : new List<Vehicle_Model__c>{ corolla, corolla, corolla, corolla, corolla, hilux, hilux, hilux, crv, crv }) {
    vehicles.add(new Vehicle__c(
        Name = 'AD Test ' + m.Name.removeStart('AD Test - ') + ' #' + n,
        Model__c = m.Id,
        Showroom__c = lagos.Id,
        Status__c = 'Available',
        Year__c = 2026,
        Colour__c = Math.mod(n, 2) == 0 ? 'Silver' : 'White',
        Chassis_Number__c = 'ADTEST' + String.valueOf(1000 + n),
        Arrival_Date__c = Date.today().addDays(-30 + n),
        RecordTypeId = vehicleTypes.get('New')
    ));
    n++;
}
insert vehicles;

// Leads, owned by the Sales Rep. Tunde stays unconverted.
Lead adaeze = new Lead(FirstName = 'Adaeze', LastName = 'AD Test Okafor', Company = 'AD Test Adaeze Okafor', Channel__c = 'Walk-in', Phone = '+2348010000001', Email = 'adaeze.okafor@example.com', OwnerId = salesRep);
Lead chinedu = new Lead(FirstName = 'Chinedu', LastName = 'AD Test Eze', Company = 'AD Test Chinedu Eze', Channel__c = 'Web', Phone = '+2348010000002', Email = 'chinedu.eze@example.com', OwnerId = salesRep);
Lead kano = new Lead(FirstName = 'Musa', LastName = 'AD Test Bello', Company = 'AD Test Kano Logistics Ltd', Channel__c = 'Returning/High-profile', Phone = '+2348010000003', Email = 'fleet@kanologistics.example.com', OwnerId = salesRep);
Lead tunde = new Lead(FirstName = 'Tunde', LastName = 'AD Test Bakare', Company = 'AD Test Tunde Bakare', Channel__c = 'Instagram', Phone = '+2348010000004', Email = 'tunde.bakare@example.com', OwnerId = salesRep);
insert new List<Lead>{ adaeze, chinedu, kano, tunde };

String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
List<Database.LeadConvert> converts = new List<Database.LeadConvert>();
for (Lead l : new List<Lead>{ adaeze, chinedu, kano }) {
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id);
    lc.setConvertedStatus(convertedStatus);
    lc.setOwnerId(salesRep);
    lc.setOpportunityName(l.Company.replace('AD Test ', 'AD Test Sale - '));
    converts.add(lc);
}
List<Database.LeadConvertResult> results = Database.convertLead(converts);
Database.LeadConvertResult rAdaeze = results[0], rChinedu = results[1], rKano = results[2];

update new List<Account>{
    new Account(Id = rAdaeze.getAccountId(), RecordTypeId = accountTypes.get('Individual')),
    new Account(Id = rChinedu.getAccountId(), RecordTypeId = accountTypes.get('Individual')),
    new Account(Id = rKano.getAccountId(), RecordTypeId = accountTypes.get('Fleet_Corporate'))
};

// Opportunities from conversion: Adaeze pays in full, Chinedu by instalment, Kano fleet by instalment with a discount.
Opportunity oppAdaeze = new Opportunity(Id = rAdaeze.getOpportunityId(), StageName = 'Negotiation', CloseDate = Date.today().addDays(7),
    Payment_Mode__c = 'Full Payment', Vehicle__c = vehicles[0].Id, Amount = 25000000, Sale_Price__c = 25000000);
Opportunity oppChinedu = new Opportunity(Id = rChinedu.getOpportunityId(), StageName = 'Negotiation', CloseDate = Date.today().addDays(14),
    Payment_Mode__c = 'Instalment', Vehicle__c = vehicles[5].Id, Amount = 45000000, Sale_Price__c = 45000000);
Opportunity oppKano = new Opportunity(Id = rKano.getOpportunityId(), StageName = 'Proposal/Quote', CloseDate = Date.today().addDays(21),
    Payment_Mode__c = 'Instalment', Vehicle__c = vehicles[6].Id, Amount = 45000000, Sale_Price__c = 45000000);
update new List<Opportunity>{ oppAdaeze, oppChinedu, oppKano };

// Not from a Lead: closing this one as Closed Won must be blocked.
Account direct = new Account(Name = 'AD Test Direct Walk-in (no Lead)', RecordTypeId = accountTypes.get('Individual'), OwnerId = salesRep);
insert direct;
insert new Opportunity(Name = 'AD Test Sale - Direct (no Lead)', AccountId = direct.Id, OwnerId = salesRep, StageName = 'Negotiation',
    CloseDate = Date.today().addDays(7), Payment_Mode__c = 'Full Payment', Vehicle__c = vehicles[1].Id, Amount = 25000000, Sale_Price__c = 25000000);

// Discount request on the fleet sale, sitting with the Showroom Manager.
Discount_Request__c discount = new Discount_Request__c(Opportunity__c = oppKano.Id, Requested_By__c = salesRep, Requested_Discount__c = 5,
    Reason__c = 'Fleet order of multiple Hilux units; matching competitor quote.', Current_Step__c = 'With Showroom Manager');
insert discount;
insert new Approval_Step__c(Discount_Request__c = discount.Id, Step__c = 'Showroom Manager', Decision__c = 'Pending');

// Chinedu's instalment plan: 30% down, 12 months, guarantor income checked.
Guarantor__c guarantor = new Guarantor__c(Name = 'AD Test Ngozi Eze', Phone__c = '+2348010000005', Income_Check_Done__c = true);
insert guarantor;
Instalment_Plan__c plan = new Instalment_Plan__c(Opportunity__c = oppChinedu.Id, Guarantor__c = guarantor.Id, Down_Payment_Percent__c = 30,
    Down_Payment_Amount__c = 13500000, Term_in_Months__c = 12, Ownership_Documents_Status__c = 'Not Started');
insert plan;
List<Instalment__c> instalments = new List<Instalment__c>{
    new Instalment__c(Instalment_Plan__c = plan.Id, Amount_Due__c = 2625000, Amount_Paid__c = 2625000, Due_Date__c = Date.today().addDays(-30), Status__c = 'Paid'),
    new Instalment__c(Instalment_Plan__c = plan.Id, Amount_Due__c = 2625000, Due_Date__c = Date.today().addDays(-5), Status__c = 'Late'),
    new Instalment__c(Instalment_Plan__c = plan.Id, Amount_Due__c = 2625000, Due_Date__c = Date.today().addDays(3), Status__c = 'Upcoming')
};
insert instalments;

insert new List<Payment__c>{
    new Payment__c(Opportunity__c = oppChinedu.Id, Type__c = 'Down Payment', Method__c = 'Bank Transfer', Amount__c = 13500000, Paid_On__c = Date.today().addDays(-35), Recorded_By__c = financeTeam),
    new Payment__c(Opportunity__c = oppChinedu.Id, Instalment__c = instalments[0].Id, Type__c = 'Instalment', Method__c = 'Card', Amount__c = 2625000, Paid_On__c = Date.today().addDays(-30), Recorded_By__c = financeTeam)
};

insert new Reconciliation_Entry__c(Date__c = Date.today().addDays(-1), Bank_Account__c = 'AD Test GTBank Operations', Bank_Total__c = 16125000,
    Recorded_Total__c = 16125000, Status__c = 'Matched', Note__c = 'Chinedu Eze down payment and first instalment.');

// Import request: customer wants a CR-V the showrooms don't have enough of.
insert new Import_Request__c(Account__c = rAdaeze.getAccountId(), Vehicle_Model__c = crv.Id, Requested_By__c = salesRep,
    Status__c = 'Requested', Expected_Arrival__c = Date.today().addDays(45));

// Service: one case per routing type, from converted customers.
List<Case> cases = new List<Case>{
    new Case(Subject = 'AD Test - Instalment payment not reflected', Type = 'Payment', Origin = 'Phone', ContactId = rChinedu.getContactId(), AccountId = rChinedu.getAccountId()),
    new Case(Subject = 'AD Test - Question about Corolla delivery date', Type = 'Sales', Origin = 'Web', ContactId = rAdaeze.getContactId(), AccountId = rAdaeze.getAccountId()),
    new Case(Subject = 'AD Test - Dashboard warning light', Type = 'Technical', Origin = 'Email', ContactId = rAdaeze.getContactId(), AccountId = rAdaeze.getAccountId())
};
// Case creation can be blocked by demo-org automation on Case (SDO_Service_Case_Creation fails on every insert),
// so cases are attempted separately and skipped with a message rather than rolling back the whole data set.
// Re-run just this part with scripts/apex/seed_test_cases.apex once Case creation works.
Savepoint beforeCases = Database.setSavepoint();
try {
    insert cases;
    insert new Customer_Message__c(Case__c = cases[0].Id, Account__c = rChinedu.getAccountId(), Channel__c = 'Email',
        Type__c = 'Acknowledgement', Message_Text__c = 'We have received your query about your instalment payment.', Sent_At__c = System.now(), Sent_By__c = 'Customer Service');
} catch (DmlException e) {
    Database.rollback(beforeCases);
    System.debug(LoggingLevel.ERROR, 'AD Test cases skipped: ' + e.getMessage());
}
insert new Knowledge_Article__c(Name = 'AD Test - How instalment payments are confirmed', Status__c = 'Published',
    Issue_Description__c = 'Customer has paid an instalment but it does not show yet.',
    Agreed_Answer__c = 'Bank transfers are reconciled daily. Payments show within one working day of the bank confirming them.');

// Legal escalation for the late instalment.
insert new Legal_Escalation__c(Account__c = rChinedu.getAccountId(), Instalment_Plan__c = plan.Id, Guarantor_Information__c = guarantor.Id,
    Status__c = 'Open', Escalated_By__c = financeTeam, Escalated_On__c = Date.today(), Vehicle_Purchased__c = 'Toyota Hilux 2026',
    Contract_Number__c = 'AD-TEST-0001', Amount_Paid__c = 16125000, Total_Amount_Owed__c = 28875000, Number_of_Missed_Payments__c = 1,
    Months_Defaulted__c = 1, Note__c = 'Sample escalation for testing.');

System.debug('AD Test data created.');
