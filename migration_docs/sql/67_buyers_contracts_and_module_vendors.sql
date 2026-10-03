-- =============================================================================
-- Migration 67: Buyers Contract Roster & 12 Factory Module Vendors
-- Description: Creates schema for 12 factory module vendor assignments, 
-- buyer master profiles, and contract fulfillment linkage.
-- =============================================================================

-- 1. Create module_vendors Table
CREATE TABLE IF NOT EXISTS public.module_vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_route TEXT NOT NULL,
    module_name TEXT NOT NULL,
    company_name TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    phone TEXT NOT NULL,
    tenant_company TEXT DEFAULT 'Nubira Creation',
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_module_vendor_route_tenant UNIQUE (module_route, tenant_company)
);

-- 2. Ensure brands Table has All Buyer Master Columns
CREATE TABLE IF NOT EXISTS public.brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_code TEXT UNIQUE NOT NULL,
    brand_name TEXT UNIQUE NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    city TEXT DEFAULT 'Kolkata, WB',
    address TEXT,
    gstin TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add any missing columns to brands if table already existed
ALTER TABLE public.brands
    ADD COLUMN IF NOT EXISTS email TEXT,
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS gstin TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3. Enhance vendors Table with module_route for cross-sync
ALTER TABLE public.vendors
    ADD COLUMN IF NOT EXISTS module_route TEXT,
    ADD COLUMN IF NOT EXISTS tenant_company TEXT DEFAULT 'Nubira Creation';

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.module_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for module_vendors
DROP POLICY IF EXISTS "Allow read module_vendors" ON public.module_vendors;
CREATE POLICY "Allow read module_vendors"
    ON public.module_vendors FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert module_vendors" ON public.module_vendors;
CREATE POLICY "Allow insert module_vendors"
    ON public.module_vendors FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update module_vendors" ON public.module_vendors;
CREATE POLICY "Allow update module_vendors"
    ON public.module_vendors FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete module_vendors" ON public.module_vendors;
CREATE POLICY "Allow delete module_vendors"
    ON public.module_vendors FOR DELETE
    USING (true);

-- 6. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_module_vendors_route ON public.module_vendors (module_route);
CREATE INDEX IF NOT EXISTS idx_module_vendors_tenant ON public.module_vendors (tenant_company);
CREATE INDEX IF NOT EXISTS idx_module_vendors_phone ON public.module_vendors (phone);
CREATE INDEX IF NOT EXISTS idx_brands_brand_name ON public.brands (brand_name);
CREATE INDEX IF NOT EXISTS idx_vendors_module_route ON public.vendors (module_route);

-- 7. Grant Permissions
GRANT ALL ON public.module_vendors TO authenticated, service_role, anon;
GRANT ALL ON public.brands TO authenticated, service_role, anon;
GRANT ALL ON public.vendors TO authenticated, service_role, anon;
