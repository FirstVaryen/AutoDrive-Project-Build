// Lists the vehicles on a discount request's sale, one per line with its own list price,
// then the number of vehicles and the total the discount is worked out on.
public with sharing class DiscountRequestVehicles {
    public static void fill(List<Discount_Request__c> requests) {
        Set<Id> oppIds = new Set<Id>();
        for (Discount_Request__c d : requests) if (d.Opportunity__c != null) oppIds.add(d.Opportunity__c);
        if (oppIds.isEmpty()) return;
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([
            SELECT Id, List_Price__c, Vehicle__r.Name,
                (SELECT Vehicle__r.Name, Vehicle_Model__r.Name, Sale_Price__c FROM Sale_Vehicles__r ORDER BY Vehicle__r.Name)
            FROM Opportunity WHERE Id IN :oppIds]);
        for (Discount_Request__c d : requests) {
            Opportunity o = opps.get(d.Opportunity__c);
            if (o == null) continue;
            List<String> lines = new List<String>();
            Decimal total = 0;
            Integer n = 0;
            for (Sale_Vehicle__c l : o.Sale_Vehicles__r) {
                n++;
                String car = l.Vehicle__r.Name != null ? l.Vehicle__r.Name : l.Vehicle_Model__r.Name;
                Decimal price = l.Sale_Price__c == null ? 0 : l.Sale_Price__c;
                total += price;
                lines.add(n + '. ' + car + '  —  USD ' + money(price));
            }
            if (n == 0 && o.Vehicle__r.Name != null) {
                n = 1;
                total = o.List_Price__c == null ? 0 : o.List_Price__c;
                lines.add('1. ' + o.Vehicle__r.Name + '  —  USD ' + money(total));
            }
            if (n == 0) { d.Vehicle_List__c = null; continue; }
            lines.add('');
            lines.add('Total for ' + n + (n == 1 ? ' vehicle' : ' vehicles') + ': USD ' + money(total));
            d.Vehicle_List__c = String.join(lines, '\n');
        }
    }

    private static String money(Decimal v) {
        return v.setScale(0).format();
    }
}
