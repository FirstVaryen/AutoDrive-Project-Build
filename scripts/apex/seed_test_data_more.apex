// Second batch of AutoDrive sample data: brings the data set to 10 customer scenarios and roughly 10 records per main object.
// Run after seed_test_data.apex and seed_test_cases.apex:
//   sf apex run -o autodrive-dev -f scripts/apex/seed_test_data_more.apex
// Scenarios already present: 1 Adaeze (full payment, open), 2 Chinedu (instalment, late, legal), 3 Kano (fleet, discount pending),
// 4 Tunde (unconverted lead), 5 Direct walk-in (no Lead, can't close). Added here:
// 6 Bola (full payment, discount approved, sale closed), 7 Emeka (instalment fully paid, plan complete, documents sent),
// 8 Funke (instalment, payment due in 3 days, open payment case), 9 Lagos Ride Hailing (fleet, 20% down with sign-off,
// discount rejected, import request), 10 Ibrahim (lost sale, technical case closed with satisfaction request).

if (![SELECT Id FROM Lead WHERE LastName = 'AD Test Adeyemi' LIMIT 1].isEmpty()) {
    System.debug('AD Test batch 2 already present - nothing done.');
    return;
}

Map<String, Id> users = new Map<String, Id>();
for (User u : [SELECT Id, Username FROM User WHERE Username LIKE 'test.%@autodrive.group3sb.test']) {
    users.put(u.Username.substringBefore('@').substringAfter('test.'), u.Id);
}
Id salesRep = users.get('salesrep');
Id showroomManager = users.get('showroommanager');
Id financeTeam = users.get('financeteam');
Id headOfFinance = users.get('headoffinance');
Id legalTeam = users.get('legalteam');

Map<String, Id> accountTypes = new Map<String, Id>();
for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName IN ('Individual', 'Fleet_Corporate')]) {
    accountTypes.put(rt.DeveloperName, rt.Id);
}
Map<String, Id> vehicleTypes = new Map<String, Id>();
for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Vehicle__c']) {
    vehicleTypes.put(rt.DeveloperName, rt.Id);
}

Showroom__c lagos = [SELECT Id FROM Showroom__c WHERE Name = 'AD Test - Lagos Main'];

Map<String, Vehicle_Model__c> models = new Map<String, Vehicle_Model__c>();
for (Vehicle_Model__c m : [SELECT Id, Name FROM Vehicle_Model__c WHERE Name LIKE 'AD Test%']) models.put(m.Name, m);
Vehicle_Model__c camry = new Vehicle_Model__c(Name = 'AD Test - Toyota Camry', List_Price__c = 32000000, Low_stock_Threshold__c = 2);
Vehicle_Model__c sportage = new Vehicle_Model__c(Name = 'AD Test - Kia Sportage', List_Price__c = 29000000, Low_stock_Threshold__c = 3);
insert new List<Vehicle_Model__c>{ camry, sportage };

// 10 more vehicles, all New (AutoDrive sells new vehicles only; the Used type is switched off): 4 Camry, 3 Sportage, 2 Hilux, 1 Corolla.
List<Vehicle__c> vehicles = new List<Vehicle__c>();
List<Vehicle_Model__c> plan = new List<Vehicle_Model__c>{ camry, camry, camry, camry, sportage, sportage, sportage,
    models.get('AD Test - Toyota Hilux'), models.get('AD Test - Toyota Hilux'), models.get('AD Test - Toyota Corolla') };
for (Integer i = 0; i < plan.size(); i++) {
    Vehicle_Model__c m = plan[i];
    vehicles.add(new Vehicle__c(
        Name = 'AD Test ' + m.Name.removeStart('AD Test - ') + ' #' + (11 + i),
        Model__c = m.Id,
        Showroom__c = lagos.Id,
        Status__c = 'Available',
        Year__c = 2026,
        Colour__c = new List<String>{ 'Black', 'Blue', 'Red', 'Grey', 'White' }[Math.mod(i, 5)],
        Chassis_Number__c = 'ADTEST' + String.valueOf(1011 + i),
        Arrival_Date__c = Date.today().addDays(-20 + i),
        RecordTypeId = vehicleTypes.get('New')
    ));
}
insert vehicles;
Vehicle__c camry1 = vehicles[0], camry2 = vehicles[1], camry3 = vehicles[2], sportage1 = vehicles[4], hilux1 = vehicles[7], hilux2 = vehicles[8];

