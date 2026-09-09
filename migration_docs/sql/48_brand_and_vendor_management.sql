-- ==============================================================================
-- 48_brand_and_vendor_management.sql
-- Brand Master & Multi-Vendor / Job-Worker Management
-- ==============================================================================

-- 1. Create brands Master Table
CREATE TABLE IF NOT EXISTS public.brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_code TEXT UNIQUE NOT NULL,
    brand_name TEXT UNIQUE NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    city TEXT,
    address TEXT,
    gstin TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Seed default brands
INSERT INTO public.brands (brand_code, brand_name, contact_person, city)
VALUES 
  ('OP', 'OLLYPOP', 'Merchandising Team', 'Kolkata'),
  ('FS', 'FIRST SMILE', 'Buyer Office', 'Kolkata'),
  ('LB', 'LAZY BONES', 'Commercial Dept', 'Kolkata'),
  ('CP', 'CANDY POP', 'Merchandiser', 'Kolkata'),
  ('NB', 'NUBIRA IN-HOUSE', 'Factory Production', 'Kolkata'),
  ('CH', 'CHERRY POP', 'Sales Agent', 'Kolkata')
ON CONFLICT (brand_name) DO NOTHING;

-- 3. Create vendors Master Table
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_code TEXT UNIQUE NOT NULL,
    vendor_name TEXT NOT NULL,
    brand_id UUID REFERENCES public.brands(id) ON DELETE SET NULL,
    brand_name TEXT NOT NULL,
    vendor_type TEXT NOT NULL DEFAULT 'STITCHING_JOB_WORK' 
      CHECK (vendor_type IN ('STITCHING_JOB_WORK', 'FABRIC_SUPPLIER', 'TRIMS_ACCESSORIES', 'PRINTING_EMBROIDERY', 'WASHING_FINISHING')),
    contact_person TEXT,
    phone TEXT,
    city TEXT,
    address TEXT,
    gst_no TEXT,
    stitching_rate NUMERIC DEFAULT 20.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Seed initial standard vendors for OLLYPOP
DO $$
DECLARE
  v_brand_id UUID;
BEGIN
  SELECT id INTO v_brand_id FROM public.brands WHERE brand_name = 'OLLYPOP' LIMIT 1;

  IF v_brand_id IS NOT NULL THEN
    INSERT INTO public.vendors (vendor_code, vendor_name, brand_id, brand_name, vendor_type, contact_person, stitching_rate)
    VALUES 
      ('OP-INHOUSE', 'In-House Stitching Unit', v_brand_id, 'OLLYPOP', 'STITCHING_JOB_WORK', 'Factory Line Master', 20.00),
      ('OP-VND-01', 'Shanti Garments (Unit-01)', v_brand_id, 'OLLYPOP', 'STITCHING_JOB_WORK', 'Master Shanti', 22.00),
      ('OP-VND-02', 'Star Apparel (Unit-02)', v_brand_id, 'OLLYPOP', 'STITCHING_JOB_WORK', 'Irfan Bhai', 20.00)
    ON CONFLICT (vendor_code) DO NOTHING;
  END IF;
END $$;

-- 5. Add vendor columns to challans table
ALTER TABLE public.challans 
ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS vendor_name TEXT;

-- 6. Add vendor column to allotments table
ALTER TABLE public.allotments 
ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL;

-- 7. Add vendor columns to delivery_challans table (Dispatch)
ALTER TABLE public.delivery_challans 
ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS vendor_name TEXT;

-- 8. Enable Row Level Security (RLS)
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

-- 9. Permissive RLS Policies for Web Admin & Mobile App
DROP POLICY IF EXISTS "Allow all for brands" ON public.brands;
CREATE POLICY "Allow all for brands" ON public.brands FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for vendors" ON public.vendors;
CREATE POLICY "Allow all for vendors" ON public.vendors FOR ALL USING (true) WITH CHECK (true);

-- 10. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_brands_brand_name ON public.brands(brand_name);
CREATE INDEX IF NOT EXISTS idx_vendors_brand_name ON public.vendors(brand_name);
CREATE INDEX IF NOT EXISTS idx_vendors_brand_id ON public.vendors(brand_id);
CREATE INDEX IF NOT EXISTS idx_vendors_vendor_type ON public.vendors(vendor_type);
CREATE INDEX IF NOT EXISTS idx_challans_vendor_id ON public.challans(vendor_id);
CREATE INDEX IF NOT EXISTS idx_allotments_vendor_id ON public.allotments(vendor_id);
CREATE INDEX IF NOT EXISTS idx_delivery_challans_vendor_id ON public.delivery_challans(vendor_id);
