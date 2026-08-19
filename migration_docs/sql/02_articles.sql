-- ============================================
-- STEP 2: ARTICLES TABLE (Art No. Master)
-- ============================================
-- Har ek garment style ka ek unique Art No. hota hai
-- Jaise "A2045" = Men's Polo Collar Navy
-- Isme uski stitching rate bhi stored hogi
-- ============================================

CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  art_no TEXT UNIQUE NOT NULL,
  description TEXT,
  stitching_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "articles" table dikhni chahiye
-- Columns: id, art_no, description, stitching_rate, is_active, created_at
