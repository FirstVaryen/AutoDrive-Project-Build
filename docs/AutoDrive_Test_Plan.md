# AutoDrive Test Plan (Stage 12, QA pass)

**Sandbox:** autodrive-dev (Group3SB) · **Data:** the "AD Test…" sample records (`scripts/apex/`) · **Version:** 18 Oct 2026

## How to run it
1. **Log in as the role, never as System Administrator.** Setup → Users → Users → **Login** next to the test user. Log out from the banner when done.
2. Work through that role's table top to bottom. The discount approval (TC-S11 → TC-M1 → TC-F1 → TC-H1 → back to TC-S13) passes between roles, so keep the role order below.
3. Fill in **Result** (Pass / Fail / Blocked) and **Notes**. For every Fail, add a line to the **Defect log** at the end with what you did, what you expected, what happened, and a screenshot.
4. Lists start on "Recently Viewed". Switch to **All …** to find records.
5. Tests change real records. To re-run, make fresh records first (see the Sales Rep section): `scripts/apex/fresh_sales_test_records.apex`.

| Role | Test user | Name shown |
|---|---|---|
| Sales Rep | test.salesrep@autodrive.group3sb.test | TestSales Rep |
| Showroom Manager | test.showroommanager@autodrive.group3sb.test | TestShowroom Manager |
| Finance Team | test.financeteam@autodrive.group3sb.test | TestFinance Team |
| Head of Finance | test.headoffinance@autodrive.group3sb.test | TestHeadOf Finance |
| Customer Service Agent | test.csagent@autodrive.group3sb.test | TestCS Agent |
| Head of Customer Service | test.headofcs@autodrive.group3sb.test | TestHeadOf CustomerService |
| Legal Team | test.legalteam@autodrive.group3sb.test | TestLegal Team |
| Management | test.management@autodrive.group3sb.test | Test Management |

---

## 1. Every role (repeat for each login)
| ID | Check | Expected | Result | Notes |
|---|---|---|---|---|
| TC-A1 | App on login | Opens in **AutoDrive Motors** | | |
| TC-A2 | Home page | The role's own dashboard at the top, then Items to Approve, tasks, recent records | | |
| TC-A3 | Dashboard | Shows figures (not errors); title names this role | | |
| TC-A4 | Tabs | Only the tabs listed for this role in its section below | | |
| TC-A5 | Delete | No **Delete** on vehicles or showroom | | |

## 2. Sales Rep

### Before each run: make fresh records
Closed sales are locked for everyone, so a test that closes a sale can't be undone. Before each run (or any re-run), create a new set of test records:
```
sf apex run -o autodrive-dev -f scripts/apex/fresh_sales_test_records.apex
```
It prints a stamp, e.g. `AD Rerun 1018-0943`. Below, **`<stamp>`** means that stamp. Each run creates, owned by TestSales Rep:
| Record | Used by |
|---|---|
| **AD Rerun `<stamp>` Sale 1 (open)**: Full Payment, at Offer, customer came from a Lead | TC-S9, TC-S10, TC-S14, TC-S15 |
| **AD Rerun `<stamp>` Sale 2 (discount approved)**: Full Payment, 7.5% discount already approved by all three approvers | TC-S12, TC-S16 |
| **AD Rerun `<stamp>` Sale 3 (open)**: third open Full Payment sale | TC-S11 |
| **AD Rerun `<stamp>` Lead**: open lead at New | TC-S7, TC-S8 |

Run the tests in the order listed. Each one says which record it uses.

### Navigation and dashboard
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S1 | Look at the tab bar | Home, Leads, Accounts, Contacts, Opportunities, AM Vehicles, AM Vehicle Models, AM Discount Requests, AM Import Requests, Reports, Dashboards. **No** Showrooms, Guarantors, Cases, Customer Messages, Knowledge, Instalment Plans, Payments, Reconciliation | KAN-48 | | |
| TC-S2 | Home page dashboard | Four tiles, no errors: Leads by Status, Leads by Channel, Deals in Pipeline by Stage, Deals Won This Month | KAN-69 | | |
| TC-S3 | Opportunities → list view picker | **All Open Opportunities**, **AutoDrive - Closed Won**, **AutoDrive - Closed Lost** exist; closed sales only appear in the closed lists. *(Tip: pin Open Deals with the pin icon so it opens by default.)* | — | | |

### Stock
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S4 | AM Vehicle Models → **AD Test - Honda CR-V** | Stock Level panel **blinks red**; **AD Test - Toyota Corolla** shows green; the model page lists its Vehicles | KAN-23 | | |
| TC-S5 | On any model page click **All Vehicle Models** (Stock Level panel) | Returns to the full model list | — | | |
| TC-S6 | AM Vehicles → New | **No New button** (reps view stock only) | — | | |

