-- ==============================================================================
-- 06_merchandising_triggers_and_functions.sql
-- Division 02: Merchandising & Sourcing Desk
-- Logic: Automated 8-Gate T&A Calendar Generator & Financial Analytics View
-- ==============================================================================

-- 1. Trigger Function: Automatically Generate 8-Gate T&A Calendar Backwards from Ex-Factory Date
CREATE OR REPLACE FUNCTION public.fn_auto_generate_tna_schedule()
RETURNS TRIGGER AS $$
DECLARE
    v_ex_factory DATE;
BEGIN
    v_ex_factory := NEW.ex_factory_date;

    -- Gate 1: EX_FACTORY (Lead offset 0 days)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'EX_FACTORY', v_ex_factory, 0, 'ON_TRACK', 'EXPORT_COORDINATOR'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 2: FINAL_AQL_AUDIT (Lead offset 4 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'FINAL_AQL_AUDIT', v_ex_factory - INTERVAL '4 days', 4, 'ON_TRACK', 'QA_MANAGER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 3: WASHING_COMPLETE (Lead offset 9 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'WASHING_COMPLETE', v_ex_factory - INTERVAL '9 days', 9, 'ON_TRACK', 'WASHING_SUPERVISOR'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 4: SEWING_COMPLETE (Lead offset 14 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'SEWING_COMPLETE', v_ex_factory - INTERVAL '14 days', 14, 'ON_TRACK', 'STITCHING_HEAD'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 5: CUTTING_START (Lead offset 24 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'CUTTING_START', v_ex_factory - INTERVAL '24 days', 24, 'ON_TRACK', 'CUTTING_MASTER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 6: PPS_APPROVAL (Lead offset 28 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'PPS_APPROVAL', v_ex_factory - INTERVAL '28 days', 28, 'ON_TRACK', 'DESIGN_STUDIO'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 7: FABRIC_INWARD (Lead offset 35 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'FABRIC_INWARD', v_ex_factory - INTERVAL '35 days', 35, 'ON_TRACK', 'STORE_HEAD'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    -- Gate 8: LAB_DIP_APPROVAL (Lead offset 45 days prior)
    INSERT INTO public.merchandising_tna_milestones (
        order_id, gate_name, target_date, lead_time_days, status, responsible_role
    ) VALUES (
        NEW.id, 'LAB_DIP_APPROVAL', v_ex_factory - INTERVAL '45 days', 45, 'ON_TRACK', 'MERCHANDISER'
    ) ON CONFLICT (order_id, gate_name) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_generate_tna ON public.merchandising_orders;

CREATE TRIGGER trg_auto_generate_tna
    AFTER INSERT ON public.merchandising_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_auto_generate_tna_schedule();


-- 2. Trigger Function: Update Order Status on Key Milestone Completion
CREATE OR REPLACE FUNCTION public.fn_sync_milestone_to_order_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If EX_FACTORY is completed, advance Order to SHIPPED
    IF NEW.gate_name = 'EX_FACTORY' AND NEW.status = 'COMPLETED' THEN
        UPDATE public.merchandising_orders
        SET status = 'SHIPPED', updated_at = NOW()
        WHERE id = NEW.order_id AND status != 'SHIPPED';
    END IF;

    -- If CUTTING_START is completed, advance Order to IN_PRODUCTION
    IF NEW.gate_name = 'CUTTING_START' AND NEW.status = 'COMPLETED' THEN
        UPDATE public.merchandising_orders
        SET status = 'IN_PRODUCTION', updated_at = NOW()
        WHERE id = NEW.order_id AND status = 'CONFIRMED';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_milestone_status ON public.merchandising_tna_milestones;

CREATE TRIGGER trg_sync_milestone_status
    AFTER UPDATE OF status ON public.merchandising_tna_milestones
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_sync_milestone_to_order_status();


-- 3. Comprehensive Financial Analytics View for Merchandising Orders
CREATE OR REPLACE VIEW public.view_merchandising_order_economics AS
SELECT 
    o.id AS order_id,
    o.order_number,
    b.brand_name AS buyer_name,
    tp.style_number,
    tp.category AS garment_silhouette,
    o.season,
    o.total_quantity,
    o.fob_price_per_piece,
    o.currency,
    o.ex_factory_date,
    o.status AS order_status,
    ROUND((o.total_quantity * o.fob_price_per_piece), 2) AS total_contract_value,
    COALESCE(ROUND(SUM(c.planned_cost_per_pc), 2), 0.00) AS total_bom_cost_per_pc,
    COALESCE(ROUND(SUM(c.actual_cost_per_pc), 2), 0.00) AS actual_bom_cost_per_pc,
    -- Estimated Cut & Make (CM) + Embellishment overheads (approx 18% of FOB)
    ROUND(o.fob_price_per_piece * 0.18, 2) AS estimated_cm_overhead_per_pc,
    -- Total Garment Landed Cost
    ROUND(COALESCE(SUM(c.planned_cost_per_pc), 0.00) + (o.fob_price_per_piece * 0.18), 2) AS total_garment_cost,
    -- Gross Profit Margin %
    CASE 
        WHEN o.fob_price_per_piece > 0 THEN
            ROUND((
                (o.fob_price_per_piece - (COALESCE(SUM(c.planned_cost_per_pc), 0.00) + (o.fob_price_per_piece * 0.18))) 
                / o.fob_price_per_piece * 100
            ), 2)
        ELSE 0.00
    END AS gross_profit_margin_pct
FROM public.merchandising_orders o
JOIN public.brands b ON o.buyer_id = b.id
JOIN public.design_tech_packs tp ON o.tech_pack_id = tp.id
LEFT JOIN public.merchandising_bom_costings c ON o.id = c.order_id
GROUP BY o.id, o.order_number, b.brand_name, tp.style_number, tp.category, o.season, o.total_quantity, o.fob_price_per_piece, o.currency, o.ex_factory_date, o.status;
