using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    public class CurrencySeeder : ISeeder<Currency>
    {
        public IEnumerable<Currency> SeedData()
        {
            var seedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

            return new List<Currency>
            {
                new Currency
                {
                    Code = "YER",
                    ArabicCode = "ريال",
                    Name = "Yemeni Rial",
                    ArabicName = "الريال اليمني",
                    IsDefault = true,
                    ExchangeRate = null,
                    LastUpdated = null
                },
                new Currency
                {
                    Code = "USD",
                    ArabicCode = "دولار",
                    Name = "US Dollar",
                    ArabicName = "الدولار الأمريكي",
                    IsDefault = false,
                    ExchangeRate = 250m,
                    LastUpdated = seedDate
                },
                new Currency
                {
                    Code = "SAR",
                    ArabicCode = "ريال سعودي",
                    Name = "Saudi Riyal",
                    ArabicName = "الريال السعودي",
                    IsDefault = false,
                    ExchangeRate = 66.67m,
                    LastUpdated = seedDate
                },
                new Currency
                {
                    Code = "EUR",
                    ArabicCode = "يورو",
                    Name = "Euro",
                    ArabicName = "اليورو",
                    IsDefault = false,
                    ExchangeRate = 270m,
                    LastUpdated = seedDate
                },
                new Currency
                {
                    Code = "GBP",
                    ArabicCode = "جنيه",
                    Name = "British Pound",
                    ArabicName = "الجنيه الإسترليني",
                    IsDefault = false,
                    ExchangeRate = 315m,
                    LastUpdated = seedDate
                },
                new Currency
                {
                    Code = "AED",
                    ArabicCode = "درهم",
                    Name = "UAE Dirham",
                    ArabicName = "الدرهم الإماراتي",
                    IsDefault = false,
                    ExchangeRate = 68m,
                    LastUpdated = seedDate
                }
            };
        }
    }
}
