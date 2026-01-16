import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/image_utils.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/search_result.dart';
import 'package:hggzk/injection_container.dart';
import 'package:hggzk/services/local_storage_service.dart';
import 'package:hggzk/core/constants/storage_constants.dart';
import '../../../favorites/domain/repositories/favorites_repository.dart';
import 'property_mismatch_badge_widget.dart';
import 'package:hggzk/core/enums/search_relaxation_level.dart';

enum CardDisplayType { list, grid, compact }

class SearchResultCardWidget extends StatefulWidget {
  final SearchResult result;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final CardDisplayType displayType;
  final bool showDistance;
  final SearchRelaxationLevel? relaxationLevel;

  const SearchResultCardWidget({
    super.key,
    required this.result,
    this.onTap,
    this.onFavoriteToggle,
    this.displayType = CardDisplayType.list,
    this.showDistance = true,
    this.relaxationLevel,
  });

  @override
  State<SearchResultCardWidget> createState() => _SearchResultCardWidgetState();
}

class _SearchResultCardWidgetState extends State<SearchResultCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    // Initialize favorite state from backend-provided flag
    _isFavorite = widget.result.isFavorite;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// الحصول على اللون حسب مستوى التخفيف
  Color _getColorForLevel() {
    final level = widget.relaxationLevel ?? SearchRelaxationLevel.exact;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return const Color(0xFF4CAF50);
      case SearchRelaxationLevel.minorRelaxation:
        return const Color(0xFF2196F3);
      case SearchRelaxationLevel.moderateRelaxation:
        return const Color(0xFFFF9800);
      case SearchRelaxationLevel.majorRelaxation:
        return const Color(0xFFFF5722);
      case SearchRelaxationLevel.alternativeSuggestions:
        return const Color(0xFF9E9E9E);
    }
  }

  /// الحصول على الأيقونة حسب مستوى التخفيف
  IconData _getIconForLevel() {
    final level = widget.relaxationLevel ?? SearchRelaxationLevel.exact;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return Icons.verified_rounded;
      case SearchRelaxationLevel.minorRelaxation:
        return Icons.star_rounded;
      case SearchRelaxationLevel.moderateRelaxation:
        return Icons.tune_rounded;
      case SearchRelaxationLevel.majorRelaxation:
        return Icons.lightbulb_rounded;
      case SearchRelaxationLevel.alternativeSuggestions:
        return Icons.auto_awesome_rounded;
    }
  }

  /// الحصول على الاسم العربي لمستوى التخفيف
  String _getDisplayName() {
    final level = widget.relaxationLevel ?? SearchRelaxationLevel.exact;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return 'تطابق دقيق';
      case SearchRelaxationLevel.minorRelaxation:
        return 'تخفيف بسيط';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'تخفيف متوسط';
      case SearchRelaxationLevel.majorRelaxation:
        return 'تخفيف كبير';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'اقتراحات بديلة';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print mismatches info
    if (widget.result.filterMismatches.isNotEmpty) {
      print(
          '🔍 [SearchResultCard] Property "${widget.result.name}" has ${widget.result.filterMismatches.length} mismatches');
      for (var m in widget.result.filterMismatches) {
        print('   - ${m.displayMessage} (${m.severity})');
      }
    }

    switch (widget.displayType) {
      case CardDisplayType.list:
        return _buildMinimalListCard();
      case CardDisplayType.grid:
        return _buildMinimalGridCard();
      case CardDisplayType.compact:
        return _buildMinimalCompactCard();
    }
  }

  Future<void> _defaultToggleFavorite() async {
    try {
      final uid =
          (sl<LocalStorageService>().getData(StorageConstants.userId) ?? '')
              .toString();
      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول لإضافة إلى المفضلة')),
        );
        return;
      }
      final repo = sl<FavoritesRepository>();
      final status = await repo.checkFavoriteStatus(
          propertyId: widget.result.id, userId: uid);
      await status.fold(
        (_) async {
          await repo.addToFavorites(propertyId: widget.result.id, userId: uid);
        },
        (isFav) async {
          if (isFav) {
            await repo.removeFromFavorites(
                propertyId: widget.result.id, userId: uid);
          } else {
            await repo.addToFavorites(
                propertyId: widget.result.id, userId: uid);
          }
        },
      );
    } catch (_) {}
  }

  Widget _buildMinimalListCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? AppTheme.primaryBlue.withOpacity(0.2)
                      : AppTheme.darkBorder.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMinimalImageSection(height: 160),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildLocationRow(),
                        const SizedBox(height: 12),
                        _buildInfoRow(),
                        const SizedBox(height: 12),
                        _buildPriceRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalGridCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isPressed
                      ? AppTheme.primaryBlue.withOpacity(0.2)
                      : AppTheme.darkBorder.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMinimalImageSection(),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.result.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.textMuted.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.result.city,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: AppTheme.warning.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.result.averageRating
                                        .toStringAsFixed(1),
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.result.discountedPrice.toStringAsFixed(0)} ${widget.result.currency}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalCompactCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPressed
                      ? AppTheme.primaryBlue.withOpacity(0.2)
                      : AppTheme.darkBorder.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Fixed width image with dynamic height
                    SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 3 / 4, // Portrait aspect ratio
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Safe network image (guards empty/relative URLs)
                              CachedImageWidget(
                                imageUrl: widget.result.mainImageUrl ?? '',
                                fit: BoxFit.cover,
                              ),
                              // Subtle gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                              // Favorite button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _buildCompactFavoriteButton(),
                              ),
                              // Discount badge
                              if (widget.result.minPrice !=
                                  widget.result.discountedPrice)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-${((1 - widget.result.discountedPrice / widget.result.minPrice) * 100).toStringAsFixed(0)}%',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Property type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.result.propertyType,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Name
                            Text(
                              widget.result.name,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 10,
                                  color: AppTheme.textMuted.withOpacity(0.6),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    widget.result.city,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Bottom row with rating and price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Rating
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 10,
                                        color: AppTheme.warning,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        widget.result.averageRating
                                            .toStringAsFixed(1),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppTheme.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Price
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (widget.result.minPrice !=
                                        widget.result.discountedPrice)
                                      Text(
                                        widget.result.minPrice
                                            .toStringAsFixed(0),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppTheme.textMuted
                                              .withOpacity(0.5),
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      '${widget.result.discountedPrice.toStringAsFixed(0)} ${widget.result.currency}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      },
    );
  }

  Widget _buildMinimalImageSection({double? height}) {
    final radius = Radius.circular(
      widget.displayType == CardDisplayType.grid ? 14 : 16,
    );
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imageUrl: widget.result.mainImageUrl ?? '',
              fit: BoxFit.cover,
            ),
            // Subtle gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
            // Top row badges
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.result.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'مميز',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  _buildMinimalFavoriteButton(),
                ],
              ),
            ),
            // Discount badge
            if (widget.result.minPrice != widget.result.discountedPrice)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${((1 - widget.result.discountedPrice / widget.result.minPrice) * 100).toStringAsFixed(0)}% خصم',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalFavoriteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        HapticFeedback.lightImpact();
        if (widget.onFavoriteToggle != null) {
          widget.onFavoriteToggle!.call();
        } else {
          _defaultToggleFavorite();
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? AppTheme.error : AppTheme.textDark,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCompactFavoriteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        HapticFeedback.lightImpact();
        if (widget.onFavoriteToggle != null) {
          widget.onFavoriteToggle!.call();
        } else {
          _defaultToggleFavorite();
        }
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? AppTheme.error : AppTheme.textDark,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.result.propertyType,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.result.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (widget.result.starRating > 0)
          Row(
            children: List.generate(
              widget.result.starRating,
              (index) => Icon(
                Icons.star,
                size: 14,
                color: AppTheme.warning.withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 12,
          color: AppTheme.textMuted.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${widget.result.address}, ${widget.result.city}',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.showDistance && widget.result.distanceKm != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me,
                  size: 10,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  '${widget.result.distanceKm!.toStringAsFixed(1)} كم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                size: 14,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 4),
              Text(
                widget.result.averageRating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.result.reviewsCount})',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (widget.result.isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'متاح',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.result.minPrice != widget.result.discountedPrice)
              Text(
                '${widget.result.minPrice.toStringAsFixed(0)} ${widget.result.currency}',
                style: AppTextStyles.caption.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.result.discountedPrice.toStringAsFixed(0),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.result.currency,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ الليلة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.9),
                  AppTheme.primaryPurple.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'عرض',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// عرض Bottom Sheet بتفاصيل الفروقات
  /// Show bottom sheet with mismatches details
  void _showMismatchesBottomSheet(BuildContext context) {
    final color = _getColorForLevel();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
                Colors.white.withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle للسحب
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // العنوان مع أيقونة
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'مقارنة مع طلبك',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    color: color,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // رسالة إيضاحية مع تصميم راقي
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2196F3).withOpacity(0.1),
                            const Color(0xFF2196F3).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              size: 20,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'هذا العقار يطابق معظم معاييرك مع بعض الاختلافات البسيطة',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.blue[800],
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // زر الإغلاق بتصميم راقي
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: color.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'فهمت',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),

                    // Safe area للأجهزة مع notch
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
