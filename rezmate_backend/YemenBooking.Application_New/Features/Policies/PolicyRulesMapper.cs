using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Helpers;

namespace YemenBooking.Application.Features.Policies;

public static class PolicyRulesMapper
{
    public static Dictionary<string, object> BuildRulesDictionary(PropertyPolicy policy)
    {
        if (policy == null) throw new ArgumentNullException(nameof(policy));

        if (!HasAnyTypedRules(policy))
        {
            return JsonHelper.SafeDeserializeDictionary(policy.Rules);
        }

        var rules = new Dictionary<string, object>();

        switch (policy.Type)
        {
            case PolicyType.Cancellation:
                AddIfHasValue(rules, "freeCancel", policy.CancellationFreeCancel);
                AddIfHasValue(rules, "fullRefund", policy.CancellationFullRefund);
                AddIfHasValue(rules, "refundPercentage", policy.CancellationRefundPercentage);
                AddIfHasValue(rules, "daysBeforeCheckIn", policy.CancellationDaysBeforeCheckIn);
                AddIfHasValue(rules, "hoursBeforeCheckIn", policy.CancellationHoursBeforeCheckIn);
                AddIfHasValue(rules, "nonRefundable", policy.CancellationNonRefundable);
                AddIfHasValue(rules, "penaltyAfterDeadline", policy.CancellationPenaltyAfterDeadline);
                AddIfHasValue(rules, "penaltyAfter", policy.CancellationPenaltyAfterDeadline);
                break;

            case PolicyType.Payment:
                AddIfHasValue(rules, "depositRequired", policy.PaymentDepositRequired);
                AddIfHasValue(rules, "fullPaymentRequired", policy.PaymentFullPaymentRequired);
                AddIfHasValue(rules, "depositPercentage", policy.PaymentDepositPercentage);
                AddIfHasValue(rules, "acceptCash", policy.PaymentAcceptCash);
                AddIfHasValue(rules, "acceptCard", policy.PaymentAcceptCard);
                AddIfHasValue(rules, "payAtProperty", policy.PaymentPayAtProperty);
                AddIfHasValue(rules, "cashPreferred", policy.PaymentCashPreferred);
                if (policy.PaymentAcceptedMethods != null && policy.PaymentAcceptedMethods.Length > 0)
                    rules["acceptedMethods"] = policy.PaymentAcceptedMethods;
                break;

            case PolicyType.CheckIn:
                AddIfHasValue(rules, "checkInTime", ToTimeString(policy.CheckInTime));
                AddIfHasValue(rules, "checkOutTime", ToTimeString(policy.CheckOutTime));
                AddIfHasValue(rules, "checkInFrom", ToTimeString(policy.CheckInFrom));
                AddIfHasValue(rules, "checkInUntil", ToTimeString(policy.CheckInUntil));
                AddIfHasValue(rules, "flexible", policy.CheckInFlexible);
                AddIfHasValue(rules, "flexibleCheckIn", policy.CheckInFlexibleCheckIn);
                AddIfHasValue(rules, "requiresCoordination", policy.CheckInRequiresCoordination);
                AddIfHasValue(rules, "contactOwner", policy.CheckInContactOwner);
                AddIfHasValue(rules, "earlyCheckIn", policy.CheckInEarlyCheckInNote);
                AddIfHasValue(rules, "lateCheckOut", policy.CheckInLateCheckOutNote);
                AddIfHasValue(rules, "lateCheckOutFee", policy.CheckInLateCheckOutFee);
                break;

            case PolicyType.Children:
                AddIfHasValue(rules, "childrenAllowed", policy.ChildrenAllowed);
                AddIfHasValue(rules, "freeUnder", policy.ChildrenFreeUnderAge);
                AddIfHasValue(rules, "halfPriceUnder", policy.ChildrenHalfPriceUnderAge);
                AddIfHasValue(rules, "maxChildrenPerRoom", policy.ChildrenMaxChildrenPerRoom);
                AddIfHasValue(rules, "maxChildren", policy.ChildrenMaxChildren);
                AddIfHasValue(rules, "cribs", policy.ChildrenCribsNote);
                AddIfHasValue(rules, "playground", policy.ChildrenPlaygroundAvailable);
                AddIfHasValue(rules, "kidsMenu", policy.ChildrenKidsMenuAvailable);
                break;

            case PolicyType.Pets:
                AddIfHasValue(rules, "petsAllowed", policy.PetsAllowed);
                AddIfHasValue(rules, "reason", policy.PetsReason);
                AddIfHasValue(rules, "feeAmount", policy.PetsFeeAmount);
                AddIfHasValue(rules, "fee", policy.PetsFeeAmount);
                AddIfHasValue(rules, "maxWeight", policy.PetsMaxWeight);
                AddIfHasValue(rules, "requiresApproval", policy.PetsRequiresApproval);
                AddIfHasValue(rules, "noFees", policy.PetsNoFees);
                AddIfHasValue(rules, "petFriendly", policy.PetsPetFriendly);
                AddIfHasValue(rules, "outdoorSpace", policy.PetsOutdoorSpace);
                AddIfHasValue(rules, "strict", policy.PetsStrict);
                break;

            case PolicyType.Modification:
                AddIfHasValue(rules, "modificationAllowed", policy.ModificationAllowed);
                AddIfHasValue(rules, "freeModificationHours", policy.ModificationFreeModificationHours);
                AddIfHasValue(rules, "feesAfter", policy.ModificationFeesAfter);
                AddIfHasValue(rules, "flexible", policy.ModificationFlexible);
                AddIfHasValue(rules, "reason", policy.ModificationReason);
                break;
        }

        return rules;
    }

