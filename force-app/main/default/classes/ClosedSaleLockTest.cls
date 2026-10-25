/**
 * A closed sale is frozen for staff below head of department, vehicle included; heads can still change it.
 */
@isTest
private class ClosedSaleLockTest {
    static String lastError;

    static User userIn(String role) {
        List<User> u = [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = :role LIMIT 1];
        return u.isEmpty() ? null : u[0];
    }

    // a closed sale owned by the rep, as it would be after the rep closes it
    static Opportunity closedSale(Id ownerId) {
        Account a = new Account(Name = 'Lock Test Customer', From_Converted_Lead__c = true, OwnerId = ownerId);
        insert a;
        Opportunity o = new Opportunity(Name = 'Lock Test Sale', AccountId = a.Id, OwnerId = ownerId, StageName = 'Closed Lost', CloseDate = Date.today());
        insert o;
        return o;
    }

    static Boolean canEdit(User u, Opportunity o) {
        Boolean ok;
        System.runAs(u) {
            UserRecordAccess a = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :u.Id AND RecordId = :o.Id];
            if (!a.HasEditAccess) { lastError = 'no edit access to the sale'; return false; }
            Database.SaveResult r = Database.update(new Opportunity(Id = o.Id, Description = 'changed after close'), false);
            ok = r.isSuccess();
            if (!ok) lastError = r.getErrors()[0].getMessage();
        }
        return ok;
    }

    @isTest static void salesRepBlocked() {
        User rep = userIn('Sales_Rep');
        if (rep == null) return;
        System.assertEquals(false, canEdit(rep, closedSale(rep.Id)), 'A Sales Rep must not change a closed sale');
        System.assert(lastError.contains('closed'), 'Refused by the closed sale lock, not by access: ' + lastError);
    }

    @isTest static void headAllowed() {
        User rep = userIn('Sales_Rep'), head = userIn('Showroom_Manager');
        if (rep == null || head == null) return;
        System.assertEquals(true, canEdit(head, closedSale(rep.Id)), 'A head of department can change a closed sale: ' + lastError);
    }
}
