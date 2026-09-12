-- ==============================================================================
-- 03_merchandising_tna_milestones.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Dynamic Time & Action (T&A) 8-Gate Critical Path Milestones
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_tna_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE CASCADE,
    gate_name VARCHAR(64) NOT NULL, 
    -- Standard Industrial Gates:
    -- 1. 'LAB_DIP_APPROVAL'
    -- 2. 'FABRIC_INWARD'
    -- 3. 'PPS_APPROVAL'
    -- 4. 'CUTTING_START'
    -- 5. 'SEWING_COMPLETE'
    -- 6. 'WASHING_COMPLETE'
    -- 7. 'FINAL_AQL_AUDIT'
    -- 8. 'EX_FACTORY'
    target_date DATE NOT NULL,
    actual_date DATE,
    lead_time_days INTEGER NOT NULL CHECK (lead_time_days >= 0),
    status VARCHAR(20) DEFAULT 'ON_TRACK' CHECK (status IN ('PENDING', 'ON_TRACK', 'DELAYED', 'COMPLETED')),
    responsible_role VARCHAR(32) NOT NULL, -- 'MERCHANDISER', 'STORE_HEAD', 'DESIGN_STUDIO', 'CUTTING_MASTER', 'STITCHING_HEAD', 'WASHING_SUPERVISOR', 'QA_MANAGER', 'EXPORT_COORDINATOR'
    delay_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, gate_name)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_tna_order ON public.merchandising_tna_milestones(order_id);
CREATE INDEX IF NOT EXISTS idx_tna_target_date ON public.merchandising_tna_milestones(target_date);
CREATE INDEX IF NOT EXISTS idx_tna_status ON public.merchandising_tna_milestones(status);
