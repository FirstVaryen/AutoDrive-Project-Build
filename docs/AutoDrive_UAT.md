# AutoDrive Motors – User Acceptance Testing

This document holds the tests for the AutoDrive Motors Salesforce system. Each tester runs the tests for the roles given to them, as that role's user.

## 1. How to test

- **Where:** Salesforce sandbox **Group3SB**, in the **AutoDrive Motors** app, on a desktop browser.
- **Website:** https://dk1791276250211--group3sb.sandbox.my.site.com/s/ (open it in a private window).
- **Logging in:** the UAT coordinator logs you in as the role you are testing. A banner at the top shows the user you are working as.
- **Finding records:** lists open on *Recently Viewed*. Click the list name and choose another list, or use the search bar at the top.
- **Recording results:** follow the steps in order. Write what you saw under **Actual result**, then **Pass** or **Fail**. A test passes only when every step passes.
- **Problems:** take a screenshot, note the test and step number, and tell the UAT coordinator.

## 2. Testers and roles

| Tester | Roles they test | Pages |
|---|---|---|
| Henry | Sales Rep, Showroom Manager | 2 – 7 |
| Obed | Finance Team, Head of Finance, Legal Team | 8 – 13 |
| Shedrach | Customer Service Agent, Head of Customer Service, Management | 14 – 17 |

| Role | Test user |
|---|---|
| Sales Rep | test.salesrep@autodrive.group3sb.test |
| Showroom Manager | test.showroommanager@autodrive.group3sb.test |
| Finance Team | test.financeteam@autodrive.group3sb.test |
| Head of Finance | test.headoffinance@autodrive.group3sb.test |
| Legal Team | test.legalteam@autodrive.group3sb.test |
| Customer Service Agent | test.csagent@autodrive.group3sb.test |
| Head of Customer Service | test.headofcs@autodrive.group3sb.test |
| Management | test.management@autodrive.group3sb.test |

**Order of testing.** Some tests follow on from another role's test. Where a test says **After**, wait until that test is done.

## 3. Sales Rep – Henry

**Test data for this role** (already in the system, owned by the Sales Rep)

| Ref | Record | Used in |
|---|---|---|
| L-1 | Lead **Adaeze Nwosu**, wants Kia Sportage 2026 White (in stock) | SR-3 |
| L-2 | Lead **Tunde Fashola**, wants Toyota Corolla 2026 White (sold out) | SR-3 |
| L-3 | Contact **Daniel Okoro**, phone +2348010180943 (existing customer) | SR-1 |
| O-1 | Opportunity **Bisi Adewale - Toyota Hilux 2026 Red** (full payment, Offer) | SR-5 |
| O-2 | Opportunity **Kelechi Obi - Honda CR-V 2026 White** (full payment, Offer) | SR-5 |
| O-3 | Opportunity **Musa Ibrahim - Toyota Camry 2026 White** (full payment, Offer) | SR-4 |
| O-4 | Opportunity **Ronke Alabi - Kia Sportage 2026 White** (full payment, Offer) | SR-6 |
| O-5 | Opportunity **Chidi Eze - Toyota Hilux 2026 Grey** (full payment, Offer) | SR-4, SR-5 |
| O-6 | Opportunity **Zainab Bello - Honda CR-V** (instalment, deposit not paid) | SR-6 |
| O-7 | Opportunity **Lagos Ride Hailing Ltd - Fleet** (fleet customer, agreed rate 5%) | SR-7 |
| V-1 | Every vehicle type has 5 cars available, except **Toyota Corolla 2026 White** and **Toyota Camry 2026 Blue**, which are sold out | SR-3, SR-4 |

#### SR-1: Record a walk-in customer
*As a sales rep, I want every walk-in recorded the same way, so that no customer is lost.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Leads** tab, then **New**. Enter First Name **Amaka**, Last Name **Okafor**, Phone **08031110099**, AM Channel **Walk-in** | The form also asks for AM Qualification Answers, Visit Purpose and Vehicle of Interest | | |
| 2 | In AM Qualification Answers type **Budget ready, buying this month**. Set Visit Purpose to **Purchase**. In Vehicle of Interest type **Kia** and pick **Kia Sportage 2026 White**. Click **Save** | The lead saves. Under Vehicle of Interest a green flag shows **In stock: Available (5)** | | |
| 3 | Click **Leads**, then **New**. Enter First Name **Daniel**, Last Name **Okoro**, Phone **+2348010180943**, AM Channel **Walk-in**. Click **Save** | A warning that this customer may already exist | | |
| 4 | Click **Leads**, then **New**. Enter First Name **Yemi**, Last Name **Alade**, Phone **08031110098**, AM Channel **Returning/High-profile**. Click **Save** | The lead saves and opens as read only. The Lead Owner is the Showroom Manager | | |
| 5 | Click **Leads**. Click the list name under Leads and choose **AutoDrive - High-profile Clients** | Yemi Alade is listed, owned by the Showroom Manager | | |
| 6 | Click the list name again and choose **AutoDrive - My Leads** | Yemi Alade is not on your list | | |

