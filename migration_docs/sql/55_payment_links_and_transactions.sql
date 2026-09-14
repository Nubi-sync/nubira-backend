-- ============================================================================
-- 55_payment_links_and_transactions.sql
-- Zigza MES - Platform Super Admin: Razorpay Payment Links & Receivables Engine
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.platform_payment_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.platform_tenant_factories(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    admin_email TEXT NOT NULL,
    razorpay_link_id TEXT UNIQUE NOT NULL,
    short_url TEXT NOT NULL,
    amount_inr NUMERIC NOT NULL DEFAULT 4999,
    subscription_tier TEXT NOT NULL DEFAULT 'FULL_PLANT_AI',
    status TEXT NOT NULL DEFAULT 'ISSUED' CHECK (status IN ('ISSUED', 'PAID', 'CANCELLED', 'EXPIRED')),
    payment_id TEXT,
    payment_method TEXT,
    description TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indices for rapid lookups and webhooks
CREATE INDEX IF NOT EXISTS idx_platform_payment_links_tenant_status 
ON public.platform_payment_links (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_platform_payment_links_razorpay_id 
ON public.platform_payment_links (razorpay_link_id);

CREATE INDEX IF NOT EXISTS idx_platform_payment_links_created 
ON public.platform_payment_links (created_at DESC);

-- Enable Row Level Security (Service role key used by platform admin bypasses RLS)
ALTER TABLE public.platform_payment_links ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE public.platform_payment_links IS 'Registry of Razorpay Payment Links issued for tenant subscriptions, demo upgrades, and retainer collections';
COMMENT ON COLUMN public.platform_payment_links.razorpay_link_id IS 'Razorpay plink_xxx unique identifier';
COMMENT ON COLUMN public.platform_payment_links.short_url IS 'Hosted checkout payment URL (e.g. https://rzp.io/l/xxx)';
COMMENT ON COLUMN public.platform_payment_links.status IS 'Lifecycle state: ISSUED, PAID, CANCELLED, EXPIRED';

