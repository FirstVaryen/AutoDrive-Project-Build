// Run once in the target org after the deploy (sf apex run -o <alias> -f scripts/deploy/post-deploy-setup.apex).
// Schedules the background jobs that a deploy does not carry over, and reports what still needs doing by hand.

// 1. Auto-assignment of web leads and cases to online staff, every 5 minutes
Set<String> existing = new Set<String>();
for (CronTrigger c : [SELECT CronJobDetail.Name FROM CronTrigger]) existing.add(c.CronJobDetail.Name);
if (!existing.contains('AD Auto Assign :00')) AutoAssigner.scheduleEvery5Minutes();

// 2. Daily refresh of each instalment plan's Next Step and Month by Month (late day counts)
if (!existing.contains('AutoDrive - Plan progress daily')) System.schedule('AutoDrive - Plan progress daily', '0 0 23 * * ?', new PlanProgress());

// 3. Checks: things a deploy cannot create
List<String> todo = new List<String>();
if ([SELECT COUNT() FROM OrgWideEmailAddress WHERE IsVerified = true] == 0) todo.add('Create and verify the AutoDrive Motors org-wide email address');
for (String r : new List<String>{ 'Showroom_Manager', 'Sales_Rep', 'Finance_Team_Member', 'Head_of_Finance', 'Customer_Service_Agent', 'Head_of_Customer_Service', 'Legal_Team', 'Management' }) {
    if ([SELECT COUNT() FROM User WHERE IsActive = true AND UserRole.DeveloperName = :r] == 0) todo.add('No active user in role ' + r);
}
for (String l : new List<String>{ 'AD_Email_Showroom_Manager', 'AD_Email_Finance', 'AD_Email_Head_Of_Finance', 'AD_Email_Legal', 'AD_Customer_Email_Sender' }) {
    todo.add('Check Custom Label ' + l + ' holds the right address for this org');
}
System.debug('POST-DEPLOY scheduled jobs: ' + [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AD Auto Assign%' OR CronJobDetail.Name = 'AutoDrive - Plan progress daily']);
for (String t : todo) System.debug('POST-DEPLOY TODO: ' + t);