#### SR-2: Website enquiries come to me
*As a sales rep, I want website enquiries given to me automatically, so that I can respond quickly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the website in a private window: https://dk1791276250211--group3sb.sandbox.my.site.com/s/ (after go-live, the live website address is used). Click **Sales enquiry**, enter your name, your email and a car. Click **Submit** | A thank-you message | | |
| 2 | Wait 5 minutes. In Salesforce click **Leads**, choose the list **AutoDrive - My Leads** | Your enquiry is listed, AM Channel **Web** | | |
| 3 | Check your email inbox | An email saying a lead has been given to you | | |

#### SR-3: Convert a lead and request an import
*As a sales rep, I want to see straight away if a car is sold out and request an import, so that the customer is not kept waiting.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click **Leads**, choose **AutoDrive - My Leads**, open **Tunde Fashola** (L-2) | Under Vehicle of Interest a red flag shows **Sold out - an import will be needed** | | |
| 2 | Open **Adaeze Nwosu** (L-1). Click the pencil beside Visit Purpose, choose **--None--**, click **Save** | Refused: Visit Purpose must be filled in | | |
| 3 | Click **Cancel**. Click **Convert** at the top right, leave the details as they are, click **Convert** | An opportunity is created for Adaeze Nwosu | | |
| 4 | Open the new opportunity | AM Vehicle Wanted shows **Kia Sportage 2026 White**, with a green flag **Car assigned · Stock: Available (5)**. AM Assigned Car shows a Kia Sportage 2026 White car held for this customer | | |
| 5 | Open **Tunde Fashola** (L-2). Click **Convert**, then **Convert**. Open the new opportunity | AM Vehicle Wanted shows **Toyota Corolla 2026 White**, with a red flag **Sold out - click Request Import**. AM Assigned Car is empty | | |
| 6 | On Tunde Fashola's opportunity, click **Request Import** at the top right of the page (beside **Request Discount**) | A window opens with AM Vehicle Model **Toyota Corolla 2026 White**, Quantity **1** and Reason for Request **Out of stock** already filled in | | |
| 7 | Click **Save** | The message **Import requested. You can follow it under Import Requests on this opportunity.** The request shows under **Import Requests** on the right-hand side, AM Status **Requested** | | |
| 8 | Click **Request Import** again, clear **Reason for Request**, click **Save** | Refused: **Choose the type of car, the reason for the request (Out of stock or Client request) and how many.** Click **Cancel** | | |

#### SR-4: Choose a vehicle and close an opportunity
*As a sales rep, I want to see what is in stock while I choose a vehicle, so that I never sell a car twice.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click **Opportunities**, choose the list **All Opportunities**, open **Chidi Eze - Toyota Hilux 2026 Grey** (O-5) | AM Vehicle Wanted shows **Toyota Hilux 2026 Grey**. Under it a green flag shows **Car assigned · Stock:** with the number available and reserved. AM Assigned Car shows the car held for this customer | | |
| 2 | Click the pencil beside **AM Vehicle Wanted**, clear it and type **Hilux** | Each Hilux type is listed once, with its stock under it, e.g. **Available (5)** or **Available (4) · Reserved (1)** | | |
| 3 | Pick **Toyota Hilux 2026 Red** and click **Save** | Saved. AM Assigned Car changes to a Hilux Red car and the green flag shows the Hilux Red stock | | |
| 4 | Click the pencil beside **AM Vehicle Wanted** again, clear it and type **Corolla 2026 White**. Look at the result, then click **Cancel** | Toyota Corolla 2026 White is listed once with **Sold out** under it | | |
| 5 | Open **Musa Ibrahim - Toyota Camry 2026 White** (O-3). On the stage bar click **Closed**, then **Select Closed Stage**, choose **Closed Won**, click **Save** | The opportunity is Closed Won | | |
| 6 | Click the car in **AM Assigned Car** | Status **Sold** | | |
| 7 | Go back. Click **Opportunities**, choose the list **AutoDrive - Closed Won**, open **Musa Ibrahim - Toyota Camry 2026 White**. Click any pencil, change the value and click **Save** | Refused: **This opportunity is closed and can't be changed. Only a head of department can change a closed opportunity.** | | |
| 8 | Click the **AM Vehicle Models** tab, choose the list **All AM Vehicle Models** | Each vehicle type is listed once, with AM Stock, AM Available Stock, AM Reserved, AM Sold and AM List Price. Toyota Camry 2026 White now shows one more sold | | |

