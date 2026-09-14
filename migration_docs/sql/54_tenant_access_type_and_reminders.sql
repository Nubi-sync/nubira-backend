-- ============================================================================
-- 54_tenant_access_type_and_reminders.sql
-- Zigza MES - Platform Super Admin: Access Models & Payment Reminder System
-- ============================================================================

-- Add access type, expiration, revocation, and payment reminder tracking
ALTER TABLE public.platform_tenant_factories 
ADD COLUMN IF NOT EXISTS access_type TEXT NOT NULL DEFAULT 'FULL_ACCESS' CHECK (access_type IN ('FULL_ACCESS', 'DEMO_TRIAL')),
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_payment_reminder_at TIMESTAMPTZ;

-- Index for fast querying of expiring/active trials
CREATE INDEX IF NOT EXISTS idx_platform_tenants_access_expiry 
ON public.platform_tenant_factories (access_type, expires_at);

-- Comments for documentation
COMMENT ON COLUMN public.platform_tenant_factories.access_type IS 'Access tier model: FULL_ACCESS (paid enterprise contract) or DEMO_TRIAL (7-day revocable trial)';
COMMENT ON COLUMN public.platform_tenant_factories.expires_at IS 'Expiration timestamp for trial accounts; null for indefinite paid contracts';
COMMENT ON COLUMN public.platform_tenant_factories.revoked_at IS 'Timestamp when administrative revocation occurred if suspended';
COMMENT ON COLUMN public.platform_tenant_factories.last_payment_reminder_at IS 'Timestamp of the most recent payment reminder email dispatched to client admin';
