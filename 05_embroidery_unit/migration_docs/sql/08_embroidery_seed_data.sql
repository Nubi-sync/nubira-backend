-- ==============================================================================
-- 08_embroidery_seed_data.sql
-- Division 05: Multi-Head Embroidery Floor
-- Factory Production Seed Data linked to PO-ZIG-8901 & Division 03 Bundles
-- ==============================================================================

DO $$
DECLARE
    v_order_id UUID;
    v_admin_id UUID;
    v_bundle_id UUID;
    v_tajima_id UUID;
    v_barudan_id UUID;
    v_swf_id UUID;
    v_design_id UUID;
    v_run_id UUID;
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

    -- 3. Locate Division 03 Serialized Cut Bundle
    SELECT id INTO v_bundle_id 
    FROM public.cutting_bundles 
    WHERE bundle_barcode = 'BND-0842-XS-001' 
    LIMIT 1;

    -- 4. Seed Physical Multi-Head Industrial Embroidery Machines
    INSERT INTO public.embroidery_machines (
        machine_code, brand, head_count, max_rpm, operational_rpm, is_active, notes
    ) VALUES 
        ('TAJIMA-20-HEAD-01', 'TAJIMA', 20, 1000, 850, TRUE, 'High-speed computerized 20-head frame for front chest logos.'),
        ('BARUDAN-15-HEAD-02', 'BARUDAN', 15, 1000, 850, TRUE, '15-head frame calibrated for heavy 380 GSM fleece appliques.'),
        ('SWF-12-HEAD-03', 'SWF', 12, 950, 800, TRUE, '12-head multi-head frame for sleeve badges & specialty puff.')
    ON CONFLICT (machine_code) DO UPDATE 
    SET is_active = EXCLUDED.is_active;

    SELECT id INTO v_tajima_id FROM public.embroidery_machines WHERE machine_code = 'TAJIMA-20-HEAD-01' LIMIT 1;
    SELECT id INTO v_barudan_id FROM public.embroidery_machines WHERE machine_code = 'BARUDAN-15-HEAD-02' LIMIT 1;
    SELECT id INTO v_swf_id FROM public.embroidery_machines WHERE machine_code = 'SWF-12-HEAD-03' LIMIT 1;

    -- 5. Seed Thread Cones Inventory
    INSERT INTO public.embroidery_thread_inventory (
        cone_code, brand, shade_number, pantone_match, thread_type, initial_weight_grams, current_weight_grams, cones_in_stock, storage_bin, status
    ) VALUES 
        ('THD-MAD-1142', 'Madeira', '1142', 'Pantone 19-4052 TCX (Classic Navy)', 'Polyester 40wt', 1000.0, 850.0, 12, 'Rack E-01 / Bin 04', 'IN_STOCK'),
        ('THD-MAD-1001', 'Madeira', '1001', 'Pantone 11-0601 TCX (Optical White)', 'Polyester 40wt', 1000.0, 920.0, 15, 'Rack E-01 / Bin 05', 'IN_STOCK'),
        ('THD-MAD-1224', 'Madeira', '1224', 'Pantone 14-0848 TCX (Mimosa Gold)', 'Polyester 40wt', 1000.0, 740.0, 8, 'Rack E-02 / Bin 01', 'IN_STOCK')
    ON CONFLICT (cone_code) DO NOTHING;

    -- 6. Seed Digitized Embroidery Master Punch Design
    IF v_order_id IS NOT NULL THEN
        INSERT INTO public.embroidery_designs (
            design_code,
            design_name,
            order_id,
            dst_file_url,
            total_stitches,
            color_change_count,
            width_mm,
            height_mm,
            rate_per_thousand_stitches,
            backing_type,
            needle_type,
            thread_brand,
            status,
            notes
        ) VALUES (
            'DST-OLLY-HD8821-CHEST',
            'OLLYPOP Bear Crest 3D Puff & Satin',
            v_order_id,
            'https://assets.zigzames.internal/emb/olly_hd8821_chest_v2.dst',
            22400,
            4,
            85.0,
            90.0,
            2.80,
            'TEARAWAY',
            'DBxK5_SES_75_11',
            'Madeira',
            'APPROVED',
            'Approved buyer punch for bulk production on 380 GSM French Terry.'
        )
        ON CONFLICT (design_code) DO UPDATE 
        SET status = 'APPROVED'
        RETURNING id INTO v_design_id;

        -- 7. Seed Active Production Run
        IF v_tajima_id IS NOT NULL AND v_design_id IS NOT NULL AND v_bundle_id IS NOT NULL THEN
            INSERT INTO public.embroidery_production_runs (
                run_number,
                machine_id,
                design_id,
                bundle_id,
                operator_id,
                operator_name,
                shift,
                run_cycles,
                panels_loaded,
                total_panels_completed,
                total_stitches_run,
                thread_breaks_count,
                needle_breakages,
                status,
                started_at,
                completed_at,
                notes
            ) VALUES (
                'EMB-RUN-2026-0842',
                v_tajima_id,
                v_design_id,
                v_bundle_id,
                v_admin_id,
                'P. Murugesan (Senior Embroidery Master)',
                'DAY',
                1,
                25,
                25,
                448000,
                1,
                0,
                'COMPLETED',
                NOW() - INTERVAL '4 hours',
                NOW() - INTERVAL '1 hour',
                'Batch 01 completed with clean jump trims and zero puckering.'
            )
            ON CONFLICT (run_number) DO UPDATE
            SET status = 'COMPLETED'
            RETURNING id INTO v_run_id;

            -- 8. Seed In-Line QC Audit
            IF v_run_id IS NOT NULL THEN
                INSERT INTO public.embroidery_qc_audits (
                    audit_code,
                    run_id,
                    head_number,
                    defect_type,
                    severity,
                    action_taken,
                    auditor_id,
                    auditor_name,
                    notes
                ) VALUES (
                    'EMB-QC-2026-001',
                    v_run_id,
                    4,
                    'JUMP_TRIM_STRAY',
                    'MINOR',
                    'TENSION_DISC_ADJUSTED',
                    v_admin_id,
                    'K. Balaji (QA Inspector)',
                    'Automatic movable trimmer knife cleaned; zero defects observed on subsequent cycle.'
                )
                ON CONFLICT (audit_code) DO NOTHING;
            END IF;
        END IF;
    END IF;
END $$;
