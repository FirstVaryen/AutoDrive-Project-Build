# AutoDrive Motors – UAT Results (build team pre-run, 25 Oct 2026)

User acceptance testing for the AutoDrive Motors Salesforce build (TAP Group 3). It checks that the system does what AutoDrive asked for, using the business goals, requirements and user stories in the v8 workbook (`AutoDrive_Requirements_UserStories_v8.xlsx`). Every script is written in plain words and is run as the user it is meant for, never as an administrator.

**How to use this document**
1. Section 9 lists every user story by persona.
2. Section 10 is split by persona. Each tester only needs section 7 (how to run a script) and their own persona sections.
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
- Linked journeys across personas: a sale from website enquiry to first monthly payment, and a complaint from the website to closure (each persona runs its own part).

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

**Cases:** created during the tests from the website (section 10.1, UAT-CU-02).

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
- Every persona section has been run.
- The results summary (section 11) is complete and the sign-off table is signed.

If not met, testing continues after fixes, and only the failed and affected scripts are run again.

---

## 9. Script index by persona

| Persona | Script | Story | Scenario | Priority | Built |
|---|---|---|---|---|---|
| Customer (website) | UAT-CU-01 | US-11 | Send a sales enquiry from the website | MUST | ✔ |
| Customer (website) | UAT-CU-02 | US-06, US-34 | Send support requests and get a reference number | MUST | ✔ |
| Customer (website) | UAT-CU-03 | US-19 | Get a reminder before a payment is due | SHOULD | ✔ |
| Front Desk | UAT-FD-01 | US-23 | Ask every walk-in the same questions | SHOULD | ✔ |
| Front Desk | UAT-FD-02 | US-30 | Walk-in goes to the next free rep, without duplicates | SHOULD | ✔ |
| Social Media Handler | UAT-SO-01 | US-31 | Instagram enquiries with no visit booked | SHOULD | ✔ |
| Sales Rep | UAT-SR-01 | US-11 | A website enquiry reaches me automatically | MUST | ✔ |
| Sales Rep | UAT-SR-02 | US-23 | A lead can't be converted without its purpose | SHOULD | ✔ |
| Sales Rep | UAT-SR-03 | US-01 | A sold car shows Sold at once and can't be sold again | MUST | ✔ |
| Sales Rep | UAT-SR-04 | US-07 | See live availability | MUST | ✔ |
| Sales Rep | UAT-SR-05 | US-02 | Request a discount and see where it sits | MUST | ✔ |
| Sales Rep | UAT-SR-06 | US-16 | A fleet customer in one place, several vehicles on one sale | SHOULD | ✔ |
| Sales Rep | UAT-SR-07 | US-20 | A fleet customer's agreed rate applies automatically | SHOULD | ✔ |
| Sales Rep | UAT-SR-08 | US-25 | No discount on an instalment sale | SHOULD | ✔ |
| Sales Rep | UAT-SR-09 | US-29 | An instalment sale can't close before deposit and sign-off | SHOULD | ✔ |
| Sales Rep | UAT-SR-10 | US-38 | Raise an import request when a model is out of stock | SHOULD | ✔ |
| Sales Rep | UAT-SR-11 | US-39 | Change vehicle or payment type before collection | SHOULD | ✔ |
| Sales Rep | UAT-SR-12 | Security | What the rep can and can't see or do | MUST | ✔ |
| Showroom Manager | UAT-SM-01 | US-32 | See where deals are stuck | SHOULD | ✔ |
| Showroom Manager | UAT-SM-02 | US-02 | Approve or reject a discount | MUST | ✔ |
| Showroom Manager | UAT-SM-03 | US-12 | Low-stock alert | SHOULD | ✔ |
| Showroom Manager | UAT-SM-04 | US-30 | Returning and high-profile walk-ins come to me | SHOULD | ✔ |
| Showroom Manager | UAT-SM-05 | US-38 | See import requests | SHOULD | ✔ |
| Finance Team | UAT-FT-01 | US-08 | See and approve the discounts waiting for me | MUST | ✔ |
| Finance Team | UAT-FT-02 | US-29 | Set up an instalment plan and take the down payment | SHOULD | ✔ |
| Finance Team | UAT-FT-03 | US-03 | Record a payment; balances update themselves | MUST | ✔ |
| Finance Team | UAT-FT-04 | US-28 | Part, short and extra payments | SHOULD | ✔ |
| Finance Team | UAT-FT-05 | US-15 | Reminder 3 days before a payment is due | SHOULD | ✔ |
| Finance Team | UAT-FT-06 | US-17 | Alert when a customer first defaults | SHOULD | ✔ |
| Finance Team | UAT-FT-07 | US-37 | Completion email when a plan is paid off | COULD | ✔ |
| Finance Team | UAT-FT-08 | US-38 | Move an import request on until the cars arrive | SHOULD | ✔ |
| Finance Team | UAT-FT-09 | Security | What Finance can and can't do | MUST | ✔ |
| Head of Finance | UAT-HF-01 | US-02, US-08 | Final discount approval | MUST | ✔ |
| Head of Finance | UAT-HF-02 | US-29 | Instalment rules and sign-off | SHOULD | ✔ |
| Head of Finance | UAT-HF-03 | US-05 | One list of late and defaulting customers | MUST | ✔ |
| Head of Finance | UAT-HF-04 | US-09 | Bank total against recorded payments | MUST | ✔ |
| Head of Finance | UAT-HF-05 | US-36 | Escalate an unrecoverable default to Legal | SHOULD | ✔ |
| Head of Finance | UAT-HF-06 | US-26 | See stock, models and list prices | SHOULD | ✔ |
| Head of Finance | UAT-HF-07 | US-39 | Approve a refund on a vehicle change | SHOULD | ✔ |
| Head of Finance | UAT-HF-08 | Security | What the Head of Finance can and can't do | MUST | ✔ |
| Legal Team | UAT-LG-01 | US-36 | See a legal escalation | SHOULD | ✔ |
| Customer Service Agent | UAT-CS-01 | US-06 | Cases arrive from the website, routed to the right team | MUST | ✔ |
| Customer Service Agent | UAT-CS-02 | US-11 | A new case is assigned to me automatically | MUST | ✔ |
| Customer Service Agent | UAT-CS-03 | US-04 | See a customer's history, not payment amounts | MUST | ✔ |
| Customer Service Agent | UAT-CS-04 | US-13 | Reply to and close a case | SHOULD | ✔ |
| Customer Service Agent | UAT-CS-05 | US-35 | The customer is told when the case changes | SHOULD | ✔ |
| Customer Service Agent | UAT-CS-06 | US-22 | Record a satisfaction score | SHOULD | ✔ |
| Customer Service Agent | UAT-CS-07 | US-14 | Search the knowledge base | SHOULD | ✔ |
| Customer Service Agent | UAT-CS-08 | Security | What the agent can and can't see | MUST | ✔ |
| Head of Customer Service | UAT-HC-01 | US-10 | Every case's owner and status | MUST | ✔ |
| Head of Customer Service | UAT-HC-02 | US-33 | An unanswered case escalates itself | SHOULD | ✔ |
| Head of Customer Service | UAT-HC-03 | US-13 | Response and resolution times | SHOULD | ✔ |
| Head of Customer Service | UAT-HC-04 | US-24 | Satisfaction trend | SHOULD | ✔ |
| Head of Customer Service | UAT-HC-05 | US-18 | Maintain knowledge articles | SHOULD | ✔ |
| Management | UAT-MG-01 | US-21 | One dashboard for the whole business | COULD | ✔ |
| Management | UAT-MG-02 | Security | Read only | MUST | ✔ |

