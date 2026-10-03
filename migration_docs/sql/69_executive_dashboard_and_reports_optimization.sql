-- =============================================================================
-- Migration 69: Executive Dashboard & Reports Performance Infrastructure
-- Description: Creates high-performance analytical B-Tree indexes and optimized
-- views for real-time factory pulse, multi-stage production reconciliation,
-- and cross-department executive reporting.
-- =============================================================================

-- =============================================================================
-- 1. ANALYTICAL PERFORMANCE INDEXES
-- Optimizes multi-table aggregations for daily output, QC audits, and store movements
-- =============================================================================

-- Daily Product (Sewing Output)
CREATE INDEX IF NOT EXISTS idx_daily_product_entry_date 
    ON public.daily_product (entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_product_art_date 
    ON public.daily_product (article_id, entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_product_lineman_date 
    ON public.daily_product (lineman_id, entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_product_quantity 
    ON public.daily_product (quantity);

-- QC Logs (Inspection & Defect Analytics)
CREATE INDEX IF NOT EXISTS idx_qc_logs_entry_date 
    ON public.qc_logs (entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_qc_logs_art_date 
    ON public.qc_logs (article_id, entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_qc_logs_defect_type 
    ON public.qc_logs (defect_type);

CREATE INDEX IF NOT EXISTS idx_qc_logs_passed_rejected 
    ON public.qc_logs (qty_passed, qty_rejected);

-- Store Transactions (Godown Inward / Outward Reconciliation)
CREATE INDEX IF NOT EXISTS idx_store_tx_entry_date 
    ON public.store_transactions (entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_store_tx_created_at 
    ON public.store_transactions (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_store_tx_type_qty 
    ON public.store_transactions (type, quantity);

CREATE INDEX IF NOT EXISTS idx_store_tx_party_name 
    ON public.store_transactions (party_name);

-- Delivery Challans (Dispatches & Logistics)
CREATE INDEX IF NOT EXISTS idx_delivery_challans_created_at 
    ON public.delivery_challans (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_delivery_challans_buyer_name 
    ON public.delivery_challans (buyer_name);

CREATE INDEX IF NOT EXISTS idx_delivery_challans_status 
    ON public.delivery_challans (status);

-- Challan Items (Dispatched Article Details)
CREATE INDEX IF NOT EXISTS idx_challan_items_art_qty 
    ON public.challan_items (article_id, quantity);

-- Cutting Lay Sheets
CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_status 
    ON public.cutting_lay_sheets (status);

CREATE INDEX IF NOT EXISTS idx_cutting_lay_sheets_created_at 
    ON public.cutting_lay_sheets (created_at DESC);

-- Articles Catalog
CREATE INDEX IF NOT EXISTS idx_articles_is_active 
    ON public.articles (is_active);

CREATE INDEX IF NOT EXISTS idx_articles_art_no 
    ON public.articles (art_no);


-- =============================================================================
-- 2. EXECUTIVE ANALYTICAL VIEWS (SECURITY INVOKER)
-- Enforces Row-Level Security while providing single-query executive rollups
-- =============================================================================

-- View 1: Real-Time Factory Pulse Metrics Rollup
CREATE OR REPLACE VIEW public.view_executive_factory_pulse
WITH (security_invoker = true) AS
SELECT
    (SELECT COUNT(*) FROM public.articles WHERE is_active = true) AS active_styles_count,
    (SELECT COUNT(*) FROM public.challans WHERE status != 'COMPLETED') AS running_orders_count,
    (SELECT COALESCE(SUM(total_pcs), 0) FROM public.challans) AS total_target_pieces,
    (SELECT COALESCE(SUM(quantity), 0) FROM public.daily_product WHERE entry_date = CURRENT_DATE) AS today_output_pieces,
    (
        SELECT GREATEST(0, COALESCE(SUM(CASE WHEN type = 'INWARD' THEN quantity WHEN type = 'OUTWARD' THEN -quantity ELSE 0 END), 0))
        FROM public.store_transactions
    ) AS godown_stock_pieces,
    (SELECT COALESCE(SUM(total_pieces), 0) FROM public.delivery_challans) AS total_dispatched_pieces,
    (SELECT COALESCE(SUM(qty_passed), 0) FROM public.qc_logs) AS total_qc_passed,
    (SELECT COALESCE(SUM(qty_rejected), 0) FROM public.qc_logs) AS total_qc_rejected;

-- View 2: Article Lifecycle Multi-Stage Throughput Reconciliation
CREATE OR REPLACE VIEW public.view_article_lifecycle_analytics
WITH (security_invoker = true) AS
SELECT
    a.id AS article_id,
    a.art_no,
    a.description,
    a.is_active,
    COALESCE(al.total_target, 0) AS target_pieces,
    COALESCE(dp.total_stitched, 0) AS stitched_pieces,
    COALESCE(qc.total_passed, 0) AS qc_passed_pieces,
    COALESCE(qc.total_rejected, 0) AS qc_failed_pieces,
    CASE 
        WHEN (COALESCE(qc.total_passed, 0) + COALESCE(qc.total_rejected, 0)) > 0 
        THEN ROUND((COALESCE(qc.total_rejected, 0)::NUMERIC / (COALESCE(qc.total_passed, 0) + COALESCE(qc.total_rejected, 0))::NUMERIC) * 100, 1)
        ELSE 0.0
    END AS qc_reject_rate_pct,
    GREATEST(0, COALESCE(st.net_inward, 0)) AS godown_pieces,
    COALESCE(disp.total_dispatched, 0) AS dispatched_pieces
FROM public.articles a
LEFT JOIN (
    SELECT article_id, SUM(target_qty) AS total_target
    FROM public.allotments
    GROUP BY article_id
) al ON al.article_id = a.id
LEFT JOIN (
    SELECT article_id, SUM(quantity) AS total_stitched
    FROM public.daily_product
    GROUP BY article_id
) dp ON dp.article_id = a.id
LEFT JOIN (
    SELECT article_id, SUM(qty_passed) AS total_passed, SUM(qty_rejected) AS total_rejected
    FROM public.qc_logs
    GROUP BY article_id
) qc ON qc.article_id = a.id
LEFT JOIN (
    SELECT article_id, SUM(CASE WHEN type = 'INWARD' THEN quantity WHEN type = 'OUTWARD' THEN -quantity ELSE 0 END) AS net_inward
    FROM public.store_transactions
    GROUP BY article_id
) st ON st.article_id = a.id
LEFT JOIN (
    SELECT ci.article_id, SUM(ci.quantity) AS total_dispatched
    FROM public.challan_items ci
    GROUP BY ci.article_id
) disp ON disp.article_id = a.id;


-- =============================================================================
-- 3. PERMISSIONS & ACCESS CONTROL
-- =============================================================================
GRANT SELECT ON public.view_executive_factory_pulse TO authenticated, service_role, anon;
GRANT SELECT ON public.view_article_lifecycle_analytics TO authenticated, service_role, anon;
