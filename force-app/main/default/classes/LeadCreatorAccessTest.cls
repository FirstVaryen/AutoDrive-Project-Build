@IsTest
private class LeadCreatorAccessTest {
    @IsTest static void creatorKeepsReadAccess() {
        User other = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() AND UserType = 'Standard' LIMIT 1];
        Lead l = new Lead(LastName = 'Access Check', Company = 'Access Check', Phone = '08011112222', OwnerId = other.Id);
        insert l;
        System.assertEquals(1, [SELECT COUNT() FROM LeadShare WHERE LeadId = :l.Id AND UserOrGroupId = :UserInfo.getUserId() AND RowCause = 'Manual']);
    }

    @IsTest static void markingHighProfileMovesLeadToManager() {
        List<User> mgr = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'Showroom_Manager' AND IsActive = true LIMIT 1];
        Lead l = new Lead(LastName = 'Later Check', Company = 'Later Check', Phone = '08011113333', Channel__c = 'Instagram');
        insert l;
        update new Lead(Id = l.Id, Returning_or_High_profile__c = true);
        if (!mgr.isEmpty()) {
            System.assertEquals(mgr[0].Id, [SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId);
        }
    }
}
