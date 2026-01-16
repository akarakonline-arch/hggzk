import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin_properties/domain/entities/property.dart';

class RealPropertySelectorCard extends StatelessWidget {
  final String? selectedPropertyId;
  final String? selectedPropertyName;
  final Function(String id, String name) onPropertySelected;
  final bool isCompact;

  const RealPropertySelectorCard({
    super.key,
    required this.selectedPropertyId,
    required this.selectedPropertyName,
    required this.onPropertySelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 60 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final title = selectedPropertyName ?? 'اختر العقار';
    return InkWell(
      onTap: () => _openPropertySearch(context),
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final veryTight = constraints.maxHeight.isFinite && constraints.maxHeight < 48;
          final compact = isCompact || veryTight;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 6 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 34 : 40,
                  height: compact ? 34 : 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: compact ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: compact
                      ? Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: selectedPropertyName == null
                                ? AppTheme.textMuted.withOpacity(0.6)
                                : AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'العقار',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: selectedPropertyName == null
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
          );
        },
      ),
    );
  }

  void _openPropertySearch(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push(
      '/helpers/search/properties',
      extra: {
        'allowMultiSelect': false,
        'onPropertySelected': (Property property) {
          onPropertySelected(property.id, property.name ?? '');
        },
      },
    );
  }
}
