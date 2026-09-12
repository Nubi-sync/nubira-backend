-- =========================================================================
-- 53_platform_superadmin_infrastructure.sql
-- Zigza MES Platform Super Admin, Tenant Factories & Inbound Demo Leads
-- Target: Supabase PostgreSQL (nnhzqvdmkarpwtkzjnra)
-- =========================================================================

-- Enable pgcrypto extension for UUID generation if not already active
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================================================
-- 1. TABLE: platform_demo_requests
-- Stores inbound live demo requests and commercial inquiries from the landing site
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.platform_demo_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_name TEXT NOT NULL,
  company_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  preferred_plan TEXT NOT NULL DEFAULT 'FULL_PLANT_AI',
  city_state TEXT,
  estimated_machines INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'NEW_LEAD',
  notes TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  contacted_at TIMESTAMPTZ,
  provisioned_tenant_id UUID,
  CONSTRAINT platform_demo_requests_status_check 
    CHECK (status IN ('NEW_LEAD', 'CONTACTED', 'DEMO_SCHEDULED', 'PROVISIONED_TENANT', 'ARCHIVED')),
  CONSTRAINT platform_demo_requests_plan_check 
    CHECK (preferred_plan IN ('MODULAR', 'FULL_PLANT_AI', 'CUSTOM'))
);

CREATE INDEX IF NOT EXISTS idx_platform_demo_status ON public.platform_demo_requests(status);
CREATE INDEX IF NOT EXISTS idx_platform_demo_submitted_at ON public.platform_demo_requests(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_demo_email ON public.platform_demo_requests(email);

-- =========================================================================
-- 2. TABLE: platform_tenant_factories
-- Stores registered and provisioned client garment manufacturing units
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.platform_tenant_factories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  plant_slug TEXT UNIQUE NOT NULL,
  admin_email TEXT UNIQUE NOT NULL,
  admin_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  city_state TEXT NOT NULL,
  subscription_tier TEXT NOT NULL DEFAULT 'FULL_PLANT_AI',
  monthly_billing_inr NUMERIC(12, 2) NOT NULL DEFAULT 4999.00,
  active_divisions_count INTEGER NOT NULL DEFAULT 11,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  allowed_divisions TEXT[] NOT NULL DEFAULT ARRAY[
    '/design',
    '/merchandising',
    '/central-store',
    '/cutting',
    '/printing',
    '/embroidery',
    '/stitching-sewing',
    '/washing',
    '/ironing',
    '/ready-goods',
    '/alteration'
  ]::TEXT[],
  provisioned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  demo_request_id UUID REFERENCES public.platform_demo_requests(id) ON DELETE SET NULL,
  CONSTRAINT platform_tenant_factories_status_check 
    CHECK (status IN ('ACTIVE', 'PENDING_SETUP', 'SUSPENDED')),
  CONSTRAINT platform_tenant_factories_tier_check 
    CHECK (subscription_tier IN ('MODULAR', 'FULL_PLANT_AI', 'CUSTOM'))
);

CREATE INDEX IF NOT EXISTS idx_platform_tenants_status ON public.platform_tenant_factories(status);
CREATE INDEX IF NOT EXISTS idx_platform_tenants_slug ON public.platform_tenant_factories(plant_slug);
CREATE INDEX IF NOT EXISTS idx_platform_tenants_email ON public.platform_tenant_factories(admin_email);

-- =========================================================================
-- 3. TABLE: platform_audit_logs
-- Immutable cryptographic & operational audit log for root superadmin actions
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.platform_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  log_code TEXT NOT NULL,
  actor TEXT NOT NULL,
  action TEXT NOT NULL,
  category TEXT NOT NULL,
  details TEXT NOT NULL,
  ip_address TEXT NOT NULL DEFAULT '127.0.0.1',
  location TEXT NOT NULL DEFAULT 'India',
  status TEXT NOT NULL DEFAULT 'SUCCESS',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT platform_audit_category_check 
    CHECK (category IN ('AUTH', 'PROVISIONING', 'SECURITY_ALERT', 'CONFIG_CHANGE')),
  CONSTRAINT platform_audit_status_check 
    CHECK (status IN ('SUCCESS', 'WARNING', 'FAILED'))
);

