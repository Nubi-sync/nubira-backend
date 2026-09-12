-- ==============================================================================
-- 01_iron_tables.sql
-- Division 08: Steam Ironing & Finishing Floor
-- Table: public.iron_tables (Industrial Vacuum Buck Tables & Presses)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.iron_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'TBL-STEAM-VAC-01'
    table_type VARCHAR(30) DEFAULT 'VACUUM_BLOW_TABLE', -- 'VACUUM_BLOW_TABLE', 'FORM_FINISHER', 'UTILITY_PRESS'
    operating_steam_bar NUMERIC(3,1) NOT NULL DEFAULT 5.0,
    vacuum_motor_power_kw NUMERIC(3,1) DEFAULT 0.75,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_iron_tables_code ON public.iron_tables(table_code);
CREATE INDEX IF NOT EXISTS idx_iron_tables_active ON public.iron_tables(is_active);

COMMENT ON TABLE public.iron_tables IS 'Finishing floor vacuum suction buck tables and calibrated steam pressing stations.';
