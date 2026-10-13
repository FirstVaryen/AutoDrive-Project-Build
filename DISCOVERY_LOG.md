# Discovery Log

Things learned/decided during the metadata-driven build, logged on request so the reasoning isn't lost. Append-only — newest at the bottom.

---

### 2026-10-13 — Why we didn't reuse the standard "Vehicle" object
The org has a standard `Vehicle` object, but it belongs to the Field Service (FSL) package already installed in this sandbox — it represents a company service vehicle (van/truck dispatched to field jobs), not a car for sale. Wrong domain, wrong fields, namespaced to a package we don't control, and nothing in our ERD (Status picklist, Model master-detail, Showroom lookup) exists on it. Built `Vehicle__c` as our own custom object instead — matches the ERD, zero license/package dependency risk.

### 2026-10-13 — Why Approval Step exists as its own object
`Discount_Request.Current_Step__c` only shows where a request is *right now*. `Approval_Step__c` (master-detail child of Discount Request) keeps a permanent record per approver per step — who acted, when, their decision, their reason. Without it we'd lose the audit trail the moment a request moves to the next step, and couldn't prove delegate approvals happened (a Stage 1 test requirement) or use the `Recorded By Finance For Head Office` flag, which only makes sense attached to one specific approval event.

### 2026-10-13 — Why Instalment.Amount Paid is a Flow-maintained field, not a Roll-Up Summary
Spec calls for a Roll-Up Summary from Payment, but Roll-Up Summary fields only work across Master-Detail relationships. Payment→Instalment has to be a plain Lookup (optional) because a Down Payment or Full Payment isn't tied to any specific instalment. So `Amount_Paid__c` is a plain Currency field, starting at 0, updated by the Stage 2 Payment-trigger Flow (US-28) on every payment. This is the standard Salesforce pattern for a lookup-based rollup, not a workaround — functionally identical to a native roll-up from any report/formula's perspective once the Flow exists.

### 2026-10-13 — Low-stock alert needs a guard field (not yet built)
US-12's Flow ("fires once, clears when stock recovers") needs a guard checkbox on Vehicle Model to avoid re-firing the alert on every save while still under threshold — same pattern as `Instalment.Default_Alert_Sent__c`. Not in the original spec. Plan to add `Low_Stock_Alert_Active__c` (checkbox) when we build this Flow in Stage 8, set true when the alert fires, cleared once stock crosses back above threshold.

### 2026-10-13 — Case.Type is safe to repurpose if we want to
Checked all Flows/Validation Rules/Workflow Rules/Approval Processes referencing Case in the org. 24 Case-related Flows exist, all pre-existing `SDO_...` demo seed automation (not ours). Only two reference a field named "Type" at all, and both actually filter `Group.Type = 'Queue'` (Omni-Channel routing), not `Case.Type`. Nothing currently reads the standard Case.Type field.

**Decided: repurposed.** Standard `Case.Type` picklist values replaced with Sales/Payment/Technical/Documents/Other; the duplicate `Case_Type__c` custom field was deleted from org and project. One field now, no duplication.

### 2026-10-13 — Low-stock blinking indicator added to Stage 9 scope
True blinking/animation isn't available declaratively in Salesforce — only a Lightning Web Component with CSS animation can do it. Added as a 4th Stage 9 code exception (see BUILD_PLAN.md) alongside VIN lookup, the Agentforce agent, and the Gmail connector. Decision: document now, build later when we reach Stage 9 — not building yet. A declarative colour-coded formula field (IMAGE(), red/green) remains available as a no-code fallback if the LWC version gets deprioritized.

### 2026-10-13 — Repurposed the standard Case object's Type field
I repurposed the standard Case.Type field instead of keeping a separate custom field, because a check of the org's Flows/Validation Rules/Workflow Rules/Approval Processes found nothing linking to it.

### 2026-10-13 — Account's Individual/Fleet-Corporate record types did NOT already exist
STAGE1_OBJECTS_SPEC.md and BUILD_PLAN.md both assumed these were "already in signed ERD v2 — confirm, don't rebuild." Checked the org directly: Account only had pre-existing demo record types (SDO_Account_Partner, SDO_Account_Simple, Business_Account, PersonAccount, SDO_PersonAccounts) — no Individual or Fleet-Corporate. Built both in Stage 2. Lesson: verify spec assumptions against the actual org rather than trusting "should already exist" notes, even when the spec sounds confident.

