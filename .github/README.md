# GitHub Configuration

## 📁 الهيكل

```
.github/
├── workflows/
│   ├── build-ios-apps.yml       # الـ workflow الرئيسي لبناء تطبيقات iOS
│   ├── QUICK_START.md           # دليل البدء السريع
│   ├── USAGE.md                 # دليل الاستخدام التفصيلي
│   ├── README_AR.md             # الدليل الشامل بالعربية
│   └── COMPLETION_SUMMARY.md    # ملخص الإنجاز
```

## 🚀 GitHub Actions Workflows

### Build iOS Apps
بناء تلقائي لجميع تطبيقات iOS الأربعة:
- hggzk_app
- hggzkportal_app  
- rezmate_app
- rezmateportal_app

**التشغيل:**
- تلقائيًا عند Push على `main` أو `develop`
- تلقائيًا عند فتح Pull Request
- يدويًا من GitHub Actions

**النتائج:**
- ملفات IPA
- Debug Symbols (dSYM)
- GitHub Releases (على main)
- TestFlight Upload (اختياري)

## 📚 التوثيق

اقرأ الملفات التالية للمزيد:

- [QUICK_START.md](workflows/QUICK_START.md) - ابدأ هنا! ⚡
- [USAGE.md](workflows/USAGE.md) - دليل الاستخدام الكامل
- [README_AR.md](workflows/README_AR.md) - الدليل الشامل بالعربية
- [COMPLETION_SUMMARY.md](workflows/COMPLETION_SUMMARY.md) - ملخص الإعداد

## ⚙️ الإعدادات

### GitHub Secrets المطلوبة:
- `IOS_CERTIFICATES_P12` ✅
- `IOS_CERTIFICATES_PASSWORD` ✅
- `IOS_PROVISIONING_PROFILE` ✅
- `APPSTORE_ISSUER_ID` (اختياري) ✅
- `APPSTORE_API_KEY_ID` (اختياري) ✅
- `APPSTORE_API_PRIVATE_KEY` (اختياري) ✅

### الملفات المطلوبة:
- `*/ios/ExportOptions.plist` ✅ (لكل تطبيق)
- `cer_ios/` ✅ (مجلد الشهادات)

## 🎯 الاستخدام السريع

```bash
# تشغيل workflow لجميع التطبيقات
gh workflow run build-ios-apps.yml -f app_to_build=all

# تشغيل لتطبيق واحد
gh workflow run build-ios-apps.yml -f app_to_build=hggzk_app

# مع رفع على TestFlight
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f upload_to_testflight=true
```

---

للمزيد من المعلومات، اقرأ [QUICK_START.md](workflows/QUICK_START.md)
