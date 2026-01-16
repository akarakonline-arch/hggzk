// lib/features/home/presentation/widgets/sections/list_section_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/cached_image_widget.dart';
import 'models/section_display_item.dart';

class ListSectionWidget extends StatelessWidget {
  final List<SectionDisplayItem> items;
  final Function(String)? onItemTap;

  const ListSectionWidget({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ListItemCard(
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

class _ListItemCard extends StatefulWidget {
  final SectionDisplayItem item;
  final VoidCallback? onTap;

  const _ListItemCard({
    required this.item,
    this.onTap,
  });

  @override
  State<_ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<_ListItemCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
          height: 125,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed
                  ? AppTheme.primaryBlue.withOpacity(0.25)
                  : AppTheme.darkBorder.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                // Image Section
                _buildImageSection(item),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTitleSection(item),
                        _buildFooterSection(item),
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
    return SizedBox(
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Hero(
            tag: 'property_list_${item.id}',
            child: item.imageUrl != null
                ? CachedImageWidget(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.08),
                          AppTheme.primaryPurple.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 36,
                      color: AppTheme.textMuted.withOpacity(0.35),
                    ),
                  ),
          ),

          // Discount Badge
          if (item.hasDiscount)
            Positioned(
              top: 8,
              left: 8,
              child: _DiscountBadge(discount: item.discount!),
            ),

          // Rating Badge
          if (item.averageRating != null && item.averageRating! > 0)
            Positioned(
              bottom: 8,
              left: 8,
              child: _RatingBadge(rating: item.averageRating!),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(SectionDisplayItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // سطر التقييم + نوع العقار
        if (item.averageRating != null ||
            (item.category != null && item.category!.isNotEmpty)) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.averageRating != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  item.averageRating!.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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
                      color: AppTheme.textMuted.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
        if (item.location != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 13,
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  item.location!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                    fontSize: 11,
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

  Widget _buildFooterSection(SectionDisplayItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Features or Arrow فقط بدون سعر
        _buildFeatures(item),
      ],
    );
  }

  Widget _buildFeatures(SectionDisplayItem item) {
    final hasFeatures = item.bedrooms != null || item.bathrooms != null;

    if (!hasFeatures) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: AppTheme.primaryBlue,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.bedrooms != null)
          _FeatureChip(
            icon: Icons.bed_outlined,
            value: '${item.bedrooms}',
          ),
        if (item.bathrooms != null) ...[
          const SizedBox(width: 6),
          _FeatureChip(
            icon: Icons.shower_outlined,
            value: '${item.bathrooms}',
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ BADGES & CHIPS
// ═══════════════════════════════════════════════════════════════════════════

class _DiscountBadge extends StatelessWidget {
  final int discount;

  const _DiscountBadge({required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error,
            AppTheme.error.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '-$discount%',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 11,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _FeatureChip({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
