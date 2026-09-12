-- ==============================================================================
-- 00_alteration_clinic_all_in_one.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Unified All-in-One Database Migration Script
-- ==============================================================================

-- 1. Master Alteration Tickets Table
CREATE TABLE IF NOT EXISTS public.alteration_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(32) NOT NULL UNIQUE,
    allotment_id UUID REFERENCES public.allotments(id) ON DELETE RESTRICT,
    bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    defect_category VARCHAR(50) NOT NULL,
    defect_severity VARCHAR(20) DEFAULT 'MAJOR',
    original_tailor_id UUID REFERENCES public.employees(id),
    repair_tailor_id UUID REFERENCES public.employees(id),
    pieces_received INTEGER NOT NULL CHECK (pieces_received > 0),
    pieces_repaired INTEGER DEFAULT 0,
    pieces_scrapped INTEGER DEFAULT 0,
    secondary_qc_inspector_id UUID REFERENCES public.employees(id),
    status VARCHAR(30) DEFAULT 'INTAKE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alter_tickets_number ON public.alteration_tickets(ticket_number);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_allotment ON public.alteration_tickets(allotment_id);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_bundle ON public.alteration_tickets(bundle_id);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_status ON public.alteration_tickets(status);

-- 2. Alteration Scrap Financial Ledger
CREATE TABLE IF NOT EXISTS public.alteration_scrap_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.alteration_tickets(id) ON DELETE CASCADE,
    scrapped_pieces INTEGER NOT NULL CHECK (scrapped_pieces > 0),
    scrap_reason TEXT NOT NULL,
    fabric_weight_kg NUMERIC(6,2),
    estimated_financial_loss_inr NUMERIC(10,2) NOT NULL,
    authorized_by UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alter_scrap_ticket ON public.alteration_scrap_logs(ticket_id);

-- 3. Non-destructive Additive Link to Stitching Allotments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'allotments' 
        AND column_name = 'bundle_id'
    ) THEN
        ALTER TABLE public.allotments
        ADD COLUMN bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE SET NULL;
        
        CREATE INDEX IF NOT EXISTS idx_allotments_bundle_id ON public.allotments(bundle_id);
    END IF;
END $$;

-- 4. Triggers
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

-- 5. Row Level Security
ALTER TABLE public.alteration_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alteration_scrap_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_alteration_tickets_select ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_select ON public.alteration_tickets FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_alteration_tickets_insert ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_insert ON public.alteration_tickets FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_alteration_tickets_update ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_update ON public.alteration_tickets FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_alteration_scrap_select ON public.alteration_scrap_logs;
CREATE POLICY p_alteration_scrap_select ON public.alteration_scrap_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_alteration_scrap_insert ON public.alteration_scrap_logs;
CREATE POLICY p_alteration_scrap_insert ON public.alteration_scrap_logs FOR INSERT TO authenticated WITH CHECK (true);
