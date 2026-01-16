# 📱 دليل GitHub Actions لبناء تطبيقات iOS

## نظرة عامة

تم إنشاء workflow احترافي لبناء التطبيقات الأربعة التالية على نظام iOS:
- **hggzk_app** - تطبيق الحجز الرئيسي
- **hggzkportal_app** - لوحة التحكم hggzk
- **rezmate_app** - تطبيق RezMate للحجز
- **rezmateportal_app** - لوحة التحكم RezMate

## 🎯 المميزات

### 1. بناء متعدد التطبيقات
- بناء جميع التطبيقات الأربعة بشكل متوازي
- إمكانية اختيار تطبيق واحد أو أكثر للبناء
- دعم matrix builds لتوفير الوقت

### 2. أنواع البناء
- **Debug Build** - للتطوير والاختبار
- **Release Build** - للإنتاج والنشر
- **IPA Generation** - إنشاء ملفات IPA للتوزيع

### 3. التوقيع والشهادات
- دعم Code Signing الكامل
- Provisioning Profiles التلقائية
- التصدير للـ App Store أو Ad-Hoc

### 4. التكامل مع TestFlight
- رفع تلقائي إلى TestFlight
- إدارة Build Numbers تلقائيًا
- دعم App Store Connect API

### 5. Artifacts والتخزين
- حفظ ملفات IPA
- حفظ Debug Symbols (dSYM)
- إنشاء GitHub Releases تلقائيًا

## 🔧 متطلبات الإعداد

### 1. GitHub Secrets (✅ تم إعدادها)

الـ Secrets المطلوبة في إعدادات المستودع:

#### للتوقيع (Code Signing)
```
✅ IOS_CERTIFICATES_P12          # شهادة التوقيع بصيغة P12 (Base64)
✅ IOS_CERTIFICATES_PASSWORD     # كلمة مرور شهادة P12
✅ IOS_PROVISIONING_PROFILE      # ملف Provisioning Profile (Base64)
```

#### للرفع على TestFlight (اختياري)
```
✅ APPSTORE_ISSUER_ID            # App Store Connect Issuer ID
✅ APPSTORE_API_KEY_ID           # App Store Connect API Key ID
✅ APPSTORE_API_PRIVATE_KEY      # App Store Connect API Private Key
```

### 2. مجلد الشهادات (✅ موجود)

```
cer_ios/
├── certificates/
├── profiles/
└── keys/
```

### 3. تحديث ExportOptions.plist

لكل تطبيق، قم بتحديث الملف `ios/ExportOptions.plist`:

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>  <!-- ضع Team ID الخاص بك -->

<key>provisioningProfiles</key>
<dict>
    <key>com.yourcompany.appname</key>  <!-- Bundle Identifier -->
    <string>Profile Name</string>        <!-- اسم الـ Profile -->
</dict>
```

للحصول على Team ID:
```bash
# من Apple Developer Portal → Membership
# أو من Xcode → Signing & Capabilities
```

## 🚀 كيفية الاستخدام

### 1. التشغيل التلقائي
يعمل الـ workflow تلقائيًا عند:
- Push على فرع `main` أو `develop`
- فتح Pull Request على هذه الفروع

### 2. التشغيل اليدوي

من صفحة GitHub Actions:

1. اذهب إلى **Actions** → **Build iOS Apps**
2. اضغط **Run workflow**
3. اختر الإعدادات:
   - **App to build**: اختر تطبيق محدد أو `all` للكل
   - **Build type**: `debug` أو `release`
   - **Upload to TestFlight**: `true` أو `false`
4. اضغط **Run workflow**

### 3. استخدام من Terminal

```bash
# إطلاق الـ workflow يدويًا باستخدام GitHub CLI
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release \
  -f upload_to_testflight=false
```

## 📦 مخرجات البناء

### 1. IPA Files
- يتم حفظها كـ Artifacts
- تبقى لمدة 30 يوم
- يمكن تنزيلها من صفحة الـ workflow run

### 2. dSYM Files (Debug Symbols)
- ضرورية لـ Firebase Crashlytics
- تُحفظ مع كل build
- استخدمها لتتبع الأخطاء

### 3. GitHub Releases
عند البناء على فرع `main`:
- يتم إنشاء Release تلقائيًا
- يحتوي على ملف IPA
- Tag بصيغة: `appname-v1.0.0+123`

## 🔄 سير العمل (Workflow)

```
1. Setup
   ├── تحديد التطبيقات للبناء
   └── إنشاء Build Matrix

2. Build iOS (لكل تطبيق)
   ├── Checkout Code
   ├── Setup Xcode & Flutter
   ├── Get Dependencies
   │   ├── flutter pub get
   │   └── pod install
   ├── Code Generation (إذا لزم)
   ├── Code Signing
   ├── Update Version
   ├── Build IPA
   ├── Upload Artifacts
   ├── Upload to TestFlight (اختياري)
   └── Create Release (اختياري)

