using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة إعادة تعيين كلمة المرور
    /// Password reset service implementation
    /// </summary>
    public class PasswordResetService : IPasswordResetService
    {
        private readonly IUserRepository _userRepository;
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IEmailService _emailService;
        private readonly ILogger<PasswordResetService> _logger;

        public PasswordResetService(
            IUserRepository userRepository,
            IPasswordHashingService passwordHashingService,
            IEmailService emailService,
            ILogger<PasswordResetService> logger)
        {
            _userRepository = userRepository;
            _passwordHashingService = passwordHashingService;
            _emailService = emailService;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task<bool> SendPasswordResetEmailAsync(string email, string resetToken)
        {
            try
            {
                var user = await _userRepository.GetUserByEmailAsync(email.Trim(), CancellationToken.None);
                var userName = user?.Name ?? "عميلنا العزيز";

                _logger.LogInformation("إرسال بريد استعادة كلمة المرور إلى {Email}", email);
                return await _emailService.SendPasswordResetEmailAsync(email, userName, resetToken, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل إرسال بريد استعادة كلمة المرور إلى {Email}", email);
                return false;
            }
        }

        /// <inheritdoc />
        public async Task<string> GenerateResetTokenAsync(Guid userId)
        {
            var user = await _userRepository.GetUserByIdAsync(userId, CancellationToken.None);
            if (user == null)
            {
                _logger.LogWarning("GenerateResetTokenAsync: لم يتم العثور على المستخدم {UserId}", userId);
                return string.Empty;
            }

            var token = Guid.NewGuid().ToString("N");
            user.PasswordResetToken = token;
            user.PasswordResetTokenExpires = DateTime.UtcNow.AddHours(2);

            await _userRepository.UpdateUserAsync(user, CancellationToken.None);
            _logger.LogInformation("تم إنشاء رمز إعادة تعيين كلمة المرور للمستخدم {UserId}", userId);

            return token;
        }

        /// <inheritdoc />
        public async Task<bool> ValidateResetTokenAsync(Guid userId, string resetToken)
        {
            var user = await _userRepository.GetUserByIdAsync(userId, CancellationToken.None);
            if (user == null) return false;
            if (string.IsNullOrWhiteSpace(user.PasswordResetToken)) return false;
            if (!string.Equals(user.PasswordResetToken, resetToken, StringComparison.Ordinal)) return false;

            if (user.PasswordResetTokenExpires.HasValue && user.PasswordResetTokenExpires.Value < DateTime.UtcNow)
            {
                _logger.LogWarning("رمز إعادة تعيين كلمة المرور منتهي الصلاحية للمستخدم {UserId}", userId);
                return false;
            }

            return true;
        }

        /// <inheritdoc />
        public async Task<bool> IsTokenExpiredAsync(string resetToken)
        {
            var users = await _userRepository.GetAllAsync(CancellationToken.None);
            var user = users?.FirstOrDefault(u => u.PasswordResetToken == resetToken);
            if (user == null) return true;

            if (!user.PasswordResetTokenExpires.HasValue) return false;
            return user.PasswordResetTokenExpires.Value < DateTime.UtcNow;
        }

        /// <inheritdoc />
        public async Task<bool> DeleteResetTokenAsync(string resetToken)
        {
            var users = await _userRepository.GetAllAsync(CancellationToken.None);
            var user = users?.FirstOrDefault(u => u.PasswordResetToken == resetToken);
            if (user == null) return false;

            user.PasswordResetToken = null;
            user.PasswordResetTokenExpires = null;
            await _userRepository.UpdateUserAsync(user, CancellationToken.None);

            _logger.LogInformation("تم حذف رمز إعادة تعيين كلمة المرور للمستخدم {UserId}", user.Id);
            return true;
        }

        /// <inheritdoc />
        public async Task<bool> ResetPasswordAsync(Guid userId, string newPassword)
        {
            var user = await _userRepository.GetUserByIdAsync(userId, CancellationToken.None);
            if (user == null)
            {
                _logger.LogWarning("ResetPasswordAsync: لم يتم العثور على المستخدم {UserId}", userId);
                return false;
            }

            var hashed = await _passwordHashingService.HashPasswordAsync(newPassword, CancellationToken.None);
            user.Password = hashed;
            user.PasswordResetToken = null;
            user.PasswordResetTokenExpires = null;
            user.UpdatedAt = DateTime.UtcNow;

            await _userRepository.UpdateUserAsync(user, CancellationToken.None);
            _logger.LogInformation("تمت إعادة تعيين كلمة المرور للمستخدم {UserId}", userId);
            return true;
        }
    }
}