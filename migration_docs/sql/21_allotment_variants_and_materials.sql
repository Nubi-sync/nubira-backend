-- ============================================
-- STEP 21: ALLOTMENT VARIANTS & MATERIALS CHECKLIST
-- ============================================

-- 1. Allotment Variants (Dynamic Size & Color Matrix)
CREATE TABLE IF NOT EXISTS allotment_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID NOT NULL REFERENCES allotments(id) ON DELETE CASCADE,
  color TEXT NOT NULL,
  size TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  completed_qty INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Allotment Materials (Raw Materials & Accessories Issue Checklist)
CREATE TABLE IF NOT EXISTS allotment_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID NOT NULL REFERENCES allotments(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  required_qty TEXT NOT NULL,
  admin_issued BOOLEAN DEFAULT false,
  admin_issued_at TIMESTAMPTZ,
  lineman_received BOOLEAN DEFAULT false,
  lineman_received_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Add Size & Color to Worker Assignments and Daily Product
ALTER TABLE worker_assignments ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE worker_assignments ADD COLUMN IF NOT EXISTS size TEXT;

ALTER TABLE daily_product ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE daily_product ADD COLUMN IF NOT EXISTS size TEXT;

-- 4. Enable RLS on new tables
ALTER TABLE allotment_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE allotment_materials ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for allotment_variants
CREATE POLICY "allotment_variants_select"
  ON allotment_variants FOR SELECT
  USING (true);

CREATE POLICY "allotment_variants_insert"
  ON allotment_variants FOR INSERT
  WITH CHECK (true);

CREATE POLICY "allotment_variants_update"
  ON allotment_variants FOR UPDATE
  USING (true);

CREATE POLICY "allotment_variants_delete"
  ON allotment_variants FOR DELETE
  USING (true);

-- 6. RLS Policies for allotment_materials
CREATE POLICY "allotment_materials_select"
  ON allotment_materials FOR SELECT
  USING (true);

CREATE POLICY "allotment_materials_insert"
  ON allotment_materials FOR INSERT
  WITH CHECK (true);

CREATE POLICY "allotment_materials_update"
  ON allotment_materials FOR UPDATE
  USING (true);

CREATE POLICY "allotment_materials_delete"
  ON allotment_materials FOR DELETE
  USING (true);