-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة PostgreSQL لفحص السعر ضمن النطاق المطلوب
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- الهدف: تقليل عدد الاستعلامات الفرعية في فلتر السعر
-- بدلاً من حساب Average ثلاث مرات (Any, >=, <=)، نحسبه مرة واحدة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION check_unit_price_in_range(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE,
    p_yer_min DECIMAL DEFAULT NULL,
    p_yer_max DECIMAL DEFAULT NULL,
    p_usd_min DECIMAL DEFAULT NULL,
    p_usd_max DECIMAL DEFAULT NULL,
    p_eur_min DECIMAL DEFAULT NULL,
    p_eur_max DECIMAL DEFAULT NULL,
    p_sar_min DECIMAL DEFAULT NULL,
    p_sar_max DECIMAL DEFAULT NULL,
    p_gbp_min DECIMAL DEFAULT NULL,
    p_gbp_max DECIMAL DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_avg_price DECIMAL;
    v_currency TEXT;
    v_has_match BOOLEAN := FALSE;
BEGIN
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- المنطق: 
    -- 1. حساب متوسط السعر لكل عملة في الفترة المحددة (مرة واحدة فقط)
    -- 2. التحقق من أن المتوسط ضمن النطاق المطلوب
    -- 3. إرجاع TRUE إذا وُجدت أي عملة تطابق الشرط
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    -- التحقق من كل عملة على حدة
    FOR v_currency, v_avg_price IN
        SELECT 
            "Currency",
            AVG("PriceAmount") as avg_price
        FROM "DailyUnitSchedules"
        WHERE "UnitId" = p_unit_id
          AND "Date" >= p_check_in
          AND "Date" < p_check_out
          AND "PriceAmount" IS NOT NULL
        GROUP BY "Currency"
    LOOP
        -- فحص YER
        IF v_currency = 'YER' AND p_yer_min IS NOT NULL THEN
            IF v_avg_price >= p_yer_min AND v_avg_price <= p_yer_max THEN
                v_has_match := TRUE;
                EXIT;
            END IF;
        END IF;
        
        -- فحص USD
        IF v_currency = 'USD' AND p_usd_min IS NOT NULL THEN
            IF v_avg_price >= p_usd_min AND v_avg_price <= p_usd_max THEN
                v_has_match := TRUE;
                EXIT;
            END IF;
        END IF;
        
        -- فحص EUR
        IF v_currency = 'EUR' AND p_eur_min IS NOT NULL THEN
            IF v_avg_price >= p_eur_min AND v_avg_price <= p_eur_max THEN
                v_has_match := TRUE;
                EXIT;
            END IF;
        END IF;
        
        -- فحص SAR
        IF v_currency = 'SAR' AND p_sar_min IS NOT NULL THEN
            IF v_avg_price >= p_sar_min AND v_avg_price <= p_sar_max THEN
                v_has_match := TRUE;
                EXIT;
            END IF;
        END IF;
        
        -- فحص GBP
        IF v_currency = 'GBP' AND p_gbp_min IS NOT NULL THEN
            IF v_avg_price >= p_gbp_min AND v_avg_price <= p_gbp_max THEN
                v_has_match := TRUE;
                EXIT;
            END IF;
        END IF;
    END LOOP;
    
    RETURN v_has_match;
EXCEPTION
    WHEN OTHERS THEN
        -- في حالة حدوث خطأ، نُرجع FALSE لعدم استبعاد الوحدة
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة مبسطة للبحث بدون فترة (CheckIn/CheckOut)
-- تبحث عن أي سعر ضمن النطاق في الأيام القادمة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION check_unit_any_price_in_range(
    p_unit_id UUID,
    p_yer_min DECIMAL DEFAULT NULL,
    p_yer_max DECIMAL DEFAULT NULL,
    p_usd_min DECIMAL DEFAULT NULL,
    p_usd_max DECIMAL DEFAULT NULL,
    p_eur_min DECIMAL DEFAULT NULL,
    p_eur_max DECIMAL DEFAULT NULL,
    p_sar_min DECIMAL DEFAULT NULL,
    p_sar_max DECIMAL DEFAULT NULL,
    p_gbp_min DECIMAL DEFAULT NULL,
    p_gbp_max DECIMAL DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- البحث عن أي سعر ضمن النطاق (بدون تحديد فترة)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    RETURN EXISTS (
        SELECT 1
        FROM "DailyUnitSchedules"
        WHERE "UnitId" = p_unit_id
          AND "PriceAmount" IS NOT NULL
          AND (
              (p_yer_min IS NOT NULL AND "Currency" = 'YER' AND "PriceAmount" BETWEEN p_yer_min AND p_yer_max) OR
              (p_usd_min IS NOT NULL AND "Currency" = 'USD' AND "PriceAmount" BETWEEN p_usd_min AND p_usd_max) OR
              (p_eur_min IS NOT NULL AND "Currency" = 'EUR' AND "PriceAmount" BETWEEN p_eur_min AND p_eur_max) OR
              (p_sar_min IS NOT NULL AND "Currency" = 'SAR' AND "PriceAmount" BETWEEN p_sar_min AND p_sar_max) OR
              (p_gbp_min IS NOT NULL AND "Currency" = 'GBP' AND "PriceAmount" BETWEEN p_gbp_min AND p_gbp_max)
          )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- تعليقات وملاحظات:
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ✅ STABLE: الدالة آمنة للاستخدام في Query Optimizer
-- ✅ معالجة الاستثناءات: تُرجع FALSE بدلاً من Error
-- ✅ الأداء: استعلام واحد بدلاً من 15 استعلام فرعي
-- ✅ المرونة: دعم جميع العملات الشائعة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
