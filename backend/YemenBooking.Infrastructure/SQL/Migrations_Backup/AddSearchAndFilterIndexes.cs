// using Microsoft.EntityFrameworkCore.Migrations;

// #nullable disable

// namespace YemenBooking.Infrastructure.Migrations
// {
//     /// <summary>
//     /// إضافة indexes محسّنة لجداول البحث والفلترة
//     /// </summary>
//     public partial class AddSearchAndFilterIndexes : Migration
//     {
//         protected override void Up(MigrationBuilder migrationBuilder)
//         {
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 1. فهارس DailyUnitSchedules (الأهم - للسعر والإتاحة)
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             // Composite Index للإتاحة والسعر (يغطي جميع استعلامات البحث)
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_search_composite 
//                 ON ""DailyUnitSchedules"" (""UnitId"", ""Date"", ""Status"")
//                 INCLUDE (""PriceAmount"", ""Currency"", ""MinimumStay"");
//             ");
            
//             // Index for Date Range queries (للبحث بالتواريخ)
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_daterange 
//                 ON ""DailyUnitSchedules"" USING btree (""Date"", ""UnitId"")
//                 WHERE ""Status"" <> 'Available';
//             ");
            
//             // Index for Price filtering (للبحث بالسعر)
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_dailyunitschedules_price 
//                 ON ""DailyUnitSchedules"" (""Currency"", ""PriceAmount"")
//                 WHERE ""PriceAmount"" IS NOT NULL;
//             ");
            
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 2. فهارس UnitFieldValues (للحقول الديناميكية)
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             // Composite Index للبحث في الحقول الديناميكية
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_search 
//                 ON ""UnitFieldValues"" (""UnitId"", ""UnitTypeFieldId"")
//                 INCLUDE (""FieldValue"");
//             ");
            
//             // Index for Numeric Values (للقيم الرقمية)
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_unitfieldvalues_numeric 
//                 ON ""UnitFieldValues"" (""UnitTypeFieldId"", ""FieldValue"")
//                 WHERE ""FieldValue"" ~ '^[0-9]+(\.[0-9]+)?$';
//             ");
            
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 3. فهارس PropertyAmenities (للمرافق)
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             // Index للبحث بالمرافق
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_propertyamenities_search 
//                 ON ""PropertyAmenities"" (""PropertyId"", ""PropertyTypeAmenityId"");
//             ");
            
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 4. فهارس Units (للفلترة السريعة)
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             // Composite Index للفلترة حسب Property و UnitType
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_units_search_composite 
//                 ON ""Units"" (""PropertyId"", ""UnitTypeId"", ""MaxCapacity"");
//             ");
            
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 5. فهارس Properties (للفلترة حسب نوع العقار والمدينة)
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             // Composite Index للبحث
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_properties_search_composite 
//                 ON ""Properties"" (""City"", ""TypeId"", ""IsApproved"")
//                 WHERE ""IsApproved"" = true;
//             ");
            
//             // GiST Index للبحث الجغرافي
//             migrationBuilder.Sql(@"
//                 CREATE INDEX IF NOT EXISTS idx_properties_location_gist 
//                 ON ""Properties"" USING gist (
//                     ll_to_earth(CAST(""Latitude"" AS double precision), 
//                                CAST(""Longitude"" AS double precision))
//                 )
//                 WHERE ""Latitude"" IS NOT NULL AND ""Longitude"" IS NOT NULL;
//             ");
            
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//             // 6. إنشاء PostgreSQL Function للفلترة الرقمية
//             // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
//             migrationBuilder.Sql(@"
//                 CREATE OR REPLACE FUNCTION is_numeric_in_range(
//                     value TEXT,
//                     min_value NUMERIC,
//                     max_value NUMERIC
//                 ) RETURNS BOOLEAN AS $$
//                 BEGIN
//                     RETURN (value ~ '^[0-9]+(\.[0-9]+)?$') AND 
//                            (value::NUMERIC BETWEEN min_value AND max_value);
//                 EXCEPTION
//                     WHEN OTHERS THEN
//                         RETURN FALSE;
//                 END;
//                 $$ LANGUAGE plpgsql IMMUTABLE;
//             ");
//         }

//         protected override void Down(MigrationBuilder migrationBuilder)
//         {
//             // حذف الـ Indexes
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_dailyunitschedules_search_composite;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_dailyunitschedules_daterange;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_dailyunitschedules_price;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_unitfieldvalues_search;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_unitfieldvalues_numeric;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_propertyamenities_search;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_units_search_composite;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_properties_search_composite;");
//             migrationBuilder.Sql(@"DROP INDEX IF EXISTS idx_properties_location_gist;");
            
//             // حذف الدالة
//             migrationBuilder.Sql(@"DROP FUNCTION IF EXISTS is_numeric_in_range(TEXT, NUMERIC, NUMERIC);");
//         }
//     }
// }
