-- =========================================================================
-- 36_link_article_9433_to_challan_457.sql
-- Link Sweatshirt Art #9433 Allotment to Challan #457
-- =========================================================================

DO $$
DECLARE
  v_article_9433_id UUID;
  v_challan_457_id UUID;
BEGIN
  -- 1. Get Challan #457 ID
  SELECT id INTO v_challan_457_id FROM public.challans WHERE UPPER(TRIM(challan_no)) = '457' LIMIT 1;

  -- 2. Get Article #9433 ID
  SELECT id INTO v_article_9433_id FROM public.articles WHERE art_no = '9433' LIMIT 1;

  -- 3. Link Art 9433 allotment to Challan #457
  IF v_article_9433_id IS NOT NULL AND v_challan_457_id IS NOT NULL THEN
    UPDATE public.allotments
    SET challan_id = v_challan_457_id
    WHERE article_id = v_article_9433_id;
  END IF;

END $$;
