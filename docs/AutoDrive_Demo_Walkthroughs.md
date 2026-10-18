# AutoDrive Demo Walkthroughs (Stage 17)

One journey per role, each told as a real day at AutoDrive and each ending with a rule stopping a mistake **live on screen**. Uses the sample data from `scripts/apex/` (records named "AD Test…").

**Rules for every demo**
- Never demo as System Administrator. Setup → Users → **Login** next to the test user; **Log out** from the banner afterwards.
- Everyone lands in the **AutoDrive Motors** app. On each list, switch to **All …** views.
- Do the roles in this order: the discount approval passes from one role to the next.
- Demos change real records. Reset afterwards by re-seeding a fresh sandbox, or ask for a reset script.

---

## 1. Sales Rep: "A walk-in buys a Corolla" (≈5 min)
**Story:** Adaeze walked in last week and is ready to buy; a second customer, who never went through reception, wants to buy too.
1. Home → point out **Items to Approve** and today's tasks.
2. **Vehicle Models → AD Test - Honda CR-V**: the stock panel **blinks red** (2 left, threshold 5). "The showroom sees low stock without running a report."
3. **Opportunities → AD Test Sale - Adaeze Okafor** → Stage **Closed Won** → Save. Open her car (AD Test Toyota Corolla #1): status is now **Sold**.
4. **Opportunities → AD Test Sale - Kano Logistics Ltd** → Discount Requests → **DR-0003** → **Submit for Approval**.
5. **Live rule:** **AD Test Sale - Direct (no Lead)** → Closed Won → Save.
   **Error shown:** *"This sale can't be closed: the customer didn't come from a converted Lead…"* "Every sale has to start as an enquiry, so we always know where business comes from."

## 2. Showroom Manager: "Approving a fleet discount and receiving stock" (≈4 min)
1. Home → **Items to Approve** → Kano discount → **Approve**. The request moves to **With Finance**.
2. **Vehicles → New** → a Camry → Save. The showroom is filled in automatically (one showroom).
3. **Live rule:** open **AD Test - Lagos Main** → set **Capacity** to the current **Vehicle Count** → Save. Add another vehicle.
   **Error shown:** *"The showroom is full. Mark a vehicle as Sold or raise the showroom Capacity before adding another."* Set Capacity back to 25 afterwards.

## 3. Finance Team: "Recording a late payment" (≈5 min)
1. Home → **Items to Approve** → approve the Kano discount → **With Head Office**.
2. **AD Test Sale - Chinedu Eze** → Payments → **New** → Type *Instalment*, Instalment = the **Late** one, **2,625,000**, *Bank Transfer* → Save. The instalment's **Amount Paid** and the sale's **Total Paid / Balance** update instantly.
3. **Reconciliation Entries** → show the **Flagged** day (Funke, bank 66,667 short) and the **Explained** day.
4. **Live rule:** Chinedu's **Instalment Plan** → Term **18** → Save.
   **Error shown:** the 12-month cap. "Only a fleet customer with Head of Finance sign-off can go past 12 months."

## 4. Head of Finance: "The final word on discounts and plans" (≈4 min)
1. **Items to Approve** → approve Kano → **Approved**. Open **AD Test Sale - Bola Adeyemi**'s discount to show a completed three-step trail.
2. **AD Test Sale - Lagos Ride Hailing Ltd** → its plan: **20% down, 18 months**, signed off. "Fleet exception, allowed with my sign-off."
3. **Live rule:** **AD Test Sale - Kano Logistics Ltd** → Instalment Plans → **New** → Guarantor *AD Test Ngozi Eze*, Down Payment **20%**, Term 12, **sign-off unticked** → Save.
   **Error shown:** 30% minimum. Tick sign-off and save again: it goes through.

## 5. Customer Service Agent: "A customer calls about a payment" (≈4 min)
1. Tab bar: Cases, Customer Messages, Knowledge, no Discounts or Dashboards. "Agents see what they need, nothing more."
2. **Cases → New** → Type **Payment**, Subject "Paid but not showing" → Save. **Routed To: Finance**.
3. **Knowledge Articles** → *How instalment payments are confirmed* → use the agreed answer.
4. Open **AD Test - Air conditioning not cooling** (closed): the satisfaction request was sent automatically on closing.
5. **Live rule:** try to open any Discount Request (search **DR-**): nothing found. "Discounts are a sales and finance matter."

## 6. Head of Customer Service: "Keeping an eye on the team" (≈3 min)
1. **Cases** → the **Escalated** case *When will my ownership documents be ready?*
2. **Dashboards** tab (dashboards to follow).
3. **Knowledge Articles** → open the **Draft** article *Ordering a model that is out of stock* → **Publish** (set Status). "I maintain the answers the team gives."

## 7. Legal Team: "A customer stopped paying" (≈3 min)
1. Tab bar: only Legal Escalations, Instalment Plans, Guarantors, Accounts, Contacts, Sales.
2. **Legal Escalations → AD-TEST-0001** (Chinedu): contract, amount paid, amount owed, missed payments. Open the linked plan and guarantor *Ngozi Eze*. "Everything Legal needs, in one place." (Legal views escalations; Finance and Management update them.)
3. Show **AD-TEST-0002** (Funke): **Settled**: "the customer cleared the arrears after our letter."
4. **Live rule:** try to open a Payment or Reconciliation Entry: no access.

## 8. Management: "The whole business at a glance" (≈3 min)
1. **Opportunities → All**: 9 sales, 2 won, 1 lost, the rest in progress.
2. **Vehicle Models**: stock against thresholds; CR-V and Sportage blinking.
3. **Discount Requests**: one approved, one rejected, one in progress.
4. **Live rule:** open any sale → no **Edit**. "Management sees everything and changes nothing."
