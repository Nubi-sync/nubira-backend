-- ==============================================================================
-- 03_embroidery_production_runs.sql
-- Division 05: Multi-Head Embroidery Floor
-- Table: public.embroidery_production_runs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.embroidery_production_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'EMB-RUN-2026-0842'
    machine_id UUID NOT NULL REFERENCES public.embroidery_machines(id) ON DELETE RESTRICT,
    design_id UUID NOT NULL REFERENCES public.embroidery_designs(id) ON DELETE RESTRICT,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    operator_name VARCHAR(100) NOT NULL,
    shift VARCHAR(10) NOT NULL DEFAULT 'DAY', -- 'DAY', 'NIGHT'
    run_cycles INTEGER NOT NULL CHECK (run_cycles > 0),
    panels_loaded INTEGER NOT NULL CHECK (panels_loaded > 0),
    total_panels_completed INTEGER NOT NULL DEFAULT 0,
    total_stitches_run BIGINT NOT NULL DEFAULT 0,
    thread_breaks_count INTEGER DEFAULT 0,
    needle_breakages INTEGER DEFAULT 0,
    thread_breakage_index NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN total_stitches_run > 0 THEN ROUND(((thread_breaks_count * 100000.0) / total_stitches_run)::NUMERIC, 2) 
            ELSE 0 
        END
    ) STORED,
    status VARCHAR(30) DEFAULT 'COMPLETED', -- 'QUEUED', 'RUNNING', 'COMPLETED', 'PAUSED_NEEDLE_ERROR', 'THREAD_ALARM'
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_machine ON public.embroidery_production_runs(machine_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_design ON public.embroidery_production_runs(design_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_bundle ON public.embroidery_production_runs(bundle_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_status ON public.embroidery_production_runs(status);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_created ON public.embroidery_production_runs(created_at DESC);

COMMENT ON TABLE public.embroidery_production_runs IS 'Shift execution runs on multi-head embroidery machines bound to cut bundles.';
COMMENT ON COLUMN public.embroidery_production_runs.thread_breakage_index IS 'Generated column: Thread Breakage Index (TBI) = (Thread Breaks * 100,000) / Total Stitches.';
