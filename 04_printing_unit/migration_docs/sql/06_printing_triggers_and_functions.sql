-- ==============================================================================
-- 06_printing_triggers_and_functions.sql
-- Division 04: Screen & Digital Printing Unit
-- Automation Triggers, Mathematical Aggregations & Analytical Views
-- ==============================================================================

-- 1. Automatic Rollup of Printed & Rejected Pieces onto Production Runs
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

-- 2. Bundle Custody Handshake Trigger (Cutting -> Printing -> Sewing)
CREATE OR REPLACE FUNCTION public.fn_sync_printing_bundle_custody()
RETURNS TRIGGER AS $$
BEGIN
    -- When bundle is added to a print run, mark its current division as PRINTING
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

-- 3. Automatic Curing Oven Thermal Anomaly Classification
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

-- 4. Executive Division 04 Floor KPIs Analytical View
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

COMMENT ON VIEW public.view_printing_floor_kpis IS 'Real-time executive performance indicators for Division 04 Printing Unit.';
