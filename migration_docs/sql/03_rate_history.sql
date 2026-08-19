-- ============================================
-- STEP 3: RATE HISTORY TABLE
-- ============================================
-- Jab bhi Admin kisi article ki stitching rate
-- change karega, toh purani rate yahan log hogi.
-- Isse baad mein dispute ya audit mein kaam aayega.
-- ============================================

CREATE TABLE rate_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  old_rate DECIMAL(10,2) NOT NULL,
  new_rate DECIMAL(10,2) NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "rate_history" table dikhni chahiye
-- Columns: id, article_id, old_rate, new_rate, changed_at
