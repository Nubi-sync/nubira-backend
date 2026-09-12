-- ==============================================================================
-- 08_cutting_seed_data.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Reference Lay Sheet, Fabric Rolls, Serialized Bundles & Verification Audit
-- ==============================================================================

DO $$
DECLARE
    v_order_id UUID;
    v_roll_1_id UUID;
    v_roll_2_id UUID;
    v_lay_sheet_id UUID;
    v_profile_id UUID;
    v_first_bundle_id UUID;
    v_bundle_count INTEGER := 0;
BEGIN
    -- 1. Resolve Reference Order (PO-ZIG-8901 - ART-HD-8821 Hoodie)
    SELECT id INTO v_order_id 
    FROM public.merchandising_orders 
    WHERE order_number = 'PO-ZIG-8901' 
    LIMIT 1;

    IF v_order_id IS NULL THEN
        SELECT id INTO v_order_id FROM public.merchandising_orders LIMIT 1;
    END IF;

    IF v_order_id IS NULL THEN
        RAISE NOTICE 'Skipping seed: No orders exist in merchandising_orders table.';
        RETURN;
    END IF;

    -- 2. Resolve Active User Profile for Operator / Inspector
    SELECT id INTO v_profile_id FROM public.profiles LIMIT 1;

    -- 3. Seed Certified Fabric Rolls in Central Store (Division 11 Inward Handshake)
    INSERT INTO public.store_fabric_rolls (
        roll_barcode,
        material_type,
        fabric_name,
        shade_group,
        dye_lot_number,
        gross_weight_kg,
        length_meters,
        usable_width_inches,
        inspection_points_score,
        status
    ) VALUES (
        'ROL-FT-8821-A1',
        'SHELL_FABRIC',
        'Heavyweight French Terry 380 GSM Combed Cotton',
        'SHADE_A',
        'LOT-2026-991',
        22.50,
        55.00,
        60.00,
        8,
        'ON_CUTTING_TABLE'
    ) ON CONFLICT (roll_barcode) DO UPDATE 
    SET status = 'ON_CUTTING_TABLE'
    RETURNING id INTO v_roll_1_id;

    INSERT INTO public.store_fabric_rolls (
        roll_barcode,
        material_type,
        fabric_name,
        shade_group,
        dye_lot_number,
        gross_weight_kg,
        length_meters,
        usable_width_inches,
        inspection_points_score,
        status
    ) VALUES (
        'ROL-FT-8821-A2',
        'SHELL_FABRIC',
        'Heavyweight French Terry 380 GSM Combed Cotton',
        'SHADE_A',
        'LOT-2026-991',
        22.80,
        55.00,
        60.00,
        12,
        'ON_CUTTING_TABLE'
    ) ON CONFLICT (roll_barcode) DO UPDATE 
    SET status = 'ON_CUTTING_TABLE'
    RETURNING id INTO v_roll_2_id;

    -- 4. Seed Reference Lay Sheet: LAY-2026-0842 (Table 01, 80 Plies, Ratio Total = 10, 800 Cut Pieces)
    INSERT INTO public.cutting_lay_sheets (
        lay_sheet_number,
        order_id,
        cutting_table_id,
        marker_length_m,
        total_plies,
        size_ratio_text,
        ratio_total,
        expected_pieces,
        actual_cut_pieces,
        spreading_operator_id,
        cutting_master_id,
        status,
        notes
    ) VALUES (
        'LAY-2026-0842',
        v_order_id,
        'TABLE_01',
        5.40,
        80,
        'XS:1, S:2, M:4, L:2, XL:1',
        10,
        800,
        800,
        v_profile_id,
        v_profile_id,
        'COMPLETED',
        'Bulk body cut for PO-ZIG-8901. French Terry 380 GSM, Jet Black. Precision straight-knife cut.'
    ) ON CONFLICT (lay_sheet_number) DO UPDATE
    SET 
        expected_pieces = 800,
        actual_cut_pieces = 800,
        status = 'COMPLETED'
    RETURNING id INTO v_lay_sheet_id;

    -- 5. Seed Fabric Rolls Junction (Lay Sheet Allocation)
    DELETE FROM public.cutting_lay_rolls WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_lay_rolls (lay_sheet_id, roll_id, plies_from_roll, meters_consumed, remnant_length_m)
    VALUES 
        (v_lay_sheet_id, v_roll_1_id, 40, 216.00, 1.20),
        (v_lay_sheet_id, v_roll_2_id, 40, 216.00, 0.85);

    -- 6. Generate 32 Serialized Component Bundles (The Root Seed Table)
    DELETE FROM public.cutting_bundles WHERE lay_sheet_id = v_lay_sheet_id;

    -- XS: 80 Pcs (4 Bundles: 3x25 + 1x5)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-XS-001', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-002', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-003', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XS-004', v_lay_sheet_id, v_order_id, 'XS', 'Jet Black', 4, 5, 76, 80, 'CUTTING', 'CUT_COMPLETED');

    -- S: 160 Pcs (7 Bundles: 6x25 + 1x10)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-S-001', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-002', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-003', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-004', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-005', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-006', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-S-007', v_lay_sheet_id, v_order_id, 'S', 'Jet Black', 7, 10, 151, 160, 'CUTTING', 'CUT_COMPLETED');

    -- M: 320 Pcs (13 Bundles: 12x25 + 1x20)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-M-001', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-002', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-003', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-004', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-005', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-006', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-007', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 7, 25, 151, 175, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-008', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 8, 25, 176, 200, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-009', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 9, 25, 201, 225, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-010', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 10, 25, 226, 250, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-011', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 11, 25, 251, 275, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-012', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 12, 25, 276, 300, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-M-013', v_lay_sheet_id, v_order_id, 'M', 'Jet Black', 13, 20, 301, 320, 'CUTTING', 'CUT_COMPLETED');

    -- L: 160 Pcs (7 Bundles: 6x25 + 1x10)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-L-001', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-002', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-003', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-004', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 4, 25, 76, 100, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-005', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 5, 25, 101, 125, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-006', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 6, 25, 126, 150, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-L-007', v_lay_sheet_id, v_order_id, 'L', 'Jet Black', 7, 10, 151, 160, 'CUTTING', 'CUT_COMPLETED');

    -- XL: 80 Pcs (4 Bundles: 3x25 + 1x5)
    INSERT INTO public.cutting_bundles (bundle_barcode, lay_sheet_id, order_id, size_label, color_name, bundle_sequence, piece_count, start_ply_num, end_ply_num, current_division, status) VALUES
        ('BND-0842-XL-001', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 1, 25, 1, 25, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-002', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 2, 25, 26, 50, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-003', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 3, 25, 51, 75, 'CUTTING', 'CUT_COMPLETED'),
        ('BND-0842-XL-004', v_lay_sheet_id, v_order_id, 'XL', 'Jet Black', 4, 5, 76, 80, 'CUTTING', 'CUT_COMPLETED');

    SELECT id INTO v_first_bundle_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-M-001' LIMIT 1;

    -- 7. Seed Precision Cut Panel QC Audit (PASS)
    DELETE FROM public.cutting_panel_qc_audits WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_panel_qc_audits (
        lay_sheet_id,
        bundle_id,
        inspector_id,
        notch_accuracy_mm,
        ply_deflection_mm,
        shade_continuity_pass,
        template_match_pass,
        qc_verdict,
        audit_notes
    ) VALUES (
        v_lay_sheet_id,
        v_first_bundle_id,
        v_profile_id,
        0.45,
        0.60,
        true,
        true,
        'PASS',
        'Top and bottom plies verified against acrylic template. Notch precision within 0.5mm. Zero blade heat fusion.'
    );

    -- 8. Seed Remnant End-Bit Conservation Log (Fabric Leakage Control)
    DELETE FROM public.cutting_end_bit_logs WHERE lay_sheet_id = v_lay_sheet_id;
    INSERT INTO public.cutting_end_bit_logs (
        lay_sheet_id,
        roll_id,
        remnant_weight_kg,
        remnant_length_m,
        disposition,
        logged_by,
        notes
    ) VALUES (
        v_lay_sheet_id,
        v_roll_1_id,
        0.48,
        1.20,
        'POCKETING_SALVAGE',
        v_profile_id,
        'End-bit salvaged for internal hood lining and pocket welts.'
    );

    RAISE NOTICE 'Division 03 Cutting Floor seed completed successfully: LAY-2026-0842 (800 Pcs, 32 Bundles) linked to PO-ZIG-8901.';
END $$;

-- 9. Verification Query
SELECT 
    cls.lay_sheet_number,
    cls.cutting_table_id,
    mo.order_number,
    mo.currency,
    cls.total_plies,
    cls.size_ratio_text,
    cls.expected_pieces,
    cls.actual_cut_pieces,
    cls.status,
    COUNT(cb.id) as total_bundles_generated,
    SUM(cb.piece_count) as total_bundled_pieces
FROM public.cutting_lay_sheets cls
JOIN public.merchandising_orders mo ON mo.id = cls.order_id
LEFT JOIN public.cutting_bundles cb ON cb.lay_sheet_id = cls.id
WHERE cls.lay_sheet_number = 'LAY-2026-0842'
GROUP BY cls.id, cls.lay_sheet_number, cls.cutting_table_id, mo.order_number, mo.currency, cls.total_plies, cls.size_ratio_text, cls.expected_pieces, cls.actual_cut_pieces, cls.status;
