using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Infrastructure.UnitOfWork;

namespace YemenBooking.Infrastructure.Extensions;

/// <summary>
/// تسجيل جميع Repositories في DI Container
/// Registration of all repositories in the Dependency Injection Container
/// </summary>
public static class RepositoryServiceRegistration
{
    public static IServiceCollection AddRepositories(this IServiceCollection services)
    {
        // Unit of Work
        services.AddScoped<IUnitOfWork, UnitOfWork.UnitOfWork>();
        
        // Generic Repository
        services.AddScoped(typeof(IRepository<>), typeof(BaseRepository<>));
        
        // User Management
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IUserWalletAccountRepository, UserWalletAccountRepository>();
        services.AddScoped<IRoleRepository, RoleRepository>();
        services.AddScoped<IUserRoleRepository, UserRoleRepository>();
        services.AddScoped<IUserSettingsRepository, UserSettingsRepository>();
        services.AddScoped<IStaffRepository, StaffRepository>();
        
        // Property & Unit
        services.AddScoped<IPropertyRepository, PropertyRepository>();
        services.AddScoped<IPropertyTypeRepository, PropertyTypeRepository>();
        services.AddScoped<IPropertyImageRepository, PropertyImageRepository>();
        services.AddScoped<IPropertyServiceRepository, PropertyServiceRepository>();
        services.AddScoped<IPropertyPolicyRepository, PropertyPolicyRepository>();
        services.AddScoped<IPropertyAmenityRepository, PropertyAmenityRepository>();
        services.AddScoped<IUnitRepository, UnitRepository>();
        services.AddScoped<IUnitTypeRepository, UnitTypeRepository>();
        services.AddScoped<IUnitFieldValueRepository, UnitFieldValueRepository>();
        services.AddScoped<IUnitTypeFieldRepository, UnitTypeFieldRepository>();
        
        // Booking & Payment
        services.AddScoped<IBookingRepository, BookingRepository>();
        services.AddScoped<IBookingServiceRepository, BookingServiceRepository>();
        services.AddScoped<IPaymentRepository, PaymentRepository>();
        
        // Pricing & Financial
        services.AddScoped<IDailyUnitScheduleRepository, DailyUnitScheduleRepository>();
        services.AddScoped<IFinancialTransactionRepository, FinancialTransactionRepository>();
        services.AddScoped<IChartOfAccountRepository, ChartOfAccountRepository>();
        
        // Review & Rating
        services.AddScoped<IReviewRepository, ReviewRepository>();
        services.AddScoped<IReviewImageRepository, ReviewImageRepository>();
        services.AddScoped<IReviewResponseRepository, ReviewResponseRepository>();
        
        // Amenity
        services.AddScoped<IAmenityRepository, AmenityRepository>();
        services.AddScoped<IPropertyTypeAmenityRepository, PropertyTypeAmenityRepository>();
        
        // Notification
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<INotificationChannelRepository, NotificationChannelRepository>();
        
        // Chat
        services.AddScoped<IChatConversationRepository, ChatConversationRepository>();
        services.AddScoped<IChatMessageRepository, ChatMessageRepository>();
        services.AddScoped<IMessageReactionRepository, MessageReactionRepository>();
        services.AddScoped<IChatAttachmentRepository, ChatAttachmentRepository>();
        services.AddScoped<IChatSettingsRepository, ChatSettingsRepository>();
        
        // Section & Content
        services.AddScoped<ISectionRepository, SectionRepository>();
        services.AddScoped<ISectionImageRepository, SectionImageRepository>();
        services.AddScoped<IPropertyInSectionImageRepository, PropertyInSectionImageRepository>();
        services.AddScoped<IUnitInSectionImageRepository, UnitInSectionImageRepository>();
        
        // Search & Filter
        services.AddScoped<ISearchLogRepository, SearchLogRepository>();
        services.AddScoped<ISearchFilterRepository, SearchFilterRepository>();
        services.AddScoped<IFieldGroupRepository, FieldGroupRepository>();
        services.AddScoped<IFieldGroupFieldRepository, FieldGroupFieldRepository>();
        
        // Favorites & Offers
        services.AddScoped<IFavoriteRepository, FavoriteRepository>();
        services.AddScoped<ISpecialOfferRepository, SpecialOfferRepository>();
        
        // Report & Legal
        services.AddScoped<IReportRepository, ReportRepository>();
        services.AddScoped<IPolicyRepository, PolicyRepository>();
        services.AddScoped<ILegalDocumentRepository, LegalDocumentRepository>();
        services.AddScoped<IFAQRepository, FAQRepository>();
        
        // Currency & App Version
        services.AddScoped<ICurrencyExchangeRepository, CurrencyExchangeRepository>();
        services.AddScoped<IAppVersionRepository, AppVersionRepository>();
        
        return services;
    }
}
