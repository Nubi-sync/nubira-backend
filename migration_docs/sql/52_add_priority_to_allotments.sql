-- =========================================================================
-- 52_add_priority_to_allotments.sql
-- Add production priority & urgency column to allotments ('NORMAL', 'RUSH', 'CRITICAL')
-- =========================================================================

ALTER TABLE IF EXISTS public.allotments
  ADD COLUMN IF NOT EXISTS priority TEXT NOT NULL DEFAULT 'NORMAL';

-- Ensure constraint allows only supported priority levels
DO $$
BEGIN
  ALTER TABLE public.allotments 
    DROP CONSTRAINT IF EXISTS allotments_priority_check;
    
  ALTER TABLE public.allotments 
    ADD CONSTRAINT allotments_priority_check 
    CHECK (priority IN ('NORMAL', 'RUSH', 'CRITICAL'));
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- B-Tree index for lightning-fast priority filtering and queue sorting
CREATE INDEX IF NOT EXISTS idx_allotments_priority ON public.allotments(priority);

-- Backfill priority from allotment_materials notes JSON if previously recorded
DO $$
BEGIN
  UPDATE public.allotments a
  SET priority = UPPER(m.notes::jsonb->>'priority')
  FROM public.allotment_materials m
  WHERE m.allotment_id = a.id
    AND m.notes IS NOT NULL
    AND (m.notes::jsonb->>'priority') IS NOT NULL
    AND UPPER(m.notes::jsonb->>'priority') IN ('RUSH', 'CRITICAL');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
