-- ==============================================================================
-- 06_alteration_seed_data.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Standard Operational Seed Data (Intake Triage Ticket & Scrap Record)
-- ==============================================================================

DO $$
DECLARE
    v_allotment_id UUID;
    v_bundle_id UUID;
    v_ticket_id UUID;
BEGIN
    SELECT id INTO v_allotment_id FROM public.allotments LIMIT 1;
    SELECT id INTO v_bundle_id FROM public.cutting_bundles LIMIT 1;

    -- 1. Insert Reference Alteration Ticket
    INSERT INTO public.alteration_tickets (
        id,
        ticket_number,
        allotment_id,
        bundle_id,
        defect_category,
        defect_severity,
        pieces_received,
        pieces_repaired,
        pieces_scrapped,
        status
    ) VALUES (
        'e1f2a3b4-c5d6-4e7f-8a9b-0123456789e1',
        'ALT-2026-00412',
        v_allotment_id,
        v_bundle_id,
        'OPEN_SEAM',
        'MAJOR',
        4,
        3,
        1,
        'SECONDARY_QC_PASSED'
    )
    ON CONFLICT (ticket_number) DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_ticket_id;

    -- 2. Insert Scrap Loss for the 1 condemned piece
    IF v_ticket_id IS NOT NULL THEN
        INSERT INTO public.alteration_scrap_logs (
            ticket_id,
            scrapped_pieces,
            scrap_reason,
            fabric_weight_kg,
            estimated_financial_loss_inr
        ) VALUES (
            v_ticket_id,
            1,
            'Irreparable shell fabric tear during lockstitch unpicking',
            0.42,
            185.00
        )
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
