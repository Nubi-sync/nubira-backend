-- =========================================================================
-- 39_qc_to_store_handshake_and_chain_of_custody.sql
-- Add Chain of Custody & QC-to-Store Handshake Tracking Columns
-- =========================================================================

-- 1. Upgrade store_transactions with Chain of Custody columns
ALTER TABLE IF EXISTS public.store_transactions 
  ADD COLUMN IF NOT EXISTS lineman_name TEXT,
  ADD COLUMN IF NOT EXISTS mending_name TEXT,
  ADD COLUMN IF NOT EXISTS qc_supervisor_name TEXT,
  ADD COLUMN IF NOT EXISTS receiver_name TEXT,
  ADD COLUMN IF NOT EXISTS color TEXT,
  ADD COLUMN IF NOT EXISTS size TEXT,
  ADD COLUMN IF NOT EXISTS challan_no TEXT,
  ADD COLUMN IF NOT EXISTS transport_no TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS entry_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS allotment_id UUID REFERENCES public.allotments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS challan_id UUID REFERENCES public.challans(id) ON DELETE SET NULL;

-- 2. Upgrade allotments with Handshake & QC lifecycle state columns
ALTER TABLE IF EXISTS public.allotments
  ADD COLUMN IF NOT EXISTS qc_status TEXT DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS store_inward_status TEXT DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS qc_supervisor_name TEXT,
  ADD COLUMN IF NOT EXISTS qc_passed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS store_inward_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS store_receiver_name TEXT;

-- 3. Ensure Full Permissive RLS Policies
ALTER TABLE public.store_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allotments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "store_transactions_all" ON public.store_transactions;
CREATE POLICY "store_transactions_all" ON public.store_transactions
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allotments_handshake_all" ON public.allotments;
CREATE POLICY "allotments_handshake_all" ON public.allotments
  FOR ALL USING (true) WITH CHECK (true);

-- 4. Create Performance Indexes for rapid handshake query lookup
CREATE INDEX IF NOT EXISTS idx_store_tx_art_date ON public.store_transactions(article_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_store_tx_type ON public.store_transactions(type);
CREATE INDEX IF NOT EXISTS idx_allotments_qc_store ON public.allotments(qc_status, store_inward_status);
