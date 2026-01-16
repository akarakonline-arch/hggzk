# 💱 تحليل: التعامل مع العملات المتعددة في البحث والفلترة

## 📋 السيناريو

**البيئة:**
- النظام يدعم **3 عملات**:
  1. **عملة محلية افتراضية** (مثلاً: YER - الريال اليمني)
  2. **عملة أجنبية 1** (مثلاً: USD - الدولار الأمريكي)
  3. **عملة أجنبية 2** (مثلاً: SAR - الريال السعودي)
- كل عملة أجنبية لها **سعر صرف** مقابل العملة المحلية
- العقارات/الوحدات تتعامل بعملات مختلفة:
  - بعضها بالعملة المحلية (YER)
  - بعضها بالدولار (USD)
  - بعضها بالريال السعودي (SAR)

**المشكلة:**
عندما يبحث المستخدم عن وحدات بنطاق سعري معين (مثلاً: 100-200 دولار)، كيف نعرض له جميع الوحدات المتاحة ضمن هذا النطاق **بغض النظر عن عملتها الأصلية**؟

---

## 🎯 الحل المقترح من المستخدم

**الخطوات:**
1. جلب جميع عملات النظام (YER, USD, SAR)
2. مصارفة سعر المستخدم بجميع العملات
3. تمرير الأسعار المصارفة في البحث

**مثال:**
```
المستخدم يبحث بـ: 100-200 USD

بعد المصارفة:
- 100-200 USD (كما هو)
- 26,000-52,000 YER (بافتراض 1 USD = 260 YER)
- 375-750 SAR (بافتراض 1 USD = 3.75 SAR)

ثم البحث:
WHERE 
  (Currency = 'USD' AND Price BETWEEN 100 AND 200) OR
  (Currency = 'YER' AND Price BETWEEN 26000 AND 52000) OR
  (Currency = 'SAR' AND Price BETWEEN 375 AND 750)
```

---

## ✅ التقييم: هل هذا الحل هو الأفضل؟

### المزايا ✅

1. **بساطة التطبيق:**
   - سهل الفهم والتنفيذ
   - لا يحتاج تعديلات كبيرة في قاعدة البيانات

2. **دقة النتائج:**
   - يعرض جميع الوحدات المتاحة ضمن النطاق
   - لا يستبعد وحدات بسبب اختلاف العملة

3. **مرونة:**
   - يدعم أي عدد من العملات
   - سهل الإضافة والتعديل

4. **أداء مقبول:**
   - استعلام SQL واحد مع `OR` على العملات
   - الفهارس على (Currency, Price) تسرّع البحث

---

### العيوب ⚠️

1. **اعتماد على سعر الصرف الحالي:**
   - إذا تغير سعر الصرف، النتائج قد تتغير
   - الوحدة قد تظهر اليوم ولا تظهر غداً (بنفس البحث)

2. **عدم احترام العملة المفضلة:**
   - المستخدم قد يريد نتائج بعملة معينة فقط
   - الحل الحالي يعرض جميع العملات

3. **عرض السعر للمستخدم:**
   - هل نعرض السعر بعملته الأصلية أم نحوّله؟
   - قد يُربك المستخدم رؤية أسعار بعملات مختلفة

---

## 💡 الحلول البديلة

### الحل 1: التوحيد في قاعدة البيانات (Normalization)

**الفكرة:**
- تخزين جميع الأسعار بعملة موحدة (مثلاً USD أو YER)
- إضافة عمود `DisplayPrice` و `DisplayCurrency` للعرض فقط

**الجدول:**
```sql
CREATE TABLE Units (
  Id UUID PRIMARY KEY,
  Name VARCHAR,
  
  -- السعر الموحد (للبحث والفلترة)
  NormalizedPrice DECIMAL(18,2),  -- بالدولار مثلاً
  NormalizedCurrency VARCHAR(3),  -- دائماً 'USD'
  
  -- السعر للعرض (كما أدخله المالك)
  DisplayPrice DECIMAL(18,2),
  DisplayCurrency VARCHAR(3)       -- YER, USD, SAR
);

-- فهرس سريع
CREATE INDEX IX_Units_NormalizedPrice ON Units (NormalizedPrice);
```

