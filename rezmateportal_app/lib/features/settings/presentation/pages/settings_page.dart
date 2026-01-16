import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_item_widget.dart';
import '../widgets/theme_selector_widget.dart';
import '../../domain/entities/app_settings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late AnimationController _itemAnimationController;
  late AnimationController _glowAnimationController;

  @override
  void initState() {
    super.initState();

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _itemAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _itemAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          CustomScrollView(
            slivers: [
              _buildFuturisticAppBar(),
              SliverToBoxAdapter(
                child: BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    if (state is SettingsLoading) {
                      return const SizedBox(
                        height: 400,
                        child: LoadingWidget(
                          type: LoadingType.circular,
                        ),
                      );
                    }

                    if (state is SettingsError) {
                      return SizedBox(
                        height: 400,
                        child: CustomErrorWidget(
                          message: state.message,
                          onRetry: () {
                            context
                                .read<SettingsBloc>()
                                .add(LoadSettingsEvent());
                          },
                        ),
                      );
                    }

                    if (state is SettingsLoaded ||
                        state is SettingsUpdated ||
                        state is SettingsUpdating) {
                      final settings = (state is SettingsLoaded)
                          ? state.settings
                          : (state is SettingsUpdated)
                              ? state.settings
                              : (state as SettingsUpdating).currentSettings;

                      return _buildFuturisticContent(settings);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_backgroundAnimationController.value * 2 * math.pi),
                math.sin(_backgroundAnimationController.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.cos(_backgroundAnimationController.value * 2 * math.pi),
                -math.sin(_backgroundAnimationController.value * 2 * math.pi),
              ),
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SettingsBackgroundPainter(
              animationValue: _glowAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withOpacity(0.3),
                AppTheme.primaryBlue.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppTheme.darkCard.withOpacity(0.3),
                child: Stack(
                  children: [
                    // Animated Lines
                    CustomPaint(
                      painter: _GridPatternPainter(
                        animationValue: _glowAnimationController.value,
                      ),
                      size: Size.infinite,
                    ),
                    // Title
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Icon(
                                Icons.settings_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                'الإعدادات',
                                style: AppTextStyles.heading1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textWhite,
            size: 18,
          ),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildFuturisticContent(AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Account Section
          _buildFuturisticSection(
            title: 'الحساب',
            icon: Icons.account_circle_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
            ),
            items: [
              FuturisticSettingsItem(
                icon: Icons.person_outline_rounded,
                title: 'الملف الشخصي',
                subtitle: 'تعديل معلوماتك الشخصية',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
                ),
                onTap: () => context.push('/profile'),
              ),
              FuturisticSettingsItem(
                icon: Icons.lock_outline_rounded,
                title: 'كلمة المرور',
                subtitle: 'تغيير كلمة المرور',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
                ),
                onTap: () => context.push('/profile/change-password'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Preferences Section
          _buildFuturisticSection(
            title: 'التفضيلات',
            icon: Icons.tune_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
            ),
            items: [
              FuturisticSettingsItem(
                icon: Icons.language_rounded,
                title: 'اللغة',
                subtitle:
                    settings.preferredLanguage == 'ar' ? 'العربية' : 'English',
                gradient: LinearGradient(
                  colors: [AppTheme.neonBlue, AppTheme.primaryCyan],
                ),
                onTap: () => context.push('/settings/language'),
              ),
              FuturisticSettingsItem(
                icon: Icons.dark_mode_rounded,
                title: 'المظهر',
                subtitle: settings.darkMode ? 'الوضع الليلي' : 'الوضع النهاري',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryViolet, AppTheme.neonPurple],
                ),
                trailing: FuturisticThemeToggle(
                  isDarkMode: settings.darkMode,
                  onChanged: (isDark) {
                    context.read<SettingsBloc>().add(UpdateThemeEvent(isDark));
                  },
                ),
              ),
              FuturisticSettingsItem(
                icon: Icons.fingerprint_rounded,
                title: 'بصمة الإصبع',
                subtitle: settings.biometricEnabled
                    ? 'مفعّل لتسجيل الدخول'
                    : 'غير مفعّل',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.neonPurple],
                ),
                trailing: FuturisticSettingsToggle(
                  icon: Icons.fingerprint_rounded,
                  title: 'بصمة الإصبع',
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.neonPurple],
                  ),
                  value: settings.biometricEnabled,
                  onChanged: (v) {
                    context.read<SettingsBloc>().add(UpdateBiometricEvent(v));
                  },
                ),
              ),
              FuturisticSettingsItem(
                icon: Icons.attach_money_rounded,
                title: 'العملة',
                subtitle: _getCurrencyName(settings.preferredCurrency),
                gradient: LinearGradient(
                  colors: [AppTheme.success, AppTheme.neonGreen],
                ),
                onTap: () => _showFuturisticCurrencySelector(
                    context, settings.preferredCurrency),
              ),
              FuturisticSettingsItem(
                icon: Icons.notifications_active_rounded,
                title: 'الإشعارات',
                subtitle: 'إدارة إعدادات الإشعارات',
                gradient: LinearGradient(
                  colors: [AppTheme.warning, Colors.orange],
                ),
                onTap: () => context.push('/notifications/settings'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildFuturisticSection(
            title: 'الدعم والمساعدة',
            icon: Icons.support_agent_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.info, AppTheme.neonBlue],
            ),
            items: [
              FuturisticSettingsItem(
                icon: Icons.help_outline_rounded,
                title: 'مركز المساعدة',
                subtitle: 'الأسئلة الشائعة والدعم',
                gradient: LinearGradient(
                  colors: [AppTheme.info, AppTheme.primaryBlue],
                ),
                onTap: () => context.push('/help'),
              ),
              FuturisticSettingsItem(
                icon: Icons.privacy_tip_rounded,
                title: 'سياسة الخصوصية',
                subtitle: 'اقرأ سياسة الخصوصية',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryCyan, AppTheme.neonBlue],
                ),
                onTap: () => context.push('/settings/privacy-policy'),
              ),
              FuturisticSettingsItem(
                icon: Icons.description_rounded,
                title: 'الشروط والأحكام',
                subtitle: 'اقرأ الشروط والأحكام',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                ),
                onTap: () => context.push('/terms'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildFuturisticSection(
            title: 'حول',
            icon: Icons.info_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.primaryViolet, AppTheme.neonPurple],
            ),
            items: [
              FuturisticSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'عن التطبيق',
                subtitle: 'معلومات حول التطبيق',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryViolet, AppTheme.neonPurple],
                ),
                onTap: () => context.push('/settings/about'),
              ),
              FuturisticSettingsItem(
                icon: Icons.star_rounded,
                title: 'قيم التطبيق',
                subtitle: 'شاركنا رأيك',
                gradient: LinearGradient(
                  colors: [Colors.orange, AppTheme.warning],
                ),
                onTap: () => _rateApp(),
              ),
              FuturisticSettingsItem(
                icon: Icons.share_rounded,
                title: 'شارك التطبيق',
                subtitle: 'شارك التطبيق مع أصدقائك',
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.info],
                ),
                onTap: () => _shareApp(),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Delete Account Button (Owner only, not Admin)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated &&
                  authState.user.isOwner &&
                  !authState.user.isAdmin) {
                return Column(
                  children: [
                    _buildFuturisticDeleteAccountButton(context),
                    const SizedBox(height: 20),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Logout Button
          _buildFuturisticLogoutButton(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFuturisticSection({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required List<Widget> items,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: gradient.colors[0].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: gradient.scale(0.3),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Items
                      ...items,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFuturisticLogoutDialog(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.8),
              AppTheme.error.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showFuturisticLogoutDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'تسجيل الخروج',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFuturisticLogoutDialog(BuildContext context) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: AppTheme.darkCard.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)],
              ).createShader(bounds),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: Text(
              'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      context.go('/login');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticDeleteAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade900.withOpacity(0.8),
              Colors.red.shade800.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade900.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.red.shade700.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDeleteAccountDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'حذف الحساب نهائياً',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return _DeleteOwnerAccountDialog(
          onConfirm: (password, reason) {
            context.read<AuthBloc>().add(
                  DeleteOwnerAccountEvent(
                    password: password,
                    reason: reason,
                  ),
                );
          },
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'تم حذف الحساب بنجاح',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            context.go('/login');
          },
        );
      },
    );
  }

  void _showFuturisticCurrencySelector(
      BuildContext context, String currentCurrency) {
    // Implementation similar to logout dialog
  }

  String _getCurrencyName(String code) {
    switch (code) {
      case 'YER':
        return 'الريال اليمني';
      case 'USD':
        return 'الدولار الأمريكي';
      case 'SAR':
        return 'الريال السعودي';
      case 'EUR':
        return 'اليورو';
      default:
        return code;
    }
  }

  void _rateApp() {
    // TODO: Implement app rating
  }

  void _shareApp() {
    // TODO: Implement app sharing
  }
}

