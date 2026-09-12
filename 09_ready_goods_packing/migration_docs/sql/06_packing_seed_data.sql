-- ==============================================================================
-- 06_packing_seed_data.sql
-- Division 09: Ready Goods & Export Packing Floor
-- Standard Operational Seed Data (Master Cartons, Bundle Links & AQL Audit)
-- ==============================================================================

DO $$
DECLARE
    v_order_id UUID;
    v_bundle_id UUID;
    v_carton_id UUID;
BEGIN
    -- 1. Locate existing PO-ZIG-8901 and a bundle from cutting
    SELECT id INTO v_order_id FROM public.merchandising_orders WHERE po_number = 'PO-ZIG-8901' LIMIT 1;
    SELECT id INTO v_bundle_id FROM public.cutting_bundles LIMIT 1;

    IF v_order_id IS NOT NULL THEN
        -- 2. Insert Master Export Carton
        INSERT INTO public.ready_goods_cartons (
            id,
            carton_barcode,
            order_id,
            carton_sequence_num,
            packing_type,
            total_pieces,
            gross_weight_kg,
            tare_weight_kg,
            length_cm,
            width_cm,
            height_cm,
            status
        ) VALUES (
            'd1e2f3a4-b5c6-4d7e-8f9a-0123456789d1',
            'CTN-2026-00841-M',
            v_order_id,
            1,
            'SOLID_SIZE_SOLID_COLOR',
            30,
            14.20,
            0.85,
            60.0,
            40.0,
            30.0,
            'AQL_AUDIT_PASSED'
        )
        ON CONFLICT (carton_barcode) DO UPDATE SET updated_at = NOW()
        RETURNING id INTO v_carton_id;

        -- 3. Link Carton to Cutting Bundle (Cryptographic Piece Enforcement)
        IF v_carton_id IS NOT NULL AND v_bundle_id IS NOT NULL THEN
            INSERT INTO public.ready_goods_carton_bundles (
                carton_id,
                bundle_id,
                pieces_from_bundle
            ) VALUES (
                v_carton_id,
                v_bundle_id,
                30
            )
            ON CONFLICT (carton_id, bundle_id) DO NOTHING;
        END IF;

        -- 4. Record Passed AQL 2.5 Audit
        IF v_carton_id IS NOT NULL THEN
            INSERT INTO public.ready_goods_aql_audits (
                carton_id,
                inspection_level,
                sample_size,
                critical_defects,
                major_defects,
                minor_defects,
                verdict,
                audit_notes
            ) VALUES (
                v_carton_id,
                'NORMAL_LEVEL_II',
                80,
                0,
                1,
                2,
                'PASS',
                'ANSI/ASQ Z1.4 Normal Level II Single Sampling Inspection Passed.'
            )
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;
