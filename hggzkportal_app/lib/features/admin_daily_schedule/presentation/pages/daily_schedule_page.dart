// lib/features/admin_daily_schedule/presentation/pages/daily_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'package:intl/intl.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../../admin_units/domain/entities/unit.dart';
import '../bloc/daily_schedule_barrel.dart';
import '../../domain/entities/daily_schedule.dart';
import '../../domain/entities/monthly_schedule.dart';
import '../../domain/usecases/delete_schedule.dart';
import '../widgets/widgets_barrel.dart';

/// صفحة الجدول اليومي الموحد للإتاحة والتسعير
///
/// توفر واجهة شاملة لإدارة الإتاحة والتسعير في مكان واحد
/// مع دعم العمليات المتقدمة مثل:
/// - التحديث الفردي واليومي
/// - التحديث الجماعي
/// - نسخ الجداول
/// - التحقق من التوفر
/// - حساب الأسعار
class DailySchedulePage extends StatefulWidget {
  /// ✅ معرف الوحدة الاختياري للتحديد المسبق
  final String? initialUnitId;

  /// ✅ اسم الوحدة الاختياري للعرض
  final String? initialUnitName;

  const DailySchedulePage({
    super.key,
    this.initialUnitId,
    this.initialUnitName,
  });

  @override
  State<DailySchedulePage> createState() => _DailySchedulePageState();
}

