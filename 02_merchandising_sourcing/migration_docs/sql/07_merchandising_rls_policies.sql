-- ==============================================================================
-- 07_merchandising_rls_policies.sql
-- Division 02: Merchandising & Sourcing Desk
-- Security: Row Level Security (RLS) Policies & Access Roles
-- ==============================================================================

-- 1. Enable RLS on all Division 02 tables
ALTER TABLE public.merchandising_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_order_ratios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_bom_costings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_tna_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_sourcing_requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_shipments ENABLE ROW LEVEL SECURITY;

-- 2. Service Role Policies (Unrestricted Backend Worker / Server Actions Access)
DROP POLICY IF EXISTS "Service role full access on merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Service role full access on merchandising_orders"
    ON public.merchandising_orders FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Service role full access on merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Service role full access on merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Service role full access on merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Service role full access on merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Service role full access on merchandising_shipments"
    ON public.merchandising_shipments FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. Authenticated Factory Staff Policies (Read & Operational Updates)
DROP POLICY IF EXISTS "Authenticated users can view merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Authenticated users can view merchandising_orders"
    ON public.merchandising_orders FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Authenticated users can insert/update merchandising_orders"
    ON public.merchandising_orders FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Authenticated users can view merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Authenticated users can insert/update merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Authenticated users can view merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Authenticated users can insert/update merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Authenticated users can view merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can update merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Authenticated users can update merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Authenticated users can view merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Authenticated users can insert/update merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Authenticated users can view merchandising_shipments"
    ON public.merchandising_shipments FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Authenticated users can insert/update merchandising_shipments"
    ON public.merchandising_shipments FOR ALL TO authenticated USING (true) WITH CHECK (true);
