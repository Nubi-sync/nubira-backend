-- ============================================
-- STEP 25: MATERIAL HANDSHAKE & SHORTAGE TRACKING
-- ============================================

-- 1. Add Store inspection, shortage tracking, and supplier challan fields to allotment_materials
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS received_qty TEXT;
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'PENDING';
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS shortage_qty TEXT;
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS supplier_challan_no TEXT;
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS store_verified BOOLEAN DEFAULT false;
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS store_verified_at TIMESTAMPTZ;
ALTER TABLE allotment_materials ADD COLUMN IF NOT EXISTS store_remarks TEXT;

-- 2. Backfill existing records
UPDATE allotment_materials
SET store_verified = true,
    status = 'VERIFIED'
WHERE admin_issued = true AND (store_verified IS NULL OR store_verified = false);

-- 3. Ensure RLS policies permit SELECT, INSERT, and UPDATE for all authenticated users
DROP POLICY IF EXISTS "allotment_materials_select" ON allotment_materials;
CREATE POLICY "allotment_materials_select"
  ON allotment_materials FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "allotment_materials_insert" ON allotment_materials;
CREATE POLICY "allotment_materials_insert"
  ON allotment_materials FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "allotment_materials_update" ON allotment_materials;
CREATE POLICY "allotment_materials_update"
  ON allotment_materials FOR UPDATE
  USING (true);
