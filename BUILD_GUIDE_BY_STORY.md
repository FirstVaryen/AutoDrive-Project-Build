# AutoDrive Build Guide — Story by Story

Same content as the Jira backlog (KAN project), written out as one linear document instead of 90 separate cards. Each story: what it's for, what to build, in what order, with the exact Setup click-path. Work through stages top to bottom — within a story, build the numbered items in order (dependencies are noted).

Jira keys are included so you can mark the matching card Done once you've actually built and tested each piece — keeps the record honest about what's real.

---

# STAGE 1 — Enquiry to Agreed Sale

## US-02/US-08 — Real-time visibility into discount approval status (Jira: KAN-11)
**Story:** Showroom Manager wants to see where a discount request sits (with them, Finance, or Head Office) without phoning anyone.

**Build in this order:**
1. **[Object]** Discount Request + Approval Step fields — *Setup → Object Manager → New Custom Object* (both, master-detail as per STAGE1_OBJECTS_SPEC.md). Build first — everything below depends on these existing.
2. **[Permission Set]** Visibility restricted to requester + current approver — *Setup → Permission Sets → New* → Object Settings on Discount Request/Approval Step.
3. **[Flow] (build last)** Approval Process: Showroom Manager → Finance → Head Office, SLAs 1/1/2 business days, delegate coverage — *Setup → Approval Processes → New Approval Process* (not a Flow — use the dedicated Approval Process builder). 3 steps, add time-based reminder actions for the SLA windows, set a delegate per approver.
4. **[Test]** Confirm SLA reminders fire and delegate approval works when the usual approver is unavailable.

**Depends on:** nothing upstream in this stage.

---

## US-16/US-20 — Fleet account discount and payment terms (Jira: KAN-26)
**Story:** Fleet customers are negotiated per deal (not a stored rate); still need approval above 5%; may get Finance-approved exceptions to the standard 30%/12-month terms.

**Build in this order:**
1. **[Object]** Confirm Account record types **Individual** / **Fleet-Corporate** exist (should already be in ERD v2) — *Setup → Object Manager → Account → Record Types*.
2. **[Validation]** Fleet case-by-case exception to the 30%/12-month cap, requires Finance approval (on Instalment Plan) — *Setup → Object Manager → Instalment Plan → Validation Rules → New*.

**Depends on:** nothing. This story's Record Type is needed by US-25 below — build it first if doing both.

---

## US-23 — Rep records qualifying questions on walk-in prospect (Jira: KAN-29)
**Story:** Standard qualifying questions get saved on the Lead.

**Build in this order:**
1. **[Object]** `Lead.Qualification Answers` (Long Text Area) — *Setup → Object Manager → Lead → Fields & Relationships → New*.

**Depends on:** nothing.

---

## US-25 — No discount on an instalment deal, fleet-only exception (Jira: KAN-30)
**Story:** Blocks a discount on instalment deals for individuals; fleet is the sole exception, and only via the normal approval process (not auto-applied).

**Build in this order:**
1. **[Validation]** Block if Payment Mode = Instalment AND Account.RecordType ≠ Fleet-Corporate — *Setup → Object Manager → Discount Request (or Opportunity) → Validation Rules → New*.
2. **[Test]** Individual customer blocked; fleet customer allowed only via approval, never auto-applied.

**Depends on:** the Account Record Type from US-16/20 above — build that first.

---

## US-30 — Walk-in assigned to next free rep (Jira: KAN-34)
**Story:** Next available rep gets the walk-in, with exceptions for returning/high-profile customers.

**Build in this order:**
1. **[Flow]** Walk-in assignment logic — *Setup → Flows → New Flow → Record-Triggered Flow* on Lead.

**Depends on:** nothing.

---

## US-32 — Showroom Manager sees all open prospects with source, rep and stage (Jira: KAN-95)
**Story:** A working view of where deals are stuck — no new fields, just a list view.

**Build in this order:**
1. **[Object]** List View — "Open Prospects", filtered to open stages, columns: Channel (source), Assigned Rep, Stage — *Lead tab → List View dropdown → New*.

**Depends on:** nothing — Lead's Channel/Assigned Rep/Stage already exist.

---

# STAGE 2 — Payment Capture

## US-03/US-09 — Payments recorded and reconciled against bank (Jira: KAN-12)
**Story:** Payment and Reconciliation Entry records; Finance-only visibility.

