-- ==============================================================================
-- 04_printing_defect_logs.sql
-- Division 04: Screen & Digital Printing Unit
-- Table: public.printing_defect_logs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.printing_defect_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_run_id UUID NOT NULL REFERENCES public.printing_bundle_runs(id) ON DELETE CASCADE,
    defect_type VARCHAR(50) NOT NULL, -- 'PINHOLE', 'OFF_REGISTRATION', 'INK_BLEEDING', 'POOR_CURING', 'SMUDGE', 'FABRIC_BURN'
    defect_count INTEGER NOT NULL CHECK (defect_count > 0),
    action_taken VARCHAR(50) DEFAULT 'PANEL_RE_CUT_REQUESTED', -- 'PANEL_RE_CUT_REQUESTED', 'SPOT_CLEANED', 'SCRAPPED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_printing_defect_logs_bundle_run ON public.printing_defect_logs(bundle_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_defect_logs_type ON public.printing_defect_logs(defect_type);

COMMENT ON TABLE public.printing_defect_logs IS 'Defect pareto classification and panel recut requests generated during printing.';
