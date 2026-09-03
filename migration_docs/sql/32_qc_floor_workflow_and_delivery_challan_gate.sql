-- =========================================================================
-- 32_qc_floor_workflow_and_delivery_challan_gate.sql
-- QC Floor Daily Receiving, Extended Delivery Challan Schema & Admin Approval Gate
-- =========================================================================

-- 1. Ensure profiles_role_check allows QC role if not present
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('ADMIN', 'PRODUCTION_MANAGER', 'QC', 'MENDING', 'LINEMAN', 'PRODUCTION', 'STORE', 'DISPATCH'));

-- 2. Add QC workflow tracking columns to allotments table
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_status TEXT DEFAULT 'PENDING_RECEIVING';
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_received_at TIMESTAMPTZ;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_supervisor_id UUID REFERENCES profiles(id);
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_total_passed INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS qc_total_alter INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS total_bags_packed INT DEFAULT 0;
ALTER TABLE allotments ADD COLUMN IF NOT EXISTS delivery_challan_id UUID REFERENCES delivery_challans(id);

-- 3. Extend delivery_challans table with authentic factory challan fields & admin approval gate
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'PENDING_ADMIN_APPROVAL';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS spot_notes TEXT;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS billed_to_name TEXT DEFAULT 'OLLYPOP INDUSTRIES PRIVATE LIMITED';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS billed_to_address TEXT DEFAULT 'Rafi Ahmed Kidwai Road, Kolkata 700055';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS billed_to_gstin TEXT DEFAULT '19AADCO1064C1ZK';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS billed_to_email TEXT;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS shipping_to_name TEXT DEFAULT 'OLLYPOP INDUSTRIES PRIVATE LIMITED';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS shipping_to_address TEXT DEFAULT 'Srijan Logistic Park, Maheshtalla';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS shipping_to_email TEXT DEFAULT 'creationnubira@gmail.com';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS total_bags INT DEFAULT 0;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS total_order_qty INT DEFAULT 0;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS total_delivery_qty INT DEFAULT 0;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS total_balance_qty INT DEFAULT 0;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES profiles(id);
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- 4. Extend challan_items table with 8-column breakdown fields
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'SUIT';
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS product_type TEXT DEFAULT 'TOP';
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS order_qty INT DEFAULT 0;
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS delivery_qty INT DEFAULT 0;
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS balance_qty INT DEFAULT 0;
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS allotment_id UUID REFERENCES allotments(id);
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

-- 5. Indexes for fast retrieval
CREATE INDEX IF NOT EXISTS idx_delivery_challans_status ON delivery_challans(status);
CREATE INDEX IF NOT EXISTS idx_challan_items_challan_id ON challan_items(challan_id);
CREATE INDEX IF NOT EXISTS idx_allotments_qc_status ON allotments(qc_status);

-- 6. Enable RLS and permissive policies
ALTER TABLE delivery_challans ENABLE ROW LEVEL SECURITY;
ALTER TABLE challan_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for delivery_challans" ON delivery_challans;
CREATE POLICY "Allow all for delivery_challans" ON delivery_challans
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for challan_items" ON challan_items;
CREATE POLICY "Allow all for challan_items" ON challan_items
  FOR ALL USING (true) WITH CHECK (true);

-- 7. Backfill existing active allotments
UPDATE allotments
SET qc_status = 'PENDING_RECEIVING'
WHERE qc_status IS NULL;
