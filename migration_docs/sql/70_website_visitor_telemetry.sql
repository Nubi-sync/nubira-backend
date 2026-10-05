-- =========================================================================
-- 70_website_visitor_telemetry.sql
-- Zigza MES Platform - Inbound Visitor Telemetry & State-Level Tracking
-- Deduplicated by IP + Device per day with Geo IP Resolution
-- =========================================================================

-- Enable pgcrypto extension for UUID generation if not already active
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================================================
-- 1. TABLE: website_page_views
-- Stores real inbound page views, resolving state/city and deduplicating
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.website_page_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'Unknown',
  state TEXT NOT NULL DEFAULT 'Unknown',
  country TEXT NOT NULL DEFAULT 'India',
  device_type TEXT NOT NULL DEFAULT 'desktop', -- 'mobile', 'desktop', 'tablet'
  browser TEXT NOT NULL DEFAULT 'Unknown',
  operating_system TEXT NOT NULL DEFAULT 'Unknown',
  referrer TEXT NOT NULL DEFAULT 'Direct',
  page_path TEXT NOT NULL DEFAULT '/',
  action TEXT NOT NULL DEFAULT 'Page Viewed',
  dwell_time_seconds INTEGER NOT NULL DEFAULT 0,
  session_id TEXT,
  visited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  visit_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Indices for high-performance deduplication and state queries
CREATE INDEX IF NOT EXISTS idx_website_page_views_date 
  ON public.website_page_views(visit_date DESC);

CREATE INDEX IF NOT EXISTS idx_website_page_views_dedup 
  ON public.website_page_views(ip_address, visit_date, device_type);

CREATE INDEX IF NOT EXISTS idx_website_page_views_state 
  ON public.website_page_views(state);

CREATE INDEX IF NOT EXISTS idx_website_page_views_visited_at 
  ON public.website_page_views(visited_at DESC);

-- =========================================================================
-- 2. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================
ALTER TABLE public.website_page_views ENABLE ROW LEVEL SECURITY;

-- Allow anonymous visitors & public frontend to log their visit (INSERT only)
DROP POLICY IF EXISTS "Allow public insert of page views" ON public.website_page_views;
CREATE POLICY "Allow public insert of page views"
  ON public.website_page_views
  FOR INSERT
  TO anon, authenticated, service_role
  WITH CHECK (true);

-- Allow platform admins & service role full read/write access
DROP POLICY IF EXISTS "Allow admin full access to website page views" ON public.website_page_views;
CREATE POLICY "Allow admin full access to website page views"
  ON public.website_page_views
  FOR ALL
  TO authenticated, service_role
  USING (true)
  WITH CHECK (true);
