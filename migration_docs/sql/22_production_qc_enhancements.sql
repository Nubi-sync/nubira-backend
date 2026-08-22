-- ============================================
-- STEP 22: PRODUCTION QC & FINISHING ENHANCEMENTS
-- ============================================

-- 1. Upgrade qc_logs with Color, Size, Defect Details, Mending lifecycle, and Bulking
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS size TEXT;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS mending_returned_qty INTEGER DEFAULT 0;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS mending_scrap_qty INTEGER DEFAULT 0;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS mending_status TEXT DEFAULT 'NONE';
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS bundle_size INTEGER DEFAULT 0;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS total_bundles INTEGER DEFAULT 0;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS sent_to_store BOOLEAN DEFAULT false;

-- 2. Ensure RLS policies are permissive for QC operations
ALTER TABLE qc_logs ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'qc_logs' AND policyname = 'qc_logs_all_access'
  ) THEN
    CREATE POLICY "qc_logs_all_access" ON qc_logs FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;