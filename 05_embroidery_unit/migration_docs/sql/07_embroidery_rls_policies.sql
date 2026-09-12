-- ==============================================================================
-- 07_embroidery_rls_policies.sql
-- Division 05: Multi-Head Embroidery Floor
-- Row Level Security (RLS) & Multi-Role Data Governance Policies
-- ==============================================================================

-- Enable RLS across all Division 05 tables
ALTER TABLE public.embroidery_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_production_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_qc_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embroidery_thread_inventory ENABLE ROW LEVEL SECURITY;

-- 1. Embroidery Designs Policies
DROP POLICY IF EXISTS p_embroidery_designs_select ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_select ON public.embroidery_designs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_designs_insert ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_insert ON public.embroidery_designs
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_embroidery_designs_update ON public.embroidery_designs;
CREATE POLICY p_embroidery_designs_update ON public.embroidery_designs
FOR UPDATE TO authenticated USING (true);

-- 2. Embroidery Machines Policies
DROP POLICY IF EXISTS p_embroidery_machines_select ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_select ON public.embroidery_machines
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_machines_insert ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_insert ON public.embroidery_machines
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_embroidery_machines_update ON public.embroidery_machines;
CREATE POLICY p_embroidery_machines_update ON public.embroidery_machines
FOR UPDATE TO authenticated USING (true);

-- 3. Embroidery Production Runs Policies
DROP POLICY IF EXISTS p_embroidery_runs_select ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_select ON public.embroidery_production_runs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_runs_insert ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_insert ON public.embroidery_production_runs
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_embroidery_runs_update ON public.embroidery_production_runs;
CREATE POLICY p_embroidery_runs_update ON public.embroidery_production_runs
FOR UPDATE TO authenticated USING (true);

-- 4. Embroidery QC Audits Policies
DROP POLICY IF EXISTS p_embroidery_qc_select ON public.embroidery_qc_audits;
CREATE POLICY p_embroidery_qc_select ON public.embroidery_qc_audits
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_qc_insert ON public.embroidery_qc_audits;
CREATE POLICY p_embroidery_qc_insert ON public.embroidery_qc_audits
FOR INSERT TO authenticated WITH CHECK (true);

-- 5. Embroidery Thread Inventory Policies
DROP POLICY IF EXISTS p_embroidery_thread_select ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_select ON public.embroidery_thread_inventory
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_embroidery_thread_insert ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_insert ON public.embroidery_thread_inventory
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_embroidery_thread_update ON public.embroidery_thread_inventory;
CREATE POLICY p_embroidery_thread_update ON public.embroidery_thread_inventory
FOR UPDATE TO authenticated USING (true);
