// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

/// 🎨 Unified Theme System - نظام ثيم موحد
class AppTheme {
  AppTheme._();

  // Current theme mode
  static ThemeMode _themeMode = ThemeMode.system;
  static ThemeMode get themeMode => _themeMode;

  // Track current brightness
  static Brightness _brightness = Brightness.dark;
  static Brightness get brightness => _brightness;

  // Initialize theme based on system or manual setting
  static void init(BuildContext context, {ThemeMode? mode}) {
    _themeMode = mode ?? ThemeMode.system;
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    if (_themeMode == ThemeMode.system) {
      _brightness = systemBrightness;
    } else if (_themeMode == ThemeMode.light) {
      _brightness = Brightness.light;
    } else {
      _brightness = Brightness.dark;
    }
  }

  // Helper method to check if dark mode
  static bool get isDark => _brightness == Brightness.dark;

  // 🎨 Primary Gradient Colors
  static Color get primaryBlue => isDark
      ? const Color.fromARGB(255, 79, 169, 254)
      : const Color(0xFF0066CC);
  static Color get primaryPurple =>
      isDark ? const Color(0xFF667EEA) : const Color(0xFF6366F1);
  static Color get primaryViolet =>
      isDark ? const Color(0xFF764BA2) : const Color(0xFF8B5CF6);
  static Color get primaryCyan =>
      isDark ? const Color.fromARGB(255, 0, 161, 254) : const Color(0xFF0891B2);