// Leads: five to convert, one (Grace) left open.
Lead bola = new Lead(FirstName = 'Bola', LastName = 'AD Test Adeyemi', Company = 'AD Test Bola Adeyemi', Channel__c = 'Walk-in', Phone = '+2348010000011', Email = 'bola.adeyemi@example.com', OwnerId = salesRep);
Lead emeka = new Lead(FirstName = 'Emeka', LastName = 'AD Test Obi', Company = 'AD Test Emeka Obi', Channel__c = 'Web', Phone = '+2348010000012', Email = 'emeka.obi@example.com', OwnerId = salesRep);
Lead funke = new Lead(FirstName = 'Funke', LastName = 'AD Test Ayo', Company = 'AD Test Funke Ayo', Channel__c = 'Instagram', Phone = '+2348010000013', Email = 'funke.ayo@example.com', OwnerId = salesRep);
Lead ride = new Lead(FirstName = 'Kemi', LastName = 'AD Test Lawal', Company = 'AD Test Lagos Ride Hailing Ltd', Channel__c = 'Returning/High-profile', Phone = '+2348010000014', Email = 'fleet@lagosride.example.com', OwnerId = salesRep);
Lead ibrahim = new Lead(FirstName = 'Ibrahim', LastName = 'AD Test Musa', Company = 'AD Test Ibrahim Musa', Channel__c = 'Walk-in', Phone = '+2348010000015', Email = 'ibrahim.musa@example.com', OwnerId = salesRep);
Lead grace = new Lead(FirstName = 'Grace', LastName = 'AD Test Nwosu', Company = 'AD Test Grace Nwosu', Channel__c = 'Web', Phone = '+2348010000016', Email = 'grace.nwosu@example.com', OwnerId = salesRep);
insert new List<Lead>{ bola, emeka, funke, ride, ibrahim, grace };

String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
List<Database.LeadConvert> converts = new List<Database.LeadConvert>();
for (Lead l : new List<Lead>{ bola, emeka, funke, ride, ibrahim }) {
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id);
    lc.setConvertedStatus(convertedStatus);
    lc.setOwnerId(salesRep);
    lc.setOpportunityName(l.Company.replace('AD Test ', 'AD Test Sale - '));
    converts.add(lc);
}
List<Database.LeadConvertResult> r = Database.convertLead(converts);
Database.LeadConvertResult rBola = r[0], rEmeka = r[1], rFunke = r[2], rRide = r[3], rIbrahim = r[4];
update new List<Account>{
    new Account(Id = rBola.getAccountId(), RecordTypeId = accountTypes.get('Individual')),
    new Account(Id = rEmeka.getAccountId(), RecordTypeId = accountTypes.get('Individual')),
    new Account(Id = rFunke.getAccountId(), RecordTypeId = accountTypes.get('Individual')),
    new Account(Id = rRide.getAccountId(), RecordTypeId = accountTypes.get('Fleet_Corporate')),
    new Account(Id = rIbrahim.getAccountId(), RecordTypeId = accountTypes.get('Individual'))
};

Id oBola = rBola.getOpportunityId(), oEmeka = rEmeka.getOpportunityId(), oFunke = rFunke.getOpportunityId(), oRide = rRide.getOpportunityId(), oIbrahim = rIbrahim.getOpportunityId();
update new List<Opportunity>{
    new Opportunity(Id = oBola, StageName = 'Negotiation', CloseDate = Date.today(), Payment_Mode__c = 'Full Payment', Vehicle__c = camry1.Id, Amount = 30400000, Sale_Price__c = 30400000),
    new Opportunity(Id = oEmeka, StageName = 'Negotiation', CloseDate = Date.today().addDays(-60), Payment_Mode__c = 'Instalment', Vehicle__c = sportage1.Id, Amount = 29000000, Sale_Price__c = 29000000),
    new Opportunity(Id = oFunke, StageName = 'Negotiation', CloseDate = Date.today().addDays(-30), Payment_Mode__c = 'Instalment', Vehicle__c = camry2.Id, Amount = 32000000, Sale_Price__c = 32000000),
    new Opportunity(Id = oRide, StageName = 'Negotiation', CloseDate = Date.today().addDays(10), Payment_Mode__c = 'Instalment', Vehicle__c = hilux1.Id, Amount = 90000000, Sale_Price__c = 90000000),
    new Opportunity(Id = oIbrahim, StageName = 'Proposal/Quote', CloseDate = Date.today().addDays(-5), Payment_Mode__c = 'Full Payment', Vehicle__c = camry3.Id, Amount = 32000000, Sale_Price__c = 32000000)
};

