using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Security.Claims;
using System.Text.Json;
using System.Threading.Tasks;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Api.Middlewares
{
    public class UserAccountStatusMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IServiceScopeFactory _serviceScopeFactory;

        public UserAccountStatusMiddleware(RequestDelegate next, IServiceScopeFactory serviceScopeFactory)
        {
            _next = next;
            _serviceScopeFactory = serviceScopeFactory;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.User?.Identity?.IsAuthenticated == true)
            {
                var userId = GetUserIdFromContext(context);
                if (userId.HasValue)
                {
                    using var scope = _serviceScopeFactory.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();

                    var status = await dbContext.Users
                        .IgnoreQueryFilters()
                        .Where(u => u.Id == userId.Value)
                        .Select(u => new { u.IsDeleted, u.IsActive })
                        .FirstOrDefaultAsync();

                    if (status == null || status.IsDeleted || !status.IsActive)
                    {
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        context.Response.ContentType = "application/json";
                        var payload = JsonSerializer.Serialize(new { success = false, message = "Account disabled" });
                        await context.Response.WriteAsync(payload);
                        return;
                    }
                }
            }

            await _next(context);
        }

        private static Guid? GetUserIdFromContext(HttpContext context)
        {
            var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)
                              ?? context.User.FindFirst("id")
                              ?? context.User.FindFirst("sub")
                              ?? context.User.FindFirst("userId")
                              ?? context.User.FindFirst("user_id");

            if (userIdClaim == null || string.IsNullOrWhiteSpace(userIdClaim.Value))
                return null;

            return Guid.TryParse(userIdClaim.Value, out var userId) ? userId : null;
        }
    }

    public static class UserAccountStatusMiddlewareExtensions
    {
        public static IApplicationBuilder UseUserAccountStatus(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<UserAccountStatusMiddleware>();
        }
    }
}
