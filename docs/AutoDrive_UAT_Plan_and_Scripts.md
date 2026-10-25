# AutoDrive Motors – UAT Plan and Test Scripts

User acceptance testing for the AutoDrive Motors Salesforce build (TAP Group 3). It checks that the system does what AutoDrive asked for, using the business goals, requirements and user stories in the v8 workbook (`AutoDrive_Requirements_UserStories_v8.xlsx`). Every script is written in plain words and is run as the user it is meant for, never as an administrator.

**How to use this document**
1. Section 9 lists every user story and its persona.
2. Each tester only needs section 7 (how to run a script) and their own scripts in section 10.
3. Record results in the **Actual** and **Pass/Fail** columns. Record problems in the defect log (section 11).

---

## 1. Purpose and business goals

**Purpose.** Confirm that each requirement works for the person who will use it, and decide whether AutoDrive can sign off the build.

| Goal | What the business wants |
|---|---|
| O1 Operational visibility | One connected view of customers, vehicles, sales, finance and service |
| O2 Process consistency and control | Clear processes, owners and business rules that the system enforces |
| O3 Less manual follow-up | Approvals, payments, reminders and issues tracked by the system |
| O4 Management visibility | Timely figures on stock, sales, finance and service |
| O5 Adoption and handover | A solution people understand and can run |

| Area | What it covers | Stories |
|---|---|---|
| A. Enquiries and prospects | Website, walk-in and social enquiries, qualifying, assigning reps | US-11, US-23, US-30, US-31, US-32 |
| B. Vehicles and stock | Live availability, sold status, low stock, imports, Finance view of stock | US-01, US-07, US-12, US-26, US-38 |
| C. Sales and discounts | Discount approvals, fleet customers, no discount on instalments, vehicle change | US-02, US-08, US-16, US-20, US-25, US-39 |
| D. Finance and payments | Payments, part and extra payments, instalment rules, reminders, late and default, reconciliation, legal, completion | US-03, US-05, US-09, US-15, US-17, US-19, US-28, US-29, US-36, US-37 |
| E. Customer service | Logging and routing requests, reference numbers, history, escalation, response times, satisfaction, knowledge base | US-04, US-06, US-10, US-13, US-14, US-18, US-22, US-24, US-33, US-34, US-35 |
| F. Management | One dashboard for the whole business | US-21 |

---

## 2. Scope

**In scope**
- Every user story in the v8 workbook with a MUST, SHOULD or COULD priority, tested by its persona.
- The business rules the build enforces: 30% minimum down payment, 12-month maximum (including after renegotiation), guarantor before sign-off, Head of Finance sign-off before monthly payments, one down payment per sale, no discount on instalment sales, approval above 5%, the 3-day reminder, 1/7/30-day late steps, legal escalation after 90 days.
- What each role can and cannot see or change (security matrix).
- Two end-to-end journeys: a sale from website enquiry to first monthly payment, and a complaint from the website to closure.