    public static string BuildRulesJson(PropertyPolicy policy)
    {
        var dict = BuildRulesDictionary(policy);
        return JsonHelper.SafeSerializeDictionary(dict);
    }

    public static void PopulatePolicyFromRulesJson(PropertyPolicy policy, string? rulesJson)
    {
        if (policy == null) throw new ArgumentNullException(nameof(policy));
        if (string.IsNullOrWhiteSpace(rulesJson)) return;

        var dict = JsonHelper.SafeDeserializeDictionary(rulesJson);
        if (dict.Count == 0) return;

        switch (policy.Type)
        {
            case PolicyType.Cancellation:
                policy.CancellationFreeCancel = GetBool(dict, "freeCancel") ?? policy.CancellationFreeCancel;
                policy.CancellationFullRefund = GetBool(dict, "fullRefund") ?? policy.CancellationFullRefund;
                policy.CancellationRefundPercentage = GetInt(dict, "refundPercentage") ?? policy.CancellationRefundPercentage;
                policy.CancellationDaysBeforeCheckIn = GetInt(dict, "daysBeforeCheckIn") ?? policy.CancellationDaysBeforeCheckIn;
                policy.CancellationHoursBeforeCheckIn = GetInt(dict, "hoursBeforeCheckIn") ?? policy.CancellationHoursBeforeCheckIn;
                policy.CancellationNonRefundable = GetBool(dict, "nonRefundable") ?? policy.CancellationNonRefundable;
                policy.CancellationPenaltyAfterDeadline = GetString(dict, "penaltyAfterDeadline") ?? GetString(dict, "penaltyAfter") ?? policy.CancellationPenaltyAfterDeadline;
                break;

            case PolicyType.Payment:
                policy.PaymentDepositRequired = GetBool(dict, "depositRequired") ?? policy.PaymentDepositRequired;
                policy.PaymentFullPaymentRequired = GetBool(dict, "fullPaymentRequired") ?? policy.PaymentFullPaymentRequired;
                policy.PaymentDepositPercentage = GetDecimal(dict, "depositPercentage") ?? policy.PaymentDepositPercentage;
                policy.PaymentAcceptCash = GetBool(dict, "acceptCash") ?? policy.PaymentAcceptCash;
                policy.PaymentAcceptCard = GetBool(dict, "acceptCard") ?? policy.PaymentAcceptCard;
                policy.PaymentPayAtProperty = GetBool(dict, "payAtProperty") ?? policy.PaymentPayAtProperty;
                policy.PaymentCashPreferred = GetBool(dict, "cashPreferred") ?? policy.PaymentCashPreferred;
                policy.PaymentAcceptedMethods = GetStringArray(dict, "acceptedMethods") ?? policy.PaymentAcceptedMethods;
                break;

            case PolicyType.CheckIn:
                policy.CheckInTime = GetTime(dict, "checkInTime") ?? policy.CheckInTime;
                policy.CheckOutTime = GetTime(dict, "checkOutTime") ?? policy.CheckOutTime;
                policy.CheckInFrom = GetTime(dict, "checkInFrom") ?? policy.CheckInFrom;
                policy.CheckInUntil = GetTime(dict, "checkInUntil") ?? policy.CheckInUntil;
                policy.CheckInFlexible = GetBool(dict, "flexible") ?? policy.CheckInFlexible;
                policy.CheckInFlexibleCheckIn = GetBool(dict, "flexibleCheckIn") ?? policy.CheckInFlexibleCheckIn;
                policy.CheckInRequiresCoordination = GetBool(dict, "requiresCoordination") ?? policy.CheckInRequiresCoordination;
                policy.CheckInContactOwner = GetBool(dict, "contactOwner") ?? policy.CheckInContactOwner;
                policy.CheckInEarlyCheckInNote = GetString(dict, "earlyCheckIn") ?? policy.CheckInEarlyCheckInNote;
                policy.CheckInLateCheckOutNote = GetString(dict, "lateCheckOut") ?? policy.CheckInLateCheckOutNote;
                policy.CheckInLateCheckOutFee = GetString(dict, "lateCheckOutFee") ?? policy.CheckInLateCheckOutFee;
                break;

            case PolicyType.Children:
                policy.ChildrenAllowed = GetBool(dict, "childrenAllowed") ?? policy.ChildrenAllowed;
                policy.ChildrenFreeUnderAge = GetInt(dict, "freeUnder") ?? policy.ChildrenFreeUnderAge;
                policy.ChildrenHalfPriceUnderAge = GetInt(dict, "halfPriceUnder") ?? policy.ChildrenHalfPriceUnderAge;
                policy.ChildrenMaxChildrenPerRoom = GetInt(dict, "maxChildrenPerRoom") ?? policy.ChildrenMaxChildrenPerRoom;
                policy.ChildrenMaxChildren = GetInt(dict, "maxChildren") ?? policy.ChildrenMaxChildren;
                policy.ChildrenCribsNote = GetString(dict, "cribs") ?? policy.ChildrenCribsNote;
                policy.ChildrenPlaygroundAvailable = GetBool(dict, "playground") ?? policy.ChildrenPlaygroundAvailable;
                policy.ChildrenKidsMenuAvailable = GetBool(dict, "kidsMenu") ?? policy.ChildrenKidsMenuAvailable;
                break;

            case PolicyType.Pets:
                policy.PetsAllowed = GetBool(dict, "petsAllowed") ?? policy.PetsAllowed;
                policy.PetsReason = GetString(dict, "reason") ?? policy.PetsReason;
                policy.PetsFeeAmount = GetDecimal(dict, "feeAmount") ?? GetDecimal(dict, "fee") ?? policy.PetsFeeAmount;
                policy.PetsMaxWeight = GetString(dict, "maxWeight") ?? policy.PetsMaxWeight;
                policy.PetsRequiresApproval = GetBool(dict, "requiresApproval") ?? policy.PetsRequiresApproval;
                policy.PetsNoFees = GetBool(dict, "noFees") ?? policy.PetsNoFees;
                policy.PetsPetFriendly = GetBool(dict, "petFriendly") ?? policy.PetsPetFriendly;
                policy.PetsOutdoorSpace = GetBool(dict, "outdoorSpace") ?? policy.PetsOutdoorSpace;
                policy.PetsStrict = GetBool(dict, "strict") ?? policy.PetsStrict;
                break;

            case PolicyType.Modification:
                policy.ModificationAllowed = GetBool(dict, "modificationAllowed") ?? policy.ModificationAllowed;
                policy.ModificationFreeModificationHours = GetInt(dict, "freeModificationHours") ?? policy.ModificationFreeModificationHours;
                policy.ModificationFeesAfter = GetString(dict, "feesAfter") ?? policy.ModificationFeesAfter;
                policy.ModificationFlexible = GetBool(dict, "flexible") ?? policy.ModificationFlexible;
                policy.ModificationReason = GetString(dict, "reason") ?? policy.ModificationReason;
                break;
        }
    }

