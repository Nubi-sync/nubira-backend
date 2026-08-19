-- ============================================
-- STEP 11: CHALLAN ITEMS TABLE
-- ============================================
-- Ek challan mein multiple Art No. aur sizes
-- ho sakte hain. Yeh table wahi detail rakhegi.
-- Example: Challan #CH001 mein:
--   A2045 - M size - 200 pcs
--   A2045 - L size - 150 pcs
--   A3001 - XL size - 100 pcs
-- ============================================

CREATE TABLE challan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challan_id UUID NOT NULL REFERENCES delivery_challans(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES articles(id),
  size TEXT,
  quantity INTEGER NOT NULL
);

-- Check: Table Editor mein "challan_items" table dikhni chahiye
-- Columns: id, challan_id, article_id, size, quantity