// Discounts: Bola's approved through all three steps; Lagos Ride's rejected at Finance.
Discount_Request__c dBola = new Discount_Request__c(Opportunity__c = oBola, Requested_By__c = salesRep, Requested_Discount__c = 5,
    Reason__c = 'Returning customer, paying in full today.', Current_Step__c = 'With Showroom Manager');
Discount_Request__c dRide = new Discount_Request__c(Opportunity__c = oRide, Requested_By__c = salesRep, Requested_Discount__c = 12,
    Reason__c = 'Two-vehicle fleet order; asking above the usual fleet rate.', Current_Step__c = 'With Showroom Manager');
insert new List<Discount_Request__c>{ dBola, dRide };
dBola.Current_Step__c = 'With Finance'; dRide.Current_Step__c = 'With Finance';
update new List<Discount_Request__c>{ dBola, dRide };
dBola.Current_Step__c = 'With Head Office'; dRide.Current_Step__c = 'Rejected';
update new List<Discount_Request__c>{ dBola, dRide };
dBola.Current_Step__c = 'Approved';
update dBola;
insert new List<Approval_Step__c>{
    new Approval_Step__c(Discount_Request__c = dBola.Id, Step__c = 'Showroom Manager', Decision__c = 'Approved', Acted_By__c = showroomManager, Acted_At__c = System.now().addHours(-6)),
    new Approval_Step__c(Discount_Request__c = dBola.Id, Step__c = 'Finance', Decision__c = 'Approved', Acted_By__c = financeTeam, Acted_At__c = System.now().addHours(-4)),
    new Approval_Step__c(Discount_Request__c = dBola.Id, Step__c = 'Head Office', Decision__c = 'Approved', Acted_By__c = headOfFinance, Acted_At__c = System.now().addHours(-2)),
    new Approval_Step__c(Discount_Request__c = dRide.Id, Step__c = 'Showroom Manager', Decision__c = 'Approved', Acted_By__c = showroomManager, Acted_At__c = System.now().addHours(-5)),
    new Approval_Step__c(Discount_Request__c = dRide.Id, Step__c = 'Finance', Decision__c = 'Rejected', Acted_By__c = financeTeam, Acted_At__c = System.now().addHours(-3), Reason__c = 'Above the fleet rate ceiling.')
};

// Bola pays in full and the sale closes (vehicle becomes Sold).
insert new Payment__c(Opportunity__c = oBola, Type__c = 'Full Payment', Method__c = 'Bank Transfer', Amount__c = 30400000, Paid_On__c = Date.today(), Recorded_By__c = financeTeam);

// Instalment plans.
List<Guarantor__c> guarantors = new List<Guarantor__c>{
    new Guarantor__c(Name = 'AD Test Chika Obi', Phone__c = '+2348010000021', Income_Check_Done__c = true),
    new Guarantor__c(Name = 'AD Test Tayo Ayo', Phone__c = '+2348010000022', Income_Check_Done__c = true),
    new Guarantor__c(Name = 'AD Test Lagos Ride Holdings', Phone__c = '+2348010000023', Income_Check_Done__c = true)
};
insert guarantors;
Instalment_Plan__c pEmeka = new Instalment_Plan__c(Opportunity__c = oEmeka, Guarantor__c = guarantors[0].Id, Down_Payment_Percent__c = 40,
    Down_Payment_Amount__c = 11600000, Term_in_Months__c = 3, Ownership_Documents_Status__c = 'In Progress');