### Leads
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S7a | Leads → New → name, Customer Type Individual, **no phone, no email** → Save | **Blocked**: "Add the customer's phone number or email address…" | — | | |
| TC-S7b | Leads → New → Phone **+2348010000001** (an existing customer) → Save | Warning banner: "This phone number or email already belongs to someone in AutoDrive…" with a link to the match; Save still possible | — | | |
| TC-S7c | Leads → New → new phone, Channel **Walk-in**, Customer Type Individual → Save. Repeat with **Returning or High-profile** ticked (AutoDrive Lead Details) | First: owner = next free rep. Second: owner = Showroom Manager | KAN-34 | | |
| TC-S8a | Open **AD Rerun `<stamp>` Lead** → clear Visit Purpose → **Convert** (creating a sale) | **Blocked**: asks for Visit Purpose (and, for a sale, the Vehicle of Interest) to be filled on the lead | — | | |
| TC-S8b | Same lead → set Visit Purpose and a Vehicle of Interest (Contacted step on the path) → **Convert** | Converts; the new sale starts at **Viewing / Test Drive**; the lead path shows only New → Contacted → Converted | — | | |

### Discounts
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S9 | **Sale 1** → Discount Requests → New → Discount Rate **4%**, Reason → Save | Saved as **Approved**, **Auto-approved** ticked, Approved On filled; no approval needed. Requested By and Step filled automatically and read-only | KAN-43 | | |
| TC-S10 | **Sale 1** → Discount Requests → New → leave Discount Rate empty → Save | **Blocked**: "Choose a Discount Rate…" | — | | |
| TC-S11 | **Sale 3** → Discount Requests → New → Discount Rate **10%** → Save; then try to change Sale 3's Stage | Request goes to **With Showroom Manager** (submitted automatically). Stage change **blocked**: "This sale has a discount request waiting for approval…". *(This request is the one Showroom Manager, Finance and Head of Finance approve in TC-M1, TC-F1, TC-H1.)* | KAN-45 | | |
| TC-S12 | **Sale 2** → Discount Requests list (right-hand side) | Shows Requested %, Step **Approved**, **Approved By**, **Approved On** | — | | |
| TC-S14 | **Sale 1** → Payment Mode **Instalment** → Save → Discount Requests → New → 2% | **Blocked**: discounts aren't allowed on instalment deals for individual customers (US-25). Set Payment Mode back to Full Payment afterwards | KAN-75 | | |

