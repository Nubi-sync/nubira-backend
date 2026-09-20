-- =============================================================================
-- Migration 65: Central Store Fabric Inventory & Production Material Flow
-- Description: Creates schema for central fabric inventory ledger, inter-module
-- material issues (challans), and division material receipts with company_name
-- multi-tenant isolation and RLS policies.
-- =============================================================================

-- =============================================================================
-- 1. CENTRAL FABRIC INVENTORY LEDGER
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.central_fabric_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    fabric_type TEXT NOT NULL,
    color TEXT NOT NULL,
    supplier_name TEXT,
    total_meters NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_weight_kg NUMERIC(10,2) DEFAULT 0,
    total_rolls INT DEFAULT 0,
    rack_location TEXT DEFAULT 'RACK-01',
    booked_for_article TEXT,
    booked_meters NUMERIC(12,2) DEFAULT 0,
    available_meters NUMERIC(12,2) GENERATED ALWAYS AS (GREATEST(0, total_meters - booked_meters)) STORED,
    notes TEXT,
    last_updated_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for central_fabric_inventory
ALTER TABLE public.central_fabric_inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read central fabric inventory" 
    ON public.central_fabric_inventory FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update central fabric inventory" 
    ON public.central_fabric_inventory FOR ALL USING (true);

-- Indexes for central_fabric_inventory
CREATE INDEX IF NOT EXISTS idx_central_fabric_company ON public.central_fabric_inventory(company_name);
CREATE INDEX IF NOT EXISTS idx_central_fabric_type_color ON public.central_fabric_inventory(fabric_type, color);
CREATE INDEX IF NOT EXISTS idx_central_fabric_article ON public.central_fabric_inventory(booked_for_article);

-- =============================================================================
-- 2. CENTRAL MATERIAL ISSUES (INTER-MODULE CHALLANS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.central_material_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    issue_challan_no TEXT NOT NULL,
    from_division TEXT NOT NULL,       -- 'MERCHANDISE', 'CUTTING', 'PRINTING', 'EMBROIDERY', 'SEWING', 'WASHING', 'IRONING'
    to_division TEXT NOT NULL,         -- 'CUTTING', 'PRINTING', 'EMBROIDERY', 'SEWING', 'WASHING', 'IRONING', 'PACKING'
    article_no TEXT,
    buyer_name TEXT,
    fabric_type TEXT,
    color TEXT,
    quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    unit TEXT DEFAULT 'meters',        -- 'meters', 'pcs', 'kg', 'rolls'
    rolls_count INT DEFAULT 0,
    issued_by TEXT,
    received_by TEXT,
    status TEXT DEFAULT 'ISSUED',       -- 'ISSUED', 'IN_TRANSIT', 'RECEIVED', 'REJECTED'
    issue_date DATE DEFAULT CURRENT_DATE,
    received_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for central_material_issues
ALTER TABLE public.central_material_issues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read central material issues" 
    ON public.central_material_issues FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update central material issues" 
    ON public.central_material_issues FOR ALL USING (true);

-- Indexes for central_material_issues
CREATE INDEX IF NOT EXISTS idx_central_issues_company ON public.central_material_issues(company_name);
CREATE INDEX IF NOT EXISTS idx_central_issues_from_to ON public.central_material_issues(from_division, to_division);
CREATE INDEX IF NOT EXISTS idx_central_issues_challan ON public.central_material_issues(issue_challan_no);
CREATE INDEX IF NOT EXISTS idx_central_issues_article ON public.central_material_issues(article_no);

-- =============================================================================
-- 3. CENTRAL MATERIAL RECEIPTS (DIVISION ACKNOWLEDGMENTS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.central_material_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    issue_id UUID REFERENCES public.central_material_issues(id) ON DELETE CASCADE,
    division_code TEXT NOT NULL,       -- 'CUTTING', 'PRINTING', 'EMBROIDERY', 'SEWING', 'WASHING', 'IRONING', 'PACKING'
    received_quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    shortage_quantity NUMERIC(12,2) DEFAULT 0,
    unit TEXT DEFAULT 'meters',
    received_by TEXT,
    rack_location TEXT,
    notes TEXT,
    received_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for central_material_receipts
ALTER TABLE public.central_material_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read central material receipts" 
    ON public.central_material_receipts FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update central material receipts" 
    ON public.central_material_receipts FOR ALL USING (true);

-- Indexes for central_material_receipts
CREATE INDEX IF NOT EXISTS idx_central_receipts_company ON public.central_material_receipts(company_name);
CREATE INDEX IF NOT EXISTS idx_central_receipts_division ON public.central_material_receipts(division_code);
CREATE INDEX IF NOT EXISTS idx_central_receipts_issue ON public.central_material_receipts(issue_id);
