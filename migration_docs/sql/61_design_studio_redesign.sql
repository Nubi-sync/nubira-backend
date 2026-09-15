-- =============================================================================
-- Migration 61: Design Studio Redesign (Division 01)
-- 3-Tier Verification Pipeline (Designer -> Provisional Head -> Super Admin -> Tech Pack)
-- =============================================================================

-- 1. Design Team Members (PH assigns creative designers with 10-digit phone login)
CREATE TABLE IF NOT EXISTS design_team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ph_user_id UUID NOT NULL,              -- Provisional Head who added this member
  designer_user_id UUID,                 -- Supabase auth user id (linked auth.users)
  designer_name TEXT NOT NULL,
  phone_number TEXT,                     -- 10-digit mobile number e.g. '8010993993'
  username TEXT,                         -- creative unique username e.g. 'rahul_nubira'
  designer_email TEXT,                   -- internal auth email e.g. '8010993993@designer.nubira.local'
  designer_phone TEXT,                   -- alias for phone_number
  password_hash TEXT,                    -- credential storage
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REMOVED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure all columns exist if table was created in an earlier partial run
ALTER TABLE design_team_members
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS designer_email TEXT,
  ADD COLUMN IF NOT EXISTS designer_phone TEXT,
  ADD COLUMN IF NOT EXISTS password_hash TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'ACTIVE';

-- Ensure phone and username uniqueness per company
CREATE UNIQUE INDEX IF NOT EXISTS uq_design_team_member_phone ON design_team_members(company_name, phone_number) WHERE phone_number IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_design_team_member_username ON design_team_members(company_name, username) WHERE username IS NOT NULL;

-- 2. Design Briefs (PH allocates work to designers)
CREATE TABLE IF NOT EXISTS design_briefs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ph_user_id UUID NOT NULL,
  designer_member_id UUID REFERENCES design_team_members(id) ON DELETE SET NULL,
  garment_type TEXT NOT NULL,            -- T-Shirt, Suit, Pant, Hoodie, Polo, Jogger, etc.
  category TEXT NOT NULL,                -- Formal, Informal, Casual, Ethnic, Sportswear, etc.
  max_colors INTEGER NOT NULL DEFAULT 3,
  instructions TEXT,                     -- Free-form design instructions from PH
  status TEXT NOT NULL DEFAULT 'ALLOCATED' CHECK (status IN ('ALLOCATED', 'SUBMITTED', 'PH_APPROVED', 'PH_REJECTED', 'SA_APPROVED', 'SA_SAVED_FOR_LATER', 'TECH_PACK_CREATED')),
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Design Submissions (Designer submits up to 2 photos per brief)
CREATE TABLE IF NOT EXISTS design_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brief_id UUID REFERENCES design_briefs(id) ON DELETE CASCADE,
  designer_member_id UUID REFERENCES design_team_members(id) ON DELETE SET NULL,
  photo_url_1 TEXT NOT NULL,             -- Supabase Storage URL
  photo_url_2 TEXT,                      -- Supabase Storage URL (optional)
  designer_notes TEXT,
  ph_verdict TEXT NOT NULL DEFAULT 'PENDING' CHECK (ph_verdict IN ('PENDING', 'APPROVED', 'REJECTED')),
  ph_feedback TEXT,
  sa_verdict TEXT CHECK (sa_verdict IN ('APPROVED', 'SAVED_FOR_LATER', 'REJECTED')),
  sa_notes TEXT,
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ
);

-- 4. PH Body Part Code-Words Settings
CREATE TABLE IF NOT EXISTS design_body_part_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ph_user_id UUID NOT NULL,
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  code TEXT NOT NULL,                    -- e.g. 'BC', 'Ch1', 'SL', 'NK', 'WST'
  body_part_name TEXT NOT NULL,          -- e.g. 'Bicep', 'Chest', 'Sleeve Length', 'Neck Width'
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_ph_body_part_code UNIQUE(ph_user_id, code)
);

