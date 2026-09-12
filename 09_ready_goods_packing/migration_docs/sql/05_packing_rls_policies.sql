-- ==============================================================================
-- 05_packing_rls_policies.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Row Level Security (RLS) & Multi-Role Access Control
-- ==============================================================================

-- Enable RLS
ALTER TABLE public.ready_goods_cartons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_carton_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_aql_audits ENABLE ROW LEVEL SECURITY;

-- 1. Cartons Policies
DROP POLICY IF EXISTS p_cartons_select ON public.ready_goods_cartons;
CREATE POLICY p_cartons_select ON public.ready_goods_cartons FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_cartons_insert ON public.ready_goods_cartons;
CREATE POLICY p_cartons_insert ON public.ready_goods_cartons FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_cartons_update ON public.ready_goods_cartons;
CREATE POLICY p_cartons_update ON public.ready_goods_cartons FOR UPDATE TO authenticated USING (true);

-- 2. Carton Bundles Policies
DROP POLICY IF EXISTS p_carton_bundles_select ON public.ready_goods_carton_bundles;
CREATE POLICY p_carton_bundles_select ON public.ready_goods_carton_bundles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_carton_bundles_insert ON public.ready_goods_carton_bundles;
CREATE POLICY p_carton_bundles_insert ON public.ready_goods_carton_bundles FOR INSERT TO authenticated WITH CHECK (true);

-- 3. AQL Audits Policies
DROP POLICY IF EXISTS p_aql_audits_select ON public.ready_goods_aql_audits;
CREATE POLICY p_aql_audits_select ON public.ready_goods_aql_audits FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_aql_audits_insert ON public.ready_goods_aql_audits;
CREATE POLICY p_aql_audits_insert ON public.ready_goods_aql_audits FOR INSERT TO authenticated WITH CHECK (true);
