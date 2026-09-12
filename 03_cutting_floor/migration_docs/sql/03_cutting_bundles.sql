-- ==============================================================================
-- 03_cutting_bundles.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_bundles (The Zero Ghost Piece Root Seed Table)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_barcode VARCHAR(64) NOT NULL UNIQUE, -- e.g. 'BND-LAY0842-SZ-M-001'
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE RESTRICT,
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    size_label VARCHAR(20) NOT NULL,
    color_name VARCHAR(50) NOT NULL,
    bundle_sequence INTEGER NOT NULL, -- Bundle 1 of N for this size
    piece_count INTEGER NOT NULL CHECK (piece_count > 0),
    start_ply_num INTEGER NOT NULL,
    end_ply_num INTEGER NOT NULL,
    current_division VARCHAR(30) DEFAULT 'CUTTING', -- 'CUTTING', 'PRINTING', 'EMBROIDERY', 'STITCHING', 'PACKING'
    status VARCHAR(30) DEFAULT 'CUT_COMPLETED', -- 'CUT_COMPLETED', 'DISPATCHED', 'IN_PROCESS', 'SEWN', 'PACKED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes for Real-Time Floor Scanning
CREATE INDEX IF NOT EXISTS idx_cutting_bundles_barcode ON public.cutting_bundles(bundle_barcode);
CREATE INDEX IF NOT EXISTS idx_cutting_bundles_lay ON public.cutting_bundles(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_cutting_bundles_order ON public.cutting_bundles(order_id);
CREATE INDEX IF NOT EXISTS idx_cutting_bundles_division ON public.cutting_bundles(current_division);
CREATE INDEX IF NOT EXISTS idx_cutting_bundles_status ON public.cutting_bundles(status);

COMMENT ON TABLE public.cutting_bundles IS 'The Root Seed Table of Zigza MES. Every piece sewn, washed, ironed, or packed in the factory is deterministically traceable to a row in this table.';
COMMENT ON COLUMN public.cutting_bundles.bundle_barcode IS 'Unique serialized barcode ticket (BND-{lay_sheet}-{size}-{seq}). Scanned at each production station.';
COMMENT ON COLUMN public.cutting_bundles.current_division IS 'Current operational location of the physical bundle across the 11 factory divisions.';
