-- ==============================================================================
-- 04_iron_triggers_and_functions.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Automated Timestamp Triggers
-- ==============================================================================

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
