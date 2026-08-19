-- ============================================
-- STEP 13: RLS POLICIES (Access Rules)
-- ============================================
-- Yeh rules define karte hain ki kaun kya
-- dekh sakta hai aur kya edit kar sakta hai.
-- ============================================

-- ==================
-- PROFILES POLICIES
-- ==================
-- User apni profile dekh sake, Admin sabki
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT
  USING (id = auth.uid() OR get_my_role() = 'ADMIN');

-- Sirf Admin naya employee bana sake
CREATE POLICY "Admin can insert profiles" ON profiles FOR INSERT
  WITH CHECK (get_my_role() = 'ADMIN');

-- Sirf Admin kisi ki role change kar sake
CREATE POLICY "Admin can update any profile" ON profiles FOR UPDATE
  USING (get_my_role() = 'ADMIN');


-- ==================
-- ARTICLES POLICIES
-- ==================
-- Sabko articles dikhein (Lineman ko bhi allotment dekhne ke liye chahiye)
CREATE POLICY "Everyone can read articles" ON articles FOR SELECT
  USING (true);

-- Sirf Admin article create/edit/delete kar sake
CREATE POLICY "Admin can manage articles" ON articles FOR ALL
  USING (get_my_role() = 'ADMIN');


-- ==================
-- RATE HISTORY POLICIES
-- ==================
CREATE POLICY "Everyone can read rate history" ON rate_history FOR SELECT
  USING (true);

CREATE POLICY "Admin can insert rate history" ON rate_history FOR INSERT
  WITH CHECK (get_my_role() = 'ADMIN');


-- ==================
-- ALLOTMENTS POLICIES
-- ==================
-- Lineman sirf apni allotment dekhe, Admin sabki
CREATE POLICY "Lineman sees own allotments" ON allotments FOR SELECT
  USING (lineman_id = auth.uid() OR get_my_role() = 'ADMIN');

-- Sirf Admin allotment assign/edit/cancel kare
CREATE POLICY "Admin can manage allotments" ON allotments FOR ALL
  USING (get_my_role() = 'ADMIN');


-- ==================
-- DAILY PRODUCT POLICIES
-- ==================
-- Lineman sirf apna daily product log kare
CREATE POLICY "Lineman can insert own product" ON daily_product FOR INSERT
  WITH CHECK (lineman_id = auth.uid());

-- Lineman apne entries dekhe, Admin sabke
CREATE POLICY "Lineman sees own entries" ON daily_product FOR SELECT
  USING (lineman_id = auth.uid() OR get_my_role() = 'ADMIN');

-- Lineman sirf aaj ke entries edit kar sake (purane nahi)
CREATE POLICY "Lineman can update own entries" ON daily_product FOR UPDATE
  USING (lineman_id = auth.uid() AND entry_date = CURRENT_DATE);

-- Lineman sirf aaj ke entries delete kar sake
CREATE POLICY "Lineman can delete own today entries" ON daily_product FOR DELETE
  USING (lineman_id = auth.uid() AND entry_date = CURRENT_DATE);


-- ==================
-- QC LOGS POLICIES
-- ==================
-- Production aur Admin QC logs manage kar sakein
CREATE POLICY "Production can manage qc_logs" ON qc_logs FOR ALL
  USING (get_my_role() IN ('PRODUCTION', 'ADMIN'));

-- Sabko QC reports dikhein (reports ke liye)
CREATE POLICY "Everyone can read qc_logs" ON qc_logs FOR SELECT
  USING (true);


-- ==================
-- STORE TRANSACTIONS POLICIES
-- ==================
-- Store aur Admin transactions manage karein
CREATE POLICY "Store can manage transactions" ON store_transactions FOR ALL
  USING (get_my_role() IN ('STORE', 'ADMIN'));

-- Sabko store data dikhein (reports ke liye)
CREATE POLICY "Everyone can read store transactions" ON store_transactions FOR SELECT
  USING (true);


-- ==================
-- ACCESSORIES POLICIES
-- ==================
-- Sirf Store aur Admin accessories manage karein
CREATE POLICY "Store can manage accessories" ON accessories FOR ALL
  USING (get_my_role() IN ('STORE', 'ADMIN'));


-- ==================
-- COUNTING REPORTS POLICIES
-- ==================
-- Sirf Dispatch aur Admin counting manage karein
CREATE POLICY "Dispatch can manage counting" ON counting_reports FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));


-- ==================
-- DELIVERY CHALLANS POLICIES
-- ==================
-- Dispatch aur Admin challans manage karein
CREATE POLICY "Dispatch can manage challans" ON delivery_challans FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));

-- Sabko challans dikhein
CREATE POLICY "Everyone can read challans" ON delivery_challans FOR SELECT
  USING (true);


-- ==================
-- CHALLAN ITEMS POLICIES
-- ==================
-- Dispatch aur Admin challan items manage karein
CREATE POLICY "Dispatch can manage challan items" ON challan_items FOR ALL
  USING (get_my_role() IN ('DISPATCH', 'ADMIN'));

-- Sabko challan items dikhein
CREATE POLICY "Everyone can read challan items" ON challan_items FOR SELECT
  USING (true);


-- ============================================
-- SAB DONE! Table Editor mein har table ke
-- paas "Policies" tab mein rules dikhenge.
-- ============================================
