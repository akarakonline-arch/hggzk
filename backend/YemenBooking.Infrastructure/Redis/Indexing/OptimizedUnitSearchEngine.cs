// using System;
// using System.Collections.Generic;
// using System.Diagnostics;
// using System.Globalization;
// using System.Linq;
// using System.Text.Json;
// using System.Threading;
// using System.Threading.Tasks;
// using Microsoft.Extensions.Logging;
// using StackExchange.Redis;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Indexing.Models;
// using YemenBooking.Core.Indexing.RediSearch;
// using YemenBooking.Infrastructure.Redis.Core.Interfaces;

// namespace YemenBooking.Infrastructure.Redis.Indexing;

// /// <summary>
// /// محرك البحث المحسّن - استراتيجية البحث المباشر في RediSearch
// /// 
// /// الاستراتيجية الجديدة:
// /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// /// المرحلة 1: البحث عن الوحدات المحجوزة (إذا كانت هناك تواريخ)
// ///   - البحث في idx:periods:avail عن فترات محجوزة تتقاطع مع التواريخ
// ///   - الحصول على قائمة UnitIds المحجوزة
// /// 
// /// المرحلة 2: البحث في الوحدات بالمعايير الأخرى
// ///   - البحث في idx:units بجميع المعايير (المدينة، النوع، المرافق، إلخ)
// ///   - استثناء UnitIds المحجوزة
// /// 
// /// المرحلة 3: حساب السعر لكل وحدة (إذا كانت هناك تواريخ)
// ///   - لكل وحدة في النتائج:
// ///     • البحث في idx:periods:price عن فترات التسعير
// ///     • حساب السعر الإجمالي للفترة
// ///     • فلترة حسب MinPrice/MaxPrice إذا كانت محددة
// /// 
// /// المرحلة 4: الترتيب والصفحات
// ///   - ترتيب النتائج حسب المعايير المحددة
// ///   - تطبيق الصفحات (Pagination)
// /// </summary>
// public sealed class OptimizedUnitSearchEngine
// {
//     #region === الحقول الخاصة ===
    
//     private readonly IRedisConnectionManager _redisManager;
//     private readonly ILogger<OptimizedUnitSearchEngine> _logger;
//     private readonly JsonSerializerOptions _jsonOptions;
    
//     #endregion
    
//     #region === البناء والتهيئة ===
    
//     public OptimizedUnitSearchEngine(
//         IRedisConnectionManager redisManager,
//         ILogger<OptimizedUnitSearchEngine> logger)
//     {
//         _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
//         _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        
//         _jsonOptions = new JsonSerializerOptions
//         {
//             PropertyNameCaseInsensitive = true,
//             WriteIndented = false
//         };
//     }
    
//     #endregion
    
//     #region === البحث الرئيسي ===
    
//     /// <summary>
//     /// البحث عن الوحدات
//     /// </summary>
//     public async Task<UnitSearchResult> SearchUnitsAsync(
//         UnitSearchRequest request,
//         CancellationToken cancellationToken = default)
//     {
//         if (request == null)
//             throw new ArgumentNullException(nameof(request));
        
//         var stopwatch = Stopwatch.StartNew();
        
//         try
//         {
//             _logger.LogInformation(
//                 "بدء البحث: المدينة={City}, CheckIn={CheckIn}, CheckOut={CheckOut}",
//                 request.City, request.CheckIn, request.CheckOut);
            
//             // المرحلة 1: البحث عن الوحدات المحجوزة
//             HashSet<string>? excludedUnitIds = null;
//             if (request.CheckIn.HasValue && request.CheckOut.HasValue)
//             {
//                 excludedUnitIds = await GetBlockedUnitsAsync(
//                     request.CheckIn.Value,
//                     request.CheckOut.Value,
//                     cancellationToken);
                
//                 _logger.LogDebug("الوحدات المحجوزة: {Count}", excludedUnitIds?.Count ?? 0);
//             }
            
//             // المرحلة 2: البحث في الوحدات
//             var units = await SearchUnitsInIndexAsync(request, excludedUnitIds, cancellationToken);
            
