# AutoDrive Build Plan — staged, in dependency order

Pulled from the Jira backlog (KAN project) and the Design Pack. Each stage lists what to build and why it has to come before the next one. Work through it top to bottom — skipping ahead means re-doing work when something downstream needs a field that doesn't exist yet.

Build everything in this list **declaratively, in Setup**, except Stage 9 (the 3 code exceptions). Jira issue keys are noted so you can mark them done as you go — that keeps the record honest about what's actually built versus planned.

**Status key:** ✅ Done · 🔶 Partially done · ⬜ Not started

> **Current build queue:** Stage 16 was pulled ahead of Stage 13/14 (2026-10-13) — most direct answer to Shedrack's feedback, client-facing deliverable needed soonest. ✅ **Delivered** (2026-10-13) as `AutoDrive_Data_Model_Explained.pdf`. Stage numbers still reflect original dependency order; **next up is Stage 13.**

---

## Stage 0 — Org foundation ✅ Done
- Role hierarchy
- Company information (timezone, locale, fiscal year, currency)
- Org-wide defaults per object (table: Design Pack §3 "Starting Access")

## Stage 1 — Objects and fields (all 20 ERD v2 objects + v8 additions) ✅ Done

Standard objects first (extend, don't recreate): Lead, Account, Contact, Opportunity, Case, User.

Custom objects, in this order (parents before children that reference them):
1. Showroom
2. Vehicle Model
3. Vehicle (master-detail to Vehicle Model) — **add `Arrival Date`** (new, v8)
4. Guarantor
5. Discount Request (master-detail to Opportunity)
6. Approval Step (master-detail to Discount Request)
7. Instalment Plan (master-detail to Opportunity)
8. Instalment (master-detail to Instalment Plan) — add `Days Late` (formula), `Default Alert Sent` (checkbox)
9. Payment (master-detail to Opportunity, lookup to Instalment)
10. Reconciliation Entry
11. Import Request
12. Legal Escalation — **add** `Vehicle Purchased`, `Contract Number`, `Amount Paid`, `Outstanding Balance`, `Number of Missed Payments`, `Guarantor Information` (lookup); Status picklist needs 4 values: Open, In Progress, Settled, Closed
13. Customer Message
14. Knowledge Article

Field-level additions on existing objects:
- `Case`: Channel picklist +Walk-in/+Text, Routed To picklist +Technical, First Response At, Resolved At, CSAT Score, CSAT Requested At
- `Lead`: Qualification Answers (long text)
- `Instalment Plan`: **Ownership Documents Status** (new picklist, v8)
- `Account`: confirm Individual / Fleet-Corporate record type exists (not a new field — see Stage 2)

**Jira:** KAN-39, 42, 46, 51, 54, 61, 63, 67, 71, 73, 77, 83, 89

## Stage 2 — Record types ✅ Done
- Account: Individual / Fleet-Corporate (already in signed ERD v2 — confirm, don't rebuild)
- Vehicle: New / Used (Used stays mostly unused this phase, build the type now so it's there later)

**Jira:** KAN-67

## Stage 3 — Relationships ✅ Done (27 total: 6 master-detail + 21 lookups — see DISCOVERY_LOG.md, count grew past the original 17 with v8 additions)
6 master-detail + 17 lookups, per ERD v2. Build these as you create each object above (a relationship field is just a field) — listed here as a separate stage only as a sanity check once Stage 1 is done: open each object and confirm every `→ X Lookup/Master-detail` field from the ERD actually exists.

## Stage 4 — Validation rules ✅ Done (all rules built; the discount-invalidation Flow, KAN-92, built 2026-10-18)
- Showroom capacity ✅
- Per-model stock limit (50) ✅
- No sale to unconverted Lead ⬜ (moved to Stage 9 as a code exception — no native field to check this declaratively)
- Instalment Plan: 30% min down, 12-month cap, guarantor required — **fleet exception** (Finance-approved override) ✅ (4 rules: down payment min, term cap, renegotiation cap, guarantor income check)
- Discount on instalment deal: blocked for individuals — **fleet-only exception**, must still go through approval ✅
- **Discount invalidation on payment-mode switch (Q-O09, confirmed, 13 Oct)**: a Flow, not a validation rule — if a Discount Request is already Approved while Payment Mode = Full Payment and the customer then switches to Instalment, the approval is invalidated and Finance reassesses separately. Build after the fleet-only rule above, same story (US-25). ⬜ Not built.

**Jira:** KAN-68, 74, 79, 92

## Stage 5 — Permission sets (Security Matrix) ✅ Done (original version) — SUPERSEDED, see Stage 13
~~Build one permission set per row of the Security Matrix (Design Pack §1)~~ — originally built this way (9 broad, matrix-based Permission Sets, one per role; see DISCOVERY_LOG.md "Stage 5" entry). **Post-presentation feedback (2026-10-13): this approach is being replaced, not extended.** Rebuild plan now lives in Stage 13 below — atomic CRUD Permission Sets per object, bundled into Permission Set Groups per role. The 9 sets listed here stay in place and functional until Stage 13 actually replaces them (decided: direct replacement, not parallel-then-retire).

Original rows, kept for reference since Stage 13 must cover the same ground:
- Finance-sensitive objects (Payment, Instalment Plan, Instalment, Reconciliation Entry, Legal Escalation) → Finance + Management only
- Legal team → read-only on own Legal Escalation records
- Customer Service Agent → Opportunity/Instalment Plan amount fields hidden
- Finance → read-only Vehicle/Vehicle Model
- Discount Request/Approval Step → requester + current approver visibility
- Management → dashboard access

**Jira:** KAN-44, 47, 49, 70, 76, 85

## Stage 6 — Page layouts / Lightning record pages ✅ Done (18 layouts: all 14 custom objects rebuilt from scratch, plus a new section inserted into Account/Opportunity/Case/Lead's existing layouts)
One per object/record-type combination that needs distinct fields visible.

## Stage 7 — Users and queues ✅ Done (8 roles, 2 queues, 8 test users — one per role)
Test users per role (Showroom Manager, Sales Rep, Finance, Head of Finance, Customer Service Agent, Head of Customer Service, Legal, Management). Queues: Customer Service, Legal Escalation recipient.

## Stage 8 — Automation (Flows + Approval Processes) — build LAST ✅ Done (all 14 items + the SLA-stamp flow, built 2026-10-14)
In this order, since several depend on fields/objects above:
1. Sale-close Flow → Vehicle.Status = Sold ✅ Done (`Opportunity_Sale_Close`, Active)
2. Discount Approval Process (Showroom Manager → Finance → Head Office, SLAs 1/1/2 business days, delegate) ✅ Routing Active (native Approval Process). `Discount_Request_Stamp_Step` Flow now stamps `Step_Reached_At__c` on every step change. **Still open: the actual SLA reminder/nag mechanism (checking elapsed business days and emailing the approver) is not built** — the timestamp exists, nothing reads it yet.
3. Payment/balance update Flow ✅ `Payment_Balance_Update` — keeps `Instalment.Amount_Paid__c` and `Opportunity.Total_Paid__c` current on every new Payment
4. Reminder Flow (3 days before due, email only) ✅ `Instalment_Reminder_3_Days`, scheduled daily
5. Missed-payment notice (1 day) / guarantor notice (7 days) / default flag (30 days) ✅ `Instalment_Late_Notices`, one scheduled flow, all 3 thresholds
6. Case routing Flow (4-way: Money/Sales/Technical/Other) ✅ `Case_Routing`
7. Case escalation Flow (1 hour, no first response) ✅ `Case_Escalation_1_Hour` — built as a Record-Triggered Flow with a Scheduled Path (1 hour after creation), not a Scheduled-Triggered Flow — Scheduled-Triggered Flows only support Daily/Weekly/Once frequency, no hourly option, so that was the only way to hit a true 1-hour SLA. Covers US-33 too (same flow, confirmed shared per the build guide's own note).
8. Legal Escalation Flow (3-gate: 90 days + guarantor + Finance approval) ✅ `Legal_Escalation_Raise` — built as a Screen Flow since 2 of the 3 gates need human judgment (guarantor outcome, Finance approval), not just data checks; the 90-day gate is checked automatically before the screens show
9. Completion email Flow ✅ `Instalment_Plan_Completion_Email`
10. Low-stock alert Flow ✅ `Vehicle_Model_Low_Stock_Alert` — needed a new guard field, `Vehicle_Model__c.Low_Stock_Alert_Active__c`, built alongside it (flagged as missing back on 2026-10-13, built now)
11. Satisfaction request Flow ✅ `Case_Satisfaction_Request`
12. Walk-in rep-assignment Flow ✅ `Lead_Walkin_Assignment` — simplification: no "On Shift"/workload field exists on User (the ERD's generic User entity never got one built), so "next free rep" is currently "first active user in the Sales Rep role," not true round-robin or workload-based. Returning/high-profile walk-ins route to Showroom Manager instead, per spec.
13. Import Request status-progression Flow ✅ Split into 2 flows (a Flow can't mix before-save and after-save triggers): `Import_Request_Status_Progression` (auto-advances Requested → Customer Confirmed when the checkbox flips) and `Import_Request_Notify_Rep` (emails the requesting rep when Status → Imported). Finance-confirms and Head-Office-imports steps stay manual picklist changes by design — no separate boolean fields exist for those stages, consistent with the object's built field set.
14. Vehicle-change/refund Flow ✅ `Opportunity_Vehicle_Change_Refund` — Screen Flow, rep-initiated. Simplifications: new vehicle is looked up by typing its serial number (no lookup-style screen component built); refund gate is a simple yes/no confirmation screen to Head of Finance, not a routed approval; Sale_Price__c is set straight to the new vehicle's list price with no re-applied discount. Functionally correct for the core journey, not a full-fidelity implementation of every nuance in Obed's Q-O07 answer.

**Jira:** KAN-40, 43, 52, 55, 57, 59, 62, 64, 65, 72, 78, 80, 81, 84, 87, 90

## Stage 9 — The 6 code exceptions (only place Apex/LWC belongs) 🔶 Partially done (re-scoped 2026-10-15)
**Status after review (2026-10-15):**
- ❌ **VIN lookup — dropped.** Every vehicle is entered into the database on arrival and `Vehicle__c.Chassis_Number__c` already holds the VIN; a decoder only saves typing at data entry.
- ⏸ **Agentforce inventory agent — deferred, build later (decided 2026-10-15; nice to have, not required).** Einstein generative AI (`EinsteinGptSettings.enableEinsteinGptPlatform`) and Agentforce (`AgentPlatformSettings.enableAgentPlatform`) switched on in `autodrive-dev` on 2026-10-15 by settings deploy, verified by retrieve. Agent not built. If built, it reads the database through one action (count available `Vehicle__c` by `Vehicle_Model__c`), not a knowledge base.
- ✅ **Gmail logging — replaced with Email-to-Case (2026-10-15).** The design pack defines this as *inbound* customer email logging, so no Gmail connector. Added routing address `AutoDrive_Customer_Support` (support@autodrive.group3sb.test placeholder, unverified) → Origin Email, owner queue `Customer_Service`, in `settings/Case.settings-meta.xml`. Salesforce service address: support@v-w9rhy1futp1w2ot2xv1mp1l05cr8r6q8n4mzuvp07a045fm4.jy-2ofxuam.usa1340s.case.sandbox.salesforce.com. **Blocked for testing:** the demo-org flow `SDO_Service_Case_Creation` fails on every Case insert, so no Case can be created until it is deactivated (owner decision — not AutoDrive metadata). For production, replace the placeholder with the real support mailbox and forward it to the service address.
- ✅ **Blinking low-stock indicator — built.** LWC `lowStockIndicator` on new record page `Vehicle_Model_Record_Page` (set as the desktop default via the object's View override). Blinks red when `Available_Stock__c` < `Low_stock_Threshold__c`, the same strictly-below rule as the `Vehicle_Model_Low_Stock_Alert` flow.
- ✅ **No-sale-to-unconverted-Lead — built without code.** Flow `Lead_Conversion_Stamp_Account` ticks `Account.From_Converted_Lead__c` on conversion (works because Lead Settings "Require Validation for Converted Leads" is on); Opportunity validation rule `Closed_Won_Requires_Converted_Lead` blocks Closed Won otherwise. Field is on no layout and granted to no role, so it can't be ticked by hand. Accounts created before 2026-10-15 are not stamped — Stage 11 test data must go through Lead conversion.
- ✅ **Discount Request visibility — solved with sharing rules, not Apex.** Gap found: Finance Team and Management had Read permission on Discount Request but no record visibility (Opportunity OWD Private, roles not above Sales). Added `Opportunity.sharingRules`: Read on Opportunities owned by Showroom Manager and subordinates, to roles Finance_Team_Member and Management. Children (Discount Request, Instalment Plan) inherit it. Apex Managed Sharing only needed if access must be limited to "only while the request is at your step".

**Original list:**
- VIN lookup: Apex class + LWC on the Vehicle page
- Agentforce single-action agent: inventory count by model
- Gmail-to-record logging: connector/connected app
- Low-stock blinking visual indicator: LWC with CSS animation on the Vehicle Model record page, driven by `Available_Stock__c` vs `Low_stock_Threshold__c` (added 2026-10-13, see DISCOVERY_LOG.md). A declarative colour-coded formula field (IMAGE()) can show red/green without code, but true blinking/animation isn't available declaratively — this is a deliberate scope add, not a gap.
- No-sale-to-unconverted-Lead check: Apex (or a Flow-maintained tracking field set at Lead conversion) to confirm an Opportunity's Account/Contact actually originated from a converted Lead before allowing Closed Won. Added 2026-10-13 — Salesforce has no native back-reference from Account/Opportunity to its originating Lead, so this can't be a plain formula. See DISCOVERY_LOG.md.
- Apex Managed Sharing for Discount Request: dynamically share each Discount Request record with the right approver group as Current_Step__c changes. Added 2026-10-13 — Discount_Request__c is Master-Detail to Opportunity, which forces its OWD to Controlled By Parent; Sharing Rules are structurally impossible on a Master-Detail child object (confirmed by deploy error), so this can't be declarative. See DISCOVERY_LOG.md. Also covers the same gap on Instalment Plan/Instalment/Payment if Finance Team/Showroom Manager ever need edit-without-owning on those (also Master-Detail children) rather than just the view-only access they have today.

These are genuinely code, not declarative-avoidable — this is where `AutoDrive-SFDX/force-app` and VS Code earn their keep.

## Stage 10 — Reports & dashboard ✅ Built 2026-10-18 (one dashboard per role; per-user dynamic dashboards still a later item)
Build last — needs every object above populated with real data to be meaningful.
**Requirement noted 2026-10-15 (not yet designed — discuss before building):** each role needs its own dashboard on its Home page. The current `AutoDrive_Home` page (Items to Approve, tasks, recent records, calendar) is shared by all roles and has no dashboard; the demo-org Enablement Dashboard was removed because its report types are inaccessible to AutoDrive users. Home pages can be assigned per app + profile, so each role can get its own Home page with its own dashboard.

**Jira:** KAN-69

## Stage 11 — Test data ✅ Done (10 customer scenarios, `scripts/apex/seed_test_*.apex`, 2026-10-15)
Clean sample data per object, enough to demo and test every Flow above.

## Stage 12 — QA pass 🔶 Test plan ready 2026-10-18 (`docs/AutoDrive_Test_Plan.md`: 60 cases by role + time-based checks + defect log); not yet run
Walk every story's Normal/Alternative/Exemption paths as the right persona (never as System Administrator). Defect log in Sandra's PROJECT_LOG.md — fill it in yourself if she isn't actually participating, but keep it honest about who found what.

## Stage 13 — Permission architecture rework (post-presentation feedback, 2026-10-13) 🔶 Done except Locked Fields — 52 atomic sets + 8 Permission Set Groups built and assigned (2026-10-14); old 8 role-based sets confirmed unassigned and deleted (2026-10-14). `Mute_Finance_Amount_Fields` kept — it's the separate, still-unresolved Locked Fields attempt, not one of the 8 retired sets. **Remaining gap: Locked Fields (hiding Opportunity/Instalment amount fields from Customer Service roles) — not fixable via any deployable metadata; must be finished manually in Setup → Permission Set Groups → [Customer Service Agent Group / Head of Customer Service Group] → Muting Permission Sets → New, since Muting Permission Sets only save correctly when created through that specific UI, not via Metadata API (confirmed 2026-10-13).**
Triggered by live presentation feedback: the audience is non-technical, role-only people, and access control needs to be legible and demo-able per role, not just correct. Decided: **replace** the 9 existing matrix-based Permission Sets (not build alongside and retire later).

**Confirmed by Obed Koplang's direct feedback on this build (Meeting Transcription, 2026-10-13, 18:59–19:54):** *"Are you going to have every permission they need in that permission set? Because that's not the proper way to build permission sets. Ideally, what you should do for a permission set is that if you are giving read access to an object, then that's what that permission set will do. If you are giving create, that's what the permission set should do. If you are giving access to run a flow, that's what the permission set should do. Then you count [combine] them to a permission set group and group all those per [role] — the finance team, the finance manager, and so on."* This is exactly the atomic-CRUD-plus-group pattern already planned below — the feedback confirms direction, it doesn't change it.

**Also surfaced in the same feedback — base profile should be minimal, not Standard User.** Shedrack Jatau separately reinforced the principle of least privilege (21:13–21:46): give someone access to exactly what their job needs, nothing more. The 8 test users currently sit on the **Standard User** profile, which grants a baseline of org access beyond what any one role needs. Stage 13 should also move them to a genuinely minimal-access profile (or a profile clone with everything stripped back), so every real grant comes from the Permission Set Group, not the profile underneath it — otherwise the atomic-sets exercise is partly cosmetic.

**New structure:**
1. **Atomic CRUD Permission Sets, one per object** — each grants exactly one of Read / Create / Edit / Delete on one object (e.g. `Vehicle_Read`, `Vehicle_Edit`), nothing bundled, nothing role-specific baked in. Building block layer only.
2. **Permission Set Groups, one per role** — Sales Rep, Showroom Manager, Finance Team, Head of Finance, Customer Service Agent, Head of Customer Service, Legal Team, Management (same 8 roles as today). Each group assembles the exact CRUD sets that role needs, object by object, matching the Security Matrix's intent but expressed as an assembled group instead of one monolithic set.
3. **Reassign all 8 test users** from their old individual Permission Set to their new Permission Set Group.
4. **Retire the 9 old Permission Sets** once the groups are confirmed working — remove assignments first, then the sets themselves.

Carries forward every constraint already discovered in the original Stage 5 build (see DISCOVERY_LOG.md): `modifyAllRecords` requires `allowDelete`; Account read requires Contact read; a Master-Detail child's read requires its parent's read; true field-hiding (Locked Fields) still needs Muting Permission Sets built manually in a Permission Set Group's own UI, not deployable from outside — same gap, now more naturally placed since Stage 13 *is* Permission Set Groups already.

**Not started. Plan only — do not build until explicitly asked.**

## Stage 14 — Role-based Lightning Apps (post-presentation feedback, 2026-10-13) ✅ Built 2026-10-15
Same feedback, second half: each of the 8 roles gets its own Lightning App (Setup → App Manager), not just shared access to one app with everything in the nav bar. Each app shows only the tabs/objects that role actually touches, so a demo to a non-technical audience can open "the Showroom Manager app" and see a Showroom Manager's world, not the whole data model.

**Plan:**
1. One custom Lightning App per role (8 apps): Sales Rep, Showroom Manager, Finance Team, Head of Finance, Customer Service Agent, Head of Customer Service, Legal Team, Management.
2. Each app's nav bar: only the objects that role's Permission Set Group (Stage 13) actually grants access to — keeps the app and the access grant honest, one shouldn't show a tab the other blocks.
3. Assign each app's visibility to its matching Permission Set Group (or Profile, if the group-level app assignment proves awkward) so each test user lands in their own app by default on login.

**Built 2026-10-15, then reworked the same day to one app (Hillary's decision).** Anderline Igwe's `AutoDrive_Motors` app is the single app for every role: it holds all 22 tabs (Home, the standard objects, all 14 AutoDrive objects, Reports, Dashboards) and is the default app on all 8 `AutoDrive <Role>` profiles. Each user sees only their own tabs: custom-object tabs through the atomic `<Object>_Tab` sets in their group (and Salesforce hides any custom tab whose object they can't access), and standard tabs through their profile (DefaultOn or Hidden). The 8 per-role apps and their 8 `<Role>_App` sets were built first, then removed from the org; backups kept outside the repo. Trade-off accepted: same tab order and app name for everyone. Created the 14 custom object tabs (none existed). Link to Anderline's Experience Cloud site "AutoDrive Motors" (Customer Service template, under construction): its Contact Support / My Cases pages create Cases that go through the same `Case_Routing` flow as Email-to-Case; site left untouched.

## Stage 15 — Solution Document (post-presentation feedback, 2026-10-13) ✅ Done — v3 (2026-10-18) in `docs/AutoDrive_Solution_Document.md`, reflecting one showroom, new cars only, one app, role profiles
A plain-language solution document for a non-technical audience — what AutoDrive's Salesforce build actually does, per role, without assuming any Salesforce knowledge. Two versions delivered 2026-10-13: a first pass as a published Artifact (not grounded in the client's own words — superseded), then a second pass as a PDF, grounded directly in `TAP 3.0/AutoDrive_Requirements_UserStories_v8.xlsx` — real stakeholder quotes (Henry Idagu, Obed Koplang, Shedrack Jatau), verified story counts (11 Must/22 Should/5 Could/12 Won't Have, 38 total), confirmed business rules, and the still-open client questions. Revisit/republish once Stage 13/14 are actually built, since the current version describes the role list and data model as they stand today, not the future per-role-app state.

## Stage 16 — Data model explainer, plain language (post-presentation feedback, 2026-10-13) ✅ Done — delivered as `AutoDrive_Data_Model_Explained.pdf` (2026-10-13)
**Separate deliverable from Stage 15.** Direct feedback from Shedrack Jatau (Head of Customer Service, Meeting Transcription 2026-10-13, 29:49–38:36) on this build's first presentation: *"I'm not sure I got much clarity as to the objects that have been configured and their purposes... for me, as the client, I want to know that you have built containers where I can store my [data] — my vehicle — I will no longer live on [Excel]... then from there my work flows smoothly."* He called the data model "the foundation of the house" — everything else (automation, reporting, security) rests on it being understood first, and asked specifically for more time spent explaining *what each object is for*, not touring fields quickly.

This is distinct from Stage 15: the solution document covers workflow and role access; this one is object-by-object, in plain terms — "this is where a vehicle lives," "this is where a discount request lives and why it's a separate record from the sale itself" — enough that a non-technical client could ask a clarifying question or request a change and have it make sense to them, and so it can be logged properly against the change log per Shedrack's instruction.

**Plan:**
1. Walk all 14 custom objects + 4 standard extensions, one plain-English paragraph each: what real-world thing it represents, why it's a separate "container" rather than a field on something else, and which role actually uses it.
2. A simple visual (diagram, not a technical ERD with arrows and cardinality notation) showing how the containers connect — e.g. "a Sale has one Discount Request, which has many Approval Steps" in sentence form before/alongside any box-and-line diagram.
3. Deliver as a document the client could read without a Salesforce person in the room, same bar as Stage 15.

**Done, 2026-10-13.** Delivered as `AutoDrive_Data_Model_Explained.pdf` — all 14 custom objects + 4 standard extensions, plain-English, plus a sentence-form connection map (Part 3 of the doc) instead of a technical ERD.

## Stage 17 — Demo readiness: persona-journey walkthroughs (post-presentation feedback, 2026-10-13) ✅ Scripted 2026-10-18 in `docs/AutoDrive_Demo_Walkthroughs.md` (8 journeys, each with a live rule failure)
Obed Koplang's feedback on *how* to present, not what to build (Meeting Transcription, 2026-10-13, 08:29 and 32:12): don't tour the org object-by-object — pick one persona's real journey (a Sales Rep selling a car, a Finance Team Member recording a payment, a Showroom Manager approving a discount) and walk it start to finish, logged in as that user, not as System Administrator. When demonstrating a validation rule, trigger it live — enter a value that should be blocked and show the actual error message, rather than describing what the rule does.

**Plan:** once Stage 14's per-role apps exist, script one journey per role (reuses Stage 12's QA persona-login discipline — never demo as System Administrator) ending in at least one live validation-rule failure shown on screen. This is presentation prep, not a Salesforce build item, but it's blocked on Stage 14 existing, so it's sequenced here.

**Not started. Plan only — do not build until explicitly asked.**

---

## A note for the record

If this is substantially a solo build, say so plainly in the final handover documentation rather than implying three people built it — Engagement Lead notes, the build log, and the retro are exactly where that honesty belongs, and it protects you better than the alternative if anyone asks a direct question in review.

## Defects found while seeding test data (2026-10-15)
Sample data: `scripts/apex/seed_test_data.apex` (+ `seed_test_cases.apex` once Cases can be created). All records named "AD Test…".
1. **Fixed — no field-level security anywhere.** None of the 52 atomic sets granted field access, so every role saw only record names. Added fieldPermissions to every `<Object>_Read` (read) and `_Create/_Edit/_Full` (edit; formula/roll-up read-only) set, for all 120 AutoDrive custom fields. Admin user had none either: new set `AutoDrive_Admin_Field_Access` (also AutoDrive record types), assigned to hillary@group.admin. Side effect: Customer Service roles now see Opportunity amount fields, so the Stage 13 Locked Fields muting is now genuinely needed.
2. **Fixed — `Down_Payment_Min_30_Percent` blocked every non-fleet plan.** Compared a percent field to 30; formulas read percents as decimals. Now `< 0.3`.
3. **Fixed — `Payment_Balance_Update` failed every Payment insert.** It wrote `Opportunity.Total_Paid__c`, a roll-up summary. Step removed; the roll-up already does it.
4. **Open — Case creation blocked** by demo flow `SDO_Service_Case_Creation` (see Stage 9 Email-to-Case).
5. **Fixed — Customer Service and Legal couldn't see Instalment Plans** despite `Instalment_Plan_Read`. Added Opportunity sharing rules (Read) to Head_of_Customer_Service and subordinates, and Legal_Team; verified all three test users can now read the plan.
6. **Open — role permission sets grant no record types,** so non-admin users can't pick Vehicle New/Used or Account Individual/Fleet.
7. **Minor — `Discount_Request_Stamp_Step` doesn't stamp the first step on create** (only on change). CreatedDate covers it, but the SLA clock reads blank for step 1.

Verified working: Lead conversion stamp + Closed Won block (and sale close marks the vehicle Sold), low-stock blink (CR-V 2 < 5), payment roll-up/instalment paid, Finance & Management see Discount Requests.

## Stage 13 follow-up — minimal profiles (2026-10-15) ✅ Done
8 custom profiles `AutoDrive <Role>` (Salesforce licence), built empty rather than cloned: only Lightning Experience, single email, tasks/events, Run Reports (roles whose app has Reports), Convert Leads (Sales Rep, Showroom Manager), page layouts, standard tabs in that role's app, and record types (Account Individual/Fleet/Business, Vehicle New/Used — Sales Rep and Showroom Manager only, which also fixes defect 6 for the roles that create those records). Each sets its role's app as the default, with Anderline's `AutoDrive_Motors` app visible as a second app. All 8 test users moved off Standard User onto their profile; group assignments and record access re-verified unchanged.

## Dashboard decisions (2026-10-15) — feeds Stage 10, not yet built
- One shared dashboard per role (8), placed on that role's Home page.
- Everyone sees only their own records.
- Metrics: no client KPIs exist; use the proposed set (e.g. Sales Rep: own sales this month, open sales; Finance: overdue instalments, payments this week; Management: total sales, stock levels) and confirm with the client.
- **Later, after the build is complete (out of current scope):** per-user dynamic dashboards so each user in a role sees only their own figures on the shared dashboard (e.g. one agent doesn't see another agent's numbers).

## Sample data batch 2 (2026-10-15)
`scripts/apex/seed_test_data_more.apex` brings the set to 10 customer scenarios: Adaeze (full payment, open), Chinedu (instalment, late, legal), Kano (fleet, discount pending), Tunde (unconverted lead), Direct walk-in (no Lead, can't close), Bola (discount approved, closed won), Emeka (plan fully paid, completion email sent), Funke (payment due in 3 days, settled legal case), Lagos Ride Hailing (fleet 20% down with sign-off, discount rejected, import confirmed), Ibrahim (lost sale, technical case closed with CSAT), plus Grace (open web lead). Totals: 3 showrooms, 5 models, 20 vehicles, 10 leads, 9 sales, 3 discount requests, 4 instalment plans, 11 instalments, 10 payments, 4 reconciliation entries, 3 import requests, 8 cases, 6 customer messages, 5 knowledge articles, 2 legal escalations. All automation fired without errors.

## Decision: one showroom only (2026-10-15)
From now on AutoDrive is built for a single showroom. Changes made:
- **Showroom object kept** (capacity and vehicle count still matter); description updated.
- **New flow `Vehicle_Default_Showroom`** (before save): a vehicle saved without a showroom is placed in the showroom automatically.
- **New flow `Vehicle_Update_Showroom_Count`** (after save): keeps `Showroom__c.Vehicle_Count__c` = vehicles in the showroom that aren't Sold. **Bug fixed:** that field was never filled, so `Showroom_Capacity_Not_Exceeded` could never fire. Verified: count 18 of 25, filling to 25 works, the 26th vehicle is blocked. Deleting a vehicle doesn't recount until the next vehicle save.
- **Capacity error message** reworded (no more "choose a different Showroom").
- **Data:** all 20 vehicles moved to "AD Test - Lagos Main" (capacity 25); Abuja and Port Harcourt deleted. Seed scripts updated to create one showroom.
- Unchanged and still correct for one showroom: the Showroom Manager role and group, `Case_Routing` "Showroom Manager", `Lead_Walkin_Assignment`, low-stock alert, sharing rules.

## Decision: new vehicles only (2026-10-15)
AutoDrive sells **new** vehicles only for now; used-car sales are a future option. The `Used` record type on Vehicle is **kept but switched off** (inactive, with a description saying how to turn it on). With only `New` available, nobody is asked to choose a type. Showroom Manager (the only role that creates vehicles) sees `New` only; the one sample used Corolla was moved to New and the seed script now creates New only.
**Client wording:** "Used cars are built into the system and switched off. When AutoDrive starts selling used cars, an admin turns them on in a few clicks; no rebuild needed."

Also: Sales Rep profile no longer has vehicle record types. Reps can only view vehicles, so it was unnecessary (found because access wasn't checked against the Security Matrix).

## To do after the build: full Security Matrix check
Hillary asked for every access decision to be checked against the Security Matrix. That wasn't done for the profile record-type settings (above). Before sign-off, walk every role × object × action (and record types, tabs, field access) against the matrix and log any differences.

## Built 2026-10-18
- **KAN-100** `Instalment_Plan__c.Ownership_Documents_Status_Changed__c` + flow `Instalment_Plan_Stamp_Documents_Status`.
- **KAN-64** `Case_Stamp_Resolved_At` (first close), `Customer_Message_First_Response` (first non-acknowledgement, non-automatic message), `Email_Message_First_Response` (first outgoing email). Escalation now only fires when nobody replied.
- **Fix:** `Case_Satisfaction_Request` failed to close any case without an Account/contact email; now skips the email instead.
- **KAN-92** flow `Opportunity_Discount_Invalidation`: Full Payment → Instalment marks Approved discounts **Invalidated** (new step value; exempt from the instalment discount rule) and emails Finance. Verified through a real 3-step approval (record locked) as admin; **still to confirm as a Sales Rep** in the login walkthrough.
- **KAN-43** step 1 now stamped on create; fields `SLA_Business_Days__c`, `SLA_Limit_Days__c`, `SLA_Reminder_Sent_Step__c`; scheduled flow `Discount_Request_SLA_Reminder` daily 07:00 UTC emails the step's approver once per step when over 1/1/2 business days (only for requests actually in approval). Public holidays not excluded.
- **KAN-69/70 (Stage 10)** 8 custom report types, 14 reports (folder *AutoDrive Reports*), 8 dashboards each in its own folder shared only with that role, 8 role Home pages (`AutoDrive_Home_<Role>`) assigned per profile in the AutoDrive Motors app. Enterprise Edition allows only 5 dynamic dashboards, so each dashboard runs as its role's test user; per-user figures stay a later item. Currency shows USD (org default). Satisfaction tile stays at 0 until customers' scores are recorded.

## Decisions 2026-10-18
- **KAN-44 (discount visibility): keep as built.** Requester (Sales Rep), Showroom Manager, Finance Team and Head of Finance (the whole approval chain) see discount requests; Management keeps read-only oversight; Customer Service and Legal see none.
- **KAN-85 (legal escalation access): Finance Team stays view-only.** Only the Head of Finance creates and updates escalations; Finance Team and Management view; Legal views escalations routed to its queue. Sharing rule `Finance_Team_Full_Access` relabelled "Finance Team Read Access" and set to Read so it matches (it never granted edit in practice, since the Finance Team's permission set is read-only).

## From Sales Rep testing, 2026-10-18
- Dashboards: all 8 load with no errors (sales tiles now count deals; multi-currency broke money tiles). Sales Rep dashboard = Leads by Status, Leads by Channel, Deals in Pipeline by Stage, Deals Won This Month.
- Opportunity page: removed Partners, Competitors and Products related lists (unused demo lists; one threw a raw query error).
- `Closed_Deal_Locked`: a Closed Won/Lost sale's stage, close date, amount, customer, payment mode and name can't change, for anyone. Vehicle and sale price left to the KAN-17 vehicle change/refund flow.
- `Opportunity_Stamp_Close_Date`: close date set to the day the sale actually closes (no back-dating).
- `Opportunity.Pending_Discount_Requests__c` (roll-up) + `Stage_Frozen_While_Discount_Pending`: stage can't move while a discount is waiting for approval.
- `Discount_Request_Defaults` (Requested By, step) + `Discount_Request_Auto_Submit` (creating a request submits it); step, requested-at and requested-by are read-only on the page.
- `Opportunity.Vehicle__c` lookup filter: only vehicles not Sold / Not for sale, except on Closed Won sales (otherwise closed sales, and payments on them, couldn't save).
- Vehicle Model page: Vehicles related list; "All Vehicle Models" back button on the Stock Level panel.
- Lead (US-23/US-30): `Visit_Purpose__c` (Enquiry/Purchase), `Vehicle_Model_Of_Interest__c` (required for Purchase), phone or email required, Customer Type required; AutoDrive Lead Details section moved up; `Lead_Individual_Company_Name` puts an individual's own name in Company.
- Test data: model "AD Test - Toyota Land Cruiser" with no vehicles (out-of-stock test); "AD Test Sale - Bola Adeyemi (2nd car)" with a discount approved through the real approval chain (TC-S9).

## From Sales Rep testing, round 2 (2026-10-18)
- **Lead statuses** (record type `AutoDrive_Lead`, process *AutoDrive Lead Process*): New → Contacted → Qualified → Converted, or Unqualified. Phone or email required from creation; Qualified (and conversion) requires Visit Purpose and Vehicle of Interest. Demo-org statuses no longer offered to AutoDrive users.
- **Sale stages** (record type `AutoDrive_Sale`, process *AutoDrive Sales Process*): Viewing / Test Drive → Offer → Payment Arranged → Closed Won / Closed Lost. All 8 profiles default to both record types; sample records migrated (open sales now at Offer).
- **Duplicate detection:** matching rules `AD_Lead_Email_or_Phone`, `AD_Contact_Email_or_Phone` and duplicate rule `AD_Lead_Existing_Customer` warn when a new lead's email or phone already belongs to a lead or customer (US-30). Save still allowed.
- **Closed deals list views:** AutoDrive - Open Deals / Closed Won / Closed Lost.
- **Discount at a glance:** `Approved_By__c`, `Approved_On__c` stamped on final approval; shown in the sale's Discount Requests list with Requested %, Step.
- **Company:** typed company kept as entered (overwrite flow `Lead_Individual_Company_Name` switched off and removed from the project; it could not be deleted from the org).
- **Sales Rep tabs** removed: Showrooms, Guarantors, Cases, Customer Messages, Knowledge. Access kept, because the Security Matrix grants Sales Rep Read on these and Create/Read on Guarantor (own deal); decision pending.

## Discounts, instalment tracking, Sales Rep access (2026-10-18)
- **Discount Rate** picklist (1, 2, 3, 4, 5, 7.5, 10, 12.5, 15%) fills Requested Discount. **5% or less is approved automatically** (`Auto_Approved__c`, no approval chain); above 5% goes Showroom Manager → Finance → Head Office (G4/G5). Fleet sale with no rate picked uses the account's Agreed Discount Rate. A rate is required (`Discount_Rate_Required`).
- **Instalment sale close:** `Instalment_Close_Needs_Plan_And_Deposit` blocks Closed Won until the Head of Finance has signed off a plan (`Opportunity.Signed_Off_Plans__c`) and Finance has recorded a down payment (`Opportunity.Down_Payment_Received__c`). The rep's side ends at Closed Won; Finance tracks the plan from there (US-03/05/15/17/29).
- **Plan Status** on Instalment Plan (Active, Late, Defaulted, With Legal, Completed), kept current by `Instalment_Plan_Recalculate_Status` (called from instalment and legal-escalation changes). List views: Plans Needing Attention, Active Plans, Completed Plans. "Instalment Plans by Status" tile on Finance and Head of Finance dashboards.
- **Sales Rep access** now follows the user stories, not the Security Matrix: Showroom, Guarantor, Case, Customer Message and Knowledge access removed (no Sales Rep story uses them; guarantors belong to the Head of Finance's US-29). **Security Matrix to be updated to match.**
- Generators kept in `scripts/build/` (dashboards, plan-status flows).

## 2026-10-18 (later)
- **5% threshold applies to the whole deal** (Hillary): a fleet order is one deal, not per vehicle. **Gap:** a sale (Opportunity) holds one vehicle (`Vehicle__c`), so a multi-vehicle fleet order is currently one sale per vehicle, each with its own discount. Needs a decision: a deal with several vehicles (e.g. vehicles linked to the sale), or one sale per vehicle with a shared fleet discount.
- **Security Matrix rebuilt from the v8 user stories** in `TAP 3.0/AutoDrive_Design_Pack_Reconstructed.md` §1 (every cell cites its story; old matrix kept collapsed). Differences from the build listed there; not yet applied: Showroom Manager and Finance need Case edit (US-06 routing), Finance needs Import Request edit (US-38), several no-story reads to remove, Sales Rep sees locked Opportunity price fields (§2). Front Desk / Social Media roles (US-30/31) not modelled.
- **Bug fixed:** lead conversion created the sale at *Closed Won* (new stages were appended after Closed Won; conversion takes the first stage). Stage list reordered; Viewing / Test Drive is first and the default; the stage path now shows in the right order.
- `scripts/apex/fresh_sales_test_records.apex`: makes a fresh, stamped set of Sales Rep test records for each test run (closed sales can't be reset). Test plan §2 rewritten around it.

## EDITED 2026-10-18: build brought in line with the user-story Security Matrix
Source: `TAP 3.0/AutoDrive_Design_Pack_Reconstructed.md` §1, rebuilt from the v8 user stories. Changes made to the build:
| Change | Role(s) | Story |
|---|---|---|
| **Edited:** Case access Read → Read + Edit; Case sharing rule `Cases_Routed_To_Showroom` (Edit) | Showroom Manager | US-06 |
| **Added:** Case Read + Edit, Case tab; Case sharing rule `Cases_Routed_To_Finance` (Edit; Head of Finance via hierarchy) | Finance Team | US-06 |
| **Edited:** Import Request Read → Read + Edit (Finance confirms the import) | Finance Team | US-38 |
| **Added:** Front Desk Staff and Social Media Handler roles, profiles (Leads only) and groups (`Lead_Create` / `Lead_Edit` + Vehicle Model read). Test users not yet created | new | US-30, US-31 |
| **Edited:** price fields locked. New atomic sets `Opportunity_Prices_Read/Edit` and `Instalment_Plan_Amounts_Read/Edit`; price and amount fields removed from the general Opportunity and Instalment Plan sets; standard Amount hidden on Sales Rep, Customer Service and Legal profiles. **Also resolves KAN-49** without a Muting Permission Set | Sales Rep, CS Agent, Head of CS, Legal lose prices; Finance, Head of Finance, Showroom Manager edit; Management reads | Q-O13, NFR-01 |
| **Edited:** `Opportunity_Vehicle_Change_Refund` runs in system mode (with sharing) so a rep can complete a vehicle change now that prices are hidden; refunds still need Head of Finance approval | Sales Rep | US-39 |
| **Removed:** Guarantor, Knowledge, Customer Message read (and tabs) | Showroom Manager | no story |
| **Removed:** Lead, Case, Customer Message, Knowledge read; Case tab | Head of Finance | no story |
| **Removed:** Lead read | Finance Team | no story |
| **Removed:** Showroom read and tab | CS Agent, Head of CS | no story |
| **Removed:** Approval Step create | Sales Rep | no story |
Verified per test user (field and object access) and on live cases (Finance can edit a payment case; Showroom Manager can edit a sales case).

## EDITED 2026-10-18: fleet sales can hold several vehicles
- New object **Sale Vehicle** (`Sale_Vehicle__c`, child of the sale): vehicle (only vehicles still for sale) and its sale price. **Fleet sales only** (`Fleet_Sales_Only`); locked once the sale closes (`Closed_Sale_Vehicles_Locked`).
- Sale shows **Fleet Vehicles** (count) and **Fleet Vehicles Total**; "Fleet Vehicles" related list on the sale page.
- `Opportunity_Fleet_Sale_Close`: closing a fleet sale Won marks every vehicle on it Sold.
- One discount request per sale, so the 5% threshold applies to the whole fleet deal (Hillary, 2026-10-18). Individual sales keep the single AM Vehicle field.
- Access: Sales Rep and Showroom Manager create/edit; Finance, Head of Finance, Management, Customer Service read. Tested: 2 Hiluxes on Lagos Ride Hailing (total 88,000,000), individual sale blocked, closing marks both Sold, adding after close blocked.

### EDITED 2026-10-18: user-story gap check (v8)
Every v8 refined story was checked rule by rule against the build. Gaps closed:
- **US-22**: validation rule `Case.CSAT_Score_1_To_10`. A score must be a whole number 1–10; blank = unrated. Tested: 15, 0, 7.5 blocked; 8 saves.
- **US-26**: `Vehicle_Model__c.No_List_Price__c` flag + list view "AutoDrive - Models With No List Price".
- **US-31**: Lead list view "AutoDrive - Enquiries No Visit Booked" (Instagram, not converted, no booked visit date). A lead leaves the list once a visit date is entered.
- **US-32 / KAN-97**: Lead list views "AutoDrive - Open Prospects" (source, rep, status) and "AutoDrive - Prospects With No Rep" (new formula `Lead.No_Rep_Assigned__c`: owner is a queue). Stage changes are recorded by Lead field history.
- **Fleet (US-16/US-20)**: multi-vehicle fleet orders kept and moved out of Won't Have in the v8 workbook (Change Log row added).
- **NOT BUILT — US-15/US-19 text reminders**: reminders are email only. No SMS provider this phase (team decision). Logged in the workbook Change Log.
- **Still open — US-11**: case owner at creation + availability. To be built with Omni-Channel alongside the Experience Cloud site fixes.

### EDITED 2026-10-19: website (Experience Cloud), Omni-Channel, customer messages
- **Case Type values** were Technical Issue / Product Support / Account Support / General, so Case_Routing (Payment / Sales / Technical) never matched a hand-picked type. Added Payment, Sales, Technical; the four SDO values are inactive (not deleted).
- **Omni-Channel (US-11)**: queues AD Finance Cases (Finance role), AD Showroom Cases (Showroom Manager role), Customer Service (CS Agent + Head of CS roles), AD Website Leads (Sales Rep role); routing configs AD Case Routing / AD Lead Routing (least active, capacity 1 each); presence status "Available" (Cases + Leads channels); presence config AD Presence (capacity 3) for Sales Rep, Finance, Showroom Manager, CS Agent, Head of CS; permission set AD Omni-Channel Access (status access) in those five groups.
- **Case_Routing** now also gives the case to its department queue (Payment→AD Finance Cases, Sales→AD Showroom Cases, Technical and unclassified→Customer Service for manual review). Tested.
- **Case_Customer_Updates (US-34, US-35)** — gap found in this round: no acknowledgement/status/resolution messages existed. New flow emails the customer on case creation (with case number), on each status change and on close; owner changes send nothing; each message logged as a Customer Message (Sent By = Automatic, not counted as first response). Tested.
- **Website forms**: Anderline's two HTML forms posted to placeholder URLs (and site HTML blocks cannot submit forms); the Contact Support page used quick actions that do not exist. Replaced with screen flows running in system mode: **Website_Sales_Enquiry** (first/last name, email or phone, buying for myself/company + company name, vehicle model, enquiry/ready to buy, preferred visit date, city, state, how did you hear about us, message → AutoDrive Lead, Channel Web, LeadSource Website, owner AD Website Leads queue) and **Website_Contact_Support** (name, email, phone, topic Payment/Sales/Technical, subject, details → Case, Origin Web, linked to an existing contact by email, reference number shown). Guest profile gets access to these two flows only; no object access.
- **Home page redesign**: removed Ask a Question, discussion tabs and trending topics/articles; added "how buying works", payment options, fleet and import sections, the two forms and a footer; new CSS.

### EDITED 2026-10-19: site look, photos, UAT tests, Jira
- Site: dark theme (near-black, amber accent), header without search, hero photo (`AD_Hero_Road`, number plate blurred), CSS scroll reveal and hover motion, rounded form fields and pill buttons. The coupe photo panel was added and then removed at Hillary's request. Scroll reveal fix: the content area had overflow:hidden, which froze the scroll timelines.
- Website flows set to "restrict to enabled profiles" so the guest profile's flow access applies (forms were blank for visitors).
- New `docs/AutoDrive_User_Story_Tests.md`: 50 plain-language UAT tests, one or more per v8 story, separate from the QA test plan.
- Jira: built stories, epics, KAN-49 and KAN-97 marked Done; KAN-101–104 created for Omni/website/customer emails/fleet vehicles (KAN-103 still to move to Done). [Test] subtasks left open for testers.

### EDITED 2026-10-19: automatic website lead assignment (replaces Omni for leads)
- Apex `LeadAutoAssigner` (+ trigger `LeadAutoAssign`, test class, 3/3 pass, 87% coverage): a lead in the AD Website Leads queue goes to an **online** Sales Rep (active login session) with **fewer than 5 open leads**; fewest open leads first, ties by longest since last given (round robin); the rep gets the standard "lead assigned" email. Nobody available → lead waits; retry every 15 minutes (4 scheduled jobs "AD Lead Auto Assign :00/:15/:30/:45", run as Hillary).
- New field `Lead.Auto_Assigned_At__c` (read-only for Lead roles). Omni routing removed from the AD Website Leads queue; Omni stays for Cases. The Sales Rep presence config (capacity 5, auto-accept) from earlier no longer affects leads.
- Out of the story scope (team decision to add it anyway).
- Permission sets deleted as unused: Mute_Finance_Amount_Fields, Approval_Step_Create. Guarantor_Create kept (not used by any group; Finance and Head of Finance create guarantors through Guarantor_Edit / Guarantor_Full for US-29).

### EDITED 2026-10-19: UAT round 1 fixes (Sales Rep)
- Lead: Phone, Email, Mobile, Description, Lead Source, Title had no field access for Lead roles (UAT-04 could not save). Added to Lead_Read (read) and Lead_Edit/Lead_Create (edit). "Assign using active assignment rule" checkbox hidden on the lead layout.
- Lead statuses simplified (Hillary): exactly New -> Contacted -> Converted. At conversion the rep creates a sale, or ticks "Don't create an opportunity" so an enquiry stays as a customer record for future reference. Qualified/Unqualified removed from the AutoDrive Lead Process; the short-lived "Closed - Not Converted" value was removed from the org (no story asks for it); 2 open leads moved to Contacted. Purpose + vehicle are now required at conversion (Visit_Purpose_And_Interest_Required). Open Prospects list = every unconverted lead; LeadAutoAssigner counts unconverted leads.
- Opportunities: the standard "All Opportunities" list now shows open sales only and is labelled "All Open Opportunities"; closed sales stay in AutoDrive - Closed Won / Closed Lost.
- Vehicle lookup shows Model, Colour, Year and Status next to each car when picking one on a sale.
- Omni: a presence status given through a permission set group did not reach users (only "Offline" showed). Omni_Channel_Access now assigned directly to the CS Agent, Head of CS, Finance and Showroom test users; removed from the Sales Rep group (Sales Reps get website leads automatically, no Omni).

### EDITED 2026-10-20: Sales Reps use Omni status for website leads; no-lead close rule dropped
- LeadAutoAssigner now treats a Sales Rep as online when their **Omni-Channel status is Available** (was: any active login session). Offline reps get no website leads. Still max 5 open leads each, round robin. Retry now every **5 minutes** (12 scheduled jobs "AD Lead Auto Assign :00 … :55"). Tests 3/3 pass.
- "Available" status access given to the **AutoDrive Sales Rep profile** (applies to every Sales Rep, present and future). Access through permission set groups does not reach Omni, so status access is on the profile / direct assignment.
- Lead path is exactly New -> Contacted -> Converted (see 19 Oct entry).
- Validation rule **Closed_Won_Requires_Converted_Lead deactivated** (Hillary): no story requires every sale to start as a lead; enquiries are converted without an opportunity instead.
- (20 Oct) Lead **path guidance** (`AutoDrive_Lead_Path`): New shows Phone, Email, Channel, Customer Type; Contacted shows Visit Purpose, Vehicle of Interest, Booked Visit Date, Qualification Answers, with a note to fill them before Convert (the standard convert window cannot show lead fields). Conversion rule changed: Visit Purpose always required; Vehicle of Interest only when a sale (opportunity) is created. Tested: enquiry converted without a sale and without a vehicle; sale without a vehicle blocked.
- (20 Oct) Omni for Sales Reps showed only "Offline". Access and presence config were correct; the status "Available" (AD_Available) covers the Cases and Leads channels, and Sales Reps have no Case access (per the stories), so Omni hid it. New status **AD_Leads_Available** (label "Available", Leads channel only) for the Sales Rep profile, replacing AD_Available there; new **AD_Away** ("Away", no channels) for Sales Reps and the case teams. LeadAutoAssigner accepts either Available status. Fallback if this does not work: online = logged in (active session).
- (20 Oct) Contacts and Accounts had no field access to Email/Phone (the email and call buttons on contact lists were dead). Added Contact Email, Phone, Mobile, Title, Mailing Address, Description and Account Phone, Billing Address, Description: edit for Contact_Edit/Account_Edit (Sales Rep, Showroom Manager), read for Contact_Read/Account_Read (other roles). New list view "AutoDrive - Contacts" with clickable phone and email.

### EDITED 2026-10-20: online = logged in, for leads and cases (Omni removed)
- Omni would not offer an "Available" status with the Leads channel to Sales Reps (only Away/Offline showed), even with correct access. Per Hillary: **online = logged in, offline = logged out**, for everyone.
- New Apex **AutoAssigner** (replaces LeadAutoAssigner, deleted) + triggers **LeadAutoAssign** and **CaseAutoAssign** + **AutoAssignerTest** (4/4 pass, 91%). Teams: AD Website Leads -> Sales Reps; AD Finance Cases -> Finance Team; AD Showroom Cases -> Showroom Manager; Customer Service -> CS Agents. Each person max 5 open items, fewest first, round robin on ties; waiting work retried every 5 minutes (12 jobs "AD Auto Assign :00 … :55"). Assignee gets the standard "assigned to you" email.
- Online check: an active UI session, or (because "Login As" sessions are recorded under the admin) a "Logged in using Login-As access for <Name>" audit entry in the last 2 hours not followed by a log-out.
- New field Case.Auto_Assigned_At__c (read-only). Omni widget removed from the AutoDrive Motors utility bar; Omni routing configs removed from the case queues. Omni statuses/presence configs left in place but unused.

### EDITED 2026-10-20: admin home, sale path, vehicle price on the sale
- Admin profile opens the AutoDrive Motors app on the Management home page (profileActionOverrides, profile Admin).
- Opportunity **path guidance** (`AutoDrive_Sale_Path`): Viewing / Test Drive (Vehicle, Payment Mode), Offer (Vehicle, List Price, Discount, Sale Price, Payment Mode), Payment Arranged (Payment Mode, Down Payment Received). Price fields show only to roles allowed by the matrix (Showroom Manager, Finance, Head of Finance, Management).
- Flow **Opportunity_Fill_List_Price** (before save): when a vehicle is picked, List Price is copied from the vehicle's model and Sale Price starts at the list price (reset if the vehicle changes).
- Confetti on Closed Won: needs Setup → Path Settings → the AutoDrive Sale Path → Enable Celebrations (not available as deployable metadata).
- (20 Oct) **Instalment terms on the sale** (US-29): new Opportunity fields Instalment Duration (Months), Down Payment Agreed, Amount on Instalment (formula: sale price - down payment), Monthly Instalment (formula: amount / months). Rule Instalment_Terms_Required: an instalment sale moving to Payment Arranged / Closed Won needs 1-12 months and a down payment of at least 30% of the sale price (fleet may go lower); only checked when the stage, payment mode or terms change, so older records are not blocked. Quick action **Create Instalment Plan** on the sale (Finance) pre-fills the plan with the agreed months, down payment and %, asking only for the guarantor. Duration visible to every sale role; money fields follow the price sets (Showroom Manager, Finance, Head of Finance, Management). Sale path shows these at Payment Arranged. Tested: 32,000,000 sale, 30% down, 12 months -> 22,400,000 on instalment, 1,866,666.67 a month; missing terms blocked.
- (20 Oct) **Sales Rep sees prices, read-only** (Hillary: "you cannot make an offer without a price tag"). New permission set **Opportunity_Prices_View** (Sales Rep group): List Price, Sale Price, Discount Amount, Discount %, Fleet Rate, Fleet Vehicles Total, Down Payment Agreed, Amount on Instalment, Monthly Instalment, all read-only. Payment data (Total Paid, Balance, Down Payment Received) stays Finance-only (NFR-01). Instalment duration and discounts are set by the Showroom Manager (duration now editable only through the price edit set). New formulas on the sale: Model, Customer Type (Individual / Fleet/Corporate), Discount %. Sale path: Viewing / Test Drive = Vehicle, Model, Account, Customer Type, Sale Price; Offer = Payment Mode, Duration, Discount, Discount %, Monthly Instalment; Payment Arranged = Payment Mode, Duration, Down Payment Agreed, Monthly, Down Payment Received (5 key fields per stage is Salesforce's limit; Contact cannot be a path key field, so Account is used). Security Matrix updated.
- (20 Oct) **Paths per stage** (Hillary's outline, checked against the stories; 5 key fields per stage max):
  - Lead: New = Phone, Email, Channel, Lead Source, Customer Type; Contacted = Visit Purpose, Booked Visit Date, Vehicle of Interest, Qualification Answers, Returning/High-profile; Converted = Visit Purpose, Vehicle of Interest, Customer Type, Phone, Email.
  - Sale: Viewing / Test Drive = Vehicle, Model, Viewing / Test Drive Date (new), Account, Customer Type; Offer = List Price, Sale Price, Payment Mode, Instalment Duration, Expected Pickup Date (new); Payment Arranged = Discount %, Pending Discount Requests, Fleet Rate, Down Payment Agreed, Monthly Instalment.
  - New date fields are for information only: test-drive recording (UC-04) and handover (UC-06) are Won't Have.
- (20 Oct) Clean-up after dropping the converted-lead close rule: deleted the 4 "AD Rerun … Sale 3 (no Lead)" sales and their "No Lead" accounts (Recycle Bin); the fresh-records script now makes Sale 3 a third open sale for the converted customer, and its lead uses Contacted; QA test TC-S13 (no-lead close) removed; TC-S8a/b and UAT docs updated to the New/Contacted/Converted path.
- (20 Oct) **Sale page uses Dynamic Forms** (AutoDrive_Opportunity_Record_Page): the record detail panel is replaced by sections whose fields appear as the sale advances.
  - Sale Details (top), always: Name, Account, Customer Type, Vehicle, Model, Viewing Date, Stage, Close Date, Owner. From Offer: Payment Mode, Expected Pickup Date, List Price, Sale Price; Instalment only: Duration, Down Payment Agreed, Amount on Instalment, Monthly Instalment. Fleet only: Fleet Vehicles and total.
  - Discount: Pending Discount Requests from Offer; Discount Amount and % from Payment Arranged; Fleet Rate (fleet) from Payment Arranged.
  - Payment (from Payment Arranged): Down Payment Received, Total Paid, Balance, Signed-off Plans (instalment).
  - System Information (bottom): Created By, Last Modified By. Field access still decides who sees money fields.
- (20 Oct) **Sale Price only when there is a discount** (Hillary): at Offer the page and path show the List Price; Sale Price, Discount Amount and Discount % appear only when a discount is approved or waiting (Discount Amount > 0 or Pending Discount Requests > 0). Offer path key fields: List Price, Customer Type, Payment Mode, Duration, Expected Pickup Date.
- New flow **Discount_Request_Apply_To_Sale**: when a discount request is Approved (including 5% or less, approved at once), the open sale gets Discount Amount = list price x rate and Sale Price = list price - discount; when Invalidated, back to the list price. Tested: 32,000,000 list, 5% -> discount 1,600,000, sale 30,400,000; invalidated -> 32,000,000. (Flow formulas read percent fields as whole numbers, so the rate is divided by 100.)
- (20 Oct) Sales Rep can **edit Instalment Duration** (1-12, checked against US-29: the story sets the limits, not who picks the months). Amount on Instalment and Monthly Instalment use the minimum 30% deposit until the Showroom Manager enters the agreed down payment. Tested: 32,000,000, 10 months, no deposit yet -> 22,400,000 on instalment, 2,240,000 a month.
- New flow **Opportunity_Instalment_Notify_Finance**: when an instalment sale moves to Payment Arranged, every active Finance Team user is emailed the sale, customer, price, months, deposit and monthly amount with a link, to create the plan (Create Instalment Plan) for Head of Finance sign-off. Delivery not yet confirmed: test users have placeholder emails.
- Rule saved: the v8 user stories are the source of truth; every change is checked against them first.
- (20 Oct) **Down payment defaults to 30%** (flow Opportunity_Default_Down_Payment, US-29 minimum): fills in when Instalment is chosen and the deposit is empty, or tops up to 30% if the sale price changes; the Showroom Manager can raise it. Before-save order: fill list price (10) then down payment (20).
- **Finance hand-over shown to the rep**: the notify flow stamps new field Finance Notified At; the sale page shows it in the Payment section (instalment, from Payment Arranged) and the Payment Arranged path guidance says Finance has been notified and will set up the plan. Tested: 32,000,000, 6 months -> deposit 9,600,000, monthly 3,733,333.33; Payment Arranged -> Finance Notified At stamped.
- (20 Oct) **Finance Status on instalment sales** (formula, Payment Arranged only): 🟠 "With Finance: payment plan being set up" / "deposit received, waiting for plan sign-off" / "plan signed off, waiting for the deposit"; 🟢 "Ready to close: plan signed off and deposit received". Shown at the top of the sale page, as the first Payment Arranged path key field, and as a column in AutoDrive - Open Deals. Sales stay under Opportunities (Hillary). New flow **Opportunity_Instalment_Ready_To_Close**: when it turns green the owner gets a High-priority to-do due today, "Ready to close: <sale>". Tested end to end (orange -> orange -> green, task created).
- (20 Oct) Finance Status column added to "All Open Opportunities" (with Payment Mode). Test data cleaned for the end-to-end run: deleted the sales "AD Rerun 1018-0943 Sale 2", "AD Test Sale - Chinedu Eze" and the leftover no-lead customer "AD Test Direct Walk-in (no Lead)"; test customers, contacts and open sales renamed to real names (e.g. Daniel Okoro, Amaka Nnamdi, Kano Logistics Ltd); the 2 open leads are now Tobi Adebayo and Ngozi Okeke. Closed sales keep their old names (locked).
- (20 Oct) Fleet sales: the **Fleet Vehicles** list now sits on the main sale page under Sale Details, shown only when Customer Type = Fleet/Corporate, with its New button. New flow **Sale_Vehicle_Fill_Price**: an added vehicle gets its model's list price; Sales Rep can read (not edit) fleet vehicle prices. Instalment Duration taken off the Offer path key fields (replaced by Vehicle) because path fields cannot be conditional; the page still shows it only for instalments. New flow **Opportunity_Clear_Instalment_Terms**: months and deposit are cleared when the payment mode is not Instalment.
- (20 Oct) **Request Discount** button on the sale (quick action creating a Discount Request: rate picklist + reason). Discount fields on the sale stay read-only by design (US-02: every discount goes through the approval chain; the approved request sets Discount Amount, Discount % and Sale Price). Payment Arranged guidance points to the button.
- (20 Oct) **Add Fleet Vehicles** button on the sale (screen flow Add_Fleet_Vehicles): pick a model and a quantity (1-50); that many Available cars of the model are added to the sale (each priced from the model) and set to Reserved; if stock is short, it says how many could not be added and to raise an Import Request (US-38). Individual sales are still blocked by Fleet_Sales_Only. Not yet tested in the UI (screen flows cannot be run from a script). Open point: reserved cars stay Reserved if the sale is lost or a line is removed.
- (20 Oct) **Approval Status** (Finance_Status__c relabelled) now covers every hand-off, not only instalments: 🟠 "x% discount waiting: With Showroom Manager / With Finance / With Head Office"; 🟠 instalment states with Finance; 🟢 ready to close / "x% discount approved"; 🔴 "x% discount rejected". New field Discount_Step__c kept up to date by Discount_Request_Apply_To_Sale (now runs on every step change). Shown at the top of Sale Details on every sale, as an Offer and Payment Arranged path key field, and in the open-sales lists. Existing sales back-filled (8).
- **Add Fleet Vehicles** was hidden for Sales Reps (no Run Flows permission): flow now requires explicit access, granted by new permission set Add_Fleet_Vehicles_Flow in the Sales Rep and Showroom Manager groups.
- (20 Oct) Fleet quantity, round 2: logic moved to autolaunched **Add_Fleet_Vehicles_Core** (inputs sale, model, quantity; output count added), called by the screen flow and testable from Apex. The model + quantity form now sits **on the fleet sale page** under Fleet Vehicles (open fleet sales only), not only behind a button. New flow **Sale_Vehicle_Reserve_Car**: any car added to a fleet sale (also by hand) is set to Reserved, which fixed a duplicate found in testing (a hand-added car was still Available and got added twice). Tested by script on "Hillary Emmanuel-": 1 car already on the sale + 3 Hilux requested -> 3 added, all 4 Reserved, total 180,000,000; a further request for 50 -> 0 added (none left). Discount % removed from the Payment Arranged path (Sale Price instead); it still shows in the details when there is a discount.
- (20 Oct) New flow **Opportunity_Lost_Release_Vehicles**: when a sale moves to Closed Lost, its Reserved cars (fleet vehicles and the sale's own vehicle) go back to Available. Tested: 2 Hiluxes reserved on a fleet sale -> Closed Lost -> both Available. Removing a single car from a fleet sale does not release it (not requested).
- (20 Oct) **How many** on the New Fleet Vehicle form (Sale_Vehicle__c.Quantity__c, default 1, beside the vehicle). Flow **Sale_Vehicle_Add_Quantity**: saving a line with How many > 1 reserves the chosen car and adds (How many - 1) more available cars of the same model via Add_Fleet_Vehicles_Core; the line resets to 1 (each car keeps its own line). Tested: one Hilux with How many = 3 -> 3 Hilux lines, all Reserved, 45,000,000 each, sale count 3.
- (20 Oct) Fleet quantity, round 3 (Hillary): **not enough stock = refused**, not partly filled. Sale_Vehicle_Add_Quantity now counts the other Available cars of the model first; if short, a flow custom error blocks the save ("Not enough in stock: you asked for N … only X are available. Nothing was added. Lower the number, or raise an Import Request"). New Vehicle formula **In Stock (Model)** shown beside each car in the vehicle search when picking. The separate Add Fleet Vehicles button and page form were removed (one place: the How many box). Tested: Camry, 4 in stock: asked 5 -> blocked, 0 added; asked 4 -> 4 added.
- (20 Oct) Fleet quantity, round 4 (Hillary): quantity only adds cars **identical to the one picked: same model, year and colour** (Sale_Vehicle_Add_Quantity and Add_Fleet_Vehicles_Core filter on Year and Colour); otherwise refused with the Import Request message. Vehicle names now show the spec: "<Model> <Year> <Colour> · <Chassis>" (21 renamed). Test stock: added 4 White 2026 Toyota Hilux (ADTEST2001-2004) so identical multiples exist. Hillary Emmanuel fleet lines cleared again. Tested: 2 x White Hilux with 1 in stock -> blocked; 4 x White Hilux with 5 in stock -> the picked car + 3 identical, all Reserved (rolled back). Add_Fleet_Vehicles screen flow is no longer on any page (unused).
- (20 Oct) Fleet quantity, round 5 (Hillary): **pick a type, not a car**. Vehicle Model is now the exact type (model + year + colour + trim). Fleet Vehicles -> New asks for **Type** (search shows each type once, with In Stock and List Price) and **How many**; the car is filled in by the system. New field Sale_Vehicle__c.Vehicle_Model__c ("Type"); Sale_Vehicle__c.Vehicle__c no longer required (system-filled, read-only on the form). New before-save flow **Sale_Vehicle_Assign_Car**: refuses the save if fewer than How many cars of the type are Available ("… raise an Import Request for this type"), else assigns the first available car and the type's price; Sale_Vehicle_Add_Quantity adds the rest (core flow now matches on type). Vehicle.Model__c made reparentable. Hilux stock split into types: 2026 White (5), 2026 Red, Grey, Silver (from the existing cars), plus new **2022 White E40** (3, 38,000,000) and **2024 Black AMG** (3, 52,000,000). Tested: 4 AMG with 3 in stock -> blocked; 2 AMG -> 2 AMG cars reserved at 52,000,000 each.
- (20 Oct) Decision (Hillary): full vehicle specifications (trim, engine, transmission, drivetrain, interior, armour level B4-B7 / VR, option packages) are **deferred** - this is a demo build. Current approach stays: Vehicle Model = car type (model + year + colour + trim in the name), fleet lines pick a type + How many.
- (20 Oct) Fleet sale totals include every car: new flow **Opportunity_Fleet_Main_Vehicle_Line** puts the sale's own Vehicle on the Fleet Vehicles list (once); new before-save flow **Opportunity_Fleet_Totals** sets the fleet sale's List Price = Fleet Vehicles Total and Sale Price = total minus approved discount. Back-filled: Hillary Emmanuel fleet sale now 6 cars, 277,000,000 (5 White Hilux + 1 Black AMG).
- Same "type" everywhere: every remaining model split into types by year and colour (5 renamed, 9 new, 10 cars moved), e.g. Toyota Camry 2026 Red, Kia Sportage 2026 Blue; "AD Test - " prefix dropped. All AM Vehicles list shows **In Stock (Type)** (how many of that type are left). Fresh-records script now finds the Camry type by name.
- (20 Oct) Fleet lines, round 6 (UAT): the stock check was skipped when a car was picked directly (old cached form) -> "Grey Camry x 30" saved with 1 car. Sale_Vehicle_Assign_Car now also runs when only a car is picked: the type is taken from the car and the save is refused unless enough identical cars exist. Tested: car picked directly, How many 30, 1 in stock -> blocked.
- Fleet lines can be **deleted** by Sales Rep and Showroom Manager (Sale_Vehicle_Edit allowDelete; cars themselves still cannot be deleted). New Apex **SaleVehicleHandler** + trigger **SaleVehicleTrigger** + test (pass): removing a line releases its car to Available; lines on closed sales cannot be removed; new field **Fleet Summary** on the sale ("4 x Toyota Hilux 2026 White ...") shown in Sale Details for fleet customers. Bad UAT lines SV-0052/0053 removed.
- "Global Action for Send Email is not configured" on contacts: AutoDrive profiles had no global publisher layout assignment; Global-Global Layout (has Send Email) assigned to all 10 AutoDrive profiles.
- (20 Oct) Fleet Vehicles list columns: Type, **Qty of this type** (new Sale_Vehicle__c.Type_Count__c, kept by SaleVehicleHandler with a recursion guard), Car, Sale Price. New rule **Car_Cannot_Be_Swapped**: a line's car/type cannot be changed after it is added (UAT showed a White Hilux line edited into a Grey Camry, bypassing the stock check) - delete the line and add the right type instead. Old lines back-filled with their type.
- (20 Oct) Send Email from contacts, round 2: Global-Global Layout had only classic publisher actions; added the Lightning action list (Send Email, New Task, New Event, Log a Call, New Contact, New Lead, New Case, Post). Sales Rep has Send Email, Edit Tasks and Edit Events permissions.

### EDITED 2026-10-20: Showroom Manager UAT round 1 fixes
- **Leads for the Showroom Manager (US-32):** rep-owned leads were already visible through the role hierarchy; new sharing rule **Website_Leads_To_Showroom_Manager** (Lead, owner = AD Website Leads queue -> role Showroom_Manager, Edit) so unassigned website prospects show too. Lead list views Open Prospects, Prospects With No Rep and Enquiries No Visit Booked now explicitly shared with all internal users.
- **Import requests (US-38), per Hillary:** the Sales Rep only fills the request: Type, **Quantity** (new, default 1) and **Reason for Request** (new, required: Out of stock / Client request), customer and sale. Status, invoice reference, customer confirmation, expected/arrival dates and Requested By are read-only for the rep (Import_Request_Create); Showroom Manager and Finance run the request. New rule Reason_And_Quantity_Required; new flow **Import_Request_Set_Requested_By** records who raised it.
- **Error fixed:** "Import Request - Notify Rep on Arrival … 0 recipients": the arrival email went to Requested By, which was empty on that request. The flow now only emails when there is a requester, and every new request records one.
- **Lists:** deleted "Opportunity Pipeline" (unused SDO list) and "AutoDrive - Open Deals" (same as All Open Opportunities, which has Approval Status). Docs updated.
- **Send Email (open):** the email action is missing from contacts for test users even with the global/contact actions and permissions in place; likely cause is the sandbox Email Deliverability setting (Setup -> Deliverability -> Access level), which is Hillary's to change.
- (20 Oct) Discount approvals per approver: new Discount Request list views **My Approvals - Showroom Manager / Finance / Head Office** (Current Step = with that approver), each shared only with that role. The approval chain is Showroom Manager -> Finance -> Head Office (Head of Finance user), US-02; "Approve" at one step sends it on to the next. Kano DR-0003 (seed data never submitted) submitted into the approval process; test request DR-0023 (10%, Halima Yusuf - Toyota Hilux) created for the manager's reject test. Story check: approver and time recorded (Approved By / Approved On, Step Reached At) - matches US-02, US-08, NFR-03.

### Setup steps for Hillary (not deployable, do in Setup)
1. **Email deliverability:** Setup -> Deliverability -> Access level -> **All email** -> Save. Needed for the Email action on contacts and for all customer/staff emails to be delivered in the sandbox.
2. **Confetti on Closed Won:** Setup -> Path Settings -> AutoDrive Sale Path -> Edit -> Next -> tick **Enable Celebrations**, choose **Closed Won**, frequency **Always** -> Save.
3. (Earlier) Automated Process user email: Setup -> Process Automation Settings.
- (20 Oct) Showroom Manager UAT round 2:
  - New flow **Import_Request_Add_Stock**: marking an import request **Imported** adds its Quantity of cars of that type to stock as Available (chassis IMP-<request>-n), so In Stock goes up for everyone (US-38). Tested: Camry 2026 Black 0 -> 3. Requests already Imported back-filled.
  - Removed demo-org list views: Leads (My Rejected Registrations, Sales - Lead, Sales - Leads West) and Cases (Battery, Billing, Chat, Closed/Open/My Experience Cases, General, Priority, Social_Queue, Turbine, Warranty, duplicate My Cases). Kept: "All - Hot Leads" (used by demo-org home pages; cannot be deleted) and standard Salesforce lists. New Case list **AutoDrive - Showroom Cases** (open cases routed to the Showroom), shared with the Showroom Manager role.
  - **Approval Steps:** tab removed from the app and from the Finance, Head of Finance and Showroom Manager groups; the step-by-step record (who decided each step, when) now shows as a related list on each Discount Request (NFR-03 audit trail kept).
  - "Prospects With No Rep" kept: US-32 requires prospects with no rep to be shown together; it is empty while every lead has a rep.
- (20 Oct) Showroom Manager UAT round 3: case list views limited by role (AD Finance Cases -> Finance + Head of Finance; AD Showroom Cases -> Showroom Manager; Customer Service queue, All Cases, All Open Cases -> CS Agent, Head of CS, Management); package lists "Cases Owned and Shared with Me" cannot be changed. New Discount Request list **Approved by Me - Showroom Manager** (manually approved requests now past the manager: With Finance / With Head Office / Approved). New Vehicle Model list **AutoDrive - Low Stock** (alert active). Test showroom case created for Daniel Okoro (Type Sales).

### EDITED 2026-10-20: Finance UAT round 1 fixes
- Finance could not create instalment plans or payments: Instalment_Plan__c, Payment__c (both master-detail to the sale) and Instalment__c (master-detail to the plan) required **edit** on the parent, and Finance only reads sales. Set writeRequiresMasterRead = true on the three master-detail fields, so read access to the parent is enough (Finance still cannot change the sale).
- New flow **Instalment_Plan_Create_Schedule**: creating a plan creates its monthly instalments at once (term months, each due a month apart, (sale price - down payment) / months, status Upcoming). Tested: Ngozi Okeke, 32,000,000, 10,000,000 down, 4 months -> 4 x 5,500,000 due monthly.
- New Opportunity list **AutoDrive - Plans To Set Up** (instalment sales at Payment Arranged with months, deposit, monthly amount, Approval Status, Finance Notified At), shared with Finance and Head of Finance.
- (20 Oct) Pre-filled payments for Finance: **Record Down Payment** button on the sale (amount = Down Payment Agreed, type Down Payment, paid today) and **Record Payment** on each instalment (screen flow Record_Instalment_Payment: amount = balance still owed, editable for short/extra payments, linked to the instalment and its sale; access via permission set Record_Instalment_Payment_Flow in Finance and Head of Finance groups).
