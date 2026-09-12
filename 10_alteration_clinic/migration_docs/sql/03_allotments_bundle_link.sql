-- ==============================================================================
-- 03_allotments_bundle_link.sql
-- Division 10 / Cross-Module Relational Integrity
-- Non-destructive additive foreign key on public.allotments
-- ==============================================================================

-- Safely add bundle_id referencing cutting_bundles if it does not already exist
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

COMMENT ON COLUMN public.allotments.bundle_id IS 'Optional foreign key linking sewing allotments to serialized cutting bundles.';
