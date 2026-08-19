-- ============================================
-- STEP 8: ACCESSORIES TABLE
-- ============================================
-- Raw materials ka tracking: dhaaga, button, zip,
-- label, polybag etc.
-- IN = naya stock aaya
-- OUT = line ko diya gaya
-- ============================================

CREATE TABLE accessories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('IN', 'OUT')),
  quantity INTEGER NOT NULL,
  unit TEXT DEFAULT 'pcs',
  party_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "accessories" table dikhni chahiye
-- Columns: id, item_name, action, quantity, unit, party_name, created_at
