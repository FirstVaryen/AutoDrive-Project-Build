// Works out, for each instalment plan, a month-by-month progress list and the next step for Finance,
// so the plan page shows where it stands without anyone compiling it (US-05, US-29).
public with sharing class PlanProgress implements Schedulable {

    // daily refresh, so "late by N days" stays current
    public void execute(SchedulableContext ctx) {
        Database.update([SELECT Id FROM Instalment_Plan__c WHERE Plan_Status__c != 'Completed'], false);
    }

    // re-saves the plans so the before-update trigger fills the fields
    public static void touch(Set<Id> planIds) {
        planIds.remove(null);
        if (planIds.isEmpty()) return;
        List<Instalment_Plan__c> plans = new List<Instalment_Plan__c>();
        for (Id i : planIds) plans.add(new Instalment_Plan__c(Id = i));
        Database.update(plans, false);
    }

    public static void fill(List<Instalment_Plan__c> plans) {
        Set<Id> ids = new Set<Id>();
        for (Instalment_Plan__c p : plans) if (p.Id != null) ids.add(p.Id);
        if (ids.isEmpty()) return;
        Map<Id, Instalment_Plan__c> data = new Map<Id, Instalment_Plan__c>([
            SELECT Id, Opportunity__r.Down_Payment_Received__c, Down_Payment_Amount__c, Completion_Email_Sent__c,
                (SELECT Name, Amount_Due__c, Amount_Paid__c, Due_Date__c, Status__c, Days_Late__c FROM Instalments__r ORDER BY Due_Date__c),
                (SELECT Name FROM Legal_Escalations__r WHERE Status__c IN ('Open', 'In Progress') LIMIT 1)
            FROM Instalment_Plan__c WHERE Id IN :ids]);
        Map<Id, List<Customer_Message__c>> messages = new Map<Id, List<Customer_Message__c>>();
        for (Customer_Message__c m : [SELECT Instalment__c, Message_Text__c, Sent_At__c, CreatedDate FROM Customer_Message__c
                                      WHERE Instalment__r.Instalment_Plan__c IN :ids ORDER BY CreatedDate]) {
            if (!messages.containsKey(m.Instalment__c)) messages.put(m.Instalment__c, new List<Customer_Message__c>());
            messages.get(m.Instalment__c).add(m);
        }
        for (Instalment_Plan__c p : plans) {
            Instalment_Plan__c d = data.get(p.Id);
            if (d == null) continue;
            List<String> lines = new List<String>();
            Instalment__c worst = null, next = null;
            Integer n = d.Instalments__r.size(), k = 0;
            for (Instalment__c i : d.Instalments__r) {
                k++;
                Decimal due = nz(i.Amount_Due__c), paid = nz(i.Amount_Paid__c);
                Integer late = daysLate(i);
                Boolean isPaid = i.Status__c == 'Paid' || (due > 0 && paid >= due);
                String line = 'Month ' + k + ' of ' + n + ' · ' + money(due) + ' · due ' + day(i.Due_Date__c) + ' · ';
                if (isPaid) {
                    line += 'PAID' + (paid > due ? ' (' + money(paid - due) + ' extra, kept as credit)' : '');
                } else if (i.Status__c == 'Default') {
                    line += 'DEFAULTED, unpaid for ' + late + ' days, ' + money(due - paid) + ' owed, Finance alerted';
                } else if (late > 0) {
                    line += 'LATE by ' + late + (late == 1 ? ' day, ' : ' days, ') + money(due - paid) + ' owed';
                } else if (paid > 0) {
                    line += 'PART PAID: ' + money(paid) + ' paid, ' + money(due - paid) + ' still owed';
                } else {
                    line += 'upcoming';
                }
                if (!isPaid && paid > 0 && (late > 0 || i.Status__c == 'Default')) line += ' (part paid: ' + money(paid) + ')';
                String sent = sentSummary(messages.get(i.Id));
                if (sent != null) line += '. Sent: ' + sent;
                lines.add(line);
                if (!isPaid) {
                    if (next == null) next = i;
                    if ((i.Status__c == 'Default' || late > 0) && (worst == null || late > daysLate(worst))) worst = i;
                }
            }
            p.Progress__c = lines.isEmpty() ? null : String.join(lines, '\n');
            p.Next_Step__c = nextStep(p, d, worst, next, n).left(255);
        }
    }

    private static String nextStep(Instalment_Plan__c p, Instalment_Plan__c d, Instalment__c worst, Instalment__c next, Integer n) {
        if (!d.Legal_Escalations__r.isEmpty())
            return 'With the legal team (' + d.Legal_Escalations__r[0].Name + '). Follow up with Legal and record any payment that comes in.';
        if (!p.Head_of_Finance_Sign_off__c) {
            if (nz(d.Opportunity__r.Down_Payment_Received__c) <= 0)
                return 'Waiting for the down payment of ' + money(nz(d.Down_Payment_Amount__c)) + '. Finance records it with Record Down Payment on the sale; then the Head of Finance signs off this plan.';
            return 'Down payment received. Waiting for the Head of Finance to sign off this plan before the monthly payments start.';
        }
        if (worst != null) {
            Integer late = daysLate(worst);
            String owed = money(nz(worst.Amount_Due__c) - nz(worst.Amount_Paid__c));
            String month = monthOf(worst);
            if (worst.Status__c == 'Default' || late >= 30)
                return month + ' has been unpaid for ' + late + ' days (' + owed + ' owed). Ask the guarantor to cover it; if they cannot, raise a Legal Escalation.';
            return month + ' is ' + late + (late == 1 ? ' day' : ' days') + ' late (' + owed + ' owed). Contact the customer; when they pay, use Record Payment on that month. '
                + (late >= 7 ? 'The guarantor has been told. ' : 'The guarantor is told at 7 days. ') + 'At 30 days it becomes a default.';
        }
        if (next == null) return 'All ' + n + ' months paid. ' + (d.Completion_Email_Sent__c ? 'Completion email sent.' : 'Completion email not sent yet.');
        return 'On track. Next payment: ' + monthOf(next) + ', ' + money(nz(next.Amount_Due__c) - nz(next.Amount_Paid__c)) + ' due ' + day(next.Due_Date__c) + '.';
    }

    private static String sentSummary(List<Customer_Message__c> ms) {
        if (ms == null || ms.isEmpty()) return null;
        List<String> parts = new List<String>();
        for (Customer_Message__c m : ms) {
            String t = m.Message_Text__c == null ? '' : m.Message_Text__c.toLowerCase();
            String what = t.contains('guarantor') ? 'guarantor notice'
                        : t.contains('reminder') ? 'reminder email'
                        : (t.contains('missed') || t.contains('overdue') || t.contains('late')) ? 'missed-payment notice'
                        : 'message';
            Datetime whenSent = m.Sent_At__c != null ? m.Sent_At__c : m.CreatedDate;
            parts.add(what + ' ' + day(whenSent.date()));
        }
        return String.join(parts, ', ');
    }

    private static Integer daysLate(Instalment__c i) { return i.Days_Late__c == null ? 0 : i.Days_Late__c.intValue(); }
    private static String monthOf(Instalment__c i) { return i.Name != null && i.Name.contains('Month ') ? i.Name.substring(i.Name.indexOf('Month ')) : 'A month'; }
    private static Decimal nz(Decimal v) { return v == null ? 0 : v; }
    private static String money(Decimal v) { return v.setScale(2).format(); }
    private static String day(Date d) {
        if (d == null) return '';
        return d.day() + ' ' + new List<String>{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'}[d.month() - 1] + ' ' + d.year();
    }
}
