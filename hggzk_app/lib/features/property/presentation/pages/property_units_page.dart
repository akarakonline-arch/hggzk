import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../../services/filter_storage_service.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/property_detail.dart';
import '../../domain/entities/property_policy.dart';
import '../../../../core/utils/image_utils.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import 'unit_gallery_page.dart';

class PropertyUnitsPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestsCount;
  final List<dynamic>? units;
  final List<PropertyService>? propertyServices;
  final List<PropertyPolicy>? propertyPolicies;

  const PropertyUnitsPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.checkInDate,
    this.checkOutDate,
    this.guestsCount = 1,
    this.units,
    this.propertyServices,
    this.propertyPolicies,
  });

  @override
  State<PropertyUnitsPage> createState() => _PropertyUnitsPageState();
}

class _PropertyUnitsPageState extends State<PropertyUnitsPage>
    with TickerProviderStateMixin {
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guestsCount;
  String? _selectedUnitId;
  String? _selectedUnitTypeId;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<_FloatingCube> _cubes = [];

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.checkInDate ?? DateTime.now();
    _checkOutDate =
        widget.checkOutDate ?? DateTime.now().add(const Duration(days: 1));
    _guestsCount = widget.guestsCount;

    final selections = sl<FilterStorageService>().getHomeSelections();
    _selectedUnitTypeId = selections['unitTypeId'] as String?;

    _initializeAnimations();
    _generateCubes();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateCubes() {
    for (int i = 0; i < 5; i++) {
      _cubes.add(_FloatingCube());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PropertyBloc>()
        ..add(GetPropertyUnitsEvent(
          propertyId: widget.propertyId,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestsCount: _guestsCount,
          unitTypeId: _selectedUnitTypeId,
        )),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildFloatingCubes(),
            Column(
              children: [
                _buildFuturisticAppBar(),
                Expanded(
                  child: BlocBuilder<PropertyBloc, PropertyState>(
                    builder: (context, state) {
                      if (state is PropertyUnitsLoading) {
                        return _buildFuturisticLoader();
                      }

                      if (state is PropertyError) {
                        return _buildFuturisticError(context, state);
                      }

                      if (state is PropertyUnitsLoaded) {
                        if (state.units.isEmpty) {
                          return _buildFuturisticEmptyState(context);
                        }

                        return RefreshIndicator(
                          onRefresh: () async => _loadUnits(context),
                          displacement: 60,
                          backgroundColor: AppTheme.darkCard,
                          color: AppTheme.primaryBlue,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: state.units.length,
                            itemBuilder: (context, index) {
                              final unit = state.units[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildFuturisticUnitCard(
                                      context,
                                      unit,
                                      state.selectedUnitId == unit.id,
                                      index,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildFuturisticBottomBar(),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkGradient,
      ),
    );
  }

  Widget _buildFloatingCubes() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _CubePainter(
            cubes: _cubes,
            animationValue: _waveController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            'الوحدات المتاحة',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.propertyName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildFilterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFilterDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.filter_list,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticDateSelector() {
    final nights = _checkOutDate.difference(_checkInDate).inDays;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFuturisticDateCard(
                        title: 'تسجيل الدخول',
                        date: _checkInDate,
                        icon: Icons.login,
                        color: AppTheme.primaryBlue,
                        onTap: () => _selectCheckInDate(context),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.nights_stay,
                                    color: AppTheme.isDark
                                        ? Colors.white
                                        : AppTheme.textDark,
                                    size: 14,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$nights',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.isDark
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    nights == 1 ? 'ليلة' : 'ليالي',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.isDark
                                          ? Colors.white.withOpacity(0.9)
                                          : AppTheme.textDark.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildFuturisticDateCard(
                        title: 'تسجيل الخروج',
                        date: _checkOutDate,
                        icon: Icons.logout,
                        color: AppTheme.primaryPurple,
                        onTap: () => _selectCheckOutDate(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFuturisticGuestsSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticDateCard({
    required String title,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ).createShader(bounds),
              child: Text(
                _formatDate(date),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticGuestsSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.2),
            AppTheme.primaryCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: AppTheme.primaryCyan,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'عدد الضيوف',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              _buildGuestControlButton(
                icon: Icons.remove_circle,
                onPressed: _guestsCount > 1
                    ? () {
                        setState(() {
                          _guestsCount--;
                        });
                        _loadUnits(context);
                        HapticFeedback.lightImpact();
                      }
                    : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _guestsCount.toString(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildGuestControlButton(
                icon: Icons.add_circle,
                onPressed: () {
                  setState(() {
                    _guestsCount++;
                  });
                  _loadUnits(context);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestControlButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: onPressed != null
                ? AppTheme.primaryCyan
                : AppTheme.textMuted.withOpacity(0.3),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticUnitCard(
    BuildContext context,
    Unit unit,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _selectUnit(context, unit),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryPurple.withOpacity(0.35)
                  : AppTheme.shadowDark.withOpacity(0.35),
              blurRadius: isSelected ? 22 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              _buildUnitImagesSection(unit, isSelected),
              _buildUnitInfoSection(unit, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitImagesSection(Unit unit, bool isSelected) {
    final isDarkMode = AppTheme.isDark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UnitGalleryPage(
              images: unit.images,
              initialIndex: 0,
              unitName: unit.name,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryPurple.withOpacity(0.35)
                  : AppTheme.shadowDark.withOpacity(0.35),
              blurRadius: isSelected ? 22 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          AppTheme.primaryPurple
                              .withOpacity(isDarkMode ? 0.20 : 0.24),
                          AppTheme.primaryCyan
                              .withOpacity(isDarkMode ? 0.16 : 0.20),
                        ]
                      : [
                          isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.85),
                          isDarkMode
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.65),
                        ],
                ),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryPurple.withOpacity(0.55)
                      : (isDarkMode
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.55)),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: unit.images.length,
                    itemBuilder: (context, index) {
                      final image = unit.images[index];
                      return Container(
                        width: 165,
                        margin: EdgeInsets.only(
                          right: index < unit.images.length - 1 ? 10 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryPurple.withOpacity(0.5)
                                : AppTheme.darkBorder.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ImageUtils.resolveUrl(image.url).isEmpty
                                  ? Container(
                                      color: AppTheme.darkSurface,
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color:
                                            AppTheme.textMuted.withOpacity(0.3),
                                      ),
                                    )
                                  : Image.network(
                                      ImageUtils.resolveUrl(image.url),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: AppTheme.darkSurface,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: AppTheme.textMuted
                                                .withOpacity(0.3),
                                          ),
                                        );
                                      },
                                    ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.05),
                                      AppTheme.darkBackground.withOpacity(0.65),
                                    ],
                                  ),
                                ),
                              ),
                              if (image.isMain)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue
                                              .withOpacity(0.45),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'رئيسية',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (index == 0 && isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.45),
                                          blurRadius: 9,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkBackground.withOpacity(0.95),
                            AppTheme.darkCard.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.35),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections_outlined,
                            size: 14,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'عرض ${unit.images.length} صور',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.darkBackground.withOpacity(0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                                color: AppTheme.primaryPurple.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppTheme.darkBackground.withOpacity(0.85),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppTheme.primaryPurple.withOpacity(0.7),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildUnitInfoSection(Unit unit, bool isSelected) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard.withOpacity(0.96),
            AppTheme.darkSurface.withOpacity(0.98),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(22),
        ),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.55)
              : AppTheme.darkBorder.withOpacity(0.8),
          width: isSelected ? 1.2 : 0.9,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => isSelected
                            ? AppTheme.primaryGradient.createShader(bounds)
                            : LinearGradient(
                                colors: [
                                  AppTheme.textWhite,
                                  AppTheme.textWhite
                                ],
                              ).createShader(bounds),
                        child: Text(
                          unit.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unit.unitTypeName,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (unit.adultCapacity != null ||
                              unit.childrenCapacity != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryCyan.withOpacity(0.3),
                                    AppTheme.primaryCyan.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryCyan.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 11,
                                    color: AppTheme.primaryCyan,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${unit.adultCapacity ?? 0}${unit.childrenCapacity != null && unit.childrenCapacity! > 0 ? '+${unit.childrenCapacity}' : ''}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (unit.pricePerNight != null &&
                          unit.pricePerNight! > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.success.withOpacity(0.2),
                                AppTheme.success.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.success.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 18,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${unit.pricePerNight!.toStringAsFixed(0)} ${unit.currency ?? 'ريال'}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ' / ليلة',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              if (unit.totalPrice != null &&
                                  unit.totalPrice! > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: AppTheme.darkBorder.withOpacity(0.3),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'الإجمالي: ${unit.totalPrice!.toStringAsFixed(0)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: !isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.2)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: isSelected ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            if (unit.customFeatures.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.15),
                      AppTheme.primaryViolet.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unit.customFeatures,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (unit.fieldValues.isNotEmpty ||
                unit.dynamicFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildUnitFeaturesGrid(unit, isSelected),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitFeaturesGrid(Unit unit, bool isSelected) {
    final filterFields = _getFilterFields(unit);

    if (filterFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleFields = filterFields.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.3),
            AppTheme.darkSurface.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.8),
                      AppTheme.primaryCyan.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'المعلومات الأساسية',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: visibleFields.map((fieldData) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildDynamicFieldRow(
                  displayName: fieldData['displayName'],
                  value: fieldData['value'],
                  fieldType: fieldData['fieldTypeId'],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilterFields(Unit unit) {
    final List<Map<String, dynamic>> filterFields = [];

    for (final fieldValue in unit.fieldValues) {
      if (fieldValue.isPrimaryFilter == true) {
        filterFields.add({
          'displayName': fieldValue.displayName.isNotEmpty
              ? fieldValue.displayName
              : fieldValue.fieldName,
          'value': fieldValue.value,
          'fieldTypeId': fieldValue.fieldTypeId ?? 'text',
        });
      }
    }
    for (final group in unit.dynamicFields) {
      for (final field in group.fieldValues) {
        if (field.isPrimaryFilter == true) {
          filterFields.add({
            'displayName': field.displayName.isNotEmpty
                ? field.displayName
                : field.fieldName,
            'value': field.value,
            'fieldTypeId': field.fieldTypeId ?? 'text',
          });
        }
      }
    }

    if (filterFields.isNotEmpty) {
      return filterFields;
    }

    final List<Map<String, dynamic>> fallback = [];
    for (final fieldValue in unit.fieldValues) {
      if (fieldValue.value.isNotEmpty) {
        fallback.add({
          'displayName': fieldValue.displayName.isNotEmpty
              ? fieldValue.displayName
              : fieldValue.fieldName,
          'value': fieldValue.value,
          'fieldTypeId': fieldValue.fieldTypeId ?? 'text',
        });
      }
    }
    for (final group in unit.dynamicFields) {
      for (final field in group.fieldValues) {
        if (field.value.isNotEmpty) {
          fallback.add({
            'displayName': field.displayName.isNotEmpty
                ? field.displayName
                : field.fieldName,
            'value': field.value,
            'fieldTypeId': field.fieldTypeId ?? 'text',
          });
        }
      }
    }

    return fallback;
  }

  Widget _buildDynamicFieldRow({
    required String displayName,
    required dynamic value,
    required String fieldType,
  }) {
    final formattedValue = _formatDynamicFieldValue(value, fieldType);
    final icon = _getFieldTypeIcon(fieldType);
    final color = _getFieldTypeColor(fieldType);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // اسم الحقل على اليسار
        Flexible(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: color.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$displayName',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // القيمة على اليمين (أقصى الطرف المقابل)
        Flexible(
          flex: 1,
          child: Text(
            formattedValue,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDynamicFieldValue(dynamic value, String fieldType) {
    if (value == null || value.toString().isEmpty) {
      return 'غير محدد';
    }

    switch (fieldType) {
      case 'boolean':
        final boolValue = value.toString().toLowerCase();
        return (boolValue == 'true' || boolValue == '1' || boolValue == 'yes')
            ? 'نعم'
            : 'لا';

      case 'currency':
        if (value is num) {
          return '${value.toStringAsFixed(0)} ريال';
        }
        final numValue = double.tryParse(value.toString());
        if (numValue != null) {
          return '${numValue.toStringAsFixed(0)} ريال';
        }
        return '$value ريال';

      case 'date':
        try {
          DateTime date;
          if (value is DateTime) {
            date = value;
          } else {
            date = DateTime.parse(value.toString());
          }
          return DateFormat('dd/MM/yyyy').format(date);
        } catch (_) {
          return value.toString();
        }

      case 'number':
        if (value is num) {
          return value.toStringAsFixed(value is int ? 0 : 1);
        }
        return value.toString();

      case 'select':
      case 'text':
      case 'textarea':
        final strValue = value.toString();
        return strValue.length > 15
            ? '${strValue.substring(0, 15)}...'
            : strValue;

      case 'multiselect':
        if (value is List) {
          final items = value.take(2).join(', ');
          if (value.length > 2) {
            return '$items +${value.length - 2}';
          }
          return items;
        }
        return value.toString();

      case 'phone':
        final phone = value.toString();
        if (phone.length == 10) {
          return '${phone.substring(0, 4)} ${phone.substring(4)}';
        }
        return phone;

      case 'email':
        final email = value.toString();
        if (email.length > 20) {
          final parts = email.split('@');
          if (parts.length == 2) {
            final username = parts[0].length > 10
                ? '${parts[0].substring(0, 10)}...'
                : parts[0];
            return '$username@${parts[1]}';
          }
        }
        return email;

      case 'file':
      case 'image':
        return 'ملف مرفق';

      default:
        final strValue = value.toString();
        return strValue.length > 15
            ? '${strValue.substring(0, 15)}...'
            : strValue;
    }
  }

  IconData _getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'currency':
        return Icons.attach_money_rounded;
      case 'boolean':
        return Icons.toggle_on_rounded;
      case 'select':
        return Icons.arrow_drop_down_circle_rounded;
      case 'multiselect':
        return Icons.checklist_rounded;
      case 'date':
        return Icons.calendar_today_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getFieldTypeColor(String fieldType) {
    switch (fieldType) {
      case 'boolean':
        return AppTheme.info;
      case 'currency':
      case 'number':
        return AppTheme.success;
      case 'date':
        return AppTheme.primaryPurple;
      case 'select':
      case 'multiselect':
        return AppTheme.primaryPurple;
      case 'email':
        return AppTheme.primaryBlue;
      case 'phone':
        return AppTheme.primaryCyan;
      case 'file':
      case 'image':
        return AppTheme.warning;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Widget _buildFuturisticBottomBar() {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        if (state is PropertyUnitsLoaded && _selectedUnitId != null) {
          // اختيار الوحدة المحددة بطريقة آمنة بدون تعارض في الأنواع مع UnitModel
          final matchingUnits =
              state.units.where((unit) => unit.id == _selectedUnitId).toList();

          final selectedUnit = matchingUnits.isNotEmpty
              ? matchingUnits.first
              : state.units.first;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkSurface,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الوحدة المحددة',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedUnit.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الحالة',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ShaderMask(
                                  shaderCallback: (bounds) => AppTheme
                                      .primaryGradient
                                      .createShader(bounds),
                                  child: Text(
                                    'جاهز للحجز',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildGlowingButton(
                          onPressed: () =>
                              _proceedToBooking(context, selectedUnit),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'متابعة الحجز',
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFuturisticLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CubeLoaderPainter(
                    animationValue: _waveController.value,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري البحث عن الوحدات المتاحة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticError(BuildContext context, PropertyError state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.2),
              AppTheme.error.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGlowingButton(
              onPressed: () => _loadUnits(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 48,
                color: AppTheme.primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'لا توجد وحدات متاحة',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'في التواريخ المحددة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildGlowingButton(
              onPressed: () => _showDatePicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'تغيير التواريخ',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _loadUnits(BuildContext context) {
    context.read<PropertyBloc>().add(GetPropertyUnitsEvent(
          propertyId: widget.propertyId,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestsCount: _guestsCount,
          unitTypeId: _selectedUnitTypeId,
        ));
  }

  void _selectCheckInDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final isDark = AppTheme.isDark;
        final colorScheme = isDark
            ? ColorScheme.dark(
                primary: AppTheme.primaryBlue,
                surface: AppTheme.darkCard,
                onSurface: AppTheme.textWhite,
              )
            : ColorScheme.light(
                primary: AppTheme.primaryBlue,
                surface: AppTheme.lightSurface,
                onSurface: AppTheme.textDark,
              );
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        _checkInDate = date;
        if (_checkOutDate.isBefore(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
      _loadUnits(context);
    }
  }

  void _selectCheckOutDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final isDark = AppTheme.isDark;
        final colorScheme = isDark
            ? ColorScheme.dark(
                primary: AppTheme.primaryBlue,
                surface: AppTheme.darkCard,
                onSurface: AppTheme.textWhite,
              )
            : ColorScheme.light(
                primary: AppTheme.primaryBlue,
                surface: AppTheme.lightSurface,
                onSurface: AppTheme.textDark,
              );
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        _checkOutDate = date;
      });
      _loadUnits(context);
    }
  }

  void _showDatePicker(BuildContext context) {
    _selectCheckInDate(context);
  }

  void _showFilterDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final state = context.read<PropertyBloc>().state;
    if (state is! PropertyUnitsLoaded) {
      return;
    }
    final units = state.units;
    if (units.isEmpty) {
      return;
    }
    final Map<String, String> types = {};
    for (final u in units) {
      types[u.unitTypeId] = u.unitTypeName;
    }
    final entries = types.entries.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نوع الوحدة',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.textMuted,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(
                      'كل الوحدات',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _selectedUnitTypeId == null
                            ? AppTheme.textWhite
                            : AppTheme.textMuted,
                      ),
                    ),
                    selected: _selectedUnitTypeId == null,
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.4),
                    backgroundColor: AppTheme.darkBackground.withOpacity(0.6),
                    onSelected: (v) {
                      setState(() {
                        _selectedUnitTypeId = null;
                      });
                      Navigator.of(ctx).pop();
                      _loadUnits(context);
                    },
                  ),
                  for (final e in entries)
                    ChoiceChip(
                      label: Text(
                        e.value,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _selectedUnitTypeId == e.key
                              ? AppTheme.textWhite
                              : AppTheme.textMuted,
                        ),
                      ),
                      selected: _selectedUnitTypeId == e.key,
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.5),
                      backgroundColor: AppTheme.darkBackground.withOpacity(0.6),
                      onSelected: (v) {
                        setState(() {
                          _selectedUnitTypeId = e.key;
                        });
                        Navigator.of(ctx).pop();
                        _loadUnits(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectUnit(BuildContext context, Unit unit) {
    setState(() {
      _selectedUnitId = unit.id;
    });
    context.read<PropertyBloc>().add(SelectUnitEvent(unitId: unit.id));
    HapticFeedback.mediumImpact();
  }

  void _proceedToBooking(BuildContext context, Unit unit) {
    HapticFeedback.heavyImpact();
    final selections = sl<FilterStorageService>().getHomeSelections();
    final DateTime? checkIn =
        selections['checkIn'] as DateTime? ?? _checkInDate;
    final DateTime? checkOut =
        selections['checkOut'] as DateTime? ?? _checkOutDate;
    final int adults = (selections['adults'] as int?) ?? _guestsCount;
    final int children = (selections['children'] as int?) ?? 0;

    context.push('/booking/form', extra: {
      'propertyId': widget.propertyId,
      'propertyName': widget.propertyName,
      'unitId': unit.id,
      'unitName': unit.name,
      'unitTypeName': unit.unitTypeName,
      'unitImages': unit.images.map((e) => e.url).toList(),
      'adultsCapacity': unit.adultCapacity,
      'childrenCapacity': unit.childrenCapacity,
      'customFeatures': unit.customFeatures,
      'services': widget.propertyServices,
      'policies': widget.propertyPolicies,
      'checkInDate': checkIn,
      'checkOutDate': checkOut,
      'adults': adults,
      'children': children,
    });
  }
}

class _FloatingCube {
  late double x;
  late double y;
  late double z;
  late double size;
  late double rotationSpeed;
  late Color color;
  late double opacity;

  _FloatingCube() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    z = math.Random().nextDouble() * 0.5 + 0.5;
    size = math.Random().nextDouble() * 20 + 15;
    rotationSpeed = math.Random().nextDouble() * 0.01 + 0.005;
    opacity = math.Random().nextDouble() * 0.05 + 0.02;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update(double animationValue) {
    y -= 0.0005;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

class _CubePainter extends CustomPainter {
  final List<_FloatingCube> cubes;
  final double animationValue;

  _CubePainter({
    required this.cubes,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var cube in cubes) {
      cube.update(animationValue);

      final center = Offset(
        cube.x * size.width,
        cube.y * size.height,
      );

      final rotation = animationValue * cube.rotationSpeed * 2 * math.pi;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            cube.color.withOpacity(cube.opacity),
            cube.color.withOpacity(cube.opacity * 0.5),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: cube.size,
          height: cube.size,
        ))
        ..style = PaintingStyle.fill;

      final path = Path()
        ..addRect(Rect.fromCenter(
          center: Offset.zero,
          width: cube.size * cube.z,
          height: cube.size * cube.z,
        ));

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CubeLoaderPainter extends CustomPainter {
  final double animationValue;

  _CubeLoaderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + animationValue * 360) * math.pi / 180;
      const radius = 25.0;

      final cubeCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final paint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(
          Rect.fromCenter(center: cubeCenter, width: 12, height: 12),
        )
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(cubeCenter.dx, cubeCenter.dy);
      canvas.rotate(animationValue * 2 * math.pi);

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 12),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
