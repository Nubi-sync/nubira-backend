-- =========================================================================
-- 31_mending_floor_assignments_and_handover.sql
-- Mending Floor Workflow: Lineman Handover & Mending Worker Assignments
-- =========================================================================

-- 1. Ensure profiles_role_check includes MENDING & PRODUCTION_MANAGER
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('ADMIN', 'PRODUCTION_MANAGER', 'MENDING', 'LINEMAN', 'PRODUCTION', 'STORE', 'DISPATCH'));

-- 2. Add Mending Handover tracking columns to allotments table
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_status TEXT DEFAULT 'PENDING_STITCHING';
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS handed_to_mending_at TIMESTAMPTZ;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_verified_at TIMESTAMPTZ;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS mending_total_counted INT DEFAULT 0;

-- 3. Create mending_assignments table for worker counting & trimming distribution
CREATE TABLE IF NOT EXISTS mending_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID REFERENCES allotments(id) ON DELETE CASCADE,
  mending_supervisor_id UUID REFERENCES profiles(id),
  worker_name TEXT NOT NULL,
  article_id UUID REFERENCES articles(id),
  color TEXT,
  size TEXT,
  assigned_qty INT NOT NULL,
  completed_qty INT DEFAULT 0,
  status TEXT DEFAULT 'PENDING', -- 'PENDING', 'DONE'
  notes TEXT,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  entry_date DATE DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_mending_assignments_allotment 
  ON mending_assignments(allotment_id);
CREATE INDEX IF NOT EXISTS idx_mending_assignments_date 
  ON mending_assignments(entry_date);

-- 4. Enable Row Level Security (RLS) & Add Policies
ALTER TABLE mending_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for mending_assignments" ON mending_assignments;
CREATE POLICY "Allow all for mending_assignments" ON mending_assignments
  FOR ALL USING (true) WITH CHECK (true);

-- 5. Backfill existing active allotments so they appear in Mending queue seamlessly
UPDATE allotments
SET mending_status = 'HANDED_OVER_TO_MENDING'
WHERE status = 'IN_PROGRESS' AND (mending_status IS NULL OR mending_status = 'PENDING_STITCHING');