CREATE INDEX IF NOT EXISTS idx_platform_audit_created ON public.platform_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_audit_actor ON public.platform_audit_logs(actor);
CREATE INDEX IF NOT EXISTS idx_platform_audit_category ON public.platform_audit_logs(category);

-- =========================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================
ALTER TABLE public.platform_demo_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_tenant_factories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow anyone (public/anon) to submit a live demo inquiry from the landing page
CREATE POLICY "Allow public demo lead submission"
  ON public.platform_demo_requests
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Allow authenticated platform admins & service role full access to demo inquiries
CREATE POLICY "Allow admin full access to demo requests"
  ON public.platform_demo_requests
  FOR ALL
  TO authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- Allow platform admins & service role full access to tenant factories
CREATE POLICY "Allow admin full access to tenant factories"
  ON public.platform_tenant_factories
  FOR ALL
  TO authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- Allow platform admins & service role full access to audit logs
CREATE POLICY "Allow admin full access to audit logs"
  ON public.platform_audit_logs
  FOR ALL
  TO authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- =========================================================================
-- 5. INITIAL SEED DATA
-- =========================================================================

-- Inbound Demo Leads (Realistic garment hubs across India)
INSERT INTO public.platform_demo_requests (
  id, applicant_name, company_name, phone, email, preferred_plan, city_state, estimated_machines, status, submitted_at, notes
) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'K. V. Ramanathan', 'Tirupur Knitwear Cluster Ltd', '+91 98430 11223', 'kv.raman@tirupurknits.in', 'FULL_PLANT_AI', 'Tirupur, Tamil Nadu', 120, 'NEW_LEAD', now() - INTERVAL '2 hours', 'Interested in cutting lot sync & piece-rate wage calculation.'),
  ('b0000000-0000-0000-0000-000000000002', 'Harpreet Singh Sandhu', 'Ludhiana Woollens & Apparel', '+91 98141 55667', 'h.sandhu@ludhianaapparel.com', 'FULL_PLANT_AI', 'Ludhiana, Punjab', 85, 'CONTACTED', now() - INTERVAL '6 hours', 'Spoke on WhatsApp. Requested evening demo walkthrough.'),
  ('b0000000-0000-0000-0000-000000000003', 'Rajesh K. Choksi', 'Surat Textile Processors', '+91 98250 33441', 'rajesh@suratprocess.in', 'MODULAR', 'Surat, Gujarat', 45, 'DEMO_SCHEDULED', now() - INTERVAL '1 day', 'Scheduled screen-share for fabric godown and GRN tracking.'),
  ('b0000000-0000-0000-0000-000000000004', 'Deepak Sharma', 'Arvind Fashions Supply Partner', '+91 98801 77889', 'deepak.s@bangaloregarments.com', 'FULL_PLANT_AI', 'Bengaluru, Karnataka', 210, 'PROVISIONED_TENANT', now() - INTERVAL '2 days', 'Allotted full 11-division MES cluster on Dedicated Tier.'),
  ('b0000000-0000-0000-0000-000000000005', 'Amitav Bose', 'Noida Export Garments Unit 3', '+91 98112 99001', 'amitav@noidaexports.in', 'CUSTOM', 'Noida, Uttar Pradesh', 320, 'CONTACTED', now() - INTERVAL '3 days', 'Enterprise multi-buyer audit required.'),
  ('b0000000-0000-0000-0000-000000000006', 'Virendra Rathore', 'Jaipur Handloom & Prints', '+91 94140 44556', 'virendra@jaipurprints.com', 'MODULAR', 'Jaipur, Rajasthan', 35, 'ARCHIVED', now() - INTERVAL '5 days', 'Follow up after festive production season.')
ON CONFLICT (id) DO NOTHING;

