-- ============================================
-- STEP 6: QC LOGS TABLE
-- ============================================
-- Production/QC department ka saara data yahan aayega.
-- 4 stages hain: RECEIVING, CHECKING, MENDING, BULKING
-- Har stage ka alag entry hoga.
-- ============================================

CREATE TABLE qc_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES articles(id),
  stage TEXT NOT NULL CHECK (stage IN ('RECEIVING', 'CHECKING', 'MENDING', 'BULKING')),
  from_lineman_id UUID REFERENCES profiles(id),
  qty_received INTEGER DEFAULT 0,
  qty_passed INTEGER DEFAULT 0,
  qty_rejected INTEGER DEFAULT 0,
  defect_type TEXT DEFAULT 'NONE',
  remarks TEXT,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "qc_logs" table dikhni chahiye
-- Columns: id, article_id, stage, from_lineman_id, qty_received, qty_passed, 
--          qty_rejected, defect_type, remarks, entry_date, created_at
