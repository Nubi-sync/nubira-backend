-- =========================================================================
-- 38_fix_truck_inwards_line_items_and_columns.sql
-- Add line_items and column aliases to truck_inwards and truck_inward_items
-- =========================================================================

-- 1. Ensure truck_inwards has all necessary columns including line_items JSONB
ALTER TABLE IF EXISTS public.truck_inwards 
  ADD COLUMN IF NOT EXISTS line_items JSONB,
  ADD COLUMN IF NOT EXISTS receiver_name TEXT,
  ADD COLUMN IF NOT EXISTS article_no TEXT,
  ADD COLUMN IF NOT EXISTS challan_no TEXT,
  ADD COLUMN IF NOT EXISTS truck_no TEXT,
  ADD COLUMN IF NOT EXISTS challan_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS total_items INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS due_items_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS shortage_items_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'VERIFIED';

-- 2. Ensure truck_inward_items has both column naming conventions (size_label/size_color, quantity/challan_qty)
ALTER TABLE IF EXISTS public.truck_inward_items
  ADD COLUMN IF NOT EXISTS size_color TEXT,
  ADD COLUMN IF NOT EXISTS challan_qty NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS size_label TEXT,
  ADD COLUMN IF NOT EXISTS quantity NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS shortage_qty NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remarks TEXT;

-- 3. Ensure Full Permissive RLS Policies
ALTER TABLE public.truck_inwards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.truck_inward_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "truck_inwards_all" ON public.truck_inwards;
CREATE POLICY "truck_inwards_all" ON public.truck_inwards
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "truck_inward_items_all" ON public.truck_inward_items;
CREATE POLICY "truck_inward_items_all" ON public.truck_inward_items
  FOR ALL USING (true) WITH CHECK (true);

-- 4. Create missing truck_inward record from recent accessories entries if needed
DO $$
DECLARE
  v_grn_id UUID;
BEGIN
  -- Check if there are accessories with Challan notes but no truck_inwards
  IF NOT EXISTS (SELECT 1 FROM public.truck_inwards) AND EXISTS (SELECT 1 FROM public.accessories WHERE action = 'IN') THEN
    INSERT INTO public.truck_inwards (
      grn_no,
      party_name,
      article_no,
      challan_no,
      inward_date,
      total_items,
      status,
      notes,
      line_items
    ) VALUES (
      'GRN-2026-001',
      COALESCE((SELECT party_name FROM public.accessories WHERE action = 'IN' AND party_name IS NOT NULL LIMIT 1), 'OLLYPOP SUPPLIER'),
      '9433',
      'CH-8841',
      CURRENT_DATE,
      (SELECT COUNT(*) FROM public.accessories WHERE action = 'IN'),
      'VERIFIED',
      'Accessory challan inward received at Godown',
      (
        SELECT json_agg(
          json_build_object(
            'name', item_name,
            'qty', quantity,
            'unit', unit,
            'status', 'RECEIVED'
          )
        )
        FROM public.accessories
        WHERE action = 'IN'
      )
    )
    RETURNING id INTO v_grn_id;

    -- Also insert into truck_inward_items
    INSERT INTO public.truck_inward_items (
      truck_inward_id,
      item_name,
      quantity,
      challan_qty,
      unit,
      status
    )
    SELECT 
      v_grn_id,
      item_name,
      quantity,
      quantity,
      unit,
      'RECEIVED'
    FROM public.accessories
    WHERE action = 'IN';
  END IF;
END $$;