**الاستعلام:**
```sql
-- بسيط جداً!
SELECT * FROM Units
WHERE NormalizedPrice BETWEEN @MinPrice AND @MaxPrice;
```

**المزايا:**
- ✅ استعلام بسيط وسريع جداً
- ✅ فهرس واحد فقط
- ✅ نتائج ثابتة (لا تتغير بتغير سعر الصرف)

**العيوب:**
- ⚠️ تحديث `NormalizedPrice` عند تغيير سعر الصرف
- ⚠️ مزامنة بين DisplayPrice و NormalizedPrice
- ⚠️ تعقيد في الإدخال والتعديل

---

### الحل 2: Computed Column في PostgreSQL

**الفكرة:**
- عمود محسوب تلقائياً يحوّل السعر لعملة موحدة
- استخدام دالة PostgreSQL للمصارفة

**الجدول:**
```sql
CREATE TABLE Units (
  Id UUID PRIMARY KEY,
  BasePrice DECIMAL(18,2),
  Currency VARCHAR(3),
  
  -- عمود محسوب (Generated Column)
  PriceInUSD DECIMAL(18,2) GENERATED ALWAYS AS (
    CASE
      WHEN Currency = 'USD' THEN BasePrice
      WHEN Currency = 'YER' THEN BasePrice / 260.0  -- سعر الصرف ثابت؟
      WHEN Currency = 'SAR' THEN BasePrice / 3.75
      ELSE BasePrice
    END
  ) STORED
);

-- فهرس على العمود المحسوب
CREATE INDEX IX_Units_PriceInUSD ON Units (PriceInUSD);
```

**الاستعلام:**
```sql
SELECT * FROM Units
WHERE PriceInUSD BETWEEN @MinPrice AND @MaxPrice;
```

**المزايا:**
- ✅ بساطة الاستعلام
- ✅ فهرس سريع
- ✅ تلقائي (لا حاجة لتحديث يدوي)

**العيوب:**
- ⚠️ سعر الصرف ثابت في الكود (صعب التعديل)
- ⚠️ لا يدعم أسعار صرف ديناميكية
- ⚠️ PostgreSQL فقط (غير متوافق مع قواعد بيانات أخرى)

---

### الحل 3: Application-Level Conversion (المقترح الحالي - محسّن)

**الفكرة:**
- نفس الحل المقترح، لكن مع تحسينات
- إضافة Cache لأسعار الصرف
- إضافة خيار للمستخدم لاختيار "العرض بعملة موحدة"

**الخطوات المحسّنة:**
```csharp
// 1. جلب أسعار الصرف (مع Cache)
var exchangeRates = await GetExchangeRates(); // Cache لمدة ساعة

// 2. تحويل نطاق السعر لجميع العملات
var priceRanges = new List<(string Currency, decimal Min, decimal Max)>
{
    ("USD", request.MinPrice, request.MaxPrice),  // كما هو
    ("YER", request.MinPrice * exchangeRates["YER"], request.MaxPrice * exchangeRates["YER"]),
    ("SAR", request.MinPrice * exchangeRates["SAR"], request.MaxPrice * exchangeRates["SAR"])
};

// 3. بناء استعلام SQL ديناميكي
var query = context.Units.Where(u => 
    priceRanges.Any(pr => 
        u.BasePrice.Currency == pr.Currency &&
        u.BasePrice.Amount >= pr.Min &&
        u.BasePrice.Amount <= pr.Max
    )
);

// 4. (اختياري) تحويل جميع الأسعار لعملة واحدة للعرض
if (request.ShowInSingleCurrency)
{
    foreach (var unit in units)
    {
        unit.DisplayPrice = ConvertTo(unit.BasePrice, request.PreferredCurrency);
        unit.DisplayCurrency = request.PreferredCurrency;
    }
}
```

**المزايا:**
- ✅ مرونة كاملة (أسعار صرف ديناميكية)
- ✅ لا يحتاج تعديل قاعدة البيانات
- ✅ خيار العرض بعملة موحدة

