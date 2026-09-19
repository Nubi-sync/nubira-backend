-- =============================================================================
-- Migration: Printing Floor Workers & Task Allocations Matrix
-- Description: Creates schema for registered Printing (Division 04) floor
-- operators and task allocation matrix table with print table / carousel stations.
-- =============================================================================

-- 1. Create printing_workers Table
CREATE TABLE IF NOT EXISTS public.printing_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['SCREEN_PRINTER']::TEXT[],
    role TEXT DEFAULT 'Screen Print Operator',
    status TEXT DEFAULT 'ACTIVE',
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for printing_workers
ALTER TABLE public.printing_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read printing workers" 
    ON public.printing_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update printing workers" 
    ON public.printing_workers FOR ALL USING (true);

-- 2. Create printing_task_allocations Table (Spreadsheet Matrix)
CREATE TABLE IF NOT EXISTS public.printing_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    buyer_id UUID,
    buyer_name TEXT NOT NULL,
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    table_number TEXT DEFAULT 'Print Table 01',
    pieces_to_print NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    due_time TIMESTAMPTZ,
    notes TEXT,
    status TEXT DEFAULT 'ASSIGNED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for printing_task_allocations
ALTER TABLE public.printing_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read printing tasks" 
    ON public.printing_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update printing tasks" 
    ON public.printing_task_allocations FOR ALL USING (true);
