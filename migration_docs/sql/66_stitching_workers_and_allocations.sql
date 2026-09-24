-- =============================================================================
-- Migration 66: Stitching & Sewing Floor Workers & Task Allocations
-- Description: Creates schema for registered Stitching/Tailoring floor operators,
-- task allocations, and progress submissions for standard factories.
-- =============================================================================

-- 1. Create stitching_workers Table
CREATE TABLE IF NOT EXISTS public.stitching_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['TAILOR']::TEXT[],
    role TEXT DEFAULT 'TAILOR',
    assigned_machine TEXT DEFAULT 'Single Needle Lockstitch (SNLS)',
    machine_specialty TEXT DEFAULT 'Single Needle Lockstitch (SNLS)',
    shift TEXT DEFAULT 'MORNING',
    status TEXT DEFAULT 'ACTIVE',
    piece_rate_inr NUMERIC DEFAULT 14.50,
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for stitching_workers
ALTER TABLE public.stitching_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read stitching workers" 
    ON public.stitching_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update stitching workers" 
    ON public.stitching_workers FOR ALL USING (true);

-- 2. Create stitching_task_allocations Table
CREATE TABLE IF NOT EXISTS public.stitching_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    lot_number TEXT NOT NULL DEFAULT 'LOT-DEFAULT',
    po_number TEXT,
    article_name TEXT NOT NULL,
    style_number TEXT,
    operation_type TEXT NOT NULL DEFAULT 'Full Garment Assembly',
    machine_type TEXT DEFAULT 'Single Needle Lockstitch (SNLS)',
    target_quantity NUMERIC NOT NULL DEFAULT 0,
    completed_quantity NUMERIC NOT NULL DEFAULT 0,
    rejected_quantity NUMERIC NOT NULL DEFAULT 0,
    piece_rate_inr NUMERIC NOT NULL DEFAULT 14.50,
    alloted_hours NUMERIC DEFAULT 8.0,
    worker_id UUID REFERENCES public.stitching_workers(id) ON DELETE SET NULL,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    due_date TIMESTAMPTZ,
    priority TEXT DEFAULT 'NORMAL',
    notes TEXT,
    status TEXT DEFAULT 'PENDING',
    company_name TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for stitching_task_allocations
ALTER TABLE public.stitching_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read stitching allocations" 
    ON public.stitching_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update stitching allocations" 
    ON public.stitching_task_allocations FOR ALL USING (true);

-- 3. Create stitching_submissions Table (Worker Submission Log)
CREATE TABLE IF NOT EXISTS public.stitching_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID,
    task_ref TEXT,
    lot_number TEXT,
    article_name TEXT,
    operation_type TEXT,
    worker_id UUID,
    worker_name TEXT NOT NULL,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    rejected_pieces NUMERIC NOT NULL DEFAULT 0,
    piece_rate_inr NUMERIC NOT NULL DEFAULT 14.50,
    total_earned_inr NUMERIC NOT NULL DEFAULT 0,
    company_name TEXT,
    notes TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for stitching_submissions
ALTER TABLE public.stitching_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read stitching submissions" 
    ON public.stitching_submissions FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update stitching submissions" 
    ON public.stitching_submissions FOR ALL USING (true);
