# Division 08: Steam Ironing & Finishing Floor — Database Migration Guide

## 1. Overview
This directory contains the modular PostgreSQL / Supabase migration scripts for **Division 08: Steam Ironing & Finishing Floor**.

The division manages central steam boiler delivery (4.5–6.0 Bar), industrial vacuum buck tables, pressing piece-rate wage calculations, and zero-glaze quality audits under 1000-lux neutral inspection lighting.

---

## 2. Migration Execution Order

Execute the following SQL scripts in the **Supabase SQL Editor** in numbered sequence:

| Step | Script File | Description |
| :---: | :--- | :--- |
| **0** | `00_ironing_unit_all_in_one.sql` | *(Optional)* Complete division schema, triggers, and RLS policies in one script |
| **1** | `01_iron_tables.sql` | Vacuum suction buck tables and finishing station registry |
| **2** | `02_iron_production_logs.sql` | Pressing output, boiler pressure telemetry, and piecework wage calculations |
| **3** | `03_iron_defect_audits.sql` | Thermal shine glaze, water spot, and scorch defect audits |
| **4** | `04_iron_triggers_and_functions.sql` | Automated updated_at timestamp triggers |
| **5** | `05_iron_rls_policies.sql` | Row Level Security (RLS) policies for finishing floor roles |
| **6** | `06_iron_seed_data.sql` | 12 factory vacuum buck tables and reference production logs |

---

## 3. Post-Migration Verification Queries

```sql
-- 1. Verify Vacuum Tables
SELECT table_code, table_type, operating_steam_bar, is_active 
FROM public.iron_tables;

-- 2. Verify Ironing Production Logs & Wages
SELECT log_number, garments_pressed, boiler_pressure_bar, standard_sam_per_pc, status
FROM public.iron_production_logs;

-- 3. Verify Finishing Defect Audits
SELECT d.defect_type, d.defect_count, d.disposition
FROM public.iron_defect_audits d;
```
