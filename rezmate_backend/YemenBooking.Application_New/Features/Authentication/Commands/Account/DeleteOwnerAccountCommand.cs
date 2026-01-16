using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.Account
{
    public class DeleteOwnerAccountCommand : IRequest<ResultDto<DeleteAccountResponse>>
    {
        public string Password { get; set; } = string.Empty;

        public string? Reason { get; set; }
    }
}