//             _logger.LogDebug("الوحدات بعد الفلترة الأولية: {Count}", units.Count);
            
//             if (!units.Any())
//             {
//                 return new UnitSearchResult
//                 {
//                     Units = new List<UnitSearchItem>(),
//                     TotalCount = 0,
//                     PageNumber = request.PageNumber,
//                     PageSize = request.PageSize,
//                     SearchTimeMs = stopwatch.ElapsedMilliseconds
//                 };
//             }
            
//             // المرحلة 3: حساب الأسعار (إذا كانت هناك تواريخ)
//             List<UnitWithPrice> unitsWithPrices;
//             if (request.CheckIn.HasValue && request.CheckOut.HasValue)
//             {
//                 unitsWithPrices = await CalculatePricesForUnitsAsync(
//                     units,
//                     request.CheckIn.Value,
//                     request.CheckOut.Value,
//                     cancellationToken);
                
//                 // فلترة حسب السعر
//                 if (request.MinPrice.HasValue)
//                 {
//                     unitsWithPrices = unitsWithPrices
//                         .Where(u => u.TotalPrice >= request.MinPrice.Value)
//                         .ToList();
//                 }
                
//                 if (request.MaxPrice.HasValue)
//                 {
//                     unitsWithPrices = unitsWithPrices
//                         .Where(u => u.TotalPrice <= request.MaxPrice.Value)
//                         .ToList();
//                 }
//             }
//             else
//             {
//                 unitsWithPrices = units.Select(u => new UnitWithPrice
//                 {
//                     UnitId = u.UnitId,
//                     PropertyId = u.PropertyId,
//                     UnitName = u.UnitName,
//                     PropertyName = u.PropertyName,
//                     City = u.City,
//                     BasePrice = u.BasePrice,
//                     TotalPrice = u.BasePrice,
//                     FullDocument = u.FullDocument
//                 }).ToList();
//             }
            
//             _logger.LogDebug("الوحدات بعد حساب الأسعار: {Count}", unitsWithPrices.Count);
            
//             // المرحلة 4: الترتيب
//             unitsWithPrices = ApplySorting(unitsWithPrices, request.SortBy);
            
//             // المرحلة 5: الصفحات
//             var totalCount = unitsWithPrices.Count;
//             var offset = (request.PageNumber - 1) * request.PageSize;
//             var pagedUnits = unitsWithPrices
//                 .Skip(offset)
//                 .Take(request.PageSize)
//                 .ToList();
            
//             // بناء النتيجة النهائية
//             var result = new UnitSearchResult
//             {
//                 Units = pagedUnits.Select(u => new UnitSearchItem
//                 {
//                     UnitId = u.UnitId,
//                     PropertyId = u.PropertyId,
//                     UnitName = u.UnitName,
//                     PropertyName = u.PropertyName,
//                     City = u.City,
//                     BasePrice = u.BasePrice,
//                     TotalPrice = u.TotalPrice
//                 }).ToList(),
//                 TotalCount = totalCount,
//                 PageNumber = request.PageNumber,
//                 PageSize = request.PageSize,
//                 SearchTimeMs = stopwatch.ElapsedMilliseconds
//             };
            
//             _logger.LogInformation(
//                 "اكتمل البحث: {Count} وحدة من {Total} في {Ms}ms",
//                 result.Units.Count, result.TotalCount, result.SearchTimeMs);
            
//             return result;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "خطأ أثناء البحث عن الوحدات");
//             throw;
//         }
//     }
    
//     #endregion
    
//     #region === المراحل الفرعية ===
    
//     /// <summary>
//     /// المرحلة 1: البحث عن الوحدات المحجوزة
//     /// </summary>
//     private async Task<HashSet<string>> GetBlockedUnitsAsync(
//         DateTime checkIn,
//         DateTime checkOut,
//         CancellationToken cancellationToken)
//     {
//         try
//         {
//             var db = await _redisManager.GetDatabaseAsync();
//             var queryBuilder = new PeriodBasedQueryBuilder(new UnitSearchRequest
//             {
//                 CheckIn = checkIn,
//                 CheckOut = checkOut
//             });
            
