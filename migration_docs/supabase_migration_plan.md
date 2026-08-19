# Supabase Migration Plan — Complete Guide

> **RULE: Kuch implement nahi hoga jab tak aap na bolo.**
> Har phase mein ek-ek command diya jayega, sab ek sath nahi.

---

## Phase Overview

```
Phase 1: Supabase Setup (Account + Database + Auth)
   ↓
Phase 2: Web Admin Convert (Next.js → Supabase)
   → 2.1 Supabase packages install
   → 2.2 Supabase client setup
   → 2.3 Login page convert
   → 2.4 Employee page convert
   → 2.5 Articles page (NEW)
   → 2.6 Allotments page (NEW)
   ↓
Phase 3: Mobile App Convert (Flutter → Supabase)
   → 3.1 supabase_flutter package install
   → 3.2 Auth provider convert
   → 3.3 Lineman Dashboard convert
   → 3.4 Production Dashboard convert
   → 3.5 Store Dashboard convert
   → 3.6 Dispatch Dashboard (NEW)
   ↓
Phase 4: Testing
```

> **Approach:**
> - Pehle **Web Admin** ke saare features ek-ek karke complete karenge
> - Web poora hone ke baad **Mobile App** ke features ek-ek karke karenge
> - Har step ke baad aapko bata diya jayega, fir aap agle step ke liye bolenge

---

## Step 1: Supabase Account Banana

### 1.1 Sign Up
1. Browser mein jao: **https://supabase.com**
2. **"Start your project"** ya **"Sign Up"** par click karo
3. **GitHub account** se login karo (sabse aasan). Agar GitHub nahi hai toh email se bhi ho jayega.
4. Login hone ke baad aap **Dashboard** par aa jaoge.

### 1.2 Naya Project Banana
1. Dashboard par **"New Project"** button par click karo
2. Yeh details bharo:

| Field | Kya daalein |
|-------|-------------|
| **Organization** | Pehli baar mein auto ban jayega (aapka naam aa jayega) |
| **Project Name** | `nubira-factory` |
| **Database Password** | Ek strong password dalo. **Isko kahin note karke rakh lo!** |
| **Region** | **South Asia (Mumbai)** |
| **Pricing Plan** | **Free** |

3. **"Create new project"** par click karo
4. 2-3 minute lagenge setup mein.

### 1.3 Important Credentials (Note karo)
Project ban jaane ke baad, **Settings → API** mein jao:

| Credential | Kahan milega | Kya hai |
|------------|-------------|---------|
| **Project URL** | Settings → API | `https://xxxxx.supabase.co` — aapka backend address |
| **anon (public) key** | Settings → API | Public API key — Flutter aur Next.js mein use hoga |
| **service_role key** | Settings → API | **SECRET** key — sirf server-side Admin ke liye |

---

## Step 2: Database Tables Banana

### 2.1 SQL Editor kaise kholein
1. Left sidebar mein **"SQL Editor"** icon par click karo
2. **"New Query"** par click karo
3. Neeche diya hua SQL paste karo aur **"Run"** dabao

### 2.2 Tables SQL

