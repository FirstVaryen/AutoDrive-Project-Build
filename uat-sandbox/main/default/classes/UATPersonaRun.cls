/**
 * UAT run against the sandbox's own test data, each script as its persona's test user.
 * Runs inside a test, so nothing it does is kept.
 * Sandbox only (uses the sandbox test customers): deploy with -d uat-sandbox, never to the live org. Each method lists every step that didn't behave as the UAT script expects.
 */
@isTest(SeeAllData=true)
private class UATPersonaRun {
    static List<String> fails = new List<String>();
    static void check(Boolean ok, String step) { if (ok != true) fails.add(step); }
    static void done() { System.assert(fails.isEmpty(), String.join(fails, ' || ')); }
    static User u(String role) { return [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = :role AND Username LIKE 'test.%' LIMIT 1]; }
    static String err(Database.SaveResult r) { return r.isSuccess() ? '' : r.getErrors()[0].getMessage(); }
    static Instalment__c month(String customer, String m) {
        return [SELECT Id, Amount_Due__c, Amount_Paid__c, Balance__c, Status__c, Instalment_Plan__c, Instalment_Plan__r.Opportunity__c FROM Instalment__c WHERE Instalment_Plan__r.Name LIKE :('%' + customer + '%') AND Name LIKE :('%Month ' + m + ' of%') LIMIT 1];
    }
    static Payment__c pay(Instalment__c i, Decimal amt) {
        return new Payment__c(Instalment__c = i.Id, Opportunity__c = i.Instalment_Plan__r.Opportunity__c, Amount__c = amt, Type__c = 'Instalment', Method__c = 'Bank Transfer', Paid_On__c = Date.today());
    }
    static Opportunity openFullSale() {
        return [SELECT Id, Vehicle__c FROM Opportunity WHERE IsClosed = false AND Payment_Mode__c = 'Full Payment' AND Vehicle__r.Status__c = 'Available' AND Owner.UserRole.DeveloperName = 'Sales_Rep' AND Pending_Discount_Requests__c = 0 LIMIT 1];
    }

    // ---------- Sales Rep ----------
    @isTest static void SR03_reservedCarCannotBeTaken() {
        User rep = u('Sales_Rep');
        Opportunity ngozi = [SELECT Vehicle__c FROM Opportunity WHERE Name LIKE 'Ngozi Okeke%' AND IsClosed = false LIMIT 1];
        Opportunity other = [SELECT Id FROM Opportunity WHERE IsClosed = false AND Owner.UserRole.DeveloperName = 'Sales_Rep' AND Id != :ngozi.Id AND Name LIKE 'Kunle%' LIMIT 1];
        System.runAs(rep) {
            Database.SaveResult r = Database.update(new Opportunity(Id = other.Id, Vehicle__c = ngozi.Vehicle__c), false);
            check(!r.isSuccess(), 'SR-03/4 another sale could take the car reserved for Ngozi');
        }
        done();
    }

    @isTest static void SR05_smallDiscount() {
        User rep = u('Sales_Rep');
        Opportunity s = openFullSale();
        System.runAs(rep) {
            Discount_Request__c small = new Discount_Request__c(Opportunity__c = s.Id, Discount_Rate__c = '5%', Reason__c = 'UAT run');
            Database.SaveResult r = Database.insert(small, false);
            check(r.isSuccess(), 'SR-05/1 5% request refused: ' + err(r));
            if (r.isSuccess()) {
                small = [SELECT Auto_Approved__c, Current_Step__c, Vehicle_List__c, Sale_List_Price__c, Discount_Value__c, Price_After_Discount__c, Customer__c FROM Discount_Request__c WHERE Id = :small.Id];
                check(small.Auto_Approved__c && small.Current_Step__c == 'Approved', 'SR-05/1 5% not auto-approved: ' + small.Current_Step__c);
                check(small.Vehicle_List__c != null && small.Sale_List_Price__c > 0 && small.Discount_Value__c > 0 && small.Price_After_Discount__c > 0 && small.Customer__c != null, 'SR-05/3 request missing customer/vehicles/prices');
            }
        }
        done();
    }

