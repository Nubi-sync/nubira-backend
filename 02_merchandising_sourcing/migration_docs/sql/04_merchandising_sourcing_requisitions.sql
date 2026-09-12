-- ==============================================================================
-- 04_merchandising_sourcing_requisitions.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Raw Material Purchase Requisitions (PR) & Central Store Handshake
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_sourcing_requisitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pr_number VARCHAR(32) NOT NULL UNIQUE, -- e.g. 'PR-2026-041'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
    category VARCHAR(32) NOT NULL CHECK (category IN ('FABRIC', 'TRIMS', 'YARN', 'CARTONS', 'PACKAGING', 'ACCESSORY')),
    item_description TEXT NOT NULL,
    required_quantity NUMERIC(12,2) NOT NULL CHECK (required_quantity > 0),
    uom VARCHAR(20) NOT NULL, -- 'KG', 'METER', 'PIECE', 'CONE', 'GROSS'
    required_in_house_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'PO_ISSUED', 'RECEIVED_STORE', 'CANCELLED')),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_order ON public.merchandising_sourcing_requisitions(order_id);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_vendor ON public.merchandising_sourcing_requisitions(vendor_id);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_status ON public.merchandising_sourcing_requisitions(status);
CREATE INDEX IF NOT EXISTS idx_sourcing_pr_in_house_date ON public.merchandising_sourcing_requisitions(required_in_house_date);
