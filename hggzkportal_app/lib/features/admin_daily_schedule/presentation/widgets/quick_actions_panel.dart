// lib/features/admin_daily_schedule/presentation/widgets/quick_actions_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

/// أنواع الإجراءات السريعة المتاحة
enum QuickAction {
  /// تحديث مجمع للجدول
  bulkUpdate,

  /// نسخ إعدادات الجدول
  cloneSchedule,

  /// مسح الاختيار
  clearSelection,

  /// التحديد الذكي
  smartSelection,
}

/// لوحة الإجراءات السريعة للجدول اليومي
/// Quick actions panel for daily schedule
///
/// ميزات:
/// - إجراءات سريعة قابلة للتخصيص
/// - تأثيرات أنيميشن جذابة
/// - دعم العرض الأفقي والعمودي
/// - تغذية حسية للتفاعلات
class QuickActionsPanel extends StatefulWidget {
  /// دالة استدعاء عند النقر على إجراء
  final Function(QuickAction) onActionTap;

  /// عرض أفقي؟
  final bool isHorizontal;

  /// الإجراءات المخصصة (إذا لم تُحدد، تُستخدم الافتراضية)
  final List<QuickActionItem>? customActions;

  const QuickActionsPanel({
    super.key,
    required this.onActionTap,
    this.isHorizontal = false,
    this.customActions,
  });

  @override
  State<QuickActionsPanel> createState() => _QuickActionsPanelState();
}

class _QuickActionsPanelState extends State<QuickActionsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
    final actions = widget.customActions ?? _getDefaultActions();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.7),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: widget.isHorizontal
                    ? _buildHorizontalLayout(actions)
                    : _buildVerticalLayout(actions),
              ),
            ),
          ),
        );
      },
    );
  }

  /// عرض أفقي
  Widget _buildHorizontalLayout(List<QuickActionItem> actions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildActionButton(action, isCompact: true),
          );
        }).toList(),
      ),
    );
  }

  /// عرض عمودي
  Widget _buildVerticalLayout(List<QuickActionItem> actions) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildActionButton(action),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// رأس اللوحة
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'إجراءات سريعة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// زر إجراء واحد
  Widget _buildActionButton(QuickActionItem action, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onActionTap(action.action);
      },
      child: Container(
        height: isCompact ? 44 : 48,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              action.color.withOpacity(0.2),
              action.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: action.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: isCompact ? 18 : 20,
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Text(
              action.label,
              style:
                  (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall)
                      .copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isCompact) const Spacer(),
            if (!isCompact)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: action.color.withOpacity(0.5),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  /// الحصول على الإجراءات الافتراضية
  List<QuickActionItem> _getDefaultActions() {
    return [
      QuickActionItem(
        action: QuickAction.bulkUpdate,
        icon: Icons.edit_calendar_rounded,
        label: 'تحديث مجمع',
        color: AppTheme.primaryBlue,
      ),
      QuickActionItem(
        action: QuickAction.cloneSchedule,
        icon: Icons.content_copy_rounded,
        label: 'نسخ الجدول',
        color: AppTheme.primaryPurple,
      ),
    ];
  }
}

/// عنصر إجراء سريع واحد
class QuickActionItem {
  /// نوع الإجراء
  final QuickAction action;

  /// أيقونة الإجراء
  final IconData icon;

  /// تسمية الإجراء
  final String label;

  /// لون الإجراء
  final Color color;

  QuickActionItem({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
  });
}
