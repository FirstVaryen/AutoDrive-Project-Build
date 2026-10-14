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

## Stage 4 — Validation rules 🔶 Partially done (7 of 7 listed rules built; the discount-invalidation item below is a Flow, not built, belongs to Stage 8)
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

## Stage 9 — The 6 code exceptions (only place Apex/LWC belongs) ⬜ Not started
- VIN lookup: Apex class + LWC on the Vehicle page
- Agentforce single-action agent: inventory count by model
- Gmail-to-record logging: connector/connected app
- Low-stock blinking visual indicator: LWC with CSS animation on the Vehicle Model record page, driven by `Available_Stock__c` vs `Low_stock_Threshold__c` (added 2026-10-13, see DISCOVERY_LOG.md). A declarative colour-coded formula field (IMAGE()) can show red/green without code, but true blinking/animation isn't available declaratively — this is a deliberate scope add, not a gap.
- No-sale-to-unconverted-Lead check: Apex (or a Flow-maintained tracking field set at Lead conversion) to confirm an Opportunity's Account/Contact actually originated from a converted Lead before allowing Closed Won. Added 2026-10-13 — Salesforce has no native back-reference from Account/Opportunity to its originating Lead, so this can't be a plain formula. See DISCOVERY_LOG.md.
- Apex Managed Sharing for Discount Request: dynamically share each Discount Request record with the right approver group as Current_Step__c changes. Added 2026-10-13 — Discount_Request__c is Master-Detail to Opportunity, which forces its OWD to Controlled By Parent; Sharing Rules are structurally impossible on a Master-Detail child object (confirmed by deploy error), so this can't be declarative. See DISCOVERY_LOG.md. Also covers the same gap on Instalment Plan/Instalment/Payment if Finance Team/Showroom Manager ever need edit-without-owning on those (also Master-Detail children) rather than just the view-only access they have today.

These are genuinely code, not declarative-avoidable — this is where `AutoDrive-SFDX/force-app` and VS Code earn their keep.

## Stage 10 — Reports & dashboard ⬜ Not started
Build last — needs every object above populated with real data to be meaningful.

**Jira:** KAN-69

## Stage 11 — Test data ⬜ Not started
Clean sample data per object, enough to demo and test every Flow above.

## Stage 12 — QA pass ⬜ Not started
Walk every story's Normal/Alternative/Exemption paths as the right persona (never as System Administrator). Defect log in Sandra's PROJECT_LOG.md — fill it in yourself if she isn't actually participating, but keep it honest about who found what.

## Stage 13 — Permission architecture rework (post-presentation feedback, 2026-10-13) 🔶 Mostly done — 52 atomic sets + 8 Permission Set Groups built and assigned (2026-10-14); old 9 sets unassigned but not yet deleted; Locked Fields/muting gap still open
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

## Stage 14 — Role-based Lightning Apps (post-presentation feedback, 2026-10-13) ⬜ Not started
Same feedback, second half: each of the 8 roles gets its own Lightning App (Setup → App Manager), not just shared access to one app with everything in the nav bar. Each app shows only the tabs/objects that role actually touches, so a demo to a non-technical audience can open "the Showroom Manager app" and see a Showroom Manager's world, not the whole data model.

**Plan:**
1. One custom Lightning App per role (8 apps): Sales Rep, Showroom Manager, Finance Team, Head of Finance, Customer Service Agent, Head of Customer Service, Legal Team, Management.
2. Each app's nav bar: only the objects that role's Permission Set Group (Stage 13) actually grants access to — keeps the app and the access grant honest, one shouldn't show a tab the other blocks.
3. Assign each app's visibility to its matching Permission Set Group (or Profile, if the group-level app assignment proves awkward) so each test user lands in their own app by default on login.

**Not started. Plan only — do not build until explicitly asked.** Depends on Stage 13 being built first (the app's visible tabs are meant to mirror the group's actual grants).

