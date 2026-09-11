# Division 01: Design & Tech-Pack Studio — Database Migration Guide

## 1. Overview
This directory contains the modular PostgreSQL / Supabase migration scripts for **Division 01: Design & Tech-Pack Studio**.

All tables are fully relational, enforcing strict foreign key integrity with `public.brands` and `public.profiles`, and protected by Row Level Security (RLS) policies and automated triggers.

---

## 2. Migration Execution Order

Execute the following SQL scripts in the **Supabase SQL Editor** in the exact numbered sequence:

| Step | Script File | Description |
| :---: | :--- | :--- |
| **1** | [`01_design_tech_packs.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/01_design_tech_packs.sql) | Master Tech-Pack Table (CAD files, SPI, seam class, lifecycle) |
| **2** | [`02_design_poms.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/02_design_poms.sql) | Point of Measure (POM) Master Table & ASTM tolerances |
| **3** | [`03_design_measurement_values.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/03_design_measurement_values.sql) | Multi-System Size Grading Values (Alpha, Numeric, Kids, Plus) |
| **4** | [`04_design_sample_audits.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/04_design_sample_audits.sql) | Proto 1, Proto 2, Size Set, PPS Approvals & Tolerance Gate |
| **5** | [`05_design_materials_library.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/05_design_materials_library.sql) | Fabric construction, shrinkage %, spirality %, needle classes |
| **6** | [`06_design_triggers_and_functions.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/06_design_triggers_and_functions.sql) | Auto timestamp updates & PPS golden-seal promotion trigger |
| **7** | [`07_design_rls_policies.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/07_design_rls_policies.sql) | Row Level Security (RLS) & Role-Based Access Control |
| **8** | [`08_design_seed_data.sql`](file:///d:/AndroidStudioProjects/Nubira_Creation/backend/01_design_studio/migration_docs/sql/08_design_seed_data.sql) | Reference standard styles (Hoodie ART-HD-8821) & POM matrix |

---

## 3. Post-Migration Verification Queries

After running all 8 scripts in Supabase, execute these quick diagnostic queries to verify that tables and seed data are populated:

```sql
-- 1. Verify Tech-Packs
SELECT id, style_number, category, target_gsm, status, version 
FROM public.design_tech_packs;

-- 2. Verify Graded POM Matrix for Style ART-HD-8821
SELECT 
    p.pom_name,
    p.tolerance_cm,
    v.size_label,
    v.value_cm,
    v.grade_step_cm,
    v.is_base_size
FROM public.design_poms p
JOIN public.design_measurement_values v ON v.pom_id = p.id
JOIN public.design_tech_packs tp ON tp.id = p.tech_pack_id
WHERE tp.style_number = 'ART-HD-8821'
ORDER BY p.sort_order, v.value_cm;

-- 3. Verify Materials Library
SELECT material_code, material_name, nominal_gsm, length_shrinkage_pct, recommended_needle
FROM public.design_materials_library;

-- 4. Verify Sample Approvals
SELECT tp.style_number, a.sample_stage, a.verdict, a.variance_max_cm, a.approved_at
FROM public.design_sample_audits a
JOIN public.design_tech_packs tp ON tp.id = a.tech_pack_id;
```

---

## 4. Next Step: Next.js Frontend Integration
Once these tables exist in Supabase, update `web_admin/src/app/design/` by replacing `designStorage.ts` (localStorage mock) with server-side queries in `web_admin/src/app/design/actions.ts`.
