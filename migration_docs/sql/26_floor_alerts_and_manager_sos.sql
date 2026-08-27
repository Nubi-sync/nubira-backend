-- =========================================================================
-- 26_floor_alerts_and_manager_sos.sql
-- Production Floor Andon SOS Alert System for Linemen and Production Managers
-- =========================================================================

CREATE TABLE IF NOT EXISTS floor_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    allotment_id UUID REFERENCES allotments(id) ON DELETE CASCADE,
    lineman_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    lineman_name TEXT,
    production_order_no TEXT,
    category TEXT NOT NULL CHECK (category IN ('MACHINE_BREAKDOWN', 'MATERIAL_SHORTAGE', 'CUTTING_DEFECT', 'GENERAL_DELAY')),
    machine_station TEXT DEFAULT 'GENERAL' CHECK (machine_station IN ('OVERLOCK', 'FIVE_THREAD', 'FLATLOCK_RIB', 'LOCKING', 'GENERAL')),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED')),
    resolved_by TEXT,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for fast querying on active floor radars
CREATE INDEX IF NOT EXISTS idx_floor_alerts_status ON floor_alerts(status);
CREATE INDEX IF NOT EXISTS idx_floor_alerts_allotment_id ON floor_alerts(allotment_id);
CREATE INDEX IF NOT EXISTS idx_floor_alerts_created_at ON floor_alerts(created_at DESC);

-- Enable RLS
ALTER TABLE floor_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow authenticated read on floor_alerts"
    ON floor_alerts FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated insert on floor_alerts"
    ON floor_alerts FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update on floor_alerts"
    ON floor_alerts FOR UPDATE
    TO authenticated
    USING (true);
