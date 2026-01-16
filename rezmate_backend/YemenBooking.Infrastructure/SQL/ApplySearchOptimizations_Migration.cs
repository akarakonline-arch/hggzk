using Microsoft.EntityFrameworkCore.Migrations;
using System.IO;

#nullable disable

namespace YemenBooking.Infrastructure.Migrations
{
    /// <summary>
    /// تطبيق تحسينات البحث والفلترة الشاملة
    /// - PostgreSQL Functions للعمليات في قاعدة البيانات
    /// - Database Indexes المحسّنة
    /// - Materialized Views للأداء العالي
    /// - دعم كامل للبالغين والأطفال
    /// </summary>
    public partial class ApplySearchOptimizations_20251117 : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // المرحلة 1: تفعيل Extensions المطلوبة
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            migrationBuilder.Sql(@"
                CREATE EXTENSION IF NOT EXISTS postgis;
                CREATE EXTENSION IF NOT EXISTS postgis_topology;
                CREATE EXTENSION IF NOT EXISTS pg_trgm;
                CREATE EXTENSION IF NOT EXISTS btree_gist;
            ");
            
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // المرحلة 2: تطبيق الدوال الأساسية
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            var sqlPath = Path.Combine(
                Directory.GetCurrentDirectory(), 
                "..", 
                "YemenBooking.Infrastructure", 
                "SQL"
            );
            
            // قراءة وتطبيق 01_SearchFunctions.sql
            var searchFunctionsScript = File.ReadAllText(
                Path.Combine(sqlPath, "Functions", "01_SearchFunctions.sql")
            );
            migrationBuilder.Sql(searchFunctionsScript);
            
            // قراءة وتطبيق 02_ComprehensiveSearchFunction.sql
            var comprehensiveSearchScript = File.ReadAllText(
                Path.Combine(sqlPath, "Functions", "02_ComprehensiveSearchFunction.sql")
            );
            migrationBuilder.Sql(comprehensiveSearchScript);
            
            // قراءة وتطبيق 03_AdvancedSearchFunctions.sql
            var advancedSearchScript = File.ReadAllText(
                Path.Combine(sqlPath, "Functions", "03_AdvancedSearchFunctions.sql")
            );
            migrationBuilder.Sql(advancedSearchScript);
            
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // المرحلة 3: إنشاء Indexes المحسّنة
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            var indexesScript = File.ReadAllText(
                Path.Combine(sqlPath, "Indexes", "01_SearchIndexes.sql")
            );
            migrationBuilder.Sql(indexesScript);
            
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // المرحلة 4: إنشاء Materialized View
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            var viewScript = File.ReadAllText(
                Path.Combine(sqlPath, "Views", "01_SearchableUnitsView.sql")
            );
            migrationBuilder.Sql(viewScript);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // ━━━ حذف الـ Views ━━━
            migrationBuilder.Sql(@"DROP MATERIALIZED VIEW IF EXISTS mv_searchable_units CASCADE;");
            
            // ━━━ حذف الدوال ━━━
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS search_units_with_dynamic_fields CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS search_units_with_amenities CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS search_units_comprehensive CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS refresh_search_view CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS convert_currency CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS has_all_amenities CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS get_unit_min_price CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS calculate_total_price CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS is_numeric_in_range CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS calculate_distance_km CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS is_unit_available CASCADE;");
            migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS is_unit_available_with_capacity CASCADE;");
            
            // ━━━ حذف الـ Indexes ━━━
            var indexes = new[]
            {
                "idx_dailyunitschedules_unit_date_status",
                "idx_dailyunitschedules_daterange_available",
                "idx_dailyunitschedules_daterange_unavailable",
                "idx_dailyunitschedules_price_yer",
                "idx_dailyunitschedules_price_usd",
                "idx_dailyunitschedules_price_sar",
                "idx_unitfieldvalues_unit_field",
                "idx_unitfieldvalues_searchable",
                "idx_unitfieldvalues_numeric",
                "idx_unitfieldvalues_text_search",
                "idx_propertyamenities_property_amenity",
                "idx_propertyamenities_amenity_property",
                "idx_units_property_type_capacity",
                "idx_units_capacity",
                "idx_properties_city_type_approved",
                "idx_properties_featured",
                "idx_properties_owner",
                "idx_properties_location_gist",
                "idx_properties_fulltext",
                "idx_propertytypeamenities_amenity",
                "idx_unittypes_capacity_flags",
                "idx_reviews_property_approved"
            };
            
            foreach (var index in indexes)
            {
                migrationBuilder.Sql($@"DROP INDEX IF EXISTS {index};");
            }
        }
    }
}
