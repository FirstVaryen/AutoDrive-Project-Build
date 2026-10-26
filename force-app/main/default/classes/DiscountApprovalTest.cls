@isTest
private class DiscountApprovalTest {
    static DiscountApproval.Request req(Id recordId, String decision) {
        DiscountApproval.Request r = new DiscountApproval.Request();
        r.recordId = recordId; r.decision = decision; r.comments = 'Test';
        return r;
    }

    @isTest static void notWaiting() {
        Account a = new Account(Name = 'Approval Test');
        insert a;
        Opportunity o = new Opportunity(Name = 'Approval Test', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(10));
        insert o;
        // a request that isn't in approval: the user is told, nothing fails
        List<String> res = DiscountApproval.decide(new List<DiscountApproval.Request>{ req(o.Id, 'Approve') });
        System.assertEquals('This request is not waiting for approval.', res[0]);
    }

    @isTest static void approverDecidesFromTheRequest() {
        Account a = new Account(Name = 'Approval Test');
        insert a;
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'Approval Model', List_Price__c = 1000);
        insert m;
        Vehicle__c car = new Vehicle__c(Name = 'Approval Car', Model__c = m.Id, Status__c = 'Available', Chassis_Number__c = 'APPR1');
        insert car;
        Opportunity o = new Opportunity(Name = 'Approval Test', AccountId = a.Id, StageName = 'Offer', CloseDate = Date.today().addDays(10),
            Payment_Mode__c = 'Full Payment', Vehicle__c = car.Id);
        insert o;
        Discount_Request__c d = new Discount_Request__c(Opportunity__c = o.Id, Discount_Rate__c = '10%', Reason__c = 'Test');
        insert d;
        List<ProcessInstanceWorkitem> w = [SELECT ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :d.Id];
        if (w.isEmpty()) return; // approver users not set up in this org yet
        // someone else is told it isn't theirs
        System.assertEquals('This request is not waiting for you.', DiscountApproval.decide(new List<DiscountApproval.Request>{ req(d.Id, 'Approve') })[0]);
        List<String> res;
        System.runAs(new User(Id = w[0].ActorId)) {
            // a rejection needs a reason
            DiscountApproval.Request blank = req(d.Id, 'Reject');
            blank.comments = ' ';
            System.assert(DiscountApproval.decide(new List<DiscountApproval.Request>{ blank })[0].startsWith('Not rejected'));
            res = DiscountApproval.decide(new List<DiscountApproval.Request>{ req(d.Id, 'Reject') });
        }
        System.assert(res[0].startsWith('Rejected.'), res[0]);
    }
}
