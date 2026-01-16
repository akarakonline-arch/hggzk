-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة التحقق من الإتاحة مع دعم البالغين والأطفال
-- Function to check unit availability with adults and children support
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION is_unit_available_with_capacity(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE,
    p_adults INTEGER DEFAULT NULL,
    p_children INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_max_capacity INTEGER;
    v_required_capacity INTEGER;
    v_unit_type_allows_adults BOOLEAN;
    v_unit_type_allows_children BOOLEAN;
BEGIN
    -- ━━━ 1. جلب معلومات الوحدة والنوع ━━━
    SELECT 
        u."MaxCapacity",
        ut."IsHasAdults",
        ut."IsHasChildren"
    INTO 
        v_max_capacity,
        v_unit_type_allows_adults,
        v_unit_type_allows_children
    FROM "Units" u
    INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."Id"
    WHERE u."Id" = p_unit_id;
    
    -- إذا لم توجد الوحدة
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- ━━━ 2. التحقق من دعم نوع الوحدة للبالغين والأطفال ━━━
    IF p_adults IS NOT NULL AND p_adults > 0 AND NOT v_unit_type_allows_adults THEN
        RETURN FALSE; -- نوع الوحدة لا يدعم البالغين
    END IF;
    
    IF p_children IS NOT NULL AND p_children > 0 AND NOT v_unit_type_allows_children THEN
        RETURN FALSE; -- نوع الوحدة لا يدعم الأطفال
    END IF;
    
    -- ━━━ 3. حساب السعة المطلوبة ━━━
    v_required_capacity := COALESCE(p_adults, 0) + COALESCE(p_children, 0);
    
    -- التحقق من السعة القصوى
    IF v_required_capacity > 0 AND v_required_capacity > v_max_capacity THEN
        RETURN FALSE; -- السعة المطلوبة أكبر من السعة القصوى
    END IF;
    
    -- ━━━ 4. التحقق من الإتاحة في التواريخ المحددة ━━━
    IF p_check_in IS NULL OR p_check_out IS NULL THEN
        -- إذا لم يتم تحديد تواريخ، نعتبر الوحدة متاحة
        RETURN TRUE;
    END IF;
    
    -- التحقق من عدم وجود حجوزات مانعة في الفترة المطلوبة
    RETURN NOT EXISTS (
        SELECT 1
        FROM "DailyUnitSchedules" ds
        LEFT JOIN "Bookings" b ON b."Id" = ds."BookingId"
        WHERE ds."UnitId" = p_unit_id
          AND ds."Date" >= p_check_in
          AND ds."Date" < p_check_out
          AND (
              ds."Status" = 'Blocked'
              OR (
                  ds."Status" = 'Booked'
                  AND (
                      ds."BookingId" IS NULL
                      OR b."Status" IN (0, 3, 4) -- Confirmed, Completed, CheckedIn
                  )
              )
          )
    );
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة التحقق من الإتاحة البسيطة (بدون سعة)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION is_unit_available(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_check_in IS NULL OR p_check_out IS NULL THEN
        RETURN TRUE;
    END IF;
    
    RETURN NOT EXISTS (
        SELECT 1
        FROM "DailyUnitSchedules" ds
        LEFT JOIN "Bookings" b ON b."Id" = ds."BookingId"
        WHERE ds."UnitId" = p_unit_id
          AND ds."Date" >= p_check_in
          AND ds."Date" < p_check_out
          AND (
              ds."Status" = 'Blocked'
              OR (
                  ds."Status" = 'Booked'
                  AND (
                      ds."BookingId" IS NULL
                      OR b."Status" IN (0, 3, 4) -- Confirmed, Completed, CheckedIn
                  )
              )
          )
    );
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للبحث الجغرافي باستخدام PostGIS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 double precision,
    lng1 double precision,
    lat2 double precision,
    lng2 double precision
) RETURNS double precision AS $$
BEGIN
    -- استخدام PostGIS للحساب الدقيق
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(lng1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lng2, lat2), 4326)::geography
    ) / 1000.0; -- تحويل من متر لكيلومتر
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للتحقق من أن القيمة رقمية ضمن نطاق
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION is_numeric_in_range(
    value TEXT,
    min_value NUMERIC,
    max_value NUMERIC
) RETURNS BOOLEAN AS $$
BEGIN
    -- التحقق من أن القيمة رقمية والتحويل والمقارنة
    RETURN (value ~ '^[0-9]+(\.[0-9]+)?$') AND 
           (value::NUMERIC BETWEEN min_value AND max_value);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة لحساب السعر الإجمالي من DailyUnitSchedule
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION calculate_total_price(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE,
    p_currency VARCHAR(3) DEFAULT 'YER'
) RETURNS TABLE(
    total_price NUMERIC,
    currency VARCHAR(3),
    nights_count INTEGER,
    average_per_night NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(ds."PriceAmount"), 0) AS total_price,
        COALESCE(MAX(ds."Currency"), p_currency) AS currency,
        COUNT(*)::INTEGER AS nights_count,
        CASE 
            WHEN COUNT(*) > 0 THEN COALESCE(AVG(ds."PriceAmount"), 0)
            ELSE 0
        END AS average_per_night
    FROM "DailyUnitSchedules" ds
    WHERE ds."UnitId" = p_unit_id
      AND ds."Date" >= p_check_in
      AND ds."Date" < p_check_out
      AND ds."PriceAmount" IS NOT NULL
      AND ds."Status" = 'Available';
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للحصول على أقل سعر للوحدة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION get_unit_min_price(
    p_unit_id UUID,
    p_currency VARCHAR(3) DEFAULT 'YER'
) RETURNS NUMERIC AS $$
DECLARE
    v_min_price NUMERIC;