//             var query = queryBuilder.BuildBlockedPeriodsQuery(checkIn, checkOut);
            
//             // تنفيذ البحث
//             var searchCmd = new List<object> { "FT.SEARCH" };
//             searchCmd.AddRange(query);
            
//             var result = await db.ExecuteAsync(searchCmd[0].ToString(), searchCmd.Skip(1).ToArray());
            
//             var blockedUnitIds = new HashSet<string>();
            
//             if (!result.IsNull)
//             {
//                 var resultArray = (RedisResult[])result;
                
//                 // النتيجة: [totalCount, key1, fields1, key2, fields2, ...]
//                 if (resultArray.Length > 1)
//                 {
//                     for (int i = 1; i < resultArray.Length; i += 2)
//                     {
//                         if (i + 1 < resultArray.Length)
//                         {
//                             var fields = (RedisResult[])resultArray[i + 1];
                            
//                             // البحث عن حقل unitId
//                             for (int j = 0; j < fields.Length; j += 2)
//                             {
//                                 if (fields[j].ToString() == PeriodBasedSearchSchema.AvailabilityPeriodFields.UNIT_ID)
//                                 {
//                                     var unitId = fields[j + 1].ToString();
//                                     if (!string.IsNullOrWhiteSpace(unitId))
//                                     {
//                                         blockedUnitIds.Add(unitId);
//                                     }
//                                     break;
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
            
//             return blockedUnitIds;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "خطأ أثناء البحث عن الوحدات المحجوزة");
//             return new HashSet<string>();
//         }
//     }
    
//     /// <summary>
//     /// المرحلة 2: البحث في الوحدات
//     /// </summary>
//     private async Task<List<UnitSearchDocument>> SearchUnitsInIndexAsync(
//         UnitSearchRequest request,
//         HashSet<string>? excludedUnitIds,
//         CancellationToken cancellationToken)
//     {
//         try
//         {
//             var db = await _redisManager.GetDatabaseAsync();
//             var queryBuilder = new PeriodBasedQueryBuilder(request);
            
//             var query = queryBuilder.BuildUnitsSearchQuery(excludedUnitIds);
            
//             // تنفيذ البحث
//             var searchCmd = new List<object> { "FT.SEARCH" };
//             searchCmd.AddRange(query);
            
//             var result = await db.ExecuteAsync(searchCmd[0].ToString(), searchCmd.Skip(1).ToArray());
            
//             var units = new List<UnitSearchDocument>();
            
//             if (!result.IsNull)
//             {
//                 var resultArray = (RedisResult[])result;
                
//                 // النتيجة: [totalCount, key1, fields1, key2, fields2, ...]
//                 if (resultArray.Length > 1)
//                 {
//                     for (int i = 1; i < resultArray.Length; i += 2)
//                     {
//                         if (i + 1 < resultArray.Length)
//                         {
//                             var fields = (RedisResult[])resultArray[i + 1];
                            
//                             var unit = ParseUnitDocument(fields);
//                             if (unit != null)
//                             {
//                                 units.Add(unit);
//                             }
//                         }
//                     }
//                 }
//             }
            
//             return units;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "خطأ أثناء البحث في الوحدات");
//             return new List<UnitSearchDocument>();
//         }
//     }
    
//     /// <summary>
//     /// المرحلة 3: حساب الأسعار لكل وحدة
//     /// </summary>
//     private async Task<List<UnitWithPrice>> CalculatePricesForUnitsAsync(
//         List<UnitSearchDocument> units,
//         DateTime checkIn,
//         DateTime checkOut,
//         CancellationToken cancellationToken)
//     {
//         var results = new List<UnitWithPrice>();
//         var db = await _redisManager.GetDatabaseAsync();
        
//         foreach (var unit in units)
//         {
//             try
//             {
//                 var queryBuilder = new PeriodBasedQueryBuilder(new UnitSearchRequest());
//                 var query = queryBuilder.BuildPricingPeriodsQuery(unit.UnitId, checkIn, checkOut);
                
//                 // تنفيذ البحث
//                 var searchCmd = new List<object> { "FT.SEARCH" };
//                 searchCmd.AddRange(query);
                
