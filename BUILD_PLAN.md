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
