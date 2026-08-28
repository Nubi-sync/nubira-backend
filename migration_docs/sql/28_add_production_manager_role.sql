-- =========================================================================
-- 28_add_production_manager_role.sql
-- Add PRODUCTION_MANAGER role to profiles table check constraint
-- =========================================================================

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('ADMIN', 'PRODUCTION_MANAGER', 'LINEMAN', 'PRODUCTION', 'STORE', 'DISPATCH'));
