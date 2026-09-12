-- ==============================================================================
-- 00_merchandising_all_in_one.sql
-- Division 02: Merchandising & Sourcing Desk (Complete All-in-One Migration)
-- ==============================================================================

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 01_merchandising_orders.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 01_merchandising_orders.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Master Buyer Purchase Orders & Size/Color Breakdown Matrix
-- ==============================================================================

-- 1. Buyer Purchase Orders (Master Commercial Contract)
CREATE TABLE IF NOT EXISTS public.merchandising_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'PO-ZIG-8901'
    buyer_id UUID NOT NULL REFERENCES public.brands(id) ON DELETE RESTRICT,
    tech_pack_id UUID NOT NULL REFERENCES public.design_tech_packs(id) ON DELETE RESTRICT,
    season VARCHAR(32) NOT NULL, -- e.g. 'SS27', 'AW27'
    total_quantity INTEGER NOT NULL CHECK (total_quantity > 0),
    fob_price_per_piece NUMERIC(10,2) NOT NULL CHECK (fob_price_per_piece >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    order_date DATE DEFAULT CURRENT_DATE,
    ex_factory_date DATE NOT NULL,
    incoterm VARCHAR(10) DEFAULT 'FOB', -- 'FOB', 'CIF', 'EXW', 'DDP'
    status VARCHAR(32) DEFAULT 'CONFIRMED', -- 'PENDING_COSTING', 'CONFIRMED', 'IN_PRODUCTION', 'SHIPPED', 'CANCELLED'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_merch_orders_buyer ON public.merchandising_orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_merch_orders_tech_pack ON public.merchandising_orders(tech_pack_id);
CREATE INDEX IF NOT EXISTS idx_merch_orders_status ON public.merchandising_orders(status);
CREATE INDEX IF NOT EXISTS idx_merch_orders_ex_factory ON public.merchandising_orders(ex_factory_date);

-- 2. Size & Color Breakdown Ratio
CREATE TABLE IF NOT EXISTS public.merchandising_order_ratios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    color_name VARCHAR(50) NOT NULL,
    color_code VARCHAR(30), -- Pantone / Hex
    size_label VARCHAR(20) NOT NULL, -- 'XS', 'S', 'M', 'L', 'XL', '2XL'
    ratio_units INTEGER NOT NULL DEFAULT 1 CHECK (ratio_units >= 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, color_name, size_label)
);

CREATE INDEX IF NOT EXISTS idx_order_ratios_order ON public.merchandising_order_ratios(order_id);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 02_merchandising_bom_costings.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 02_merchandising_bom_costings.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Double-Entry Bill of Materials (BOM) Costing Ledger & Variance Engine
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_bom_costings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    item_category VARCHAR(32) NOT NULL, -- 'SHELL_FABRIC', 'RIB_KNIT', 'SEWING_THREAD', 'ZIPPER', 'BUTTONS', 'LABELS', 'PACKAGING', 'ACCESSORY'
    item_name VARCHAR(128) NOT NULL,
    supplier_vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
    consumption_per_pc NUMERIC(8,4) NOT NULL CHECK (consumption_per_pc > 0), -- e.g. 1.3500 kg or 1.0000 pc
    unit_of_measure VARCHAR(20) NOT NULL, -- 'KG', 'METER', 'PIECE', 'CONE', 'GROSS', 'SET'
    planned_rate_per_unit NUMERIC(10,2) NOT NULL CHECK (planned_rate_per_unit >= 0),
    planned_cost_per_pc NUMERIC(10,2) NOT NULL CHECK (planned_cost_per_pc >= 0),
    actual_cost_per_pc NUMERIC(10,2) CHECK (actual_cost_per_pc >= 0),
    variance_amount NUMERIC(10,2) GENERATED ALWAYS AS (actual_cost_per_pc - planned_cost_per_pc) STORED,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_bom_costing_order ON public.merchandising_bom_costings(order_id);