```sql
-- ============================================
-- NUBIRA FACTORY MANAGEMENT SYSTEM
-- Complete Database Schema
-- ============================================

-- 1. PROFILES (User details + role)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ADMIN', 'LINEMAN', 'PRODUCTION', 'STORE', 'DISPATCH')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. ARTICLES (Art No. Master)
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  art_no TEXT UNIQUE NOT NULL,
  description TEXT,
  stitching_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. RATE HISTORY
CREATE TABLE rate_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  old_rate DECIMAL(10,2) NOT NULL,
  new_rate DECIMAL(10,2) NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- 4. ALLOTMENTS (Admin → Lineman assignment)
CREATE TABLE allotments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lineman_id UUID NOT NULL REFERENCES profiles(id),
  article_id UUID NOT NULL REFERENCES articles(id),
  target_qty INTEGER NOT NULL,
  allotment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. DAILY PRODUCT (Lineman daily log)
CREATE TABLE daily_product (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lineman_id UUID NOT NULL REFERENCES profiles(id),
  employee_id UUID NOT NULL REFERENCES profiles(id),
  article_id UUID NOT NULL REFERENCES articles(id),
  quantity INTEGER NOT NULL,
  notes TEXT,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. QC LOGS
CREATE TABLE qc_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  stage TEXT NOT NULL CHECK (stage IN ('RECEIVING', 'CHECKING', 'MENDING', 'BULKING')),
  from_lineman_id UUID REFERENCES profiles(id),
  qty_received INTEGER DEFAULT 0,
  qty_passed INTEGER DEFAULT 0,
  qty_rejected INTEGER DEFAULT 0,
  defect_type TEXT DEFAULT 'NONE',
  remarks TEXT,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. STORE TRANSACTIONS
CREATE TABLE store_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  type TEXT NOT NULL CHECK (type IN ('INWARD', 'OUTWARD')),
  quantity INTEGER NOT NULL,
  party_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. ACCESSORIES
CREATE TABLE accessories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('IN', 'OUT')),
  quantity INTEGER NOT NULL,
  unit TEXT DEFAULT 'pcs',
  party_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. COUNTING REPORTS
CREATE TABLE counting_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  size TEXT,
  counted_qty INTEGER NOT NULL,
  expected_qty INTEGER DEFAULT 0,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. DELIVERY CHALLANS
CREATE TABLE delivery_challans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challan_no TEXT UNIQUE NOT NULL,
  buyer_name TEXT NOT NULL,
  destination TEXT,
  vehicle_no TEXT,
  driver_name TEXT,
  total_pieces INTEGER DEFAULT 0,
  delivery_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 11. CHALLAN ITEMS
CREATE TABLE challan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challan_id UUID NOT NULL REFERENCES delivery_challans(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES articles(id),
  size TEXT,
  quantity INTEGER NOT NULL
);
```

### 2.3 Check karo
Tables banne ke baad left sidebar mein **"Table Editor"** par click karo — saari 11 tables dikhengi.

---

## Step 3: Row Level Security (RLS)

SQL Editor mein naya query banao aur yeh paste karo:

```sql
-- RLS Enable
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE allotments ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_product ENABLE ROW LEVEL SECURITY;
ALTER TABLE qc_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE counting_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_challans ENABLE ROW LEVEL SECURITY;
ALTER TABLE challan_items ENABLE ROW LEVEL SECURITY;

-- Helper Function
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- PROFILES
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT
  USING (id = auth.uid() OR get_my_role() = 'ADMIN');
CREATE POLICY "Admin can insert profiles" ON profiles FOR INSERT
  WITH CHECK (get_my_role() = 'ADMIN');
CREATE POLICY "Admin can update any profile" ON profiles FOR UPDATE
  USING (get_my_role() = 'ADMIN');

-- ARTICLES
CREATE POLICY "Everyone can read articles" ON articles FOR SELECT USING (true);
CREATE POLICY "Admin can manage articles" ON articles FOR ALL USING (get_my_role() = 'ADMIN');

-- ALLOTMENTS
CREATE POLICY "Lineman sees own allotments" ON allotments FOR SELECT
  USING (lineman_id = auth.uid() OR get_my_role() = 'ADMIN');
CREATE POLICY "Admin can manage allotments" ON allotments FOR ALL
  USING (get_my_role() = 'ADMIN');

-- DAILY PRODUCT
CREATE POLICY "Lineman can insert own product" ON daily_product FOR INSERT
  WITH CHECK (lineman_id = auth.uid());
CREATE POLICY "Lineman sees own entries" ON daily_product FOR SELECT
  USING (lineman_id = auth.uid() OR get_my_role() = 'ADMIN');
CREATE POLICY "Lineman can update own entries" ON daily_product FOR UPDATE
  USING (lineman_id = auth.uid() AND entry_date = CURRENT_DATE);
CREATE POLICY "Lineman can delete own today entries" ON daily_product FOR DELETE
  USING (lineman_id = auth.uid() AND entry_date = CURRENT_DATE);

-- QC LOGS
CREATE POLICY "Production can manage qc_logs" ON qc_logs FOR ALL
  USING (get_my_role() IN ('PRODUCTION', 'ADMIN'));
CREATE POLICY "Everyone can read qc_logs" ON qc_logs FOR SELECT USING (true);

-- STORE TRANSACTIONS
CREATE POLICY "Store can manage transactions" ON store_transactions FOR ALL
  USING (get_my_role() IN ('STORE', 'ADMIN'));
CREATE POLICY "Everyone can read store transactions" ON store_transactions FOR SELECT USING (true);

-- ACCESSORIES
CREATE POLICY "Store can manage accessories" ON accessories FOR ALL
  USING (get_my_role() IN ('STORE', 'ADMIN'));

-- COUNTING REPORTS
CREATE POLICY "Dispatch can manage counting" ON counting_reports FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));

-- DELIVERY CHALLANS
CREATE POLICY "Dispatch can manage challans" ON delivery_challans FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));
CREATE POLICY "Everyone can read challans" ON delivery_challans FOR SELECT USING (true);

-- CHALLAN ITEMS
CREATE POLICY "Dispatch can manage challan items" ON challan_items FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));
CREATE POLICY "Everyone can read challan items" ON challan_items FOR SELECT USING (true);

-- RATE HISTORY
CREATE POLICY "Everyone can read rate history" ON rate_history FOR SELECT USING (true);
CREATE POLICY "Admin can insert rate history" ON rate_history FOR INSERT
  WITH CHECK (get_my_role() = 'ADMIN');
```

