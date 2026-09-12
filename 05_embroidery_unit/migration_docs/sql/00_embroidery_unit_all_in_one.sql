-- ==============================================================================
-- 00_embroidery_unit_all_in_one.sql
-- Division 05: Multi-Head Embroidery Floor (Zigza MES Garment Platform)
-- Complete Monolithic Migration: Tables, Indexes, Triggers, Views, RLS & Production Seed Data
-- Operating Order: 05 of 11
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: public.embroidery_designs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.embroidery_designs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    design_code VARCHAR(50) NOT NULL UNIQUE,
    design_name VARCHAR(100) NOT NULL,
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    dst_file_url TEXT NOT NULL,
    total_stitches INTEGER NOT NULL CHECK (total_stitches > 0),
    color_change_count INTEGER NOT NULL DEFAULT 1,
    width_mm NUMERIC(6,2) NOT NULL,
    height_mm NUMERIC(6,2) NOT NULL,
    rate_per_thousand_stitches NUMERIC(6,2) DEFAULT 2.80,
    backing_type VARCHAR(40) DEFAULT 'TEARAWAY',
    needle_type VARCHAR(40) DEFAULT 'DBxK5_SES_75_11',
    thread_brand VARCHAR(40) DEFAULT 'Madeira',
    status VARCHAR(30) DEFAULT 'APPROVED',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embroidery_designs_order ON public.embroidery_designs(order_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_designs_code ON public.embroidery_designs(design_code);
CREATE INDEX IF NOT EXISTS idx_embroidery_designs_status ON public.embroidery_designs(status);

-- ------------------------------------------------------------------------------
-- 2. Table: public.embroidery_machines
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.embroidery_machines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    machine_code VARCHAR(30) NOT NULL UNIQUE,
    brand VARCHAR(50) NOT NULL,
    head_count INTEGER NOT NULL CHECK (head_count IN (6, 12, 15, 18, 20, 24)),
    max_rpm INTEGER NOT NULL DEFAULT 1000,
    operational_rpm INTEGER NOT NULL DEFAULT 850,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embroidery_machines_code ON public.embroidery_machines(machine_code);
CREATE INDEX IF NOT EXISTS idx_embroidery_machines_active ON public.embroidery_machines(is_active);

-- ------------------------------------------------------------------------------
-- 3. Table: public.embroidery_production_runs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.embroidery_production_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_number VARCHAR(32) NOT NULL UNIQUE,
    machine_id UUID NOT NULL REFERENCES public.embroidery_machines(id) ON DELETE RESTRICT,
    design_id UUID NOT NULL REFERENCES public.embroidery_designs(id) ON DELETE RESTRICT,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    operator_name VARCHAR(100) NOT NULL,
    shift VARCHAR(10) NOT NULL DEFAULT 'DAY',
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
    status VARCHAR(30) DEFAULT 'COMPLETED',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embroidery_runs_machine ON public.embroidery_production_runs(machine_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_design ON public.embroidery_production_runs(design_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_bundle ON public.embroidery_production_runs(bundle_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_status ON public.embroidery_production_runs(status);
CREATE INDEX IF NOT EXISTS idx_embroidery_runs_created ON public.embroidery_production_runs(created_at DESC);

-- ------------------------------------------------------------------------------
-- 4. Table: public.embroidery_qc_audits
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.embroidery_qc_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_code VARCHAR(32) NOT NULL UNIQUE,
    run_id UUID REFERENCES public.embroidery_production_runs(id) ON DELETE SET NULL,
    head_number INTEGER NOT NULL CHECK (head_number BETWEEN 1 AND 24),
    defect_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'MINOR',
    action_taken VARCHAR(100) DEFAULT 'TENSION_DISC_ADJUSTED',
    auditor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    auditor_name VARCHAR(100) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embroidery_qc_run ON public.embroidery_qc_audits(run_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_qc_head ON public.embroidery_qc_audits(head_number);
CREATE INDEX IF NOT EXISTS idx_embroidery_qc_defect ON public.embroidery_qc_audits(defect_type);

-- ------------------------------------------------------------------------------
-- 5. Table: public.embroidery_thread_inventory
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.embroidery_thread_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cone_code VARCHAR(32) NOT NULL UNIQUE,
    brand VARCHAR(40) NOT NULL DEFAULT 'Madeira',
    shade_number VARCHAR(30) NOT NULL,
    pantone_match VARCHAR(50) NOT NULL,
    thread_type VARCHAR(40) NOT NULL DEFAULT 'Polyester 40wt',
    initial_weight_grams NUMERIC(6,2) NOT NULL DEFAULT 1000.0,
    current_weight_grams NUMERIC(6,2) NOT NULL DEFAULT 850.0,
    cones_in_stock INTEGER NOT NULL DEFAULT 12,
    storage_bin VARCHAR(40) DEFAULT 'Rack E-01 / Bin 04',
    status VARCHAR(20) DEFAULT 'IN_STOCK',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embroidery_thread_brand ON public.embroidery_thread_inventory(brand);
CREATE INDEX IF NOT EXISTS idx_embroidery_thread_shade ON public.embroidery_thread_inventory(shade_number);
CREATE INDEX IF NOT EXISTS idx_embroidery_thread_status ON public.embroidery_thread_inventory(status);

-- ------------------------------------------------------------------------------
-- 6. Functions, Triggers & Analytical View
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_sync_embroidery_run_stitches()
RETURNS TRIGGER AS $$
DECLARE
    v_unit_stitches INTEGER;
    v_head_count INTEGER;
BEGIN
    IF NEW.total_stitches_run IS NULL OR NEW.total_stitches_run = 0 THEN
        SELECT total_stitches INTO v_unit_stitches 
        FROM public.embroidery_designs 
        WHERE id = NEW.design_id;

        SELECT head_count INTO v_head_count 
        FROM public.embroidery_machines 
        WHERE id = NEW.machine_id;

        NEW.total_stitches_run := COALESCE(NEW.run_cycles, 1) * COALESCE(v_unit_stitches, 15000) * COALESCE(v_head_count, 20);
    END IF;

    IF NEW.total_stitches_run > 0 THEN
        IF ((NEW.thread_breaks_count * 100000.0) / NEW.total_stitches_run) > 3.0 THEN
            IF NEW.status = 'RUNNING' THEN
                NEW.status := 'THREAD_ALARM';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_embroidery_run_stitches ON public.embroidery_production_runs;
CREATE TRIGGER trg_sync_embroidery_run_stitches
BEFORE INSERT OR UPDATE ON public.embroidery_production_runs
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_embroidery_run_stitches();

CREATE OR REPLACE FUNCTION public.fn_sync_embroidery_bundle_custody()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'COMPLETED' THEN
        UPDATE public.cutting_bundles
        SET 
            current_division = '06_SEWING',
            status = 'COMPLETED',
            updated_at = NOW()
        WHERE id = NEW.bundle_id;
    ELSE
        UPDATE public.cutting_bundles
        SET 
            current_division = '05_EMBROIDERY',
            status = 'IN_TRANSIT',
            updated_at = NOW()
        WHERE id = NEW.bundle_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_embroidery_bundle_custody ON public.embroidery_production_runs;
CREATE TRIGGER trg_sync_embroidery_bundle_custody
AFTER INSERT OR UPDATE ON public.embroidery_production_runs
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_embroidery_bundle_custody();

CREATE OR REPLACE VIEW public.view_embroidery_floor_kpis AS
SELECT
    COUNT(DISTINCT m.id) AS total_machines,
    COUNT(DISTINCT CASE WHEN m.is_active = TRUE THEN m.id END) AS active_machines,
    COALESCE(SUM(CASE WHEN m.is_active = TRUE THEN m.head_count ELSE 0 END), 0) AS total_operational_heads,
    COUNT(DISTINCT r.id) AS total_production_runs,
    COUNT(DISTINCT CASE WHEN r.status IN ('RUNNING', 'QUEUED') THEN r.id END) AS active_runs,
    COALESCE(SUM(r.total_panels_completed), 0) AS total_panels_completed,
    COALESCE(SUM(r.total_stitches_run), 0) AS total_stitches_completed,
    COALESCE(SUM(r.thread_breaks_count), 0) AS total_thread_breaks,
    ROUND(
        CASE 
            WHEN SUM(r.total_stitches_run) > 0 
            THEN ((SUM(r.thread_breaks_count)::NUMERIC * 100000.0) / SUM(r.total_stitches_run)::NUMERIC)
            ELSE 0.00 
        END, 2
    ) AS avg_thread_breakage_index,
    COUNT(DISTINCT d.id) AS registered_designs_count,
    COUNT(DISTINCT CASE WHEN d.status = 'APPROVED' THEN d.id END) AS approved_designs_count
FROM public.embroidery_machines m
FULL OUTER JOIN public.embroidery_production_runs r ON TRUE
FULL OUTER JOIN public.embroidery_designs d ON TRUE;

-- ------------------------------------------------------------------------------
-- 7. Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.embroidery_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_production_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_qc_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_thread_inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_embroidery_designs_select ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_select ON public.embroidery_designs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_embroidery_designs_insert ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_insert ON public.embroidery_designs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_embroidery_designs_update ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_update ON public.embroidery_designs FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_machines_select ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_select ON public.embroidery_machines FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_embroidery_machines_insert ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_insert ON public.embroidery_machines FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_embroidery_machines_update ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_update ON public.embroidery_machines FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_runs_select ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_select ON public.embroidery_production_runs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_embroidery_runs_insert ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_insert ON public.embroidery_production_runs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_embroidery_runs_update ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_update ON public.embroidery_production_runs FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_qc_select ON public.embroidery_qc_audits;
CREATE POLICY p_embroidery_qc_select ON public.embroidery_qc_audits FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_embroidery_qc_insert ON public.embroidery_qc_audits;
CREATE POLICY p_embroidery_qc_insert ON public.embroidery_qc_audits FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_embroidery_thread_select ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_select ON public.embroidery_thread_inventory FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_embroidery_thread_insert ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_insert ON public.embroidery_thread_inventory FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_embroidery_thread_update ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_update ON public.embroidery_thread_inventory FOR UPDATE TO authenticated USING (true);

-- ------------------------------------------------------------------------------
-- 8. Factory Production Seed Data
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    v_order_id UUID;
    v_admin_id UUID;
    v_bundle_id UUID;
    v_tajima_id UUID;
    v_barudan_id UUID;
    v_swf_id UUID;
    v_design_id UUID;
    v_run_id UUID;
BEGIN
    SELECT id INTO v_order_id FROM public.merchandising_orders WHERE order_number = 'PO-ZIG-8901' LIMIT 1;
    SELECT id INTO v_admin_id FROM public.profiles WHERE role = 'ADMIN' LIMIT 1;
    SELECT id INTO v_bundle_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-XS-001' LIMIT 1;

    INSERT INTO public.embroidery_machines (
        machine_code, brand, head_count, max_rpm, operational_rpm, is_active, notes
    ) VALUES 
        ('TAJIMA-20-HEAD-01', 'TAJIMA', 20, 1000, 850, TRUE, 'High-speed computerized 20-head frame for front chest logos.'),
        ('BARUDAN-15-HEAD-02', 'BARUDAN', 15, 1000, 850, TRUE, '15-head frame calibrated for heavy 380 GSM fleece appliques.'),
        ('SWF-12-HEAD-03', 'SWF', 12, 950, 800, TRUE, '12-head multi-head frame for sleeve badges & specialty puff.')
    ON CONFLICT (machine_code) DO UPDATE 
    SET is_active = EXCLUDED.is_active;

    SELECT id INTO v_tajima_id FROM public.embroidery_machines WHERE machine_code = 'TAJIMA-20-HEAD-01' LIMIT 1;
    SELECT id INTO v_barudan_id FROM public.embroidery_machines WHERE machine_code = 'BARUDAN-15-HEAD-02' LIMIT 1;
    SELECT id INTO v_swf_id FROM public.embroidery_machines WHERE machine_code = 'SWF-12-HEAD-03' LIMIT 1;

    INSERT INTO public.embroidery_thread_inventory (
        cone_code, brand, shade_number, pantone_match, thread_type, initial_weight_grams, current_weight_grams, cones_in_stock, storage_bin, status
    ) VALUES 
        ('THD-MAD-1142', 'Madeira', '1142', 'Pantone 19-4052 TCX (Classic Navy)', 'Polyester 40wt', 1000.0, 850.0, 12, 'Rack E-01 / Bin 04', 'IN_STOCK'),
        ('THD-MAD-1001', 'Madeira', '1001', 'Pantone 11-0601 TCX (Optical White)', 'Polyester 40wt', 1000.0, 920.0, 15, 'Rack E-01 / Bin 05', 'IN_STOCK'),
        ('THD-MAD-1224', 'Madeira', '1224', 'Pantone 14-0848 TCX (Mimosa Gold)', 'Polyester 40wt', 1000.0, 740.0, 8, 'Rack E-02 / Bin 01', 'IN_STOCK')
    ON CONFLICT (cone_code) DO NOTHING;

    IF v_order_id IS NOT NULL THEN
        INSERT INTO public.embroidery_designs (
            design_code,
            design_name,
            order_id,
            dst_file_url,
            total_stitches,
            color_change_count,
            width_mm,
            height_mm,
            rate_per_thousand_stitches,
            backing_type,
            needle_type,
            thread_brand,
            status,
            notes
        ) VALUES (
            'DST-OLLY-HD8821-CHEST',
            'OLLYPOP Bear Crest 3D Puff & Satin',
            v_order_id,
            'https://assets.zigzames.internal/emb/olly_hd8821_chest_v2.dst',
            22400,
            4,
            85.0,
            90.0,
            2.80,
            'TEARAWAY',
            'DBxK5_SES_75_11',
            'Madeira',
            'APPROVED',
            'Approved buyer punch for bulk production on 380 GSM French Terry.'
        )
        ON CONFLICT (design_code) DO UPDATE 
        SET status = 'APPROVED'
        RETURNING id INTO v_design_id;

        IF v_tajima_id IS NOT NULL AND v_design_id IS NOT NULL AND v_bundle_id IS NOT NULL THEN
            INSERT INTO public.embroidery_production_runs (
                run_number,
                machine_id,
                design_id,
                bundle_id,
                operator_id,
                operator_name,
                shift,
                run_cycles,
                panels_loaded,
                total_panels_completed,
                total_stitches_run,
                thread_breaks_count,
                needle_breakages,
                status,
                started_at,
                completed_at,
                notes
            ) VALUES (
                'EMB-RUN-2026-0842',
                v_tajima_id,
                v_design_id,
                v_bundle_id,
                v_admin_id,
                'P. Murugesan (Senior Embroidery Master)',
                'DAY',
                1,
                25,
                25,
                448000,
                1,
                0,
                'COMPLETED',
                NOW() - INTERVAL '4 hours',
                NOW() - INTERVAL '1 hour',
                'Batch 01 completed with clean jump trims and zero puckering.'
            )
            ON CONFLICT (run_number) DO UPDATE
            SET status = 'COMPLETED'
            RETURNING id INTO v_run_id;

            IF v_run_id IS NOT NULL THEN
                INSERT INTO public.embroidery_qc_audits (
                    audit_code,
                    run_id,
                    head_number,
                    defect_type,
                    severity,
                    action_taken,
                    auditor_id,
                    auditor_name,
                    notes
                ) VALUES (
                    'EMB-QC-2026-001',
                    v_run_id,
                    4,
                    'JUMP_TRIM_STRAY',
                    'MINOR',
                    'TENSION_DISC_ADJUSTED',
                    v_admin_id,
                    'K. Balaji (QA Inspector)',
                    'Automatic movable trimmer knife cleaned; zero defects observed on subsequent cycle.'
                )
                ON CONFLICT (audit_code) DO NOTHING;
            END IF;
        END IF;
    END IF;
END $$;
