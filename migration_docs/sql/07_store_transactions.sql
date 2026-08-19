-- ============================================
-- STEP 7: STORE TRANSACTIONS TABLE
-- ============================================
-- Store/Godown ka inventory track hoga yahan.
-- INWARD = maal andar aaya (QC se pass hokar)
-- OUTWARD = maal bahar gaya (dispatch ke liye)
-- ============================================

CREATE TABLE store_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  type TEXT NOT NULL CHECK (type IN ('INWARD', 'OUTWARD')),
  quantity INTEGER NOT NULL,
  party_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "store_transactions" table dikhni chahiye
-- Columns: id, article_id, type, quantity, party_name, created_at
