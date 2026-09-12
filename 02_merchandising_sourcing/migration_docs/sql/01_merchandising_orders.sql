-- ==============================================================================
-- 01_merchandising_orders.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Master Buyer Purchase Orders & Size/Color Breakdown Matrix
-- ==============================================================================

-- 1. Buyer Purchase Orders (Master Commercial Contract)
CREATE TABLE IF NOT EXISTS public.merchandising_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'PO-ZIG-8901'
    buyer_id UUID NOT NULL REFERENCES public.brands(id) ON DELETE RESTRICT,
    tech_pack_id UUID NOT NULL REFERENCES public.design_tech_packs(id) ON DELETE RESTRICT,
    season VARCHAR(32) NOT NULL, -- e.g. 'SS27', 'AW27'
    total_quantity INTEGER NOT NULL CHECK (total_quantity > 0),
    fob_price_per_piece NUMERIC(10,2) NOT NULL CHECK (fob_price_per_piece >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    order_date DATE DEFAULT CURRENT_DATE,
    ex_factory_date DATE NOT NULL,
    incoterm VARCHAR(10) DEFAULT 'FOB', -- 'FOB', 'CIF', 'EXW', 'DDP'
    status VARCHAR(32) DEFAULT 'CONFIRMED', -- 'PENDING_COSTING', 'CONFIRMED', 'IN_PRODUCTION', 'SHIPPED', 'CANCELLED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_merch_orders_buyer ON public.merchandising_orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_merch_orders_tech_pack ON public.merchandising_orders(tech_pack_id);
CREATE INDEX IF NOT EXISTS idx_merch_orders_status ON public.merchandising_orders(status);
CREATE INDEX IF NOT EXISTS idx_merch_orders_ex_factory ON public.merchandising_orders(ex_factory_date);

-- 2. Size & Color Breakdown Ratio
CREATE TABLE IF NOT EXISTS public.merchandising_order_ratios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    color_name VARCHAR(50) NOT NULL,
    color_code VARCHAR(30), -- Pantone / Hex
    size_label VARCHAR(20) NOT NULL, -- 'XS', 'S', 'M', 'L', 'XL', '2XL'
    ratio_units INTEGER NOT NULL DEFAULT 1 CHECK (ratio_units >= 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, color_name, size_label)
);

CREATE INDEX IF NOT EXISTS idx_order_ratios_order ON public.merchandising_order_ratios(order_id);
