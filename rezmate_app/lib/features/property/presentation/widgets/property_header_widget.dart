import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../domain/entities/property_detail.dart';

class PropertyHeaderWidget extends StatefulWidget {
  final PropertyDetail property;
  final bool isFavorite;
  final bool isFavoritePending;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  const PropertyHeaderWidget({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.isFavoritePending,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  State<PropertyHeaderWidget> createState() => _PropertyHeaderWidgetState();
}

class _PropertyHeaderWidgetState extends State<PropertyHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _statsController;
  late AnimationController _glowController;

  late Animation<double> _heartAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));

    _shimmerAnimation = const AlwaysStoppedAnimation<double>(0.0);

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutBack,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _statsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _statsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.darkBackground2,
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark,
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFuturisticHeader(),
                  const SizedBox(height: 12),
                  _buildFuturisticLocation(),
                  const SizedBox(height: 12),
                  _buildFuturisticStats(),
                  if (widget.property.averageRating > 0) ...[
                    const SizedBox(height: 12),
                    _buildFuturisticRating(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPatternPainter(
            shimmerPosition: _shimmerAnimation.value,
            glowIntensity: _glowAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildFuturisticHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.property.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.primaryViolet,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFuturisticTag(
                    label: widget.property.typeName,
                    icon: Icons.home_work,
                    backgroundColor: AppTheme.primaryViolet,
                  ),
                  const SizedBox(width: 6),
                  if (widget.property.starRating > 0) _buildStarRating(),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.share_outlined,
              onPressed: () {
                widget.onShare();
                HapticFeedback.lightImpact();
              },
              backgroundColor: AppTheme.primaryPurple,
            ),
            const SizedBox(width: 8),
            _buildFavoriteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildFuturisticTag({
    required String label,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.property.starRating,
          (index) => Padding(
            padding: EdgeInsets.only(right: 1),
            child: Icon(
              Icons.star,
              size: 10,
              color: AppTheme.warning,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () {
        if (widget.isFavoritePending) {
          HapticFeedback.selectionClick();
          return;
        }
        widget.onFavoriteToggle();
        if (!widget.isFavorite) {
          _heartController.forward().then((_) {
            _heartController.reverse();
          });
        }
        HapticFeedback.mediumImpact();
      },
      child: AnimatedBuilder(
        animation: _heartAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isFavorite ? _heartAnimation.value : 1.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isFavorite
                    ? AppTheme.error
                    : AppTheme.darkCard.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isFavorite
                      ? Colors.transparent
                      : AppTheme.textMuted.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? Colors.white : AppTheme.textMuted,
                size: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFuturisticLocation() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.property.address}, ${widget.property.city}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticStats() {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_outlined,
                  value: widget.property.viewCount.toString(),
                  label: 'مشاهدة',
                  color: AppTheme.primaryBlue,
                  delay: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bookmark_outline,
                  value: widget.property.bookingCount.toString(),
                  label: 'حجز',
                  color: AppTheme.primaryPurple,
                  delay: 50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.home_outlined,
                  value: widget.property.unitsCount.toString(),
                  label: 'وحدة',
                  color: AppTheme.primaryCyan,
                  delay: 100,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticRating() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.warning,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 18,
                  ),
                  Text(
                    widget.property.averageRating.toStringAsFixed(1),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingWidget(
                  rating: widget.property.averageRating,
                  starSize: 16,
                  showLabel: false,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.property.reviewsCount} تقييم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getRatingColor(widget.property.averageRating)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getRatingLabel(widget.property.averageRating),
              style: AppTextStyles.caption.copyWith(
                color: _getRatingColor(widget.property.averageRating),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.success;
    if (rating >= 3.5) return AppTheme.warning;
    if (rating >= 2.5) return Colors.orange;
    return AppTheme.error;
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 3.5) return 'جيد جداً';
    if (rating >= 2.5) return 'جيد';
    return 'مقبول';
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final double shimmerPosition;
  final double glowIntensity;

  _BackgroundPatternPainter({
    required this.shimmerPosition,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final haloPaint = Paint()..style = PaintingStyle.fill;

    // هالة نيون علوية تعطي إحساس Sci‑Fi حول عنوان العقار
    final topCenter = Offset(size.width * 0.2, size.height * -0.1);
    final topRadius = size.width * 1.1;
    final topGradient = RadialGradient(
      colors: [
        Colors.transparent,
        AppTheme.primaryCyan.withOpacity(0.25 * glowIntensity),
        AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 0.8, 1.0],
    );
    haloPaint.shader = topGradient
        .createShader(Rect.fromCircle(center: topCenter, radius: topRadius));
    canvas.drawCircle(topCenter, topRadius, haloPaint);

    // هالة ثانية سفلية باتجاه زر المفضلة تعطي توازن بصري
    final bottomCenter = Offset(size.width * 0.9, size.height * 1.2);
    final bottomRadius = size.width * 1.4;
    final bottomGradient = RadialGradient(
      colors: [
        Colors.transparent,
        AppTheme.primaryBlue.withOpacity(0.18 * glowIntensity),
        AppTheme.primaryViolet.withOpacity(0.06 * glowIntensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 0.8, 1.0],
    );
    haloPaint.shader = bottomGradient.createShader(
        Rect.fromCircle(center: bottomCenter, radius: bottomRadius));
    canvas.drawCircle(bottomCenter, bottomRadius, haloPaint);

    // مسار ضوئي خفيف يمر خلف الإحصائيات لإضافة عمق بدون إزعاج
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppTheme.primaryCyan.withOpacity(0.35 * glowIntensity),
          AppTheme.primaryPurple.withOpacity(0.35 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.1),
      );

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.6,
          size.width * 0.65, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.9, size.height * 0.78, size.width, size.height * 0.72);

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../domain/entities/property_detail.dart';

// class PropertyHeaderWidget extends StatefulWidget {
//   final PropertyDetail property;
//   final bool isFavorite;
//   final bool isFavoritePending;
//   final VoidCallback onFavoriteToggle;
//   final VoidCallback onShare;

//   const PropertyHeaderWidget({
//     super.key,
//     required this.property,
//     required this.isFavorite,
//     required this.isFavoritePending,
//     required this.onFavoriteToggle,
//     required this.onShare,
//   });

//   @override
//   State<PropertyHeaderWidget> createState() => _PropertyHeaderWidgetState();
// }

// class _PropertyHeaderWidgetState extends State<PropertyHeaderWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _heartController;

//   @override
//   void initState() {
//     super.initState();
//     _heartController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _heartController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppTheme.darkCard.withOpacity(0.5),
//         border: Border(
//           bottom: BorderSide(
//             color: AppTheme.darkBorder.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//       ),
//       child: ClipRRect(
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(),
//                 const SizedBox(height: 16),
//                 _buildLocation(),
//                 const SizedBox(height: 20),
//                 _buildStats(),
//                 if (widget.property.averageRating > 0) ...[
//                   const SizedBox(height: 20),
//                   _buildRating(),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.property.name,
//                 style: AppTextStyles.h2.copyWith(
//                   color: AppTheme.textWhite,
//                   fontWeight: FontWeight.w700,
//                   
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       gradient: AppTheme.primaryGradient,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.apartment_rounded,
//                           size: 14,
//                           color: Colors.white,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           widget.property.typeName,
//                           style: AppTextStyles.caption.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (widget.property.starRating > 0) ...[
//                     const SizedBox(width: 8),
//                     _buildStarRating(),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Row(
//           children: [
//             _buildActionButton(
//               icon: Icons.share_rounded,
//               onPressed: widget.onShare,
//               isPrimary: false,
//             ),
//             const SizedBox(width: 8),
//             _buildFavoriteButton(),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStarRating() {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 6,
//       ),
//       decoration: BoxDecoration(
//         color: AppTheme.warning.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: List.generate(
//           5,
//           (index) => Padding(
//             padding: const EdgeInsets.only(right: 2),
//             child: Icon(
//               index < widget.property.starRating
//                   ? Icons.star_rounded
//                   : Icons.star_outline_rounded,
//               size: 12,
//               color: AppTheme.warning,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required VoidCallback onPressed,
//     required bool isPrimary,
//   }) {
//     return Container(
//       width: 42,
//       height: 42,
//       decoration: BoxDecoration(
//         color: isPrimary
//             ? AppTheme.primaryBlue.withOpacity(0.1)
//             : AppTheme.darkCard.withOpacity(0.5),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isPrimary
//               ? AppTheme.primaryBlue.withOpacity(0.2)
//               : AppTheme.darkBorder.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(12),
//           child: Icon(
//             icon,
//             color: isPrimary ? AppTheme.primaryBlue : AppTheme.textLight,
//             size: 20,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFavoriteButton() {
//     return GestureDetector(
//       onTap: () {
//         if (!widget.isFavoritePending) {
//           widget.onFavoriteToggle();
//           _heartController.forward().then((_) {
//             _heartController.reverse();
//           });
//           HapticFeedback.lightImpact();
//         }
//       },
//       child: AnimatedBuilder(
//         animation: _heartController,
//         builder: (context, child) {
//           final scale = 1.0 + (_heartController.value * 0.2);
//           return Transform.scale(
//             scale: widget.isFavorite ? scale : 1.0,
//             child: Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 color: widget.isFavorite
//                     ? AppTheme.error.withOpacity(0.1)
//                     : AppTheme.darkCard.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: widget.isFavorite
//                       ? AppTheme.error.withOpacity(0.2)
//                       : AppTheme.darkBorder.withOpacity(0.1),
//                   width: 1,
//                 ),
//               ),
//               child: Icon(
//                 widget.isFavorite
//                     ? Icons.favorite_rounded
//                     : Icons.favorite_outline_rounded,
//                 color: widget.isFavorite ? AppTheme.error : AppTheme.textLight,
//                 size: 20,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLocation() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.primaryCyan.withOpacity(0.08),
//             AppTheme.primaryCyan.withOpacity(0.03),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: AppTheme.primaryCyan.withOpacity(0.15),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.primaryCyan.withOpacity(0.2),
//                   AppTheme.primaryCyan.withOpacity(0.1),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               Icons.location_on_rounded,
//               size: 20,
//               color: AppTheme.primaryCyan,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'الموقع',
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textMuted,
//                     
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   '${widget.property.address}, ${widget.property.city}',
//                   style: AppTextStyles.bodySmall.copyWith(
//                     color: AppTheme.textWhite,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStats() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             icon: Icons.visibility_rounded,
//             value: widget.property.viewCount.toString(),
//             label: 'مشاهدة',
//             color: AppTheme.primaryBlue,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _buildStatCard(
//             icon: Icons.bookmark_rounded,
//             value: widget.property.bookingCount.toString(),
//             label: 'حجز',
//             color: AppTheme.primaryPurple,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _buildStatCard(
//             icon: Icons.meeting_room_rounded,
//             value: widget.property.unitsCount.toString(),
//             label: 'وحدة',
//             color: AppTheme.primaryCyan,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String value,
//     required String label,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             color.withOpacity(0.08),
//             color.withOpacity(0.03),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.15),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             icon,
//             size: 20,
//             color: color,
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: AppTextStyles.bodyLarge.copyWith(
//               color: AppTheme.textWhite,
//               fontWeight: FontWeight.w700,
//               
//             ),
//           ),
//           Text(
//             label,
//             style: AppTextStyles.caption.copyWith(
//               color: AppTheme.textMuted,
//               
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRating() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.warning.withOpacity(0.08),
//             AppTheme.warning.withOpacity(0.03),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: AppTheme.warning.withOpacity(0.15),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.warning.withOpacity(0.2),
//                   AppTheme.warning.withOpacity(0.1),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.star_rounded,
//                   color: AppTheme.warning,
//                   size: 24,
//                 ),
//                 Text(
//                   widget.property.averageRating.toStringAsFixed(1),
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.warning,
//                     fontWeight: FontWeight.w700,
//                     
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: List.generate(
//                     5,
//                     (index) => Icon(
//                       index < widget.property.averageRating.round()
//                           ? Icons.star_rounded
//                           : Icons.star_outline_rounded,
//                       size: 18,
//                       color: AppTheme.warning,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${widget.property.reviewsCount} تقييم من النزلاء',
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textMuted,
//                     
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 6,
//             ),
//             decoration: BoxDecoration(
//               color: _getRatingColor(widget.property.averageRating)
//                   .withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               _getRatingLabel(widget.property.averageRating),
//               style: AppTextStyles.caption.copyWith(
//                 color: _getRatingColor(widget.property.averageRating),
//                 fontWeight: FontWeight.w600,
//                 
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getRatingColor(double rating) {
//     if (rating >= 4.5) return AppTheme.success;
//     if (rating >= 3.5) return AppTheme.warning;
//     if (rating >= 2.5) return AppTheme.info;
//     return AppTheme.error;
//   }

//   String _getRatingLabel(double rating) {
//     if (rating >= 4.5) return 'ممتاز';
//     if (rating >= 3.5) return 'جيد جداً';
//     if (rating >= 2.5) return 'جيد';
//     return 'مقبول';
//   }
// }