**Linked scripts.** Some scripts carry on from another persona's script (for example, the manager approves the discount the rep requested). Each script says at the top what must be done first and by whom.

---

## 10. The scripts, by persona

### 10.1 Customer (website)
**Login:** none. Open the website in a private window: https://dk1791276250211--group3sb.sandbox.my.site.com/s/ · **Tester:** Henry

#### UAT-CU-01: Send a sales enquiry from the website (US-11)
**Traces:** Goal O3 · Story US-11. **Scenario:** A customer asks about a car on the website. **Test data:** TD-05, a car from TD-10. **Then:** the Sales Rep runs UAT-SR-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the website and fill in **Sales enquiry** with your name, phone or email, and a car. Submit | A thank-you message shows | Thank-you pops up | Pass |

#### UAT-CU-02: Send support requests and get a reference number (US-06, US-34)
**Traces:** Goal O1, O3 · Stories US-06, US-34. **Test data:** TD-05. **Then:** the CS Agent runs UAT-CS-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Contact support**, topic **Payments or my instalment plan**, submit | A reference number on screen, and an email with the same number | To be checked by tester | |
| 2 | Submit **Buying a vehicle or my order** | A reference number on screen and by email | To be checked by tester | |
| 3 | Submit **A problem with my vehicle** | A reference number on screen and by email | To be checked by tester | |

