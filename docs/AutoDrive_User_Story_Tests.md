# AutoDrive — User Story Tests (UAT)

**What this is:** one simple test for each user story in the v8 requirements workbook, grouped by role so you log in once per role and work straight down. Run the roles in the order shown: some tests hand over to the next role (for example the discount approval goes Sales Rep → Showroom Manager → Finance → Head of Finance).
It is separate from `AutoDrive_Test_Plan.md`, which is the detailed QA checklist used to find and fix build errors.

**Sandbox:** autodrive-dev (Group3SB) · **Version:** 20 Oct 2026 (grouped by role)


## Before you start
1. **Log in as the role named in the test**, not as an administrator. An admin opens Setup → Users → Users and clicks **Login** next to the test user. Click **Log out** in the top banner when finished.
2. **Do the steps in order** and compare what you see with **You should see**.
3. Write **Pass** or **Fail** in the Result column. For a Fail, write one line in Notes (what you saw) and take a screenshot.
4. **Can't find a record?** Lists open on *Recently Viewed*. Click the list name and choose **All …**.
5. **Need fresh sales to test with?** Closed sales are locked, so a test that closes a sale can't be repeated on the same record. Make a new set instead (admin only, takes about a minute), either way:
   - **From the project folder (terminal):** `sf apex run -o autodrive-dev -f scripts/apex/fresh_sales_test_records.apex`
   - **From Salesforce (no terminal):** gear icon → **Developer Console** → **Debug** → **Open Execute Anonymous Window** → paste the whole content of `scripts/apex/fresh_sales_test_records.apex` → tick **Open Log** → **Execute**.

   It creates, owned by TestSales Rep and named **"AD Rerun <date-time> …"** (use the newest set):
   - **Sale 1 (open)**: Full Payment, at Offer, with an available car (UAT-01, UAT-15)
   - **Sale 2 (discount approved)**: a 7.5% discount already approved (UAT-22)
   - **Sale 3 (open)**: a third open Full Payment sale (UAT-02, UAT-16)
   - **Lead**: an open lead at New
6. Some tests wait for a daily automatic job (early morning). They are marked **(next day)**.

| Role | Login |
|---|---|
| Sales Rep | test.salesrep@autodrive.group3sb.test |
| Showroom Manager | test.showroommanager@autodrive.group3sb.test |
| Finance Team | test.financeteam@autodrive.group3sb.test |
| Head of Finance | test.headoffinance@autodrive.group3sb.test |
| Customer Service Agent | test.csagent@autodrive.group3sb.test |
| Head of Customer Service | test.headofcs@autodrive.group3sb.test |
| Legal Team | test.legalteam@autodrive.group3sb.test |
| Management | test.management@autodrive.group3sb.test |
| Website visitor | No login. Open the site in a private / incognito window: https://dk1791276250211--group3sb.sandbox.my.site.com/s/ |

---

## Order to run
| # | Role | Tests | Hands over to |
|---|---|---|---|
| 1 | Website visitor (no login) | UAT-37, UAT-40a | Sales Rep, Finance, Customer Service pick these up |
| 2 | Sales Rep | UAT-01 to UAT-05, UAT-07, UAT-08, UAT-11a, UAT-12, UAT-15, UAT-16, UAT-21, UAT-22, UAT-36a, UAT-40b | Showroom Manager approves UAT-16 |
| 3 | Showroom Manager | UAT-06, UAT-09, UAT-10, UAT-13, UAT-14, UAT-17, UAT-20 | Finance approves next |
| 4 | Finance Team | UAT-11b, UAT-18, UAT-23, UAT-24, UAT-25, UAT-30, UAT-31, UAT-34, UAT-38a | Head of Finance approves last |
| 5 | Head of Finance | UAT-19, UAT-26 to UAT-29, UAT-32, UAT-33a, UAT-35 | Legal checks UAT-33 |
| 6 | Sales Rep (short return) | UAT-11c | |
| 7 | Legal Team | UAT-33b | |
| 8 | Customer Service Agent | UAT-36b, UAT-38b, UAT-39, UAT-41, UAT-42, UAT-46, UAT-48 | |
| 9 | Head of Customer Service | UAT-43, UAT-44, UAT-45, UAT-47, UAT-49 | |
| 10 | Management | UAT-50 | |

---

## 1. Website visitor (no login, private window)

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-37 | US-06 / US-34 Request becomes a case with a reference number | 1. Open the site. 2. Fill in **Contact support** with your real email, choose **Payments or my instalment plan**, submit. 3. Submit two more: **Buying a vehicle or my order**, then **A problem with my vehicle**. | Each time a reference number appears on screen, and an email with the same number arrives. Note the three numbers for Finance (UAT-38a) and Customer Service (UAT-38b, UAT-39). | | |
| UAT-40a | US-11 Website sales enquiry | 1. Fill in **Sales enquiry** (name, phone or email, a vehicle), submit. | A thank-you message. Note the name for the Sales Rep (UAT-40b). | | |

