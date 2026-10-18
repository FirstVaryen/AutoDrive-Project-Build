# AutoDrive Motors on Salesforce: Solution Document

*Version 3, 18 October 2026. Written for AutoDrive's management and staff; no Salesforce knowledge needed.*

---

## 1. What this system does

AutoDrive used to run on spreadsheets, phone calls and memory. This system puts the whole business in one place: the cars in the showroom, every customer from first enquiry to final payment, discounts and who approved them, instalment plans and payments, customer complaints, and legal cases when a customer stops paying.

Everyone works in the same system, but each person only sees what their job needs. A sales rep never sees the bank reconciliation; a customer service agent never sees who approved a discount.

### What AutoDrive runs today
- **One showroom.** Every car belongs to it automatically; nobody has to choose.
- **New cars only.** Used-car sales are already built into the system and switched off. When AutoDrive starts selling used cars, an administrator turns them on in a few clicks; nothing needs rebuilding.
- **One app for everyone**, called **AutoDrive Motors**. Each person opens it and sees only their own tabs.

---

## 2. Who uses it and what they see

| Role | What they do in the system | What they can't do |
|---|---|---|
| **Sales Rep** | Record enquiries (Leads), convert them to customers, run sales, request discounts and imports, see stock | Add or change cars; see payments, instalment plans or bank records |
| **Showroom Manager** | Everything a rep does, plus add cars to stock, set showroom capacity, and approve discounts first | See payments or bank records |
| **Finance Team** | Record payments, manage instalment plans, reconcile the bank, approve discounts second | Change cars or prices |
| **Head of Finance** | Everything Finance does, plus the final discount approval, sign off instalment plans, and approve exceptions for fleet customers | — |
| **Customer Service Agent** | Handle customer cases, send messages, use the knowledge base, look up a customer's purchase and plan | See discounts; change sales or plans |
| **Head of Customer Service** | Everything an agent does, plus maintain the knowledge base and see escalated cases | — |
| **Legal Team** | Work legal escalations, with the customer's plan and guarantor in view | Anything outside legal cases |
| **Management** | See the whole business: sales, stock, discounts, payments, legal, service | Change records (view only) |

Each role has its own login profile and access group. Nobody can delete cars or showroom records.

---

## 3. How a customer moves through the business

### Enquiry to sale
1. A customer walks in, calls, or enquires online. The rep records them as a **Lead**, noting where they came from (walk-in, web, Instagram, returning customer). Walk-ins are assigned to the next free rep automatically; returning or high-profile customers go to the Showroom Manager.
2. When the customer is serious, the rep **converts** the Lead into a customer and a sale. **A sale can only be closed for a customer who came in as a Lead**, so every sale is traceable to how it started.
3. When the sale closes, the car is marked **Sold** straight away, so stock is always accurate.

### Discounts
A rep can request a discount on a sale. It goes through three approvals in order: **Showroom Manager → Finance Team → Head of Finance**. Each step is timed. Discounts on instalment deals are **not allowed for individual customers**; fleet (company) customers can request one, but it still needs all three approvals.

### Paying in instalments
- The customer pays **at least 30% up front** and the rest over **no more than 12 months**.
- Every plan needs a **guarantor**, and the guarantor's income must be checked before the Head of Finance signs off.
- Fleet customers can go below 30% or beyond 12 months, but only with Head of Finance sign-off.
- When a plan is renegotiated, the new term can't be longer than the original.

### When payments come in
Finance records each payment. The sale's **total paid** and **balance remaining** update immediately, and so does the instalment it pays off. Finance reconciles each day's payments against the bank and marks the day **Matched**, **Flagged** or **Explained**.

### Reminders and late payments (automatic)
- **3 days before** an instalment is due: a reminder email to the customer.
- **1 day late**: a missed-payment email to the customer.
- **7 days late**: a guarantor notice is logged on the customer's record so the guarantor can be contacted.
- **30 days late**: the instalment is flagged as in **default**.
- **90 days late**, guarantor unable to pay, and Finance approves: a **Legal Escalation** is raised and the Legal team is notified.
- When the **last instalment is paid**, the customer gets a congratulations email and Finance starts the ownership documents.

### Out of stock
If a customer wants a model the showroom doesn't have, the rep raises an **Import Request**. It moves through: requested → customer confirmed → Finance confirmed → imported. The rep is told automatically when the car arrives.

### Stock and the showroom
- Each model has a **low-stock level**. When stock drops below it, the Showroom Manager is emailed and the model's page **blinks red**.
- The showroom has a **capacity**. Once it's full, no more cars can be added until one is sold or the capacity is raised.
- No model can have more than **50 cars** in stock.

---

## 4. Customer service

- **Every channel becomes a case:** phone, email, web, walk-in, WhatsApp, text. Emails to the support address become cases automatically.
- Cases are **routed by type**: payment questions to Finance, sales and vehicle questions to the Showroom Manager, technical issues to Customer Service, anything else for manual review.
- A case with **no response after 1 hour** is escalated to high priority and flagged to the Head of Customer Service.
- When a case is closed, the customer is asked **how satisfied they were**.
- Agents answer from a shared **knowledge base** of agreed answers, maintained by the Head of Customer Service.
- Every message to a customer is logged against them, so anyone picking up the case sees the history.

---

## 5. Still being finished

| Item | Status |
|---|---|
| Reports and a dashboard for each role | Being designed |
| Cases assigned to the right team's work queue automatically (today they're labelled with the team) | Being built |
| Recording when a case gets its first reply, so escalation only fires when nobody has answered | Being built |
| Reminders when a discount approval waits too long | Being built |
| Cancelling an approved discount if the customer switches to paying by instalments | Being built |
| Hiding payment amounts from Customer Service | Being set up |
| The customer website (enquiry form and support page) | Being set up |

---

## 6. Questions and changes

Any change to how the system works is logged on the project change log so it can be tracked, tested and approved before it goes live.
