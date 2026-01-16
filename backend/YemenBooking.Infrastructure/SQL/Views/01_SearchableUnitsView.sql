-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Materialized View للبحث المحسّن
-- Optimized Search Materialized View with Adults/Children Support
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DROP MATERIALIZED VIEW IF EXISTS mv_searchable_units CASCADE;

CREATE MATERIALIZED VIEW mv_searchable_units AS
SELECT 
    -- ━━━ معلومات الوحدة الأساسية ━━━
    u."UnitId" AS unit_id,
    u."Name" AS unit_name,
    u."PropertyId" AS property_id,
    u."UnitTypeId" AS unit_type_id,
    u."MaxCapacity" AS max_capacity,
    u."CustomFeatures" AS custom_features,
    
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
    
    -- ━━━ الموقع الجغرافي ━━━
    p."Latitude" AS latitude,
    p."Longitude" AS longitude,
    point(CAST(p."Longitude" AS float8), CAST(p."Latitude" AS float8)) AS location_point,
    
    -- ━━━ نوع الوحدة ━━━
    ut."Name" AS unit_type_name,
    ut."IsHasAdults" AS is_has_adults,
    ut."IsHasChildren" AS is_has_children,
    ut."IsMultiDays" AS is_multi_days,
    ut."IsRequiredToDetermineTheHour" AS is_required_hour,
    
    -- ━━━ التقييمات ━━━
    COALESCE(
        (SELECT AVG(r."AverageRating")
         FROM "Reviews" r
         WHERE r."PropertyId" = p."PropertyId" AND r."IsActive" = true),
        0
    ) AS average_rating,
    
    COALESCE(
        (SELECT COUNT(*)
         FROM "Reviews" r
         WHERE r."PropertyId" = p."PropertyId" AND r."IsActive" = true),
        0
    ) AS reviews_count,
    
    -- ━━━ الصورة الرئيسية ━━━
    (SELECT pi."Url"
     FROM "PropertyImages" pi
     WHERE pi."PropertyId" = p."PropertyId" AND pi."IsMain" = true
     ORDER BY pi."DisplayOrder" ASC
     LIMIT 1
    ) AS main_image_url,
    
    -- ━━━ السعر (من DailyUnitSchedule) - لكل عملة ━━━
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."UnitId" 
       AND ds."Currency" = 'YER'
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price_yer,
    
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."UnitId" 
       AND ds."Currency" = 'USD'
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price_usd,
    
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."UnitId" 
       AND ds."Currency" = 'SAR'
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price_sar,
    
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."UnitId" 
       AND ds."Currency" = 'EUR'
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price_eur,
    
    (SELECT MIN(ds."PriceAmount")
     FROM "DailyUnitSchedules" ds
     WHERE ds."UnitId" = u."UnitId" 
       AND ds."Currency" = 'GBP'
       AND ds."PriceAmount" IS NOT NULL
       AND ds."Status" = 'Available'
       AND ds."Date" >= CURRENT_DATE
       AND ds."Date" < CURRENT_DATE + INTERVAL '90 days'
    ) AS min_price_gbp,
    
    -- ━━━ عدد المرافق ━━━
    (SELECT COUNT(DISTINCT pa."PtaId")
     FROM "PropertyAmenities" pa
     WHERE pa."PropertyId" = p."PropertyId"
    ) AS amenities_count,
    
    -- ━━━ Full-Text Search Vector ━━━
    to_tsvector('arabic', 
        COALESCE(u."Name", '') || ' ' || 
        COALESCE(p."Name", '') || ' ' || 
        COALESCE(p."Description", '') || ' ' ||
        COALESCE(p."City", '') || ' ' ||
        COALESCE(ut."Name", '')
    ) AS search_vector,
    
    -- ━━━ تاريخ آخر تحديث ━━━
    GREATEST(
        COALESCE(u."UpdatedAt", u."CreatedAt"),
        COALESCE(p."UpdatedAt", p."CreatedAt")
    ) AS last_updated,
    
    -- ━━━ الحالة ━━━
    u."CreatedAt" AS created_at,
    p."CreatedAt" AS property_created_at

FROM "Units" u
INNER JOIN "Properties" p ON u."PropertyId" = p."PropertyId"
INNER JOIN "PropertyTypes" pt ON p."TypeId" = pt."TypeId"
INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."UnitTypeId"
WHERE p."IsApproved" = true;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Indexes للـ Materialized View
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE UNIQUE INDEX idx_mv_searchable_units_pk ON mv_searchable_units(unit_id);
CREATE INDEX idx_mv_searchable_units_city ON mv_searchable_units(city);
CREATE INDEX idx_mv_searchable_units_property_type ON mv_searchable_units(property_type_id);
CREATE INDEX idx_mv_searchable_units_unit_type ON mv_searchable_units(unit_type_id);
CREATE INDEX idx_mv_searchable_units_capacity ON mv_searchable_units(max_capacity);
CREATE INDEX idx_mv_searchable_units_price_yer ON mv_searchable_units(min_price_yer) WHERE min_price_yer IS NOT NULL;
CREATE INDEX idx_mv_searchable_units_price_usd ON mv_searchable_units(min_price_usd) WHERE min_price_usd IS NOT NULL;
CREATE INDEX idx_mv_searchable_units_rating ON mv_searchable_units(average_rating);
CREATE INDEX idx_mv_searchable_units_location ON mv_searchable_units USING GIST(location_point);
CREATE INDEX idx_mv_searchable_units_search ON mv_searchable_units USING GIN(search_vector);
CREATE INDEX idx_mv_searchable_units_owner ON mv_searchable_units(owner_id);
CREATE INDEX idx_mv_searchable_units_approved ON mv_searchable_units(is_approved) WHERE is_approved = true;
CREATE INDEX idx_mv_searchable_units_featured ON mv_searchable_units(is_featured) WHERE is_featured = true;

-- ملاحظة: تحديث الـ View
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_searchable_units;
