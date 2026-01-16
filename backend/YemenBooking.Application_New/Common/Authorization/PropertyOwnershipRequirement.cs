using Microsoft.AspNetCore.Authorization;

namespace YemenBooking.Application.Common.Authorization
{
    /// <summary>
    /// متطلب التفويض للتحقق من ملكية العقار
    /// Authorization requirement to verify property ownership
    /// </summary>
    public class PropertyOwnershipRequirement : IAuthorizationRequirement
    {
        /// <summary>
        /// السماح للمسؤول بالوصول
        /// Allow admin access
        /// </summary>
        public bool AllowAdmin { get; set; } = true;

        /// <summary>
        /// السماح للموظفين بالوصول
        /// Allow staff access
        /// </summary>
        public bool AllowStaff { get; set; } = false;

        public PropertyOwnershipRequirement(bool allowAdmin = true, bool allowStaff = false)
        {
            AllowAdmin = allowAdmin;
            AllowStaff = allowStaff;
        }
    }
}
