-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 02: POINT OF MEASURE (POM) MASTER TABLE
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.design_poms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tech_pack_id UUID NOT NULL REFERENCES public.design_tech_packs(id) ON DELETE CASCADE,
    pom_code VARCHAR(32) NOT NULL, -- e.g. 'CHEST_WIDTH', 'BODY_LENGTH_HPS', 'SLEEVE_LENGTH_CB', 'NECK_OPENING'
    pom_name VARCHAR(128) NOT NULL,
    tolerance_cm NUMERIC(4,2) DEFAULT 0.50 CHECK (tolerance_cm >= 0),
    sort_order INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_tech_pack_pom UNIQUE(tech_pack_id, pom_code)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_design_poms_tech_pack ON public.design_poms(tech_pack_id);
CREATE INDEX IF NOT EXISTS idx_design_poms_sort ON public.design_poms(tech_pack_id, sort_order);

-- Comments
COMMENT ON TABLE public.design_poms IS 'Point of Measure (POM) master definitions and ASTM measurement tolerances per tech-pack.';
