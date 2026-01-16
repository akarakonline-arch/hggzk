namespace YemenBooking.Core.Wallets.Jwali
{
    /// <summary>
    /// نماذج البيانات (DTOs) الخاصة بتكامل محفظة جوالي
    /// تحتوي على الهيدر الموحد وطلبات / استجابات الخدمات الرئيسية
    /// مثل تسجيل الدخول، استعلام الفاتورة، السحب النقدي، والاسترداد.
    /// </summary>
    public static class JwaliModels
    {
    }

    /// <summary>
    /// تفاصيل الخدمة المستخدمة في هيدر طلبات جوالي
    /// ServiceDetail section for Jawali APIs header
    /// </summary>
    public class JwaliServiceDetail
    {
        /// <summary>
        /// معرف ارتباط فريد للرسالة (Correlation ID)
        /// يُستخدم لتتبع الطلب عبر الأنظمة المختلفة
        /// مثال: GUID
        /// </summary>
        public string CorrID { get; set; } = string.Empty;

        /// <summary>
        /// اسم النطاق (Domain) الخاص بالمحفظة
        /// مثال: "WalletDomain"
        /// </summary>
        public string DomainName { get; set; } = string.Empty;

        /// <summary>
        /// اسم الخدمة المطلوب تنفيذها
        /// أمثلة:
        /// - PAYWA.WALLETAUTHENTICATION
        /// - PAYAG.ECOMMERCEINQUIRY
        /// - PAYAG.ECOMMCASHOUT
        /// - PAYAG.ECOMMERCEREFUND
        /// </summary>
        public string ServiceName { get; set; } = string.Empty;
    }

    /// <summary>
    /// تفاصيل الدخول (SignOn) في هيدر طلبات جوالي
    /// تحتوي على معرف العميل والمنشأة والمستخدم التقني
    /// </summary>
    public class JwaliSignonDetail
    {
        /// <summary>
        /// معرف العميل ClientID كما تم تسجيله لدى مزود الخدمة
        /// مثال: "WeCash"
        /// </summary>
        public string ClientID { get; set; } = string.Empty;

        /// <summary>
        /// معرف المنشأة / المؤسسة (OrgID)
        /// مثال: "22000001688"
        /// </summary>
        public string OrgID { get; set; } = string.Empty;

        /// <summary>
        /// معرف المستخدم التقني (UserID)
        /// مثال: "school.branch.api.test"
        /// </summary>
        public string UserID { get; set; } = string.Empty;

        /// <summary>
        /// اسم المستخدم الخارجي (ExternalUser)
        /// يمكن استخدامه لتتبع المستخدم من طرف نظامك
        /// مثال: "user1"
        /// </summary>
        public string ExternalUser { get; set; } = string.Empty;
    }

    /// <summary>
    /// سياق الرسالة (MessageContext) في هيدر طلبات جوالي
    /// </summary>
    public class JwaliMessageContext
    {
        /// <summary>
        /// تاريخ ووقت العميل بالشكل: yyyyMMddHHmm
        /// مثال: "202211101156"
        /// </summary>
        public string ClientDate { get; set; } = string.Empty;

        /// <summary>
        /// نوع جسم الرسالة (BodyType)
        /// غالباً تكون قيمته "Clear" للـ JSON الواضح
        /// </summary>
        public string BodyType { get; set; } = "Clear";
    }

    /// <summary>
    /// هيدر موحد لجميع طلبات جوالي
    /// يحوي تفاصيل الخدمة، وتفاصيل الدخول، وسياق الرسالة
    /// </summary>
    public class JwaliHeader
    {
        /// <summary>
        /// تفاصيل الخدمة (اسم الخدمة، النطاق، CorrID)
        /// </summary>
        public JwaliServiceDetail ServiceDetail { get; set; } = new();

        /// <summary>
        /// تفاصيل الدخول (ClientID, OrgID, UserID, ExternalUser)
        /// </summary>
        public JwaliSignonDetail SignonDetail { get; set; } = new();

        /// <summary>
        /// سياق الرسالة (تاريخ العميل ونوع الجسم)
        /// </summary>
        public JwaliMessageContext MessageContext { get; set; } = new();
    }

    #region Login (PAYWA.WALLETAUTHENTICATION)

    /// <summary>
    /// جسم طلب تسجيل الدخول لمحفظة جوالي
    /// Body section for PAYWA.WALLETAUTHENTICATION
    /// </summary>
    public class JwaliLoginBody
    {
        /// <summary>
        /// رقم المحفظة (Wallet Number) الخاصة بالوكيل
        /// مثال: "22000001686"
        /// </summary>
        public string Identifier { get; set; } = string.Empty;

        /// <summary>
        /// كلمة المرور الخاصة بالمحفظة
        /// مثال: "123456"
        /// </summary>
        public string Password { get; set; } = string.Empty;
    }

    /// <summary>
    /// طلب تسجيل الدخول الكامل (Header + Body)
    /// </summary>
    public class JwaliLoginRequest
    {
        /// <summary>
        /// هيدر الطلب (تفاصيل الخدمة + الدخول + السياق)
        /// </summary>
        public JwaliHeader Header { get; set; } = new();

        /// <summary>
        /// الجسم الذي يحتوي على بيانات تسجيل الدخول (رقم المحفظة + كلمة المرور)
        /// </summary>
        public JwaliLoginBody Body { get; set; } = new();
    }

    /// <summary>
    /// استجابة تسجيل الدخول لمحفظة جوالي
    /// تحتوي على التوكن المستخدم في بقية العمليات
    /// </summary>
    public class JwaliLoginResponse
    {
        /// <summary>
        /// رمز الوصول (Access Token) الذي يتم تمريره في الطلبات اللاحقة
        /// </summary>
        public string Access_Token { get; set; } = string.Empty;

        /// <summary>
        /// قيمة تعريفية للمنشأة (Org Value) تعود من النظام
        /// </summary>
        public string Org_Value { get; set; } = string.Empty;

        /// <summary>
        /// اسم المنشأة (Org Name)
        /// </summary>
        public string Org_Name { get; set; } = string.Empty;
    }

    #endregion

    #region E-Commerce Inquiry (PAYAG.ECOMMERCEINQUIRY)

    /// <summary>
    /// جسم طلب استعلام الفاتورة الإلكترونية (E-Commerce Inquiry)
    /// يستخدم للتحقق من تفاصيل الفاتورة قبل السحب أو الدفع
    /// </summary>
    public class JwaliEcommerceInquiryBody
    {
        /// <summary>
        /// رقم محفظة الوكيل الذي ينفذ العملية
        /// </summary>
        public string AgentWallet { get; set; } = string.Empty;

        /// <summary>
        /// كود القسيمة / الفاتورة (Voucher) القادم من تطبيق جوالي
        /// </summary>
        public string Voucher { get; set; } = string.Empty;

        /// <summary>
        /// رقم جوال المستلم (Receiver Mobile)
        /// </summary>
        public string ReceiverMobile { get; set; } = string.Empty;

        /// <summary>
        /// كلمة مرور محفظة الوكيل
        /// </summary>
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// رمز الوصول (Access Token) الناتج من عملية التسجيل
        /// </summary>
        public string AccessToken { get; set; } = string.Empty;

        /// <summary>
        /// معرف مرجعي داخلي يولده نظامك لكل عملية
        /// مثال: GUID أو رقم تسلسلي فريد
        /// </summary>
        public string RefId { get; set; } = string.Empty;

        /// <summary>
        /// الغرض من العملية (اختياري)
        /// مثال: "Booking Payment"
        /// </summary>
        public string? Purpose { get; set; }
    }

    /// <summary>
    /// طلب استعلام الفاتورة الإلكترونية الكامل (هيدر + جسم)
    /// </summary>
    public class JwaliEcommerceInquiryRequest
    {
        public JwaliHeader Header { get; set; } = new();
        public JwaliEcommerceInquiryBody Body { get; set; } = new();
    }

    /// <summary>
    /// استجابة استعلام الفاتورة الإلكترونية
    /// تحتوي على حالة الفاتورة والمبلغ والهواتف وغيرها
    /// </summary>
    public class JwaliEcommerceInquiryResponse
    {
        /// <summary>
        /// رقم العملية من جهة المُصدر (IssuerTrxRef)
        /// </summary>
        public string IssuerTrxRef { get; set; } = string.Empty;

        /// <summary>
        /// مبلغ الفاتورة (TxnAmount)
        /// </summary>
        public decimal TxnAmount { get; set; }

        /// <summary>
        /// رقم جوال المستلم
        /// </summary>
        public string ReceiverMobile { get; set; } = string.Empty;

        /// <summary>
        /// رقم جوال المرسل
        /// </summary>
        public string SenderMobile { get; set; } = string.Empty;

        /// <summary>
        /// حالة الفاتورة (ACCEPTED / PENDING / REJECTED / EXPIRED)
        /// </summary>
        public string State { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ العملية
        /// </summary>
        public string TrxDate { get; set; } = string.Empty;
    }

    #endregion

    #region E-Commerce Cashout (PAYAG.ECOMMCASHOUT)

    /// <summary>
    /// جسم طلب السحب النقدي (Cashout) لفاتورة جوالي
    /// غالباً يستخدم نفس الحقول الخاصة بالاستعلام
    /// </summary>
    public class JwaliEcommerceCashoutBody
    {
        public string AgentWallet { get; set; } = string.Empty;
        public string Voucher { get; set; } = string.Empty;
        public string ReceiverMobile { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string AccessToken { get; set; } = string.Empty;
        public string RefId { get; set; } = string.Empty;
        public string? Purpose { get; set; }
    }

    /// <summary>
    /// طلب السحب النقدي الكامل (هيدر + جسم)
    /// </summary>
    public class JwaliEcommerceCashoutRequest
    {
        public JwaliHeader Header { get; set; } = new();
        public JwaliEcommerceCashoutBody Body { get; set; } = new();
    }

    /// <summary>
    /// استجابة السحب النقدي لفاتورة جوالي
    /// </summary>
    public class JwaliEcommerceCashoutResponse
    {
        /// <summary>
        /// مبلغ العملية المنفذة
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// رصيد المحفظة بعد العملية
        /// </summary>
        public decimal Balance { get; set; }

        /// <summary>
        /// المرجع الصادر من جهة المُصدر (IssuerRef)
        /// </summary>
        public string IssuerRef { get; set; } = string.Empty;

        /// <summary>
        /// حالة العملية (ACCEPTED / REJECTED ...)
        /// </summary>
        public string Status { get; set; } = string.Empty;
    }

    #endregion

    #region E-Commerce Refund (PAYAG.ECOMMERCEREFUND)

    /// <summary>
    /// جسم طلب استرداد E-Commerce لمحفظة جوالي
    /// </summary>
    public class JwaliEcommerceRefundBody
    {
        public string AgentWallet { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string ReceiverMobile { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string AccessToken { get; set; } = string.Empty;
        public string RefId { get; set; } = string.Empty;

        /// <summary>
        /// نوع الاسترداد (RefundType) حسب تعريف المزود (كود رقمي)
        /// </summary>
        public string RefundType { get; set; } = string.Empty;

        /// <summary>
        /// المرجع الأصلي للعملية (IssuerRef) المطلوب استردادها
        /// </summary>
        public string IssuerRef { get; set; } = string.Empty;

        /// <summary>
        /// الغرض من الاسترداد (اختياري)
        /// </summary>
        public string? Purpose { get; set; }
    }

    /// <summary>
    /// طلب استرداد جوالي الكامل (هيدر + جسم)
    /// </summary>
    public class JwaliEcommerceRefundRequest
    {
        public JwaliHeader Header { get; set; } = new();
        public JwaliEcommerceRefundBody Body { get; set; } = new();
    }

    /// <summary>
    /// استجابة عملية الاسترداد في جوالي
    /// </summary>
    public class JwaliEcommerceRefundResponse
    {
        public decimal Amount { get; set; }
        public string Status { get; set; } = string.Empty;
        public string RefId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string TrxDate { get; set; } = string.Empty;
    }

    #endregion
}
