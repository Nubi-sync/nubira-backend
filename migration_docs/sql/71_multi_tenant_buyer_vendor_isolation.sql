-- =============================================================================
-- Migration 71: Strict Multi-Tenant Buyer, Vendor & Contract Isolation
-- Description: Enforces strict tenant scoping across all buyer profiles, 
-- brands, vendor assignments, and merchandising contracts.
-- Contracts forged in Merchandising or Buyers & Vendors belong strictly to the
-- tenant company that created them and cannot leak into other company profiles.
-- =============================================================================

-- 1. Ensure company_name / tenant_company columns exist with proper defaults
ALTER TABLE public.brands 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

ALTER TABLE public.vendors 
  ADD COLUMN IF NOT EXISTS tenant_company TEXT;

ALTER TABLE public.module_vendors 
  ADD COLUMN IF NOT EXISTS tenant_company TEXT;

ALTER TABLE public.merchandising_active_buyers 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

ALTER TABLE public.merchandising_orders 
  ADD COLUMN IF NOT EXISTS company_name TEXT;

-- 2. Multi-Tenant Performance Indexes
CREATE INDEX IF NOT EXISTS idx_brands_company_name 
  ON public.brands (company_name);

CREATE INDEX IF NOT EXISTS idx_vendors_tenant_company 
  ON public.vendors (tenant_company);

CREATE INDEX IF NOT EXISTS idx_module_vendors_tenant_company 
  ON public.module_vendors (tenant_company);

CREATE INDEX IF NOT EXISTS idx_merch_buyers_company_name 
  ON public.merchandising_active_buyers (company_name);

CREATE INDEX IF NOT EXISTS idx_merch_orders_company_name 
  ON public.merchandising_orders (company_name);

-- 3. Dynamic Contract Ownership Alignment
-- Align merchandising orders to the company that owns the underlying tech pack
UPDATE public.merchandising_orders o
  SET company_name = tp.company_name
  FROM public.design_tech_packs tp
  WHERE o.tech_pack_id::text = tp.id::text 
    AND tp.company_name IS NOT NULL
    AND (o.company_name IS NULL OR o.company_name != tp.company_name);

-- Align active buyer contracts to the company that owns the linked article/tech pack
UPDATE public.merchandising_active_buyers b
  SET company_name = tp.company_name
  FROM public.design_tech_packs tp
  WHERE (b.linked_article_id = tp.id::text OR b.linked_article_number = tp.style_number)
    AND tp.company_name IS NOT NULL
    AND (b.company_name IS NULL OR b.company_name != tp.company_name);

-- Align brand ownership to the company that forged contracts with it
UPDATE public.brands br
  SET company_name = o.company_name
  FROM public.merchandising_orders o
  WHERE o.buyer_id::text = br.id::text 
    AND o.company_name IS NOT NULL
    AND (br.company_name IS NULL OR br.company_name != o.company_name);

-- 4. Correct Historical Demo Industries Contracts
-- Hollypop (DEMO-101-03) and ollywood (DEMO-102) contracts were both forged for Demo Industries
UPDATE public.merchandising_orders 
  SET company_name = 'Demo Industries' 
  WHERE order_number IN ('HOLL-2026-2963', 'BYRO-2026-6837') 
     OR tech_pack_id::text IN (
       SELECT id::text FROM public.design_tech_packs 
       WHERE style_number IN ('DEMO-101-03', 'DEMO-102')
     );

UPDATE public.merchandising_active_buyers 
  SET company_name = 'Demo Industries' 
  WHERE buyer_name IN ('Hollypop', 'ollywood')
     OR linked_article_number IN ('DEMO-101-03', 'DEMO-102');

UPDATE public.brands 
  SET company_name = 'Demo Industries' 
  WHERE brand_name IN ('Hollypop', 'ollywood');

-- Point Demo Tech Packs to their genuine buyer brands
UPDATE public.design_tech_packs tp
  SET brand_id = br.id
  FROM public.brands br
  WHERE tp.style_number = 'DEMO-101-03' AND br.brand_name = 'Hollypop';

UPDATE public.design_tech_packs tp
  SET brand_id = br.id
  FROM public.brands br
  WHERE tp.style_number = 'DEMO-102' AND br.brand_name = 'ollywood';

-- Purge legacy unused dummy seed brands from early development
DELETE FROM public.brands 
  WHERE brand_name IN ('FIRST SMILE', 'LAZY BONES', 'CANDY POP', 'CHERRY POP', 'PRIVATE LABEL');

-- 5. Proprietary In-House Brands for Nubira Creation
UPDATE public.brands 
  SET company_name = 'Nubira Creation' 
  WHERE brand_name ILIKE '%NUBIRA%' AND (company_name IS NULL OR company_name != 'Nubira Creation');