**العيوب:**
- ⚠️ استعلام أطول قليلاً (OR على 3 عملات)
- ⚠️ اعتماد على Application Layer

---

## 🏆 التوصية النهائية

### ✅ الحل الموصى به: **Application-Level Conversion (الحل 3 المحسّن)**

**السبب:**

1. **مرونة:**
   - أسعار الصرف ديناميكية (يمكن تحديثها بدون تعديل الكود)
   - سهولة إضافة عملات جديدة

2. **بساطة:**
   - لا يحتاج تعديلات في قاعدة البيانات
   - لا يحتاج مزامنة بين أعمدة

3. **تجربة مستخدم أفضل:**
   - خيار العرض بعملة موحدة
   - خيار الفلترة بعملة محددة

4. **أداء مقبول:**
   - مع فهارس `(Currency, Amount)` الأداء ممتاز
   - Cache لأسعار الصرف (تحديث كل ساعة)

---

## 🛠️ التطبيق الفعلي

### 1️⃣ جدول أسعار الصرف

```csharp
public class ExchangeRate : BaseEntity<Guid>
{
    public string FromCurrency { get; set; }  // USD
    public string ToCurrency { get; set; }    // YER
    public decimal Rate { get; set; }          // 260.0
    public DateTime EffectiveDate { get; set; }
    public bool IsActive { get; set; }
}
```

### 2️⃣ خدمة أسعار الصرف

```csharp
public class CurrencyService
{
    private readonly IMemoryCache _cache;
    private readonly YemenBookingDbContext _context;
    
    // Cache لمدة ساعة
    public async Task<Dictionary<string, decimal>> GetExchangeRatesAsync(string baseCurrency = "USD")
    {
        var cacheKey = $"ExchangeRates_{baseCurrency}";
        
        if (!_cache.TryGetValue(cacheKey, out Dictionary<string, decimal> rates))
        {
            rates = await _context.ExchangeRates
                .Where(er => er.FromCurrency == baseCurrency && er.IsActive)
                .OrderByDescending(er => er.EffectiveDate)
                .GroupBy(er => er.ToCurrency)
                .Select(g => g.First())
                .ToDictionaryAsync(er => er.ToCurrency, er => er.Rate);
            
            _cache.Set(cacheKey, rates, TimeSpan.FromHours(1));
        }
        
        return rates;
    }
}
```

### 3️⃣ تعديل UnitSearchRequest

```csharp
public class UnitSearchRequest
{
    // ... الحقول الموجودة
    
    // حقول جديدة للعملات
    public string? SearchCurrency { get; set; } = "USD";  // العملة المطلوبة للبحث
    public bool ConvertToSingleCurrency { get; set; } = false;  // عرض النتائج بعملة واحدة
    public string? PreferredDisplayCurrency { get; set; }  // العملة المفضلة للعرض
}
```

### 4️⃣ تعديل PostgresUnitSearchEngine

```csharp
private async Task<IQueryable<Unit>> ApplyPriceFilterAsync(
    IQueryable<Unit> query, 
    UnitSearchRequest request)
{
    if (!request.MinPrice.HasValue && !request.MaxPrice.HasValue)
        return query;
    
    // جلب أسعار الصرف
    var exchangeRates = await _currencyService.GetExchangeRatesAsync(request.SearchCurrency);
    
    // تحويل النطاق السعري لجميع العملات
    var priceRanges = new List<PriceRange>
    {
        new(request.SearchCurrency, request.MinPrice ?? 0, request.MaxPrice ?? decimal.MaxValue)
    };
    
    foreach (var (currency, rate) in exchangeRates)
    {
        priceRanges.Add(new PriceRange(
            currency,
            (request.MinPrice ?? 0) * rate,
            (request.MaxPrice ?? decimal.MaxValue) * rate
        ));
    }
    
    // تطبيق الفلتر
    var predicate = PredicateBuilder.New<Unit>(false);  // OR condition
    
    foreach (var range in priceRanges)
    {
        var currency = range.Currency;
        var min = range.Min;
        var max = range.Max;
        
        predicate = predicate.Or(u => 
            u.BasePrice.Currency == currency &&
            u.BasePrice.Amount >= min &&
            u.BasePrice.Amount <= max
        );
    }
    
    return query.Where(predicate);
}

private record PriceRange(string Currency, decimal Min, decimal Max);
```

