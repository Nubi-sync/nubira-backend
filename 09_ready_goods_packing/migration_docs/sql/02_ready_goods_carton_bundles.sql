-- ==============================================================================
-- 02_ready_goods_carton_bundles.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Table: public.ready_goods_carton_bundles (Bundle-to-Carton Lineage Join)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ready_goods_carton_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    pieces_from_bundle INTEGER NOT NULL CHECK (pieces_from_bundle > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(carton_id, bundle_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_carton_bundles_carton ON public.ready_goods_carton_bundles(carton_id);
CREATE INDEX IF NOT EXISTS idx_carton_bundles_bundle ON public.ready_goods_carton_bundles(bundle_id);

COMMENT ON TABLE public.ready_goods_carton_bundles IS 'Enforces zero ghost pieces by mathematically joining packed cartons back to cutting floor serialized bundles.';
