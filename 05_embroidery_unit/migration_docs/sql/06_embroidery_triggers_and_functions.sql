-- ==============================================================================
-- 06_embroidery_triggers_and_functions.sql
-- Division 05: Multi-Head Embroidery Floor
-- Automation Triggers, Mathematical Aggregations & Analytical Views
-- ==============================================================================

-- 1. Automatic Stitch Calculation & TBI Classification Trigger
CREATE OR REPLACE FUNCTION public.fn_sync_embroidery_run_stitches()
RETURNS TRIGGER AS $$
DECLARE
    v_unit_stitches INTEGER;
    v_head_count INTEGER;
BEGIN
    -- Fetch design stitch count if not supplied
    IF NEW.total_stitches_run IS NULL OR NEW.total_stitches_run = 0 THEN
        SELECT total_stitches INTO v_unit_stitches 
        FROM public.embroidery_designs 
        WHERE id = NEW.design_id;

        SELECT head_count INTO v_head_count 
        FROM public.embroidery_machines 
        WHERE id = NEW.machine_id;

        NEW.total_stitches_run := COALESCE(NEW.run_cycles, 1) * COALESCE(v_unit_stitches, 15000) * COALESCE(v_head_count, 20);
    END IF;

    -- Automatic TBI Alarm Check (SLA threshold: 3.0 breaks per 100k stitches)
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

-- 2. Bundle Custody Handshake Trigger (Cutting -> Embroidery -> Sewing)
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

-- 3. Executive Division 05 Floor KPIs Analytical View
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

COMMENT ON VIEW public.view_embroidery_floor_kpis IS 'Real-time multi-head computerized embroidery operational metrics and TBI compliance.';
