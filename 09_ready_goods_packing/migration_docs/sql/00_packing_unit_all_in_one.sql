-- ==============================================================================
-- 00_packing_unit_all_in_one.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Unified All-in-One Database Migration Script
-- ==============================================================================

-- 1. Master Export Cartons Table
CREATE TABLE IF NOT EXISTS public.ready_goods_cartons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_barcode VARCHAR(64) NOT NULL UNIQUE,
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    carton_sequence_num INTEGER NOT NULL DEFAULT 1,
    packing_type VARCHAR(30) DEFAULT 'SOLID_SIZE_SOLID_COLOR',
    total_pieces INTEGER NOT NULL CHECK (total_pieces > 0),
    gross_weight_kg NUMERIC(6,2) NOT NULL CHECK (gross_weight_kg > 0),
    tare_weight_kg NUMERIC(5,2) DEFAULT 0.85,
    length_cm NUMERIC(5,1) NOT NULL DEFAULT 60.0,
    width_cm NUMERIC(5,1) NOT NULL DEFAULT 40.0,
    height_cm NUMERIC(5,1) NOT NULL DEFAULT 30.0,
    cbm NUMERIC(6,4) GENERATED ALWAYS AS ((length_cm * width_cm * height_cm) / 1000000.0) STORED,
    status VARCHAR(32) DEFAULT 'PACKED',
    pack_operator_id UUID REFERENCES public.employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cartons_order ON public.ready_goods_cartons(order_id);
CREATE INDEX IF NOT EXISTS idx_cartons_barcode ON public.ready_goods_cartons(carton_barcode);
CREATE INDEX IF NOT EXISTS idx_cartons_status ON public.ready_goods_cartons(status);

-- 2. Carton-to-Bundle Cryptographic Join
CREATE TABLE IF NOT EXISTS public.ready_goods_carton_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    pieces_from_bundle INTEGER NOT NULL CHECK (pieces_from_bundle > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(carton_id, bundle_id)
);

CREATE INDEX IF NOT EXISTS idx_carton_bundles_carton ON public.ready_goods_carton_bundles(carton_id);
CREATE INDEX IF NOT EXISTS idx_carton_bundles_bundle ON public.ready_goods_carton_bundles(bundle_id);

-- 3. AQL Audit Log Table
CREATE TABLE IF NOT EXISTS public.ready_goods_aql_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    inspector_id UUID REFERENCES public.employees(id),
    inspection_level VARCHAR(20) DEFAULT 'NORMAL_LEVEL_II',
    sample_size INTEGER NOT NULL CHECK (sample_size > 0),
    critical_defects INTEGER NOT NULL DEFAULT 0,
    major_defects INTEGER NOT NULL DEFAULT 0,
    minor_defects INTEGER NOT NULL DEFAULT 0,
    max_allowed_critical INTEGER NOT NULL DEFAULT 0,
    max_allowed_major INTEGER NOT NULL DEFAULT 3,
    max_allowed_minor INTEGER NOT NULL DEFAULT 5,
    verdict VARCHAR(20) NOT NULL,
    audit_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_aql_audits_carton ON public.ready_goods_aql_audits(carton_id);
CREATE INDEX IF NOT EXISTS idx_aql_audits_verdict ON public.ready_goods_aql_audits(verdict);

-- 4. Triggers
CREATE OR REPLACE FUNCTION update_carton_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cartons_updated_at ON public.ready_goods_cartons;
CREATE TRIGGER trg_cartons_updated_at
BEFORE UPDATE ON public.ready_goods_cartons
FOR EACH ROW EXECUTE FUNCTION update_carton_timestamp();

CREATE OR REPLACE FUNCTION update_carton_status_from_aql()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.verdict = 'PASS' THEN
        UPDATE public.ready_goods_cartons
        SET status = 'AQL_AUDIT_PASSED', updated_at = NOW()
        WHERE id = NEW.carton_id;
    ELSE
        UPDATE public.ready_goods_cartons
        SET status = 'QUARANTINED_AQL_FAILED', updated_at = NOW()
        WHERE id = NEW.carton_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_carton_status_from_aql ON public.ready_goods_aql_audits;
CREATE TRIGGER trg_update_carton_status_from_aql
AFTER INSERT OR UPDATE ON public.ready_goods_aql_audits
FOR EACH ROW EXECUTE FUNCTION update_carton_status_from_aql();

-- 5. Row Level Security
ALTER TABLE public.ready_goods_cartons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_carton_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_aql_audits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_cartons_select ON public.ready_goods_cartons;
CREATE POLICY p_cartons_select ON public.ready_goods_cartons FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_cartons_insert ON public.ready_goods_cartons;
CREATE POLICY p_cartons_insert ON public.ready_goods_cartons FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_cartons_update ON public.ready_goods_cartons;
CREATE POLICY p_cartons_update ON public.ready_goods_cartons FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS p_carton_bundles_select ON public.ready_goods_carton_bundles;
CREATE POLICY p_carton_bundles_select ON public.ready_goods_carton_bundles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_carton_bundles_insert ON public.ready_goods_carton_bundles;
CREATE POLICY p_carton_bundles_insert ON public.ready_goods_carton_bundles FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS p_aql_audits_select ON public.ready_goods_aql_audits;
CREATE POLICY p_aql_audits_select ON public.ready_goods_aql_audits FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_aql_audits_insert ON public.ready_goods_aql_audits;
CREATE POLICY p_aql_audits_insert ON public.ready_goods_aql_audits FOR INSERT TO authenticated WITH CHECK (true);
