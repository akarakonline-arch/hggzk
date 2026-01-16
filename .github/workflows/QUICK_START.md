# 🚀 بدء سريع - GitHub Actions iOS

## ✅ جاهز للعمل!

جميع الإعدادات تمت بنجاح:
- ✅ Workflow files
- ✅ ExportOptions.plist 
- ✅ GitHub Secrets
- ✅ Certificates في `cer_ios/`

## 🎯 تشغيل سريع

### من GitHub Web:
1. https://github.com/akarakonline-arch/hggzk/actions
2. **Build iOS Apps** → **Run workflow**
3. اختر: `app_to_build=all`, `build_type=release`
4. **Run workflow**

### من Terminal:
```bash
gh workflow run build-ios-apps.yml \
  -f app_to_build=all \
  -f build_type=release
```

## 📱 التطبيقات

- `hggzk_app`
- `hggzkportal_app`
- `rezmate_app`
- `rezmateportal_app`

## 📥 النتائج

بعد البناء، ستجد في **Artifacts**:
- ملفات IPA
- Debug Symbols (dSYM)

## 📚 التوثيق الكامل

- [USAGE.md](./USAGE.md) - دليل الاستخدام السريع
- [README_AR.md](./README_AR.md) - الدليل الشامل

## 🔍 متابعة البناء

```bash
# عرض التشغيلات
gh run list

# متابعة مباشرة
gh run watch
```

---
**جاهز؟** ابدأ البناء الآن! 🎉