#### SR-5: Request a discount
*As a sales rep, I want to request a discount and see where it is, so that I can update the customer.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click **Opportunities**, choose the list **All Opportunities**, open **Bisi Adewale - Toyota Hilux 2026 Red** (O-1). Check the stage bar shows **Offer**. At the top right of the page, click **Request Discount** (beside **Follow**). Choose Discount Rate **5%**, type **Loyal customer** in AM Reason, click **Save** | Under Sale Details, AM Approval Status shows a green marker and **5.00% discount approved** | | |
| 2 | Look at **Discount Requests** on the right-hand side | The request shows AM Current Step **Approved**, the discount and the price after discount | | |
| 3 | Open **Kelechi Obi - Honda CR-V 2026 White** (O-2), another full-payment opportunity at **Offer**. At the top right of the page, click **Request Discount** (beside **Follow**). Choose **7.5%**, type **Price match** in AM Reason, click **Save** | Under Sale Details, AM Approval Status shows an orange marker and the message **7.50% discount waiting: With Showroom Manager**, telling you it was sent to the Showroom Manager | | |
| 4 | Under **Discount Requests** on the right-hand side, click the request's name (it starts with DR-) | The request opens and shows the customer, the vehicle with its price, the discount value and the price after discount | | |
| 5 | Open **Chidi Eze - Toyota Hilux 2026 Grey** (O-5). At the top right of the page, click **Request Discount** (beside **Follow**). Choose **10%**, type **Customer asked for more** in AM Reason, click **Save** | AM Approval Status shows an orange marker and **10.00% discount waiting: With Showroom Manager** | | |
| 6 | Go back to **Bisi Adewale - Toyota Hilux 2026 Red**. Under **Sale Details**, click the pencil beside **AM Payment Mode**, choose **Instalment**, set **AM Instalment Duration (Months)** to **6**, click **Save** | The 5% discount shows **Invalidated** under Discount Requests. The price returns to the full list price and AM Down Payment Agreed (30%) is 30% of the full price | | |

#### SR-6: Instalment opportunities
*As a sales rep, I want instalment terms worked out for me, so that I follow the payment rules.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Ronke Alabi - Kia Sportage 2026 White** (O-4). Under **Sale Details**, click the pencil beside **AM Payment Mode**, choose **Instalment**, set **AM Instalment Duration (Months)** to **6**, click **Save** | AM Down Payment Agreed (30%) shows 30% of the price. AM Amount on Instalment and AM Monthly Instalment are worked out | | |
| 2 | On the same opportunity, click **Request Discount** at the top right of the page. Choose **5%**, type a reason, click **Save** | Refused: **Discounts are not permitted on instalment deals for individual customers.** Click **Cancel** | | |
| 3 | Open **Zainab Bello - Honda CR-V** (O-6). On the stage bar click **Closed**, then **Select Closed Stage**, choose **Closed Won**, click **Save** | Refused: **An instalment opportunity can only be closed once Finance has recorded the down payment and the Head of Finance has signed off the instalment plan.** | | |

#### SR-7: Fleet opportunities
*As a sales rep, I want a company's vehicles on one opportunity with its agreed rate, so that fleet deals are simple.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Accounts** tab and open **Lagos Ride Hailing Ltd** | AM Agreed Discount Rate **5%** beside Phone; on the right, Contacts shows **Kemi Lawal** and Opportunities shows Lagos Ride Hailing Ltd - Fleet | | |
| 2 | Open **Lagos Ride Hailing Ltd - Fleet** (O-7). On the right-hand side, find **Fleet Vehicles**, click the small drop-down arrow beside it and click **New**. Choose Type **Toyota Hilux 2026 White**, How many **2**, click **Save** | 2 cars of that type are listed under Fleet Vehicles, each Reserved. The fleet total and count update | | |
| 3 | Under **Fleet Vehicles**, click the drop-down arrow and **New** again. Choose **Toyota Hilux 2026 White**, How many **10**, click **Save** | Refused: **Not enough in stock: you asked for 10 but only 3 of this type are available. Nothing was added. Lower the number, or raise an Import Request for this type.** Click **Cancel** | | |
| 4 | At the top right of the page, click **Request Discount** (beside **Follow**). Leave Discount Rate empty, type **Fleet agreement** in AM Reason, click **Save** | The request uses the agreed rate of **5%** on the fleet total | | |

