// Go-live UAT data, step 4 of 5 (Group3Prod): copy of instalment_test_plans.apex for the go-live org, plus Funke Ayo (late)
// and Ngozi Okeke (awaiting sign-off). Each customer takes a free car of the type named. Run once per customer: set ONLY to 0..7.
// Creates six instalment customers, each set up to test one part of the instalment process.
// Every plan follows the rules: at least 30% down (recorded as a payment), 12 months or less,
// a guarantor whose income check is done, Head of Finance sign-off before monthly payments, car reserved then sold.
// Dates are relative to today, so the scenarios stay valid whenever the script is run.
// Run once per customer (set ONLY to 0..5). Suleiman (1) has the most history: if it hits the SOQL limit,
// run it up to the payments, then set the overdue months and close the sale in separate calls.
Date t = Date.today();
Id rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Individual'].Id;
Id rep = [SELECT Id FROM User WHERE Username = 'henry.salesrep@autodrive.group3prod'].Id;
Id hof = [SELECT Id FROM User WHERE Username = 'obed.headoffinance@autodrive.group3prod'].Id;

// name, email, chassis, months, down %, deposit day, first due day, months paid, closed?, signed?
List<List<Object>> plans = new List<List<Object>>{
    new List<Object>{ 'Chiamaka Okonkwo', 'hillaryemmanuel@gmail.com', 'Toyota Corolla 2026 Silver', 6, 40, -20, 3,   0, true,  true },
    new List<Object>{ 'Suleiman Bello',   'suleiman.bello@example.com', 'Toyota Corolla 2026 Silver', 6, 40, -100, -65, 1, true, true },
    new List<Object>{ 'Folake Ogunleye',  'folake.ogunleye@example.com', 'Kia Sportage 2026 Blue', 4, 40, -50, -31, 0, true, true },
    new List<Object>{ 'Emmanuel Udo',     'emmanuel.udo@example.com', 'Toyota Hilux 2026 Silver', 3, 40, -80, -58, 2, true, true },
    new List<Object>{ 'Hauwa Lawal',      'hauwa.lawal@example.com', 'Kia Sportage 2026 Black', 6, 40, -1, 30,   0, false, false },
    new List<Object>{ 'Segun Ajayi',      'segun.ajayi@example.com', 'Honda CR-V 2026 Silver', 6, 40, -45, -30, 1, true, true },
    new List<Object>{ 'Funke Ayo',        'funke.ayo@example.com', 'Toyota Camry 2026 Grey', 6, 40, -40, -12, 0, true, true },
    new List<Object>{ 'Ngozi Okeke',      'ngozi.okeke@example.com', 'Toyota Camry 2026 Red', 4, 40, -2, 30, 0, false, false }
};

