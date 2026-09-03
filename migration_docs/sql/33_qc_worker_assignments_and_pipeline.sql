-- =========================================================================
-- 33_qc_worker_assignments_and_pipeline.sql
-- QC Floor Worker Assignments, Multi-Worker Inspection & Lineman Alteration Tracking
-- =========================================================================

-- 1. Create qc_assignments table for floor checker distribution
CREATE TABLE IF NOT EXISTS qc_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID REFERENCES allotments(id) ON DELETE CASCADE,
  qc_supervisor_id UUID REFERENCES profiles(id),
  worker_name TEXT NOT NULL,
  article_id UUID REFERENCES articles(id),
  color TEXT,
  size TEXT,
  assigned_qty INT NOT NULL,
  checked_qty INT DEFAULT 0,
  passed_qty INT DEFAULT 0,
  alter_qty INT DEFAULT 0,
  status TEXT DEFAULT 'ASSIGNED', -- 'ASSIGNED', 'IN_PROGRESS', 'DONE'
  notes TEXT,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  entry_date DATE DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_qc_assignments_allotment ON qc_assignments(allotment_id);
CREATE INDEX IF NOT EXISTS idx_qc_assignments_date ON qc_assignments(entry_date);

-- 2. Enable Row Level Security (RLS) & Add Policies
ALTER TABLE qc_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for qc_assignments" ON qc_assignments;
CREATE POLICY "Allow all for qc_assignments" ON qc_assignments
  FOR ALL USING (true) WITH CHECK (true);

-- 3. Add helper tracking columns to allotments table
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_status TEXT DEFAULT 'PENDING_RECEIVING';
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_received_at TIMESTAMPTZ;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_total_passed INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_total_alter INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_total_counted INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_verified_at TIMESTAMPTZ;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_status TEXT DEFAULT 'PENDING_STITCHING';

-- 4. Add helper columns to qc_logs table for direct Lineman Alteration tracking
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS size TEXT;
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS mending_status TEXT DEFAULT 'NONE';
ALTER TABLE qc_logs ADD COLUMN IF NOT EXISTS allotment_id UUID REFERENCES allotments(id);

CREATE INDEX IF NOT EXISTS idx_qc_logs_allotment ON qc_logs(allotment_id);
CREATE INDEX IF NOT EXISTS idx_qc_logs_lineman ON qc_logs(from_lineman_id);
CREATE INDEX IF NOT EXISTS idx_qc_logs_status ON qc_logs(mending_status);