    @isTest static void SR05_SM02_FT01_HF01_approvalChain() {
        User rep = u('Sales_Rep'), mgr = u('Showroom_Manager'), fin = u('Finance_Team_Member'), hof = u('Head_of_Finance');
        Opportunity s = openFullSale();
        Discount_Request__c d = new Discount_Request__c(Opportunity__c = s.Id, Discount_Rate__c = '7.5%', Reason__c = 'UAT run');
        System.runAs(rep) { insert d; }
        d = [SELECT Current_Step__c, Step_Reached_At__c FROM Discount_Request__c WHERE Id = :d.Id];
        check(d.Current_Step__c == 'With Showroom Manager' && d.Step_Reached_At__c != null, 'SR-05/2 7.5% step: ' + d.Current_Step__c);
        List<String> expected = new List<String>{ 'With Finance', 'With Head Office', 'Approved' };
        List<User> approvers = new List<User>{ mgr, fin, hof };
        for (Integer k = 0; k < 3; k++) {
            List<ProcessInstanceWorkitem> w = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :d.Id];
            if (w.isEmpty()) { check(false, 'step ' + (k + 1) + ': nothing waiting for approval'); break; }
            System.runAs(approvers[k]) {
                Approval.ProcessWorkitemRequest a = new Approval.ProcessWorkitemRequest();
                a.setWorkitemId(w[0].Id); a.setAction('Approve'); a.setComments('UAT run');
                try { Approval.process(a); } catch (Exception e) { check(false, 'approval ' + (k + 1) + ' failed: ' + e.getMessage()); }
            }
            d = [SELECT Current_Step__c, Approved_By__c, Approved_On__c FROM Discount_Request__c WHERE Id = :d.Id];
            check(d.Current_Step__c == expected[k], 'after approver ' + (k + 1) + ' step is ' + d.Current_Step__c + ', expected ' + expected[k]);
        }
        check(d.Approved_By__c != null && d.Approved_On__c != null, 'HF-01/2 Approved By / On not filled');
        done();
    }

    @isTest static void SM02_reject() {
        User rep = u('Sales_Rep'), mgr = u('Showroom_Manager');
        Opportunity s = openFullSale();
        Discount_Request__c d = new Discount_Request__c(Opportunity__c = s.Id, Discount_Rate__c = '10%', Reason__c = 'UAT run');
        System.runAs(rep) { insert d; }
        List<ProcessInstanceWorkitem> w = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :d.Id];
        check(!w.isEmpty(), 'SM-02/4 10% request not waiting for the manager');
        if (!w.isEmpty()) System.runAs(mgr) {
            Approval.ProcessWorkitemRequest a = new Approval.ProcessWorkitemRequest();
            a.setWorkitemId(w[0].Id); a.setAction('Reject'); a.setComments('Too high');
            Approval.process(a);
        }
        check([SELECT Current_Step__c FROM Discount_Request__c WHERE Id = :d.Id].Current_Step__c == 'Rejected', 'SM-02/4 not Rejected');
        done();
    }

    @isTest static void SR08_noDiscountOnInstalment() {
        User rep = u('Sales_Rep');
        Opportunity inst = [SELECT Id FROM Opportunity WHERE IsClosed = false AND Payment_Mode__c = 'Instalment' AND Owner.UserRole.DeveloperName = 'Sales_Rep' AND (NOT Name LIKE '%Ltd%') LIMIT 1];
        Opportunity s = openFullSale();
        System.runAs(rep) {
            Database.SaveResult r = Database.insert(new Discount_Request__c(Opportunity__c = inst.Id, Discount_Rate__c = '5%', Reason__c = 'UAT run'), false);
            check(!r.isSuccess(), 'SR-08/1 discount allowed on an instalment sale');
            Discount_Request__c d = new Discount_Request__c(Opportunity__c = s.Id, Discount_Rate__c = '5%', Reason__c = 'UAT run');
            insert d;
            Database.SaveResult r2 = Database.update(new Opportunity(Id = s.Id, Payment_Mode__c = 'Instalment'), false);
            check(r2.isSuccess(), 'SR-08/2 could not switch sale to instalment: ' + err(r2));
            check([SELECT Current_Step__c FROM Discount_Request__c WHERE Id = :d.Id].Current_Step__c == 'Invalidated', 'SR-08/2 approved discount not Invalidated');
        }
        done();
    }

    @isTest static void SR09_instalmentCloseRules() {
        User rep = u('Sales_Rep');
        Opportunity z = [SELECT Id FROM Opportunity WHERE Name LIKE 'Zainab Bello%' AND IsClosed = false LIMIT 1];
        Opportunity s = openFullSale();
        System.runAs(rep) {
            Database.SaveResult r = Database.update(new Opportunity(Id = z.Id, StageName = 'Closed Won'), false);
            check(!r.isSuccess(), 'SR-09/1 Zainab closed without deposit and sign-off');
            Database.SaveResult r2 = Database.update(new Opportunity(Id = s.Id, Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = 6), false);
            check(r2.isSuccess(), 'SR-09/2 setting 6 months refused: ' + err(r2));
        }
        Opportunity after = [SELECT Instalment_Down_Payment__c, Monthly_Instalment__c, Sale_Price__c FROM Opportunity WHERE Id = :s.Id];
        check(after.Instalment_Down_Payment__c != null && after.Sale_Price__c != null && after.Instalment_Down_Payment__c.setScale(0) == (after.Sale_Price__c * 0.3).setScale(0), 'SR-09/2 deposit not 30%: ' + after.Instalment_Down_Payment__c + ' of ' + after.Sale_Price__c);
        check(after.Monthly_Instalment__c != null && after.Monthly_Instalment__c > 0, 'SR-09/2 monthly amount not worked out');
        done();
    }

    @isTest static void SR10_importRequest() {
        User rep = u('Sales_Rep');
        Vehicle_Model__c m = [SELECT Id FROM Vehicle_Model__c WHERE Available_Stock__c = 0 LIMIT 1];
        Account a = [SELECT Id FROM Account WHERE Name = 'Daniel Okoro' LIMIT 1];
        System.runAs(rep) {
            Import_Request__c ir = new Import_Request__c(Account__c = a.Id, Vehicle_Model__c = m.Id, Quantity__c = 2, Reason__c = 'Out of stock');
            Database.SaveResult r = Database.insert(ir, false);
            check(r.isSuccess(), 'SR-10/1 import request refused: ' + err(r));
            if (r.isSuccess()) {
                ir = [SELECT Status__c, Requested_By__c FROM Import_Request__c WHERE Id = :ir.Id];
                check(ir.Status__c == 'Requested' && ir.Requested_By__c == rep.Id, 'SR-10/1 status ' + ir.Status__c + ', requested by not the rep');
            }
            check(!Database.insert(new Import_Request__c(Account__c = a.Id, Vehicle_Model__c = m.Id, Quantity__c = 2), false).isSuccess(), 'SR-10/2 saved without a reason');
        }
        done();
    }

    @isTest static void SR06_SR07_fleet() {
        User rep = u('Sales_Rep');
        Account lagos = [SELECT Id, Agreed_Discount_Rate__c FROM Account WHERE Name = 'Lagos Ride Hailing Ltd' LIMIT 1];
        Vehicle_Model__c m = [SELECT Id, Available_Stock__c FROM Vehicle_Model__c WHERE Available_Stock__c >= 2 LIMIT 1];
        Opportunity indiv = openFullSale();
        System.runAs(rep) {
            Opportunity s = new Opportunity(Name = 'UAT fleet', AccountId = lagos.Id, StageName = 'Qualification', CloseDate = Date.today().addDays(30), Payment_Mode__c = 'Full Payment');
            Database.SaveResult r = Database.insert(s, false);
            check(r.isSuccess(), 'SR-06 fleet sale refused: ' + err(r));
            if (r.isSuccess()) {
                Flow.Interview f = Flow.Interview.createInterview('Add_Fleet_Vehicles_Core', new Map<String, Object>{ 'recordId' => s.Id, 'modelId' => m.Id, 'quantity' => 2 });
                try { f.start(); } catch (Exception e) { check(false, 'SR-06/2 add vehicles failed: ' + e.getMessage()); }
                List<Sale_Vehicle__c> lines = [SELECT Vehicle__r.Status__c FROM Sale_Vehicle__c WHERE Opportunity__c = :s.Id];
                Integer reserved = 0;
                for (Sale_Vehicle__c l : lines) if (l.Vehicle__r.Status__c == 'Reserved') reserved++;
                check(lines.size() == 2 && reserved == 2, 'SR-06/2 expected 2 reserved cars, got ' + lines.size() + ' lines, ' + reserved + ' reserved');
                Opportunity t = [SELECT Fleet_Vehicles_Total__c, Fleet_Vehicle_Count__c FROM Opportunity WHERE Id = :s.Id];
                check(t.Fleet_Vehicle_Count__c == 2 && t.Fleet_Vehicles_Total__c > 0, 'SR-06/2 totals not updated: ' + t.Fleet_Vehicle_Count__c + ' / ' + t.Fleet_Vehicles_Total__c);
                Flow.Interview more = Flow.Interview.createInterview('Add_Fleet_Vehicles_Core', new Map<String, Object>{ 'recordId' => s.Id, 'modelId' => m.Id, 'quantity' => 999 });
                more.start();
                check([SELECT COUNT() FROM Sale_Vehicle__c WHERE Opportunity__c = :s.Id] < 999, 'SR-06/3 more cars added than in stock');
                Discount_Request__c d = new Discount_Request__c(Opportunity__c = s.Id, Reason__c = 'Agreed fleet rate');
                Database.SaveResult rd = Database.insert(d, false);
                check(rd.isSuccess(), 'SR-07 blank-rate fleet request refused: ' + err(rd));
                if (rd.isSuccess()) {
                    d = [SELECT Requested_Discount__c, Discount_Value__c FROM Discount_Request__c WHERE Id = :d.Id];
                    check(d.Requested_Discount__c == lagos.Agreed_Discount_Rate__c && d.Discount_Value__c > 0, 'SR-07 agreed rate not applied: ' + d.Requested_Discount__c + ' value ' + d.Discount_Value__c);
                }
            }
            Database.SaveResult ri = Database.insert(new Sale_Vehicle__c(Opportunity__c = indiv.Id, Vehicle_Model__c = m.Id), false);
            check(!ri.isSuccess(), 'SR-06/4 fleet vehicles added to an individual sale');
        }
        done();
    }

    // ---------- Sales Rep, new UAT data (scripts/apex/uat_sales_rep_data.apex) ----------
    static Opportunity opp(String name) { return [SELECT Id, AccountId FROM Opportunity WHERE Name = :name LIMIT 1]; }

    @isTest static void SRD_convertAndImport() {
        User rep = u('Sales_Rep');
        String conv = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
        System.runAs(rep) {
            for (String n : new List<String>{ 'Adaeze Nwosu', 'Tunde Fashola' }) {
                Lead l = [SELECT Id, Stock_Alert__c FROM Lead WHERE Name = :n AND IsConverted = false LIMIT 1];
                System.debug('UAT LEAD ' + n + ' flag: ' + l.Stock_Alert__c);
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id); lc.setConvertedStatus(conv);
                Database.LeadConvertResult r = Database.convertLead(lc, false);
                check(r.isSuccess(), 'convert ' + n + ': ' + (r.isSuccess() ? '' : r.getErrors()[0].getMessage()));
                if (!r.isSuccess()) continue;
                Opportunity o = [SELECT Name, Vehicle_Model_Wanted__r.Name, Stock_Alert__c, AccountId FROM Opportunity WHERE Id = :r.getOpportunityId()];
                System.debug('UAT CONVERTED ' + o.Name + ' wanted ' + o.Vehicle_Model_Wanted__r.Name + ' flag: ' + o.Stock_Alert__c);
                check(o.Vehicle_Model_Wanted__c != null, n + ' wanted model not copied');
                if (n == 'Tunde Fashola') {
                    Database.SaveResult ir = Database.insert(new Import_Request__c(Opportunity__c = o.Id, Account__c = o.AccountId, Vehicle_Model__c = o.Vehicle_Model_Wanted__c, Quantity__c = 1, Reason__c = 'Out of stock'), false);
                    check(ir.isSuccess(), 'request import: ' + err(ir));
                }
            }
        }
        done();
    }

    @isTest static void SRD_closeWonAndLock() {
        User rep = u('Sales_Rep');
        Opportunity o = opp('Musa Ibrahim - Toyota Camry 2026 White');
        System.runAs(rep) {
            Database.SaveResult r = Database.update(new Opportunity(Id = o.Id, StageName = 'Closed Won'), false);
            check(r.isSuccess(), 'close won: ' + err(r));
            Database.SaveResult r2 = Database.update(new Opportunity(Id = o.Id, CloseDate = Date.today().addDays(3)), false);
            check(!r2.isSuccess(), 'closed opportunity could be edited');
        }
        check([SELECT Vehicle__r.Status__c FROM Opportunity WHERE Id = :o.Id].Vehicle__r.Status__c == 'Sold', 'car not Sold');
        done();
    }

    @isTest static void SRD_discounts() {
        User rep = u('Sales_Rep');
        Opportunity bisi = opp('Bisi Adewale - Toyota Hilux 2026 Red'), kel = opp('Kelechi Obi - Honda CR-V 2026 White'), ronke = opp('Ronke Alabi - Kia Sportage 2026 White');
        System.runAs(rep) {
            insert new Discount_Request__c(Opportunity__c = bisi.Id, Discount_Rate__c = '5%', Reason__c = 'Loyal customer');
            insert new Discount_Request__c(Opportunity__c = kel.Id, Discount_Rate__c = '7.5%', Reason__c = 'Price match');
            System.debug('UAT BISI ' + [SELECT Finance_Status__c, Sale_Price__c FROM Opportunity WHERE Id = :bisi.Id]);
            System.debug('UAT KELECHI ' + [SELECT Finance_Status__c FROM Opportunity WHERE Id = :kel.Id].Finance_Status__c);
            Database.SaveResult r = Database.update(new Opportunity(Id = bisi.Id, Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = 6), false);
            check(r.isSuccess(), 'bisi to instalment: ' + err(r));
            Opportunity b = [SELECT List_Price__c, Sale_Price__c, Instalment_Down_Payment__c, Monthly_Instalment__c, Finance_Status__c FROM Opportunity WHERE Id = :bisi.Id];
            System.debug('UAT BISI AFTER ' + b);
            check(b.Sale_Price__c == b.List_Price__c && b.Instalment_Down_Payment__c == b.List_Price__c * 0.3, 'price/deposit after invalidation: ' + b);
            Database.SaveResult r2 = Database.update(new Opportunity(Id = ronke.Id, Payment_Mode__c = 'Instalment', Instalment_Term_Months__c = 6), false);
            check(r2.isSuccess(), 'ronke to instalment: ' + err(r2));
            Database.SaveResult r3 = Database.insert(new Discount_Request__c(Opportunity__c = ronke.Id, Discount_Rate__c = '5%', Reason__c = 'x'), false);
            check(!r3.isSuccess(), 'discount allowed on instalment');
            System.debug('UAT RONKE ' + [SELECT Instalment_Down_Payment__c, Monthly_Instalment__c, Sale_Price__c FROM Opportunity WHERE Id = :ronke.Id]);
        }
        done();
    }

    @isTest static void FT09_CS08_fieldAccess() {
        User agent = u('Customer_Service_Agent');
        Set<Id> ps = new Set<Id>();
        for (PermissionSetAssignment p : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :agent.Id]) ps.add(p.PermissionSetId);
        for (FieldPermissions f : [SELECT Field FROM FieldPermissions WHERE ParentId IN :ps AND SobjectType = 'Opportunity' AND PermissionsRead = true AND Field IN ('Opportunity.Amount', 'Opportunity.Sale_Price__c', 'Opportunity.List_Price__c', 'Opportunity.Total_Paid__c', 'Opportunity.Balance_Remaining__c')]) check(false, 'CS-08/2 CS Agent can see ' + f.Field);
        User fin = u('Finance_Team_Member');
        Set<Id> fps = new Set<Id>();
        for (PermissionSetAssignment p : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :fin.Id]) fps.add(p.PermissionSetId);
        for (FieldPermissions f : [SELECT Field FROM FieldPermissions WHERE ParentId IN :fps AND PermissionsEdit = true AND Field IN ('Instalment_Plan__c.Head_of_Finance_Sign_off__c', 'Instalment_Plan__c.Signed_Off_By__c', 'Instalment_Plan__c.Signed_Off_On__c')]) check(false, 'FT-09/1 Finance can edit ' + f.Field);
        done();
    }

    // ---------- Showroom Manager ----------
    @isTest static void SM03_SM04_manager() {
        User mgr = u('Showroom_Manager'), rep = u('Sales_Rep');
        Vehicle_Model__c m = [SELECT Id, Available_Stock__c FROM Vehicle_Model__c WHERE Available_Stock__c > 0 LIMIT 1];
        List<Lead> hp = [SELECT Id FROM Lead WHERE IsConverted = false AND Owner.UserRole.DeveloperName = 'Showroom_Manager' AND Returning_or_High_profile__c = true LIMIT 1];
        System.runAs(mgr) {
            Database.SaveResult r = Database.update(new Vehicle_Model__c(Id = m.Id, Low_stock_Threshold__c = m.Available_Stock__c + 1), false);
            check(r.isSuccess(), 'SM-03/1 threshold not saved: ' + err(r));
            if (!hp.isEmpty()) {
                Database.SaveResult r2 = Database.update(new Lead(Id = hp[0].Id, OwnerId = rep.Id), false);
                check(r2.isSuccess(), 'SM-04/2 manager could not hand the client to a rep: ' + err(r2));
            } else check(false, 'SM-04 no high-profile lead owned by the manager to test with');
        }
        done();
    }

    // ---------- Finance ----------
    @isTest static void FT02_depositAndSignoffRules() {
        User fin = u('Finance_Team_Member');
        Instalment__c h1 = month('Hauwa Lawal', '1');
        System.runAs(fin) {
            Database.SaveResult r = Database.insert(new Payment__c(Opportunity__c = h1.Instalment_Plan__r.Opportunity__c, Amount__c = 1000, Type__c = 'Down Payment', Method__c = 'Bank Transfer', Paid_On__c = Date.today()), false);
            check(!r.isSuccess(), 'FT-02/4 a second down payment was accepted');
            Database.SaveResult r2 = Database.insert(pay(h1, h1.Amount_Due__c), false);
            check(!r2.isSuccess(), 'FT-02/5 monthly payment accepted before sign-off');
        }
        done();
    }

    @isTest static void FT03_fullPayment() {
        User fin = u('Finance_Team_Member');
        Instalment__c m2 = month('Segun Ajayi', '2');
        System.runAs(fin) {
            Database.SaveResult r = Database.insert(pay(m2, m2.Balance__c), false);
            check(r.isSuccess(), 'FT-03/2 payment refused: ' + err(r));
            if (r.isSuccess()) check([SELECT Recorded_By__c FROM Payment__c WHERE Id = :r.getId()].Recorded_By__c != null, 'FT-03/2 Recorded By empty');
        }
        Instalment__c after = [SELECT Amount_Paid__c, Balance__c, Status__c FROM Instalment__c WHERE Id = :m2.Id];
        check(after.Balance__c == 0 && after.Status__c == 'Paid', 'FT-03/2 month 2: balance ' + after.Balance__c + ', status ' + after.Status__c);
        done();
    }

    @isTest static void FT04_partAndExtraPayments() {
        User fin = u('Finance_Team_Member');
        Instalment__c m1 = month('Chiamaka Okonkwo', '1'), m2 = month('Chiamaka Okonkwo', '2');
        System.runAs(fin) {
            insert pay(m1, 2000000);
            Instalment__c a1 = [SELECT Balance__c, Status__c FROM Instalment__c WHERE Id = :m1.Id];
            check(a1.Balance__c == m1.Amount_Due__c - 2000000 && a1.Status__c != 'Paid', 'FT-04/1 part payment: balance ' + a1.Balance__c + ' status ' + a1.Status__c);
            insert pay(m2, 3000000);
            Instalment__c a2 = [SELECT Balance__c, Status__c FROM Instalment__c WHERE Id = :m2.Id];
            check(a2.Status__c == 'Paid', 'FT-04/2 overpaid month not Paid: ' + a2.Status__c);
        }
        done();
    }

    @isTest static void FT07_completion() {
        User fin = u('Finance_Team_Member');
        Instalment__c m3 = month('Emmanuel Udo', '3');
        System.runAs(fin) { insert pay(m3, m3.Balance__c); }
        Instalment_Plan__c p = [SELECT Plan_Status__c, Completion_Email_Sent__c FROM Instalment_Plan__c WHERE Id = :m3.Instalment_Plan__c];
        check(p.Plan_Status__c == 'Completed' && p.Completion_Email_Sent__c, 'FT-07/1 plan ' + p.Plan_Status__c + ', email sent ' + p.Completion_Email_Sent__c);
        done();
    }

    @isTest static void FT08_importToStock() {
        // an existing request raised by sales (sharing on a request created inside a test isn't applied yet)
        User fin = u('Finance_Team_Member');
        Import_Request__c ir = [SELECT Id, Quantity__c, Vehicle_Model__c FROM Import_Request__c WHERE Status__c = 'Requested' LIMIT 1];
        Vehicle_Model__c m = [SELECT Id, Available_Stock__c FROM Vehicle_Model__c WHERE Id = :ir.Vehicle_Model__c];
        Decimal stockBefore = m.Available_Stock__c == null ? 0 : m.Available_Stock__c;
        System.runAs(fin) {
            for (String st : new List<String>{ 'Customer Confirmed', 'Finance Confirmed', 'Imported' }) {
                Database.SaveResult r = Database.update(new Import_Request__c(Id = ir.Id, Status__c = st), false);
                check(r.isSuccess(), 'FT-08/1 could not move to ' + st + ': ' + err(r));
            }
        }
        check([SELECT Available_Stock__c FROM Vehicle_Model__c WHERE Id = :m.Id].Available_Stock__c == stockBefore + (ir.Quantity__c == null ? 1 : ir.Quantity__c), 'FT-08/2 stock did not go up by the quantity');
        done();
    }

    // ---------- Head of Finance ----------
    @isTest static void HF02_planRulesAndSignoff() {
        User hof = u('Head_of_Finance');
        Instalment_Plan__c ngozi = [SELECT Id FROM Instalment_Plan__c WHERE Name LIKE '%Ngozi Okeke%' LIMIT 1];
        Instalment_Plan__c hauwa = [SELECT Id FROM Instalment_Plan__c WHERE Name LIKE '%Hauwa Lawal%' LIMIT 1];
        System.runAs(hof) {
            check(!Database.update(new Instalment_Plan__c(Id = ngozi.Id, Term_in_Months__c = 13), false).isSuccess(), 'HF-02/1 13 months accepted');
            check(!Database.update(new Instalment_Plan__c(Id = ngozi.Id, Down_Payment_Percent__c = 20), false).isSuccess(), 'HF-02/2 20% deposit accepted');
            Database.SaveResult r = Database.update(new Instalment_Plan__c(Id = hauwa.Id, Head_of_Finance_Sign_off__c = true), false);
            check(r.isSuccess(), 'HF-02/3 sign-off refused: ' + err(r));
        }
        Instalment_Plan__c h = [SELECT Signed_Off_By__c, Signed_Off_On__c, Plan_Status__c FROM Instalment_Plan__c WHERE Id = :hauwa.Id];
        check(h.Signed_Off_By__c != null && h.Signed_Off_On__c != null && h.Plan_Status__c == 'Active', 'HF-02/3 after sign-off: by ' + h.Signed_Off_By__c + ', status ' + h.Plan_Status__c);
        done();
    }

    @isTest static void HF02_guarantorIncomeCheck() {
        User hof = u('Head_of_Finance');
        Instalment_Plan__c z = [SELECT Id, Guarantor__c FROM Instalment_Plan__c WHERE Name LIKE '%Zainab Bello%' LIMIT 1];
        update new Guarantor__c(Id = z.Guarantor__c, Income_Check_Done__c = false);
        System.runAs(hof) {
            check(!Database.update(new Instalment_Plan__c(Id = z.Id, Head_of_Finance_Sign_off__c = true), false).isSuccess(), 'HF-02/4 signed off with guarantor income check not done');
        }
        done();
    }

    @isTest static void HF03_needsAttention() {
        Map<String, String> want = new Map<String, String>{ 'Funke Ayo' => 'Late', 'Folake Ogunleye' => 'Defaulted', 'Suleiman Bello' => 'Defaulted' };
        for (String c : want.keySet()) {
            Instalment_Plan__c p = [SELECT Plan_Status__c, Next_Step__c FROM Instalment_Plan__c WHERE Name LIKE :('%' + c + '%') LIMIT 1];
            check(p.Plan_Status__c == want.get(c), 'HF-03/1 ' + c + ' is ' + p.Plan_Status__c);
            if (c == 'Funke Ayo') System.debug('UAT FUNKE NEXT STEP: ' + p.Next_Step__c);
        }
        done();
    }

    @isTest static void HF04_reconciliation() {
        User hof = u('Head_of_Finance');
        System.runAs(hof) {
            Reconciliation_Entry__c e = new Reconciliation_Entry__c(Date__c = Date.today(), Bank_Total__c = 123456789);
            Database.SaveResult r = Database.insert(e, false);
            check(r.isSuccess(), 'HF-04/1 entry refused: ' + err(r));
            if (r.isSuccess()) {
                e = [SELECT Recorded_Total__c, Difference__c, Status__c FROM Reconciliation_Entry__c WHERE Id = :e.Id];
                check(e.Recorded_Total__c != null && e.Difference__c != 0 && e.Status__c == 'Flagged', 'HF-04/1 recorded ' + e.Recorded_Total__c + ' status ' + e.Status__c);
                check(!Database.update(new Reconciliation_Entry__c(Id = e.Id, Status__c = 'Explained'), false).isSuccess(), 'HF-04/3 Explained without a note');
                check(Database.update(new Reconciliation_Entry__c(Id = e.Id, Status__c = 'Explained', Note__c = 'Bank charge'), false).isSuccess(), 'HF-04/4 Explained with a note refused');
            }
        }
        done();
    }

    @isTest static void HF05_legalEscalation() {
        User hof = u('Head_of_Finance');
        Instalment_Plan__c p = [SELECT Id, Opportunity__r.AccountId FROM Instalment_Plan__c WHERE Name LIKE '%Suleiman Bello%' LIMIT 1];
        System.runAs(hof) {
            Database.SaveResult r = Database.insert(new Legal_Escalation__c(Instalment_Plan__c = p.Id, Account__c = p.Opportunity__r.AccountId, Months_Defaulted__c = 3, Total_Amount_Owed__c = 7500000), false);
            check(r.isSuccess(), 'HF-05/2 escalation refused: ' + err(r));
        }
        check([SELECT Plan_Status__c FROM Instalment_Plan__c WHERE Id = :p.Id].Plan_Status__c == 'With Legal', 'HF-05/3 plan not With Legal');
        done();
    }

    // ---------- Customer Service ----------
    @isTest static void CS01_routing() {
        List<Case> cs = new List<Case>();
        for (Schema.PicklistEntry e : Case.Type.getDescribe().getPicklistValues()) if (e.isActive()) cs.add(new Case(Subject = 'UAT ' + e.getValue(), Type = e.getValue(), Origin = 'Web', SuppliedEmail = 'uat@example.com'));
        insert cs;
        for (Case c : [SELECT Type, Routed_To__c, Owner.Name FROM Case WHERE Id IN :cs]) {
            System.debug('UAT CASE ' + c.Type + ' -> ' + c.Routed_To__c + ' / ' + c.Owner.Name);
            check(c.Routed_To__c != null, 'CS-01 case type ' + c.Type + ' not routed');
        }
        done();
    }

    @isTest static void CS04_CS05_CS06_caseLife() {
        User agent = u('Customer_Service_Agent');
        Case c = new Case(Subject = 'UAT problem', Type = 'Technical', Origin = 'Web', SuppliedEmail = 'uat@example.com');
        insert c;
        update new Case(Id = c.Id, OwnerId = agent.Id);
        System.runAs(agent) {
            Database.SaveResult r = Database.insert(new Customer_Message__c(Case__c = c.Id, Type__c = 'Status Update', Channel__c = 'Email', Message_Text__c = 'We are looking at it'), false);
            check(r.isSuccess(), 'CS-04/1 reply refused: ' + err(r));
            check([SELECT First_Response_At__c FROM Case WHERE Id = :c.Id].First_Response_At__c != null, 'CS-04/1 First Response At empty');
            Integer before = [SELECT COUNT() FROM Customer_Message__c WHERE Case__c = :c.Id];
            update new Case(Id = c.Id, Status = 'Working');
            check([SELECT COUNT() FROM Customer_Message__c WHERE Case__c = :c.Id] == before + 1, 'CS-05/1 no status update message for Working');
            check(!Database.update(new Case(Id = c.Id, Status = 'Closed', CSAT_Score__c = 11), false).isSuccess(), 'CS-06/1 CSAT 11 accepted');
            Database.SaveResult rc = Database.update(new Case(Id = c.Id, Status = 'Closed'), false);
            check(rc.isSuccess(), 'CS-04/2 close refused: ' + err(rc));
            check([SELECT Resolved_At__c FROM Case WHERE Id = :c.Id].Resolved_At__c != null, 'CS-04/2 Resolved At empty');
            check([SELECT COUNT() FROM Customer_Message__c WHERE Case__c = :c.Id AND Type__c = 'Resolution'] == 1, 'CS-05/1 not exactly one resolution message');
            check(Database.update(new Case(Id = c.Id, CSAT_Score__c = 8), false).isSuccess(), 'CS-06/2 CSAT 8 refused');
        }
        done();
    }

    @isTest static void CS05_ownerChangeSendsNothing() {
        User head = u('Head_of_Customer_Service');
        Case c = new Case(Subject = 'UAT owner', Type = 'Technical', Origin = 'Web', SuppliedEmail = 'uat@example.com');
        insert c;
        Integer before = [SELECT COUNT() FROM Customer_Message__c WHERE Case__c = :c.Id];
        update new Case(Id = c.Id, OwnerId = head.Id);
        check([SELECT COUNT() FROM Customer_Message__c WHERE Case__c = :c.Id] == before, 'CS-05/2 owner change sent a message');
        done();
    }

    @isTest static void HC05_knowledge() {
        User head = u('Head_of_Customer_Service');
        List<Knowledge_Article__c> ka = [SELECT Id FROM Knowledge_Article__c LIMIT 2];
        check(ka.size() == 2, 'HC-05 fewer than 2 knowledge articles');
        if (ka.size() == 2) System.runAs(head) {
            check(Database.update(new Knowledge_Article__c(Id = ka[0].Id, Agreed_Answer__c = 'Updated in UAT'), false).isSuccess(), 'HC-05/1 edit refused');
            Database.SaveResult r = Database.update(new Knowledge_Article__c(Id = ka[1].Id, Status__c = 'Retired'), false);
            check(r.isSuccess(), 'HC-05/2 retire refused: ' + err(r));
        }
        done();
    }
}
