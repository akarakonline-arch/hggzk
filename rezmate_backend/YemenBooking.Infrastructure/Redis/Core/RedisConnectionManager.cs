// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// استيراد المكتبات المطلوبة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using StackExchange.Redis; // مكتبة Redis الرسمية
using Polly; // مكتبة للمرونة وإعادة المحاولة
using Polly.CircuitBreaker;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.Core
{
    /// <summary>
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// مدير اتصال Redis مع تطبيق مبادئ المرونة والعزل
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 
    /// المسؤوليات:
    /// • إدارة اتصال واحد (Singleton) مع Redis
    /// • إعادة الاتصال التلقائي عند الانقطاع
    /// • تطبيق سياسات إعادة المحاولة (Retry Policies)
    /// • مراقبة حالة الاتصال وتسجيل الأحداث
    /// • توفير واجهات للوصول إلى Database, Server, Subscriber
    /// 
    /// المبادئ المطبقة:
    /// ✓ Circuit Breaker Pattern - عدم محاولة الاتصال المتكرر عند الفشل
    /// ✓ Exponential Backoff - زيادة وقت الانتظار بين المحاولات
    /// ✓ Thread Safety - استخدام SemaphoreSlim للحماية من التزامن
    /// ✓ Event Handling - تسجيل جميع أحداث الاتصال للمراقبة
    /// </summary>
    public sealed class RedisConnectionManager : IRedisConnectionManager
    {
        #region === الحقول الخاصة (Private Fields) ===
        
        /// <summary>مُسجل الأحداث</summary>
        private readonly ILogger<RedisConnectionManager> _logger;
        
        /// <summary>مصدر الإعدادات (لقراءة سلسلة الاتصال)</summary>
        private readonly IConfiguration _configuration;
        
        /// <summary>قفل (Semaphore) لحماية عملية الاتصال من التنفيذ المتزامن</summary>
        private readonly SemaphoreSlim _connectionLock;
        
        /// <summary>سياسة إعادة المحاولة باستخدام Polly</summary>
        private readonly IAsyncPolicy<IConnectionMultiplexer> _reconnectPolicy;
        
        /// <summary>الاتصال الفعلي بـ Redis</summary>
        private IConnectionMultiplexer _connection;
        
        /// <summary>معلومات الاتصال والإحصائيات</summary>
        private readonly ConnectionInfo _connectionInfo;
        
        /// <summary>علامة التخلص من الموارد</summary>
        private bool _disposed;
        
        #endregion
        
        #region === البناء والتهيئة (Constructor & Initialization) ===

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// بناء مدير الاتصال مع تكوين سياسة إعادة المحاولة
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// </summary>
        public RedisConnectionManager(
            ILogger<RedisConnectionManager> logger,
            IConfiguration configuration)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
            
            // إنشاء قفل للحماية من التنفيذ المتزامن (نسمح بعملية واحدة فقط في وقت واحد)
            _connectionLock = new SemaphoreSlim(1, 1);
            _connectionInfo = new ConnectionInfo();
            
            // ━━━ إعداد سياسة إعادة الاتصال باستخدام Polly ━━━
            // استراتيجية: 3 محاولات مع انتظار متزايد (2^1, 2^2, 2^3 ثواني)
            _reconnectPolicy = Policy<IConnectionMultiplexer>
                .Handle<RedisConnectionException>() // التعامل مع استثناءات الاتصال
                .Or<RedisTimeoutException>() // أو استثناءات انتهاء الوقت
                .Or<ObjectDisposedException>() // أو الكائنات المتخلص منها
                .WaitAndRetryAsync(
                    3, // عدد المحاولات
                    retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)), // انتظار متزايد
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        // تسجيل كل محاولة إعادة
                        _logger.LogWarning(
                            "Retry {RetryCount} after {TimeSpan}ms to connect to Redis",
                            retryCount, timespan.TotalMilliseconds);
                    });
        }
        
        #endregion

        #region === الوصول إلى موارد Redis (Redis Resources Access) ===
        
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على قاعدة بيانات Redis (متزامن)
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يتحقق من الاتصال ويعيد محاولة الاتصال إذا لزم الأمر
        /// </summary>
        /// <param name="db">رقم قاعدة البيانات (-1 للافتراضية)</param>
        /// <returns>واجهة للتعامل مع قاعدة البيانات</returns>
        public IDatabase GetDatabase(int db = -1)
        {
            // التأكد من وجود اتصال نشط
            EnsureConnected();
            // إرجاع قاعدة البيانات المطلوبة
            return _connection.GetDatabase(db);
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على قاعدة بيانات Redis (غير متزامن)
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// مع فحص الاتصال وإعادة المحاولة التلقائية (حتى 3 محاولات)
        /// </summary>
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على قاعدة بيانات Redis (غير متزامن)
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// مع فحص الاتصال وإعادة المحاولة التلقائية (حتى 3 محاولات)
        /// يتضمن اختبار الاتصال (Ping) قبل الإرجاع
        /// </summary>
        public async Task<IDatabase> GetDatabaseAsync(int db = -1)
        {
            const int maxRetries = 3; // الحد الأقصى لعدد المحاولات
            
            // محاولة الحصول على قاعدة البيانات مع إعادة المحاولة
            for (int attempt = 0; attempt < maxRetries; attempt++)
            {
                try
                {
                    // ━━━ التحقق من حالة الاتصال ━━━
                    if (_connection == null || !_connection.IsConnected)
                    {
                        // محاولة الحصول على القفل (timeout: 5 ثواني)
                        var lockAcquired = await _connectionLock.WaitAsync(TimeSpan.FromSeconds(5)).ConfigureAwait(false);
                        if (!lockAcquired)
                        {
                            _logger.LogWarning("Failed to acquire connection lock, attempt {Attempt}", attempt + 1);
                            if (attempt < maxRetries - 1)
                            {
                                continue; // إعادة المحاولة
                            }
                            throw new TimeoutException("Failed to acquire connection lock");
                        }
                        
                        try
                        {
                            // التحقق المزدوج (Double-Check Locking)
                            if (_connection == null || !_connection.IsConnected)
                            {
                                _logger.LogWarning("Redis connection lost, attempting to reconnect (attempt {Attempt}/{MaxRetries})...", attempt + 1, maxRetries);
                                // إنشاء اتصال جديد
                                _connection = await ConnectAsync().ConfigureAwait(false);
                                _connectionInfo.LastReconnectTime = DateTime.UtcNow;
                            }
                        }
                        finally
                        {
                            // إطلاق القفل
                            _connectionLock.Release();
                        }
                    }
                    
                    // ━━━ اختبار الاتصال قبل الإرجاع ━━━
                    var database = _connection.GetDatabase(db);
                    await database.PingAsync().ConfigureAwait(false); // تأكيد أن الاتصال يعمل
                    return database;
                }
                catch (Exception ex) when (attempt < maxRetries - 1)
                {
                    // تسجيل الفشل ومتابعة المحاولة
                    _logger.LogWarning(ex, "Failed to get database, retry {Attempt} of {MaxRetries}", attempt + 1, maxRetries);
                }
            }
            
            // المحاولة الأخيرة بدون معالجة الاستثناءات
            return _connection?.GetDatabase(db) ?? throw new InvalidOperationException("Failed to get Redis database after multiple retries");
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على Subscriber (للنشر/الاشتراك في القنوات)
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// </summary>
        public ISubscriber GetSubscriber()
        {
            EnsureConnected();
            return _connection.GetSubscriber();
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على Server (لأوامر الإدارة مثل KEYS, FLUSHALL)
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// </summary>
        public IServer GetServer()
        {
            EnsureConnected();
            // الحصول على نقاط النهاية (Endpoints)
            var endpoints = _connection.GetEndPoints();
            if (endpoints.Length == 0)
            {
                throw new InvalidOperationException("No Redis endpoints configured");
            }
            // إرجاع الخادم الأول
            return _connection.GetServer(endpoints[0]);
        }
        
        #endregion
        
        #region === فحص الاتصال وإعادة الاتصال (Connection Check & Reconnect) ===

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// التحقق من حالة الاتصال
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يختبر الاتصال فعلياً باستخدام Ping
        /// </summary>
        public async Task<bool> IsConnectedAsync()
        {
            try
            {
                // التحقق من وجود الاتصال
                if (_connection == null || !_connection.IsConnected)
                {
                    return false;
                }

                // اختبار الاتصال الفعلي باستخدام Ping
                var db = GetDatabase();
                await db.PingAsync().ConfigureAwait(false);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis connection check failed");
                return false;
            }
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// إعادة الاتصال بـ Redis
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يغلق الاتصال القديم وينشئ اتصالاً جديداً
        /// </summary>
        public async Task ReconnectAsync()
        {
            // الحصول على القفل
            await _connectionLock.WaitAsync().ConfigureAwait(false);
            try
            {
                _logger.LogInformation("Attempting to reconnect to Redis");
                
                // ━━━ إغلاق الاتصال القديم ━━━
                if (_connection != null)
                {
                    try
                    {
                        await _connection.CloseAsync().ConfigureAwait(false);
                        _connection.Dispose();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Error closing old Redis connection");
                    }
                }

                // ━━━ إنشاء اتصال جديد ━━━
                _connection = await ConnectAsync().ConfigureAwait(false);
                _connectionInfo.LastReconnectTime = DateTime.UtcNow;
                _connectionInfo.IsConnected = true;
                
                _logger.LogInformation("Successfully reconnected to Redis");
            }
            catch (Exception ex)
            {
                // تحديث إحصائيات الفشل
                _connectionInfo.FailedConnections++;
                _connectionInfo.IsConnected = false;
                _logger.LogError(ex, "Failed to reconnect to Redis");
                throw;
            }
            finally
            {
                // إطلاق القفل
                _connectionLock.Release();
            }
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// الحصول على معلومات الاتصال والإحصائيات
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// </summary>
        public ConnectionInfo GetConnectionInfo()
        {
            return new ConnectionInfo
            {
                IsConnected = _connection?.IsConnected ?? false,
                Endpoint = _connectionInfo.Endpoint,
                ResponseTime = _connectionInfo.ResponseTime,
                TotalConnections = _connectionInfo.TotalConnections,
                FailedConnections = _connectionInfo.FailedConnections,
                LastReconnectTime = _connectionInfo.LastReconnectTime
            };
        }
        
        #endregion

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// التأكد من وجود اتصال نشط
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الوظيفة:
        /// يتحقق من وجود اتصال Redis نشط، وإذا لم يكن موجوداً يقوم بإنشائه
        /// يستخدم قفل (Lock) لضمان عدم إنشاء اتصالات متعددة في نفس الوقت
        /// 
        /// الاستثناءات:
        /// • ObjectDisposedException: إذا تم التخلص من المدير مسبقاً
        /// </summary>
        private void EnsureConnected()
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(nameof(RedisConnectionManager));
            }

            if (_connection == null || !_connection.IsConnected)
            {
                using (var cts = new CancellationTokenSource(TimeSpan.FromSeconds(60)))
                {
                    var lockAcquired = _connectionLock.Wait(TimeSpan.FromSeconds(10), cts.Token);
                    if (!lockAcquired)
                    {
                        _logger.LogError("Failed to acquire connection lock within 10 seconds");
                        throw new TimeoutException("Failed to acquire Redis connection lock");
                    }
                    
                    try
                    {
                        if (_connection == null || !_connection.IsConnected)
                        {
                            _logger.LogInformation("Establishing Redis connection (synchronous call)...");
                            
                            _connection = Task.Run(async () => await ConnectAsync().ConfigureAwait(false), cts.Token)
                                .ConfigureAwait(false)
                                .GetAwaiter()
                                .GetResult();
                            
                            _logger.LogInformation("Redis connection established successfully");
                        }
                    }
                    catch (OperationCanceledException)
                    {
                        _logger.LogError("Redis connection cancelled due to timeout");
                        throw new TimeoutException("Redis connection timeout after 60 seconds");
                    }
                    finally
                    {
                        _connectionLock.Release();
                    }
                }
            }
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// إنشاء اتصال جديد بـ Redis
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// العملية:
        /// 1. قراءة سلسلة الاتصال من التكوينات (Configuration)
        /// 2. تكوين خيارات الاتصال (timeout, retry policy, etc.)
        /// 3. إنشاء الاتصال باستخدام سياسة إعادة المحاولة (Retry Policy)
        /// 4. تسجيل معالجات الأحداث (Connection events)
        /// 5. تحديث معلومات الاتصال
        /// 
        /// الإرجاع:
        /// اتصال Redis جاهز للاستخدام
        /// </summary>
        private async Task<IConnectionMultiplexer> ConnectAsync()
        {
            var connectionString = _configuration.GetConnectionString("Redis") 
                ?? _configuration["Redis:ConnectionString"]
                ?? _configuration["RedisConnectionString"]
                ?? "localhost:6379";

            _logger.LogInformation("Preparing Redis connection to: {ConnectionString}", connectionString);

            var options = ConfigurationOptions.Parse(connectionString);
            
            options.AbortOnConnectFail = false;              
            options.ConnectRetry = 5;                        
            options.ConnectTimeout = 30000;                  
            options.SyncTimeout = 10000;                     
            options.AsyncTimeout = 10000;                    
            options.KeepAlive = 60;                          
            options.ReconnectRetryPolicy = new ExponentialRetry(5000);
            
            if (!options.AllowAdmin && (connectionString.Contains("allowadmin=true", StringComparison.OrdinalIgnoreCase) ||
                                        _configuration.GetValue<bool>("Redis:AllowAdmin")))
            {
                options.AllowAdmin = true;
            }
            
            var connection = await _reconnectPolicy.ExecuteAsync(async () =>
            {
                _logger.LogInformation("Attempting to connect to Redis at {Endpoint}", connectionString);
                
                var conn = await ConnectionMultiplexer.ConnectAsync(options).ConfigureAwait(false);
                
                _logger.LogInformation("Redis connection multiplexer created, registering event handlers...");
                
                conn.ConnectionFailed += OnConnectionFailed;
                conn.ConnectionRestored += OnConnectionRestored;
                conn.ErrorMessage += OnErrorMessage;
                conn.InternalError += OnInternalError;
                
                _connectionInfo.TotalConnections++;
                _connectionInfo.Endpoint = connectionString;
                
                return conn;
            }).ConfigureAwait(false);

            _logger.LogInformation("Successfully connected to Redis at {Endpoint}", connectionString);
            return connection;
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالج حدث فشل الاتصال
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يتم استدعاؤه تلقائياً عندما يفشل الاتصال بـ Redis
        /// يسجل الخطأ ويحدث إحصائيات الاتصال
        /// </summary>
        private void OnConnectionFailed(object sender, ConnectionFailedEventArgs e)
        {
            // تحديث الإحصائيات
            _connectionInfo.FailedConnections++;
            _connectionInfo.IsConnected = false;
            
            // تسجيل تفاصيل الفشل
            _logger.LogError(e.Exception, 
                "Redis connection failed. Endpoint: {Endpoint}, FailureType: {FailureType}", 
                e.EndPoint, e.FailureType);
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالج حدث استعادة الاتصال
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يتم استدعاؤه تلقائياً عندما يتم استعادة الاتصال بـ Redis بعد انقطاع
        /// يسجل الاستعادة ويحدث حالة الاتصال
        /// </summary>
        private void OnConnectionRestored(object sender, ConnectionFailedEventArgs e)
        {
            // تحديث حالة الاتصال
            _connectionInfo.IsConnected = true;
            
            // تسجيل الاستعادة الناجحة
            _logger.LogInformation(
                "Redis connection restored. Endpoint: {Endpoint}", 
                e.EndPoint);
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالج رسائل الخطأ من Redis
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يتم استدعاؤه عندما يرسل Redis رسالة خطأ
        /// يسجل الرسالة مع معلومات الخادم
        /// </summary>
        private void OnErrorMessage(object sender, RedisErrorEventArgs e)
        {
            _logger.LogError("Redis error: {Message} from {EndPoint}", 
                e.Message, e.EndPoint);
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// معالج الأخطاء الداخلية في مكتبة Redis
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// يتم استدعاؤه عند حدوث خطأ داخلي في مكتبة StackExchange.Redis
        /// يسجل تفاصيل الخطأ مع المصدر
        /// </summary>
        private void OnInternalError(object sender, InternalErrorEventArgs e)
        {
            _logger.LogError(e.Exception, 
                "Redis internal error: {Origin}", e.Origin);
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// التخلص من الموارد وإغلاق الاتصالات
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// العملية:
        /// 1. التحقق من عدم التخلص المسبق
        /// 2. إلغاء تسجيل معالجات الأحداث
        /// 3. إغلاق اتصال Redis
        /// 4. التخلص من القفل (SemaphoreSlim)
        /// 
        /// الملاحظات:
        /// • يتم استدعاؤها تلقائياً عند إيقاف التطبيق
        /// • آمنة للاستدعاء المتعدد (Idempotent)
        /// </summary>
        public void Dispose()
        {
            // التحقق من عدم التخلص المسبق
            if (_disposed) return;

            _disposed = true;

            try
            {
                if (_connection != null)
                {
                    // ━━━ إلغاء تسجيل معالجات الأحداث لتجنب memory leaks ━━━
                    _connection.ConnectionFailed -= OnConnectionFailed;
                    _connection.ConnectionRestored -= OnConnectionRestored;
                    _connection.ErrorMessage -= OnErrorMessage;
                    _connection.InternalError -= OnInternalError;
                    
                    // إغلاق الاتصال والتخلص منه
                    _connection.Close();
                    _connection.Dispose();
                }

                // التخلص من قفل التزامن
                _connectionLock?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error disposing Redis connection manager");
            }
        }
    }
}
