-- ==============================================================================
-- 02_alteration_scrap_logs.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Table: public.alteration_scrap_logs (Financial Scrap Loss Accrual Ledger)
-- ==============================================================================

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

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_alter_scrap_ticket ON public.alteration_scrap_logs(ticket_id);

COMMENT ON TABLE public.alteration_scrap_logs IS 'Irreparable garment scrap declarations tracking monetary losses and salvage cutoffs.';
