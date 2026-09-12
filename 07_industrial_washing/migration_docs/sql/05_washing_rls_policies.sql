-- ==============================================================================
-- 05_washing_rls_policies.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Row Level Security (RLS) & Multi-Role Access Control
-- ==============================================================================

-- Enable RLS
ALTER TABLE public.washing_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_shrinkage_alerts ENABLE ROW LEVEL SECURITY;

-- 1. Recipes Policies
DROP POLICY IF EXISTS p_washing_recipes_select ON public.washing_recipes;
CREATE POLICY p_washing_recipes_select ON public.washing_recipes
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_washing_recipes_insert ON public.washing_recipes;
CREATE POLICY p_washing_recipes_insert ON public.washing_recipes
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_washing_recipes_update ON public.washing_recipes;
CREATE POLICY p_washing_recipes_update ON public.washing_recipes
FOR UPDATE TO authenticated USING (true);

-- 2. Batches Policies
DROP POLICY IF EXISTS p_washing_batches_select ON public.washing_batches;
CREATE POLICY p_washing_batches_select ON public.washing_batches
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_washing_batches_insert ON public.washing_batches;
CREATE POLICY p_washing_batches_insert ON public.washing_batches
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_washing_batches_update ON public.washing_batches;
CREATE POLICY p_washing_batches_update ON public.washing_batches
FOR UPDATE TO authenticated USING (true);

-- 3. Shrinkage Alerts Policies
DROP POLICY IF EXISTS p_washing_shrinkage_select ON public.washing_shrinkage_alerts;
CREATE POLICY p_washing_shrinkage_select ON public.washing_shrinkage_alerts
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS p_washing_shrinkage_insert ON public.washing_shrinkage_alerts;
CREATE POLICY p_washing_shrinkage_insert ON public.washing_shrinkage_alerts
FOR INSERT TO authenticated WITH CHECK (true);
