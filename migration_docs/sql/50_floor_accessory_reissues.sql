-- =========================================================================
-- 50_floor_accessory_reissues.sql
-- Floor Accessory Loss, Machine Damage & Counter Re-Issue Audit System
-- Tracks when tailors/workers lose or damage trims (zipper, buttons, etc.)
-- =========================================================================

CREATE TABLE IF NOT EXISTS floor_accessory_reissues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID REFERENCES allotments(id) ON DELETE SET NULL,
  article_id UUID REFERENCES articles(id) ON DELETE SET NULL,
  article_no TEXT NOT NULL,
  challan_no TEXT,
  worker_name TEXT NOT NULL,
  lineman_name TEXT,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit TEXT DEFAULT 'pcs',
  reason TEXT NOT NULL CHECK (reason IN ('LOST', 'MACHINE_DAMAGE', 'DEFECTIVE_PIECE', 'SHORT_IN_LOT')),
  channel TEXT DEFAULT 'DIRECT_COUNTER' CHECK (channel IN ('DIRECT_COUNTER', 'VIA_LINEMAN')),
  issued_by TEXT NOT NULL,
  notes TEXT,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indices for fast lookups on floor radars, mobile app, and admin reports
CREATE INDEX IF NOT EXISTS idx_floor_reissues_allotment ON floor_accessory_reissues(allotment_id);
CREATE INDEX IF NOT EXISTS idx_floor_reissues_article ON floor_accessory_reissues(article_no);
CREATE INDEX IF NOT EXISTS idx_floor_reissues_worker ON floor_accessory_reissues(worker_name);
CREATE INDEX IF NOT EXISTS idx_floor_reissues_date ON floor_accessory_reissues(entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_floor_reissues_created_at ON floor_accessory_reissues(created_at DESC);

-- Enable Row Level Security
ALTER TABLE floor_accessory_reissues ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Allow authenticated read on floor_accessory_reissues" ON floor_accessory_reissues;
CREATE POLICY "Allow authenticated read on floor_accessory_reissues"
  ON floor_accessory_reissues FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow authenticated insert on floor_accessory_reissues" ON floor_accessory_reissues;
CREATE POLICY "Allow authenticated insert on floor_accessory_reissues"
  ON floor_accessory_reissues FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated update on floor_accessory_reissues" ON floor_accessory_reissues;
CREATE POLICY "Allow authenticated update on floor_accessory_reissues"
  ON floor_accessory_reissues FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow authenticated delete on floor_accessory_reissues" ON floor_accessory_reissues;
CREATE POLICY "Allow authenticated delete on floor_accessory_reissues"
  ON floor_accessory_reissues FOR DELETE
  TO authenticated
  USING (true);

-- Allow service_role bypass for administrative actions
DROP POLICY IF EXISTS "Allow service_role full access on floor_accessory_reissues" ON floor_accessory_reissues;
CREATE POLICY "Allow service_role full access on floor_accessory_reissues"
  ON floor_accessory_reissues FOR ALL
  TO service_role
  USING (true);