    private static bool HasAnyTypedRules(PropertyPolicy policy)
    {
        switch (policy.Type)
        {
            case PolicyType.Cancellation:
                return policy.CancellationFreeCancel.HasValue ||
                       policy.CancellationFullRefund.HasValue ||
                       policy.CancellationRefundPercentage.HasValue ||
                       policy.CancellationDaysBeforeCheckIn.HasValue ||
                       policy.CancellationHoursBeforeCheckIn.HasValue ||
                       policy.CancellationNonRefundable.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.CancellationPenaltyAfterDeadline);

            case PolicyType.Payment:
                return policy.PaymentDepositRequired.HasValue ||
                       policy.PaymentFullPaymentRequired.HasValue ||
                       policy.PaymentDepositPercentage.HasValue ||
                       policy.PaymentAcceptCash.HasValue ||
                       policy.PaymentAcceptCard.HasValue ||
                       policy.PaymentPayAtProperty.HasValue ||
                       policy.PaymentCashPreferred.HasValue ||
                       (policy.PaymentAcceptedMethods != null && policy.PaymentAcceptedMethods.Length > 0);

            case PolicyType.CheckIn:
                return policy.CheckInTime.HasValue ||
                       policy.CheckOutTime.HasValue ||
                       policy.CheckInFrom.HasValue ||
                       policy.CheckInUntil.HasValue ||
                       policy.CheckInFlexible.HasValue ||
                       policy.CheckInFlexibleCheckIn.HasValue ||
                       policy.CheckInRequiresCoordination.HasValue ||
                       policy.CheckInContactOwner.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.CheckInEarlyCheckInNote) ||
                       !string.IsNullOrWhiteSpace(policy.CheckInLateCheckOutNote) ||
                       !string.IsNullOrWhiteSpace(policy.CheckInLateCheckOutFee);

