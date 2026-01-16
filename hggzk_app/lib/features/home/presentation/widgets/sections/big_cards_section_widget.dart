// lib/features/home/presentation/widgets/sections/big_cards_section_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/cached_image_widget.dart';
import 'models/section_display_item.dart';

class BigCardsSectionWidget extends StatefulWidget {
  final List<SectionDisplayItem> items;
  final Function(String)? onItemTap;

  const BigCardsSectionWidget({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  State<BigCardsSectionWidget> createState() => _BigCardsSectionWidgetState();
}

class _BigCardsSectionWidgetState extends State<BigCardsSectionWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cards
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.12)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Opacity(
                      opacity: value.clamp(0.75, 1.0),
                      child: Transform.scale(
                        scale: value.clamp(0.94, 1.0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _BigCard(
                    item: item,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onItemTap?.call(item.id);
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Page Indicator
        if (widget.items.length > 1) ...[
          const SizedBox(height: 18),
          _PageIndicator(
            itemCount: widget.items.length,
            currentPage: _currentPage,
          ),
        ],
      ],
    );
  }
}

class _BigCard extends StatefulWidget {
  final SectionDisplayItem item;
  final VoidCallback? onTap;

  const _BigCard({
    required this.item,
    this.onTap,
  });

  @override
  State<_BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<_BigCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _isPressed
                  ? AppTheme.primaryBlue.withOpacity(0.35)
                  : AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.04),
                blurRadius: 48,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Expanded(
                  flex: 52,
                  child: _buildImageSection(item),
                ),

                // Content Section
                Expanded(
                  flex: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeader(item),
                        const SizedBox(height: 6),
                        _buildFooter(item),
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
        // Main Image
        Hero(
          tag: 'property_big_${item.id}',
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
                        AppTheme.primaryBlue.withOpacity(0.15),
                        AppTheme.primaryPurple.withOpacity(0.15),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.villa_rounded,
                    size: 64,
                    color: AppTheme.textMuted.withOpacity(0.3),
                  ),
                ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppTheme.darkCard.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Top Badges
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Discount
              if (item.hasDiscount)
                _LuxuryDiscountBadge(discount: item.discount!)
              else
                const SizedBox.shrink(),

              // Rating
              if (item.averageRating != null && item.averageRating! > 0)
                _LuxuryRatingBadge(rating: item.averageRating!)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(SectionDisplayItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          style: AppTextStyles.h5.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // سطر التقييم + نوع العقار
        if (item.averageRating != null ||
            (item.category != null && item.category!.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.averageRating != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 3),
                Text(
                  item.averageRating!.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
              if (item.averageRating != null &&
                  item.category != null &&
                  item.category!.isNotEmpty)
                const SizedBox(width: 8),
              if (item.category != null && item.category!.isNotEmpty)
                Expanded(
                  child: Text(
                    item.category!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.9),
                      fontSize: 11,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
        if (item.location != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 10,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  item.location!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.0,
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

  bool _hasFeatures(SectionDisplayItem item) {
    return item.bedrooms != null || item.bathrooms != null;
  }

  Widget _buildFeatures(SectionDisplayItem item) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (item.bedrooms != null)
          _FeatureTag(
            icon: Icons.bed_outlined,
            label: '${item.bedrooms} غرف',
            color: AppTheme.primaryBlue,
          ),
        if (item.bathrooms != null)
          _FeatureTag(
            icon: Icons.shower_outlined,
            label: '${item.bathrooms} حمام',
            color: AppTheme.primaryPurple,
          ),
      ],
    );
  }

  Widget _buildFooter(SectionDisplayItem item) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryPurple,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'احجز الآن',
              style: AppTextStyles.buttonSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ LUXURY BADGES & COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _LuxuryDiscountBadge extends StatelessWidget {
  final int discount;

  const _LuxuryDiscountBadge({required this.discount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.error.withOpacity(0.9),
                AppTheme.error.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_rounded,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                'خصم $discount%',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryRatingBadge extends StatelessWidget {
  final double rating;

  const _LuxuryRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentPage;

  const _PageIndicator({
    required this.itemCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlue
                : AppTheme.textMuted.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
