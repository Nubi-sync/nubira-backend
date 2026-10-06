-- ============================================================================
-- Migration 73: Remove Plant Location Requirement & Relax Constraints
-- Dropping NOT NULL constraints from city_state in platform_tenant_factories
-- and demo_inquiries, making location completely optional/unused.
-- ============================================================================

-- 1. Relax NOT NULL constraint on platform_tenant_factories
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'platform_tenant_factories' AND column_name = 'city_state'
  ) THEN
    ALTER TABLE public.platform_tenant_factories ALTER COLUMN city_state DROP NOT NULL;
    ALTER TABLE public.platform_tenant_factories ALTER COLUMN city_state SET DEFAULT '';
  END IF;
END $$;

-- 2. Relax NOT NULL constraint on demo_inquiries
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'demo_inquiries' AND column_name = 'city_state'
  ) THEN
    ALTER TABLE public.demo_inquiries ALTER COLUMN city_state DROP NOT NULL;
    ALTER TABLE public.demo_inquiries ALTER COLUMN city_state SET DEFAULT '';
  END IF;
END $$;

-- 3. Notify schema update
COMMENT ON TABLE public.platform_tenant_factories IS 'Enterprise tenant factories (Location field deprecated)';
