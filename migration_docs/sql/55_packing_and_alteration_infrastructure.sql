-- ============================================================================
-- 55_packing_and_alteration_infrastructure.sql
-- Zigza MES: Division 09 (Ready Goods Packing) & Division 10 (Alteration Clinic)
-- + Additive Stitching Bundle Traceability Handshake
-- PostgreSQL Infrastructure Migration
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ADDITIVE STITCHING BACKBONE LINK (ZERO REGRESSION)
-- ----------------------------------------------------------------------------
ALTER TABLE public.allotments 
ADD COLUMN IF NOT EXISTS bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_allotments_bundle_id ON public.allotments(bundle_id);

-- ----------------------------------------------------------------------------
-- 2. DIVISION 09: READY GOODS & EXPORT PACKING TABLES
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.ready_goods_cartons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_barcode VARCHAR(64) NOT NULL UNIQUE,
    order_id UUID REFERENCES public.merchandising_orders(id) ON DELETE SET NULL,
    carton_sequence_num INTEGER NOT NULL DEFAULT 1,
    packing_type VARCHAR(30) DEFAULT 'SOLID_SIZE_SOLID_COLOR',
    total_pieces INTEGER NOT NULL CHECK (total_pieces > 0),
    gross_weight_kg NUMERIC(6,2) NOT NULL DEFAULT 12.50,
    tare_weight_kg NUMERIC(5,2) DEFAULT 0.85,
    length_cm NUMERIC(5,1) NOT NULL DEFAULT 60.0,
    width_cm NUMERIC(5,1) NOT NULL DEFAULT 40.0,
    height_cm NUMERIC(5,1) NOT NULL DEFAULT 30.0,
    status VARCHAR(32) DEFAULT 'PACKED',
    pack_operator_id UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ready_goods_carton_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    bundle_id UUID NOT NULL REFERENCES public.cutting_bundles(id) ON DELETE RESTRICT,
    pieces_from_bundle INTEGER NOT NULL CHECK (pieces_from_bundle > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(carton_id, bundle_id)
);

CREATE TABLE IF NOT EXISTS public.ready_goods_aql_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carton_id UUID NOT NULL REFERENCES public.ready_goods_cartons(id) ON DELETE CASCADE,
    inspector_id UUID REFERENCES public.profiles(id),
    inspector_name VARCHAR(100) DEFAULT 'Certified Buyer QA',
    inspection_level VARCHAR(20) DEFAULT 'NORMAL_LEVEL_II',
    sample_size INTEGER NOT NULL CHECK (sample_size > 0),
    critical_defects INTEGER NOT NULL DEFAULT 0,
    major_defects INTEGER NOT NULL DEFAULT 0,
    minor_defects INTEGER NOT NULL DEFAULT 0,
    max_allowed_critical INTEGER NOT NULL DEFAULT 0,
    max_allowed_major INTEGER NOT NULL DEFAULT 3,
    max_allowed_minor INTEGER NOT NULL DEFAULT 5,
    verdict VARCHAR(20) NOT NULL DEFAULT 'PASS',
    audit_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cartons_order ON public.ready_goods_cartons(order_id);
CREATE INDEX IF NOT EXISTS idx_cartons_status ON public.ready_goods_cartons(status);

-- ----------------------------------------------------------------------------
-- 3. DIVISION 10: ALTERATION & QUALITY REWORK CLINIC TABLES
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.alteration_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(32) NOT NULL UNIQUE,
    allotment_id UUID REFERENCES public.allotments(id) ON DELETE SET NULL,
    bundle_id UUID REFERENCES public.cutting_bundles(id) ON DELETE SET NULL,
    defect_category VARCHAR(50) NOT NULL,
    defect_severity VARCHAR(20) DEFAULT 'MAJOR',
    original_tailor_id UUID REFERENCES public.profiles(id),
    repair_tailor_id UUID REFERENCES public.profiles(id),
    repair_tailor_name VARCHAR(100),
    pieces_received INTEGER NOT NULL CHECK (pieces_received > 0),
    pieces_repaired INTEGER DEFAULT 0,
    pieces_scrapped INTEGER DEFAULT 0,
    secondary_qc_inspector_id UUID REFERENCES public.profiles(id),
    status VARCHAR(30) DEFAULT 'INTAKE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.alteration_scrap_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.alteration_tickets(id) ON DELETE CASCADE,
    scrapped_pieces INTEGER NOT NULL CHECK (scrapped_pieces > 0),
    scrap_reason TEXT NOT NULL,
    fabric_weight_kg NUMERIC(6,2),
    estimated_financial_loss_inr NUMERIC(10,2) NOT NULL DEFAULT 0,
    authorized_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alter_tickets_allotment ON public.alteration_tickets(allotment_id);
CREATE INDEX IF NOT EXISTS idx_alter_tickets_status ON public.alteration_tickets(status);

-- Enable RLS
ALTER TABLE public.ready_goods_cartons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_carton_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ready_goods_aql_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alteration_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alteration_scrap_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Allow all access to authenticated users" ON public.ready_goods_cartons FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.ready_goods_carton_bundles FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.ready_goods_aql_audits FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.alteration_tickets FOR ALL TO authenticated USING (true);
    CREATE POLICY "Allow all access to authenticated users" ON public.alteration_scrap_logs FOR ALL TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