#### UAT-CU-03: Get a reminder before a payment is due (US-19)
**Traces:** Goal O3 · Story US-19. **Test data:** TD-20 Chiamaka Okonkwo (her email is the tester's inbox). **(next day)**

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | The morning after Chiamaka's Month 1 becomes 3 days away, check the inbox | A reminder with the amount and the due date | To be checked by tester | |

### 10.2 Front Desk
**Login:** Front Desk Staff test user · **Tester:** Henry · **Tabs:** Home, Leads only

#### UAT-FD-01: Ask every walk-in the same questions (US-23)
**Traces:** Goal O2 · Story US-23. **Test data:** TD-04 Amina Sule. **Then:** the Sales Rep runs UAT-SR-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → New**. Name, phone, Channel = **Walk-in** | The form shows Qualification Answers, Visit Purpose and Vehicle Model of Interest | Done, saves | Pass |
| 2 | Fill in the qualifying answers, Visit Purpose = Purchase, pick a model, save | The lead saves | Yes | Pass |

#### UAT-FD-02: Walk-in goes to the next free rep, without duplicates (US-30)
**Traces:** Goal O2, O3 · Story US-30. **Test data:** TD-04 (new), TD-01 Daniel Okoro (returning). **Then:** the Showroom Manager runs UAT-SM-04.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Create a walk-in lead for a new person, save | **Lead Owner** is a sales rep, picked automatically | Done | Pass |
| 2 | Create a lead for **Daniel Okoro** with his existing phone number | A warning that a matching record already exists | It shows the warning | Pass |
| 3 | Create a walk-in lead with Channel = **Returning/High-profile** (or tick Returning or High-profile) | It saves and opens read-only; the owner is the Showroom Manager; a bell message says the client was passed to the manager | Round 1: stayed with the rep. Round 2: passed to the Showroom Manager | Pass (round 2) |
| 4 | Open **Leads → List View → AutoDrive - High-profile Clients** | The client is listed, owned by the Showroom Manager | Listed | Pass |

### 10.3 Social Media Handler
**Login:** Social Media Handler test user · **Tester:** Henry · **Tabs:** Home, Leads only

#### UAT-SO-01: Instagram enquiries with no visit booked (US-31)
**Traces:** Goal O3 · Story US-31. **Test data:** a new Instagram enquiry.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → New**, Channel = **Instagram**, no Booked Visit Date, save | It saves | It saves | |
| 2 | Open **Leads → AutoDrive - Enquiries No Visit Booked** | The new enquiry is listed | To be checked by tester | |
| 3 | Enter a Booked Visit Date on it, save, open the list again | It is no longer listed | To be checked by tester | |

### 10.4 Sales Rep
**Login:** test.salesrep@autodrive.group3sb.test · **Tester:** Henry

#### UAT-SR-01: A website enquiry reaches me automatically (US-11)
**Traces:** Goal O3 · Story US-11. **First:** stay logged in, then the Customer runs UAT-CU-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Log in and stay logged in | The rep's Home page opens | Opens | Pass |
| 2 | Wait up to 5 minutes after UAT-CU-01. Open **Leads → My Leads** | The enquiry is there, owned by the rep, Channel = Web, with the chosen car and **Auto Assigned At** filled in | Visible | Pass |
| 3 | Check email and notifications | A "lead assigned to you" message | No email arrived | Fail (DEF-15) |

#### UAT-SR-02: A lead can't be converted without its purpose (US-23)
**Traces:** Goal O2 · Story US-23. **First:** Front Desk runs UAT-FD-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the walk-in lead, clear Visit Purpose, click **Convert** | Refused until the purpose (and, for a purchase, the vehicle) is filled in | Refuses to save | Pass |
| 2 | Fill the purpose and vehicle, convert | A sale is created | Converts; sale created | Pass |

#### UAT-SR-03: A sold car shows Sold at once and can't be sold again (US-01)
**Traces:** Goal O1, O2 · Story US-01. **Test data:** fresh sales set (Sale 1, Sale 3), TD-28 Ngozi.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AD Rerun … Sale 1 (open)**, note the vehicle | The vehicle shows Available or Reserved | To be checked by tester | |
| 2 | Set Stage to **Closed Won**, save, click the vehicle | Status is **Sold**; nobody edited the car | To be checked by tester | |
| 3 | Open **Sale 3**, edit **Vehicle**, search for the car from step 2 | The sold car is not offered | To be checked by tester | |
| 4 | On another open sale, try to pick Ngozi Okeke's reserved car | Refused: "That car is reserved for another customer's sale…" | Refused: car reserved for another sale | Pass |

#### UAT-SR-04: See live availability (US-07)
**Traces:** Goal O1 · Story US-07.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Vehicles → All** | Every car shows Available, Reserved or Sold, with model, colour and year | Status, model, colour, year shown | Pass |
| 2 | Try to edit a car | View only | View only | Pass |

#### UAT-SR-05: Request a discount and see where it sits (US-02)
**Traces:** Goal O2, O3 · Story US-02. **Test data:** Sale 1, Sale 3. **Then:** the Showroom Manager runs UAT-SM-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On Sale 1, **Request Discount**, rate 5%, give a reason | Approved straight away (Auto Approved ticked) | Approved at once; Auto Approved ticked | Pass |
| 2 | On Sale 3, request **7.5%** with a reason | Current Step = **With Showroom Manager**, with the date and time | With Showroom Manager, date and time stamped | Pass |
| 3 | Open the request | The customer, each vehicle with its own list price, the total, the discount value and the price after discount | Customer, vehicles, list price, discount value, price after discount shown | Pass |
| 4 | After the manager has acted (UAT-SM-02), open Sale 3 | The sale's Approval Status shows where the discount is now, or Rejected | Approval status follows each step | Pass |

#### UAT-SR-06: A fleet customer in one place, several vehicles on one sale (US-16)
**Traces:** Goal O1 · Story US-16. **Test data:** TD-02 Lagos Ride Hailing Ltd.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Lagos Ride Hailing Ltd** | Contact person, agreed discount rate, owner and past sales on one page | To be checked by tester | |
| 2 | On an open fleet sale, **Add Fleet Vehicles**: pick a type and how many | That many identical cars are added and Reserved; totals update | 2 cars added and Reserved; totals updated | Pass |
| 3 | Ask for more cars of a type than are in stock | Refused, with a suggestion to raise an import request | Only the cars in stock added | Pass |
| 4 | On a sale for an individual, try to add fleet vehicles | Refused: fleet sales only | Refused: fleet sales only | Pass |

#### UAT-SR-07: A fleet customer's agreed rate applies automatically (US-20)
**Traces:** Goal O2 · Story US-20. **Test data:** TD-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a fleet sale, **Request Discount**, leave the rate blank, save | The agreed rate is filled in, worked out on the fleet total | Agreed rate (5%) filled in, worked on fleet total | Pass |

#### UAT-SR-08: No discount on an instalment sale (US-25)
**Traces:** Goal O2 · Story US-25. **Test data:** Sale 2 (7.5% approved).

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On an instalment sale, try **Request Discount** | Refused, with a message saying why | Refused with a message | Pass |
| 2 | Open Sale 2, change Payment Mode to **Instalment**, save | The approved discount becomes **Invalidated** | Discount Invalidated (after DEF-18 fix) | Pass |

#### UAT-SR-09: An instalment sale can't close before deposit and sign-off (US-29)
**Traces:** Goal O2 · Story US-29. **Test data:** TD-27 Zainab Bello.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Zainab Bello's sale, set Stage **Closed Won** | Refused: needs the down payment and the Head of Finance sign-off first | Refused: needs deposit and sign-off | Pass |
| 2 | On an instalment sale, set the months to 6 | The 30% deposit fills itself and the monthly amount is worked out; Finance is notified | 30% deposit and monthly amount filled in | Pass |

#### UAT-SR-10: Raise an import request (US-38)
**Traces:** Goal O1, O3 · Story US-38. **Test data:** TD-12. **Then:** Finance runs UAT-FT-08.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a customer, **Import Requests → New**: the model, Quantity 2, Reason = Out of stock. Save | Saved as Requested; Requested By is the rep | Saved as Requested; Requested By is the rep | Pass |
| 2 | Try to save one without a reason | Refused, with a message | Refused with a message | Pass |
| 3 | After Finance marks it Imported (UAT-FT-08), check notifications | A notice that the cars arrived | To be checked by tester | |

#### UAT-SR-11: Change vehicle or payment type before collection (US-39)
**Traces:** Goal O2 · Story US-39. **Then:** the Head of Finance runs UAT-HF-07.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a sale with a payment, change the vehicle to a cheaper one | The amount paid carries over; a refund is shown as needing approval | To be checked by tester | |
| 2 | Change a sale from instalment to full payment | Earlier payments count towards the full price | To be checked by tester | |

#### UAT-SR-12: What the rep can and can't see or do (Security)
**Traces:** Goal O2 · Security matrix.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Look at the tabs | Only the rep's tabs | To be checked by tester | |
| 2 | **Leads → List View**, open the list menu | AutoDrive - My Leads, AutoDrive - Website Leads, AutoDrive - High-profile Clients (and Recently Viewed) | To be checked by tester | |
| 3 | Look for Payments, Instalment Plans, Reconciliation | Not visible | Not visible | Pass |
| 4 | Open your own discount request | No Approve button | To be checked by tester | |

### 10.5 Showroom Manager
**Login:** test.showroommanager@autodrive.group3sb.test · **Tester:** Henry

#### UAT-SM-01: See where deals are stuck (US-32)
**Traces:** Goal O4 · Story US-32.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Leads → AutoDrive - Open Prospects** | Each open lead shows channel, owner and status | To be checked by tester | |
| 2 | **Leads → AutoDrive - Prospects With No Rep** | Leads without a rep (if any) | To be checked by tester | |
| 3 | **Opportunities → All Open Opportunities** | Each open sale shows owner, stage and approval status | To be checked by tester | |

#### UAT-SM-02: Approve or reject a discount (US-02)
**Traces:** Goal O2, O3 · Story US-02. **First:** the Sales Rep runs UAT-SR-05. **Then:** Finance runs UAT-FT-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Home → Items to Approve**, open the 7.5% request | Vehicles, list prices, total, discount value and price after discount are shown | Vehicles, prices and totals shown | Pass |
| 2 | Approve it | Step moves to **With Finance**, with a new date and time | Moved to With Finance, new date and time | Pass |
| 3 | Approve and reject lists: open **Approved by Me - Showroom Manager** | The approved request is listed | To be checked by tester | |
| 4 | Have the rep request another above 5%; **Reject** it with a reason | Status Rejected | Rejected | Pass |

#### UAT-SM-03: Low-stock alert (US-12)
**Traces:** Goal O3, O4 · Story US-12. **Test data:** TD-11.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a Vehicle Model, set **Low Stock Threshold** above its Available Stock, save | It saves | Saves (after DEF-20 fix) | Pass |
| 2 | **(next day)** check the bell | One low-stock notification for that model | To be checked by tester | |
| 3 | Open **Vehicle Models → AutoDrive - Low Stock** | The model is listed | Listed | Pass |
| 4 | **(day after)** check the bell again | No repeat alert for the same model | To be checked by tester | |

#### UAT-SM-04: Returning and high-profile walk-ins come to me (US-30)
**Traces:** Goal O2 · Story US-30. **First:** Front Desk runs UAT-FD-02 step 3.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Check the bell, then **Leads → AutoDrive - High-profile Clients** | A message about the new client; the client is listed and owned by the manager | To be checked by tester | |
| 2 | Change its owner to a chosen rep | Allowed and saved | Owner changed to the rep | Pass |

#### UAT-SM-05: See import requests (US-38)
**Traces:** Goal O1 · Story US-38. **First:** the Sales Rep runs UAT-SR-10.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AM Import Requests** | The rep's request, with quantity, reason and status | Listed with quantity, reason, status | Pass |

### 10.6 Finance Team
**Login:** test.financeteam@autodrive.group3sb.test · **Tester:** Obed

#### UAT-FT-01: See and approve the discounts waiting for me (US-08)
**Traces:** Goal O3 · Story US-08. **First:** the Showroom Manager runs UAT-SM-02. **Then:** the Head of Finance runs UAT-HF-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Home → Items to Approve** | The request is listed with its date | To be checked by tester | |
| 2 | Approve it | Step moves to **With Head Office** at once | Moved to With Head Office | Pass |

#### UAT-FT-02: Set up an instalment plan and take the down payment (US-29)
**Traces:** Goal O2, O3 · Story US-29. **First:** the Sales Rep has an instalment sale at Payment Arranged. **Then:** the Head of Finance runs UAT-HF-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Opportunities → AutoDrive - Plans To Set Up**, open the sale | The sale is listed with months, deposit and monthly amount | To be checked by tester | |
| 2 | **Create Instalment Plan**, choose a guarantor, save | Plan status **Awaiting Sign-off**; one instalment per month is created | To be checked by tester | |
| 3 | **Record Down Payment** | Saved; the sale's car becomes **Reserved**; Next Step says it is waiting for sign-off | To be checked by tester | |
| 4 | Click **Record Down Payment** again | Refused: the down payment is already recorded | Refused: already recorded | Pass |
| 5 | Try **Record Payment** on Month 1 | Refused: the Head of Finance has not signed off the plan | Refused: not signed off | Pass |

#### UAT-FT-03: Record a payment; balances update themselves (US-03)
**Traces:** Goal O2, O3 · Story US-03. **Test data:** TD-21 Segun Ajayi.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Instalment Plans → All**, open Segun Ajayi's plan → Related → Instalments → **Month 2 of 6** | Balance 3,800,000 | Balance 3,800,000 | Pass |
| 2 | **Record Payment**, keep the amount, record | Amount Paid 3,800,000, Balance 0, Status Paid; Recorded By and the date filled in | Paid, balance 0, Recorded By filled (after DEF-17, DEF-22 fixes) | Pass |
| 3 | Back on the plan, **Where This Plan Stands** | Month 2 PAID; Next Step names Month 3 | To be checked by tester | |

#### UAT-FT-04: Part, short and extra payments (US-28)
**Traces:** Goal O2 · Story US-28. **Test data:** TD-20 Chiamaka Okonkwo.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Month 1 of 6 → Record Payment → **2,000,000** (due 2,500,000) | Balance **500,000** owed; "part paid: 2,000,000" | Balance 500,000 owed | Pass |
| 2 | Month 2 of 6 → Record Payment → **3,000,000** | PAID, "500,000 extra, kept as credit" | Paid | Pass |

#### UAT-FT-05: Reminder 3 days before a payment is due (US-15)
**Traces:** Goal O3 · Story US-15. **Test data:** TD-20. **(next day)**

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Chiamaka's plan the morning her Month 1 is 3 days away | Month by Month shows "Sent: reminder email" with the date | To be checked by tester | |
| 2 | Look at a month that is already paid | No reminder was sent for it | To be checked by tester | |

#### UAT-FT-06: Alert when a customer first defaults (US-17)
**Traces:** Goal O3 · Story US-17. **Test data:** TD-25 Folake Ogunleye. **(next day)**

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Before the morning job, open Folake's plan | Month 1 LATE by 30+ days; plan Late | Month 1 Default; plan Defaulted; alert sent once | Pass |
| 2 | **(next day)** open the plan and the bell | Month 1 DEFAULTED, plan **Defaulted**, one alert | To be checked by tester | |
| 3 | **(day after)** check | No second alert for the same month | To be checked by tester | |

#### UAT-FT-07: Completion email when a plan is paid off (US-37)
**Traces:** Goal O3 · Story US-37. **Test data:** TD-22 Emmanuel Udo.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Month 3 of 3 → Record Payment → keep the amount | Plan **Completed**; Completion Email Sent ticked | Completed; Completion Email Sent ticked | Pass |
| 2 | Edit and save the plan again | No second email | To be checked by tester | |

#### UAT-FT-08: Move an import request on until the cars arrive (US-38)
**Traces:** Goal O1, O3 · Story US-38. **First:** the Sales Rep runs UAT-SR-10.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the request and move it on step by step to **Imported** | Each step saves | Each step saves (after DEF-19 fix) | Pass |
| 2 | Open the model | Available Stock has gone up by the quantity (new cars named IMP-…) | Stock up by the quantity; car named IMP-... | Pass |

#### UAT-FT-09: What Finance can and can't do (Security)
**Traces:** Goal O2 · Security matrix.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a plan | Head of Finance Sign-off, Signed Off By and Signed Off On can't be edited | Not editable | Pass |
| 2 | Look at the tabs | Only Finance's tabs | To be checked by tester | |

### 10.7 Head of Finance
**Login:** test.headoffinance@autodrive.group3sb.test · **Tester:** Obed

#### UAT-HF-01: Final discount approval (US-02, US-08)
**Traces:** Goal O2 · Stories US-02, US-08. **First:** Finance runs UAT-FT-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Home → Items to Approve**, open the request | Vehicles, list prices, total and price after discount are shown | To be checked by tester | |
| 2 | Approve it | Status **Approved**; Approved By and Approved On filled in | Approved; Approved By and On filled | Pass |

#### UAT-HF-02: Instalment rules and sign-off (US-29)
**Traces:** Goal O2 · Story US-29. **Test data:** TD-28 Ngozi Okeke, TD-23 Hauwa Lawal.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On Ngozi's plan set Term in Months to **13**, save | Refused: no longer than 12 months | Refused | Pass |
| 2 | Set Down Payment % to **20**, save | Refused: at least 30% | Refused | Pass |
| 3 | Open Hauwa's plan, tick **Head of Finance Sign-off**, save | Signed Off By and Signed Off On fill themselves; Awaiting Sign-off → Active | By and On filled; Active | Pass |
| 4 | Untick a guarantor's **Income Check Done**; try to sign off a plan using that guarantor | Refused: income check must be done first | Refused | Pass |

#### UAT-HF-03: One list of late and defaulting customers (US-05)
**Traces:** Goal O4 · Story US-05. **Test data:** TD-24, TD-25, TD-26.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Instalment Plans → Needs Attention** | Funke Ayo, Folake Ogunleye (Late) and Suleiman Bello (Defaulted) | Funke Late; Folake, Suleiman Defaulted | Pass |
| 2 | Open Funke's plan | Next Step says how many days late, how much is owed and what to do | Days late, amount owed and action shown | Pass |

#### UAT-HF-04: Bank total against recorded payments (US-09)
**Traces:** Goal O2 · Story US-09.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **AM Reconciliation Entries → New**: a Date and a Bank Total different from that day's payments. Save | Recorded Total fills itself; the Difference shows; Status **Flagged** | Recorded Total filled; Flagged | Pass |
| 2 | Check the bell | An alert: bank and recorded payments do not match | To be checked by tester | |
| 3 | Set Status to **Explained** with Note empty | Refused: write the cause in Note | Refused | Pass |
| 4 | Write a note, set Explained, save | Saves as Explained | Saves as Explained | Pass |

#### UAT-HF-05: Escalate an unrecoverable default to Legal (US-36)
**Traces:** Goal O2, O3 · Story US-36. **Test data:** TD-26 Suleiman Bello; TD-25 Folake for the refusal. **Then:** Legal runs UAT-LG-01.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Folake's plan → **Raise Legal Escalation** | Refused: no month is 90+ days unpaid | To be checked by tester | |
| 2 | Suleiman's plan → **Raise Legal Escalation**; Yes to both questions; enter months defaulted and amount owed | Raised; the screen says Legal was notified | To be checked by tester | |
| 3 | Refresh the plan | Plan Status **With Legal**; Related → Legal Escalations shows it with **Legal Team Notified At** | With Legal | Pass |

#### UAT-HF-06: See stock, models and list prices (US-26)
**Traces:** Goal O1 · Story US-26.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **AM Vehicles** and **Vehicle Models** | Stock and list prices visible | Visible | Pass |
| 2 | Try to edit a car or a price | Not allowed | Not allowed | Pass |
| 3 | Open **AutoDrive - Models With No List Price** | Models missing a price (if any) | List available | Pass |

#### UAT-HF-07: Approve a refund on a vehicle change (US-39)
**Traces:** Goal O2 · Story US-39. **First:** the Sales Rep runs UAT-SR-11.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Approve the refund | The refund is recorded with who approved it | To be checked by tester | |

#### UAT-HF-08: What the Head of Finance can and can't do (Security)
**Traces:** Goal O2 · Security matrix.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a sale | No edit pencils; no Request Discount button | Read only | Pass |
| 2 | Look at the tabs | Only the Head of Finance's tabs | To be checked by tester | |

### 10.8 Legal Team
**Login:** test.legalteam@autodrive.group3sb.test · **Tester:** Obed

#### UAT-LG-01: See a legal escalation (US-36)
**Traces:** Goal O1 · Story US-36. **First:** the Head of Finance runs UAT-HF-05.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Legal Escalations → All**, open Suleiman Bello's | Customer, months defaulted and amount owed | To be checked by tester | |
| 2 | Try to edit it | View only | View only | Pass |

### 10.9 Customer Service Agent
**Login:** test.csagent@autodrive.group3sb.test · **Tester:** Shedrack

#### UAT-CS-01: Cases arrive from the website, routed to the right team (US-06)
**Traces:** Goal O1, O3 · Story US-06. **First:** the Customer runs UAT-CU-02.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Cases → All Open Cases** | Payments → Finance; Buying → Showroom; Problem → Customer Service (Routed To filled in) | Payment > Finance, Sales > Showroom, Technical > Customer Service | Pass |

#### UAT-CS-02: A new case is assigned to me automatically (US-11)
**Traces:** Goal O3 · Story US-11.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Stay logged in. Ask the Customer to submit "A problem with my vehicle" | | To be checked by tester | |
| 2 | Wait up to 5 minutes, **Cases → My Cases** | The case is the agent's (Auto Assigned At filled in) | Assigned automatically, Auto Assigned At filled | Pass |

#### UAT-CS-03: See a customer's history, not payment amounts (US-04)
**Traces:** Goal O1 · Story US-04. **Test data:** TD-01 Daniel Okoro.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Search **Daniel Okoro** by name or phone, open the account | Purchases, cases and messages on one record | To be checked by tester | |
| 2 | Look for prices or payment amounts | None are shown; view only | No prices; view only | Pass |

#### UAT-CS-04: Reply to and close a case (US-13)
**Traces:** Goal O4 · Story US-13. **Then:** the Head of CS runs UAT-HC-03.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Reply to the customer on your case | First Response At filled in (the automatic acknowledgement doesn't count) | First Response At filled (after DEF-21 fix) | Pass |
| 2 | Close the case | Resolved At filled in | Resolved At filled | Pass |

#### UAT-CS-05: The customer is told when the case changes (US-35)
**Traces:** Goal O3 · Story US-35.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Set a case to **Working**, then **Closed** | One status update and one resolution message under Customer Messages, each with the time sent | One status update, one resolution message | Pass |
| 2 | Change only the owner | No message is sent | No message | Pass |

#### UAT-CS-06: Record a satisfaction score (US-22)
**Traces:** Goal O4 · Story US-22.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | On a closed case, CSAT Score **11**, save | Refused: 1 to 10 | Refused: 1 to 10 | Pass |
| 2 | Enter **8**, save | Saves | Saves | Pass |

#### UAT-CS-07: Search the knowledge base (US-14)
**Traces:** Goal O3 · Story US-14.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Knowledge Articles**, search a keyword | Published articles with the issue and the agreed answer | Published articles found | Pass |
| 2 | Try to edit an article | Not allowed | Not allowed | Pass |

#### UAT-CS-08: What the agent can and can't see (Security)
**Traces:** Goal O2 · Security matrix.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Look at the tabs | Only the agent's tabs | To be checked by tester | |
| 2 | Look for prices on a sale | Not shown | Not shown | Pass |

### 10.10 Head of Customer Service
**Login:** test.headofcs@autodrive.group3sb.test · **Tester:** Shedrack

#### UAT-HC-01: Every case's owner and status (US-10)
**Traces:** Goal O4 · Story US-10.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | **Cases → All Cases** | Every case has one owner and one status | Every case has an owner and status | Pass |

#### UAT-HC-02: An unanswered case escalates itself (US-33)
**Traces:** Goal O3 · Story US-33.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Leave a new case with no reply for over **1 hour** | Priority High, Escalated At filled in, Head of CS flagged | Unanswered cases escalated | Pass |
| 2 | Check a closed case | Closed cases do not escalate | Closed cases not escalated | Pass |

#### UAT-HC-03: Response and resolution times (US-13)
**Traces:** Goal O4 · Story US-13. **First:** the CS Agent runs UAT-CS-04.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Run report **AD Cases by Status** | The case shows with its first response and resolution times | To be checked by tester | |

#### UAT-HC-04: Satisfaction trend (US-24)
**Traces:** Goal O4 · Story US-24. **First:** the CS Agent runs UAT-CS-06.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Run report **AD Satisfaction Scores** | Scores over time with the number of ratings; blank is not counted as low | To be checked by tester | |

#### UAT-HC-05: Maintain knowledge articles (US-18)
**Traces:** Goal O5 · Story US-18.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Edit an article, save | The change shows at once | Saves | Pass |
| 2 | Set another to **Retired** | Hidden from agents, not deleted | Retired, not deleted | Pass |

### 10.11 Management
**Login:** test.management@autodrive.group3sb.test · **Tester:** Sponsor

#### UAT-MG-01: One dashboard for the whole business (US-21)
**Traces:** Goal O4 · Story US-21.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Home / the Management dashboard | Sales, stock, finance and service figures together, no errors | To be checked by tester | |
| 2 | Compare one stock figure with the model record | They agree | To be checked by tester | |

#### UAT-MG-02: Read only (Security)
**Traces:** Goal O2 · Security matrix.

| Step | What to do | Expected | Actual | Pass/Fail |
|---|---|---|---|---|
| 1 | Open any record and try to edit it | Everything can be read, nothing can be changed | Read only | Pass |

---

## 11. Results summary, defect log and sign-off

**Results** (fill in when testing ends)

| Persona | Scripts | Passed | Failed | Not run |
|---|---|---|---|---|
| Customer (website) | 3 | | | |
| Front Desk | 2 | | | |
| Social Media Handler | 1 | | | |
| Sales Rep | 12 | | | |
| Showroom Manager | 5 | | | |
| Finance Team | 9 | | | |
| Head of Finance | 8 | | | |
| Legal Team | 1 | | | |
| Customer Service Agent | 8 | | | |
| Head of Customer Service | 5 | | | |
| Management | 2 | | | |
| **Total** | **56** | | | |

**Defect log**

| ID | Script and step | What happened | Severity | Owner | Status |
|---|---|---|---|---|---|
| DEF-01 | UAT-FT-09 / 1 | Finance could tick the Head of Finance sign-off on a plan | Critical | Build team | Fixed, retest |
| DEF-02 | UAT-HF-08 / 1 | The Head of Finance could edit and delete sales | Critical | Build team | Fixed, retest |
| DEF-03 | UAT-FT-02 / 4 | A down payment could be recorded more than once | High | Build team | Fixed, retest |
| DEF-04 | UAT-FT-02 / 5 | Monthly payments could be recorded before the plan was signed off | High | Build team | Fixed, retest |
| DEF-05 | UAT-HF-01 / 2 | Approve and Reject failed on a discount (a car was on two sales) | High | Build team | Fixed, retest |
| DEF-06 | UAT-HF-03 / 1 | Unpaid months were never marked Late, so the late list stayed empty | High | Build team | Fixed, retest |
| DEF-07 | UAT-HF-02 / 1–2 | Fleet customers could go below 30% or past 12 months | High | Build team | Fixed, retest |
| DEF-08 | UAT-HF-04 / 1 | Reconciliation totals were typed by hand and nobody was alerted | High | Build team | Fixed, retest |
| DEF-09 | UAT-SR-03 / 4 | A single-car sale with a deposit left the car Available to other reps | High | Build team | Fixed, retest |
| DEF-10 | UAT-HF-05 / 2 | The legal escalation screen had no button; "New" skipped its checks and the email to Legal | High | Build team | Fixed, retest |
| DEF-11 | UAT-FT-03 / 1 | Instalments and payments were not listed on the plan | Medium | Build team | Fixed, retest |
| DEF-12 | UAT-SM-02 / 1 | Discount requests did not show what was being discounted or its cost | Medium | Build team | Fixed, retest |
| DEF-13 | UAT-HF-02 / 3 | A plan showed Active before it was signed off | Medium | Build team | Fixed, retest |
| DEF-14 | UAT-FT-02 / 5 | A refused payment showed "unhandled fault" instead of a clear message | Low | Build team | Fixed, retest |
| DEF-15 | UAT-SR-01 / 3 | No "lead assigned to you" email arrived: test users had placeholder email addresses | High | Hillary | Fixed, retest after confirming the 8 verification emails |
| DEF-16 | UAT-FD-02 / 3 | A returning or high-profile lead stayed with the rep instead of going to the Showroom Manager (now: goes to the manager at save, or when ticked later; the person who entered it keeps read-only access) | Medium | Build team | Closed: retest passed |
| DEF-17 | UAT-FT-03 / 2, UAT-HF-03 / 1 | A month paid outside the Record Payment screen stayed unpaid in its status, so the morning job marked it Late, then Default (Segun, Emmanuel and Suleiman showed Defaulted) | High | Build team | Fixed, retest |
| DEF-18 | UAT-SR-08 / 2 | Switching a sale with an approved discount to instalments failed with an error (the Finance alert could not find who to send to); the overdue-approval reminder had the same fault | High | Build team | Fixed, retest |
| DEF-19 | UAT-FT-08 / 1, UAT-SM-05 | Finance and the Showroom Manager could not open import requests, guarantors or reconciliations created by others (their teams had no members) | High | Build team | Fixed, retest |
| DEF-20 | UAT-SM-03 / 1 | The Showroom Manager could not change a model's Low Stock Threshold | Medium | Build team | Fixed, retest |
| DEF-21 | UAT-CS-04 / 1 | First Response At stayed empty after an agent replied | Medium | Build team | Fixed, retest |
| DEF-22 | UAT-FT-03 / 2 | Recorded By was empty unless the payment was entered through the screen | Low | Build team | Fixed, retest |
| DEF-23 | UAT-CU-03, UAT-FT-05 | Payment reminder, late notices, completion and satisfaction emails were not sent from AutoDrive Motors; the reminder did not show on Month by Month | Medium | Build team | Fixed, retest |
| DEF-24 | UAT-SR-07 | Lagos Ride Hailing Ltd had no agreed discount rate (test data) | Low | Build team | Fixed: 5% |
| CR-01 | All | Record names were numbers only; now reference · customer · detail | Change | Hillary | Done |
| CR-02 | UAT-HF-03 | Plan page shows Next Step and Month by Month | Change | Hillary | Done |
| CR-03 | UAT-SR-02, UAT-SR-03 | A lead or sale for a model with no cars available shows a red "Out of stock - request an import" marker; an open sale whose car was sold to someone else shows "This car has been sold to another customer - pick another car" | Change | Hillary | Done |
| CR-04 | UAT-SR-03 | A Closed Won or Closed Lost sale can't be changed, vehicle included, except by an administrator or a head of department | Change | Hillary | Done |
| OPEN-01 | Entry criteria | Email was off in the sandbox (Deliverability) | High | Hillary | Done |

**Sign-off**

| Role | Name | Signature | Date |
|---|---|---|---|
| Business sponsor (AutoDrive) | | | |
| Business tester – Showroom | Henry | | |
| Business tester – Finance | Obed | | |
| Business tester – Customer Service | Shedrack | | |
| Delivery lead | Hillary Emmanuel | | |
| Africa Ohana / DKloud representative | | | |
