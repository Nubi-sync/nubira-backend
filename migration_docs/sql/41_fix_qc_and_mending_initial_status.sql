-- =========================================================================
-- 41_fix_qc_and_mending_initial_status.sql
-- Fix initial qc_status and mending_status so new allotments do not appear
-- in QC Incoming until Lineman stitches and Mending forwards.
-- =========================================================================

-- 1. Set sensible default values on allotments table
ALTER TABLE allotments ALTER COLUMN qc_status SET DEFAULT 'PENDING_STITCHING';
ALTER TABLE allotments ALTER COLUMN mending_status SET DEFAULT 'PENDING_STITCHING';

-- 2. Clean up existing in-progress allotments where Lineman has not finished
-- and Mending has not verified/handed over to QC
UPDATE allotments
SET 
  qc_status = 'PENDING_STITCHING',
  mending_status = 'PENDING_STITCHING'
WHERE (status = 'IN_PROGRESS' OR status IS NULL)
  AND (mending_status IS NULL OR mending_status = 'PENDING_STITCHING')
  AND (qc_total_passed = 0 OR qc_total_passed IS NULL)
  AND (qc_status = 'PENDING_RECEIVING' OR qc_status IS NULL);
