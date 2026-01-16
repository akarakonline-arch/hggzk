// lib/features/admin_daily_schedule/presentation/widgets/schedule_legend.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/daily_schedule.dart';

/// دليل الألوان والرموز للجدول اليومي
/// Legend for daily schedule colors and symbols
/// 
/// ميزات:
/// - عرض دليل حالات الإتاحة
/// - عرض دليل فئات التسعير
/// - تصميم زجاجي جذاب
/// - تخطيط مرن (أفقي/عمودي)
class ScheduleLegend extends StatelessWidget {
  /// نوع الدليل (availability أو pricing)
  final LegendType type;
  
  /// عرض مدمج؟
  final bool isCompact;

  const ScheduleLegend({
    super.key,
    required this.type,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: type == LegendType.availability
              ? _buildAvailabilityLegend()
              : _buildPricingLegend(),
        ),
      ),
    );
  }

  /// دليل حالات الإتاحة
  Widget _buildAvailabilityLegend() {
    return Wrap(
      spacing: isCompact ? 8 : 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          label: 'متاح',
          color: AppTheme.success,
          icon: Icons.check_circle_rounded,
        ),
        _buildLegendItem(
          label: 'محجوز',
          color: AppTheme.warning,
          icon: Icons.event_busy_rounded,
        ),
        _buildLegendItem(
          label: 'محظور',
          color: AppTheme.error,
          icon: Icons.block_rounded,
        ),
        _buildLegendItem(
          label: 'صيانة',
          color: AppTheme.info,
          icon: Icons.build_rounded,
        ),
        _buildLegendItem(
          label: 'استخدام المالك',
          color: AppTheme.primaryPurple,
          icon: Icons.person_rounded,
        ),
      ],
    );
  }

  /// دليل فئات التسعير
  Widget _buildPricingLegend() {
    return Wrap(
      spacing: isCompact ? 8 : 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          label: 'خصم',
          color: AppTheme.success,
          icon: Icons.arrow_downward_rounded,
        ),
        _buildLegendItem(
          label: 'عادي',
          color: AppTheme.primaryBlue,
          icon: Icons.horizontal_rule_rounded,
        ),
        _buildLegendItem(
          label: 'عالي',
          color: AppTheme.warning,
          icon: Icons.arrow_upward_rounded,
        ),
        _buildLegendItem(
          label: 'ذروة',
          color: AppTheme.error,
          icon: Icons.trending_up_rounded,
        ),
        _buildLegendItem(
          label: 'مخصص',
          color: AppTheme.primaryPurple,
          icon: Icons.star_rounded,
        ),
      ],
    );
  }

  /// عنصر دليل واحد
  Widget _buildLegendItem({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 10 : 12,
          height: isCompact ? 10 : 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: isCompact ? 6 : 8,
            color: color,
          ),
        ),
        SizedBox(width: isCompact ? 4 : 6),
        Text(
          label,
          style: (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall).copyWith(
            color: AppTheme.textWhite.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// أنواع الدليل
enum LegendType {
  /// دليل حالات الإتاحة
  availability,
  
  /// دليل فئات التسعير
  pricing,
}
