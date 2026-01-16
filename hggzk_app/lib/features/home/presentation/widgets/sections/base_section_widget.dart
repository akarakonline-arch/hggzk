// lib/features/home/presentation/widgets/sections/base_section_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/enums/section_type_enum.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../domain/entities/section.dart';
import '../../../data/models/section_item_models.dart';
import 'models/section_display_item.dart';
import 'list_section_widget.dart';
import 'grid_section_widget.dart';
import 'big_cards_section_widget.dart';

class BaseSectionWidget extends StatelessWidget {
  final Section section;
  final dynamic data;
  final bool isLoadingMore;
  final VoidCallback? onViewAll;
  final Function(String)? onItemTap;
  final VoidCallback? onLoadMore;

  const BaseSectionWidget({
    super.key,
    required this.section,
    this.data,
    this.isLoadingMore = false,
    this.onViewAll,
    this.onItemTap,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    // Convert data to display items
    final displayItems = _convertToDisplayItems();

    // إذا كانت البيانات null، نعرض skeleton
    if (data == null) {
      return _buildSkeletonLoader();
    }

    // إذا كانت القائمة فارغة بعد التحويل
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ElegantSectionContainer(
      section: section,
      items: displayItems,
      isLoadingMore: isLoadingMore,
      onViewAll: onViewAll,
      onItemTap: onItemTap,
      onLoadMore: onLoadMore,
    );
  }

  List<SectionDisplayItem> _convertToDisplayItems() {
    if (data == null) {
      return [];
    }

    try {
      List<dynamic> itemsList = [];

      // ✅ التحقق من نوع البيانات
      if (data is List) {
        // البيانات قائمة مباشرة
        itemsList = data as List;
      } else if (data is PaginatedResult) {
        // البيانات PaginatedResult - نستخرج items منها
        itemsList = (data as PaginatedResult).items;
      } else {
        // محاولة الوصول لخاصية items ديناميكياً (لأي نوع آخر)
        try {
          final dynamic dynamicData = data;
          if (dynamicData.items != null) {
            itemsList = dynamicData.items as List;
          }
        } catch (e) {
          debugPrint('❌ Cannot access items property: $e');
          return [];
        }
      }

      if (itemsList.isEmpty) {
        return [];
      }

      // تحويل العناصر إلى SectionDisplayItem
      final result = <SectionDisplayItem>[];

      for (final item in itemsList) {
        if (item is SectionPropertyItemModel) {
          result.add(SectionDisplayItem.fromProperty(item));
        } else if (item is SectionUnitItemModel) {
          result.add(SectionDisplayItem.fromUnit(item));
        } else if (item is SectionDisplayItem) {
          result.add(item);
        } else if (item is Map<String, dynamic>) {
          // محاولة تحويل من Map
          final converted = _convertFromMap(item);
          if (converted != null) {
            result.add(converted);
          }
        }
      }

      return result;
    } catch (e, stack) {
      debugPrint('❌ Error converting section data: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  SectionDisplayItem? _convertFromMap(Map<String, dynamic> map) {
    try {
      // تحقق إذا كان property أو unit
      if (map.containsKey('propertyInSectionId') ||
          map.containsKey('propertyType') ||
          map.containsKey('address')) {
        final model = SectionPropertyItemModel.fromJson(map);
        return SectionDisplayItem.fromProperty(model);
      } else if (map.containsKey('unitInSectionId') ||
          map.containsKey('unitTypeId')) {
        final model = SectionUnitItemModel.fromJson(map);
        return SectionDisplayItem.fromUnit(model);
      }

      // محاولة افتراضية كـ property
      final model = SectionPropertyItemModel.fromJson(map);
      return SectionDisplayItem.fromProperty(model);
    } catch (e) {
      debugPrint('Error converting map: $e');
      return null;
    }
  }

  Widget _buildSkeletonLoader() {
    return _SectionSkeletonLoader(type: section.uiType);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 ELEGANT SECTION CONTAINER
// ═══════════════════════════════════════════════════════════════════════════

class _ElegantSectionContainer extends StatelessWidget {
  final Section section;
  final List<SectionDisplayItem> items;
  final bool isLoadingMore;
  final VoidCallback? onViewAll;
  final Function(String)? onItemTap;
  final VoidCallback? onLoadMore;

  const _ElegantSectionContainer({
    required this.section,
    required this.items,
    this.isLoadingMore = false,
    this.onViewAll,
    this.onItemTap,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 16),

          // Content
          _buildContent(),

          // Loading More Indicator
          if (isLoadingMore) _buildLoadingMoreIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = section.title ?? section.name ?? 'القسم';
    final subtitle = section.subtitle;

    switch (section.uiType) {
      case SectionType.bigCards:
        return _LuxurySectionHeader(
          title: title,
          subtitle: subtitle,
          onSeeAllTap: onViewAll,
        );
      default:
        return _ElegantSectionHeader(
          title: title,
          subtitle: subtitle,
          onSeeAllTap: onViewAll,
        );
    }
  }

  Widget _buildContent() {
    switch (section.uiType) {
      case SectionType.bigCards:
        return BigCardsSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
      case SectionType.list:
        return ListSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
      case SectionType.grid:
      default:
        return GridSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
    }
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'جارِ تحميل المزيد...',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ ELEGANT SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _ElegantSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAllTap;

  const _ElegantSectionHeader({
    required this.title,
    this.subtitle,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSeeAllTap?.call();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عرض الكل',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💎 LUXURY SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _LuxurySectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAllTap;

  const _LuxurySectionHeader({
    required this.title,
    this.subtitle,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryPurple,
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        title,
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onSeeAllTap != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSeeAllTap?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryPurple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryPurple.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 SKELETON LOADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionSkeletonLoader extends StatefulWidget {
  final SectionType type;

  const _SectionSkeletonLoader({
    this.type = SectionType.grid,
  });

  @override
  State<_SectionSkeletonLoader> createState() => _SectionSkeletonLoaderState();
}

class _SectionSkeletonLoaderState extends State<_SectionSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(width: 140, height: 22),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 200, height: 14),
                      ],
                    ),
                    _buildSkeletonBox(width: 80, height: 36, borderRadius: 10),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content Skeleton
              _buildContentSkeleton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(_animation.value),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildContentSkeleton() {
    switch (widget.type) {
      case SectionType.bigCards:
        return SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => _buildSkeletonBox(
              width: 300,
              height: 360,
              borderRadius: 26,
            ),
          ),
        );
      case SectionType.list:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index < 2 ? 14 : 0),
                child: _buildSkeletonBox(
                  width: double.infinity,
                  height: 125,
                  borderRadius: 18,
                ),
              ),
            ),
          ),
        );
      case SectionType.grid:
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 0.73,
            children: List.generate(
              4,
              (_) => _buildSkeletonBox(
                borderRadius: 20,
              ),
            ),
          ),
        );
    }
  }
}