**Build in this order:**
1. **[Object]** Payment, Reconciliation Entry fields — *Object Manager → New Custom Object* (per spec). Build first.
2. **[Permission Set]** Finance/Management only — *Permission Sets → New* → lock Payment/Instalment Plan/Instalment/Reconciliation Entry to Finance + Management.
3. **[Test]** Confirm a Sales Rep test user cannot see these objects at all (not read-only — genuinely invisible).

**Depends on:** nothing.

---

## US-28 — Partial and extra payments recorded accurately (Jira: KAN-32)
**Story:** Payment amounts and running balances stay correct through partial payments.

**Build in this order:**
1. **[Object]** `Payment.Amount` (negative = reversal), `Instalment.Amount Paid` (roll-up), `Instalment.Balance` (formula) — per STAGE1_OBJECTS_SPEC.md.
2. **[Flow] (build last)** Update paid/remaining balance at once on each payment; log who recorded it and when — *Flows → New Flow → Record-Triggered Flow* on Payment create.

**Depends on:** Payment and Instalment objects (US-03/09) must exist first.

---

## US-29 — Instalment plan rules enforced (Jira: KAN-33)
**Story:** 30% minimum down, 12-month cap (with renegotiation cap), guarantor required before sign-off.

**Build in this order:**
1. **[Validation]** 30% down min / 12-month cap / guarantor required — *Object Manager → Instalment Plan → Validation Rules → New* (2–3 separate rules for clarity). Build first.
2. **[Flow] (build last)** Guarantor income-check gate before Head of Finance sign-off — *Flows → New Flow*, or an Approval Process if that fits better (single approver).

**Depends on:** Instalment Plan object must exist.

---

# STAGE 3 — Sale Close & Stock Update

## US-01 — Vehicle status always reflects reality at sale close (Jira: KAN-10)
**Story:** Vehicle.Status flips to Sold automatically the instant a sale closes.

**Build in this order:**
1. **[Object]** `Vehicle.Status` picklist (Available/Reserved/Sold/Not for sale) — build as part of Stage 1 objects.
2. **[Flow] (build last)** Sale-close Flow sets Status = Sold in the same transaction — *Flows → New Flow → Record-Triggered Flow* on Opportunity (sale-close action). One record-trigger flow per object.

**Depends on:** Vehicle object must exist (Stage 1).

---

## US-07 — Sales Rep sees live vehicle availability before speaking to a customer (Jira: KAN-93)
**Story:** The rep-facing read of the same status US-01 maintains — "I never promise a car that's already sold."

**Build:** No new build — this is Vehicle.Status (US-01, above) read on the Vehicle tab/record page and in list views reps already use. Card exists for traceability against the original 11 Must stories.

**Depends on:** US-01's Status field and sale-close Flow.

---

## US-12 — Low-stock alert per model (Jira: KAN-23)
**Story:** Alerts the Showroom Manager once when stock drops below threshold; clears when it recovers.

**Build in this order:**
1. **[Object]** `Vehicle Model.Low-stock Threshold` — part of Stage 1.
2. **[Flow] (build last)** Fires once, clears when stock recovers — *Flows → New Flow → Record-Triggered Flow* on Vehicle Model, comparing Available Stock to threshold.

**Depends on:** Vehicle Model + Vehicle (for the Available Stock roll-up) must exist first.

---

## US-26 — Finance sees inventory, models and list prices (read-only) (Jira: KAN-31)
**Story:** Finance needs read access to stock/models/prices for reconciliation.

**Build in this order:**
1. **[Permission Set]** Finance read-only on Vehicle/Vehicle Model — *Permission Sets → New*.

**Depends on:** Vehicle/Vehicle Model objects must exist.

---

## US-38 — Import Request when a model is out of stock (Jira: KAN-38)
**Story:** Rep raises a request, customer confirms, Finance confirms, head office imports, rep is notified.

**Build in this order:**
1. **[Object]** Import Request fields — per spec. Build first.
2. **[Flow] (build last)** Status progression: requested → customer confirmed → Finance confirmed → imported → rep notified — *Flows → New Flow → Record-Triggered Flow* on Import Request.

**Depends on:** nothing outside this story.

---

# STAGE 4 — Collections & Legal Escalation