CREATE INDEX IF NOT EXISTS idx_bom_costing_category ON public.merchandising_bom_costings(item_category);
CREATE INDEX IF NOT EXISTS idx_bom_costing_vendor ON public.merchandising_bom_costings(supplier_vendor_id);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 03_merchandising_tna_milestones.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 03_merchandising_tna_milestones.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Dynamic Time & Action (T&A) 8-Gate Critical Path Milestones
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_tna_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    gate_name VARCHAR(64) NOT NULL, 
    -- Standard Industrial Gates:
    -- 1. 'LAB_DIP_APPROVAL'
    -- 2. 'FABRIC_INWARD'
    -- 3. 'PPS_APPROVAL'
    -- 4. 'CUTTING_START'
    -- 5. 'SEWING_COMPLETE'
    -- 6. 'WASHING_COMPLETE'
    -- 7. 'FINAL_AQL_AUDIT'
    -- 8. 'EX_FACTORY'
    target_date DATE NOT NULL,
    actual_date DATE,
    lead_time_days INTEGER NOT NULL CHECK (lead_time_days >= 0),
    status VARCHAR(20) DEFAULT 'ON_TRACK' CHECK (status IN ('PENDING', 'ON_TRACK', 'DELAYED', 'COMPLETED')),
    responsible_role VARCHAR(32) NOT NULL, -- 'MERCHANDISER', 'STORE_HEAD', 'DESIGN_STUDIO', 'CUTTING_MASTER', 'STITCHING_HEAD', 'WASHING_SUPERVISOR', 'QA_MANAGER', 'EXPORT_COORDINATOR'
    delay_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, gate_name)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_tna_order ON public.merchandising_tna_milestones(order_id);
