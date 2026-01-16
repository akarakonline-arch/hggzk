using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Application.Features.SearchAndFilters.Services;

/// <summary>
/// واجهة خدمة الفهرسة والبحث - النسخة الجديدة المبنية على فهرسة الوحدات
/// 
/// المبدأ الأساسي:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// الفهرسة على مستوى الوحدة (Unit-Level Indexing):
/// • كل وحدة = مستند JSON كامل في Redis
/// • المفتاح: property:{propertyId}:unit:{unitId}
/// • المستند يحتوي على: بيانات الوحدة + العقار + الإتاحات + الأسعار + المرافق + الخدمات
/// 
/// الفهارس الثانوية (Secondary Indexes):
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • uindex:city:{city} → SET of unitKeys (فهرس المدينة)
/// • uindex:unittype:{unitTypeId} → SET of unitKeys (فهرس نوع الوحدة)
/// • uindex:propertytype:{propertyTypeId} → SET of unitKeys (فهرس نوع العقار)
/// • uindex:price → ZSET(score=price) (فهرس السعر)
/// • uindex:rating → ZSET(score=rating) (فهرس التقييم)
/// • uindex:amenity:{amenityId} → SET of unitKeys (فهرس المرافق)
/// • uindex:geo → GEOHASH (فهرس جغرافي)
/// • uindex:keyword:{keyword} → SET of unitKeys (فهرس نصي)
/// • uindex:property:{propertyId} → SET of unitKeys (وحدات العقار)
/// • ufield:{fieldName}:{value} → SET of unitKeys (فهرس الحقول الديناميكية)
/// • ufield:num:{fieldName} → ZSET(score=numericValue) (فهرس رقمي للحقول)
/// 
/// Events المدعومة:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • OnUnitCreated - فهرسة وحدة جديدة
/// • OnUnitUpdated - تحديث فهرسة وحدة
/// • OnUnitDeleted - حذف فهرسة وحدة
/// • OnPropertyUpdated - تحديث بيانات العقار في جميع وحداته
/// • OnPropertyDeleted - حذف جميع وحدات العقار
/// • OnAvailabilityChanged - تحديث الإتاحات
/// • OnPricingChanged - تحديث الأسعار
/// </summary>
public interface IUnitIndexingService
{
    #region === عمليات الوحدة (Unit Operations) ===
    
