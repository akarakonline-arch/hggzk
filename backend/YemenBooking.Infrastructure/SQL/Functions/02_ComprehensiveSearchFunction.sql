-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة البحث الشاملة مع دعم كامل للبالغين والأطفال
-- Comprehensive Search Function with Full Adults/Children Support
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 
-- المميزات:
-- ✅ جميع العمليات في SQL فقط (لا معالجة في الذاكرة)
-- ✅ دعم البالغين والأطفال مع التحقق من UnitType
-- ✅ فلترة السعر بجميع العملات
-- ✅ البحث الجغرافي باستخدام PostGIS
-- ✅ الإتاحة من DailyUnitSchedule
-- ✅ الترتيب الديناميكي
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION search_units_comprehensive(
    -- ━━━ معايير البحث النصي ━━━
    p_search_text TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    
    -- ━━━ معايير التصنيف ━━━
    p_property_type_id UUID DEFAULT NULL,
    p_unit_type_id UUID DEFAULT NULL,
    
    -- ━━━ معايير التواريخ ━━━
    p_check_in DATE DEFAULT NULL,
    p_check_out DATE DEFAULT NULL,
    
    -- ━━━ معايير السعة (البالغين والأطفال) ━━━
    p_adults INTEGER DEFAULT NULL,
    p_children INTEGER DEFAULT NULL,
    p_guests_count INTEGER DEFAULT NULL, -- بديل إذا لم يتم تحديد adults/children
    
    -- ━━━ معايير السعر ━━━
    p_min_price NUMERIC DEFAULT NULL,
    p_max_price NUMERIC DEFAULT NULL,
    p_currency VARCHAR(3) DEFAULT 'YER',
    
    -- ━━━ معايير الجودة ━━━
    p_min_rating NUMERIC DEFAULT NULL,
    p_min_star_rating INTEGER DEFAULT NULL,
    
    -- ━━━ معايير جغرافية ━━━
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_radius_km DOUBLE PRECISION DEFAULT NULL,
    
    -- ━━━ معايير أخرى ━━━
    p_featured_only BOOLEAN DEFAULT FALSE,
    p_owner_id UUID DEFAULT NULL,
    
    -- ━━━ الترتيب والتصفح ━━━
    p_sort_by TEXT DEFAULT 'rating', -- rating, price_asc, price_desc, distance, newest
    p_page_number INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 20
) RETURNS TABLE(
    -- معلومات الوحدة
    unit_id UUID,
    unit_name TEXT,
    custom_features TEXT,
    max_capacity INTEGER,
    
    -- معلومات العقار
    property_id UUID,
    property_name TEXT,
    property_description TEXT,
    city TEXT,
    address TEXT,
    property_type_id UUID,
    property_type_name TEXT,
    star_rating INTEGER,
    is_featured BOOLEAN,
    owner_id UUID,
    
    -- معلومات نوع الوحدة
    unit_type_id UUID,
    unit_type_name TEXT,
    is_has_adults BOOLEAN,
    is_has_children BOOLEAN,
    is_multi_days BOOLEAN,
    
    -- التقييمات
    average_rating NUMERIC,
    reviews_count BIGINT,
    
    -- الصور
    main_image_url TEXT,
    unit_image_url TEXT,
    
    -- الموقع
    latitude NUMERIC,
    longitude NUMERIC,
    distance_km DOUBLE PRECISION,
    
    -- السعر
    min_price NUMERIC,
    price_currency VARCHAR(3),
    
    -- الإحصائيات
    total_count BIGINT,
    page_number INTEGER,
    total_pages INTEGER
) AS $$
DECLARE
    v_offset INTEGER;
    v_total_count BIGINT;
    v_total_pages INTEGER;
    v_effective_adults INTEGER;
    v_effective_children INTEGER;
    v_required_capacity INTEGER;