Instalment_Plan__c pFunke = new Instalment_Plan__c(Opportunity__c = oFunke, Guarantor__c = guarantors[1].Id, Down_Payment_Percent__c = 35,
    Down_Payment_Amount__c = 11200000, Term_in_Months__c = 6, Ownership_Documents_Status__c = 'Not Started');
Instalment_Plan__c pRide = new Instalment_Plan__c(Opportunity__c = oRide, Guarantor__c = guarantors[2].Id, Down_Payment_Percent__c = 20,
    Down_Payment_Amount__c = 18000000, Term_in_Months__c = 18, Head_of_Finance_Sign_off__c = true, Signed_Off_By__c = headOfFinance,
    Signed_Off_On__c = Date.today(), Ownership_Documents_Status__c = 'Not Started');
insert new List<Instalment_Plan__c>{ pEmeka, pFunke, pRide };

List<Instalment__c> emekaInst = new List<Instalment__c>();
for (Integer i = 0; i < 3; i++) {
    emekaInst.add(new Instalment__c(Instalment_Plan__c = pEmeka.Id, Amount_Due__c = 5800000, Due_Date__c = Date.today().addDays(-50 + 20 * i), Status__c = 'Due'));
}
List<Instalment__c> funkeInst = new List<Instalment__c>{
    new Instalment__c(Instalment_Plan__c = pFunke.Id, Amount_Due__c = 3466667, Due_Date__c = Date.today().addDays(-27), Status__c = 'Paid', Amount_Paid__c = 3466667),
    new Instalment__c(Instalment_Plan__c = pFunke.Id, Amount_Due__c = 3466667, Due_Date__c = Date.today().addDays(3), Status__c = 'Upcoming'),
    new Instalment__c(Instalment_Plan__c = pFunke.Id, Amount_Due__c = 3466667, Due_Date__c = Date.today().addDays(33), Status__c = 'Upcoming')
};
List<Instalment__c> rideInst = new List<Instalment__c>{
    new Instalment__c(Instalment_Plan__c = pRide.Id, Amount_Due__c = 4000000, Due_Date__c = Date.today().addDays(30), Status__c = 'Upcoming'),
    new Instalment__c(Instalment_Plan__c = pRide.Id, Amount_Due__c = 4000000, Due_Date__c = Date.today().addDays(60), Status__c = 'Upcoming')
};
List<Instalment__c> allInst = new List<Instalment__c>();
allInst.addAll(emekaInst); allInst.addAll(funkeInst); allInst.addAll(rideInst);
insert allInst;

List<Payment__c> payments = new List<Payment__c>{
    new Payment__c(Opportunity__c = oEmeka, Type__c = 'Down Payment', Method__c = 'Bank Transfer', Amount__c = 11600000, Paid_On__c = Date.today().addDays(-60), Recorded_By__c = financeTeam),
    new Payment__c(Opportunity__c = oFunke, Type__c = 'Down Payment', Method__c = 'Card', Amount__c = 11200000, Paid_On__c = Date.today().addDays(-30), Recorded_By__c = financeTeam),
    new Payment__c(Opportunity__c = oFunke, Instalment__c = funkeInst[0].Id, Type__c = 'Instalment', Method__c = 'Card', Amount__c = 3466667, Paid_On__c = Date.today().addDays(-27), Recorded_By__c = financeTeam),
    new Payment__c(Opportunity__c = oRide, Type__c = 'Down Payment', Method__c = 'Bank Transfer', Amount__c = 18000000, Paid_On__c = Date.today(), Recorded_By__c = financeTeam)
};
for (Instalment__c i : emekaInst) {
    payments.add(new Payment__c(Opportunity__c = oEmeka, Instalment__c = i.Id, Type__c = 'Instalment', Method__c = 'Bank Transfer', Amount__c = 5800000, Paid_On__c = i.Due_Date__c, Recorded_By__c = financeTeam));
}
insert payments;
// Marking Emeka's last instalments Paid fires the plan-completion flow. If that flow can't run here, still mark them paid.
Savepoint beforeComplete = Database.setSavepoint();
try {
    for (Instalment__c i : emekaInst) i.Status__c = 'Paid';
    update emekaInst;
} catch (DmlException e) {
    Database.rollback(beforeComplete);
    System.debug(LoggingLevel.ERROR, 'AD Test plan completion flow skipped: ' + e.getMessage());
    List<Instalment__c> plain = new List<Instalment__c>();
    for (Instalment__c i : emekaInst) plain.add(new Instalment__c(Id = i.Id, Status__c = 'Paid'));
    update plain;
}

