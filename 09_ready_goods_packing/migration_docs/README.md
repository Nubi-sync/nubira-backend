# Division 09: Ready Goods & Export Packing — Database Migration Guide

## 1. Overview
This directory contains the modular PostgreSQL / Supabase migration scripts for **Division 09: Ready Goods & Export Packing Floor**.

The division manages barcode hangtag attachment, folding, individual polybagging, master carton packing, bundle lineage joins (zero ghost pieces), and ANSI/ASQ Z1.4 Normal Level II AQL 2.5 quality gates.

---

## 2. Migration Execution Order

Execute the following SQL scripts in the **Supabase SQL Editor** in numbered sequence:

| Step | Script File | Description |
| :---: | :--- | :--- |
| **0** | `00_packing_unit_all_in_one.sql` | *(Optional)* Complete division schema, triggers, and RLS policies in one script |
| **1** | `01_ready_goods_cartons.sql` | Master export cartons with automatic CBM volumetric calculation |
| **2** | `02_ready_goods_carton_bundles.sql` | Mathematical join binding packed cartons back to cutting serialized bundles |
| **3** | `03_ready_goods_aql_audits.sql` | ANSI/ASQ Z1.4 Normal Level II statistical AQL inspection audits |
| **4** | `04_packing_triggers_and_functions.sql` | Automated carton status transition trigger from AQL verdict |
| **5** | `05_packing_rls_policies.sql` | Row Level Security (RLS) policies for packing and dispatch |
| **6** | `06_packing_seed_data.sql` | Reference packed master export carton joined to cutting bundles and passed AQL audit |

---

## 3. Post-Migration Verification Queries

```sql
-- 1. Verify Master Cartons & Calculated CBM
SELECT carton_barcode, total_pieces, gross_weight_kg, cbm, status 
FROM public.ready_goods_cartons;

-- 2. Verify Carton-to-Bundle Cryptographic Join
SELECT cb.carton_id, c.carton_barcode, cb.bundle_id, cb.pieces_from_bundle
FROM public.ready_goods_carton_bundles cb
JOIN public.ready_goods_cartons c ON c.id = cb.carton_id;

-- 3. Verify AQL Audit Clearance
SELECT a.carton_id, a.sample_size, a.critical_defects, a.major_defects, a.verdict
FROM public.ready_goods_aql_audits a;
```
