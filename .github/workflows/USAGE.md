# 📱 دليل الاستخدام السريع - GitHub Actions iOS Build

## ✅ الإعداد (تم بالفعل)
- ✅ مجلد `cer_ios` تم إضافته في المسار الرئيسي
- ✅ GitHub Secrets تم إعدادها
- ✅ ExportOptions.plist جاهزة لكل تطبيق

## 🚀 كيفية الاستخدام

### 1️⃣ التشغيل التلقائي
يعمل الـ workflow تلقائيًا عند:
```
✅ Push على فرع main
✅ Push على فرع develop  
✅ فتح Pull Request
```

### 2️⃣ التشغيل اليدوي من GitHub

1. اذهب إلى: https://github.com/akarakonline-arch/hggzk/actions
2. اختر **"Build iOS Apps"**
3. اضغط **"Run workflow"**
4. املأ الخيارات:
   - **App to build**: اختر التطبيق أو `all` للكل
   - **Build type**: `release` أو `debug`
   - **Upload to TestFlight**: `true` أو `false`
5. اضغط **"Run workflow"**

### 3️⃣ التشغيل من Terminal (باستخدام GitHub CLI)

```bash
# بناء جميع التطبيقات
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release \
  -f upload_to_testflight=false

# بناء تطبيق واحد فقط
gh workflow run build-ios-apps.yml \
  -f app_to_build=hggzk_app \
  -f build_type=release \
  -f upload_to_testflight=false

# بناء ورفع على TestFlight
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release \
  -f upload_to_testflight=true
```

## 📦 التطبيقات المدعومة

| التطبيق | الوصف |
|---------|-------|
| `hggzk_app` | تطبيق الحجز الرئيسي |
| `hggzkportal_app` | لوحة التحكم hggzk |
| `rezmate_app` | تطبيق RezMate للحجز |
| `rezmateportal_app` | لوحة التحكم RezMate |

## 📥 تنزيل ملفات IPA

بعد اكتمال البناء:

1. اذهب إلى صفحة الـ workflow run
2. في قسم **"Artifacts"** في الأسفل
3. قم بتنزيل:
   - `[app-name]-ios-ipa` - ملف IPA
   - `[app-name]-ios-dsym` - Debug Symbols

## 📋 متطلبات هامة

### قبل أول تشغيل:
تحقق من أن كل تطبيق يحتوي على `ExportOptions.plist` في مجلد `ios/` مع:

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>  <!-- ✅ تأكد من Team ID -->

<key>provisioningProfiles</key>
<dict>
    <key>com.yourapp.bundleid</key>  <!-- ✅ Bundle Identifier الصحيح -->
    <string>Profile Name</string>     <!-- ✅ اسم الـ Profile -->
</dict>
```

### GitHub Secrets المطلوبة (تم إعدادها):
✅ `IOS_CERTIFICATES_P12`  
✅ `IOS_CERTIFICATES_PASSWORD`  
✅ `IOS_PROVISIONING_PROFILE`  
✅ `APPSTORE_ISSUER_ID` (اختياري - للـ TestFlight)  
✅ `APPSTORE_API_KEY_ID` (اختياري - للـ TestFlight)  
✅ `APPSTORE_API_PRIVATE_KEY` (اختياري - للـ TestFlight)

## 🎯 أمثلة سريعة

### بناء سريع لتطبيق واحد:
```bash
gh workflow run build-ios-apps.yml -f app_to_build=hggzk_app
```

### بناء جميع التطبيقات للإنتاج:
```bash
gh workflow run build-ios-apps.yml -f app_to_build=all -f build_type=release
```

### بناء ونشر على TestFlight:
```bash
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release \
  -f upload_to_testflight=true
```

## 📊 مراقبة البناء

### عرض قائمة الـ workflows:
```bash
gh workflow list
```

### عرض آخر التشغيلات:
```bash
gh run list --workflow=build-ios-apps.yml
```

### عرض تفاصيل تشغيل معين:
```bash
gh run view [RUN_ID]
```

### متابعة البناء مباشرة:
```bash
gh run watch
```

## 🔍 استكشاف الأخطاء

### إذا فشل البناء:

1. **تحقق من الـ Logs:**
   ```bash
   gh run view [RUN_ID] --log
   ```

2. **الأخطاء الشائعة:**
   - ❌ Bundle ID غير صحيح → تحقق من ExportOptions.plist
   - ❌ Certificate expired → جدد الشهادة
   - ❌ Profile mismatch → تحقق من Provisioning Profile

3. **إعادة التشغيل:**
   ```bash
   gh run rerun [RUN_ID]
   ```

## 📈 النتائج المتوقعة

بعد البناء الناجح:
- ✅ ملف IPA لكل تطبيق
- ✅ Debug Symbols (dSYM)
- ✅ GitHub Release (عند البناء على main)
- ✅ رفع على TestFlight (إذا تم تفعيله)

## 💡 نصائح

1. **البناء السريع:** استخدم `debug` للاختبار السريع
2. **البناء الإنتاجي:** استخدم `release` للنشر
3. **Build Numbers:** يتم تحديثها تلقائيًا
4. **Version:** يُؤخذ من `pubspec.yaml`

## 📞 المراجع

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter iOS Build Guide](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Portal](https://developer.apple.com/)

---

**ملاحظة:** جميع الإعدادات جاهزة، فقط قم بتشغيل الـ workflow! 🚀
