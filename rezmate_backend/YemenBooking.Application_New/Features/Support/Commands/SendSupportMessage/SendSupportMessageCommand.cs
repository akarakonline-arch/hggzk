using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Support.Commands.SendSupportMessage;

public class SendSupportMessageCommand : IRequest<ResultDto<SendSupportMessageResponse>>
{
    public string UserName { get; set; } = string.Empty;
    public string UserEmail { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? DeviceType { get; set; }
    public string? OperatingSystem { get; set; }
    public string? OsVersion { get; set; }
    public string? AppVersion { get; set; }
}

public class SendSupportMessageResponse
{
    public bool Success { get; set; }
    public string ReferenceNumber { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
