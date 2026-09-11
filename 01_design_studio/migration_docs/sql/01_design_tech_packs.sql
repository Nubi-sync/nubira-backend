-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 01: MASTER TECH-PACK TABLE
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.design_tech_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_number VARCHAR(50) NOT NULL,
    brand_id UUID NOT NULL REFERENCES public.brands(id) ON DELETE RESTRICT,
    category VARCHAR(50) NOT NULL, -- 'HOODIE', 'TSHIRT', 'POLO', 'JOGGER', 'JACKET', 'KIDS_ROMPER'
    size_system VARCHAR(30) DEFAULT 'ALPHA_ADULT', -- 'ALPHA_ADULT', 'NUMERIC_WAIST', 'KIDS_AGE', 'PLUS_SIZE'
    base_size VARCHAR(20) DEFAULT 'M',
    fabric_composition TEXT NOT NULL,
    target_gsm INTEGER NOT NULL CHECK (target_gsm BETWEEN 60 AND 800),
    embellishment_sequence VARCHAR(40) DEFAULT 'NONE', -- 'NONE', 'EMBROIDERY_FIRST_THEN_PRINT', 'PRINT_FIRST_THEN_EMBROIDERY'
    cad_front_url TEXT,
    cad_back_url TEXT,
    spi INTEGER DEFAULT 12 CHECK (spi BETWEEN 6 AND 24),
    seam_class VARCHAR(50) DEFAULT 'ISO 4915 Class 401',
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'SAMPLE_DEV', 'PPS_SUBMITTED', 'PPS_APPROVED', 'APPROVED_BULK', 'REVISE_FIT'
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_tech_pack_brand_style_ver UNIQUE(brand_id, style_number, version)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tech_packs_brand_style ON public.design_tech_packs(brand_id, style_number);
CREATE INDEX IF NOT EXISTS idx_tech_packs_status ON public.design_tech_packs(status);
CREATE INDEX IF NOT EXISTS idx_tech_packs_category ON public.design_tech_packs(category);
CREATE INDEX IF NOT EXISTS idx_tech_packs_created_at ON public.design_tech_packs(created_at DESC);

-- Comments for documentation
COMMENT ON TABLE public.design_tech_packs IS 'Master registry for design tech-packs, CAD specs, and garment construction rules.';
COMMENT ON COLUMN public.design_tech_packs.embellishment_sequence IS 'Strict sequence directive: defines whether embroidery or printing processes raw cut panels first.';