### 2026-10-13 — Vehicle's Used record type (and Showroom's multi-location shape) are built for the future, not today
Traced the "do we sell used vehicles" question to source. Not Obed — two different mentions, neither a current-state confirmation: (1) a TAP training lecture (session 8.md) used "if we decide to start selling used vehicles" purely as a hypothetical teaching example for validation rules; (2) Aramy Aram, in Meeting Transcription 4, used pre-owned sales as the textbook example of an *unconfirmed assumption you shouldn't silently build on* — the opposite point of "build it now."

The actual confirmed client fact is in `TAP 3.0/AutoDrive_Handoff.md` line 86: **"One showroom, new vehicles only today. Multi-showroom transfer and pre-owned sales are out of scope for the build, but the design should not prevent them later."**

So Vehicle's `Used` record type, and Showroom's `City` field plus its general multi-row shape, are both the same kind of decision: present in the data model so the design doesn't block future expansion, but doing no real work today since AutoDrive currently runs one showroom selling only new vehicles. Showroom as an object itself stays required regardless (Vehicle.Showroom__c is a mandatory lookup — every Vehicle needs a parent Showroom even when there's only one) — it's specifically the City field and multi-location flexibility that are the forward-looking part, not the object's existence.

### 2026-10-13 — Stage 3 relationship sanity check: 6 Master-Detail, 21 Lookup, all confirmed
Verified every relationship field against the org and local source. 6 Master-Detail relationships exactly matches BUILD_PLAN.md's stated count. 21 Lookup relationships vs. the spec's stated "17" — not a gap, the spec's number predates the v8 field additions (Legal Escalation's Guarantor Information, Instalment Plan, Account, Escalated By lookups were added as part of v8, after the original "17" count was written).

### 2026-10-13 — Full relationship list, in build order