## 4. Showroom Manager – Henry

**Before you start:** the Sales Rep tests SR-1, SR-3 and SR-5 must be done first. They create the high-profile client, the import request and the discount requests used here.

#### SM-1: See where deals are
*As the showroom manager, I want to see open prospects and opportunities, so that I know where deals are stuck.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Leads** tab. Click the list name under Leads and choose **AutoDrive - Open Prospects** | Each open lead shows its AM Channel, Lead Owner and Lead Status | | |
| 2 | Click the list name again and choose **AutoDrive - Prospects With No Rep** | Any lead without a sales rep is listed (the list may be empty) | | |
| 3 | Click the **Opportunities** tab. Click the list name and choose **All Opportunities** | Each opportunity shows its owner and stage | | |

#### SM-2: Approve or reject a discount
*After:* SR-5. *As the showroom manager, I want to approve discounts above 5%, so that pricing stays under control.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Discount Requests** tab. Click the list name and choose **My Approvals - Showroom Manager** | The 7.5% request for **Kelechi Obi** and the 10% request for **Chidi Eze** are listed | | |
| 2 | Click the **Kelechi Obi** request to open it | The request shows the customer, the vehicle with its price, the list price, the discount value and the price after discount | | |
| 3 | Click **Approve or Reject** at the top right | A window shows the same details, the current step **With Showroom Manager**, and a choice of Approve or Reject | | |
| 4 | Choose **Approve**, type **Approved** in Comments, click **Next** | The message **Approved. The request is now: With Finance.** Click **Finish**: you are back on the request and AM Current Step shows **With Finance** | | |
| 5 | Go back to the list **My Approvals - Showroom Manager** and open the **Chidi Eze** request. Click **Approve or Reject**, choose **Reject**, leave Comments empty, click **Next** | Refused: **Give a reason for rejecting.** | | |
| 6 | Type **10% is above what we can offer on this model** in Comments, click **Next**, then **Finish** | The message **Rejected. The request is now: Rejected.** AM Current Step shows **Rejected** | | |
| 7 | Click the **Opportunities** tab, open **Chidi Eze - Toyota Hilux 2026 Grey** | AM Approval Status shows a red marker and **10.00% discount rejected** | | |

#### SM-3: High-profile clients come to me
*After:* SR-1 step 4. *As the showroom manager, I want returning and high-profile clients sent to me, so that I look after them myself.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **bell** icon at the top right corner of the screen, next to your profile picture | A message: **New returning or high-profile client for you**, about Yemi Alade | | |
| 2 | Click the **Leads** tab. Click the list name under Leads and choose **AutoDrive - High-profile Clients** | Yemi Alade is listed and the Lead Owner is you | | |
| 3 | Click **Yemi Alade** to open the lead. Beside **Lead Owner**, click the small person icon with arrows (Change Owner) | A **Change Lead Owner** window opens | | |
| 4 | In the search box type **TestSales**, click **TestSales Rep**, then click **Change Owner** (or **Submit**) | The window closes and the Lead Owner is now TestSales Rep | | |

#### SM-4: Stock and import requests
*As the showroom manager, I want to be warned when stock runs low and to see import requests, so that I can reorder in time.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Vehicle Models** tab (if you cannot see it, click **More** at the end of the tab bar, then **AM Vehicle Models**). Click the list name and choose **All** | Every vehicle model is listed with its stock | | |
| 2 | Click **Kia Sportage 2026 Blue** to open it | AM Available Stock shows **5** | | |
| 3 | Click the pencil beside **AM Low-stock Threshold**, type **6**, click **Save** | Saved | | |
| 4 | Click the **AM Vehicle Models** tab. Click the list name and choose **AutoDrive - Low Stock** | Kia Sportage 2026 Blue is listed | | |
| 5 | The next morning, click the **bell** icon at the top right corner | One message **Low stock alert** for Kia Sportage 2026 Blue | | |
| 6 | The morning after, click the bell again | No second alert for the same model | | |
| 7 | Click the **AM Import Requests** tab. Click the list name and choose **All** | The request raised for **Tunde Fashola** in SR-3, with AM Vehicle Model, Quantity, Reason for Request and Status **Requested** | | |

