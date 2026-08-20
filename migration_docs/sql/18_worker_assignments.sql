-- ============================================
-- STEP 18: WORKER ASSIGNMENTS TABLE
-- ============================================
-- Lineman (Supervisor) apne workers ko kaam
-- distribute karta hai. Ye table track karti hai
-- ki kis worker ko kitna qty diya, kab diya,
-- aur done hua ya nahi.
-- ============================================

CREATE TABLE worker_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allotment_id UUID NOT NULL REFERENCES allotments(id) ON DELETE CASCADE,
  lineman_id UUID NOT NULL REFERENCES profiles(id),
  worker_id UUID NOT NULL REFERENCES profiles(id),
  article_id UUID NOT NULL REFERENCES articles(id),
  assigned_qty INTEGER NOT NULL,
  completed_qty INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'IN_PROGRESS', 'DONE')),
  notes TEXT,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Check: Table Editor mein "worker_assignments" table dikhni chahiye
-- Columns: id, allotment_id, lineman_id, worker_id, article_id,
--          assigned_qty, completed_qty, status, notes,
--          assigned_at, completed_at, entry_date