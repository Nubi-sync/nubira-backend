-- ==============================================================================
-- 02_iron_production_logs.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Table: public.iron_production_logs (Pressing Output & Piecework Wages)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.iron_production_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'IRN-2026-092'
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    table_id UUID REFERENCES public.iron_tables(id) ON DELETE RESTRICT,
    operator_id UUID REFERENCES public.employees(id),
    shift VARCHAR(10) DEFAULT 'DAY',
    garments_pressed INTEGER NOT NULL CHECK (garments_pressed > 0),
    boiler_pressure_bar NUMERIC(3,1) NOT NULL CHECK (boiler_pressure_bar BETWEEN 3.0 AND 8.0),
    standard_sam_per_pc NUMERIC(4,2) DEFAULT 0.85,
    total_minutes_spent INTEGER NOT NULL,
    status VARCHAR(30) DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_iron_logs_number ON public.iron_production_logs(log_number);
CREATE INDEX IF NOT EXISTS idx_iron_logs_order ON public.iron_production_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_iron_logs_table ON public.iron_production_logs(table_id);
CREATE INDEX IF NOT EXISTS idx_iron_logs_operator ON public.iron_production_logs(operator_id);

COMMENT ON TABLE public.iron_production_logs IS 'Daily finishing operator piece-count output, boiler telemetry pressure, and SAM rate ledger.';
