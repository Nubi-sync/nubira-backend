-- ==============================================================================
-- 00_ironing_unit_all_in_one.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Unified All-in-One Database Migration Script
-- ==============================================================================

-- 1. Vacuum Steam Tables Registry
CREATE TABLE IF NOT EXISTS public.iron_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_code VARCHAR(30) NOT NULL UNIQUE,
    table_type VARCHAR(30) DEFAULT 'VACUUM_BLOW_TABLE',
    operating_steam_bar NUMERIC(3,1) NOT NULL DEFAULT 5.0,
    vacuum_motor_power_kw NUMERIC(3,1) DEFAULT 0.75,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iron_tables_code ON public.iron_tables(table_code);
CREATE INDEX IF NOT EXISTS idx_iron_tables_active ON public.iron_tables(is_active);

-- 2. Steam Ironing Production Logs
CREATE TABLE IF NOT EXISTS public.iron_production_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_number VARCHAR(32) NOT NULL UNIQUE,
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

CREATE INDEX IF NOT EXISTS idx_iron_logs_number ON public.iron_production_logs(log_number);
CREATE INDEX IF NOT EXISTS idx_iron_logs_order ON public.iron_production_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_iron_logs_table ON public.iron_production_logs(table_id);

-- 3. Ironing Defect Audits
CREATE TABLE IF NOT EXISTS public.iron_defect_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iron_log_id UUID NOT NULL REFERENCES public.iron_production_logs(id) ON DELETE CASCADE,
    defect_type VARCHAR(50) NOT NULL,
    defect_count INTEGER NOT NULL CHECK (defect_count > 0),
    disposition VARCHAR(30) DEFAULT 'STEAM_RE_WORK',
    inspector_id UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iron_defects_log ON public.iron_defect_audits(iron_log_id);

-- 4. Triggers
CREATE OR REPLACE FUNCTION update_iron_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_iron_tables_updated_at ON public.iron_tables;
CREATE TRIGGER trg_iron_tables_updated_at
BEFORE UPDATE ON public.iron_tables
FOR EACH ROW EXECUTE FUNCTION update_iron_timestamp();

DROP TRIGGER IF EXISTS trg_iron_logs_updated_at ON public.iron_production_logs;
CREATE TRIGGER trg_iron_logs_updated_at
BEFORE UPDATE ON public.iron_production_logs
FOR EACH ROW EXECUTE FUNCTION update_iron_timestamp();

-- 5. Row Level Security
ALTER TABLE public.iron_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_production_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_defect_audits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_iron_tables_select ON public.iron_tables;
CREATE POLICY p_iron_tables_select ON public.iron_tables FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_tables_insert ON public.iron_tables;
CREATE POLICY p_iron_tables_insert ON public.iron_tables FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_iron_tables_update ON public.iron_tables;
CREATE POLICY p_iron_tables_update ON public.iron_tables FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_iron_logs_select ON public.iron_production_logs;
CREATE POLICY p_iron_logs_select ON public.iron_production_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_logs_insert ON public.iron_production_logs;
CREATE POLICY p_iron_logs_insert ON public.iron_production_logs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_iron_logs_update ON public.iron_production_logs;
CREATE POLICY p_iron_logs_update ON public.iron_production_logs FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_iron_defects_select ON public.iron_defect_audits;
CREATE POLICY p_iron_defects_select ON public.iron_defect_audits FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_defects_insert ON public.iron_defect_audits;
CREATE POLICY p_iron_defects_insert ON public.iron_defect_audits FOR INSERT TO authenticated WITH CHECK (true);

-- 6. Steam Ironing Pressers & Task Allocations Matrix
CREATE TABLE IF NOT EXISTS public.iron_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['FINISHING_PRESSER']::TEXT[],
    role TEXT DEFAULT 'FINISHING_PRESSER',
    assigned_table TEXT DEFAULT 'Steam Table 01 (Vacuum)',
    shift TEXT DEFAULT 'SHIFT_1',
    status TEXT DEFAULT 'ACTIVE',
    is_active BOOLEAN DEFAULT TRUE,
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iron_workers_company ON public.iron_workers(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_workers_phone ON public.iron_workers(phone_number);

ALTER TABLE public.iron_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron workers" ON public.iron_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron workers" ON public.iron_workers FOR ALL USING (true);

CREATE TABLE IF NOT EXISTS public.iron_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    cutting_allocation_id UUID,
    buyer_id UUID,
    buyer_name TEXT NOT NULL DEFAULT 'Direct Buyer',
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID REFERENCES public.iron_workers(id) ON DELETE SET NULL,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    machine_table TEXT DEFAULT 'Steam Table 01 (Vacuum)',
    table_number TEXT,
    pieces_to_press NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    shift TEXT DEFAULT 'SHIFT_1',
    iron_temp_c INTEGER DEFAULT 150,
    due_time TIMESTAMPTZ,
    notes TEXT,
    status TEXT DEFAULT 'PENDING',
    company_name TEXT,
    started_at TIMESTAMPTZ,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iron_allocations_company ON public.iron_task_allocations(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_task_ref ON public.iron_task_allocations(task_ref);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_worker ON public.iron_task_allocations(worker_id);

ALTER TABLE public.iron_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron tasks" ON public.iron_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron tasks" ON public.iron_task_allocations FOR ALL USING (true);