## 5. Finance Team – Obed

**Test data for this role** (already in the system)

| Ref | Record | Used in |
|---|---|---|
| F-1 | Opportunity **Grace Okon - Toyota Camry 2026 White** (instalment, 6 months, 30% down payment of USD 9,600,000, no plan yet) | FT-2 |
| F-2 | Guarantor **Peter Okon** (income check done) | FT-2 |
| F-3 | Instalment plan for **Segun Ajayi** (Month 2 of 6 is due) | FT-3 |
| F-4 | Instalment plan for **Chiamaka Okonkwo** (Month 1 due 29 Oct) | FT-3, FT-4 |
| F-5 | Instalment plan for **Emmanuel Udo** (only Month 3 of 3 left to pay) | FT-3 |
| F-6 | Instalment plans for **Funke Ayo** (late) and **Folake Ogunleye** (defaulted) | FT-4 |
| F-7 | Import request for **Tunde Fashola** (raised by the Sales Rep in SR-3) | FT-5 |

**Where things are:** the tabs run along the top of the screen. If a tab is not shown, click **More** at the end of the tab bar and pick it there. On an opportunity, the buttons **Create Instalment Plan** and **Record Down Payment** are at the top right of the page, beside **Follow**. On a plan or an instalment, the lists of related records (Instalments, Payments) are under the **Related** tab, next to **Details**. Each instalment is named like **INST-0064 · Segun Ajayi · Month 2 of 6**.

#### FT-1: Approve discounts
*After:* SM-2. *As finance, I want to see the discounts waiting for me, so that none are held up.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Discount Requests** tab. Click the list name under AM Discount Requests and choose **My Approvals - Finance** | The 7.5% request for **Kelechi Obi** is listed | | |
| 2 | Click the **Kelechi Obi** request to open it | The request shows the customer, the vehicle with its price, the list price, the discount value and the price after discount | | |
| 3 | Click **Approve or Reject** at the top right of the request. Choose **Approve**, type **Approved** in Comments, click **Next** | The message **Approved. The request is now: With Head Office.** | | |
| 4 | Click **Finish** | You are back on the request. AM Current Step shows **With Head Office** | | |

#### FT-2: Set up an instalment plan and take the down payment
*As finance, I want to set up a plan and take the down payment, so that the customer can pay monthly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Opportunities** tab. Click the list name under Opportunities and choose **AutoDrive - Plans To Set Up** | **Grace Okon - Toyota Camry 2026 White** is listed with 6 months, a down payment of USD 9,600,000 and the monthly amount | | |
| 2 | Click **Grace Okon - Toyota Camry 2026 White** to open it | AM Approval Status shows an orange marker and **With Finance: payment plan being set up** | | |
| 3 | At the top right of the page, click **Create Instalment Plan** | A window opens with AM Down Payment Amount **9,600,000.00**, AM Term in Months **6** and AM Down Payment % **30.00%** already filled in | | |
| 4 | Click in **AM Guarantor**, type **Peter** and pick **Peter Okon** from the list. Click **Save** | The window closes. On the right, under **Instalment Plans**, a plan for Grace Okon shows Plan Status **Awaiting Sign-off** | | |
| 5 | Click the plan's name to open it. Click the **Related** tab | Under **Instalments** there are 6 months, from **Month 1 of 6** to **Month 6 of 6**, each with its due date and amount | | |
| 6 | Go back to Grace Okon's opportunity. At the top right, click **Record Down Payment** | A window opens with AM Amount **9,600,000.00**, AM Paid On today and AM Type **Down Payment** filled in | | |
| 7 | Choose AM Method **Bank Transfer** and click **Save** | Saved. Under **Payments** on the right the down payment is listed. AM Assigned Car on the opportunity shows its car as **Reserved** | | |
| 8 | Click **Record Down Payment** again, then **Save** | Refused: **The down payment for this opportunity has already been recorded. Record further money as an instalment payment.** Click **Cancel** | | |
| 9 | Open the plan again (under **Instalment Plans** on the right). Click the **Related** tab. Under **Instalments**, click the one ending **Month 1 of 6** | The instalment opens | | |
| 10 | At the top right of the instalment, click **Record Payment** | The message **This payment can't be recorded yet. The Head of Finance has not signed off this instalment plan.** | | |

