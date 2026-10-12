# AutoDrive-SFDX

Local Salesforce DX project for the AutoDrive Motors capstone (Group 3). Metadata written here (Apex, LWC, Flow XML, object/field definitions) gets deployed to the team sandbox by whoever is running the deploy — not automatically, and not by Claude.

## Connect to the sandbox (do this yourself, once)

```bash
sf org login web --alias autodrive-dev --instance-url https://dk1791276250211--group3sb.sandbox.my.salesforce.com
```

This opens your browser for you to log in and consent — nothing is handled outside that browser window. Once authorized, `autodrive-dev` becomes the alias for every command below.

## Everyday commands

| What | Command |
|---|---|
| Check who you're connected as | `sf org display --target-org autodrive-dev` |
| Retrieve what's already in the sandbox | `sf project retrieve start --target-org autodrive-dev` |
| Deploy what's in `force-app/` | `sf project deploy start --target-org autodrive-dev` |
| Check a deploy's status | `sf project deploy report --target-org autodrive-dev` |
| Open the sandbox in a browser | `sf org open --target-org autodrive-dev` |

## Project structure

```
force-app/main/default/
  classes/            Apex classes (VIN lookup exception)
  lwc/                Lightning web components (VIN lookup display)
  flows/              Flow metadata XML (payment schedule, reminders, legal escalation, etc.)
  objects/            Custom object + field definitions, validation rules, record types
  permissionsets/     Permission sets (Security Matrix — see TAP 3.0/AutoDrive_Design_Pack_Reconstructed.md)
  layouts/            Page layouts
  flexipages/         Lightning record pages
  applications/       Lightning apps
  triggers/           Apex triggers (only if a Flow genuinely can't do it — declarative first)
```

## Source of truth for what goes in each folder

This project holds code, not decisions. For what to build and why:
- `../TAP 3.0/AutoDrive_Design_Pack_Reconstructed.md` — Security Matrix, Locked Fields, Automation List, ERD field changes.
- `../TAP 3.0/AutoDrive_TOBE_Process_Map_v2.drawio` — process flow, stage by stage.
- `../Kingsley - Solution Builder/TASKS.md` — build order, validation rules, Flow specs.
- Jira project **KAN** — the full backlog, story by story.

## Who deploys

Per the Delivery Plan: everybody builds, but **one person owns deployment** — that's the Release Lead (Hillary), and only at Week 6, DEV → PRD, via Change Set. Until then, this `autodrive-dev` connection is for building and testing in the team's shared DEV sandbox — treat it the same as Setup-UI building: visible to the whole team, nobody refreshes it, and whoever runs a deploy here should be the person who understands what's in it.
