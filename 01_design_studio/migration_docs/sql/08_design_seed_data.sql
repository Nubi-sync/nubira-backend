-- ==============================================================================
-- ZIGZA MES — DIVISION 01: DESIGN & TECH-PACK STUDIO
-- MIGRATION SCRIPT 08: PRODUCTION SEED DATA (STANDARD FACTORY ARTICLES)
-- Target Engine: PostgreSQL 14+ / Supabase
-- ==============================================================================

DO $$
DECLARE
    v_brand_id UUID;
    v_tech_pack_id UUID;
    v_polo_id UUID;
    v_pom_chest UUID;
    v_pom_length UUID;
    v_pom_sleeve UUID;
    v_pom_neck UUID;
BEGIN
    -- 1. Obtain an existing active brand (or fallback)
    SELECT id INTO v_brand_id FROM public.brands WHERE is_active = TRUE LIMIT 1;
    
    IF v_brand_id IS NULL THEN
        -- If no brands exist yet, insert a default enterprise client brand
        INSERT INTO public.brands (name, code, is_active)
        VALUES ('Zara Global Corp', 'ZARA-01', TRUE)
        RETURNING id INTO v_brand_id;
    END IF;

    -- 2. Insert Standard Material Library Items
    INSERT INTO public.design_materials_library 
    (material_code, material_name, material_type, composition, nominal_gsm, usable_width_cm, length_shrinkage_pct, width_shrinkage_pct, spirality_pct, recommended_needle)
    VALUES
    ('FAB-FTERRY-380-BLK', 'Heavyweight French Terry Black', 'KNIT_FABRIC', '100% Combed Cotton', 380, 185.0, 4.20, 2.50, 1.80, 'Ball Point 75/11'),
    ('FAB-SJERSEY-180-WHT', 'Single Jersey Combed White', 'KNIT_FABRIC', '100% Ring Spun Cotton', 180, 175.0, 3.50, 2.00, 1.20, 'Ball Point 70/10'),
    ('RIB-2X2-420-BLK', '2x2 Heavy Cotton Rib Black', 'RIB_TRIM', '95% Cotton 5% Elastane', 420, 110.0, 5.00, 4.00, 0.50, 'Ball Point 80/12'),
    ('THR-POLY-120-BLK', 'A&E Perma Spun Polyester Thread', 'SEWING_THREAD', '100% Staple Spun Polyester', 120, 0.0, 0.50, 0.50, 0.00, 'Universal 75/11')
    ON CONFLICT (material_code) DO NOTHING;

    -- 3. Insert Master Tech Pack: Style ART-HD-8821 (Heavyweight Fleece Hoodie)
    INSERT INTO public.design_tech_packs 
    (style_number, brand_id, category, size_system, base_size, fabric_composition, target_gsm, embellishment_sequence, spi, seam_class, status, version, notes)
    VALUES
    ('ART-HD-8821', v_brand_id, 'HOODIE', 'ALPHA_ADULT', 'M', '100% Combed Cotton French Terry 380 GSM', 380, 'EMBROIDERY_FIRST_THEN_PRINT', 12, 'ISO 4915 Class 401', 'APPROVED_BULK', 1, 'Standard bulk export hoodie specification.')
    ON CONFLICT (brand_id, style_number, version) DO UPDATE SET status = 'APPROVED_BULK'
    RETURNING id INTO v_tech_pack_id;

    -- 4. Insert POMs for ART-HD-8821
    -- 4.1 Chest Width
    INSERT INTO public.design_poms (tech_pack_id, pom_code, pom_name, tolerance_cm, sort_order)
    VALUES (v_tech_pack_id, 'CHEST_WIDTH', 'Half Chest Width across armhole', 0.50, 1)
    ON CONFLICT (tech_pack_id, pom_code) DO UPDATE SET tolerance_cm = 0.50
    RETURNING id INTO v_pom_chest;

    -- 4.2 Body Length HPS
    INSERT INTO public.design_poms (tech_pack_id, pom_code, pom_name, tolerance_cm, sort_order)
    VALUES (v_tech_pack_id, 'BODY_LENGTH_HPS', 'Body Length from High Point Shoulder', 0.50, 2)
    ON CONFLICT (tech_pack_id, pom_code) DO UPDATE SET tolerance_cm = 0.50
    RETURNING id INTO v_pom_length;

    -- 4.3 Sleeve Length
    INSERT INTO public.design_poms (tech_pack_id, pom_code, pom_name, tolerance_cm, sort_order)
    VALUES (v_tech_pack_id, 'SLEEVE_LENGTH_CB', 'Sleeve Length from Center Back', 0.50, 3)
    ON CONFLICT (tech_pack_id, pom_code) DO UPDATE SET tolerance_cm = 0.50
    RETURNING id INTO v_pom_sleeve;

    -- 4.4 Neck Opening
    INSERT INTO public.design_poms (tech_pack_id, pom_code, pom_name, tolerance_cm, sort_order)
    VALUES (v_tech_pack_id, 'NECK_OPENING', 'Neck Opening Width Edge to Edge', 0.25, 4)
    ON CONFLICT (tech_pack_id, pom_code) DO UPDATE SET tolerance_cm = 0.25
    RETURNING id INTO v_pom_neck;

    -- 5. Insert Graded Values for ART-HD-8821 across XS, S, M, L, XL, 2XL
    -- Chest Values
    INSERT INTO public.design_measurement_values (pom_id, size_label, value_cm, grade_step_cm, is_base_size)
    VALUES 
    (v_pom_chest, 'XS', 48.00, -5.00, FALSE),
    (v_pom_chest, 'S',  50.50, -2.50, FALSE),
    (v_pom_chest, 'M',  53.00,  0.00, TRUE),
    (v_pom_chest, 'L',  55.50, +2.50, FALSE),
    (v_pom_chest, 'XL', 58.00, +5.00, FALSE),
    (v_pom_chest, '2XL',60.50, +7.50, FALSE)
    ON CONFLICT (pom_id, size_label) DO UPDATE SET value_cm = EXCLUDED.value_cm;

    -- Body Length Values
    INSERT INTO public.design_measurement_values (pom_id, size_label, value_cm, grade_step_cm, is_base_size)
    VALUES 
    (v_pom_length, 'XS', 68.00, -4.00, FALSE),
    (v_pom_length, 'S',  70.00, -2.00, FALSE),
    (v_pom_length, 'M',  72.00,  0.00, TRUE),
    (v_pom_length, 'L',  74.00, +2.00, FALSE),
    (v_pom_length, 'XL', 76.00, +4.00, FALSE),
    (v_pom_length, '2XL',78.00, +6.00, FALSE)
    ON CONFLICT (pom_id, size_label) DO UPDATE SET value_cm = EXCLUDED.value_cm;

    -- Sleeve Length Values
    INSERT INTO public.design_measurement_values (pom_id, size_label, value_cm, grade_step_cm, is_base_size)
    VALUES 
    (v_pom_sleeve, 'XS', 82.00, -5.00, FALSE),
    (v_pom_sleeve, 'S',  84.50, -2.50, FALSE),
    (v_pom_sleeve, 'M',  87.00,  0.00, TRUE),
    (v_pom_sleeve, 'L',  89.50, +2.50, FALSE),
    (v_pom_sleeve, 'XL', 92.00, +5.00, FALSE),
    (v_pom_sleeve, '2XL',94.50, +7.50, FALSE)
    ON CONFLICT (pom_id, size_label) DO UPDATE SET value_cm = EXCLUDED.value_cm;

    -- Neck Opening Values
    INSERT INTO public.design_measurement_values (pom_id, size_label, value_cm, grade_step_cm, is_base_size)
    VALUES 
    (v_pom_neck, 'XS', 17.50, -1.00, FALSE),
    (v_pom_neck, 'S',  18.00, -0.50, FALSE),
    (v_pom_neck, 'M',  18.50,  0.00, TRUE),
    (v_pom_neck, 'L',  19.00, +0.50, FALSE),
    (v_pom_neck, 'XL', 19.50, +1.00, FALSE),
    (v_pom_neck, '2XL',20.00, +1.50, FALSE)
    ON CONFLICT (pom_id, size_label) DO UPDATE SET value_cm = EXCLUDED.value_cm;

    -- 6. Insert Sample Audit Record for ART-HD-8821 (PPS Approved)
    INSERT INTO public.design_sample_audits 
    (tech_pack_id, sample_stage, measured_chest, measured_length, measured_sleeve, variance_max_cm, within_tolerance, fit_comments, buyer_reviewer_name, verdict, approved_at)
    VALUES 
    (v_tech_pack_id, 'PPS', 53.15, 72.10, 86.90, 0.15, TRUE, 'Golden seal approved by Zara QA. Clean collar construction, stitch balance perfect.', 'Marc Henderson (Zara Buying House)', 'APPROVED', NOW() - INTERVAL '1 DAY');

END $$;
