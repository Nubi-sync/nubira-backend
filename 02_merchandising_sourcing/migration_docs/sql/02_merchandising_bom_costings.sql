-- ==============================================================================
-- 02_merchandising_bom_costings.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Double-Entry Bill of Materials (BOM) Costing Ledger & Variance Engine
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_bom_costings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    item_category VARCHAR(32) NOT NULL, -- 'SHELL_FABRIC', 'RIB_KNIT', 'SEWING_THREAD', 'ZIPPER', 'BUTTONS', 'LABELS', 'PACKAGING', 'ACCESSORY'
    item_name VARCHAR(128) NOT NULL,
    supplier_vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    consumption_per_pc NUMERIC(8,4) NOT NULL CHECK (consumption_per_pc > 0), -- e.g. 1.3500 kg or 1.0000 pc
    unit_of_measure VARCHAR(20) NOT NULL, -- 'KG', 'METER', 'PIECE', 'CONE', 'GROSS', 'SET'
    planned_rate_per_unit NUMERIC(10,2) NOT NULL CHECK (planned_rate_per_unit >= 0),
    planned_cost_per_pc NUMERIC(10,2) NOT NULL CHECK (planned_cost_per_pc >= 0),
    actual_cost_per_pc NUMERIC(10,2) CHECK (actual_cost_per_pc >= 0),
    variance_amount NUMERIC(10,2) GENERATED ALWAYS AS (actual_cost_per_pc - planned_cost_per_pc) STORED,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_bom_costing_order ON public.merchandising_bom_costings(order_id);
CREATE INDEX IF NOT EXISTS idx_bom_costing_category ON public.merchandising_bom_costings(item_category);
CREATE INDEX IF NOT EXISTS idx_bom_costing_vendor ON public.merchandising_bom_costings(supplier_vendor_id);
