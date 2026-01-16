import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/unit.dart';

class UnitGalleryPage extends StatefulWidget {
  final List<UnitImage> images;
  final int initialIndex;
  final String unitName;

  const UnitGalleryPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.unitName = '',
  });

  @override
  State<UnitGalleryPage> createState() => _UnitGalleryPageState();
}

class _UnitGalleryPageState extends State<UnitGalleryPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _bottomInfoSlideAnimation;
  late Animation<double> _glowAnimation;

  late int _currentIndex;
  bool _showInfo = true;
  final List<_FloatingOrb> _orbs = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeAnimations();
    _generateOrbs();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _bottomInfoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateOrbs() {
    for (int i = 0; i < 5; i++) {
      _orbs.add(_FloatingOrb());
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildFloatingOrbs(),
          _buildPhotoGallery(),
          _buildFuturisticTopBar(),
          if (_showInfo) _buildFuturisticBottomInfo(),
          _buildFuturisticPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground.withValues(alpha: 0.9),
            AppTheme.darkBackground.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _OrbPainter(
            orbs: _orbs,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildPhotoGallery() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showInfo = !_showInfo;
        });
        if (_showInfo) {
          _fadeController.forward();
          _slideController.forward();
        } else {
          _fadeController.reverse();
          _slideController.reverse();
        }
      },
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(
              ImageUtils.resolveUrl(widget.images[index].url),
            ),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'unit_image_${widget.images[index].id}',
            ),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => Center(
          child: _buildFuturisticLoader(event),
        ),
        backgroundDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildFuturisticLoader(ImageChunkEvent? event) {
    final progress = event == null
        ? 0.0
        : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.2),
            AppTheme.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue,
            ),
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTopBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBackground.withValues(alpha: 0.9),
                AppTheme.darkBackground.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassButton(
                        icon: Icons.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      _buildImageCounter(),
                      Row(
                        children: [
                          _buildGlassButton(
                            icon: Icons.share_outlined,
                            onPressed: _shareImage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.6),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: AppTheme.textWhite,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCounter() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(
                  alpha: 0.3 * _glowAnimation.value,
                ),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.images.length}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticBottomInfo() {
    final currentImage = widget.images[_currentIndex];

    return SlideTransition(
      position: _bottomInfoSlideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.darkBackground.withValues(alpha: 0.95),
                  AppTheme.darkBackground.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.unitName.isNotEmpty)
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              widget.unitName,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (currentImage.caption.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentImage.caption,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (currentImage.isMain) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'الصورة الرئيسية',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticPageIndicator() {
    if (widget.images.length <= 1) return const SizedBox.shrink();

    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.8),
                  AppTheme.darkCard.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                math.min(widget.images.length, 10),
                (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? AppTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                AppTheme.textMuted.withValues(alpha: 0.3),
                                AppTheme.textMuted.withValues(alpha: 0.3),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareImage() {
    HapticFeedback.mediumImpact();
  }
}

class _FloatingOrb {
  late double x;
  late double y;
  late double size;
  late double speedX;
  late double speedY;
  late Color color;

  _FloatingOrb() {
    final random = math.Random();
    x = random.nextDouble();
    y = random.nextDouble();
    size = 20 + random.nextDouble() * 40;
    speedX = (random.nextDouble() - 0.5) * 0.3;
    speedY = (random.nextDouble() - 0.5) * 0.3;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

class _OrbPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animationValue;

  _OrbPainter({
    required this.orbs,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final x = (orb.x + orb.speedX * animationValue) % 1.0;
      final y = (orb.y + orb.speedY * animationValue) % 1.0;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.15),
            orb.color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(x * size.width, y * size.height),
            radius: orb.size,
          ),
        );

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        orb.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => true;
}
