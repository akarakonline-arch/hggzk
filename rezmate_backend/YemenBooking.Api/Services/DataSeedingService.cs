using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Seeds;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Seeds;
using Microsoft.Extensions.Logging;
using PaymentStatus = YemenBooking.Core.Enums.PaymentStatus;
using System.Text.Json;
using YemenBooking.Application.Features.Policies;

namespace YemenBooking.Api.Services
{
    public class DataSeedingService
    {
        private readonly global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext _context;
        private readonly ILogger<DataSeedingService> _logger;

        public DataSeedingService(global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext context, ILogger<DataSeedingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SeedAsync()
        {
            // Initialize currencies
            if (!await _context.Currencies.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة العملات...");
                _context.Currencies.AddRange(new CurrencySeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة العملات بنجاح");
            }

            // Initialize cities
            if (!await _context.Cities.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة المدن...");
                _context.Cities.AddRange(new CitySeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة المدن بنجاح");
            }

            // Roles (Admin, Owner, Staff, Client)
            if (!await _context.Roles.AnyAsync())
            {
                _context.Roles.AddRange(
                    new Role { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Name = "Admin", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Name = "Owner", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Staff", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Name = "Client", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true }
                );
                await _context.SaveChangesAsync();
            }

            // Users
            if (!await _context.Users.AnyAsync())
            {
                _context.Users.AddRange(new UserSeeder().SeedData());
                await _context.SaveChangesAsync();
            }

            // Migrate Favorites from Users.FavoritesJson to Favorites table (one-time)
            if (!await _context.Favorites.AnyAsync())
            {
                try
                {
                    var allUsers = await _context.Users.AsNoTracking().ToListAsync();
                    var propsList = await _context.Properties.AsNoTracking().Select(p => p.Id).ToListAsync();
                    var props = propsList.ToHashSet();
                    var toAdd = new List<Favorite>();
                    foreach (var u in allUsers)
                    {
                        List<Guid>? favIds = null;
                        try { favIds = System.Text.Json.JsonSerializer.Deserialize<List<Guid>>(u.FavoritesJson ?? "[]"); }
                        catch { favIds = new List<Guid>(); }
                        if (favIds == null || favIds.Count == 0) continue;
                        foreach (var pid in favIds.Distinct())
                        {
                            if (!props.Contains(pid)) continue;
                            toAdd.Add(new Favorite
                            {
                                Id = Guid.NewGuid(),
                                UserId = u.Id,
                                PropertyId = pid,
                                DateAdded = DateTime.UtcNow,
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow,
                                IsActive = true,
                                IsDeleted = false
                            });
                        }
                    }
                    if (toAdd.Count > 0)
                    {
                        await _context.Favorites.AddRangeAsync(toAdd);
                        await _context.SaveChangesAsync();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Favorites migration skipped due to error");
                }
            }

            // UserRoles: Ensure roles for users (Admin, Owner, and assign Client for regular users) incrementally
            {
                var now = DateTime.UtcNow;
                var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "admin@example.com");
                var ownerUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "owner@example.com");
                var adminRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Admin");
                var ownerRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Owner");
                var clientRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Client");

                var rolesToAdd = new List<UserRole>();

                // Ensure Admin has Admin role
                if (adminUser != null && adminRole != null)
                {
                    var exists = await _context.UserRoles.AnyAsync(ur => ur.UserId == adminUser.Id && ur.RoleId == adminRole.Id);
                    if (!exists)
                    {
                        rolesToAdd.Add(new UserRole
                        {
                            Id = Guid.Parse("CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"),
                            UserId = adminUser.Id,
                            RoleId = adminRole.Id,
                            AssignedAt = now,
                            CreatedAt = now,
                            UpdatedAt = now,
                            IsActive = true
                        });
                    }
                }

                // Ensure Owner has Owner role
                if (ownerUser != null && ownerRole != null)
                {
                    var exists = await _context.UserRoles.AnyAsync(ur => ur.UserId == ownerUser.Id && ur.RoleId == ownerRole.Id);
                    if (!exists)
                    {
                        rolesToAdd.Add(new UserRole
                        {
                            Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"),
                            UserId = ownerUser.Id,
                            RoleId = ownerRole.Id,
                            AssignedAt = now,
                            CreatedAt = now,
                            UpdatedAt = now,
                            IsActive = true
                        });
                    }
                }

                // Ensure all regular users have Client role
                if (clientRole != null)
                {
                    var regularUserIds = new[]
                    {
                        Guid.Parse("C0000000-0000-0000-0000-000000000001"),
                        Guid.Parse("C0000000-0000-0000-0000-000000000002"),
                        Guid.Parse("C0000000-0000-0000-0000-000000000003"),
                        Guid.Parse("C0000000-0000-0000-0000-000000000004"),
                        Guid.Parse("C0000000-0000-0000-0000-000000000005")
                    };

                    var users = await _context.Users.Where(u => regularUserIds.Contains(u.Id)).Select(u => u.Id).ToListAsync();
                    foreach (var uid in users)
                    {
                        var hasAnyRole = await _context.UserRoles.AnyAsync(ur => ur.UserId == uid);
                        var hasClientRole = await _context.UserRoles.AnyAsync(ur => ur.UserId == uid && ur.RoleId == clientRole.Id);
                        if (!hasClientRole)
                        {
                            rolesToAdd.Add(new UserRole
                            {
                                Id = Guid.NewGuid(),
                                UserId = uid,
                                RoleId = clientRole.Id,
                                AssignedAt = now,
                                CreatedAt = now,
                                UpdatedAt = now,
                                IsActive = true
                            });
                        }
                    }
                }

                if (rolesToAdd.Any())
                {
                    _context.UserRoles.AddRange(rolesToAdd);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("✅ تم إسناد {Count} دور مستخدم مفقود بشكل تراكمي (Admin/Owner/Client)", rolesToAdd.Count);
                }
            }

            // Property types
            if (!await _context.PropertyTypes.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة أنواع العقارات...");
                _context.PropertyTypes.AddRange(new PropertyTypeSeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة أنواع العقارات بنجاح");
            }

            // Unit types: استخدام السيدر الجديد الدقيق
            if (!await _context.UnitTypes.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة أنواع الوحدات...");
                _context.UnitTypes.AddRange(new UnitTypeSeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة أنواع الوحدات بنجاح");
            }

            // Properties: استخدام السيدر الجديد الدقيق بدون تعديلات
            var existingPropertyIds = await _context.Properties.Select(p => p.Id).ToListAsync();
            var seededProperties = new PropertySeeder().SeedData().ToList();
            var newProperties = seededProperties.Where(p => !existingPropertyIds.Contains(p.Id)).ToList();

            if (newProperties.Any())
            {
                _logger.LogInformation($"🔄 بدء إضافة {newProperties.Count} عقار جديد...");
                _context.Properties.AddRange(newProperties);
                await _context.SaveChangesAsync();
                _logger.LogInformation($"✅ تم إضافة {newProperties.Count} عقار بنجاح");
            }

            // Property Policies: seed policies for properties
            if (!await _context.PropertyPolicies.AnyAsync())
            {
                var propertyPolicySeeder = new PropertyPolicySeeder();
                var policies = propertyPolicySeeder.SeedData().ToList();
                if (policies.Any())
                {
                    _context.PropertyPolicies.AddRange(policies);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"✅ تم بذر {policies.Count} سياسة عقار");
                }
            }

            // Property Services: seed services for properties
            if (!await _context.PropertyServices.AnyAsync())
            {
                var propertiesForServices = await _context.Properties.AsNoTracking().ToListAsync();
                if (propertiesForServices.Any())
                {
                    var propertyServiceSeeder = new PropertyServiceSeeder(propertiesForServices);
                    var services = propertyServiceSeeder.SeedData().ToList();
                    if (services.Any())
                    {
                        _context.PropertyServices.AddRange(services);
                        await _context.SaveChangesAsync();
                    }
                }
            }

            // Units: استخدام السيدر الجديد الدقيق بدون تعديلات
            var existingUnitIds = await _context.Units.Select(u => u.Id).ToListAsync();
            var seededUnits = new UnitSeeder().SeedData().ToList();
            var newUnits = seededUnits.Where(u => !existingUnitIds.Contains(u.Id)).ToList();

            if (newUnits.Any())
            {
                _logger.LogInformation($"🔄 بدء إضافة {newUnits.Count} وحدة جديدة...");
                _context.Units.AddRange(newUnits);
                await _context.SaveChangesAsync();
                _logger.LogInformation($"✅ تم إضافة {newUnits.Count} وحدة بنجاح");
            }

            // ========================================================================
            // إنشاء الجداول اليومية (DailyUnitSchedule) - الإتاحة والتسعير
            // ========================================================================
            if (!await _context.DailyUnitSchedules.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء توليد الجداول اليومية للإتاحة والتسعير...");
                
                var units = await _context.Units.AsNoTracking().ToListAsync();
                var properties = await _context.Properties.AsNoTracking().ToListAsync();
                
                if (units.Any() && properties.Any())
                {
                    var scheduleSeeder = new DailyUnitScheduleSeeder();
                    var schedules = scheduleSeeder.GenerateSchedules(units, properties, monthsAhead: 6);
                    
                    _logger.LogInformation($"📊 تم توليد {schedules.Count} جدول يومي لـ {units.Count} وحدة");
                    
                    // إضافة الجداول بشكل تدريجي لتجنب الأخطاء
                    var batchSize = 1000;
                    for (int i = 0; i < schedules.Count; i += batchSize)
                    {
                        var batch = schedules.Skip(i).Take(batchSize).ToList();
                        _context.DailyUnitSchedules.AddRange(batch);
                        await _context.SaveChangesAsync();
                        _logger.LogInformation($"✅ تمت إضافة دفعة {(i / batchSize) + 1} من الجداول");
                    }
                    
                    _logger.LogInformation("✅ اكتمل توليد الجداول اليومية بنجاح");
                }
            }

            // Property images: assign valid PropertyId and optional UnitId
            if (!await _context.PropertyImages.AnyAsync())
            {
                var properties = await _context.Properties.AsNoTracking().ToListAsync();
                var units = await _context.Units.AsNoTracking().ToListAsync();
                var seededImages = new PropertyImageSeeder().SeedData().ToList();
                var rnd = new Random();
                foreach (var img in seededImages)
                {
                    img.PropertyId = properties[rnd.Next(properties.Count)].Id;
                    if (units.Any()) img.UnitId = units[rnd.Next(units.Count)].Id;
                }
                _context.PropertyImages.AddRange(seededImages);
                await _context.SaveChangesAsync();
            }

            // ========================================================================
            // Unit Type Fields: الحقول الديناميكية لأنواع الوحدات
            // ========================================================================
            if (!await _context.UnitTypeFields.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة الحقول الديناميكية...");
                _context.UnitTypeFields.AddRange(new UnitTypeFieldSeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة الحقول الديناميكية بنجاح");
            }

            // ========================================================================
            // Unit Field Values: قيم الحقول الديناميكية للوحدات
            // ========================================================================
            if (!await _context.UnitFieldValues.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء توليد قيم الحقول الديناميكية...");
                
                var unitsForFields = await _context.Units.AsNoTracking().ToListAsync();
                var unitTypeFields = await _context.UnitTypeFields.AsNoTracking().ToListAsync();
                
                if (unitsForFields.Any() && unitTypeFields.Any())
                {
                    var fieldValues = UnitFieldValueSeeder.GenerateValuesForUnits(
                        unitsForFields, 
                        unitTypeFields);
                    
                    _logger.LogInformation($"📊 تم توليد {fieldValues.Count} قيمة حقل ديناميكي");
                    
                    _context.UnitFieldValues.AddRange(fieldValues);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("✅ اكتمل توليد قيم الحقول الديناميكية بنجاح");
                }
            }

            // Amenities
            if (!await _context.Amenities.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة المرافق...");
                _context.Amenities.AddRange(new AmenitySeeder().SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة المرافق بنجاح");
            }

            // Property type amenities (ربط أنواع العقار بالمرافق)
            if (!await _context.PropertyTypeAmenities.AnyAsync())
            {
                _logger.LogInformation("🔄 بدء تهيئة روابط أنواع العقار بالمرافق...");
                var ptaSeeder = new PropertyTypeAmenitySeeder();
                _context.PropertyTypeAmenities.AddRange(ptaSeeder.SeedData());
                await _context.SaveChangesAsync();
                _logger.LogInformation("✅ تم تهيئة روابط أنواع العقار بالمرافق بنجاح");
            }

            // ========================================================================
            // إنشاء/استكمال الحجوزات اليدوية الدقيقة بشكل تراكمي
            // ========================================================================
            {
                var existingBookingIds = await _context.Bookings.Select(b => b.Id).ToListAsync();
                var seededBookings = new BookingSeeder().SeedData().ToList();
                var newBookings = seededBookings.Where(b => !existingBookingIds.Contains(b.Id)).ToList();

                if (newBookings.Any())
                {
                    _logger.LogInformation("🔄 بدء إضافة {Count} حجز جديد (تراكمي)...", newBookings.Count);
                    _context.Bookings.AddRange(newBookings);
                    await _context.SaveChangesAsync();

                    _logger.LogInformation("✅ تم إضافة {Count} حجز جديد", newBookings.Count);
                    _logger.LogInformation("📊 تفاصيل الحجوزات المضافة:");
                    _logger.LogInformation("  - حجوزات مكتملة: {Count}", newBookings.Count(b => b.Status == YemenBooking.Core.Enums.BookingStatus.Completed));
                    _logger.LogInformation("  - حجوزات قيد التنفيذ: {Count}", newBookings.Count(b => b.Status == YemenBooking.Core.Enums.BookingStatus.CheckedIn));
                    _logger.LogInformation("  - حجوزات ملغاة: {Count}", newBookings.Count(b => b.Status == YemenBooking.Core.Enums.BookingStatus.Cancelled));
                    _logger.LogInformation("  - حجوزات مؤكدة: {Count}", newBookings.Count(b => b.Status == YemenBooking.Core.Enums.BookingStatus.Confirmed));
                }
                else
                {
                    _logger.LogInformation("ℹ️ لا توجد حجوزات جديدة لإضافتها (جميع المعرفات موجودة)");
                }
            }

            // --------------------------------------------------------------------
            // حفظ لقطة سياسات العقار لكل حجز يفتقد PolicySnapshot (تراكمي وآمن)
            // --------------------------------------------------------------------
            try
            {
                var pendingBookings = await _context.Bookings
                    .Include(b => b.Unit)
                    .Where(b => string.IsNullOrWhiteSpace(b.PolicySnapshot))
                    .ToListAsync();

                if (pendingBookings.Any())
                {
                    _logger.LogInformation("🔄 بدء حفظ لقطات السياسات لعدد {Count} حجز يفتقد PolicySnapshot...", pendingBookings.Count);

                    var propertyIds = pendingBookings
                        .Select(b => b.Unit?.PropertyId)
                        .Where(pid => pid.HasValue)
                        .Select(pid => pid!.Value)
                        .Distinct()
                        .ToList();

                    var policiesByProperty = await _context.PropertyPolicies
                        .Where(pp => propertyIds.Contains(pp.PropertyId))
                        .AsNoTracking()
                        .GroupBy(pp => pp.PropertyId)
                        .ToDictionaryAsync(g => g.Key, g => g.ToList());

                    var jsonOptions = new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        WriteIndented = false
                    };

                    var nowUtc = DateTime.UtcNow;
                    int updated = 0;
                    foreach (var b in pendingBookings)
                    {
                        var propId = b.Unit?.PropertyId;
                        if (propId == null) continue;

                        policiesByProperty.TryGetValue(propId.Value, out var propPolicies);
                        var snapshot = new
                        {
                            propertyId = propId.Value,
                            capturedAt = nowUtc,
                            policies = (propPolicies ?? new List<YemenBooking.Core.Entities.PropertyPolicy>()).Select(p => new
                            {
                                type = p.Type.ToString(),
                                cancellationWindowDays = p.CancellationWindowDays,
                                requireFullPaymentBeforeConfirmation = p.RequireFullPaymentBeforeConfirmation,
                                minimumDepositPercentage = p.MinimumDepositPercentage,
                                minHoursBeforeCheckIn = p.MinHoursBeforeCheckIn,
                                description = p.Description,
                                rules = PolicyRulesMapper.BuildRulesJson(p)
                            }).ToList()
                        };

                        b.PolicySnapshot = JsonSerializer.Serialize(snapshot, jsonOptions);
                        b.PolicySnapshotAt = nowUtc;
                        updated++;
                    }

                    if (updated > 0)
                    {
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("✅ تم حفظ لقطات السياسات لعدد {Updated} حجز", updated);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ تعذّر حفظ لقطات السياسات للحجوزات. سيتم تخطي هذه الخطوة دون إيقاف البذر.");
            }

            // Booking Services: link some property services to existing bookings
            if (!await _context.BookingServices.AnyAsync())
            {
                var bookingsForServices = await _context.Bookings.AsNoTracking().ToListAsync();
                var servicesForBookings = await _context.PropertyServices.AsNoTracking().ToListAsync();
                var unitsForBookings = await _context.Units.AsNoTracking().ToListAsync();
                if (bookingsForServices.Any() && servicesForBookings.Any() && unitsForBookings.Any())
                {
                    var bookingServiceSeeder = new BookingServiceSeeder(bookingsForServices, servicesForBookings, unitsForBookings);
                    var bookingServicesToAdd = bookingServiceSeeder.SeedData().ToList();
                    if (bookingServicesToAdd.Any())
                    {
                        _context.BookingServices.AddRange(bookingServicesToAdd);
                        await _context.SaveChangesAsync();
                    }
                }
            }

            // Verification: ensure bookings link to services from the same property's services
            try
            {
                var bookingsInfo = await _context.Bookings.AsNoTracking()
                    .Select(b => new { b.Id, b.Status })
                    .ToListAsync();
                var nonCancelledIds = bookingsInfo
                    .Where(b => b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled)
                    .Select(b => b.Id)
                    .ToHashSet();

                var joinList = await (
                    from bs in _context.BookingServices.AsNoTracking()
                    join ps in _context.PropertyServices.AsNoTracking() on bs.ServiceId equals ps.Id
                    join b in _context.Bookings.AsNoTracking() on bs.BookingId equals b.Id
                    join u in _context.Units.AsNoTracking() on b.UnitId equals u.Id
                    select new { b.Id, BookingPropId = u.PropertyId, ServicePropId = ps.PropertyId }
                ).ToListAsync();

                var servicesByBooking = joinList
                    .GroupBy(x => x.Id)
                    .ToDictionary(g => g.Key, g => g.ToList());

                int totalNonCancelled = nonCancelledIds.Count;
                int matchedNonCancelled = servicesByBooking
                    .Where(kvp => nonCancelledIds.Contains(kvp.Key))
                    .Count(kvp => kvp.Value.Any(v => v.BookingPropId == v.ServicePropId));
                int mismatches = joinList.Count(x => x.BookingPropId != x.ServicePropId);
                int totalBs = await _context.BookingServices.CountAsync();

                double percent = totalNonCancelled == 0 ? 0 : (matchedNonCancelled * 100.0) / totalNonCancelled;
                _logger.LogInformation(
                    "BookingServices verification => Non-cancelled bookings: {TotalNonCancelled}, with >=1 matching service: {Matched} ({Percent:F1}%), Total BookingServices: {BSCount}, Cross-property links (should be 0): {Mismatches}",
                    totalNonCancelled,
                    matchedNonCancelled,
                    percent,
                    totalBs,
                    mismatches
                );
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "BookingServices verification failed");
            }

            // Reviews: seed reviews using ReviewSeeder (incremental)
            {
                _logger.LogInformation("🔄 بدء تهيئة المراجعات والتقييمات...");
                
                var existingReviewIds = await _context.Reviews.Select(r => r.Id).ToListAsync();
                var seededReviews = new ReviewSeeder().SeedData().ToList();
                var newReviews = seededReviews.Where(r => !existingReviewIds.Contains(r.Id)).ToList();

                if (newReviews.Any())
                {
                    _logger.LogInformation($"🔄 بدء إضافة {newReviews.Count} مراجعة جديدة...");
                    _context.Reviews.AddRange(newReviews);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"✅ تم إضافة {newReviews.Count} مراجعة بنجاح");
                    
                    // تحديث متوسط التقييمات للعقارات بعد إضافة المراجعات
                    var propertyIds = newReviews.Select(r => r.PropertyId).Distinct().ToList();
                    foreach (var propertyId in propertyIds)
                    {
                        var reviews = await _context.Reviews
                            .Where(r => r.PropertyId == propertyId && !r.IsDisabled)
                            .AsNoTracking()
                            .ToListAsync();
                        
                        if (reviews.Any())
                        {
                            var avgRating = reviews.Average(r => r.AverageRating);
                            var property = await _context.Properties.FirstOrDefaultAsync(p => p.Id == propertyId);
                            if (property != null)
                            {
                                property.AverageRating = avgRating;
                                _context.Properties.Update(property);
                            }
                        }
                    }
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"✅ تم تحديث متوسط التقييمات لـ {propertyIds.Count} عقار");
                }
                else
                {
                    _logger.LogInformation("ℹ️ لا توجد مراجعات جديدة لإضافتها (جميع المعرفات موجودة)");
                }
            }

            // Reports: seed diverse reports in Arabic with relationships
            if (!await _context.Reports.AnyAsync())
            {
                var users = await _context.Users.AsNoTracking().ToListAsync();
                var properties = await _context.Properties.AsNoTracking().ToListAsync();
                var rnd = new Random();
                var reasons = new[]
                {
                    "محتوى مسيء",
                    "سلوك غير لائق",
                    "مشكلة في الحجز",
                    "خطأ تقني",
                    "طلب إلغاء غير منطقي",
                    "معلومات خاطئة",
                    "انتهاك للقواعد",
                    "شكاوى أخرى"
                };
                var descriptions = new[]
                {
                    "تم العثور على محتوى مسيء في وصف الوحدة.",
                    "سلوك المستخدم كان غير لائق خلال فترة الإقامة.",
                    "واجهت مشكلة في عملية الحجز لم يتم حلها.",
                    "تعذر الوصول إلى تفاصيل الحجز بسبب خطأ تقني.",
                    "طلب الإلغاء لم يتم قبوله من قبل الإدارة.",
                    "المعلومات المعروضة لا تتطابق مع الواقع.",
                    "تم انتهاك قواعد السكن بوجود ضيوف إضافيين.",
                    "بلاغ عام حول مشاكل أخرى تتعلق بالخدمة."
                };
                var statuses = new[] { "Open", "InReview", "Resolved", "Dismissed" };
                var reportsToAdd = users.SelectMany(u =>
                {
                    int count = rnd.Next(1, 7);
                    return Enumerable.Range(1, count).Select(_ => new Report
                    {
                        Id = Guid.NewGuid(),
                        ReporterUserId = u.Id,
                        ReportedUserId = rnd.Next(2) == 0 ? users[rnd.Next(users.Count)].Id : (Guid?)null,
                        ReportedPropertyId = properties.Any() && rnd.Next(2) == 1
                            ? properties[rnd.Next(properties.Count)].Id : (Guid?)null,
                        Reason = reasons[rnd.Next(reasons.Length)],
                        Description = descriptions[rnd.Next(descriptions.Length)],
                        Status = statuses[rnd.Next(statuses.Length)],
                        CreatedAt = DateTime.UtcNow.AddDays(-rnd.Next(0, 30)),
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        ActionNote = string.Empty,
                        AdminId = null
                    });
                }).ToList();
                _context.Reports.AddRange(reportsToAdd);
                await _context.SaveChangesAsync();
            }

            // ========================================================================
            // إنشاء/استكمال المدفوعات اليدوية الدقيقة بشكل تراكمي
            // ========================================================================
            {
                var existingPaymentIds = await _context.Payments.Select(p => p.Id).ToListAsync();
                var seededPayments = new PaymentSeeder().SeedData().ToList();
                var newPayments = seededPayments.Where(p => !existingPaymentIds.Contains(p.Id)).ToList();

                if (newPayments.Any())
                {
                    _logger.LogInformation("🔄 بدء إضافة {Count} دفعة جديدة (تراكمية)...", newPayments.Count);
                    _context.Payments.AddRange(newPayments);
                    await _context.SaveChangesAsync();

                    _logger.LogInformation("✅ تم إضافة {Count} دفعة جديدة", newPayments.Count);
                    _logger.LogInformation("📊 تفاصيل المدفوعات المضافة:");
                    _logger.LogInformation("  - دفعات ناجحة: {Count}", newPayments.Count(p => p.Status == PaymentStatus.Successful));
                    _logger.LogInformation("  - مردودات كاملة: {Count}", newPayments.Count(p => p.Status == PaymentStatus.Refunded));
                    _logger.LogInformation("  - مردودات جزئية: {Count}", newPayments.Count(p => p.Status == PaymentStatus.PartiallyRefunded));
                    _logger.LogInformation("  - دفعات فاشلة: {Count}", newPayments.Count(p => p.Status == PaymentStatus.Failed));
                    _logger.LogInformation("  - دفعات معلقة: {Count}", newPayments.Count(p => p.Status == PaymentStatus.Pending));
                }
                else
                {
                    _logger.LogInformation("ℹ️ لا توجد مدفوعات جديدة لإضافتها (جميع المعرفات موجودة)");
                }
            }

            // Seed Arabic notifications for admin@example.com
            if (!await _context.Notifications.AnyAsync())
            {
                var admin = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == "admin@example.com");
                if (admin != null)
                {
                    var now = DateTime.UtcNow;
                    var notifications = new List<Notification>
                    {
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "BOOKING_CREATED",
                            Title = "حجز جديد",
                            Message = "تم إنشاء حجز جديد برقم HBK-2025-001",
                            TitleAr = "حجز جديد",
                            MessageAr = "تم إنشاء حجز جديد برقم HBK-2025-001",
                            Priority = "MEDIUM",
                            Data = "{\"bookingNumber\":\"HBK-2025-001\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-30),
                            UpdatedAt = now.AddMinutes(-30)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "BOOKING_CANCELLED",
                            Title = "إلغاء حجز",
                            Message = "تم إلغاء الحجز رقم HBK-2025-002",
                            TitleAr = "إلغاء حجز",
                            MessageAr = "تم إلغاء الحجز رقم HBK-2025-002",
                            Priority = "LOW",
                            Data = "{\"bookingNumber\":\"HBK-2025-002\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddHours(-2),
                            UpdatedAt = now.AddHours(-2)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PAYMENT_UPDATE",
                            Title = "تحديث الدفع",
                            Message = "تم اعتماد دفعة بمبلغ 120,000 ريال يمني",
                            TitleAr = "تحديث الدفع",
                            MessageAr = "تم اعتماد دفعة بمبلغ 120,000 ريال يمني",
                            Priority = "HIGH",
                            Data = "{\"amount\":\"120000 YER\",\"status\":\"Approved\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-10),
                            UpdatedAt = now.AddMinutes(-10)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PAYMENT_FAILED",
                            Title = "فشل عملية الدفع",
                            Message = "تعذر معالجة الدفعة الأخيرة، يرجى المحاولة لاحقاً",
                            TitleAr = "فشل عملية الدفع",
                            MessageAr = "تعذر معالجة الدفعة الأخيرة، يرجى المحاولة لاحقاً",
                            Priority = "URGENT",
                            RequiresAction = true,
                            Data = "{\"reason\":\"CardDeclined\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-5),
                            UpdatedAt = now.AddMinutes(-5)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PROMOTION_OFFER",
                            Title = "عرض ترويجي جديد",
                            Message = "خصم 20% على الحجوزات لمدة محدودة",
                            TitleAr = "عرض ترويجي جديد",
                            MessageAr = "خصم 20% على الحجوزات لمدة محدودة",
                            Priority = "LOW",
                            Data = "{\"discount\":20,\"currency\":\"YER\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddDays(-1),
                            UpdatedAt = now.AddDays(-1)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "SYSTEM_UPDATE",
                            Title = "تحديث النظام",
                            Message = "تم تحديث النظام لتحسين الأداء والاستقرار",
                            TitleAr = "تحديث النظام",
                            MessageAr = "تم تحديث النظام لتحسين الأداء والاستقرار",
                            Priority = "MEDIUM",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddDays(-2),
                            UpdatedAt = now.AddDays(-2)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "SECURITY_ALERT",
                            Title = "تنبيه أمني",
                            Message = "تم اكتشاف محاولة تسجيل دخول غير معتادة وتم حظرها",
                            TitleAr = "تنبيه أمني",
                            MessageAr = "تم اكتشاف محاولة تسجيل دخول غير معتادة وتم حظرها",
                            Priority = "HIGH",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddHours(-6),
                            UpdatedAt = now.AddHours(-6)
                        }
                    };

                    _context.Notifications.AddRange(notifications);
                    await _context.SaveChangesAsync();
                }
            }

            // Chart of Accounts (دليل الحسابات المحاسبية)
            // بذر الحسابات الأساسية للنظام المحاسبي
            try
            {
                await ChartOfAccountSeeder.SeedAsync(_context, _logger);
                _logger.LogInformation("✅ تم بذر دليل الحسابات المحاسبية بنجاح");

                // ✅ مهم جداً: إنشاء الحسابات الشخصية للمستخدمين
                // يجب أن يتم هذا بعد إنشاء دليل الحسابات وقبل العمليات المالية
                await UserAccountsSeeder.SeedAsync(_context, _logger);
                _logger.LogInformation("✅ تم إنشاء الحسابات المحاسبية الشخصية بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ فشل في بذر الحسابات المحاسبية");
            }

            // Financial Transactions (العمليات المالية)
            // ✅ تحسين: بذر العمليات المالية لجميع الحجوزات والدفعات
            if (!await _context.FinancialTransactions.AnyAsync())
            {
                try
                {
                    _logger.LogInformation("🔄 بدء بذر العمليات المالية الشاملة...");

                    // جلب جميع البيانات المطلوبة - لا نحدد بـ 50 فقط
                    var bookings = await _context.Bookings
                        .Include(b => b.Unit)
                        .OrderByDescending(b => b.CreatedAt)
                        .ToListAsync(); // ✅ جلب جميع الحجوزات

                    var payments = await _context.Payments
                        .OrderByDescending(p => p.PaymentDate)
                        .ToListAsync();

                    var allUsers = await _context.Users.ToListAsync();
                    var allProperties = await _context.Properties.ToListAsync();
                    var allUnits = await _context.Units.ToListAsync();

                    // ✅ جلب الحسابات مع تضمين الحسابات الشخصية الجديدة
                    var accounts = await _context.ChartOfAccounts
                        .Include(a => a.User)
                        .Include(a => a.Property)
                        .ToListAsync();

                    _logger.LogInformation($"📊 البيانات المتاحة: {bookings.Count} حجز، {payments.Count} دفعة، {accounts.Count} حساب محاسبي");

                    if (bookings.Any() && accounts.Any())
                    {
                        // TODO: إنشاء القيود المحاسبية تلقائياً في المستقبل
                        // سيتم استخدام FinancialTransactionSeeder لاحقاً
                        _logger.LogInformation("ℹ️ القيود المحاسبية سيتم إنشاؤها في المرحلة القادمة");
                        
                        /*
                        // إنشاء السيدر مع البيانات المطلوبة
                        var transactionSeeder = new FinancialTransactionSeeder();
                        var transactions = transactionSeeder.SeedData();

                        if (transactions.Any())
                        {
                            // إضافة جميع العمليات المالية
                            _context.FinancialTransactions.AddRange(transactions);
                            await _context.SaveChangesAsync();
                            _logger.LogInformation($"✅ تم بذر {transactions.Count()} عملية مالية بنجاح لـ {bookings.Count} حجز");
                        }
                        */
                    }
                    else
                    {
                        _logger.LogInformation("ℹ️ تخطي بذر العمليات المالية - لا توجد حجوزات أو حسابات محاسبية");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ فشل في بذر العمليات المالية");
                }
            }

            // تم تعطيل SeedAvailabilityAndPricingAsync مؤقتاً بسبب استبدال UnitAvailability و PricingRule بـ DailyUnitSchedule
            // await SeedAvailabilityAndPricingAsync();
            
            await SeedPropertyPoliciesAdvancedAsync();
        }

        /*
        // تم تعطيل هذه الدالة مؤقتاً - تحتاج إعادة كتابة لاستخدام DailyUnitSchedule
        private async Task SeedAvailabilityAndPricingAsync()
        {
            var today = DateTime.UtcNow.Date;
            var units = await _context.Units.AsNoTracking().ToListAsync();
            if (!units.Any()) return;
            var bookings = await _context.Bookings.AsNoTracking()
                .Where(b => b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled)
                .ToListAsync();
            var bookingsByUnit = bookings
                .GroupBy(b => b.UnitId)
                .ToDictionary(g => g.Key, g => g.ToList());

            // ... rest of old code with UnitAvailability and PricingRule ...
        }
        */

        private async Task SeedPropertyPoliciesAdvancedAsync()
        {
            var properties = await _context.Properties
                .AsNoTracking()
                .Select(p => new { p.Id, p.StarRating, p.Currency })
                .ToListAsync();
            if (properties.Count == 0) return;

            var existing = await _context.PropertyPolicies
                .AsNoTracking()
                .Select(pp => new { pp.PropertyId, pp.Type })
                .ToListAsync();
            var existingSet = new HashSet<string>(existing.Select(e => $"{e.PropertyId}:{e.Type}"));

            var refundsByProperty = (await (
                from pay in _context.Payments.AsNoTracking()
                where pay.Status == YemenBooking.Core.Enums.PaymentStatus.Refunded
                   || pay.Status == YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded
                join b in _context.Bookings.AsNoTracking() on pay.BookingId equals b.Id
                join u in _context.Units.AsNoTracking() on b.UnitId equals u.Id
                group pay by u.PropertyId into g
                select new { PropertyId = g.Key, Count = g.Count() }
            ).ToListAsync()).ToDictionary(x => x.PropertyId, x => x.Count);

            var toAdd = new List<PropertyPolicy>();
            var now = DateTime.UtcNow;
            var types = (YemenBooking.Core.Enums.PolicyType[])Enum.GetValues(typeof(YemenBooking.Core.Enums.PolicyType));

            foreach (var prop in properties)
            {
                var refunds = refundsByProperty.ContainsKey(prop.Id) ? refundsByProperty[prop.Id] : 0;
                var strict = ((prop.Currency ?? "YER").ToUpper() == "USD" || prop.StarRating >= 5) && refunds == 0;
                var flexible = refunds > 0;

                foreach (var t in types)
                {
                    if (existingSet.Contains($"{prop.Id}:{t}")) continue;

                    var pp = new PropertyPolicy
                    {
                        Id = Guid.NewGuid(),
                        PropertyId = prop.Id,
                        Type = t,
                        CancellationWindowDays = 0,
                        RequireFullPaymentBeforeConfirmation = false,
                        MinimumDepositPercentage = 0,
                        MinHoursBeforeCheckIn = 0,
                        Description = "",
                        Rules = "{}",
                        CreatedAt = now,
                        UpdatedAt = now,
                        IsActive = true,
                        IsDeleted = false
                    };

                    if (t == YemenBooking.Core.Enums.PolicyType.Payment)
                    {
                        if (strict)
                        {
                            pp.RequireFullPaymentBeforeConfirmation = true;
                            pp.MinimumDepositPercentage = 100;
                            pp.Description = "يتطلب الدفع الكامل عند التأكيد";
                            pp.Rules = "{\"fullPaymentRequired\":true,\"acceptedMethods\":[\"CreditCard\",\"Paypal\",\"Cash\"]}";
                        }
                        else if (flexible)
                        {
                            pp.RequireFullPaymentBeforeConfirmation = false;
                            pp.MinimumDepositPercentage = 10;
                            pp.Description = "مقدمة 10%، الباقي عند الوصول";
                            pp.Rules = "{\"depositPercentage\":10,\"acceptedMethods\":[\"Cash\",\"JwaliWallet\",\"CreditCard\"]}";
                        }
                        else
                        {
                            pp.RequireFullPaymentBeforeConfirmation = false;
                            pp.MinimumDepositPercentage = 30;
                            pp.Description = "مقدمة 30% عند الحجز";
                            pp.Rules = "{\"depositPercentage\":30,\"acceptedMethods\":[\"Cash\",\"CreditCard\"]}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Cancellation)
                    {
                        if (strict)
                        {
                            pp.CancellationWindowDays = 7;
                            pp.Description = "استرداد 50% إذا تم الإلغاء قبل 7 أيام";
                            pp.Rules = "{\"freeCancel\":false,\"refundPercentage\":50,\"daysBeforeCheckIn\":7}";
                        }
                        else if (flexible)
                        {
                            pp.CancellationWindowDays = 1;
                            pp.Description = "إلغاء مجاني حتى 24 ساعة قبل الوصول";
                            pp.Rules = "{\"freeCancel\":true,\"hoursBeforeCheckIn\":24,\"fullRefund\":true}";
                        }
                        else
                        {
                            pp.CancellationWindowDays = 5;
                            pp.Description = "إلغاء مجاني قبل 5 أيام";
                            pp.Rules = "{\"freeCancel\":true,\"daysBeforeCheckIn\":5}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.CheckIn)
                    {
                        if (strict)
                        {
                            pp.MinHoursBeforeCheckIn = 48;
                            pp.Description = "تسجيل الوصول من 3 عصراً، المغادرة حتى 11 صباحاً";
                            pp.Rules = "{\"checkInTime\":\"15:00\",\"checkOutTime\":\"11:00\"}";
                        }
                        else if (flexible)
                        {
                            pp.MinHoursBeforeCheckIn = 12;
                            pp.Description = "تسجيل وصول مرن من 12 ظهراً";
                            pp.Rules = "{\"checkInFrom\":\"12:00\",\"checkOutTime\":\"12:00\",\"flexible\":true}";
                        }
                        else
                        {
                            pp.MinHoursBeforeCheckIn = 24;
                            pp.Description = "تسجيل الوصول من 2 ظهراً، المغادرة حتى 12 ظهراً";
                            pp.Rules = "{\"checkInTime\":\"14:00\",\"checkOutTime\":\"12:00\"}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Children)
                    {
                        if (strict)
                        {
                            pp.Description = "الأطفال أقل من 3 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":3}";
                        }
                        else if (flexible)
                        {
                            pp.Description = "مرحب بالأطفال حتى 8 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":8}";
                        }
                        else
                        {
                            pp.Description = "الأطفال أقل من 6 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":6}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Pets)
                    {
                        if (strict)
                        {
                            pp.Description = "لا يُسمح بالحيوانات الأليفة";
                            pp.Rules = "{\"petsAllowed\":false}";
                        }
                        else if (flexible)
                        {
                            pp.Description = "يُسمح بالحيوانات الأليفة بدون رسوم";
                            pp.Rules = "{\"petsAllowed\":true,\"noFees\":true}";
                        }
                        else
                        {
                            pp.Description = "يُسمح بالحيوانات الأليفة مقابل رسوم";
                            pp.Rules = "{\"petsAllowed\":true,\"fee\":5000}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Modification)
                    {
                        if (strict)
                        {
                            pp.MinHoursBeforeCheckIn = 0;
                            pp.Description = "لا يمكن تعديل الحجز بعد التأكيد";
                            pp.Rules = "{\"modificationAllowed\":false}";
                        }
                        else if (flexible)
                        {
                            pp.MinHoursBeforeCheckIn = 12;
                            pp.Description = "تعديل مجاني حتى 12 ساعة قبل الوصول";
                            pp.Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":12}";
                        }
                        else
                        {
                            pp.MinHoursBeforeCheckIn = 24;
                            pp.Description = "تعديل مجاني حتى 24 ساعة قبل الوصول";
                            pp.Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":24}";
                        }
                    }

                    toAdd.Add(pp);
                }
            }

            if (toAdd.Count > 0)
            {
                await _context.PropertyPolicies.AddRangeAsync(toAdd);
                await _context.SaveChangesAsync();
            }
        }
    }
}