# SQL Scripts Documentation
## دليل ملفات SQL للبحث والفلترة المحسّنة

هذا المجلد يحتوي على جميع ملفات SQL المطلوبة لتحسين نظام البحث والفلترة.
**مهم:** هذه الملفات مستقلة عن مجلد Migrations - يمكن تطبيقها يدوياً في أي وقت.

---

## 📁 هيكل المجلدات

```
SQL/
├── Functions/          # دوال PostgreSQL
│   ├── 01_SearchFunctions.sql
│   ├── 02_ComprehensiveSearchFunction.sql
│   └── 03_AdvancedSearchFunctions.sql
├── Views/             # Materialized Views
│   └── 01_SearchableUnitsView.sql
├── Indexes/           # Database Indexes
│   └── 01_SearchIndexes.sql
└── README.md          # هذا الملف
```

---

## 🚀 ترتيب التطبيق

يجب تطبيق الملفات بالترتيب التالي:

### المرحلة 1: الدوال الأساسية
```bash
psql -U postgres -d yemen_booking -f Functions/01_SearchFunctions.sql
```

**يحتوي على:**
- ✅ `is_unit_available_with_capacity()` - التحقق من الإتاحة مع البالغين والأطفال
- ✅ `is_unit_available()` - التحقق من الإتاحة البسيط
- ✅ `calculate_distance_km()` - حساب المسافة بـ PostGIS
- ✅ `is_numeric_in_range()` - التحقق من النطاق الرقمي
- ✅ `calculate_total_price()` - حساب السعر الإجمالي
- ✅ `get_unit_min_price()` - الحصول على أقل سعر
- ✅ `has_all_amenities()` - التحقق من المرافق
- ✅ `convert_currency()` - تحويل العملة

### المرحلة 2: الدوال المتقدمة
```bash
psql -U postgres -d yemen_booking -f Functions/02_ComprehensiveSearchFunction.sql
```

**يحتوي على:**
- ✅ `search_units_comprehensive()` - دالة البحث الشاملة
  - دعم كامل للبالغين والأطفال
  - فلترة السعر بجميع العملات
  - البحث الجغرافي بـ PostGIS
  - الترتيب الديناميكي
  - كل شيء في SQL

```bash
psql -U postgres -d yemen_booking -f Functions/03_AdvancedSearchFunctions.sql
```

**يحتوي على:**
- ✅ `search_units_with_amenities()` - البحث مع المرافق
- ✅ `search_units_with_dynamic_fields()` - البحث مع الحقول الديناميكية

### المرحلة 3: Materialized Views
```bash
psql -U postgres -d yemen_booking -f Views/01_SearchableUnitsView.sql
```

**يحتوي على:**
- ✅ `mv_searchable_units` - View محسّن لجميع بيانات البحث
- ✅ Indexes للـ View (13 index)

### المرحلة 4: Database Indexes
```bash
psql -U postgres -d yemen_booking -f Indexes/01_SearchIndexes.sql
```

**يحتوي على:**
- ✅ 25+ index محسّن للبحث والفلترة

---

## 📊 ملخص الدوال المتاحة

### 1. دوال التحقق من الإتاحة

#### `is_unit_available_with_capacity()`
**الاستخدام:**
```sql
SELECT is_unit_available_with_capacity(
    'unit-id-here'::UUID,
    '2025-12-01'::DATE,
    '2025-12-05'::DATE,
    2,  -- adults
    1   -- children
);
```

**الوظيفة:**
- ✅ التحقق من دعم نوع الوحدة للبالغين/الأطفال
- ✅ التحقق من السعة القصوى
- ✅ التحقق من الإتاحة في التواريخ

#### `is_unit_available()`
**الاستخدام:**
```sql
SELECT is_unit_available(
    'unit-id-here'::UUID,
    '2025-12-01'::DATE,
    '2025-12-05'::DATE
);
```

### 2. دوال الأسعار

#### `get_unit_min_price()`
```sql
SELECT get_unit_min_price('unit-id'::UUID, 'USD');
-- يرجع: أقل سعر متاح في الـ 90 يوم القادمة
```

#### `calculate_total_price()`
```sql
SELECT * FROM calculate_total_price(
    'unit-id'::UUID,
    '2025-12-01'::DATE,
    '2025-12-05'::DATE,
    'USD'
);
-- يرجع: total_price, currency, nights_count, average_per_night
```

#### `convert_currency()`
```sql
SELECT convert_currency(100, 'USD', 'YER');
-- يرجع: المبلغ بالريال اليمني
```

### 3. دوال البحث