//                 var result = await db.ExecuteAsync(searchCmd[0].ToString(), searchCmd.Skip(1).ToArray());
                
//                 var pricingRules = new List<PricingPeriod>();
                
//                 if (!result.IsNull)
//                 {
//                     var resultArray = (RedisResult[])result;
                    
//                     if (resultArray.Length > 1)
//                     {
//                         for (int i = 1; i < resultArray.Length; i += 2)
//                         {
//                             if (i + 1 < resultArray.Length)
//                             {
//                                 var fields = (RedisResult[])resultArray[i + 1];
//                                 var period = ParsePricingPeriod(fields);
//                                 if (period != null)
//                                 {
//                                     pricingRules.Add(period);
//                                 }
//                             }
//                         }
//                     }
//                 }
                
//                 // حساب السعر الإجمالي
//                 decimal totalPrice;
//                 if (pricingRules.Any())
//                 {
//                     totalPrice = CalculateTotalPriceFromPeriods(pricingRules, checkIn, checkOut, unit.BasePrice);
//                 }
//                 else
//                 {
//                     var numberOfNights = (checkOut.Date - checkIn.Date).Days;
//                     totalPrice = unit.BasePrice * numberOfNights;
//                 }
                
//                 results.Add(new UnitWithPrice
//                 {
//                     UnitId = unit.UnitId,
//                     PropertyId = unit.PropertyId,
//                     UnitName = unit.UnitName,
//                     PropertyName = unit.PropertyName,
//                     City = unit.City,
//                     BasePrice = unit.BasePrice,
//                     TotalPrice = totalPrice,
//                     FullDocument = unit.FullDocument
//                 });
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogWarning(ex, "خطأ أثناء حساب السعر للوحدة {UnitId}", unit.UnitId);
                
//                 // استخدام السعر الأساسي في حالة الخطأ
//                 var numberOfNights = (checkOut.Date - checkIn.Date).Days;
//                 results.Add(new UnitWithPrice
//                 {
//                     UnitId = unit.UnitId,
//                     PropertyId = unit.PropertyId,
//                     UnitName = unit.UnitName,
//                     PropertyName = unit.PropertyName,
//                     City = unit.City,
//                     BasePrice = unit.BasePrice,
//                     TotalPrice = unit.BasePrice * numberOfNights,
//                     FullDocument = unit.FullDocument
//                 });
//             }
//         }
        
//         return results;
//     }
    
//     #endregion
    
//     #region === الوظائف المساعدة ===
    
//     /// <summary>
//     /// تحليل مستند الوحدة من حقول Redis
//     /// </summary>
//     private UnitSearchDocument? ParseUnitDocument(RedisResult[] fields)
//     {
//         try
//         {
//             var doc = new UnitSearchDocument();
            
//             for (int i = 0; i < fields.Length; i += 2)
//             {
//                 if (i + 1 >= fields.Length) break;
                
//                 var fieldName = fields[i].ToString();
//                 var fieldValue = fields[i + 1].ToString();
                
//                 switch (fieldName)
//                 {
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.UNIT_ID:
//                         if (Guid.TryParse(fieldValue, out var unitId))
//                             doc.UnitId = unitId;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.PROPERTY_ID:
//                         if (Guid.TryParse(fieldValue, out var propertyId))
//                             doc.PropertyId = propertyId;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.UNIT_NAME:
//                         doc.UnitName = fieldValue;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.PROPERTY_NAME:
//                         doc.PropertyName = fieldValue;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.CITY:
//                         doc.City = fieldValue;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.BASE_PRICE:
//                         if (decimal.TryParse(fieldValue, NumberStyles.Any, CultureInfo.InvariantCulture, out var price))
//                             doc.BasePrice = price;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.UnitFields.FULL_DOCUMENT:
//                         doc.FullDocument = fieldValue;
//                         break;
//                 }
//             }
            
//             return doc.UnitId != Guid.Empty ? doc : null;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogWarning(ex, "خطأ أثناء تحليل مستند الوحدة");
//             return null;
//         }
//     }
    
