# إصلاح مشكلة Transaction مع NpgsqlRetryingExecutionStrategy

## المشكلة الأصلية

```
System.InvalidOperationException: The configured execution strategy 'NpgsqlRetryingExecutionStrategy' does not support user-initiated transactions.
```

### السبب الجذري

كان `UnitOfWork.ExecuteInTransactionAsync` يستخدم:
```csharp
await BeginTransactionAsync(cancellationToken);
// ... operations
await CommitTransactionAsync(cancellationToken);
```

هذا التصميم **لا يتوافق** مع `NpgsqlRetryingExecutionStrategy` لأن:
1. الـ Execution Strategy يحتاج أن يُدير retry logic بنفسه
2. لا يمكن دمج user-initiated transactions مع auto-retry strategy
3. عند حدوث خطأ، الـ Strategy يحتاج re-execute **كامل** Transaction block

---

## الحل الصحيح

### 1. تحديث UnitOfWork.cs

استخدام **ExecutionStrategy Pattern** من EF Core:

```csharp
public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
{
    // استخدام ExecutionStrategy للتوافق مع NpgsqlRetryingExecutionStrategy
    var strategy = _context.Database.CreateExecutionStrategy();
    
    return await strategy.ExecuteAsync<Func<Task<T>>, T>(
        state: operation,
        operation: async (context, state, ct) =>
        {
            await using var transaction = await context.Database.BeginTransactionAsync(ct);
            try
            {
                var result = await state();
                await transaction.CommitAsync(ct);
                return result;
            }
            catch
            {
                await transaction.RollbackAsync(ct);
                throw;
            }
        },
        verifySucceeded: null,
        cancellationToken: cancellationToken);
}
```

### كيف يعمل الحل:

1. **CreateExecutionStrategy()**: ينشئ instance من NpgsqlRetryingExecutionStrategy
2. **ExecuteAsync<TState, TResult>**: يستدعي lambda مع:
   - `state`: العملية المطلوب تنفيذها
   - `operation`: lambda تُدير Transaction lifecycle
   - `context`: DbContext (للوصول لـ Database)
   - Retry logic تلقائي عند transient failures

3. **Transaction Scope**: محصور داخل lambda، فالـ Strategy يمكنه إعادة تنفيذه بالكامل

---

## الملفات المُصلحة

### ✅ Core Fix
- `YemenBooking.Infrastructure/UnitOfWork/UnitOfWork.cs`
  - `ExecuteInTransactionAsync<T>` 
  - `ExecuteInTransactionAsync` (void version)

### ✅ Handlers Fixed
- `DeleteImagesCommandHandler.cs` - حذف الصور
- `CreateUnitCommandHandler.cs` - إنشاء وحدة
- `UpdateUnitCommandHandler.cs` - تحديث وحدة (كانت تعمل بالفعل)

### ✅ Supporting Fixes
- `DataSeedingService.cs` - إصلاح `Payment.Notes` → `PaymentStatus.Refunded`

---

## الفوائد

✅ **Automatic Retries**: عند حدوث transient failures (network, deadlock)  
✅ **Clean Code**: Handlers تستخدم Transaction بشكل طبيعي  
✅ **Consistency**: كل Repositories تعمل مع نفس الـ Strategy  
✅ **No Breaking Changes**: الـ API لم يتغير، فقط التنفيذ الداخلي  

---

## Testing Checklist

- [x] Build successful
- [ ] Create Unit test
- [ ] Update Unit test  
- [ ] Delete Images test
- [ ] Concurrent requests test
- [ ] Deadlock simulation test

---

## الأنماط المُطبّقة

1. **Execution Strategy Pattern** (EF Core)
2. **Unit of Work Pattern** (Repository)
3. **Retry Pattern** (Resilience)
4. **Ambient Transaction** (automatic scope)

---

## ملاحظات مهمة

⚠️ **لا تستخدم** `BeginTransactionAsync` مباشرة عندما يكون `RetryingExecutionStrategy` مُفعّل  
⚠️ **استخدم دائماً** `CreateExecutionStrategy().ExecuteAsync`  
⚠️ **تأكد** أن الـ operation lambda قابلة لإعادة التنفيذ (idempotent)  

---

**تاريخ الإصلاح**: 2025-11-17  
**المطور**: GitHub Copilot  
**النسخة**: 1.0
