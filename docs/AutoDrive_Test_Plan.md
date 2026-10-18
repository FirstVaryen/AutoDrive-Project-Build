# AutoDrive Test Plan (Stage 12, QA pass)

**Sandbox:** autodrive-dev (Group3SB) · **Data:** the "AD Test…" sample records (`scripts/apex/`) · **Version:** 18 Oct 2026

## How to run it
1. **Log in as the role, never as System Administrator.** Setup → Users → Users → **Login** next to the test user. Log out from the banner when done.
2. Work through that role's table top to bottom. The discount approval case (TC-S5 → TC-M1 → TC-F1 → TC-H1) passes between roles, so keep the role order below.
3. Fill in **Result** (Pass / Fail / Blocked) and **Notes**. For every Fail, add a line to the **Defect log** at the end with what you did, what you expected, what happened, and a screenshot.
4. Lists start on "Recently Viewed". Switch to **All …** to find records.
5. Tests change real records. If a case needs re-running on fresh data, ask for a reset.

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
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-S1 | Tabs | Leads, Accounts, Contacts, Opportunities, Vehicles, Vehicle Models, Showrooms, Discount Requests, Import Requests, Guarantors, Cases, Customer Messages, Knowledge Articles, Reports, Dashboards. **No** Instalment Plans, Payments, Reconciliation | KAN-48 | | |
| TC-S2 | Vehicle Models → AD Test - Honda CR-V | Stock panel **blinks red** (2 / 5). Toyota Corolla shows **green** | KAN-23 | | |
| TC-S3 | Opportunities → AD Test Sale - Direct (no Lead) → Stage Closed Won → Save | **Blocked**: "This sale can't be closed: the customer didn't come from a converted Lead…" | — | | |
| TC-S4 | AD Test Sale - Adaeze Okafor → Closed Won → Save; open her car (Corolla #1) | Saves; car Status = **Sold** | KAN-41 | | |
| TC-S5 | AD Test Sale - Kano Logistics Ltd → Discount Requests → DR-0003 → **Submit for Approval** | Submitted; Current Step **With Showroom Manager** | KAN-43 | | |
| TC-S6 | Try to sell an already Sold car: on Bola's sale try selecting Corolla #1 / any **Sold** vehicle | Blocked or not selectable (Side Flow C) | KAN-41 | | |
| TC-S7 | Leads → New → Channel **Walk-in** → Save | Owner becomes the next free rep (returning/high-profile → Showroom Manager) | KAN-34 | | |
| TC-S8 | Create a discount on an **individual instalment** sale (Chinedu Eze) | **Blocked**: discounts not permitted on instalment deals for individuals | KAN-75 | | |
| TC-S9 | Bola Adeyemi's sale (Full Payment, discount Approved) → Payment Mode **Instalment** → Save | Discount becomes **Invalidated**; Finance emailed. *(Confirms KAN-92 works for a rep, not just admin.)* | KAN-92 | | |
| TC-S10 | Vehicles → New | **No New button** (reps view stock only) | — | | |

## 3. Showroom Manager
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-M1 | Home → Items to Approve → Kano discount → **Approve** | Step → **With Finance**; Step Reached At updates | KAN-45 | | |
| TC-M2 | Vehicles → New → a Camry → Save | Only **New** record type (no New/Used choice); Showroom fills in as Lagos Main | — | | |
| TC-M3 | Open AD Test - Lagos Main → Capacity = current Vehicle Count → Save → add a vehicle | **Blocked**: "The showroom is full…". Set Capacity back to 25 | — | | |
| TC-M4 | Opportunities → All | Sees all of the team's sales | KAN-95 | | |
| TC-M5 | Cases → AD Test - Question about Corolla delivery date | Routed To = **Showroom Manager** | KAN-56 | | |
| TC-M6 | Import Requests → Lagos Ride Hailing's request | Status **Customer Confirmed**, confirmed date filled | KAN-38 | | |

## 4. Finance Team
| ID | Steps | Expected | Jira | Result | Notes |
|---|---|---|---|---|---|
| TC-F1 | Items to Approve → Kano discount → **Approve** | Step → **With Head Office** | KAN-45 | | |
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
| TC-H1 | Items to Approve → Kano discount → **Approve** | Step → **Approved** | KAN-45 | | |
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
