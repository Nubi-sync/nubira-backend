-- ============================================
-- STEP 17: ADD ENTRY DATE TO STORE TRANSACTIONS
-- ============================================
-- Issue: store_transactions table was missing the entry_date column
-- which is used by the mobile app to filter today's inward transactions.
-- Fix: Add the entry_date column.
-- ============================================

ALTER TABLE store_transactions 
ADD COLUMN IF NOT EXISTS entry_date DATE NOT NULL DEFAULT CURRENT_DATE;

-- Check: Run this in Supabase SQL Editor, then check the mobile app again.
