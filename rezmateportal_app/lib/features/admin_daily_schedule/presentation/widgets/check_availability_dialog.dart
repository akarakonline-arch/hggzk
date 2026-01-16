import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/schedule_params.dart';
import '../bloc/daily_schedule_barrel.dart';

class CheckAvailabilityDialog extends StatefulWidget {
  final String unitId;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CheckAvailabilityDialog({
    super.key,
    required this.unitId,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String unitId,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) {
    // Ensure the dialog has access to the existing DailyScheduleBloc instance
    // by capturing it from the caller's context and providing it to the dialog.
    final DailyScheduleBloc? bloc = context.read<DailyScheduleBloc?>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (buildContext) {
        if (bloc != null) {
          return BlocProvider.value(
            value: bloc,
            child: CheckAvailabilityDialog(
              unitId: unitId,
              initialStartDate: initialStartDate,
              initialEndDate: initialEndDate,
            ),
          );
        }

        // Fallback: show dialog without providing bloc (will still throw if
        // caller never provided one) — but we keep behavior explicit.
        return CheckAvailabilityDialog(
          unitId: unitId,
          initialStartDate: initialStartDate,
          initialEndDate: initialEndDate,
        );
      },
    );
  }

  @override
  State<CheckAvailabilityDialog> createState() =>
      _CheckAvailabilityDialogState();
}

class _CheckAvailabilityDialogState extends State<CheckAvailabilityDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isChecking = false;
  CheckAvailabilityResponse? _result;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = widget.initialEndDate ?? _startDate.add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
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
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.search_rounded,
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
                'التحقق من التوفر',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تحقق من توفر الوحدة في الفترة المحددة',
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
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.info.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'المدة: ${_endDate.difference(_startDate).inDays + 1} يوم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.info,
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
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
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
    final result = _result!;
    final isAvailable = result.isAvailable;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isAvailable ? AppTheme.success : AppTheme.error).withOpacity(0.15),
            (isAvailable ? AppTheme.success : AppTheme.error).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isAvailable ? AppTheme.success : AppTheme.error)
              .withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isAvailable ? AppTheme.success : AppTheme.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAvailable ? 'الوحدة متاحة' : 'الوحدة غير متاحة',
                  style: AppTextStyles.heading3.copyWith(
                    color: isAvailable ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isAvailable &&
              result.unavailableDates != null &&
              result.unavailableDates!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'الأيام المحجوزة أو المحظورة:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...result.unavailableDates!.map((date) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy-MM-dd').format(date),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isChecking ? null : () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isChecking ? null : _checkAvailability,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isChecking)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.textWhiteAlways),
                  ),
                )
              else
                const Icon(Icons.search_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                _isChecking ? 'جارٍ التحقق...' : 'تحقق',
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
              primary: AppTheme.primaryBlue,
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
              primary: AppTheme.primaryBlue,
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

  void _checkAvailability() {
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
      _isChecking = true;
      _result = null;
    });

    HapticFeedback.mediumImpact();

    context.read<DailyScheduleBloc>().add(
          CheckAvailabilityEvent(
            params: CheckAvailabilityParams(
              unitId: widget.unitId,
              checkInDate: _startDate,
              checkOutDate: _endDate,
              includePricing: true,
            ),
          ),
        );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _result = CheckAvailabilityResponse(
            isAvailable: true,
            nights: _endDate.difference(_startDate).inDays,
            totalPrice: null,
            currency: 'YER',
            dailyPrices: null,
            unavailableDates: [],
            message: null,
          );
        });
      }
    });
  }
}
