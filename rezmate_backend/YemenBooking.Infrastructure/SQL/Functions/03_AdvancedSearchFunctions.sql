-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للبحث مع فلتر المرافق (Amenities)
-- Search with Amenities Filter (AND Logic)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION search_units_with_amenities(
    p_amenity_ids UUID[],
    p_search_text TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_property_type_id UUID DEFAULT NULL,
    p_unit_type_id UUID DEFAULT NULL,
    p_check_in DATE DEFAULT NULL,
    p_check_out DATE DEFAULT NULL,
    p_adults INTEGER DEFAULT NULL,
    p_children INTEGER DEFAULT NULL,
    p_min_price NUMERIC DEFAULT NULL,
    p_max_price NUMERIC DEFAULT NULL,
    p_currency VARCHAR(3) DEFAULT 'YER',
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_radius_km DOUBLE PRECISION DEFAULT NULL,
    p_sort_by TEXT DEFAULT 'rating',
    p_page_number INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 20
) RETURNS TABLE(
    unit_id UUID,
    property_id UUID,
    property_name TEXT,
    unit_name TEXT,
    city TEXT,
    min_price NUMERIC,
    average_rating NUMERIC,
    main_image_url TEXT,
    distance_km DOUBLE PRECISION,
    total_count BIGINT
) AS $$
DECLARE
    v_amenity_count INTEGER;
BEGIN
    v_amenity_count := array_length(p_amenity_ids, 1);
    
    -- إذا لم يتم تحديد amenities، استخدم البحث العادي
    IF v_amenity_count IS NULL OR v_amenity_count = 0 THEN
        RETURN QUERY
        SELECT 
            s.unit_id,
            s.property_id,
            s.property_name,
            s.unit_name,
            s.city,
            s.min_price,
            s.average_rating,
            s.main_image_url,
            s.distance_km,
            s.total_count
        FROM search_units_comprehensive(
            p_search_text, p_city, p_property_type_id, p_unit_type_id,
            p_check_in, p_check_out, p_adults, p_children, NULL,
            p_min_price, p_max_price, p_currency, NULL, NULL,
            p_latitude, p_longitude, p_radius_km, FALSE, NULL,
            p_sort_by, p_page_number, p_page_size
        ) s;
        RETURN;
    END IF;
    
    -- البحث مع فلتر المرافق (AND logic)
    RETURN QUERY
    SELECT 
        s.unit_id,
        s.property_id,
        s.property_name,
        s.unit_name,
        s.city,
        s.min_price,
        s.average_rating,
        s.main_image_url,
        s.distance_km,
        s.total_count
    FROM search_units_comprehensive(
        p_search_text, p_city, p_property_type_id, p_unit_type_id,
        p_check_in, p_check_out, p_adults, p_children, NULL,
        p_min_price, p_max_price, p_currency, NULL, NULL,
        p_latitude, p_longitude, p_radius_km, FALSE, NULL,
        p_sort_by, p_page_number, p_page_size
    ) s
    WHERE has_all_amenities(s.property_id, p_amenity_ids);
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- دالة للبحث مع فلتر الحقول الديناميكية
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION search_units_with_dynamic_fields(
    p_field_filters JSONB, -- {"fieldName": "value", "area": "50..150", "view": "~sea"}
    p_search_text TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_property_type_id UUID DEFAULT NULL,
    p_unit_type_id UUID DEFAULT NULL,
    p_check_in DATE DEFAULT NULL,
    p_check_out DATE DEFAULT NULL,
    p_adults INTEGER DEFAULT NULL,
    p_children INTEGER DEFAULT NULL,
    p_min_price NUMERIC DEFAULT NULL,
    p_max_price NUMERIC DEFAULT NULL,
    p_currency VARCHAR(3) DEFAULT 'YER',
    p_sort_by TEXT DEFAULT 'rating',
    p_page_number INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 20
) RETURNS TABLE(
    unit_id UUID,
    property_id UUID,
    property_name TEXT,
    unit_name TEXT,
    total_count BIGINT
) AS $$
DECLARE
    v_field_name TEXT;
    v_field_value TEXT;
    v_filter JSONB;
BEGIN
    RETURN QUERY
    SELECT 
        s.unit_id,
        s.property_id,
        s.property_name,
        s.unit_name,
        s.total_count
    FROM search_units_comprehensive(
        p_search_text, p_city, p_property_type_id, p_unit_type_id,
        p_check_in, p_check_out, p_adults, p_children, NULL,
        p_min_price, p_max_price, p_currency, NULL, NULL,
        NULL, NULL, NULL, FALSE, NULL,
        p_sort_by, p_page_number, p_page_size
    ) s
    WHERE 
        -- فلترة الحقول الديناميكية (كل filter يطبق AND)
        (
            p_field_filters IS NULL 
            OR jsonb_array_length(p_field_filters) = 0
            OR (
                SELECT COUNT(*) = jsonb_object_keys(p_field_filters)::INTEGER
                FROM jsonb_each_text(p_field_filters) AS filter(key, value)
                WHERE EXISTS (
                    SELECT 1
                    FROM "UnitFieldValues" fv
                    INNER JOIN "UnitTypeFields" f ON fv."UnitTypeFieldId" = f."Id"
                    WHERE fv."UnitId" = s.unit_id
                      AND f."FieldName" = filter.key
                      AND (
                          -- تطابق تام
                          (NOT filter.value LIKE '~%' AND NOT filter.value LIKE '%..%' 
                           AND fv."FieldValue" = filter.value)
                          -- بحث نصي جزئي
                          OR (filter.value LIKE '~%' 
                              AND fv."FieldValue" ILIKE '%' || substring(filter.value from 2) || '%')
                          -- نطاق رقمي
                          OR (filter.value LIKE '%..%' 
                              AND is_numeric_in_range(
                                  fv."FieldValue",
                                  split_part(filter.value, '..', 1)::NUMERIC,
                                  split_part(filter.value, '..', 2)::NUMERIC
                              ))
                      )
                )
            )
        );
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;
