import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/property_detail.dart';
import '../../domain/entities/unit.dart';

class PropertyGalleryPage extends StatefulWidget {
  final List<Unit> units;
  final String propertyName;
  final int initialUnitIndex;

  const PropertyGalleryPage({
    super.key,
    required this.units,
    this.propertyName = 'Al Zaereen Hotel 2',
    this.initialUnitIndex = 0,
  });

  @override
  State<PropertyGalleryPage> createState() => _PropertyGalleryPageState();
}

class _PropertyGalleryPageState extends State<PropertyGalleryPage> {
  late int _selectedUnitIndex;

  @override
  void initState() {
    super.initState();
    _selectedUnitIndex = widget.initialUnitIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.units.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: _buildAppBar(),
        body: Center(
          child: Text(
            'لا توجد وحدات متاحة',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ),
      );
    }

    final currentUnit = widget.units[_selectedUnitIndex];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildUnitsTabs(),
          Expanded(
            child: _buildAlternatingImagesGrid(currentUnit),
          ),
        ],
      ),
      bottomNavigationBar: _buildSelectRoomButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.9),
              AppTheme.darkCard.withOpacity(0.98),
            ],
          ),
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: Colors.white,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.propertyName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.h4.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, size: 20),
          color: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 20),
          color: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildUnitsTabs() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: widget.units.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final unit = widget.units[index];
          final isSelected = index == _selectedUnitIndex;
          // تجنب مشكلة عدم توافق الأنواع بين UnitImage و UnitImageModel
          final mainImageIndex = unit.images.indexWhere((img) => img.isMain);
          final mainImage = mainImageIndex != -1
              ? unit.images[mainImageIndex]
              : (unit.images.isNotEmpty ? unit.images.first : null);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedUnitIndex = index;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.cardGradient : null,
                color: isSelected ? null : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.darkBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (mainImage != null && mainImage.url.isNotEmpty)
                    Container(
                      width: 70,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.inputBackground,
                        image: DecorationImage(
                          image: NetworkImage(
                            ImageUtils.resolveUrl(mainImage.url),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.inputBackground,
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      unit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textWhite,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlternatingImagesGrid(Unit unit) {
    if (unit.images.isEmpty) {
      return Center(
        child: Text(
          'لا توجد صور لهذه الوحدة',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      );
    }

    final sortedImages = [...unit.images]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _calculateItemCount(sortedImages.length),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              unit.name,
              textAlign: TextAlign.right,
              style: AppTextStyles.h4.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          );
        }

        return _buildAlternatingItem(sortedImages, index - 1, unit);
      },
    );
  }

  int _calculateItemCount(int imagesCount) {
    int count = 1;
    int imageIndex = 0;

    while (imageIndex < imagesCount) {
      if (count % 2 == 1) {
        imageIndex += 1;
      } else {
        imageIndex += 2;
      }
      count++;
    }

    return count;
  }

  Widget _buildAlternatingItem(
      List<UnitImage> images, int layoutIndex, Unit unit) {
    int imageStartIndex = 0;

    for (int i = 0; i < layoutIndex; i++) {
      if (i % 2 == 0) {
        imageStartIndex += 1;
      } else {
        imageStartIndex += 2;
      }
    }

    if (imageStartIndex >= images.length) {
      return const SizedBox.shrink();
    }

    final isLargeImage = layoutIndex % 2 == 0;

    if (isLargeImage) {
      final image = images[imageStartIndex];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => _openImageViewer(unit, imageStartIndex),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                ImageUtils.resolveUrl(image.url),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.inputBackground,
                  child: Icon(Icons.broken_image,
                      size: 50, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (imageStartIndex < images.length)
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(unit, imageStartIndex),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 3 / 2,
                      child: Image.network(
                        ImageUtils.resolveUrl(images[imageStartIndex].url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.inputBackground,
                          child: Icon(Icons.broken_image,
                              size: 30, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (imageStartIndex + 1 < images.length) ...[
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(unit, imageStartIndex + 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 3 / 2,
                      child: Image.network(
                        ImageUtils.resolveUrl(images[imageStartIndex + 1].url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.inputBackground,
                          child: Icon(Icons.broken_image,
                              size: 30, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  void _openImageViewer(Unit unit, int index) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnitImageStudioPage(
          images: unit.images,
          initialIndex: index,
          title: unit.name,
        ),
      ),
    );
  }

  Widget _buildSelectRoomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder,
            width: 1,
          ),
        ),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                'اختر الغرف',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnitImageStudioPage extends StatefulWidget {
  final List<UnitImage> images;
  final int initialIndex;
  final String title;

  const UnitImageStudioPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title = '',
  });

  @override
  State<UnitImageStudioPage> createState() => _UnitImageStudioPageState();
}

class _UnitImageStudioPageState extends State<UnitImageStudioPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _bottomInfoSlideAnimation;
  late Animation<double> _glowAnimation;

  late int _currentIndex;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeAnimations();
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _bottomInfoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildPhotoGallery(),
          _buildTopBar(),
          if (_showInfo) _buildBottomInfo(),
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
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue,
            ),
          ),
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

  Widget _buildTopBar() {
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
                  const SizedBox(width: 40),
                ],
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
            gradient: AppTheme.primaryGradient,
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

  Widget _buildBottomInfo() {
    final currentImage = widget.images[_currentIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _bottomInfoSlideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.darkBackground.withValues(alpha: 0.95),
                  AppTheme.darkBackground.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title.isNotEmpty) ...[
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        widget.title,
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (currentImage.caption.isNotEmpty)
                    Text(
                      currentImage.caption,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textLight.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PropertyImageStudioPage extends StatefulWidget {
  final List<PropertyImage> images;
  final int initialIndex;
  final String title;

  const PropertyImageStudioPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title = '',
  });

  @override
  State<PropertyImageStudioPage> createState() =>
      _PropertyImageStudioPageState();
}

class _PropertyImageStudioPageState extends State<PropertyImageStudioPage>
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
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _bottomInfoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
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
            AppTheme.darkBackground.withOpacity(0.9),
            AppTheme.darkBackground.withOpacity(0.8),
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
              tag: 'property_image_${widget.images[index].id}',
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
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryBlue.withOpacity(0.05),
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
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
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
                AppTheme.darkBackground.withOpacity(0.9),
                AppTheme.darkBackground.withOpacity(0.7),
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
                      const SizedBox(width: 40),
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
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
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
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(
                  0.3 * _glowAnimation.value,
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _bottomInfoSlideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.darkBackground.withOpacity(0.95),
                  AppTheme.darkBackground.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title.isNotEmpty) ...[
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            widget.title,
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (currentImage.caption.isNotEmpty)
                        Text(
                          currentImage.caption,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textLight.withOpacity(0.8),
                            height: 1.5,
                          ),
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

  Widget _buildFuturisticPageIndicator() {
    if (widget.images.length <= 1) return const SizedBox.shrink();

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.images.length > 10 ? 10 : widget.images.length,
              (index) {
                final isSelected = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: !isSelected
                        ? AppTheme.textWhite.withOpacity(0.3)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingOrb {
  late double x;
  late double y;
  late double radius;
  late double vx;
  late double vy;
  late Color color;
  late double opacity;

  _FloatingOrb() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    radius = math.Random().nextDouble() * 100 + 50;
    vx = (math.Random().nextDouble() - 0.5) * 0.0005;
    vy = (math.Random().nextDouble() - 0.5) * 0.0005;
    opacity = math.Random().nextDouble() * 0.1 + 0.05;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;

    if (x < -0.1 || x > 1.1) vx = -vx;
    if (y < -0.1 || y > 1.1) vy = -vy;
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
    for (var orb in orbs) {
      orb.update();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withOpacity(orb.opacity),
            orb.color.withOpacity(0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(orb.x * size.width, orb.y * size.height),
            radius: orb.radius,
          ),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height),
        orb.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