  // 🌟 Neon & Glow Colors
  static Color get neonBlue =>
      isDark ? const Color.fromARGB(255, 0, 174, 255) : const Color(0xFF0EA5E9);
  static Color get neonPurple =>
      isDark ? const Color(0xFF9D50FF) : const Color(0xFFA855F7);
  static Color get neonGreen =>
      isDark ? const Color(0xFF00FF88) : const Color(0xFF10B981);
  static Color get glowBlue =>
      isDark ? const Color(0xFF4FACFE) : const Color(0xFF3B82F6);
  static Color get glowWhite =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFA);

  // 🌙 Base Colors
  static Color get darkBackground =>
      isDark ? const Color(0xFF0A0E27) : const Color(0xFFFAFAFA);
  static Color get darkBackground2 =>
      isDark ? const Color(0xFF0F1629) : const Color(0xFFFAFAFA);
  static Color get darkBackground3 =>
      isDark ? const Color(0xFF1A0E3D) : const Color(0xFFFAFAFA);

  // static Color get darkBackground => isDark ? const Color(0xFF0A0E27) : const Color(0xFFFAFBFF);
  // static Color get darkBackground2 => isDark ? const Color(0xFF0D1332) : const Color(0xFFF5F7FE);
  // static Color get darkBackground3 => isDark ? const Color(0xFF11183F) : const Color(0xFFF0F3FD);

  // static Color get darkBackground => isDark ? const Color(0xFF0A0E27) : const Color(0xFFF0F4FF);
  // static Color get darkBackground2 => isDark ? const Color(0xFF1A1547) : const Color(0xFFE8EFFF);
  // static Color get darkBackground3 => isDark ? const Color(0xFF2D1B69) : const Color(0xFFE0E8FF);

  static Color get darkSurface =>
      isDark ? const Color(0xFF151930) : const Color(0xFFFFFFFF);
  static Color get darkCard =>
      isDark ? const Color(0xFF1E2341) : const Color(0xFFFFFFFF);
  static Color get darkBorder =>
      isDark ? const Color(0xFF2A3050) : const Color(0xFFE5E5E5);

  // ☀️ Light Theme Base Colors
  static Color get lightBackground =>
      isDark ? const Color(0xFFF8FAFF) : const Color(0xFFF9FAFB);
  static Color get lightSurface =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
  static Color get lightCard =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
  static Color get lightBorder =>
      isDark ? const Color(0xFFE8ECFA) : const Color(0xFFE5E7EB);

  // 📝 Text Colors
  static Color get textWhite =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
  static Color get textLight =>
      isDark ? const Color(0xFFB8C4E6) : const Color(0xFF374151);
  static Color get textMuted =>
      isDark ? const Color(0xFF8B95B7) : const Color(0xFF6B7280);
  static Color get textDark =>
      isDark ? const Color(0xFF1A1F36) : const Color(0xFF030712);

  // ✨ Glass & Blur Effects
  static Color get glassDark =>
      isDark ? const Color(0x1A000000) : const Color(0x08000000);
  static Color get glassLight =>
      isDark ? const Color(0x0DFFFFFF) : const Color(0x0F0066CC);
  static Color get glassOverlay =>
      isDark ? const Color(0x80151930) : const Color(0x66FFFFFF);
  static Color get frostedGlass =>
      isDark ? const Color(0x30FFFFFF) : const Color(0x99F9FAFB);

  // 🚦 Status Colors
  static Color get success =>
      isDark ? const Color(0xFF00FF88) : const Color(0xFF059669);
  static Color get warning =>
      isDark ? const Color(0xFFFFB800) : const Color(0xFFF59E0B);
  static Color get error =>
      isDark ? const Color(0xFFFF3366) : const Color(0xFFDC2626);
  static Color get info =>
      isDark ? const Color.fromARGB(255, 0, 183, 255) : const Color(0xFF0284C7);

  // 🎭 Shadows & Overlays
  static Color get shadowDark =>
      isDark ? const Color(0x40000000) : const Color(0x0A000000);
  static Color get shadowLight =>
      isDark ? const Color(0x1A4FACFE) : const Color(0x050066CC);
  static Color get overlayDark =>
      isDark ? const Color(0xCC0A0E27) : const Color(0x0A111827);
  static Color get overlayLight =>
      isDark ? const Color(0x99FFFFFF) : const Color(0xE6FFFFFF);

  // 🌈 Gradient Definitions
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryCyan, primaryBlue, primaryPurple, primaryViolet],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );

  static LinearGradient get darkGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1F36), Color(0xFF0F1629)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFB), Color(0xFFFAFAFA)],
        );

  static LinearGradient get cardGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1A4FACFE),
            Color(0x0D667EEA),
            Color(0x1A764BA2),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x050066CC),
            Color(0x036366F1),
            Color(0x058B5CF6),
          ],
        );

  static LinearGradient get neonGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [neonBlue, neonPurple, neonGreen],
      );

  static LinearGradient get glassGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x40FFFFFF),
            Color(0x1AFFFFFF),
            Color(0x40FFFFFF),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x0DFFFFFF),
            Color(0x08FFFFFF),
            Color(0x0DFFFFFF),
          ],
        );

  static RadialGradient get glowGradient => isDark
      ? const RadialGradient(
          colors: [
            Color(0x804FACFE),
            Color(0x404FACFE),
            Color(0x004FACFE),
          ],
        )
      : const RadialGradient(
          colors: [
            Color(0x1A0066CC),
            Color(0x0D0066CC),
            Color(0x000066CC),
          ],
        );

  // 🎯 Component Specific Colors
  static Color get buttonPrimary => primaryBlue;
  static Color get buttonSecondary => primaryPurple;
  static Color get inputBackground =>
      isDark ? const Color(0x0D4FACFE) : const Color(0xFFF3F4F6);
  static Color get inputBorder =>
      isDark ? const Color(0x334FACFE) : const Color(0xFFD1D5DB);
  static Color get inputFocusBorder => primaryBlue;

  // 💎 Special Effects
  static Color get shimmerBase => primaryBlue.withOpacity(isDark ? 0.05 : 0.03);
  static Color get shimmerHighlight =>
      primaryBlue.withOpacity(isDark ? 0.2 : 0.08);
  static Color get holographic => primaryPurple.withOpacity(isDark ? 0.3 : 0.1);

  // 🔲 Booking Status
  static Color get bookingPending =>
      isDark ? const Color(0xFFFFB800) : const Color(0xFFF59E0B);
  static Color get bookingConfirmed =>
      isDark ? const Color(0xFF00FF88) : const Color(0xFF059669);
  static Color get bookingCancelled =>
      isDark ? const Color(0xFFFF3366) : const Color(0xFFDC2626);
  static Color get bookingCompleted =>
      isDark ? const Color(0xFF00D4FF) : const Color(0xFF0284C7);

  // 🔁 Backward-compatible aliases
  static Color get shadow => shadowDark;
  static Color get primaryDark =>
      isDark ? const Color(0xFF0F1629) : const Color(0xFF003D7A);
  static const Color transparent = Colors.transparent;
  static Color get gray200 => lightBorder;
  static Color get textDisabled => textMuted;
  static Color get shimmer =>
      isDark ? const Color(0xFF2A3050) : const Color(0xFFF3F4F6);
}

