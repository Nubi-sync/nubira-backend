-- ============================================
-- STEP 10: DELIVERY CHALLANS TABLE
-- ============================================
-- Final dispatch document. Jab truck mein maal
-- load hota hai tab yeh challan banta hai.
-- Ek challan mein multiple articles ho sakte hain.
-- ============================================

CREATE TABLE delivery_challans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challan_no TEXT UNIQUE NOT NULL,
  buyer_name TEXT NOT NULL,
  destination TEXT,
  vehicle_no TEXT,
  driver_name TEXT,
  total_pieces INTEGER DEFAULT 0,
  delivery_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "delivery_challans" table dikhni chahiye
-- Columns: id, challan_no, buyer_name, destination, vehicle_no, 
--          driver_name, total_pieces, delivery_date, created_at