class _DailySchedulePageState extends State<DailySchedulePage>
    with TickerProviderStateMixin {
  // ===== Animation Controllers =====
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _contentAnimationController;

  // ===== Animations =====
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // ===== State Variables =====
  String? _selectedUnitId;
  String? _selectedUnitName;
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  DateTime _currentDate = DateTime.now();

  /// نطاق الاختيار الحالي (للتحديثات الجماعية)
  DateTime? _selectionStart;
  DateTime? _selectionEnd;

  /// حالة التصفية الحالية
  ScheduleStatus? _currentFilter;

  /// آخر جدول شهري محمّل (للاستخدام في التحقق من الأيام المحجوزة)
  MonthlySchedule? _currentMonthlySchedule;

  /// Particles for background animation
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    // ✅ تهيئة القيم المبدئية من الـ widget
    if (widget.initialUnitId != null) {
      _selectedUnitId = widget.initialUnitId;
      _selectedUnitName = widget.initialUnitName;
    }
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }

  /// تهيئة الأنيميشن
  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ));
  }

  /// إنشاء الجزيئات للخلفية
  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle());
    }
  }

  /// بدء الأنيميشن
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppDimensions.desktopBreakpoint;
    final isTablet = size.width > AppDimensions.tabletBreakpoint;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // الخلفية المتحركة
          _buildAnimatedBackground(),

          // الجزيئات
          _buildParticles(),

          // المحتوى الرئيسي
          _buildMainContent(isDesktop, isTablet),
        ],
      ),
      // floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// عرض حوار خطأ خاص بالجدول اليومي
  void _showScheduleErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تعذر تنفيذ العملية',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// عرض ديالوج يوضح معاني ألوان التقويم
  void _showLegendDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'دليل ألوان التقويم',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'الألوان تساعدك على فهم حالة كل يوم وسعره بسرعة:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                // حالات الأيام
                Text(
                  'حالة اليوم (لون الخلفية والدائرة الأولى):',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendRow(
                  color: AppTheme.success,
                  icon: Icons.check_circle_rounded,
                  title: 'متاح',
                  description: 'اليوم متاح للحجز ويمكن تعديل الإتاحة والتسعير.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.warning,
                  icon: Icons.event_busy_rounded,
                  title: 'محجوز',
                  description:
                      'يوجد حجز فعّال في هذا اليوم، لا يمكن تعديل الإتاحة أو التسعير.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.error,
                  icon: Icons.block_rounded,
                  title: 'محجوب',
                  description: 'اليوم محجوب من التقويم (إغلاق يدوي أو صيانة).',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.info,
                  icon: Icons.build_rounded,
                  title: 'صيانة',
                  description:
                      'اليوم مخصص لأعمال الصيانة ولا يظهر كمتاح للحجز.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.primaryPurple,
                  icon: Icons.person_rounded,
                  title: 'استخدام المالك',
                  description:
                      'اليوم محجوز لصاحب العقار ولا يظهر في نتائج البحث للزوار.',
                ),
                const SizedBox(height: 16),
                // مؤشرات التسعير
                Text(
                  'التسعير (النص أو الدائرة الثانية):',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendRow(
                  color: AppTheme.success,
                  title: 'سعر عادي',
                  description: 'السعر ضمن الشريحة العادية للوحدة.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.warning,
                  title: 'سعر مرتفع',
                  description: 'سعر أعلى من المعتاد (مثل نهاية الأسبوع).',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.error,
                  title: 'ذروة/مواسم',
                  description: 'سعر مرتفع في مواسم أو أعياد أو طلب عالٍ.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.info,
                  title: 'خصم/عرض',
                  description: 'سعر مخفّض أو عرض ترويجي.',
                ),
                const SizedBox(height: 6),
                _buildLegendRow(
                  color: AppTheme.primaryPurple,
                  title: 'تسعير مخصص',
                  description: 'سعر خاص لهذا اليوم فقط (Custom).',
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('فهمت'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== UI Building Methods =====

  /// بناء الخلفية المتحركة
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _backgroundRotation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  /// بناء الجزيئات
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  /// بناء المحتوى الرئيسي
  Widget _buildMainContent(bool isDesktop, bool isTablet) {
    return SafeArea(
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: SlideTransition(
          position: _contentSlideAnimation,
          child: BlocConsumer<DailyScheduleBloc, DailyScheduleState>(
            listener: (context, state) {
              _handleStateChanges(context, state);
            },
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  children: [
                    // الهيدر
                    _buildHeader(state),
                    const SizedBox(height: 20),

                    // المحتوى الرئيسي
                    Expanded(
                      child:
                          _buildStateBasedContent(state, isDesktop, isTablet),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// بناء الهيدر
  Widget _buildHeader(DailyScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان وأيقونة المساعدة
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'الجدول اليومي للوحدة',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderIconButton(
                    icon: Icons.help_outline_rounded,
                    tooltip: 'شرح ألوان التقويم',
                    onTap: _showLegendDialog,
                    color: AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // الإحصائيات السريعة
              if (state is DailyScheduleLoaded) _buildQuickStats(state),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء زر في الهيدر
  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withOpacity(0.6),
                AppTheme.darkSurface.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (color ?? AppTheme.primaryBlue).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }

  /// عنصر مساعد لصف في ديالوج شرح الألوان
  Widget _buildLegendRow({
    required Color color,
    IconData? icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء الإحصائيات السريعة
  Widget _buildQuickStats(DailyScheduleLoaded state) {
    final stats = state.monthlySchedule.statistics;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.check_circle_rounded,
            value: '${stats['availableDays'] ?? 0}',
            label: 'متاح',
            color: AppTheme.success,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.event_busy_rounded,
            value: '${stats['bookedDays'] ?? 0}',
            label: 'محجوز',
            color: AppTheme.warning,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.block_rounded,
            value: '${stats['blockedDays'] ?? 0}',
            label: 'محظور',
            color: AppTheme.error,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.build_rounded,
            value: '${stats['maintenanceDays'] ?? 0}',
            label: 'صيانة',
            color: AppTheme.info,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.show_chart_rounded,
            value: _formatMoney(
                stats['averagePrice'] ?? 0.0,
                state.monthlySchedule.schedules.firstOrNull?.displayCurrency ??
                    'YER'),
            label: 'متوسط السعر',
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.payments_rounded,
            value: _formatMoney(
                stats['totalRevenue'] ?? 0.0,
                state.monthlySchedule.schedules.firstOrNull?.displayCurrency ??
                    'YER'),
            label: 'العائد المتوقع',
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  /// بناء شريحة إحصائية
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء المحتوى بناءً على الحالة
  Widget _buildStateBasedContent(
    DailyScheduleState state,
    bool isDesktop,
    bool isTablet,
  ) {
    // Debug: تتبع نوع الحالة في صفحة الجدول
    // ignore: avoid_print
    print('[DailySchedulePage] state runtimeType = ' '${state.runtimeType}');
    if (state is DailyScheduleInitial) {
      return _buildInitialState();
    } else if (state is DailyScheduleLoading) {
      return _buildLoadingState(state.loadingMessage);
    } else if (state is DailyScheduleLoaded) {
      // ignore: avoid_print
      print('[DailySchedulePage] DailyScheduleLoaded with '
          '${state.monthlySchedule.schedules.length} days');
      return isDesktop
          ? _buildDesktopLayout(state)
          : _buildMobileLayout(state, isTablet);
    } else if (state is DailyScheduleUpdating) {
      return _buildUpdatingState(state);
    } else if (state is DailyScheduleError) {
      if (state.lastSchedule != null) {
        final fallbackState = DailyScheduleLoaded(
          monthlySchedule: state.lastSchedule!,
          selectedUnitId: _selectedUnitId,
          currentYear: _currentDate.year,
          currentMonth: _currentDate.month,
          currentFilter: _currentFilter,
        );

        return isDesktop
            ? _buildDesktopLayout(fallbackState)
            : _buildMobileLayout(fallbackState, isTablet);
      }
      return _buildErrorState(state);
    }

    return _buildInitialState();
  }

  /// بناء الحالة الأولية
  Widget _buildInitialState() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppDimensions.desktopBreakpoint;

    return Column(
      children: [
        if (isDesktop) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    RealPropertySelectorCard(
                      selectedPropertyId: _selectedPropertyId,
                      selectedPropertyName: _selectedPropertyName,
                      onPropertySelected: (id, name) {
                        setState(() {
                          _selectedPropertyId = id;
                          _selectedPropertyName = name;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    RealUnitSelectorCard(
                      selectedUnitId: _selectedUnitId,
                      selectedUnitName: _selectedUnitName,
                      selectedPropertyId: _selectedPropertyId,
                      onUnitSelected: (id, name) {
                        setState(() {
                          _selectedUnitId = id;
                          _selectedUnitName = name;
                        });
                        context.read<DailyScheduleBloc>().add(
                              LoadMonthlyScheduleEvent(
                                unitId: id,
                                year: _currentDate.year,
                                month: _currentDate.month,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 80,
                        color: AppTheme.primaryBlue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'اختر عقاراً ووحدة لعرض الجدول',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يمكنك إدارة الإتاحة والتسعير من هنا',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          RealPropertySelectorCard(
            selectedPropertyId: _selectedPropertyId,
            selectedPropertyName: _selectedPropertyName,
            onPropertySelected: (id, name) {
              setState(() {
                _selectedPropertyId = id;
                _selectedPropertyName = name;
              });
            },
            isCompact: true,
          ),
          const SizedBox(height: 8),
          RealUnitSelectorCard(
            selectedUnitId: _selectedUnitId,
            selectedUnitName: _selectedUnitName,
            selectedPropertyId: _selectedPropertyId,
            onUnitSelected: (id, name) {
              setState(() {
                _selectedUnitId = id;
                _selectedUnitName = name;
              });
              context.read<DailyScheduleBloc>().add(
                    LoadMonthlyScheduleEvent(
                      unitId: id,
                      year: _currentDate.year,
                      month: _currentDate.month,
                    ),
                  );
            },
            isCompact: true,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 80,
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'اختر عقاراً ووحدة لعرض الجدول',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'يمكنك إدارة الإتاحة والتسعير من هنا',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء حالة التحديث
  Widget _buildUpdatingState(DailyScheduleUpdating state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            state.updatingMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة الخطأ
  Widget _buildErrorState(DailyScheduleError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'حدث خطأ',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.errorMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DailyScheduleBloc>().add(const ResetErrorEvent());
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تخطيط سطح المكتب
  Widget _buildDesktopLayout(DailyScheduleLoaded state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الشريط الجانبي الأيسر
        SizedBox(
          width: 320,
          child: Column(
            children: [
              // اختيار العقار
              RealPropertySelectorCard(
                selectedPropertyId: _selectedPropertyId,
                selectedPropertyName: _selectedPropertyName,
                onPropertySelected: (id, name) {
                  setState(() {
                    _selectedPropertyId = id;
                    _selectedPropertyName = name;
                  });
                },
              ),
              const SizedBox(height: 12),

              // اختيار الوحدة
              RealUnitSelectorCard(
                selectedUnitId: _selectedUnitId,
                selectedUnitName: _selectedUnitName,
                selectedPropertyId: _selectedPropertyId,
                onUnitSelected: (id, name) {
                  setState(() {
                    _selectedUnitId = id;
                    _selectedUnitName = name;
                  });
                  context.read<DailyScheduleBloc>().add(
                        LoadMonthlyScheduleEvent(
                          unitId: id,
                          year: _currentDate.year,
                          month: _currentDate.month,
                        ),
                      );
                },
              ),
              const SizedBox(height: 16),

              // لوحة التحكم بالإحصائيات
              Expanded(
                child: StatsDashboardCard(
                  schedules: state.monthlySchedule.schedules,
                  currency: state.monthlySchedule.schedules.firstOrNull
                          ?.displayCurrency ??
                      'YER',
                ),
              ),
              const SizedBox(height: 16),

              // لوحة الإجراءات السريعة
              QuickActionsPanel(
                onActionTap: _handleQuickAction,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // منطقة التقويم الرئيسية
        Expanded(
          child: Column(
            children: [
              // شريط التنقل بين الأشهر
              _buildMonthNavigationBar(),
              const SizedBox(height: 16),

              // عرض التقويم الموحد
              Expanded(
                child: UnifiedScheduleCalendar(
                  monthlySchedule: state.monthlySchedule,
                  currentDate: _currentDate,
                  onMonthChanged: (newDate) {
                    setState(() => _currentDate = newDate);
                    if (_selectedUnitId != null) {
                      context.read<DailyScheduleBloc>().add(
                            ChangeMonthEvent(
                              year: newDate.year,
                              month: newDate.month,
                            ),
                          );
                    }
                  },
                  onDayTap: (date, schedule) => _handleDayTap(date, schedule),
                  selectionStart: _selectionStart,
                  selectionEnd: _selectionEnd,
                  onSelectionChanged: (start, end) {
                    setState(() {
                      _selectionStart = start;
                      _selectionEnd = end;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء تخطيط الموبايل
  Widget _buildMobileLayout(DailyScheduleLoaded state, bool isTablet) {
    return Column(
      children: [
        // اختيار العقار (مضغوط)
        RealPropertySelectorCard(
          selectedPropertyId: _selectedPropertyId,
          selectedPropertyName: _selectedPropertyName,
          onPropertySelected: (id, name) {
            setState(() {
              _selectedPropertyId = id;
              _selectedPropertyName = name;
            });
          },
          isCompact: true,
        ),
        const SizedBox(height: 8),

        // اختيار الوحدة (مضغوط)
        RealUnitSelectorCard(
          selectedUnitId: _selectedUnitId,
          selectedUnitName: _selectedUnitName,
          selectedPropertyId: _selectedPropertyId,
          onUnitSelected: (id, name) {
            setState(() {
              _selectedUnitId = id;
              _selectedUnitName = name;
            });
            context.read<DailyScheduleBloc>().add(
                  LoadMonthlyScheduleEvent(
                    unitId: id,
                    year: _currentDate.year,
                    month: _currentDate.month,
                  ),
                );
          },
          isCompact: true,
        ),
        const SizedBox(height: 12),

        // شريط التنقل بين الأشهر
        _buildMonthNavigationBar(),
        const SizedBox(height: 12),

        // عرض التقويم
        Expanded(
          child: UnifiedScheduleCalendar(
            monthlySchedule: state.monthlySchedule,
            currentDate: _currentDate,
            onMonthChanged: (newDate) {
              setState(() => _currentDate = newDate);
              if (_selectedUnitId != null) {
                context.read<DailyScheduleBloc>().add(
                      ChangeMonthEvent(
                        year: newDate.year,
                        month: newDate.month,
                      ),
                    );
              }
            },
            onDayTap: (date, schedule) => _handleDayTap(date, schedule),
            isCompact: !isTablet,
          ),
        ),

        const SizedBox(height: 12),

        // لوحة الإجراءات السريعة (أفقي)
        SizedBox(
          height: 60,
          child: QuickActionsPanel(
            onActionTap: _handleQuickAction,
            isHorizontal: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الشهر السابق
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.textWhite,
          ),

          // عرض الشهر الحالي
          Text(
            _formatMonthYear(_currentDate),
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),

          // زر الشهر التالي
          IconButton(
            onPressed: _goToNextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.textWhite,
          ),
        ],
      ),
    );
  }

  /// بناء زر الإجراءات العائم
  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActionsMenu,
      icon: const Icon(Icons.flash_on_rounded),
      label: const Text('إجراءات سريعة'),
      backgroundColor: AppTheme.primaryBlue,
      focusColor: AppTheme.textWhite.withOpacity(0.1),
      extendedTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.textWhite,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ===== Event Handlers =====

  /// معالجة تغيرات الحالة
  void _handleStateChanges(BuildContext context, DailyScheduleState state) {
    if (state is DailyScheduleLoaded) {
      _currentMonthlySchedule = state.monthlySchedule;
    }

    if (state is DailyScheduleUpdateSuccess) {
      _showSuccessSnackbar(state.successMessage);
      // إعادة تحميل الجدول
      if (_selectedUnitId != null) {
        context.read<DailyScheduleBloc>().add(
              LoadMonthlyScheduleEvent(
                unitId: _selectedUnitId!,
                year: _currentDate.year,
                month: _currentDate.month,
              ),
            );
      }
    } else if (state is DailyScheduleError) {
      _showScheduleErrorDialog(state.errorMessage);
    }
  }

  /// معالجة النقر على يوم في التقويم
  void _handleDayTap(DateTime date, DailySchedule? schedule) {
    HapticFeedback.mediumImpact();
    if (schedule != null) {
      if (schedule.isBooked) {
        _showScheduleErrorDialog(
          'لا يمكن تعديل هذا اليوم لأنه محجوز. يرجى إلغاء الحجز أولاً قبل تعديل الإتاحة أو التسعير.',
        );
        return;
      }
      showDialog(
        context: context,
        builder: (context) => DayDetailsDialog(
          schedule: schedule,
          onSave: (updatedSchedule) {
            context.read<DailyScheduleBloc>().add(
                  UpdateSingleDayEvent(
                    unitId: updatedSchedule.unitId,
                    date: updatedSchedule.date,
                    status: updatedSchedule.status,
                    priceAmount: updatedSchedule.priceAmount,
                    currency: updatedSchedule.currency,
                    priceType: updatedSchedule.priceType,
                    pricingTier: updatedSchedule.pricingTier,
                    reason: updatedSchedule.reason,
                    notes: updatedSchedule.notes,
                    overwriteExisting: true,
                  ),
                );
            Navigator.pop(context);
          },
          onDelete: () {
            context.read<DailyScheduleBloc>().add(
                  DeleteScheduleEvent(
                    params: DeleteScheduleParams(
                      unitId: _selectedUnitId!,
                      startDate: date,
                      endDate: date,
                      forceDelete: true,
                    ),
                  ),
                );
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  /// معالجة الإجراءات السريعة
  void _handleQuickAction(QuickAction action) {
    HapticFeedback.mediumImpact();
    switch (action) {
      case QuickAction.bulkUpdate:
        _showBulkUpdateDialog();
        break;
      case QuickAction.cloneSchedule:
        _showCloneScheduleDialog();
        break;
      case QuickAction.clearSelection:
        setState(() {
          _selectionStart = null;
          _selectionEnd = null;
        });
        break;
      case QuickAction.smartSelection:
        _performSmartSelection();
        break;
    }
  }

  /// الانتقال للشهر السابق
  void _goToPreviousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      _selectionStart = null;
      _selectionEnd = null;
    });

    if (_selectedUnitId != null) {
      context.read<DailyScheduleBloc>().add(
            ChangeMonthEvent(
              year: _currentDate.year,
              month: _currentDate.month,
            ),
          );
    }
  }

  /// الانتقال للشهر التالي
  void _goToNextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
      _selectionStart = null;
      _selectionEnd = null;
    });

    if (_selectedUnitId != null) {
      context.read<DailyScheduleBloc>().add(
            ChangeMonthEvent(
              year: _currentDate.year,
              month: _currentDate.month,
            ),
          );
    }
  }

  // ===== Dialog Methods =====

  /// عرض مربع حوار الفلاتر
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentFilter: _currentFilter,
        onApplyFilter: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          context.read<DailyScheduleBloc>().add(
                FilterScheduleEvent(filterStatus: filter),
              );
        },
      ),
    );
  }

  /// عرض مربع حوار الإعدادات
  void _showSettingsDialog() {
    final currentSettings = <String, dynamic>{
      'showWeekends': true,
      'highlightToday': true,
      'showPrices': true,
      'showStatistics': true,
      'autoRefresh': false,
      'compactMode': false,
      'defaultCurrency': 'YER',
      'dateFormat': 'yyyy-MM-dd',
    };

    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentSettings: currentSettings,
        onSaveSettings: (settings) {
          _showSuccessSnackbar('تم حفظ الإعدادات بنجاح');
        },
      ),
    );
  }

  /// عرض قائمة الإجراءات السريعة
  void _showQuickActionsMenu() {
    HapticFeedback.mediumImpact();

    if (_selectedUnitId == null) {
      _showErrorSnackbar('يرجى اختيار وحدة أولاً');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionsBottomSheet(),
    );
  }

  /// بناء قائمة الإجراءات السريعة
  Widget _buildQuickActionsBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'الإجراءات السريعة',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionTile(
            icon: Icons.update_rounded,
            title: 'التحديث الجماعي',
            subtitle: 'تحديث عدة أيام دفعة واحدة',
            onTap: () {
              Navigator.pop(context);
              _showBulkUpdateDialog();
            },
          ),
          _buildQuickActionTile(
            icon: Icons.copy_rounded,
            title: 'نسخ الجدول',
            subtitle: 'نسخ جدول من فترة إلى أخرى',
            onTap: () {
              Navigator.pop(context);
              _showCloneScheduleDialog();
            },
          ),
          _buildQuickActionTile(
            icon: Icons.search_rounded,
            title: 'التحقق من التوفر',
            subtitle: 'فحص توفر الوحدة لفترة محددة',
            onTap: () {
              Navigator.pop(context);
              _showCheckAvailabilityDialog();
            },
          ),
          _buildQuickActionTile(
            icon: Icons.calculate_rounded,
            title: 'حساب السعر الإجمالي',
            subtitle: 'احسب السعر لفترة محددة',
            onTap: () {
              Navigator.pop(context);
              _showCalculatePriceDialog();
            },
          ),
        ],
      ),
    );
  }

  /// بناء عنصر في قائمة الإجراءات السريعة
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textMuted,
        ),
      ),
      onTap: onTap,
    );
  }

  /// عرض مربع حوار التحديث الجماعي
  void _showBulkUpdateDialog() {
    if (_selectedUnitId == null) {
      _showErrorSnackbar('الرجاء اختيار وحدة أولاً');
      return;
    }
    // تمرير نفس الـ Bloc المستخدم في الصفحة إلى الحوار لتفادي ProviderNotFoundError
    final bloc = context.read<DailyScheduleBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (innerContext) {
              return BulkUpdateDialog(
                unitId: _selectedUnitId!,
                initialStartDate: _selectionStart ?? _currentDate,
                initialEndDate: _selectionEnd ?? _currentDate,
                currencyCode: 'YER',
                onSave: (params) {
                  innerContext.read<DailyScheduleBloc>().add(
                        BulkUpdateScheduleEvent(params: params),
                      );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// عرض مربع حوار نسخ الجدول
  void _showCloneScheduleDialog() {
    if (_selectedUnitId == null) {
      _showErrorSnackbar('الرجاء اختيار وحدة أولاً');
      return;
    }

    // تمرير نفس الـ Bloc المستخدم في الصفحة إلى الحوار لتفادي ProviderNotFoundError
    final bloc = context.read<DailyScheduleBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: Builder(
          builder: (innerContext) {
            return CloneScheduleDialog(
              unitId: _selectedUnitId!,
              initialSourceStart: _selectionStart,
              initialSourceEnd: _selectionEnd,
              onSave: (params) {
                innerContext.read<DailyScheduleBloc>().add(
                      CloneScheduleEvent(params: params),
                    );
                setState(() {
                  _selectionStart = null;
                  _selectionEnd = null;
                });
              },
            );
          },
        ),
      ),
    );
  }

  /// عرض مربع حوار التحقق من التوفر
  void _showCheckAvailabilityDialog() {
    if (_selectedUnitId == null) {
      _showErrorSnackbar('الرجاء اختيار وحدة أولاً');
      return;
    }

    final bloc = context.read<DailyScheduleBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: CheckAvailabilityDialog(
          unitId: _selectedUnitId!,
          initialStartDate: _selectionStart,
          initialEndDate: _selectionEnd,
        ),
      ),
    );
  }

  /// عرض مربع حوار حساب السعر الإجمالي
  void _showCalculatePriceDialog() {
    if (_selectedUnitId == null) {
      _showErrorSnackbar('الرجاء اختيار وحدة أولاً');
      return;
    }

    final bloc = context.read<DailyScheduleBloc>();
    final state = bloc.state;
    String currency = 'YER';

    if (state is DailyScheduleLoaded) {
      currency =
          state.monthlySchedule.schedules.firstOrNull?.displayCurrency ?? 'YER';
    }

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: CalculatePriceDialog(
          unitId: _selectedUnitId!,
          initialStartDate: _selectionStart,
          initialEndDate: _selectionEnd,
          currencyCode: currency,
        ),
      ),
    );
  }

  /// التحديد الذكي - يقوم بتحديد أيام بناءً على معايير ذكية
  void _performSmartSelection() {
    if (_selectedUnitId == null) {
      _showErrorSnackbar('الرجاء اختيار وحدة أولاً');
      return;
    }

    final bloc = context.read<DailyScheduleBloc>();
    final state = bloc.state;

    if (state is! DailyScheduleLoaded) {
      _showErrorSnackbar('الرجاء تحميل الجدول أولاً');
      return;
    }

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple),
              const SizedBox(width: 12),
              Text(
                'التحديد الذكي',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر نمط التحديد الذكي:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _buildSmartSelectionOption(
                icon: Icons.check_circle_rounded,
                title: 'جميع الأيام المتاحة',
                subtitle: 'تحديد كل الأيام المتاحة للحجز',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _selectAvailableDays(state);
                },
              ),
              const SizedBox(height: 12),
              _buildSmartSelectionOption(
                icon: Icons.weekend_rounded,
                title: 'عطل نهاية الأسبوع',
                subtitle: 'تحديد أيام السبت والجمعة',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _selectWeekends(state);
                },
              ),
              const SizedBox(height: 12),
              _buildSmartSelectionOption(
                icon: Icons.today_rounded,
                title: 'أيام العمل',
                subtitle: 'تحديد أيام الأحد إلى الخميس',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _selectWeekdays(state);
                },
              ),
              const SizedBox(height: 12),
              _buildSmartSelectionOption(
                icon: Icons.event_busy_rounded,
                title: 'الأيام المحجوزة',
                subtitle: 'تحديد جميع الأيام المحجوزة',
                onTap: () {
                  Navigator.pop(dialogContext);
                  _selectBookedDays(state);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'إلغاء',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartSelectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.6),
              AppTheme.darkSurface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _selectAvailableDays(DailyScheduleLoaded state) {
    final availableDays = state.monthlySchedule.schedules
        .where((schedule) => schedule.status == ScheduleStatus.available)
        .map((schedule) => schedule.date)
        .toList();

    if (availableDays.isEmpty) {
      _showInfoSnackbar('لا توجد أيام متاحة في هذا الشهر');
      return;
    }

    availableDays.sort();
    setState(() {
      _selectionStart = availableDays.first;
      _selectionEnd = availableDays.last;
    });
    _showSuccessSnackbar('تم تحديد ${availableDays.length} يوم متاح');
  }

  void _selectWeekends(DailyScheduleLoaded state) {
    final weekendDays = state.monthlySchedule.schedules
        .where((schedule) =>
            schedule.date.weekday == DateTime.friday ||
            schedule.date.weekday == DateTime.saturday)
        .map((schedule) => schedule.date)
        .toList();

    if (weekendDays.isEmpty) {
      _showInfoSnackbar('لا توجد أيام عطلة في هذا الشهر');
      return;
    }

    weekendDays.sort();
    setState(() {
      _selectionStart = weekendDays.first;
      _selectionEnd = weekendDays.last;
    });
    _showSuccessSnackbar('تم تحديد ${weekendDays.length} يوم عطلة');
  }

  void _selectWeekdays(DailyScheduleLoaded state) {
    final weekdays = state.monthlySchedule.schedules
        .where((schedule) =>
            schedule.date.weekday >= DateTime.sunday &&
            schedule.date.weekday <= DateTime.thursday)
        .map((schedule) => schedule.date)
        .toList();

    if (weekdays.isEmpty) {
      _showInfoSnackbar('لا توجد أيام عمل في هذا الشهر');
      return;
    }

    weekdays.sort();
    setState(() {
      _selectionStart = weekdays.first;
      _selectionEnd = weekdays.last;
    });
    _showSuccessSnackbar('تم تحديد ${weekdays.length} يوم عمل');
  }

  void _selectBookedDays(DailyScheduleLoaded state) {
    final bookedDays = state.monthlySchedule.schedules
        .where((schedule) => schedule.status == ScheduleStatus.booked)
        .map((schedule) => schedule.date)
        .toList();

    if (bookedDays.isEmpty) {
      _showInfoSnackbar('لا توجد أيام محجوزة في هذا الشهر');
      return;
    }

    bookedDays.sort();
    setState(() {
      _selectionStart = bookedDays.first;
      _selectionEnd = bookedDays.last;
    });
    _showSuccessSnackbar('تم تحديد ${bookedDays.length} يوم محجوز');
  }

  // ===== Snackbar Methods =====

  /// عرض رسالة نجاح
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض رسالة خطأ
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// عرض رسالة معلومات
  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===== Helper Methods =====

  /// تنسيق المبلغ المالي
  String _formatMoney(double value, String currency) {
    try {
      final f = NumberFormat('#,##0');
      return '${f.format(value)} $currency';
    } catch (_) {
      return '$value $currency';
    }
  }

  /// تنسيق الشهر والسنة
  String _formatMonthYear(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ===== Custom Painters =====

/// رسام الخلفية المتحركة
class _BackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _BackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppTheme.primaryBlue.withOpacity(0.05);

    // رسم الشبكة
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // رسم التوهج الدوار
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.1 * glowIntensity),
          AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, size.width / 3, glowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===== Particle System =====

/// صنف الجزيء
class _Particle {
  late double x, y, vx, vy;
  late double radius;
  late Color color;

  _Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 2 + 1;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;

    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

/// رسام الجزيئات
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
