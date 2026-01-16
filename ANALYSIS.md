# تحليل عميق لمشكلة "Error resolving address"

## السبب الجذري

### ما حدث بالضبط:

1. ✅ **التوثيق نجح**
   - تم الاتصال بـ `ani.sidestore.io` بنجاح
   - تم الحصول على anisette data
   - تم التوثيق مع Apple ID بنجاح (2FA)
   - تم الحصول على token: `com.apple.gs.xcode.auth`

2. ✅ **الاتصال بالجهاز نجح**
   - تم التعرف على UDID: `00008030-001A755C2ED2402E`
   - تم إنشاء pairing file بنجاح

3. ❌ **فشل في مرحلة التثبيت**
   - الخطأ: `Error resolving address`
   - يحدث عند محاولة الاتصال بخوادم Apple لتنزيل provisioning profile

### التفسير التقني:

**AltServer** يعمل كالتالي:
```
1. التوثيق → ✅ نجح
2. الحصول على token → ✅ نجح  
3. طلب provisioning profile من developer.apple.com → ❌ فشل هنا
4. توقيع IPA بالـ profile
5. إرسال IPA للجهاز
```

### السبب المحتمل:

**مشكلة DNS/Network داخل Docker Container:**
- Container لا يمكنه resolve hostnames لخوادم Apple
- خوادم Apple المطلوبة:
  - `developer.apple.com`
  - `idmsa.apple.com` 
  - `gsa.apple.com`
  - `p58-buy.itunes.apple.com`

### لماذا `--network host` لم يحل المشكلة:

1. DNS configuration داخل Container معزولة
2. resolv.conf في Container قد تكون مختلفة
3. قد يكون هناك firewall rules تمنع الاتصال

## الحلول المقترحة:

### الحل 1: إصلاح DNS (السكريبت الجديد)
```bash
bash /home/ameen/Desktop/BOOKIN/BOOKIN/install_ipa_final.sh
```

### الحل 2: استخدام Windows/macOS
- AltServer يعمل بشكل أفضل على Windows/macOS
- استخدام VM أو Dual boot

### الحل 3: استخدام Free Apple Developer Account
- إذا كان الحساب المستخدم ليس developer account
- قد تحتاج لتسجيل free developer account

### الحل 4: استخدام SideStore مباشرة
- تثبيت SideStore على iPhone أولاً
- استخدام SideStore لتثبيت IPAs الأخرى

### الحل 5: استخدام أداة بديلة
- Sideloadly عبر Wine
- ios-deploy + zsign (manual signing)
