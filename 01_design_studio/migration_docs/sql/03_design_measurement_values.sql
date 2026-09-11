-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 03: NORMALIZED SIZE GRADING & MEASUREMENT VALUES
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.design_measurement_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pom_id UUID NOT NULL REFERENCES public.design_poms(id) ON DELETE CASCADE,
    size_label VARCHAR(20) NOT NULL, -- e.g. 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '32x32', '4T', '1X'
    value_cm NUMERIC(6,2) NOT NULL,
    grade_step_cm NUMERIC(4,2) DEFAULT 0.00,
    is_base_size BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_pom_size UNIQUE(pom_id, size_label)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_meas_values_pom ON public.design_measurement_values(pom_id);
CREATE INDEX IF NOT EXISTS idx_meas_values_size ON public.design_measurement_values(size_label);

-- Comments
COMMENT ON TABLE public.design_measurement_values IS 'Fully normalized size grading values supporting Alpha, Numeric, Kids, and Plus-size dimensions per POM.';