**Out of scope (agreed)**
- More than one showroom, used vehicles, sales commission.
- Text (SMS) and WhatsApp messages. Reminders and notices are sent by email only (team decision, 18 Oct 2026).
- Vehicle handover and ownership documents (workbook "Won't Have"). Only the Ownership Documents Status field is tested.
- Customer logins. Customers use the website forms and email only.
- Rep incentive for selling above list price (US-27, retired to Won't Have).
- Performance, load and data migration testing.

---

## 3. Where the testing happens

- **Environment:** Salesforce sandbox **Group3SB**, in the **AutoDrive Motors** app, on a desktop browser.
- **Website:** https://dk1791276250211--group3sb.sandbox.my.site.com/s/ (open it in a private or incognito window).
- **How to test as a user:** the UAT coordinator opens Setup → Users and clicks **Login** next to the test user. A blue banner shows who you are. Click **Log out as …** in the banner to return.
- **Evidence:** a screenshot for every failed step, and for the key result of every script.
- **Finding a record:** lists open on *Recently Viewed*. Click the list name and choose **All**, or use the search bar at the top.

---

## 4. Testers

| Role | Test user (login) | Tester | Scripts they run |
|---|---|---|---|
| Customer (website) | No login, private window | Henry | Website enquiry and support request |
| Front Desk | Front Desk Staff test user | Henry | Walk-in enquiries |
| Social Media Handler | Social Media Handler test user | Henry | Instagram enquiries |
| Sales Rep | test.salesrep@autodrive.group3sb.test | Henry | Leads, sales, discounts, fleet, imports, vehicle change |
| Showroom Manager | test.showroommanager@autodrive.group3sb.test | Henry | Prospects, stock, low-stock alert, first discount approval |
| Finance Team | test.financeteam@autodrive.group3sb.test | Obed | Plans, payments, imports, Finance approvals |
| Head of Finance | test.headoffinance@autodrive.group3sb.test | Obed | Sign-off, rules, final approval, reconciliation, legal |
| Legal Team | test.legalteam@autodrive.group3sb.test | Obed | Viewing legal escalations |
| Customer Service Agent | test.csagent@autodrive.group3sb.test | Shedrack | Cases, customer history, knowledge base |
| Head of Customer Service | test.headofcs@autodrive.group3sb.test | Shedrack | Case overview, escalation, times, satisfaction, articles |
| Management | test.management@autodrive.group3sb.test | Sponsor | Dashboard, read-only checks |
| UAT coordinator (facilitator) | Admin | Hillary | Logs in as users, prepares data, records results and defects |
| Business sponsor (AutoDrive) |  |  | Watches, accepts results, signs off |

---

## 5. Test data

Load before testing. Do not change it between runs except by running the scripts. Customer emails that should reach a tester use the tester's own inbox.

**Customers**

| ID | Record | Details |
|---|---|---|
| TD-01 | Returning customer | **Daniel Okoro** (contact, email ewryen@gmail.com), with past enquiries and a case |
| TD-02 | Fleet customer | **Lagos Ride Hailing Ltd** (Fleet/Corporate account), with an Agreed Discount Rate |
| TD-03 | Fleet customer | **Kano Logistics Ltd** (Fleet/Corporate account) |
| TD-04 | New walk-in | A new person typed in during the test, e.g. **Amina Sule**, phone 0802 555 0101 |
| TD-05 | Website visitor | The tester's own name and email, typed into the website forms |

**Vehicles and stock**

| ID | Record | Details |
|---|---|---|
| TD-10 | Models with stock | Toyota Corolla 2026, Kia Sportage 2026, Toyota Hilux 2026, Honda CR-V 2026 (several cars Available each) |
| TD-11 | Model for the low-stock test | Any model; the tester sets its Low Stock Threshold above its Available Stock |
| TD-12 | Model with no stock | A model with no Available cars, for the import request |

**Sales (fresh set)**
Run `scripts/apex/fresh_sales_test_records.apex` before a round. It creates, owned by the Sales Rep: **Sale 1 (open, full payment, at Offer)**, **Sale 2 (7.5% discount approved)**, **Sale 3 (open)** and an open **Lead**, all named "AD Rerun <date> …".

**Instalment customers** (`scripts/apex/instalment_test_plans.apex`; every plan follows all the rules)

| ID | Customer | Set up for |
|---|---|---|
| TD-20 | **Chiamaka Okonkwo** | On track; Month 1 due in a few days (3-day reminder; part and extra payment). Email: tester's inbox |
| TD-21 | **Segun Ajayi** | Month 2 due today (full payment; or missed-payment notice the next day if not paid) |
| TD-22 | **Emmanuel Udo** | Last month due (plan completion and completion email) |
| TD-23 | **Hauwa Lawal** | Deposit paid, waiting for Head of Finance sign-off |
| TD-24 | **Funke Ayo** | One month about 7 days late (late list; guarantor notice) |
| TD-25 | **Folake Ogunleye** | One month 30+ days late, alert not sent yet (default alert the next morning) |
| TD-26 | **Suleiman Bello** | Defaulted, a month unpaid for 90+ days (legal escalation) |
| TD-27 | **Zainab Bello** | Plan created, deposit not paid yet (waiting for deposit) |
| TD-28 | **Ngozi Okeke** | Signed off, on track, car reserved |

**Cases:** created during the tests from the website (section 10, UAT-E-01).

**Overnight jobs.** Some results only appear after the automatic morning jobs run (marked **(next day)**): marking late, the 3-day reminder, the 1/7/30-day notices, the low-stock alert, the daily plan refresh.

---

## 6. Entry criteria

Testing starts only when all of these are true. The coordinator ticks each one.

- [ ] The sandbox is **frozen**: no one changes the setup during a round, except to fix a logged defect.
- [ ] Every test user in section 4 exists, can log in, and has the right profile and permission set group.
- [ ] Test data in section 5 is loaded.
- [ ] Every flow, validation rule and approval process in scope is **Active**.
- [ ] Email is switched on: Setup → Deliverability → Access level = **All email**.
- [ ] Each tester has their scripts.
- [ ] Smoke test passed: each test user logs in, opens the AutoDrive Motors app and sees their tabs.
- [ ] No open Critical defect.
- [ ] The defect log (section 11) is ready, with Hillary as the owner for triage.

---

## 7. How to run a script

1. Log in as the user named in the script. Never as an administrator, unless the script says so.
2. Follow the steps in order. Do not skip.
3. After each step, compare what you see with **Expected**. Write what you actually saw in **Actual**.
4. Mark the step **Pass** or **Fail**. The script passes only if every step passes.
5. For a failure: take a screenshot, note the script ID and step number, and tell the coordinator, who logs a defect.
6. After a defect is fixed, run the **whole** script again (next round). Only the tester closes a defect.

**Defect severity**

| Severity | Meaning | Example |
|---|---|---|
| Critical | A business rule is broken, or work cannot continue | A car can be sold twice; Finance can sign off a plan |
| High | A MUST story fails, with no workaround | A discount above 5% is not sent for approval |
| Medium | Works wrongly, but there is a workaround | A list shows the wrong column |
| Low | Wording, layout or cosmetic | A typo on a label |

**Defect or change request?** A defect is when the system does not do what was agreed. A change request is something new or different from what was agreed (for example "can it also text the customer?"). Change requests are logged as **CR-xx** and decided later; they do not block sign-off.

---

## 8. Exit criteria

Testing ends, and sign-off is requested, when all of these are true:

- Every script in scope has been run and its result recorded. Blocked scripts are listed with the reason and a date.
- **100%** of MUST scripts have passed.
- At least **90%** of SHOULD and COULD scripts have passed, and the rest have an agreed plan.
- No open **Critical** or **High** defects.
- Every Medium and Low defect is fixed, or accepted in writing by AutoDrive with a fix date.
- Every business rule in section 2 has been proved at least once.
- Both end-to-end scripts have passed.
- The results summary (section 11) is complete and the sign-off table is signed.

If not met, testing continues after fixes, and only the failed and affected scripts are run again.

---

## 9. Script index (all user stories)

| Script | Story | Scenario | Priority | Persona | Built |
|---|---|---|---|---|---|
| UAT-B-01 | US-01 | A car shows Sold as soon as the sale closes, and can't be sold again | MUST | Sales Rep | ✔ |
| UAT-C-01 | US-02 | See where a discount approval sits | MUST | Sales Rep, Showroom Manager | ✔ |
| UAT-D-01 | US-03 | A payment is recorded once and balances update themselves | MUST | Finance Team | ✔ |
| UAT-E-02 | US-04 | Agent sees the customer's history, not payment amounts | MUST | CS Agent | ✔ |
| UAT-D-02 | US-05 | One list of late and defaulting customers | MUST | Head of Finance | ✔ |
| UAT-E-01 | US-06 | A request from any channel becomes a case and goes to the right team | MUST | Customer, CS Agent | ✔ |
| UAT-B-02 | US-07 | Rep sees live availability before talking to a customer | MUST | Sales Rep | ✔ |
| UAT-C-02 | US-08 | Finance sees which approvals are waiting for them | MUST | Finance Team | ✔ |
| UAT-D-03 | US-09 | Bank total compared with recorded payments | MUST | Head of Finance | ✔ |
| UAT-E-03 | US-10 | Head of CS sees every case's owner and status | MUST | Head of CS | ✔ |
| UAT-A-01 | US-11 | A website enquiry reaches an online rep automatically | MUST | Customer, Sales Rep | ✔ |
| UAT-B-03 | US-12 | Low-stock alert for a model | SHOULD | Showroom Manager | ✔ |
| UAT-E-04 | US-13 | First response and resolution times recorded | SHOULD | Head of CS | ✔ |
| UAT-E-05 | US-14 | Agent searches the knowledge base | SHOULD | CS Agent | ✔ |
| UAT-D-04 | US-15 | Reminder 3 days before a payment is due | SHOULD | Finance Team | ✔ |
| UAT-C-03 | US-16 | A fleet customer's information in one place | SHOULD | Sales Rep | ✔ |
| UAT-D-05 | US-17 | Alert when a customer first defaults | SHOULD | Finance Team | ✔ |
| UAT-E-06 | US-18 | Head of CS maintains articles | SHOULD | Head of CS | ✔ |
| UAT-D-04 | US-19 | Customer gets a reminder before payment is due | SHOULD | Customer | ✔ |
| UAT-C-04 | US-20 | A fleet customer's agreed rate applies automatically | SHOULD | Sales Rep | ✔ |
| UAT-F-01 | US-21 | One dashboard for sales, stock, finance and service | COULD | Management | ✔ |
| UAT-E-07 | US-22 | Satisfaction score 1 to 10 on a closed case | SHOULD | CS Agent | ✔ |
| UAT-A-02 | US-23 | Same qualifying questions for every walk-in | SHOULD | Front Desk / Sales Rep | ✔ |
| UAT-E-07 | US-24 | Satisfaction trend over time | SHOULD | Head of CS | ✔ |
| UAT-C-05 | US-25 | No discount on an instalment sale | SHOULD | Sales Rep | ✔ |
| UAT-B-04 | US-26 | Finance sees stock, models and list prices (read only) | SHOULD | Head of Finance | ✔ |
| UAT-D-06 | US-28 | Part, short and extra payments | SHOULD | Finance Team | ✔ |
| UAT-D-07 | US-29 | Instalment rules: 30% down, 12 months, guarantor, sign-off | SHOULD | Finance Team, Head of Finance | ✔ |
| UAT-A-03 | US-30 | Walk-in goes to the next free rep, without duplicates | SHOULD | Front Desk | ✔ |
| UAT-A-04 | US-31 | Instagram enquiries with no visit booked are listed | SHOULD | Social Media Handler | ✔ |
| UAT-A-05 | US-32 | Manager sees where deals are stuck | SHOULD | Showroom Manager | ✔ |
| UAT-E-08 | US-33 | An unanswered case escalates itself after 1 hour | SHOULD | Head of CS | ✔ |
| UAT-E-01 | US-34 | Customer gets a reference number for their request | SHOULD | Customer | ✔ |
| UAT-E-09 | US-35 | Customer is told when their case changes | SHOULD | CS Agent | ✔ |
| UAT-D-08 | US-36 | Unrecoverable default escalated to Legal | SHOULD | Head of Finance, Legal | ✔ |
| UAT-D-09 | US-37 | Completion email when the plan is paid off | COULD | Finance Team | ✔ |
| UAT-B-05 | US-38 | Import request when a model is out of stock | SHOULD | Sales Rep, Showroom Manager, Finance | ✔ |
| UAT-C-06 | US-39 | Change vehicle or payment type before collection | SHOULD | Sales Rep, Head of Finance | ✔ |
| UAT-S-01 | Security | Each role sees only its own tabs and actions | MUST | Each role | ✔ |
| UAT-S-02 | Security | Locked actions: only the right person can sign off, approve or edit | MUST | Several | ✔ |
| UAT-E2E-01 | Journey | Website enquiry to sale, deposit, sign-off, car sold and first payment | MUST | Several | ✔ |
| UAT-E2E-02 | Journey | Website complaint to case closed and measured | MUST | Several | ✔ |

---

## 10. The scripts

Each script has a header, then a step table. **Actual** and **Pass/Fail** stay empty until the script is run.

### A. Enquiries and prospects

#### UAT-A-01: A website enquiry reaches an online rep automatically (US-11)
**Traces:** Goal O3 · Story US-11 · Criterion: a new enquiry is assigned to an available rep without anyone noticing it first. **Tester:** Customer (website), then Sales Rep. **Scenario:** A customer asks about a car on the website after hours of searching; a rep who is logged in gets it straight away. **Test data:** TD-05, a car from TD-10.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | As the Sales Rep, log in and stay logged in | The rep's Home page opens | | |
| 2 | In a private window, open the website and fill in **Sales enquiry** with your name, phone or email, and a car. Submit | A thank-you message shows | | |
| 3 | Wait up to 5 minutes. As the Sales Rep, open **Leads → My Leads** | The enquiry is there, owned by the rep, Channel = Web, with the chosen car and **Auto Assigned At** filled in | | |
| 4 | Check the rep's email or notifications | A "lead assigned to you" message | | |

#### UAT-A-02: Same qualifying questions for every walk-in (US-23)
**Traces:** Goal O2 · Story US-23 · Criterion: every walk-in is asked the same questions, and the answers are saved. **Tester:** Front Desk (or Sales Rep). **Scenario:** A new customer walks in. **Test data:** TD-04 Amina Sule.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → New**. Enter name, phone, Channel = **Walk-in** | The form shows Qualification Answers, Visit Purpose and Vehicle Model of Interest | | |
| 2 | Fill in the qualifying answers and Visit Purpose = Purchase, pick a model, save | The lead saves | | |
| 3 | As the Sales Rep, open the lead and click **Convert** with Visit Purpose cleared | Conversion is refused until the purpose (and for a purchase, the vehicle) is filled in | | |

#### UAT-A-03: Walk-in goes to the next free rep, without duplicates (US-30)
**Traces:** Goal O2, O3 · Story US-30 · Criterion: a walk-in is assigned to a rep automatically; a returning or high-profile customer goes to the manager; the same person isn't entered twice. **Tester:** Front Desk. **Test data:** TD-04 (new), TD-01 Daniel Okoro (returning).

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Create a new walk-in lead for a new person, save | **Lead Owner** is a sales rep, picked automatically | | |
| 2 | Create a lead for **Daniel Okoro** with his existing phone number | A warning that a matching record already exists | | |
| 3 | Create a walk-in lead marked returning or high profile | It goes to the Showroom Manager, not a general rep | | |

#### UAT-A-04: Instagram enquiries with no visit booked (US-31)
**Traces:** Goal O3 · Story US-31 · Criterion: social enquiries without a booked visit can be followed up from one list. **Tester:** Social Media Handler. **Test data:** a new Instagram enquiry.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → New**, Channel = **Instagram**, no Booked Visit Date, save | It saves | | |
| 2 | Open **Leads → AutoDrive - Enquiries No Visit Booked** | The new enquiry is listed | | |
| 3 | Enter a Booked Visit Date on it, save, open the list again | It is no longer listed | | |

#### UAT-A-05: Manager sees where deals are stuck (US-32)
**Traces:** Goal O4 · Story US-32 · Criterion: one view of open prospects with source, rep and stage. **Tester:** Showroom Manager.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → AutoDrive - Open Prospects** | Each open lead shows channel, owner and status | | |
| 2 | **Leads → AutoDrive - Prospects With No Rep** | Leads without a rep (if any) | | |
| 3 | **Opportunities → All Open Opportunities** | Each open sale shows owner, stage and approval status | | |

### B. Vehicles and stock

#### UAT-B-01: A sold car shows Sold at once and can't be sold again (US-01)
**Traces:** Goal O1, O2 · Story US-01 · Criterion: when a sale closes, the car's status changes with no one editing it. **Tester:** Sales Rep. **Test data:** Sale 1 and Sale 3 (fresh set).

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AD Rerun … Sale 1 (open)**, note the vehicle | The vehicle shows Available or Reserved | | |
| 2 | Set Stage to **Closed Won**, save, then click the vehicle | Status is **Sold**; nobody edited the car | | |
| 3 | Open **Sale 3**, edit **Vehicle** and search for the car from step 2 | The sold car is not offered | | |
| 4 | Open a sale where the deposit is paid (TD-28 Ngozi), note its car; on another open sale try to pick that car | Refused: "That car is reserved for another customer's sale…" | | |

#### UAT-B-02: Live availability (US-07)
**Traces:** Goal O1 · Story US-07. **Tester:** Sales Rep.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Vehicles → All** | Every car shows Available, Reserved or Sold, with model, colour and year | | |
| 2 | Try to edit a car | The rep can view but not change it | | |

#### UAT-B-03: Low-stock alert (US-12)
**Traces:** Goal O3, O4 · Story US-12 · Criterion: the manager is told once when a model drops below its threshold. **Tester:** Showroom Manager. **Test data:** TD-11.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a Vehicle Model, set **Low Stock Threshold** above its Available Stock, save | It saves | | |
| 2 | **(next day)** check the bell | One low-stock notification for that model | | |
| 3 | Open **Vehicle Models → AutoDrive - Low Stock** | The model is listed | | |
| 4 | **(day after)** check the bell again | No repeat alert for the same model | | |

#### UAT-B-04: Finance sees stock, models and prices (US-26)
**Traces:** Goal O1 · Story US-26. **Tester:** Head of Finance.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AM Vehicles** and **Vehicle Models** | Stock and list prices are visible | | |
| 2 | Try to edit a car or a price | Not allowed (read only) | | |
| 3 | Open **AutoDrive - Models With No List Price** | Models missing a price are listed (if any) | | |

#### UAT-B-05: Import request when a model is out of stock (US-38)
**Traces:** Goal O1, O3 · Story US-38 · Criterion: the request is recorded against the customer and model; Finance and head office see it; stock goes up when the cars arrive; the rep is told. **Tester:** Sales Rep, then Showroom Manager, then Finance Team. **Test data:** TD-12.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | As the rep, on a customer, **Import Requests → New**. Pick the model, Quantity 2, Reason = Out of stock. Save | Saves as Requested; Requested By is the rep | | |
| 2 | Try to save one without a reason | Refused, with a message | | |
| 3 | As Finance, open the request and move it on step by step to **Imported** | Each step saves | | |
| 4 | Open the model | Available Stock has gone up by 2 (new cars named IMP-…) | | |
| 5 | As the rep, check notifications / email | A notice that the cars arrived | | |

### C. Sales and discounts

#### UAT-C-01: See where a discount approval sits (US-02)
**Traces:** Goal O2, O3 · Story US-02 · Criterion: each approval shows its current step and when it reached it; 5% or less is approved at once. **Tester:** Sales Rep, then Showroom Manager. **Test data:** Sale 1 and Sale 3.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | As the rep, on Sale 1 click **Request Discount**, rate 5%, give a reason | Approved straight away (Auto Approved ticked) | | |
| 2 | On Sale 3, request **7.5%** with a reason | Current Step = **With Showroom Manager**, with the date and time | | |
| 3 | Open the request | It shows the customer, each vehicle with its own list price, the total, the discount value and the price after discount | | |
| 4 | As the Showroom Manager, **Home → Items to Approve**, approve it | Step moves to **With Finance**, new date and time; the sale's Approval Status updates | | |
| 5 | Request another above 5% and have the manager **Reject** it | The rep sees Rejected on the sale | | |

#### UAT-C-02: Finance sees what is waiting for them (US-08)
**Traces:** Goal O3 · Story US-08. **Tester:** Finance Team, then Head of Finance.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | As Finance, **Home → Items to Approve** | The request from UAT-C-01 step 4 is listed with its date | | |
| 2 | Approve it | Step moves to **With Head Office** at once | | |
| 3 | As the Head of Finance, approve it | Status **Approved**; Approved By and Approved On filled in | | |

#### UAT-C-03: A fleet customer's information in one place (US-16)
**Traces:** Goal O1 · Story US-16. **Tester:** Sales Rep. **Test data:** TD-02 Lagos Ride Hailing Ltd.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Lagos Ride Hailing Ltd** | Contact person, agreed discount rate, owner and past sales on one page | | |
| 2 | On an open fleet sale, **Add Fleet Vehicles**: pick a type and how many | That many identical cars are added and Reserved; totals update | | |
| 3 | Ask for more cars of a type than are in stock | Refused, with a suggestion to raise an import request | | |
| 4 | On a sale for an individual, try to add fleet vehicles | Refused: fleet sales only | | |

#### UAT-C-04: Fleet agreed rate applies automatically (US-20)
**Traces:** Goal O2 · Story US-20. **Tester:** Sales Rep. **Test data:** TD-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a fleet sale, **Request Discount**, leave the rate blank, save | The account's agreed rate is filled in automatically, worked out on the fleet total | | |

#### UAT-C-05: No discount on an instalment sale (US-25)
**Traces:** Goal O2 · Story US-25. **Tester:** Sales Rep. **Test data:** Sale 2 (7.5% approved).

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On an instalment sale, try **Request Discount** | Refused, with a message saying why | | |
| 2 | Open Sale 2, change Payment Mode to **Instalment**, save | The approved discount becomes **Invalidated** | | |

#### UAT-C-06: Change vehicle or payment type before collection (US-39)
**Traces:** Goal O2 · Story US-39 · Criterion: money paid carries over; the difference is settled; a refund needs Head of Finance approval. **Tester:** Sales Rep, then Head of Finance.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a sale with a payment, change the vehicle to a cheaper one | The amount paid carries over and a refund is shown as needing approval | | |
| 2 | As the Head of Finance, approve the refund | The refund is recorded with who approved it | | |
| 3 | Change a sale from instalment to full payment | Earlier payments count towards the full price | | |

### D. Finance and payments

#### UAT-D-01: Payment recorded once, balances update themselves (US-03)
**Traces:** Goal O2, O3 · Story US-03. **Tester:** Finance Team. **Test data:** TD-21 Segun Ajayi.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AM Instalment Plans → All**, open **Segun Ajayi**'s plan → Related → Instalments → **Month 2 of 6** | Balance 3,800,000 | | |
| 2 | Click **Record Payment**, keep the amount, record | Amount Paid 3,800,000, Balance 0, Status Paid; Recorded By and the date filled in | | |
| 3 | Back on the plan, look at **Where This Plan Stands** | Month 2 shows PAID; Next Step names Month 3 | | |
| 4 | On a sale whose deposit is already recorded, click **Record Down Payment** again | Refused: the down payment is already recorded | | |

#### UAT-D-02: One list of late and defaulting customers (US-05)
**Traces:** Goal O4 · Story US-05. **Tester:** Head of Finance. **Test data:** TD-24, TD-25, TD-26.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Instalment Plans → Needs Attention** | Funke Ayo and Folake Ogunleye (Late) and Suleiman Bello (Defaulted) are listed | | |
| 2 | Open Funke's plan | Next Step says how many days late, how much is owed and what to do; Month by Month shows each month | | |

#### UAT-D-03: Bank total against recorded payments (US-09)
**Traces:** Goal O2 · Story US-09. **Tester:** Head of Finance.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Reconciliation Entries → New**: a Date and a Bank Total different from the payments that day. Save | Recorded Total fills itself; the Difference shows; Status **Flagged** | | |
| 2 | Check the bell (Finance and Head of Finance) | An alert: bank and recorded payments do not match | | |
| 3 | Set Status to **Explained** with Note empty | Refused: write the cause in Note | | |
| 4 | Write a note, set Explained, save | Saves as Explained | | |

#### UAT-D-04: Reminder 3 days before a payment is due (US-15, US-19)
**Traces:** Goal O3 · Stories US-15, US-19. **Tester:** Finance Team. **Test data:** TD-20 Chiamaka Okonkwo (email: tester's inbox).

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | The day before Chiamaka's Month 1 is 3 days away, note it is unpaid | Month 1 shows "upcoming" | | |
| 2 | **(next day)** open her plan | Month by Month shows "Sent: reminder email" with the date | | |
| 3 | Check the tester's inbox | A reminder with the amount and due date | | |
| 4 | Check a month that is already paid | No reminder was sent for it | | |

#### UAT-D-05: Alert when a customer first defaults (US-17)
**Traces:** Goal O3 · Story US-17. **Tester:** Finance Team. **Test data:** TD-25 Folake Ogunleye.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Before the job: open Folake's plan | Month 1 is LATE by 30+ days; plan Late | | |
| 2 | **(next day)** open the plan again | Month 1 DEFAULTED, plan **Defaulted**, "Finance alerted" | | |
| 3 | **(day after)** check | No second alert for the same month | | |

#### UAT-D-06: Part, short and extra payments (US-28)
**Traces:** Goal O2 · Story US-28 · Criterion: a payment of 475 against 500 is recorded with what remains. **Tester:** Finance Team. **Test data:** TD-20 Chiamaka Okonkwo.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Month 1 of 6 → Record Payment → **2,000,000** (due 2,500,000) | Balance **500,000** owed; Month by Month "part paid: 2,000,000" | | |
| 2 | Month 2 of 6 → Record Payment → **3,000,000** | PAID, "500,000 extra, kept as credit" | | |
| 3 | On a plan not yet signed off (TD-23 before sign-off), try Record Payment on a month | Refused: the Head of Finance has not signed off the plan | | |

#### UAT-D-07: Instalment rules (US-29)
**Traces:** Goal O2 · Story US-29 · Rules: 30% down, 12 months max (no exceptions), guarantor with income check before sign-off, only the Head of Finance signs off, sale can't close before deposit and sign-off. **Tester:** Head of Finance, then Finance Team. **Test data:** TD-28 Ngozi, TD-23 Hauwa, TD-27 Zainab.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On Ngozi's plan set Term in Months to **13**, save | Refused: no longer than 12 months | | |
| 2 | Set Down Payment % to **20**, save | Refused: at least 30% | | |
| 3 | As Finance, open Hauwa's plan | The Head of Finance Sign-off box cannot be edited | | |
| 4 | As the Head of Finance, tick Sign-off on Hauwa's plan | Signed Off By and Signed Off On fill themselves; status Awaiting Sign-off → Active | | |
| 5 | Untick a guarantor's **Income Check Done**, then try to sign off a plan using that guarantor | Refused: income check must be done first | | |
| 6 | Open Zainab's sale, set Stage **Closed Won** | Refused: needs the deposit and the sign-off first | | |

#### UAT-D-08: Legal escalation (US-36)
**Traces:** Goal O2, O3 · Story US-36 · Criterion: escalation needs 90+ days unpaid, guarantor unable, Finance approval; saving it notifies Legal with the name, months defaulted and amount owed. **Tester:** Head of Finance, then Legal Team. **Test data:** TD-26 Suleiman Bello; TD-25 Folake for the refusal.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Folake's plan → **Raise Legal Escalation** | Refused: no month is 90+ days unpaid | | |
| 2 | Open Suleiman's plan → **Raise Legal Escalation**; answer Yes to both questions; enter months defaulted and amount owed | The escalation is raised and the screen says Legal was notified | | |
| 3 | Refresh the plan | Plan Status **With Legal**; Related → Legal Escalations shows it with **Legal Team Notified At** | | |
| 4 | As Legal, **Legal Escalations → All**, open it | Customer, months defaulted and amount owed; view only | | |

#### UAT-D-09: Completion email (US-37)
**Traces:** Goal O3 · Story US-37. **Tester:** Finance Team. **Test data:** TD-22 Emmanuel Udo.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Month 3 of 3 → Record Payment → keep the amount | Plan **Completed**; Completion Email Sent ticked | | |
| 2 | Edit and save the plan again | No second email | | |

### E. Customer service

#### UAT-E-01: A request becomes a case with a reference number, and goes to the right team (US-06, US-34)
**Traces:** Goal O1, O3 · Stories US-06, US-34. **Tester:** Customer (website), then CS Agent. **Test data:** TD-05.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On the website, **Contact support**, topic **Payments or my instalment plan**, submit | A reference number on screen and an email with the same number | | |
| 2 | Submit two more: **Buying a vehicle or my order**, then **A problem with my vehicle** | A reference number each time | | |
| 3 | As the CS Agent / Head of CS, **Cases → All Open Cases** | Payments → Finance; Buying → Showroom; Problem → Customer Service (Routed To filled in) | | |

#### UAT-E-02: Agent sees history, not payment amounts (US-04)
**Traces:** Goal O1 · Story US-04. **Tester:** CS Agent. **Test data:** TD-01 Daniel Okoro.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Search **Daniel Okoro** by name or phone, open the account | Purchases, cases and messages on one record | | |
| 2 | Look for prices or payment amounts | None are shown; view only | | |

#### UAT-E-03: Every case's owner and status (US-10)
**Traces:** Goal O4 · Story US-10. **Tester:** Head of CS.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Cases → All Cases** | Every case has one owner and one status | | |
| 2 | Leave the CS Agent logged in; submit "A problem with my vehicle" on the website; wait up to 5 minutes | The case is the agent's automatically (Auto Assigned At filled in) | | |

#### UAT-E-04: First response and resolution times (US-13)
**Traces:** Goal O4 · Story US-13. **Tester:** CS Agent, then Head of CS.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Reply to a case, then close it | First Response At and Resolved At filled in; the automatic acknowledgement does not count | | |
| 2 | Run report **AD Cases by Status** | The case shows with its times | | |

#### UAT-E-05: Search the knowledge base (US-14)
**Traces:** Goal O3 · Story US-14. **Tester:** CS Agent.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Knowledge Articles**, search a keyword | Published articles with the issue and the agreed answer | | |
| 2 | Try to edit an article | Not allowed | | |

#### UAT-E-06: Head of CS maintains articles (US-18)
**Traces:** Goal O5 · Story US-18. **Tester:** Head of CS.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Edit an article, save | The change shows at once | | |
| 2 | Set another to **Retired** | Hidden from agents, not deleted | | |

#### UAT-E-07: Satisfaction score and trend (US-22, US-24)
**Traces:** Goal O4 · Stories US-22, US-24. **Tester:** CS Agent, then Head of CS.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a closed case enter CSAT Score **11**, save | Refused: 1 to 10 | | |
| 2 | Enter **8**, save | Saves | | |
| 3 | As Head of CS, run **AD Satisfaction Scores** | Scores over time with the number of ratings; blank is not counted as low | | |

#### UAT-E-08: An unanswered case escalates itself (US-33)
**Traces:** Goal O3 · Story US-33. **Tester:** Head of CS.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Leave a new case with no reply for over **1 hour** | Priority High, Escalated At filled in, Head of CS flagged | | |
| 2 | Check a closed case | Closed cases do not escalate | | |

#### UAT-E-09: Customer told when the case changes (US-35)
**Traces:** Goal O3 · Story US-35. **Tester:** CS Agent.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Set a case to **Working**, then **Closed** | One status update and one resolution message under Customer Messages, each with the time sent | | |
| 2 | Change only the owner | No message is sent | | |

### F. Management

#### UAT-F-01: One dashboard for the whole business (US-21)
**Traces:** Goal O4 · Story US-21. **Tester:** Management.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Home / the Management dashboard | Sales, stock, finance and service figures together, no errors | | |
| 2 | Compare one stock figure with the model record | They agree | | |
| 3 | Try to edit a record | Read only | | |

### Security and access

#### UAT-S-01: Each role sees only its own tabs and actions
**Traces:** Goal O2 · Security matrix. **Tester:** each role in turn.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Log in as each role in section 4 | Only that role's tabs show (per the security matrix) | | |
| 2 | As the Sales Rep, look for Payments, Instalment Plans, Reconciliation | Not visible | | |
| 3 | As the CS Agent, look for prices on a sale | Not shown | | |

#### UAT-S-02: Locked actions
**Traces:** Goal O2 · Security matrix, US-29, US-02. **Tester:** several.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | As Finance, open a plan | Sign-off, Signed Off By and Signed Off On cannot be edited | | |
| 2 | As the Head of Finance, open a sale | No edit pencils on the sale; no Request Discount button | | |
| 3 | As the Sales Rep, open your own discount request | No Approve button | | |
| 4 | As any user, edit a record's name (e.g. a plan) and save | The automatic name is kept | | |

### End-to-end journeys

#### UAT-E2E-01: Website enquiry to sale, deposit, sign-off, car sold and first payment
**Traces:** Goals O1–O4 · Stories US-11, US-23, US-01, US-25, US-29, US-03. **Test data:** TD-05, a car from TD-10.

| Step | Who | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|---|
| 1 | Customer | Sales enquiry on the website | Thank-you message | | |
| 2 | Sales Rep | Find it in My Leads, fill the qualifying answers, convert with the car | A sale is created | | |
| 3 | Sales Rep | Payment Mode = Instalment, 6 months; try Request Discount | Discount refused; 30% deposit filled in; Finance notified | | |
| 4 | Finance | Plans To Set Up → Create Instalment Plan with a guarantor | Plan Awaiting Sign-off; 6 months created | | |
| 5 | Finance | Record Down Payment | Car **Reserved**; Next Step: waiting for sign-off | | |
| 6 | Head of Finance | Tick sign-off | Name and date stamped; plan Active | | |
| 7 | Sales Rep | Stage **Closed Won** | Car **Sold** | | |
| 8 | Finance | Record Payment on Month 1 | Month 1 Paid; Next Step names Month 2 | | |
| 9 | Management | Open the dashboard | The sale and the payment appear | | |

#### UAT-E2E-02: Website complaint to case closed and measured
**Traces:** Goals O3, O4 · Stories US-06, US-34, US-11, US-13, US-35, US-22, US-21.

| Step | Who | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|---|
| 1 | Customer | Contact support, "A problem with my vehicle" | Reference number on screen and by email | | |
| 2 | CS Agent (logged in) | Wait up to 5 minutes, My Cases | The case is the agent's | | |
| 3 | CS Agent | Reply, set Working, then Closed | Status emails sent; First Response At and Resolved At filled | | |
| 4 | CS Agent | Enter CSAT 8 | Saves | | |
| 5 | Head of CS | AD Cases by Status, AD Satisfaction Scores | The case counted with its times and score | | |

---

## 11. Results summary, defect log and sign-off

**Results** (fill in when testing ends)

| Measure | Round 1 | Round 2 |
|---|---|---|
| Scripts run | | |
| Scripts passed | | |
| Scripts failed | | |
| Scripts blocked | | |
| MUST scripts passed | | |
| Open Critical or High defects | | |
| Open Medium or Low defects | | |

**Results so far (internal round, 20–25 Oct 2026)**

| Role | Result |
|---|---|
| Sales Rep | 15 of 16 passed, 1 skipped (Instagram list, no social leads yet) |
| Showroom Manager | 7 of 7 passed |
| Finance Team | In progress |
| Head of Finance | Approvals, 30%, 12 months, sign-off rules, late list and reconciliation passed; legal escalation to run |

**Defect log** (found during the internal round; all fixed and waiting for the tester's retest)

| ID | Script and step | What happened | Severity | Owner | Status |
|---|---|---|---|---|---|
| DEF-01 | UAT-S-02 / 1 | Finance could tick the Head of Finance sign-off on a plan | Critical | Build team | Fixed, retest |
| DEF-02 | UAT-S-02 / 2 | The Head of Finance could edit and delete sales | Critical | Build team | Fixed, retest |
| DEF-03 | UAT-D-01 / 4 | A down payment could be recorded more than once | High | Build team | Fixed, retest |
| DEF-04 | UAT-D-06 / 3 | Monthly payments could be recorded before the plan was signed off | High | Build team | Fixed, retest |
| DEF-05 | UAT-C-02 / 3 | Approve and Reject failed on a discount (a car was on two sales) | High | Build team | Fixed, retest |
| DEF-06 | UAT-D-02 / 1 | Unpaid months were never marked Late, so the late list stayed empty | High | Build team | Fixed, retest |
| DEF-07 | UAT-D-07 / 1–2 | Fleet customers could go below 30% or past 12 months; the story allows no exceptions | High | Build team | Fixed, retest |
| DEF-08 | UAT-D-03 / 1 | Reconciliation totals were typed by hand and nobody was alerted | High | Build team | Fixed, retest |
| DEF-09 | UAT-B-01 / 4 | A single-car sale with a deposit left the car Available to other reps | High | Build team | Fixed, retest |
| DEF-10 | UAT-D-08 / 2 | The legal escalation screen had no button; "New" skipped its checks and the email to Legal | High | Build team | Fixed, retest |
| DEF-11 | UAT-D-01 / 1 | Instalments and payments were not listed on the plan | Medium | Build team | Fixed, retest |
| DEF-12 | UAT-C-01 / 3 | Discount requests did not show what was being discounted or its cost | Medium | Build team | Fixed, retest |
| DEF-13 | UAT-D-07 / 4 | A plan showed Active before it was signed off | Medium | Build team | Fixed, retest |
| DEF-14 | UAT-D-06 / 3 | Refused payment showed "unhandled fault" instead of a clear message | Low | Build team | Fixed, retest |
| CR-01 | All | Record names were numbers only; now reference · customer · detail | Change | Hillary | Done |
| CR-02 | UAT-D-02 | Plan page shows Next Step and Month by Month | Change | Hillary | Done |
| OPEN-01 | Entry criteria | Email is off in the sandbox (Deliverability), so email checks can't pass | High | Hillary | Open: set Access level to All email |

**Sign-off**

| Role | Name | Signature | Date |
|---|---|---|---|
| Business sponsor (AutoDrive) | | | |
| Business tester – Showroom | Henry | | |
| Business tester – Finance | Obed | | |
| Business tester – Customer Service | Shedrack | | |
| Delivery lead | Hillary Emmanuel | | |
| Africa Ohana / DKloud representative | | | |