#### FT-3: Record payments
*As finance, I want balances to update when I record a payment, so that the records are always right.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Instalment Plans** tab (under **More** if not shown). Click the list name and choose **All AM Instalment Plans** | Every plan is listed with its status | | |
| 2 | Click the plan for **Segun Ajayi**. Click the **Related** tab. Under **Instalments**, click the one ending **Month 2 of 6** | AM Amount Due **3,800,000**, AM Amount Paid **0** | | |
| 3 | At the top right, click **Record Payment**. Leave the amount as it is (3,800,000), choose Method **Bank Transfer**, click **Next** | The message **Payment recorded. The instalment's amount paid and balance are updated.** | | |
| 4 | Click **Finish** and look at the instalment | AM Status **Paid**, AM Balance **0**. Under **Related**, the payment shows your name under AM Recorded By | | |
| 5 | Go to **AM Instalment Plans → All AM Instalment Plans** and open **Chiamaka Okonkwo**'s plan. Click **Related**, then the instalment ending **Month 2 of 6**. Click **Record Payment** at the top right, change the amount to **2,000,000**, choose **Bank Transfer**, click **Next**, then **Finish** | AM Amount Paid **2,000,000**, AM Balance **500,000** still owed. The status is not Paid | | |
| 6 | Go back to Chiamaka's plan, **Related**, open the instalment ending **Month 3 of 6**. Record Payment of **3,000,000**, **Bank Transfer**, **Next**, **Finish** | AM Status **Paid**. AM Amount Paid **3,000,000** (500,000 more than due) | | |
| 7 | Open **Emmanuel Udo**'s plan, **Related**, open the instalment ending **Month 3 of 3**. Record Payment, keep the amount, **Bank Transfer**, **Next**, **Finish** | The month is Paid | | |
| 8 | Open Emmanuel Udo's plan again and click **Details** | Plan Status **Completed** and **Completion Email Sent** is ticked | | |

#### FT-4: Reminders and late payments
*As finance, I want customers reminded before a payment is due and late payers flagged, so that we chase less.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Chiamaka Okonkwo**'s plan and click **Details**. Look at **Month by Month** under Where This Plan Stands | Month 1 shows **Sent: reminder email** with the date (the reminder goes out 3 days before the due date) | | |
| 2 | Open **Funke Ayo**'s plan, **Details** | Plan Status **Late**. **Next Step** says how many days late, how much is owed and what to do | | |
| 3 | Open **Folake Ogunleye**'s plan, **Details** | Plan Status **Defaulted** | | |

#### FT-5: Imports arrive
*After:* SR-3. *As finance, I want to move import requests on, so that new cars go into stock.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Import Requests** tab. Click the list name and choose **All AM Import Requests**. Open the request for **Tunde Fashola** | AM Status **Requested**, AM Vehicle Model **Toyota Corolla 2026 White** | | |
| 2 | Click the pencil beside **AM Status**, choose **Customer Confirmed**, click **Save** | Saved | | |
| 3 | Change AM Status to **Finance Confirmed**, **Save**. Then change it to **Imported**, **Save** | Each change saves | | |
| 4 | Click the **AM Vehicle Models** tab, list **All AM Vehicle Models** | Toyota Corolla 2026 White now shows cars available (it was sold out) | | |
| 5 | Open any instalment plan and look for **AM Head of Finance Sign-off** | It cannot be ticked by Finance | | |

## 6. Head of Finance – Obed

**Before you start:** the Finance tests FT-1 and FT-2 must be done first.

#### HF-1: Final discount approval
*After:* FT-1. *As head of finance, I want the final say on discounts, so that margins are protected.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Discount Requests** tab. Click the list name and choose **My Approvals - Head Office**. Open the **Kelechi Obi** request | The request shows the customer, the vehicle with its price and the price after discount | | |
| 2 | Click **Approve or Reject** at the top right. Choose **Approve**, type **Approved** in Comments, click **Next** | The message **Approved. The request is now: Approved.** | | |
| 3 | Click **Finish** | AM Current Step **Approved**, your name under AM Approved By and today's date under AM Approved On | | |

