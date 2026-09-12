-- ==============================================================================
-- 03_iron_defect_audits.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Table: public.iron_defect_audits (Thermal Shine Glaze & Spot Defect Audits)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.iron_defect_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iron_log_id UUID NOT NULL REFERENCES public.iron_production_logs(id) ON DELETE CASCADE,
    defect_type VARCHAR(50) NOT NULL, -- 'THERMAL_SHINE_GLAZE', 'WATER_DROP_STAIN', 'CRUSHED_CREASE', 'FABRIC_SCORCH'
    defect_count INTEGER NOT NULL CHECK (defect_count > 0),
    disposition VARCHAR(30) DEFAULT 'STEAM_RE_WORK', -- 'STEAM_RE_WORK', 'SCRAP'
    inspector_id UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_iron_defects_log ON public.iron_defect_audits(iron_log_id);
CREATE INDEX IF NOT EXISTS idx_iron_defects_type ON public.iron_defect_audits(defect_type);

COMMENT ON TABLE public.iron_defect_audits IS 'Finishing quality audits checking for thermal glaze, water stains, and iron shine under 1000-lux neutral lighting.';
