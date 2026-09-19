-- =============================================================================
-- Migration: Washing Floor Workers & Task Allocations Matrix
-- Division: 07. Industrial Washing & Wet Processing Plant
-- Description: Creates schema for registered Washing floor operators and
-- garment task allocation matrix table with washer machine/drum stations.
-- =============================================================================

-- 1. Create washing_workers Table
CREATE TABLE IF NOT EXISTS public.washing_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['WASH_MASTER']::TEXT[],
    role TEXT DEFAULT 'WASH_MASTER',
    assigned_machine TEXT DEFAULT 'Washer 01 (Tumbler 600kg)',
    shift TEXT DEFAULT 'MORNING',
    status TEXT DEFAULT 'ACTIVE',
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for washing_workers
CREATE INDEX IF NOT EXISTS idx_washing_workers_company ON public.washing_workers(company_name);
CREATE INDEX IF NOT EXISTS idx_washing_workers_phone ON public.washing_workers(phone_number);

-- Enable RLS for washing_workers
ALTER TABLE public.washing_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read washing workers" 
    ON public.washing_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update washing workers" 
    ON public.washing_workers FOR ALL USING (true);

-- 2. Create washing_task_allocations Table (Spreadsheet Matrix)
CREATE TABLE IF NOT EXISTS public.washing_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    buyer_id UUID,
    buyer_name TEXT NOT NULL DEFAULT 'Direct Buyer',
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID REFERENCES public.washing_workers(id) ON DELETE SET NULL,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    table_number TEXT DEFAULT 'Washer 01 (Tumbler 600kg)',
    machine_number TEXT,
    pieces_to_wash NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    due_time TIMESTAMPTZ,
    wash_recipe TEXT DEFAULT 'Bio-Enzyme Wash 55°C',
    notes TEXT,
    status TEXT DEFAULT 'ASSIGNED',
    company_name TEXT,
    started_at TIMESTAMPTZ,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for washing_task_allocations
CREATE INDEX IF NOT EXISTS idx_washing_allocations_company ON public.washing_task_allocations(company_name);
CREATE INDEX IF NOT EXISTS idx_washing_allocations_task_ref ON public.washing_task_allocations(task_ref);
CREATE INDEX IF NOT EXISTS idx_washing_allocations_worker ON public.washing_task_allocations(worker_id);

-- Enable RLS for washing_task_allocations
ALTER TABLE public.washing_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read washing tasks" 
    ON public.washing_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update washing tasks" 
    ON public.washing_task_allocations FOR ALL USING (true);