// import 'package:flutter/material.dart';

// /// ════════════════════════════════════════════════════════════════════════════
// /// 🎨 ELEGANT GRAYSCALE LUXURY THEME SYSTEM
// /// نظام ثيم رمادي فاخر مع ألوان حالات مضيئة
// /// ════════════════════════════════════════════════════════════════════════════
// ///
// /// 🏛️ Philosophy: الفلسفة
// /// ───────────────────────01
// /// • الرمادي ودرجاته = الألوان الأساسية والرئيسية
// /// • الألوان المضيئة = للحالات والإشعارات والتمييز فقط
// ///
// /// ════════════════════════════════════════════════════════════════════════════

// class AppTheme {
//   AppTheme._();

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🔧 THEME CONFIGURATION
//   // ═══════════════════════════════════════════════════════════════════════════

//   static ThemeMode _themeMode = ThemeMode.system;
//   static ThemeMode get themeMode => _themeMode;

//   static Brightness _brightness = Brightness.dark;
//   static Brightness get brightness => _brightness;

//   static void init(BuildContext context, {ThemeMode? mode}) {
//     _themeMode = mode ?? ThemeMode.system;
//     final systemBrightness = MediaQuery.of(context).platformBrightness;

//     if (_themeMode == ThemeMode.system) {
//       _brightness = systemBrightness;
//     } else if (_themeMode == ThemeMode.light) {
//       _brightness = Brightness.light;
//     } else {
//       _brightness = Brightness.dark;
//     }
//   }

//   static bool get isDark => _brightness == Brightness.dark;
//   static bool get isLight => !isDark;

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🎨 PRIMARY GRAYSCALE COLORS - الألوان الرمادية الأساسية
//   // ═══════════════════════════════════════════════════════════════════════════

//   /// Primary Charcoal - الفحمي الرئيسي
//   static Color get primaryBlue =>
//       isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A);

//   /// Graphite - الجرافيتي
//   static Color get primaryPurple =>
//       isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46);

//   /// Slate - الأردوازي
//   static Color get primaryViolet =>
//       isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

//   /// Steel - الفولاذي
//   static Color get primaryCyan =>
//       isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 💎 LUXURY METALLIC ACCENTS - اللمسات المعدنية الفاخرة
//   // ═══════════════════════════════════════════════════════════════════════════

//   /// Champagne Gold - ذهبي شامبانيا
//   static Color get accentGold =>
//       isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8960C);

//   /// Rose Gold - ذهبي وردي
//   static Color get accentRose =>
//       isDark ? const Color(0xFFE8B4B8) : const Color(0xFFB76E79);

//   /// Platinum - بلاتيني
//   static Color get accentSilver =>
//       isDark ? const Color(0xFFE8E8EC) : const Color(0xFFB8B8BC);

//   /// Cool Gray - رمادي بارد
//   static Color get accentMint =>
//       isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🌟 SUBTLE GLOW COLORS - ألوان التوهج الناعمة (رمادية)
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get neonBlue =>
//       isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

