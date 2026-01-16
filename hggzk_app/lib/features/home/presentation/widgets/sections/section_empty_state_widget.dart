// lib/features/home/presentation/widgets/sections/section_empty_state_widget.dart

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';

class SectionEmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;

  const SectionEmptyStateWidget({
    super.key,
    this.title = 'لا توجد عناصر',
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Refresh Button
          if (onRefresh != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تحديث',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
