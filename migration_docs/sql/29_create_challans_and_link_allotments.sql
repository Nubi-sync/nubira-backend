-- ==============================================================================
-- 29_create_challans_and_link_allotments.sql
-- Multi-Article Job Work Delivery Challan Management (Matching Industry Standards)
-- ==============================================================================

-- 1. Create challans table
CREATE TABLE IF NOT EXISTS public.challans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challan_no TEXT NOT NULL,
    challan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    brand TEXT NOT NULL DEFAULT 'OLLYPOP',
    delivery_date DATE,
    fabric_type TEXT,
    sample_given BOOLEAN DEFAULT false,
    notes TEXT,
    total_sets INTEGER DEFAULT 0,
    total_pcs INTEGER DEFAULT 0,
    status TEXT DEFAULT 'IN_PROGRESS',
    bom_details JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable Row Level Security (RLS) on challans
ALTER TABLE public.challans ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies for challans (Public/Authenticated read/write for factory ERP)
CREATE POLICY "Allow all authenticated users full access to challans"
ON public.challans
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow anon users full access to challans"
ON public.challans
FOR ALL
TO anon
USING (true)
WITH CHECK (true);

-- 4. Add challan_id to allotments table (Nullable to preserve backward compatibility with existing lots)
ALTER TABLE public.allotments 
ADD COLUMN IF NOT EXISTS challan_id UUID REFERENCES public.challans(id) ON DELETE SET NULL;

-- 5. Performance Index for fast filtering & grouping
CREATE INDEX IF NOT EXISTS idx_allotments_challan_id ON public.allotments(challan_id);
CREATE INDEX IF NOT EXISTS idx_challans_challan_no ON public.challans(challan_no);
CREATE INDEX IF NOT EXISTS idx_challans_brand ON public.challans(brand);
CREATE INDEX IF NOT EXISTS idx_challans_status ON public.challans(status);