### Closing and locking
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S15 | **Sale 1** → Stage **Closed Won** → Save; open its vehicle | Saves; Close Date = today; vehicle Status **Sold**. Then change Stage / Close Date / Amount → **blocked**: "This sale is closed and can't be changed…" | KAN-41 | | |
| TC-S16 | **Sale 2** → Payment Mode **Instalment** → Save | Its approved discount becomes **Invalidated**; Finance emailed | KAN-92 | | |
| TC-S17 | **Sale 2** (now Instalment) → Stage **Closed Won** | **Blocked**: "An instalment sale can only be closed once Finance has recorded the down payment and the Head of Finance has signed off the instalment plan…" | — | | |
| TC-S18 | Any open sale → click the AM Vehicle field → search a sold car (e.g. **Corolla #1**) | Not offered; only available/reserved cars | KAN-41 | | |
| TC-S19 | Any open sale → AM Vehicle → search **Land Cruiser** | **No vehicles** (model out of stock) → Import Requests → New for **AD Test - Toyota Land Cruiser** saves | KAN-38 | | |

## 3. Showroom Manager
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-M1 | Home → Items to Approve → the **10% request on AD Rerun `<stamp>` Sale 3** (from TC-S11) → **Approve** | Step → **With Finance**; Step Reached At updates | KAN-45 | | |
| TC-M2 | Vehicles → New → a Camry → Save | Only **New** record type (no New/Used choice); Showroom fills in as Lagos Main | — | | |
| TC-M3 | Open AD Test - Lagos Main → Capacity = current Vehicle Count → Save → add a vehicle | **Blocked**: "The showroom is full…". Set Capacity back to 25 | — | | |
| TC-M4 | Opportunities → All | Sees all of the team's sales | KAN-95 | | |
| TC-M5 | Cases → AD Test - Question about Corolla delivery date | Routed To = **Showroom Manager** | KAN-56 | | |
| TC-M6 | Import Requests → Lagos Ride Hailing's request | Status **Customer Confirmed**, confirmed date filled | KAN-38 | | |

## 4. Finance Team
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-F1 | Items to Approve → the Sale 3 discount → **Approve** | Step → **With Head Office** | KAN-45 | | |
| TC-F2 | Open any Discount Request | View only, **no Edit** | KAN-44 | | |
| TC-F3 | Chinedu Eze's sale → Payments → New: Instalment = the **Late** one, 2,625,000, Bank Transfer | Instalment Amount Paid = 2,625,000; sale Total Paid rises by 2,625,000; Balance falls | KAN-32 | | |
| TC-F4 | Chinedu's Instalment Plan → Term **18** → Save | **Blocked** (12-month cap) | KAN-33 | | |
| TC-F5 | Reconciliation Entries → All | Matched, **Flagged** (Funke, 66,667 short) and **Explained** entries visible | KAN-12 | | |
| TC-F6 | Vehicles / Vehicle Models | View only, no Edit | KAN-31 | | |
| TC-F7 | Search for a Legal Escalation (AD-TEST-0001) | **Not found / no access** | KAN-85 | | |
| TC-F8 | Instalments → All | Late instalment shows **Late**; Days Late filled | KAN-14 | | |

## 5. Head of Finance
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-H1 | Items to Approve → the Sale 3 discount → **Approve** | Step → **Approved** | KAN-45 | | |
| TC-H2 | Chinedu's Instalment Plan → tick **Head of Finance Sign-off** → Save | Saves (guarantor income checked) | KAN-33 | | |
| TC-H3 | Kano sale → Instalment Plans → New: Guarantor Ngozi Eze, Down 20%, Term 12, **sign-off unticked** | **Blocked** (30% minimum) | KAN-26 | | |
| TC-H4 | Same as TC-H3 with sign-off **ticked** | Saves (fleet exception) | KAN-26 | | |
| TC-H5 | Funke Ayo's plan → Ownership Documents Status → **Sent** → Save | **Documents Status Changed** fills with now | KAN-100 | | |
| TC-H6 | Legal Escalations → AD-TEST-0001 → change Status → Save | Saves (Head of Finance can update) | KAN-85 | | |
| TC-H7 | From an Instalment Plan 90+ days late, run **Raise Legal Escalation** | Escalation created; Legal emailed. *(Needs a plan 90+ days late; ask for test data if none.)* | KAN-86 | | |

## 6. Customer Service Agent
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-C1 | Tabs | Accounts, Contacts, Opportunities, Vehicles, Vehicle Models, Showrooms, Instalment Plans, Cases, Customer Messages, Knowledge Articles, Reports. **No** Discount Requests or Dashboards tab | — | | |
| TC-C2 | Cases → New: Type **Payment**, subject "Paid but not showing" | Routed To = **Finance** | KAN-56 | | |
| TC-C3 | On that case add a Customer Message, Type **Acknowledgement** | Case **First Response At stays blank** | KAN-64 | | |
| TC-C4 | Add another Customer Message, Type **Status Update** | **First Response At** fills | KAN-64 | | |
| TC-C5 | Close that case | **Resolved At** fills; **CSAT Requested At** fills | KAN-28 | | |
| TC-C6 | Create a case and leave it 1 hour with no reply | Priority → **High**; Escalated To = Head of Customer Service | KAN-58 | | |
| TC-C7 | Open Chinedu Eze's Instalment Plan | View only; **amount fields hidden** *(after the KAN-49 muting step)* | KAN-50 | | |
| TC-C8 | Search "DR-" | No discount requests found | KAN-44 | | |
| TC-C9 | Knowledge Articles → open a Published article | Readable; no Edit | KAN-96 | | |

## 7. Head of Customer Service
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-HC1 | Cases → All | Sees the agents' cases, incl. **Escalated** "ownership documents" case | KAN-94 | | |
| TC-HC2 | Knowledge Articles → Draft "Ordering a model that is out of stock" → Status **Published** | Saves (maintains the knowledge base) | KAN-96 | | |
| TC-HC3 | Open any sale | Sale amounts **visible** (muting applies to agents only) | KAN-49 | | |

## 8. Legal Team
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-L1 | Tabs | Only Accounts, Contacts, Opportunities, Instalment Plans, Guarantors, Legal Escalations, Reports | — | | |
| TC-L2 | Legal Escalations → All | Both escalations visible (AD-TEST-0001, 0002) | KAN-85 | | |
| TC-L3 | Open AD-TEST-0001 | View only, **no Edit**; linked plan and guarantor open | KAN-85 | | |
| TC-L4 | Try Payments / Reconciliation | No access | — | | |

## 9. Management
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-G1 | Opportunities → All | All 9 sales; **no Edit** | — | | |
| TC-G2 | Discount Requests → All | All 3 visible, read only | KAN-44 | | |
| TC-G3 | Legal Escalations → All | Both visible, read only | KAN-85 | | |
| TC-G4 | Vehicle Models | CR-V and Kia Sportage **blink** | KAN-23 | | |

## 10. Automatic / time-based (check the next day)
| ID | What | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-T1 | Instalment due in 3 days (Funke Ayo) | Reminder email sent the morning it's 3 days out; skipped if already paid | KAN-66 | | |
| TC-T2 | Instalment 1 / 7 / 30 days late (Chinedu) | Missed-payment email (day 1), guarantor notice logged on the account (day 7), default flag (day 30) | KAN-53 | | |
| TC-T3 | Discount request waiting > 1 business day at Showroom Manager | One reminder email to the Showroom Manager; not repeated for the same step | KAN-45 | | |
| TC-T4 | Pay the last instalment of a plan | Completion email once; never re-sent | KAN-88 | | |
| TC-T5 | Email to the support address | Case created, Origin Email, owner Customer Service queue | KAN-56 | | |

> Emails only send once the **Automated Process user email** is set in Setup → Process Automation Settings.

---

## Defect log
| # | Test ID | Role | What I did | Expected | What happened | Screenshot | Found by | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | |
