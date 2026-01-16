// lib/features/admin_daily_schedule/presentation/widgets/stats_dashboard_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/daily_schedule.dart';

/// لوحة الإحصائيات الشاملة للجدول اليومي
/// Comprehensive stats dashboard for daily schedule
/// 
/// ميزات:
/// - عرض إحصائيات الإتاحة والتسعير
/// - تأثيرات أنيميشن متقدمة
/// - رسوم بيانية تفاعلية
/// - تحديث مباشر للبيانات
class StatsDashboardCard extends StatefulWidget {
  /// قائمة الجداول اليومية
  final List<DailySchedule> schedules;
  
  /// عملة العرض
  final String currency;

  const StatsDashboardCard({
    super.key,
    required this.schedules,
    this.currency = 'YER',
  });

  @override
  State<StatsDashboardCard> createState() => _StatsDashboardCardState();
}

class _StatsDashboardCardState extends State<StatsDashboardCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _countController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countController.dispose();
    super.dispose();
  }

  /// حساب الإحصائيات من البيانات
  Map<String, dynamic> _calculateStats() {
    final totalDays = widget.schedules.length;
    final availableDays = widget.schedules.where((s) => s.isAvailable).length;
    final bookedDays = widget.schedules.where((s) => s.isBooked).length;
    final blockedDays = widget.schedules.where((s) => s.isBlocked).length;
    final maintenanceDays = widget.schedules.where((s) => s.isMaintenance).length;
    
    final occupancyRate = totalDays > 0 ? bookedDays / totalDays : 0.0;
    
    final prices = widget.schedules
        .where((s) => s.priceAmount != null && s.priceAmount! > 0)
        .map((s) => s.priceAmount!)
        .toList();
    
    final averagePrice = prices.isNotEmpty 
        ? prices.reduce((a, b) => a + b) / prices.length 
        : 0.0;
    final minPrice = prices.isNotEmpty ? prices.reduce(math.min) : 0.0;
    final maxPrice = prices.isNotEmpty ? prices.reduce(math.max) : 0.0;
    final potentialRevenue = prices.isNotEmpty 
        ? prices.reduce((a, b) => a + b) 
        : 0.0;
    
    return {
      'totalDays': totalDays,
      'availableDays': availableDays,
      'bookedDays': bookedDays,
      'blockedDays': blockedDays,
      'maintenanceDays': maintenanceDays,
      'occupancyRate': occupancyRate,
      'averagePrice': averagePrice,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'potentialRevenue': potentialRevenue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAvailabilityStats(stats),
                            const SizedBox(height: 20),
                            _buildPricingStats(stats),
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
      },
    );
  }

  /// رأس لوحة الإحصائيات
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'الإحصائيات',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'مباشر',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// إحصائيات الإتاحة
  Widget _buildAvailabilityStats(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات الإتاحة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.check_circle_rounded,
          label: 'أيام متاحة',
          value: stats['availableDays'].toString(),
          total: stats['totalDays'],
          color: AppTheme.success,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.event_busy_rounded,
          label: 'أيام محجوزة',
          value: stats['bookedDays'].toString(),
          total: stats['totalDays'],
          color: AppTheme.warning,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.block_rounded,
          label: 'أيام محظورة',
          value: stats['blockedDays'].toString(),
          total: stats['totalDays'],
          color: AppTheme.error,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.build_rounded,
          label: 'أيام صيانة',
          value: stats['maintenanceDays'].toString(),
          total: stats['totalDays'],
          color: AppTheme.info,
        ),
        const SizedBox(height: 16),
        _buildOccupancyRate(stats['occupancyRate']),
      ],
    );
  }

  /// إحصائيات التسعير
  Widget _buildPricingStats(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات التسعير',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildPriceCard(
          label: 'متوسط السعر',
          value: stats['averagePrice'],
          icon: Icons.analytics_rounded,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: 12),
        _buildPriceCard(
          label: 'أعلى سعر',
          value: stats['maxPrice'],
          icon: Icons.trending_up_rounded,
          color: AppTheme.error,
        ),
        const SizedBox(height: 12),
        _buildPriceCard(
          label: 'أقل سعر',
          value: stats['minPrice'],
          icon: Icons.trending_down_rounded,
          color: AppTheme.success,
        ),
        const SizedBox(height: 16),
        _buildRevenueCard(stats['potentialRevenue']),
      ],
    );
  }

  /// صف إحصائي واحد
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (int.parse(value) / total * 100) : 0.0;
    
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _countController,
                    builder: (context, child) {
                      final animatedValue = (_countController.value * int.parse(value)).round();
                      return Text(
                        '$animatedValue',
                        style: AppTextStyles.heading3.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    ' / $total',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// معدل الإشغال
  Widget _buildOccupancyRate(double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل الإشغال',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'للفترة المحددة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة سعر واحدة
  Widget _buildPriceCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(0)} ${widget.currency}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الإيرادات المحتملة
  Widget _buildRevenueCard(double revenue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإيرادات المحتملة',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '${revenue.toStringAsFixed(0)} ${widget.currency}',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