//   static Color get neonPurple =>
//       isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

//   static Color get neonGreen =>
//       isDark ? const Color(0xFFA8A8B0) : const Color(0xFF78787F);

//   static Color get glowBlue =>
//       isDark ? const Color(0xFFB0B0B8) : const Color(0xFF5A5A62);

//   static Color get glowWhite =>
//       isDark ? const Color(0xFFF8F8FA) : const Color(0xFFFAFAFC);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🌑 DARK THEME BACKGROUNDS - خلفيات الوضع الداكن
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get darkBackground =>
//       isDark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA);

//   static Color get darkBackground2 =>
//       isDark ? const Color(0xFF0F0F11) : const Color(0xFFF5F5F7);

//   static Color get darkBackground3 =>
//       isDark ? const Color(0xFF141416) : const Color(0xFFF0F0F2);

//   static Color get darkSurface =>
//       isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);

//   static Color get darkCard =>
//       isDark ? const Color(0xFF1F1F23) : const Color(0xFFFFFFFF);

//   static Color get darkBorder =>
//       isDark ? const Color(0xFF2E2E32) : const Color(0xFFE4E4E7);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ☀️ LIGHT THEME BACKGROUNDS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get lightBackground => const Color(0xFFFAFAFA);
//   static Color get lightSurface => const Color(0xFFFFFFFF);
//   static Color get lightCard => const Color(0xFFFFFFFF);
//   static Color get lightBorder => const Color(0xFFE4E4E7);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 📝 TEXT COLORS - ألوان النصوص
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get textWhite =>
//       isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);

//   static Color get textLight =>
//       isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46);

//   static Color get textMuted =>
//       isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);

//   static Color get textDark =>
//       isDark ? const Color(0xFF18181B) : const Color(0xFF09090B);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ✨ GLASS & BLUR EFFECTS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get glassDark =>
//       isDark ? const Color(0x14000000) : const Color(0x0A000000);

//   static Color get glassLight =>
//       isDark ? const Color(0x0CFFFFFF) : const Color(0x0A27272A);

//   static Color get glassOverlay =>
//       isDark ? const Color(0x7018181B) : const Color(0x60FFFFFF);

//   static Color get frostedGlass =>
//       isDark ? const Color(0x28FFFFFF) : const Color(0x94F5F5F7);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🚦 VIBRANT STATUS COLORS - ألوان الحالات المضيئة والجميلة
//   // ═══════════════════════════════════════════════════════════════════════════
//   //
//   // هذه الألوان مصممة لتكون:
//   // ✓ مضيئة وواضحة
//   // ✓ متناسقة مع القاعدة الرمادية
//   // ✓ سهلة التمييز عن بعضها
//   //
//   // ═══════════════════════════════════════════════════════════════════════════

//   // ─────────────────────────────────────────────────────────────────
//   // ✅ SUCCESS - النجاح (أخضر زمردي مضيء)
//   // ─────────────────────────────────────────────────────────────────

//   /// Success Primary - اللون الأساسي للنجاح
//   static Color get success =>
//       isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);

//   /// Success Light - نسخة فاتحة
//   static Color get successLight =>
//       isDark ? const Color(0xFF6EE7B7) : const Color(0xFF34D399);

//   /// Success Dark - نسخة داكنة
//   static Color get successDark =>
//       isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

//   /// Success Background - خلفية النجاح
//   static Color get successBg =>
//       isDark ? const Color(0xFF052E16) : const Color(0xFFECFDF5);

//   /// Success Border - حدود النجاح
//   static Color get successBorder =>
//       isDark ? const Color(0xFF166534) : const Color(0xFFA7F3D0);

//   // ─────────────────────────────────────────────────────────────────
//   // ⚠️ WARNING - التحذير (ذهبي/كهرماني مضيء)
//   // ─────────────────────────────────────────────────────────────────

//   /// Warning Primary - اللون الأساسي للتحذير
//   static Color get warning =>
//       isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

