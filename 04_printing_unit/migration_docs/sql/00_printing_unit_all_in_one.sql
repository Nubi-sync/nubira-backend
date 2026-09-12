-- ==============================================================================
-- 00_printing_unit_all_in_one.sql
-- Division 04: Screen & Digital Printing Unit (Zigza MES Garment Platform)
-- Complete Monolithic Migration: Tables, Indexes, Triggers, Views, RLS & Production Seed Data
-- Operating Order: 04 of 11
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: public.printing_strike_offs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.printing_strike_offs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    strike_off_code VARCHAR(32) NOT NULL UNIQUE,
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    print_design_name VARCHAR(100) NOT NULL,
    print_technique VARCHAR(32) NOT NULL,
    pantone_codes TEXT[] NOT NULL,
    mesh_count INTEGER NOT NULL DEFAULT 120,
    squeegee_durometer INTEGER DEFAULT 75,
    spectro_delta_e NUMERIC(4,2) DEFAULT 0.38,
    wash_fastness_rating NUMERIC(3,1) DEFAULT 4.5,
    strike_off_swatch_url TEXT,
    buyer_approved BOOLEAN DEFAULT FALSE,
    approval_status VARCHAR(30) DEFAULT 'APPROVED',
    approved_by VARCHAR(100),
    approved_at TIMESTAMPTZ,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_order ON public.printing_strike_offs(order_id);
CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_status ON public.printing_strike_offs(approval_status);
CREATE INDEX IF NOT EXISTS idx_printing_strike_offs_code ON public.printing_strike_offs(strike_off_code);

-- ------------------------------------------------------------------------------
-- 2. Table: public.printing_production_runs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.printing_production_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_code VARCHAR(32) NOT NULL UNIQUE,
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    strike_off_id UUID NOT NULL REFERENCES public.printing_strike_offs(id) ON DELETE RESTRICT,
    printing_table_or_machine VARCHAR(60) NOT NULL,
    operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    operator_name VARCHAR(100) NOT NULL,
    oven_temperature_c NUMERIC(5,2) NOT NULL CHECK (oven_temperature_c BETWEEN 120 AND 220),
    oven_dwell_seconds INTEGER NOT NULL CHECK (oven_dwell_seconds BETWEEN 30 AND 300),
    stroke_speed_cpm INTEGER DEFAULT 28,
    shift VARCHAR(10) NOT NULL DEFAULT 'DAY',
    total_panels_printed INTEGER NOT NULL DEFAULT 0,
    total_rejections INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PRINTING',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_printing_production_runs_order ON public.printing_production_runs(order_id);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_strike_off ON public.printing_production_runs(strike_off_id);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_status ON public.printing_production_runs(status);
CREATE INDEX IF NOT EXISTS idx_printing_production_runs_created ON public.printing_production_runs(created_at DESC);

