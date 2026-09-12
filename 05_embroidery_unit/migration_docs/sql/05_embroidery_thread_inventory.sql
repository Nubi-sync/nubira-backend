-- ==============================================================================
-- 05_embroidery_thread_inventory.sql
-- Division 05: Multi-Head Embroidery Floor
-- Table: public.embroidery_thread_inventory (Thread Cone Stores & Raw Materials)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.embroidery_thread_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cone_code VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'THD-MAD-1142'
    brand VARCHAR(40) NOT NULL DEFAULT 'Madeira', -- 'Madeira', 'Isacord', 'Coats', 'Vardhman'
    shade_number VARCHAR(30) NOT NULL,
    pantone_match VARCHAR(50) NOT NULL,
    thread_type VARCHAR(40) NOT NULL DEFAULT 'Polyester 40wt', -- 'Polyester 40wt', 'Rayon Viscose 40wt', 'Metallic Gold'
    initial_weight_grams NUMERIC(6,2) NOT NULL DEFAULT 1000.0,
    current_weight_grams NUMERIC(6,2) NOT NULL DEFAULT 850.0,
    cones_in_stock INTEGER NOT NULL DEFAULT 12,
    storage_bin VARCHAR(40) DEFAULT 'Rack E-01 / Bin 04',
    status VARCHAR(20) DEFAULT 'IN_STOCK', -- 'IN_STOCK', 'LOW_STOCK', 'EXHAUSTED'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_embroidery_thread_brand ON public.embroidery_thread_inventory(brand);
CREATE INDEX IF NOT EXISTS idx_embroidery_thread_shade ON public.embroidery_thread_inventory(shade_number);
CREATE INDEX IF NOT EXISTS idx_embroidery_thread_status ON public.embroidery_thread_inventory(status);

COMMENT ON TABLE public.embroidery_thread_inventory IS 'High-tenacity industrial embroidery thread cones tracking brand, Pantone shade and gram consumption.';
