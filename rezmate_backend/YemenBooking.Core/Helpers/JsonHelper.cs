using System;
using System.Collections.Generic;
using System.Text.Json;

namespace YemenBooking.Core.Helpers
{
    /// <summary>
    /// مساعد لتحويل JSON بشكل صحيح مع دعم القوائم والخرائط المتداخلة
    /// Helper for correct JSON conversion with support for nested lists and maps
    /// </summary>
    public static class JsonHelper
    {
        /// <summary>
        /// تحويل JSON string إلى Dictionary مع تحويل JsonElement إلى أنواع .NET الأصلية
        /// </summary>
        public static Dictionary<string, object> SafeDeserializeDictionary(string? json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return new Dictionary<string, object>();
            }

            try
            {
                using var document = JsonDocument.Parse(json);
                return ConvertJsonElementToDictionary(document.RootElement);
            }
            catch (JsonException)
            {
                return new Dictionary<string, object>();
            }
        }

        /// <summary>
        /// تسلسل Dictionary إلى JSON بشكل آمن مع تحويل JsonElement إلى أنواع أصلية أولاً
        /// Safe serialize Dictionary to JSON, converting JsonElement to native types first
        /// </summary>
        public static string SafeSerializeDictionary(Dictionary<string, object>? dict)
        {
            if (dict == null || dict.Count == 0)
            {
                return "{}";
            }

            try
            {
                // تحويل القاموس لإزالة أي JsonElement
                var cleanDict = ConvertDictionaryValues(dict);
                return JsonSerializer.Serialize(cleanDict);
            }
            catch (Exception)
            {
                return "{}";
            }
        }

        /// <summary>
        /// تحويل قيم Dictionary من JsonElement إلى أنواع .NET الأصلية
        /// Convert Dictionary values from JsonElement to native .NET types
        /// </summary>
        public static Dictionary<string, object> ConvertDictionaryValues(Dictionary<string, object>? dict)
        {
            if (dict == null)
            {
                return new Dictionary<string, object>();
            }

            var result = new Dictionary<string, object>();
            foreach (var kvp in dict)
            {
                result[kvp.Key] = ConvertValue(kvp.Value);
            }
            return result;
        }

        /// <summary>
        /// تحويل قيمة واحدة - إذا كانت JsonElement يتم تحويلها
        /// Convert a single value - if it's JsonElement, convert it
        /// </summary>
        public static object ConvertValue(object? value)
        {
            if (value == null)
            {
                return null!;
            }

            if (value is JsonElement jsonElement)
            {
                return ConvertJsonElement(jsonElement);
            }

            if (value is Dictionary<string, object> dict)
            {
                return ConvertDictionaryValues(dict);
            }

            if (value is System.Collections.IList list)
            {
                var convertedList = new List<object>();
                foreach (var item in list)
                {
                    convertedList.Add(ConvertValue(item));
                }
                return convertedList;
            }

            return value;
        }

        /// <summary>
        /// تحويل JsonElement إلى Dictionary مع تحويل القوائم والقيم المتداخلة بشكل صحيح
        /// </summary>
        public static Dictionary<string, object> ConvertJsonElementToDictionary(JsonElement element)
        {
            var result = new Dictionary<string, object>();

            if (element.ValueKind != JsonValueKind.Object)
            {
                return result;
            }

            foreach (var property in element.EnumerateObject())
            {
                result[property.Name] = ConvertJsonElement(property.Value);
            }

            return result;
        }

        /// <summary>
        /// تحويل JsonElement إلى النوع الأصلي المناسب
        /// </summary>
        public static object ConvertJsonElement(JsonElement element)
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.Object:
                    return ConvertJsonElementToDictionary(element);

                case JsonValueKind.Array:
                    var list = new List<object>();
                    foreach (var item in element.EnumerateArray())
                    {
                        list.Add(ConvertJsonElement(item));
                    }
                    return list;

                case JsonValueKind.String:
                    return element.GetString() ?? string.Empty;

                case JsonValueKind.Number:
                    if (element.TryGetInt32(out var intValue))
                        return intValue;
                    if (element.TryGetInt64(out var longValue))
                        return longValue;
                    if (element.TryGetDouble(out var doubleValue))
                        return doubleValue;
                    return element.GetDecimal();

                case JsonValueKind.True:
                    return true;

                case JsonValueKind.False:
                    return false;

                case JsonValueKind.Null:
                case JsonValueKind.Undefined:
                default:
                    return null!;
            }
        }
    }
}
