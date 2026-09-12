-- ==============================================================================
-- 07_cutting_rls_policies.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Row-Level Security (RLS) Configuration & Permissions
-- ==============================================================================

-- 1. Enable RLS on all Division 03 tables
ALTER TABLE public.cutting_lay_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_fabric_rolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_lay_rolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_panel_qc_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_end_bit_logs ENABLE ROW LEVEL SECURITY;

-- 2. Service Role Bypass Policies (Full Access)
DROP POLICY IF EXISTS "service_role_all_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "service_role_all_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "service_role_all_store_fabric_rolls" ON public.store_fabric_rolls
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_lay_rolls" ON public.cutting_lay_rolls;
CREATE POLICY "service_role_all_cutting_lay_rolls" ON public.cutting_lay_rolls
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_bundles" ON public.cutting_bundles;
CREATE POLICY "service_role_all_cutting_bundles" ON public.cutting_bundles
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits;
CREATE POLICY "service_role_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits
    FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs;
CREATE POLICY "service_role_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. Authenticated Users (Floor Supervisors, Cutting Masters, Production Managers)
DROP POLICY IF EXISTS "authenticated_select_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "authenticated_select_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_modify_cutting_lay_sheets" ON public.cutting_lay_sheets;
CREATE POLICY "authenticated_modify_cutting_lay_sheets" ON public.cutting_lay_sheets
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_select_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "authenticated_select_store_fabric_rolls" ON public.store_fabric_rolls
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_modify_store_fabric_rolls" ON public.store_fabric_rolls;
CREATE POLICY "authenticated_modify_store_fabric_rolls" ON public.store_fabric_rolls
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_select_cutting_lay_rolls" ON public.cutting_lay_rolls;
CREATE POLICY "authenticated_select_cutting_lay_rolls" ON public.cutting_lay_rolls
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_bundles" ON public.cutting_bundles;
CREATE POLICY "authenticated_all_cutting_bundles" ON public.cutting_bundles
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits;
CREATE POLICY "authenticated_all_cutting_panel_qc_audits" ON public.cutting_panel_qc_audits
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs;
CREATE POLICY "authenticated_all_cutting_end_bit_logs" ON public.cutting_end_bit_logs
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
