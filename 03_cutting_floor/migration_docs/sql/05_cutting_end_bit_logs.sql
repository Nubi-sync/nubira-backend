-- ==============================================================================
-- 05_cutting_end_bit_logs.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_end_bit_logs (Remnant End-Bit Conservation Ledger)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_end_bit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE RESTRICT,
    roll_id UUID NOT NULL REFERENCES public.store_fabric_rolls(id) ON DELETE RESTRICT,
    remnant_weight_kg NUMERIC(6,2) NOT NULL CHECK (remnant_weight_kg >= 0),
    remnant_length_m NUMERIC(6,2) NOT NULL CHECK (remnant_length_m >= 0),
    disposition VARCHAR(30) NOT NULL DEFAULT 'POCKETING_SALVAGE', -- 'RETURN_TO_STORE', 'POCKETING_SALVAGE', 'SCRAP'
    logged_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_end_bit_lay ON public.cutting_end_bit_logs(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_end_bit_roll ON public.cutting_end_bit_logs(roll_id);
CREATE INDEX IF NOT EXISTS idx_end_bit_disposition ON public.cutting_end_bit_logs(disposition);

COMMENT ON TABLE public.cutting_end_bit_logs IS 'Fabric conservation ledger tracking all remnant end-bits (<= 1.5m) to prevent material leakage and recover secondary utility (pocketing/piping).';
COMMENT ON COLUMN public.cutting_end_bit_logs.disposition IS 'Action taken for remnant: RETURN_TO_STORE, POCKETING_SALVAGE, or SCRAP.';
