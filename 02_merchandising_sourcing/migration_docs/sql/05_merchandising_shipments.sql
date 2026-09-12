-- ==============================================================================
-- 05_merchandising_shipments.sql
-- Division 02: Merchandising & Sourcing Desk
-- Schema: Export Ocean Container Logistics & Bill of Lading (B/L) Tracking
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.merchandising_shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_ref VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'SHP-ZIG-2026-09'
    order_id UUID NOT NULL REFERENCES public.merchandising_orders(id) ON DELETE RESTRICT,
    container_number VARCHAR(30), -- e.g. 'MSKU-892182-1'
    container_type VARCHAR(20) DEFAULT '40_HIGH_CUBE' CHECK (container_type IN ('20_STANDARD', '40_STANDARD', '40_HIGH_CUBE', 'LCL_PALLET')),
    forwarder_name VARCHAR(100) NOT NULL, -- e.g. 'Maersk Line Logistics', 'Kuehne+Nagel'
    bill_of_lading_no VARCHAR(50), -- e.g. 'BL-MAEU-992102'
    total_cartons INTEGER NOT NULL CHECK (total_cartons > 0),
    total_gross_weight_kg NUMERIC(10,2) NOT NULL CHECK (total_gross_weight_kg > 0),
    total_cbm NUMERIC(8,3) NOT NULL CHECK (total_cbm > 0),
    port_of_loading VARCHAR(50) DEFAULT 'JNPT Mumbai',
    port_of_discharge VARCHAR(50) NOT NULL,
    etd_date DATE NOT NULL,
    eta_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'BOOKED' CHECK (status IN ('BOOKED', 'CONTAINER_STUFFED', 'CUSTOMS_CLEARED', 'ON_VESSEL', 'DELIVERED', 'CANCELLED')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_shipments_order ON public.merchandising_shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_shipments_status ON public.merchandising_shipments(status);
CREATE INDEX IF NOT EXISTS idx_shipments_etd ON public.merchandising_shipments(etd_date);
