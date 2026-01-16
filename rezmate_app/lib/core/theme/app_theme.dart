// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

/// 🎨 Unified Theme System - نظام ثيم موحد
/// Updated with Professional Teal/Turquoise Color Scheme
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

  // 🎨 Primary Gradient Colors - ألوان التدرج الرئيسية
  // الأزرق السماوي - يبقى كما هو
  static Color get primaryBlue =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);

  // التركوازي/الفيروزي - بدلاً من البنفسجي
  static Color get primaryPurple =>
      isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488);

  // الأخضر الزمردي - للتدرج
  static Color get primaryViolet =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  // السماوي الفاتح - للتكامل
  static Color get primaryCyan =>
      isDark ? const Color(0xFF22D3EE) : const Color(0xFF06B6D4);

  // 🌟 Neon & Glow Colors - ألوان النيون والتوهج
  static Color get neonBlue =>
      isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0369A1);
  static Color get neonPurple =>
      isDark ? const Color(0xFF2DD4BF) : const Color(0xFF14B8A6);
  static Color get neonGreen =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get glowBlue =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB);
  static Color get glowWhite =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFA);

  // 🌙 Base Colors - الألوان الأساسية
  static Color get darkBackground =>
      isDark ? const Color(0xFF020617) : const Color(0xFFF9FAFB);
  static Color get darkBackground2 =>
      isDark ? const Color(0xFF020617) : const Color(0xFFF3F4F6);
  static Color get darkBackground3 =>
      isDark ? const Color(0xFF020617) : const Color(0xFFE5E7EB);

  static Color get darkSurface =>
      isDark ? const Color(0xFF020617) : const Color(0xFFFFFFFF);
  static Color get darkCard =>
      isDark ? const Color(0xFF020617) : const Color(0xFFFFFFFF);
  static Color get darkBorder =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E5EB);

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
      isDark ? const Color(0xFFF9FAFB) : const Color(0xFF020617);
  static Color get textLight =>
      isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);
  static Color get textMuted =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get textDark =>
      isDark ? const Color(0xFF020617) : const Color(0xFF020617);

  // ✨ Glass & Blur Effects
  static Color get glassDark =>
      isDark ? const Color(0x1A000000) : const Color(0x08000000);
  static Color get glassLight =>
      isDark ? const Color(0x0DFFFFFF) : const Color(0x0F0066CC);
  static Color get glassOverlay =>
      isDark ? const Color(0x80151930) : const Color(0x66FFFFFF);
  static Color get frostedGlass =>
      isDark ? const Color(0x30FFFFFF) : const Color(0x99F9FAFB);

  // 🚦 Status Colors - ألوان الحالات
  static Color get success =>
      isDark ? const Color(0xFF00FF88) : const Color(0xFF059669);
  static Color get warning =>
      isDark ? const Color(0xFFFFB800) : const Color(0xFFF59E0B);
  static Color get error =>
      isDark ? const Color(0xFFFF3366) : const Color(0xFFDC2626);
  static Color get info =>
      isDark ? const Color(0xFF00D4FF) : const Color(0xFF0284C7);

  // 🎭 Shadows & Overlays
  static Color get shadowDark =>
      isDark ? const Color(0x40000000) : const Color(0x0A000000);
  static Color get shadowLight =>
      isDark ? const Color(0x1A4FACFE) : const Color(0x050066CC);
  static Color get overlayDark =>
      isDark ? const Color(0xCC0A0E27) : const Color(0x0A111827);
  static Color get overlayLight =>
      isDark ? const Color(0x99FFFFFF) : const Color(0xE6FFFFFF);

  // 🌈 Gradient Definitions - تعريفات التدرجات
  // التدرج الرئيسي: من السماوي إلى التركوازي إلى الأخضر الزمردي
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryBlue, // الأزرق السماوي
          primaryCyan, // السماوي
          primaryCyan, // السماوي
          primaryPurple, // التركوازي
        ],
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
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.1),
            primaryPurple.withOpacity(0.05),
            primaryViolet.withOpacity(0.1),
          ],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.02),
            primaryPurple.withOpacity(0.015),
            primaryViolet.withOpacity(0.02),
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
      ? RadialGradient(
          colors: [
            primaryBlue.withOpacity(0.5),
            primaryPurple.withOpacity(0.25),
            Colors.transparent,
          ],
        )
      : RadialGradient(
          colors: [
            primaryBlue.withOpacity(0.1),
            primaryPurple.withOpacity(0.05),
            Colors.transparent,
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
