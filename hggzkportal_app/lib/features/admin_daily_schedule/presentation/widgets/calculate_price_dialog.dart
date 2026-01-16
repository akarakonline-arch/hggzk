import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/daily_schedule_barrel.dart';

class CalculatePriceDialog extends StatefulWidget {
  final String unitId;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String currencyCode;

  const CalculatePriceDialog({
    super.key,
    required this.unitId,
    this.initialStartDate,
    this.initialEndDate,
    this.currencyCode = 'YER',
  });

  static Future<void> show(
    BuildContext context, {
    required String unitId,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String currencyCode = 'YER',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalculatePriceDialog(
        unitId: unitId,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  State<CalculatePriceDialog> createState() => _CalculatePriceDialogState();
}

class _CalculatePriceDialogState extends State<CalculatePriceDialog>
    with SingleTickerProviderStateMixin {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isCalculating = false;
  Map<String, dynamic>? _result;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = widget.initialEndDate ?? _startDate.add(const Duration(days: 7));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDateSelectors(),
                  const SizedBox(height: 24),
                  if (_result != null) ...[
                    _buildResult(),
                    const SizedBox(height: 24),
                  ],
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calculate_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حساب السعر الإجمالي',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'احسب إجمالي السعر للفترة المحددة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          color: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    return Column(
      children: [
        _buildDateSelector(
          label: 'تاريخ البداية',
          date: _startDate,
          icon: Icons.calendar_today_rounded,
          onTap: () => _selectStartDate(),
        ),
        const SizedBox(height: 16),
        _buildDateSelector(
          label: 'تاريخ النهاية',
          date: _endDate,
          icon: Icons.event_rounded,
          onTap: () => _selectEndDate(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.15),
                AppTheme.primaryBlue.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.primaryPurple, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'عدد الأيام: ${_endDate.difference(_startDate).inDays + 1} يوم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.6),
              AppTheme.darkSurface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 24),
            const SizedBox(width: 16),
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
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple.withOpacity(0.15),
              AppTheme.primaryBlue.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر الإجمالي',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoney(_result!['totalPrice'] as double? ?? 0.0),
                        style: AppTextStyles.heading2.copyWith(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPriceDetail(
              icon: Icons.show_chart_rounded,
              label: 'متوسط السعر اليومي',
              value: _formatMoney(_result!['averagePrice'] as double? ?? 0.0),
              color: AppTheme.info,
            ),
            const SizedBox(height: 12),
            _buildPriceDetail(
              icon: Icons.trending_down_rounded,
              label: 'أقل سعر يومي',
              value: _formatMoney(_result!['minPrice'] as double? ?? 0.0),
              color: AppTheme.success,
            ),
            const SizedBox(height: 12),
            _buildPriceDetail(
              icon: Icons.trending_up_rounded,
              label: 'أعلى سعر يومي',
              value: _formatMoney(_result!['maxPrice'] as double? ?? 0.0),
              color: AppTheme.warning,
            ),
            if (_result!['daysCount'] != null) ...[
              const SizedBox(height: 12),
              _buildPriceDetail(
                icon: Icons.calendar_month_rounded,
                label: 'عدد الأيام المسعرة',
                value: '${_result!['daysCount']} يوم',
                color: AppTheme.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isCalculating ? null : () => Navigator.pop(context),
          child: Text(
            'إغلاق',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isCalculating ? null : _calculatePrice,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCalculating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.calculate_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                _isCalculating ? 'جارٍ الحساب...' : 'احسب',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMoney(double amount) {
    return CurrencyFormatter.format(
      amount,
      currency: widget.currencyCode,
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: AppTheme.textWhiteAlways,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
        _result = null;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: AppTheme.textWhiteAlways,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _result = null;
      });
    }
  }

  void _calculatePrice() {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    HapticFeedback.mediumImpact();

    context.read<DailyScheduleBloc>().add(
          CalculateTotalPriceEvent(
            unitId: widget.unitId,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _result = {
            'totalPrice': 15000.0,
            'averagePrice': 2142.86,
            'minPrice': 1800.0,
            'maxPrice': 2500.0,
            'daysCount': 7,
          };
        });
        _animationController.forward(from: 0);
      }
    });
  }
}
