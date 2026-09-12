-- ==============================================================================
-- 07_printing_rls_policies.sql
-- Division 04: Screen & Digital Printing Unit
-- Row Level Security (RLS) & Multi-Role Data Governance Policies
-- ==============================================================================

-- Enable RLS across all Division 04 tables
ALTER TABLE public.printing_strike_offs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_production_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_bundle_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_defect_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_curing_oven_logs ENABLE ROW LEVEL SECURITY;

-- 1. Strike-Offs Policies
DROP POLICY IF EXISTS p_printing_strike_offs_select ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_select ON public.printing_strike_offs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_strike_offs_insert ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_insert ON public.printing_strike_offs
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_printing_strike_offs_update ON public.printing_strike_offs;
CREATE POLICY p_printing_strike_offs_update ON public.printing_strike_offs
FOR UPDATE TO authenticated USING (true);

-- 2. Production Runs Policies
DROP POLICY IF EXISTS p_printing_production_runs_select ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_select ON public.printing_production_runs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_production_runs_insert ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_insert ON public.printing_production_runs
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_printing_production_runs_update ON public.printing_production_runs;
CREATE POLICY p_printing_production_runs_update ON public.printing_production_runs
FOR UPDATE TO authenticated USING (true);

-- 3. Bundle Runs Policies
DROP POLICY IF EXISTS p_printing_bundle_runs_select ON public.printing_bundle_runs;
CREATE POLICY p_printing_bundle_runs_select ON public.printing_bundle_runs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_bundle_runs_insert ON public.printing_bundle_runs;
CREATE POLICY p_printing_bundle_runs_insert ON public.printing_bundle_runs
FOR INSERT TO authenticated WITH CHECK (true);

-- 4. Defect Logs Policies
DROP POLICY IF EXISTS p_printing_defect_logs_select ON public.printing_defect_logs;
CREATE POLICY p_printing_defect_logs_select ON public.printing_defect_logs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_defect_logs_insert ON public.printing_defect_logs;
CREATE POLICY p_printing_defect_logs_insert ON public.printing_defect_logs
FOR INSERT TO authenticated WITH CHECK (true);

-- 5. Curing Oven Logs Policies
DROP POLICY IF EXISTS p_printing_curing_oven_logs_select ON public.printing_curing_oven_logs;
CREATE POLICY p_printing_curing_oven_logs_select ON public.printing_curing_oven_logs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_printing_curing_oven_logs_insert ON public.printing_curing_oven_logs;
CREATE POLICY p_printing_curing_oven_logs_insert ON public.printing_curing_oven_logs
FOR INSERT TO authenticated WITH CHECK (true);
