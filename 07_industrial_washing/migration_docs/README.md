# Division 07: Industrial Washing & Wet Processing — Database Migration Guide

## 1. Overview
This directory contains the modular PostgreSQL / Supabase migration scripts for **Division 07: Industrial Washing & Wet Processing Plant**.

The division handles technical chemical finishes (Bio-Enzyme Polishing, Silicon Softening, Stone Washing), machine cycle tracking, liquor ratio calculations, and post-wash shrinkage & spirality quality gates.

---

## 2. Migration Execution Order

Execute the following SQL scripts in the **Supabase SQL Editor** in numbered sequence:

| Step | Script File | Description |
| :---: | :--- | :--- |
| **0** | `00_washing_unit_all_in_one.sql` | *(Optional)* Complete division schema, triggers, and RLS policies in one script |
| **1** | `01_washing_recipes.sql` | Master chemical formulations, liquor ratios, pH targets, and dosing standards |
| **2** | `02_washing_batches.sql` | Production washer, hydro-extractor, and tumble dryer batch runs |
| **3** | `03_washing_shrinkage_alerts.sql` | Specimen measurement table with generated shrinkage percentage columns |
| **4** | `04_washing_triggers_and_functions.sql` | Auto timestamp handlers and tolerance threshold checkers |
| **5** | `05_washing_rls_policies.sql` | Row Level Security (RLS) data access policies |
| **6** | `06_washing_seed_data.sql` | Baseline chemical recipes and operational batch linked to live order `PO-ZIG-8901` |

---

## 3. Post-Migration Verification Queries

```sql
-- 1. Verify Standard Washing Recipes
SELECT recipe_code, wash_type, liquor_ratio, wash_temperature_c, cycle_time_minutes 
FROM public.washing_recipes;

-- 2. Verify Washing Batches
SELECT b.batch_number, b.machine_id, b.total_garments, b.residual_moisture_percent, b.status
FROM public.washing_batches b;

-- 3. Verify Shrinkage Alerts & Computed Tolerances
SELECT batch_id, specimen_size, length_shrinkage_percent, width_shrinkage_percent, is_within_spec
FROM public.washing_shrinkage_alerts;
```
