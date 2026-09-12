-- ==============================================================================
-- 01_ready_goods_cartons.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Table: public.ready_goods_cartons (Master Export Cartons & Volumetric CBM)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.ready_goods_cartons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_barcode VARCHAR(64) NOT NULL UNIQUE, -- e.g. 'CTN-2026-00124-M'
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    carton_sequence_num INTEGER NOT NULL DEFAULT 1,
    packing_type VARCHAR(30) DEFAULT 'SOLID_SIZE_SOLID_COLOR', -- 'SOLID_SIZE_SOLID_COLOR', 'RATIO_ASSORTED'
    total_pieces INTEGER NOT NULL CHECK (total_pieces > 0),
    gross_weight_kg NUMERIC(6,2) NOT NULL CHECK (gross_weight_kg > 0),
    tare_weight_kg NUMERIC(5,2) DEFAULT 0.85,
    length_cm NUMERIC(5,1) NOT NULL DEFAULT 60.0,
    width_cm NUMERIC(5,1) NOT NULL DEFAULT 40.0,
    height_cm NUMERIC(5,1) NOT NULL DEFAULT 30.0,
    cbm NUMERIC(6,4) GENERATED ALWAYS AS ((length_cm * width_cm * height_cm) / 1000000.0) STORED,
    status VARCHAR(32) DEFAULT 'PACKED', -- 'PACKED', 'AQL_AUDIT_PASSED', 'QUARANTINED_AQL_FAILED', 'TRANSFERRED_TO_STORE'
    pack_operator_id UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_cartons_order ON public.ready_goods_cartons(order_id);
CREATE INDEX IF NOT EXISTS idx_cartons_barcode ON public.ready_goods_cartons(carton_barcode);
CREATE INDEX IF NOT EXISTS idx_cartons_status ON public.ready_goods_cartons(status);

COMMENT ON TABLE public.ready_goods_cartons IS 'Master commercial export cartons with barcode serialization and automatic CBM cubic calculation.';
