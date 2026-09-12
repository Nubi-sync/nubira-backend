-- ==============================================================================
-- 05_alteration_rls_policies.sql
-- Division 10: Alteration & Quality Rework Clinic
-- Row Level Security (RLS) & Role-Based Access Control
-- ==============================================================================

-- Enable RLS
ALTER TABLE public.alteration_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alteration_scrap_logs ENABLE ROW LEVEL SECURITY;

-- 1. Tickets Policies
DROP POLICY IF EXISTS p_alteration_tickets_select ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_select ON public.alteration_tickets FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_alteration_tickets_insert ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_insert ON public.alteration_tickets FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS p_alteration_tickets_update ON public.alteration_tickets;
CREATE POLICY p_alteration_tickets_update ON public.alteration_tickets FOR UPDATE TO authenticated USING (true);

-- 2. Scrap Logs Policies
DROP POLICY IF EXISTS p_alteration_scrap_select ON public.alteration_scrap_logs;
CREATE POLICY p_alteration_scrap_select ON public.alteration_scrap_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS p_alteration_scrap_insert ON public.alteration_scrap_logs;
CREATE POLICY p_alteration_scrap_insert ON public.alteration_scrap_logs FOR INSERT TO authenticated WITH CHECK (true);
