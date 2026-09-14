-- =========================================================================
-- 60_add_module_heads_to_profiles.sql
-- Zigza MES Enterprise - Department Heads & Module Incharge RBAC
-- Target: Supabase PostgreSQL (nnhzqvdmkarpwtkzjnra)
-- =========================================================================

-- 1. Add RBAC & Department Head columns to public.profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS allowed_modules TEXT[] DEFAULT ARRAY['/stitching-sewing'],
ADD COLUMN IF NOT EXISTS company_name TEXT,
ADD COLUMN IF NOT EXISTS designation TEXT,
ADD COLUMN IF NOT EXISTS is_head BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Create index for tenant & head lookups
CREATE INDEX IF NOT EXISTS idx_profiles_company ON public.profiles(company_name);
CREATE INDEX IF NOT EXISTS idx_profiles_is_head ON public.profiles(is_head);

-- 3. Update existing admin profiles with full 12-division access
UPDATE public.profiles
SET allowed_modules = ARRAY[
  '/design',
  '/merchandising',
  '/cutting',
  '/printing',
  '/embroidery',
  '/stitching-sewing',
  '/washing',
  '/iron',
  '/ready-goods',
  '/alter',
  '/store',
  '/dispatch'
]
WHERE role IN ('SUPERADMIN', 'ADMIN', 'PLATFORM_SUPERADMIN')
  AND (allowed_modules IS NULL OR array_length(allowed_modules, 1) = 0);
