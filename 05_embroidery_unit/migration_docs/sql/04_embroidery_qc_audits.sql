-- ==============================================================================
-- 04_embroidery_qc_audits.sql
-- Division 05: Multi-Head Embroidery Floor
-- Table: public.embroidery_qc_audits (In-Line Machine Head Defect Logging)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.embroidery_qc_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'EMB-QC-2026-001'
    run_id UUID REFERENCES public.embroidery_production_runs(id) ON DELETE SET NULL,
    head_number INTEGER NOT NULL CHECK (head_number BETWEEN 1 AND 24),
    defect_type VARCHAR(50) NOT NULL, -- 'BIRD_NESTING', 'NEEDLE_BREAKAGE', 'TENSION_LOOPING', 'HOOP_DISTORTION', 'MISSED_STITCH', 'JUMP_TRIM_STRAY'
    severity VARCHAR(20) DEFAULT 'MINOR', -- 'CRITICAL', 'MAJOR', 'MINOR'
    action_taken VARCHAR(100) DEFAULT 'TENSION_DISC_ADJUSTED', -- 'TENSION_DISC_ADJUSTED', 'NEEDLE_REPLACED', 'BOBBIN_CLEANED'
    auditor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    auditor_name VARCHAR(100) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_embroidery_qc_run ON public.embroidery_qc_audits(run_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_qc_head ON public.embroidery_qc_audits(head_number);
CREATE INDEX IF NOT EXISTS idx_embroidery_qc_defect ON public.embroidery_qc_audits(defect_type);

COMMENT ON TABLE public.embroidery_qc_audits IS 'In-line multi-head machine quality audits identifying specific malfunctioning heads.';
