# AutoDrive — User Story Tests (UAT)

**What this is:** one simple test for each user story in the v8 requirements workbook, so anyone with a login can check that the system does what the story asks.
It is separate from `AutoDrive_Test_Plan.md`, which is the detailed QA checklist used to find and fix build errors.

**Sandbox:** autodrive-dev (Group3SB) · **Version:** 19 Oct 2026

---

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
   - **Sale 3 (no Lead)**: for a customer who never came through a lead (UAT-02)
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

## Sales and vehicles

| ID | Story | Login as | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|---|
| UAT-01 | US-01 A sold car shows as sold straight away | Sales Rep | 1. Open the sale **AD Rerun … Sale 1 (open)**. 2. Note the vehicle on it. 3. Change Stage to **Closed Won** and save. 4. Click the vehicle. | The vehicle's Status is **Sold** without anyone editing it. | | |
| UAT-02 | US-01 A sold car can't be sold again | Sales Rep | 1. Open **AD Rerun … Sale 3 (no Lead)**. 2. Edit **Vehicle** and search for the car sold in UAT-01. | The sold car is not offered (only Available or Reserved cars appear). | | |
| UAT-03 | US-07 See live availability | Sales Rep | 1. Open the **Vehicles** tab, list **All**. | Every car shows Available, Reserved or Sold. You can view but not edit them. | | |
| UAT-04 | US-23 Same qualifying questions for every walk-in | Sales Rep | 1. Open **Leads** → **New**. 2. Fill in name and phone, Channel = Walk-in. 3. Look for **Qualification Answers**, **Visit Purpose** and **Vehicle Model of Interest**. 4. Save. | The fields are there and the lead saves. | | |
| UAT-05 | US-23 Qualifying needs purpose and vehicle | Sales Rep | 1. Open the lead from UAT-04. 2. Clear Visit Purpose. 3. Set Status = **Qualified** and save. | An error asks for Visit Purpose and Vehicle Model of Interest. | | |
| UAT-06 | US-30 Walk-in goes to a rep without retyping | Showroom Manager | 1. Create a lead with Channel = **Walk-in**. 2. Save and look at **Lead Owner**. | The owner is a sales rep, picked automatically. | | |
| UAT-07 | US-30 Same person is not entered twice | Sales Rep | 1. Create a new lead with the **same phone number** as an existing customer. 2. Save. | A message warns that a matching record already exists. | | |
| UAT-08 | US-31 Instagram enquiries with no visit booked are listed | Sales Rep | 1. Create a lead with Channel = **Instagram** and no Booked Visit Date. 2. Open **Leads** → list **AutoDrive - Enquiries No Visit Booked**. 3. Enter a Booked Visit Date on the lead, save, and reopen the list. | The lead is on the list at step 2 and gone at step 3. | | |
| UAT-09 | US-32 Manager sees where deals are stuck | Showroom Manager | 1. **Leads** → **AutoDrive - Open Prospects**. 2. **Leads** → **AutoDrive - Prospects With No Rep**. 3. **Opportunities** → **AutoDrive - Open Deals**. | Each list shows source/channel, owner (rep) and stage/status. | | |
| UAT-10 | US-12 Low-stock alert | Showroom Manager | 1. Open a **Vehicle Model**. 2. Set **Low Stock Threshold** above its Available Stock. 3. Save. **(next day)** check notifications. | One alert for that model. It does not repeat the day after. | | |
| UAT-11 | US-38 Import when a model is out of stock | Sales Rep | 1. Open a customer → **Import Requests** → **New**. 2. Pick the model and save. 3. Log in as Finance and move the status forward to **Arrived**. 4. Log back in as Sales Rep. | The request is visible to Rep, Showroom Manager and Finance. The rep gets a notice when it arrives. | | |
| UAT-12 | US-16 Fleet customer in one place | Sales Rep | 1. Open a **Fleet/Corporate** account (e.g. Lagos Ride Hailing). | Contact person, agreed discount rate, owner and the list of past sales are all on the one page. | | |
| UAT-13 | US-16 Fleet order with several vehicles | Showroom Manager | 1. Open an open sale for a fleet account. 2. In **Fleet Vehicles** click **New**, add two cars with prices. | The sale shows Fleet Vehicle Count = 2 and the total. Closing the sale marks both cars **Sold**. | | |
| UAT-14 | US-16 Several vehicles only for fleet | Showroom Manager | 1. On a sale for an **Individual** customer, try to add a Fleet Vehicle. | An error says this is for fleet sales only. | | |

## Discounts

