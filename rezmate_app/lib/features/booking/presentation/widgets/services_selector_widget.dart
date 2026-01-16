import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rezmate/features/property/domain/entities/property_detail.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ServicesSelectorWidget extends StatefulWidget {
  final String propertyId;
  final List<PropertyService>? services;
  final Function(List<Map<String, dynamic>>) onServicesChanged;
  final List<Map<String, dynamic>>? initialSelected;

  const ServicesSelectorWidget({
    super.key,
    required this.propertyId,
    this.services,
    required this.onServicesChanged,
    this.initialSelected,
  });

  @override
  State<ServicesSelectorWidget> createState() => _ServicesSelectorWidgetState();
}

class _ServicesSelectorWidgetState extends State<ServicesSelectorWidget>
    with TickerProviderStateMixin {
  late final List<Map<String, dynamic>> _services;

  static final List<Color> _serviceColors = [
    AppTheme.primaryBlue,
    AppTheme.warning,
    AppTheme.primaryPurple,
    AppTheme.success,
    AppTheme.info,
  ];

  final Map<String, bool> _selectedServices = {};
  final Map<String, int> _serviceQuantities = {};
  final Map<String, AnimationController> _animationControllers = {};
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.services != null && widget.services!.isNotEmpty) {
      int index = 0;
      _services = widget.services!.map((s) {
        final color = _serviceColors[index % _serviceColors.length];
        index++;
        return {
          'id': s.id,
          'name': s.name,
          'price': s.price,
          'description': s.description ?? '',
          'icon': Icons.room_service,
          'color': color,
        };
      }).toList();
    } else {
      _services = [];
    }

    for (var service in _services) {
      _selectedServices[service['id']] = false;
      _serviceQuantities[service['id']] = 1;
      _animationControllers[service['id']] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }

    // Apply initial selections if provided
    if (widget.initialSelected != null && widget.initialSelected!.isNotEmpty) {
      for (final item in widget.initialSelected!) {
        try {
          final id = item['id']?.toString();
          if (id != null && _selectedServices.containsKey(id)) {
            _selectedServices[id] = true;
            final q = (item['quantity'] is int)
                ? (item['quantity'] as int)
                : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            _serviceQuantities[id] = q > 0 ? q : 1;
          }
        } catch (_) {}
      }
      // Notify parent with initial state
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateSelectedServices());
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _animationControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.35),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.96),
            AppTheme.darkSurface.withOpacity(0.96),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            ...List.generate(_services.length, (index) {
              final service = _services[index];
              final isLast = index == _services.length - 1;
              return _buildServiceTimelineRow(service, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final selectedCount =
        _selectedServices.values.where((selected) => selected).length;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryViolet,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.room_service,
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
                'الخدمات المتاحة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                selectedCount > 0
                    ? 'تم اختيار $selectedCount خدمة إضافية'
                    : 'اختر الخدمات الإضافية التي ترغب بإضافتها إلى حجزك',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: AppTheme.darkBackground.withOpacity(0.7),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 11,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                '${_services.length}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTimelineRow(Map<String, dynamic> service, bool isLast) {
    final isSelected = _selectedServices[service['id']] ?? false;
    final quantity = _serviceQuantities[service['id']] ?? 1;
    final animationController = _animationControllers[service['id']]!;

    if (isSelected && !animationController.isCompleted) {
      animationController.forward();
    } else if (!isSelected && animationController.isCompleted) {
      animationController.reverse();
    }

    final Color color = service['color'] as Color;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                          color,
                          color.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 34,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.35),
                            color.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.98),
                        AppTheme.darkCard.withOpacity(0.95),
                      ],
                    ),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.85)
                          : color.withOpacity(0.55),
                      width: isSelected ? 1.4 : 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isSelected ? 0.35 : 0.25),
                        blurRadius: isSelected ? 18 : 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedServices[service['id']] = !isSelected;
                          _updateSelectedServices();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.9),
                                        color.withOpacity(0.5),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.55),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    service['icon'] as IconData,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              service['name'],
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppTheme.textWhite,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: color.withOpacity(0.9),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if ((service['description'] as String)
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'] as String,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${(service['price'] as double).toStringAsFixed(0)} ريال',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isSelected)
                                            _buildQuantitySelector(
                                                service, quantity),
                                        ],
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              )
            : null,
        color: !isSelected ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppTheme.darkBorder,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> service) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            service['color'].withOpacity(0.3),
            service['color'].withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        service['icon'],
        color: service['color'],
        size: 20,
      ),
    );
  }

  Widget _buildQuantitySelector(Map<String, dynamic> service, int quantity) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'الكمية',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: quantity > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _serviceQuantities[service['id']] =
                                    quantity - 1;
                                _updateSelectedServices();
                              });
                            }
                          : null,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Text(
                        quantity.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _serviceQuantities[service['id']] = quantity + 1;
                          _updateSelectedServices();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled
                ? AppTheme.primaryBlue.withOpacity(0.8)
                : AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _updateSelectedServices() {
    final selectedList = <Map<String, dynamic>>[];

    _selectedServices.forEach((id, isSelected) {
      if (isSelected) {
        final service = _services.firstWhere((s) => s['id'] == id);
        selectedList.add({
          'id': id,
          'name': service['name'],
          'price': service['price'] * (_serviceQuantities[id] ?? 1),
          'quantity': _serviceQuantities[id] ?? 1,
        });
      }
    });

    widget.onServicesChanged(selectedList);
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/widgets/price_widget.dart';

// class ServicesSelectorWidget extends StatefulWidget {
//   final String propertyId;
//   final Function(List<Map<String, dynamic>>) onServicesChanged;

//   const ServicesSelectorWidget({
//     super.key,
//     required this.propertyId,
//     required this.onServicesChanged,
//   });

//   @override
//   State<ServicesSelectorWidget> createState() => _ServicesSelectorWidgetState();
// }

// class _ServicesSelectorWidgetState extends State<ServicesSelectorWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
  
//   final List<Map<String, dynamic>> _availableServices = [
//     {
//       'id': '1',
//       'name': 'وجبة إفطار',
//       'icon': Icons.breakfast_dining_rounded,
//       'price': 50.0,
//       'color': AppTheme.warning,
//     },
//     {
//       'id': '2',
//       'name': 'موقف سيارة',
//       'icon': Icons.local_parking_rounded,
//       'price': 30.0,
//       'color': AppTheme.primaryBlue,
//     },
//     {
//       'id': '3',
//       'name': 'واي فاي سريع',
//       'icon': Icons.wifi_rounded,
//       'price': 20.0,
//       'color': AppTheme.primaryCyan,
//     },
//     {
//       'id': '4',
//       'name': 'تنظيف يومي',
//       'icon': Icons.cleaning_services_rounded,
//       'price': 40.0,
//       'color': AppTheme.success,
//     },
//   ];
  
//   final List<Map<String, dynamic>> _selectedServices = [];

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeIn,
//     ));
    
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _toggleService(Map<String, dynamic> service) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       final index = _selectedServices.indexWhere((s) => s['id'] == service['id']);
//       if (index >= 0) {
//         _selectedServices.removeAt(index);
//       } else {
//         _selectedServices.add(service);
//       }
//     });
//     widget.onServicesChanged(_selectedServices);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppTheme.darkCard.withOpacity(0.3),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: AppTheme.primaryViolet.withOpacity(0.1),
//             width: 0.5,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.room_service_rounded,
//                         color: AppTheme.primaryViolet.withOpacity(0.7),
//                         size: 14,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         'اختر الخدمات التي تريدها',
//                         style: AppTextStyles.caption.copyWith(
//                           color: AppTheme.textMuted.withOpacity(0.8),
//                           
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   height: 0.5,
//                   color: AppTheme.darkBorder.withOpacity(0.1),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _availableServices.map((service) {
//                       final isSelected = _selectedServices.any((s) => s['id'] == service['id']);
//                       return _buildServiceChip(service, isSelected);
//                     }).toList(),
//                   ),
//                 ),
//                 if (_selectedServices.isNotEmpty) ...[
//                   Container(
//                     height: 0.5,
//                     color: AppTheme.darkBorder.withOpacity(0.1),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'المجموع:',
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.textMuted.withOpacity(0.7),
//                           ),
//                         ),
//                         PriceWidget(
//                           price: _selectedServices.fold(0.0, (sum, s) => sum + s['price']),
//                           currency: 'ريال',
//                           displayType: PriceDisplayType.compact,
//                           priceStyle: AppTextStyles.bodySmall.copyWith(
//                             color: AppTheme.primaryViolet.withOpacity(0.9),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceChip(Map<String, dynamic> service, bool isSelected) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0, end: 1),
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//       builder: (context, value, child) {
//         return Transform.scale(
//           scale: 0.9 + (0.1 * value),
//           child: GestureDetector(
//             onTap: () => _toggleService(service),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 gradient: isSelected
//                     ? LinearGradient(
//                         colors: [
//                           (service['color'] as Color).withOpacity(0.2),
//                           (service['color'] as Color).withOpacity(0.1),
//                         ],
//                       )
//                     : null,
//                 color: !isSelected ? AppTheme.darkCard.withOpacity(0.2) : null,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: isSelected
//                       ? (service['color'] as Color).withOpacity(0.3)
//                       : AppTheme.darkBorder.withOpacity(0.1),
//                   width: 0.5,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     service['icon'] as IconData,
//                     size: 14,
//                     color: isSelected
//                         ? (service['color'] as Color).withOpacity(0.8)
//                         : AppTheme.textMuted.withOpacity(0.5),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     service['name'],
//                     style: AppTextStyles.caption.copyWith(
//                       color: isSelected
//                           ? AppTheme.textWhite.withOpacity(0.9)
//                           : AppTheme.textMuted.withOpacity(0.6),
//                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? (service['color'] as Color).withOpacity(0.1)
//                           : AppTheme.darkBorder.withOpacity(0.05),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       '${service['price'].toStringAsFixed(0)} ريال',
//                       style: AppTextStyles.caption.copyWith(
//                         color: isSelected
//                             ? (service['color'] as Color).withOpacity(0.9)
//                             : AppTheme.textMuted.withOpacity(0.5),
//                         
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   if (isSelected) ...[
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.check_circle_rounded,
//                       size: 12,
//                       color: (service['color'] as Color).withOpacity(0.8),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }