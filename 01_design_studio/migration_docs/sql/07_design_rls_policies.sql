-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 07: ROW LEVEL SECURITY (RLS) & ROLE PERMISSIONS
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

-- 1. Enable RLS on all Division 01 Tables
ALTER TABLE public.design_tech_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_poms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_measurement_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_sample_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_materials_library ENABLE ROW LEVEL SECURITY;

-- 2. Read Access Policies (All active authenticated staff can read tech specs)
CREATE POLICY "Allow authenticated staff to read design_tech_packs"
ON public.design_tech_packs FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated staff to read design_poms"
ON public.design_poms FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated staff to read design_measurement_values"
ON public.design_measurement_values FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated staff to read design_sample_audits"
ON public.design_sample_audits FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated staff to read design_materials_library"
ON public.design_materials_library FOR SELECT
TO authenticated
USING (true);

-- 3. Write Access Policies (Restricted to Authorized Roles or Service Role)
-- Authorized roles: 'SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER'
CREATE POLICY "Allow authorized staff to modify design_tech_packs"
ON public.design_tech_packs FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER')
    )
);

CREATE POLICY "Allow authorized staff to modify design_poms"
ON public.design_poms FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER')
    )
);

CREATE POLICY "Allow authorized staff to modify design_measurement_values"
ON public.design_measurement_values FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER')
    )
);

CREATE POLICY "Allow authorized staff to modify design_sample_audits"
ON public.design_sample_audits FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER', 'QC_SUPERVISOR')
    )
);

CREATE POLICY "Allow authorized staff to modify design_materials_library"
ON public.design_materials_library FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('SUPER_ADMIN', 'ADMIN', 'DESIGN_HEAD', 'CAD_DESIGNER', 'PRODUCTION_MANAGER')
    )
);
