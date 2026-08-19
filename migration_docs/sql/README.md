# SQL Migration Files — Run Order Guide

Supabase SQL Editor mein yeh files **ek-ek karke, isi order mein** run karo.
Har file run karne ke baad Table Editor mein check karo ki table bani ya nahi.

## Order:

| # | File | Kya banega | Check kaise karein |
|---|------|-----------|-------------------|
| 1 | `01_profiles.sql` | profiles table | Table Editor → "profiles" dikhni chahiye |
| 2 | `02_articles.sql` | articles table | Table Editor → "articles" dikhni chahiye |
| 3 | `03_rate_history.sql` | rate_history table | Table Editor → "rate_history" dikhni chahiye |
| 4 | `04_allotments.sql` | allotments table | Table Editor → "allotments" dikhni chahiye |
| 5 | `05_daily_product.sql` | daily_product table | Table Editor → "daily_product" dikhni chahiye |
| 6 | `06_qc_logs.sql` | qc_logs table | Table Editor → "qc_logs" dikhni chahiye |
| 7 | `07_store_transactions.sql` | store_transactions table | Table Editor → "store_transactions" dikhni chahiye |
| 8 | `08_accessories.sql` | accessories table | Table Editor → "accessories" dikhni chahiye |
| 9 | `09_counting_reports.sql` | counting_reports table | Table Editor → "counting_reports" dikhni chahiye |
| 10 | `10_delivery_challans.sql` | delivery_challans table | Table Editor → "delivery_challans" dikhni chahiye |
| 11 | `11_challan_items.sql` | challan_items table | Table Editor → "challan_items" dikhni chahiye |
| 12 | `12_enable_rls.sql` | RLS ON + helper function | Har table ke paas shield 🛡️ icon aayega |
| 13 | `13_rls_policies.sql` | Access rules | Table → Policies tab mein rules dikhenge |
| 14 | `14_first_admin_user.sql` | Admin profile entry | profiles table mein "admin" row dikhegi |

## Important Notes:
- **Order matter karta hai!** Pehle tables banao (1-11), fir RLS (12-13), fir admin (14)
- Agar koi SQL mein error aaye, toh mujhe batao — main fix kar dunga
- Step 14 ke liye pehle Dashboard se user banana padega (file mein likha hai)

## Kya karna hai:
1. Supabase account banao (agar nahi bana)
2. Project banao (Mumbai region, Free plan)
3. SQL Editor kholke **ek-ek file** copy-paste karke run karo
4. Sab ho jaye toh mujhe bolo — fir Web Admin convert karenge