// Background Painter
class _SettingsBackgroundPainter extends CustomPainter {
  final double animationValue;

  _SettingsBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating hexagons
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        size.width * (0.2 + i * 0.2),
        size.height * (0.3 + animationValue * 0.1 + i * 0.1),
      );

      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryPurple.withOpacity(0.05 + animationValue * 0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: offset, radius: 100));

      _drawHexagon(canvas, offset, 50 + i * 10, paint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final double animationValue;

  _GridPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw grid lines
    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppTheme.primaryBlue.withOpacity(0.1 + animationValue * 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, 0, 1, size.height));

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      paint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppTheme.primaryPurple.withOpacity(0.1 + animationValue * 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 1));

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ديالوج حذف حساب المالك
class _DeleteOwnerAccountDialog extends StatefulWidget {
  final void Function(String password, String? reason) onConfirm;
  final VoidCallback onSuccess;

  const _DeleteOwnerAccountDialog({
    required this.onConfirm,
    required this.onSuccess,
  });

  @override
  State<_DeleteOwnerAccountDialog> createState() =>
      _DeleteOwnerAccountDialogState();
}

class _DeleteOwnerAccountDialogState extends State<_DeleteOwnerAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAccountDeleteSuccess) {
          Navigator.of(context).pop();
          widget.onSuccess();
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppTheme.darkCard.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.red.shade900.withOpacity(0.5),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade900,
                      Colors.red.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'حذف الحساب نهائياً',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade700.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '⚠️ تحذير: هذا الإجراء لا يمكن التراجع عنه!\n\n'
                    '• سيتم تعطيل جميع عقاراتك ووحداتك\n'
                    '• لن تتمكن من استقبال حجوزات جديدة\n'
                    '• سيتم حفظ الحجوزات الحالية حتى اكتمالها',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.red.shade300,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade700.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange.shade300, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'كلمة المرور (مطلوب)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'أدخل كلمة المرور للتأكيد',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'سبب الحذف (اختياري)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'أخبرنا لماذا تريد حذف حسابك...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.comment_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: _isLoading ? AppTheme.textMuted : Colors.white70,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey, Colors.grey.shade700]
                      : [Colors.red.shade900, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () {
                          if (_passwordController.text.isEmpty) {
                            setState(() {
                              _errorMessage = 'كلمة المرور مطلوبة';
                            });
                            return;
                          }
                          widget.onConfirm(
                            _passwordController.text,
                            _reasonController.text.isNotEmpty
                                ? _reasonController.text
                                : null,
                          );
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'حذف الحساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
