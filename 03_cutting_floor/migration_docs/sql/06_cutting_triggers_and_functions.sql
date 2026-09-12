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
