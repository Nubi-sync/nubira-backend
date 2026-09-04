-- =========================================================================
-- MIGRATION 45: CASCADE ALLOTMENTS FOREIGN KEYS
-- Ensures smooth, error-free deletion of test allotments and delivery challans
-- =========================================================================

-- 1. qc_logs cascade
ALTER TABLE IF EXISTS public.qc_logs
  DROP CONSTRAINT IF EXISTS qc_logs_allotment_id_fkey;

ALTER TABLE IF EXISTS public.qc_logs
  ADD CONSTRAINT qc_logs_allotment_id_fkey
  FOREIGN KEY (allotment_id)
  REFERENCES public.allotments(id)
  ON DELETE CASCADE;

-- 2. allotment_variants cascade (ensures clean cascade on size variants)
ALTER TABLE IF EXISTS public.allotment_variants
  DROP CONSTRAINT IF EXISTS allotment_variants_allotment_id_fkey;

ALTER TABLE IF EXISTS public.allotment_variants
  ADD CONSTRAINT allotment_variants_allotment_id_fkey
  FOREIGN KEY (allotment_id)
  REFERENCES public.allotments(id)
  ON DELETE CASCADE;

-- 3. allotment_materials cascade (ensures clean cascade on BOM materials)
ALTER TABLE IF EXISTS public.allotment_materials
  DROP CONSTRAINT IF EXISTS allotment_materials_allotment_id_fkey;

ALTER TABLE IF EXISTS public.allotment_materials
  ADD CONSTRAINT allotment_materials_allotment_id_fkey
  FOREIGN KEY (allotment_id)
  REFERENCES public.allotments(id)
  ON DELETE CASCADE;
