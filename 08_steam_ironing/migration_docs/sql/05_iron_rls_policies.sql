-- ==============================================================================
-- 05_iron_rls_policies.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Row Level Security (RLS) & Role-Based Access Control
-- ==============================================================================

-- Enable RLS
ALTER TABLE public.iron_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_production_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iron_defect_audits ENABLE ROW LEVEL SECURITY;

-- 1. Tables Policies
DROP POLICY IF EXISTS p_iron_tables_select ON public.iron_tables;
CREATE POLICY p_iron_tables_select ON public.iron_tables FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_tables_insert ON public.iron_tables;
CREATE POLICY p_iron_tables_insert ON public.iron_tables FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_iron_tables_update ON public.iron_tables;
CREATE POLICY p_iron_tables_update ON public.iron_tables FOR UPDATE TO authenticated USING (true);

-- 2. Production Logs Policies
DROP POLICY IF EXISTS p_iron_logs_select ON public.iron_production_logs;
CREATE POLICY p_iron_logs_select ON public.iron_production_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_logs_insert ON public.iron_production_logs;
CREATE POLICY p_iron_logs_insert ON public.iron_production_logs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_iron_logs_update ON public.iron_production_logs;
CREATE POLICY p_iron_logs_update ON public.iron_production_logs FOR UPDATE TO authenticated USING (true);

-- 3. Defect Audits Policies
DROP POLICY IF EXISTS p_iron_defects_select ON public.iron_defect_audits;
CREATE POLICY p_iron_defects_select ON public.iron_defect_audits FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_iron_defects_insert ON public.iron_defect_audits;
CREATE POLICY p_iron_defects_insert ON public.iron_defect_audits FOR INSERT TO authenticated WITH CHECK (true);