//   /// Warning Light - نسخة فاتحة
//   static Color get warningLight =>
//       isDark ? const Color(0xFFFDE68A) : const Color(0xFFFBBF24);

//   /// Warning Dark - نسخة داكنة
//   static Color get warningDark =>
//       isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

//   /// Warning Background - خلفية التحذير
//   static Color get warningBg =>
//       isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB);

//   /// Warning Border - حدود التحذير
//   static Color get warningBorder =>
//       isDark ? const Color(0xFF854D0E) : const Color(0xFFFDE68A);

//   // ─────────────────────────────────────────────────────────────────
//   // ❌ ERROR - الخطأ (أحمر مرجاني مضيء)
//   // ─────────────────────────────────────────────────────────────────

//   /// Error Primary - اللون الأساسي للخطأ
//   static Color get error =>
//       isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

//   /// Error Light - نسخة فاتحة
//   static Color get errorLight =>
//       isDark ? const Color(0xFFFCA5A5) : const Color(0xFFF87171);

//   /// Error Dark - نسخة داكنة
//   static Color get errorDark =>
//       isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

//   /// Error Background - خلفية الخطأ
//   static Color get errorBg =>
//       isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);

//   /// Error Border - حدود الخطأ
//   static Color get errorBorder =>
//       isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);

//   // ─────────────────────────────────────────────────────────────────
//   // ℹ️ INFO - المعلومات (أزرق سماوي مضيء)
//   // ─────────────────────────────────────────────────────────────────

//   /// Info Primary - اللون الأساسي للمعلومات
//   static Color get info =>
//       isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);

//   /// Info Light - نسخة فاتحة
//   static Color get infoLight =>
//       isDark ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8);

//   /// Info Dark - نسخة داكنة
//   static Color get infoDark =>
//       isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);

//   /// Info Background - خلفية المعلومات
//   static Color get infoBg =>
//       isDark ? const Color(0xFF082F49) : const Color(0xFFF0F9FF);

//   /// Info Border - حدود المعلومات
//   static Color get infoBorder =>
//       isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🔔 NOTIFICATION COLORS - ألوان الإشعارات المتنوعة
//   // ═══════════════════════════════════════════════════════════════════════════

//   // ─────────────────────────────────────────────────────────────────
//   // 💜 PURPLE NOTIFICATION - إشعار بنفسجي (للتحديثات/الجديد)
//   // ─────────────────────────────────────────────────────────────────

//   static Color get notificationPurple =>
//       isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);

//   static Color get notificationPurpleLight =>
//       isDark ? const Color(0xFFC4B5FD) : const Color(0xFFA78BFA);

//   static Color get notificationPurpleBg =>
//       isDark ? const Color(0xFF2E1065) : const Color(0xFFF5F3FF);

//   static Color get notificationPurpleBorder =>
//       isDark ? const Color(0xFF6D28D9) : const Color(0xFFDDD6FE);

//   // ─────────────────────────────────────────────────────────────────
//   // 💖 PINK NOTIFICATION - إشعار وردي (للعروض/الترويج)
//   // ─────────────────────────────────────────────────────────────────

//   static Color get notificationPink =>
//       isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899);

//   static Color get notificationPinkLight =>
//       isDark ? const Color(0xFFF9A8D4) : const Color(0xFFF472B6);

//   static Color get notificationPinkBg =>
//       isDark ? const Color(0xFF500724) : const Color(0xFFFDF2F8);

//   static Color get notificationPinkBorder =>
//       isDark ? const Color(0xFFBE185D) : const Color(0xFFFBCFE8);

//   // ─────────────────────────────────────────────────────────────────
//   // 🧡 ORANGE NOTIFICATION - إشعار برتقالي (للتذكيرات)
//   // ─────────────────────────────────────────────────────────────────

//   static Color get notificationOrange =>
//       isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316);

//   static Color get notificationOrangeLight =>
//       isDark ? const Color(0xFFFDBA74) : const Color(0xFFFB923C);

