-- ==============================================================================
-- 02_washing_batches.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Table: public.washing_batches (Production Washer Machine Batches)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.washing_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'WSH-BAT-2026-112'
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    recipe_id UUID REFERENCES public.washing_recipes(id) ON DELETE RESTRICT,
    machine_id VARCHAR(30) NOT NULL, -- e.g. 'BELLY_WASHER_01', 'FRONT_LOAD_WASHER_02'
    operator_id UUID REFERENCES public.employees(id),
    total_garments INTEGER NOT NULL CHECK (total_garments > 0),
    dry_input_weight_kg NUMERIC(8,2) NOT NULL,
    hydro_extracted_weight_kg NUMERIC(8,2),
    tumbler_dry_weight_kg NUMERIC(8,2),
    residual_moisture_percent NUMERIC(4,2),
    status VARCHAR(30) DEFAULT 'WASHING', -- 'WASHING', 'HYDRO_EXTRACTION', 'TUMBLE_DRYING', 'QC_AUDIT', 'COMPLETED'
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_washing_batches_number ON public.washing_batches(batch_number);
CREATE INDEX IF NOT EXISTS idx_washing_batches_order ON public.washing_batches(order_id);
CREATE INDEX IF NOT EXISTS idx_washing_batches_status ON public.washing_batches(status);
CREATE INDEX IF NOT EXISTS idx_washing_batches_recipe ON public.washing_batches(recipe_id);

COMMENT ON TABLE public.washing_batches IS 'Production batches processed across industrial washing cylinders, hydro-extractors, and tumblers.';
COMMENT ON COLUMN public.washing_batches.residual_moisture_percent IS 'Must be <= 6.0% before passing garments to steam ironing.';
