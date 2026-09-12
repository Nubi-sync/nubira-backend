-- ==============================================================================
-- 03_washing_shrinkage_alerts.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Table: public.washing_shrinkage_alerts (Pre/Post Wash Dimensional Shrinkage Audits)
-- ==============================================================================

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

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_washing_shrinkage_batch ON public.washing_shrinkage_alerts(batch_id);
CREATE INDEX IF NOT EXISTS idx_washing_shrinkage_spec ON public.washing_shrinkage_alerts(is_within_spec);

COMMENT ON TABLE public.washing_shrinkage_alerts IS 'Post-wash specimen measurement records to verify length/width shrinkage within +/- 2.5% tolerance.';