// Close sales: Bola and Emeka won (converted Leads, so allowed), Ibrahim lost.
update new List<Opportunity>{
    new Opportunity(Id = oBola, StageName = 'Closed Won'),
    new Opportunity(Id = oEmeka, StageName = 'Closed Won'),
    new Opportunity(Id = oIbrahim, StageName = 'Closed Lost')
};

// Import requests: Lagos Ride wants a second Hilux (customer has confirmed); Funke's Sportage request has arrived.
Import_Request__c impRide = new Import_Request__c(Account__c = rRide.getAccountId(), Opportunity__c = oRide, Vehicle_Model__c = models.get('AD Test - Toyota Hilux').Id,
    Requested_By__c = salesRep, Status__c = 'Requested', Expected_Arrival__c = Date.today().addDays(40));
Import_Request__c impFunke = new Import_Request__c(Account__c = rFunke.getAccountId(), Vehicle_Model__c = sportage.Id,
    Requested_By__c = salesRep, Status__c = 'Requested', Expected_Arrival__c = Date.today().addDays(-2), Invoice_Reference__c = 'AD-TEST-INV-0042');
insert new List<Import_Request__c>{ impRide, impFunke };
impRide.Customer_Confirmed__c = true;
impFunke.Customer_Confirmed__c = true;
update new List<Import_Request__c>{ impRide, impFunke };
impFunke.Status__c = 'Finance Confirmed';
update impFunke;
impFunke.Status__c = 'Imported';
impFunke.Arrived_On__c = Date.today();
update impFunke;

// Reconciliation: one matched day, one flagged, one explained.
insert new List<Reconciliation_Entry__c>{
    new Reconciliation_Entry__c(Date__c = Date.today(), Bank_Account__c = 'AD Test GTBank Operations', Bank_Total__c = 48400000, Recorded_Total__c = 48400000, Status__c = 'Matched', Note__c = 'Bola full payment and Lagos Ride down payment.'),
    new Reconciliation_Entry__c(Date__c = Date.today().addDays(-27), Bank_Account__c = 'AD Test GTBank Operations', Bank_Total__c = 3400000, Recorded_Total__c = 3466667, Status__c = 'Flagged', Note__c = 'Funke instalment: bank shows 66,667 less than recorded. Card fee?'),
    new Reconciliation_Entry__c(Date__c = Date.today().addDays(-60), Bank_Account__c = 'AD Test Zenith Collections', Bank_Total__c = 11600000, Recorded_Total__c = 11600000, Status__c = 'Explained', Note__c = 'Emeka down payment arrived in the collections account, not operations.')
};

