-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- SCRIPT 09: DESIGN TECH-PACKS & BRANDS ACCESS POLICIES
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

-- 1. Ensure design_tech_packs table has full access policies for anon and authenticated
ALTER TABLE IF EXISTS public.design_tech_packs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon access to design_tech_packs" ON public.design_tech_packs;
CREATE POLICY "Allow anon access to design_tech_packs" 
ON public.design_tech_packs FOR ALL 
TO anon 
USING (true) 
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated access to design_tech_packs" ON public.design_tech_packs;
CREATE POLICY "Allow authenticated access to design_tech_packs" 
ON public.design_tech_packs FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- 2. Ensure brands table has full access policies for anon and authenticated
ALTER TABLE IF EXISTS public.brands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon access to brands" ON public.brands;
CREATE POLICY "Allow anon access to brands" 
ON public.brands FOR ALL 
TO anon 
USING (true) 
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated access to brands" ON public.brands;
CREATE POLICY "Allow authenticated access to brands" 
ON public.brands FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);