---

## Step 4: Auth Setup

### 4.1 Settings
1. Supabase Dashboard → **Authentication → Settings → Email**
2. **Confirm Email** → ❌ OFF (factory workers ke paas email nahi)

### 4.2 Username Trick
Supabase email-based auth use karta hai. Hum username ko fake email banayenge:
```
username "ramesh" → email "ramesh@nubira.local"
```
User ko kuch pata nahi chalega, wo sirf username daalega.

### 4.3 First Admin User
1. **Authentication → Users → Add User → Create New User**
2. Email: `admin@nubira.local`, Password: apna password
3. **Auto Confirm** ✅ check karo
4. User banega, UUID copy karo
5. SQL Editor mein:
```sql
INSERT INTO profiles (id, username, role)
VALUES ('paste-uuid-here', 'admin', 'ADMIN');
```

---

## Step 5: Web Admin Integration (EK-EK KARKE)

> Jab aap bolenge "web shuru karo", tab yeh steps ek-ek karke diye jayenge:

| Step | Kya hoga | Kab |
|------|---------|-----|
| 5.1 | Supabase packages install | Jab aap bolo |
| 5.2 | Supabase client file banao | Uske baad |
| 5.3 | Login page → Supabase Auth | Uske baad |
| 5.4 | Employee page → Supabase | Uske baad |
| 5.5 | Articles page (NEW) | Uske baad |
| 5.6 | Allotments page (NEW) | Uske baad |
| 5.7 | Dashboard stats → Supabase | Uske baad |

---

## Step 6: Mobile App Integration (EK-EK KARKE)

> Jab Web poora ho jayega aur aap bolenge "app shuru karo", tab yeh steps ek-ek karke diye jayenge:

| Step | Kya hoga | Kab |
|------|---------|-----|
| 6.1 | supabase_flutter install | Jab aap bolo |
| 6.2 | Auth provider convert | Uske baad |
| 6.3 | Lineman Dashboard convert | Uske baad |
| 6.4 | Production Dashboard convert | Uske baad |
| 6.5 | Store Dashboard convert | Uske baad |
| 6.6 | Dispatch Dashboard (NEW) | Uske baad |

---

## Architecture: Before vs After

```
PEHLE:
Phone → Tunnel → NestJS → Local PostgreSQL
Web   → localhost:3000 → NestJS → Local PostgreSQL

BAAD MEIN:
Phone → Supabase Cloud (direct)
Web   → Supabase Cloud (direct)
```

> **Kya hatega:** NestJS backend, Cloudflare Tunnel, local PostgreSQL
> **Kya rahega:** Flutter app, Next.js web, poora UI, AppTheme, offline SQLite
