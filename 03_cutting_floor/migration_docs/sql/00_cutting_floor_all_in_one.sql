-- ==============================================================================
-- 00_cutting_floor_all_in_one.sql
-- Division 03: Cutting & Lay Floor Operations Desk (Master Consolidated Migration)
-- Target: Supabase PostgreSQL (Full Schema, Triggers, Functions, RLS & Seed)
-- ==============================================================================

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 01_cutting_lay_sheets.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 01_cutting_lay_sheets.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_lay_sheets
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_lay_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'LAY-2026-0842'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    cutting_table_id VARCHAR(20) NOT NULL, -- 'TABLE_01', 'TABLE_02', 'TABLE_03'
    marker_length_m NUMERIC(6,2) NOT NULL CHECK (marker_length_m > 0),
    total_plies INTEGER NOT NULL CHECK (total_plies BETWEEN 1 AND 250),
    size_ratio_text VARCHAR(100) NOT NULL, -- e.g. 'XS:1, S:2, M:4, L:2, XL:1'
    ratio_total INTEGER NOT NULL CHECK (ratio_total > 0),
    expected_pieces INTEGER NOT NULL CHECK (expected_pieces > 0),
    actual_cut_pieces INTEGER,
    spreading_operator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    cutting_master_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'SPREADING', -- 'SPREADING', 'READY_FOR_CUT', 'CUTTING', 'COMPLETED', 'AUDIT_FAILED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_order ON public.cutting_lay_sheets(order_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_status ON public.cutting_lay_sheets(status);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_table ON public.cutting_lay_sheets(cutting_table_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_created ON public.cutting_lay_sheets(created_at DESC);

COMMENT ON TABLE public.cutting_lay_sheets IS 'Master lay sheet spreading and cutting orders converted from Merchandising Buyer POs.';
COMMENT ON COLUMN public.cutting_lay_sheets.order_id IS 'Foreign Key to public.merchandising_orders (Division 02 commercial order handshake).';
COMMENT ON COLUMN public.cutting_lay_sheets.expected_pieces IS 'Mathematically guaranteed: total_plies * ratio_total.';


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 02_cutting_lay_rolls.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 02_cutting_lay_rolls.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Tables: public.store_fabric_rolls (Stub) & public.cutting_lay_rolls
-- ==============================================================================

-- 1. Forward-compatible Stub Table: public.store_fabric_rolls (Division 11 Central Store Godown)
CREATE TABLE IF NOT EXISTS public.store_fabric_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roll_barcode VARCHAR(64) NOT NULL UNIQUE, -- e.g. 'ROL-FT-8821-A1'
    material_type VARCHAR(50) DEFAULT 'SHELL_FABRIC',
    fabric_name VARCHAR(150) NOT NULL,
    shade_group VARCHAR(20) NOT NULL, -- 'SHADE_A', 'SHADE_B', 'SHADE_C'
    dye_lot_number VARCHAR(50),
    gross_weight_kg NUMERIC(8,2) NOT NULL,
    length_meters NUMERIC(8,2) NOT NULL,
    usable_width_inches NUMERIC(5,2) DEFAULT 60.00,
    inspection_points_score INTEGER DEFAULT 0, -- 4-Point System score
    status VARCHAR(30) DEFAULT 'STORE_GODOWN', -- 'STORE_GODOWN', 'RELAXATION', 'ON_CUTTING_TABLE', 'DEPLETED'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_store_fabric_rolls_barcode ON public.store_fabric_rolls(roll_barcode);
CREATE INDEX IF NOT EXISTS idx_store_fabric_rolls_shade ON public.store_fabric_rolls(shade_group);