### 5️⃣ تحويل الأسعار للعرض

```csharp
private async Task ConvertPricesForDisplayAsync(
    List<UnitSearchItem> units,
    UnitSearchRequest request)
{
    if (!request.ConvertToSingleCurrency)
        return;
    
    var targetCurrency = request.PreferredDisplayCurrency ?? request.SearchCurrency ?? "USD";
    var rates = await _currencyService.GetExchangeRatesAsync(targetCurrency);
    
    foreach (var unit in units)
    {
        if (unit.Currency == targetCurrency)
            continue;  // نفس العملة، لا حاجة للتحويل
        
        // تحويل السعر
        if (rates.TryGetValue(unit.Currency, out var rate))
        {
            unit.DisplayPrice = unit.BasePrice / rate;  // تحويل عكسي
            unit.DisplayCurrency = targetCurrency;
            unit.OriginalPrice = unit.BasePrice;
            unit.OriginalCurrency = unit.Currency;
        }
    }
}
```

---

## 📊 مثال عملي

**السيناريو:**
```
المستخدم يبحث:
- MinPrice: 100 USD
- MaxPrice: 200 USD
- ConvertToSingleCurrency: true
- PreferredDisplayCurrency: "USD"

أسعار الصرف:
- 1 USD = 260 YER
- 1 USD = 3.75 SAR
```

**النتيجة:**

| الوحدة | السعر الأصلي | العملة | السعر المعروض | ملاحظة |
|--------|--------------|---------|---------------|---------|
| شقة A | 150 USD | USD | 150 USD | ✅ ضمن النطاق |
| فيلا B | 45,000 YER | YER | 173 USD | ✅ ضمن النطاق (45000÷260) |
| شاليه C | 500 SAR | SAR | 133 USD | ✅ ضمن النطاق (500÷3.75) |
| قصر D | 300 USD | USD | - | ❌ خارج النطاق |
| استراحة E | 80,000 YER | YER | - | ❌ خارج النطاق (307 USD) |

---

## ⚡ الأداء

### الاستعلام الفعلي:
```sql
SELECT * FROM "Units"
WHERE 
  ("BasePrice_Currency" = 'USD' AND "BasePrice_Amount" BETWEEN 100 AND 200) OR
  ("BasePrice_Currency" = 'YER' AND "BasePrice_Amount" BETWEEN 26000 AND 52000) OR
  ("BasePrice_Currency" = 'SAR' AND "BasePrice_Amount" BETWEEN 375 AND 750)
```

### الفهارس المطلوبة:
```sql
-- فهرس مركّب على (Currency, Amount)
CREATE INDEX IX_Units_Currency_Price 
ON "Units" ("BasePrice_Currency", "BasePrice_Amount");
```

### زمن التنفيذ المتوقع:
- **بدون فهرس:** 50-80 ms (90,000 وحدة)
- **مع فهرس:** 10-15 ms ⚡

---

## ✅ الخلاصة

### الإجابة على سؤالك:

> **هل الحل المقترح هو الأفضل؟**

**نعم ✅** - بشرط التحسينات التالية:

1. ✅ **استخدام Cache لأسعار الصرف** (تحديث كل ساعة)
2. ✅ **إضافة خيار ConvertToSingleCurrency** للعرض
3. ✅ **إضافة فهرس (Currency, Amount)** للأداء
4. ✅ **عرض السعر الأصلي والمحول** للشفافية

### البدائل الأخرى:
- **Normalized Price Column:** جيد لكن يحتاج مزامنة
- **Computed Column:** جيد لكن سعر الصرف ثابت
- **Application-Level (المحسّن):** ✅ الأفضل للمرونة والدقة

---

**🚀 جاهز للتطبيق!**