// Service: five more cases across types, statuses and origins.
Contact cFunke = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Ayo' LIMIT 1];
Contact cEmeka = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Obi' LIMIT 1];
Contact cIbrahim = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Musa' LIMIT 1];
Contact cBola = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Adeyemi' LIMIT 1];
Contact cRide = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Lawal' LIMIT 1];
List<Case> cases = new List<Case>{
    new Case(Subject = 'AD Test - Can I pay my next instalment early?', Type = 'Payment', Origin = 'Email', ContactId = cFunke.Id, AccountId = cFunke.AccountId),
    new Case(Subject = 'AD Test - When will my ownership documents be ready?', Type = 'Payment', Origin = 'Phone', ContactId = cEmeka.Id, AccountId = cEmeka.AccountId),
    new Case(Subject = 'AD Test - Air conditioning not cooling', Type = 'Technical', Origin = 'Phone', ContactId = cIbrahim.Id, AccountId = cIbrahim.AccountId),
    new Case(Subject = 'AD Test - Second Hilux delivery date', Type = 'Sales', Origin = 'Email', ContactId = cRide.Id, AccountId = cRide.AccountId),
    new Case(Subject = 'AD Test - Request for spare key', Type = 'Technical', Origin = 'Web', ContactId = cBola.Id, AccountId = cBola.AccountId)
};
insert cases;
update new List<Case>{
    new Case(Id = cases[2].Id, Status = 'Closed'),
    new Case(Id = cases[1].Id, Status = 'Escalated')
};
insert new List<Customer_Message__c>{
    new Customer_Message__c(Case__c = cases[0].Id, Account__c = cFunke.AccountId, Channel__c = 'Email', Type__c = 'Acknowledgement', Message_Text__c = 'Thanks Funke, we have your request and will reply within one working day.', Sent_At__c = System.now().addHours(-3), Sent_By__c = 'Customer Service'),
    new Customer_Message__c(Case__c = cases[1].Id, Account__c = cEmeka.AccountId, Channel__c = 'WhatsApp', Type__c = 'Status Update', Message_Text__c = 'Your documents are with Finance and should be ready this week.', Sent_At__c = System.now().addHours(-2), Sent_By__c = 'Customer Service'),
    new Customer_Message__c(Case__c = cases[2].Id, Account__c = cIbrahim.AccountId, Channel__c = 'Phone', Type__c = 'Resolution', Message_Text__c = 'Air conditioning re-gassed under warranty.', Sent_At__c = System.now().addHours(-1), Sent_By__c = 'Customer Service'),
    new Customer_Message__c(Case__c = cases[2].Id, Account__c = cIbrahim.AccountId, Channel__c = 'Text', Type__c = 'Satisfaction Request', Message_Text__c = 'How did we do? Reply 1-5.', Sent_At__c = System.now(), Sent_By__c = 'Customer Service'),
    new Customer_Message__c(Account__c = cFunke.AccountId, Instalment__c = funkeInst[1].Id, Channel__c = 'Text', Type__c = 'Status Update', Message_Text__c = 'Reminder: your instalment of 3,466,667 is due in 3 days.', Sent_At__c = System.now(), Sent_By__c = 'Finance')
};

insert new List<Knowledge_Article__c>{
    new Knowledge_Article__c(Name = 'AD Test - Minimum down payment for instalments', Status__c = 'Published', Issue_Description__c = 'Customer asks how much they must pay upfront.', Agreed_Answer__c = 'At least 30% of the sale price. Fleet customers can go lower only with Head of Finance sign-off.'),
    new Knowledge_Article__c(Name = 'AD Test - Longest instalment term', Status__c = 'Published', Issue_Description__c = 'Customer asks how long they can spread payments.', Agreed_Answer__c = 'Up to 12 months. Longer terms are for fleet customers with Head of Finance sign-off.'),
    new Knowledge_Article__c(Name = 'AD Test - Ownership documents after final payment', Status__c = 'Published', Issue_Description__c = 'Customer has finished paying and wants their papers.', Agreed_Answer__c = 'Finance starts the documents once the last instalment clears; allow up to 10 working days.'),
    new Knowledge_Article__c(Name = 'AD Test - Ordering a model that is out of stock', Status__c = 'Draft', Issue_Description__c = 'Customer wants a model none of the showrooms have.', Agreed_Answer__c = 'Raise an Import Request; the customer confirms, Finance confirms, then we import.')
};

// Legal: a settled escalation from an earlier default on Funke's plan.
insert new Legal_Escalation__c(Account__c = cFunke.AccountId, Instalment_Plan__c = pFunke.Id, Guarantor_Information__c = guarantors[1].Id,
    Status__c = 'Settled', Escalated_By__c = financeTeam, Escalated_On__c = Date.today().addDays(-20), Vehicle_Purchased__c = 'Toyota Camry 2026',
    Contract_Number__c = 'AD-TEST-0002', Amount_Paid__c = 14666667, Total_Amount_Owed__c = 17333333, Number_of_Missed_Payments__c = 1,
    Months_Defaulted__c = 1, Note__c = 'Customer cleared the arrears after the legal letter. Kept for history.');

System.debug('AD Test batch 2 created.');