BEGIN
    -- ━━━ حساب السعة الفعلية ━━━
    v_effective_adults := COALESCE(p_adults, 0);
    v_effective_children := COALESCE(p_children, 0);
    
    -- إذا تم تحديد guests_count ولم يتم تحديد adults/children
    IF p_guests_count IS NOT NULL AND (p_adults IS NULL AND p_children IS NULL) THEN
        v_effective_adults := p_guests_count;
        v_effective_children := 0;
    END IF;
    
    v_required_capacity := v_effective_adults + v_effective_children;
    
    -- ━━━ حساب الـ offset ━━━
    v_offset := (p_page_number - 1) * p_page_size;
    
    -- ━━━ حساب العدد الكلي أولاً ━━━
    WITH filtered_units AS (
        SELECT u."Id"
        FROM "Units" u
        INNER JOIN "Properties" p ON u."PropertyId" = p."Id"
        INNER JOIN "PropertyTypes" pt ON p."TypeId" = pt."Id"
        INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."Id"
        WHERE 
            -- ━━━ فلتر الموافقة ━━━
            p."IsApproved" = true
            
            -- ━━━ فلتر المالك ━━━
            AND (p_owner_id IS NULL OR p."OwnerId" = p_owner_id)
            
            -- ━━━ فلتر المميز ━━━
            AND (NOT p_featured_only OR p."IsFeatured" = true)
            
            -- ━━━ فلتر المدينة ━━━
            AND (p_city IS NULL OR p."City" ILIKE p_city)
            
            -- ━━━ فلتر نوع العقار ━━━
            AND (p_property_type_id IS NULL OR p."TypeId" = p_property_type_id)
            
            -- ━━━ فلتر نوع الوحدة ━━━
            AND (p_unit_type_id IS NULL OR u."UnitTypeId" = p_unit_type_id)
            
            -- ━━━ فلتر التقييم ━━━
            AND (p_min_star_rating IS NULL OR p."StarRating" >= p_min_star_rating)
            
            -- ━━━ فلتر السعة (مع التحقق من دعم نوع الوحدة) ━━━
            AND (
                v_required_capacity = 0 
                OR (
                    -- التحقق من السعة القصوى
                    u."MaxCapacity" >= v_required_capacity
                    -- التحقق من دعم البالغين
                    AND (v_effective_adults = 0 OR ut."IsHasAdults" = true)
                    -- التحقق من دعم الأطفال
                    AND (v_effective_children = 0 OR ut."IsHasChildren" = true)
                )
            )
            
            -- ━━━ فلتر النص (Full-Text Search) ━━━
            AND (
                p_search_text IS NULL 
                OR to_tsvector('arabic', 
                    COALESCE(u."Name", '') || ' ' || 
                    COALESCE(p."Name", '') || ' ' || 
                    COALESCE(p."Description", '') || ' ' ||
                    COALESCE(p."City", '') || ' ' ||
                    COALESCE(ut."Name", '')
                ) @@ plainto_tsquery('arabic', p_search_text)
            )
            
            -- ━━━ فلتر السعر (دعم جميع العملات) ━━━
            AND (
                (p_min_price IS NULL AND p_max_price IS NULL)
                OR EXISTS (
                    SELECT 1
                    FROM "DailyUnitSchedules" ds
                    WHERE ds."UnitId" = u."Id"
                      AND ds."Currency" = p_currency
                      AND ds."Status" = 'Available'
                      AND ds."PriceAmount" IS NOT NULL
                      AND (p_min_price IS NULL OR ds."PriceAmount" >= p_min_price)
                      AND (p_max_price IS NULL OR ds."PriceAmount" <= p_max_price)
                      AND ds."Date" >= CURRENT_DATE
                      AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
                    LIMIT 1
                )
            )
            
            -- ━━━ فلتر الإتاحة (مع التحقق من السعة) ━━━
            AND (
                (p_check_in IS NULL OR p_check_out IS NULL)
                OR is_unit_available_with_capacity(
                    u."Id", 
                    p_check_in, 
                    p_check_out,
                    CASE WHEN v_effective_adults > 0 THEN v_effective_adults ELSE NULL END,
                    CASE WHEN v_effective_children > 0 THEN v_effective_children ELSE NULL END
                )
            )
            
            -- ━━━ فلتر جغرافي (PostGIS) ━━━
            AND (
                (p_latitude IS NULL OR p_longitude IS NULL OR p_radius_km IS NULL)
                OR ST_DWithin(
                    ST_SetSRID(ST_MakePoint(
                        CAST(p."Longitude" AS double precision),
                        CAST(p."Latitude" AS double precision)
                    ), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
                    p_radius_km * 1000 -- km to meters
                )
            )
    )
    SELECT COUNT(*) INTO v_total_count FROM filtered_units;
    
    -- حساب عدد الصفحات
    v_total_pages := CEILING(v_total_count::NUMERIC / p_page_size)::INTEGER;
    
    -- ━━━ إرجاع النتائج مع جميع البيانات ━━━
    RETURN QUERY
    SELECT 
        -- معلومات الوحدة
        u."Id" AS unit_id,
        u."Name" AS unit_name,
        u."CustomFeatures" AS custom_features,
        u."MaxCapacity" AS max_capacity,
        
        -- معلومات العقار
        p."Id" AS property_id,
        p."Name" AS property_name,
        p."Description" AS property_description,
        p."City" AS city,
        p."Address" AS address,
        p."TypeId" AS property_type_id,
        pt."Name" AS property_type_name,
        p."StarRating" AS star_rating,
        p."IsFeatured" AS is_featured,
        p."OwnerId" AS owner_id,
        
        -- معلومات نوع الوحدة
        ut."Id" AS unit_type_id,
        ut."Name" AS unit_type_name,
        ut."IsHasAdults" AS is_has_adults,
        ut."IsHasChildren" AS is_has_children,
        ut."IsMultiDays" AS is_multi_days,
        
        -- التقييمات (حساب في SQL)
        COALESCE(
            (SELECT AVG(r."Rating")
             FROM "Reviews" r
             WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
            0
        )::NUMERIC AS average_rating,
        
        COALESCE(
            (SELECT COUNT(*)
             FROM "Reviews" r
             WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
            0
        ) AS reviews_count,
        
        -- الصور (في SQL)
        (SELECT pi."Url"
         FROM "PropertyImages" pi
         WHERE pi."PropertyId" = p."Id" AND pi."IsMain" = true
         ORDER BY pi."DisplayOrder" ASC
         LIMIT 1
        ) AS main_image_url,
        
        (SELECT ui."Url"
         FROM "UnitImages" ui
         WHERE ui."UnitId" = u."Id" AND ui."IsMain" = true
         ORDER BY ui."DisplayOrder" ASC
         LIMIT 1
        ) AS unit_image_url,
        
        -- الموقع
        p."Latitude" AS latitude,
        p."Longitude" AS longitude,
        
        -- المسافة (حساب في SQL باستخدام PostGIS)
        CASE 
            WHEN p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
                calculate_distance_km(
                    p_latitude,
                    p_longitude,
                    CAST(p."Latitude" AS double precision),
                    CAST(p."Longitude" AS double precision)
                )
            ELSE NULL
        END AS distance_km,
        
        -- السعر (حساب في SQL)
        get_unit_min_price(u."Id", p_currency) AS min_price,
        p_currency AS price_currency,
        
        -- الإحصائيات
        v_total_count AS total_count,
        p_page_number AS page_number,
        v_total_pages AS total_pages
        
    FROM "Units" u
    INNER JOIN "Properties" p ON u."PropertyId" = p."Id"
    INNER JOIN "PropertyTypes" pt ON p."TypeId" = pt."Id"
    INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."Id"
    WHERE 
        -- ━━━ نفس الفلاتر السابقة ━━━
        p."IsApproved" = true
        AND (p_owner_id IS NULL OR p."OwnerId" = p_owner_id)
        AND (NOT p_featured_only OR p."IsFeatured" = true)
        AND (p_city IS NULL OR p."City" ILIKE p_city)
        AND (p_property_type_id IS NULL OR p."TypeId" = p_property_type_id)
        AND (p_unit_type_id IS NULL OR u."UnitTypeId" = p_unit_type_id)
        AND (p_min_star_rating IS NULL OR p."StarRating" >= p_min_star_rating)
        
        -- ━━━ فلتر السعة (البالغين والأطفال) ━━━
        AND (
            v_required_capacity = 0 
            OR (
                u."MaxCapacity" >= v_required_capacity
                AND (v_effective_adults = 0 OR ut."IsHasAdults" = true)
                AND (v_effective_children = 0 OR ut."IsHasChildren" = true)
            )
        )
        
        -- ━━━ فلتر النص ━━━
        AND (
            p_search_text IS NULL 
            OR to_tsvector('arabic', 
                COALESCE(u."Name", '') || ' ' || 
                COALESCE(p."Name", '') || ' ' || 
                COALESCE(p."Description", '') || ' ' ||
                COALESCE(p."City", '') || ' ' ||
                COALESCE(ut."Name", '')
            ) @@ plainto_tsquery('arabic', p_search_text)
        )
        
        -- ━━━ فلتر السعر ━━━
        AND (
            (p_min_price IS NULL AND p_max_price IS NULL)
            OR EXISTS (
                SELECT 1
                FROM "DailyUnitSchedules" ds
                WHERE ds."UnitId" = u."Id"
                  AND ds."Currency" = p_currency
                  AND ds."Status" = 'Available'
                  AND ds."PriceAmount" IS NOT NULL
                  AND (p_min_price IS NULL OR ds."PriceAmount" >= p_min_price)
                  AND (p_max_price IS NULL OR ds."PriceAmount" <= p_max_price)
                  AND ds."Date" >= CURRENT_DATE
                  AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
                LIMIT 1
            )
        )
        
        -- ━━━ فلتر الإتاحة ━━━
        AND (
            (p_check_in IS NULL OR p_check_out IS NULL)
            OR is_unit_available_with_capacity(
                u."Id", 
                p_check_in, 
                p_check_out,
                CASE WHEN v_effective_adults > 0 THEN v_effective_adults ELSE NULL END,
                CASE WHEN v_effective_children > 0 THEN v_effective_children ELSE NULL END
            )
        )
        
        -- ━━━ فلتر جغرافي ━━━
        AND (
            (p_latitude IS NULL OR p_longitude IS NULL OR p_radius_km IS NULL)
            OR ST_DWithin(
                ST_SetSRID(ST_MakePoint(
                    CAST(p."Longitude" AS double precision),
                    CAST(p."Latitude" AS double precision)
                ), 4326)::geography,
                ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
                p_radius_km * 1000
            )
        )
        
        -- ━━━ فلتر التقييم ━━━
        AND (
            p_min_rating IS NULL 
            OR COALESCE(
                (SELECT AVG(r."Rating")
                 FROM "Reviews" r
                 WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
                0
            ) >= p_min_rating
        )
        
    -- ━━━ الترتيب الديناميكي (في SQL) ━━━
    ORDER BY
        CASE 
            WHEN p_sort_by = 'distance' AND p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
                calculate_distance_km(
                    p_latitude, p_longitude,
                    CAST(p."Latitude" AS double precision),
                    CAST(p."Longitude" AS double precision)
                )
            ELSE 999999
        END ASC,
        
        CASE 
            WHEN p_sort_by = 'price_asc' THEN get_unit_min_price(u."Id", p_currency)
            ELSE 999999
        END ASC,
        
        CASE 
            WHEN p_sort_by = 'price_desc' THEN get_unit_min_price(u."Id", p_currency)
            ELSE 0
        END DESC,
        
        CASE 
            WHEN p_sort_by = 'rating' THEN
                COALESCE(
                    (SELECT AVG(r."Rating")
                     FROM "Reviews" r
                     WHERE r."PropertyId" = p."Id" AND r."IsApproved" = true),
                    0
                )
            ELSE 0
        END DESC,
        
        CASE 
            WHEN p_sort_by = 'newest' THEN u."CreatedAt"
            ELSE '2000-01-01'::timestamp
        END DESC,
        
        -- ترتيب افتراضي
        p."IsFeatured" DESC,
        p."StarRating" DESC,
        u."CreatedAt" DESC
        
    LIMIT p_page_size
    OFFSET v_offset;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة مساعدة لتحديث الـ Materialized View
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION refresh_search_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_searchable_units;
    RAISE NOTICE 'Search view refreshed successfully at %', now();
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to refresh search view: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
