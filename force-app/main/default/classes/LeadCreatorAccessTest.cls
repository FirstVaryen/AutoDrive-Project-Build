@IsTest
private class LeadCreatorAccessTest {
    @IsTest static void creatorKeepsReadAccess() {
        User other = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() AND UserType = 'Standard' LIMIT 1];
        Lead l = new Lead(LastName = 'Access Check', Company = 'Access Check', OwnerId = other.Id);
        insert l;
        System.assertEquals(1, [SELECT COUNT() FROM LeadShare WHERE LeadId = :l.Id AND UserOrGroupId = :UserInfo.getUserId() AND RowCause = 'Manual']);
    }
}