| ID | Story | Login as | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|---|
| UAT-15 | US-02 Small discount is approved at once | Sales Rep | 1. On an open Full Payment sale, **Discount Requests** → **New**. 2. Rate = **5%** or less, add a reason, save. | Approved straight away (Auto Approved ticked), no approval needed. | | |
| UAT-16 | US-02 Larger discount goes up the chain | Sales Rep | 1. On another open Full Payment sale, request **7.5%**. 2. Open the request. | Current Step = **With Showroom Manager**, with the date and time it got there. | | |
| UAT-17 | US-02 Manager sees where it sits | Showroom Manager | 1. Open **Items to Approve** on Home and approve the request from UAT-16. 2. Reopen the request. | Step now **With Finance**, with a new date/time. No phone call needed to know. | | |
| UAT-18 | US-08 Finance sees what waits for them | Finance Team | 1. Home → **Items to Approve**. 2. Approve the request. | The request was listed with its date. After approving, it moves to **With Head Office** at once. | | |
| UAT-19 | US-02 / NFR-03 Who approved and when | Head of Finance | 1. Approve the request (Head Office step). 2. Open the request. | Status **Approved**; Approved By and Approved On filled in. | | |
| UAT-20 | US-20 Fleet agreed rate applies | Showroom Manager | 1. On a sale for a fleet account with an Agreed Discount Rate, create a Discount Request and leave the rate blank. 2. Save. | The fleet's agreed rate is filled in automatically and saved on the request. | | |
| UAT-21 | US-25 No discount on an instalment deal | Sales Rep | 1. On an **Instalment** sale for an individual, try to create a Discount Request. | Blocked with a message saying why. | | |
| UAT-22 | US-25 Switching to instalment cancels the discount | Sales Rep | 1. Open **AD Rerun … Sale 2 (discount approved)**. 2. Change Payment Mode to **Instalment** and save. | The approved discount becomes **Invalidated**. | | |

## Payments and instalments

| ID | Story | Login as | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|---|
| UAT-23 | US-03 Payment recorded once, balance updates itself | Finance Team | 1. Open an instalment on an active plan. 2. **Payments** → **New**, enter the amount, save. | Amount Paid and Balance update on their own. Recorded By and the date are filled in. | | |
| UAT-24 | US-28 Short payment (475 against 500) | Finance Team | 1. On an instalment of 500, record a payment of **475**. | Balance shows **25** still owed. Nothing is rounded away. | | |
| UAT-25 | US-28 Extra payment becomes credit | Finance Team | 1. On another instalment, pay more than is due. | The extra shows as a credit for the customer. | | |
| UAT-26 | US-29 30% down minimum | Head of Finance | 1. Create an Instalment Plan with a down payment under **30%**. | Blocked with a message. | | |
| UAT-27 | US-29 12-month maximum | Head of Finance | 1. On a plan, set Term to **13** months. | Blocked with a message. | | |
| UAT-28 | US-29 Guarantor and sign-off | Head of Finance | 1. Try to sign off a plan with no guarantor. 2. Then try to close an instalment sale before the plan is signed off and the deposit received. | Both are blocked. | | |
| UAT-29 | US-05 One list of late and defaulting customers | Head of Finance | 1. **Instalment Plans** → list **Needs Attention**. | Every Late, Defaulted or With Legal plan is listed, with the status worked out from payments. | | |
| UAT-30 | US-17 Alert when a customer first defaults | Finance Team | 1. Find an instalment 30+ days overdue. **(next day)** check notifications and the Default Alert Sent box. | One alert naming the customer, amount and days overdue. It doesn't repeat. | | |
| UAT-31 | US-15 / US-19 Reminder 3 days before due | Finance Team | 1. Note an unpaid instalment due in exactly 3 days. **(next day)** open its customer's **Customer Messages**. | A reminder email was sent, with the amount still due and the date. None is sent for instalments already paid. | | |
| UAT-32 | US-09 Bank vs recorded totals | Head of Finance | 1. **Reconciliation Entries** → **New**. 2. Enter a Bank Total different from the Recorded Total, save. | The Difference shows and the entry is flagged until explained. | | |
| UAT-33 | US-36 Legal is told about an unrecoverable default | Head of Finance | 1. On a Defaulted plan, create a **Legal Escalation** (all three conditions met). 2. Log in as Legal Team. | Legal sees the record. Legal Team Notified At is filled in; the email gives name, months defaulted and total owed. | | |
| UAT-34 | US-37 Completion email | Finance Team | 1. Record the final payment that clears a plan. 2. Open the plan. | Completion Email Sent is ticked; one email only. | | |
| UAT-35 | US-26 Finance sees stock, models and prices | Head of Finance | 1. Open **Vehicle Models** and **Vehicles**. 2. Open list **AutoDrive - Models With No List Price**. | Stock and list prices are visible, read only. Any model without a price shows on that list. | | |
| UAT-36 | NFR-01 Money is hidden from others | Sales Rep, then Customer Service Agent | 1. Look for **Payments**, **Instalment Plans** or price amounts on a sale. | Not visible to either role. | | |

