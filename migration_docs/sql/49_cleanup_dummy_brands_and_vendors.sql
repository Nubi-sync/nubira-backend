-- ==============================================================================
-- 49_cleanup_dummy_brands_and_vendors.sql
-- Cleanup: Remove dummy seed vendors and unused brands from production DB
-- ==============================================================================

-- 1. Remove dummy seed vendors inserted by migration 48
DELETE FROM public.vendors 
WHERE vendor_code IN ('OP-INHOUSE', 'OP-VND-01', 'OP-VND-02');

-- 2. Remove unused dummy brands (preserving real active brands like OLLYPOP)
DELETE FROM public.brands 
WHERE brand_name IN ('FIRST SMILE', 'LAZY BONES', 'CANDY POP', 'NUBIRA IN-HOUSE', 'CHERRY POP');
