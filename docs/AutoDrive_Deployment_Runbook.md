# AutoDrive Motors – Deployment Runbook

How to move the AutoDrive build from the build/UAT sandbox to the go-live org without anything being missed. Every step has an owner and a check. **Do not start until the build is complete and UAT is signed off.**

| | |
|---|---|
| **From (build and UAT)** | Group3SB – https://dk1791276250211--group3sb.sandbox.my.salesforce.com (CLI alias `autodrive-dev`) |
| **To (go-live)** | Group3Prod – https://dk1791276250211--group3prod.sandbox.my.salesforce.com (CLI alias `autodrive-prod`, already connected) |
| **Source** | `force-app/` in this repository (git, branch `master`) |
| **Release lead** | Hillary Emmanuel |

---

## 1. What has been made deploy-safe

These were checked and fixed so the package doesn't depend on anything that only exists in Group3SB.

| Problem in the sandbox build | Fixed by | Files |
|---|---|---|
| Three flows used the sandbox's internal role and user IDs, which are different in every org | The flows now look up the role by its name (Showroom_Manager, Sales_Rep, Head_of_Customer_Service) | `Lead_Walkin_Assignment`, `Lead_HighProfile_To_Manager`, `Case_Escalation_1_Hour` |
| Six flows sent staff alerts to typed-in test addresses | Addresses moved to **Custom Labels**, one per team, editable in Setup → Custom Labels | Labels `AD_Email_Showroom_Manager`, `AD_Email_Finance`, `AD_Email_Head_Of_Finance`, `AD_Email_Legal`; flows `Legal_Escalation_Raise`, `Opportunity_Discount_Invalidation`, `Opportunity_Vehicle_Change_Refund`, `Vehicle_Model_Low_Stock_Alert`, `Discount_Request_SLA_Reminder` |
| Customer emails were sent from a fixed sender address | Sender held in Custom Label `AD_Customer_Email_Sender` | `Case_Customer_Updates`, `Case_Satisfaction_Request`, `Instalment_Reminder_3_Days`, `Instalment_Late_Notices`, `Instalment_Plan_Completion_Email` |
| Discount approval steps, 8 dashboards and the Case support address name sandbox test users (usernames are unique across Salesforce, so they can't exist in Group3Prod) | `scripts/deploy/prepare-target.ps1` swaps them for the Group3Prod usernames listed in `scripts/deploy/target-users.csv` | `approvalProcesses/`, `dashboards/`, `settings/Case.settings-meta.xml` |
| The website metadata in the repo was older than the live site (an earlier deploy failed: "needs omniscript route") | Fresh copy of the AutoDrive site retrieved into the repo (other demo-org sites left out) | `experiences/AutoDrive_Motors1/`, `networks/`, `sites/` |
| An unused custom New Lead form was left in the build | Removed from the repo and from Group3SB | `Lead_New_Enquiry`, `LeadNewOverride`, `Lead_New_Enquiry_Flow` |
| Two AutoDrive Apex tests failed (test leads had no phone) | Test data fixed; all AutoDrive tests pass | `LeadCreatorAccessTest` |

**Apex test status (Group3SB, 25 Oct 2026):** all 5 AutoDrive test classes pass. Coverage per class: AutoAssigner 93%, SaleVehicleHandler 100%, DiscountRequestVehicles 89%, PlanProgress 78%, Reconciliation 97%, LeadCreatorAccess 86–100%. The demo org's own sample tests (B2B, SDO) fail on their own; they are not ours, so deploy with **RunSpecifiedTests** (section 5).

---

## 2. Corrections made during UAT (what the package now contains)

Each line is something found in testing and the build that fixed it. All of it is in `force-app/` and deploys with the package unless the last column says otherwise.

### Sales and showroom
| Found in testing | What was built | Deploys? |
|---|---|---|
| Discount approve/reject failed when a car was on two sales | Data fix; plus single-car sales now **reserve** the car on deposit (`Payment_Down_Payment_Reserve_Car`) and a sale can't take a car reserved for another (`Opportunity_Vehicle_Must_Be_Free`) | Yes |
| Approvers couldn't see what was being discounted | Discount Request shows customer, every vehicle with its own list price, total, discount value and price after discount (`Vehicle_List__c`, Apex `DiscountRequestVehicles`, formula fields, approval page fields) | Yes |
| Records were named only by number | Reference · customer · detail names on Discount Requests, Approval Steps, Customer Messages, Plans, Instalments, Payments (`Record_No__c` + `*_Set_Name` / `*_Keep_Name` flows) | Yes |
| Head of Finance could edit and delete sales; saw Request Discount | Sales read-only in the `*_Full` permission sets; Head of Finance sale layout without Request Discount (`Opportunity-AutoDrive Finance Layout`, profile assignment) | Yes |
| High-profile / returning walk-ins stayed with the rep, then errored on save | Routed to the Showroom Manager at save or when ticked later; the person who entered it keeps read-only access (Apex `LeadCreatorAccess`); bell messages (`Lead_HighProfile_To_Manager`, notification type `AutoDrive_Sales_Alert`); list `AutoDrive - High-profile Clients` | Yes |
| Too many lead lists | Reps: My Leads, Website Leads, High-profile Clients; manager lists shared to the manager only | Yes (list views). Two demo lists to delete by hand: see 6.3 |
| Hot Leads not in any story | Removed | Yes (removed) |

### Finance
| Found in testing | What was built | Deploys? |
|---|---|---|
| Finance could tick Head of Finance sign-off | Sign-off editable by Head of Finance only; Signed Off By/On stamped automatically (`Instalment_Plan_Stamp_Signoff`) | Yes |
| Down payment could be recorded twice; monthly payments before sign-off | Rules `Down_Payment_Only_Once`, `Instalment_Payment_Needs_Signoff`; Record Payment screen explains a refusal | Yes |
| Instalments and payments not visible on the plan | Related lists on plan and instalment layouts | Yes |
| Plans showed Active before sign-off | New status **Awaiting Sign-off** (`Instalment_Plan_Recalculate_Status`, `Instalment_Plan_Status_From_Signoff`) | Yes |
| Last month didn't add up exactly | Schedule puts the rounding on the last month (`Instalment_Plan_Create_Schedule`) | Yes |
| Fleet exception let plans go below 30% / over 12 months | Exception removed from the plan and sale rules (US-29) | Yes |
| Original Term in Months not in any story | Field and rule removed | Yes (removed) |
| Late list stayed empty | Daily job marks unpaid overdue months Late (`Instalment_Mark_Late`, scheduled flow) | Yes (active scheduled flow) |
| Plan page didn't say what to do next | **Where This Plan Stands**: Next Step + Month by Month (Apex `PlanProgress` + triggers) | Yes; **daily refresh job must be scheduled** (section 6.2) |
| Reconciliation totals typed by hand | Recorded Total adds itself up from payments; Matched/Flagged automatically; bell alert to Finance (`Reconciliation`, notification type `AutoDrive_Finance_Alert`, rule `Explained_Needs_Note`) | Yes |
| Legal escalation had no button; "New" skipped checks and the email | **Raise Legal Escalation** button on the plan, Legal Escalations list | Yes |

### Customer service and email
| Found in testing | What was built | Deploys? |
|---|---|---|
| Customer emails (reference number, status, reminders) never reached Gmail | Sent from a verified org-wide address held in a Custom Label | Flows yes; **sender address must be created and verified** (section 6.1) |
| Staff assignment emails didn't arrive | Test users had placeholder addresses | **Users' email set in the target org** (section 4) |
| A lead or sale for a model with 0 cars in stock gave no warning | Red "Out of stock - request an import" marker on the lead and the sale (Stock Alert); the wanted model is copied to the sale on conversion | Yes |
| A Closed Won / Closed Lost sale could still be edited | Closed sale lock freezes every editable field, vehicle included; only System Administrators and heads (Showroom Manager, Head of Finance, Head of CS, Management) can change it | Yes |
| Paid months not marked Paid unless paid through the screen; plans showed Defaulted | Month status follows the amount paid; Days Late stops once paid | Yes |
| Switching a discounted sale to instalments failed (Finance alert looked up a user by email) | Alert and overdue-approval reminder send straight to the Custom Label address | Yes |
| Sharing to Finance and Showroom Manager went to empty groups | Sharing rules now share by role (Head of Finance and below; Showroom Manager) | Yes; old rules removed with a destructive deploy in Group3SB only |
| Showroom Manager couldn't edit models | Sharing rule: Showroom Manager edits vehicle models | Yes |
| First Response At never stamped | Flow start condition fixed | Yes |
| Payments had no Recorded By outside the screen | Payment stamps Recorded By on save | Yes |
| Reminder, late, completion and satisfaction emails used the system sender | All customer emails send from `AD_Customer_Email_Sender` | Yes; sender must be verified (section 6) |

---

## 3. Package order

Deploy in this order. Each phase is validated first, then deployed.

| Phase | What | Folders |
|---|---|---|
| 1 | Objects, fields, record types, validation rules, labels, roles, groups, queues, notification types | `objects`, `labels`, `roles`, `groups`, `queues`, `notificationtypes`, `standardValueSets`, `customMetadata` (if any) |
| 2 | Apex classes and triggers, Lightning components | `classes`, `triggers`, `lwc`, `aura` |
| 3 | Flows, email templates, duplicate and matching rules, sharing rules | `flows`, `email`, `duplicateRules`, `matchingRules`, `sharingRules`, `workflows` |
| 4 | Layouts, record pages, apps, tabs, quick actions, paths, list views | `layouts`, `flexipages`, `applications`, `tabs`, `quickActions`, `pathAssistants` |
| 5 | Profiles, permission sets, permission set groups | `profiles`, `permissionsets`, `permissionsetgroups` |
| 6 | Website | `sites`, `networks`, `experiences`, `staticresources`, `contentassets` |
| — | **Create users** (section 4), then: | |
| 7 | Approval process, reports, dashboards, Case settings – from `deploy-build` after `prepare-target.ps1` | `approvalProcesses`, `reportTypes`, `reports`, `dashboards`, `settings` |

Phases 1–6 can usually go in one validated deploy. If it fails on a missing dependency, deploy phase by phase.

---

## 4. Before deploying: target org

| # | Step | Owner | Check |
|---|---|---|---|
| 4.1 | Confirm UAT is signed off, no open Critical/High defects | Hillary | Signed UAT PDF |
| 4.2 | Freeze changes in Group3SB; `git status` clean and pushed | Hillary | `git status` shows nothing |
| 4.3 | Back up Group3Prod metadata: `sf project generate manifest --from-org autodrive-prod --name backup-prod` then `sf project retrieve start -o autodrive-prod -x backup-prod.xml -r backup-prod` | Release lead | Folder `backup-prod` created |
| 4.4 | Setup → Deliverability → Access level **All email**; tick **Enable compliance with standard email security mechanisms** | Hillary | Both saved |

---

## 5. Deploy commands

Run from the project folder. `autodrive-prod` is already connected.

**Phases 1–6, validate only (nothing changes in the org):**
```bash
sf project deploy validate -o autodrive-prod -d force-app/main/default -l RunSpecifiedTests -t AutoAssignerTest -t DiscountRequestVehiclesTest -t LeadCreatorAccessTest -t PlanProgressTest -t SaleVehicleHandlerTest -t ClosedSaleLockTest --wait 60
```
This validates everything, including phase 7. Phase 7 will fail here until users exist. If the only errors are about the approval process, dashboards or Case settings, phases 1–6 are fine. Then deploy phases 1–6 without those folders (keep a copy, deploy, restore), or deploy folder by folder in the order of section 3.

**Create users (section 4b below), then prepare and deploy phase 7:**
```bash
powershell -File scripts/deploy/prepare-target.ps1
```
```bash
sf project deploy start -o autodrive-prod -d deploy-build/force-app/main/default/approvalProcesses -d deploy-build/force-app/main/default/reportTypes -d deploy-build/force-app/main/default/reports -d deploy-build/force-app/main/default/dashboards -d deploy-build/force-app/main/default/settings --wait 60
```

### 4b. Users in Group3Prod (between phase 6 and 7)
Create one user per role. Give each user the AutoDrive profile, the matching **role** and the matching **permission set group**, then put their username into `scripts/deploy/target-users.csv`.

| Role (developer name) | Profile | Permission set group |
|---|---|---|
| Sales_Rep | AutoDrive Sales Rep | Sales_Rep_Group |
| Showroom_Manager | AutoDrive Showroom Manager | Showroom_Manager_Group |
| Finance_Team_Member | AutoDrive Finance Team | Finance_Team_Group |
| Head_of_Finance | AutoDrive Head of Finance | Head_of_Finance_Group |
| Customer_Service_Agent | AutoDrive Customer Service Agent | Customer_Service_Agent_Group |
| Head_of_Customer_Service | AutoDrive Head of Customer Service | Head_of_Customer_Service_Group |
| Legal_Team | AutoDrive Legal Team | Legal_Team_Group |
| Management | AutoDrive Management | Management_Group |
| Front_Desk_Staff | AutoDrive Front Desk Staff | Front_Desk_Staff_Group |
| Social_Media_Handler | AutoDrive Social Media Handler | Social_Media_Handler_Group |

Users can share one email address; each username must be unique across Salesforce. Each user must click the Salesforce **email confirmation** before emails reach them.

---

## 6. After deploying: manual steps (not carried by a deploy)

### 6.1 Email
| Step | Where | Check |
|---|---|---|
| Create the org-wide address **AutoDrive Motors** and click its verification email | Setup → Organization-Wide Addresses | Status Verified |
| Set Custom Label `AD_Customer_Email_Sender` to that address | Setup → Custom Labels | Value matches |
| Set `AD_Email_Showroom_Manager`, `AD_Email_Finance`, `AD_Email_Head_Of_Finance`, `AD_Email_Legal` to the real team inboxes | Setup → Custom Labels | Each holds the right address |
| Automated Process user email | Setup → Process Automation Settings | Set |

> Order matters: create and verify the sender **before** the website goes live. Customer emails from an unverified sender are refused.

### 6.2 Jobs and automation
| Step | How | Check |
|---|---|---|
| Schedule auto-assignment (every 5 min) and the daily plan refresh | `sf apex run -o autodrive-prod -f scripts/deploy/post-deploy-setup.apex` | Log shows scheduled jobs and lists any TODOs left |
| Confirm flows are Active (record-triggered, scheduled, screen) | Setup → Flows, filter AutoDrive / AM | All AutoDrive flows Active |
| Approval process active | Setup → Approval Processes → Discount Request | Active |

### 6.3 Org settings and clean-up
| Step | Where |
|---|---|
| Path celebrations on Closed Won (AutoDrive Sale Path) | Setup → Path Settings |
| Org-wide sharing defaults match the security matrix (Leads, Opportunities, Cases private as built) | Setup → Sharing Settings |
| Delete demo list "Leads Created by Partners This Month" | Leads → that list → gear → Delete |

### 6.4 Website
| Step | Where | Check |
|---|---|---|
| Give the site's guest user its access: the new org names the guest profile with a number (e.g. `AutoDrive Motors Profile1793015025697`), so deploy `profiles/AutoDrive Motors Profile.profile-meta.xml` again under that exact name | Check with `SELECT Profile.Name FROM User WHERE Name LIKE 'AutoDrive Motors Site Guest%'` | Both website forms load and the vehicle list is filled |
| Publish the AutoDrive Motors site | Setup → Digital Experiences → Builder → Publish | Site loads in a private window |
| Guest user can submit Sales enquiry and Contact support | Site → submit both | Lead created; case created with a reference number and email |

### 6.5 Data
Load only what go-live needs, in this order (vehicle models before vehicles, accounts before contacts). Test-data scripts in `scripts/apex/` are **for UAT sandboxes only**: don't run them in the go-live org.

---

## 7. Smoke test (log in as each role, about 20 minutes)

| Role | Check |
|---|---|
| Sales Rep | Leads lists show My Leads, Website Leads, High-profile Clients; create a walk-in (goes to a rep); create a high-profile walk-in (goes to the Showroom Manager, opens read-only) |
| Showroom Manager | Items to Approve works; High-profile Clients list; Low Stock list |
| Finance Team | Plans To Set Up list; Create Instalment Plan; Record Down Payment (car Reserved) |
| Head of Finance | Sign-off stamps name and date; no edit on sales |
| CS Agent | Website "problem with my vehicle" case is assigned within 5 minutes; status email sent |
| Customer (website) | Reference-number email arrives |
| Management | Dashboard opens with figures |

Any failure here is a go/no-go item.

---

## 8. Rollback

| Trigger | Action |
|---|---|
| A flow misbehaves after go-live | Setup → Flows → deactivate that flow (instant); fix in Group3SB; redeploy the flow |
| Emails going to the wrong people | Change the Custom Label value (no deploy needed) |
| Deploy breaks something wider | Redeploy from `backup-prod` (step 4.3) for the affected components |
| Bad data load | Delete by the load's external IDs / created date, reload |

Decision-maker for rollback: release lead (Hillary), with the sponsor informed.

---

## 9. Go / no-go checklist

1. UAT signed off; known issues accepted in writing.
2. Validation deploy passed (section 5).
3. Backup of Group3Prod taken (4.3).
4. Users created with the right profile, role and permission set group; `target-users.csv` filled in.
5. Org-wide sender verified; Custom Labels set (6.1).
6. Post-deploy script run; jobs scheduled (6.2).
7. Website published and tested (6.4).
8. Smoke test passed for every role (7).
9. Rollback plan understood (8).
10. Support contact and hyper-care period agreed.
11. Go / no-go meeting held and the decision recorded.
