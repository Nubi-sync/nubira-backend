-- =============================================================================
-- Migration 68: Fix Supabase Security Advisor Critical Alerts (Security Invoker Views)
-- Description: Sets security_invoker = true on all analytical KPI views to enforce
-- Row Level Security (RLS) and resolve Supabase Security Definer View alerts.
-- =============================================================================

-- 1. Merchandising Order Economics View
ALTER VIEW IF EXISTS public.view_merchandising_order_economics 
    SET (security_invoker = true);

-- 2. Cutting Floor KPIs View
ALTER VIEW IF EXISTS public.view_cutting_floor_kpis 
    SET (security_invoker = true);

-- 3. Printing Floor KPIs View
ALTER VIEW IF EXISTS public.view_printing_floor_kpis 
    SET (security_invoker = true);

-- 4. Embroidery Floor KPIs View
ALTER VIEW IF EXISTS public.view_embroidery_floor_kpis 
    SET (security_invoker = true);
