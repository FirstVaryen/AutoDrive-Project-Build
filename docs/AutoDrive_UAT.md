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
| Henry | Sales Rep, Showroom Manager | 2 – 6 |
| Obed | Finance Team, Head of Finance, Legal Team | 7 – 10 |
| Shedrach | Customer Service Agent, Head of Customer Service, Management | 11 – 13 |

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
| V-1 | Every vehicle model has 5 cars available, except **Toyota Corolla 2026 White** and **Toyota Camry 2026 Blue**, which are sold out | SR-3, SR-4 |

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
| 1 | Open the website in a private window. Click **Sales enquiry**, enter your name, your email and a car. Click **Submit** | A thank-you message | | |
| 2 | Wait 5 minutes. In Salesforce click **Leads**, choose the list **AutoDrive - My Leads** | Your enquiry is listed, AM Channel **Web** | | |
| 3 | Check your email inbox | An email saying a lead has been given to you | | |

#### SR-3: Convert a lead and request an import
*As a sales rep, I want to see straight away if a car is sold out and request an import, so that the customer is not kept waiting.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click **Leads**, choose **AutoDrive - My Leads**, open **Tunde Fashola** (L-2) | Under Vehicle of Interest a red flag shows **Sold out - an import will be needed** | | |
| 2 | Open **Adaeze Nwosu** (L-1). Click the pencil beside Visit Purpose, choose **--None--**, click **Save** | Refused: Visit Purpose must be filled in | | |
| 3 | Click **Cancel**. Click **Convert** at the top right, leave the details as they are, click **Convert** | An opportunity is created for Adaeze Nwosu | | |
| 4 | Open the new opportunity | AM Vehicle Wanted shows **Kia Sportage 2026 White**, with a green flag **In stock: Available (5) - pick a car in AM Vehicle** | | |
| 5 | Open **Tunde Fashola** (L-2). Click **Convert**, then **Convert**. Open the new opportunity | AM Vehicle Wanted shows **Toyota Corolla 2026 White**, with a red flag **Sold out - click Request Import** | | |
| 6 | On Tunde Fashola's opportunity click **Request Import** at the top right | A window opens with AM Vehicle Model **Toyota Corolla 2026 White**, Quantity **1** and Reason for Request **Out of stock** already filled in | | |
| 7 | Click **Save** | The message **Import requested. You can follow it under Import Requests on this opportunity.** The request shows under **Import Requests** on the right, status Requested | | |
| 8 | Click **Request Import** again, clear **Reason for Request**, click **Save** | Refused: **Choose the type of car, the reason for the request (Out of stock or Client request) and how many.** | | |

#### SR-4: Pick a car and close an opportunity
*As a sales rep, I want to see what is available while I pick a car, so that I never sell a car twice.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click **Opportunities**, choose the list **All Opportunities**, open **Chidi Eze - Toyota Hilux 2026 Grey** (O-5) | Under AM Vehicle a green flag shows **Car available · Model stock:** with the number available and reserved | | |
| 2 | Click the pencil beside **AM Vehicle**, clear it and type **Hilux** | Only available cars are offered. Under each car: **Available · Model: Available (n)**, and **Reserved (n)** where any are reserved | | |
| 3 | Pick any **Toyota Hilux 2026 Red** car and click **Save** | Saved. The green flag now shows the Hilux Red stock | | |
| 4 | Click the pencil beside **AM Vehicle** again and type **Corolla 2026 White** | No car is offered: the model is sold out | | |
| 5 | Click **Cancel**. Open **Musa Ibrahim - Toyota Camry 2026 White** (O-3). On the stage bar click **Closed**, then **Select Closed Stage**, choose **Closed Won**, click **Save** | The opportunity is Closed Won | | |
| 6 | Click the car in **AM Vehicle** | Status **Sold** | | |
| 7 | Go back. Click **Opportunities**, choose the list **AutoDrive - Closed Won**, open **Musa Ibrahim - Toyota Camry 2026 White**. Click any pencil, change the value and click **Save** | Refused: **This opportunity is closed and can't be changed. Only a head of department can change a closed opportunity.** | | |
| 8 | Click the **AM Vehicles** tab, choose the list **All** | Every car shows Available, Reserved or Sold. There is no pencil to change a car | | |

