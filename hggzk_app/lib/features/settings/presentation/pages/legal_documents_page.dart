import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class LegalDocumentsPage extends StatelessWidget {
  final String baseUrl;

  const LegalDocumentsPage({
    super.key,
    required this.baseUrl,
  });

  List<_LegalItem> _items() {
    return [
      _LegalItem(
        title: 'سياسة الخصوصية',
        path: '/privacy',
        icon: Icons.privacy_tip_rounded,
        color: AppTheme.primaryCyan,
      ),
      _LegalItem(
        title: 'كيف نعمل',
        path: '/how-we-work',
        icon: Icons.lightbulb_outline_rounded,
        color: AppTheme.primaryBlue,
      ),
      _LegalItem(
        title: 'إرشادات المحتوى',
        path: '/content-guidelines',
        icon: Icons.rule_rounded,
        color: AppTheme.primaryPurple,
      ),
      _LegalItem(
        title: 'شروط الشركاء',
        path: '/terms-partners',
        icon: Icons.handshake_rounded,
        color: AppTheme.success,
      ),
      _LegalItem(
        title: 'شروط العملاء',
        path: '/terms-customers',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.warning,
      ),
      _LegalItem(
        title: 'قانون الأسواق الرقمية',
        path: '/digital-markets-law',
        icon: Icons.gavel_rounded,
        color: AppTheme.info,
      ),
      _LegalItem(
        title: 'القانون الأساسي',
        path: '/basic-law',
        icon: Icons.balance_rounded,
        color: AppTheme.primaryViolet,
      ),
      _LegalItem(
        title: 'الدعم والمساعدة',
        path: '/support',
        icon: Icons.support_agent_rounded,
        color: AppTheme.primaryCyan,
      ),
      _LegalItem(
        title: 'حذف الحساب',
        path: '/delete-account',
        icon: Icons.delete_forever_rounded,
        color: AppTheme.error,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _LegalBackground(),
          SafeArea(
            child: Column(
              children: [
                _LegalHeader(
                  title: 'السياسات والشروط',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.darkBorder.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Container(
                              height: 0.5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              color: AppTheme.darkBorder.withOpacity(0.08),
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _LegalListItem(
                                icon: item.icon,
                                title: item.title,
                                color: item.color,
                                onTap: () {
                                  final url = _normalizeUrl(baseUrl, item.path);
                                  context.push(
                                    '/legal/webview',
                                    extra: <String, dynamic>{
                                      'title': item.title,
                                      'url': url,
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeUrl(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$normalizedBase$path';
  }
}

class _LegalItem {
  final String title;
  final String path;
  final IconData icon;
  final Color color;

  _LegalItem({
    required this.title,
    required this.path,
    required this.icon,
    required this.color,
  });
}

class _LegalBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkSurface.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _LegalHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _LegalListItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
