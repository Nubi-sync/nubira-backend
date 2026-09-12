-- ==============================================================================
-- 01_embroidery_designs.sql
-- Division 05: Multi-Head Embroidery Floor
-- Table: public.embroidery_designs (DST / EMB Digital Punch Master Registry)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.embroidery_designs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    design_code VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'DST-OLLY-HD8821-CHEST'
    design_name VARCHAR(100) NOT NULL,
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    dst_file_url TEXT NOT NULL,
    total_stitches INTEGER NOT NULL CHECK (total_stitches > 0),
    color_change_count INTEGER NOT NULL DEFAULT 1,
    width_mm NUMERIC(6,2) NOT NULL,
    height_mm NUMERIC(6,2) NOT NULL,
    rate_per_thousand_stitches NUMERIC(6,2) DEFAULT 2.80,
    backing_type VARCHAR(40) DEFAULT 'TEARAWAY', -- 'TEARAWAY', 'CUTAWAY_2.5OZ', 'WATER_SOLUBLE'
    needle_type VARCHAR(40) DEFAULT 'DBxK5_SES_75_11', -- Industrial Ballpoint Needle
    thread_brand VARCHAR(40) DEFAULT 'Madeira',
    status VARCHAR(30) DEFAULT 'APPROVED', -- 'APPROVED', 'IN_TESTING', 'REVISE_PUNCH'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_embroidery_designs_order ON public.embroidery_designs(order_id);
CREATE INDEX IF NOT EXISTS idx_embroidery_designs_code ON public.embroidery_designs(design_code);
CREATE INDEX IF NOT EXISTS idx_embroidery_designs_status ON public.embroidery_designs(status);

COMMENT ON TABLE public.embroidery_designs IS 'Master digitized embroidery vector files (DST/EMB) and stitch allocation metadata.';
COMMENT ON COLUMN public.embroidery_designs.order_id IS 'Foreign Key to public.merchandising_orders (Division 02).';
COMMENT ON COLUMN public.embroidery_designs.total_stitches IS 'Exact punch stitch count used for machine cycle time and piece-rate billing.';
