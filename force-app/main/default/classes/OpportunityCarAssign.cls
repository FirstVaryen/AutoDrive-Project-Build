/**
 * The sales rep picks only the vehicle type (Vehicle Wanted). This puts a free car of that type on the
 * opportunity: an Available car that no other open opportunity is holding. If the type changes, the car
 * is swapped, and so is a car since sold to someone else. If none is free, the opportunity keeps no car and shows the sold-out flag.
 */
public with sharing class OpportunityCarAssign {
    public static void assign(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        Set<Id> currentCars = new Set<Id>();
        for (Opportunity o : opps) if (o.Vehicle__c != null) currentCars.add(o.Vehicle__c);
        Map<Id, Id> carModel = new Map<Id, Id>();
        // a car that has been sold elsewhere no longer counts as this opportunity's car
        for (Vehicle__c v : [SELECT Id, Model__c, Status__c FROM Vehicle__c WHERE Id IN :currentCars]) if (v.Status__c != 'Sold') carModel.put(v.Id, v.Model__c);

        List<Opportunity> todo = new List<Opportunity>();
        Set<Id> models = new Set<Id>();
        for (Opportunity o : opps) {
            if (o.IsClosed || o.Vehicle_Model_Wanted__c == null) continue;
            Boolean modelChanged = oldMap == null || oldMap.get(o.Id).Vehicle_Model_Wanted__c != o.Vehicle_Model_Wanted__c;
            Boolean carMatches = o.Vehicle__c != null && carModel.get(o.Vehicle__c) == o.Vehicle_Model_Wanted__c;
            if (carMatches) continue;
            if (o.Vehicle__c != null && carModel.containsKey(o.Vehicle__c) && !modelChanged) continue; // a car picked directly is kept
            todo.add(o);
            models.add(o.Vehicle_Model_Wanted__c);
        }
        if (todo.isEmpty()) return;

        Set<Id> held = new Set<Id>();
        for (Opportunity o : [SELECT Vehicle__c FROM Opportunity WHERE IsClosed = false AND Vehicle__c != null AND Vehicle__r.Model__c IN :models AND Id NOT IN :opps])
            held.add(o.Vehicle__c);
        Map<Id, List<Id>> free = new Map<Id, List<Id>>();
        for (Vehicle__c v : [SELECT Id, Model__c FROM Vehicle__c WHERE Model__c IN :models AND Status__c = 'Available' ORDER BY Name]) {
            if (held.contains(v.Id)) continue;
            if (!free.containsKey(v.Model__c)) free.put(v.Model__c, new List<Id>());
            free.get(v.Model__c).add(v.Id);
        }
        for (Opportunity o : todo) {
            List<Id> cars = free.get(o.Vehicle_Model_Wanted__c);
            o.Vehicle__c = (cars == null || cars.isEmpty()) ? null : cars.remove(0);
        }
    }

    // The opportunity is named after the customer and the vehicle type they want, and the name follows the type
    // whenever it changes, so the name, Vehicle Wanted and the assigned car always tell the same story.
    public static void nameFromModel(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> todo = new List<Opportunity>();
        Set<Id> ids = new Set<Id>();
        for (Opportunity o : opps) {
            if (o.Vehicle_Model_Wanted__c == null || o.AccountId == null) continue;
            if (oldMap != null && oldMap.get(o.Id).Vehicle_Model_Wanted__c == o.Vehicle_Model_Wanted__c) continue;
            todo.add(o);
            ids.add(o.Vehicle_Model_Wanted__c);
            ids.add(o.AccountId);
        }
        if (todo.isEmpty()) return;
        Map<Id, String> names = new Map<Id, String>();
        for (Vehicle_Model__c m : [SELECT Id, Name FROM Vehicle_Model__c WHERE Id IN :ids]) names.put(m.Id, m.Name);
        for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :ids]) names.put(a.Id, a.Name);
        for (Opportunity o : todo) o.Name = (names.get(o.AccountId) + ' - ' + names.get(o.Vehicle_Model_Wanted__c)).left(120);
    }
}