## 2. Sales Rep

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-01 | US-01 A sold car shows as sold straight away | 1. Open **AD Rerun … Sale 1 (open)**. 2. Note the vehicle. 3. Change Stage to **Closed Won**, save. 4. Click the vehicle. | The vehicle's Status is **Sold** without anyone editing it. The sale leaves **All Open Opportunities** and appears in **AutoDrive - Closed Won**. | Pass | Vehicle showed Sold. |
| UAT-02 | US-01 A sold car can't be sold again | 1. Open another open sale (e.g. **AD Rerun … Sale 3 (open)**). 2. Edit **Vehicle** and search for the car sold in UAT-01. | The sold car is not offered. Each result shows model, colour, year and status. | Pass |  |
| UAT-03 | US-07 See live availability | 1. **Vehicles** tab, list **All**. | Every car shows Available, Reserved or Sold. View only. | Pass |  |
| UAT-04 | US-23 Same qualifying questions for every walk-in | 1. **Leads** → **New**. 2. Name, phone, Channel = Walk-in. 3. Find **Qualification Answers**, **Visit Purpose**, **Vehicle Model of Interest**. 4. Save. | The fields are there, Phone and Email can be filled in, there is no "assignment rule" checkbox, and the lead saves. | Pass | Passed after Phone/Email access fix (19 Oct). |
| UAT-05 | US-23 Purpose (and vehicle for a sale) needed to convert | 1. Open a lead at Contacted; on the path, click **Contacted** to see its key fields. 2. Clear Visit Purpose, click **Convert** → **Convert**. 3. Set Visit Purpose = Enquiry, Convert again with **Don't create an opportunity** ticked. 4. On another lead (Purchase, no vehicle), Convert creating the sale. | Step 2 blocked. Step 3 converts with no sale (kept as a customer record). Step 4 blocked until a Vehicle of Interest is picked on the lead. Path shows only New → Contacted → Converted. | Pass |  |
| UAT-07 | US-30 Same person is not entered twice | 1. New lead with the **same phone number** as an existing customer. 2. Save. | A message warns that a matching record already exists. | Pass | Tested with Daniel Okoro. |
| UAT-08 | US-31 Instagram enquiries with no visit booked | 1. New lead, Channel = **Instagram**, no Booked Visit Date. 2. **Leads** → **AutoDrive - Enquiries No Visit Booked**. 3. Add a Booked Visit Date, save, reopen the list. | On the list at step 2, gone at step 3. | Skipped | Not run (no social media leads yet). |
| UAT-11a | US-38 Import when a model is out of stock | 1. Open a customer → **Import Requests** → **New**. 2. Pick the model, save. | The request saves with status Requested. (Finance moves it on in UAT-11b.) | Pass |  |
| UAT-12 | US-16 Fleet customer in one place | 1. Open a **Fleet/Corporate** account (e.g. Lagos Ride Hailing). | Contact person, agreed discount rate, owner and past sales on one page. | | |
| UAT-15 | US-02 Small discount is approved at once | 1. On an open Full Payment sale, **Discount Requests** → **New**. 2. Rate **5%** or less, reason, save. | Approved straight away (Auto Approved ticked). | Pass |  |
| UAT-16 | US-02 Larger discount goes up the chain | 1. On another open Full Payment sale, request **7.5%**. 2. Open the request. | Current Step = **With Showroom Manager**, with date and time. (Manager approves in UAT-17.) | Pass |  |
| UAT-21 | US-25 No discount on an instalment deal | 1. On an **Instalment** sale for an individual, try to create a Discount Request. | Blocked with a message saying why. | Pass |  |
| UAT-22 | US-25 Switching to instalment cancels the discount | 1. Open **AD Rerun … Sale 2 (discount approved)**. 2. Payment Mode = **Instalment**, save. | The approved discount becomes **Invalidated**. | Pass |  |
| UAT-36a | NFR-01 Money is hidden | 1. Open any sale and look for payments, instalment plans and price fields. | None visible. | Pass |  |
| UAT-40b | US-11 Website lead reaches a rep | 1. Be logged in as the Sales Rep (Login As is fine). 2. Wait up to 5 minutes after UAT-40a. 3. **Leads** → **My Leads**. | The website lead is yours with no clicking: Channel = Web, the chosen vehicle, Auto Assigned At filled in, plus a "lead assigned to you" email. A logged-out rep, or one with 5 open leads, gets none. | Pass | Fleet enquiry (Hillary Emmanuel) auto-assigned. |