// run one customer per call to stay within limits: set ONLY to 0-7, or -1 for all
Integer ONLY = -1;
for (Integer idx = 0; idx < plans.size(); idx++) {
    if (ONLY >= 0 && idx != ONLY) continue;
    List<Object> s = plans[idx];
    String name = (String) s[0];
    Integer months = (Integer) s[3], pct = (Integer) s[4], depDay = (Integer) s[5], firstDue = (Integer) s[6], paidMonths = (Integer) s[7];
    Boolean closeIt = (Boolean) s[8], sign = (Boolean) s[9];
    Vehicle__c car = [SELECT Id, Model__c, Model__r.Name, Model__r.List_Price__c FROM Vehicle__c WHERE Model__r.Name = :(String) s[2] AND Status__c = 'Available' AND Id NOT IN (SELECT Vehicle__c FROM Opportunity WHERE IsClosed = false AND Vehicle__c != null) ORDER BY Name LIMIT 1];
    Decimal price = car.Model__r.List_Price__c;
    Decimal down = (price * pct / 100).setScale(2);

    Account a = new Account(Name = name, RecordTypeId = rt, OwnerId = rep); insert a;
    insert new Contact(FirstName = name.substringBefore(' '), LastName = name.substringAfter(' '), AccountId = a.Id, Email = (String) s[1], Phone = '0803' + String.valueOf(Math.mod(Math.abs(name.hashCode()), 10000000)).leftPad(7, '0'));
    Opportunity o = new Opportunity(Name = name + ' - ' + car.Model__r.Name, AccountId = a.Id, OwnerId = rep, StageName = 'Payment Arranged',
        CloseDate = t.addDays(30), Vehicle__c = car.Id, Vehicle_Model_Wanted__c = car.Model__c, Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = months,
        Instalment_Down_Payment__c = down, Viewing_Date__c = t.addDays(depDay - 7));
    insert o;
    o = [SELECT Id, Sale_Price__c FROM Opportunity WHERE Id = :o.Id];
    if (o.Sale_Price__c == null) { update new Opportunity(Id = o.Id, Sale_Price__c = price); }

    Guarantor__c g = new Guarantor__c(Name = 'Guarantor for ' + name, Income_Check_Done__c = true, Phone__c = '08090000000'); insert g;
    insert new Payment__c(Name = 'x', Opportunity__c = o.Id, Type__c = 'Down Payment', Amount__c = down, Paid_On__c = t.addDays(depDay), Method__c = 'Bank Transfer');

    Instalment_Plan__c p = new Instalment_Plan__c(Name = 'x', Opportunity__c = o.Id, Guarantor__c = g.Id, Term_in_Months__c = months,
        Down_Payment_Amount__c = down, Down_Payment_Percent__c = pct);
    insert p;
    if (sign) {
        update new Instalment_Plan__c(Id = p.Id, Head_of_Finance_Sign_off__c = true);
        update new Instalment_Plan__c(Id = p.Id, Signed_Off_By__c = hof, Signed_Off_On__c = t.addDays(depDay + 1));
    }

    // monthly schedule moved to this customer's dates
    List<Instalment__c> insts = [SELECT Id, Amount_Due__c FROM Instalment__c WHERE Instalment_Plan__c = :p.Id ORDER BY Due_Date__c];
    for (Integer k = 0; k < insts.size(); k++) insts[k].Due_Date__c = t.addDays(firstDue).addMonths(k);
    update insts;
    // months already paid, on their due date
    List<Payment__c> pays = new List<Payment__c>();
    for (Integer k = 0; k < paidMonths; k++)
        pays.add(new Payment__c(Name = 'x', Opportunity__c = o.Id, Instalment__c = insts[k].Id, Type__c = 'Instalment',
            Amount__c = insts[k].Amount_Due__c, Paid_On__c = t.addDays(firstDue).addMonths(k), Method__c = 'Bank Transfer'));
    insert pays;
    // unpaid months already past their due date: Late, or Default once 30+ days (as the nightly jobs would have set)
    List<Instalment__c> overdue = new List<Instalment__c>();
    for (Integer k = paidMonths; k < insts.size(); k++) {
        Date due = t.addDays(firstDue).addMonths(k);
        if (due >= t) continue;
        Integer late = due.daysBetween(t);
        // Folake is left one step before default, so tonight's job marks it and alerts Finance (UAT-30)
        Boolean defaulted = late >= 30 && name != 'Folake Ogunleye';
        overdue.add(new Instalment__c(Id = insts[k].Id, Status__c = defaulted ? 'Default' : 'Late', Default_Alert_Sent__c = defaulted));
    }
    update overdue;
    if (closeIt) update new Opportunity(Id = o.Id, StageName = 'Closed Won', CloseDate = t.addDays(depDay + 2));
    Flow.Interview.createInterview('Instalment_Plan_Recalculate_Status', new Map<String, Object>{ 'planId' => p.Id }).start();
    update new Instalment_Plan__c(Id = p.Id);
}
for (Instalment_Plan__c p : [SELECT Name, Plan_Status__c, Next_Step__c FROM Instalment_Plan__c WHERE CreatedDate = TODAY ORDER BY Name])
    System.debug('RES ' + p.Name + ' | ' + p.Plan_Status__c + ' | ' + p.Next_Step__c);
