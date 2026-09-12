-- ==============================================================================
-- 06_washing_seed_data.sql
-- Division 07: Industrial Washing & Wet Processing Plant
-- Standard Baseline Formulations & Factory Operational Seed Data
-- ==============================================================================

-- 1. Standard Technical Wash Recipes
INSERT INTO public.washing_recipes (
    id,
    recipe_code,
    wash_type,
    liquor_ratio,
    wash_temperature_c,
    cycle_time_minutes,
    chemical_recipe_json,
    ph_target
) VALUES 
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0123456789a1',
    'WSH-BIO-ENZYME-01',
    'BIO_ENZYME',
    '1:10',
    55,
    45,
    '[
        {"chemical_name": "Neutral Cellulase Enzyme", "dosing_g_per_l": 1.5},
        {"chemical_name": "Acetic Acid (Glacial)", "dosing_g_per_l": 0.8},
        {"chemical_name": "Non-Ionic Wetting Agent", "dosing_g_per_l": 0.5}
    ]'::jsonb,
    5.5
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0123456789a2',
    'WSH-SILICON-SOFT-02',
    'SILICON_SOFTENER',
    '1:8',
    40,
    30,
    '[
        {"chemical_name": "Micro-Emulsion Silicon Softener", "dosing_g_per_l": 2.5},
        {"chemical_name": "Cationic Softener Flakes", "dosing_g_per_l": 1.2}
    ]'::jsonb,
    6.0
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0123456789a3',
    'WSH-VINTAGE-STONE-03',
    'STONE_WASH',
    '1:12',
    60,
    60,
    '[
        {"chemical_name": "Pumice Stone Media (2-4cm)", "dosing_g_per_l": 50.0},
        {"chemical_name": "Acid Cellulase Concentrate", "dosing_g_per_l": 2.0},
        {"chemical_name": "Anti-Backstaining Polymer", "dosing_g_per_l": 1.0}
    ]'::jsonb,
    4.8
)
ON CONFLICT (recipe_code) DO NOTHING;

-- 2. Production Washing Batch linked to live PO-ZIG-8901
DO $$
DECLARE
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    SELECT id INTO v_order_id FROM public.merchandising_orders WHERE po_number = 'PO-ZIG-8901' LIMIT 1;

    IF v_order_id IS NOT NULL THEN
        INSERT INTO public.washing_batches (
            id,
            batch_number,
            order_id,
            recipe_id,
            machine_id,
            total_garments,
            dry_input_weight_kg,
            hydro_extracted_weight_kg,
            tumbler_dry_weight_kg,
            residual_moisture_percent,
            status,
            started_at
        ) VALUES (
            'b1c2d3e4-f5a6-4b5c-8d9e-1234567890b1',
            'WSH-BAT-2026-0841',
            v_order_id,
            'a1b2c3d4-e5f6-4a5b-8c9d-0123456789a1',
            'BELLY_WASHER_01',
            600,
            240.00,
            330.00,
            248.50,
            3.54,
            'COMPLETED',
            NOW() - INTERVAL '3 hours'
        )
        ON CONFLICT (batch_number) DO UPDATE SET updated_at = NOW()
        RETURNING id INTO v_batch_id;

        -- 3. Specimen Shrinkage Audit
        IF v_batch_id IS NOT NULL THEN
            INSERT INTO public.washing_shrinkage_alerts (
                batch_id,
                specimen_size,
                pre_wash_length_cm,
                post_wash_length_cm,
                pre_wash_width_cm,
                post_wash_width_cm,
                spirality_angle_deg,
                is_within_spec
            ) VALUES (
                v_batch_id,
                'L',
                72.00,
                71.10,
                56.00,
                55.40,
                0.50,
                true
            )
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;
