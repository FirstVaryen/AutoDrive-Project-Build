# Stage 1 — Full Object & Field Spec

Everything you need to build every object in one sitting, no round-trips needed. Build in this order (parents before children). For every field: Setup → Object Manager → [Object] → Fields & Relationships → New, and **fill in the Description** — not optional, it's the build standard.

Standard objects (Lead, Account, Contact, Opportunity, Case, User) — extend with the fields listed under "Field additions" at the bottom. Don't recreate these as custom objects.

---

## 1. Showroom
| Field | Type |
|---|---|
| Name | Text (or use standard Name field) |
| City | Text |

## 2. Vehicle Model
| Field | Type |
|---|---|
| Model Name | Text |
| List Price | Currency |
| Low-stock Threshold | Number |
| Available Stock | Roll-Up Summary (Count, from Vehicle, where Status = Available) — **build this after Vehicle exists** |

## 3. Vehicle
Master-Detail to **Vehicle Model**. Lookup to **Showroom**.
| Field | Type |
|---|---|
| Vehicle Name | Text |
| Serial Number | Text |
| Chassis Number | Text |
| Colour | Text |
| Year | Number |
| Status | Picklist — values: Available, Reserved, Sold, Not for sale |
| Reserved Until | Date/Time |
| **Arrival Date** (new, v8) | Date |
| Model | Master-Detail → Vehicle Model |
| Showroom | Lookup → Showroom |

Record Types on Vehicle: **New**, **Used** (Used stays mostly unused this phase, build it anyway).

## 4. Guarantor
| Field | Type |
|---|---|
| Name | Text |
| Phone | Phone |
| Income Check Done | Checkbox |

## 5. Discount Request
Master-Detail to **Opportunity**.
| Field | Type |
|---|---|
| Requested Discount | Percent |
| Current Step | Picklist — values: With Showroom Manager, With Finance, With Head Office, Approved, Rejected |
| Step Reached At | Date/Time |
| Reason | Long Text Area |
| Requested By | Lookup → User |

## 6. Approval Step
Master-Detail to **Discount Request**.
| Field | Type |
|---|---|
| Step | Picklist — values: Showroom Manager, Finance, Head Office |
| Decision | Picklist — values: Approved, Rejected, Pending |
| Acted By | Lookup → User |
| Acted At | Date/Time |
| Reason | Text |
| Recorded By Finance For Head Office | Checkbox |

## 7. Instalment Plan
Master-Detail to **Opportunity**. Lookup to **Guarantor** (required).
| Field | Type |
|---|---|
| Down Payment % | Percent (validation: min 30 — built in Stage 4) |
| Down Payment Amount | Currency |
| Term in Months | Number (validation: max 12 — built in Stage 4) |
| Original Term in Months | Number |
| Guarantor | Lookup → Guarantor |
| Head of Finance Sign-off | Checkbox |
| Signed Off By | Lookup → User |
| Signed Off On | Date |
| Completion Email Sent | Checkbox |
| **Ownership Documents Status** (new, v8) | Picklist — values: Not Started, In Progress, Sent, Received |

## 8. Instalment
Master-Detail to **Instalment Plan**.
| Field | Type |
|---|---|
| Due Date | Date |
| Amount Due | Currency |
| Amount Paid | Roll-Up Summary (Sum, from Payment) — build after Payment exists |
| Balance | Formula (Currency): `Amount_Due__c - Amount_Paid__c` |
| Days Late | Formula (Number): `IF(TODAY() > Due_Date__c, TODAY() - Due_Date__c, 0)` |
| Status | Picklist — values: Upcoming, Due, Paid, Late, Default |
| Default Alert Sent | Checkbox |

## 9. Payment
Master-Detail to **Opportunity**. Lookup to **Instalment** (optional).
| Field | Type |
|---|---|
| Amount | Currency (negative = reversal) |
| Type | Picklist — values: Down Payment, Instalment, Full Payment |
| Method | Picklist — values: Bank Transfer, Card |
| Paid On | Date |
| Recorded By | Lookup → User |
| Reversal Of | Lookup → Payment (self-lookup) |
| Reversal Reason | Text |

## 10. Reconciliation Entry
Standalone (no master-detail).
| Field | Type |
|---|---|
| Date | Date |
| Recorded Total | Currency |
| Bank Total | Currency |
| Difference | Formula (Currency): `Recorded_Total__c - Bank_Total__c` |
| Status | Picklist — values: Matched, Flagged, Explained |
| Note | Long Text Area |
| Bank Account | Text |

