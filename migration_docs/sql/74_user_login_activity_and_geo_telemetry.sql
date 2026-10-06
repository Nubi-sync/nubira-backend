-- ============================================================================
-- Migration 74: User Login Activity & State-Level Geo Telemetry
-- Fully Tenant-Agnostic: Tracks 7-day hourly login matrix and isolated state-level geolocation
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_login_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'MEMBER',
  company_name TEXT,
  tenant_id TEXT,
  ip_address TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'India',
  device_type TEXT DEFAULT 'desktop', -- 'desktop', 'mobile', 'tablet'
  browser TEXT DEFAULT 'Browser',
  operating_system TEXT DEFAULT 'OS',
  logged_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  login_date DATE NOT NULL DEFAULT CURRENT_DATE,
  hour_slot INTEGER NOT NULL DEFAULT EXTRACT(HOUR FROM now())::INTEGER
);

-- Indices for rapid 7-day aggregation
CREATE INDEX IF NOT EXISTS idx_user_login_activity_date 
  ON public.user_login_activity(login_date DESC, hour_slot);

CREATE INDEX IF NOT EXISTS idx_user_login_activity_user 
  ON public.user_login_activity(user_id, login_date);

CREATE INDEX IF NOT EXISTS idx_user_login_activity_tenant 
  ON public.user_login_activity(company_name, login_date);

CREATE INDEX IF NOT EXISTS idx_user_login_activity_state 
  ON public.user_login_activity(state);

-- Enable RLS
ALTER TABLE public.user_login_activity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated insert into user_login_activity" ON public.user_login_activity;
CREATE POLICY "Allow authenticated insert into user_login_activity"
  ON public.user_login_activity
  FOR INSERT
  TO anon, authenticated, service_role
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow users to read login activity" ON public.user_login_activity;
CREATE POLICY "Allow users to read login activity"
  ON public.user_login_activity
  FOR ALL
  TO authenticated, service_role
  USING (true)
  WITH CHECK (true);

COMMENT ON TABLE public.user_login_activity IS 'Tenant-agnostic owner and executive login session telemetry with state-level geolocation';
