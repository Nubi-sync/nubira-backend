-- =========================================================================
-- MIGRATION 47: CASCADE ARTICLES FOREIGN KEYS
-- Ensures clean, error-free deletion of articles and rate history
-- =========================================================================

-- 1. rate_history cascade
ALTER TABLE IF EXISTS public.rate_history
  DROP CONSTRAINT IF EXISTS rate_history_article_id_fkey;

ALTER TABLE IF EXISTS public.rate_history
  ADD CONSTRAINT rate_history_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 2. allotments cascade (when article is removed, its allotments cascade)
ALTER TABLE IF EXISTS public.allotments
  DROP CONSTRAINT IF EXISTS allotments_article_id_fkey;

ALTER TABLE IF EXISTS public.allotments
  ADD CONSTRAINT allotments_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 3. challan_items cascade
ALTER TABLE IF EXISTS public.challan_items
  DROP CONSTRAINT IF EXISTS challan_items_article_id_fkey;

ALTER TABLE IF EXISTS public.challan_items
  ADD CONSTRAINT challan_items_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 4. qc_logs cascade
ALTER TABLE IF EXISTS public.qc_logs
  DROP CONSTRAINT IF EXISTS qc_logs_article_id_fkey;

ALTER TABLE IF EXISTS public.qc_logs
  ADD CONSTRAINT qc_logs_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 5. daily_product cascade
ALTER TABLE IF EXISTS public.daily_product
  DROP CONSTRAINT IF EXISTS daily_product_article_id_fkey;

ALTER TABLE IF EXISTS public.daily_product
  ADD CONSTRAINT daily_product_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 6. counting_reports cascade
ALTER TABLE IF EXISTS public.counting_reports
  DROP CONSTRAINT IF EXISTS counting_reports_article_id_fkey;

ALTER TABLE IF EXISTS public.counting_reports
  ADD CONSTRAINT counting_reports_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;

-- 7. store_transactions cascade
ALTER TABLE IF EXISTS public.store_transactions
  DROP CONSTRAINT IF EXISTS store_transactions_article_id_fkey;

ALTER TABLE IF EXISTS public.store_transactions
  ADD CONSTRAINT store_transactions_article_id_fkey
  FOREIGN KEY (article_id)
  REFERENCES public.articles(id)
  ON DELETE CASCADE;
