-- =========================================================================
-- 35_split_article_9437_into_challan_458.sql
-- Split Pant Art #9437 into its own separate Challan #458
-- =========================================================================

DO $$
DECLARE
  v_article_9437_id UUID;
  v_challan_458_id UUID;
BEGIN
  -- 1. Get Article ID for 9437
  SELECT id INTO v_article_9437_id FROM public.articles WHERE art_no = '9437' LIMIT 1;

  -- 2. Create Challan #458 if it does not already exist
  SELECT id INTO v_challan_458_id FROM public.challans WHERE UPPER(TRIM(challan_no)) = '458' LIMIT 1;
  
  IF v_challan_458_id IS NULL THEN
    INSERT INTO public.challans (
      challan_no,
      challan_date,
      brand,
      fabric_type,
      total_sets,
      total_pcs,
      status,
      notes
    ) VALUES (
      '458',
      CURRENT_DATE,
      'OLLYPOP',
      'PRINTED SINKER',
      1,
      500,
      'IN_PROGRESS',
      '{"user_notes":"","article_lines":[{"art_no":"9437","pattern_no":"PANT","color_pattern":"ROBIN BLUE","size_range":"S","sets":1,"pcs_per_set":500,"total_pcs":500}]}'
    ) RETURNING id INTO v_challan_458_id;
  END IF;

  -- 3. Link Art 9437 allotment to Challan #458
  IF v_article_9437_id IS NOT NULL AND v_challan_458_id IS NOT NULL THEN
    UPDATE public.allotments
    SET challan_id = v_challan_458_id
    WHERE article_id = v_article_9437_id;
  END IF;

END $$;
