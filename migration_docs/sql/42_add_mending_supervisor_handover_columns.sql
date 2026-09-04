-- =========================================================================
-- 42_add_mending_supervisor_handover_columns.sql
-- Multi-Supervisor Mending Handover & Chain of Custody Tracking
-- =========================================================================

-- 1. Add Mending Supervisor and Handover tracking columns to allotments
ALTER TABLE IF EXISTS public.allotments
  ADD COLUMN IF NOT EXISTS mending_supervisor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS mending_supervisor_name TEXT,
  ADD COLUMN IF NOT EXISTS handed_to_mending_by TEXT,
  ADD COLUMN IF NOT EXISTS mending_handover_notes TEXT;

-- 2. Create index for fast lookup of lots by Mending Supervisor
CREATE INDEX IF NOT EXISTS idx_allotments_mending_sup 
  ON public.allotments(mending_supervisor_id, mending_status);

-- 3. Ensure RLS allows read and update on allotments
ALTER TABLE public.allotments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allotments_mending_handover_all" ON public.allotments;
CREATE POLICY "allotments_mending_handover_all" ON public.allotments
  FOR ALL USING (true) WITH CHECK (true);
