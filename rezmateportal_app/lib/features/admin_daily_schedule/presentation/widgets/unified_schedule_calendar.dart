// lib/features/admin_daily_schedule/presentation/widgets/unified_schedule_calendar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/daily_schedule.dart';
import '../../domain/entities/monthly_schedule.dart';
import '../bloc/daily_schedule_barrel.dart';

/// ويدجت التقويم الموحد للإتاحة والتسعير
/// يعرض شهراً كاملاً في شبكة تفاعلية مع معلومات الإتاحة والتسعير
class UnifiedScheduleCalendar extends StatefulWidget {
  /// الجدول الشهري المراد عرضه
  final MonthlySchedule monthlySchedule;

  /// التاريخ الحالي (الشهر المعروض)
  final DateTime currentDate;

  /// معاودة عند تغيير الشهر
  final Function(DateTime) onMonthChanged;

  /// معاودة عند الضغط على يوم
  final Function(DateTime, DailySchedule?)? onDayTap;

  /// معاودة عند الضغط المطوّل على يوم
  final Function(DateTime, DailySchedule?)? onDayLongPress;

  /// بداية نطاق الاختيار
  final DateTime? selectionStart;

  /// نهاية نطاق الاختيار
  final DateTime? selectionEnd;

  /// معاودة عند تغيير نطاق الاختيار
  final Function(DateTime? start, DateTime? end)? onSelectionChanged;

  /// وضع مضغوط (للشاشات الصغيرة)
  final bool isCompact;

  const UnifiedScheduleCalendar({
    super.key,
    required this.monthlySchedule,
    required this.currentDate,
    required this.onMonthChanged,
    this.onDayTap,
    this.onDayLongPress,
    this.selectionStart,
    this.selectionEnd,
    this.onSelectionChanged,
    this.isCompact = false,
  });

  @override
  State<UnifiedScheduleCalendar> createState() =>
      _UnifiedScheduleCalendarState();
}

