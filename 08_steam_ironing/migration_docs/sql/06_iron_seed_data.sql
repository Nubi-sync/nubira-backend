-- ==============================================================================
-- 06_iron_seed_data.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Standard Operational Seed Data (Vacuum Buck Tables & Pressing Logs)
-- ==============================================================================

-- 1. Standard 12 Vacuum Buck Pressing Tables
INSERT INTO public.iron_tables (table_code, table_type, operating_steam_bar, vacuum_motor_power_kw, is_active)
VALUES
    ('TBL-STEAM-VAC-01', 'VACUUM_BLOW_TABLE', 4.8, 0.75, true),
    ('TBL-STEAM-VAC-02', 'VACUUM_BLOW_TABLE', 4.8, 0.75, true),
    ('TBL-STEAM-VAC-03', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-04', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-05', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-06', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-07', 'VACUUM_BLOW_TABLE', 4.6, 0.75, true),
    ('TBL-STEAM-VAC-08', 'VACUUM_BLOW_TABLE', 4.6, 0.75, true),
    ('TBL-STEAM-VAC-09', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-10', 'VACUUM_BLOW_TABLE', 4.5, 0.75, true),
    ('TBL-STEAM-VAC-11', 'FORM_FINISHER',     5.2, 1.10, true),
    ('TBL-STEAM-VAC-12', 'UTILITY_PRESS',     5.0, 1.50, true)
ON CONFLICT (table_code) DO NOTHING;

-- 2. Pressing Production Log linked to live PO-ZIG-8901
DO $$
DECLARE
    v_order_id UUID;
    v_table_id UUID;
    v_log_id UUID;
BEGIN
    SELECT id INTO v_order_id FROM public.merchandising_orders WHERE po_number = 'PO-ZIG-8901' LIMIT 1;
    SELECT id INTO v_table_id FROM public.iron_tables WHERE table_code = 'TBL-STEAM-VAC-01' LIMIT 1;

    IF v_order_id IS NOT NULL AND v_table_id IS NOT NULL THEN
        INSERT INTO public.iron_production_logs (
            id,
            log_number,
            order_id,
            table_id,
            shift,
            garments_pressed,
            boiler_pressure_bar,
            standard_sam_per_pc,
            total_minutes_spent,
            status
        ) VALUES (
            'c1d2e3f4-a5b6-4c7d-8e9f-0123456789c1',
            'IRN-2026-0921',
            v_order_id,
            v_table_id,
            'DAY',
            420,
            4.6,
            0.85,
            330,
            'COMPLETED'
        )
        ON CONFLICT (log_number) DO UPDATE SET updated_at = NOW()
        RETURNING id INTO v_log_id;

        -- 3. Defect audit check
        IF v_log_id IS NOT NULL THEN
            INSERT INTO public.iron_defect_audits (
                iron_log_id,
                defect_type,
                defect_count,
                disposition
            ) VALUES (
                v_log_id,
                'THERMAL_SHINE_GLAZE',
                1,
                'STEAM_RE_WORK'
            )
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;
