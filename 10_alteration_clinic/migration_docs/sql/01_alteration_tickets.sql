-- ==============================================================================
-- 01_alteration_tickets.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Table: public.alteration_tickets (Defect Triage & Repair Station Tickets)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.alteration_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'ALT-2026-00412'
    allotment_id UUID REFERENCES public.allotments(id) ON DELETE RESTRICT,
    bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    defect_category VARCHAR(50) NOT NULL, -- 'OPEN_SEAM', 'SKIP_STITCH', 'ASYMMETRY', 'BROKEN_THREAD', 'OIL_STAIN'
    defect_severity VARCHAR(20) DEFAULT 'MAJOR', -- 'MINOR', 'MAJOR', 'CRITICAL'
    original_tailor_id UUID REFERENCES public.employees(id),
    repair_tailor_id UUID REFERENCES public.employees(id),
    pieces_received INTEGER NOT NULL CHECK (pieces_received > 0),
    pieces_repaired INTEGER DEFAULT 0,
    pieces_scrapped INTEGER DEFAULT 0,
    secondary_qc_inspector_id UUID REFERENCES public.employees(id),
    status VARCHAR(30) DEFAULT 'INTAKE', -- 'INTAKE', 'IN_REPAIR', 'SECONDARY_QC_PASSED', 'CONDEMNED_SCRAP'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_alter_tickets_number ON public.alteration_tickets(ticket_number);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_allotment ON public.alteration_tickets(allotment_id);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_bundle ON public.alteration_tickets(bundle_id);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_status ON public.alteration_tickets(status);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_defect ON public.alteration_tickets(defect_category);

COMMENT ON TABLE public.alteration_tickets IS 'Defect intake triage tickets tracking rework tailor reassignment, secondary QC clearance, and salvage rates.';