#### HF-2: Plan rules and sign-off
*After:* FT-2. *As head of finance, I want every plan to follow the rules and need my sign-off, so that risk is controlled.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Instalment Plans** tab, list **All AM Instalment Plans**, open **Ngozi Okeke**'s plan. Click the **Details** tab | The plan's terms are shown | | |
| 2 | Click the pencil beside **AM Term in Months**, type **13**, click **Save** | Refused: **The plan cannot be longer than 12 months, including after renegotiation.** Click **Cancel** | | |
| 3 | Click the pencil beside **AM Down Payment %**, type **20**, click **Save** | Refused: **Down payment must be at least 30% of the price.** Click **Cancel** | | |
| 4 | In the **Search** box at the top of the screen type **Peter Okon** and open the guarantor. Click the pencil beside **AM Income Check Done**, untick it, click **Save** | Saved | | |
| 5 | Open **Grace Okon**'s plan (from **AM Instalment Plans**). Click the pencil beside **AM Head of Finance Sign-off**, tick it, click **Save** | Refused: **Guarantor income check must be completed before Head of Finance sign-off.** Click **Cancel** | | |
| 6 | Search **Peter Okon** again, tick **AM Income Check Done** again, **Save**. Return to Grace Okon's plan, tick **AM Head of Finance Sign-off**, **Save** | Saved. AM Signed Off By shows your name, AM Signed Off On shows today. Plan Status changes from **Awaiting Sign-off** to **Active** | | |

#### HF-3: Late customers and the bank
*As head of finance, I want late customers in one list and the bank checked against payments, so that nothing is missed.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Instalment Plans** tab. Click the list name and choose **Plans Needing Attention** | Funke Ayo (Late), Folake Ogunleye (Defaulted) and Suleiman Bello (Defaulted) are listed | | |
| 2 | Click **More** at the end of the tab bar and choose **AM Reconciliation Entries**, then click **New** at the top right | A form opens with AM Date, AM Bank Total and AM Status | | |
| 3 | Set AM Date to **today**, AM Bank Total to **1,000,000**, click **Save** | Saved. AM Recorded Total shows today's recorded payments, AM Difference shows the gap, AM Status **Flagged** | | |
| 4 | Click the **bell** icon at the top right corner of the screen | An alert that the bank total and recorded payments do not match | | |
| 5 | On the entry, click the pencil beside **AM Status**, choose **Explained**, leave AM Note empty, click **Save** | Refused: **Write what caused the difference in Note before marking it Explained.** | | |
| 6 | Type **Test entry for UAT** in **AM Note**, click **Save** | Saved as **Explained** | | |

#### HF-4: Send a default to Legal
*As head of finance, I want to pass long defaults to Legal, so that the money can be recovered.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Folake Ogunleye**'s plan. At the top right, click **Raise Legal Escalation** | The message **This plan can't go to Legal yet: no month has been unpaid for 90 days or more.** Click **Finish** | | |
| 2 | Open **Suleiman Bello**'s plan. Click **Raise Legal Escalation** | Two questions appear about the guarantor and Finance management approval | | |
| 3 | Answer **Yes** to both questions, click **Next**. Enter AM Months Defaulted **3** and AM Total Amount Owed **7,500,000**, click **Next** | The message **Legal Escalation raised and the legal team has been notified by email.** Click **Finish** | | |
| 4 | Refresh the page (press F5) | Plan Status **With Legal**. Under **Related**, AM Legal Escalations shows the new escalation with **AM Legal Team Notified At** filled in | | |
| 5 | Click the **Opportunities** tab, open any opportunity | You can read it but there are no pencils to change it | | |

## 7. Legal Team – Obed

#### LG-1: See a legal escalation
*After:* HF-4. *As legal, I want the full details of a default, so that I can act on it.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Check the Legal Team's email inbox | An email about Suleiman Bello's escalation | | |
| 2 | Click the **AM Legal Escalations** tab. Click the list name and choose **All AM Legal Escalations**. Open the one for **Suleiman Bello** | AM Account **Suleiman Bello**, AM Months Defaulted **3** and AM Total Amount Owed **7,500,000** | | |
| 3 | Look for pencils beside the fields | There are none: you can read the escalation but not change it | | |

## 8. Customer Service Agent – Shedrach

**Where things are:** on a case, the **Feed** area on the left has a **Reply to Customer** tab for writing to the customer. The **Related** tab (beside Feed) lists every **Customer Message** sent on the case. The case details are on the right-hand side.

#### CS-1: Website requests reach the right team
*As customer service, I want requests from the website routed to the right team, so that customers get help quickly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the website in a private window: https://dk1791276250211--group3sb.sandbox.my.site.com/s/ . Click **Contact support**. Fill in Your name, Email, choose **Payments or my instalment plan** under What is this about?, type a Subject and a message under How can we help?, then submit | A reference number on screen, and an email with the same number | | |
| 2 | Do the same with the topic **Buying a vehicle or my order** | A reference number on screen and by email | | |
| 3 | Do the same with the topic **A problem with my vehicle** | A reference number on screen and by email | | |
| 4 | Wait 5 minutes. In Salesforce click the **Cases** tab. Click the list name and choose **My Cases** | The vehicle problem case is yours | | |
| 5 | Click the list name and choose **All Open Cases** | The payment case went to Finance, the buying case to the Showroom and the problem case to Customer Service (see AM Routed To) | | |

