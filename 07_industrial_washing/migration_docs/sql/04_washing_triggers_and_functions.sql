-- ==============================================================================
-- 04_washing_triggers_and_functions.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Automated Timestamp Triggers & Quality Threshold Handlers
-- ==============================================================================

-- 1. Automated Updated_At Trigger Function
CREATE OR REPLACE FUNCTION update_washing_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on washing_recipes
DROP TRIGGER IF EXISTS trg_washing_recipes_updated_at ON public.washing_recipes;
CREATE TRIGGER trg_washing_recipes_updated_at
BEFORE UPDATE ON public.washing_recipes
FOR EACH ROW EXECUTE FUNCTION update_washing_timestamp();

-- Trigger on washing_batches
DROP TRIGGER IF EXISTS trg_washing_batches_updated_at ON public.washing_batches;
CREATE TRIGGER trg_washing_batches_updated_at
BEFORE UPDATE ON public.washing_batches
FOR EACH ROW EXECUTE FUNCTION update_washing_timestamp();

-- 2. Automated Shrinkage Tolerance Threshold Trigger
CREATE OR REPLACE FUNCTION check_washing_shrinkage_spec()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-evaluate is_within_spec if shrinkage exceeds +/- 2.5%
    IF ABS(((NEW.pre_wash_length_cm - NEW.post_wash_length_cm) / NEW.pre_wash_length_cm) * 100) > 2.5 OR
       ABS(((NEW.pre_wash_width_cm - NEW.post_wash_width_cm) / NEW.pre_wash_width_cm) * 100) > 2.5 THEN
        NEW.is_within_spec = false;
    ELSE
        NEW.is_within_spec = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_washing_shrinkage_spec ON public.washing_shrinkage_alerts;
CREATE TRIGGER trg_check_washing_shrinkage_spec
BEFORE INSERT OR UPDATE ON public.washing_shrinkage_alerts
FOR EACH ROW EXECUTE FUNCTION check_washing_shrinkage_spec();
