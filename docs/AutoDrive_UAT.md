# AutoDrive Motors – User Acceptance Testing

This document holds the tests for the AutoDrive Motors Salesforce system. Each tester runs the tests for the roles given to them, as that role's user.

## 1. How to test

- **Where:** Salesforce sandbox **Group3SB**, in the **AutoDrive Motors** app, on a desktop browser.
- **Website:** https://dk1791276250211--group3sb.sandbox.my.site.com/s/ (open it in a private window).
- **Logging in:** the UAT coordinator logs you in as the role you are testing. A banner at the top shows the user you are working as. Test only as that user, never as an administrator.
- **Finding records:** lists open on *Recently Viewed*. Click the list name and choose another list, or use the search bar at the top.
- **Recording results:** follow the steps in order. Write what you saw under **Actual result**, then **Pass** or **Fail**. A test passes only when every step passes.
- **Problems:** take a screenshot, note the test and step number, and tell the UAT coordinator.

## 2. Testers and roles

| Tester | Roles they test | Pages |
|---|---|---|
| Henry | Sales Rep, Showroom Manager | 2 – 4 |
| Obed | Finance Team, Head of Finance, Legal Team | 5 – 7 |
| Shedrach | Customer Service Agent, Head of Customer Service, Management | 8 – 10 |

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

#### SR-1: Record a walk-in customer
*As a sales rep, I want every walk-in recorded the same way, so that no customer is lost.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Leads → New. Enter a name, a phone number and Channel = Walk-in | The form asks for Qualification Answers, Visit Purpose and Vehicle of Interest | | |
| 2 | Fill in the answers, Visit Purpose = Purchase, pick a vehicle, save | The lead saves and is given to a sales rep | | |
| 3 | Create a lead with the phone number of **Daniel Okoro** | A warning that this customer already exists | | |
| 4 | Create a walk-in with Channel = Returning/High-profile, save | The lead goes to the Showroom Manager | | |

#### SR-2: Website enquiries come to me
*As a sales rep, I want website enquiries given to me automatically, so that I can respond quickly.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open the website in a private window. Fill in **Sales enquiry** with your name, email and a car. Submit | A thank-you message | | |
| 2 | Within 5 minutes, open Leads → AutoDrive - My Leads | The enquiry is there, Channel = Web | | |
| 3 | Check your email | A message that a lead was given to you | | |

#### SR-3: Out-of-stock vehicles are flagged
*As a sales rep, I want to know when a car is not in stock, so that I can request an import.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a lead whose Vehicle of Interest is **Toyota Corolla 2026 White** | A red flag: "Out of stock - request an import" | | |
| 2 | Clear Visit Purpose and click Convert | Refused until the purpose is filled in | | |
| 3 | Fill in the purpose and convert | A sale is created and shows the same red flag | | |

#### SR-4: A car can only be sold once
*As a sales rep, I want to see live availability, so that I never sell a car twice.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | AM Vehicles → All | Each car shows Available, Reserved or Sold | | |
| 2 | On an open sale, try to choose the car on **Ngozi Okeke's** sale | Refused: the car is reserved for another customer | | |
| 3 | Set an open full-payment sale to Closed Won, then open its car | The car shows Sold | | |
| 4 | On the closed sale, try to change any field | Refused: the sale is closed | | |

#### SR-5: Request a discount
*As a sales rep, I want to request a discount and see where it is, so that I can update the customer.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | On an open full-payment sale, Request Discount, 5%, with a reason | Approved straight away | | |
| 2 | On another open sale, request 7.5% with a reason | Sent to the Showroom Manager | | |
| 3 | Open the request | The customer, each vehicle with its price, the total and the price after discount | | |
| 4 | On an instalment sale, try Request Discount | Refused: no discount on instalment sales | | |

#### SR-6: Fleet sales
*As a sales rep, I want a company's vehicles on one sale with its agreed rate, so that fleet deals are simple.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open **Lagos Ride Hailing Ltd** | Contact, agreed discount rate and past sales on one page | | |
| 2 | Create a sale for Lagos Ride Hailing Ltd. Add Fleet Vehicles: a model and quantity 2 | Two cars added and reserved; totals update | | |
| 3 | Ask for more cars than are in stock | Told how many could not be added | | |
| 4 | Request Discount and leave the rate blank | The agreed rate is filled in | | |

#### SR-7: Instalment sales and imports
*As a sales rep, I want instalment terms and imports handled by the system, so that I follow the rules.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | On an open sale, set Payment Mode = Instalment and months = 6 | The 30% deposit and monthly amount fill in | | |
| 2 | Open **Zainab Bello's** sale and set it to Closed Won | Refused: deposit and sign-off needed first | | |
| 3 | On a customer, Import Requests → New: a model, quantity 2, reason Out of stock | Saved as Requested | | |
| 4 | Try to save another without a reason | Refused | | |

## 4. Showroom Manager – Henry

#### SM-1: See where deals are
*As the showroom manager, I want to see open prospects and sales, so that I know where deals are stuck.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Leads → AutoDrive - Open Prospects | Each lead shows channel, owner and status | | |
| 2 | Leads → AutoDrive - Prospects With No Rep | Leads without a rep, if any | | |
| 3 | Opportunities → All Opportunities | Each sale shows owner and stage | | |

#### SM-2: Approve or reject a discount
*After:* SR-5. *As the showroom manager, I want to approve discounts above 5%, so that pricing stays under control.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Home → Items to Approve, open the 7.5% request | Vehicles, prices, total and price after discount are shown | | |
| 2 | Approve it | It moves on to Finance | | |
| 3 | Ask Henry (Sales Rep) for a 10% request, then Reject it with a reason | Status Rejected | | |

#### SM-3: High-profile clients
*After:* SR-1 step 4. *As the showroom manager, I want returning and high-profile clients sent to me, so that I look after them.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Check the bell | A message about the new client | | |
| 2 | Leads → AutoDrive - High-profile Clients | The client is listed and owned by you | | |
| 3 | Change the owner to a sales rep | Saved | | |

#### SM-4: Stock and imports
*As the showroom manager, I want low-stock alerts and to see import requests, so that I can reorder in time.*

| Step | What to do | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|
| 1 | Open a Vehicle Model. Set Low Stock Threshold above its Available Stock, save | Saved | | |
| 2 | Vehicle Models → AutoDrive - Low Stock | The model is listed | | |
| 3 | The next morning, check the bell | One low-stock message for that model | | |
| 4 | Open AM Import Requests | The sales rep's request with quantity, reason and status | | |

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
| 1 | Opportunities → AutoDrive - Plans To Set Up, open a sale | Months, deposit and monthly amount are shown | | |
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
*After:* SR-7. *As finance, I want to move import requests on, so that new cars go into stock.*

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
| 4 | Open any sale | You can read it but not change it | | |

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
*As management, I want sales, stock, finance and service in one place, so that I can make decisions.*

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
