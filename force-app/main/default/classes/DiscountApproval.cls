/**
 * Approve or reject a discount request from the request's own page, so the approver stays on the
 * customer's details instead of the standard approval page. Used by the "Approve or Reject" screen flow.
 */
public without sharing class DiscountApproval {
    public class Request {
        @InvocableVariable(required=true) public Id recordId;
        @InvocableVariable(required=true) public String decision;
        @InvocableVariable public String comments;
    }

    @InvocableMethod(label='Approve or reject a discount request')
    public static List<String> decide(List<Request> requests) {
        List<String> results = new List<String>();
        for (Request r : requests) {
            List<ProcessInstanceWorkitem> items = [SELECT Id, ActorId FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :r.recordId AND ProcessInstance.Status = 'Pending'];
            ProcessInstanceWorkitem mine;
            for (ProcessInstanceWorkitem w : items) if (w.ActorId == UserInfo.getUserId()) mine = w;
            if (mine == null) {
                results.add(items.isEmpty() ? 'This request is not waiting for approval.' : 'This request is not waiting for you.');
                continue;
            }
            Approval.ProcessWorkitemRequest a = new Approval.ProcessWorkitemRequest();
            a.setWorkitemId(mine.Id);
            a.setAction(r.decision == 'Reject' ? 'Reject' : 'Approve');
            a.setComments(r.comments);
            Approval.process(a);
            Discount_Request__c d = [SELECT Current_Step__c FROM Discount_Request__c WHERE Id = :r.recordId];
            results.add((r.decision == 'Reject' ? 'Rejected.' : 'Approved.') + ' The request is now: ' + d.Current_Step__c + '.');
        }
        return results;
    }
}
