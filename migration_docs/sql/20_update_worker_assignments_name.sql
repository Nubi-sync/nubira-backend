-- ============================================
-- STEP 20: ADD WORKER_NAME TO WORKER_ASSIGNMENTS
-- ============================================
-- Factory workers/tailors ke login accounts nahi hote,
-- Lineman supervisor unka naam khud type karta hai (e.g. Ramesh, Suresh).
-- ============================================

ALTER TABLE worker_assignments ADD COLUMN IF NOT EXISTS worker_name TEXT;
ALTER TABLE worker_assignments ALTER COLUMN worker_id DROP NOT NULL;