-- Active Tenant Factories
INSERT INTO public.platform_tenant_factories (
  id, company_name, plant_slug, admin_email, admin_name, phone, city_state, subscription_tier, monthly_billing_inr, active_divisions_count, status, provisioned_at, last_active_at
) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Vardhman Garment Division', 'vardhman-textiles', 'admin@vardhman.com', 'Ashok Singhania', '+91 98140 00112', 'Baddi, Himachal Pradesh', 'FULL_PLANT_AI', 4999.00, 11, 'ACTIVE', now() - INTERVAL '28 days', now() - INTERVAL '12 minutes'),
  ('c0000000-0000-0000-0000-000000000002', 'Page Industries Unit 7', 'page-industries-u7', 'operations@pageind.com', 'M. Venkatesh', '+91 98450 99881', 'Bengaluru, Karnataka', 'FULL_PLANT_AI', 4999.00, 11, 'ACTIVE', now() - INTERVAL '20 days', now() - INTERVAL '4 minutes'),
  ('c0000000-0000-0000-0000-000000000003', 'Shahi Exports Plant 12', 'shahi-exports-p12', 'mes@shahiexports.com', 'Praveen Kumar', '+91 98100 22334', 'Faridabad, Haryana', 'CUSTOM', 9999.00, 11, 'ACTIVE', now() - INTERVAL '14 days', now() - INTERVAL '1 hour'),
  ('c0000000-0000-0000-0000-000000000004', 'Eastman Exports Garmenting', 'eastman-exports', 'plant@eastmanexports.in', 'S. Natarajan', '+91 98422 66778', 'Tirupur, Tamil Nadu', 'MODULAR', 1999.00, 3, 'PENDING_SETUP', now() - INTERVAL '2 days', now() - INTERVAL '2 days')
ON CONFLICT (admin_email) DO NOTHING;

-- Security & Audit Logs
INSERT INTO public.platform_audit_logs (
  id, log_code, actor, action, category, details, ip_address, location, status, created_at
) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'LOG-8801', 'admin@zigza.in', 'Root SuperAdmin Sign-In', 'AUTH', 'Authenticated via Platform Master Portal challenge', '103.24.12.89', 'Burhanpur, MP, India', 'SUCCESS', now() - INTERVAL '15 minutes'),
  ('d0000000-0000-0000-0000-000000000002', 'LOG-8802', 'admin@zigza.in', 'Tenant Provisioning Completed', 'PROVISIONING', 'Generated credentials and allotted 11 divisions for Shahi Exports Plant 12', '103.24.12.89', 'Burhanpur, MP, India', 'SUCCESS', now() - INTERVAL '40 minutes'),
  ('d0000000-0000-0000-0000-000000000003', 'LOG-8803', 'system_bot', 'Demo Lead Ingestion', 'CONFIG_CHANGE', 'New inquiry registered: Arvind Fashions (Deepak Sharma, Bengaluru)', '49.207.211.34', 'Bengaluru, KA, India', 'SUCCESS', now() - INTERVAL '2 hours'),
  ('d0000000-0000-0000-0000-000000000004', 'LOG-8804', 'unknown@external', 'Repeated Invalid Sign-In Attempt', 'SECURITY_ALERT', '3 consecutive failed attempts on /login; IP rate-limited for 15 minutes', '185.220.101.5', 'Frankfurt, Germany', 'WARNING', now() - INTERVAL '3 hours'),
  ('d0000000-0000-0000-0000-000000000005', 'LOG-8805', 'admin@zigza.in', 'API Key Re-Issue', 'PROVISIONING', 'Rotated Supabase Service Role client keys for Raymon Mills Plant', '103.24.12.89', 'Burhanpur, MP, India', 'SUCCESS', now() - INTERVAL '5 hours'),
  ('d0000000-0000-0000-0000-000000000006', 'LOG-8806', 'admin@zigza.in', 'Division Module Entitlement Added', 'CONFIG_CHANGE', 'Enabled Washing & Garment Finishing unit for Eastman Exports', '103.24.12.89', 'Burhanpur, MP, India', 'SUCCESS', now() - INTERVAL '1 day'),
  ('d0000000-0000-0000-0000-000000000007', 'LOG-8807', 'system_backup', 'PostgreSQL Snapshot Sync', 'AUTH', 'Encrypted AES-256 cloud snapshot created for multi-tenant partitions', '10.0.4.12', 'AWS ap-south-1 Mumbai', 'SUCCESS', now() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;
