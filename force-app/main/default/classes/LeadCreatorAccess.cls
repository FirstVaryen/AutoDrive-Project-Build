// A returning or high-profile lead belongs to the Showroom Manager. Whoever entered it, or owned it
// before it was marked high-profile, keeps read-only access so they can still see it but not work it.
public without sharing class LeadCreatorAccess {

    // before update: a lead newly marked high-profile moves to the Showroom Manager
    public static void routeHighProfile(List<Lead> leads, Map<Id, Lead> old) {
        Id manager = managerId();
        if (manager == null) return;
        for (Lead l : leads) {
            Lead o = old.get(l.Id);
            if (!l.IsConverted && isHighProfile(l) && !isHighProfile(o) && l.OwnerId != manager) {
                l.OwnerId = manager;
                l.Returning_or_High_profile__c = true;
            }
        }
    }

    // after insert / update: the person who lost the lead keeps read access
    public static void grant(List<Lead> leads, Map<Id, Lead> old) {
        List<LeadShare> shares = new List<LeadShare>();
        for (Lead l : leads) {
            Id keep = old == null ? l.CreatedById : old.get(l.Id).OwnerId;
            if (keep != null && l.OwnerId != keep && String.valueOf(l.OwnerId).startsWith('005') && String.valueOf(keep).startsWith('005')) {
                shares.add(new LeadShare(LeadId = l.Id, UserOrGroupId = keep, LeadAccessLevel = 'Read', RowCause = 'Manual'));
            }
        }
        if (!shares.isEmpty()) Database.insert(shares, false);
    }

    public static void grant(List<Lead> leads) { grant(leads, null); }

    private static Boolean isHighProfile(Lead l) {
        return l.Returning_or_High_profile__c == true || l.Channel__c == 'Returning/High-profile';
    }

    private static Id managerId() {
        List<User> u = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'Showroom_Manager' AND IsActive = true LIMIT 1];
        return u.isEmpty() ? null : u[0].Id;
    }
}
