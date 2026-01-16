import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/favorite.dart';

class FavoritePropertyCardWidget extends StatefulWidget {
  final Favorite favorite;
  final bool isGridView;
  final Duration animationDelay;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoritePropertyCardWidget({
    super.key,
    required this.favorite,
    required this.isGridView,
    required this.animationDelay,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<FavoritePropertyCardWidget> createState() => 
      _FavoritePropertyCardWidgetState();
}

class _FavoritePropertyCardWidgetState extends State<FavoritePropertyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isHovered = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.isGridView
              ? _buildGridCard()
              : _buildListCard(),
        ),
      ),
    );
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _isHovered ? 0.97 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard,
                AppTheme.darkCard.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Image Section with Overlay Info
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Property Image
                      _buildPropertyImage(),

                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.darkBackground.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),

                      // Type Badge (Top Left)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildNeuroTypeBadge(),
                      ),

                      // Remove Button (Top Right)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildRemoveButton(size: 24),
                      ),

                      // Bottom Info Bar (bedrooms, bathrooms, area)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground.withOpacity(0.9),
                          ),
                          child: _buildPropertySpecsRow(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Property Name
                        Text(
                          widget.favorite.propertyName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Location Row with Circular Icon
                        _buildNeuroLocationRow(),

                        // Bottom Row (Price & Rating)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price with Gradient Background
                            _buildNeuroPriceTag(),

                            // Rating or Action Icon
                            if (widget.favorite.averageRating > 0)
                              _buildNeuroRatingBar()
                            else
                              Icon(
                                Icons.arrow_circle_left_outlined,
                                color: AppTheme.primaryCyan,
                                size: 28,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress Indicator (Gradient Line at Bottom)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryCyan,
                        AppTheme.primaryPurple,
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

  Widget _buildListCard() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _isHovered ? 0.98 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard,
                AppTheme.darkCard.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Overlays
                Stack(
                  children: [
                    // Property Image with Fixed Height
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: _buildPropertyImage(),
                    ),

                    // Dark gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.darkBackground.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Type Badge (Top Left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildNeuroTypeBadge(),
                    ),

                    // Remove Button (Top Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildRemoveButton(size: 32),
                    ),

                    // Bottom Info Bar (bedrooms, bathrooms, area)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground.withOpacity(0.9),
                        ),
                        child: _buildPropertySpecsRow(),
                      ),
                    ),
                  ],
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Name
                      Text(
                        widget.favorite.propertyName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Location Row with Circular Icon
                      _buildNeuroLocationRow(),

                      const SizedBox(height: 14),

                      // Bottom Row (Price & Rating)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price with Gradient Background
                          _buildNeuroPriceTag(),

                          // Rating or Action Icon
                          if (widget.favorite.averageRating > 0)
                            _buildNeuroRatingBar()
                          else
                            Icon(
                              Icons.arrow_circle_left_outlined,
                              color: AppTheme.primaryCyan,
                              size: 32,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress Indicator (Gradient Line at Bottom)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryCyan,
                        AppTheme.primaryPurple,
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

  Widget _buildPropertyImage() {
    String? imageUrl = widget.favorite.propertyImage;
    if ((imageUrl.isEmpty || imageUrl == 'null') && 
        widget.favorite.images.isNotEmpty) {
      final mainImage = widget.favorite.images.firstWhere(
        (img) => img.isMain,
        orElse: () => widget.favorite.images.first,
      );
      imageUrl = mainImage.url;
    }

    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      return CachedImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground2.withOpacity(0.5),
              AppTheme.darkBackground3.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.architecture_rounded,
            size: 36,
            color: AppTheme.textMuted.withOpacity(0.2),
          ),
        ),
      );
    }
  }

  Widget _buildNeuroTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(width: 4),
          Text(
            widget.favorite.typeName,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySpecsRow() {
    return Row(
      children: [
        // Add room info if available from the favorite entity
        // Since the favorite entity might not have these fields, 
        // we'll show other relevant info
        if (widget.favorite.amenities.isNotEmpty)
          _buildMiniSpec(
            Icons.check_circle_outline_rounded,
            '${widget.favorite.amenities.length}',
          ),
        if (widget.favorite.starRating > 0)
          _buildMiniSpec(
            Icons.star_rounded,
            '${widget.favorite.starRating}',
          ),
      ],
    );
  }

  Widget _buildMiniSpec(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.textLight.withOpacity(0.7),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuroLocationRow() {
    final location = widget.favorite.propertyLocation.isNotEmpty 
        ? widget.favorite.propertyLocation 
        : '${widget.favorite.city}, ${widget.favorite.address}';

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.navigation_rounded,
              size: 10,
              color: AppTheme.primaryCyan,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            location,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNeuroPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_rounded,
            size: 14,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(width: 4),
          Text(
            widget.favorite.minPrice.toStringAsFixed(0),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            widget.favorite.currency,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryCyan.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuroRatingBar() {
    final rating = widget.favorite.averageRating;
    final starCount = widget.favorite.starRating;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < starCount
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 12,
              color: AppTheme.warning,
            );
          }),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton({required double size}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _animateRemoval();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isRemoving
                ? [
                    AppTheme.error.withOpacity(0.7),
                    AppTheme.error.withOpacity(0.5),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRemoving
                ? Colors.transparent
                : Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isRemoving
                  ? AppTheme.error.withOpacity(0.25)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 3,
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: size * 0.5,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }

  void _animateRemoval() {
    setState(() {
      _isRemoving = true;
    });
    
    _animationController.reverse().then((_) {
      widget.onRemove();
    });
  }
}