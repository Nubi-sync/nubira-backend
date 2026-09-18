-- =============================================================================
-- Migration: Cutting Floor Workers & Task Allocations Matrix
-- Description: Creates schema for registered cutting floor operators with multi-role
-- capabilities and the task allocation matrix table with strict hour deadlines.
-- =============================================================================

-- 1. Create cutting_workers Table
CREATE TABLE IF NOT EXISTS public.cutting_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['KNIFE_CUTTER']::TEXT[],
    role TEXT DEFAULT 'Knife Cutter',
    status TEXT DEFAULT 'ACTIVE',
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for cutting_workers
ALTER TABLE public.cutting_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read cutting workers" 
    ON public.cutting_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update cutting workers" 
    ON public.cutting_workers FOR ALL USING (true);

-- 2. Create cutting_task_allocations Table (Spreadsheet Matrix)
CREATE TABLE IF NOT EXISTS public.cutting_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    buyer_id UUID,
    buyer_name TEXT NOT NULL,
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    table_number TEXT DEFAULT 'Table 01',
    pieces_to_cut NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    due_time TIMESTAMPTZ,
    notes TEXT,
    status TEXT DEFAULT 'ASSIGNED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for cutting_task_allocations
ALTER TABLE public.cutting_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read cutting tasks" 
    ON public.cutting_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update cutting tasks" 
    ON public.cutting_task_allocations FOR ALL USING (true);
