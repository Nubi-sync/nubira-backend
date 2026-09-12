-- ==============================================================================
-- 09_merchandising_inr_currency_update.sql
-- Division 02: Merchandising & Sourcing Desk
-- Migration: Update Default Commercial Currency to INR (₹) and Adjust Seed Pricing
-- ==============================================================================

-- 1. Update Default Currency on merchandising_orders table to INR
ALTER TABLE public.merchandising_orders 
    ALTER COLUMN currency SET DEFAULT 'INR';

-- 2. Update Seed Order PO-ZIG-8901 to INR Commercial Pricing
DO $$
DECLARE
    v_order_id UUID;
    v_vendor_id UUID;
BEGIN
    -- Resolve Order ID
    SELECT id INTO v_order_id 
    FROM public.merchandising_orders 
    WHERE order_number = 'PO-ZIG-8901' 
    LIMIT 1;

    -- Resolve Vendor ID (In-House Stitching or first active vendor)
    SELECT id INTO v_vendor_id 
    FROM public.vendors 
    WHERE vendor_code = 'OP-INHOUSE' 
    LIMIT 1;

    IF v_vendor_id IS NULL THEN
        SELECT id INTO v_vendor_id FROM public.vendors LIMIT 1;
    END IF;

    IF v_order_id IS NOT NULL THEN
        -- Update Master Order to INR and domestic unit price (₹750.00/pc)
        UPDATE public.merchandising_orders
        SET 
            currency = 'INR',
            fob_price_per_piece = 750.00,
            notes = 'Domestic & Export commercial contract in Indian National Rupees (INR ₹).'
        WHERE id = v_order_id;

        -- Delete old USD BOM items
        DELETE FROM public.merchandising_bom_costings WHERE order_id = v_order_id;

        -- Insert realistic Indian Garment Manufacturing BOM items (in ₹ INR)
        INSERT INTO public.merchandising_bom_costings (
            order_id, 
            item_category, 
            item_name, 
            supplier_vendor_id, 
            consumption_per_pc, 
            unit_of_measure, 
            planned_rate_per_unit, 
            planned_cost_per_pc, 
            actual_cost_per_pc, 
            notes
        ) VALUES
            (v_order_id, 'SHELL_FABRIC', 'Heavyweight French Terry 380 GSM Combed Cotton', v_vendor_id, 1.3500, 'KG', 310.00, 418.50, 415.00, '100% Cotton French Terry body fabric in INR'),
            (v_order_id, 'RIB_KNIT', '2x2 Lycra Rib 420 GSM Tone-on-Tone', v_vendor_id, 0.2500, 'KG', 280.00, 70.00, 70.00, 'Hem & cuff ribbing in INR'),
            (v_order_id, 'SEWING_THREAD', '100% Spun Polyester 40/2 Filament Thread', NULL, 0.0500, 'CONE', 60.00, 3.00, 3.00, 'Thread consumption across chainstitch & overlock'),
            (v_order_id, 'ACCESSORY', 'Flat Tubular Cotton Hood Drawcord 120cm with Aglet', NULL, 1.0000, 'PIECE', 18.00, 18.00, 18.00, 'Pre-shrunk knitted drawcord'),
            (v_order_id, 'ACCESSORY', 'Gunmetal Matte Stainless Steel Eyelets #4', NULL, 2.0000, 'PIECE', 4.00, 8.00, 8.00, 'Corrosion-resistant hood eyelets'),
            (v_order_id, 'PACKAGING', 'Self-Adhesive Recycled Polybag 14x18 + Warning', NULL, 1.0000, 'PIECE', 5.50, 5.50, 5.50, 'Individual master pack garment fold');

        RAISE NOTICE 'PO-ZIG-8901 and BOM costing successfully migrated to Indian Rupees (INR).';
    END IF;
END $$;

-- 3. Verification Query for INR Commercial Contract
SELECT 
    order_number,
    buyer_name,
    style_number,
    season,
    total_quantity,
    currency,
    fob_price_per_piece,
    total_contract_value,
    total_bom_cost_per_pc,
    total_garment_cost,
    gross_profit_margin_pct
FROM public.view_merchandising_order_economics
WHERE order_number = 'PO-ZIG-8901';
