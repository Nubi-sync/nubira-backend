-- ==============================================================================
-- 00_washing_unit_all_in_one.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Unified All-in-One Database Migration Script
-- ==============================================================================

-- 1. Standard Washing Recipes Table
CREATE TABLE IF NOT EXISTS public.washing_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_code VARCHAR(32) NOT NULL UNIQUE,
    wash_type VARCHAR(50) NOT NULL,
    liquor_ratio VARCHAR(10) DEFAULT '1:10',
    wash_temperature_c INTEGER NOT NULL CHECK (wash_temperature_c BETWEEN 30 AND 95),
    cycle_time_minutes INTEGER NOT NULL CHECK (cycle_time_minutes BETWEEN 10 AND 180),
    chemical_recipe_json JSONB NOT NULL,
    ph_target NUMERIC(3,1) NOT NULL DEFAULT 6.5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_washing_recipes_code ON public.washing_recipes(recipe_code);
CREATE INDEX IF NOT EXISTS idx_washing_recipes_type ON public.washing_recipes(wash_type);

-- 2. Washing Production Batches Table
CREATE TABLE IF NOT EXISTS public.washing_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(32) NOT NULL UNIQUE,
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    recipe_id UUID REFERENCES public.washing_recipes(id) ON DELETE RESTRICT,
    machine_id VARCHAR(30) NOT NULL,
    operator_id UUID REFERENCES public.employees(id),
    total_garments INTEGER NOT NULL CHECK (total_garments > 0),
    dry_input_weight_kg NUMERIC(8,2) NOT NULL,
    hydro_extracted_weight_kg NUMERIC(8,2),
    tumbler_dry_weight_kg NUMERIC(8,2),
    residual_moisture_percent NUMERIC(4,2),
    status VARCHAR(30) DEFAULT 'WASHING',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_washing_batches_number ON public.washing_batches(batch_number);
CREATE INDEX IF NOT EXISTS idx_washing_batches_order ON public.washing_batches(order_id);
CREATE INDEX IF NOT EXISTS idx_washing_batches_status ON public.washing_batches(status);
CREATE INDEX IF NOT EXISTS idx_washing_batches_recipe ON public.washing_batches(recipe_id);

-- 3. Shrinkage & Dimensional Distortion Alerts Table
CREATE TABLE IF NOT EXISTS public.washing_shrinkage_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES public.washing_batches(id) ON DELETE CASCADE,
    specimen_size VARCHAR(10) NOT NULL DEFAULT 'M',
    pre_wash_length_cm NUMERIC(6,2) NOT NULL,
    post_wash_length_cm NUMERIC(6,2) NOT NULL,
    length_shrinkage_percent NUMERIC(5,2) GENERATED ALWAYS AS (
        ((pre_wash_length_cm - post_wash_length_cm) / pre_wash_length_cm) * 100
    ) STORED,
    pre_wash_width_cm NUMERIC(6,2) NOT NULL,
    post_wash_width_cm NUMERIC(6,2) NOT NULL,
    width_shrinkage_percent NUMERIC(5,2) GENERATED ALWAYS AS (
        ((pre_wash_width_cm - post_wash_width_cm) / pre_wash_width_cm) * 100
    ) STORED,
    spirality_angle_deg NUMERIC(4,2) DEFAULT 0.00,
    is_within_spec BOOLEAN NOT NULL DEFAULT true,
    inspector_id UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_washing_shrinkage_batch ON public.washing_shrinkage_alerts(batch_id);
CREATE INDEX IF NOT EXISTS idx_washing_shrinkage_spec ON public.washing_shrinkage_alerts(is_within_spec);

-- 4. Triggers & Automated Quality Handlers
CREATE OR REPLACE FUNCTION update_washing_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_washing_recipes_updated_at ON public.washing_recipes;
CREATE TRIGGER trg_washing_recipes_updated_at
BEFORE UPDATE ON public.washing_recipes
FOR EACH ROW EXECUTE FUNCTION update_washing_timestamp();

DROP TRIGGER IF EXISTS trg_washing_batches_updated_at ON public.washing_batches;
CREATE TRIGGER trg_washing_batches_updated_at
BEFORE UPDATE ON public.washing_batches
FOR EACH ROW EXECUTE FUNCTION update_washing_timestamp();

-- 5. Row Level Security
ALTER TABLE public.washing_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.washing_shrinkage_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_washing_recipes_select ON public.washing_recipes;
CREATE POLICY p_washing_recipes_select ON public.washing_recipes FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_washing_recipes_insert ON public.washing_recipes;
CREATE POLICY p_washing_recipes_insert ON public.washing_recipes FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_washing_recipes_update ON public.washing_recipes;
CREATE POLICY p_washing_recipes_update ON public.washing_recipes FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_washing_batches_select ON public.washing_batches;
CREATE POLICY p_washing_batches_select ON public.washing_batches FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_washing_batches_insert ON public.washing_batches;
CREATE POLICY p_washing_batches_insert ON public.washing_batches FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_washing_batches_update ON public.washing_batches;
CREATE POLICY p_washing_batches_update ON public.washing_batches FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_washing_shrinkage_select ON public.washing_shrinkage_alerts;
CREATE POLICY p_washing_shrinkage_select ON public.washing_shrinkage_alerts FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_washing_shrinkage_insert ON public.washing_shrinkage_alerts;
CREATE POLICY p_washing_shrinkage_insert ON public.washing_shrinkage_alerts FOR INSERT TO authenticated WITH CHECK (true);
