import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/property_detail.dart';

class PropertyInfoWidget extends StatefulWidget {
  final PropertyDetail property;

  const PropertyInfoWidget({
    super.key,
    required this.property,
  });

  @override
  State<PropertyInfoWidget> createState() => _PropertyInfoWidgetState();
}

class _PropertyInfoWidgetState extends State<PropertyInfoWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _gridController;
  late AnimationController _glowController;

  late Animation<double> _expandAnimation;
  late Animation<double> _gridAnimation;

  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gridController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _gridController.forward();
      }
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    _gridController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.property.description.isNotEmpty) ...[
          _buildFuturisticSectionTitle('الوصف', Icons.description_outlined),
          const SizedBox(height: 10),
          _buildFuturisticExpandableText(),
          const SizedBox(height: 18),
        ],
        _buildFuturisticSectionTitle(
            'المخطط العام للعقار', Icons.device_hub_outlined),
        const SizedBox(height: 10),
        _buildFuturisticInfoGrid(),
        if (widget.property.ownerName.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildFuturisticSectionTitle(
              'هوية المالك', Icons.verified_user_outlined),
          const SizedBox(height: 10),
          _buildFuturisticOwnerInfo(),
        ],
      ],
    );
  }

  Widget _buildFuturisticSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppTheme.primaryCyan.withOpacity(0.8),
                      AppTheme.primaryPurple.withOpacity(0.4),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.45),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticExpandableText() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.9),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.9),
                AppTheme.darkSurface.withOpacity(0.9),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedCrossFade(
                      firstChild: Text(
                        widget.property.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.6,
                          color: AppTheme.textLight,
                        ),
                      ),
                      secondChild: Text(
                        widget.property.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.6,
                          color: AppTheme.textLight,
                        ),
                      ),
                      crossFadeState: _isDescriptionExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                          if (_isDescriptionExpanded) {
                            _expandController.forward();
                          } else {
                            _expandController.reverse();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppTheme.primaryBlue,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.35),
                                blurRadius: 12,
                                spreadRadius: 0.8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDescriptionExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isDescriptionExpanded
                                    ? 'عرض أقل من التفاصيل'
                                    : 'عرض المزيد من التفاصيل',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticInfoGrid() {
    final items = [
      _InfoItem(
        icon: Icons.home_work_outlined,
        label: 'النوع',
        value: widget.property.typeName,
        color: AppTheme.primaryBlue,
      ),
      _InfoItem(
        icon: Icons.stars_outlined,
        label: 'التصنيف',
        value: '${widget.property.starRating} نجوم',
        color: AppTheme.warning,
      ),
      _InfoItem(
        icon: Icons.location_city_outlined,
        label: 'المدينة',
        value: widget.property.city,
        color: AppTheme.primaryCyan,
      ),
      _InfoItem(
        icon: Icons.apartment_outlined,
        label: 'عدد الوحدات',
        value: '${widget.property.unitsCount} وحدة',
        color: AppTheme.primaryPurple,
      ),
    ];

    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        final t = _gridAnimation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                    AppTheme.darkCard.withOpacity(0.95),
                    AppTheme.darkSurface.withOpacity(0.96),
                  ],
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++)
                    _buildFuturisticInfoTimelineRow(
                      items[i],
                      isLast: i == items.length - 1,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticInfoTimelineRow(_InfoItem item,
      {required bool isLast}) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = _glowController.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          item.color.withOpacity(0.7 + glow * 0.2),
                          item.color.withOpacity(0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.35 * glow),
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
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            item.color.withOpacity(0.4),
                            item.color.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.color.withOpacity(0.5),
                      width: 0.9,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.96),
                        item.color.withOpacity(0.22),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              item.color.withOpacity(0.45),
                              item.color.withOpacity(0.18),
                            ],
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticOwnerInfo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.45),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.96),
            AppTheme.darkSurface.withOpacity(0.94),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.23),
            blurRadius: 20,
            spreadRadius: 0.8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                bottomStart: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.85),
                  AppTheme.primaryPurple.withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.darkSurface.withOpacity(0.85),
                          border: Border.all(
                            color: AppTheme.primaryViolet.withOpacity(0.5),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppTheme.primaryCyan,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'مالك موثوق',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      widget.property.ownerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'متواجد للرد على استفساراتك بخصوص هذا العقار',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textLight,
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
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