//   static Color get notificationOrangeBg =>
//       isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED);

//   static Color get notificationOrangeBorder =>
//       isDark ? const Color(0xFFC2410C) : const Color(0xFFFED7AA);

//   // ─────────────────────────────────────────────────────────────────
//   // 💙 INDIGO NOTIFICATION - إشعار نيلي (للرسائل)
//   // ─────────────────────────────────────────────────────────────────

//   static Color get notificationIndigo =>
//       isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);

//   static Color get notificationIndigoLight =>
//       isDark ? const Color(0xFFA5B4FC) : const Color(0xFF818CF8);

//   static Color get notificationIndigoBg =>
//       isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);

//   static Color get notificationIndigoBorder =>
//       isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE);

//   // ─────────────────────────────────────────────────────────────────
//   // 🩵 TEAL NOTIFICATION - إشعار تركوازي (للنصائح)
//   // ─────────────────────────────────────────────────────────────────

//   static Color get notificationTeal =>
//       isDark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);

//   static Color get notificationTealLight =>
//       isDark ? const Color(0xFF5EEAD4) : const Color(0xFF2DD4BF);

//   static Color get notificationTealBg =>
//       isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDFA);

//   static Color get notificationTealBorder =>
//       isDark ? const Color(0xFF0F766E) : const Color(0xFF99F6E4);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🏷️ TAG/BADGE COLORS - ألوان العلامات والشارات
//   // ═══════════════════════════════════════════════════════════════════════════

//   /// New Tag - علامة "جديد"
//   static Color get tagNew =>
//       isDark ? const Color(0xFF22D3EE) : const Color(0xFF06B6D4);
//   static Color get tagNewBg =>
//       isDark ? const Color(0xFF083344) : const Color(0xFFECFEFF);

//   /// Hot Tag - علامة "رائج"
//   static Color get tagHot =>
//       isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E);
//   static Color get tagHotBg =>
//       isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);

//   /// Sale Tag - علامة "تخفيض"
//   static Color get tagSale =>
//       isDark ? const Color(0xFFA3E635) : const Color(0xFF84CC16);
//   static Color get tagSaleBg =>
//       isDark ? const Color(0xFF1A2E05) : const Color(0xFFF7FEE7);

//   /// Premium Tag - علامة "مميز"
//   static Color get tagPremium =>
//       isDark ? const Color(0xFFE879F9) : const Color(0xFFD946EF);
//   static Color get tagPremiumBg =>
//       isDark ? const Color(0xFF4A044E) : const Color(0xFFFDF4FF);

//   /// Featured Tag - علامة "مختار"
//   static Color get tagFeatured =>
//       isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B);
//   static Color get tagFeaturedBg =>
//       isDark ? const Color(0xFF451A03) : const Color(0xFFFEFCE8);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🎭 SHADOWS & OVERLAYS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get shadowDark => const Color(0x40000000);
//   static Color get shadowLight => const Color(0x10000000);

//   static Color get overlayDark =>
//       isDark ? const Color(0xD909090B) : const Color(0x20000000);

//   static Color get overlayLight =>
//       isDark ? const Color(0x40FFFFFF) : const Color(0xE5FFFFFF);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🌈 GRADIENTS - التدرجات
//   // ═══════════════════════════════════════════════════════════════════════════

//   /// Primary Gradient - تدرج رمادي أنيق
//   static LinearGradient get primaryGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [
//                 Color(0xFF3F3F46),
//                 Color(0xFF52525B),
//                 Color(0xFF3F3F46),
//               ]
//             : const [
//                 Color(0xFF52525B),
//                 Color(0xFF71717A),
//                 Color(0xFF52525B),
//               ],
//         stops: const [0.0, 0.5, 1.0],
//       );

