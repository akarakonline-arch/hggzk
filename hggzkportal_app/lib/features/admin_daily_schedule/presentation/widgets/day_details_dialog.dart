// lib/features/admin_daily_schedule/presentation/widgets/day_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/daily_schedule.dart';

/// مربع حوار تفاصيل اليوم
/// Day details dialog
///
/// ميزات:
/// - عرض تفاصيل كاملة ليوم واحد
/// - إمكانية التعديل المباشر
/// - تصميم زجاجي جذاب
/// - تأثيرات أنيميشن متقدمة
class DayDetailsDialog extends StatefulWidget {
  /// الجدول اليومي
  final DailySchedule schedule;

  /// دالة الحفظ
  final Function(DailySchedule updated) onSave;

  /// دالة الحذف
  final VoidCallback? onDelete;

  const DayDetailsDialog({
    super.key,
    required this.schedule,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required DailySchedule schedule,
    required Function(DailySchedule) onSave,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppTheme.overlayDark,
      builder: (context) => DayDetailsDialog(
        schedule: schedule,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<DayDetailsDialog> createState() => _DayDetailsDialogState();
}

class _DayDetailsDialogState extends State<DayDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late DailySchedule _editedSchedule;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _editedSchedule = widget.schedule;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildContent(),
                      ),
                    ),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// رأس الحوار
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.2),
            _getStatusColor().withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(),
                  _getStatusColor().withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'ar')
                      .format(_editedSchedule.date),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _editedSchedule.status.toArabicString(),
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_editedSchedule.hasCustomPrice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_editedSchedule.displayPrice.toStringAsFixed(0)} ${_editedSchedule.displayCurrency}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// محتوى الحوار
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'معلومات الإتاحة',
          icon: Icons.event_available_rounded,
          children: [
            _buildInfoRow('الحالة', _editedSchedule.status.toArabicString()),
            if (_editedSchedule.reason != null)
              _buildInfoRow('السبب', _editedSchedule.reason!),
            if (_editedSchedule.notes != null)
              _buildInfoRow('ملاحظات', _editedSchedule.notes!),
            if (_editedSchedule.bookingId != null)
              _buildInfoRow('رقم الحجز', _editedSchedule.bookingId.toString()),
          ],
        ),
        const SizedBox(height: 20),
        _buildSection(
          title: 'معلومات التسعير',
          icon: Icons.attach_money_rounded,
          children: [
            if (_editedSchedule.priceAmount != null)
              _buildInfoRow(
                'السعر',
                '${_editedSchedule.priceAmount!.toStringAsFixed(0)} ${_editedSchedule.displayCurrency}',
              ),
            if (_editedSchedule.priceType != null)
              _buildInfoRow(
                  'نوع السعر', _editedSchedule.priceType!.toArabicString()),
            if (_editedSchedule.pricingTier != null)
              _buildInfoRow(
                  'فئة التسعير', _editedSchedule.pricingTier!.toArabicString()),
            if (_editedSchedule.percentageChange != null)
              _buildInfoRow(
                'نسبة التغيير',
                '${_editedSchedule.percentageChange!.toStringAsFixed(0)}%',
              ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSection(
          title: 'معلومات إضافية',
          icon: Icons.info_outline_rounded,
          children: [
            if (_editedSchedule.createdAt != null)
              _buildInfoRow(
                'تاريخ الإنشاء',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(_editedSchedule.createdAt!),
              ),
            if (_editedSchedule.updatedAt != null)
              _buildInfoRow(
                'آخر تحديث',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(_editedSchedule.updatedAt!),
              ),
            if (_editedSchedule.createdBy != null)
              _buildInfoRow('أنشئ بواسطة', _editedSchedule.createdBy!),
            if (_editedSchedule.modifiedBy != null)
              _buildInfoRow('عُدّل بواسطة', _editedSchedule.modifiedBy!),
          ],
        ),
      ],
    );
  }

  /// قسم معلومات
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.5),
            AppTheme.darkSurface.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// صف معلومة واحدة
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أزرار الإجراءات
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onDelete != null)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onDelete!();
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onDelete != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'إغلاق',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppTheme.textWhiteAlways,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على لون الحالة
  Color _getStatusColor() {
    switch (_editedSchedule.status) {
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

  /// الحصول على أيقونة الحالة
  IconData _getStatusIcon() {
    switch (_editedSchedule.status) {
      case ScheduleStatus.available:
        return Icons.check_circle_rounded;
      case ScheduleStatus.booked:
        return Icons.event_busy_rounded;
      case ScheduleStatus.blocked:
        return Icons.block_rounded;
      case ScheduleStatus.maintenance:
        return Icons.build_rounded;
      case ScheduleStatus.ownerUse:
        return Icons.person_rounded;
    }
  }
}