## 3. Showroom Manager

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-06 | US-30 Walk-in goes to a rep without retyping | 1. New lead, Channel = **Walk-in**, phone, save. 2. Look at **Lead Owner**. | The owner is a sales rep, picked automatically. | | |
| UAT-09 | US-32 Where deals are stuck | 1. **Leads** → **AutoDrive - Open Prospects**. 2. **AutoDrive - Prospects With No Rep**. 3. **Opportunities** → **AutoDrive - Open Deals**. | Each list shows source/channel, owner and stage/status. | | |
| UAT-10 | US-12 Low-stock alert | 1. Open a **Vehicle Model**. 2. Set **Low Stock Threshold** above its Available Stock, save. **(next day)** check notifications. | One alert for that model; it does not repeat. | | |
| UAT-13 | US-16 Fleet order with several vehicles | 1. Open an open sale for a fleet account. 2. **Fleet Vehicles** → **New**, add two cars with prices. | Fleet Vehicle Count = 2 and the total. Closing the sale marks both cars **Sold**. | Pass | Run as Sales Rep: Type + How many, identical cars reserved, totals and Fleet Summary update; delete line releases car; lost sale releases cars. |
| UAT-14 | US-16 Several vehicles only for fleet | 1. On a sale for an **Individual**, try to add a Fleet Vehicle. | An error says fleet sales only. | Pass | Not enough stock refused; Import Request raised. |
| UAT-17 | US-02 Manager sees where the discount sits | 1. Home → **Items to Approve**, approve the request from UAT-16. 2. Reopen it. | Step now **With Finance**, with a new date/time. | | |
| UAT-20 | US-20 Fleet agreed rate applies | 1. On a fleet sale (account has an Agreed Discount Rate), new Discount Request, leave the rate blank, save. | The fleet's agreed rate is filled in automatically. | Pass | Fleet rate applied on fleet total (run as Sales Rep). |

## 4. Finance Team

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-18 | US-08 Finance sees what waits for them | 1. Home → **Items to Approve**. 2. Approve the request from UAT-17. | It was listed with its date; after approving it moves to **With Head Office** at once. | | |
| UAT-11b | US-38 Finance moves the import on | 1. Open the import request from UAT-11a. 2. Move the status forward step by step to **Arrived**. | Each step saves; the request is visible to Finance. | | |
| UAT-23 | US-03 Payment recorded once, balance updates itself | 1. Open an instalment on an active plan. 2. **Payments** → **New**, amount, save. | Amount Paid and Balance update; Recorded By and date filled in. | | |
| UAT-24 | US-28 Short payment (475 against 500) | 1. On an instalment of 500, record **475**. | Balance shows **25** owed. | | |
| UAT-25 | US-28 Extra payment becomes credit | 1. On another instalment, pay more than is due. | The extra shows as a credit. | | |
| UAT-30 | US-17 Alert when a customer first defaults | 1. Find an instalment 30+ days overdue. **(next day)** check notifications and Default Alert Sent. | One alert with customer, amount and days overdue; no repeat. | | |
| UAT-31 | US-15 / US-19 Reminder 3 days before due | 1. Note an unpaid instalment due in exactly 3 days. **(next day)** check its customer's **Customer Messages**. | A reminder email with the amount due and the date. None for paid instalments. | | |
| UAT-34 | US-37 Completion email | 1. Record the final payment that clears a plan. 2. Open the plan. | Completion Email Sent ticked; one email only. | | |
| UAT-38a | US-06 Payment request routed to Finance | 1. **Cases** → **All Open Cases**. | The "Payments" case from UAT-37 is in **AD Finance Cases** (or with a Finance user), Routed To = Finance. | | |

## 5. Head of Finance

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-19 | US-02 / NFR-03 Who approved and when | 1. Approve the request from UAT-18 (Head Office step). 2. Open it. | Status **Approved**; Approved By and Approved On filled in. | | |
| UAT-26 | US-29 30% down minimum | 1. New Instalment Plan with a down payment under **30%**. | Blocked with a message. | | |
| UAT-27 | US-29 12-month maximum | 1. On a plan, Term = **13** months. | Blocked with a message. | | |
| UAT-28 | US-29 Guarantor and sign-off | 1. Sign off a plan with no guarantor. 2. Close an instalment sale before sign-off and deposit. | Both blocked. | | |
| UAT-29 | US-05 Late and defaulting customers | 1. **Instalment Plans** → **Needs Attention**. | Every Late, Defaulted or With Legal plan, status worked out from payments. | | |
| UAT-32 | US-09 Bank vs recorded totals | 1. **Reconciliation Entries** → **New**, Bank Total different from Recorded Total, save. | The Difference shows and the entry stays flagged until explained. | | |
| UAT-33a | US-36 Escalate an unrecoverable default to Legal | 1. On a Defaulted plan, create a **Legal Escalation** (all three conditions met). | Saves; Legal Team Notified At filled in; the email gives name, months defaulted and total owed. | | |
| UAT-35 | US-26 Finance sees stock, models and prices | 1. **Vehicle Models** and **Vehicles**. 2. **AutoDrive - Models With No List Price**. | Stock and list prices visible, read only; models without a price listed. | | |

