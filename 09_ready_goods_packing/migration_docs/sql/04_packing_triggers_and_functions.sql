-- ==============================================================================
-- 04_packing_triggers_and_functions.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Automated Carton Status Transition & Timestamp Triggers
-- ==============================================================================

-- 1. Automated Updated_At Trigger Function
CREATE OR REPLACE FUNCTION update_carton_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cartons_updated_at ON public.ready_goods_cartons;
CREATE TRIGGER trg_cartons_updated_at
BEFORE UPDATE ON public.ready_goods_cartons
FOR EACH ROW EXECUTE FUNCTION update_carton_timestamp();

-- 2. Automated Carton Status Transition from AQL Audit Verdict
CREATE OR REPLACE FUNCTION update_carton_status_from_aql()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.verdict = 'PASS' THEN
        UPDATE public.ready_goods_cartons
        SET status = 'AQL_AUDIT_PASSED', updated_at = NOW()
        WHERE id = NEW.carton_id;
    ELSE
        UPDATE public.ready_goods_cartons
        SET status = 'QUARANTINED_AQL_FAILED', updated_at = NOW()
        WHERE id = NEW.carton_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_carton_status_from_aql ON public.ready_goods_aql_audits;
CREATE TRIGGER trg_update_carton_status_from_aql
AFTER INSERT OR UPDATE ON public.ready_goods_aql_audits
FOR EACH ROW EXECUTE FUNCTION update_carton_status_from_aql();
