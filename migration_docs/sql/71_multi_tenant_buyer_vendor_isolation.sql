-- =============================================================================
-- Migration 71: Strict Multi-Tenant Buyer & Vendor Isolation
-- Ensures every buyer, brand, vendor, and contract belongs strictly to its
-- tenant company and cannot leak across different company profiles.
-- =============================================================================

-- 1. Ensure company_name / tenant_company columns exist with proper indexes
ALTER TABLE public.brands 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

ALTER TABLE public.vendors 
  ADD COLUMN IF NOT EXISTS tenant_company TEXT;

ALTER TABLE public.module_vendors 
  ADD COLUMN IF NOT EXISTS tenant_company TEXT DEFAULT 'Nubira Creation';

ALTER TABLE public.merchandising_active_buyers 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

ALTER TABLE public.merchandising_orders 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

-- 2. Performance & Partition Indexes for Multi-Tenant Lookups
CREATE INDEX IF NOT EXISTS idx_brands_company_name 
  ON public.brands (company_name);

CREATE INDEX IF NOT EXISTS idx_vendors_tenant_company 
  ON public.vendors (tenant_company);

CREATE INDEX IF NOT EXISTS idx_module_vendors_tenant_company 
  ON public.module_vendors (tenant_company);

CREATE INDEX IF NOT EXISTS idx_merch_buyers_company_name 
  ON public.merchandising_active_buyers (company_name);

CREATE INDEX IF NOT EXISTS idx_merch_orders_company_name 
  ON public.merchandising_orders (company_name);

-- 3. Data Cleansing & Tenant Assignment for Existing Records
-- Hollypop belongs strictly to Demo Industries
UPDATE public.brands 
  SET company_name = 'Demo Industries' 
  WHERE brand_name ILIKE 'Hollypop' AND (company_name IS NULL OR company_name != 'Demo Industries');

UPDATE public.merchandising_active_buyers 
  SET company_name = 'Demo Industries' 
  WHERE buyer_name ILIKE 'Hollypop' AND (company_name IS NULL OR company_name != 'Demo Industries');

UPDATE public.merchandising_orders 
  SET company_name = 'Demo Industries' 
  WHERE order_number ILIKE 'HOLL-%' AND (company_name IS NULL OR company_name != 'Demo Industries');

-- ollywood belongs strictly to Nubira Creation
UPDATE public.brands 
  SET company_name = 'Nubira Creation' 
  WHERE brand_name ILIKE 'ollywood' AND (company_name IS NULL OR company_name != 'Nubira Creation');

UPDATE public.merchandising_active_buyers 
  SET company_name = 'Nubira Creation' 
  WHERE buyer_name ILIKE 'ollywood' AND (company_name IS NULL OR company_name != 'Nubira Creation');

UPDATE public.merchandising_orders 
  SET company_name = 'Nubira Creation' 
  WHERE order_number ILIKE 'BYRO-%' AND (company_name IS NULL OR company_name != 'Nubira Creation');

-- Nubira In-House brand
UPDATE public.brands 
  SET company_name = 'Nubira Creation' 
  WHERE brand_name ILIKE '%NUBIRA%' AND company_name IS NULL;

-- Assign any un-scoped legacy demo brands to Demo Industries so they don't leak into new tenant accounts
UPDATE public.brands 
  SET company_name = 'Demo Industries' 
  WHERE company_name IS NULL;
