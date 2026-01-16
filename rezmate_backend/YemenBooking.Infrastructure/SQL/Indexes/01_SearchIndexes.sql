-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Database Indexes للبحث والفلترة السريعة
-- Comprehensive indexes for optimal search performance
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ━━━ 1. DailyUnitSchedules Indexes (الأهم) ━━━

-- Composite Index للإتاحة والسعر (يغطي أغلب الاستعلامات)
CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_unit_date_status 
ON "DailyUnitSchedules" ("UnitId", "Date", "Status")
INCLUDE ("PriceAmount", "Currency");

-- Index للبحث بنطاق التواريخ
CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_daterange_available 
ON "DailyUnitSchedules" ("Date", "UnitId")
WHERE "Status" = 'Available';

-- Index للبحث بنطاق التواريخ (غير متاح)
CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_daterange_unavailable 
ON "DailyUnitSchedules" ("Date", "UnitId")
WHERE "Status" IN ('Booked', 'Blocked');

-- Index للبحث بالسعر (كل عملة)
CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_price_yer 
ON "DailyUnitSchedules" ("Currency", "PriceAmount", "UnitId")
WHERE "Currency" = 'YER' AND "PriceAmount" IS NOT NULL AND "Status" = 'Available';

CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_price_usd 
ON "DailyUnitSchedules" ("Currency", "PriceAmount", "UnitId")
WHERE "Currency" = 'USD' AND "PriceAmount" IS NOT NULL AND "Status" = 'Available';

CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_price_sar 
ON "DailyUnitSchedules" ("Currency", "PriceAmount", "UnitId")
WHERE "Currency" = 'SAR' AND "PriceAmount" IS NOT NULL AND "Status" = 'Available';

-- ━━━ 2. UnitFieldValues Indexes (الحقول الديناميكية) ━━━

-- Composite Index للبحث السريع
CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_unit_field 
ON "UnitFieldValues" ("UnitId", "UnitTypeFieldId")
INCLUDE ("FieldValue");

-- Index للحقول القابلة للبحث
CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_searchable 
ON "UnitFieldValues" ("UnitTypeFieldId", "FieldValue")
WHERE "FieldValue" IS NOT NULL;

-- Partial Index للقيم الرقمية فقط
CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_numeric 
ON "UnitFieldValues" ("UnitTypeFieldId", "FieldValue")
WHERE "FieldValue" ~ '^[0-9]+(\.[0-9]+)?$';

-- GIN Index للبحث النصي في القيم
CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_text_search 
ON "UnitFieldValues" USING GIN (to_tsvector('arabic', COALESCE("FieldValue", '')))
WHERE "FieldValue" IS NOT NULL AND length("FieldValue") > 2;

-- ━━━ 3. PropertyAmenities Indexes ━━━

CREATE INDEX IF NOT EXISTS idx_propertyamenities_property_amenity 
ON "PropertyAmenities" ("PropertyId", "PtaId");

-- للبحث العكسي (من amenity للـ properties)
CREATE INDEX IF NOT EXISTS idx_propertyamenities_amenity_property 
ON "PropertyAmenities" ("PtaId", "PropertyId");

-- ━━━ 4. Units Indexes ━━━

-- Composite Index للفلترة المشتركة
CREATE INDEX IF NOT EXISTS idx_units_property_type_capacity 
ON "Units" ("PropertyId", "UnitTypeId", "MaxCapacity");

-- Index للبحث بالسعة (البالغين والأطفال)
CREATE INDEX IF NOT EXISTS idx_units_capacity 
ON "Units" ("MaxCapacity")
WHERE "MaxCapacity" IS NOT NULL;

-- ━━━ 5. Properties Indexes ━━━

-- Composite Index للبحث المشترك
CREATE INDEX IF NOT EXISTS idx_properties_city_type_approved 
ON "Properties" ("City", "TypeId", "IsApproved")
WHERE "IsApproved" = true;

-- Index للعقارات المميزة
CREATE INDEX IF NOT EXISTS idx_properties_featured 
ON "Properties" ("IsFeatured", "City")
WHERE "IsFeatured" = true AND "IsApproved" = true;

-- Index للبحث بالمالك
CREATE INDEX IF NOT EXISTS idx_properties_owner 
ON "Properties" ("OwnerId", "IsApproved");

-- GiST Index للبحث الجغرافي (PostGIS)
CREATE INDEX IF NOT EXISTS idx_properties_location_gist 
ON "Properties" USING gist (
    ST_SetSRID(ST_MakePoint(
        CAST("Longitude" AS double precision),
        CAST("Latitude" AS double precision)
    ), 4326)::geography
)
WHERE "Latitude" IS NOT NULL AND "Longitude" IS NOT NULL;

-- GIN Index للبحث النصي
CREATE INDEX IF NOT EXISTS idx_properties_fulltext 
ON "Properties" USING GIN (
    to_tsvector('arabic', 
        COALESCE("Name", '') || ' ' || 
        COALESCE("Description", '') || ' ' ||
        COALESCE("City", '') || ' ' ||
        COALESCE("Address", '')
    )
);

-- ━━━ 6. PropertyTypeAmenities Indexes ━━━

CREATE INDEX IF NOT EXISTS idx_propertytypeamenities_amenity 
ON "PropertyTypeAmenities" ("AmenityId", "PropertyTypeId");

-- ━━━ 7. UnitTypes Indexes ━━━

-- للفلترة بدعم البالغين/الأطفال
CREATE INDEX IF NOT EXISTS idx_unittypes_capacity_flags 
ON "UnitTypes" ("IsHasAdults", "IsHasChildren", "IsMultiDays");

-- ━━━ 8. Reviews Indexes ━━━

CREATE INDEX IF NOT EXISTS idx_reviews_property_approved 
ON "Reviews" ("PropertyId", "IsApproved", "Rating")
WHERE "IsApproved" = true;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Statistics Update (لتحسين Query Planner)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ANALYZE "DailyUnitSchedules";
ANALYZE "UnitFieldValues";
ANALYZE "PropertyAmenities";
ANALYZE "Units";
ANALYZE "Properties";
ANALYZE "Reviews";
