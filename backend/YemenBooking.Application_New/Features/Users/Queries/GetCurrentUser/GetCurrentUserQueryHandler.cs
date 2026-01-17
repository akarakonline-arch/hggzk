using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Queries.GetCurrentUser
{
    /// <summary>
    /// معالج استعلام الحصول على بيانات المستخدم الحالي
    /// Query handler for GetCurrentUserQuery
    /// </summary>
    public class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, ResultDto<UserDto>>
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly IUserWalletAccountRepository _userWalletAccountRepository;
        private readonly IMapper _mapper;
        private readonly ILogger<GetCurrentUserQueryHandler> _logger;

        public GetCurrentUserQueryHandler(
            ICurrentUserService currentUserService,
            IUserWalletAccountRepository userWalletAccountRepository,
            IMapper mapper,
            ILogger<GetCurrentUserQueryHandler> logger)
        {
            _currentUserService = currentUserService;
            _userWalletAccountRepository = userWalletAccountRepository;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<ResultDto<UserDto>> Handle(GetCurrentUserQuery request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("جاري معالجة استعلام بيانات المستخدم الحالي: {UserId}", _currentUserService.UserId);

                if (_currentUserService.UserId == Guid.Empty)
                {
                    _logger.LogWarning("طلب غير مصادق عليه لبيانات المستخدم الحالي");
                    return ResultDto<UserDto>.Failure("يجب تسجيل الدخول للوصول إلى بيانات المستخدم");
                }

                var user = await _currentUserService.GetCurrentUserAsync(cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("تعذر العثور على المستخدم: {UserId}", _currentUserService.UserId);
                    return ResultDto<UserDto>.Failure($"المستخدم بالمعرف {_currentUserService.UserId} غير موجود");
                }

                var userDto = _mapper.Map<UserDto>(user);
                // enrich with claims-based context
                userDto.AccountRole = _currentUserService.AccountRole;
                if (_currentUserService.PropertyId.HasValue)
                {
                    userDto.PropertyId = _currentUserService.PropertyId;
                    userDto.PropertyName = _currentUserService.PropertyName;
                    userDto.PropertyCurrency = _currentUserService.PropertyCurrency;
                }

                var isOwner = string.Equals(userDto.AccountRole, "Owner", StringComparison.OrdinalIgnoreCase)
                              || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Owner", StringComparison.OrdinalIgnoreCase)) ?? false);
                if (isOwner)
                {
                    var accounts = await _userWalletAccountRepository.GetByUserIdAsync(userDto.Id, cancellationToken);
                    userDto.WalletAccounts = accounts
                        .Select(a => new UserWalletAccountDto
                        {
                            Id = a.Id,
                            WalletType = a.WalletType,
                            AccountNumber = a.AccountNumber,
                            AccountName = a.AccountName,
                            IsDefault = a.IsDefault,
                        })
                        .ToList();
                }

                _logger.LogInformation("تم جلب بيانات المستخدم الحالي بنجاح: {UserId}", userDto.Id);
                return ResultDto<UserDto>.Ok(userDto, "تم جلب بيانات المستخدم بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة استعلام بيانات المستخدم الحالي");
                return ResultDto<UserDto>.Failure("حدث خطأ أثناء جلب بيانات المستخدم");
            }
        }
    }
} 