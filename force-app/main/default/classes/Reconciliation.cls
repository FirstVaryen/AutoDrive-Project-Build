// Compares a day's bank total with the payments recorded in Salesforce for that day (US-09).
// The recorded total and the status fill themselves; Finance is alerted when a day doesn't match.
public with sharing class Reconciliation {

    public static void fill(List<Reconciliation_Entry__c> entries) {
        Set<Date> days = new Set<Date>();
        for (Reconciliation_Entry__c e : entries) if (e.Date__c != null) days.add(e.Date__c);
        Map<Date, Decimal> totals = new Map<Date, Decimal>();
        for (AggregateResult r : [SELECT Paid_On__c d, SUM(Amount__c) s FROM Payment__c WHERE Paid_On__c IN :days GROUP BY Paid_On__c])
            totals.put((Date) r.get('d'), (Decimal) r.get('s'));
        for (Reconciliation_Entry__c e : entries) {
            if (e.Date__c == null) continue;
            e.Recorded_Total__c = totals.containsKey(e.Date__c) ? totals.get(e.Date__c) : 0;
            Decimal bank = e.Bank_Total__c == null ? 0 : e.Bank_Total__c;
            if (e.Recorded_Total__c == bank) e.Status__c = 'Matched';
            else if (e.Status__c != 'Explained') e.Status__c = 'Flagged';
        }
    }

    public static void alert(List<Reconciliation_Entry__c> entries, Map<Id, Reconciliation_Entry__c> old) {
        List<Reconciliation_Entry__c> flagged = new List<Reconciliation_Entry__c>();
        for (Reconciliation_Entry__c e : entries)
            if (e.Status__c == 'Flagged' && (old == null || old.get(e.Id).Status__c != 'Flagged')) flagged.add(e);
        if (flagged.isEmpty()) return;
        List<CustomNotificationType> types = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'AutoDrive_Finance_Alert' LIMIT 1];
        List<Group> teams = [SELECT Id FROM Group WHERE DeveloperName IN ('Finance_Team', 'Head_of_Finance') AND Type IN ('Regular', 'Role')];
        if (types.isEmpty() || teams.isEmpty()) return;
        Set<String> recipients = new Set<String>();
        for (Group g : teams) recipients.add(g.Id);
        for (Reconciliation_Entry__c e : flagged) {
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setNotificationTypeId(types[0].Id);
            n.setTargetId(e.Id);
            n.setTitle('Bank and recorded payments do not match');
            n.setBody('On ' + e.Date__c.format() + ' the bank shows ' + (e.Bank_Total__c == null ? 0 : e.Bank_Total__c).format()
                + ' but recorded payments total ' + e.Recorded_Total__c.format() + '. Please find the difference and add a note.');
            try { n.send(recipients); } catch (Exception ex) { System.debug(LoggingLevel.WARN, ex.getMessage()); }
        }
    }

    // a payment added, changed or removed re-checks the entries for its day
    public static void touchDays(Set<Date> days) {
        days.remove(null);
        if (days.isEmpty()) return;
        Database.update([SELECT Id FROM Reconciliation_Entry__c WHERE Date__c IN :days], false);
    }
}
