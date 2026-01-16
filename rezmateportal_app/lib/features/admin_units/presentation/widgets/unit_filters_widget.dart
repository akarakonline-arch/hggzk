// lib/features/admin_units/presentation/widgets/unit_filters_widget.dart

import 'package:rezmateportal/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:rezmateportal/core/theme/app_text_styles.dart';

class UnitFiltersWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;

  const UnitFiltersWidget({
    super.key,
    required this.onFiltersChanged,
  });

  @override
  State<UnitFiltersWidget> createState() => _UnitFiltersWidgetState();
}

class _UnitFiltersWidgetState extends State<UnitFiltersWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final Map<String, dynamic> _filters = {
    'propertyId': null,
    'unitTypeId': null,
    // ❌ 'isAvailable': null,  // تم الإزالة - Backend لا يدعمه
    'minPrice': null,
    'maxPrice': null,
    'pricingMethod': null,
    'checkInDate': null,
    'checkOutDate': null,
    'numberOfGuests': null,
    'hasActiveBookings': null,
    'location': null,
    'sortBy': null,
    'latitude': null,
    'longitude': null,
    'radiusKm': null,
    'nameContains': null,
  };

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _radiusController = TextEditingController();
  final _guestsController = TextEditingController();
  final _nameSearchController = TextEditingController();

  // متغيرات الموقع المحدد
  LatLng? _selectedLocation;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationController.dispose();
    _radiusController.dispose();
    _guestsController.dispose();
    _nameSearchController.dispose();
    super.dispose();
  }

  void _updateFilter(String key, dynamic value) {
    setState(() => _filters[key] = value);
    widget.onFiltersChanged(_filters);
    HapticFeedback.lightImpact();
  }

  void _resetFilters() {
    setState(() {
      _filters.forEach((key, value) {
        _filters[key] = null;
      });
      _minPriceController.clear();
      _maxPriceController.clear();
      _locationController.clear();
      _radiusController.clear();
      _guestsController.clear();
      _nameSearchController.clear();
      _selectedLocation = null;
      _selectedAddress = null;
    });
    widget.onFiltersChanged(_filters);
    HapticFeedback.mediumImpact();
  }

  int get _activeFiltersCount => _filters.values.where((v) => v != null).length;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: 280, child: _buildNameSearchFilter()),
                    SizedBox(width: 280, child: _buildPriceRangeFilter()),
                    // ❌ تم إزالة: SizedBox(width: 220, child: _buildAvailabilityFilter()),
                    // Backend لا يدعم isAvailable - يعتمد على DailyUnitSchedules
                    SizedBox(width: 280, child: _buildPricingMethodFilter()),
                    SizedBox(width: 280, child: _buildDateRangeFilter()),
                    SizedBox(width: 180, child: _buildGuestsFilter()),
                    SizedBox(width: 220, child: _buildActiveBookingsFilter()),
                    SizedBox(width: 340, child: _buildLocationFilter()),
                    SizedBox(width: 400, child: _buildSortFilter()),
                    _buildApplyButton(),
                  ],
                ),
                if (_activeFiltersCount > 0) ...[
                  const SizedBox(height: 16),
                  _buildActiveFiltersChips(),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فلترة الوحدات',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_activeFiltersCount > 0)
                    Text(
                      '$_activeFiltersCount فلتر نشط',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryBlue,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_activeFiltersCount > 0) _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _resetFilters,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: AppTheme.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'إعادة تعيين',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSearchFilter() {
    return _buildFilterContainer(
      label: 'البحث بالاسم أو الرقم',
      icon: Icons.search_rounded,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: TextField(
          controller: _nameSearchController,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'اسم الوحدة أو الرقم...',
            hintStyle: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              Icons.badge_rounded,
              size: 16,
              color: AppTheme.primaryBlue.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (value) =>
              _updateFilter('nameContains', value.isEmpty ? null : value),
        ),
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return _buildFilterContainer(
      label: 'نطاق السعر (ريال)',
      icon: Icons.monetization_on_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPriceField(
                  'الحد الأدنى',
                  _minPriceController,
                  Icons.arrow_downward_rounded,
                  (value) => _updateFilter('minPrice', int.tryParse(value)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceField(
                  'الحد الأقصى',
                  _maxPriceController,
                  Icons.arrow_upward_rounded,
                  (value) => _updateFilter('maxPrice', int.tryParse(value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickPriceChip('0-1000', 0, 1000),
                const SizedBox(width: 6),
                _buildQuickPriceChip('1000-5000', 1000, 5000),
                const SizedBox(width: 6),
                _buildQuickPriceChip('5000-10000', 5000, 10000),
                const SizedBox(width: 6),
                _buildQuickPriceChip('10000+', 10000, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(
    String hint,
    TextEditingController controller,
    IconData icon,
    Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(icon,
                size: 14, color: AppTheme.primaryBlue.withValues(alpha: 0.6)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixText: 'ر.ي',
                suffixStyle: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPriceChip(String label, int? min, int? max) {
    final isActive = _filters['minPrice'] == min && _filters['maxPrice'] == max;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filters['minPrice'] = min;
          _filters['maxPrice'] = max;
          _minPriceController.text = min?.toString() ?? '';
          _maxPriceController.text = max?.toString() ?? '';
        });
        widget.onFiltersChanged(_filters);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGradient : null,
          color: !isActive ? AppTheme.darkSurface.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive
                ? Colors.white
                : AppTheme.textMuted.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityFilter() {
    return _buildFilterContainer(
      label: 'حالة التوفر',
      icon: Icons.check_circle_outline_rounded,
      child: Column(
        children: [
          _buildToggleOption(
            'متاحة',
            true,
            Icons.check_circle_rounded,
            AppTheme.success,
            _filters['isAvailable'] == true,
            () => _updateFilter(
                'isAvailable', _filters['isAvailable'] == true ? null : true),
          ),
          const SizedBox(height: 8),
          _buildToggleOption(
            'غير متاحة',
            false,
            Icons.cancel_rounded,
            AppTheme.error,
            _filters['isAvailable'] == false,
            () => _updateFilter(
                'isAvailable', _filters['isAvailable'] == false ? null : false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    dynamic value,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color:
              !isSelected ? AppTheme.darkSurface.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? color : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingMethodFilter() {
    final methods = [
      {
        'value': 'Hourly',
        'label': 'بالساعة',
        'icon': Icons.hourglass_bottom_rounded,
        'color': AppTheme.warning
      },
      {
        'value': 'Daily',
        'label': 'يومي',
        'icon': Icons.today_rounded,
        'color': AppTheme.primaryBlue
      },
      {
        'value': 'Weekly',
        'label': 'أسبوعي',
        'icon': Icons.date_range_rounded,
        'color': AppTheme.primaryPurple
      },
      {
        'value': 'Monthly',
        'label': 'شهري',
        'icon': Icons.calendar_month_rounded,
        'color': AppTheme.success
      },
    ];

    return _buildFilterContainer(
      label: 'طريقة التسعير',
      icon: Icons.payments_rounded,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: methods.map((method) {
          final isSelected = _filters['pricingMethod'] == method['value'];

          return GestureDetector(
            onTap: () => _updateFilter(
                'pricingMethod', isSelected ? null : method['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          (method['color'] as Color).withValues(alpha: 0.3),
                          (method['color'] as Color).withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                color: !isSelected
                    ? AppTheme.darkSurface.withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? (method['color'] as Color).withValues(alpha: 0.5)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    method['icon'] as IconData,
                    size: 14,
                    color: isSelected
                        ? (method['color'] as Color)
                        : AppTheme.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    method['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? (method['color'] as Color)
                          : AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildDateRangeFilter() {
    DateTime? checkIn = _filters['checkInDate'];
    DateTime? checkOut = _filters['checkOutDate'];

    return _buildFilterContainer(
      label: 'فترة الإقامة',
      icon: Icons.calendar_month_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💡 ملاحظة: فلتر الإتاحة يعتمد على التواريخ
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'فلتر الإتاحة يعتمد على اختيار التواريخ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'تاريخ الوصول',
                  checkIn,
                  Icons.login_rounded,
                  () => _pickDate('checkInDate', checkIn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'تاريخ المغادرة',
                  checkOut,
                  Icons.logout_rounded,
                  () => _pickDate('checkOutDate', checkOut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label, DateTime? value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value != null
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: AppTheme.primaryBlue.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value != null
                    ? '${value.day}/${value.month}/${value.year}'
                    : label,
                style: AppTextStyles.caption.copyWith(
                  color: value != null
                      ? AppTheme.textWhite
                      : AppTheme.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(String key, DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primaryBlue,
            onPrimary: Colors.white,
            surface: AppTheme.darkCard,
            onSurface: AppTheme.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _updateFilter(key, picked);
    }
  }

  Widget _buildGuestsFilter() {
    return _buildFilterContainer(
      label: 'عدد الضيوف',
      icon: Icons.group_rounded,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.person_rounded,
                  size: 14, color: AppTheme.primaryBlue.withValues(alpha: 0.6)),
            ),
            Expanded(
              child: TextField(
                controller: _guestsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'العدد',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) =>
                    _updateFilter('numberOfGuests', int.tryParse(v)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingsFilter() {
    return _buildFilterContainer(
      label: 'الحجوزات',
      icon: Icons.event_available_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool?>(
          value: _filters['hasActiveBookings'],
          isExpanded: true,
          dropdownColor: AppTheme.darkCard,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.primaryBlue.withValues(alpha: 0.7),
            size: 20,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
          ),
          hint: Text(
            'حالة الحجوزات',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('جميع الوحدات'),
            ),
            DropdownMenuItem(
              value: true,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('مع حجوزات نشطة'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: false,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('بدون حجوزات'),
                ],
              ),
            ),
          ],
          onChanged: (value) => _updateFilter('hasActiveBookings', value),
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return _buildFilterContainer(
      label: 'الموقع الجغرافي',
      icon: Icons.location_on_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.darkBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _locationController,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'المدينة أو العنوان...',
                      hintStyle: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) =>
                        _updateFilter('location', v.isEmpty ? null : v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildMapButton(),
            ],
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'موقع محدد',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedAddress != null)
                          Text(
                            _selectedAddress!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textWhite.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLocation = null;
                        _selectedAddress = null;
                        _filters['latitude'] = null;
                        _filters['longitude'] = null;
                      });
                      widget.onFiltersChanged(_filters);
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildRadiusField(),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openMapPicker,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.8),
                AppTheme.primaryBlue.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'تحديد على الخريطة',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.radar_rounded,
              size: 14,
              color: AppTheme.warning.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'نطاق البحث (كيلومتر)',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textWhite.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.straighten_rounded,
                  size: 14,
                  color: AppTheme.warning.withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _radiusController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مثال: 5',
                    hintStyle: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixText: 'كم',
                    suffixStyle: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  onChanged: (v) =>
                      _updateFilter('radiusKm', double.tryParse(v)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRadiusChip('1 كم', 1),
              const SizedBox(width: 6),
              _buildRadiusChip('5 كم', 5),
              const SizedBox(width: 6),
              _buildRadiusChip('10 كم', 10),
              const SizedBox(width: 6),
              _buildRadiusChip('25 كم', 25),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadiusChip(String label, double radius) {
    final isActive = _filters['radiusKm'] == radius;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filters['radiusKm'] = radius;
          _radiusController.text = radius.toString();
        });
        widget.onFiltersChanged(_filters);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [
                  AppTheme.warning.withValues(alpha: 0.8),
                  AppTheme.warning.withValues(alpha: 0.6),
                ])
              : null,
          color: !isActive ? AppTheme.darkSurface.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.warning.withValues(alpha: 0.5)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive
                ? Colors.white
                : AppTheme.textMuted.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _openMapPicker() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _MapPickerDialog(
        initialLocation: _selectedLocation,
        onLocationSelected: (location, address) {
          setState(() {
            _selectedLocation = location;
            _selectedAddress = address;
            _filters['latitude'] = location.latitude;
            _filters['longitude'] = location.longitude;
            if (address != null) {
              _locationController.text = address;
              _filters['location'] = address;
            }
          });
          widget.onFiltersChanged(_filters);
        },
      ),
    );
  }

  Widget _buildSortFilter() {
    const options = {
      'popularity': {
        'label': 'الأكثر حجزاً',
        'icon': Icons.trending_up_rounded
      },
      'price_asc': {
        'label': 'السعر تصاعدي',
        'icon': Icons.arrow_upward_rounded
      },
      'price_desc': {
        'label': 'السعر تنازلي',
        'icon': Icons.arrow_downward_rounded
      },
      'name_asc': {'label': 'الاسم (أ-ي)', 'icon': Icons.sort_by_alpha_rounded},
      'name_desc': {
        'label': 'الاسم (ي-أ)',
        'icon': Icons.sort_by_alpha_rounded
      },
    };

    return _buildFilterContainer(
      label: 'الترتيب حسب',
      icon: Icons.sort_rounded,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options.entries.map((e) {
          final isSelected = _filters['sortBy'] == e.key;

          return GestureDetector(
            onTap: () => _updateFilter('sortBy', isSelected ? null : e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: !isSelected
                    ? AppTheme.darkSurface.withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e.value['icon'] as IconData,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.value['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildFilterContainer({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.5),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onFiltersChanged(_filters),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'تطبيق الفلاتر',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    List<Widget> chips = [];

    _filters.forEach((key, value) {
      if (value != null) {
        String label = '';
        IconData icon = Icons.filter_alt_rounded;
        Color color = AppTheme.primaryBlue;

        switch (key) {
          case 'minPrice':
            label = 'من: $value ر.ي';
            icon = Icons.arrow_downward_rounded;
            color = AppTheme.success;
            break;
          case 'maxPrice':
            label = 'إلى: $value ر.ي';
            icon = Icons.arrow_upward_rounded;
            color = AppTheme.success;
            break;
          case 'isAvailable':
            label = value ? 'متاحة' : 'غير متاحة';
            icon = value ? Icons.check_circle_rounded : Icons.cancel_rounded;
            color = value ? AppTheme.success : AppTheme.error;
            break;
          case 'pricingMethod':
            label = _getPricingMethodLabel(value);
            icon = Icons.schedule_rounded;
            color = AppTheme.primaryPurple;
            break;
          case 'checkInDate':
            label = 'وصول: ${(value as DateTime).day}/${value.month}';
            icon = Icons.login_rounded;
            color = AppTheme.primaryBlue;
            break;
          case 'checkOutDate':
            label = 'مغادرة: ${(value as DateTime).day}/${value.month}';
            icon = Icons.logout_rounded;
            color = AppTheme.primaryBlue;
            break;
          case 'numberOfGuests':
            label = 'ضيوف: $value';
            icon = Icons.group_rounded;
            color = AppTheme.primaryBlue;
            break;
          case 'hasActiveBookings':
            label = value ? 'بحجوزات نشطة' : 'بدون حجوزات';
            icon = Icons.event_available_rounded;
            color = AppTheme.primaryPurple;
            break;
          case 'location':
            label = 'الموقع: $value';
            icon = Icons.place_rounded;
            color = AppTheme.warning;
            break;
          case 'radiusKm':
            label = 'نطاق: $valueكم';
            icon = Icons.radar_rounded;
            color = AppTheme.warning;
            break;
          case 'latitude':
          case 'longitude':
            if (key == 'latitude' && _filters['longitude'] != null) {
              label = 'إحداثيات محددة';
              icon = Icons.gps_fixed_rounded;
              color = AppTheme.primaryBlue;
            }
            break;
          case 'sortBy':
            label = _getSortLabel(value);
            icon = Icons.sort_rounded;
            color = AppTheme.primaryPurple;
            break;
          case 'nameContains':
            label = 'البحث: $value';
            icon = Icons.search_rounded;
            color = AppTheme.primaryBlue;
            break;
        }

        if (label.isNotEmpty) {
          chips.add(
            Container(
              margin: const EdgeInsets.only(left: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _updateFilter(key, null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    return Wrap(children: chips);
  }

  String _getPricingMethodLabel(String value) {
    switch (value) {
      case 'Hourly':
        return 'بالساعة';
      case 'Daily':
        return 'يومي';
      case 'Weekly':
        return 'أسبوعي';
      case 'Monthly':
        return 'شهري';
      default:
        return value;
    }
  }

  String _getSortLabel(String value) {
    switch (value) {
      case 'popularity':
        return 'الأكثر حجزاً';
      case 'price_asc':
        return 'السعر تصاعدي';
      case 'price_desc':
        return 'السعر تنازلي';
      case 'name_asc':
        return 'الاسم (أ-ي)';
      case 'name_desc':
        return 'الاسم (ي-أ)';
      default:
        return value;
    }
  }
}

// Dialog لاختيار الموقع على الخريطة
class _MapPickerDialog extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;

  const _MapPickerDialog({
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _updateMarker(_selectedLocation!);
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(15.3694, 44.1910),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    controller.setMapStyle('''
                      [
                        {
                          "elementType": "geometry",
                          "stylers": [{"color": "#1d2c4d"}]
                        },
                        {
                          "elementType": "labels.text.fill",
                          "stylers": [{"color": "#8ec3f5"}]
                        },
                        {
                          "elementType": "labels.text.stroke",
                          "stylers": [{"color": "#1a3646"}]
                        },
                        {
                          "featureType": "water",
                          "elementType": "geometry",
                          "stylers": [{"color": "#0e1626"}]
                        },
                        {
                          "featureType": "road",
                          "elementType": "geometry",
                          "stylers": [{"color": "#2f3948"}]
                        }
                      ]
                    ''');
                  },
                  markers: _markers,
                  onTap: (location) {
                    _updateMarker(location);
                    _selectedAddress =
                        'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.darkCard,
                          AppTheme.darkCard.withValues(alpha: 0.95),
                          AppTheme.darkCard.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.darkBorder
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.textWhite,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تحديد الموقع على الخريطة',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.darkBorder.withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextField(
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن موقع...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 35),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 40,
                      color: AppTheme.primaryBlue,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.darkCard,
                          AppTheme.darkCard.withValues(alpha: 0.95),
                          AppTheme.darkCard.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_selectedLocation != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.darkSurface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الموقع المحدد',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _selectedAddress ??
                                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkSurface
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.darkBorder
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'إلغاء',
                                      style:
                                          AppTextStyles.buttonMedium.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectedLocation != null
                                    ? () {
                                        widget.onLocationSelected(
                                          _selectedLocation!,
                                          _selectedAddress,
                                        );
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: _selectedLocation != null
                                        ? AppTheme.primaryGradient
                                        : null,
                                    color: _selectedLocation == null
                                        ? AppTheme.darkSurface
                                            .withValues(alpha: 0.5)
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _selectedLocation != null
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryBlue
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'تأكيد الموقع',
                                      style:
                                          AppTextStyles.buttonMedium.copyWith(
                                        color: _selectedLocation != null
                                            ? Colors.white
                                            : AppTheme.textMuted
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
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
      ),
    );
  }
}