    /// <summary>
    /// فهرسة وحدة جديدة في Redis
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. جلب جميع بيانات الوحدة والعقار من DB
    /// 2. جلب الإتاحات، قواعد التسعير، الحقول الديناميكية
    /// 3. جلب المرافق والخدمات والصور من العقار
    /// 4. حساب الملخصات (نطاقات الأسعار، الكلمات المفتاحية)
    /// 5. بناء UnitIndexDocument كامل
    /// 6. حفظ JSON في Redis تحت key: property:{propertyId}:unit:{unitId}
    /// 7. تحديث جميع الفهارس الثانوية
    /// 
    /// الفهارس الثانوية المحدثة:
    /// • uindex:city:{city}
    /// • uindex:unittype:{unitTypeId}
    /// • uindex:price (ZSET)
    /// • uindex:rating (ZSET)
    /// • uindex:amenity:{amenityId} (لكل مرفق)
    /// • uindex:geo (GEOHASH)
    /// • uindex:keyword:{keyword} (لكل كلمة مفتاحية)
    /// • uindex:property:{propertyId}
    /// • ufield:{fieldName}:{value} (لكل حقل ديناميكي)
    /// • ufield:num:{fieldName} (للحقول الرقمية)
    /// </summary>
    /// <param name="unitId">معرف الوحدة المراد فهرستها</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجحت الفهرسة</returns>
    Task<bool> OnUnitCreatedAsync(Guid unitId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث فهرسة وحدة موجودة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. حذف الفهرسة القديمة (المستند + جميع الفهارس الثانوية)
    /// 2. إعادة الفهرسة بالبيانات الجديدة (مثل OnUnitCreatedAsync)
    /// 
    /// ملاحظة: عملية آمنة تضمن عدم فقدان البيانات
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجح التحديث</returns>
    Task<bool> OnUnitUpdatedAsync(Guid unitId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف فهرسة وحدة من Redis
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. حذف المستند الرئيسي: property:{propertyId}:unit:{unitId}
    /// 2. إزالة من جميع الفهارس الثانوية:
    ///    • uindex:city:{city}
    ///    • uindex:unittype:{unitTypeId}
    ///    • uindex:price
    ///    • uindex:rating
    ///    • uindex:amenity:* (جميع المرافق)
    ///    • uindex:geo
    ///    • uindex:keyword:* (جميع الكلمات المفتاحية)
    ///    • uindex:property:{propertyId}
    ///    • ufield:* (جميع الحقول الديناميكية)
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجح الحذف</returns>
    Task<bool> OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === عمليات نوع الوحدة (Unit Type Operations) ===
    
    /// <summary>
    /// معالجة حذف نوع وحدة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. إعادة فهرسة جميع الوحدات التي كانت من هذا النوع
    /// 2. تحديث الفهارس الثانوية ذات الصلة
    /// </summary>
    /// <param name="unitTypeId">معرف نوع الوحدة المحذوف</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المحدثة</returns>
    Task<int> OnUnitTypeDeletedAsync(Guid unitTypeId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// معالجة تحديث حقل ديناميكي لنوع الوحدة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. تحديث الفهارس الديناميكية للحقل
    /// 2. إعادة فهرسة جميع الوحدات المتأثرة
    /// </summary>
    /// <param name="oldFieldName">اسم الحقل القديم</param>
    /// <param name="newFieldName">اسم الحقل الجديد</param>
    /// <param name="fieldTypeId">معرف نوع الحقل</param>
    /// <param name="isPrimaryFilter">هل الحقل فلتر أساسي</param>
    /// <param name="unitTypeId">معرف نوع الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المحدثة</returns>
    Task<int> OnUnitTypeFieldUpdatedAsync(
        string oldFieldName, 
        string newFieldName, 
        string fieldTypeId,
        bool isPrimaryFilter,
        Guid unitTypeId, 
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// معالجة حذف حقل ديناميكي لنوع الوحدة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. حذف الفهارس الديناميكية للحقل
    /// 2. إعادة فهرسة جميع الوحدات المتأثرة
    /// </summary>
    /// <param name="fieldName">اسم الحقل المحذوف</param>
    /// <param name="unitTypeId">معرف نوع الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المحدثة</returns>
    Task<int> OnUnitTypeFieldDeletedAsync(string fieldName, Guid unitTypeId, CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === عمليات العقار (Property Operations) ===
    
    /// <summary>
    /// معالجة إنشاء عقار جديد
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. فهرسة جميع وحدات العقار الجديد
    /// 2. إنشاء الفهارس الثانوية
    /// </summary>
    /// <param name="propertyId">معرف العقار الجديد</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المفهرسة</returns>
    Task<int> OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث بيانات العقار في جميع وحداته
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. الحصول على قائمة جميع وحدات العقار من: uindex:property:{propertyId}
    /// 2. لكل وحدة: تحديث بيانات العقار في JSON (PropertyName, Location, Rating, إلخ)
    /// 3. تحديث الفهارس الثانوية إذا تغيرت (City, PropertyType, Rating)
    /// 
    /// الحالات المُعالجة:
    /// • تغيير اسم العقار → تحديث PropertyName فقط
    /// • تغيير المدينة → تحديث City + نقل بين فهارس المدن
    /// • تغيير التقييم → تحديث Rating في ZSET
    /// • تغيير المرافق → تحديث Amenities في جميع الوحدات
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المحدثة</returns>
    Task<int> OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف جميع وحدات العقار من الفهرس
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. الحصول على قائمة جميع وحدات العقار من: uindex:property:{propertyId}
    /// 2. لكل وحدة: استدعاء OnUnitDeletedAsync
    /// 3. حذف فهرس العقار نفسه: uindex:property:{propertyId}
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المحذوفة</returns>
    Task<int> OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === عمليات الإتاحة والتسعير (Availability & Pricing) ===
    
    /// <summary>
    /// تحديث إتاحة وحدة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. جلب الإتاحات الجديدة من DB
    /// 2. تحديث قسم Availabilities في JSON
    /// 3. إعادة حساب ملخص الإتاحة (NextAvailableDate, BlockedDates)
    /// 4. تحديث IsAvailable الأساسي
    /// 5. حفظ JSON المحدث
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجح التحديث</returns>
    Task<bool> OnAvailabilityChangedAsync(Guid unitId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث الجداول اليومية للتسعير والإتاحة للوحدة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. جلب الجداول اليومية من DB
    /// 2. تحديث قسم DailySchedules في JSON
    /// 3. إعادة حساب نطاقات الأسعار والإتاحة
    /// 4. تحديث فهرس السعر (uindex:price)
    /// 5. حفظ JSON المحدث
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجح التحديث</returns>
    Task<bool> OnDailyScheduleChangedAsync(Guid unitId, CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === البحث (Search) ===
    
    /// <summary>
    /// تنفيذ بحث عن الوحدات بناءً على المعايير المحددة
    /// 
    /// استراتيجية البحث متعدد المراحل:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// المرحلة 1 - الفلترة الأساسية (Primary Filtering):
    ///   1. إذا City → جلب من uindex:city:{city}
    ///   2. إذا UnitTypeId → تقاطع مع uindex:unittype:{unitTypeId}
    ///   3. إذا PropertyTypeId → تقاطع مع uindex:propertytype:{propertyTypeId}
    ///   4. النتيجة: قائمة أولية من معرفات الوحدات
    /// 
    /// المرحلة 2 - فلترة السعر والتقييم (Price & Rating Filter):
    ///   1. إذا MinPrice/MaxPrice → فلترة من uindex:price (ZRANGE)
    ///   2. إذا MinRating → فلترة من uindex:rating (ZRANGE)
    ///   3. تقاطع النتائج مع القائمة الأولية
    /// 
    /// المرحلة 3 - فلترة المرافق (Amenities Filter):
    ///   1. لكل مرفق مطلوب → جلب من uindex:amenity:{amenityId}
    ///   2. تقاطع جميع المجموعات (AND logic)
    ///   3. تقاطع النتيجة مع القائمة الحالية
    /// 
    /// المرحلة 4 - البحث النصي (Text Search):
    ///   1. إذا SearchText → تقسيم إلى كلمات
    ///   2. لكل كلمة → جلب من uindex:keyword:{keyword}
    ///   3. تقاطع النتائج (AND logic)
    /// 
    /// المرحلة 5 - البحث الجغرافي (Geographic Search):
    ///   1. إذا Lat/Lng/Radius → استخدام GEORADIUS على uindex:geo
    ///   2. تقاطع النتيجة مع القائمة الحالية
    /// 
    /// المرحلة 6 - فحص التفاصيل (Detail Filtering):
    ///   1. جلب JSON لكل وحدة متبقية
    ///   2. فحص: GuestsCount (MaxCapacity)
    ///   3. فحص: الحقول الديناميكية (DynamicFieldFilters)
    ///   4. فحص: التواريخ (Availabilities) - التحقق الدقيق
    ///   5. حساب السعر الإجمالي للفترة (إذا CheckIn/CheckOut)
    /// 
    /// المرحلة 7 - الترتيب (Sorting):
    ///   1. ترتيب حسب SortBy
    ///   2. حساب RelevanceScore لكل نتيجة
    /// 
    /// المرحلة 8 - التصفح (Pagination):
    ///   1. تطبيق PageNumber & PageSize
    ///   2. بناء UnitSearchResult
    /// </summary>
    /// <param name="request">معايير البحث</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة البحث مع الوحدات المطابقة</returns>
    Task<UnitSearchResult> SearchUnitsAsync(UnitSearchRequest request, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// بحث مع تجميع النتائج حسب العقار
    /// 
    /// الفرق عن SearchUnitsAsync:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// • بعد الحصول على قائمة الوحدات المطابقة
    /// • يتم تجميعها حسب PropertyId
    /// • لكل عقار: بناء PropertySearchItem يحتوي على MatchedUnits
    /// • حساب نطاق الأسعار للوحدات المطابقة في كل عقار
    /// • ترتيب العقارات (وليس الوحدات)
    /// 
    /// الاستخدام:
    /// يُفضل للواجهات التي تعرض العقارات مع إمكانية التوسع لرؤية الوحدات
    /// </summary>
    /// <param name="request">معايير البحث</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة البحث مع العقارات ووحداتها المطابقة</returns>
    Task<PropertyWithUnitsSearchResult> SearchPropertiesWithUnitsAsync(
        PropertyWithUnitsSearchRequest request, 
        CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === الصيانة (Maintenance) ===
    
    /// <summary>
    /// إعادة بناء فهرس وحدة واحدة
    /// 
    /// الاستخدام:
    /// • بعد تصحيح بيانات تالفة
    /// • عند الاشتباه بعدم تزامن البيانات
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا نجحت الإعادة</returns>
    Task<bool> RebuildUnitIndexAsync(Guid unitId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إعادة بناء فهارس جميع وحدات عقار
    /// 
    /// الاستخدام:
    /// • بعد تحديث جذري على العقار
    /// • عند تحديث المرافق أو الخدمات
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الوحدات المعاد فهرستها</returns>
    Task<int> RebuildPropertyUnitsIndexAsync(Guid propertyId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إعادة بناء الفهرس الكامل (جميع الوحدات)
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. مسح جميع فهارس الوحدات القديمة من Redis
    /// 2. جلب جميع الوحدات النشطة من DB
    /// 3. فهرسة كل وحدة باستخدام OnUnitCreatedAsync
    /// 4. معالجة على دفعات (batches) لتجنب استهلاك الذاكرة
    /// 
    /// تحذير: عملية كثيفة - تُستخدم فقط عند الحاجة
    /// يُفضل تشغيلها في Background Job أو خارج ساعات الذروة
    /// </summary>
    /// <param name="batchSize">حجم الدفعة (افتراضي: 100)</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إجمالي عدد الوحدات المفهرسة</returns>
    Task<int> RebuildAllIndexesAsync(int batchSize = 100, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تنظيف الفهارس من البيانات القديمة أو التالفة
    /// 
    /// العملية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. مسح المفاتيح المؤقتة (temp:*)
    /// 2. مسح الفهارس الفارغة
    /// 3. حذف مستندات الوحدات المحذوفة من DB
    /// 4. تحديث الفهارس الثانوية لإزالة المراجع اليتيمة
    /// </summary>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد المفاتيح المحذوفة</returns>
    Task<int> CleanupIndexesAsync(CancellationToken cancellationToken = default);
    
    #endregion
    
    #region === الإحصائيات (Statistics) ===
    
    /// <summary>
    /// الحصول على إحصائيات الفهرس
    /// 
    /// الإحصائيات المُرجعة:
    /// • إجمالي عدد الوحدات المفهرسة
    /// • إجمالي عدد العقارات
    /// • توزيع الوحدات حسب المدن
    /// • توزيع الوحدات حسب الأنواع
    /// • نطاقات الأسعار العامة
    /// • حجم الذاكرة المستخدمة
    /// • عدد الفهارس الثانوية
    /// </summary>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قاموس الإحصائيات</returns>
    Task<Dictionary<string, object>> GetIndexStatisticsAsync(CancellationToken cancellationToken = default);
    
    #endregion
}
