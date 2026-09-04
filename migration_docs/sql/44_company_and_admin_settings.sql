-- =========================================================================
-- 44_company_and_admin_settings.sql
-- Company Profile, Admin Settings & Account Deletion Requests
-- =========================================================================

-- 1. Create company_profile table for factory and admin settings
CREATE TABLE IF NOT EXISTS public.company_profile (
  id TEXT PRIMARY KEY DEFAULT 'default',
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  factory_address TEXT DEFAULT 'Rafi Ahmed Kidwai Road, Kolkata 700055, West Bengal',
  gstin TEXT DEFAULT '19AADCO1064C1ZK',
  contact_phone TEXT DEFAULT '+91 98765 43210',
  contact_email TEXT DEFAULT 'creationnubira@gmail.com',
  admin_display_name TEXT DEFAULT 'Admin',
  admin_phone TEXT DEFAULT '+91 98765 43210',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default company row if not exists
INSERT INTO public.company_profile (
  id,
  company_name,
  factory_address,
  gstin,
  contact_phone,
  contact_email,
  admin_display_name,
  admin_phone
)
VALUES (
  'default',
  'Nubira Creation',
  'Rafi Ahmed Kidwai Road, Kolkata 700055, West Bengal',
  '19AADCO1064C1ZK',
  '+91 98765 43210',
  'creationnubira@gmail.com',
  'Admin',
  '+91 98765 43210'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create account_deletion_requests table
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  admin_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  reason TEXT,
  status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- 3. Enable RLS and add policies
ALTER TABLE public.company_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "company_profile_allow_all" ON public.company_profile;
CREATE POLICY "company_profile_allow_all" ON public.company_profile
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "account_deletion_requests_allow_all" ON public.account_deletion_requests;
CREATE POLICY "account_deletion_requests_allow_all" ON public.account_deletion_requests
  FOR ALL USING (true) WITH CHECK (true);
