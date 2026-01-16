import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hggzk/features/property/domain/entities/property_detail.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/filter_storage_service.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/property_header_widget.dart';
import '../widgets/property_images_grid_widget.dart';
import '../widgets/property_info_widget.dart';
import '../widgets/amenities_grid_widget.dart';
import '../widgets/units_list_widget.dart';
import '../widgets/reviews_summary_widget.dart';
import '../widgets/policies_widget.dart';
import '../widgets/location_map_widget.dart';
import '../../../../services/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;
  final String? userId;
  final String? unitId;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
    this.userId,
    this.unitId,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingHeaderController;
  late AnimationController _particleController;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  double _scrollOffset = 0;
  int _currentTabIndex = 0;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<_AnimatedParticle> _particles = [];

  // إنشاء Bloc instance واحد فقط ويبقى طوال حياة الصفحة
  late PropertyBloc _propertyBloc;

  // متغيرات لمنع Loop اللانهائي وتحسين الأداء
  bool _hasInitializedUnit = false;
  List<dynamic>? _cachedUnits;
  String? _cachedPropertyId;

  @override
  void initState() {
    super.initState();

    // إنشاء Bloc instance واحد فقط
    _propertyBloc = sl<PropertyBloc>()
      ..add(GetPropertyDetailsEvent(
        propertyId: widget.propertyId,
        userId: (sl<LocalStorageService>().getData(StorageConstants.userId) ??
                widget.userId)
            ?.toString(),
        userRole: sl<LocalStorageService>()
            .getData(StorageConstants.accountRole)
            ?.toString(),
      ))
      ..add(UpdateViewCountEvent(propertyId: widget.propertyId));

    _initializeAnimations();
    _generateParticles();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatingHeaderController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
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

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 5; i++) {
      _particles.add(_AnimatedParticle());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _propertyBloc.close(); // إغلاق الـ Bloc عند dispose
    _tabController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingHeaderController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      final shouldShow = _scrollOffset > 200;

      if (shouldShow != _showFloatingHeader) {
        _showFloatingHeader = shouldShow;
        if (_showFloatingHeader) {
          _floatingHeaderController.forward();
        } else {
          _floatingHeaderController.reverse();
        }
      }
    });
  }

  Widget _buildFuturisticBottomBarFromState(
      BuildContext context, PropertyState state) {
    final detailsState = state is PropertyWithDetails
        ? PropertyDetailsLoaded(
            property: state.property,
            isFavorite: state.isFavorite,
            selectedImageIndex: state.selectedImageIndex,
            selectedUnitId: state.selectedUnitId,
          )
        : state as PropertyDetailsLoaded;
    final units = state is PropertyWithDetails
        ? state.units
        : detailsState.property.units;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: _buildBookNowButton(context, state, units),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PropertyBloc>.value(
      value:
          _propertyBloc, // استخدام الـ instance الموجود بدلاً من إنشاء واحد جديد
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        bottomNavigationBar: BlocBuilder<PropertyBloc, PropertyState>(
          buildWhen: (previous, current) => current is! PropertyFavoriteUpdated,
          builder: (context, state) {
            if (state is PropertyDetailsLoaded ||
                state is PropertyWithDetails) {
              return _buildFuturisticBottomBarFromState(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildParticles(),
            BlocBuilder<PropertyBloc, PropertyState>(
              buildWhen: (previous, current) =>
                  current is! PropertyFavoriteUpdated,
              builder: (context, state) {
                if (state is PropertyLoading) {
                  return _buildFuturisticLoader();
                }

                if (state is PropertyError) {
                  return _buildFuturisticError(context, state);
                }

                if (state is PropertyDetailsLoaded) {
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildFuturisticSliverAppBar(context, state),
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 0),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PropertyHeaderWidget(
                                          property: state.property,
                                          isFavorite: state.isFavorite,
                                          isFavoritePending:
                                              state.isFavoritePending,
                                          onFavoriteToggle: () =>
                                              _toggleFavorite(context, state),
                                          onShare: () => _shareProperty(state),
                                        ),
                                        _buildFuturisticTabBar(),
                                        _buildFuturisticTabContentFromState(
                                            state),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showFloatingHeader)
                        _buildFuturisticFloatingHeader(context, state),
                    ],
                  );
                }

                if (state is PropertyWithDetails) {
                  final detailsState = PropertyDetailsLoaded(
                    property: state.property,
                    isFavorite: state.isFavorite,
                    selectedImageIndex: state.selectedImageIndex,
                    selectedUnitId: state.selectedUnitId,
                    isFavoritePending: state.isFavoritePending,
                    queuedFavoriteTarget: state.queuedFavoriteTarget,
                    availability: state.availability,
                  );
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildFuturisticSliverAppBar(context, detailsState),
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 0),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PropertyHeaderWidget(
                                          property: detailsState.property,
                                          isFavorite: detailsState.isFavorite,
                                          isFavoritePending:
                                              detailsState.isFavoritePending,
                                          onFavoriteToggle: () =>
                                              _toggleFavorite(
                                                  context, detailsState),
                                          onShare: () =>
                                              _shareProperty(detailsState),
                                        ),
                                        _buildFuturisticTabBar(),
                                        _buildFuturisticTabContentFromState(
                                            state),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showFloatingHeader)
                        _buildFuturisticFloatingHeader(context, detailsState),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkSurface,
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.7, -0.9),
            radius: 1.3,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.18),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticles() {
    // تم تبسيط الخلفية بإزالة الطبقة المتحركة لإعطاء إحساس أكثر هدوءًا ورقيًا
    return const SizedBox.shrink();
  }

  Widget _buildFuturisticLoader() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل تفاصيل العقار',
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
              AppTheme.darkCard.withOpacity(0.8),
              AppTheme.darkCard.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGlowingButton(
              onPressed: () {
                _propertyBloc.add(
                  GetPropertyDetailsEvent(
                    propertyId: widget.propertyId,
                    userId: widget.userId,
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.buttonMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticSliverAppBar(
      BuildContext context, PropertyDetailsLoaded state) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _buildGlassBackButton(context),
      actions: const [],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.biggest.height;
          const minHeight = kToolbarHeight + 16;
          final t =
              ((maxHeight - minHeight) / (320 - minHeight)).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'property_${state.property.id}',
                child: PropertyImagesGridWidget(
                  images: state.property.images,
                  onImageTap: (index) => _openGallery(context, state, index),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1 * t),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Opacity(
                  opacity: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.property.name,
                        style: AppTextStyles.h3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              state.property.address,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.35),
                                width: 0.7,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.property.averageRating
                                      .toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${state.property.reviewsCount})',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.25),
                                width: 0.7,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.apartment,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.property.city ?? '',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
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
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (color ?? AppTheme.primaryBlue).withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 16),
              color: color ?? AppTheme.textWhite,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticTabBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        labelColor: AppTheme.textWhite,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        labelStyle: AppTextStyles.bodySmall,
        unselectedLabelStyle: AppTextStyles.caption,
        overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.02)),
        tabs: [
          _buildFuturisticTab('نظرة عامة', Icons.info_outline, 0),
          _buildFuturisticTab('المرافق', Icons.star_border, 1),
          _buildFuturisticTab('التقييمات', Icons.rate_review, 2),
          _buildFuturisticTab('الموقع', Icons.location_on, 3),
        ],
      ),
    );
  }

  Widget _buildFuturisticTab(String label, IconData icon, int index) {
    final isSelected = _currentTabIndex == index;

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.5),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : AppTheme.textMuted.withOpacity(0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticTabContentFromState(PropertyState state) {
    final detailsState = state is PropertyWithDetails
        ? PropertyDetailsLoaded(
            property: state.property,
            isFavorite: state.isFavorite,
            selectedImageIndex: state.selectedImageIndex,
            selectedUnitId: state.selectedUnitId,
            availability: state.availability,
          )
        : state as PropertyDetailsLoaded;

    // لا AnimatedContainer حول TabBarView لتجنب إعادة حساب layout
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildOverviewTab(detailsState),
          _buildAmenitiesTab(detailsState),
          _buildReviewsTab(detailsState),
          _buildLocationTab(detailsState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(PropertyDetailsLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassContainer(
            child: PropertyInfoWidget(property: state.property),
          ),
          const SizedBox(height: 12),
          if (state.property.services.isNotEmpty) ...[
            _buildSectionTitle('الخدمات المتاحة', Icons.room_service),
            const SizedBox(height: 10),
            _buildServicesGrid(state),
            const SizedBox(height: 12),
          ],
          if (state.property.policies.isNotEmpty) ...[
            _buildSectionTitle('السياسات والقوانين', Icons.policy),
            const SizedBox(height: 10),
            _buildGlassContainer(
              child: PoliciesWidget(policies: state.property.policies),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsTabWithUnits(PropertyDetailsLoaded state,
      List<dynamic> units, String? selectedUnitId) {
    // Cache units to avoid cast overhead
    if (_cachedPropertyId != state.property.id || _cachedUnits == null) {
      _cachedPropertyId = state.property.id;
      _cachedUnits = units;
    }

    // التهيئة مرة واحدة فقط لمنع Loop اللانهائي
    if (!_hasInitializedUnit &&
        widget.unitId != null &&
        widget.unitId!.isNotEmpty) {
      _hasInitializedUnit = true;

      // تأخير بسيط لضمان اكتمال البناء
      Future.microtask(() {
        if (mounted) {
          _propertyBloc.add(SelectUnitEvent(unitId: widget.unitId!));
        }
      });

      // Scroll to the unit only once
      final index = units.indexWhere((u) => u.id == widget.unitId);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            const estimatedItemExtent = 240.0;
            final offset = (index * estimatedItemExtent).toDouble();
            _scrollController.animateTo(
              offset.clamp(0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
            );
          }
        });
      }
    }

    return UnitsListWidget(
      units: _cachedUnits!.cast(),
      selectedUnitId: selectedUnitId,
      onUnitSelect: (unit) => _selectUnit(context, unit),
    );
  }

  Widget _buildAmenitiesTab(PropertyDetailsLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: _buildGlassContainer(
        child: AmenitiesGridWidget(amenities: state.property.amenities),
      ),
    );
  }

  Widget _buildReviewsTab(PropertyDetailsLoaded state) {
    return ReviewsSummaryWidget(
      propertyId: state.property.id,
      reviewsCount: state.property.reviewsCount,
      averageRating: state.property.averageRating,
      onViewAll: () => _navigateToReviews(context, state),
    );
  }

  Widget _buildLocationTab(PropertyDetailsLoaded state) {
    return LocationMapWidget(
      latitude: state.property.latitude,
      longitude: state.property.longitude,
      propertyName: state.property.name,
      address: state.property.address,
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  //################### الخدمات
// تحديث دالة بناء الخدمات في Flutter

  Widget _buildServicesGrid(PropertyDetailsLoaded state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.property.services.map((service) {
        // الحصول على اللون بناءً على اسم الخدمة
        final serviceColor = _getServiceColorFromName(service.name);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                serviceColor.withOpacity(0.2),
                serviceColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: serviceColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getServiceIcon(service),
                size: 12,
                color: serviceColor.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                service.name,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite.withOpacity(0.9),
                ),
              ),
              if (service.price > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: serviceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${service.price.toStringAsFixed(0)} ${service.currency}',
                    style: AppTextStyles.caption.copyWith(
                      color: serviceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getServiceColorFromName(String serviceName) {
    // توليد hash ثابت من اسم الخدمة
    int hash = serviceName.hashCode;

    // قائمة الألوان المتاحة
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.primaryViolet,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.info,
    ];

    // اختيار لون بناءً على hash
    return colors[hash.abs() % colors.length];
  }

// دالة للحصول على أيقونة الخدمة الديناميكية
  IconData _getServiceIcon(PropertyService service) {
    // إذا كانت الخدمة تحتوي على أيقونة محددة من الخادم
    if (service.icon.isNotEmpty) {
      return _getIconFromServiceName(service.icon);
    }

    // وإلا استخدم الأيقونة الافتراضية بناءً على الاسم
    final name = service.name.toLowerCase();
    if (name.contains('تنظيف') || name.contains('cleaning'))
      return Icons.cleaning_services;
    if (name.contains('غسيل') || name.contains('laundry'))
      return Icons.local_laundry_service;
    if (name.contains('طعام') || name.contains('food')) return Icons.restaurant;
    if (name.contains('إفطار') || name.contains('breakfast'))
      return Icons.breakfast_dining;
    if (name.contains('غداء') || name.contains('lunch'))
      return Icons.lunch_dining;
    if (name.contains('عشاء') || name.contains('dinner'))
      return Icons.dinner_dining;
    if (name.contains('نقل') || name.contains('transport'))
      return Icons.airport_shuttle;
    if (name.contains('تاكسي') || name.contains('taxi'))
      return Icons.local_taxi;
    if (name.contains('واي فاي') || name.contains('wifi')) return Icons.wifi;
    if (name.contains('سبا') || name.contains('spa')) return Icons.spa;
    if (name.contains('جيم') || name.contains('gym'))
      return Icons.fitness_center;
    if (name.contains('مسبح') || name.contains('pool')) return Icons.pool;

    return Icons.check_circle;
  }

// دالة لتحويل اسم الأيقونة من السلسلة النصية إلى IconData
  IconData _getIconFromServiceName(String iconName) {
    // خريطة شاملة لتحويل أسماء أيقونات الخدمات إلى Material Icons
    final iconMap = <String, IconData>{
      // خدمات التنظيف
      'cleaning_services': Icons.cleaning_services,
      'dry_cleaning': Icons.dry_cleaning,
      'local_laundry_service': Icons.local_laundry_service,
      'iron': Icons.iron,
      'wash': Icons.wash,
      'soap': Icons.soap,
      'plumbing': Icons.plumbing,

      // خدمات الطعام والضيافة
      'room_service': Icons.room_service,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'delivery_dining': Icons.delivery_dining,
      'takeout_dining': Icons.takeout_dining,
      'ramen_dining': Icons.ramen_dining,
      'icecream': Icons.icecream,
      'cake': Icons.cake,
      'local_pizza': Icons.local_pizza,
      'fastfood': Icons.fastfood,

      // خدمات النقل
      'airport_shuttle': Icons.airport_shuttle,
      'local_taxi': Icons.local_taxi,
      'car_rental': Icons.car_rental,
      'car_repair': Icons.car_repair,
      'directions_car': Icons.directions_car,
      'directions_bus': Icons.directions_bus,
      'directions_boat': Icons.directions_boat,
      'directions_bike': Icons.directions_bike,
      'electric_bike': Icons.electric_bike,
      'electric_scooter': Icons.electric_scooter,
      'local_shipping': Icons.local_shipping,
      'local_parking': Icons.local_parking,

      // خدمات الاتصالات
      'wifi': Icons.wifi,
      'wifi_calling': Icons.wifi_calling,
      'router': Icons.router,
      'phone_in_talk': Icons.phone_in_talk,
      'phone_callback': Icons.phone_callback,
      'support_agent': Icons.support_agent,
      'headset_mic': Icons.headset_mic,
      'mail': Icons.mail,
      'markunread_mailbox': Icons.markunread_mailbox,
      'print': Icons.print,
      'scanner': Icons.scanner,
      'fax': Icons.fax,

      // خدمات الترفيه
      'spa': Icons.spa,
      'hot_tub': Icons.hot_tub,
      'pool': Icons.pool,
      'fitness_center': Icons.fitness_center,
      'sports_tennis': Icons.sports_tennis,
      'sports_golf': Icons.sports_golf,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'casino': Icons.casino,
      'theater_comedy': Icons.theater_comedy,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'nightlife': Icons.nightlife,
      'celebration': Icons.celebration,

      // خدمات الأعمال
      'business_center': Icons.business_center,
      'meeting_room': Icons.meeting_room,
      'co_present': Icons.co_present,
      'groups': Icons.groups,
      'event': Icons.event,
      'event_available': Icons.event_available,
      'event_seat': Icons.event_seat,
      'mic': Icons.mic,
      'videocam': Icons.videocam,
      'desktop_windows': Icons.desktop_windows,
      'laptop': Icons.laptop,

      // خدمات صحية
      'medical_services': Icons.medical_services,
      'local_hospital': Icons.local_hospital,
      'local_pharmacy': Icons.local_pharmacy,
      'emergency': Icons.emergency,
      'vaccines': Icons.vaccines,
      'healing': Icons.healing,
      'monitor_heart': Icons.monitor_heart,
      'health_and_safety': Icons.health_and_safety,
      'masks': Icons.masks,
      'sanitizer': Icons.sanitizer,
      'psychology': Icons.psychology,
      'self_improvement': Icons.self_improvement,

      // خدمات التسوق
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'local_mall': Icons.local_mall,
      'local_grocery_store': Icons.local_grocery_store,
      'local_convenience_store': Icons.local_convenience_store,
      'store': Icons.store,
      'storefront': Icons.storefront,
      'local_offer': Icons.local_offer,
      'loyalty': Icons.loyalty,
      'card_giftcard': Icons.card_giftcard,

      // خدمات العائلة
      'child_care': Icons.child_care,
      'baby_changing_station': Icons.baby_changing_station,
      'child_friendly': Icons.child_friendly,
      'toys': Icons.toys,
      'stroller': Icons.stroller,
      'family_restroom': Icons.family_restroom,
      'escalator_warning': Icons.escalator_warning,
      'pregnant_woman': Icons.pregnant_woman,

      // حيوانات أليفة
      'pets': Icons.pets,

      // خدمات الأمان
      'security': Icons.security,
      'local_police': Icons.local_police,
      'shield': Icons.shield,
      'verified_user': Icons.verified_user,
      'lock': Icons.lock,
      'key': Icons.key,
      'doorbell': Icons.doorbell,
      'camera_alt': Icons.camera_alt,

      // خدمات مالية
      'local_atm': Icons.local_atm,
      'account_balance': Icons.account_balance,
      'currency_exchange': Icons.currency_exchange,
      'payment': Icons.payment,
      'credit_card': Icons.credit_card,
      'account_balance_wallet': Icons.account_balance_wallet,
      'savings': Icons.savings,

      // خدمات أخرى
      'handshake': Icons.handshake,
      'luggage': Icons.luggage,
      'umbrella': Icons.beach_access,
      'translate': Icons.translate,
      'tour': Icons.tour,
      'map': Icons.map,
      'info': Icons.info,
    };

    return iconMap[iconName] ?? Icons.check_circle;
  }

  //################### الخدمات
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticFloatingHeader(
      BuildContext context, PropertyDetailsLoaded state) {
    return AnimatedBuilder(
      animation: _floatingHeaderController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -90 * (1 - _floatingHeaderController.value)),
          child: Opacity(
            opacity: _floatingHeaderController.value.clamp(0.0, 1.0).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.96),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
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
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          _buildGlassBackButton(context),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.property.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 11,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        state.property.address,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        );
      },
    );
  }

  // Widget _buildFuturisticBottomBarFromState(
  //     BuildContext context, PropertyState state) {
  //   final detailsState = state is PropertyWithDetails
  //       ? PropertyDetailsLoaded(
  //           property: state.property,
  //           isFavorite: state.isFavorite,
  //           selectedImageIndex: state.selectedImageIndex,
  //           selectedUnitId: state.selectedUnitId,
  //         )
  //       : state as PropertyDetailsLoaded;
  //   final units = state is PropertyWithDetails
  //       ? state.units
  //       : detailsState.property.units;

  //   // استخراج معلومات التوفّر والتسعير من الحالة
  //   final availability = state is PropertyWithDetails
  //       ? state.availability
  //       : (state as PropertyDetailsLoaded).availability;
  //   final double? lowestPrice = availability?.minAvailablePrice;
  //   final String currency = availability?.currency ?? 'YER';
  //   final bool hasRealPrice = lowestPrice != null && lowestPrice > 0;

  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //         colors: [
  //           AppTheme.darkCard.withOpacity(0.95),
  //           AppTheme.darkSurface,
  //         ],
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppTheme.primaryBlue.withOpacity(0.2),
  //           blurRadius: 15,
  //           offset: const Offset(0, -3),
  //         ),
  //       ],
  //     ),
  //     child: ClipRRect(
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           child: SafeArea(
  //             top: false,
  //             child: Row(
  //               children: [
  //                 if (hasRealPrice) ...[
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Text(
  //                           'يبدأ من',
  //                           style: AppTextStyles.caption.copyWith(
  //                             color: AppTheme.textMuted,
  //                             fontSize: 10,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 2),
  //                         Row(
  //                           crossAxisAlignment: CrossAxisAlignment.baseline,
  //                           textBaseline: TextBaseline.alphabetic,
  //                           children: [
  //                             ShaderMask(
  //                               shaderCallback: (bounds) => AppTheme
  //                                   .primaryGradient
  //                                   .createShader(bounds),
  //                               child: Text(
  //                                 lowestPrice.toStringAsFixed(0),
  //                                 style: AppTextStyles.h2.copyWith(
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Colors.white,
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(width: 6),
  //                             Text(
  //                               '$currency / ليلة',
  //                               style: AppTextStyles.caption.copyWith(
  //                                 color: AppTheme.textMuted,
  //                                 fontSize: 10,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                 ],
  //                 // استخدام BlocBuilder لمراقبة تغييرات selectedUnitId
  //                 BlocBuilder<PropertyBloc, PropertyState>(
  //                   builder: (context, currentState) {
  //                     final selectedUnitId = currentState is PropertyWithDetails
  //                         ? currentState.selectedUnitId
  //                         : currentState is PropertyDetailsLoaded
  //                             ? currentState.selectedUnitId
  //                             : null;

  //                     // Debug: bottom bar selected unit
  //                     // print('[PropertyDetailsPage] Bottom bar - selectedUnitId: $selectedUnitId');

  //                     return selectedUnitId != null && selectedUnitId.isNotEmpty
  //                         ? _buildBookNowButton(
  //                             context, state, selectedUnitId, units)
  //                         : _buildSelectUnitMessage();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildGlowingButton({
    required VoidCallback? onPressed, // تغيير من VoidCallback إلى VoidCallback?
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
          onTap: onPressed, // سيقبل null الآن
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, PropertyDetailsLoaded state) {
    final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ??
            widget.userId ??
            '')
        .toString();
    _propertyBloc.add(
      ToggleFavoriteEvent(
        propertyId: state.property.id,
        userId: uid,
        isFavorite: state.isFavorite,
      ),
    );

    HapticFeedback.lightImpact();
  }

  void _shareProperty(PropertyDetailsLoaded state) {
    HapticFeedback.mediumImpact();
  }

  void _openGallery(
      BuildContext context, PropertyDetailsLoaded state, int index) {
    context.push(
      '/property/${state.property.id}/gallery',
      extra: {
        'images': state.property.images,
        'initialIndex': index,
      },
    );
  }

  void _selectUnit(BuildContext context, dynamic unit) {
    print('[PropertyDetailsPage] _selectUnit called: unitId=${unit.id}');
    print(
        '[PropertyDetailsPage] _propertyBloc state: ${_propertyBloc.state.runtimeType}');
    // إطلاق Event مباشرة للـ bloc instance بدلاً من context.read
    _propertyBloc.add(SelectUnitEvent(unitId: unit.id));
    HapticFeedback.lightImpact();
  }

  Widget _buildFuturisticUnitModal(
      BuildContext ctx, dynamic unit, BuildContext parentContext) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkSurface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                unit.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (unit.images.isNotEmpty)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedImageWidget(
                              imageUrl: unit.images.first.url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _loadUnitAvailability(unit),
                        builder: (context, snapshot) {
                          // تحديد حالة التحميل
                          final isLoading =
                              snapshot.connectionState != ConnectionState.done;
                          final hasData =
                              snapshot.hasData && snapshot.data != null;
                          final pricePerNight = hasData
                              ? (snapshot.data!['pricePerNight'] as num?)
                                  ?.toDouble()
                              : null;
                          final currency = hasData
                              ? (snapshot.data!['currency'] as String?) ?? 'YER'
                              : 'YER';

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue.withOpacity(0.1),
                                      AppTheme.primaryPurple.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  switchInCurve: Curves.easeOutBack,
                                  child: isLoading
                                      ? Container(
                                          key: const ValueKey('loading'),
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Column(
                                            children: [
                                              // مؤشر تحميل DNA متحرك صغير
                                              Container(
                                                height: 30,
                                                width: 100,
                                                child: CustomPaint(
                                                  painter:
                                                      _MiniDNALoaderPainter(
                                                    animationValue:
                                                        _particleController
                                                            .value,
                                                    color: AppTheme.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // نص التحميل مع نقاط متحركة
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'جاري التحقق من التوفر',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  // نقاط متحركة
                                                  TweenAnimationBuilder<int>(
                                                    tween: IntTween(
                                                        begin: 0, end: 3),
                                                    duration: const Duration(
                                                        milliseconds: 1500),
                                                    builder: (context, value,
                                                        child) {
                                                      String dots =
                                                          '.' * (value + 1);
                                                      return Text(
                                                        dots.padRight(3),
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                          color: AppTheme
                                                              .primaryBlue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                                    onEnd: () {
                                                      // إعادة تشغيل الأنيميشن
                                                      if (mounted &&
                                                          isLoading) {
                                                        setState(() {});
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          key: ValueKey('price_$pricePerNight'),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              TweenAnimationBuilder<double>(
                                                tween:
                                                    Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(
                                                    milliseconds: 600),
                                                curve: Curves.elasticOut,
                                                builder:
                                                    (context, value, child) {
                                                  return Transform.scale(
                                                    scale: value,
                                                    child: Opacity(
                                                      opacity: value,
                                                      child: ShaderMask(
                                                        shaderCallback:
                                                            (bounds) => AppTheme
                                                                .primaryGradient
                                                                .createShader(
                                                                    bounds),
                                                        child: Text(
                                                          (pricePerNight ?? 0)
                                                              .toStringAsFixed(
                                                                  0),
                                                          style: AppTextStyles
                                                              .h2
                                                              .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              TweenAnimationBuilder<double>(
                                                tween:
                                                    Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(
                                                    milliseconds: 800),
                                                curve: Curves.easeOut,
                                                builder:
                                                    (context, value, child) {
                                                  return Opacity(
                                                    opacity: value,
                                                    child: Text(
                                                      '$currency / ليلة',
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color:
                                                            AppTheme.textMuted,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildGlowingButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        final images = unit.images is List
                                            ? (unit.images as List)
                                                .map((e) =>
                                                    (e.url as String?) ?? '')
                                                .where((u) => u.isNotEmpty)
                                                .toList()
                                            : <String>[];
                                        // Read selected dates and guests to pass to booking form
                                        final selections =
                                            sl<FilterStorageService>()
                                                .getHomeSelections();
                                        final DateTime? checkIn =
                                            selections['checkIn'] as DateTime?;
                                        final DateTime? checkOut =
                                            selections['checkOut'] as DateTime?;
                                        final int adults =
                                            (selections['adults'] as int?) ?? 1;
                                        final int children =
                                            (selections['children'] as int?) ??
                                                0;

                                        // Ensure we always have propertyId; fall back to page's propertyId
                                        final String propertyId =
                                            (unit.propertyId is String &&
                                                    (unit.propertyId as String)
                                                        .isNotEmpty)
                                                ? unit.propertyId
                                                : widget.propertyId;
                                        // Best-effort property name from unit or bloc without blocking
                                        String propertyName =
                                            (unit.propertyName is String)
                                                ? unit.propertyName
                                                : '';
                                        if (propertyName.isEmpty) {
                                          final state = parentContext
                                              .read<PropertyBloc>()
                                              .state;
                                          if (state is PropertyDetailsLoaded) {
                                            propertyName = state.property.name;
                                          } else if (state
                                              is PropertyWithDetails) {
                                            propertyName = state.property.name;
                                          }
                                        }

                                        // Try to extract services list from current property state
                                        List<PropertyService>? services;
                                        final currentState = parentContext
                                            .read<PropertyBloc>()
                                            .state;
                                        if (currentState
                                            is PropertyDetailsLoaded) {
                                          services =
                                              currentState.property.services;
                                        } else if (currentState
                                            is PropertyWithDetails) {
                                          services =
                                              currentState.property.services;
                                        }

                                        parentContext.push(
                                          '/booking/form',
                                          extra: {
                                            'propertyId': propertyId,
                                            'propertyName': propertyName,
                                            'unitId': unit.id,
                                            'unitName': unit.name,
                                            'unitImages': images,
                                            if (pricePerNight != null)
                                              'pricePerNight': pricePerNight,
                                            // Pass currency so booking page can display it
                                            'currency': currency,
                                            'unitTypeName': unit.unitTypeName,
                                            'adultsCapacity':
                                                unit.adultCapacity,
                                            'childrenCapacity':
                                                unit.childrenCapacity,
                                            'customFeatures':
                                                unit.customFeatures,
                                            if (checkIn != null)
                                              'checkInDate': checkIn,
                                            if (checkOut != null)
                                              'checkOutDate': checkOut,
                                            'adults': adults,
                                            'children': children,
                                            if (services != null)
                                              'services': services,
                                            'policies': currentState
                                                    is PropertyDetailsLoaded
                                                ? currentState.property.policies
                                                : currentState
                                                        is PropertyWithDetails
                                                    ? currentState
                                                        .property.policies
                                                    : [],
                                          },
                                        );
                                      },
                                child: AnimatedOpacity(
                                  opacity: isLoading ? 0.5 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'احجز هذه الوحدة',
                                        style:
                                            AppTextStyles.buttonMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
  }

  Future<Map<String, dynamic>?> _loadUnitAvailability(dynamic unit) async {
    try {
      final selections = sl<FilterStorageService>().getHomeSelections();
      final DateTime? checkIn = selections['checkIn'] as DateTime?;
      final DateTime? checkOut = selections['checkOut'] as DateTime?;
      final int adults = math.max(1, (selections['adults'] as int?) ?? 1);
      final int children = (selections['children'] as int?) ?? 0;

      if (checkIn == null || checkOut == null) {
        return null;
      }

      final api = sl<ApiClient>();
      final response = await api.post(
        '/api/client/units/check-availability',
        data: {
          'unitId': unit.id,
          'checkInDate': checkIn.toIso8601String(),
          'checkOutDate': checkOut.toIso8601String(),
          'adults': adults,
          'children': children,
        },
      );

      final body = response.data;
      Map<String, dynamic>? payload;
      if (body is Map<String, dynamic>) {
        payload = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
      }
      if (payload == null) return null;

      return {
        'isAvailable': payload['isAvailable'] as bool? ?? false,
        'totalPrice': (payload['totalPrice'] as num?)?.toDouble() ??
            (payload['total_price'] as num?)?.toDouble(),
        'currency': (payload['currency'] as String?) ?? 'YER',
        'pricePerNight': (payload['pricePerNight'] as num?)?.toDouble() ??
            (payload['price_per_night'] as num?)?.toDouble(),
        'nights':
            payload['numberOfNights'] as int? ?? payload['nights'] as int? ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  void _navigateToReviews(BuildContext context, PropertyDetailsLoaded state) {
    context.push(
      '/property/${state.property.id}/reviews',
      extra: state.property.name,
    );
  }

  void _navigateToBooking(BuildContext context, PropertyDetailsLoaded state) {
    context.push(
      '/booking/form',
      extra: {
        'propertyId': state.property.id,
        'propertyName': state.property.name,
        'services': state.property.services,
      },
    );
  }

  Widget _buildBookNowButton(
      BuildContext context, PropertyState state, List<dynamic> units) {
    final property = state is PropertyWithDetails
        ? state.property
        : (state as PropertyDetailsLoaded).property;

    return _buildGlowingButton(
      onPressed: () {
        // الانتقال لصفحة الوحدات لاختيار الوحدة
        context.push('/property/${property.id}/units', extra: {
          'propertyName': property.name,
          'units': units,
          'propertyServices': property.services,
          'propertyPolicies': property.policies,
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'احجز الآن',
            style: AppTextStyles.buttonMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectUnitMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 16,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'قم بتحديد الوحدة',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingWithUnit(
      BuildContext context, PropertyState state, dynamic selectedUnit) {
    final property = state is PropertyWithDetails
        ? state.property
        : (state as PropertyDetailsLoaded).property;

    // جلب التواريخ والضيوف من FilterStorageService
    final selections = sl<FilterStorageService>().getHomeSelections();
    final DateTime? checkIn = selections['checkIn'] as DateTime?;
    final DateTime? checkOut = selections['checkOut'] as DateTime?;
    final int adults = (selections['adults'] as int?) ?? 1;
    final int children = (selections['children'] as int?) ?? 0;

    // الانتقال لصفحة الحجز
    context.push('/booking/form', extra: {
      'propertyId': property.id,
      'propertyName': property.name,
      'unitId': selectedUnit.id,
      'unitName': selectedUnit.name,
      'unitTypeName': selectedUnit.unitTypeName,
      'unitImages': selectedUnit.images.map((e) => e.url).toList(),
      'adultsCapacity': selectedUnit.adultCapacity,
      'childrenCapacity': selectedUnit.childrenCapacity,
      'customFeatures': selectedUnit.customFeatures,
      // pricePerNight and currency are resolved later via availability check
      'services': property.services,
      'policies': property.policies,
      'checkInDate': checkIn,
      'checkOutDate': checkOut,
      'adults': adults,
      'children': children,
    });
  }
}

// كلاسات الـ Painters بدون تغيير ولكن بأحجام أصغر
class _AnimatedParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double radius;
  late double opacity;
  late Color color;

  _AnimatedParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.0005;
    vy = (math.Random().nextDouble() - 0.5) * 0.0005;
    radius = math.Random().nextDouble() * 1.5 + 0.5;
    opacity = math.Random().nextDouble() * 0.2 + 0.05;

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

    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_AnimatedParticle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniDNALoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _MiniDNALoaderPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pointCount = 8;
    final waveHeight = size.height / 3;
    final dx = size.width / (pointCount - 1);

    for (int j = 0; j < 2; j++) {
      final path = Path();
      final paint = Paint()
        ..color = color.withOpacity(0.6 - (j * 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < pointCount; i++) {
        final x = i * dx;
        final angle =
            (i / pointCount) * 2 * math.pi + (animationValue * 2 * math.pi);
        final y =
            size.height / 2 + math.sin(angle + (j * math.pi)) * waveHeight;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);

      // رسم النقاط
      for (int i = 0; i < pointCount; i++) {
        final x = i * dx;
        final angle =
            (i / pointCount) * 2 * math.pi + (animationValue * 2 * math.pi);
        final y =
            size.height / 2 + math.sin(angle + (j * math.pi)) * waveHeight;

        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()
            ..color = color.withOpacity(0.8)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hggzk/features/property/domain/entities/property_detail.dart';
// import 'dart:ui';
// import 'dart:math' as math;
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/widgets/cached_image_widget.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/widgets/loading_widget.dart';
// import '../../../../injection_container.dart';
// import '../../../../core/network/api_client.dart';
// import '../../../../services/filter_storage_service.dart';
// import '../bloc/property_bloc.dart';
// import '../bloc/property_event.dart';
// import '../bloc/property_state.dart';
// import '../widgets/property_header_widget.dart';
// import '../widgets/property_images_grid_widget.dart';
// import '../widgets/property_info_widget.dart';
// import '../widgets/amenities_grid_widget.dart';
// import '../widgets/units_list_widget.dart';
// import '../widgets/reviews_summary_widget.dart';
// import '../widgets/policies_widget.dart';
// import '../widgets/location_map_widget.dart';
// import '../../../../services/local_storage_service.dart';
// import '../../../../core/constants/storage_constants.dart';

// class PropertyDetailsPage extends StatefulWidget {
//   final String propertyId;
//   final String? userId;
//   final String? unitId;

//   const PropertyDetailsPage({
//     super.key,
//     required this.propertyId,
//     this.userId,
//     this.unitId,
//   });

//   @override
//   State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
// }

// class _PropertyDetailsPageState extends State<PropertyDetailsPage>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   late AnimationController _fadeController;
//   late AnimationController _floatingHeaderController;

//   final ScrollController _scrollController = ScrollController();
//   bool _showFloatingHeader = false;
//   double _scrollOffset = 0;
//   int _currentTabIndex = 0;

//   late PropertyBloc _propertyBloc;

//   @override
//   void initState() {
//     super.initState();

//     _propertyBloc = sl<PropertyBloc>()
//       ..add(GetPropertyDetailsEvent(
//         propertyId: widget.propertyId,
//         userId: (sl<LocalStorageService>().getData(StorageConstants.userId) ??
//                 widget.userId)
//             ?.toString(),
//         userRole: sl<LocalStorageService>()
//             .getData(StorageConstants.accountRole)
//             ?.toString(),
//       ))
//       ..add(UpdateViewCountEvent(propertyId: widget.propertyId));

//     _initializeAnimations();
//     _tabController = TabController(length: 5, vsync: this);
//     _scrollController.addListener(_onScroll);

//     _tabController.addListener(() {
//       setState(() {
//         _currentTabIndex = _tabController.index;
//       });
//     });

//     if (widget.unitId != null && widget.unitId!.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _tabController.animateTo(1);
//         }
//       });
//     }

//     _startAnimations();
//   }

//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _floatingHeaderController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//   }

//   void _startAnimations() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _fadeController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _propertyBloc.close();
//     _tabController.dispose();
//     _scrollController.dispose();
//     _fadeController.dispose();
//     _floatingHeaderController.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     setState(() {
//       _scrollOffset = _scrollController.offset;
//       final shouldShow = _scrollOffset > 250;

//       if (shouldShow != _showFloatingHeader) {
//         _showFloatingHeader = shouldShow;
//         if (_showFloatingHeader) {
//           _floatingHeaderController.forward();
//         } else {
//           _floatingHeaderController.reverse();
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<PropertyBloc>.value(
//       value: _propertyBloc,
//       child: Scaffold(
//         backgroundColor: AppTheme.darkBackground,
//         bottomNavigationBar: BlocBuilder<PropertyBloc, PropertyState>(
//           buildWhen: (previous, current) => current is! PropertyFavoriteUpdated,
//           builder: (context, state) {
//             if (state is PropertyDetailsLoaded ||
//                 state is PropertyWithDetails) {
//               return _buildElegantBottomBar(context, state);
//             }
//             return const SizedBox.shrink();
//           },
//         ),
//         body: BlocBuilder<PropertyBloc, PropertyState>(
//           buildWhen: (previous, current) => current is! PropertyFavoriteUpdated,
//           builder: (context, state) {
//             if (state is PropertyLoading) {
//               return _buildElegantLoader();
//             }

//             if (state is PropertyError) {
//               return _buildElegantError(context, state);
//             }

//             if (state is PropertyDetailsLoaded ||
//                 state is PropertyWithDetails) {
//               final detailsState = state is PropertyWithDetails
//                   ? PropertyDetailsLoaded(
//                       property: state.property,
//                       isFavorite: state.isFavorite,
//                       selectedImageIndex: state.selectedImageIndex,
//                       selectedUnitId: state.selectedUnitId,
//                       isFavoritePending: state.isFavoritePending,
//                       queuedFavoriteTarget: state.queuedFavoriteTarget,
//                       availability: state.availability,
//                     )
//                   : state as PropertyDetailsLoaded;

//               return Stack(
//                 children: [
//                   CustomScrollView(
//                     controller: _scrollController,
//                     physics: const BouncingScrollPhysics(),
//                     slivers: [
//                       _buildElegantSliverAppBar(context, detailsState),
//                       SliverToBoxAdapter(
//                         child: FadeTransition(
//                           opacity: _fadeController,
//                           child: Column(
//                             children: [
//                               PropertyHeaderWidget(
//                                 property: detailsState.property,
//                                 isFavorite: detailsState.isFavorite,
//                                 isFavoritePending:
//                                     detailsState.isFavoritePending,
//                                 onFavoriteToggle: () =>
//                                     _toggleFavorite(context, detailsState),
//                                 onShare: () => _shareProperty(detailsState),
//                               ),
//                               _buildElegantTabBar(),
//                               _buildTabContent(
//                                 state is PropertyWithDetails
//                                     ? state
//                                     : detailsState,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (_showFloatingHeader)
//                     _buildElegantFloatingHeader(context, detailsState),
//                 ],
//               );
//             }

//             return const SizedBox.shrink();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildElegantLoader() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Elegant loading animation
//             TweenAnimationBuilder<double>(
//               tween: Tween(begin: 0.0, end: 1.0),
//               duration: const Duration(seconds: 2),
//               builder: (context, value, child) {
//                 return Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         AppTheme.primaryBlue.withOpacity(0.1),
//                         AppTheme.primaryPurple.withOpacity(0.1),
//                       ],
//                     ),
//                   ),
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       value: null,
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         AppTheme.primaryBlue,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'جاري تحميل تفاصيل العقار',
//               style: AppTextStyles.bodyLarge.copyWith(
//                 color: AppTheme.textWhite,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'يرجى الانتظار...',
//               style: AppTextStyles.caption.copyWith(
//                 color: AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildElegantError(BuildContext context, PropertyError state) {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(24),
//         padding: const EdgeInsets.all(32),
//         decoration: BoxDecoration(
//           gradient: AppTheme.cardGradient,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: AppTheme.error.withOpacity(0.2),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 gradient: RadialGradient(
//                   colors: [
//                     AppTheme.error.withOpacity(0.1),
//                     AppTheme.error.withOpacity(0.03),
//                   ],
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.error_outline_rounded,
//                 size: 32,
//                 color: AppTheme.error,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'حدث خطأ',
//               style: AppTextStyles.h3.copyWith(
//                 color: AppTheme.error,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               state.message,
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: AppTheme.textMuted,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Material(
//                 color: Colors.transparent,
//                 borderRadius: BorderRadius.circular(12),
//                 child: InkWell(
//                   onTap: () {
//                     _propertyBloc.add(
//                       GetPropertyDetailsEvent(
//                         propertyId: widget.propertyId,
//                         userId: widget.userId,
//                       ),
//                     );
//                   },
//                   borderRadius: BorderRadius.circular(12),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.refresh_rounded,
//                             size: 18, color: Colors.white),
//                         const SizedBox(width: 8),
//                         Text(
//                           'إعادة المحاولة',
//                           style: AppTextStyles.buttonMedium.copyWith(
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildElegantSliverAppBar(
//       BuildContext context, PropertyDetailsLoaded state) {
//     return SliverAppBar(
//       expandedHeight: 360,
//       pinned: true,
//       elevation: 0,
//       backgroundColor: AppTheme.darkCard.withOpacity(0.9),
//       systemOverlayStyle: SystemUiOverlayStyle.light,
//       leading: _buildGlassIconButton(
//         icon: Icons.arrow_back_ios_new_rounded,
//         onPressed: () => context.pop(),
//       ),
//       actions: [
//         _buildGlassIconButton(
//           icon: Icons.share_rounded,
//           onPressed: () => _shareProperty(state),
//         ),
//         _buildGlassIconButton(
//           icon: state.isFavorite
//               ? Icons.favorite_rounded
//               : Icons.favorite_border_rounded,
//           color: state.isFavorite ? AppTheme.error : null,
//           onPressed: state.isFavoritePending
//               ? null
//               : () => _toggleFavorite(context, state),
//         ),
//         const SizedBox(width: 8),
//       ],
//       flexibleSpace: LayoutBuilder(
//         builder: (context, constraints) {
//           final maxHeight = constraints.biggest.height;
//           const minHeight = kToolbarHeight + 36;
//           final t =
//               ((maxHeight - minHeight) / (360 - minHeight)).clamp(0.0, 1.0);

//           return Stack(
//             fit: StackFit.expand,
//             children: [
//               // Images
//               Hero(
//                 tag: 'property_${state.property.id}',
//                 child: PropertyImagesGridWidget(
//                   images: state.property.images,
//                   onImageTap: (index) => _openGallery(context, state, index),
//                 ),
//               ),
//               // Elegant gradient overlay
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withOpacity(0.3),
//                       Colors.black.withOpacity(0.7),
//                     ],
//                     stops: const [0.0, 0.6, 1.0],
//                   ),
//                 ),
//               ),
//               // Property info
//               Positioned(
//                 left: 20,
//                 right: 20,
//                 bottom: 20,
//                 child: AnimatedOpacity(
//                   opacity: t,
//                   duration: const Duration(milliseconds: 200),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         state.property.name,
//                         style: AppTextStyles.h2.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 26,
//                           letterSpacing: -0.5,
//                           shadows: [
//                             Shadow(
//                               offset: const Offset(0, 2),
//                               blurRadius: 8,
//                               color: Colors.black.withOpacity(0.3),
//                             ),
//                           ],
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on_rounded,
//                             size: 16,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               state.property.address,
//                               style: AppTextStyles.bodySmall.copyWith(
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontSize: 13,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           // Rating
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.3),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.2),
//                                 width: 0.5,
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.star_rounded,
//                                   size: 16,
//                                   color: AppTheme.warning,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   state.property.averageRating
//                                       .toStringAsFixed(1),
//                                   style: AppTextStyles.bodySmall.copyWith(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   '(${state.property.reviewsCount})',
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: Colors.white.withOpacity(0.8),
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // City
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.3),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.2),
//                                 width: 0.5,
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.location_city_rounded,
//                                   size: 14,
//                                   color: Colors.white.withOpacity(0.9),
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   state.property.city ?? '',
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: Colors.white.withOpacity(0.9),
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildGlassIconButton({
//     required IconData icon,
//     required VoidCallback? onPressed,
//     Color? color,
//   }) {
//     return Container(
//       margin: const EdgeInsets.all(8),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.darkCard.withOpacity(0.5),
//                   AppTheme.darkCard.withOpacity(0.3),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: (color ?? AppTheme.textLight).withOpacity(0.2),
//                 width: 0.5,
//               ),
//             ),
//             child: IconButton(
//               icon: Icon(icon, size: 20),
//               color: color ?? Colors.white,
//               onPressed: onPressed,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildElegantTabBar() {
//     return Container(
//       height: 56,
//       decoration: BoxDecoration(
//         color: AppTheme.darkCard.withOpacity(0.5),
//         border: Border(
//           bottom: BorderSide(
//             color: AppTheme.darkBorder.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//       ),
//       child: TabBar(
//         controller: _tabController,
//         isScrollable: false,
//         physics: const BouncingScrollPhysics(),
//         labelColor: AppTheme.textWhite,
//         unselectedLabelColor: AppTheme.textMuted,
//         indicatorColor: AppTheme.primaryBlue,
//         indicatorSize: TabBarIndicatorSize.label,
//         indicatorWeight: 2,
//         labelStyle: AppTextStyles.bodySmall.copyWith(
//           fontWeight: FontWeight.w600,
//         ),
//         unselectedLabelStyle: AppTextStyles.caption,
//         tabs: [
//           _buildTab('نظرة عامة', Icons.info_outline_rounded, 0),
//           _buildTab('الوحدات', Icons.meeting_room_rounded, 1),
//           _buildTab('المرافق', Icons.star_outline_rounded, 2),
//           _buildTab('التقييمات', Icons.rate_review_outlined, 3),
//           _buildTab('الموقع', Icons.location_on_outlined, 4),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(String label, IconData icon, int index) {
//     final isSelected = _currentTabIndex == index;

//     return Tab(
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 20,
//               color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabContent(PropertyState state) {
//     final detailsState = state is PropertyWithDetails
//         ? PropertyDetailsLoaded(
//             property: state.property,
//             isFavorite: state.isFavorite,
//             selectedImageIndex: state.selectedImageIndex,
//             selectedUnitId: state.selectedUnitId,
//             availability: state.availability,
//           )
//         : state as PropertyDetailsLoaded;
//     final units = state is PropertyWithDetails
//         ? state.units
//         : detailsState.property.units;

//     return Container(
//       height: MediaQuery.of(context).size.height * 0.5,
//       child: TabBarView(
//         controller: _tabController,
//         physics: const BouncingScrollPhysics(),
//         children: [
//           _buildOverviewTab(detailsState),
//           BlocBuilder<PropertyBloc, PropertyState>(
//             builder: (context, currentState) {
//               final selectedId = currentState is PropertyWithDetails
//                   ? currentState.selectedUnitId
//                   : currentState is PropertyDetailsLoaded
//                       ? currentState.selectedUnitId
//                       : null;
//               return _buildUnitsTab(detailsState, units, selectedId);
//             },
//           ),
//           _buildAmenitiesTab(detailsState),
//           _buildReviewsTab(detailsState),
//           _buildLocationTab(detailsState),
//         ],
//       ),
//     );
//   }

//   Widget _buildOverviewTab(PropertyDetailsLoaded state) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           PropertyInfoWidget(property: state.property),
//           if (state.property.services.isNotEmpty) ...[
//             _buildServicesSection(state),
//           ],
//           if (state.property.policies.isNotEmpty) ...[
//             PoliciesWidget(policies: state.property.policies),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildServicesSection(PropertyDetailsLoaded state) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppTheme.primaryCyan.withOpacity(0.1),
//                       AppTheme.primaryCyan.withOpacity(0.05),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.room_service_rounded,
//                   size: 20,
//                   color: AppTheme.primaryCyan,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'الخدمات المتاحة',
//                 style: AppTextStyles.h3.copyWith(
//                   color: AppTheme.textWhite,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: state.property.services.map((service) {
//               return Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppTheme.primaryBlue.withOpacity(0.08),
//                       AppTheme.primaryBlue.withOpacity(0.03),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: AppTheme.primaryBlue.withOpacity(0.15),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _getServiceIcon(service.name),
//                       size: 14,
//                       color: AppTheme.primaryBlue,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       service.name,
//                       style: AppTextStyles.caption.copyWith(
//                         color: AppTheme.textWhite,
//                         fontSize: 12,
//                       ),
//                     ),
//                     if (service.price > 0) ...[
//                       const SizedBox(width: 6),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryBlue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           '${service.price.toStringAsFixed(0)} ${service.currency}',
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.primaryBlue,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getServiceIcon(String serviceName) {
//     final name = serviceName.toLowerCase();
//     if (name.contains('تنظيف') || name.contains('cleaning'))
//       return Icons.cleaning_services_rounded;
//     if (name.contains('غسيل') || name.contains('laundry'))
//       return Icons.local_laundry_service_rounded;
//     if (name.contains('طعام') || name.contains('food'))
//       return Icons.restaurant_rounded;
//     if (name.contains('واي فاي') || name.contains('wifi'))
//       return Icons.wifi_rounded;
//     if (name.contains('نقل') || name.contains('transport'))
//       return Icons.airport_shuttle_rounded;
//     return Icons.check_circle_rounded;
//   }

//   Widget _buildUnitsTab(PropertyDetailsLoaded state, List<dynamic> units,
//       String? selectedUnitId) {
//     if (widget.unitId != null &&
//         widget.unitId!.isNotEmpty &&
//         selectedUnitId == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         _propertyBloc.add(SelectUnitEvent(unitId: widget.unitId!));
//       });
//     }

//     return UnitsListWidget(
//       units: units.cast(),
//       selectedUnitId: selectedUnitId,
//       onUnitSelect: (unit) => _selectUnit(context, unit),
//     );
//   }

//   Widget _buildAmenitiesTab(PropertyDetailsLoaded state) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.all(20),
//       child: AmenitiesGridWidget(amenities: state.property.amenities),
//     );
//   }

//   Widget _buildReviewsTab(PropertyDetailsLoaded state) {
//     return ReviewsSummaryWidget(
//       propertyId: state.property.id,
//       reviewsCount: state.property.reviewsCount,
//       averageRating: state.property.averageRating,
//       onViewAll: () => _navigateToReviews(context, state),
//     );
//   }

//   Widget _buildLocationTab(PropertyDetailsLoaded state) {
//     return LocationMapWidget(
//       latitude: state.property.latitude,
//       longitude: state.property.longitude,
//       propertyName: state.property.name,
//       address: state.property.address,
//     );
//   }

//   Widget _buildElegantFloatingHeader(
//       BuildContext context, PropertyDetailsLoaded state) {
//     return AnimatedBuilder(
//       animation: _floatingHeaderController,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, -80 * (1 - _floatingHeaderController.value)),
//           child: Opacity(
//             opacity: _floatingHeaderController.value,
//             child: ClipRRect(
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppTheme.darkCard.withOpacity(0.8),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppTheme.shadowDark.withOpacity(0.2),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: SafeArea(
//                     bottom: false,
//                     child: Container(
//                       height: 60,
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                                 size: 20),
//                             color: AppTheme.textWhite,
//                             onPressed: () => context.pop(),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   state.property.name,
//                                   style: AppTextStyles.bodyMedium.copyWith(
//                                     fontWeight: FontWeight.w600,
//                                     color: AppTheme.textWhite,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 Text(
//                                   state.property.address,
//                                   style: AppTextStyles.caption.copyWith(
//                                     color: AppTheme.textMuted,
//                                     fontSize: 11,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(
//                               state.isFavorite
//                                   ? Icons.favorite_rounded
//                                   : Icons.favorite_border_rounded,
//                               size: 20,
//                             ),
//                             color: state.isFavorite
//                                 ? AppTheme.error
//                                 : AppTheme.textWhite,
//                             onPressed: () => _toggleFavorite(context, state),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildElegantBottomBar(BuildContext context, PropertyState state) {
//     final detailsState = state is PropertyWithDetails
//         ? PropertyDetailsLoaded(
//             property: state.property,
//             isFavorite: state.isFavorite,
//             selectedImageIndex: state.selectedImageIndex,
//             selectedUnitId: state.selectedUnitId,
//           )
//         : state as PropertyDetailsLoaded;

//     final units = state is PropertyWithDetails
//         ? state.units
//         : detailsState.property.units;

//     final availability = state is PropertyWithDetails
//         ? state.availability
//         : (state as PropertyDetailsLoaded).availability;

//     final isLoadingPrice = availability == null;
//     final double? lowestPrice = availability?.minAvailablePrice;
//     final String currency = availability?.currency ?? 'YER';
//     final bool hasRealPrice = lowestPrice != null && lowestPrice > 0;

//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 AppTheme.darkCard.withOpacity(0.9),
//                 AppTheme.darkCard.withOpacity(0.95),
//               ],
//             ),
//             border: Border(
//               top: BorderSide(
//                 color: AppTheme.darkBorder.withOpacity(0.1),
//                 width: 1,
//               ),
//             ),
//           ),
//           child: SafeArea(
//             top: false,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   if (isLoadingPrice) ...[
//                     _buildPriceLoader(),
//                   ] else if (hasRealPrice) ...[
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'يبدأ من',
//                             style: AppTextStyles.caption.copyWith(
//                               color: AppTheme.textMuted,
//                               fontSize: 11,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.baseline,
//                             textBaseline: TextBaseline.alphabetic,
//                             children: [
//                               Text(
//                                 lowestPrice.toStringAsFixed(0),
//                                 style: AppTextStyles.h2.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                   color: AppTheme.textWhite,
//                                   fontSize: 24,
//                                 ),
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 '$currency / ليلة',
//                                 style: AppTextStyles.caption.copyWith(
//                                   color: AppTheme.textMuted,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ] else if (availability != null &&
//                       availability!.hasAvailableUnits == false) ...[
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'غير متاح',
//                             style: AppTextStyles.caption.copyWith(
//                               color: AppTheme.error,
//                               fontSize: 11,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'محجوز حالياً',
//                             style: AppTextStyles.bodyLarge.copyWith(
//                               color: AppTheme.error,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                   const SizedBox(width: 16),
//                   BlocBuilder<PropertyBloc, PropertyState>(
//                     builder: (context, currentState) {
//                       final selectedUnitId = currentState is PropertyWithDetails
//                           ? currentState.selectedUnitId
//                           : currentState is PropertyDetailsLoaded
//                               ? currentState.selectedUnitId
//                               : null;

//                       return selectedUnitId != null && selectedUnitId.isNotEmpty
//                           ? _buildBookButton(
//                               context, state, selectedUnitId, units)
//                           : _buildSelectUnitButton();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPriceLoader() {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'جاري التحقق من السعر',
//             style: AppTextStyles.caption.copyWith(
//               color: AppTheme.textMuted,
//               fontSize: 11,
//             ),
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
//             valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
//             minHeight: 2,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBookButton(BuildContext context, PropertyState state,
//       String selectedUnitId, List<dynamic> units) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: AppTheme.primaryGradient,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: AppTheme.primaryBlue.withOpacity(0.2),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(14),
//         child: InkWell(
//           onTap: () {
//             final selectedUnit =
//                 units.firstWhere((u) => u.id == selectedUnitId);
//             _navigateToBookingWithUnit(context, state, selectedUnit);
//           },
//           borderRadius: BorderRadius.circular(14),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24,
//               vertical: 14,
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.calendar_today_rounded,
//                     size: 18, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Text(
//                   'احجز الآن',
//                   style: AppTextStyles.buttonMedium.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSelectUnitButton() {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 20,
//         vertical: 12,
//       ),
//       decoration: BoxDecoration(
//         color: AppTheme.darkBorder.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: AppTheme.darkBorder.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.touch_app_rounded,
//             size: 18,
//             color: AppTheme.textMuted,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             'قم بتحديد الوحدة',
//             style: AppTextStyles.buttonMedium.copyWith(
//               color: AppTheme.textMuted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper methods
//   void _toggleFavorite(BuildContext context, PropertyDetailsLoaded state) {
//     final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ??
//             widget.userId ??
//             '')
//         .toString();
//     _propertyBloc.add(
//       ToggleFavoriteEvent(
//         propertyId: state.property.id,
//         userId: uid,
//         isFavorite: state.isFavorite,
//       ),
//     );
//     HapticFeedback.lightImpact();
//   }

//   void _shareProperty(PropertyDetailsLoaded state) {
//     HapticFeedback.lightImpact();
//     // TODO: Implement share functionality
//   }

//   void _openGallery(
//       BuildContext context, PropertyDetailsLoaded state, int index) {
//     context.push(
//       '/property/${state.property.id}/gallery',
//       extra: {
//         'images': state.property.images,
//         'initialIndex': index,
//       },
//     );
//   }

//   void _selectUnit(BuildContext context, dynamic unit) {
//     _propertyBloc.add(SelectUnitEvent(unitId: unit.id));
//     HapticFeedback.lightImpact();

//     // Show elegant unit modal
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => _buildElegantUnitModal(ctx, unit, context),
//     );
//   }

//   Widget _buildElegantUnitModal(
//       BuildContext ctx, dynamic unit, BuildContext parentContext) {
//     return Container(
//       height: MediaQuery.of(ctx).size.height * 0.7,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             AppTheme.darkCard,
//             AppTheme.darkSurface,
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Column(
//             children: [
//               Container(
//                 margin: const EdgeInsets.only(top: 12),
//                 width: 48,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: AppTheme.darkBorder.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               unit.name,
//                               style: AppTextStyles.h3.copyWith(
//                                 color: AppTheme.textWhite,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: AppTheme.primaryGradient,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               unit.unitTypeName,
//                               style: AppTextStyles.caption.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 11,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       if (unit.images.isNotEmpty)
//                         Container(
//                           height: 200,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: CachedImageWidget(
//                               imageUrl: unit.images.first.url,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       const SizedBox(height: 20),
//                       FutureBuilder<Map<String, dynamic>?>(
//                         future: _loadUnitAvailability(unit),
//                         builder: (context, snapshot) {
//                           final isLoading =
//                               snapshot.connectionState != ConnectionState.done;
//                           final hasData =
//                               snapshot.hasData && snapshot.data != null;
//                           final pricePerNight = hasData
//                               ? (snapshot.data!['pricePerNight'] as num?)
//                                   ?.toDouble()
//                               : null;
//                           final currency = hasData
//                               ? (snapshot.data!['currency'] as String?) ?? 'YER'
//                               : 'YER';

//                           return Column(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       AppTheme.primaryBlue.withOpacity(0.08),
//                                       AppTheme.primaryBlue.withOpacity(0.03),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color:
//                                         AppTheme.primaryBlue.withOpacity(0.15),
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: isLoading
//                                     ? Center(
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           valueColor:
//                                               AlwaysStoppedAnimation<Color>(
//                                             AppTheme.primaryBlue,
//                                           ),
//                                         ),
//                                       )
//                                     : Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Text(
//                                             (pricePerNight ?? 0)
//                                                 .toStringAsFixed(0),
//                                             style:
//                                                 AppTextStyles.h2.copyWith(
//                                               fontWeight: FontWeight.w700,
//                                               color: AppTheme.textWhite,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Text(
//                                             '$currency / ليلة',
//                                             style: AppTextStyles.bodySmall
//                                                 .copyWith(
//                                               color: AppTheme.textMuted,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                               const SizedBox(height: 20),
//                               Container(
//                                 width: double.infinity,
//                                 decoration: BoxDecoration(
//                                   gradient: AppTheme.primaryGradient,
//                                   borderRadius: BorderRadius.circular(14),
//                                 ),
//                                 child: Material(
//                                   color: Colors.transparent,
//                                   borderRadius: BorderRadius.circular(14),
//                                   child: InkWell(
//                                     onTap: isLoading
//                                         ? null
//                                         : () {
//                                             Navigator.pop(ctx);
//                                             _navigateToBooking(context, unit,
//                                                 pricePerNight, currency);
//                                           },
//                                     borderRadius: BorderRadius.circular(14),
//                                     child: Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 16),
//                                       child: Center(
//                                         child: Text(
//                                           'احجز هذه الوحدة',
//                                           style: AppTextStyles.buttonMedium
//                                               .copyWith(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<Map<String, dynamic>?> _loadUnitAvailability(dynamic unit) async {
//     try {
//       final selections = sl<FilterStorageService>().getHomeSelections();
//       final DateTime? checkIn = selections['checkIn'] as DateTime?;
//       final DateTime? checkOut = selections['checkOut'] as DateTime?;
//       final int adults = math.max(1, (selections['adults'] as int?) ?? 1);
//       final int children = (selections['children'] as int?) ?? 0;

//       if (checkIn == null || checkOut == null) {
//         return null;
//       }

//       final api = sl<ApiClient>();
//       final response = await api.post(
//         '/api/client/units/check-availability',
//         data: {
//           'unitId': unit.id,
//           'checkInDate': checkIn.toIso8601String(),
//           'checkOutDate': checkOut.toIso8601String(),
//           'adults': adults,
//           'children': children,
//         },
//       );

//       final body = response.data;
//       Map<String, dynamic>? payload;
//       if (body is Map<String, dynamic>) {
//         payload = (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
//       }
//       if (payload == null) return null;

//       return {
//         'isAvailable': payload['isAvailable'] as bool? ?? false,
//         'totalPrice': (payload['totalPrice'] as num?)?.toDouble() ??
//             (payload['total_price'] as num?)?.toDouble(),
//         'currency': (payload['currency'] as String?) ?? 'YER',
//         'pricePerNight': (payload['pricePerNight'] as num?)?.toDouble() ??
//             (payload['price_per_night'] as num?)?.toDouble(),
//         'nights':
//             payload['numberOfNights'] as int? ?? payload['nights'] as int? ?? 0,
//       };
//     } catch (_) {
//       return null;
//     }
//   }

//   void _navigateToReviews(BuildContext context, PropertyDetailsLoaded state) {
//     context.push(
//       '/property/${state.property.id}/reviews',
//       extra: state.property.name,
//     );
//   }

//   void _navigateToBooking(BuildContext context, dynamic unit,
//       double? pricePerNight, String currency) {
//     final state = _propertyBloc.state;
//     final property = state is PropertyWithDetails
//         ? state.property
//         : (state as PropertyDetailsLoaded).property;

//     final selections = sl<FilterStorageService>().getHomeSelections();

//     context.push('/booking/form', extra: {
//       'propertyId': property.id,
//       'propertyName': property.name,
//       'unitId': unit.id,
//       'unitName': unit.name,
//       'unitTypeName': unit.unitTypeName,
//       'unitImages': unit.images.map((e) => e.url).toList(),
//       'pricePerNight': pricePerNight,
//       'currency': currency,
//       'services': property.services,
//       'policies': property.policies,
//       'checkInDate': selections['checkIn'],
//       'checkOutDate': selections['checkOut'],
//       'adults': selections['adults'] ?? 1,
//       'children': selections['children'] ?? 0,
//     });
//   }

//   void _navigateToBookingWithUnit(
//       BuildContext context, PropertyState state, dynamic selectedUnit) {
//     final property = state is PropertyWithDetails
//         ? state.property
//         : (state as PropertyDetailsLoaded).property;

//     final selections = sl<FilterStorageService>().getHomeSelections();

//     context.push('/booking/form', extra: {
//       'propertyId': property.id,
//       'propertyName': property.name,
//       'unitId': selectedUnit.id,
//       'unitName': selectedUnit.name,
//       'unitTypeName': selectedUnit.unitTypeName,
//       'unitImages': selectedUnit.images.map((e) => e.url).toList(),
//       'adultsCapacity': selectedUnit.adultCapacity,
//       'childrenCapacity': selectedUnit.childrenCapacity,
//       'customFeatures': selectedUnit.customFeatures,
//       'services': property.services,
//       'policies': property.policies,
//       'checkInDate': selections['checkIn'],
//       'checkOutDate': selections['checkOut'],
//       'adults': selections['adults'] ?? 1,
//       'children': selections['children'] ?? 0,
//     });
//   }
// }
