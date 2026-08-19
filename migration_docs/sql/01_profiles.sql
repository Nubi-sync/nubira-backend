-- ============================================
-- STEP 1: PROFILES TABLE
-- ============================================
-- Supabase Auth apna "auth.users" table banata hai
-- jisme sirf email/password hota hai.
-- Humein username aur role store karne ke liye
-- ek alag "profiles" table chahiye jo auth.users
-- se linked hogi.
-- ============================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ADMIN', 'LINEMAN', 'PRODUCTION', 'STORE', 'DISPATCH')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Check: Table Editor mein "profiles" table dikhni chahiye
-- Columns: id, username, role, is_active, created_at
