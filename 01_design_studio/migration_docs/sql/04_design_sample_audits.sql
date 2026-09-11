-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 04: SAMPLE APPROVALS & GOLDEN SEAL FIT AUDITS
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.design_sample_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tech_pack_id UUID NOT NULL REFERENCES public.design_tech_packs(id) ON DELETE CASCADE,
    sample_stage VARCHAR(30) NOT NULL, -- 'PROTO_1', 'PROTO_2', 'SIZE_SET', 'PPS'
    inspector_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    measured_chest NUMERIC(6,2) NOT NULL,
    measured_length NUMERIC(6,2) NOT NULL,
    measured_sleeve NUMERIC(6,2) NOT NULL,
    measured_neck NUMERIC(6,2),
    variance_max_cm NUMERIC(4,2) NOT NULL DEFAULT 0.00,
    within_tolerance BOOLEAN NOT NULL DEFAULT TRUE,
    fit_comments TEXT,
    buyer_reviewer_name VARCHAR(100),
    buyer_reviewer_email VARCHAR(255),
    verdict VARCHAR(30) NOT NULL, -- 'APPROVED', 'REVISE_FIT', 'REJECTED'
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sample_audits_tech_pack ON public.design_sample_audits(tech_pack_id);
CREATE INDEX IF NOT EXISTS idx_sample_audits_stage ON public.design_sample_audits(sample_stage);
CREATE INDEX IF NOT EXISTS idx_sample_audits_verdict ON public.design_sample_audits(verdict);
CREATE INDEX IF NOT EXISTS idx_sample_audits_created_at ON public.design_sample_audits(created_at DESC);

-- Comments
COMMENT ON TABLE public.design_sample_audits IS 'Buyer sample fit iterations and Pre-Production Sample (PPS) golden-seal approval gate audits.';
