import 'package:flutter/material.dart';
import 'package:hggzk/core/theme/app_text_styles.dart';
import '../../data/models/property_filter_mismatch_model.dart';

/// Widget لعرض معلومات الفروقات بين المعايير المطلوبة والعقار
/// Widget to display mismatches between requested criteria and property
class PropertyMismatchBadgeWidget extends StatelessWidget {
  /// قائمة الفروقات
  /// List of mismatches
  final List<PropertyFilterMismatchModel> mismatches;

  /// هل العرض مختصر؟ (عدد الفروقات فقط)
  /// Is the view compact? (count only)
  final bool compact;

  const PropertyMismatchBadgeWidget({
    super.key,
    required this.mismatches,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    // إذا لم توجد فروقات، لا نعرض شيء
    if (mismatches.isEmpty) return const SizedBox.shrink();

    return compact ? _buildCompactView(context) : _buildDetailedView(context);
  }

  /// النسخة المختصرة: عدد الفروقات فقط
  /// Compact view: count only
  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            '${mismatches.length} فرق',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  /// النسخة المفصلة: قائمة الفروقات
  /// Detailed view: list of mismatches
  Widget _buildDetailedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'فروقات عن طلبك:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mismatches.map((mismatch) {
            return _buildMismatchChip(context, mismatch);
          }).toList(),
        ),
      ],
    );
  }

  /// Chip لكل فرق
  /// Chip for each mismatch
  Widget _buildMismatchChip(
      BuildContext context, PropertyFilterMismatchModel mismatch) {
    final color = _getColorForSeverity(mismatch.severity);
    final icon = _getIconForSeverity(mismatch.severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              mismatch.displayMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الألوان حسب الشدة
  /// Colors by severity
  Color _getColorForSeverity(MismatchSeverity severity) {
    switch (severity) {
      case MismatchSeverity.minor:
        return Colors.blue;
      case MismatchSeverity.moderate:
        return Colors.orange;
      case MismatchSeverity.major:
        return Colors.red;
    }
  }

  /// الأيقونات حسب الشدة
  /// Icons by severity
  IconData _getIconForSeverity(MismatchSeverity severity) {
    switch (severity) {
      case MismatchSeverity.minor:
        return Icons.info_outline_rounded;
      case MismatchSeverity.moderate:
        return Icons.warning_amber_rounded;
      case MismatchSeverity.major:
        return Icons.error_outline_rounded;
    }
  }
}
