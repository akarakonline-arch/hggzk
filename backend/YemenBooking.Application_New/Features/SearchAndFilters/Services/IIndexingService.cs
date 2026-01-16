// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// استيراد المكتبات والمساحات الأساسية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.SearchAndFilters.Services {
    /// <summary>
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// واجهة خدمة الفهرسة والبحث - IIndexingService
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 
    /// الوصف:
    /// واجهة موحدة لخدمات الفهرسة والبحث في نظام حجوزات اليمن.
    /// تعرّف عقد (Contract) موحد لجميع عمليات الفهرسة والبحث بغض النظر عن التقنية المستخدمة.
    /// 
    /// المسؤوليات الرئيسية:
    /// • معالجة أحداث دورة حياة العقارات (إنشاء، تحديث، حذف)
    /// • معالجة أحداث دورة حياة الوحدات (إنشاء، تحديث، حذف)
    /// • تحديث فهارس الإتاحة والتسعير
    /// • معالجة التغييرات على الحقول الديناميكية
    /// • تنفيذ عمليات البحث والفلترة
    /// • الصيانة وإعادة بناء الفهارس
    /// 
    /// التطبيقات (Implementations):
    /// • RedisIndexingService: تطبيق مبني على Redis للأداء العالي
    /// • (يمكن إضافة تطبيقات أخرى: ElasticSearch، Solr، إلخ)
    /// 
    /// الاستخدام:
    /// يتم حقن هذه الواجهة عبر Dependency Injection وتُستخدم في:
    /// • Domain Events Handlers
    /// • Application Services
    /// • Background Jobs
    /// • API Controllers
    /// 
    /// ملاحظات هامة:
    /// • جميع الدوال غير متزامنة (Async) لتحسين الأداء
    /// • تدعم CancellationToken لإلغاء العمليات الطويلة
    /// • مصممة للعمل ضمن بيئة موزعة (Distributed)
    /// • thread-safe ويمكن استخدامها من threads متعددة
    /// </summary>
    public interface IIndexingService
    {
        #region إدارة العقارات (Properties Management)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث إنشاء عقار جديد
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند إنشاء عقار جديد في النظام.
        /// تقوم بإنشاء سجل فهرسة للعقار مع جميع بياناته ووحداته.
        /// 
        /// المعاملات:
        /// <param name="propertyId">معرف العقار الفريد</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// 
        /// الإرجاع:
        /// Task: مهمة غير متزامنة تكتمل عند انتهاء الفهرسة
        /// </summary>
        Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث تحديث عقار
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند تحديث بيانات عقار موجود.
        /// تقوم بتحديث مستند الفهرسة مع البيانات الجديدة.
        /// 
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث حذف عقار
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند حذف عقار من النظام.
        /// تقوم بحذف مستند الفهرسة وجميع وحداته من الفهرس.
        /// 
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        
        #endregion

        #region إدارة الوحدات (Units Management)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث إنشاء وحدة جديدة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند إضافة وحدة جديدة لعقار.
        /// تقوم بإنشاء مستند JSON كامل للوحدة مع جميع بياناتها.
        /// 
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="propertyId">معرف العقار المالك</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث تحديث وحدة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند تحديث بيانات وحدة موجودة.
        /// تقوم بتحديث مستند الفهرسة والفهارس الثانوية.
        /// 
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حدث حذف وحدة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند حذف وحدة من العقار.
        /// تقوم بحذف مستند الفهرسة وتحديث الفهارس الثانوية.
        /// 
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        
        #endregion

        #region إدارة الإتاحة والتسعير (Availability & Pricing)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة تغيير إتاحة الوحدة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند تغيير فترات الإتاحة للوحدة.
        /// تقوم بتحديث سجلات الإتاحة في مستند الفهرسة.
        /// 
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="availableRanges">قائمة فترات الإتاحة (تاريخ البداية والنهاية)</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default);

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة تغيير قواعد التسعير
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند تحديث قواعد التسعير للوحدة.
        /// تقوم بتحديث نطاقات الأسعار (يومي، أسبوعي، شهري) في الفهرس.
        /// 
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="schedules">قائمة الجداول اليومية الجديدة</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnDailyScheduleChangedAsync(Guid unitId, Guid propertyId, List<DailyUnitSchedule> schedules, CancellationToken cancellationToken = default);
        
        #endregion

        #region إدارة الحقول الديناميكية (Dynamic Fields)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حذف حقل ديناميكي
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند حذف تعريف حقل ديناميكي من نوع الوحدة.
        /// تقوم بحذف الحقل من جميع مستندات الفهرسة المتأثرة.
        /// 
        /// <param name="fieldName">اسم الحقل المراد حذفه</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitTypeFieldDeletedAsync(string fieldName, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة تحديث حقل ديناميكي
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند تحديث تعريف حقل ديناميكي (تغيير اسم، نوع، أو أولوية).
        /// تقوم بتحديث الحقل في جميع مستندات الفهرسة المتأثرة.
        /// 
        /// <param name="oldFieldName">الاسم القديم للحقل</param>
        /// <param name="newFieldName">الاسم الجديد للحقل</param>
        /// <param name="newFieldType">نوع الحقل الجديد</param>
        /// <param name="isPrimary">هل الحقل فلتر أساسي</param>
        /// <param name="unitTypeId">معرف نوع الوحدة</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitTypeFieldUpdatedAsync(string oldFieldName, string newFieldName, string newFieldType, bool isPrimary, Guid unitTypeId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة حذف نوع وحدة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند حذف نوع وحدة كامل.
        /// تقوم بحذف جميع الحقول الديناميكية المرتبطة بهذا النوع.
        /// 
        /// <param name="unitTypeId">معرف نوع الوحدة</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnUnitTypeDeletedAsync(Guid unitTypeId, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالجة تغيير قيمة حقل ديناميكي
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتم استدعاؤها عند إضافة أو تعديل قيمة حقل ديناميكي لعقار.
        /// تقوم بتحديث قيمة الحقل في مستندات الفهرسة.
        /// 
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="fieldName">اسم الحقل</param>
        /// <param name="fieldValue">قيمة الحقل الجديدة</param>
        /// <param name="isAdd">هل هي عملية إضافة (true) أم تحديث (false)</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default);
        
        #endregion

        #region عمليات البحث (Search Operations)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// تنفيذ عملية بحث متقدمة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// تنفذ عملية بحث وفلترة متقدمة في الفهرس.
        /// تدعم البحث حسب:
        /// • الموقع والمدينة
        /// • نطاقات الأسعار
        /// • التواريخ والإتاحة
        /// • المرافق والخدمات
        /// • الحقول الديناميكية
        /// • التقييمات والتصنيفات
        /// 
        /// المميزات:
        /// • البحث النصي الكامل (Full-Text Search)
        /// • الفلترة المتعددة المعايير
        /// • الترتيب حسب السعر، التقييم، أو الشعبية
        /// • Pagination للنتائج
        /// • أداء عالي (< 100ms للاستعلامات البسيطة)
        /// 
        /// <param name="request">كائن طلب البحث يحتوي على جميع معايير الفلترة والترتيب</param>
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// 
        /// الإرجاع:
        /// PropertySearchResult: نتائج البحث مع metadata (عدد النتائج، الوقت المستغرق، إلخ)
        /// </summary>
        Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default);
        
        #endregion

        #region عمليات الصيانة (Maintenance Operations)
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// تحسين قاعدة البيانات والفهارس
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// تقوم بعمليات تحسين وصيانة دورية للفهارس:
        /// • إزالة المستندات القديمة أو المحذوفة
        /// • ضغط الفهارس لتوفير المساحة
        /// • إعادة بناء الفهارس التالفة
        /// • تحديث الإحصائيات
        /// 
        /// الاستخدام:
        /// يُنصح بتشغيلها كمهمة مجدولة (Background Job) خارج أوقات الذروة.
        /// 
        /// ملاحظات:
        /// • قد تستغرق وقتاً طويلاً حسب حجم البيانات
        /// • لا تؤثر على توفر الخدمة (Non-blocking)
        /// </summary>
        Task OptimizeDatabaseAsync();
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// إعادة بناء الفهرس بالكامل
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// تقوم بإعادة بناء جميع الفهارس من الصفر:
        /// 1. حذف جميع المستندات الموجودة
        /// 2. قراءة البيانات من قاعدة البيانات الرئيسية
        /// 3. إعادة فهرسة جميع العقارات والوحدات
        /// 4. إعادة بناء الفهارس الثانوية
        /// 
        /// الاستخدام:
        /// • عند حدوث مشاكل في مزامنة البيانات
        /// • بعد تغييرات كبيرة في هيكل الفهرس
        /// • عند الترحيل من نظام فهرسة لآخر
        /// 
        /// تحذير:
        /// • عملية مكلفة جداً وتستغرق وقتاً طويلاً
        /// • قد تؤثر على أداء النظام أثناء التنفيذ
        /// • يُنصح بتشغيلها في بيئة منفصلة أو خارج أوقات الذروة
        /// 
        /// <param name="cancellationToken">رمز إلغاء العملية</param>
        /// </summary>
        Task RebuildIndexAsync(CancellationToken cancellationToken = default);
        
        #endregion
    }
}