-- =========================================================================
-- 34_unique_challan_numbers_and_validation.sql
-- Enforce Unique Job Work Delivery Challan Numbers on Database Level
-- =========================================================================

-- 1. Create unique index on uppercase, trimmed challan_no to prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_challans_unique_no 
  ON public.challans(UPPER(TRIM(challan_no)));

-- 2. Performance index for brand & status lookups
CREATE INDEX IF NOT EXISTS idx_challans_brand_status 
  ON public.challans(brand, status);