#### SR-5: Request a discount
*As a sales rep, I want to request a discount and see where it is, so that I can update the customer.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Bisi Adewale - Toyota Hilux 2026 Red** (O-1). Click **Request Discount** at the top right. Choose Discount Rate **5%**, AM Reason **Loyal customer**, click **Save** | AM Approval Status shows a green marker and **5.00% discount approved** | | |
| 2 | Look at **Discount Requests** on the right | The request shows the list price, the discount value and the price after discount | | |
| 3 | Open **Kelechi Obi - Honda CR-V 2026 White** (O-2). Click **Request Discount**. Choose **7.5%**, AM Reason **Price match**, click **Save** | AM Approval Status shows an orange marker and **7.50% discount waiting: With Showroom Manager** | | |
| 4 | Under **Discount Requests** on the right, click the request number | The request shows the customer, the vehicle with its price, the discount value and the price after discount | | |
| 5 | Open **Chidi Eze - Toyota Hilux 2026 Grey** (O-5). Click **Request Discount**. Choose **10%**, AM Reason **Customer asked for more**, click **Save** | AM Approval Status shows an orange marker and **10.00% discount waiting: With Showroom Manager** | | |
| 6 | Go back to **Bisi Adewale - Toyota Hilux 2026 Red**. Click the pencil beside AM Payment Mode, choose **Instalment**, set AM Instalment Duration (Months) to **6**, click **Save** | The 5% discount shows **Invalidated**. The price returns to the full list price and AM Down Payment Agreed (30%) is 30% of the full price | | |

#### SR-6: Instalment opportunities
*As a sales rep, I want instalment terms worked out for me, so that I follow the payment rules.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Ronke Alabi - Kia Sportage 2026 White** (O-4). Click the pencil beside AM Payment Mode, choose **Instalment**, set AM Instalment Duration (Months) to **6**, click **Save** | AM Down Payment Agreed (30%) shows 30% of the price. AM Amount on Instalment and AM Monthly Instalment are worked out | | |
| 2 | On the same opportunity click **Request Discount**, choose **5%**, give a reason, click **Save** | Refused: **Discounts are not permitted on instalment deals for individual customers.** | | |
| 3 | Open **Zainab Bello - Honda CR-V** (O-6). On the stage bar click **Closed**, then **Select Closed Stage**, choose **Closed Won**, click **Save** | Refused: **An instalment opportunity can only be closed once Finance has recorded the down payment and the Head of Finance has signed off the instalment plan.** | | |

#### SR-7: Fleet opportunities
*As a sales rep, I want a company's vehicles on one opportunity with its agreed rate, so that fleet deals are simple.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Click the **Accounts** tab and open **Lagos Ride Hailing Ltd** | AM Agreed Discount Rate **5%** beside Phone; on the right, Contacts shows **Kemi Lawal** and Opportunities shows Lagos Ride Hailing Ltd - Fleet | | |
| 2 | Open **Lagos Ride Hailing Ltd - Fleet** (O-7). Click **Add Fleet Vehicles**. Choose Model **Toyota Hilux 2026 White**, How many **2**, click **Next** | 2 cars are added under Fleet Vehicles, each Reserved. The fleet total and count update | | |
| 3 | Click **Add Fleet Vehicles** again. Choose **Toyota Hilux 2026 White**, How many **10**, click **Next** | Only the cars in stock are added; a message says how many could not be added | | |
| 4 | Click **Request Discount**. Leave Discount Rate empty, AM Reason **Fleet agreement**, click **Save** | The request uses the agreed rate of **5%** on the fleet total | | |

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
| 1 | Click the **Home** tab. In the **Items to Approve** box, click the request for **Kelechi Obi** (7.5%) | The request opens and shows the customer, the vehicle with its price, the discount value and the price after discount | | |
| 2 | Click **Approve** at the top right. In Comments type **Approved**, click **Approve** | The request moves on to Finance: AM Current Step shows **With Finance** | | |
| 3 | Click the **Home** tab. In **Items to Approve**, click the request for **Chidi Eze** (10%) | The request opens with its details | | |
| 4 | Click **Reject** at the top right. In Comments type **10% is above what we can offer on this model**, click **Reject** | AM Current Step shows **Rejected** | | |
| 5 | Click the **Opportunities** tab, open **Chidi Eze - Toyota Hilux 2026 Grey** | AM Approval Status shows a red marker and **10.00% discount rejected** | | |

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
| 2 | Click **Toyota Hilux 2026 Silver** to open it | AM Stock shows **Available (5)** | | |
| 3 | Click the pencil beside **AM Low-stock Threshold**, type **6**, click **Save** | Saved | | |
| 4 | Click the **AM Vehicle Models** tab. Click the list name and choose **AutoDrive - Low Stock** | Toyota Hilux 2026 Silver is listed | | |
| 5 | The next morning, click the **bell** icon at the top right corner | One message **Low stock alert** for Toyota Hilux 2026 Silver | | |
| 6 | The morning after, click the bell again | No second alert for the same model | | |
| 7 | Click the **AM Import Requests** tab. Click the list name and choose **All** | The request raised for **Tunde Fashola** in SR-3, with AM Vehicle Model, Quantity, Reason for Request and Status **Requested** | | |

