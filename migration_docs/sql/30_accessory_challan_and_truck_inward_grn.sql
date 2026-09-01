-- =========================================================================
-- TRUCK RAW MATERIAL & ACCESSORY CHALLAN INWARD (GRN) TABLES
-- =========================================================================

-- 1. Create truck_inwards (Challan Master)
CREATE TABLE IF NOT EXISTS public.truck_inwards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grn_no TEXT NOT NULL,
    party_name TEXT NOT NULL,
    article_no TEXT,
    challan_no TEXT,
    inward_date DATE DEFAULT CURRENT_DATE,
    truck_no TEXT,
    challan_photo_url TEXT,
    received_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    receiver_name TEXT,
    status TEXT NOT NULL DEFAULT 'VERIFIED' CHECK (status IN ('VERIFIED', 'SHORTAGE', 'DUE_PENDING')),
    total_items INT DEFAULT 0,
    due_items_count INT DEFAULT 0,
    shortage_items_count INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create truck_inward_items (Line Items)
CREATE TABLE IF NOT EXISTS public.truck_inward_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_inward_id UUID REFERENCES public.truck_inwards(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    size_label TEXT,
    quantity NUMERIC NOT NULL DEFAULT 0,
    unit TEXT DEFAULT 'pcs',
    status TEXT NOT NULL DEFAULT 'RECEIVED' CHECK (status IN ('RECEIVED', 'SHORTAGE', 'DUE', 'DEFECTIVE')),
    shortage_qty NUMERIC DEFAULT 0,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Performance Indices
CREATE INDEX IF NOT EXISTS idx_truck_inwards_party_name ON public.truck_inwards(party_name);
CREATE INDEX IF NOT EXISTS idx_truck_inwards_inward_date ON public.truck_inwards(inward_date DESC);
CREATE INDEX IF NOT EXISTS idx_truck_inwards_status ON public.truck_inwards(status);
CREATE INDEX IF NOT EXISTS idx_truck_inward_items_inward_id ON public.truck_inward_items(truck_inward_id);

-- 4. Enable RLS
ALTER TABLE public.truck_inwards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.truck_inward_items ENABLE ROW LEVEL SECURITY;

-- 5. Safe Policies (Drop if exists then create)
DROP POLICY IF EXISTS "Allow all for truck_inwards" ON public.truck_inwards;
CREATE POLICY "Allow all for truck_inwards" ON public.truck_inwards
    FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for truck_inward_items" ON public.truck_inward_items;
CREATE POLICY "Allow all for truck_inward_items" ON public.truck_inward_items
    FOR ALL USING (true) WITH CHECK (true);