## US-05/US-17 — Late and default views for Finance (Jira: KAN-14)
**Story:** Late list with amount overdue and days late; 30-day default flag; 1-day customer notice; 7-day guarantor notice.

**Build in this order:**
1. **[Object]** `Instalment.Days Late` (formula), `Default Alert Sent` (checkbox) — Stage 1.
2. **[Flow] (build last)** Missed-payment (1 day) / guarantor notice (7 days) / default flag (30 days) — *Flows → New Flow → Scheduled-Triggered Flow* on Instalment.
3. **[Test]** Confirm all three thresholds fire at the correct day count (not the old 7-day default assumption).

**Depends on:** Instalment object must exist.

---

## US-15/US-19 — Instalment reminder 3 days before due date (Jira: KAN-25)
**Story:** Email-only reminder (confirmed, no SMS this phase).

**Build in this order:**
1. **[Flow]** Scheduled Flow, 3 days before Due Date, email only — *Flows → New Flow → Scheduled-Triggered Flow*.
2. **[Test]** Confirm it's skipped if already paid, and follows a renegotiated schedule if the plan changed.

**Depends on:** Instalment object.

---

## US-36 — Legal Escalation raised when a guarantor can't cover a default (Jira: KAN-36)
**Story:** 3-gate trigger — 90 days default AND guarantor contacted/unable AND Finance management approval — all three required together.

**Build in this order:**
1. **[Object]** Legal Escalation full field list (incl. v8 additions: Vehicle Purchased, Contract Number, Amount Paid, Outstanding Balance, Number of Missed Payments, Guarantor Information; Status 4 values) — per spec. Build first.
2. **[Permission Set]** Finance + Management full access; Legal read-only on own records — *Permission Sets → New*.
3. **[Flow] (build last)** 3-gate trigger, raised by Head of Finance, emails the Legal team distribution list — *Flows → New Flow → Screen Flow*.
4. **[Test]** Confirm each gate is required independently; customer can still pay after escalation; closes only on settlement or management approval.

**Depends on:** Instalment Plan + Guarantor objects must exist.

---

## US-37 — Completion email sent when plan is fully paid (Jira: KAN-37)
**Story:** Congratulates customer, confirms settlement, next steps for ownership docs, Finance contact — sent once, from the Finance mailbox.

**Build in this order:**
1. **[Flow]** Completion Flow + `Completion Email Sent` checkbox guard (so it never re-fires) — *Flows → New Flow → Record-Triggered Flow* on Instalment Plan.
2. **[Test]** Confirm it fires exactly once per plan, never re-sends on a later edit.

**Depends on:** Instalment Plan object (already has the checkbox field built in Stage 1).

---

# STAGE 5 — Customer Service Intake

## US-06 — Case logged and routed from any channel (Jira: KAN-15)
**Story:** Every channel (incl. walk-in, text — confirmed Q-S01) creates a Case; routes 4 ways: Finance / Showroom Manager / Customer Service (Technical) / manual review.

**Build in this order:**
1. **[Object]** `Case.Channel` (+Walk-in, +Text), `Case.Routed To` (+Technical) — per spec. Build first.
2. **[Flow] (build last)** 4-way routing — *Flows → New Flow → Record-Triggered Flow* on Case.
3. **[Test]** Confirm every channel creates a Case and all 4 routing branches work.

**Depends on:** nothing outside this story.

---

# STAGE 6 — Case Routing & Resolution

## US-04 — Agent sees history, not payment amounts (Jira: KAN-13)
**Story:** Field-level security, not a build-new-thing story.

**Build in this order:**
1. **[Permission Set] / Locked Fields** Hide Opportunity/Instalment Plan amount fields from the Agent profile — *Permission Sets → New* or Field-Level Security on the profile directly.
2. **[Test]** Agent sees "plan exists," not the dollar figure.

**Depends on:** Instalment Plan object (Stage 2) must exist.

---

