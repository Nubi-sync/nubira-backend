-- =============================================================================
-- Migration: Embroidery Floor Workers & Task Allocations Matrix
-- Description: Creates schema for registered Embroidery (Division 05) floor
-- operators and task allocation matrix table with multi-head machine stations.
-- =============================================================================

-- 1. Create embroidery_workers Table
CREATE TABLE IF NOT EXISTS public.embroidery_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['EMBROIDERY_OPERATOR']::TEXT[],
    role TEXT DEFAULT 'Multi-Head Machine Operator',
    status TEXT DEFAULT 'ACTIVE',
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for embroidery_workers
ALTER TABLE public.embroidery_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read embroidery workers" 
    ON public.embroidery_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update embroidery workers" 
    ON public.embroidery_workers FOR ALL USING (true);

-- 2. Create embroidery_task_allocations Table (Spreadsheet Matrix)
CREATE TABLE IF NOT EXISTS public.embroidery_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    buyer_id UUID,
    buyer_name TEXT NOT NULL,
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    table_number TEXT DEFAULT 'Machine 01 (Tajima 20-Head)',
    pieces_to_embroider NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    due_time TIMESTAMPTZ,
    notes TEXT,
    status TEXT DEFAULT 'ASSIGNED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for embroidery_task_allocations
ALTER TABLE public.embroidery_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read embroidery tasks" 
    ON public.embroidery_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update embroidery tasks" 
    ON public.embroidery_task_allocations FOR ALL USING (true);
