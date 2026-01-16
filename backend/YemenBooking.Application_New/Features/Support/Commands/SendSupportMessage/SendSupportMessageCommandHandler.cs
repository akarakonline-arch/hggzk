using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;

namespace YemenBooking.Application.Features.Support.Commands.SendSupportMessage;

public class SendSupportMessageCommandHandler : IRequestHandler<SendSupportMessageCommand, ResultDto<SendSupportMessageResponse>>
{
    private readonly ILogger<SendSupportMessageCommandHandler> _logger;
    private readonly IEmailService _emailService;

    public SendSupportMessageCommandHandler(
        ILogger<SendSupportMessageCommandHandler> logger,
        IEmailService emailService)
    {
        _logger = logger;
        _emailService = emailService;
    }

    public async Task<ResultDto<SendSupportMessageResponse>> Handle(
        SendSupportMessageCommand request,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation(
                "استلام رسالة دعم جديدة من: {UserEmail}، الموضوع: {Subject}",
                request.UserEmail,
                request.Subject);

            string? deviceInfo = null;
            if (!string.IsNullOrWhiteSpace(request.DeviceType) ||
                !string.IsNullOrWhiteSpace(request.OperatingSystem))
            {
                var deviceData = new
                {
                    DeviceType = request.DeviceType,
                    OperatingSystem = request.OperatingSystem,
                    OsVersion = request.OsVersion,
                    AppVersion = request.AppVersion
                };
                deviceInfo = JsonSerializer.Serialize(deviceData, new JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });
            }

            var emailSent = await _emailService.SendSupportEmailAsync(
                request.UserName,
                request.UserEmail,
                request.Subject,
                request.Message,
                deviceInfo,
                cancellationToken);

            if (!emailSent)
            {
                _logger.LogError("فشل إرسال رسالة الدعم من: {UserEmail}", request.UserEmail);
                return ResultDto<SendSupportMessageResponse>.Failure(
                    "فشل إرسال رسالة الدعم. يرجى المحاولة مرة أخرى.");
            }

            var referenceNumber = Guid.NewGuid().ToString().Substring(0, 8).ToUpper();
            _logger.LogInformation(
                "تم إرسال رسالة الدعم بنجاح. الرقم المرجعي: {ReferenceNumber}",
                referenceNumber);

            return ResultDto<SendSupportMessageResponse>.Ok(
                new SendSupportMessageResponse
                {
                    Success = true,
                    ReferenceNumber = referenceNumber,
                    Message = "تم إرسال رسالتك بنجاح. سنتواصل معك قريباً."
                },
                "تم إرسال رسالة الدعم بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء معالجة رسالة الدعم من: {UserEmail}", request.UserEmail);
            return ResultDto<SendSupportMessageResponse>.Failure(
                "حدث خطأ أثناء إرسال رسالة الدعم. يرجى المحاولة مرة أخرى.");
        }
    }
}
