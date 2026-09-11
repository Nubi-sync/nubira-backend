-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 06: AUTOMATED TRIGGERS & BUSINESS LOGIC PROCEDURES
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

-- 1. Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.fn_design_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: design_tech_packs updated_at
DROP TRIGGER IF EXISTS trg_design_tech_packs_timestamp ON public.design_tech_packs;
CREATE TRIGGER trg_design_tech_packs_timestamp
BEFORE UPDATE ON public.design_tech_packs
FOR EACH ROW EXECUTE FUNCTION public.fn_design_update_timestamp();

-- Trigger: design_materials_library updated_at
DROP TRIGGER IF EXISTS trg_design_materials_timestamp ON public.design_materials_library;
CREATE TRIGGER trg_design_materials_timestamp
BEFORE UPDATE ON public.design_materials_library
FOR EACH ROW EXECUTE FUNCTION public.fn_design_update_timestamp();

-- 2. Function: Auto-Promote Tech-Pack Status on PPS Golden Seal Approval
CREATE OR REPLACE FUNCTION public.fn_auto_promote_tech_pack_pps()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.sample_stage = 'PPS' AND NEW.verdict = 'APPROVED' THEN
        UPDATE public.design_tech_packs
        SET 
            status = 'PPS_APPROVED',
            updated_at = NOW()
        WHERE id = NEW.tech_pack_id;
    ELSIF NEW.sample_stage = 'PPS' AND NEW.verdict = 'REVISE_FIT' THEN
        UPDATE public.design_tech_packs
        SET 
            status = 'REVISE_FIT',
            updated_at = NOW()
        WHERE id = NEW.tech_pack_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: On Sample Audit Insert or Update
DROP TRIGGER IF EXISTS trg_auto_promote_tech_pack_pps ON public.design_sample_audits;
CREATE TRIGGER trg_auto_promote_tech_pack_pps
AFTER INSERT OR UPDATE ON public.design_sample_audits
FOR EACH ROW EXECUTE FUNCTION public.fn_auto_promote_tech_pack_pps();