## Customer service

| ID | Story | Login as | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|---|
| UAT-37 | US-06 / US-34 Website request becomes a case with a reference number | Website visitor | 1. Open the site. 2. Fill in **Contact support**, choose **Payments or my instalment plan**, submit. | A reference number appears on screen, and an email with the same number arrives. | | |
| UAT-38 | US-06 Routed to the right team | Finance Team | 1. **Cases** → **All Open Cases**. | The case from UAT-37 is in the **AD Finance Cases** queue (or with a Finance user), Routed To = Finance. Repeat UAT-37 with "Buying a vehicle" → Showroom, and "A problem with my vehicle" → Customer Service. | | |
| UAT-39 | US-11 Assigned to an available person | Customer Service Agent | 1. Open **Omni-Channel** in the bottom bar and set **Available**. 2. A visitor submits "A problem with my vehicle" (UAT-37 steps). | A request pops up to accept. After accepting, you are the case owner. Offline, the case waits in the queue. | | |
| UAT-40 | US-11 Website sales enquiry reaches a rep | Sales Rep | 1. Be logged in as the Sales Rep (a real login; "Login As" may not count as online). 2. A visitor submits **Sales enquiry** on the site. 3. Wait up to 15 minutes, open **Leads** → **My Leads**. | The lead is yours with no clicking, Channel = Web, the chosen vehicle, and Auto Assigned At filled in. A rep with 5 open leads, or logged out, gets none. | | |
| UAT-41 | US-04 One view of the customer | Customer Service Agent | 1. Search a customer by name or phone. 2. Open the account. | Purchases, cases and past messages are all on the record, view only, with no payment amounts. | | |
| UAT-42 | US-35 Customer told when status changes | Customer Service Agent | 1. Open your case from UAT-39. 2. Change Status to **Working**, then **Closed**. 3. Check **Customer Messages** on the case. | One status update and one resolution message, each with the time sent. Changing only the owner sends nothing. | | |
| UAT-43 | US-10 Head sees every case's owner and status | Head of Customer Service | 1. **Cases** → **All Cases**. | Every case with one owner and one status. | | |
| UAT-44 | US-33 Stuck case escalates itself | Head of Customer Service | 1. Leave a new case with no reply for over **1 hour**. 2. Reopen it. | Priority is High, Escalated At is filled in and the Head of CS is flagged. A closed case does not escalate. | | |
| UAT-45 | US-13 Response and resolution times | Head of Customer Service | 1. Reply to a case, then close it. 2. Open the case. 3. Open report **AD Cases by Status**. | First Response At and Resolved At are filled in; the auto acknowledgement does not count as first response. | | |
| UAT-46 | US-22 Satisfaction score 1 to 10 | Customer Service Agent | 1. On a closed case, enter CSAT Score **11**, save. 2. Enter **8**, save. | 11 is rejected; 8 saves. Blank means unrated. | | |
| UAT-47 | US-24 Satisfaction trend | Head of Customer Service | 1. Open report **AD Satisfaction Scores**. | Scores over time, with the number of ratings. Unrated cases are not counted as low. | | |
| UAT-48 | US-14 Search the knowledge base | Customer Service Agent | 1. Open **Knowledge Articles** and search a keyword. | Matching published articles, each with issue and agreed answer. | | |
| UAT-49 | US-18 Head maintains articles | Head of Customer Service | 1. Edit an article and save. 2. Set another to **Retired**. 3. Log in as Agent. | The edit shows at once; the retired article is hidden from the agent but not deleted. | | |

## Management

| ID | Story | Login as | Steps | You should see | Result | Notes |
|---|---|---|---|---|---|---|
| UAT-50 | US-21 One dashboard for the whole business | Management | 1. Open Home / the Management dashboard. | Sales, stock, finance and service measures together, with figures (no errors). | | |

---

## Not tested (decided out of scope)
- **Text (SMS) reminders** (US-15 / US-19): reminders go by email only. Team decision, 18 Oct 2026.
- Items on the workbook's **Won't Have** sheet.

## Results summary
| Area | Tests | Passed | Failed | Tester | Date |
|---|---|---|---|---|---|
| Sales and vehicles | 14 | | | | |
| Discounts | 8 | | | | |
| Payments and instalments | 14 | | | | |
| Customer service | 13 | | | | |
| Management | 1 | | | | |
