-- =========================================================================
-- 27_size_wise_article_rates.sql
-- Support for Dynamic Size-Wise and Tiered Stitching Piece Rates
-- =========================================================================

-- Add size_rates JSONB column to articles table
ALTER TABLE articles ADD COLUMN IF NOT EXISTS size_rates JSONB DEFAULT '{}'::jsonb;

-- Add size_rates JSONB column to rate_history table for audit logging
ALTER TABLE rate_history ADD COLUMN IF NOT EXISTS size_rates JSONB DEFAULT '{}'::jsonb;

-- Index for fast querying on size_rates
CREATE INDEX IF NOT EXISTS idx_articles_size_rates ON articles USING gin (size_rates);
