import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin_units/domain/entities/unit.dart';

class RealUnitSelectorCard extends StatefulWidget {
  final String? selectedUnitId;
  final String? selectedUnitName;
  final String? selectedPropertyId;
  final Function(String id, String name) onUnitSelected;
  final bool isCompact;

  const RealUnitSelectorCard({
    super.key,
    required this.selectedUnitId,
    this.selectedUnitName,
    this.selectedPropertyId,
    required this.onUnitSelected,
    this.isCompact = false,
  });

  @override
  State<RealUnitSelectorCard> createState() => _RealUnitSelectorCardState();
}

class _RealUnitSelectorCardState extends State<RealUnitSelectorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: widget.isCompact ? 60 : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue
                  .withOpacity(0.2 + 0.1 * _glowAnimation.value),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue
                    .withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: _buildBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.selectedPropertyId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.door_front_door_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الوحدة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    'اختر عقاراً أولاً',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      );
    }

    final title = widget.selectedUnitName ?? 'اختر الوحدة';
    return InkWell(
      onTap: () => _openUnitSearch(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.door_front_door_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الوحدة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: widget.selectedUnitName == null
                          ? AppTheme.textMuted.withOpacity(0.5)
                          : AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  void _openUnitSearch(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push(
      '/helpers/search/units',
      extra: {
        'propertyId': widget.selectedPropertyId,
        'allowMultiSelect': false,
        'onUnitSelected': (Unit unit) {
          widget.onUnitSelected(unit.id, unit.name);
        },
      },
    );
  }
}
