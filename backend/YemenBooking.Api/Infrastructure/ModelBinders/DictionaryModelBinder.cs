using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ModelBinding.Metadata;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace YemenBooking.Api.Infrastructure.ModelBinders
{
    /// <summary>
    /// Custom Model Binder لربط query parameters بصيغة key[subkey]=value إلى Dictionary&lt;string, string&gt;
    /// يدعم الصيغة: ?dynamicFieldFilters[chalet_size]=139&amp;dynamicFieldFilters[numberOfBedrooms]=3..5
    /// Custom Model Binder for binding query parameters in the format key[subkey]=value to Dictionary&lt;string, string&gt;
    /// Supports format: ?dynamicFieldFilters[chalet_size]=139&amp;dynamicFieldFilters[numberOfBedrooms]=3..5
    /// </summary>
    public class DictionaryModelBinder : IModelBinder
    {
        private readonly ILogger<DictionaryModelBinder> _logger;

        public DictionaryModelBinder(ILogger<DictionaryModelBinder> logger)
        {
            _logger = logger;
        }

        public Task BindModelAsync(ModelBindingContext bindingContext)
        {
            if (bindingContext == null)
                throw new ArgumentNullException(nameof(bindingContext));

            var modelName = bindingContext.ModelName;
            
            _logger.LogInformation("🔧 [DictionaryModelBinder] بدء الربط للـ model: {ModelName}", modelName);
            
            // التحقق من أن النوع المستهدف هو Dictionary<string, string>
            if (bindingContext.ModelType != typeof(Dictionary<string, string>))
            {
                _logger.LogWarning("⚠️ [DictionaryModelBinder] النوع المستهدف ليس Dictionary<string, string>");
                return Task.CompletedTask;
            }

            var dictionary = new Dictionary<string, string>();
            
            // الحصول على جميع المفاتيح من HttpContext.Request.Query
            var request = bindingContext.HttpContext.Request;
            
            if (request.Query == null || !request.Query.Any())
            {
                _logger.LogInformation("🔧 [DictionaryModelBinder] لا توجد query parameters في الطلب");
                bindingContext.Result = ModelBindingResult.Success(dictionary);
                return Task.CompletedTask;
            }

            _logger.LogInformation("🔧 [DictionaryModelBinder] إجمالي query parameters: {Count}", request.Query.Count);
            
            // البحث عن المفاتيح التي تبدأ بـ modelName[
            var prefix = $"{modelName}[";
            var matchingKeys = request.Query.Keys
                .Where(k => k.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                .ToList();

            _logger.LogInformation("🔧 [DictionaryModelBinder] المفاتيح المطابقة لـ '{Prefix}': {Count}", prefix, matchingKeys.Count);

            if (!matchingKeys.Any())
            {
                _logger.LogInformation("🔧 [DictionaryModelBinder] لا توجد قيم - إرجاع dictionary فارغ");
                bindingContext.Result = ModelBindingResult.Success(dictionary);
                return Task.CompletedTask;
            }

            // معالجة كل مفتاح وقيمته
            foreach (var fullKey in matchingKeys)
            {
                var values = request.Query[fullKey];
                
                if (values.Count > 0)
                {
                    var value = values[0];
                    
                    if (!string.IsNullOrWhiteSpace(value))
                    {
                        // استخراج المفتاح الفعلي من dynamicFieldFilters[key]
                        // مثال: dynamicFieldFilters[chalet_size] → chalet_size
                        var startIndex = prefix.Length;
                        var endIndex = fullKey.IndexOf(']', startIndex);
                        
                        if (endIndex > startIndex)
                        {
                            var actualKey = fullKey.Substring(startIndex, endIndex - startIndex);
                            dictionary[actualKey] = value;
                            
                            _logger.LogInformation("🔧 [DictionaryModelBinder] تم إضافة: {Key} = {Value}", actualKey, value);
                        }
                    }
                }
            }

            _logger.LogInformation("🔧 [DictionaryModelBinder] Dictionary النهائي: {Count} عنصر", dictionary.Count);
            
            bindingContext.Result = ModelBindingResult.Success(dictionary);
            return Task.CompletedTask;
        }
    }

    /// <summary>
    /// Provider للـ DictionaryModelBinder
    /// Provider for DictionaryModelBinder
    /// </summary>
    public class DictionaryModelBinderProvider : IModelBinderProvider
    {
        public IModelBinder? GetBinder(ModelBinderProviderContext context)
        {
            if (context == null)
                throw new ArgumentNullException(nameof(context));

            // تطبيق فقط على Dictionary<string, string>
            if (context.Metadata.ModelType == typeof(Dictionary<string, string>))
            {
                var loggerFactory = context.Services.GetService(typeof(ILoggerFactory)) as ILoggerFactory;
                var logger = loggerFactory?.CreateLogger<DictionaryModelBinder>();
                
                return new DictionaryModelBinder(logger ?? throw new InvalidOperationException("Logger is required"));
            }

            return null;
        }
    }
}
