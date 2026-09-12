-- ==============================================================================
-- 08_printing_seed_data.sql
-- Division 04: Screen & Digital Printing Unit
-- Factory Production Seed Data linked to PO-ZIG-8901 & Division 03 Bundles
-- ==============================================================================

DO $$
DECLARE
    v_order_id UUID;
    v_strike_off_id UUID;
    v_run_id UUID;
    v_bundle_1_id UUID;
    v_bundle_2_id UUID;
    v_bundle_3_id UUID;
    v_bundle_run_3_id UUID;
    v_admin_id UUID;
BEGIN
    -- 1. Locate Master Commercial Order PO-ZIG-8901
    SELECT id INTO v_order_id 
    FROM public.merchandising_orders 
    WHERE order_number = 'PO-ZIG-8901' 
    LIMIT 1;

    -- 2. Locate Admin Profile
    SELECT id INTO v_admin_id 
    FROM public.profiles 
    WHERE role = 'ADMIN' 
    LIMIT 1;

    IF v_order_id IS NOT NULL THEN
        -- 3. Seed Golden Strike-Off Approval
        INSERT INTO public.printing_strike_offs (
            strike_off_code,
            order_id,
            print_design_name,
            print_technique,
            pantone_codes,
            mesh_count,
            squeegee_durometer,
            spectro_delta_e,
            wash_fastness_rating,
            buyer_approved,
            approval_status,
            approved_by,
            approved_at,
            remarks
        ) VALUES (
            'SO-2026-0842',
            v_order_id,
            'OLLYPOP Core Chest Crest & Signature Sleeve Graphic',
            'PLASTISOL',
            ARRAY['19-4052 TCX', '11-0601 TCX'],
            160,
            75,
            0.38,
            4.5,
            TRUE,
            'APPROVED',
            'S. Mehra (Buyer Technical QA)',
            NOW() - INTERVAL '1 day',
            'Approved for bulk print. Excellent opacity and sharp edge resolution on 380 GSM French Terry.'
        )
        ON CONFLICT (strike_off_code) DO UPDATE 
        SET approval_status = 'APPROVED'
        RETURNING id INTO v_strike_off_id;

        -- 4. Seed Active Bulk Production Run
        INSERT INTO public.printing_production_runs (
            run_code,
            order_id,
            strike_off_id,
            printing_table_or_machine,
            operator_id,
            operator_name,
            oven_temperature_c,
            oven_dwell_seconds,
            stroke_speed_cpm,
            shift,
            status,
            started_at,
            notes
        ) VALUES (
            'PRN-2026-0842',
            v_order_id,
            v_strike_off_id,
            'Octopus Carousel 01 (12 Color Automatic)',
            v_admin_id,
            'R. Veeramani (Master Printer)',
            162.5,
            120,
            28,
            'DAY',
            'PRINTING',
            NOW() - INTERVAL '3 hours',
            'Production run executing high-density plastisol decoration on Jet Black hoodie panels.'
        )
        ON CONFLICT (run_code) DO UPDATE
        SET status = 'PRINTING'
        RETURNING id INTO v_run_id;

        -- 5. Locate Serialized Cut Bundles from Division 03
        SELECT id INTO v_bundle_1_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-XS-001' LIMIT 1;
        SELECT id INTO v_bundle_2_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-XS-002' LIMIT 1;
        SELECT id INTO v_bundle_3_id FROM public.cutting_bundles WHERE bundle_barcode = 'BND-0842-S-001' LIMIT 1;

        -- Ingest Bundle 1
        IF v_bundle_1_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (
                production_run_id,
                bundle_id,
                received_pieces,
                passed_pieces,
                rejected_pieces
            ) VALUES (
                v_run_id,
                v_bundle_1_id,
                25,
                25,
                0
            ) ON CONFLICT DO NOTHING;
        END IF;

        -- Ingest Bundle 2
        IF v_bundle_2_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (
                production_run_id,
                bundle_id,
                received_pieces,
                passed_pieces,
                rejected_pieces
            ) VALUES (
                v_run_id,
                v_bundle_2_id,
                25,
                25,
                0
            ) ON CONFLICT DO NOTHING;
        END IF;

        -- Ingest Bundle 3 with 1 Rejection
        IF v_bundle_3_id IS NOT NULL THEN
            INSERT INTO public.printing_bundle_runs (
                production_run_id,
                bundle_id,
                received_pieces,
                passed_pieces,
                rejected_pieces
            ) VALUES (
                v_run_id,
                v_bundle_3_id,
                25,
                24,
                1
            ) ON CONFLICT DO NOTHING
            RETURNING id INTO v_bundle_run_3_id;

            -- If inserted, log defect
            IF v_bundle_run_3_id IS NOT NULL THEN
                INSERT INTO public.printing_defect_logs (
                    bundle_run_id,
                    defect_type,
                    defect_count,
                    action_taken,
                    notes
                ) VALUES (
                    v_bundle_run_3_id,
                    'PINHOLE',
                    1,
                    'PANEL_RE_CUT_REQUESTED',
                    'Micro pinhole ink bleed near pocket notch. Panel quarantined and replacement requested from Cutting floor.'
                );
            END IF;
        END IF;

        -- 6. Seed Curing Oven Telemetry Log
        INSERT INTO public.printing_curing_oven_logs (
            log_code,
            oven_id,
            production_run_id,
            target_temp_c,
            probe_temp_c,
            dwell_time_seconds,
            conveyor_speed_mpm,
            wash_test_cycles,
            fastness_rating,
            auditor_id,
            auditor_name,
            status,
            notes
        ) VALUES (
            'OVEN-2026-0842',
            'Tunnel Dryer Conveyor 01',
            v_run_id,
            160.0,
            162.4,
            120,
            2.4,
            5,
            4.5,
            v_admin_id,
            'K. Balaji (QA Inspector)',
            'OPTIMAL',
            'Curing heat profile verified with optical pyrometer probe across 6 heating zones.'
        ) ON CONFLICT (log_code) DO NOTHING;

    END IF;
END $$;
