namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان سياسة الكيان
/// Property Policy entity
/// </summary>
[Display(Name = "كيان سياسة الكيان")]
public class PropertyPolicy : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// نوع السياسة (إلغاء، تعديل، دخول، أطفال، حيوانات)
    /// Policy type (Cancellation, Modification, CheckIn, Children, Pets)
    /// </summary>
    [Display(Name = "نوع السياسة")]
    public PolicyType Type { get; set; }
    
    /// <summary>
    /// عدد أيام نافذة الإلغاء قبل تاريخ الوصول
    /// Number of days before check-in to allow cancellation
    /// </summary>
    [Display(Name = "عدد أيام نافذة الإلغاء قبل تاريخ الوصول")]
    public int CancellationWindowDays { get; set; }
    
    /// <summary>
    /// يتطلب الدفع الكامل قبل التأكيد
    /// Requires full payment before confirmation
    /// </summary>
    [Display(Name = "يتطلب الدفع الكامل قبل التأكيد")]
    public bool RequireFullPaymentBeforeConfirmation { get; set; }
    
    /// <summary>
    /// الحد الأدنى لنسبة الدفع المقدمة (كنسبة مئوية)
    /// Minimum deposit percentage (as percentage)
    /// </summary>
    [Display(Name = "الحد الأدنى لنسبة الدفع المقدمة")]
    public decimal MinimumDepositPercentage { get; set; }
    
    /// <summary>
    /// الحد الأدنى للساعات قبل تسجيل الوصول لتعديل الحجز
    /// Minimum hours before check-in to allow modification
    /// </summary>
    [Display(Name = "الحد الأدنى للساعات قبل تسجيل الوصول لتعديل الحجز")]
    public int MinHoursBeforeCheckIn { get; set; }
    
    /// <summary>
    /// وصف السياسة
    /// Policy description
    /// </summary>
    [Display(Name = "وصف السياسة")]
    public string Description { get; set; }
    
    /// <summary>
    /// قواعد السياسة (JSON)
    /// Policy rules (JSON)
    /// </summary>
    [Display(Name = "قواعد السياسة")]
    public string? Rules { get; set; }

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
    
    /// <summary>
    /// الكيان المرتبط بالسياسة
    /// Property associated with the policy
    /// </summary>
    [Display(Name = "الكيان المرتبط بالسياسة")]
    public virtual Property Property { get; set; }
}