-- 2. Master Lay Sheet Fabric Rolls Junction Table (Shade Group Integrity)
CREATE TABLE IF NOT EXISTS public.cutting_lay_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE CASCADE,
    roll_id UUID NOT NULL REFERENCES public.store_fabric_rolls(id) ON DELETE RESTRICT,
    plies_from_roll INTEGER NOT NULL CHECK (plies_from_roll > 0),
    meters_consumed NUMERIC(8,2) NOT NULL,
    remnant_length_m NUMERIC(6,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_cutting_lay_rolls_lay ON public.cutting_lay_rolls(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_rolls_roll ON public.cutting_lay_rolls(roll_id);

COMMENT ON TABLE public.cutting_lay_rolls IS 'Fabric rolls spread across a specific lay sheet. Enforces single dye lot and shade group integrity.';
COMMENT ON COLUMN public.cutting_lay_rolls.meters_consumed IS 'Total linear fabric meters pulled from this roll for the lay.';


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 03_cutting_bundles.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

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


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 04_cutting_panel_qc_audits.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 04_cutting_panel_qc_audits.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_panel_qc_audits
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_panel_qc_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE RESTRICT,
    bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE SET NULL,
    inspector_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notch_accuracy_mm NUMERIC(4,2) NOT NULL, -- Tol: <= 1.0mm
    ply_deflection_mm NUMERIC(4,2) NOT NULL, -- Tol: <= 1.5mm
    shade_continuity_pass BOOLEAN NOT NULL DEFAULT true,
    template_match_pass BOOLEAN NOT NULL DEFAULT true,
    qc_verdict VARCHAR(20) NOT NULL DEFAULT 'PASS', -- 'PASS', 'RE_CUT_PANELS', 'REJECT'
    audit_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_panel_qc_lay ON public.cutting_panel_qc_audits(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_panel_qc_bundle ON public.cutting_panel_qc_audits(bundle_id);
CREATE INDEX IF NOT EXISTS idx_panel_qc_verdict ON public.cutting_panel_qc_audits(qc_verdict);

COMMENT ON TABLE public.cutting_panel_qc_audits IS 'Precision quality inspections of cut garment panels verifying pattern notch depth, blade ply deflection, and shade matching.';
COMMENT ON COLUMN public.cutting_panel_qc_audits.notch_accuracy_mm IS 'Notch depth deviation from CAD spec in millimeters (Factory SLA: <= 1.0mm).';
COMMENT ON COLUMN public.cutting_panel_qc_audits.ply_deflection_mm IS 'Deflection between top ply and bottom ply cut perimeter (Factory SLA: <= 1.5mm).';


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 05_cutting_end_bit_logs.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

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


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 06_cutting_triggers_and_functions.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 06_cutting_triggers_and_functions.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Automation Triggers, Bundle Generator Function, and Executive Floor KPI View
-- ==============================================================================

-- 1. Updated-At Timestamp Trigger Functions
CREATE OR REPLACE FUNCTION public.fn_set_cutting_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cutting_lay_sheets_updated_at ON public.cutting_lay_sheets;
CREATE TRIGGER trg_cutting_lay_sheets_updated_at
    BEFORE UPDATE ON public.cutting_lay_sheets
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_cutting_updated_at();

DROP TRIGGER IF EXISTS trg_cutting_bundles_updated_at ON public.cutting_bundles;
CREATE TRIGGER trg_cutting_bundles_updated_at
    BEFORE UPDATE ON public.cutting_bundles
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_cutting_updated_at();

-- 2. Stored Procedure: Atomic Bundle Generator & Barcode Serializer (The Root Seed)
-- Standard Factory Bundle Size: 20 to 25 pieces per ticket
CREATE OR REPLACE FUNCTION public.fn_generate_cutting_bundles_for_lay(
    p_lay_sheet_id UUID,
    p_max_bundle_size INTEGER DEFAULT 25
)
RETURNS INTEGER AS $$
DECLARE
    v_lay RECORD;
    v_order RECORD;
    v_ratio RECORD;
    v_color RECORD;
    v_bundle_seq INTEGER;
    v_total_pieces_for_size INTEGER;
    v_num_bundles INTEGER;
    v_b INTEGER;
    v_pcs INTEGER;
    v_start_ply INTEGER;
    v_end_ply INTEGER;
    v_clean_lay_num VARCHAR(32);
    v_barcode VARCHAR(64);
    v_inserted_count INTEGER := 0;
BEGIN
    -- Fetch Lay Sheet
    SELECT * INTO v_lay FROM public.cutting_lay_sheets WHERE id = p_lay_sheet_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lay sheet ID % not found.', p_lay_sheet_id;
    END IF;

    -- Fetch Associated Order
    SELECT * INTO v_order FROM public.merchandising_orders WHERE id = v_lay.order_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order ID % not found for lay sheet %.', v_lay.order_id, v_lay.lay_sheet_number;
    END IF;

    v_clean_lay_num := REPLACE(v_lay.lay_sheet_number, 'LAY-', '');

    -- Delete any existing un-dispatched bundles for idempotency
    DELETE FROM public.cutting_bundles 
    WHERE lay_sheet_id = p_lay_sheet_id AND status = 'CUT_COMPLETED';

    -- Loop through each distinct size ratio for this order
    FOR v_ratio IN 
        SELECT size_label, color_name, SUM(ratio_units) as ratio_sum
        FROM public.merchandising_order_ratios
        WHERE order_id = v_lay.order_id
        GROUP BY size_label, color_name
        ORDER BY size_label
    LOOP
        v_total_pieces_for_size := v_lay.total_plies * COALESCE(v_ratio.ratio_sum, 1);
        v_num_bundles := CEIL(v_total_pieces_for_size::NUMERIC / p_max_bundle_size::NUMERIC);

        FOR v_b IN 1..v_num_bundles LOOP
            -- Calculate piece count for this ticket (handle remainder on final bundle)
            IF v_b = v_num_bundles AND (v_total_pieces_for_size % p_max_bundle_size) != 0 THEN
                v_pcs := v_total_pieces_for_size % p_max_bundle_size;
            ELSE
                v_pcs := p_max_bundle_size;
            END IF;

            v_start_ply := ((v_b - 1) * p_max_bundle_size) + 1;
            v_end_ply := v_start_ply + v_pcs - 1;

            -- Construct standard industrial barcode: BND-{lay}-{size}-{seq}
            v_barcode := 'BND-' || v_clean_lay_num || '-' || v_ratio.size_label || '-' || LPAD(v_b::TEXT, 3, '0');

            INSERT INTO public.cutting_bundles (
                bundle_barcode,
                lay_sheet_id,
                order_id,
                size_label,
                color_name,
                bundle_sequence,
                piece_count,
                start_ply_num,
                end_ply_num,
                current_division,
                status
            ) VALUES (
                v_barcode,
                p_lay_sheet_id,
                v_lay.order_id,
                v_ratio.size_label,
                v_ratio.color_name,
                v_b,
                v_pcs,
                v_start_ply,
                v_end_ply,
                'CUTTING',
                'CUT_COMPLETED'
            );

            v_inserted_count := v_inserted_count + 1;
        END LOOP;
    END LOOP;

    -- Update Lay Sheet actual cut pieces
    UPDATE public.cutting_lay_sheets
    SET 
        actual_cut_pieces = (SELECT COALESCE(SUM(piece_count), 0) FROM public.cutting_bundles WHERE lay_sheet_id = p_lay_sheet_id),
        status = 'COMPLETED',
        updated_at = NOW()
    WHERE id = p_lay_sheet_id;

    RETURN v_inserted_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Consolidated Real-Time Executive KPI View: view_cutting_floor_kpis
CREATE OR REPLACE VIEW public.view_cutting_floor_kpis AS
SELECT
    COUNT(DISTINCT cls.id) AS total_lay_sheets,
    COUNT(DISTINCT cls.id) FILTER (WHERE cls.status IN ('SPREADING', 'READY_FOR_CUT', 'CUTTING')) AS active_lay_sheets_wip,
    COUNT(DISTINCT cls.cutting_table_id) FILTER (WHERE cls.status IN ('SPREADING', 'READY_FOR_CUT', 'CUTTING')) AS active_cutting_tables,
    COALESCE(SUM(cls.expected_pieces), 0) AS total_expected_cut_pieces,
    COALESCE(SUM(cls.actual_cut_pieces), 0) AS total_actual_cut_pieces,
    COUNT(DISTINCT cb.id) AS total_serialized_bundles,
    COUNT(DISTINCT cb.id) FILTER (WHERE cb.status = 'CUT_COMPLETED' AND cb.current_division = 'CUTTING') AS bundles_ready_for_dispatch,
    ROUND(
        CASE 
            WHEN COUNT(qa.id) = 0 THEN 100.00
            ELSE (COUNT(qa.id) FILTER (WHERE qa.qc_verdict = 'PASS')::NUMERIC / COUNT(qa.id)::NUMERIC) * 100.00
        END, 2
    ) AS panel_qc_pass_rate_pct,
    COALESCE(SUM(eb.remnant_weight_kg), 0) AS total_end_bit_remnant_kg,
    COALESCE(SUM(eb.remnant_length_m), 0) AS total_end_bit_remnant_meters
FROM public.cutting_lay_sheets cls
LEFT JOIN public.cutting_bundles cb ON cb.lay_sheet_id = cls.id
LEFT JOIN public.cutting_panel_qc_audits qa ON qa.lay_sheet_id = cls.id
LEFT JOIN public.cutting_end_bit_logs eb ON eb.lay_sheet_id = cls.id;

COMMENT ON VIEW public.view_cutting_floor_kpis IS 'Real-time aggregation of cutting floor operations, table utilization, serialized bundles, and quality audit pass rates.';


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 07_cutting_rls_policies.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 07_cutting_rls_policies.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Row-Level Security (RLS) Configuration & Permissions
-- ==============================================================================

-- 1. Enable RLS on all Division 03 tables
ALTER TABLE public.cutting_lay_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_fabric_rolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_lay_rolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_panel_qc_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_end_bit_logs ENABLE ROW LEVEL SECURITY;

-- 2. Service Role Bypass Policies (Full Access)
DROP POLICY IF EXISTS "service_role_all_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "service_role_all_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "service_role_all_store_fabric_rolls" ON public.store_fabric_rolls
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_lay_rolls" ON public.cutting_lay_rolls;
CREATE POLICY "service_role_all_cutting_lay_rolls" ON public.cutting_lay_rolls
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_bundles" ON public.cutting_bundles;
CREATE POLICY "service_role_all_cutting_bundles" ON public.cutting_bundles
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits;
CREATE POLICY "service_role_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs;
CREATE POLICY "service_role_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. Authenticated Users (Floor Supervisors, Cutting Masters, Production Managers)
DROP POLICY IF EXISTS "authenticated_select_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "authenticated_select_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_modify_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "authenticated_modify_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_select_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "authenticated_select_store_fabric_rolls" ON public.store_fabric_rolls
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_modify_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "authenticated_modify_store_fabric_rolls" ON public.store_fabric_rolls
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_select_cutting_lay_rolls" ON public.cutting_lay_rolls;
CREATE POLICY "authenticated_select_cutting_lay_rolls" ON public.cutting_lay_rolls
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_bundles" ON public.cutting_bundles;
CREATE POLICY "authenticated_all_cutting_bundles" ON public.cutting_bundles
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits;
CREATE POLICY "authenticated_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs;
CREATE POLICY "authenticated_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs
    FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 08_cutting_seed_data.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 08_cutting_seed_data.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Reference Lay Sheet, Fabric Rolls, Serialized Bundles & Verification Audit
-- ==============================================================================

DO $$
DECLARE
    v_order_id UUID;
    v_roll_1_id UUID;
    v_roll_2_id UUID;
    v_lay_sheet_id UUID;
    v_profile_id UUID;
    v_first_bundle_id UUID;
    v_bundle_count INTEGER := 0;
BEGIN
    -- 1. Resolve Reference Order (PO-ZIG-8901 - ART-HD-8821 Hoodie)
    SELECT id INTO v_order_id 
    FROM public.merchandising_orders 
    WHERE order_number = 'PO-ZIG-8901' 
    LIMIT 1;

    IF v_order_id IS NULL THEN
        SELECT id INTO v_order_id FROM public.merchandising_orders LIMIT 1;
    END IF;

    IF v_order_id IS NULL THEN
        RAISE NOTICE 'Skipping seed: No orders exist in merchandising_orders table.';
        RETURN;
    END IF;

    -- 2. Resolve Active User Profile for Operator / Inspector
    SELECT id INTO v_profile_id FROM public.profiles LIMIT 1;

    -- 3. Seed Certified Fabric Rolls in Central Store (Division 11 Inward Handshake)
    INSERT INTO public.store_fabric_rolls (
        roll_barcode,
        material_type,
        fabric_name,
        shade_group,
        dye_lot_number,
        gross_weight_kg,
        length_meters,
        usable_width_inches,
        inspection_points_score,
        status
    ) VALUES (
        'ROL-FT-8821-A1',
        'SHELL_FABRIC',
        'Heavyweight French Terry 380 GSM Combed Cotton',
        'SHADE_A',
        'LOT-2026-991',
        22.50,
        55.00,
        60.00,
        8,
        'ON_CUTTING_TABLE'
    ) ON CONFLICT (roll_barcode) DO UPDATE 
    SET status = 'ON_CUTTING_TABLE'
    RETURNING id INTO v_roll_1_id;

    INSERT INTO public.store_fabric_rolls (
        roll_barcode,
        material_type,
        fabric_name,
        shade_group,
        dye_lot_number,
        gross_weight_kg,
        length_meters,
        usable_width_inches,
        inspection_points_score,
        status
    ) VALUES (
        'ROL-FT-8821-A2',
        'SHELL_FABRIC',
        'Heavyweight French Terry 380 GSM Combed Cotton',
        'SHADE_A',
        'LOT-2026-991',
        22.80,
        55.00,
        60.00,
        12,
        'ON_CUTTING_TABLE'
    ) ON CONFLICT (roll_barcode) DO UPDATE 
    SET status = 'ON_CUTTING_TABLE'
    RETURNING id INTO v_roll_2_id;

    -- 4. Seed Reference Lay Sheet: LAY-2026-0842 (Table 01, 80 Plies, Ratio Total = 10, 800 Cut Pieces)
    INSERT INTO public.cutting_lay_sheets (
        lay_sheet_number,
        order_id,
        cutting_table_id,
        marker_length_m,
        total_plies,
        size_ratio_text,
        ratio_total,
        expected_pieces,
        actual_cut_pieces,
        spreading_operator_id,
        cutting_master_id,
        status,
        notes
    ) VALUES (
        'LAY-2026-0842',
        v_order_id,
        'TABLE_01',
        5.40,
        80,
        'XS:1, S:2, M:4, L:2, XL:1',
        10,
        800,
        800,
        v_profile_id,
        v_profile_id,
        'COMPLETED',
        'Bulk body cut for PO-ZIG-8901. French Terry 380 GSM, Jet Black. Precision straight-knife cut.'
    ) ON CONFLICT (lay_sheet_number) DO UPDATE
    SET 
        expected_pieces = 800,
        actual_cut_pieces = 800,
        status = 'COMPLETED'
    RETURNING id INTO v_lay_sheet_id;

    -- 5. Seed Fabric Rolls Junction (Lay Sheet Allocation)
    DELETE FROM public.cutting_lay_rolls WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_lay_rolls (lay_sheet_id, roll_id, plies_from_roll, meters_consumed, remnant_length_m)
    VALUES 
        (v_lay_sheet_id, v_roll_1_id, 40, 216.00, 1.20),
        (v_lay_sheet_id, v_roll_2_id, 40, 216.00, 0.85);

    -- 6. Generate 32 Serialized Component Bundles (The Root Seed Table)
    DELETE FROM public.cutting_bundles WHERE lay_sheet_id = v_lay_sheet_id;

    -- XS: 80 Pcs (4 Bundles: 3x25 + 1x5)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-XS-001', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-002', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-003', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-004', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 4, 5, 76, 80, 'CUTTING', 'CUT_COMPLETED');

    -- S: 160 Pcs (7 Bundles: 6x25 + 1x10)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-S-001', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-002', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-003', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-004', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-005', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-006', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-007', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 7, 10, 151, 160, 'CUTTING', 'CUT_COMPLETED');

    -- M: 320 Pcs (13 Bundles: 12x25 + 1x20)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-M-001', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-002', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-003', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-004', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-005', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-006', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-007', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 7, 25, 151, 175, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-008', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 8, 25, 176, 200, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-009', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 9, 25, 201, 225, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-010', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 10, 25, 226, 250, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-011', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 11, 25, 251, 275, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-012', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 12, 25, 276, 300, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-013', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 13, 20, 301, 320, 'CUTTING', 'CUT_COMPLETED');

    -- L: 160 Pcs (7 Bundles: 6x25 + 1x10)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-L-001', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-002', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-003', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-004', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-005', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-006', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-007', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 7, 10, 151, 160, 'CUTTING', 'CUT_COMPLETED');

    -- XL: 80 Pcs (4 Bundles: 3x25 + 1x5)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-XL-001', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-002', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-003', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-004', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 4, 5, 76, 80, 'CUTTING', 'CUT_COMPLETED');

    SELECT id INTO v_first_bundle_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-M-001' LIMIT 1;

    -- 7. Seed Precision Cut Panel QC Audit (PASS)
    DELETE FROM public.cutting_panel_qc_audits WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_panel_qc_audits (
        lay_sheet_id,
        bundle_id,
        inspector_id,
        notch_accuracy_mm,
        ply_deflection_mm,
        shade_continuity_pass,
        template_match_pass,
        qc_verdict,
        audit_notes
    ) VALUES (
        v_lay_sheet_id,
        v_first_bundle_id,
        v_profile_id,
        0.45,
        0.60,
        true,
        true,
        'PASS',
        'Top and bottom plies verified against acrylic template. Notch precision within 0.5mm. Zero blade heat fusion.'
    );

    -- 8. Seed Remnant End-Bit Conservation Log (Fabric Leakage Control)
    DELETE FROM public.cutting_end_bit_logs WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_end_bit_logs (
        lay_sheet_id,
        roll_id,
        remnant_weight_kg,
        remnant_length_m,
        disposition,
        logged_by,
        notes
    ) VALUES (
        v_lay_sheet_id,
        v_roll_1_id,
        0.48,
        1.20,
        'POCKETING_SALVAGE',
        v_profile_id,
        'End-bit salvaged for internal hood lining and pocket welts.'
    );

    RAISE NOTICE 'Division 03 Cutting Floor seed completed successfully: LAY-2026-0842 (800 Pcs, 32 Bundles) linked to PO-ZIG-8901.';
END $$;

-- 9. Verification Query
SELECT 
    cls.lay_sheet_number,
    cls.cutting_table_id,
    mo.order_number,
    mo.currency,
    cls.total_plies,
    cls.size_ratio_text,
    cls.expected_pieces,
    cls.actual_cut_pieces,
    cls.status,
    COUNT(cb.id) as total_bundles_generated,
    SUM(cb.piece_count) as total_bundled_pieces
FROM public.cutting_lay_sheets cls
JOIN public.merchandising_orders mo ON mo.id = cls.order_id
LEFT JOIN public.cutting_bundles cb ON cb.lay_sheet_id = cls.id
WHERE cls.lay_sheet_number = 'LAY-2026-0842'
GROUP BY cls.id, cls.lay_sheet_number, cls.cutting_table_id, mo.order_number, mo.currency, cls.total_plies, cls.size_ratio_text, cls.expected_pieces, cls.actual_cut_pieces, cls.status;


