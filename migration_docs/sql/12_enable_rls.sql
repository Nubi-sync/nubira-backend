-- ============================================
-- STEP 12: ROW LEVEL SECURITY (RLS) — ENABLE
-- ============================================
-- RLS matlab database level par rules ki
-- kis user ko kaunsa data dikhega.
-- Pehle sabhi tables par RLS ON karo,
-- fir policies (rules) lagao.
-- ============================================

-- Sabhi tables par RLS enable karo
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE allotments ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_product ENABLE ROW LEVEL SECURITY;
ALTER TABLE qc_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE counting_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_challans ENABLE ROW LEVEL SECURITY;
ALTER TABLE challan_items ENABLE ROW LEVEL SECURITY;

-- Helper Function: Current logged-in user ka role nikalo
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check: Koi error nahi aana chahiye. 
-- Table Editor mein har table ke naam ke saamne ek shield icon dikhega.
