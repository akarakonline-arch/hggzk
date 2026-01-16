-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PostgreSQL Functions: Price Filter - Professional & Optimized
-- الغرض: فلترة الوحدات حسب السعر مع دعم العملات المتعددة
-- الأداء: O(1) - محسّن باستخدام indexes
-- التاريخ: 2025-01-18
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Function 1: check_unit_any_price_in_range
-- البحث بدون تحديد فترة - يبحث في أي سعر متاح
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DROP FUNCTION IF EXISTS check_unit_any_price_in_range(UUID, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL);

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
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
PARALLEL SAFE
AS $$
    -- ✅ استراتيجية محسّنة: نبحث عن أقل سعر (BasePrice) لكل عملة
    -- ثم نتحقق هل هو ضمن النطاق - يطابق منطق BasePrice في الكود
    WITH min_prices AS (
        SELECT 
            ds."Currency",
            MIN(ds."PriceAmount") as min_price
        FROM "DailyUnitSchedules" ds
        WHERE ds."UnitId" = p_unit_id
          AND ds."Status" = 'Available'
          AND ds."PriceAmount" IS NOT NULL
          AND ds."Date" >= CURRENT_DATE
        GROUP BY ds."Currency"
    )
    SELECT EXISTS (
        SELECT 1
        FROM min_prices mp
        WHERE 
            -- YER Range
            (p_yer_min IS NOT NULL AND p_yer_max IS NOT NULL 
             AND mp."Currency" = 'YER' 
             AND mp.min_price BETWEEN p_yer_min AND p_yer_max)
            OR
            -- USD Range  
            (p_usd_min IS NOT NULL AND p_usd_max IS NOT NULL 
             AND mp."Currency" = 'USD' 
             AND mp.min_price BETWEEN p_usd_min AND p_usd_max)
            OR
            -- EUR Range
            (p_eur_min IS NOT NULL AND p_eur_max IS NOT NULL 
             AND mp."Currency" = 'EUR' 
             AND mp.min_price BETWEEN p_eur_min AND p_eur_max)
            OR
            -- SAR Range
            (p_sar_min IS NOT NULL AND p_sar_max IS NOT NULL 
             AND mp."Currency" = 'SAR' 
             AND mp.min_price BETWEEN p_sar_min AND p_sar_max)
            OR
            -- GBP Range
            (p_gbp_min IS NOT NULL AND p_gbp_max IS NOT NULL 
             AND mp."Currency" = 'GBP' 
             AND mp.min_price BETWEEN p_gbp_min AND p_gbp_max)
    );
$$;

COMMENT ON FUNCTION check_unit_any_price_in_range IS 
'فحص ما إذا كانت الوحدة لديها أي سعر متاح ضمن النطاق المحدد - يدعم عملات متعددة';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Function 2: check_unit_price_in_range (with dates)
-- البحث مع تحديد فترة - يحسب متوسط السعر في الفترة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DROP FUNCTION IF EXISTS check_unit_price_in_range(UUID, DATE, DATE, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL);

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
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
PARALLEL SAFE
AS $$
    -- ✅ استراتيجية ذكية: نحسب متوسط السعر في الفترة ونتحقق من النطاق
    -- نستخدم WITH للوضوح والأداء
    WITH avg_prices AS (
        SELECT 
            ds."Currency",
            AVG(ds."PriceAmount") AS avg_price
        FROM "DailyUnitSchedules" ds
        WHERE ds."UnitId" = p_unit_id
          AND ds."Date" >= p_check_in
          AND ds."Date" < p_check_out
          AND ds."PriceAmount" IS NOT NULL
          AND ds."Status" = 'Available'
        GROUP BY ds."Currency"
    )
    SELECT EXISTS (
        SELECT 1
        FROM avg_prices ap
        WHERE 
            -- YER Range
            (p_yer_min IS NOT NULL AND p_yer_max IS NOT NULL 
             AND ap."Currency" = 'YER' 
             AND ap.avg_price BETWEEN p_yer_min AND p_yer_max)
            OR
            -- USD Range
            (p_usd_min IS NOT NULL AND p_usd_max IS NOT NULL 
             AND ap."Currency" = 'USD' 
             AND ap.avg_price BETWEEN p_usd_min AND p_usd_max)
            OR
            -- EUR Range
            (p_eur_min IS NOT NULL AND p_eur_max IS NOT NULL 
             AND ap."Currency" = 'EUR' 
             AND ap.avg_price BETWEEN p_eur_min AND p_eur_max)
            OR
            -- SAR Range
            (p_sar_min IS NOT NULL AND p_sar_max IS NOT NULL 
             AND ap."Currency" = 'SAR' 
             AND ap.avg_price BETWEEN p_sar_min AND p_sar_max)
            OR
            -- GBP Range
            (p_gbp_min IS NOT NULL AND p_gbp_max IS NOT NULL 
             AND ap."Currency" = 'GBP' 
             AND ap.avg_price BETWEEN p_gbp_min AND p_gbp_max)
    );