            case PolicyType.Children:
                return policy.ChildrenAllowed.HasValue ||
                       policy.ChildrenFreeUnderAge.HasValue ||
                       policy.ChildrenHalfPriceUnderAge.HasValue ||
                       policy.ChildrenMaxChildrenPerRoom.HasValue ||
                       policy.ChildrenMaxChildren.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.ChildrenCribsNote) ||
                       policy.ChildrenPlaygroundAvailable.HasValue ||
                       policy.ChildrenKidsMenuAvailable.HasValue;

            case PolicyType.Pets:
                return policy.PetsAllowed.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.PetsReason) ||
                       policy.PetsFeeAmount.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.PetsMaxWeight) ||
                       policy.PetsRequiresApproval.HasValue ||
                       policy.PetsNoFees.HasValue ||
                       policy.PetsPetFriendly.HasValue ||
                       policy.PetsOutdoorSpace.HasValue ||
                       policy.PetsStrict.HasValue;

            case PolicyType.Modification:
                return policy.ModificationAllowed.HasValue ||
                       policy.ModificationFreeModificationHours.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.ModificationFeesAfter) ||
                       policy.ModificationFlexible.HasValue ||
                       !string.IsNullOrWhiteSpace(policy.ModificationReason);

            default:
                return false;
        }
    }

    private static void AddIfHasValue<T>(Dictionary<string, object> dict, string key, T? value)
        where T : struct
    {
        if (value.HasValue)
        {
            dict[key] = value.Value;
        }
    }

    private static void AddIfHasValue(Dictionary<string, object> dict, string key, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            dict[key] = value;
        }
    }

    private static string? ToTimeString(TimeOnly? time)
    {
        return time.HasValue ? time.Value.ToString("HH\\:mm", CultureInfo.InvariantCulture) : null;
    }

    private static bool? GetBool(Dictionary<string, object> dict, string key)
    {
        if (!dict.TryGetValue(key, out var value) || value == null) return null;

        if (value is bool b) return b;

        if (bool.TryParse(value.ToString(), out var parsed)) return parsed;

        return null;
    }

    private static int? GetInt(Dictionary<string, object> dict, string key)
    {
        if (!dict.TryGetValue(key, out var value) || value == null) return null;

        if (value is int i) return i;
        if (value is long l) return (int)l;
        if (int.TryParse(value.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)) return parsed;

        return null;
    }

    private static decimal? GetDecimal(Dictionary<string, object> dict, string key)
    {
        if (!dict.TryGetValue(key, out var value) || value == null) return null;

        if (value is decimal d) return d;
        if (value is double dbl) return (decimal)dbl;
        if (value is float f) return (decimal)f;
        if (decimal.TryParse(value.ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed)) return parsed;

        return null;
    }

    private static string? GetString(Dictionary<string, object> dict, string key)
    {
        if (!dict.TryGetValue(key, out var value) || value == null) return null;
        var s = value.ToString();
        return string.IsNullOrWhiteSpace(s) ? null : s;
    }

    private static string[]? GetStringArray(Dictionary<string, object> dict, string key)
    {
        if (!dict.TryGetValue(key, out var value) || value == null) return null;

        if (value is string[] arr) return arr;

        if (value is IEnumerable<object> list)
        {
            var strings = list.Select(x => x?.ToString())
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x!)
                .ToArray();

            return strings.Length == 0 ? null : strings;
        }

        var single = value.ToString();
        return string.IsNullOrWhiteSpace(single) ? null : new[] { single };
    }

    private static TimeOnly? GetTime(Dictionary<string, object> dict, string key)
    {
        var s = GetString(dict, key);
        if (string.IsNullOrWhiteSpace(s)) return null;

        if (TimeOnly.TryParseExact(s, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var time))
            return time;

        if (TimeOnly.TryParse(s, CultureInfo.InvariantCulture, DateTimeStyles.None, out time))
            return time;

        return null;
    }
}