1. `Vehicle.Model__c` → Vehicle Model **(Master-Detail — a Vehicle has no meaning without its Model; deleting the Model deletes its Vehicles; required for the Available Stock roll-up — US-12, KAN-23)**
2. `Vehicle.Showroom__c` → Showroom **(Lookup — a Vehicle can exist/move without a fixed Showroom tie, and Showroom can't own Vehicle's lifecycle — general inventory tracking, STAGE1_OBJECTS_SPEC.md #3)**
3. `Discount_Request__c.Opportunity__c` → Opportunity **(Master-Detail — the request only exists in service of one sale; needed so visibility/sharing can be controlled by the parent — US-02/US-08, KAN-11)**
4. `Discount_Request__c.Requested_By__c` → User **(Lookup — just an audit pointer to who asked; doesn't own the request's lifecycle — US-02/US-08)**
5. `Approval_Step__c.Discount_Request__c` → Discount Request **(Master-Detail — each step is a child record that exists only to document one request's history — US-02/US-08, KAN-11)**
6. `Approval_Step__c.Acted_By__c` → User **(Lookup — audit pointer to which approver acted, supports proving delegate approval — US-02/US-08)**
7. `Instalment_Plan__c.Opportunity__c` → Opportunity **(Master-Detail — the plan is entirely a feature of one sale — US-29, KAN-33)**
8. `Instalment_Plan__c.Guarantor__c` → Guarantor **(Lookup, required — a plan always needs a guarantor before sign-off, but Guarantor is its own independent record, not owned by the plan — US-29, KAN-33)**
9. `Instalment_Plan__c.Signed_Off_By__c` → User **(Lookup — audit pointer to which Head of Finance signed off — US-29)**
10. `Instalment__c.Instalment_Plan__c` → Instalment Plan **(Master-Detail — one scheduled payment only exists as part of its plan — US-29 / US-05/US-17, KAN-14)**
11. `Payment__c.Opportunity__c` → Opportunity **(Master-Detail — every payment belongs to one sale; required for the Total Paid roll-up — US-03/US-09, KAN-12)**
12. `Payment__c.Instalment__c` → Instalment **(Lookup, optional — a Down Payment or Full Payment isn't tied to any specific instalment, so it can't be Master-Detail — US-28, KAN-32)**
13. `Payment__c.Recorded_By__c` → User **(Lookup — audit pointer to who recorded it — US-03/US-09)**
14. `Payment__c.Reversal_Of__c` → Payment **(Lookup, self-reference — links a reversal back to the original payment; a payment can't be its own master — US-28)**
15. `Import_Request__c.Account__c` → Account **(Lookup — the requesting customer, independent of the request's lifecycle — US-38, KAN-38)**
16. `Import_Request__c.Vehicle_Model__c` → Vehicle Model **(Lookup — which model is being imported — US-38)**
17. `Import_Request__c.Opportunity__c` → Opportunity **(Lookup, optional — a related sale may not exist yet when the request is raised — US-38)**
18. `Import_Request__c.Requested_By__c` → User **(Lookup — audit pointer to the rep who raised it — US-38)**
19. `Legal_Escalation__c.Account__c` → Account **(Lookup — the customer being escalated — US-36, KAN-36)**
20. `Legal_Escalation__c.Instalment_Plan__c` → Instalment Plan **(Lookup — the defaulted plan driving the escalation — US-36)**
21. `Legal_Escalation__c.Guarantor_Information__c` → Guarantor **(Lookup, v8 addition — the guarantor on the defaulted plan — US-36)**
22. `Legal_Escalation__c.Escalated_By__c` → User **(Lookup — audit pointer, should be Head of Finance per the 3-gate process — US-36)**
23. `Customer_Message__c.Case__c` → Case **(Lookup, optional — a message may relate to a support case — US-06, KAN-15)**
24. `Customer_Message__c.Instalment__c` → Instalment **(Lookup, optional — a message may be a payment reminder/missed-payment notice — US-15/US-19, US-05/US-17)**
25. `Customer_Message__c.Account__c` → Account **(Lookup, optional — the recipient account — US-06)**
26. `Opportunity.Vehicle__c` → Vehicle **(Lookup, added to the standard object — which vehicle is being sold; Opportunity already exists independently of any one Vehicle — core sale field additions, STAGE1_OBJECTS_SPEC.md field additions)**
27. `Case.Escalated_To__c` → User **(Lookup, added to the standard object — who the case was escalated to — US-11/US-33, KAN-16/KAN-35)**

Not relationship fields, but the two record-type decisions from Stage 2 belong in this same mental model: Vehicle's Used record type and Account's Individual/Fleet-Corporate record types shape how these relationships get *used*, not the relationships themselves.

### 2026-10-13 — Stage 4 validation rules: 6 built, two build errors fixed
Built 6 of the Stage 4 rules: Instalment Plan's 30% down payment minimum, 12-month term cap, renegotiation-can't-exceed-original-term, and guarantor-income-check-before-signoff (all with the Fleet + Head of Finance sign-off exception baked in); Discount Request's no-discount-on-individual-instalment-deal; and Vehicle's 50-unit per-model stock cap (backed by a new native Roll-Up Summary, `Vehicle_Model__c.Total_Stock_Count__c`, counting non-Sold Vehicles — this one works natively since Vehicle→Vehicle Model is Master-Detail, unlike the Payment/Instalment situation).

Two build errors:
1. **Validation Rule API names (`fullName`) are capped at 40 characters** — two rule names were 41 chars, rejected on deploy. Shortened `Renegotiation_Cannot_Exceed_Original_Term` → `Renegotiation_Term_Cap`, and `No_Discount_On_Individual_Instalment_Deal` → `No_Discount_Individual_Instalment`.
2. **Picklist fields can't use `=` in a formula** — must use `ISPICKVAL(field, 'value')` instead. Hit this comparing `Opportunity.Payment_Mode__c = 'Instalment'`; fixed to `ISPICKVAL(Opportunity__r.Payment_Mode__c, 'Instalment')`. (Text-type fields like `RecordType.DeveloperName` are fine with plain `<>`/`=`.)

Also a packaging quirk: deploying just a `validationRules` subfolder for an object whose record types are declared inline in its `.object-meta.xml` (Vehicle__c) confused the deploy manifest — "RecordType... Not in package.xml" errors. Fixed by deploying the whole object folder instead of a slice of it, same pattern as the earlier sharing-model fix.

### 2026-10-13 — Showroom capacity: Flow-maintained field chosen (not a 2nd Master-Detail)
Decided: `Showroom__c.Vehicle_Count__c` (plain Number, default 0) maintained by a Stage 8 Flow, same pattern as `Instalment.Amount_Paid__c`. Rejected converting `Vehicle.Showroom__c` to a second Master-Detail (Salesforce allows up to 2 per object, so it was technically possible) because that would make deleting a Showroom cascade-delete every Vehicle assigned to it — unacceptable risk for a physical-location object. The validation rule `Vehicle__c.Showroom_Capacity_Not_Exceeded` is built and deployed, but is **inert** (will never block) until the Stage 8 Flow exists to actually increment/decrement the count.

### 2026-10-13 — No-sale-to-unconverted-Lead: deferred to Stage 9 as a 5th code exception
Decided: can't be a plain validation-rule formula — Salesforce has no native field linking an Account/Opportunity back to the Lead it was converted from, so there's nothing to traverse declaratively. Added as a 5th Stage 9 code exception in BUILD_PLAN.md (Apex or a Flow-maintained tracking field set at conversion time). Not built yet.

Two more build errors hit while finishing Stage 4:
3. **Validation Rule `description` field is capped at 255 characters** (separate limit from the 40-char `fullName` cap hit earlier) — `Showroom_Capacity_Not_Exceeded`'s description was too long on first try; shortened.
4. Same object-folder packaging quirk as before, this time on Showroom__c + Vehicle__c together — deployed both full object folders rather than a slice, which resolved it.

### 2026-10-13 — Stage 4 validation rules, in build order

1. `Instalment_Plan__c.Down_Payment_Min_30_Percent` **(Down Payment % < 30 AND (not Fleet-Corporate OR no Head of Finance sign-off) — US-29, KAN-33)**
2. `Instalment_Plan__c.Term_Cap_12_Months` **(Term in Months > 12 AND (not Fleet-Corporate OR no Head of Finance sign-off) — US-29)**
3. `Instalment_Plan__c.Renegotiation_Term_Cap` **(Original Term set AND Term in Months > Original Term in Months — client handoff fact: "renegotiation cannot exceed the original 12")**
4. `Instalment_Plan__c.Guarantor_Income_Check_Before_Signoff` **(Head of Finance Sign-off = true AND Guarantor's Income Check Done = false — US-29)**
5. `Discount_Request__c.No_Discount_Individual_Instalment` **(Opportunity Payment Mode = Instalment AND Account record type ≠ Fleet-Corporate — US-25, KAN-30)**
6. `Vehicle__c.Per_Model_Stock_Limit_50` **(new record AND Vehicle Model's Total Stock Count ≥ 50 — client handoff fact: "target of up to 50 units per model"; backed by a native Roll-Up Summary since Vehicle→Vehicle Model is Master-Detail)**
7. `Vehicle__c.Showroom_Capacity_Not_Exceeded` **(Showroom + Capacity both set, new record or Showroom changed, Showroom's Vehicle Count ≥ Capacity — Developer/Admin role plan rule; inert until the Stage 8 Flow maintaining Vehicle_Count__c exists)**

### 2026-10-13 — Stage 0 (Org-Wide Defaults) was never built; caught retroactively while starting Stage 5
Jumped straight to Stage 1 at session start, skipping Stage 0 entirely. This mattered concretely for Stage 5: Permission Sets only ADD access on top of OWD — if OWD is too open, a restrictive Permission Set does nothing. Checked our 14 custom objects' `sharingModel` (= OWD for custom objects) against the Design Pack's §3 "Starting Access" table and found 7 wrong, all defaulted to the too-permissive `ReadWrite` instead of what the spec requires:

- Showroom, Vehicle Model, Knowledge Article → should be Public Read Only (`Read`) — fixed
- Guarantor, Reconciliation Entry, Import Request, Customer Message → should be Private — fixed, this one mattered most since Reconciliation Entry wide open directly violated NFR-01 (Finance/Management-only financial data, a Must-Have)
- Legal Escalation → was already correctly Private

Fix note: the Metadata API enum value for "Public Read Only" is literally `Read`, not `PublicReadOnly` — first deploy attempt failed on that.

Standard objects (Opportunity/Lead/Account/Contact/Case) don't have OWD set via these per-object files at all — it lives in org-wide Sharing Settings (Setup → Security → Sharing Settings), a separate mechanism, though it turns out deployable the same way as custom objects (just a `CustomObject` metadata file containing only `<sharingModel>`, no other tags needed, for a standard object).

All 5 now confirmed Private: Opportunity and Lead fixed by Hillary directly in Setup → Security → Sharing Settings; Account and Case finished via metadata deploy after the UI edit didn't take for those two rows. Contact correctly follows Account via ControlledByParent. Stage 0's Org-Wide Defaults are now fully correct across every object in the data model.

### 2026-10-13 — Stage 5: 8 Permission Sets built, one per Security Matrix role
Built Sales Rep, Showroom Manager, Head of Finance, Finance Team, Customer Service Agent, Head of Customer Service, Legal Team, Management — object CRUD matching the Design Pack's Security Matrix (§1), plus field-level grants for the Locked Fields table (§2) where applicable.

**Consistent rule applied across all 8:** where the matrix says "(own)", relied on ownership + Private OWD, no extra grant. Where it doesn't say "(own)" and the object is Lead/Account/Opportunity, relied on role hierarchy (Stage 7) rather than `viewAllRecords`, per the Design Pack's own note ("Showroom Manager sees reps' records via hierarchy"). Everywhere else without "(own)", granted `viewAllRecords` since there's no hierarchy mechanism for our custom objects.

**Four build errors, each revealing a real Salesforce rule:**
1. Descriptions capped at 255 chars (same limit validation rules hit) — shortened two.
2. `modifyAllRecords=true` requires `allowDelete=true` — Salesforce bundles "edit any record" with delete rights at the all-records tier, no way to split them. Since the matrix never grants Delete to anyone, dropped `modifyAllRecords` everywhere rather than grant unwanted delete rights.
3. `allowRead` on Account requires `allowRead` on Contact (Salesforce bundles these). Hit on Legal Team; added Contact Read.
4. `allowRead` on a Master-Detail child requires `allowRead` on its parent — Instalment Plan is Master-Detail to Opportunity, so any role reading Instalment Plan must also read Opportunity. Hit on Legal Team (matrix doesn't list Opportunity for Legal at all); added it as a required technical consequence, not a matrix deviation.

**Real gap surfaced by #2: true "edit records you don't own, without delete rights" needs a Sharing Rule (Read/Write access level), not a Permission Set flag.** This is the *same* mechanism as the already-flagged row-level visibility gaps (Discount Request requester+approver, Legal's own-escalations) — all of it is Sharing Rules territory, not yet built. Current state: Finance Team/Head of Finance/Showroom Manager/Head of CS can **see** all relevant records (`viewAllRecords=true`) but can only **edit** records they personally own until Sharing Rules exist to grant Read/Write across the team.

**Separate, known gap (not fixable via Permission Sets at all):** the Locked Fields requirement to *hide* Opportunity/Instalment Plan amount fields from Customer Service Agent and Head of CS. Permission Sets are purely additive — they can grant visibility but can never take away what a Profile already exposes. True hiding needs either Profile-level Field-Level Security edits (manual, same category as the OWD fix) or Permission Set Groups with a Muting Permission Set. Not built; both Agent-facing permission sets flag this in their own description.

### 2026-10-13 — Validation rules by object (for quick reference alongside Object Manager)
- **Instalment Plan**: Down_Payment_Min_30_Percent, Term_Cap_12_Months, Renegotiation_Term_Cap, Guarantor_Income_Check_Before_Signoff
- **Discount Request**: No_Discount_Individual_Instalment
- **Vehicle**: Per_Model_Stock_Limit_50, Showroom_Capacity_Not_Exceeded
- Every other object: none yet.

### 2026-10-13 — Field-hiding fix attempted via Permission Set Groups + Muting: hit a Metadata API wall
Built a `MutingPermissionSet` (correct root element, correct `<fieldPermissions><field>...<readable>false</readable>` structure once the schema was found by trial) muting the Opportunity/Instalment amount fields, plus two `PermissionSetGroup`s to bundle it with Customer Service Agent / Head of Customer Service. Deployed the muting set successfully, but querying it back via Tooling API showed `Type: Regular`, not a true muting type — Salesforce silently accepted the deploy without actually registering it as muting-capable. The Permission Set Groups then failed to reference it ("permission set names are invalid"), even after the muting set existed in a prior, separate deploy (same-batch dependency resolution issue, confirmed separately).

**Conclusion: Muting Permission Sets appear to only be reliably creatable through the Permission Set Groups UI** (Setup → Permission Set Groups → a group → Muting Permission Sets → New), not as a standalone deployable metadata component referenced from outside. Removed the two Permission Set Group files (never deployed, nothing to clean up server-side). This piece needs to be finished manually in Setup once Stage 7 creates real users to assign it to — the natural point anyway.

### 2026-10-13 — "The heads can delete" — matrix correction (Hillary's call, not a technical finding)
Security Matrix never granted Delete to any role. Corrected at Hillary's instruction: Head of Finance and Head of Customer Service now have `allowDelete=true` + `modifyAllRecords=true` on every object they already had Edit on (Head of Finance: Discount Request, Approval Step, Import Request, Instalment Plan, Instalment, Payment, Reconciliation Entry, Guarantor, Legal Escalation; Head of CS: Case, Customer Message, Knowledge Article). Finance Team and Showroom Manager were deliberately left unchanged — "the heads" means the two Head roles specifically, not their teams.

### 2026-10-13 — Sharing Rules: built where possible, blocked by a hard Salesforce constraint elsewhere
Attempted Sharing Rules for Discount Request's "requester + current approver only" visibility (3 Public Groups: Showroom_Managers, Finance_Team, Head_Office_Approvers, criteria on `Current_Step__c`). **Deploy rejected it outright: "Deploying sharing rule not supported... since OWD is Controlled By Parent."** This is a hard architectural wall, not a syntax issue — `Discount_Request__c` is Master-Detail to Opportunity, which forces `ControlledByParent`, and a `ControlledByParent` object has no independent sharing model to layer rules onto. Same wall applies to Instalment Plan, Instalment, and Payment (also Master-Detail children) — so Finance Team/Showroom Manager's "edit records they don't own" gap on those three specifically can't be closed with Sharing Rules either.

**Decided (Hillary's call): Apex Managed Sharing**, added as Stage 9's 6th code exception, covering both the Discount Request routing and the Master-Detail Finance objects if that gap ever needs closing. Not built yet — documented in BUILD_PLAN.md.

**What WAS buildable and deployed**: the 4 standalone objects (Private OWD, not Master-Detail children) got real Sharing Rules — Finance Team now has Edit access org-wide on Reconciliation Entry, Guarantor, and Legal Escalation; Finance Team and Showroom Manager both have Edit access org-wide on Import Request. 3 Public Groups created: Showroom_Managers, Finance_Team, Head_Office_Approvers (Head_Office_Approvers currently unused pending the Apex sharing work, kept for when that's built).

Two more build errors along the way:
1. `sharingRules` is a **top-level** SFDX metadata folder (`force-app/main/default/sharingRules/`), not nested under `objects/[Object]/sharingRules/` — moved the file once this became clear from a `TypeInferenceError`.
2. Sharing-rule criteria fields are validated against a **restricted field list** specific to the object — `CreatedDate` was rejected ("bad value for restricted picklist field") despite being a real, standard field. Switched to each object's own `Status__c` picklist (`notEqual` blank, matching every record regardless of value) for Reconciliation Entry/Legal Escalation/Import Request, and two explicit rules (`Income_Check_Done__c equals True` / `equals False`) for Guarantor, which has no Status field.

### 2026-10-13 — Stage 6: custom fields don't auto-appear on page layouts when deployed via Metadata API
Checked the auto-generated default layout for Vehicle before building Stage 6 and found it had only `Name`, the Master-Detail field, and system fields — none of the 8 other custom fields we built. This is a general rule, not a Vehicle-specific gap: clicking "New Field" in Setup has an "Add to page layouts" checkbox baked into the wizard; deploying a CustomField via Metadata API has no equivalent, so every one of our 14 custom objects had the same problem. Rebuilt all 14 default layouts from scratch with every field placed (formula/roll-up fields marked Readonly, required fields marked Required).

Standard objects (Opportunity, Case, Lead, Account) had the same issue for the fields we added to them, but their layouts already existed with real content from Shedrack's org setup — surgically inserted a new "AutoDrive [Object] Details" section into each rather than rewriting the whole layout, to avoid disturbing anything already there.

Two build errors: `OneColumn` style layouts must have exactly one `<layoutColumns>` block, not one-with-items plus one-empty (`"Too many columns for section style"`). Related list declarations (`RelatedActivityList` with a `NAME` field) were rejected (`"Invalid field:NAME in related list"`) — dropped related-list declarations from the custom-object layouts entirely rather than keep guessing at valid field names per related-list type; related lists still show by Salesforce's own default behavior, just not customized. Worth revisiting in a later pass if specific related-list field columns matter.

### 2026-10-13 — Stage 7: found 6 of 8 roles already built outside this session
Checked before building anything and found `Showroom_Manager`, `Sales_Rep`, `Finance_Team_Member`, `Head_of_Finance`, `Head_of_Customer_Service`, `Customer_Service_Agent` roles already existed, created by Hillary in Setup on 2026-10-12 evening, not tracked in git. Pulled them into `force-app/main/default/roles/` for version control. Hierarchy: the three top-level roles (Head of Finance, Showroom Manager, Head of Customer Service) all correctly chain up under the org's pre-existing "CEO" role, where Shedrack already sits — sensible, intentional design already in place.

**Naming collision found, not fixed**: the org has a separate, pre-existing demo "Customer Service Agent" role (under a "VP of Customer Service" hierarchy, role ID `00EjV000001KUeHUAW`) with the exact same display name as our AutoDrive one (`00EjY000000065RUAQ`). Two different roles, identical label — confusing in any role-picker dropdown. Used the correct AutoDrive-specific role ID for our test user; the collision itself is unresolved.

Built the two missing roles (Legal_Team, Management) and two Queues (Customer Service on Case, Legal Escalation Recipient on Legal_Escalation__c) to complete the set.

### 2026-10-13 — Stage 7: Henry/Obed/Shedrack are on System Administrator — created separate test users instead
Found the actual discovery-session people (Henry, Obed, Shedrack) already exist as real active Users in the org, but all three are on System Administrator profile — which overrides every validation rule, sharing rule, and permission set built this session. Assigning them our restricted Permission Sets would have changed nothing. Also directly conflicts with Stage 12's explicit instruction to test "as the right persona, never as System Administrator."

**Decided (Hillary's call): created 8 dedicated test users instead of touching the real accounts.** One per role, Standard User profile, correct Role assignment, matching Permission Set:

| Test User | Role | Permission Set |
|---|---|---|
| test.salesrep@autodrive.group3sb.test | Sales Rep | Sales_Rep |
| test.showroommanager@autodrive.group3sb.test | Showroom Manager | Showroom_Manager |
| test.financeteam@autodrive.group3sb.test | Finance Team Member | Finance_Team |
| test.headoffinance@autodrive.group3sb.test | Head of Finance | Head_of_Finance |
| test.csagent@autodrive.group3sb.test | Customer Service Agent (AutoDrive role, not the demo one) | Customer_Service_Agent |
| test.headofcs@autodrive.group3sb.test | Head of Customer Service | Head_of_Customer_Service |
| test.legalteam@autodrive.group3sb.test | Legal Team | Legal_Team |
| test.management@autodrive.group3sb.test | Management | Management |

Checked license headroom before creating (550 total Salesforce licenses, 43 used at the time — plenty of room). All verified correct via SOQL after creation. These are the accounts Stage 12 QA should actually log in as; Henry/Obed/Shedrack's real accounts were left untouched.

### 2026-10-13 — New Stage 4 scope added to BUILD_PLAN.md: discount invalidation on payment-mode switch
BUILD_PLAN.md was updated externally (not by me) to add: if a Discount Request is already Approved while Payment Mode = Full Payment and the customer switches to Instalment, the approval must be invalidated and Finance must reassess separately (Q-O09, confirmed 2026-10-13, Jira KAN-92). This is explicitly called out as **a Flow, not a validation rule** — same story as US-25, so it belongs in Stage 8 even though the plan lists it under the Stage 4 heading. Not built yet; noting so Stage 4 isn't mistaken for fully closed.
