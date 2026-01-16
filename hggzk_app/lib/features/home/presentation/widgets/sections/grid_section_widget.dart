// lib/features/home/presentation/widgets/sections/grid_section_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/cached_image_widget.dart';
import 'models/section_display_item.dart';

class GridSectionWidget extends StatelessWidget {
  final List<SectionDisplayItem> items;
  final Function(String)? onItemTap;

  const GridSectionWidget({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.73,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GridItemCard(
          item: item,
          onTap: () {
            HapticFeedback.lightImpact();
            onItemTap?.call(item.id);
          },
        );
      },
    );
  }
}

class _GridItemCard extends StatefulWidget {
  final SectionDisplayItem item;
  final VoidCallback? onTap;

  const _GridItemCard({
    required this.item,
    this.onTap,
  });

  @override
  State<_GridItemCard> createState() => _GridItemCardState();
}

class _GridItemCardState extends State<_GridItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? AppTheme.primaryBlue.withOpacity(0.25)
                  : AppTheme.darkBorder.withOpacity(0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Expanded(
                  flex: 55,
                  child: _buildImageSection(item),
                ),

                // Content Section
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Expanded(
                          child: _buildTitleSection(item),
                        ),

                        // City Row
                        _buildCityRow(item),
                      ],
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

  Widget _buildImageSection(SectionDisplayItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        Hero(
          tag: 'property_grid_${item.id}',
          child: item.imageUrl != null
              ? CachedImageWidget(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.1),
                        AppTheme.primaryPurple.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 40,
                    color: AppTheme.textMuted.withOpacity(0.3),
                  ),
                ),
        ),

        // Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),

        // Top Badges
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rating
              if (item.averageRating != null && item.averageRating! > 0)
                _CompactRatingBadge(rating: item.averageRating!)
              else
                const SizedBox.shrink(),

              // Discount
              if (item.hasDiscount)
                _CompactDiscountBadge(discount: item.discount!)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(SectionDisplayItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ إصلاح مشكلة overflow
      children: [
        Flexible(
          child: Text(
            item.name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
              height: 1.15, // ✅ تقليل ارتفاع السطر
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.location != null) ...[
          const SizedBox(height: 2), // ✅ تقليل المسافة من 3 إلى 2
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_outlined,
                size: 10, // ✅ تقليل حجم الأيقونة
                color: AppTheme.textMuted.withOpacity(0.6),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  item.location!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                    fontSize: 9, // ✅ تقليل حجم الخط
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCityRow(SectionDisplayItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // City
        if (item.city != null)
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.city!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),

        // Arrow Button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ COMPACT BADGES
// ═══════════════════════════════════════════════════════════════════════════

class _CompactRatingBadge extends StatelessWidget {
  final double rating;

  const _CompactRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 10,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactDiscountBadge extends StatelessWidget {
  final int discount;

  const _CompactDiscountBadge({required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '-$discount%',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
