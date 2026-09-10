-- =========================================================================
-- 51_add_garment_type_to_truck_inwards.sql
-- Add garment_type column to truck_inwards (e.g. Suit, Top, Pant, Jacket)
-- =========================================================================

ALTER TABLE IF EXISTS public.truck_inwards
  ADD COLUMN IF NOT EXISTS garment_type TEXT;

-- Index for garment_type queries
CREATE INDEX IF NOT EXISTS idx_truck_inwards_garment_type ON public.truck_inwards(garment_type);
