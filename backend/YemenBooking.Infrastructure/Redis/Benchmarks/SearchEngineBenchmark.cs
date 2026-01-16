using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Infrastructure.Redis.Benchmarks;

/// <summary>
/// مقارنة الأداء بين النسخة القديمة والمحسّنة
/// 
/// كيفية الاستخدام:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// var benchmark = new SearchEngineBenchmark(logger);
/// var results = await benchmark.RunComparisonAsync(oldFunc, newFunc);
/// 
/// النتائج المتوقعة:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • بحث بسيط: تحسين 60-70%
/// • بحث مع تواريخ: تحسين 70-80%
/// • بحث معقد: تحسين 75-85%
/// </summary>
public class SearchEngineBenchmark
{
    private readonly ILogger _logger;
    
    public SearchEngineBenchmark(ILogger logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    /// <summary>
    /// تشغيل المقارنة الشاملة
    /// </summary>
    public async Task<BenchmarkResults> RunComparisonAsync(
        Func<UnitSearchRequest, Task<UnitSearchResult>> oldSearchFunc,
        Func<UnitSearchRequest, Task<UnitSearchResult>> newSearchFunc,
        int iterations = 10)
    {
        _logger.LogInformation("═══════════════════════════════════════════════════════════");
        _logger.LogInformation("🚀 بدء مقارنة الأداء بين النسخة القديمة والمحسّنة");
        _logger.LogInformation("═══════════════════════════════════════════════════════════");
        
        var results = new BenchmarkResults();
        
        // السيناريو 1: بحث بسيط (مدينة فقط)
        _logger.LogInformation("\n📊 السيناريو 1: بحث بسيط (مدينة فقط)");
        var scenario1 = await RunScenarioAsync(
            "بحث بسيط - مدينة فقط",
            new UnitSearchRequest { City = "صنعاء", PageSize = 20 },
            oldSearchFunc,
            newSearchFunc,
            iterations);
        results.Scenarios.Add(scenario1);
        
        // السيناريو 2: بحث مع تواريخ
        _logger.LogInformation("\n📊 السيناريو 2: بحث مع تواريخ");
        var scenario2 = await RunScenarioAsync(
            "بحث مع تواريخ",
            new UnitSearchRequest
            {
                City = "صنعاء",
                CheckIn = DateTime.UtcNow.AddDays(7),
                CheckOut = DateTime.UtcNow.AddDays(10),
                PageSize = 20
            },
            oldSearchFunc,
            newSearchFunc,
            iterations);
        results.Scenarios.Add(scenario2);
        
        PrintSummary(results);
        return results;
    }
    
    private async Task<ScenarioBenchmark> RunScenarioAsync(
        string scenarioName,
        UnitSearchRequest request,
        Func<UnitSearchRequest, Task<UnitSearchResult>> oldSearchFunc,
        Func<UnitSearchRequest, Task<UnitSearchResult>> newSearchFunc,
        int iterations)
    {
        var scenario = new ScenarioBenchmark { Name = scenarioName };
        var oldTimes = new List<long>();
        var newTimes = new List<long>();
        
        for (int i = 0; i < iterations; i++)
        {
            var sw = Stopwatch.StartNew();
            await oldSearchFunc(request);
            sw.Stop();
            oldTimes.Add(sw.ElapsedMilliseconds);
        }
        
        for (int i = 0; i < iterations; i++)
        {
            var sw = Stopwatch.StartNew();
            await newSearchFunc(request);
            sw.Stop();
            newTimes.Add(sw.ElapsedMilliseconds);
        }
        
        scenario.OldAverageMs = (long)oldTimes.Average();
        scenario.NewAverageMs = (long)newTimes.Average();
        scenario.ImprovementPercent = ((double)(scenario.OldAverageMs - scenario.NewAverageMs) / scenario.OldAverageMs) * 100;
        
        return scenario;
    }
    
    private void PrintSummary(BenchmarkResults results)
    {
        _logger.LogInformation("\n📊 الملخص النهائي:");
        foreach (var scenario in results.Scenarios)
        {
            _logger.LogInformation("   {0}: {1}ms → {2}ms (تحسين {3:F1}%)",
                scenario.Name,
                scenario.OldAverageMs,
                scenario.NewAverageMs,
                scenario.ImprovementPercent);
        }
    }
}

public class BenchmarkResults
{
    public List<ScenarioBenchmark> Scenarios { get; set; } = new();
}

public class ScenarioBenchmark
{
    public string Name { get; set; } = string.Empty;
    public long OldAverageMs { get; set; }
    public long NewAverageMs { get; set; }
    public double ImprovementPercent { get; set; }
}
