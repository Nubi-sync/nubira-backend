# Division 10: Alteration & Quality Rework Clinic — Database Migration Guide

## 1. Overview
This directory contains the modular PostgreSQL / Supabase migration scripts for **Division 10: Alteration & Quality Rework Clinic**.

The division serves as the factory triage clinic, tracking defect intake triage tickets, original tailor root causes, repair tailors, secondary QC inspection clearance, and irreparable scrap financial loss accruals.

---

## 2. Migration Execution Order

Execute the following SQL scripts in the **Supabase SQL Editor** in numbered sequence:

| Step | Script File | Description |
| :---: | :--- | :--- |
| **0** | `00_alteration_clinic_all_in_one.sql` | *(Optional)* Complete division schema, triggers, and RLS policies in one script |
| **1** | `01_alteration_tickets.sql` | Master defect intake, triage, tailor reassignment, and status tickets |
| **2** | `02_alteration_scrap_logs.sql` | Financial scrap loss ledger tracking condemned pieces and INR monetary loss |
| **3** | `03_allotments_bundle_link.sql` | Purely additive nullable foreign key linking sewing allotments to cutting bundles |
| **4** | `04_alteration_triggers_and_functions.sql` | Automated updated_at timestamp triggers |
| **5** | `05_alteration_rls_policies.sql` | Row Level Security (RLS) policies for alteration and mending roles |
| **6** | `06_alteration_seed_data.sql` | Operational triage ticket and scrap loss record |

---

## 3. Post-Migration Verification Queries

```sql
-- 1. Verify Alteration Tickets
SELECT ticket_number, defect_category, defect_severity, pieces_received, pieces_repaired, status 
FROM public.alteration_tickets;

-- 2. Verify Scrap Financial Ledger
SELECT s.ticket_id, s.scrapped_pieces, s.scrap_reason, s.estimated_financial_loss_inr
FROM public.alteration_scrap_logs s;

-- 3. Verify Non-Destructive Allotment Link
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'allotments' AND column_name = 'bundle_id';
```