//   /// Dark/Background Gradient
//   static LinearGradient get darkGradient => LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: isDark
//             ? const [
//                 Color(0xFF09090B),
//                 Color(0xFF0F0F11),
//                 Color(0xFF141416),
//               ]
//             : const [
//                 Color(0xFFFAFAFA),
//                 Color(0xFFF5F5F7),
//                 Color(0xFFF0F0F2),
//               ],
//       );

//   /// Card Gradient
//   static LinearGradient get cardGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [
//                 Color(0xFF1F1F23),
//                 Color(0xFF1C1C20),
//                 Color(0xFF18181B),
//               ]
//             : const [
//                 Color(0xFFFFFFFF),
//                 Color(0xFFFDFDFD),
//                 Color(0xFFFAFAFA),
//               ],
//       );

//   /// Metallic Gradient - تدرج معدني
//   static LinearGradient get metallicGradient => LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: isDark
//             ? const [
//                 Color(0xFF71717A),
//                 Color(0xFF52525B),
//                 Color(0xFF71717A),
//                 Color(0xFF52525B),
//               ]
//             : const [
//                 Color(0xFFE4E4E7),
//                 Color(0xFFD4D4D8),
//                 Color(0xFFE4E4E7),
//                 Color(0xFFD4D4D8),
//               ],
//         stops: const [0.0, 0.35, 0.65, 1.0],
//       );

//   /// Luxury Gold Gradient - تدرج ذهبي فاخر
//   static LinearGradient get luxuryGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? [
//                 accentGold.withValues(alpha: 0.25),
//                 accentSilver.withValues(alpha: 0.15),
//                 accentGold.withValues(alpha: 0.25),
//               ]
//             : [
//                 accentGold.withValues(alpha: 0.12),
//                 accentSilver.withValues(alpha: 0.08),
//                 accentGold.withValues(alpha: 0.12),
//               ],
//       );

//   /// Neon Gradient (Subtle Gray)
//   static LinearGradient get neonGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [
//                 Color(0xFF6B7280),
//                 Color(0xFF71717A),
//                 Color(0xFF6B7280),
//               ]
//             : const [
//                 Color(0xFF52525B),
//                 Color(0xFF71717A),
//                 Color(0xFF52525B),
//               ],
//       );

//   /// Glass Gradient
//   static LinearGradient get glassGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [
//                 Color(0x18FFFFFF),
//                 Color(0x0AFFFFFF),
//                 Color(0x14FFFFFF),
//               ]
//             : const [
//                 Color(0x0A27272A),
//                 Color(0x0527272A),
//                 Color(0x0827272A),
//               ],
//       );

//   /// Glow Gradient (Radial)
//   static RadialGradient get glowGradient => RadialGradient(
//         colors: isDark
//             ? [
//                 accentSilver.withValues(alpha: 0.12),
//                 accentSilver.withValues(alpha: 0.05),
//                 Colors.transparent,
//               ]
//             : [
//                 primaryBlue.withValues(alpha: 0.08),
//                 primaryBlue.withValues(alpha: 0.03),
//                 Colors.transparent,
//               ],
//         stops: const [0.0, 0.5, 1.0],
//       );

//   // ─────────────────────────────────────────────────────────────────
//   // 🌈 STATUS GRADIENTS - تدرجات الحالات المضيئة
//   // ─────────────────────────────────────────────────────────────────

//   /// Success Gradient - تدرج النجاح
//   static LinearGradient get successGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFF34D399), Color(0xFF10B981)]
//             : const [Color(0xFF10B981), Color(0xFF059669)],
//       );

//   /// Warning Gradient - تدرج التحذير
//   static LinearGradient get warningGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFFFDE68A), Color(0xFFFBBF24)]
//             : const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
//       );

//   /// Error Gradient - تدرج الخطأ
//   static LinearGradient get errorGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFFFCA5A5), Color(0xFFF87171)]
//             : const [Color(0xFFF87171), Color(0xFFEF4444)],
//       );

//   /// Info Gradient - تدرج المعلومات
//   static LinearGradient get infoGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFF7DD3FC), Color(0xFF38BDF8)]
//             : const [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
//       );

