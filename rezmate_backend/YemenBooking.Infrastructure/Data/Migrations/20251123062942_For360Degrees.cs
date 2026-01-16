using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YemenBooking.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class For360Degrees : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "Is360",
                table: "UnitInSectionImages",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "Is360",
                table: "SectionImages",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDisabled",
                table: "Reviews",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "Is360",
                table: "PropertyInSectionImages",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "Is360",
                table: "PropertyImages",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Is360",
                table: "UnitInSectionImages");

            migrationBuilder.DropColumn(
                name: "Is360",
                table: "SectionImages");

            migrationBuilder.DropColumn(
                name: "IsDisabled",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "Is360",
                table: "PropertyInSectionImages");

            migrationBuilder.DropColumn(
                name: "Is360",
                table: "PropertyImages");
        }
    }
}
