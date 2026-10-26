// Go-live UAT data, step 2 of 5 (Group3Prod): copy of uat_sales_rep_data.apex for the go-live org's Sales Rep login.
// UAT test data for the Sales Rep tests in docs/AutoDrive_UAT.md. Safe to run more than once: anything already there is left alone.
//   sf apex run -o <alias> -f scripts/apex/uat_sales_rep_data.apex
// Owner of every record: the Sales Rep test user.
// Stock: every model has 5 cars Available, except the sold-out models below (kept at 0 for the import tests).

Set<String> soldOut = new Set<String>{ 'Toyota Corolla 2026 White', 'Toyota Camry 2026 Blue' };
Id rep = [SELECT Id FROM User WHERE Username = 'henry.salesrep@autodrive.group3prod'].Id;
Id leadRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'AutoDrive_Lead'].Id;
Id oppRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'AutoDrive_Sale'].Id;
Id individualRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual'].Id;
String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
// test customers may repeat a phone number from an earlier round: allow the save past the duplicate warning
Database.DMLOptions dupOk = new Database.DMLOptions();
dupOk.DuplicateRuleHeader.allowSave = true;

// 1. Stock: top every model up to 5 available cars
List<Showroom__c> rooms = [SELECT Id, Capacity__c FROM Showroom__c LIMIT 1];
if (!rooms.isEmpty() && rooms[0].Capacity__c != null && rooms[0].Capacity__c < 200) update new Showroom__c(Id = rooms[0].Id, Capacity__c = 200);
List<Vehicle__c> newCars = new List<Vehicle__c>();
Integer nextNo = 5001 + [SELECT COUNT() FROM Vehicle__c WHERE Chassis_Number__c LIKE 'ADM%'];
Integer shortTypes = 0;
for (Vehicle_Model__c m : [SELECT Id, Name, Available_Stock__c FROM Vehicle_Model__c ORDER BY Name]) {
    if (soldOut.contains(m.Name)) continue;
    Integer have = m.Available_Stock__c == null ? 0 : m.Available_Stock__c.intValue();
    if (have < 5 && ++shortTypes > 2) continue; // go-live org: two types per run to stay within limits
    List<String> words = m.Name.split(' ');
    Integer year = 2026;
    for (String w : words) if (w.isNumeric() && w.length() == 4) year = Integer.valueOf(w);
    for (Integer i = have + 1; i <= 5; i++) {
        String chassis = 'ADM' + nextNo++;
        newCars.add(new Vehicle__c(Name = m.Name + ' · ' + chassis, Model__c = m.Id, Status__c = 'Available', Year__c = year,
            Colour__c = words[words.size() - 1], Chassis_Number__c = chassis));
    }
}
insert newCars;
System.debug('UAT DATA cars added: ' + newCars.size());
if (!newCars.isEmpty()) { System.debug('UAT DATA more to add: run this again'); return; }

// helper data: a free car of a model
Map<String, List<Vehicle__c>> free = new Map<String, List<Vehicle__c>>();
for (Vehicle__c v : [SELECT Id, Model__r.Name FROM Vehicle__c WHERE Status__c = 'Available' AND Id NOT IN (SELECT Vehicle__c FROM Opportunity WHERE IsClosed = false AND Vehicle__c != null) ORDER BY Name]) {
    if (!free.containsKey(v.Model__r.Name)) free.put(v.Model__r.Name, new List<Vehicle__c>());
    free.get(v.Model__r.Name).add(v);
}
Map<String, Id> model = new Map<String, Id>();
for (Vehicle_Model__c m : [SELECT Id, Name FROM Vehicle_Model__c]) model.put(m.Name, m.Id);

// 2. Open leads
Map<String, List<Object>> leads = new Map<String, List<Object>>{
    'Adaeze Nwosu' => new List<Object>{ '08031110001', 'Kia Sportage 2026 White' },
    'Tunde Fashola' => new List<Object>{ '08031110002', 'Toyota Corolla 2026 White' }
};
for (String n : leads.keySet()) {
    if ([SELECT COUNT() FROM Lead WHERE Name = :n AND IsConverted = false] > 0) continue;
    Database.insert(new Lead(RecordTypeId = leadRt, FirstName = n.substringBefore(' '), LastName = n.substringAfter(' '), Company = n,
        Phone = (String) leads.get(n)[0], Channel__c = 'Walk-in', Visit_Purpose__c = 'Purchase', Customer_Type__c = 'Individual',
        Qualification_Answers__c = 'Budget agreed; wants to buy this month', Vehicle_Model_Of_Interest__c = model.get((String) leads.get(n)[1]),
        Status = 'Contacted', OwnerId = rep), dupOk);
}

