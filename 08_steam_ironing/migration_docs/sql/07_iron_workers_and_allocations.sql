-- =============================================================================
-- Migration: Steam Ironing Pressers & Task Allocations Matrix
-- Division: 08. Steam Ironing & Finishing Floor
-- Description: Creates schema for registered Finishing pressers and
-- garment task allocation matrix table with steam table / vacuum stations.
-- =============================================================================

-- 1. Create iron_workers Table
CREATE TABLE IF NOT EXISTS public.iron_workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_user_id UUID,
    worker_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    worker_email TEXT,
    roles TEXT[] DEFAULT ARRAY['FINISHING_PRESSER']::TEXT[],
    role TEXT DEFAULT 'FINISHING_PRESSER',
    assigned_table TEXT DEFAULT 'Steam Table 01 (Vacuum)',
    shift TEXT DEFAULT 'SHIFT_1',
    status TEXT DEFAULT 'ACTIVE',
    is_active BOOLEAN DEFAULT TRUE,
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for iron_workers
CREATE INDEX IF NOT EXISTS idx_iron_workers_company ON public.iron_workers(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_workers_phone ON public.iron_workers(phone_number);

-- Enable RLS for iron_workers
ALTER TABLE public.iron_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron workers" 
    ON public.iron_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron workers" 
    ON public.iron_workers FOR ALL USING (true);

-- 2. Create iron_task_allocations Table (Spreadsheet Matrix)
CREATE TABLE IF NOT EXISTS public.iron_task_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_ref TEXT NOT NULL,
    cutting_allocation_id UUID,
    buyer_id UUID,
    buyer_name TEXT NOT NULL DEFAULT 'Direct Buyer',
    article_number TEXT NOT NULL,
    article_name TEXT,
    worker_id UUID REFERENCES public.iron_workers(id) ON DELETE SET NULL,
    worker_name TEXT NOT NULL,
    worker_phone TEXT,
    machine_table TEXT DEFAULT 'Steam Table 01 (Vacuum)',
    table_number TEXT,
    pieces_to_press NUMERIC NOT NULL DEFAULT 0,
    completed_pieces NUMERIC NOT NULL DEFAULT 0,
    alloted_hours NUMERIC NOT NULL DEFAULT 4.0,
    shift TEXT DEFAULT 'SHIFT_1',
    iron_temp_c INTEGER DEFAULT 150,
    due_time TIMESTAMPTZ,
    notes TEXT,
    status TEXT DEFAULT 'PENDING',
    company_name TEXT,
    started_at TIMESTAMPTZ,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for iron_task_allocations
CREATE INDEX IF NOT EXISTS idx_iron_allocations_company ON public.iron_task_allocations(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_task_ref ON public.iron_task_allocations(task_ref);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_worker ON public.iron_task_allocations(worker_id);

-- Enable RLS for iron_task_allocations
ALTER TABLE public.iron_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron tasks" 
    ON public.iron_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron tasks" 
    ON public.iron_task_allocations FOR ALL USING (true);
