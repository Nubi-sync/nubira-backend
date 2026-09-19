-- =============================================================================
-- Migration 64: Washing & Ironing Floor Workers & Task Allocations Matrix
-- Description: Creates schema for registered Washing (Division 07) and
-- Steam Ironing (Division 08) floor operators and task allocation matrix tables.
-- =============================================================================

-- =============================================================================
-- 1. DIVISION 07: WASHING WORKERS & TASK ALLOCATIONS
-- =============================================================================

-- 1.1 Create washing_workers Table
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

-- Enable RLS for washing_workers
ALTER TABLE public.washing_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read washing workers" 
    ON public.washing_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update washing workers" 
    ON public.washing_workers FOR ALL USING (true);

-- 1.2 Create washing_task_allocations Table (Spreadsheet Matrix)
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

-- Enable RLS for washing_task_allocations
ALTER TABLE public.washing_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read washing tasks" 
    ON public.washing_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update washing tasks" 
    ON public.washing_task_allocations FOR ALL USING (true);

-- Indexes for washing
CREATE INDEX IF NOT EXISTS idx_washing_workers_company ON public.washing_workers(company_name);
CREATE INDEX IF NOT EXISTS idx_washing_workers_phone ON public.washing_workers(phone_number);
CREATE INDEX IF NOT EXISTS idx_washing_allocations_company ON public.washing_task_allocations(company_name);
CREATE INDEX IF NOT EXISTS idx_washing_allocations_task_ref ON public.washing_task_allocations(task_ref);


-- =============================================================================
-- 2. DIVISION 08: STEAM IRONING WORKERS & TASK ALLOCATIONS
-- =============================================================================

-- 2.1 Create iron_workers Table
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

-- Enable RLS for iron_workers
ALTER TABLE public.iron_workers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron workers" 
    ON public.iron_workers FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron workers" 
    ON public.iron_workers FOR ALL USING (true);

-- 2.2 Create iron_task_allocations Table (Spreadsheet Matrix)
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

-- Enable RLS for iron_task_allocations
ALTER TABLE public.iron_task_allocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read iron tasks" 
    ON public.iron_task_allocations FOR SELECT USING (true);
CREATE POLICY "Allow public insert/update iron tasks" 
    ON public.iron_task_allocations FOR ALL USING (true);

-- Indexes for steam ironing
CREATE INDEX IF NOT EXISTS idx_iron_workers_company ON public.iron_workers(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_workers_phone ON public.iron_workers(phone_number);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_company ON public.iron_task_allocations(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_allocations_task_ref ON public.iron_task_allocations(task_ref);

-- Ensure company_name on legacy batch/table records if present
ALTER TABLE IF EXISTS public.washing_batches ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE IF EXISTS public.washing_recipes ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE IF EXISTS public.iron_tables ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE IF EXISTS public.iron_production_logs ADD COLUMN IF NOT EXISTS company_name TEXT;

CREATE INDEX IF NOT EXISTS idx_washing_batches_company ON public.washing_batches(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_tables_company ON public.iron_tables(company_name);
CREATE INDEX IF NOT EXISTS idx_iron_production_logs_company ON public.iron_production_logs(company_name);
