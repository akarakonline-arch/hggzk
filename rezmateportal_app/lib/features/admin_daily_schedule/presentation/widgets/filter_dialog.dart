import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/daily_schedule.dart';

class FilterDialog extends StatefulWidget {
  final ScheduleStatus? currentFilter;
  final Function(ScheduleStatus? filter) onApplyFilter;

  const FilterDialog({
    super.key,
    this.currentFilter,
    required this.onApplyFilter,
  });

  static Future<void> show(
    BuildContext context, {
    ScheduleStatus? currentFilter,
    required Function(ScheduleStatus? filter) onApplyFilter,
  }) {
    return showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentFilter: currentFilter,
        onApplyFilter: onApplyFilter,
      ),
    );
  }

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  ScheduleStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter;
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
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: _buildFilterOptions(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.filter_alt_rounded,
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
                'تصفية الجدول',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر حالة الإتاحة للتصفية',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          color: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Column(
      children: [
        _buildFilterOption(
          status: null,
          icon: Icons.all_inclusive_rounded,
          label: 'جميع الأيام',
          subtitle: 'عرض جميع الأيام بدون فلتر',
          color: AppTheme.info,
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          status: ScheduleStatus.available,
          icon: Icons.check_circle_rounded,
          label: 'متاح للحجز',
          subtitle: 'عرض الأيام المتاحة فقط',
          color: AppTheme.success,
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          status: ScheduleStatus.booked,
          icon: Icons.event_busy_rounded,
          label: 'محجوز',
          subtitle: 'عرض الأيام المحجوزة فقط',
          color: AppTheme.warning,
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          status: ScheduleStatus.blocked,
          icon: Icons.block_rounded,
          label: 'محظور',
          subtitle: 'عرض الأيام المحظورة فقط',
          color: AppTheme.error,
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          status: ScheduleStatus.maintenance,
          icon: Icons.build_rounded,
          label: 'صيانة',
          subtitle: 'عرض أيام الصيانة فقط',
          color: AppTheme.info,
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          status: ScheduleStatus.ownerUse,
          icon: Icons.person_rounded,
          label: 'استخدام المالك',
          subtitle: 'عرض أيام استخدام المالك فقط',
          color: AppTheme.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildFilterOption({
    required ScheduleStatus? status,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedFilter == status;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ]
                : [
                    AppTheme.darkSurface.withOpacity(0.6),
                    AppTheme.darkSurface.withOpacity(0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : AppTheme.darkSurface.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected ? color : AppTheme.textWhite,
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
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedFilter = null;
            });
          },
          child: Text(
            'إعادة تعيين',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onApplyFilter(_selectedFilter);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'تطبيق',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