## US-11 — Unresolved case escalated to Head of Customer Service (Jira: KAN-16)
**Story:** 1-hour no-first-response threshold (Delivery Plan figure — Q-S03's 24-hour proposal is still unanswered).

**Build in this order:**
1. **[Flow]** Escalation Flow, 1 hour no first response → High priority, flags Head of CS — *Flows → New Flow → Scheduled or Record-Triggered Flow* on Case.
2. **[Test]** Confirm it fires at exactly 1 hour.

**Depends on:** nothing. **Note:** US-33 below shares this exact Flow — build once, don't duplicate.

---

## US-10 — Head of Customer Service sees case status without asking an agent (Jira: KAN-94)
**Story:** Same traceability situation as US-07 — no new build.

**Build:** No new build — covered by Case fields and list views already supported by US-11 and US-13. Card exists for traceability against the original 11 Must stories.

**Depends on:** US-11/US-13's Case fields.

---

## US-13 — First-response and resolution time tracked (Jira: KAN-24)
**Build in this order:**
1. **[Object]** `Case.First Response At`, `Resolved At` — Stage 1/5.
2. **[Flow] (build last)** Capture timestamps on first genuine reply (not auto-ack) and on Resolved — *Flows → New Flow → Record-Triggered Flow* on Case.

**Depends on:** Case object (standard, already exists) with the extra fields added.

---

## US-33 — Case auto-escalates past the response time limit (Jira: KAN-35)
**Build:** Same Flow as US-11 (KAN-16) above. **Check KAN-16/57 first** — if built, just confirm it satisfies this story too and don't rebuild it.

---

# STAGE 7 — Satisfaction

## US-22/US-24 — Satisfaction score captured on case resolution (Jira: KAN-28)
**Build in this order:**
1. **[Object]** `Case.CSAT Score`, `CSAT Requested At` — Stage 1.
2. **[Flow] (build last)** Satisfaction request sent on Resolved — *Flows → New Flow → Record-Triggered Flow* on Case.

**Depends on:** Case object with the extra fields.

---

# STAGE 8 — Management Dashboard

## US-21 — Unified management dashboard (Jira: KAN-27)

KPI Management Pack reconciled: of its 26 measures, 22 are buildable off the current design (several newly unlocked by v8's Arrival Date and Ownership Documents Status fields), 3 need an out-of-scope handover event, 1 (public-review-first complaints) was deliberately dropped.

**Build in this order:**
1. **[Object]** `Vehicle Model.Stock Ceiling` (Number) — makes the 50-unit cap reportable, not just enforced by a hardcoded validation-rule number. Update the Stage 4 validation rule to reference it once both exist.
2. **[Object]** `Instalment Plan.Ownership Documents Status Changed` (Date/Time) — needed for "how long outstanding," not just current status. The Flow that updates it on status change belongs in Stage 8 with the rest of automation, not now.
3. **[Object]** Reports built on top of every object above — *Setup → Reports → New Report*, then **Dashboards → New Dashboard** to assemble them.
4. **[Permission Set]** Dashboard access restricted to Management — dashboard folder sharing, or a Permission Set if you want it more formal.

**Depends on:** genuinely everything above — build this last, once there's real data flowing through every other object.

---

## US-14/US-18 — Searchable knowledge base, maintained centrally (Jira: KAN-96)
**Story:** Agents search a consistent set of answers; Head of Customer Service keeps it current. This is the same behaviour as Side Flow F below, now with its own story.

**Build in this order:**
1. **[Object]** List view/search on Knowledge Article (filter Status = Published) for agents — *Knowledge Article tab → New List View*.
2. **[Permission Set]** Create/Edit on Knowledge Article restricted to Head of Customer Service — *Setup → Permission Sets → New*.

**Depends on:** Knowledge Article object (Stage 1 #14) already exists — nothing else needed.

---

# SIDE FLOWS — Vehicle Change / Refund (new, back in scope)

## US-39 — Vehicle change or payment-type switch before collection (Jira: KAN-17)
**Story:** Amount paid transfers to the new vehicle; price difference settled either way; refund needs Head of Finance approval; instalment-to-full switches credit prior payments.

**Build in this order:**
1. **[Flow]** Vehicle-change/refund Flow — *Flows → New Flow → Screen Flow* (rep-initiated).
2. **[Test]** Payment-transfer and price-difference math correct both directions; refund genuinely blocked without approval.

**Depends on:** Opportunity + Payment objects must exist.

---

## Cross-story notes worth keeping in mind
- **US-11 (KAN-16) and US-33 (KAN-35)** are the same underlying Flow from two different story IDs in the original workbook — build once.
- **US-25's validation rule** needs the **Account Record Type** from US-16/20 — do that one first if building both in the same session.
- Everything in **Stage 8 (Dashboard)** depends on every earlier stage having real data — it's last for a reason, don't jump ahead to it.
