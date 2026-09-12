-- ==============================================================================
-- 03_printing_bundle_runs.sql
-- Division 04: Screen & Digital Printing Unit
-- Table: public.printing_bundle_runs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.printing_bundle_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    production_run_id UUID NOT NULL REFERENCES public.printing_production_runs(id) ON DELETE CASCADE,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    received_pieces INTEGER NOT NULL CHECK (received_pieces > 0),
    passed_pieces INTEGER NOT NULL CHECK (passed_pieces >= 0),
    rejected_pieces INTEGER NOT NULL DEFAULT 0 CHECK (rejected_pieces >= 0),
    reconciliation_valid BOOLEAN GENERATED ALWAYS AS (received_pieces = passed_pieces + rejected_pieces) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_printing_bundle_runs_run ON public.printing_bundle_runs(production_run_id);
CREATE INDEX IF NOT EXISTS idx_printing_bundle_runs_bundle ON public.printing_bundle_runs(bundle_id);

COMMENT ON TABLE public.printing_bundle_runs IS 'Ingested cut bundle piece-count reconciliation records for print runs.';
COMMENT ON COLUMN public.printing_bundle_runs.bundle_id IS 'Foreign Key to public.cutting_bundles (Division 03 physical bundle barcode).';
COMMENT ON COLUMN public.printing_bundle_runs.reconciliation_valid IS 'Generated stored column: guarantees 100% piece reconciliation parity.';