//     /// <summary>
//     /// تحليل فترة تسعير من حقول Redis
//     /// </summary>
//     private PricingPeriod? ParsePricingPeriod(RedisResult[] fields)
//     {
//         try
//         {
//             var period = new PricingPeriod();
            
//             for (int i = 0; i < fields.Length; i += 2)
//             {
//                 if (i + 1 >= fields.Length) break;
                
//                 var fieldName = fields[i].ToString();
//                 var fieldValue = fields[i + 1].ToString();
                
//                 switch (fieldName)
//                 {
//                     case var _ when fieldName == PeriodBasedSearchSchema.PricingPeriodFields.START_DATE_TS:
//                         if (long.TryParse(fieldValue, out var startTs))
//                             period.StartDate = DateTimeOffset.FromUnixTimeSeconds(startTs).DateTime;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.PricingPeriodFields.END_DATE_TS:
//                         if (long.TryParse(fieldValue, out var endTs))
//                             period.EndDate = DateTimeOffset.FromUnixTimeSeconds(endTs).DateTime;
//                         break;
                    
//                     case var _ when fieldName == PeriodBasedSearchSchema.PricingPeriodFields.PRICE:
//                         if (decimal.TryParse(fieldValue, NumberStyles.Any, CultureInfo.InvariantCulture, out var price))
//                             period.Price = price;
//                         break;
//                 }
//             }
            
//             return period;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogWarning(ex, "خطأ أثناء تحليل فترة التسعير");
//             return null;
//         }
//     }
    
//     /// <summary>
//     /// حساب السعر الإجمالي من فترات التسعير
//     /// </summary>
//     private decimal CalculateTotalPriceFromPeriods(
//         List<PricingPeriod> periods,
//         DateTime checkIn,
//         DateTime checkOut,
//         decimal basePrice)
//     {
//         decimal totalPrice = 0;
//         var currentDate = checkIn.Date;
        
//         while (currentDate < checkOut.Date)
//         {
//             var dailyPrice = basePrice;
            
//             var applicablePeriod = periods
//                 .Where(p => currentDate >= p.StartDate.Date && currentDate < p.EndDate.Date)
//                 .OrderByDescending(p => p.StartDate)
//                 .FirstOrDefault();
            
//             if (applicablePeriod != null)
//             {
//                 dailyPrice = applicablePeriod.Price;
//             }
            
//             totalPrice += dailyPrice;
//             currentDate = currentDate.AddDays(1);
//         }
        
//         return totalPrice;
//     }
    
//     /// <summary>
//     /// تطبيق الترتيب
//     /// </summary>
//     private List<UnitWithPrice> ApplySorting(List<UnitWithPrice> units, string? sortBy)
//     {
//         if (string.IsNullOrWhiteSpace(sortBy))
//             return units;
        
//         return sortBy.ToLowerInvariant() switch
//         {
//             "price_asc" => units.OrderBy(u => u.TotalPrice).ToList(),
//             "price_desc" => units.OrderByDescending(u => u.TotalPrice).ToList(),
//             "name" => units.OrderBy(u => u.UnitName).ToList(),
//             _ => units
//         };
//     }
    
//     #endregion
// }

// #region === الكلاسات المساعدة ===

// internal class UnitSearchDocument
// {
//     public Guid UnitId { get; set; }
//     public Guid PropertyId { get; set; }
//     public string UnitName { get; set; } = string.Empty;
//     public string PropertyName { get; set; } = string.Empty;
//     public string City { get; set; } = string.Empty;
//     public decimal BasePrice { get; set; }
//     public string? FullDocument { get; set; }
// }

// internal class UnitWithPrice
// {
//     public Guid UnitId { get; set; }
//     public Guid PropertyId { get; set; }
//     public string UnitName { get; set; } = string.Empty;
//     public string PropertyName { get; set; } = string.Empty;
//     public string City { get; set; } = string.Empty;
//     public decimal BasePrice { get; set; }
//     public decimal TotalPrice { get; set; }
//     public string? FullDocument { get; set; }
// }

// internal class PricingPeriod
// {
//     public DateTime StartDate { get; set; }
//     public DateTime EndDate { get; set; }
//     public decimal Price { get; set; }
// }

// #endregion
