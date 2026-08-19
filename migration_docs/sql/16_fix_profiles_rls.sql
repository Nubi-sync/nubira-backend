-- ============================================
-- STEP 16: FIX PROFILES RLS POLICY
-- ============================================
-- Issue: Dashboard crashed because Supervisor could not read 
-- the Lineman's username. The SELECT policy on profiles was
-- restricted to only 'own profile' or 'admin'.
-- Fix: Allow all authenticated users to view profiles so names 
-- can be displayed in lists.
-- ============================================

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

CREATE POLICY "Everyone can view profiles" ON profiles FOR SELECT
  USING (true);

-- Check: Run this in Supabase SQL Editor and refresh the mobile app.
