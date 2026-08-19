-- ============================================
-- STEP 14: FIRST ADMIN USER BANANA
-- ============================================
-- Yeh step 2 parts mein hoga:
--
-- PART A (Supabase Dashboard pe karo):
--   1. Authentication → Users → "Add User"
--   2. Email: admin@nubira.local
--   3. Password: apna strong password
--   4. "Auto Confirm" checkbox ✅ ON karo
--   5. "Create User" par click karo
--   6. User ban jayega — uska UUID copy karo
--
-- PART B (Yahan SQL Editor mein run karo):
--   Neeche ke SQL mein UUID paste karo
-- ============================================

-- ⚠️ IMPORTANT: 'paste-your-admin-uuid-here' ko
-- upar se copy kiye hue UUID se replace karo!

INSERT INTO profiles (id, username, role)
VALUES ('6ab804ee-3fcc-4a27-a23d-a3cf72faf75c', 'admin', 'ADMIN');

-- Check: Table Editor → profiles table mein
-- ek row dikhni chahiye: admin, ADMIN, true