//   /// Purple Gradient - تدرج بنفسجي
//   static LinearGradient get purpleGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFFC4B5FD), Color(0xFFA78BFA)]
//             : const [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
//       );

//   /// Pink Gradient - تدرج وردي
//   static LinearGradient get pinkGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFFF9A8D4), Color(0xFFF472B6)]
//             : const [Color(0xFFF472B6), Color(0xFFEC4899)],
//       );

//   /// Orange Gradient - تدرج برتقالي
//   static LinearGradient get orangeGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFFFDBA74), Color(0xFFFB923C)]
//             : const [Color(0xFFFB923C), Color(0xFFF97316)],
//       );

//   /// Teal Gradient - تدرج تركوازي
//   static LinearGradient get tealGradient => LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? const [Color(0xFF5EEAD4), Color(0xFF2DD4BF)]
//             : const [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
//       );

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🎯 COMPONENT SPECIFIC COLORS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get buttonPrimary =>
//       isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A);

//   static Color get buttonSecondary =>
//       isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7);

//   static Color get inputBackground =>
//       isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);

//   static Color get inputBorder =>
//       isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8);

//   static Color get inputFocusBorder =>
//       isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 💎 SPECIAL EFFECTS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get shimmerBase =>
//       isDark ? const Color(0xFF1F1F23) : const Color(0xFFF0F0F2);

//   static Color get shimmerHighlight =>
//       isDark ? const Color(0xFF2E2E32) : const Color(0xFFE4E4E7);

//   static Color get holographic =>
//       accentSilver.withValues(alpha: isDark ? 0.15 : 0.10);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🔲 BOOKING STATUS - حالات الحجز
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get bookingPending => warning;
//   static Color get bookingPendingBg => warningBg;
//   static Color get bookingConfirmed => success;
//   static Color get bookingConfirmedBg => successBg;
//   static Color get bookingCancelled => error;
//   static Color get bookingCancelledBg => errorBg;
//   static Color get bookingCompleted => info;
//   static Color get bookingCompletedBg => infoBg;

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🔁 BACKWARD COMPATIBILITY
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Color get shadow => shadowDark;
//   static Color get primaryDark =>
//       isDark ? const Color(0xFF09090B) : const Color(0xFF18181B);
//   static const Color transparent = Colors.transparent;
//   static Color get gray200 => lightBorder;
//   static Color get textDisabled => textMuted;
//   static Color get shimmer => shimmerBase;

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 🎨 THEME DATA
//   // ═══════════════════════════════════════════════════════════════════════════

//   static ThemeData get themeData => isDark ? darkThemeData : lightThemeData;

//   static ThemeData get darkThemeData => ThemeData(
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: darkBackground,
//         primaryColor: primaryBlue,
//         colorScheme: ColorScheme.dark(
//           primary: primaryBlue,
//           secondary: accentGold,
//           surface: darkSurface,
//           error: error,
//           onPrimary: const Color(0xFF09090B),
//           onSecondary: const Color(0xFF09090B),
//           onSurface: textWhite,
//           onError: const Color(0xFFFAFAFA),
//         ),
//         cardColor: darkCard,
//         dividerColor: darkBorder,
//         fontFamily: 'Inter',
//       );

//   static ThemeData get lightThemeData => ThemeData(
//         brightness: Brightness.light,
//         scaffoldBackgroundColor: lightBackground,
//         primaryColor: primaryBlue,
//         colorScheme: ColorScheme.light(
//           primary: primaryBlue,
//           secondary: accentGold,
//           surface: lightSurface,
//           error: error,
//           onPrimary: const Color(0xFFFAFAFA),
//           onSecondary: const Color(0xFFFAFAFA),
//           onSurface: textWhite,
//           onError: const Color(0xFFFAFAFA),
//         ),
//         cardColor: lightCard,
//         dividerColor: darkBorder,
//         fontFamily: 'Inter',
//       );
// }
