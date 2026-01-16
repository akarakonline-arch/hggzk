# ✅ تم إنشاء GitHub Actions Workflow لبناء تطبيقات iOS

## 📋 ما تم إنجازه

### 1. ملفات Workflow
✅ `.github/workflows/build-ios-apps.yml` - الـ workflow الرئيسي

### 2. ملفات ExportOptions.plist
تم إنشاء ملفات التصدير لجميع التطبيقات مع Bundle IDs الصحيحة:

| التطبيق | Bundle ID | الملف |
|---------|-----------|-------|
| hggzk_app | `com.hggzk.app` | ✅ `hggzk_app/ios/ExportOptions.plist` |
| hggzkportal_app | `com.hggzkportal.app` | ✅ `hggzkportal_app/ios/ExportOptions.plist` |
| rezmate_app | `com.arma.rezmate` | ✅ `rezmate_app/ios/ExportOptions.plist` |
| rezmateportal_app | `com.rezmateportal.app` | ✅ `rezmateportal_app/ios/ExportOptions.plist` |

### 3. ملفات التوثيق
- ✅ `QUICK_START.md` - البدء السريع
- ✅ `USAGE.md` - دليل الاستخدام التفصيلي
- ✅ `README_AR.md` - الدليل الشامل بالعربية

### 4. الإعدادات الموجودة
- ✅ مجلد `cer_ios/` في المسار الرئيسي
- ✅ GitHub Secrets تم إعدادها

## 🎯 الخطوة التالية

### تحديث Team ID في ExportOptions.plist

يجب عليك تحديث `YOUR_TEAM_ID` في الملفات التالية:

```bash
# 1. hggzk_app
nano hggzk_app/ios/ExportOptions.plist

# 2. hggzkportal_app  
nano hggzkportal_app/ios/ExportOptions.plist

# 3. rezmate_app
nano rezmate_app/ios/ExportOptions.plist

# 4. rezmateportal_app
nano rezmateportal_app/ios/ExportOptions.plist
```

ابحث عن:
```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
```

واستبدل `YOUR_TEAM_ID` بـ Team ID الخاص بك من Apple Developer Portal.

### كيفية الحصول على Team ID:
1. اذهب إلى: https://developer.apple.com/account
2. اختر **Membership**
3. انسخ **Team ID**

أو من Xcode:
1. افتح مشروعك في Xcode
2. اذهب إلى **Signing & Capabilities**
3. ستجد Team ID بجانب Team Name

## 🚀 تشغيل أول Build

بعد تحديث Team ID:

### من GitHub Web:
```
1. اذهب إلى: https://github.com/akarakonline-arch/hggzk/actions
2. اختر "Build iOS Apps"
3. اضغط "Run workflow"
4. اختر:
   - app_to_build: all
   - build_type: release
   - upload_to_testflight: false
5. اضغط "Run workflow"
```

### من Terminal:
```bash
# تأكد من أنك في مجلد المشروع
cd /home/ameen/Desktop/BOOKIN/BOOKIN

# قم بعمل commit و push
git add .github/
git add */ios/ExportOptions.plist
git commit -m "Add GitHub Actions iOS build workflow"
git push

# أو قم بتشغيل الـ workflow مباشرة
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release \
  -f upload_to_testflight=false
```

## 📊 ما سيحدث عند التشغيل

```
⏳ Setting up build matrix...
⏳ Building hggzk_app for iOS...
   ├── ✅ Setup Xcode & Flutter
   ├── ✅ Install dependencies
   ├── ✅ Code signing
   ├── ✅ Build IPA
   └── ✅ Upload artifacts

⏳ Building hggzkportal_app for iOS...
   └── ... (نفس الخطوات)

⏳ Building rezmate_app for iOS...
   └── ... (نفس الخطوات)

⏳ Building rezmateportal_app for iOS...
   └── ... (نفس الخطوات)

✅ All builds completed!
```

## 📥 النتائج المتوقعة

بعد اكتمال البناء، ستجد:

### في GitHub Artifacts:
- `hggzk_app-ios-ipa` (ملف IPA + dSYM)
- `hggzkportal_app-ios-ipa` (ملف IPA + dSYM)
- `rezmate_app-ios-ipa` (ملف IPA + dSYM)
- `rezmateportal_app-ios-ipa` (ملف IPA + dSYM)

### في GitHub Releases (إذا كان على main):
- Release جديد مع tag: `[app-name]-v1.0.0+[build-number]`
- ملف IPA مرفق

## ⚙️ الإعدادات المتقدمة

### تغيير Flutter Version:
في `.github/workflows/build-ios-apps.yml`:
```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # غيّر هنا
```

### تغيير Xcode Version:
```yaml
env:
  XCODE_VERSION: '15.2'  # غيّر هنا
```

### بناء تطبيق واحد فقط:
```bash
gh workflow run build-ios-apps.yml -f app_to_build=hggzk_app
```

### بناء Debug Build:
```bash
gh workflow run build-ios-apps.yml -f build_type=debug
```

### رفع على TestFlight:
```bash
gh workflow run build-ios-apps.yml -f upload_to_testflight=true
```

## 🔍 استكشاف الأخطاء

### مشكلة: "No matching provisioning profile"
**الحل:**
1. تحقق من Bundle ID في ExportOptions.plist
2. تأكد من وجود Provisioning Profile مطابق في GitHub Secrets
3. تأكد من أن Profile لم ينتهي

### مشكلة: "Code signing failed"
**الحل:**
1. تحقق من صلاحية شهادة P12
2. تأكد من كلمة المرور الصحيحة في GitHub Secrets
3. تأكد من Team ID الصحيح

### مشكلة: "Pod install failed"
**الحل:**
1. قم بتحديث Podfile.lock محليًا
2. push التحديثات
3. أعد تشغيل الـ workflow

## 📚 المراجع السريعة

- [QUICK_START.md](.github/workflows/QUICK_START.md) - البدء السريع
- [USAGE.md](.github/workflows/USAGE.md) - دليل الاستخدام
- [README_AR.md](.github/workflows/README_AR.md) - الدليل الشامل

## ✨ المميزات الرئيسية

✅ بناء متوازي لجميع التطبيقات  
✅ دعم Debug و Release builds  
✅ Code signing تلقائي  
✅ TestFlight integration  
✅ Automatic versioning  
✅ GitHub Releases  
✅ Artifacts storage (30 days)  
✅ dSYM files للـ Crashlytics  

## 🎉 كل شيء جاهز!

فقط قم بـ:
1. ✅ تحديث Team ID في ExportOptions.plist
2. ✅ Commit & Push
3. ✅ تشغيل الـ workflow
4. ✅ انتظر النتائج!

---

**تم الإنشاء:** ${new Date().toLocaleDateString('ar-EG')}  
**المطور:** GitHub Copilot  
**الإصدار:** 1.0.0  
**الحالة:** ✅ جاهز للاستخدام