## 5. Finance Team – Obed

#### FT-1: Approve discounts
*After:* SM-2. *As finance, I want to see discounts waiting for me, so that none are held up.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Home → Items to Approve | The 7.5% request is listed | | |
| 2 | Approve it | It moves on to the Head of Finance | | |

#### FT-2: Set up an instalment plan
*As finance, I want to set up a plan and take the deposit, so that the customer can pay monthly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Opportunities → AutoDrive - Plans To Set Up, open a opportunity | Months, deposit and monthly amount are shown | | |
| 2 | Create Instalment Plan, choose a guarantor, save | Plan is Awaiting Sign-off with one instalment per month | | |
| 3 | Record Down Payment | Saved; the car becomes Reserved | | |
| 4 | Record Down Payment again | Refused: already recorded | | |
| 5 | Try Record Payment on Month 1 | Refused: the plan is not signed off | | |

#### FT-3: Record payments
*As finance, I want balances to update when I record a payment, so that records are always right.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Segun Ajayi's** plan → Month 2 → Record Payment, keep the amount | Paid; balance 0; your name under Recorded By | | |
| 2 | **Chiamaka Okonkwo's** plan → Month 2 → Record Payment of 2,000,000 | 500,000 still owed | | |
| 3 | Chiamaka's Month 3 → Record Payment of 3,000,000 | Paid, with 500,000 extra | | |
| 4 | **Emmanuel Udo's** plan → Month 3 → Record Payment, keep the amount | Plan Completed; completion email sent | | |

#### FT-4: Reminders and late payments
*As finance, I want customers reminded and late payers flagged, so that we chase less.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open Chiamaka's plan, Month by Month | Month 1 shows a reminder email was sent | | |
| 2 | Open **Funke Ayo's** plan | Late; Next Step says how many days late and what to do | | |
| 3 | Open **Folake Ogunleye's** plan | Defaulted; one alert sent | | |

#### FT-5: Imports arrive
*After:* SR-3. *As finance, I want to move import requests on, so that new cars go into stock.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the import request and move it step by step to Imported | Each step saves | | |
| 2 | Open its vehicle model | Available Stock has gone up by the quantity | | |
| 3 | On any plan, try to tick Head of Finance Sign-off | Not allowed | | |

## 6. Head of Finance – Obed

#### HF-1: Final discount approval
*After:* FT-1. *As head of finance, I want the final say on discounts, so that margins are protected.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Home → Items to Approve, open the request | Vehicles, prices and price after discount are shown | | |
| 2 | Approve it | Approved, with your name and the date | | |

#### HF-2: Plan rules and sign-off
*As head of finance, I want plans to follow the rules and need my sign-off, so that risk is controlled.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Ngozi Okeke's** plan, set Term in Months to 13, save | Refused: 12 months at most | | |
| 2 | Set Down Payment % to 20, save | Refused: at least 30% | | |
| 3 | Open **Hauwa Lawal's** plan, tick Head of Finance Sign-off, save | Your name and the date fill in; plan becomes Active | | |
| 4 | Untick a guarantor's Income Check Done, then try to sign off a plan using that guarantor | Refused: income check first | | |