#### `search_units_comprehensive()`
**البحث الشامل مع جميع المعايير:**
```sql
SELECT * FROM search_units_comprehensive(
    p_search_text := 'فندق',
    p_city := 'صنعاء',
    p_check_in := '2025-12-01'::DATE,
    p_check_out := '2025-12-05'::DATE,
    p_adults := 2,
    p_children := 1,
    p_min_price := 50,
    p_max_price := 200,
    p_currency := 'USD',
    p_sort_by := 'price_asc',
    p_page_number := 1,
    p_page_size := 20
);
```

#### `search_units_with_amenities()`
**البحث مع المرافق (AND logic):**
```sql
SELECT * FROM search_units_with_amenities(
    p_amenity_ids := ARRAY[
        'wifi-id'::UUID,
        'parking-id'::UUID,
        'pool-id'::UUID
    ]::UUID[],
    p_city := 'صنعاء',
    p_adults := 2,
    p_min_price := 100,
    p_max_price := 500,
    p_currency := 'USD'
);
```

#### `search_units_with_dynamic_fields()`
**البحث مع الحقول الديناميكية:**
```sql
SELECT * FROM search_units_with_dynamic_fields(
    p_field_filters := '{"numberOfBedrooms": "3", "area": "50..150", "view": "~بحر"}'::JSONB,
    p_city := 'عدن',
    p_adults := 2
);
```

---

## 🔄 تحديث الـ Materialized View

### تحديث يدوي:
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_searchable_units;
```

### تحديث تلقائي (كل ساعة):
```sql
-- إنشاء Cron Job
SELECT cron.schedule(
    'refresh-search-view',
    '0 * * * *',  -- كل ساعة
    $$ SELECT refresh_search_view(); $$
);
```

### التحقق من آخر تحديث:
```sql
SELECT 
    schemaname,
    matviewname,
    last_refresh
FROM pg_catalog.pg_stat_user_tables
WHERE relname = 'mv_searchable_units';
```

---

## 🧪 الاختبارات

### Test 1: البحث البسيط
```sql
SELECT unit_name, property_name, city, min_price
FROM search_units_comprehensive(
    p_city := 'صنعاء',
    p_page_size := 10
);
```

### Test 2: البحث مع البالغين والأطفال
```sql
SELECT unit_name, max_capacity, is_has_adults, is_has_children
FROM search_units_comprehensive(
    p_adults := 2,
    p_children := 1,
    p_check_in := '2025-12-01'::DATE,
    p_check_out := '2025-12-05'::DATE
);
```

### Test 3: البحث بالسعر والعملة
```sql
SELECT unit_name, min_price, price_currency
FROM search_units_comprehensive(
    p_min_price := 50,
    p_max_price := 200,
    p_currency := 'USD',
    p_sort_by := 'price_asc'
);
```

### Test 4: البحث الجغرافي
```sql
SELECT unit_name, property_name, distance_km
FROM search_units_comprehensive(
    p_latitude := 15.3694,
    p_longitude := 44.1910,
    p_radius_km := 10.0,
    p_sort_by := 'distance'
)
ORDER BY distance_km;
```

---

## 📊 الأداء المتوقع

| العملية | قبل | بعد | التحسين |
|---------|-----|-----|---------|
| البحث البسيط | ~450ms | ~50ms | ⚡ 89% |
| البحث مع المرافق | ~600ms | ~80ms | ⚡ 87% |
| البحث الجغرافي | ~800ms | ~30ms | ⚡ 96% |
| الحقول الديناميكية | ❌ Broken | ~60ms | ✅ Fixed |

---

## 🔧 Troubleshooting

### خطأ: Function does not exist

```bash
# التحقق من وجود الدوال
\df is_unit_available*
\df search_units*

# إعادة تطبيق الملفات
psql -U postgres -d yemen_booking -f Functions/01_SearchFunctions.sql
```

### خطأ: PostGIS extension not found

```sql
-- تفعيل PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
```

### بطء في الـ Materialized View

```sql
-- إعادة بناء الـ indexes
REINDEX TABLE mv_searchable_units;

-- تحديث الإحصائيات
ANALYZE mv_searchable_units;
```

---

## 📝 ملاحظات مهمة

1. **PostGIS Required:** يجب تفعيل PostGIS extension للبحث الجغرافي
2. **pg_trgm Required:** للبحث النصي المحسّن
3. **Materialized View:** يجب تحديثها دورياً (كل ساعة موصى به)
4. **Indexes:** قد يستغرق إنشاؤها بعض الوقت في قاعدة بيانات كبيرة

---

## 🎯 الخلاصة

جميع الدوال مصممة للعمل **بالكامل في SQL** بدون أي معالجة في application layer:
- ✅ الفلترة في SQL
- ✅ الترتيب في SQL
- ✅ الحسابات في SQL
- ✅ التجميع في SQL
- ✅ Pagination في SQL

**النتيجة:** أداء ممتاز وقابلية توسع عالية.
