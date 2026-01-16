using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using YemenBooking.Core.Enums;

namespace YemenBooking.Api.JsonConverters
{
    public class SectionTypeJsonConverter : JsonConverter<SectionType>
    {
        public override SectionType Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                var raw = reader.GetString() ?? string.Empty;
                var value = raw.Trim();

                if (value.Length == 0)
                {
                    return SectionType.Grid;
                }

                // Allow both API-style (Grid/BigCards/List) and client-style (grid/bigCards/list)
                var lower = value.ToLowerInvariant();
                if (lower == "grid")
                {
                    return SectionType.Grid;
                }
                if (lower == "bigcards")
                {
                    return SectionType.BigCards;
                }
                if (lower == "list")
                {
                    return SectionType.List;
                }

                // Fallback: try parse enum name
                if (Enum.TryParse<SectionType>(value, ignoreCase: true, out var parsed))
                {
                    return parsed;
                }

                throw new JsonException($"Invalid SectionType value: '{raw}'");
            }

            if (reader.TokenType == JsonTokenType.Number && reader.TryGetInt32(out var intValue))
            {
                if (Enum.IsDefined(typeof(SectionType), intValue))
                {
                    return (SectionType)intValue;
                }

                throw new JsonException($"Invalid numeric SectionType value: {intValue}");
            }

            throw new JsonException($"Unexpected token parsing SectionType: {reader.TokenType}");
        }

        public override void Write(Utf8JsonWriter writer, SectionType value, JsonSerializerOptions options)
        {
            // Serialize using canonical string values expected by clients (grid/bigCards/list)
            writer.WriteStringValue(value.GetValue());
        }
    }
}