-- 5. PH BOM Component Codes (button color, sleeve type, trim specs)
CREATE TABLE IF NOT EXISTS design_bom_component_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ph_user_id UUID NOT NULL,
  company_name TEXT NOT NULL DEFAULT 'Nubira Creation',
  component_type TEXT NOT NULL,          -- 'BUTTON', 'SLEEVE', 'COLLAR', 'TRIM', 'ZIPPER', 'FABRIC', 'THREAD'
  component_spec TEXT NOT NULL,          -- e.g. 'Red Horn Button', 'Cut Sleeve', 'Full Sleeve', 'Rib Collar 2x2'
  code TEXT,                             -- Optional short code e.g. 'BTN-RED-01'
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Garment Body Part Templates (auto-fill presets)
CREATE TABLE IF NOT EXISTS design_garment_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  garment_type TEXT NOT NULL,            -- 'T-Shirt', 'Hoodie', 'Polo', 'Suit', 'Pant', 'Jogger'
  body_parts JSONB NOT NULL,             -- [{code: 'CH', name: 'Chest Width', default_tolerance: 1.0, default_grade_step: 2.0}]
  bom_defaults JSONB,                    -- [{type: 'BUTTON', spec: 'Standard Resin', code: 'BTN-01'}]
  is_system_template BOOLEAN DEFAULT TRUE,
  ph_user_id UUID,                       -- NULL for system templates
  company_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Extend existing design_tech_packs with 3-tier approval chain
ALTER TABLE design_tech_packs
  ADD COLUMN IF NOT EXISTS design_submission_id UUID REFERENCES design_submissions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_by_ph UUID,
  ADD COLUMN IF NOT EXISTS approved_by_sa BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS sa_verdict TEXT DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS company_name TEXT DEFAULT 'Nubira Creation';

-- -----------------------------------------------------------------------------
-- Indexes for Performance
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_design_team_members_ph ON design_team_members(ph_user_id);
CREATE INDEX IF NOT EXISTS idx_design_team_members_email ON design_team_members(designer_email);
CREATE INDEX IF NOT EXISTS idx_design_briefs_ph ON design_briefs(ph_user_id);
CREATE INDEX IF NOT EXISTS idx_design_briefs_designer ON design_briefs(designer_member_id);
CREATE INDEX IF NOT EXISTS idx_design_briefs_status ON design_briefs(status);
CREATE INDEX IF NOT EXISTS idx_design_submissions_brief ON design_submissions(brief_id);
CREATE INDEX IF NOT EXISTS idx_design_submissions_ph_verdict ON design_submissions(ph_verdict);
CREATE INDEX IF NOT EXISTS idx_design_submissions_sa_verdict ON design_submissions(sa_verdict);
CREATE INDEX IF NOT EXISTS idx_design_body_part_codes_ph ON design_body_part_codes(ph_user_id);
CREATE INDEX IF NOT EXISTS idx_design_bom_component_codes_ph ON design_bom_component_codes(ph_user_id);

