using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YemenBooking.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddTypedPolicyRulesColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Rules",
                table: "PropertyPolicies",
                type: "text",
                nullable: true,
                comment: "قواعد السياسة (JSON)",
                oldClrType: typeof(string),
                oldType: "text",
                oldComment: "قواعد السياسة (JSON)");

            migrationBuilder.AddColumn<int>(
                name: "CancellationDaysBeforeCheckIn",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CancellationFreeCancel",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CancellationFullRefund",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancellationHoursBeforeCheckIn",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CancellationNonRefundable",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancellationPenaltyAfterDeadline",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancellationRefundPercentage",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CheckInContactOwner",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CheckInEarlyCheckInNote",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CheckInFlexible",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CheckInFlexibleCheckIn",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "CheckInFrom",
                table: "PropertyPolicies",
                type: "time without time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CheckInLateCheckOutFee",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CheckInLateCheckOutNote",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "CheckInRequiresCoordination",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "CheckInTime",
                table: "PropertyPolicies",
                type: "time without time zone",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "CheckInUntil",
                table: "PropertyPolicies",
                type: "time without time zone",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "CheckOutTime",
                table: "PropertyPolicies",
                type: "time without time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ChildrenAllowed",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ChildrenCribsNote",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChildrenFreeUnderAge",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChildrenHalfPriceUnderAge",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ChildrenKidsMenuAvailable",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChildrenMaxChildren",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChildrenMaxChildrenPerRoom",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ChildrenPlaygroundAvailable",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ModificationAllowed",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ModificationFeesAfter",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ModificationFlexible",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ModificationFreeModificationHours",
                table: "PropertyPolicies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ModificationReason",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentAcceptCard",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentAcceptCash",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string[]>(
                name: "PaymentAcceptedMethods",
                table: "PropertyPolicies",
                type: "text[]",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentCashPreferred",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "PaymentDepositPercentage",
                table: "PropertyPolicies",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentDepositRequired",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentFullPaymentRequired",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PaymentPayAtProperty",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsAllowed",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "PetsFeeAmount",
                table: "PropertyPolicies",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PetsMaxWeight",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsNoFees",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsOutdoorSpace",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsPetFriendly",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PetsReason",
                table: "PropertyPolicies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsRequiresApproval",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PetsStrict",
                table: "PropertyPolicies",
                type: "boolean",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CancellationDaysBeforeCheckIn",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationFreeCancel",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationFullRefund",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationHoursBeforeCheckIn",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationNonRefundable",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationPenaltyAfterDeadline",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CancellationRefundPercentage",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInContactOwner",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInEarlyCheckInNote",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInFlexible",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInFlexibleCheckIn",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInFrom",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInLateCheckOutFee",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInLateCheckOutNote",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInRequiresCoordination",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInTime",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckInUntil",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "CheckOutTime",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenAllowed",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenCribsNote",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenFreeUnderAge",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenHalfPriceUnderAge",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenKidsMenuAvailable",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenMaxChildren",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenMaxChildrenPerRoom",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ChildrenPlaygroundAvailable",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ModificationAllowed",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ModificationFeesAfter",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ModificationFlexible",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ModificationFreeModificationHours",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "ModificationReason",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentAcceptCard",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentAcceptCash",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentAcceptedMethods",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentCashPreferred",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentDepositPercentage",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentDepositRequired",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentFullPaymentRequired",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PaymentPayAtProperty",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsAllowed",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsFeeAmount",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsMaxWeight",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsNoFees",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsOutdoorSpace",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsPetFriendly",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsReason",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsRequiresApproval",
                table: "PropertyPolicies");

            migrationBuilder.DropColumn(
                name: "PetsStrict",
                table: "PropertyPolicies");

            migrationBuilder.AlterColumn<string>(
                name: "Rules",
                table: "PropertyPolicies",
                type: "text",
                nullable: false,
                defaultValue: "",
                comment: "قواعد السياسة (JSON)",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true,
                oldComment: "قواعد السياسة (JSON)");
        }
    }
}
