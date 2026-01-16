#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Script للتحقق من اكتمال التحسينات والترابط
# Verification Script for Search Optimizations
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-yemen_booking}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   فحص اكتمال تحسينات البحث والفلترة${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ━━━ فحص الدوال المطلوبة ━━━
echo -e "${YELLOW}🔍 فحص PostgreSQL Functions...${NC}"

REQUIRED_FUNCTIONS=(
    "is_unit_available_with_capacity"
    "is_unit_available"
    "calculate_distance_km"
    "is_numeric_in_range"
    "calculate_total_price"
    "get_unit_min_price"
    "has_all_amenities"
    "convert_currency"
    "search_units_comprehensive"
    "search_units_with_amenities"
    "search_units_with_dynamic_fields"
    "refresh_search_view"
)

MISSING_FUNCTIONS=0
for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -c "
        SELECT 1 FROM pg_proc WHERE proname = '$func';
    " | grep -q 1; then
        echo -e "  ${GREEN}✓${NC} $func"
    else
        echo -e "  ${RED}✗${NC} $func ${RED}(مفقود)${NC}"
        MISSING_FUNCTIONS=$((MISSING_FUNCTIONS + 1))
    fi
done

echo ""

# ━━━ فحص الـ Indexes ━━━
echo -e "${YELLOW}🔍 فحص Database Indexes...${NC}"

REQUIRED_INDEXES=(
    "idx_dailyunitschedules_unit_date_status"
    "idx_dailyunitschedules_daterange_available"
    "idx_dailyunitschedules_price_yer"
    "idx_unitfieldvalues_unit_field"
    "idx_unitfieldvalues_numeric"
    "idx_propertyamenities_property_amenity"
    "idx_units_property_type_capacity"
    "idx_properties_city_type_approved"
    "idx_properties_location_gist"
    "idx_properties_fulltext"
)

MISSING_INDEXES=0
for idx in "${REQUIRED_INDEXES[@]}"; do
    if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -c "
        SELECT 1 FROM pg_indexes WHERE indexname = '$idx';
    " | grep -q 1; then
        echo -e "  ${GREEN}✓${NC} $idx"
    else
        echo -e "  ${RED}✗${NC} $idx ${RED}(مفقود)${NC}"
        MISSING_INDEXES=$((MISSING_INDEXES + 1))
    fi
done

echo ""

# ━━━ فحص الـ Views ━━━
echo -e "${YELLOW}🔍 فحص Materialized Views...${NC}"

if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -c "
    SELECT 1 FROM pg_matviews WHERE matviewname = 'mv_searchable_units';
" | grep -q 1; then
    echo -e "  ${GREEN}✓${NC} mv_searchable_units"
    
    # عدد السجلات في الـ View
    VIEW_COUNT=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM mv_searchable_units;
    " | xargs)
    echo -e "    ${BLUE}→${NC} عدد الوحدات: ${VIEW_COUNT}"
else
    echo -e "  ${RED}✗${NC} mv_searchable_units ${RED}(مفقود)${NC}"
    MISSING_INDEXES=$((MISSING_INDEXES + 1))
fi

echo ""

# ━━━ فحص Extensions ━━━
echo -e "${YELLOW}🔍 فحص PostgreSQL Extensions...${NC}"

REQUIRED_EXTENSIONS=(
    "postgis"
    "pg_trgm"
    "btree_gist"
)

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -c "
        SELECT 1 FROM pg_extension WHERE extname = '$ext';
    " | grep -q 1; then
        echo -e "  ${GREEN}✓${NC} $ext"
    else
        echo -e "  ${YELLOW}⚠${NC} $ext ${YELLOW}(غير مفعّل)${NC}"
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# النتيجة النهائية
if [ $MISSING_FUNCTIONS -eq 0 ] && [ $MISSING_INDEXES -eq 0 ]; then
    echo -e "${GREEN}✅ جميع التحسينات مطبقة بنجاح!${NC}"
    echo -e "${GREEN}   النظام جاهز للاستخدام${NC}"
    exit 0
else
    echo -e "${RED}❌ بعض المكونات مفقودة:${NC}"
    [ $MISSING_FUNCTIONS -gt 0 ] && echo -e "${RED}   - دوال مفقودة: $MISSING_FUNCTIONS${NC}"
    [ $MISSING_INDEXES -gt 0 ] && echo -e "${RED}   - indexes مفقودة: $MISSING_INDEXES${NC}"
    echo ""
    echo -e "${YELLOW}💡 قم بتشغيل: ./apply_all.sh${NC}"
    exit 1
fi
