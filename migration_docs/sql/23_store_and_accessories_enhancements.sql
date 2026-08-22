-- ============================================
-- STEP 23: STORE & ACCESSORIES ENHANCEMENTS
-- ============================================

-- 1. Upgrade store_transactions with Color, Size, Challan/Dispatch Ref & Notes
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS size TEXT;
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS challan_no TEXT;
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS transport_no TEXT;
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE store_transactions ADD COLUMN IF NOT EXISTS entry_date DATE DEFAULT CURRENT_DATE;

-- 2. Upgrade accessories table with Notes and Entry Date
ALTER TABLE accessories ADD COLUMN IF NOT EXISTS entry_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE accessories ADD COLUMN IF NOT EXISTS notes TEXT;

-- 3. Permissive RLS Policies for Store Operations
ALTER TABLE store_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE accessories ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'store_transactions' AND policyname = 'store_transactions_all_access'
  ) THEN
    CREATE POLICY "store_transactions_all_access" ON store_transactions FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'accessories' AND policyname = 'accessories_all_access'
  ) THEN
    CREATE POLICY "accessories_all_access" ON accessories FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;