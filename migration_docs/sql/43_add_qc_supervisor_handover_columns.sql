-- =========================================================================
-- 43_add_qc_supervisor_handover_columns.sql
-- Multi-Supervisor QC Handover & Chain of Custody Tracking
-- =========================================================================

-- 1. Add QC Supervisor and Handover tracking columns to allotments
ALTER TABLE IF EXISTS public.allotments
  ADD COLUMN IF NOT EXISTS qc_supervisor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS qc_supervisor_name TEXT,
  ADD COLUMN IF NOT EXISTS handed_to_qc_by TEXT,
  ADD COLUMN IF NOT EXISTS handed_to_qc_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS qc_handover_notes TEXT;

-- 2. Create index for fast lookup of lots by QC Supervisor
CREATE INDEX IF NOT EXISTS idx_allotments_qc_sup 
  ON public.allotments(qc_supervisor_id, qc_status);

-- 3. Ensure RLS allows read and update on allotments
ALTER TABLE public.allotments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allotments_qc_handover_all" ON public.allotments;
CREATE POLICY "allotments_qc_handover_all" ON public.allotments
  FOR ALL USING (true) WITH CHECK (true);
