-- ==============================================================================
-- 02_embroidery_machines.sql
-- Division 05: Multi-Head Embroidery Floor
-- Table: public.embroidery_machines (Physical Multi-Head Industrial Frames)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.embroidery_machines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    machine_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'TAJIMA-20-HEAD-01'
    brand VARCHAR(50) NOT NULL, -- 'TAJIMA', 'BARUDAN', 'SWF', 'HAPPY'
    head_count INTEGER NOT NULL CHECK (head_count IN (6, 12, 15, 18, 20, 24)),
    max_rpm INTEGER NOT NULL DEFAULT 1000,
    operational_rpm INTEGER NOT NULL DEFAULT 850,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_embroidery_machines_code ON public.embroidery_machines(machine_code);
CREATE INDEX IF NOT EXISTS idx_embroidery_machines_active ON public.embroidery_machines(is_active);

COMMENT ON TABLE public.embroidery_machines IS 'Physical multi-head computerized embroidery frames deployed on the factory floor.';
COMMENT ON COLUMN public.embroidery_machines.head_count IS 'Parallel head multiplier: 20-head frame embroiders 20 cut panels concurrently.';
