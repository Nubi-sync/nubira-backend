-- ============================================
-- STEP 19: RLS POLICIES FOR WORKER_ASSIGNMENTS
-- ============================================

-- Enable RLS
ALTER TABLE worker_assignments ENABLE ROW LEVEL SECURITY;

-- Lineman can see their own assignments
CREATE POLICY "lineman_select_own_assignments"
  ON worker_assignments FOR SELECT
  USING (lineman_id = auth.uid());

-- Lineman can insert assignments for themselves
CREATE POLICY "lineman_insert_own_assignments"
  ON worker_assignments FOR INSERT
  WITH CHECK (lineman_id = auth.uid());

-- Lineman can update their own assignments (mark done, edit qty)
CREATE POLICY "lineman_update_own_assignments"
  ON worker_assignments FOR UPDATE
  USING (lineman_id = auth.uid());

-- Lineman can delete their own assignments (same day only, app enforces)
CREATE POLICY "lineman_delete_own_assignments"
  ON worker_assignments FOR DELETE
  USING (lineman_id = auth.uid());

-- Admin can see all assignments (for reports)
CREATE POLICY "admin_select_all_assignments"
  ON worker_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'ADMIN'
    )
  );