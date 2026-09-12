-- ==============================================================================
-- 01_printing_strike_offs.sql
-- Division 04: Screen & Digital Printing Unit
-- Table: public.printing_strike_offs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.printing_strike_offs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    strike_off_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'SO-2026-0842'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    print_design_name VARCHAR(100) NOT NULL,
    print_technique VARCHAR(32) NOT NULL, -- 'PLASTISOL', 'WATER_BASED', 'DISCHARGE', 'PUFF', 'DTF', 'SUBLIMATION'
    pantone_codes TEXT[] NOT NULL, -- e.g. ARRAY['19-4052 TCX', '11-0601 TCX']
    mesh_count INTEGER NOT NULL DEFAULT 120, -- Mesh per inch: 80, 110, 120, 160, 230, 305
    squeegee_durometer INTEGER DEFAULT 75, -- 65, 70, 75, 80 Shore A
    spectro_delta_e NUMERIC(4,2) DEFAULT 0.38,
    wash_fastness_rating NUMERIC(3,1) DEFAULT 4.5, -- 1 to 5 scale
    strike_off_swatch_url TEXT,
    buyer_approved BOOLEAN DEFAULT FALSE,
    approval_status VARCHAR(30) DEFAULT 'APPROVED', -- 'APPROVED', 'REVISE_RECIPE', 'REJECTED', 'PENDING_LAB'
    approved_by VARCHAR(100),
    approved_at TIMESTAMPTZ,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_order ON public.printing_strike_offs(order_id);
CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_status ON public.printing_strike_offs(approval_status);
CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_code ON public.printing_strike_offs(strike_off_code);

COMMENT ON TABLE public.printing_strike_offs IS 'Buyer strike-off golden swatches and Pantone color approvals for Division 04 printing.';
COMMENT ON COLUMN public.printing_strike_offs.order_id IS 'Foreign Key to public.merchandising_orders (Division 02).';
COMMENT ON COLUMN public.printing_strike_offs.spectro_delta_e IS 'Spectrophotometer color difference tolerance (acceptable delta <= 0.8).';
