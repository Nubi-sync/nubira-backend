-- ============================================
-- STEP 15: FIX DAILY PRODUCT RLS POLICY
-- ============================================
-- Issue: Checker (PRODUCTION role) was not able to see the 
-- daily_product entries made by Lineman because the SELECT
-- policy only allowed the Lineman and Admin to view them.
-- Fix: Allowed PRODUCTION role to also SELECT from daily_product.
-- ============================================

DROP POLICY IF EXISTS "Lineman sees own entries" ON daily_product;

CREATE POLICY "Lineman and others can see entries" ON daily_product FOR SELECT
  USING (lineman_id = auth.uid() OR get_my_role() IN ('ADMIN', 'PRODUCTION'));

-- Check: Run this in Supabase SQL Editor and then check the mobile app
-- as a PRODUCTION user. The pending products should now be visible.