#### CS-2: Work a case
*As customer service, I want to reply to, update and close cases, so that customers are kept informed.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open your vehicle problem case from **My Cases**. Click the **Related** tab | **Customer Messages** shows the acknowledgement sent to the customer | | |
| 2 | Click the **Feed** tab. Under **Reply to Customer**, click the box that says **Create new...**, type a reply in **AM Message Text**, click **Save** | Saved. The reply is listed under Customer Messages, and on the right **AM First Response At** is filled in | | |
| 3 | On the case, click the pencil beside **Status**, choose **Working**, click **Save** | The customer gets a status email. A new Status Update message shows under Customer Messages | | |
| 4 | Change **Status** to **Closed**, click **Save** | **AM Resolved At** is filled in. The customer gets a closing email | | |
| 5 | Click the pencil beside **AM CSAT Score**, type **11**, click **Save** | Refused: **The satisfaction score must be a whole number from 1 to 10.** | | |
| 6 | Type **8** instead, click **Save** | Saved | | |
| 7 | Click **Change Owner** at the top right, choose another agent, **Submit**. Then look at AM Customer Messages | No new message was sent to the customer for the owner change | | |

#### CS-3: Customer history and agreed answers
*As customer service, I want a customer's history and the agreed answers in one place, so that I answer correctly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | In the **Search** box at the top of the screen, type **Daniel Okoro** and open the account | On the right: his opportunities, cases and customer messages | | |
| 2 | Open one of his opportunities and look for prices or payment amounts | None are shown, and nothing can be changed | | |
| 3 | Click **More** at the end of the tab bar and choose **AM Knowledge Articles**. Click the list name and choose **AutoDrive - Published Articles**. In **Search this list**, type **instalment** | Published articles about instalments, each with the issue and the agreed answer | | |
| 4 | Open an article and look for pencils | There are none: articles can be read but not changed | | |

## 9. Head of Customer Service – Shedrach

#### HC-1: Oversee cases
*As head of customer service, I want every case owned and tracked, so that none is forgotten.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Cases** tab. Click the list name and choose **All Cases** | Every case has a Case Owner and a Status | | |
| 2 | Ask the Customer Service Agent to leave a new website case without any reply for over 1 hour, then open it | Priority **High**, **AM Escalated At** filled in and **AM Escalated To** shows you. The bell at the top right shows an alert | | |
| 3 | Click the **Reports** tab. In **Search all reports** type **AD Cases by Status** and open it | Cases grouped by status, with first response and resolution times | | |
| 4 | Search for **AD Satisfaction Scores** and open it | Satisfaction scores over time, including the score of 8 from CS-2 | | |

#### HC-2: Keep the knowledge base current
*As head of customer service, I want to update and retire articles, so that agents give the right answers.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **AM Knowledge Articles** tab, list **All AM Knowledge Articles**, open **AD Test - Longest instalment term** | The article opens | | |
| 2 | Click the pencil beside **AM Agreed Answer**, add a sentence, click **Save** | Saved, and the change shows at once | | |
| 3 | Open **AD Test - Ownership documents after final payment**. Click the pencil beside **AM Status**, choose **Retired**, click **Save** | Saved. The article is kept but shows as Retired | | |
| 4 | Click the **AM Knowledge Articles** tab, list **AutoDrive - Published Articles** | The retired article is no longer listed, so agents will not use it | | |

## 10. Management – Shedrach

#### MG-1: One view of the business
*As management, I want sales, stock, finance and service figures in one place, so that I can make decisions.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Home** tab. On the **AutoDrive - Management** dashboard, click **Refresh** at the top right of the dashboard | The figures update: Deals Won This Month, Payments Last 30 Days, Total Owed in Legal, Deals in Pipeline by Stage and Available Stock by Model, with no errors | | |
| 2 | On the dashboard, find **Available Stock by Model** and note the number for one model. Click the **AM Vehicle Models** tab, list **All AM Vehicle Models**, and find the same model | The numbers match | | |
| 3 | Open any opportunity, case or instalment plan | Everything can be read; there are no pencils to change anything | | |

## 11. Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Tester – Sales | Henry | | |
| Tester – Finance | Obed | | |
| Tester – Customer Service | Shedrach | | |
| UAT coordinator | Hillary Emmanuel | | |
| Business sponsor | | | |
