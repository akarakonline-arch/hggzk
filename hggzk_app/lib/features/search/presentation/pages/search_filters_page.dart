// lib/features/search/presentation/pages/ultra_refined_search_filters_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hggzk/features/search/domain/entities/search_result.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_state.dart';
import '../bloc/search_event.dart';
import '../../../../services/data_sync_service.dart';
import '../../../../injection_container.dart';
import 'package:hggzk/features/search/data/models/search_filter_model.dart';
import '../widgets/futuristic_filter_type_card.dart';

class SearchFiltersPage extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const SearchFiltersPage({
    super.key,
    this.initialFilters,
  });

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends State<SearchFiltersPage>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _filters;
  final ScrollController _scrollController = ScrollController();

  // Data services
  late DataSyncService _dataSyncService;

  // Data state
  List<dynamic> _propertyTypes = [];
  List<dynamic> _unitTypes = [];
  bool _isLoadingData = false;

  // Validation state
  bool _isValidFilter = false;
  String _validationError = '';
  Map<String, bool> _requiredFieldsStatus = {};

  // Ultra Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _floatingController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _waveController;

  // Animations
  late Animation<double> _entranceAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;

  // Active filters tracking
  int _activeFilterCount = 0;

  // Floating particles
  final List<_NanoParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters ?? {});

    // ✅ FIX: تعيين العملة الافتراضية إذا لم تكن موجودة
    _filters['preferredCurrency'] ??= 'YER';

    _dataSyncService = sl<DataSyncService>();
    _initializeAnimations();
    _generateParticles();
    _calculateActiveFilters();
    _loadFilters();
    _loadLocalData();
    _validateFilters();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutExpo,
    );

    _floatingAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _entranceController.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_NanoParticle());
    }
  }

  bool _validateFilters() {
    setState(() {
      _validationError = '';
      _requiredFieldsStatus.clear();
      _isValidFilter = true;
    });
    setState(() {
      _isValidFilter = true;
      _validationError = '';
    });
    return true;
  }

  void _loadFilters() {
    final bloc = context.read<SearchBloc>();
    if (bloc.state is! SearchFiltersLoaded) {
      bloc.add(const GetSearchFiltersEvent());
    }
  }

  void _loadLocalData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      if (!_dataSyncService.hasCachedData() ||
          !_dataSyncService.isDataValid()) {
        await _dataSyncService.syncAllData();
      }

      final propertyTypes = await _dataSyncService.getPropertyTypes();
      setState(() {
        _propertyTypes = propertyTypes;
      });

      if (_filters['propertyTypeId'] != null) {
        _loadUnitTypesForPropertyType(_filters['propertyTypeId']);
      }

    } catch (e) {
      print('Error loading local data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _loadUnitTypesForPropertyType(String propertyTypeId) async {
    try {
      final unitTypeModels =
          await _dataSyncService.getUnitTypes(propertyTypeId: propertyTypeId);
      final filterModels = unitTypeModels
          .map((m) => UnitTypeFilterModel(
                id: m.id,
                name: m.name,
                unitsCount: 0,
                propertyTypeId: m.propertyTypeId,
                isHasAdults: m.isHasAdults,
                isHasChildren: m.isHasChildren,
              ))
          .toList();
      setState(() {
        _unitTypes = filterModels;
      });
    } catch (e) {
      print('Error loading unit types: $e');
    }
  }

  void _calculateActiveFilters() {
    _activeFilterCount = 0;
    _filters.forEach((key, value) {
      if (value != null &&
          value != false &&
          (value is! List || value.isNotEmpty) &&
          (value is! Map || value.isNotEmpty)) {
        _activeFilterCount++;
      }
    });
    _validateFilters();
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _validationError,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildUltraBackground(),
          _buildFloatingParticles(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _entranceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    (1 - _entranceAnimation.value) * 50,
                  ),
                  child: Opacity(
                    opacity: _entranceAnimation.value,
                    child: Column(
                      children: [
                        _buildUltraHeader(),
                        Expanded(
                          child: _buildContent(),
                        ),
                        _buildUltraFooter(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnimation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkSurface.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.90),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _UltraWavePainter(
              waveAnimation: _waveAnimation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _NanoParticlePainter(
            particles: _particles,
            animation: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildUltraHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildNanoButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.primaryCyan,
                      AppTheme.primaryBlue,
                      AppTheme.primaryPurple,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'تخصيص البحث',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_activeFilterCount > 0)
            _buildNanoTextButton(
              label: 'مسح',
              icon: Icons.clear_all_rounded,
              onTap: _resetFilters,
              color: AppTheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        SearchFilters? filters;

        if (state is SearchCombinedState) {
          final filtersState = state.filtersState;
          if (filtersState is SearchFiltersLoaded) {
            filters = filtersState.filters;
          }
        } else if (state is SearchFiltersLoaded) {
          filters = state.filters;
        }

        return AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildQuickFilters(),
                          const SizedBox(height: 16),
                          _buildPriceSection(),
                          const SizedBox(height: 12),
                          _buildRatingSection(),
                          const SizedBox(height: 12),
                          _buildAmenitiesSection(filters),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickFilters() {
    final quickFilters = [
      {'label': 'الأكثر شعبية', 'icon': Icons.trending_up_rounded},
      {'label': 'الأفضل تقييماً', 'icon': Icons.star_rounded},
      {'label': 'الأرخص', 'icon': Icons.attach_money_rounded},
      {'label': 'قريب مني', 'icon': Icons.near_me_rounded},
    ];

    return Container(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickFilters.length,
        itemBuilder: (context, index) {
          final filter = quickFilters[index];
          final isSelected = false;

          return Padding(
            padding: EdgeInsets.only(
              right: index == 0 ? 0 : 8,
            ),
            child: _buildQuickFilterChip(
              label: filter['label'] as String,
              icon: filter['icon'] as IconData,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: !isSelected ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : AppTheme.textMuted.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppTheme.textLight.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return _NanoSection(
      title: 'التواريخ',
      icon: Icons.calendar_today_rounded,
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              label: 'من',
              date: _filters['checkIn'],
              onTap: () => _selectDate('checkIn'),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBlue.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDateField(
              label: 'إلى',
              date: _filters['checkOut'],
              onTap: () => _selectDate('checkOut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: date != null
              ? AppTheme.primaryBlue.withOpacity(0.08)
              : AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : AppTheme.darkBorder.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date) : 'اختر',
              style: AppTextStyles.bodySmall.copyWith(
                color: date != null
                    ? AppTheme.textWhite
                    : AppTheme.textMuted.withOpacity(0.5),
                fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSection() {
    final guestsCount = _filters['guestsCount'] ?? 1;

    return _NanoSection(
      title: 'الضيوف',
      icon: Icons.people_outline_rounded,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.4),
              AppTheme.darkCard.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$guestsCount ${guestsCount == 1 ? 'ضيف' : 'ضيوف'}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            Row(
              children: [
                _buildNanoCounterButton(
                  icon: Icons.remove,
                  enabled: guestsCount > 1,
                  onTap: () {
                    setState(() {
                      _filters['guestsCount'] = guestsCount - 1;
                      _calculateActiveFilters();
                    });
                  },
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    guestsCount.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildNanoCounterButton(
                  icon: Icons.add,
                  enabled: true,
                  onTap: () {
                    setState(() {
                      _filters['guestsCount'] = guestsCount + 1;
                      _calculateActiveFilters();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticPropertyTypesSection(SearchFilters? filters) {
    final types = _propertyTypes.isNotEmpty
        ? _propertyTypes
        : (filters?.propertyTypes ?? []);
    if (types.isEmpty) return const SizedBox.shrink();

    final isRequired = _requiredFieldsStatus['propertyTypeId'] == false;

    return _NanoSection(
      title: 'نوع العقار',
      icon: Icons.home_outlined,
      isRequired: true,
      hasError: isRequired,
      child: Container(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final isSelected = _filters['propertyTypeId'] == type.id;

            return Padding(
              padding: EdgeInsets.only(
                left: index == types.length - 1 ? 0 : 10,
              ),
              child: SizedBox(
                width: 85,
                child: FuturisticFilterTypeCard(
                  id: type.id,
                  name: type.name,
                  icon: type.icon ?? 'home',
                  count: type.propertiesCount ?? 0,
                  isSelected: isSelected,
                  cardType: FilterCardType.property,
                  animationDelay: Duration(milliseconds: index * 50),
                  onTap: () async {
                    setState(() {
                      if (isSelected) {
                        _filters.remove('propertyTypeId');
                        _filters.remove('unitTypeId');
                        _unitTypes = [];
                      } else {
                        if (_filters['propertyTypeId'] != type.id) {
                          _filters.remove('unitTypeId');
                          _unitTypes = [];
                        }
                        _filters['propertyTypeId'] = type.id;
                      }
                      _calculateActiveFilters();
                    });

                    if (!isSelected && type.id != null) {
                      _loadUnitTypesForPropertyType(type.id);
                    }

                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFuturisticUnitTypesSection(SearchFilters? filters) {
    final selectedPropertyTypeId = _filters['propertyTypeId'];
    if (selectedPropertyTypeId == null) return const SizedBox.shrink();

    final allUnitTypes =
        _unitTypes.isNotEmpty ? _unitTypes : (filters?.unitTypes ?? []);
    if (allUnitTypes.isEmpty) return const SizedBox.shrink();

    final unitTypes = allUnitTypes
        .where((u) => u.propertyTypeId == selectedPropertyTypeId)
        .toList();
    if (unitTypes.isEmpty) return const SizedBox.shrink();

    final isRequired = _requiredFieldsStatus['unitTypeId'] == false;

    return _NanoSection(
      title: 'نوع الوحدة',
      icon: Icons.bed_outlined,
      isRequired: true,
      hasError: isRequired,
      child: Container(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: unitTypes.length,
          itemBuilder: (context, index) {
            final unit = unitTypes[index];
            final isSelected = _filters['unitTypeId'] == unit.id;

            return Padding(
              padding: EdgeInsets.only(
                left: index == unitTypes.length - 1 ? 0 : 10,
              ),
              child: SizedBox(
                width: 85,
                child: FuturisticFilterTypeCard(
                  id: unit.id,
                  name: unit.name,
                  icon: unit.icon ?? 'bed',
                  count: unit.unitsCount ?? 0,
                  isSelected: isSelected,
                  cardType: FilterCardType.unit,
                  animationDelay: Duration(milliseconds: index * 50),
                  onTap: () async {
                    setState(() {
                      if (isSelected) {
                        _filters.remove('unitTypeId');
                      } else {
                        _filters['unitTypeId'] = unit.id;
                      }
                      _calculateActiveFilters();
                    });

                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final double minPrice = (_filters['minPrice'] as num?)?.toDouble() ?? 0.0;
    final double maxPrice =
        (_filters['maxPrice'] as num?)?.toDouble() ?? 1000000.0;
    final String selectedCurrency =
        _filters['preferredCurrency'] as String? ?? 'YER';

    return _NanoSection(
      title: 'السعر',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          // ✅ Currency Selector
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCurrencySelector(selectedCurrency),
          ),
          Row(
            children: [
              Expanded(
                child: _buildPriceField(
                  label: 'من',
                  value: minPrice,
                  currency: selectedCurrency,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: AppTheme.textMuted.withOpacity(0.3),
                ),
              ),
              Expanded(
                child: _buildPriceField(
                  label: 'إلى',
                  value: maxPrice,
                  currency: selectedCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUltraPriceSlider(minPrice, maxPrice),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(String selectedCurrency) {
    const currencies = ['YER', 'USD', 'SAR', 'EUR', 'GBP'];
    const currencyNames = {
      'YER': 'ريال يمني',
      'USD': 'دولار أمريكي',
      'SAR': 'ريال سعودي',
      'EUR': 'يورو',
      'GBP': 'جنيه إسترليني',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            size: 18,
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'العملة:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selectedCurrency,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppTheme.darkCard,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              items: currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(
                    '${currencyNames[currency]} ($currency)',
                    style: AppTextStyles.bodySmall,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filters['preferredCurrency'] = value;
                    _validateFilters();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required String label,
    required double value,
    String currency = 'YER',
  }) {
    const currencySymbols = {
      'YER': 'ر.ي',
      'USD': '\$',
      'SAR': 'ر.س',
      'EUR': '€',
      'GBP': '£',
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.toStringAsFixed(0),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              Text(
                currencySymbols[currency] ?? currency,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUltraPriceSlider(double min, double max) {
    return Container(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                height: 4,
                margin: EdgeInsets.only(
                  left: 20,
                  right: MediaQuery.of(context).size.width * 0.3,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue
                          .withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          RangeSlider(
            min: 0.0,
            max: 1000000.0,
            values: RangeValues(min, max),
            onChanged: (RangeValues values) {
              setState(() {
                _filters['minPrice'] = values.start;
                _filters['maxPrice'] = values.end;
                _calculateActiveFilters();
              });
            },
            activeColor: AppTheme.primaryBlue,
            inactiveColor: AppTheme.darkCard.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final selectedRating = _filters['minStarRating'] ?? 0;

    return _NanoSection(
      title: 'التقييم',
      icon: Icons.star_outline_rounded,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final rating = index + 1;
          final isSelected = selectedRating == rating;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _filters.remove('minStarRating');
                } else {
                  _filters['minStarRating'] = rating;
                }
                _calculateActiveFilters();
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.warning.withOpacity(0.8),
                          AppTheme.warning.withOpacity(0.5),
                        ],
                      )
                    : null,
                color: !isSelected ? AppTheme.darkCard.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.15),
                  width: 0.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.warning.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  '$rating',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textMuted.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAmenitiesSection(SearchFilters? filters) {
    final allAmenities = filters?.amenities ?? [];
    if (allAmenities.isEmpty) return const SizedBox.shrink();

    final selectedPropertyTypeId = _filters['propertyTypeId'] as String?;

    final amenities = selectedPropertyTypeId == null
        ? allAmenities
        : allAmenities.where((a) {
            // إذا لم يكن هناك نوع عقار محدد، نعرض كل المرافق
            if (selectedPropertyTypeId == null) {
              return true;
            }

            // إذا كانت القائمة فارغة فهذا يعني أنه لا يوجد ربط صريح بالممتلكات
            // في هذه الحالة نخفي المرفق عند اختيار نوع عقار محدد
            if (a.propertyTypeIds.isEmpty) {
              return false;
            }

            // نعرض المرفق فقط إذا كان مرتبطًا صراحةً بنوع العقار المحدد
            return a.propertyTypeIds.contains(selectedPropertyTypeId);
          }).toList();

    if (amenities.isEmpty) return const SizedBox.shrink();

    final selectedAmenities =
        List<String>.from(_filters['requiredAmenities'] ?? []);

    return _NanoSection(
      title: 'المرافق',
      icon: Icons.widgets_outlined,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: amenities.map((amenity) {
          final isSelected = selectedAmenities.contains(amenity.id);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedAmenities.remove(amenity.id);
                } else {
                  selectedAmenities.add(amenity.id);
                }
                _filters['requiredAmenities'] = selectedAmenities;
                _calculateActiveFilters();
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : AppTheme.darkCard.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAmenityIcon(amenity.name),
                    size: 12,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amenity.name,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textLight.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUltraFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.darkSurface.withOpacity(0.8),
            AppTheme.darkSurface.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isValidFilter && _validationError.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationError,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Row(
                children: [
                  if (_activeFilterCount > 0)
                    Expanded(
                      child: GestureDetector(
                        onTap: _resetFilters,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'مسح الكل',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_activeFilterCount > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isValidFilter
                          ? () {
                              HapticFeedback.mediumImpact();
                              final sanitized =
                                  Map<String, dynamic>.from(_filters);
                              final unitTypeId =
                                  sanitized['unitTypeId'] as String?;
                              if (unitTypeId != null) {
                                try {
                                  final matching = _unitTypes
                                      .where((u) => u.id == unitTypeId);
                                  if (matching.isNotEmpty) {
                                    final ut = matching.first;
                                    final bool hasAdults =
                                        (ut.isHasAdults == true);
                                    final bool hasChildren =
                                        (ut.isHasChildren == true);
                                    if (!hasAdults && !hasChildren) {
                                      sanitized.remove('guestsCount');
                                    }
                                  }
                                } catch (_) {}
                              }
                              Navigator.pop(context, sanitized);
                            }
                          : () {
                              HapticFeedback.heavyImpact();
                              _showValidationError();
                            },
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: _isValidFilter
                                  ? AppTheme.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        AppTheme.textMuted.withOpacity(0.3),
                                        AppTheme.textMuted.withOpacity(0.2),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isValidFilter
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(
                                            0.3 + (0.2 * _glowAnimation.value)),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isValidFilter
                                        ? Icons.check_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 16,
                                    color: _isValidFilter
                                        ? Colors.white
                                        : AppTheme.textMuted.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isValidFilter
                                        ? (_activeFilterCount > 0
                                            ? 'تطبيق ($_activeFilterCount)'
                                            : 'تطبيق الفلاتر')
                                        : 'أكمل الحقول المطلوبة',
                                    style: AppTextStyles.buttonMedium.copyWith(
                                      color: _isValidFilter
                                          ? Colors.white
                                          : AppTheme.textMuted.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNanoButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.textLight,
        ),
      ),
    );
  }

  Widget _buildNanoTextButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNanoCounterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : AppTheme.darkCard.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? AppTheme.primaryBlue
              : AppTheme.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters.clear();
      _activeFilterCount = 0;
      _unitTypes = [];
      _validateFilters();
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _selectDate(String field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filters[field] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filters[field] = picked;
        _calculateActiveFilters();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  IconData _getAmenityIcon(String amenity) {
    final icons = {
      'واي فاي': Icons.wifi_rounded,
      'موقف': Icons.local_parking_rounded,
      'مسبح': Icons.pool_rounded,
    };
    return icons[amenity] ?? Icons.check_circle_outline_rounded;
  }
}

// Nano Section Widget with validation support
class _NanoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isRequired;
  final bool hasError;

  const _NanoSection({
    required this.title,
    required this.icon,
    required this.child,
    this.isRequired = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.1),
          width: hasError ? 1.5 : 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: hasError
                            ? LinearGradient(
                                colors: [
                                  AppTheme.error.withOpacity(0.8),
                                  AppTheme.error.withOpacity(0.6),
                                ],
                              )
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hasError ? Icons.warning_amber_rounded : icon,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasError ? AppTheme.error : AppTheme.textWhite,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Painters
class _UltraWavePainter extends CustomPainter {
  final double waveAnimation;
  final double glowIntensity;

  _UltraWavePainter({
    required this.waveAnimation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final offset = i * 0.3;
      final path = Path();

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.9 +
            math.sin((x / size.width * 2 * math.pi) +
                    (waveAnimation * 2 * math.pi) +
                    (offset * math.pi)) *
                10;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryBlue.withOpacity(0.02 * glowIntensity),
          AppTheme.primaryPurple.withOpacity(0.01 * glowIntensity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NanoParticle {
  late double x, y, vx, vy, radius, opacity;

  _NanoParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 1.5 + 0.5;
    opacity = math.Random().nextDouble() * 0.3 + 0.1;
  }

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

class _NanoParticlePainter extends CustomPainter {
  final List<_NanoParticle> particles;
  final double animation;

  _NanoParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update();

      paint.color = AppTheme.primaryBlue.withOpacity(particle.opacity);

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