-- -----------------------------------------------------------------------------
-- Seed System Garment Templates (Auto-fill Presets)
-- -----------------------------------------------------------------------------
INSERT INTO design_garment_templates (garment_type, body_parts, bom_defaults, is_system_template)
VALUES 
  ('T-Shirt', '[
    {"code": "CH", "name": "Chest Width (1\" below armhole)", "default_tolerance": 1.0, "default_grade_step": 2.5},
    {"code": "BL", "name": "Body Length (HSP to hem)", "default_tolerance": 1.0, "default_grade_step": 2.0},
    {"code": "SH", "name": "Across Shoulder", "default_tolerance": 0.5, "default_grade_step": 1.5},
    {"code": "SL", "name": "Sleeve Length", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "SO", "name": "Sleeve Opening", "default_tolerance": 0.5, "default_grade_step": 0.5},
    {"code": "NW", "name": "Neck Width", "default_tolerance": 0.5, "default_grade_step": 0.5},
    {"code": "ND", "name": "Front Neck Drop", "default_tolerance": 0.5, "default_grade_step": 0.5}
  ]'::jsonb, '[
    {"type": "FABRIC", "spec": "100% Combed Cotton Single Jersey 180 GSM", "code": "FAB-SJ-180"},
    {"type": "COLLAR", "spec": "1x1 Cotton Rib Neckband 2.0cm width", "code": "RIB-1X1"},
    {"type": "THREAD", "spec": "100% Spun Polyester 40/2 Core Spun", "code": "TH-SP-402"}
  ]'::jsonb, TRUE),

  ('Hoodie', '[
    {"code": "CH", "name": "Chest Width (1\" below armhole)", "default_tolerance": 1.5, "default_grade_step": 3.0},
    {"code": "BL", "name": "Body Length (HSP to hem)", "default_tolerance": 1.5, "default_grade_step": 2.5},
    {"code": "SH", "name": "Across Shoulder", "default_tolerance": 1.0, "default_grade_step": 2.0},
    {"code": "SL", "name": "Sleeve Length (including cuff)", "default_tolerance": 1.0, "default_grade_step": 1.5},
    {"code": "HW", "name": "Hood Width", "default_tolerance": 0.5, "default_grade_step": 0.5},
    {"code": "HH", "name": "Hood Height", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "PK", "name": "Kangaroo Pocket Width", "default_tolerance": 1.0, "default_grade_step": 1.5},
    {"code": "CW", "name": "Bottom Rib Cuff Height", "default_tolerance": 0.5, "default_grade_step": 0.0}
  ]'::jsonb, '[
    {"type": "FABRIC", "spec": "3-End French Terry 360 GSM Brushed Inside", "code": "FAB-FT-360"},
    {"type": "TRIM", "spec": "2x2 Heavy Spandex Rib Waist & Cuffs", "code": "RIB-2X2"},
    {"type": "TRIM", "spec": "Flat Braided Cotton Drawcord with Metal Tips", "code": "DRW-CRD-01"},
    {"type": "TRIM", "spec": "Gunmetal Eyelets 8mm", "code": "EYE-GM-08"}
  ]'::jsonb, TRUE),

  ('Polo', '[
    {"code": "CH", "name": "Chest Width", "default_tolerance": 1.0, "default_grade_step": 2.5},
    {"code": "BL", "name": "Body Length (HSP)", "default_tolerance": 1.0, "default_grade_step": 2.0},
    {"code": "SH", "name": "Across Shoulder", "default_tolerance": 0.5, "default_grade_step": 1.5},
    {"code": "SL", "name": "Short Sleeve Length", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "PL", "name": "Placket Length (3 Button)", "default_tolerance": 0.5, "default_grade_step": 0.0},
    {"code": "PW", "name": "Placket Width", "default_tolerance": 0.2, "default_grade_step": 0.0},
    {"code": "CL", "name": "Flat Knit Collar Width", "default_tolerance": 0.5, "default_grade_step": 0.5}
  ]'::jsonb, '[
    {"type": "FABRIC", "spec": "100% Cotton Pique 220 GSM", "code": "FAB-PIQ-220"},
    {"type": "COLLAR", "spec": "Jacquard / Flatknit Rib Collar", "code": "CLR-FK-01"},
    {"type": "BUTTON", "spec": "Mother of Pearl 4-Hole Buttons 18L", "code": "BTN-MOP-18L"}
  ]'::jsonb, TRUE),

  ('Pant', '[
    {"code": "WST", "name": "Waist Width (Relaxed)", "default_tolerance": 1.0, "default_grade_step": 2.5},
    {"code": "HIP", "name": "Hip Width (7\" below waistband)", "default_tolerance": 1.0, "default_grade_step": 2.5},
    {"code": "TH", "name": "Thigh Width (1\" below crotch)", "default_tolerance": 0.5, "default_grade_step": 1.5},
    {"code": "IN", "name": "Inseam Length", "default_tolerance": 1.0, "default_grade_step": 1.0},
    {"code": "OUT", "name": "Outseam Length (including waistband)", "default_tolerance": 1.0, "default_grade_step": 2.0},
    {"code": "FR", "name": "Front Rise (including waistband)", "default_tolerance": 0.5, "default_grade_step": 0.8},
    {"code": "BR", "name": "Back Rise (including waistband)", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "LO", "name": "Leg Opening", "default_tolerance": 0.5, "default_grade_step": 0.5}
  ]'::jsonb, '[
    {"type": "FABRIC", "spec": "98% Cotton 2% Elastane Twill 280 GSM", "code": "FAB-TWL-280"},
    {"type": "ZIPPER", "spec": "YKK #4 Metal Zipper Antique Brass 6\"", "code": "ZIP-YKK-M4"},
    {"type": "BUTTON", "spec": "Metal Shank Button 24L Tack", "code": "BTN-SHK-24L"}
  ]'::jsonb, TRUE),

  ('Suit', '[
    {"code": "CH", "name": "Chest Circumference", "default_tolerance": 1.0, "default_grade_step": 4.0},
    {"code": "WST", "name": "Jacket Waist Circumference", "default_tolerance": 1.0, "default_grade_step": 4.0},
    {"code": "BL", "name": "Back Length from Collar Seam", "default_tolerance": 0.5, "default_grade_step": 1.5},
    {"code": "SH", "name": "Across Shoulder", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "SL", "name": "Sleeve Outseam", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "BC", "name": "Bicep Width", "default_tolerance": 0.5, "default_grade_step": 1.0},
    {"code": "LP", "name": "Lapel Width (at widest point)", "default_tolerance": 0.3, "default_grade_step": 0.0}
  ]'::jsonb, '[
    {"type": "FABRIC", "spec": "Super 120s Wool Worsted 260 GSM", "code": "FAB-WOL-120"},
    {"type": "TRIM", "spec": "Viscose Bemberg Body Lining", "code": "LIN-BEM-01"},
    {"type": "BUTTON", "spec": "Natural Horn Buttons 32L (Front) & 24L (Sleeve)", "code": "BTN-HRN-01"},
    {"type": "TRIM", "spec": "Horsehair Floating Canvas Interlining", "code": "CNV-HR-01"}
  ]'::jsonb, TRUE)
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- Enable RLS and Policies
-- -----------------------------------------------------------------------------
ALTER TABLE design_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_briefs ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_body_part_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_bom_component_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_garment_templates ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to perform operations (tenant isolation handled at service layer & company_name)
DROP POLICY IF EXISTS "Allow all access to design_team_members for authenticated" ON design_team_members;
CREATE POLICY "Allow all access to design_team_members for authenticated" ON design_team_members FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to design_briefs for authenticated" ON design_briefs;
CREATE POLICY "Allow all access to design_briefs for authenticated" ON design_briefs FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to design_submissions for authenticated" ON design_submissions;
CREATE POLICY "Allow all access to design_submissions for authenticated" ON design_submissions FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to design_body_part_codes for authenticated" ON design_body_part_codes;
CREATE POLICY "Allow all access to design_body_part_codes for authenticated" ON design_body_part_codes FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to design_bom_component_codes for authenticated" ON design_bom_component_codes;
CREATE POLICY "Allow all access to design_bom_component_codes for authenticated" ON design_bom_component_codes FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to design_garment_templates for authenticated" ON design_garment_templates;
CREATE POLICY "Allow all access to design_garment_templates for authenticated" ON design_garment_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Allow anon access for read/write if using anon key in development
DROP POLICY IF EXISTS "Allow anon access to design_team_members" ON design_team_members;
CREATE POLICY "Allow anon access to design_team_members" ON design_team_members FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon access to design_briefs" ON design_briefs;
CREATE POLICY "Allow anon access to design_briefs" ON design_briefs FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon access to design_submissions" ON design_submissions;
CREATE POLICY "Allow anon access to design_submissions" ON design_submissions FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon access to design_body_part_codes" ON design_body_part_codes;
CREATE POLICY "Allow anon access to design_body_part_codes" ON design_body_part_codes FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon access to design_bom_component_codes" ON design_bom_component_codes;
CREATE POLICY "Allow anon access to design_bom_component_codes" ON design_bom_component_codes FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon access to design_garment_templates" ON design_garment_templates;
CREATE POLICY "Allow anon access to design_garment_templates" ON design_garment_templates FOR ALL TO anon USING (true) WITH CHECK (true);
