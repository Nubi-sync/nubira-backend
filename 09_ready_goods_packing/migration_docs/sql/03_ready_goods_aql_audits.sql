-- ==============================================================================
-- 03_ready_goods_aql_audits.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Table: public.ready_goods_aql_audits (ANSI/ASQ Z1.4 Normal Level II AQL Audits)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ready_goods_aql_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    inspector_id UUID REFERENCES public.employees(id),
    inspection_level VARCHAR(20) DEFAULT 'NORMAL_LEVEL_II',
    sample_size INTEGER NOT NULL CHECK (sample_size > 0),
    critical_defects INTEGER NOT NULL DEFAULT 0,
    major_defects INTEGER NOT NULL DEFAULT 0,
    minor_defects INTEGER NOT NULL DEFAULT 0,
    max_allowed_critical INTEGER NOT NULL DEFAULT 0,
    max_allowed_major INTEGER NOT NULL DEFAULT 3,
    max_allowed_minor INTEGER NOT NULL DEFAULT 5,
    verdict VARCHAR(20) NOT NULL, -- 'PASS', 'FAIL'
    audit_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_aql_audits_carton ON public.ready_goods_aql_audits(carton_id);
CREATE INDEX IF NOT EXISTS idx_aql_audits_verdict ON public.ready_goods_aql_audits(verdict);

COMMENT ON TABLE public.ready_goods_aql_audits IS 'Export carton statistical quality audits enforcing AQL 2.5 Major / 4.0 Minor defect ceilings.';