// 3. Customers with an open full-payment opportunity at Offer, each with an available car
Map<String, List<String>> opps = new Map<String, List<String>>{
    'Bisi Adewale' => new List<String>{ '08031110011', 'Toyota Hilux 2026 Red' },
    'Kelechi Obi' => new List<String>{ '08031110012', 'Honda CR-V 2026 White' },
    'Musa Ibrahim' => new List<String>{ '08031110013', 'Toyota Camry 2026 White' },
    'Ronke Alabi' => new List<String>{ '08031110014', 'Kia Sportage 2026 White' },
    'Chidi Eze' => new List<String>{ '08031110015', 'Toyota Hilux 2026 Grey' }
};
Integer madeOpps = 0;
for (String n : opps.keySet()) {
    String oppName = n + ' - ' + opps.get(n)[1];
    if ([SELECT COUNT() FROM Opportunity WHERE Name = :oppName] > 0) continue;
    if (madeOpps++ > 0) { System.debug('UAT DATA more to add: run this again'); return; } // one customer per run in the go-live org
    Lead l = new Lead(RecordTypeId = leadRt, FirstName = n.substringBefore(' '), LastName = n.substringAfter(' '), Company = n,
        Phone = opps.get(n)[0], Channel__c = 'Walk-in', Visit_Purpose__c = 'Purchase', Customer_Type__c = 'Individual',
        Vehicle_Model_Of_Interest__c = model.get(opps.get(n)[1]), Status = 'Contacted', OwnerId = rep);
    Database.insert(l, dupOk);
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id); lc.setConvertedStatus(convertedStatus); lc.setOwnerId(rep); lc.setOpportunityName(oppName);
    Database.LeadConvertResult r = Database.convertLead(lc, dupOk);
    update new Account(Id = r.getAccountId(), RecordTypeId = individualRt);
    Vehicle__c car = free.get(opps.get(n)[1]).remove(0);
    update new Opportunity(Id = r.getOpportunityId(), RecordTypeId = oppRt, StageName = 'Offer', CloseDate = Date.today().addDays(30),
        Payment_Mode__c = 'Full Payment', Vehicle_Model_Wanted__c = model.get(opps.get(n)[1]), Vehicle__c = car.Id);
}

// 4. Fleet customer the rep can open, with a contact and an open fleet opportunity
Account lagos = [SELECT Id FROM Account WHERE Name = 'Lagos Ride Hailing Ltd' LIMIT 1];
update new Account(Id = lagos.Id, OwnerId = rep, Agreed_Discount_Rate__c = 5);
if ([SELECT COUNT() FROM Contact WHERE AccountId = :lagos.Id] == 0) insert new Contact(AccountId = lagos.Id, FirstName = 'Kemi', LastName = 'Lawal', Phone = '08031110020', Title = 'Fleet Manager', OwnerId = rep);
if ([SELECT COUNT() FROM Opportunity WHERE AccountId = :lagos.Id AND IsClosed = false] == 0)
    insert new Opportunity(RecordTypeId = oppRt, Name = 'Lagos Ride Hailing Ltd - Fleet', AccountId = lagos.Id, OwnerId = rep,
        StageName = 'Offer', CloseDate = Date.today().addDays(30), Payment_Mode__c = 'Full Payment');

for (Opportunity o : [SELECT Name, StageName, Vehicle__r.Name FROM Opportunity WHERE OwnerId = :rep AND IsClosed = false AND CreatedDate = TODAY]) System.debug('UAT DATA opp: ' + o.Name + ' | ' + o.StageName + ' | ' + o.Vehicle__r.Name);
System.debug('UAT DATA Daniel Okoro phone: ' + [SELECT Phone FROM Contact WHERE Name = 'Daniel Okoro' LIMIT 1].Phone);
