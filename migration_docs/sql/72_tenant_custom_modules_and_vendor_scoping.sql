-- =============================================================================
-- Migration 72: Dynamic Subscribed Modules & Custom Factory Modules for Vendors
-- Description: 
-- 1. Relaxes NOT NULL constraints on module_vendors so factory owners can create
--    custom modules just for the name before assigning a vendor.
-- 2. Adds module_code, icon_name, and is_custom columns to module_vendors.
-- =============================================================================

-- 1. Relax NOT NULL constraints for flexible custom module creation
ALTER TABLE public.module_vendors 
  ALTER COLUMN company_name DROP NOT NULL,
  ALTER COLUMN contact_person DROP NOT NULL,
  ALTER COLUMN phone DROP NOT NULL;

-- 2. Add custom module metadata columns
ALTER TABLE public.module_vendors 
  ADD COLUMN IF NOT EXISTS module_code TEXT,
  ADD COLUMN IF NOT EXISTS icon_name TEXT DEFAULT 'Layers',
  ADD COLUMN IF NOT EXISTS is_custom BOOLEAN DEFAULT FALSE;

-- 3. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_module_vendors_custom 
  ON public.module_vendors (tenant_company, is_custom);