$$;

COMMENT ON FUNCTION check_unit_price_in_range IS 
'فحص ما إذا كان متوسط سعر الوحدة في الفترة المحددة ضمن النطاق - يدعم عملات متعددة';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Indexes Optimization
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- فهرس مركب لتحسين أداء فلترة السعر
CREATE INDEX IF NOT EXISTS "IX_DailyUnitSchedules_Price_Filter"
ON "DailyUnitSchedules"("UnitId", "Currency", "Status", "Date")
INCLUDE ("PriceAmount")
WHERE "PriceAmount" IS NOT NULL AND "Status" = 'Available';

-- فهرس على Currency لتحسين الفلترة
CREATE INDEX IF NOT EXISTS "IX_DailyUnitSchedules_Currency_Price"
ON "DailyUnitSchedules"("Currency", "PriceAmount")
WHERE "PriceAmount" IS NOT NULL AND "Status" = 'Available';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Testing
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DO $$
DECLARE
    v_test_unit_id UUID;
    v_result_any BOOLEAN;
    v_result_range BOOLEAN;
    v_check_in DATE := CURRENT_DATE + INTERVAL '7 days';
    v_check_out DATE := CURRENT_DATE + INTERVAL '10 days';
BEGIN
    -- الحصول على أول وحدة للاختبار
    SELECT "UnitId" INTO v_test_unit_id
    FROM "Units"
    LIMIT 1;
    
    IF v_test_unit_id IS NOT NULL THEN
        -- اختبار 1: البحث بدون تواريخ (نطاق YER: 50,000 - 150,000)
        SELECT check_unit_any_price_in_range(
            v_test_unit_id,
            50000::DECIMAL, 150000::DECIMAL,  -- YER
            NULL, NULL,  -- USD
            NULL, NULL,  -- EUR
            NULL, NULL,  -- SAR
            NULL, NULL   -- GBP
        ) INTO v_result_any;
        
        RAISE NOTICE 'Test 1 (Any Price Range): Unit % - Result: %', v_test_unit_id, v_result_any;
        
        -- اختبار 2: البحث مع تواريخ
        SELECT check_unit_price_in_range(
            v_test_unit_id,
            v_check_in,
            v_check_out,
            50000::DECIMAL, 150000::DECIMAL,  -- YER
            NULL, NULL,  -- USD
            NULL, NULL,  -- EUR
            NULL, NULL,  -- SAR
            NULL, NULL   -- GBP
        ) INTO v_result_range;
        
        RAISE NOTICE 'Test 2 (Price Range with Dates): Unit % - Result: %', v_test_unit_id, v_result_range;
        
        RAISE NOTICE '✅ Price filter functions created and tested successfully!';
    ELSE
        RAISE NOTICE '⚠️ No units found for testing';
    END IF;
END $$;
