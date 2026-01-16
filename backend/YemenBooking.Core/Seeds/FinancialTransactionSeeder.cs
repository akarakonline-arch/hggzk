using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// بيانات أولية يدوية للقيود المحاسبية - مستوى متوسط (حجز + دفعة + عمولة)
    /// Manual seed data for financial transactions - medium level (booking + payment + commission)
    /// </summary>
    public class FinancialTransactionSeeder : ISeeder<FinancialTransaction>
    {
        private static readonly DateTime BaseDate = new DateTime(2024, 11, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<FinancialTransaction> SeedData()
        {
            var transactions = new List<FinancialTransaction>();
            
            // ملاحظة: سيتم تعبئة القيود المحاسبية تلقائياً من خلال DataSeedingService
            // بعد إنشاء الحجوزات والمدفوعات والحسابات المحاسبية
            // هذا السيدر موجود كنموذج ويمكن ملؤه لاحقاً إذا لزم الأمر
            
            return transactions;
        }
    }
}
