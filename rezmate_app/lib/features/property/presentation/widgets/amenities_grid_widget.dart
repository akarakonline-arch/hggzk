// lib/features/property/presentation/widgets/amenities_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/amenity.dart';

class AmenitiesGridWidget extends StatefulWidget {
  final List<Amenity> amenities;

  const AmenitiesGridWidget({
    super.key,
    required this.amenities,
  });

  @override
  State<AmenitiesGridWidget> createState() => _AmenitiesGridWidgetState();
}

class _AmenitiesGridWidgetState extends State<AmenitiesGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, bool> _expandedCategories = {};
  String? _selectedAmenityId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Initialize categories as expanded
    final categories = _groupAmenitiesByCategory();
    for (final category in categories.keys) {
      _expandedCategories[category] = true;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// الحصول على لون الفئة بناءً على اسمها
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'أساسيات':
        return AppTheme.primaryBlue;
      case 'مرافق':
        return AppTheme.primaryCyan;
      case 'ترفيه':
        return AppTheme.primaryPurple;
      case 'خدمات':
        return AppTheme.success;
      case 'رياضة':
        return AppTheme.warning;
      case 'مواصلات':
        return AppTheme.primaryViolet;
      case 'أمان':
        return AppTheme.error;
      case 'تقنية':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.primaryCyan;
    }
  }

  Map<String, List<Amenity>> _groupAmenitiesByCategory() {
    final groupedAmenities = <String, List<Amenity>>{};
    for (final amenity in widget.amenities) {
      final category = amenity.category ?? 'عام';
      if (!groupedAmenities.containsKey(category)) {
        groupedAmenities[category] = [];
      }
      groupedAmenities[category]!.add(amenity);
    }
    return groupedAmenities;
  }

  Map<String, List<Amenity>> _buildMockGroupedAmenities() {
    final now = DateTime.now();

    final mockList = <Amenity>[
      Amenity(
        id: 'a1',
        name: 'واي فاي فائق السرعة',
        description: 'اتصال إنترنت مستقر يناسب العمل عن بعد والبث بدقة عالية.',
        iconUrl: '',
        category: 'أساسيات',
        icon: 'wifi',
        isActive: true,
        extraCost: null,
        displayOrder: 1,
        createdAt: now,
      ),
      Amenity(
        id: 'a2',
        name: 'موقف سيارات مجاني',
        description: 'موقف خاص داخل المبنى مزود بكاميرات مراقبة.',
        iconUrl: '',
        category: 'مرافق',
        icon: 'local_parking',
        isActive: true,
        extraCost: null,
        displayOrder: 2,
        createdAt: now,
      ),
      Amenity(
        id: 'a3',
        name: 'مسبح خارجي بإضاءة ليلية',
        description: 'مسبح أنيق بإضاءة نيون ليلية وإطلالة مفتوحة.',
        iconUrl: '',
        category: 'ترفيه',
        icon: 'pool',
        isActive: true,
        extraCost: 25,
        displayOrder: 3,
        createdAt: now,
      ),
      Amenity(
        id: 'a4',
        name: 'خدمة تنظيف يومية',
        description:
            'تنظيف الغرف والأجنحة بشكل يومي للحفاظ على أعلى مستوى من النظافة.',
        iconUrl: '',
        category: 'خدمات',
        icon: 'cleaning_services',
        isActive: true,
        extraCost: null,
        displayOrder: 4,
        createdAt: now,
      ),
      Amenity(
        id: 'a5',
        name: 'نادي رياضي مجهز',
        description: 'معدات رياضية حديثة متاحة على مدار 24 ساعة.',
        iconUrl: '',
        category: 'رياضة',
        icon: 'fitness_center',
        isActive: true,
        extraCost: null,
        displayOrder: 5,
        createdAt: now,
      ),
      Amenity(
        id: 'a6',
        name: 'خدمة نقل من المطار',
        description: 'نقل خاص من وإلى المطار عند الطلب.',
        iconUrl: '',
        category: 'مواصلات',
        icon: 'directions_car',
        isActive: false,
        extraCost: 40,
        displayOrder: 6,
        createdAt: now,
      ),
    ];

    final grouped = <String, List<Amenity>>{};
    for (final amenity in mockList) {
      final category = amenity.category;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(amenity);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // الكود الأصلي المعتمد على بيانات العقار الحقيقية (معلّق مؤقتاً لعرض بيانات تجريبية)
    // if (widget.amenities.isEmpty) {
    //   return _buildUltraMinimalEmptyState();
    // }
    //
    // final groupedAmenities = _groupAmenitiesByCategory();

    final groupedAmenities = _buildMockGroupedAmenities();

    final items = <_AmenityWithCategory>[];
    groupedAmenities.forEach((category, amenities) {
      for (final amenity in amenities) {
        items.add(_AmenityWithCategory(category: category, amenity: amenity));
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmenitiesSectionTitle(),
          const SizedBox(height: 10),
          if (items.isNotEmpty) _buildAmenitiesTimeline(items),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSectionTitle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الخدمات والمرافق',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.9),
                      AppTheme.primaryPurple.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: AppTheme.primaryViolet,
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesTimeline(List<_AmenityWithCategory> items) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.9),
          width: 0.9,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.96),
            AppTheme.darkSurface.withOpacity(0.96),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 260 + (i * 70)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 10),
                      child: child,
                    ),
                  );
                },
                child: _buildAmenityTimelineRow(
                  items[i],
                  isLast: i == items.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityTimelineRow(
    _AmenityWithCategory item, {
    required bool isLast,
  }) {
    final categoryColor = _getCategoryColor(item.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withOpacity(0.9),
                      categoryColor.withOpacity(0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        categoryColor.withOpacity(0.4),
                        categoryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildUltraMinimalAmenityChip(
              item.amenity,
              categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraMinimalAmenityChip(Amenity amenity, Color categoryColor) {
    final isSelected = _selectedAmenityId == amenity.id;
    final isInactive = !amenity.isActive;

    final baseColor = AppTheme.darkSurface.withOpacity(0.96);

    final borderColor = isSelected
        ? categoryColor.withOpacity(0.55)
        : (isInactive
            ? AppTheme.darkBorder.withOpacity(0.7)
            : categoryColor.withOpacity(0.4));

    final textColor = isInactive
        ? AppTheme.textMuted.withOpacity(0.45)
        : AppTheme.textWhite.withOpacity(isSelected ? 0.95 : 0.85);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmenityId = isSelected ? null : amenity.id;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    categoryColor.withOpacity(0.32),
                    categoryColor.withOpacity(0.16),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor,
                    isInactive
                        ? AppTheme.darkCard.withOpacity(0.9)
                        : categoryColor.withOpacity(0.18),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.26),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isInactive ? AppTheme.darkBorder : categoryColor)
                        .withOpacity(0.32),
                    (isInactive ? AppTheme.darkBorder : categoryColor)
                        .withOpacity(0.14),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAmenityIcon(amenity),
                size: 14,
                color: isInactive
                    ? AppTheme.textMuted.withOpacity(0.4)
                    : AppTheme.textWhite.withOpacity(isSelected ? 0.95 : 0.75),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                amenity.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (amenity.extraCost != null && amenity.extraCost! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(isInactive ? 0.15 : 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${amenity.extraCost!.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(
                    color: isInactive
                        ? AppTheme.textMuted.withOpacity(0.7)
                        : AppTheme.warning.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (isInactive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'غير متوفر',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.error.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(Amenity amenity) {
    // إذا كان للمرفق أيقونة محددة من الخادم
    if (amenity.icon != null && amenity.icon!.isNotEmpty) {
      return _getIconFromName(amenity.icon!);
    }

    // وإلا استخدم الأيقونة الافتراضية بناءً على الاسم
    final name = amenity.name.toLowerCase();
    if (name.contains('wifi') || name.contains('واي فاي')) return Icons.wifi;
    if (name.contains('parking') || name.contains('موقف'))
      return Icons.local_parking;
    if (name.contains('pool') || name.contains('مسبح')) return Icons.pool;
    if (name.contains('gym') || name.contains('جيم'))
      return Icons.fitness_center;
    if (name.contains('kitchen') || name.contains('مطبخ')) return Icons.kitchen;
    if (name.contains('ac') || name.contains('تكييف')) return Icons.ac_unit;
    if (name.contains('tv') || name.contains('تلفاز')) return Icons.tv;
    if (name.contains('elevator') || name.contains('مصعد'))
      return Icons.elevator;
    return Icons.check_circle_outline;
  }

  IconData _getIconFromName(String iconName) {
    // خريطة شاملة لتحويل أسماء الأيقونات إلى Material Icons
    final iconMap = <String, IconData>{
      // أساسيات
      'wifi': Icons.wifi,
      'network_wifi': Icons.network_wifi,
      'signal_wifi_4_bar': Icons.signal_wifi_4_bar,
      'router': Icons.router,
      'ac_unit': Icons.ac_unit,
      'thermostat': Icons.thermostat,
      'air': Icons.air,
      'water_drop': Icons.water_drop,
      'electric_bolt': Icons.electric_bolt,
      'gas_meter': Icons.gas_meter,
      'heating': Icons.heat_pump,
      'light': Icons.light,

      // مطبخ
      'kitchen': Icons.kitchen,
      'microwave': Icons.microwave,
      'coffee_maker': Icons.coffee_maker,
      'blender': Icons.blender_outlined,
      'dining_room': Icons.dining,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'outdoor_grill': Icons.outdoor_grill,
      'countertops': Icons.countertops,

      // أجهزة
      'tv': Icons.tv,
      'desktop_windows': Icons.desktop_windows,
      'laptop': Icons.laptop,
      'phone_android': Icons.phone_android,
      'tablet': Icons.tablet,
      'speaker': Icons.speaker,
      'radio': Icons.radio,
      'videogame_asset': Icons.videogame_asset,
      'local_laundry_service': Icons.local_laundry_service,
      'dry_cleaning': Icons.dry_cleaning,
      'iron': Icons.iron,
      'dishwasher': Icons.kitchen,

      // حمام
      'bathroom': Icons.bathroom,
      'bathtub': Icons.bathtub,
      'shower': Icons.shower,
      'soap': Icons.soap,
      'dry': Icons.dry,
      'wash': Icons.wash,

      // نوم
      'bed': Icons.bed,
      'king_bed': Icons.king_bed,
      'single_bed': Icons.single_bed,
      'bedroom_parent': Icons.bed,
      'bedroom_child': Icons.child_care,
      'crib': Icons.crib,
      'chair': Icons.chair,
      'chair_alt': Icons.chair_alt,
      'weekend': Icons.weekend,
      'living': Icons.living,

      // رياضة
      'pool': Icons.pool,
      'hot_tub': Icons.hot_tub,
      'fitness_center': Icons.fitness_center,
      'sports_tennis': Icons.sports_tennis,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'sports_volleyball': Icons.sports_volleyball,
      'sports_golf': Icons.sports_golf,
      'sports_handball': Icons.sports_handball,
      'sports_cricket': Icons.sports_cricket,
      'sports_baseball': Icons.sports_baseball,
      'sports_esports': Icons.sports_esports,
      'spa': Icons.spa,
      'sauna': Icons.hot_tub,
      'self_improvement': Icons.self_improvement,

      // مواصلات
      'local_parking': Icons.local_parking,
      'garage': Icons.garage,
      'ev_station': Icons.ev_station,
      'local_gas_station': Icons.local_gas_station,
      'car_rental': Icons.car_rental,
      'car_repair': Icons.car_repair,
      'directions_car': Icons.directions_car,
      'directions_bus': Icons.directions_bus,
      'directions_bike': Icons.directions_bike,
      'electric_bike': Icons.electric_bike,
      'electric_scooter': Icons.electric_scooter,
      'moped': Icons.moped,

      // وصول
      'elevator': Icons.elevator,
      'stairs': Icons.stairs,
      'escalator': Icons.escalator,
      'escalator_warning': Icons.escalator_warning,
      'accessible': Icons.accessible,
      'wheelchair_pickup': Icons.wheelchair_pickup,
      'elderly': Icons.elderly,

      // أمان
      'security': Icons.security,
      'lock': Icons.lock,
      'key': Icons.key,
      'vpn_key': Icons.vpn_key,
      'shield': Icons.shield,
      'admin_panel_settings': Icons.admin_panel_settings,
      'verified_user': Icons.verified_user,
      'safety_check': Icons.safety_check,
      'health_and_safety': Icons.health_and_safety,
      'local_police': Icons.local_police,
      'local_fire_department': Icons.local_fire_department,
      'medical_services': Icons.medical_services,
      'emergency': Icons.emergency,
      'camera_alt': Icons.camera_alt,
      'videocam': Icons.videocam,
      'sensor_door': Icons.sensor_door,
      'sensor_window': Icons.sensor_window,
      'doorbell': Icons.doorbell,

      // خدمات
      'cleaning_services': Icons.cleaning_services,
      'room_service': Icons.room_service,
      'luggage': Icons.luggage,
      'shopping_cart': Icons.shopping_cart,
      'local_grocery_store': Icons.local_grocery_store,
      'local_mall': Icons.local_mall,
      'local_pharmacy': Icons.local_pharmacy,
      'local_hospital': Icons.local_hospital,
      'local_atm': Icons.local_atm,
      'local_library': Icons.local_library,
      'local_post_office': Icons.local_post_office,
      'print': Icons.print,
      'mail': Icons.mail,

      // خارجي
      'balcony': Icons.balcony,
      'deck': Icons.deck,
      'yard': Icons.yard,
      'grass': Icons.grass,
      'park': Icons.park,
      'forest': Icons.forest,
      'beach_access': Icons.beach_access,
      'water': Icons.water,
      'fence': Icons.fence,
      'roofing': Icons.roofing,

      // أطفال
      'child_care': Icons.child_care,
      'child_friendly': Icons.child_friendly,
      'baby_changing_station': Icons.baby_changing_station,
      'toys': Icons.toys,
      'stroller': Icons.stroller,

      // حيوانات
      'pets': Icons.pets,

      // عمل
      'desk': Icons.desk,
      'meeting_room': Icons.meeting_room,
      'business_center': Icons.business_center,
      'computer': Icons.computer,
      'scanner': Icons.scanner,
      'fax': Icons.fax,

      // ديني
      'mosque': Icons.mosque,
    };

    return iconMap[iconName] ?? Icons.check_circle_outline;
  }
}

class _AmenityWithCategory {
  final String category;
  final Amenity amenity;

  _AmenityWithCategory({
    required this.category,
    required this.amenity,
  });
}
