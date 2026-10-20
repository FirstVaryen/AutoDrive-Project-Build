/**
 * Fleet sale lines (Sale_Vehicle__c):
 * - a line on a closed sale cannot be removed;
 * - removing a line puts its car back to Available (it was Reserved for this sale);
 * - the sale's Fleet Summary shows how many cars of each type it holds, e.g. "5 x Toyota Hilux 2026 White".
 */
public without sharing class SaleVehicleHandler {
    public static void blockClosed(List<Sale_Vehicle__c> lines) {
        Set<Id> opps = new Set<Id>();
        for (Sale_Vehicle__c l : lines) opps.add(l.Opportunity__c);
        Map<Id, Opportunity> closed = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :opps AND IsClosed = true]);
        for (Sale_Vehicle__c l : lines) if (closed.containsKey(l.Opportunity__c)) l.addError('This sale is closed, so its vehicles cannot be removed.');
    }

    public static void releaseCars(List<Sale_Vehicle__c> lines) {
        Set<Id> cars = new Set<Id>();
        for (Sale_Vehicle__c l : lines) if (l.Vehicle__c != null) cars.add(l.Vehicle__c);
        // a car still on another line keeps its reservation
        for (Sale_Vehicle__c other : [SELECT Vehicle__c FROM Sale_Vehicle__c WHERE Vehicle__c IN :cars]) cars.remove(other.Vehicle__c);
        List<Vehicle__c> back = [SELECT Id FROM Vehicle__c WHERE Id IN :cars AND Status__c = 'Reserved'];
        for (Vehicle__c v : back) v.Status__c = 'Available';
        update back;
    }

    public static void refreshSummaries(List<Sale_Vehicle__c> lines) {
        Set<Id> opps = new Set<Id>();
        for (Sale_Vehicle__c l : lines) opps.add(l.Opportunity__c);
        Map<Id, Map<String, Integer>> counts = new Map<Id, Map<String, Integer>>();
        for (Id o : opps) counts.put(o, new Map<String, Integer>());
        for (Sale_Vehicle__c l : [SELECT Opportunity__c, Vehicle_Model__r.Name, Vehicle__r.Model__r.Name FROM Sale_Vehicle__c WHERE Opportunity__c IN :opps]) {
            String t = l.Vehicle_Model__r.Name != null ? l.Vehicle_Model__r.Name : l.Vehicle__r.Model__r.Name;
            Map<String, Integer> m = counts.get(l.Opportunity__c);
            m.put(t, (m.containsKey(t) ? m.get(t) : 0) + 1);
        }
        List<Opportunity> ups = new List<Opportunity>();
        for (Opportunity o : [SELECT Id FROM Opportunity WHERE Id IN :opps AND IsClosed = false]) {
            List<String> parts = new List<String>();
            List<String> types = new List<String>(counts.get(o.Id).keySet());
            types.sort();
            for (String t : types) parts.add(counts.get(o.Id).get(t) + ' x ' + t);
            ups.add(new Opportunity(Id = o.Id, Fleet_Summary__c = String.join(parts, '\n')));
        }
        update ups;
    }
}