#### HF-3: Late customers and the bank
*As head of finance, I want late customers in one list and the bank checked against payments, so that nothing is missed.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | AM Instalment Plans → Needs Attention | Funke Ayo, Folake Ogunleye and Suleiman Bello | | |
| 2 | AM Reconciliation Entries → New: today's date and a Bank Total that differs from today's payments | Saved as Flagged, with the difference shown | | |
| 3 | Check the bell | An alert that the bank and payments don't match | | |
| 4 | Set Status to Explained without a note | Refused: add a note | | |
| 5 | Add a note and save | Saved as Explained | | |

#### HF-4: Send a default to Legal
*As head of finance, I want to pass long defaults to Legal, so that the money is recovered.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | On Folake Ogunleye's plan, Raise Legal Escalation | Refused: no month is 90 days unpaid | | |
| 2 | On **Suleiman Bello's** plan, Raise Legal Escalation and complete the screen | Raised; Legal is told | | |
| 3 | Refresh the plan | Plan Status is With Legal | | |
| 4 | Open any opportunity | You can read it but not change it | | |

## 7. Legal Team – Obed

#### LG-1: See a legal escalation
*After:* HF-4. *As legal, I want the full details of a default, so that I can act on it.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Check your email | A message about Suleiman Bello's escalation | | |
| 2 | Legal Escalations → All, open Suleiman Bello's | Customer, months defaulted and amount owed | | |
| 3 | Try to edit it | Not allowed | | |

## 8. Customer Service Agent – Shedrach

#### CS-1: Website requests reach the right team
*As customer service, I want requests from the website routed to the right team, so that customers get help quickly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | On the website, Contact support three times: Payments, Buying a vehicle, A problem with my vehicle | A reference number on screen and by email each time | | |
| 2 | Within 5 minutes, Cases → My Cases | The vehicle problem case is yours | | |
| 3 | Cases → All Open Cases | Payments went to Finance, Buying to the Showroom, the problem to Customer Service | | |

#### CS-2: Work a case
*As customer service, I want to reply, update and close cases, so that customers are kept informed.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | On your case, add a Customer Message reply | First Response At fills in | | |
| 2 | Set Status to Working | The customer gets a status email | | |
| 3 | Close the case | Resolved At fills in; the customer gets a closing email | | |
| 4 | Enter CSAT Score 11, save | Refused: 1 to 10 | | |
| 5 | Enter 8, save | Saved | | |

#### CS-3: Customer history and answers
*As customer service, I want a customer's history and agreed answers in one place, so that I answer correctly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Search **Daniel Okoro**, open the account | Purchases, cases and messages together | | |
| 2 | Look for prices or payment amounts | None are shown | | |
| 3 | Knowledge Articles, search a word such as "instalment" | Articles with the issue and the agreed answer | | |
| 4 | Try to edit an article | Not allowed | | |

## 9. Head of Customer Service – Shedrach

#### HC-1: Oversee cases
*As head of customer service, I want every case owned and tracked, so that none is forgotten.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Cases → All Cases | Every case has an owner and a status | | |
| 2 | Leave a new case unanswered for over an hour, then open it | Priority High; you are alerted | | |
| 3 | Run report AD Cases by Status | Cases with first response and resolution times | | |
| 4 | Run report AD Satisfaction Scores | Scores over time | | |

#### HC-2: Keep the knowledge base current
*As head of customer service, I want to update and retire articles, so that agents give the right answers.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Edit an article's answer, save | The change shows at once | | |
| 2 | Set another article to Retired | Agents no longer see it | | |

## 10. Management – Shedrach

#### MG-1: One view of the business
*As management, I want opportunities, stock, finance and service in one place, so that I can make decisions.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the Management dashboard | Sales, stock, finance and service figures, no errors | | |
| 2 | Compare one model's stock on the dashboard with the model record | They match | | |
| 3 | Open any record and try to edit it | You can read everything but change nothing | | |

## 11. Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Tester – Sales | Henry | | |
| Tester – Finance | Obed | | |
| Tester – Customer Service | Shedrach | | |
| UAT coordinator | Hillary Emmanuel | | |
| Business sponsor | | | |
