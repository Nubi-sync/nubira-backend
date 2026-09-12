-- ==============================================================================
-- 02_cutting_lay_rolls.sql
-- Division 03: Cutting & Lay Floor Operations Desk
-- Tables: public.store_fabric_rolls (Stub) & public.cutting_lay_rolls
-- ==============================================================================

-- 1. Forward-compatible Stub Table: public.store_fabric_rolls (Division 11 Central Store Godown)
CREATE TABLE IF NOT EXISTS public.store_fabric_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roll_barcode VARCHAR(64) NOT NULL UNIQUE, -- e.g. 'ROL-FT-8821-A1'
    material_type VARCHAR(50) DEFAULT 'SHELL_FABRIC',
    fabric_name VARCHAR(150) NOT NULL,
    shade_group VARCHAR(20) NOT NULL, -- 'SHADE_A', 'SHADE_B', 'SHADE_C'
    dye_lot_number VARCHAR(50),
    gross_weight_kg NUMERIC(8,2) NOT NULL,
    length_meters NUMERIC(8,2) NOT NULL,
    usable_width_inches NUMERIC(5,2) DEFAULT 60.00,
    inspection_points_score INTEGER DEFAULT 0, -- 4-Point System score
    status VARCHAR(30) DEFAULT 'STORE_GODOWN', -- 'STORE_GODOWN', 'RELAXATION', 'ON_CUTTING_TABLE', 'DEPLETED'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_store_fabric_rolls_barcode ON public.store_fabric_rolls(roll_barcode);
CREATE INDEX IF NOT EXISTS idx_store_fabric_rolls_shade ON public.store_fabric_rolls(shade_group);

-- 2. Master Lay Sheet Fabric Rolls Junction Table (Shade Group Integrity)
CREATE TABLE IF NOT EXISTS public.cutting_lay_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lay_sheet_id UUID NOT NULL REFERENCES public.cutting_lay_sheets(id) ON DELETE CASCADE,
    roll_id UUID NOT NULL REFERENCES public.store_fabric_rolls(id) ON DELETE RESTRICT,
    plies_from_roll INTEGER NOT NULL CHECK (plies_from_roll > 0),
    meters_consumed NUMERIC(8,2) NOT NULL,
    remnant_length_m NUMERIC(6,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_cutting_lay_rolls_lay ON public.cutting_lay_rolls(lay_sheet_id);
CREATE INDEX IF NOT EXISTS idx_cutting_lay_rolls_roll ON public.cutting_lay_rolls(roll_id);

COMMENT ON TABLE public.cutting_lay_rolls IS 'Fabric rolls spread across a specific lay sheet. Enforces single dye lot and shade group integrity.';
COMMENT ON COLUMN public.cutting_lay_rolls.meters_consumed IS 'Total linear fabric meters pulled from this roll for the lay.';
