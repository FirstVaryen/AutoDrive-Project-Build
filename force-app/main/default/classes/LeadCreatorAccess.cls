// A lead that is passed straight to someone else when it is saved (for example a high-profile walk-in
// sent to the Showroom Manager) stays readable, not editable, by the person who entered it.
public without sharing class LeadCreatorAccess {
    public static void grant(List<Lead> leads) {
        List<LeadShare> shares = new List<LeadShare>();
        for (Lead l : leads) {
            if (l.OwnerId != l.CreatedById && String.valueOf(l.OwnerId).startsWith('005')) {
                shares.add(new LeadShare(LeadId = l.Id, UserOrGroupId = l.CreatedById, LeadAccessLevel = 'Read', RowCause = 'Manual'));
            }
        }
        if (!shares.isEmpty()) Database.insert(shares, false);
    }
}
