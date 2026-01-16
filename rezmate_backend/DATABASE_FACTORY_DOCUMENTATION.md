# 📚 توثيق YemenBookingDbContextFactory

## 📌 **الغرض من YemenBookingDbContextFactory**

`YemenBookingDbContextFactory` هو **مُولّد سياق قاعدة البيانات في وقت التصميم** (Design-Time)

### ✅ **متى يُستخدم؟**

يُستخدم **فقط** عند تشغيل أدوات EF Core CLI:

```bash
# عند إنشاء Migration
dotnet ef migrations add YourMigrationName

# عند تحديث قاعدة البيانات
dotnet ef database update

# عند حذف قاعدة البيانات
dotnet ef database drop
```

### ❌ **متى لا يُستخدم؟**

**لا يُستخدم إطلاقاً في Runtime** - عند تشغيل المشروع (`dotnet run`)

---

## 🎯 **هل يؤثر على البحث والفلترة؟**

### الجواب القصير: **لا**

### التفصيل:

| الجانب | استخدام Factory | استخدام Runtime |
|--------|-----------------|-----------------|
| **المتى** | Design-Time فقط | عند تشغيل التطبيق |
| **الاستخدام** | Migrations | البحث/الفلترة/الحجوزات |
| **DbContext Source** | `YemenBookingDbContextFactory` | `DI Container` في `Program.cs` |
| **HttpContext** | غير متوفر ❌ | متوفر ✅ |
| **CurrentUser** | غير متوفر ❌ | متوفر ✅ |
| **التأثير على البحث** | صفر 0️⃣ | يعمل بشكل كامل ✅ |

---

## 🔧 **التحسينات المطبقة**

### ✅ **قبل التحسين:**

```csharp
public YemenBookingDbContext CreateDbContext(string[] args)
{
    var optionsBuilder = new DbContextOptionsBuilder<YemenBookingDbContext>();
    
    // ❌ Hard-coded connection string
    var connectionString = "Host=localhost;Database=YemenBookingDb;...";
    
    optionsBuilder.UseNpgsql(connectionString);
    
    return new YemenBookingDbContext(optionsBuilder.Options);
}
```

**المشاكل:**
- ❌ Connection string مكتوب مباشرة في الكود
- ❌ لا يقرأ من appsettings.json
- ❌ صعوبة التعديل حسب البيئة
- ❌ لا يدعم Retry Logic

---

### ✅ **بعد التحسين:**

```csharp
public YemenBookingDbContext CreateDbContext(string[] args)
{
    // 1️⃣ قراءة Configuration من appsettings.json تلقائياً
    var apiProjectPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "YemenBooking.Api");
    
    var configuration = new ConfigurationBuilder()
        .SetBasePath(apiProjectPath)
        .AddJsonFile("appsettings.json", optional: false)
        .AddJsonFile("appsettings.Development.json", optional: true)
        .AddEnvironmentVariables()
        .Build();
    
    // 2️⃣ قراءة Connection String من Configuration
    var connectionString = configuration.GetConnectionString("DefaultConnection");
    
    if (string.IsNullOrEmpty(connectionString))
        throw new InvalidOperationException("❌ Connection String مفقود");
    
    // 3️⃣ إعداد DbContext مع Retry Logic
    var optionsBuilder = new DbContextOptionsBuilder<YemenBookingDbContext>();
    
    optionsBuilder.UseNpgsql(connectionString, npgsqlOptions =>
    {
        npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorCodesToAdd: null);
        
        npgsqlOptions.MigrationsAssembly("YemenBooking.Infrastructure");
    });
    
    return new YemenBookingDbContext(optionsBuilder.Options);
}
```

**المميزات:**
- ✅ قراءة تلقائية من appsettings.json
- ✅ دعم بيئات متعددة (Development/Production)
- ✅ Retry Logic للتعامل مع انقطاع الاتصال
- ✅ رسائل خطأ واضحة
- ✅ مرونة في التعديل

---

## 📊 **مقارنة شاملة**

### **الطريقة القديمة (Hard-coded)**

| الميزة | الحالة |
|--------|---------|
| سهولة التعديل | ❌ صعبة - يتطلب تعديل الكود |
| دعم البيئات المتعددة | ❌ لا |
| Retry Logic | ❌ لا |
| قراءة من appsettings | ❌ لا |
| رسائل خطأ واضحة | ❌ لا |
| احترافية | ⚠️ متوسطة |

### **الطريقة الجديدة (Configuration-based)**

| الميزة | الحالة |
|--------|---------|
| سهولة التعديل | ✅ سهلة - تعديل appsettings فقط |
| دعم البيئات المتعددة | ✅ نعم |
| Retry Logic | ✅ نعم (3 محاولات) |
| قراءة من appsettings | ✅ نعم |
| رسائل خطأ واضحة | ✅ نعم |
| احترافية | ✅ عالية جداً |

---

## 🛠️ **أمثلة الاستخدام**

### 1️⃣ **إنشاء Migration جديدة**

```bash
cd /home/ameen/Desktop/BOOKIN/BOOKIN/backend

dotnet ef migrations add YourMigrationName \
  --project YemenBooking.Infrastructure \
  --startup-project YemenBooking.Api
```

**ما يحدث:**
1. EF Core يستدعي `YemenBookingDbContextFactory.CreateDbContext()`
2. Factory يقرأ Connection String من `appsettings.json`
3. يتم إنشاء Migration بناءً على التغييرات في DbContext

---

### 2️⃣ **تحديث قاعدة البيانات**

```bash
dotnet ef database update \
  --project YemenBooking.Infrastructure \
  --startup-project YemenBooking.Api
```

