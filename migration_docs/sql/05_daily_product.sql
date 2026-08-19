-- ============================================
-- STEP 5: DAILY PRODUCT TABLE
-- ============================================
-- Lineman daily apni line ke workers ka
-- production log karega yahan.
-- Kis employee ne kis Art No. ke kitne piece banaye.
-- ============================================

CREATE TABLE daily_product (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lineman_id UUID NOT NULL REFERENCES profiles(id),
  employee_id UUID NOT NULL REFERENCES profiles(id),
  article_id UUID NOT NULL REFERENCES articles(id),
  quantity INTEGER NOT NULL,
  notes TEXT,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "daily_product" table dikhni chahiye
-- Columns: id, lineman_id, employee_id, article_id, quantity, notes, entry_date, created_at
