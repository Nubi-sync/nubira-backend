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
