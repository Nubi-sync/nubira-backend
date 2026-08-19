-- ============================================
-- STEP 4: ALLOTMENTS TABLE
-- ============================================
-- Admin decide karta hai ki kis Lineman ko
-- kaunsa Art No. silna hai aur kitna target hai.
-- Yeh table wahi data store karegi.
-- ============================================

CREATE TABLE allotments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lineman_id UUID NOT NULL REFERENCES profiles(id),
  article_id UUID NOT NULL REFERENCES articles(id),
  target_qty INTEGER NOT NULL,
  allotment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "allotments" table dikhni chahiye
-- Columns: id, lineman_id, article_id, target_qty, allotment_date, status, created_at
