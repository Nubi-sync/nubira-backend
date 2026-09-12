-- ==============================================================================
-- 04_alteration_triggers_and_functions.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Automated Timestamp Triggers
-- ==============================================================================

CREATE OR REPLACE FUNCTION update_alteration_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_alteration_tickets_updated_at ON public.alteration_tickets;
CREATE TRIGGER trg_alteration_tickets_updated_at
BEFORE UPDATE ON public.alteration_tickets
FOR EACH ROW EXECUTE FUNCTION update_alteration_timestamp();