class _UnifiedScheduleCalendarState extends State<UnifiedScheduleCalendar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime? _tempSelectionStart;
  DateTime? _tempSelectionEnd;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(UnifiedScheduleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
            child: Padding(
              padding: EdgeInsets.all(widget.isCompact ? 12 : 20),
              child: Column(
                children: [
                  // شريط أيام الأسبوع
                  _buildWeekdaysHeader(),
                  SizedBox(height: widget.isCompact ? 8 : 16),

                  // شبكة الأيام
                  Expanded(
                    child: _buildCalendarGrid(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء رأس أيام الأسبوع
  Widget _buildWeekdaysHeader() {
    final weekdays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// بناء شبكة التقويم
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(widget.currentDate.year, widget.currentDate.month, 1);
    final lastDayOfMonth = DateTime(widget.currentDate.year, widget.currentDate.month + 1, 0);

    // حساب اليوم الأول من الأسبوع (الأحد = 7)
    int firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    // عدد الأيام في الشهر
    final daysInMonth = lastDayOfMonth.day;

    // عدد الصفوف المطلوبة
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: widget.isCompact ? 4 : 8,
        mainAxisSpacing: widget.isCompact ? 4 : 8,
        childAspectRatio: widget.isCompact ? 0.9 : 1.0,
      ),
      itemCount: rowCount * 7,
      physics: widget.isCompact
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: !widget.isCompact,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;

        // خلية فارغة قبل بداية الشهر
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(widget.currentDate.year, widget.currentDate.month, dayNumber);
        final schedule = widget.monthlySchedule.getScheduleForDate(date);

        return _buildDayCell(date, schedule);
      },
    );
  }

  /// بناء خلية اليوم
  Widget _buildDayCell(DateTime date, DailySchedule? schedule) {
    final isToday = _isToday(date);
    final isSelected = _isSelected(date);
    final isInRange = _isInSelectionRange(date);
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleDayTap(date, schedule);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _handleDayLongPress(date, schedule);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: _getDayGradient(schedule, isSelected, isInRange, isPast),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppTheme.primaryBlue
                : isSelected
                    ? AppTheme.success
                    : _getBorderColor(schedule).withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: isSelected || isInRange
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // رقم اليوم
            Text(
              '${date.day}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _getTextColor(schedule, isPast),
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),

            // معلومات إضافية (الحالة والسعر)
            if (schedule != null && !widget.isCompact) ...[
              const SizedBox(height: 4),
              _buildStatusIndicator(schedule),
              if (schedule.hasCustomPrice) ...[
                const SizedBox(height: 2),
                _buildPriceIndicator(schedule),
              ],
            ],

            // مؤشر بسيط للوضع المضغوط
            if (schedule != null && widget.isCompact) ...[
              const SizedBox(height: 2),
              _buildCompactIndicators(schedule),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء مؤشر الحالة
  Widget _buildStatusIndicator(DailySchedule schedule) {
    IconData icon;
    Color color;

    switch (schedule.status) {
      case ScheduleStatus.available:
        icon = Icons.check_circle_rounded;
        color = AppTheme.success;
        break;
      case ScheduleStatus.booked:
        icon = Icons.event_busy_rounded;
        color = AppTheme.warning;
        break;
      case ScheduleStatus.blocked:
        icon = Icons.block_rounded;
        color = AppTheme.error;
        break;
      case ScheduleStatus.maintenance:
        icon = Icons.build_rounded;
        color = AppTheme.info;
        break;
      case ScheduleStatus.ownerUse:
        icon = Icons.person_rounded;
        color = AppTheme.primaryPurple;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  /// بناء مؤشر السعر
  Widget _buildPriceIndicator(DailySchedule schedule) {
    return Text(
      _formatPrice(schedule.displayPrice, schedule.displayCurrency),
      style: AppTextStyles.caption.copyWith(
        color: _getPriceColor(schedule),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// بناء المؤشرات المضغوطة
  Widget _buildCompactIndicators(DailySchedule schedule) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // نقطة الحالة
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _getStatusColor(schedule),
            shape: BoxShape.circle,
          ),
        ),
        if (schedule.hasCustomPrice) ...[
          const SizedBox(width: 3),
          // نقطة السعر
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getPriceColor(schedule),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  // ===== Helper Methods =====

  /// التحقق من أن التاريخ هو اليوم
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// التحقق من أن التاريخ محدد
  bool _isSelected(DateTime date) {
    if (widget.selectionStart == null) return false;
    if (widget.selectionEnd == null) {
      return _isSameDay(date, widget.selectionStart!);
    }
    return _isSameDay(date, widget.selectionStart!) ||
        _isSameDay(date, widget.selectionEnd!);
  }

  /// التحقق من أن التاريخ في نطاق الاختيار
  bool _isInSelectionRange(DateTime date) {
    if (widget.selectionStart == null || widget.selectionEnd == null) {
      return false;
    }

    final start = widget.selectionStart!;
    final end = widget.selectionEnd!;

    return date.isAfter(start) && date.isBefore(end);
  }

  /// التحقق من تطابق يومين
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// الحصول على تدرج الخلفية لليوم
  LinearGradient _getDayGradient(
    DailySchedule? schedule,
    bool isSelected,
    bool isInRange,
    bool isPast,
  ) {
    if (isSelected) {
      return LinearGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.3),
          AppTheme.primaryBlue.withOpacity(0.2),
        ],
      );
    }

    if (isInRange) {
      return LinearGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.15),
          AppTheme.primaryBlue.withOpacity(0.1),
        ],
      );
    }

    if (schedule == null || isPast) {
      return LinearGradient(
        colors: [
          AppTheme.darkSurface.withOpacity(0.3),
          AppTheme.darkSurface.withOpacity(0.2),
        ],
      );
    }

    // لون حسب الحالة
    final baseColor = _getStatusColor(schedule);
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.2),
        baseColor.withOpacity(0.1),
      ],
    );
  }

  /// الحصول على لون الحدود
  Color _getBorderColor(DailySchedule? schedule) {
    if (schedule == null) return AppTheme.darkBorder;
    return _getStatusColor(schedule);
  }

  /// الحصول على لون النص
  Color _getTextColor(DailySchedule? schedule, bool isPast) {
    if (isPast) return AppTheme.textMuted.withOpacity(0.5);
    if (schedule == null) return AppTheme.textMuted;
    return Colors.white;
  }

  /// الحصول على لون الحالة
  Color _getStatusColor(DailySchedule schedule) {
    switch (schedule.status) {
      case ScheduleStatus.available:
        return AppTheme.success;
      case ScheduleStatus.booked:
        return AppTheme.warning;
      case ScheduleStatus.blocked:
        return AppTheme.error;
      case ScheduleStatus.maintenance:
        return AppTheme.info;
      case ScheduleStatus.ownerUse:
        return AppTheme.primaryPurple;
    }
  }

  /// الحصول على لون السعر
  Color _getPriceColor(DailySchedule schedule) {
    if (schedule.pricingTier == null) return AppTheme.textMuted;

    switch (schedule.pricingTier!) {
      case PricingTier.normal:
        return AppTheme.success;
      case PricingTier.high:
        return AppTheme.warning;
      case PricingTier.peak:
        return AppTheme.error;
      case PricingTier.discount:
        return AppTheme.info;
      case PricingTier.custom:
        return AppTheme.primaryPurple;
    }
  }

  /// تنسيق السعر
  String _formatPrice(double price, String currency) {
    try {
      final formatter = NumberFormat.compact(locale: 'ar');
      return '${formatter.format(price)} $currency';
    } catch (_) {
      return '$price $currency';
    }
  }

  /// معالجة الضغط على اليوم
  void _handleDayTap(DateTime date, DailySchedule? schedule) {
    // معالجة الاختيار
    if (widget.onSelectionChanged != null) {
      if (_tempSelectionStart == null) {
        setState(() {
          _tempSelectionStart = date;
          _tempSelectionEnd = null;
          _isSelecting = true;
        });
        widget.onSelectionChanged!(date, null);
      } else if (_tempSelectionEnd == null) {
        if (date.isBefore(_tempSelectionStart!)) {
          setState(() {
            _tempSelectionEnd = _tempSelectionStart;
            _tempSelectionStart = date;
            _isSelecting = false;
          });
        } else {
          setState(() {
            _tempSelectionEnd = date;
            _isSelecting = false;
          });
        }
        widget.onSelectionChanged!(_tempSelectionStart, _tempSelectionEnd);
      } else {
        // إعادة البداية
        setState(() {
          _tempSelectionStart = date;
          _tempSelectionEnd = null;
          _isSelecting = true;
        });
        widget.onSelectionChanged!(date, null);
      }
    }

    // استدعاء معاودة الضغط
    widget.onDayTap?.call(date, schedule);
  }

  /// معالجة الضغط المطول على اليوم
  void _handleDayLongPress(DateTime date, DailySchedule? schedule) {
    widget.onDayLongPress?.call(date, schedule);
  }
}