-- ------------------------------------------------------------------------------
-- 3. Table: public.printing_bundle_runs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.printing_bundle_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    production_run_id UUID NOT NULL REFERENCES public.printing_production_runs(id) ON DELETE CASCADE,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    received_pieces INTEGER NOT NULL CHECK (received_pieces > 0),
    passed_pieces INTEGER NOT NULL CHECK (passed_pieces >= 0),
    rejected_pieces INTEGER NOT NULL DEFAULT 0 CHECK (rejected_pieces >= 0),
    reconciliation_valid BOOLEAN GENERATED ALWAYS AS (received_pieces = passed_pieces + rejected_pieces) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_printing_bundle_runs_run ON public.printing_bundle_runs(production_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_bundle_runs_bundle ON public.printing_bundle_runs(bundle_id);

-- ------------------------------------------------------------------------------
-- 4. Table: public.printing_defect_logs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.printing_defect_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_run_id UUID NOT NULL REFERENCES public.printing_bundle_runs(id) ON DELETE CASCADE,
    defect_type VARCHAR(50) NOT NULL,
    defect_count INTEGER NOT NULL CHECK (defect_count > 0),
    action_taken VARCHAR(50) DEFAULT 'PANEL_RE_CUT_REQUESTED',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_printing_defect_logs_bundle_run ON public.printing_defect_logs(bundle_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_defect_logs_type ON public.printing_defect_logs(defect_type);

-- ------------------------------------------------------------------------------
-- 5. Table: public.printing_curing_oven_logs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.printing_curing_oven_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_code VARCHAR(32) NOT NULL UNIQUE,
    oven_id VARCHAR(50) NOT NULL,
    production_run_id UUID REFERENCES public.printing_production_runs(id) ON DELETE SET NULL,
    target_temp_c NUMERIC(5,2) NOT NULL DEFAULT 160.0,
    probe_temp_c NUMERIC(5,2) NOT NULL,
    dwell_time_seconds INTEGER NOT NULL DEFAULT 120,
    conveyor_speed_mpm NUMERIC(4,2) DEFAULT 2.4,
    wash_test_cycles INTEGER DEFAULT 5,
    fastness_rating NUMERIC(3,1) DEFAULT 4.5,
    auditor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    auditor_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'OPTIMAL',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_run ON public.printing_curing_oven_logs(production_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_status ON public.printing_curing_oven_logs(status);
CREATE INDEX IF NOT EXISTS idx_printing_curing_oven_created ON public.printing_curing_oven_logs(created_at DESC);

-- ------------------------------------------------------------------------------
-- 6. Functions, Triggers & Analytical View
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_sync_printing_run_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.printing_production_runs
    SET 
        total_panels_printed = COALESCE((
            SELECT SUM(passed_pieces)
            FROM public.printing_bundle_runs
            WHERE production_run_id = COALESCE(NEW.production_run_id, OLD.production_run_id)
        ), 0),
        total_rejections = COALESCE((
            SELECT SUM(rejected_pieces)
            FROM public.printing_bundle_runs
            WHERE production_run_id = COALESCE(NEW.production_run_id, OLD.production_run_id)
        ), 0),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.production_run_id, OLD.production_run_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_printing_run_totals ON public.printing_bundle_runs;
CREATE TRIGGER trg_sync_printing_run_totals
AFTER INSERT OR UPDATE OR DELETE ON public.printing_bundle_runs
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_printing_run_totals();

CREATE OR REPLACE FUNCTION public.fn_sync_printing_bundle_custody()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.cutting_bundles
    SET 
        current_division = '04_PRINTING',
        status = 'IN_TRANSIT',
        updated_at = NOW()
    WHERE id = NEW.bundle_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_printing_bundle_custody ON public.printing_bundle_runs;
CREATE TRIGGER trg_sync_printing_bundle_custody
AFTER INSERT ON public.printing_bundle_runs
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_printing_bundle_custody();

CREATE OR REPLACE FUNCTION public.fn_classify_curing_oven_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.probe_temp_c < 150.0 THEN
        NEW.status := 'CRITICAL';
    ELSIF NEW.probe_temp_c < 158.0 THEN
        NEW.status := 'TEMP_WARNING';
    ELSE
        NEW.status := 'OPTIMAL';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_classify_curing_oven_status ON public.printing_curing_oven_logs;
CREATE TRIGGER trg_classify_curing_oven_status
BEFORE INSERT OR UPDATE ON public.printing_curing_oven_logs
FOR EACH ROW
EXECUTE FUNCTION public.fn_classify_curing_oven_status();

CREATE OR REPLACE VIEW public.view_printing_floor_kpis AS
SELECT
    COUNT(DISTINCT so.id) AS total_strike_offs,
    COUNT(DISTINCT CASE WHEN so.approval_status = 'APPROVED' THEN so.id END) AS approved_strike_offs,
    ROUND(
        (COUNT(DISTINCT CASE WHEN so.approval_status = 'APPROVED' THEN so.id END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT so.id), 0)) * 100, 1
    ) AS strike_off_approval_rate_pct,
    COUNT(DISTINCT CASE WHEN pr.status IN ('PRINTING', 'RUNNING') THEN pr.id END) AS active_production_runs,
    COUNT(DISTINCT CASE WHEN pr.status = 'COMPLETED' THEN pr.id END) AS completed_production_runs,
    COALESCE(SUM(pr.total_panels_printed), 0) AS total_panels_printed,
    COALESCE(SUM(pr.total_rejections), 0) AS total_panels_rejected,
    ROUND(
        (COALESCE(SUM(pr.total_rejections), 0)::NUMERIC / 
        NULLIF(COALESCE(SUM(pr.total_panels_printed), 0) + COALESCE(SUM(pr.total_rejections), 0), 0)) * 100, 2
    ) AS printing_rejection_rate_pct,
    COUNT(DISTINCT CASE WHEN ol.status = 'OPTIMAL' THEN ol.id END) AS optimal_ovens_count,
    COUNT(DISTINCT CASE WHEN ol.status IN ('TEMP_WARNING', 'CRITICAL') THEN ol.id END) AS thermal_alarm_count
FROM public.printing_production_runs pr
FULL OUTER JOIN public.printing_strike_offs so ON TRUE
FULL OUTER JOIN public.printing_curing_oven_logs ol ON TRUE;

-- ------------------------------------------------------------------------------
-- 7. Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.printing_strike_offs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_production_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_bundle_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_defect_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_curing_oven_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_printing_strike_offs_select ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_select ON public.printing_strike_offs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_printing_strike_offs_insert ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_insert ON public.printing_strike_offs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_printing_strike_offs_update ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_update ON public.printing_strike_offs FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_production_runs_select ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_select ON public.printing_production_runs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_printing_production_runs_insert ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_insert ON public.printing_production_runs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_printing_production_runs_update ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_update ON public.printing_production_runs FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_bundle_runs_select ON public.printing_bundle_runs;
CREATE POLICY p_printing_bundle_runs_select ON public.printing_bundle_runs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_printing_bundle_runs_insert ON public.printing_bundle_runs;
CREATE POLICY p_printing_bundle_runs_insert ON public.printing_bundle_runs FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_printing_defect_logs_select ON public.printing_defect_logs;
CREATE POLICY p_printing_defect_logs_select ON public.printing_defect_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_printing_defect_logs_insert ON public.printing_defect_logs;
CREATE POLICY p_printing_defect_logs_insert ON public.printing_defect_logs FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_printing_curing_oven_logs_select ON public.printing_curing_oven_logs;
CREATE POLICY p_printing_curing_oven_logs_select ON public.printing_curing_oven_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_printing_curing_oven_logs_insert ON public.printing_curing_oven_logs;
CREATE POLICY p_printing_curing_oven_logs_insert ON public.printing_curing_oven_logs FOR INSERT TO authenticated WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 8. Factory Production Seed Data
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    v_order_id UUID;
    v_strike_off_id UUID;
    v_run_id UUID;
    v_bundle_1_id UUID;
    v_bundle_2_id UUID;
    v_bundle_3_id UUID;
    v_bundle_run_3_id UUID;
    v_admin_id UUID;
BEGIN
    SELECT id INTO v_order_id FROM public.merchandising_orders WHERE order_number = 'PO-ZIG-8901' LIMIT 1;
    SELECT id INTO v_admin_id FROM public.profiles WHERE role = 'ADMIN' LIMIT 1;

    IF v_order_id IS NOT NULL THEN
        INSERT INTO public.printing_strike_offs (
            strike_off_code,
            order_id,
            print_design_name,
            print_technique,
            pantone_codes,
            mesh_count,
            squeegee_durometer,
            spectro_delta_e,
            wash_fastness_rating,
            buyer_approved,
            approval_status,
            approved_by,
            approved_at,
            remarks
        ) VALUES (
            'SO-2026-0842',
            v_order_id,
            'OLLYPOP Core Chest Crest & Signature Sleeve Graphic',
            'PLASTISOL',
            ARRAY['19-4052 TCX', '11-0601 TCX'],
            160,
            75,
            0.38,
            4.5,
            TRUE,
            'APPROVED',
            'S. Mehra (Buyer Technical QA)',
            NOW() - INTERVAL '1 day',
            'Approved for bulk print. Excellent opacity and sharp edge resolution on 380 GSM French Terry.'
        )
        ON CONFLICT (strike_off_code) DO UPDATE 
        SET approval_status = 'APPROVED'
        RETURNING id INTO v_strike_off_id;

        INSERT INTO public.printing_production_runs (
            run_code,
            order_id,
            strike_off_id,
            printing_table_or_machine,
            operator_id,
            operator_name,
            oven_temperature_c,
            oven_dwell_seconds,
            stroke_speed_cpm,
            shift,
            status,
            started_at,
            notes
        ) VALUES (
            'PRN-2026-0842',
            v_order_id,
            v_strike_off_id,
            'Octopus Carousel 01 (12 Color Automatic)',
            v_admin_id,
            'R. Veeramani (Master Printer)',
            162.5,
            120,
            28,
            'DAY',
            'PRINTING',
            NOW() - INTERVAL '3 hours',
            'Production run executing high-density plastisol decoration on Jet Black hoodie panels.'
        )
        ON CONFLICT (run_code) DO UPDATE
        SET status = 'PRINTING'
        RETURNING id INTO v_run_id;

        SELECT id INTO v_bundle_1_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-XS-001' LIMIT 1;
        SELECT id INTO v_bundle_2_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-XS-002' LIMIT 1;
        SELECT id INTO v_bundle_3_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-S-001' LIMIT 1;

        IF v_bundle_1_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (production_run_id, bundle_id, received_pieces, passed_pieces, rejected_pieces)
            VALUES (v_run_id, v_bundle_1_id, 25, 25, 0)
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_bundle_2_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (production_run_id, bundle_id, received_pieces, passed_pieces, rejected_pieces)
            VALUES (v_run_id, v_bundle_2_id, 25, 25, 0)
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_bundle_3_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (production_run_id, bundle_id, received_pieces, passed_pieces, rejected_pieces)
            VALUES (v_run_id, v_bundle_3_id, 25, 24, 1)
            ON CONFLICT DO NOTHING
            RETURNING id INTO v_bundle_run_3_id;

            IF v_bundle_run_3_id IS NOT NULL THEN
                INSERT INTO public.printing_defect_logs (bundle_run_id, defect_type, defect_count, action_taken, notes)
                VALUES (v_bundle_run_3_id, 'PINHOLE', 1, 'PANEL_RE_CUT_REQUESTED', 'Micro pinhole ink bleed near pocket notch.');
            END IF;
        END IF;

        INSERT INTO public.printing_curing_oven_logs (
            log_code,
            oven_id,
            production_run_id,
            target_temp_c,
            probe_temp_c,
            dwell_time_seconds,
            conveyor_speed_mpm,
            wash_test_cycles,
            fastness_rating,
            auditor_id,
            auditor_name,
            status,
            notes
        ) VALUES (
            'OVEN-2026-0842',
            'Tunnel Dryer Conveyor 01',
            v_run_id,
            160.0,
            162.4,
            120,
            2.4,
            5,
            4.5,
            v_admin_id,
            'K. Balaji (QA Inspector)',
            'OPTIMAL',
            'Curing heat profile verified with optical pyrometer probe across 6 heating zones.'
        ) ON CONFLICT (log_code) DO NOTHING;

    END IF;
END $$;