CREATE INDEX IF NOT EXISTS idx_tna_target_date ON public.merchandising_tna_milestones(target_date);
CREATE INDEX IF NOT EXISTS idx_tna_status ON public.merchandising_tna_milestones(status);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 04_merchandising_sourcing_requisitions.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 04_merchandising_sourcing_requisitions.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Raw Material Purchase Requisitions (PR) & Central Store Handshake
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_sourcing_requisitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pr_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'PR-2026-041'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
    category VARCHAR(32) NOT NULL CHECK (category IN ('FABRIC', 'TRIMS', 'YARN', 'CARTONS', 'PACKAGING', 'ACCESSORY')),
    item_description TEXT NOT NULL,
    required_quantity NUMERIC(12,2) NOT NULL CHECK (required_quantity > 0),
    uom VARCHAR(20) NOT NULL, -- 'KG', 'METER', 'PIECE', 'CONE', 'GROSS'
    required_in_house_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'PO_ISSUED', 'RECEIVED_STORE', 'CANCELLED')),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_order ON public.merchandising_sourcing_requisitions(order_id);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_vendor ON public.merchandising_sourcing_requisitions(vendor_id);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_status ON public.merchandising_sourcing_requisitions(status);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_in_house_date ON public.merchandising_sourcing_requisitions(required_in_house_date);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 05_merchandising_shipments.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 05_merchandising_shipments.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Export Ocean Container Logistics & Bill of Lading (B/L) Tracking
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_ref VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'SHP-ZIG-2026-09'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    container_number VARCHAR(30), -- e.g. 'MSKU-892182-1'
    container_type VARCHAR(20) DEFAULT '40_HIGH_CUBE' CHECK (container_type IN ('20_STANDARD', '40_STANDARD', '40_HIGH_CUBE', 'LCL_PALLET')),
    forwarder_name VARCHAR(100) NOT NULL, -- e.g. 'Maersk Line Logistics', 'Kuehne+Nagel'
    bill_of_lading_no VARCHAR(50), -- e.g. 'BL-MAEU-992102'
    total_cartons INTEGER NOT NULL CHECK (total_cartons > 0),
    total_gross_weight_kg NUMERIC(10,2) NOT NULL CHECK (total_gross_weight_kg > 0),
    total_cbm NUMERIC(8,3) NOT NULL CHECK (total_cbm > 0),
    port_of_loading VARCHAR(50) DEFAULT 'JNPT Mumbai',
    port_of_discharge VARCHAR(50) NOT NULL,
    etd_date DATE NOT NULL,
    eta_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'BOOKED' CHECK (status IN ('BOOKED', 'CONTAINER_STUFFED', 'CUSTOMS_CLEARED', 'ON_VESSEL', 'DELIVERED', 'CANCELLED')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_shipments_order ON public.merchandising_shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_shipments_status ON public.merchandising_shipments(status);
CREATE INDEX IF NOT EXISTS idx_shipments_etd ON public.merchandising_shipments(etd_date);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 06_merchandising_triggers_and_functions.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 06_merchandising_triggers_and_functions.sql
-- Division 02: Merchandising & Sourcing Desk
-- Logic: Automated 8-Gate T&A Calendar Generator & Financial Analytics View
-- ==============================================================================

-- 1. Trigger Function: Automatically Generate 8-Gate T&A Calendar Backwards from Ex-Factory Date
CREATE OR REPLACE FUNCTION public.fn_auto_generate_tna_schedule()
RETURNS TRIGGER AS $$
DECLARE
    v_ex_factory DATE;
BEGIN
    v_ex_factory := NEW.ex_factory_date;

    -- Gate 1: EX_FACTORY (Lead offset 0 days)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'EX_FACTORY', v_ex_factory, 0, 'ON_TRACK', 'EXPORT_COORDINATOR'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 2: FINAL_AQL_AUDIT (Lead offset 4 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'FINAL_AQL_AUDIT', v_ex_factory - INTERVAL '4 days', 4, 'ON_TRACK', 'QA_MANAGER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 3: WASHING_COMPLETE (Lead offset 9 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'WASHING_COMPLETE', v_ex_factory - INTERVAL '9 days', 9, 'ON_TRACK', 'WASHING_SUPERVISOR'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 4: SEWING_COMPLETE (Lead offset 14 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'SEWING_COMPLETE', v_ex_factory - INTERVAL '14 days', 14, 'ON_TRACK', 'STITCHING_HEAD'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 5: CUTTING_START (Lead offset 24 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'CUTTING_START', v_ex_factory - INTERVAL '24 days', 24, 'ON_TRACK', 'CUTTING_MASTER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 6: PPS_APPROVAL (Lead offset 28 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'PPS_APPROVAL', v_ex_factory - INTERVAL '28 days', 28, 'ON_TRACK', 'DESIGN_STUDIO'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 7: FABRIC_INWARD (Lead offset 35 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'FABRIC_INWARD', v_ex_factory - INTERVAL '35 days', 35, 'ON_TRACK', 'STORE_HEAD'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 8: LAB_DIP_APPROVAL (Lead offset 45 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'LAB_DIP_APPROVAL', v_ex_factory - INTERVAL '45 days', 45, 'ON_TRACK', 'MERCHANDISER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_generate_tna ON public.merchandising_orders;

CREATE TRIGGER trg_auto_generate_tna
    AFTER INSERT ON public.merchandising_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_auto_generate_tna_schedule();


-- 2. Trigger Function: Update Order Status on Key Milestone Completion
CREATE OR REPLACE FUNCTION public.fn_sync_milestone_to_order_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If EX_FACTORY is completed, advance Order to SHIPPED
    IF NEW.gate_name = 'EX_FACTORY' AND NEW.status = 'COMPLETED' THEN
        UPDATE public.merchandising_orders
        SET status = 'SHIPPED', updated_at = NOW()
        WHERE id = NEW.order_id AND status != 'SHIPPED';
    END IF;

    -- If CUTTING_START is completed, advance Order to IN_PRODUCTION
    IF NEW.gate_name = 'CUTTING_START' AND NEW.status = 'COMPLETED' THEN
        UPDATE public.merchandising_orders
        SET status = 'IN_PRODUCTION', updated_at = NOW()
        WHERE id = NEW.order_id AND status = 'CONFIRMED';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_milestone_status ON public.merchandising_tna_milestones;

CREATE TRIGGER trg_sync_milestone_status
    AFTER UPDATE OF status ON public.merchandising_tna_milestones
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_sync_milestone_to_order_status();


-- 3. Comprehensive Financial Analytics View for Merchandising Orders
CREATE OR REPLACE VIEW public.view_merchandising_order_economics AS
SELECT 
    o.id AS order_id,
    o.order_number,
    b.brand_name AS buyer_name,
    tp.style_number,
    tp.category AS garment_silhouette,
    o.season,
    o.total_quantity,
    o.fob_price_per_piece,
    o.currency,
    o.ex_factory_date,
    o.status AS order_status,
    ROUND((o.total_quantity * o.fob_price_per_piece), 2) AS total_contract_value,
    COALESCE(ROUND(SUM(c.planned_cost_per_pc), 2), 0.00) AS total_bom_cost_per_pc,
    COALESCE(ROUND(SUM(c.actual_cost_per_pc), 2), 0.00) AS actual_bom_cost_per_pc,
    -- Estimated Cut & Make (CM) + Embellishment overheads (approx 18% of FOB)
    ROUND(o.fob_price_per_piece * 0.18, 2) AS estimated_cm_overhead_per_pc,
    -- Total Garment Landed Cost
    ROUND(COALESCE(SUM(c.planned_cost_per_pc), 0.00) + (o.fob_price_per_piece * 0.18), 2) AS total_garment_cost,
    -- Gross Profit Margin %
    CASE 
        WHEN o.fob_price_per_piece > 0 THEN
            ROUND((
                (o.fob_price_per_piece - (COALESCE(SUM(c.planned_cost_per_pc), 0.00) + (o.fob_price_per_piece * 0.18))) 
                / o.fob_price_per_piece * 100
            ), 2)
        ELSE 0.00
    END AS gross_profit_margin_pct
FROM public.merchandising_orders o
JOIN public.brands b ON o.buyer_id = b.id
JOIN public.design_tech_packs tp ON o.tech_pack_id = tp.id
LEFT JOIN public.merchandising_bom_costings c ON o.id = c.order_id
GROUP BY o.id, o.order_number, b.brand_name, tp.style_number, tp.category, o.season, o.total_quantity, o.fob_price_per_piece, o.currency, o.ex_factory_date, o.status;


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 07_merchandising_rls_policies.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 07_merchandising_rls_policies.sql
-- Division 02: Merchandising & Sourcing Desk
-- Security: Row Level Security (RLS) Policies & Access Roles
-- ==============================================================================

-- 1. Enable RLS on all Division 02 tables
ALTER TABLE public.merchandising_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_order_ratios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_bom_costings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_tna_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_sourcing_requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchandising_shipments ENABLE ROW LEVEL SECURITY;

-- 2. Service Role Policies (Unrestricted Backend Worker / Server Actions Access)
DROP POLICY IF EXISTS "Service role full access on merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Service role full access on merchandising_orders"
    ON public.merchandising_orders FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Service role full access on merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Service role full access on merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Service role full access on merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Service role full access on merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Service role full access on merchandising_shipments"
    ON public.merchandising_shipments FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. Authenticated Factory Staff Policies (Read & Operational Updates)
DROP POLICY IF EXISTS "Authenticated users can view merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Authenticated users can view merchandising_orders"
    ON public.merchandising_orders FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_orders" ON public.merchandising_orders;
CREATE POLICY "Authenticated users can insert/update merchandising_orders"
    ON public.merchandising_orders FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Authenticated users can view merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_order_ratios" ON public.merchandising_order_ratios;
CREATE POLICY "Authenticated users can insert/update merchandising_order_ratios"
    ON public.merchandising_order_ratios FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Authenticated users can view merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_bom_costings" ON public.merchandising_bom_costings;
CREATE POLICY "Authenticated users can insert/update merchandising_bom_costings"
    ON public.merchandising_bom_costings FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Authenticated users can view merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can update merchandising_tna_milestones" ON public.merchandising_tna_milestones;
CREATE POLICY "Authenticated users can update merchandising_tna_milestones"
    ON public.merchandising_tna_milestones FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Authenticated users can view merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_sourcing_requisitions" ON public.merchandising_sourcing_requisitions;
CREATE POLICY "Authenticated users can insert/update merchandising_sourcing_requisitions"
    ON public.merchandising_sourcing_requisitions FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Authenticated users can view merchandising_shipments"
    ON public.merchandising_shipments FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert/update merchandising_shipments" ON public.merchandising_shipments;
CREATE POLICY "Authenticated users can insert/update merchandising_shipments"
    ON public.merchandising_shipments FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: 08_merchandising_seed_data.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ==============================================================================
-- 08_merchandising_seed_data.sql
-- Division 02: Merchandising & Sourcing Desk
-- Seed: Reference Order PO-ZIG-8901 (linked to ART-HD-8821), BOM, T&A, PR & Shipment
-- ==============================================================================

DO $$
DECLARE
    v_buyer_id UUID;
    v_tech_pack_id UUID;
    v_vendor_id UUID;
    v_order_id UUID;
    v_ex_factory DATE;
BEGIN
    -- 1. Resolve Buyer Brand (OLLYPOP or first active brand)
    SELECT id INTO v_buyer_id FROM public.brands WHERE brand_name = 'OLLYPOP' LIMIT 1;
    IF v_buyer_id IS NULL THEN
        SELECT id INTO v_buyer_id FROM public.brands LIMIT 1;
    END IF;

    -- 2. Resolve Tech-Pack (ART-HD-8821 Hoodie or first tech pack)
    SELECT id INTO v_tech_pack_id FROM public.design_tech_packs WHERE style_number = 'ART-HD-8821' LIMIT 1;
    IF v_tech_pack_id IS NULL THEN
        SELECT id INTO v_tech_pack_id FROM public.design_tech_packs LIMIT 1;
    END IF;

    -- 3. Resolve Vendor (In-House Stitching or first vendor)
    SELECT id INTO v_vendor_id FROM public.vendors WHERE vendor_code = 'OP-INHOUSE' LIMIT 1;
    IF v_vendor_id IS NULL THEN
        SELECT id INTO v_vendor_id FROM public.vendors LIMIT 1;
    END IF;

    IF v_buyer_id IS NULL OR v_tech_pack_id IS NULL THEN
        RAISE EXCEPTION 'Prerequisite brands or design_tech_packs missing. Ensure Division 01 seed data is applied.';
    END IF;

    v_ex_factory := CURRENT_DATE + INTERVAL '45 days';

    -- 4. Insert Master Commercial Order (PO-ZIG-8901)
    INSERT INTO public.merchandising_orders (
        order_number,
        buyer_id,
        tech_pack_id,
        season,
        total_quantity,
        fob_price_per_piece,
        currency,
        order_date,
        ex_factory_date,
        incoterm,
        status,
        notes
    ) VALUES (
        'PO-ZIG-8901',
        v_buyer_id,
        v_tech_pack_id,
        'SS27',
        5000,
        18.50,
        'USD',
        CURRENT_DATE,
        v_ex_factory,
        'FOB',
        'CONFIRMED',
        'Export order for Zara Men Global / Ollypop Premium Heavyweight Hoodie collection.'
    ) ON CONFLICT (order_number) DO UPDATE 
    SET 
        total_quantity = EXCLUDED.total_quantity,
        fob_price_per_piece = EXCLUDED.fob_price_per_piece,
        ex_factory_date = EXCLUDED.ex_factory_date,
        status = 'CONFIRMED'
    RETURNING id INTO v_order_id;

    -- 5. Insert Size & Color Breakdown Ratio (5,000 Pcs total)
    -- Jet Black (2,500 Pcs)
    INSERT INTO public.merchandising_order_ratios (order_id, color_name, color_code, size_label, ratio_units, quantity)
    VALUES
        (v_order_id, 'Jet Black', '#0A0A0A', 'XS', 1, 250),
        (v_order_id, 'Jet Black', '#0A0A0A', 'S', 2, 500),
        (v_order_id, 'Jet Black', '#0A0A0A', 'M', 4, 1000),
        (v_order_id, 'Jet Black', '#0A0A0A', 'L', 2, 500),
        (v_order_id, 'Jet Black', '#0A0A0A', 'XL', 1, 200),
        (v_order_id, 'Jet Black', '#0A0A0A', '2XL', 1, 50),
    -- Heather Grey (2,500 Pcs)
        (v_order_id, 'Heather Grey', '#8A8D8F', 'XS', 1, 250),
        (v_order_id, 'Heather Grey', '#8A8D8F', 'S', 2, 500),
        (v_order_id, 'Heather Grey', '#8A8D8F', 'M', 4, 1000),
        (v_order_id, 'Heather Grey', '#8A8D8F', 'L', 2, 500),
        (v_order_id, 'Heather Grey', '#8A8D8F', 'XL', 1, 200),
        (v_order_id, 'Heather Grey', '#8A8D8F', '2XL', 1, 50)
    ON CONFLICT (order_id, color_name, size_label) DO UPDATE
    SET quantity = EXCLUDED.quantity, ratio_units = EXCLUDED.ratio_units;

    -- 6. Insert Bill of Materials (BOM) Costing Ledger
    DELETE FROM public.merchandising_bom_costings WHERE order_id = v_order_id;

    INSERT INTO public.merchandising_bom_costings (
        order_id, item_category, item_name, supplier_vendor_id, consumption_per_pc, unit_of_measure, planned_rate_per_unit, planned_cost_per_pc, actual_cost_per_pc, notes
    ) VALUES
        (v_order_id, 'SHELL_FABRIC', 'Heavyweight French Terry 380 GSM Combed Cotton', v_vendor_id, 1.3500, 'KG', 6.80, 9.18, 9.10, '100% Cotton French Terry body fabric'),
        (v_order_id, 'RIB_KNIT', '2x2 Lycra Rib 420 GSM Tone-on-Tone', v_vendor_id, 0.2500, 'KG', 5.60, 1.40, 1.40, 'Hem & cuff ribbing'),
        (v_order_id, 'SEWING_THREAD', '100% Spun Polyester 40/2 Filament Thread', NULL, 0.0500, 'CONE', 6.00, 0.30, 0.32, 'Thread consumption across chainstitch & overlock'),
        (v_order_id, 'ACCESSORY', 'Flat Tubular Cotton Hood Drawcord 120cm with Aglet', NULL, 1.0000, 'PIECE', 0.65, 0.65, 0.65, 'Pre-shrunk knitted drawcord'),
        (v_order_id, 'ACCESSORY', 'Gunmetal Matte Stainless Steel Eyelets #4', NULL, 2.0000, 'PIECE', 0.12, 0.24, 0.24, 'Corrosion-resistant hood eyelets'),
        (v_order_id, 'PACKAGING', 'Self-Adhesive Recycled Polybag 14x18 + Warning', NULL, 1.0000, 'PIECE', 0.35, 0.35, 0.35, 'Individual master pack garment fold');

    -- 7. Insert Sourcing Purchase Requisition (PR-2026-041)
    INSERT INTO public.merchandising_sourcing_requisitions (
        pr_number, order_id, vendor_id, category, item_description, required_quantity, uom, required_in_house_date, status, notes
    ) VALUES (
        'PR-2026-041',
        v_order_id,
        v_vendor_id,
        'FABRIC',
        'Bulk French Terry 380 GSM Yarn Dyed Knitted Fabric (6,750 KG for PO-ZIG-8901)',
        6750.00,
        'KG',
        CURRENT_DATE + INTERVAL '10 days',
        'SUBMITTED',
        'Urgent mill knitting requisition with 3% cutting allowance.'
    ) ON CONFLICT (pr_number) DO UPDATE
    SET required_quantity = EXCLUDED.required_quantity, status = 'SUBMITTED';

    -- 8. Insert Export Ocean Shipment Booking (SHP-ZIG-2026-09)
    INSERT INTO public.merchandising_shipments (
        shipment_ref,
        order_id,
        container_number,
        container_type,
        forwarder_name,
        bill_of_lading_no,
        total_cartons,
        total_gross_weight_kg,
        total_cbm,
        port_of_loading,
        port_of_discharge,
        etd_date,
        eta_date,
        status,
        notes
    ) VALUES (
        'SHP-ZIG-2026-09',
        v_order_id,
        'MSKU-892182-1',
        '40_HIGH_CUBE',
        'Maersk Line Logistics India',
        'BL-MAEU-992102-MUM',
        250,
        6500.00,
        54.000,
        'JNPT Mumbai, India',
        'Port of Rotterdam, Netherlands',
        v_ex_factory,
        v_ex_factory + INTERVAL '23 days',
        'BOOKED',
        'Direct 40ft HC ocean container booked. Awaiting final packing slip signoff.'
    ) ON CONFLICT (shipment_ref) DO UPDATE
    SET total_cartons = EXCLUDED.total_cartons, status = 'BOOKED';

END $$;

-- ==============================================================================
-- 9. Comprehensive Verification Query
-- ==============================================================================
SELECT 
    e.order_number,
    e.buyer_name,
    e.style_number,
    e.season,
    e.total_quantity,
    e.fob_price_per_piece,
    e.total_contract_value,
    e.total_bom_cost_per_pc,
    e.total_garment_cost,
    e.gross_profit_margin_pct,
    COUNT(DISTINCT r.id) AS total_color_size_ratios,
    COUNT(DISTINCT m.id) AS total_tna_milestones,
    COUNT(DISTINCT b.id) AS total_bom_items,
    COUNT(DISTINCT pr.id) AS total_sourcing_prs,
    COUNT(DISTINCT s.id) AS total_export_shipments
FROM public.view_merchandising_order_economics e
LEFT JOIN public.merchandising_order_ratios r ON e.order_id = r.order_id
LEFT JOIN public.merchandising_tna_milestones m ON e.order_id = m.order_id
LEFT JOIN public.merchandising_bom_costings b ON e.order_id = b.order_id
LEFT JOIN public.merchandising_sourcing_requisitions pr ON e.order_id = pr.order_id
LEFT JOIN public.merchandising_shipments s ON e.order_id = s.order_id
WHERE e.order_number = 'PO-ZIG-8901'
GROUP BY 
    e.order_number, e.buyer_name, e.style_number, e.season, e.total_quantity, 
    e.fob_price_per_piece, e.total_contract_value, e.total_bom_cost_per_pc, 
    e.total_garment_cost, e.gross_profit_margin_pct;