## Stage 15 — Solution Document (post-presentation feedback, 2026-10-13) ✅ Done (2 versions — see entry below)
A plain-language solution document for a non-technical audience — what AutoDrive's Salesforce build actually does, per role, without assuming any Salesforce knowledge. Two versions delivered 2026-10-13: a first pass as a published Artifact (not grounded in the client's own words — superseded), then a second pass as a PDF, grounded directly in `TAP 3.0/AutoDrive_Requirements_UserStories_v8.xlsx` — real stakeholder quotes (Henry Idagu, Obed Koplang, Shedrack Jatau), verified story counts (11 Must/22 Should/5 Could/12 Won't Have, 38 total), confirmed business rules, and the still-open client questions. Revisit/republish once Stage 13/14 are actually built, since the current version describes the role list and data model as they stand today, not the future per-role-app state.

## Stage 16 — Data model explainer, plain language (post-presentation feedback, 2026-10-13) ✅ Done — delivered as `AutoDrive_Data_Model_Explained.pdf` (2026-10-13)
**Separate deliverable from Stage 15.** Direct feedback from Shedrack Jatau (Head of Customer Service, Meeting Transcription 2026-10-13, 29:49–38:36) on this build's first presentation: *"I'm not sure I got much clarity as to the objects that have been configured and their purposes... for me, as the client, I want to know that you have built containers where I can store my [data] — my vehicle — I will no longer live on [Excel]... then from there my work flows smoothly."* He called the data model "the foundation of the house" — everything else (automation, reporting, security) rests on it being understood first, and asked specifically for more time spent explaining *what each object is for*, not touring fields quickly.

This is distinct from Stage 15: the solution document covers workflow and role access; this one is object-by-object, in plain terms — "this is where a vehicle lives," "this is where a discount request lives and why it's a separate record from the sale itself" — enough that a non-technical client could ask a clarifying question or request a change and have it make sense to them, and so it can be logged properly against the change log per Shedrack's instruction.

**Plan:**
1. Walk all 14 custom objects + 4 standard extensions, one plain-English paragraph each: what real-world thing it represents, why it's a separate "container" rather than a field on something else, and which role actually uses it.
2. A simple visual (diagram, not a technical ERD with arrows and cardinality notation) showing how the containers connect — e.g. "a Sale has one Discount Request, which has many Approval Steps" in sentence form before/alongside any box-and-line diagram.
3. Deliver as a document the client could read without a Salesforce person in the room, same bar as Stage 15.

**Done, 2026-10-13.** Delivered as `AutoDrive_Data_Model_Explained.pdf` — all 14 custom objects + 4 standard extensions, plain-English, plus a sentence-form connection map (Part 3 of the doc) instead of a technical ERD.

## Stage 17 — Demo readiness: persona-journey walkthroughs (post-presentation feedback, 2026-10-13) ⬜ Not started
Obed Koplang's feedback on *how* to present, not what to build (Meeting Transcription, 2026-10-13, 08:29 and 32:12): don't tour the org object-by-object — pick one persona's real journey (a Sales Rep selling a car, a Finance Team Member recording a payment, a Showroom Manager approving a discount) and walk it start to finish, logged in as that user, not as System Administrator. When demonstrating a validation rule, trigger it live — enter a value that should be blocked and show the actual error message, rather than describing what the rule does.

**Plan:** once Stage 14's per-role apps exist, script one journey per role (reuses Stage 12's QA persona-login discipline — never demo as System Administrator) ending in at least one live validation-rule failure shown on screen. This is presentation prep, not a Salesforce build item, but it's blocked on Stage 14 existing, so it's sequenced here.

**Not started. Plan only — do not build until explicitly asked.**

---

## A note for the record

If this is substantially a solo build, say so plainly in the final handover documentation rather than implying three people built it — Engagement Lead notes, the build log, and the retro are exactly where that honesty belongs, and it protects you better than the alternative if anyone asks a direct question in review.
