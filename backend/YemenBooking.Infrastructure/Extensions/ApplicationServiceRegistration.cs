using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.Services;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Authorization;
using YemenBooking.Infrastructure.Postgres.Indexing;
using YemenBooking.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Extensions;

/// <summary>
/// تسجيل جميع Application Services في DI Container
/// Registration of all application services in the Dependency Injection Container
/// </summary>
public static class ApplicationServiceRegistration
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Authentication & Authorization
        services.AddScoped<IAuthenticationService, AuthenticationService>();
        services.AddScoped<IPasswordHashingService, PasswordHashingService>();
        services.AddScoped<IPasswordResetService, PasswordResetService>();
        services.AddScoped<ISocialAuthService, SocialAuthService>();
        services.AddScoped<IEmailVerificationService, EmailVerificationService>();
        
        // User Services
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        
        // Communication
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<ISmsService, SmsService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<INotificationChannelService, NotificationChannelService>();
        
        // Payment & Financial
        services.AddScoped<IPaymentGatewayService, PaymentGatewayService>();
        services.AddScoped<IDailyUnitScheduleService, DailyUnitScheduleService>();
        services.AddScoped<IFinancialAccountingService, FinancialAccountingService>();
        
        // Currency & Location
        services.AddScoped<ICurrencyExchangeService, CurrencyExchangeService>();
        services.AddScoped<ICurrencyEnsureService, CurrencyEnsureService>();
        services.AddScoped<ICurrencySettingsService, CurrencySettingsService>();
        services.AddScoped<IGeolocationService, GeolocationService>();
        services.AddScoped<ICitySettingsService, CitySettingsService>();
        
        // Search & Filter
        services.AddScoped<ISearchService, SearchService>();
        // ملاحظة: IUnitSearchEngine و IUnitIndexingService يتم تسجيلهم في Program.cs
        // حسب نوع المحرك المستخدم (Redis أو PostgreSQL)
        
        // Availability & Booking
        services.AddScoped<IAvailabilityService, AvailabilityService>();
        
        // Analytics & Dashboard
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IAnalyticsTrackerService, AnalyticsTrackerService>();
        services.AddScoped<ISentimentAnalysisService, SentimentAnalysisService>();
        
        // Reporting & Export
        services.AddScoped<IReportingService, ReportingService>();
        services.AddScoped<IExportService, ExportService>();
        
        // File & Media
        services.AddScoped<IFileStorageService, FileStorageService>();
        services.AddScoped<IFileUploadService, FileUploadService>();
        services.AddScoped<IImageProcessingService, ImageProcessingService>();
        services.AddScoped<IMediaMetadataService, MediaMetadataService>();
        services.AddScoped<IMediaThumbnailService, MediaThumbnailService>();
        
        // Firebase
        services.AddSingleton<IFirebaseService, FirebaseService>();
        
        // Recommendation
        services.AddScoped<IRecommendationService, RecommendationService>();
        
        // Validation & System
        services.AddScoped<IValidationService, ValidationService>();
        services.AddScoped<ISystemSettingsService, SystemSettingsService>();
        
        // Audit
        services.AddScoped<IAuditService, AuditService>();
        
        // Helper
        services.AddSingleton<IUrlHelper, UrlHelper>();

    // Authorization helpers (used by MediatR handlers)
    services.AddScoped<PropertyAuthorizationHelper>();
        
        // Background Services
        services.AddSingleton<IEventPublisher, EventPublisherService>();
        services.AddHostedService<ScheduledNotificationsDispatcher>();
        
        return services;
    }
}
