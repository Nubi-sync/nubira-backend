-- ==============================================================================
-- 05_printing_curing_oven_logs.sql
-- Division 04: Screen & Digital Printing Unit
-- Table: public.printing_curing_oven_logs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.printing_curing_oven_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'OVEN-2026-0842'
    oven_id VARCHAR(50) NOT NULL, -- e.g. 'Tunnel Dryer Conveyor 01'
    production_run_id UUID REFERENCES public.printing_production_runs(id) ON DELETE SET NULL,
    target_temp_c NUMERIC(5,2) NOT NULL DEFAULT 160.0,
    probe_temp_c NUMERIC(5,2) NOT NULL,
    dwell_time_seconds INTEGER NOT NULL DEFAULT 120,
    conveyor_speed_mpm NUMERIC(4,2) DEFAULT 2.4,
    wash_test_cycles INTEGER DEFAULT 5,
    fastness_rating NUMERIC(3,1) DEFAULT 4.5, -- 1 to 5 scale
    auditor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    auditor_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'OPTIMAL', -- 'OPTIMAL', 'TEMP_WARNING', 'CRITICAL'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_run ON public.printing_curing_oven_logs(production_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_status ON public.printing_curing_oven_logs(status);
CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_created ON public.printing_curing_oven_logs(created_at DESC);

COMMENT ON TABLE public.printing_curing_oven_logs IS 'Continuous thermal probe telemetry and wash fastness audits for textile curing tunnel dryers.';