3. Notify Completion
   └── ملخص النتائج
```

## 🎨 تخصيص الـ Workflow

### تغيير إصدار Flutter
```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # غيّر هنا
```

### تغيير إصدار Xcode
```yaml
env:
  XCODE_VERSION: '15.2'  # غيّر هنا
```

### إضافة تطبيق جديد
1. أضفه في `setup.outputs.matrix`
2. أضف ExportOptions.plist له
3. تأكد من Bundle ID في Provisioning Profile

### تغيير طريقة التوزيع
في `ExportOptions.plist`:
```xml
<!-- للـ App Store -->
<key>method</key>
<string>app-store</string>

<!-- للـ Ad-Hoc -->
<key>method</key>
<string>ad-hoc</string>

<!-- للـ Development -->
<key>method</key>
<string>development</string>

<!-- للـ Enterprise -->
<key>method</key>
<string>enterprise</string>
```

## 🐛 استكشاف الأخطاء

### خطأ: "No matching provisioning profile found"
**الحل:**
1. تأكد من Bundle ID في ExportOptions.plist
2. تأكد من صلاحية Provisioning Profile
3. تأكد من تطابق الشهادة مع الـ Profile

### خطأ: "Code signing failed"
**الحل:**
1. تأكد من صحة شهادة P12
2. تأكد من كلمة مرور P12
3. تأكد من أن الشهادة لم تنتهي صلاحيتها

### خطأ: "Pod install failed"
**الحل:**
1. تحديث Podfile.lock
2. تشغيل `pod repo update` محليًا
3. التأكد من توافق إصدارات الـ dependencies

### خطأ: "Build failed with Firebase"
**الحل:**
1. تأكد من وجود GoogleService-Info.plist
2. تأكد من صحة Firebase configuration
3. تحقق من Firebase dependencies في pubspec.yaml

## 📊 مثال على الـ Build Logs

```
✅ Checkout repository
✅ Setup Xcode 15.2
✅ Setup Flutter 3.24.0
✅ Flutter Doctor
✅ Get Flutter dependencies
✅ Install CocoaPods dependencies
✅ Import Code Signing Certificates
✅ Download Provisioning Profiles
✅ Update version to 1.0.0+123
✅ Build iOS IPA
✅ Upload IPA Artifact
✅ Upload Debug Symbols
✅ Create GitHub Release

Build completed successfully! 🎉
Time: 15m 32s
IPA: hggzk_app-v1.0.0+123-iOS.ipa (45.3 MB)
```

## 🔐 الأمان

### حماية الـ Secrets
- لا تشارك Secrets أبدًا
- استخدم Environment Secrets للحماية الإضافية
- قم بتدوير الشهادات بشكل دوري

### التحكم بالوصول
- قيّد من يمكنه تشغيل الـ workflows
- استخدم Branch Protection Rules
- فعّل Required Reviews

## 📈 التحسينات المستقبلية

- [ ] إضافة Unit Tests
- [ ] إضافة Integration Tests
- [ ] إضافة Code Coverage
- [ ] إضافة Fastlane
- [ ] إضافة Slack Notifications
- [ ] إضافة Performance Monitoring
- [ ] إضافة Screenshot Testing

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من الـ Logs
2. راجع هذا الدليل
3. تحقق من GitHub Actions Documentation
4. تواصل مع الفريق

## 📝 ملاحظات هامة

### Bundle Identifiers
تأكد من أن Bundle IDs في ExportOptions.plist تطابق:
- **hggzk_app**: `com.hggzk.app`
- **hggzkportal_app**: `com.hggzkportal.app`
- **rezmate_app**: `com.rezmate.app`
- **rezmateportal_app**: `com.rezmateportal.app`

### Build Numbers
- يتم تحديث Build Number تلقائيًا من `github.run_number`
- لا تحتاج لتحديثه يدويًا
- يزيد بشكل تلقائي مع كل build

### Retention Period
- Artifacts تُحفظ لمدة 30 يوم
- يمكنك تغييرها في `retention-days`
- بعد 30 يوم، يتم حذفها تلقائيًا

## ✨ أفضل الممارسات

1. **استخدم Semantic Versioning**: `major.minor.patch+build`
2. **اختبر محليًا أولاً**: قبل الـ push
3. **راجع الـ Logs**: حتى لو نجح البناء
4. **احتفظ بنسخة من الشهادات**: في مكان آمن
5. **حدّث Dependencies بانتظام**: للأمان والأداء

---

**تم الإنشاء بواسطة:** GitHub Copilot  
**التاريخ:** يناير 2026  
**الإصدار:** 1.0.0
