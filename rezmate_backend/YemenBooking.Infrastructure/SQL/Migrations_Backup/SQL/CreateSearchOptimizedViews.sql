-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Materialized View for Optimized Property Search
-- يجمع جميع البيانات المطلوبة للبحث في view واحد محسّن
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1️⃣ View للوحدات مع جميع البيانات المجمعة
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_searchable_units AS
SELECT 
    -- ━━━ معلومات الوحدة الأساسية ━━━
    u."Id" AS unit_id,
    u."Name" AS unit_name,
    u."PropertyId" AS property_id,
    u."UnitTypeId" AS unit_type_id,
    u."MaxCapacity" AS max_capacity,
    
    -- ━━━ معلومات العقار ━━━
    p."Name" AS property_name,
    p."City" AS city,
    p."Address" AS address,
    p."Description" AS property_description,
    p."TypeId" AS property_type_id,
    p."StarRating" AS star_rating,
    p."IsApproved" AS is_approved,
    p."IsFeatured" AS is_featured,
    p."OwnerId" AS owner_id,
    pt."Name" AS property_type_name,
    
    -- ━━━ الموقع الجغرافي (PostGIS) ━━━
    p."Latitude" AS latitude,
    p."Longitude" AS longitude,
    -- تحويل للـ Geography type للبحث السريع
    ST_SetSRID(ST_MakePoint(
        CAST(p."Longitude" AS double precision),
        CAST(p."Latitude" AS double precision)
    ), 4326)::geography AS location_point,
    
    -- ━━━ نوع الوحدة ━━━
    ut."Name" AS unit_type_name,
    ut."IsHasAdults" AS is_has_adults,
    ut."IsHasChildren" AS is_has_children,
    ut."IsMultiDays" AS is_multi_days,
    
    -- ━━━ التقييمات ━━━
    COALESCE(
        (SELECT AVG(r."Rating")
         FROM "Reviews" r
         WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
        0
    ) AS average_rating,
    
    COALESCE(
        (SELECT COUNT(*)
         FROM "Reviews" r
         WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
        0
    ) AS reviews_count,
    
    -- ━━━ الصورة الرئيسية ━━━
    (SELECT pi."Url"
     FROM "PropertyImages" pi
     WHERE pi."PropertyId" = p."Id"
     ORDER BY pi."DisplayOrder" ASC, pi."Id" ASC
     LIMIT 1
    ) AS main_image_url,
    
    -- ━━━ السعر (من DailyUnitSchedule) ━━━
    -- أقل سعر متاح
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."Id" 
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price,
    
    -- العملة الافتراضية
    (SELECT ds."Currency"
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."Id" 
       AND ds."PriceAmount" IS NOT NULL
     ORDER BY ds."Date" ASC
     LIMIT 1
    ) AS default_currency,
    
    -- ━━━ عدد المرافق ━━━
    (SELECT COUNT(DISTINCT pa."PropertyTypeAmenityId")
     FROM "PropertyAmenities" pa
     WHERE pa."PropertyId" = p."Id"
    ) AS amenities_count,
    
    -- ━━━ Full-Text Search Vector ━━━
    to_tsvector('arabic', COALESCE(u."Name", '') || ' ' || 
                         COALESCE(p."Name", '') || ' ' || 
                         COALESCE(p."Description", '') || ' ' ||
                         COALESCE(p."City", '')) AS search_vector,
    
    -- ━━━ تاريخ آخر تحديث ━━━
    GREATEST(
        COALESCE(u."UpdatedAt", u."CreatedAt"),
        COALESCE(p."UpdatedAt", p."CreatedAt")
    ) AS last_updated

FROM "Units" u
INNER JOIN "Properties" p ON u."PropertyId" = p."Id"
INNER JOIN "PropertyTypes" pt ON p."TypeId" = pt."Id"
INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."Id"
WHERE p."IsApproved" = true;

-- Index للـ Materialized View
CREATE INDEX idx_mv_searchable_units_city ON mv_searchable_units(city);
CREATE INDEX idx_mv_searchable_units_property_type ON mv_searchable_units(property_type_id);
CREATE INDEX idx_mv_searchable_units_unit_type ON mv_searchable_units(unit_type_id);
CREATE INDEX idx_mv_searchable_units_price ON mv_searchable_units(min_price) WHERE min_price IS NOT NULL;
CREATE INDEX idx_mv_searchable_units_rating ON mv_searchable_units(average_rating);
CREATE INDEX idx_mv_searchable_units_location ON mv_searchable_units USING GIST(location_point);
CREATE INDEX idx_mv_searchable_units_search ON mv_searchable_units USING GIN(search_vector);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2️⃣ دالة للبحث الجغرافي السريع (PostGIS)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 double precision,
    lng1 double precision,
    lat2 double precision,
    lng2 double precision
) RETURNS double precision AS $$
BEGIN
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(lng1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lng2, lat2), 4326)::geography
    ) / 1000.0; -- تحويل من متر لكيلومتر
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3️⃣ دالة لحساب السعر الإجمالي من DailyUnitSchedule
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION calculate_total_price(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE,
    p_currency VARCHAR(3) DEFAULT 'YER'
) RETURNS TABLE(
    total_price NUMERIC,
    currency VARCHAR(3),
    nights_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(ds."PriceAmount"), 0) AS total_price,
        COALESCE(MAX(ds."Currency"), p_currency) AS currency,
        COUNT(*)::INTEGER AS nights_count
    FROM "DailyUnitSchedules" ds
    WHERE ds."UnitId" = p_unit_id
      AND ds."Date" >= p_check_in
      AND ds."Date" < p_check_out
      AND ds."PriceAmount" IS NOT NULL
      AND ds."Status" = 'Available';
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4️⃣ دالة للتحقق من الإتاحة
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION is_unit_available(
    p_unit_id UUID,
    p_check_in DATE,
    p_check_out DATE
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1
        FROM "DailyUnitSchedules" ds
        WHERE ds."UnitId" = p_unit_id
          AND ds."Date" >= p_check_in
          AND ds."Date" < p_check_out
          AND ds."Status" <> 'Available'
    );
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5️⃣ دالة للبحث الشامل (كل شيء في SQL)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION search_units(
    p_search_text TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_property_type_id UUID DEFAULT NULL,
    p_unit_type_id UUID DEFAULT NULL,
    p_check_in DATE DEFAULT NULL,
    p_check_out DATE DEFAULT NULL,
    p_min_price NUMERIC DEFAULT NULL,
    p_max_price NUMERIC DEFAULT NULL,
    p_currency VARCHAR(3) DEFAULT 'YER',
    p_min_capacity INTEGER DEFAULT NULL,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_radius_km DOUBLE PRECISION DEFAULT NULL,
    p_min_rating NUMERIC DEFAULT NULL,
    p_page_number INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 20
) RETURNS TABLE(
    unit_id UUID,
    unit_name TEXT,
    property_id UUID,
    property_name TEXT,
    city TEXT,
    property_type_name TEXT,
    unit_type_name TEXT,
    min_price NUMERIC,
    default_currency VARCHAR(3),
    average_rating NUMERIC,
    reviews_count BIGINT,
    main_image_url TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    distance_km DOUBLE PRECISION,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_total_count BIGINT;
BEGIN
    v_offset := (p_page_number - 1) * p_page_size;
    
    -- حساب العدد الكلي أولاً
    SELECT COUNT(*) INTO v_total_count
    FROM mv_searchable_units u
    WHERE 
        -- فلتر النص
        (p_search_text IS NULL OR search_vector @@ plainto_tsquery('arabic', p_search_text))
        -- فلتر المدينة
        AND (p_city IS NULL OR u.city ILIKE p_city)
        -- فلتر نوع العقار
        AND (p_property_type_id IS NULL OR u.property_type_id = p_property_type_id)
        -- فلتر نوع الوحدة
        AND (p_unit_type_id IS NULL OR u.unit_type_id = p_unit_type_id)
        -- فلتر السعة
        AND (p_min_capacity IS NULL OR u.max_capacity >= p_min_capacity)
        -- فلتر السعر
        AND (p_min_price IS NULL OR u.min_price >= p_min_price)
        AND (p_max_price IS NULL OR u.min_price <= p_max_price)
        -- فلتر التقييم
        AND (p_min_rating IS NULL OR u.average_rating >= p_min_rating)
        -- فلتر الإتاحة (إذا تم تحديد تواريخ)
        AND (
            (p_check_in IS NULL OR p_check_out IS NULL) 
            OR is_unit_available(u.unit_id, p_check_in, p_check_out)
        )
        -- فلتر جغرافي (PostGIS)
        AND (
            (p_latitude IS NULL OR p_longitude IS NULL OR p_radius_km IS NULL)
            OR ST_DWithin(
                u.location_point,
                ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
                p_radius_km * 1000 -- تحويل km لـ meters
            )
        );
    
    -- إرجاع النتائج
    RETURN QUERY
    SELECT 
        u.unit_id,
        u.unit_name,
        u.property_id,
        u.property_name,
        u.city,
        u.property_type_name,
        u.unit_type_name,
        u.min_price,
        u.default_currency,
        u.average_rating,
        u.reviews_count,
        u.main_image_url,
        u.latitude,
        u.longitude,
        -- حساب المسافة في SQL (PostGIS)
        CASE 
            WHEN p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
                ST_Distance(
                    u.location_point,
                    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
                ) / 1000.0
            ELSE NULL
        END AS distance_km,
        v_total_count AS total_count
    FROM mv_searchable_units u
    WHERE 
        (p_search_text IS NULL OR search_vector @@ plainto_tsquery('arabic', p_search_text))
        AND (p_city IS NULL OR u.city ILIKE p_city)
        AND (p_property_type_id IS NULL OR u.property_type_id = p_property_type_id)
        AND (p_unit_type_id IS NULL OR u.unit_type_id = p_unit_type_id)
        AND (p_min_capacity IS NULL OR u.max_capacity >= p_min_capacity)
        AND (p_min_price IS NULL OR u.min_price >= p_min_price)
        AND (p_max_price IS NULL OR u.min_price <= p_max_price)
        AND (p_min_rating IS NULL OR u.average_rating >= p_min_rating)
        AND (
            (p_check_in IS NULL OR p_check_out IS NULL) 
            OR is_unit_available(u.unit_id, p_check_in, p_check_out)
        )
        AND (
            (p_latitude IS NULL OR p_longitude IS NULL OR p_radius_km IS NULL)
            OR ST_DWithin(
                u.location_point,
                ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
                p_radius_km * 1000
            )
        )
    ORDER BY
        -- ترتيب حسب المسافة إذا كان بحث جغرافي
        CASE 
            WHEN p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
                ST_Distance(
                    u.location_point,
                    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
                )
            ELSE 999999999
        END,
        -- ثم حسب التقييم
        u.average_rating DESC,
        -- ثم حسب السعر
        u.min_price ASC
    LIMIT p_page_size
    OFFSET v_offset;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6️⃣ دالة لتحديث الـ Materialized View
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION refresh_search_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_searchable_units;
END;
$$ LANGUAGE plpgsql;

-- إنشاء Trigger للتحديث التلقائي (اختياري)
-- يمكن تشغيلها كل ساعة عبر Cron Job
