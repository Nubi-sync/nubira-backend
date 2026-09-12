-- ==============================================================================
-- 01_cutting_lay_sheets.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_lay_sheets
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_lay_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'LAY-2026-0842'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    cutting_table_id VARCHAR(20) NOT NULL, -- 'TABLE_01', 'TABLE_02', 'TABLE_03'
    marker_length_m NUMERIC(6,2) NOT NULL CHECK (marker_length_m > 0),
    total_plies INTEGER NOT NULL CHECK (total_plies BETWEEN 1 AND 250),
    size_ratio_text VARCHAR(100) NOT NULL, -- e.g. 'XS:1, S:2, M:4, L:2, XL:1'
    ratio_total INTEGER NOT NULL CHECK (ratio_total > 0),
    expected_pieces INTEGER NOT NULL CHECK (expected_pieces > 0),
    actual_cut_pieces INTEGER,
    spreading_operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    cutting_master_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'SPREADING', -- 'SPREADING', 'READY_FOR_CUT', 'CUTTING', 'COMPLETED', 'AUDIT_FAILED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_order ON public.cutting_lay_sheets(order_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_status ON public.cutting_lay_sheets(status);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_table ON public.cutting_lay_sheets(cutting_table_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_created ON public.cutting_lay_sheets(created_at DESC);

COMMENT ON TABLE public.cutting_lay_sheets IS 'Master lay sheet spreading and cutting orders converted from Merchandising Buyer POs.';
COMMENT ON COLUMN public.cutting_lay_sheets.order_id IS 'Foreign Key to public.merchandising_orders (Division 02 commercial order handshake).';
COMMENT ON COLUMN public.cutting_lay_sheets.expected_pieces IS 'Mathematically guaranteed: total_plies * ratio_total.';
