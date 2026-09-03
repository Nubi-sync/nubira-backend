-- =========================================================================
-- 37_set_challans_pending_when_unallotted.sql
-- Set Challan Status to PENDING for delivery challans without active floor allotments
-- =========================================================================

DO $$
BEGIN
  -- Update challans that have no active lineman allotments to PENDING
  UPDATE public.challans
  SET status = 'PENDING'
  WHERE id NOT IN (
    SELECT DISTINCT challan_id 
    FROM public.allotments 
    WHERE challan_id IS NOT NULL 
      AND lineman_id IS NOT NULL 
      AND status NOT IN ('CANCELLED')
  );
END $$;
