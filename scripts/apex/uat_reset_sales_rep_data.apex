// Before a fresh UAT round: puts aside the Sales Rep / Showroom Manager records an earlier round used up, so
// scripts/apex/uat_sales_rep_data.apex can create clean ones under the same names. Nothing is deleted:
// used opportunities are renamed "(used)" and, if still open, closed as Closed Lost so their cars go back to stock.
//   sf apex run -o <alias> -f scripts/apex/uat_reset_sales_rep_data.apex
//   sf apex run -o <alias> -f scripts/apex/uat_sales_rep_data.apex

List<String> names = new List<String>{ 'Bisi Adewale - Toyota Hilux 2026 Red', 'Kelechi Obi - Honda CR-V 2026 White', 'Musa Ibrahim - Toyota Camry 2026 White',
    'Ronke Alabi - Kia Sportage 2026 White', 'Chidi Eze - Toyota Hilux 2026 Grey', 'Lagos Ride Hailing Ltd - Fleet', 'Tunde Fashola-', 'Adaeze Nwosu-' };
List<Opportunity> opps = [SELECT Id, Name, IsClosed FROM Opportunity WHERE Name IN :names];
Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();

// withdraw discount requests still waiting for approval, so the stage can change
Set<Id> drIds = new Map<Id, Discount_Request__c>([SELECT Id FROM Discount_Request__c WHERE Opportunity__c IN :oppIds]).keySet();
for (ProcessInstanceWorkitem w : [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :drIds]) {
    Approval.ProcessWorkitemRequest r = new Approval.ProcessWorkitemRequest();
    r.setWorkitemId(w.Id); r.setAction('Removed'); r.setComments('UAT reset');
    Approval.process(r);
}
// import requests raised in the earlier round are cancelled
List<Import_Request__c> irs = [SELECT Id FROM Import_Request__c WHERE Opportunity__c IN :oppIds AND Status__c NOT IN ('Imported', 'Cancelled')];
for (Import_Request__c i : irs) i.Status__c = 'Cancelled';
update irs;

List<Opportunity> ups = new List<Opportunity>();
for (Opportunity o : opps) {
    Opportunity u = new Opportunity(Id = o.Id, Name = o.Name + ' (used)');
    if (!o.IsClosed) u.StageName = 'Closed Lost';
    ups.add(u);
}
Database.SaveResult[] res = Database.update(ups, false);
for (Integer i = 0; i < res.size(); i++) System.debug('UAT RESET ' + opps[i].Name + ': ' + (res[i].isSuccess() ? 'put aside' : res[i].getErrors()[0].getMessage()));

// customers created by converting the two test leads are renamed too, so converting them again isn't stopped as a duplicate
List<Account> converted = [SELECT Id, Name FROM Account WHERE Name IN ('Tunde Fashola', 'Adaeze Nwosu')];
for (Account a : converted) a.Name = a.Name + ' (used)';
update converted;

// the Showroom Manager's low-stock test model goes back to its usual threshold
List<Vehicle_Model__c> silver = [SELECT Id FROM Vehicle_Model__c WHERE Name = 'Toyota Hilux 2026 Silver'];
if (!silver.isEmpty()) update new Vehicle_Model__c(Id = silver[0].Id, Low_stock_Threshold__c = 2);