BEGIN
    SELECT MIN(ds."PriceAmount")
    INTO v_min_price
    FROM "DailyUnitSchedules" ds
    WHERE ds."UnitId" = p_unit_id
      AND ds."Currency" = p_currency
      AND ds."PriceAmount" IS NOT NULL
      AND ds."Status" = 'Available'
      AND ds."Date" >= CURRENT_DATE
      AND ds."Date" < CURRENT_DATE + INTERVAL '90 days';
    
    RETURN COALESCE(v_min_price, 0);
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للتحقق من المرافق المطلوبة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION has_all_amenities(
    p_property_id UUID,
    p_amenity_ids UUID[]
) RETURNS BOOLEAN AS $$
DECLARE
    v_required_count INTEGER;
    v_actual_count INTEGER;
BEGIN
    v_required_count := array_length(p_amenity_ids, 1);
    
    IF v_required_count IS NULL OR v_required_count = 0 THEN
        RETURN TRUE;
    END IF;
    
    SELECT COUNT(DISTINCT pta."AmenityId")
    INTO v_actual_count
    FROM "PropertyAmenities" pa
    INNER JOIN "PropertyTypeAmenities" pta ON pa."PropertyTypeAmenityId" = pta."Id"
    WHERE pa."PropertyId" = p_property_id
      AND pta."AmenityId" = ANY(p_amenity_ids);
    
    RETURN v_actual_count = v_required_count;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة لتحويل العملة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION convert_currency(
    p_amount NUMERIC,
    p_from_currency VARCHAR(3),
    p_to_currency VARCHAR(3)
) RETURNS NUMERIC AS $$
DECLARE
    v_from_rate NUMERIC;
    v_to_rate NUMERIC;
    v_default_currency VARCHAR(3);
BEGIN
    -- إذا كانت نفس العملة
    IF p_from_currency = p_to_currency THEN
        RETURN p_amount;
    END IF;
    
    -- الحصول على العملة الافتراضية
    SELECT "Code" INTO v_default_currency
    FROM "Currencies"
    WHERE "IsDefault" = true
    LIMIT 1;
    
    -- إذا From هي الافتراضية
    IF p_from_currency = v_default_currency THEN
        SELECT "ExchangeRate" INTO v_to_rate
        FROM "Currencies"
        WHERE "Code" = p_to_currency;
        
        RETURN ROUND(p_amount * COALESCE(v_to_rate, 1), 4);
    END IF;
    
    -- إذا To هي الافتراضية
    IF p_to_currency = v_default_currency THEN
        SELECT "ExchangeRate" INTO v_from_rate
        FROM "Currencies"
        WHERE "Code" = p_from_currency;
        
        RETURN ROUND(p_amount / COALESCE(v_from_rate, 1), 4);
    END IF;
    
    -- التحويل عبر العملة الافتراضية
    SELECT "ExchangeRate" INTO v_from_rate
    FROM "Currencies"
    WHERE "Code" = p_from_currency;
    
    SELECT "ExchangeRate" INTO v_to_rate
    FROM "Currencies"
    WHERE "Code" = p_to_currency;
    
    RETURN ROUND(p_amount / COALESCE(v_from_rate, 1) * COALESCE(v_to_rate, 1), 4);
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;