## 11. Import Request
Lookups to **Account**, **Vehicle Model**, **Opportunity** (optional), **User**.
| Field | Type |
|---|---|
| Account | Lookup → Account |
| Vehicle Model | Lookup → Vehicle Model |
| Opportunity | Lookup → Opportunity (optional) |
| Requested By | Lookup → User |
| Status | Picklist — values: Requested, Customer Confirmed, Finance Confirmed, Imported, Cancelled |
| Invoice Reference | Text |
| Customer Confirmed | Checkbox |
| Customer Confirmed On | Date |
| Expected Arrival | Date |
| Arrived On | Date |

## 12. Legal Escalation
Lookups to **Account**, **Instalment Plan**, **User**, **Guarantor** (new, v8).
| Field | Type |
|---|---|
| Account | Lookup → Account |
| Instalment Plan | Lookup → Instalment Plan |
| **Vehicle Purchased** (new, v8) | Text (or Lookup → Vehicle if you want it structured) |
| **Contract Number** (new, v8) | Text |
| Months Defaulted | Number |
| Total Amount Owed | Currency |
| **Amount Paid** (new, v8) | Currency |
| **Outstanding Balance** (new, v8) | Formula (Currency): `Total_Amount_Owed__c - Amount_Paid__c` |
| **Number of Missed Payments** (new, v8) | Number |
| **Guarantor Information** (new, v8) | Lookup → Guarantor |
| Escalated By | Lookup → User |
| Escalated On | Date |
| Status | Picklist — **4 values (v8 confirmed)**: Open, In Progress, Settled, Closed |
| Legal Team Notified At | Date/Time |
| Note | Long Text Area |

## 13. Customer Message
Lookups to **Case**, **Instalment**, **Account**.
| Field | Type |
|---|---|
| Type | Picklist — values: Acknowledgement, Status Update, Resolution, Satisfaction Request |
| Channel | Picklist — values: Email, WhatsApp, Text, Phone |
| Sent At | Date/Time |
| Sent By | Text (automatic or user) |
| Message Text | Long Text Area |
| Case | Lookup → Case |
| Instalment | Lookup → Instalment |
| Account | Lookup → Account |

## 14. Knowledge Article
Standalone.
| Field | Type |
|---|---|
| Title | Text |
| Issue Description | Long Text Area |
| Agreed Answer | Long Text Area |
| Status | Picklist — values: Draft, Published, Retired |
| Last Changed By and At | (use standard Last Modified By / Last Modified Date — no custom field needed) |

---

## Field additions on standard objects

**Lead**
- Channel: Picklist — Instagram, Walk-in, Web, Returning/High-profile
- Interest: Text
- Booked Visit Date: Date
- Customer Type: Picklist — Individual, Fleet/Corporate
- Qualification Answers: Long Text Area
- Returning or High-profile: Checkbox

**Account**
- Agreed Discount Rate: Percent (fleet only — field-level security can restrict visibility later, build the field now)
- Record Types: **Individual**, **Fleet/Corporate** (already in signed ERD v2 — build if not already there)

**Opportunity**
- Vehicle: Lookup → Vehicle
- Payment Mode: Picklist — Full Payment, Instalment
- List Price: Currency
- Discount Amount: Currency
- Fleet Rate Applied: Percent
- Sale Price: Currency
- Total Paid: Roll-Up Summary (Sum, from Payment)
- Balance Remaining: Formula (Currency): `Sale_Price__c - Total_Paid__c`

**Case**
- Channel: Picklist — Email, WhatsApp, Web, Walk-in, Text, Phone
- Type: Picklist — Sales, Payment, Technical, Documents, Other
- Routed To: Picklist — Finance, Showroom Manager, Customer Service (Technical), Other
- First Response At: Date/Time
- Resolved At: Date/Time
- Escalated At: Date/Time
- Escalated To: Lookup → User
- CSAT Requested At: Date/Time
- CSAT Score: Number (1–10, blank = unrated)

---

## When you're done with all 14 + field additions

Come back and tell me — next is Stage 2 (record types, already mostly folded in above) and Stage 3 (relationship sanity-check), then Stage 4 (validation rules). If something errors partway through (a roll-up won't save, a master-detail option is greyed out, etc.), paste the exact error and I'll debug it immediately rather than you having to guess.
