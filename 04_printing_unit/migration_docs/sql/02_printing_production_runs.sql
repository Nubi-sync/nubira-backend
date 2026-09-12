-- ==============================================================================
-- 02_printing_production_runs.sql
-- Division 04: Screen & Digital Printing Unit
-- Table: public.printing_production_runs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.printing_production_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'PRN-2026-0842'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    strike_off_id UUID NOT NULL REFERENCES public.printing_strike_offs(id) ON DELETE RESTRICT,
    printing_table_or_machine VARCHAR(60) NOT NULL, -- e.g. 'Octopus Carousel 01 (12 Color Auto)'
    operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    operator_name VARCHAR(100) NOT NULL,
    oven_temperature_c NUMERIC(5,2) NOT NULL CHECK (oven_temperature_c BETWEEN 120 AND 220),
    oven_dwell_seconds INTEGER NOT NULL CHECK (oven_dwell_seconds BETWEEN 30 AND 300),
    stroke_speed_cpm INTEGER DEFAULT 28,
    shift VARCHAR(10) NOT NULL DEFAULT 'DAY', -- 'DAY', 'NIGHT'
    total_panels_printed INTEGER NOT NULL DEFAULT 0,
    total_rejections INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PRINTING', -- 'QUEUED', 'PRINTING', 'CURING', 'COMPLETED', 'QUARANTINED', 'OVEN_ALARM_HOLD'
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_order ON public.printing_production_runs(order_id);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_strike_off ON public.printing_production_runs(strike_off_id);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_status ON public.printing_production_runs(status);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_created ON public.printing_production_runs(created_at DESC);

COMMENT ON TABLE public.printing_production_runs IS 'Bulk carousel & table print runs executing cut panel garment decoration.';
COMMENT ON COLUMN public.printing_production_runs.oven_temperature_c IS 'Mandatory cross-linking curing oven temperature (>= 160 C for Plastisol/Water-Based).';
