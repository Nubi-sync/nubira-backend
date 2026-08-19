-- ============================================
-- STEP 9: COUNTING REPORTS TABLE
-- ============================================
-- Dispatch se pehle maal ki ginti hoti hai.
-- Size-wise count karke match karte hain ki
-- expected qty aur actual count same hai ya nahi.
-- ============================================

CREATE TABLE counting_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  size TEXT,
  counted_qty INTEGER NOT NULL,
  expected_qty INTEGER DEFAULT 0,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "counting_reports" table dikhni chahiye
-- Columns: id, article_id, size, counted_qty, expected_qty, entry_date, created_at
