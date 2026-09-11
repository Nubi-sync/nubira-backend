-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 05: FABRIC & TRIMS TECHNICAL MATERIALS LIBRARY
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.design_materials_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_code VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'FAB-FTERRY-380-BLK'
    material_name VARCHAR(128) NOT NULL,
    material_type VARCHAR(32) NOT NULL, -- 'KNIT_FABRIC', 'WOVEN_FABRIC', 'RIB_TRIM', 'SEWING_THREAD'
    composition TEXT NOT NULL, -- e.g. '100% Combed Cotton' or '95% Cotton 5% Elastane'
    nominal_gsm INTEGER NOT NULL CHECK (nominal_gsm BETWEEN 40 AND 800),
    usable_width_cm NUMERIC(5,1) DEFAULT 180.0,
    length_shrinkage_pct NUMERIC(4,2) DEFAULT 4.00,
    width_shrinkage_pct NUMERIC(4,2) DEFAULT 2.50,
    spirality_pct NUMERIC(4,2) DEFAULT 1.50,
    recommended_needle VARCHAR(50) DEFAULT 'Ball Point 75/11',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_materials_lib_code ON public.design_materials_library(material_code);
CREATE INDEX IF NOT EXISTS idx_materials_lib_type ON public.design_materials_library(material_type);

-- Comments
COMMENT ON TABLE public.design_materials_library IS 'Technical repository of tested fabrics, knits, trims, shrinkage benchmarks, and needle classes.';
