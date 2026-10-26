// Go-live UAT data, step 5 of 5 (Group3Prod): knowledge articles for Customer Service, and an earlier case with its
// message on Daniel Okoro's account. Stops if it has already run.
//   sf apex run -o autodrive-prod -f scripts/apex/prod/05_knowledge_and_service.apex

if ([SELECT COUNT() FROM Knowledge_Article__c] > 0) { System.debug('PROD DATA step 5 already done'); return; }
insert new List<Knowledge_Article__c>{
    new Knowledge_Article__c(Name = 'How instalment payments are confirmed', Status__c = 'Published', Issue_Description__c = 'Customer has paid an instalment but it does not show yet.', Agreed_Answer__c = 'Bank transfers are reconciled daily. Payments show within one working day of the bank confirming them.'),
    new Knowledge_Article__c(Name = 'Minimum down payment for instalments', Status__c = 'Published', Issue_Description__c = 'Customer asks how much they must pay upfront.', Agreed_Answer__c = 'At least 30% of the sale price. Fleet customers can go lower only with Head of Finance sign-off.'),
    new Knowledge_Article__c(Name = 'Longest instalment term', Status__c = 'Published', Issue_Description__c = 'Customer asks how long they can spread payments.', Agreed_Answer__c = 'Up to 12 months. Longer terms are for fleet customers with Head of Finance sign-off.'),
    new Knowledge_Article__c(Name = 'Ownership documents after final payment', Status__c = 'Published', Issue_Description__c = 'Customer has finished paying and wants their papers.', Agreed_Answer__c = 'Finance starts the documents once the last instalment clears; allow up to 10 working days.'),
    new Knowledge_Article__c(Name = 'Ordering a model that is out of stock', Status__c = 'Draft', Issue_Description__c = 'Customer wants a model the showroom does not have.', Agreed_Answer__c = 'Raise an Import Request; the customer confirms, Finance confirms, then we import.')
};

Contact daniel = [SELECT Id, AccountId FROM Contact WHERE Name = 'Daniel Okoro' LIMIT 1];
Case c = new Case(Subject = 'Air conditioning not cooling', Description = 'The air conditioning on my Hilux blows warm air.', Type = 'Technical',
    Origin = 'Phone', Priority = 'Medium', ContactId = daniel.Id, AccountId = daniel.AccountId);
insert c;
insert new Customer_Message__c(Name = 'Reply', Case__c = c.Id, Account__c = daniel.AccountId, Channel__c = 'Phone', Type__c = 'Status Update',
    Message_Text__c = 'Called Daniel: booked the car in for an air conditioning check on Thursday.', Sent_At__c = System.now(), Sent_By__c = 'Customer Service');
System.debug('PROD DATA step 5: articles and Daniel Okoro case ' + [SELECT CaseNumber FROM Case WHERE Id = :c.Id].CaseNumber);
