# AutoDrive Motors – Salesforce Build

A Salesforce system for **AutoDrive Motors**, a single-showroom new-car dealer that used to run on spreadsheets, phone calls and memory. It brings the whole business into one place: the cars in stock, every customer from first enquiry to final payment, discounts and who approved them, instalment plans and payments, customer service cases, and legal escalation when a customer stops paying.

Built as the Group 3 capstone (DKloud / Africa Ohana programme), from user stories through build, UAT and deployment to the go-live org.

## Who uses it

| Role | What they do in the system |
|---|---|
| Sales Rep | Record walk-ins and website enquiries, pick a car type and see live stock, request discounts and imports, run individual, instalment and fleet deals |
| Showroom Manager | Approve or reject discounts, take high-profile clients, watch stock and import requests |
| Finance Team | Approve discounts, set up instalment plans, record down payments and monthly payments |
| Head of Finance | Final discount approval, plan sign-off, late and defaulted plans, bank reconciliation, raise legal escalations |
| Legal Team | Work escalated defaults with the customer, guarantor and amount owed |
| Customer Service Agent | Work cases from the website, reply to customers by email, use the knowledge base |
| Head of Customer Service | Oversee all cases and keep the knowledge base current |
| Management | One read-only view of sales, stock, payments, legal and service |

Each role has its own profile, role, permission set group, home dashboard and record pages, and sees only what the security matrix allows.

## What it does

- **Website (Experience Cloud):** a sales enquiry form that creates a lead for a rep, and a contact-support form that creates a case routed to Finance, the Showroom or Customer Service. Customers get a reference number by email.
- **Leads to sales:** walk-ins recorded the same way every time, duplicate warnings, high-profile clients routed to the Showroom Manager, conversion to an opportunity.
- **Live stock:** the rep picks a car *type*; a free car of that type is reserved automatically and swapped if the type changes. Every list and lookup shows availability (Available · Reserved · Sold out), and a sold-out type offers a one-click import request.
- **Discounts:** small discounts approve themselves; larger ones go Showroom Manager → Finance → Head of Finance, approved from the request's own page, with a coloured step flag. Switching a deal to instalments invalidates its discount and restores the full price.
- **Instalment plans:** at least 30% down, up to 12 months, guarantor income check, Head of Finance sign-off. Payments update each month's status (Upcoming, Part Paid, Paid, Late, Default), with what is outstanding or overpaid, a month-by-month summary and a next step for Finance.
- **Reminders and defaults:** reminder emails three days before a due date, late notices, guarantor notice at 7 days, default at 30 days, legal escalation after 90 days.
- **Customer service:** cases auto-assigned to agents who are online, every message to a customer logged on the case, agent replies emailed to the customer, first-response and resolution times tracked, satisfaction score.
- **Closed deals are locked** for everyone below a head of department.
- **Dashboards and reports** for every role.

## Inside the build

| Part | Count |
|---|---|
| Custom objects | 15 (Vehicle Model, Vehicle, Discount Request, Instalment Plan, Instalment, Payment, Guarantor, Import Request, Legal Escalation, Customer Message, Knowledge Article, Reconciliation Entry, and more) |
| Flows | 81 (record-triggered, scheduled and screen flows) |
| Apex | 8 classes with 8 test classes (car assignment, auto-assignment, discount approval, plan progress, fleet vehicles, closed-deal lock) |
| Lightning web component | Low-stock indicator |
| Profiles / permission set groups | 10 roles, each with a profile and permission set group |

```
force-app/main/default/   Salesforce metadata (objects, flows, Apex, layouts, pages, sharing, site)
scripts/apex/             Test-data scripts for the UAT sandbox
scripts/apex/prod/        Fresh UAT data for the go-live org, in five steps
scripts/deploy/           Deploy helpers: username mapping and post-deploy setup
docs/                     Solution document, UAT scripts, deployment runbook
```

## Documents

- [Solution document](docs/AutoDrive_Solution_Document.md)
- [User acceptance testing](docs/AutoDrive_UAT.md) (also as [PDF](docs/AutoDrive_UAT.pdf))
- [Deployment runbook](docs/AutoDrive_Deployment_Runbook.md): deploy order, manual post-deploy steps, smoke test, rollback

## Deploying

Deploy in the runbook's order: data model and roles → Apex → flows and sharing → layouts and pages → profiles and permission set groups → website → create users → approval process, reports and dashboards.

```bash
sf project deploy validate -o <target-org> -d force-app/main/default -l RunLocalTests
```

The approval process and dashboards name real users, so fill in `scripts/deploy/target-users.csv` and run `scripts/deploy/prepare-target.ps1` before deploying them. The full steps, including email setup and publishing the website, are in the [runbook](docs/AutoDrive_Deployment_Runbook.md).

## Built with

Salesforce Platform · Flow · Apex · Lightning Web Components · Experience Cloud · Salesforce CLI
