using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using Microsoft.Extensions.Options;
using YemenBooking.Infrastructure.Settings;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة البريد الإلكتروني باستخدام MailKit
    /// Email service implementation using MailKit
    /// </summary>
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;
        private readonly EmailSettings _settings;

        public EmailService(ILogger<EmailService> logger, IOptions<EmailSettings> options)
        {
            _logger = logger;
            _settings = options.Value;
        }

        /// <inheritdoc />
        public async Task<bool> SendEmailAsync(string to, string subject, string body, bool isHtml = true, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال بريد إلى: {To}، الموضوع: {Subject}", to, subject);
            try
            {
                // إنشاء رسالة MIME
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(
                    string.IsNullOrWhiteSpace(_settings.FromName) ? "YemenBooking" : _settings.FromName,
                    string.IsNullOrWhiteSpace(_settings.FromEmail) ? "noreply@example.com" : _settings.FromEmail
                ));
                message.To.Add(MailboxAddress.Parse(to));
                message.Subject = subject;

                // إنشاء محتوى الرسالة
                var bodyBuilder = new BodyBuilder();
                if (isHtml)
                {
                    bodyBuilder.HtmlBody = body;
                }
                else
                {
                    bodyBuilder.TextBody = body;
                }
                message.Body = bodyBuilder.ToMessageBody();

                // التحقق من وضع الحفظ المحلي
                if (_settings.UsePickupDirectory)
                {
                    var pickupPath = string.IsNullOrWhiteSpace(_settings.PickupDirectoryLocation) ? "Emails" : _settings.PickupDirectoryLocation;
                    Directory.CreateDirectory(pickupPath);
                    var filePath = Path.Combine(pickupPath, $"{Guid.NewGuid()}.eml");
                    await message.WriteToAsync(filePath, cancellationToken);
                    _logger.LogInformation("تم حفظ البريد في: {FilePath}", filePath);
                    return true;
                }

                // إرسال عبر SMTP باستخدام MailKit
                using var client = new MailKit.Net.Smtp.SmtpClient();
                
                // تحديد نوع الاتصال بناءً على المنفذ
                SecureSocketOptions secureSocketOptions;
                if (_settings.SmtpPort == 465)
                {
                    // Port 465 = SSL/TLS مباشر (Implicit TLS)
                    secureSocketOptions = SecureSocketOptions.SslOnConnect;
                }
                else if (_settings.SmtpPort == 587)
                {
                    // Port 587 = STARTTLS
                    secureSocketOptions = SecureSocketOptions.StartTls;
                }
                else
                {
                    // منافذ أخرى - استخدام Auto أو None حسب EnableSsl
                    secureSocketOptions = _settings.EnableSsl ? SecureSocketOptions.Auto : SecureSocketOptions.None;
                }

                _logger.LogDebug("الاتصال بـ SMTP: {Host}:{Port} مع {SecureOption}", 
                    _settings.SmtpHost, _settings.SmtpPort, secureSocketOptions);

                await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, secureSocketOptions, cancellationToken);

                // المصادقة إذا كانت مطلوبة
                if (!string.IsNullOrWhiteSpace(_settings.Username))
                {
                    await client.AuthenticateAsync(_settings.Username, _settings.Password, cancellationToken);
                }

                await client.SendAsync(message, cancellationToken);
                await client.DisconnectAsync(true, cancellationToken);

                _logger.LogInformation("تم إرسال البريد بنجاح إلى: {To}", to);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إرسال البريد إلى {To}: {Message}", to, ex.Message);
                return false;
            }
        }

        /// <inheritdoc />
        public Task<bool> SendWelcomeEmailAsync(string email, string userName, CancellationToken cancellationToken = default)
        {
            var subject = "مرحباً بك في YemenBooking";
            var body = $"<p>مرحباً {userName},</p><p>شكراً لانضمامك إلينا!</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendBookingConfirmationEmailAsync(string email, string customerName, object bookingDetails, CancellationToken cancellationToken = default)
        {
            var subject = "تأكيد الحجز";
            var details = JsonSerializer.Serialize(bookingDetails, new JsonSerializerOptions { WriteIndented = true });
            var body = $"<p>عزيزي {customerName},</p><p>تم تأكيد حجزك بنجاح:</p><pre>{details}</pre>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendBookingCancellationEmailAsync(string email, string customerName, object bookingDetails, string reason, CancellationToken cancellationToken = default)
        {
            var subject = "إلغاء الحجز";
            var details = JsonSerializer.Serialize(bookingDetails, new JsonSerializerOptions { WriteIndented = true });
            var body = $"<p>عزيزي {customerName},</p><p>تم إلغاء حجزك:</p><pre>{details}</pre><p>السبب: {reason}</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendPasswordResetEmailAsync(string email, string userName, string resetToken, CancellationToken cancellationToken = default)
        {
            var subject = "إعادة تعيين كلمة المرور";
            var body = $"<p>مرحباً {userName},</p><p>رمز إعادة التعيين الخاص بك هو: <strong>{resetToken}</strong></p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendOwnerNotificationEmailAsync(string email, string ownerName, string subject, string message, CancellationToken cancellationToken = default)
        {
            var body = $"<p>مرحباً {ownerName},</p><p>{message}</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public async Task<bool> SendReportEmailAsync(string email, string reportName, byte[] reportData, string fileName, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال تقرير عبر البريد إلى: {Email} للتقرير: {ReportName}", email, reportName);
            try
            {
                // إنشاء رسالة MIME مع مرفق
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(_settings.FromName, _settings.FromEmail));
                message.To.Add(MailboxAddress.Parse(email));
                message.Subject = $"تقرير: {reportName}";

                // إنشاء محتوى الرسالة مع المرفق
                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = "<p>يرجى الاطلاع على التقرير المرفق.</p>"
                };
                bodyBuilder.Attachments.Add(fileName, reportData);
                message.Body = bodyBuilder.ToMessageBody();

                // إرسال عبر SMTP باستخدام MailKit
                using var client = new MailKit.Net.Smtp.SmtpClient();
                
                // تحديد نوع الاتصال
                SecureSocketOptions secureSocketOptions = _settings.SmtpPort == 465 
                    ? SecureSocketOptions.SslOnConnect 
                    : (_settings.SmtpPort == 587 ? SecureSocketOptions.StartTls : SecureSocketOptions.Auto);

                await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, secureSocketOptions, cancellationToken);

                if (!string.IsNullOrWhiteSpace(_settings.Username))
                {
                    await client.AuthenticateAsync(_settings.Username, _settings.Password, cancellationToken);
                }

                await client.SendAsync(message, cancellationToken);
                await client.DisconnectAsync(true, cancellationToken);

                _logger.LogInformation("تم إرسال التقرير بنجاح إلى: {Email}", email);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إرسال التقرير عبر البريد");
                return false;
            }
        }

        /// <inheritdoc />
        public async Task<bool> SendSupportEmailAsync(
            string userName,
            string userEmail,
            string subject,
            string message,
            string? deviceInfo = null,
            CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال رسالة دعم من: {UserEmail}، الموضوع: {Subject}", userEmail, subject);
            try
            {
                var bodyBuilder = new System.Text.StringBuilder();
                bodyBuilder.AppendLine("<div dir='rtl' style='font-family: Arial, sans-serif;'>");
                bodyBuilder.AppendLine($"<h2>رسالة دعم جديدة</h2>");
                bodyBuilder.AppendLine($"<p><strong>من المستخدم:</strong> {userName}</p>");
                bodyBuilder.AppendLine($"<p><strong>البريد الإلكتروني:</strong> {userEmail}</p>");
                bodyBuilder.AppendLine($"<p><strong>الموضوع:</strong> {subject}</p>");
                bodyBuilder.AppendLine($"<hr/>");
                bodyBuilder.AppendLine($"<h3>الرسالة:</h3>");
                bodyBuilder.AppendLine($"<p>{message.Replace("\n", "<br/>")}</p>");
                
                if (!string.IsNullOrWhiteSpace(deviceInfo))
                {
                    bodyBuilder.AppendLine($"<hr/>");
                    bodyBuilder.AppendLine($"<h3>معلومات الجهاز:</h3>");
                    bodyBuilder.AppendLine($"<pre>{deviceInfo}</pre>");
                }
                
                bodyBuilder.AppendLine("</div>");

                return await SendEmailAsync(
                    "support@rezmate.com",
                    $"رسالة دعم: {subject}",
                    bodyBuilder.ToString(),
                    true,
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إرسال رسالة الدعم من {UserEmail}: {Message}", userEmail, ex.Message);
                return false;
            }
        }
    }
}