## 6. Sales Rep (short return)

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-11c | US-38 Rep told the import arrived | 1. Check notifications / email. 2. Open the import request. | A notice that the vehicle arrived; status **Arrived**. | | |

## 7. Legal Team

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-33b | US-36 Legal can see the escalation | 1. **Legal Escalations** → **All**. 2. Open the one from UAT-33a. | The record with customer, months defaulted and total owed, view only. | | |

## 8. Customer Service Agent

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-36b | NFR-01 Money is hidden | 1. Open a customer's sale. | No payment amounts, plans or prices. | | |
| UAT-38b | US-06 Requests routed to the right team | 1. **Cases** → **All Open Cases**. | "Buying a vehicle" case → Showroom (AD Showroom Cases); "A problem with my vehicle" case → Customer Service. | | |
| UAT-39 | US-11 Assigned to an online person | 1. Stay logged in as the Agent. 2. Ask someone to submit "A problem with my vehicle" on the site. 3. Wait up to 5 minutes, **Cases** → **My Cases**. | The case is yours automatically (Auto Assigned At filled in). Logged out, it waits in the Customer Service queue. | | |
| UAT-41 | US-04 One view of the customer | 1. Search a customer by name or phone, open the account. | Purchases, cases and messages on one record, view only, no payment amounts. | | |
| UAT-42 | US-35 Customer told when status changes | 1. Open your case from UAT-39. 2. Status **Working**, then **Closed**. 3. **Customer Messages** on the case. | One status update and one resolution message, each with the time sent. Changing only the owner sends nothing. | | |
| UAT-46 | US-22 Satisfaction score 1 to 10 | 1. On a closed case, CSAT Score **11**, save. 2. **8**, save. | 11 rejected; 8 saves. Blank = unrated. | | |
| UAT-48 | US-14 Search the knowledge base | 1. **Knowledge Articles**, search a keyword. | Matching published articles with issue and agreed answer. | | |

## 9. Head of Customer Service

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-43 | US-10 Every case's owner and status | 1. **Cases** → **All Cases**. | Every case with one owner and one status. | | |
| UAT-44 | US-33 Stuck case escalates itself | 1. Leave a new case with no reply for over **1 hour**. 2. Reopen it. | Priority High, Escalated At filled in, Head of CS flagged. Closed cases don't escalate. | | |
| UAT-45 | US-13 Response and resolution times | 1. Reply to a case, then close it. 2. Open it. 3. Report **AD Cases by Status**. | First Response At and Resolved At filled in; the auto acknowledgement doesn't count. | | |
| UAT-47 | US-24 Satisfaction trend | 1. Report **AD Satisfaction Scores**. | Scores over time with the number of ratings; unrated not counted as low. | | |
| UAT-49 | US-18 Head maintains articles | 1. Edit an article, save. 2. Set another to **Retired**. 3. (Optional) check as the Agent. | The edit shows at once; the retired article is hidden from agents but not deleted. | | |

## 10. Management

| ID | Story | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|
| UAT-50 | US-21 One dashboard for the whole business | 1. Open Home / the Management dashboard. | Sales, stock, finance and service figures together, no errors. | | |

---

## Not tested (decided out of scope)
- **Text (SMS) reminders** (US-15 / US-19): email only. Team decision, 18 Oct 2026.
- Items on the workbook's **Won't Have** sheet.

## Results summary
| Role | Tests | Passed | Failed | Tester | Date |
|---|---|---|---|---|---|
| Website visitor | 2 | | | | |
| Sales Rep | 16 | 15 | 0 | Hillary | 20 Oct 2026 (1 skipped) |
| Showroom Manager | 7 | | | | |
| Finance Team | 9 | | | | |
| Head of Finance | 8 | | | | |
| Legal Team | 1 | | | | |
| Customer Service Agent | 7 | | | | |
| Head of Customer Service | 5 | | | | |
| Management | 1 | | | | |
