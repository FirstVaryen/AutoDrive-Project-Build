# AutoDrive Build Plan — staged, in dependency order

Pulled from the Jira backlog (KAN project) and the Design Pack. Each stage lists what to build and why it has to come before the next one. Work through it top to bottom — skipping ahead means re-doing work when something downstream needs a field that doesn't exist yet.

Build everything in this list **declaratively, in Setup**, except Stage 9 (the 3 code exceptions). Jira issue keys are noted so you can mark them done as you go — that keeps the record honest about what's actually built versus planned.

---

## Stage 0 — Org foundation
- Role hierarchy
- Company information (timezone, locale, fiscal year, currency)
- Org-wide defaults per object (table: Design Pack §3 "Starting Access")

## Stage 1 — Objects and fields (all 20 ERD v2 objects + v8 additions)

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

## Stage 2 — Record types
- Account: Individual / Fleet-Corporate (already in signed ERD v2 — confirm, don't rebuild)
- Vehicle: New / Used (Used stays mostly unused this phase, build the type now so it's there later)

**Jira:** KAN-67

## Stage 3 — Relationships
6 master-detail + 17 lookups, per ERD v2. Build these as you create each object above (a relationship field is just a field) — listed here as a separate stage only as a sanity check once Stage 1 is done: open each object and confirm every `→ X Lookup/Master-detail` field from the ERD actually exists.

## Stage 4 — Validation rules
- Showroom capacity
- Per-model stock limit (50)
- No sale to unconverted Lead
- Instalment Plan: 30% min down, 12-month cap, guarantor required — **fleet exception** (Finance-approved override)
- Discount on instalment deal: blocked for individuals — **fleet-only exception**, must still go through approval
- **Discount invalidation on payment-mode switch (Q-O09, confirmed, 13 Oct)**: a Flow, not a validation rule — if a Discount Request is already Approved while Payment Mode = Full Payment and the customer then switches to Instalment, the approval is invalidated and Finance reassesses separately. Build after the fleet-only rule above, same story (US-25).

**Jira:** KAN-68, 74, 79, 92

## Stage 5 — Permission sets (Security Matrix)
Build one permission set per row of the Security Matrix (Design Pack §1):
- Finance-sensitive objects (Payment, Instalment Plan, Instalment, Reconciliation Entry, Legal Escalation) → Finance + Management only
- Legal team → read-only on own Legal Escalation records
- Customer Service Agent → Opportunity/Instalment Plan amount fields hidden
- Finance → read-only Vehicle/Vehicle Model
- Discount Request/Approval Step → requester + current approver visibility
- Management → dashboard access

**Jira:** KAN-44, 47, 49, 70, 76, 85

## Stage 6 — Page layouts / Lightning record pages
One per object/record-type combination that needs distinct fields visible.

## Stage 7 — Users and queues
Test users per role (Showroom Manager, Sales Rep, Finance, Head of Finance, Customer Service Agent, Head of Customer Service, Legal, Management). Queues: Customer Service, Legal Escalation recipient.

## Stage 8 — Automation (Flows + Approval Processes) — build LAST
In this order, since several depend on fields/objects above:
1. Sale-close Flow → Vehicle.Status = Sold
2. Discount Approval Process (Showroom Manager → Finance → Head Office, SLAs 1/1/2 business days, delegate)
3. Payment/balance update Flow
4. Reminder Flow (3 days before due, email only)
5. Missed-payment notice (1 day) / guarantor notice (7 days) / default flag (30 days)
6. Case routing Flow (4-way: Money/Sales/Technical/Other)
7. Case escalation Flow (1 hour, no first response)
8. Legal Escalation Flow (3-gate: 90 days + guarantor + Finance approval)
9. Completion email Flow
10. Low-stock alert Flow
11. Satisfaction request Flow
12. Walk-in rep-assignment Flow
13. Import Request status-progression Flow
14. Vehicle-change/refund Flow

**Jira:** KAN-40, 43, 52, 55, 57, 59, 62, 64, 65, 72, 78, 80, 81, 84, 87, 90

## Stage 9 — The 5 code exceptions (only place Apex/LWC belongs)
- VIN lookup: Apex class + LWC on the Vehicle page
- Agentforce single-action agent: inventory count by model
- Gmail-to-record logging: connector/connected app
- Low-stock blinking visual indicator: LWC with CSS animation on the Vehicle Model record page, driven by `Available_Stock__c` vs `Low_stock_Threshold__c` (added 2026-10-13, see DISCOVERY_LOG.md). A declarative colour-coded formula field (IMAGE()) can show red/green without code, but true blinking/animation isn't available declaratively — this is a deliberate scope add, not a gap.
- No-sale-to-unconverted-Lead check: Apex (or a Flow-maintained tracking field set at Lead conversion) to confirm an Opportunity's Account/Contact actually originated from a converted Lead before allowing Closed Won. Added 2026-10-13 — Salesforce has no native back-reference from Account/Opportunity to its originating Lead, so this can't be a plain formula. See DISCOVERY_LOG.md.

These are genuinely code, not declarative-avoidable — this is where `AutoDrive-SFDX/force-app` and VS Code earn their keep.

## Stage 10 — Reports & dashboard
Build last — needs every object above populated with real data to be meaningful.

**Jira:** KAN-69

## Stage 11 — Test data
Clean sample data per object, enough to demo and test every Flow above.

## Stage 12 — QA pass
Walk every story's Normal/Alternative/Exemption paths as the right persona (never as System Administrator). Defect log in Sandra's PROJECT_LOG.md — fill it in yourself if she isn't actually participating, but keep it honest about who found what.

---

## A note for the record

If this is substantially a solo build, say so plainly in the final handover documentation rather than implying three people built it — Engagement Lead notes, the build log, and the retro are exactly where that honesty belongs, and it protects you better than the alternative if anyone asks a direct question in review.
