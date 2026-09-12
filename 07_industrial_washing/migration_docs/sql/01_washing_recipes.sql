-- ==============================================================================
-- 01_washing_recipes.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Table: public.washing_recipes (Chemical Recipes & Liquor Ratios)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.washing_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'WSH-ENZYME-SILK-01'
    wash_type VARCHAR(50) NOT NULL, -- 'BIO_ENZYME', 'SILICON_SOFTENER', 'STONE_WASH', 'GARMENT_DYE', 'ACID_WASH'
    liquor_ratio VARCHAR(10) DEFAULT '1:10', -- 1:8, 1:10, 1:12
    wash_temperature_c INTEGER NOT NULL CHECK (wash_temperature_c BETWEEN 30 AND 95),
    cycle_time_minutes INTEGER NOT NULL CHECK (cycle_time_minutes BETWEEN 10 AND 180),
    chemical_recipe_json JSONB NOT NULL, -- Array of { chemical_name, dosing_g_per_l }
    ph_target NUMERIC(3,1) NOT NULL DEFAULT 6.5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_washing_recipes_code ON public.washing_recipes(recipe_code);
CREATE INDEX IF NOT EXISTS idx_washing_recipes_type ON public.washing_recipes(wash_type);

COMMENT ON TABLE public.washing_recipes IS 'Standard technical garment washing formulations, liquor ratios, and chemical dosing rules.';
COMMENT ON COLUMN public.washing_recipes.chemical_recipe_json IS 'JSON array of chemicals and standard dosing in grams per liter (g/L).';