**ما يحدث:**
1. Factory يقرأ Connection String
2. يتم الاتصال بقاعدة البيانات
3. تطبيق جميع Migrations المعلقة

---

### 3️⃣ **حذف قاعدة البيانات**

```bash
dotnet ef database drop --force \
  --project YemenBooking.Infrastructure \
  --startup-project YemenBooking.Api
```

---

## 🔍 **كيف يعمل DbContext في Runtime؟**

عند تشغيل التطبيق (`dotnet run`), **لا يُستخدم Factory** - بل يتم إنشاء DbContext من `Program.cs`:

```csharp
// في Program.cs
builder.Services.AddDbContext<YemenBookingDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
);

// عند الاستخدام في Controller/Service
public class PropertyController
{
    private readonly YemenBookingDbContext _context;
    
    // DI Container يُنشئ DbContext تلقائياً
    public PropertyController(YemenBookingDbContext context)
    {
        _context = context;
    }
}
```

**الفرق الرئيسي:**

| المكون | Design-Time (Factory) | Runtime (DI) |
|--------|----------------------|--------------|
| **IHttpContextAccessor** | ❌ غير متوفر | ✅ متوفر |
| **Current User** | ❌ غير متوفر | ✅ متوفر |
| **Audit Logging** | ❌ معطل | ✅ يعمل |
| **الاستخدام** | Migrations فقط | كل شيء آخر |

---

## ⚠️ **ملاحظات مهمة**

### 1️⃣ **لماذا لا نستخدم IHttpContextAccessor في Factory؟**

**الجواب:** لأن HttpContext **غير متوفر** في Design-Time

```csharp
// ✅ هذا صحيح - Constructor بدون IHttpContextAccessor
return new YemenBookingDbContext(optionsBuilder.Options);

// ❌ هذا خطأ - IHttpContextAccessor غير متوفر في Design-Time
// return new YemenBookingDbContext(optionsBuilder.Options, httpContextAccessor);
```

لهذا السبب، يوجد **Constructor ثانوي** في `YemenBookingDbContext`:

```csharp
// Constructor للـRuntime (مع HttpContext)
public YemenBookingDbContext(
    DbContextOptions<YemenBookingDbContext> options,
    IHttpContextAccessor httpContextAccessor) : base(options)
{
    _httpContextAccessor = httpContextAccessor;
}

// Constructor للـDesign-Time (بدون HttpContext)
public YemenBookingDbContext(
    DbContextOptions<YemenBookingDbContext> options) : base(options)
{
    _httpContextAccessor = null!;
}
```

---

### 2️⃣ **كيف يجد Factory ملف appsettings.json؟**

```csharp
var apiProjectPath = Path.Combine(
    Directory.GetCurrentDirectory(),  // المجلد الحالي (YemenBooking.Infrastructure)
    "..",                              // العودة للخلف
    "YemenBooking.Api"                 // الدخول لمجلد YemenBooking.Api
);
```

**المسار الكامل:**
```
/home/ameen/Desktop/BOOKIN/BOOKIN/backend/
  ├── YemenBooking.Infrastructure/  ← نحن هنا
  └── YemenBooking.Api/
      ├── appsettings.json           ← يقرأ من هنا
      └── appsettings.Development.json
```

---

### 3️⃣ **ماذا لو كان Connection String خاطئ؟**

Factory يتحقق تلقائياً:

```csharp
if (string.IsNullOrEmpty(connectionString))
{
    throw new InvalidOperationException(
        "❌ لم يتم العثور على Connection String في appsettings.json\n" +
        "تأكد من وجود 'ConnectionStrings:DefaultConnection' في ملف الإعدادات");
}
```

**مثال على الخطأ:**
```
❌ لم يتم العثور على Connection String في appsettings.json
تأكد من وجود 'ConnectionStrings:DefaultConnection' في ملف الإعدادات
```

---

## 🎓 **الخلاصة**

### ✅ **ما فهمناه:**

1. ✅ `YemenBookingDbContextFactory` يُستخدم **فقط في Design-Time**
2. ✅ **لا يؤثر** على البحث/الفلترة/Runtime
3. ✅ يقرأ Connection String من **appsettings.json** (بعد التحسين)
4. ✅ يدعم **Retry Logic** للمحاولات الفاشلة
5. ✅ يستخدم **Constructor بدون HttpContext** (طبيعي في Design-Time)
6. ✅ في Runtime، يُستخدم DbContext من **DI Container** (مع HttpContext)

---

### 🎯 **التوصيات:**

1. ✅ استخدم الحل المحسّن الحالي (يقرأ من appsettings.json)
2. ✅ لا داعي للقلق من تأثيره على البحث/الفلترة
3. ✅ تأكد من وجود Connection String في appsettings.json
4. ⚠️ لا تحاول إضافة IHttpContextAccessor للـFactory (غير متوفر في Design-Time)

---

## 📞 **للمساعدة**

إذا واجهت مشاكل مع Migrations:

```bash
# تحقق من Connection String
cat backend/YemenBooking.Api/appsettings.Development.json | grep DefaultConnection

# تحقق من أن PostgreSQL يعمل
psql -U postgres -h localhost -c "SELECT version();"

# حاول إنشاء Migration
cd backend
dotnet ef migrations add TestMigration \
  --project YemenBooking.Infrastructure \
  --startup-project YemenBooking.Api \
  --verbose
```

---

**تاريخ الإنشاء:** 2025-01-15  
**الإصدار:** 1.0  
**الحالة:** ✅ مُحسّن ومُوثّق
