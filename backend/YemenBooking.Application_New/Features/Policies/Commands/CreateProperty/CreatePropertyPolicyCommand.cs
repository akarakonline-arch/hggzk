using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Policies.Commands.CreateProperty
{
    /// <summary>
    /// أمر لإنشاء سياسة جديدة للكيان
    /// Command to create a new property policy
    /// </summary>
    public class CreatePropertyPolicyCommand : IRequest<ResultDto<Guid>>
    {
        /// <summary>
        /// معرف الكيان
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// نوع السياسة
        /// </summary>
        public PolicyType Type { get; set; }

        /// <summary>
        /// الوصف
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// القواعد
        /// </summary>
        public string? Rules { get; set; }

        /// <summary>
        /// عدد أيام نافذة الإلغاء قبل تاريخ الوصول
        /// </summary>
        public int CancellationWindowDays { get; set; }

        /// <summary>
        /// يتطلب الدفع الكامل قبل التأكيد
        /// </summary>
        public bool RequireFullPaymentBeforeConfirmation { get; set; }

        /// <summary>
        /// الحد الأدنى لنسبة الدفع المقدمة
        /// </summary>
        public decimal MinimumDepositPercentage { get; set; }

        /// <summary>
        /// الحد الأدنى للساعات قبل تسجيل الوصول
        /// </summary>
        public int MinHoursBeforeCheckIn { get; set; }

        public bool? CancellationFreeCancel { get; set; }
        public bool? CancellationFullRefund { get; set; }
        public int? CancellationRefundPercentage { get; set; }
        public int? CancellationDaysBeforeCheckIn { get; set; }
        public int? CancellationHoursBeforeCheckIn { get; set; }
        public bool? CancellationNonRefundable { get; set; }
        public string? CancellationPenaltyAfterDeadline { get; set; }

        public bool? PaymentDepositRequired { get; set; }
        public bool? PaymentFullPaymentRequired { get; set; }
        public decimal? PaymentDepositPercentage { get; set; }
        public bool? PaymentAcceptCash { get; set; }
        public bool? PaymentAcceptCard { get; set; }
        public bool? PaymentPayAtProperty { get; set; }
        public bool? PaymentCashPreferred { get; set; }
        public string[]? PaymentAcceptedMethods { get; set; }

        public TimeOnly? CheckInTime { get; set; }
        public TimeOnly? CheckOutTime { get; set; }
        public TimeOnly? CheckInFrom { get; set; }
        public TimeOnly? CheckInUntil { get; set; }
        public bool? CheckInFlexible { get; set; }
        public bool? CheckInFlexibleCheckIn { get; set; }
        public bool? CheckInRequiresCoordination { get; set; }
        public bool? CheckInContactOwner { get; set; }
        public string? CheckInEarlyCheckInNote { get; set; }
        public string? CheckInLateCheckOutNote { get; set; }
        public string? CheckInLateCheckOutFee { get; set; }

        public bool? ChildrenAllowed { get; set; }
        public int? ChildrenFreeUnderAge { get; set; }
        public int? ChildrenHalfPriceUnderAge { get; set; }
        public int? ChildrenMaxChildrenPerRoom { get; set; }
        public int? ChildrenMaxChildren { get; set; }
        public string? ChildrenCribsNote { get; set; }
        public bool? ChildrenPlaygroundAvailable { get; set; }
        public bool? ChildrenKidsMenuAvailable { get; set; }

        public bool? PetsAllowed { get; set; }
        public string? PetsReason { get; set; }
        public decimal? PetsFeeAmount { get; set; }
        public string? PetsMaxWeight { get; set; }
        public bool? PetsRequiresApproval { get; set; }
        public bool? PetsNoFees { get; set; }
        public bool? PetsPetFriendly { get; set; }
        public bool? PetsOutdoorSpace { get; set; }
        public bool? PetsStrict { get; set; }

        public bool? ModificationAllowed { get; set; }
        public int? ModificationFreeModificationHours { get; set; }
        public string? ModificationFeesAfter { get; set; }
        public bool? ModificationFlexible { get; set; }
        public string? ModificationReason { get; set; }
    }
}