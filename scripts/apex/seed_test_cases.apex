// Adds the AD Test Cases and their Customer Message on top of seed_test_data.apex.
// Run once Case creation works (the demo flow SDO_Service_Case_Creation fails on every Case insert):
//   sf apex run -o autodrive-dev -f scripts/apex/seed_test_cases.apex
// One case per Case_Routing type: Payment -> Finance, Sales -> Showroom Manager, Technical -> Customer Service (Technical).

if (![SELECT Id FROM Case WHERE Subject LIKE 'AD Test%' LIMIT 1].isEmpty()) {
    System.debug('AD Test cases already present - nothing done.');
    return;
}

Contact chinedu = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Eze' LIMIT 1];
Contact adaeze = [SELECT Id, AccountId FROM Contact WHERE LastName = 'AD Test Okafor' LIMIT 1];

List<Case> cases = new List<Case>{
    new Case(Subject = 'AD Test - Instalment payment not reflected', Type = 'Payment', Origin = 'Phone', ContactId = chinedu.Id, AccountId = chinedu.AccountId),
    new Case(Subject = 'AD Test - Question about Corolla delivery date', Type = 'Sales', Origin = 'Web', ContactId = adaeze.Id, AccountId = adaeze.AccountId),
    new Case(Subject = 'AD Test - Dashboard warning light', Type = 'Technical', Origin = 'Email', ContactId = adaeze.Id, AccountId = adaeze.AccountId)
};
insert cases;
insert new Customer_Message__c(Case__c = cases[0].Id, Account__c = chinedu.AccountId, Channel__c = 'Email',
    Type__c = 'Acknowledgement', Message_Text__c = 'We have received your query about your instalment payment.', Sent_At__c = System.now(), Sent_By__c = 'Customer Service');

System.debug('AD Test cases created.');
