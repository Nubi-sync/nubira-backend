-- ============================================
-- STEP 24: DISPATCH & CHALLAN ENHANCEMENTS
-- ============================================

-- 1. Upgrade challan_items with color
ALTER TABLE challan_items ADD COLUMN IF NOT EXISTS color TEXT;

-- 2. Upgrade delivery_challans with driver phone, e-way bill & status
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS driver_phone TEXT;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS e_way_bill TEXT;
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'DISPATCHED';
ALTER TABLE delivery_challans ADD COLUMN IF NOT EXISTS notes TEXT;

-- 3. Upgrade counting_reports with color & remarks
ALTER TABLE counting_reports ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE counting_reports ADD COLUMN IF NOT EXISTS remarks TEXT;

-- 4. Enable Permissive RLS Policies for Dispatch Operations
ALTER TABLE delivery_challans ENABLE ROW LEVEL SECURITY;
ALTER TABLE challan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE counting_reports ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'delivery_challans' AND policyname = 'delivery_challans_all_access'
  ) THEN
    CREATE POLICY "delivery_challans_all_access" ON delivery_challans FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'challan_items' AND policyname = 'challan_items_all_access'
  ) THEN
    CREATE POLICY "challan_items_all_access" ON challan_items FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'counting_reports' AND policyname = 'counting_reports_all_access'
  ) THEN
    CREATE POLICY "counting_reports_all_access" ON counting_reports FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;