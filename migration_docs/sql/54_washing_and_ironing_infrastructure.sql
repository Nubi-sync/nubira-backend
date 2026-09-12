-- ============================================================================
-- 54_washing_and_ironing_infrastructure.sql
-- Zigza MES: Division 07 (Industrial Washing) & Division 08 (Steam Ironing)
-- PostgreSQL Infrastructure Migration
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DIVISION 07: INDUSTRIAL WASHING TABLES
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.washing_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_code VARCHAR(32) NOT NULL UNIQUE,
    wash_type VARCHAR(50) NOT NULL,
    liquor_ratio VARCHAR(10) DEFAULT '1:10',
    wash_temperature_c INTEGER NOT NULL CHECK (wash_temperature_c BETWEEN 20 AND 100),
    cycle_time_minutes INTEGER NOT NULL CHECK (cycle_time_minutes BETWEEN 5 AND 240),
    chemical_recipe_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    ph_target NUMERIC(3,1) NOT NULL DEFAULT 6.5,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.washing_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(32) NOT NULL UNIQUE,
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE SET NULL,
    recipe_id UUID REFERENCES public.washing_recipes(id) ON DELETE SET NULL,
    machine_id VARCHAR(30) NOT NULL,
    operator_id UUID REFERENCES public.profiles(id),
    operator_name VARCHAR(100),
    total_garments INTEGER NOT NULL CHECK (total_garments > 0),
    dry_input_weight_kg NUMERIC(8,2) NOT NULL DEFAULT 45.0,
    hydro_extracted_weight_kg NUMERIC(8,2),
    tumbler_dry_weight_kg NUMERIC(8,2),
    residual_moisture_percent NUMERIC(4,2) DEFAULT 5.2,
    status VARCHAR(30) DEFAULT 'WASHING',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.washing_shrinkage_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES public.washing_batches(id) ON DELETE CASCADE,
    specimen_size VARCHAR(10) NOT NULL,
    pre_wash_length_cm NUMERIC(6,2) NOT NULL,
    post_wash_length_cm NUMERIC(6,2) NOT NULL,
    pre_wash_width_cm NUMERIC(6,2) NOT NULL,
    post_wash_width_cm NUMERIC(6,2) NOT NULL,
    is_within_spec BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_washing_batches_order ON public.washing_batches(order_id);
CREATE INDEX IF NOT EXISTS idx_washing_batches_status ON public.washing_batches(status);

-- ----------------------------------------------------------------------------
-- 2. DIVISION 08: STEAM IRONING TABLES
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.iron_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_code VARCHAR(30) NOT NULL UNIQUE,
    table_type VARCHAR(30) DEFAULT 'VACUUM_BLOW_TABLE',
    operating_steam_bar NUMERIC(3,1) NOT NULL DEFAULT 5.0,
    vacuum_motor_power_kw NUMERIC(3,1) DEFAULT 0.75,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.iron_production_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_number VARCHAR(32) NOT NULL UNIQUE,
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE SET NULL,
    table_id UUID REFERENCES public.iron_tables(id) ON DELETE SET NULL,
    operator_id UUID REFERENCES public.profiles(id),
    operator_name VARCHAR(100),
    shift VARCHAR(10) DEFAULT 'DAY',
    garments_pressed INTEGER NOT NULL CHECK (garments_pressed > 0),
    boiler_pressure_bar NUMERIC(3,1) NOT NULL DEFAULT 5.0,
    standard_sam_per_pc NUMERIC(4,2) DEFAULT 0.85,
    total_minutes_spent INTEGER NOT NULL DEFAULT 45,
    status VARCHAR(30) DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.iron_defect_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iron_log_id UUID NOT NULL REFERENCES public.iron_production_logs(id) ON DELETE CASCADE,
    defect_type VARCHAR(50) NOT NULL,
    defect_count INTEGER NOT NULL CHECK (defect_count > 0),
    disposition VARCHAR(30) DEFAULT 'STEAM_RE_WORK',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iron_logs_order ON public.iron_production_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_iron_logs_status ON public.iron_production_logs(status);

-- Enable RLS
ALTER TABLE public.washing_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_shrinkage_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_production_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_defect_audits ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Allow all access to authenticated users" ON public.washing_recipes FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.washing_batches FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.washing_shrinkage_alerts FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.iron_tables FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.iron_production_logs FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.iron_defect_audits FOR ALL TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
