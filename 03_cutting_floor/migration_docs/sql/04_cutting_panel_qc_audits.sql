-- ==============================================================================
-- 04_cutting_panel_qc_audits.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Table: public.cutting_panel_qc_audits
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.cutting_panel_qc_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE RESTRICT,
    bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE SET NULL,
    inspector_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notch_accuracy_mm NUMERIC(4,2) NOT NULL, -- Tol: <= 1.0mm
    ply_deflection_mm NUMERIC(4,2) NOT NULL, -- Tol: <= 1.5mm
    shade_continuity_pass BOOLEAN NOT NULL DEFAULT true,
    template_match_pass BOOLEAN NOT NULL DEFAULT true,
    qc_verdict VARCHAR(20) NOT NULL DEFAULT 'PASS', -- 'PASS', 'RE_CUT_PANELS', 'REJECT'
    audit_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_panel_qc_lay ON public.cutting_panel_qc_audits(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_panel_qc_bundle ON public.cutting_panel_qc_audits(bundle_id);
CREATE INDEX IF NOT EXISTS idx_panel_qc_verdict ON public.cutting_panel_qc_audits(qc_verdict);

COMMENT ON TABLE public.cutting_panel_qc_audits IS 'Precision quality inspections of cut garment panels verifying pattern notch depth, blade ply deflection, and shade matching.';
COMMENT ON COLUMN public.cutting_panel_qc_audits.notch_accuracy_mm IS 'Notch depth deviation from CAD spec in millimeters (Factory SLA: <= 1.0mm).';
COMMENT ON COLUMN public.cutting_panel_qc_audits.ply_deflection_mm IS 'Deflection between top ply and bottom ply cut perimeter (Factory SLA: <= 1.5mm).';
