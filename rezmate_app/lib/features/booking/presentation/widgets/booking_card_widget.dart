import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/price_widget.dart';
import '../../../../core/enums/booking_status.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import 'booking_status_widget.dart';

class BookingCardWidget extends StatefulWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final bool showActions;
  final VoidCallback? onEdit;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
    this.onReview,
    this.showActions = true,
    this.onEdit,
  });

  @override
  State<BookingCardWidget> createState() => _BookingCardWidgetState();
}

class _BookingCardWidgetState extends State<BookingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM', 'ar');

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
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
                AppTheme.darkCard.withOpacity(0.96),
                AppTheme.darkSurface.withOpacity(0.96),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withOpacity(0.55),
                blurRadius: 22,
                spreadRadius: 0.8,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                  // Subtle shimmer effect
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1 + _shimmerAnimation.value, 0),
                              end: Alignment(-0.5 + _shimmerAnimation.value, 0),
                              colors: [
                                Colors.transparent,
                                _getStatusColor().withOpacity(0.02),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Content
                  Column(
                    children: [
                      _buildMinimalHeader(),
                      _buildCompactPropertyInfo(),
                      _buildCompactBookingDetails(dateFormat),
                      if (widget.showActions) _buildMinimalActions(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalHeader() {
    final bool isMissed = _hasStarted() && !_isCancelledOrDone();
    final bool isPartiallyPaid = _isPartiallyPaid();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            _getStatusColor().withOpacity(0.25),
            _getStatusColor().withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.6),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStatusColor().withOpacity(0.9),
                  _getStatusColor().withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMissed)
                      BookingStatusWidget(
                        status: widget.booking.status,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        showIcon: false,
                        animated: false,
                      ),
                    if (!isMissed) const SizedBox(width: 6),
                    if (isMissed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.error.withOpacity(0.12),
                          border: Border.all(
                            color: AppTheme.error.withOpacity(0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'تم تفويت الحجز',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.error.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (widget.booking.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.success.withOpacity(0.09),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'مدفوع بالكامل',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.success.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isPartiallyPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.info.withOpacity(0.08),
                          border: Border.all(
                            color: AppTheme.info.withOpacity(0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'مدفوع جزئياً',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.info.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (!_hasStarted() &&
                        !_isCancelledOrDone() &&
                        _showAwaitingPayment())
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.warning.withOpacity(0.08),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'في انتظار الدفع',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.warning.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.9),
                  AppTheme.primaryPurple.withOpacity(0.7),
                ],
              ),
            ),
            child: Text(
              '#${widget.booking.bookingNumber}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildMinimalPropertyImage(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.propertyName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite.withOpacity(0.98),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.booking.unitName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.booking.unitName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: AppTheme.primaryCyan.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.booking.propertyAddress ?? 'موقع العقار',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
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
    );
  }

  Widget _buildMinimalPropertyImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.booking.unitImages.isNotEmpty
            ? CachedImageWidget(
                imageUrl: widget.booking.unitImages.first,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(12),
              )
            : Icon(
                Icons.image_outlined,
                color: AppTheme.textMuted.withOpacity(0.5),
                size: 24,
              ),
      ),
    );
  }

  Widget _buildCompactBookingDetails(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ الحجز',
            value:
                '${dateFormat.format(widget.booking.checkInDate)} - ${dateFormat.format(widget.booking.checkOutDate)}',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.nights_stay_outlined,
            label: 'عدد الليالي',
            value:
                '${widget.booking.numberOfNights} ${widget.booking.numberOfNights == 1 ? 'ليلة' : 'ليالي'}',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.people_outline,
            label: 'الضيوف',
            value:
                '${widget.booking.totalGuests} ${widget.booking.totalGuests == 1 ? 'ضيف' : 'ضيوف'}',
          ),
          const SizedBox(height: 8),
          _buildPriceRow(),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textMuted.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    final remaining = _calculateRemainingAmount();
    final isPartiallyPaid = _isPartiallyPaid();

    return Row(
      children: [
        Icon(
          Icons.attach_money,
          size: 14,
          color: AppTheme.primaryCyan.withOpacity(0.8),
        ),
        const SizedBox(width: 6),
        Text(
          isPartiallyPaid ? 'المبلغ المتبقي' : 'السعر الإجمالي',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        PriceWidget(
          price: isPartiallyPaid ? remaining : widget.booking.totalAmount,
          currency: widget.booking.currency,
          displayType: PriceDisplayType.normal,
          priceStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isPartiallyPaid
                ? AppTheme.warning.withOpacity(0.9)
                : AppTheme.primaryCyan.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalActions() {
    if (!widget.showActions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.booking.status == BookingStatus.pending &&
              widget.onCancel != null)
            _buildMinimalActionButton(
              label: 'إلغاء',
              onPressed: widget.onCancel!,
              color: AppTheme.error,
              icon: Icons.close_rounded,
            ),
          if (widget.booking.status == BookingStatus.completed &&
              widget.onReview != null)
            _buildMinimalActionButton(
              label: 'تقييم',
              onPressed: widget.onReview!,
              color: AppTheme.warning,
              icon: Icons.star_border_rounded,
            ),
          if (widget.onEdit != null &&
              widget.booking.status != BookingStatus.cancelled &&
              widget.booking.status != BookingStatus.completed)
            _buildMinimalActionButton(
              label: 'تعديل',
              onPressed: widget.onEdit!,
              color: AppTheme.info,
              icon: Icons.edit_outlined,
            ),
          _buildMinimalActionButton(
            label: 'التفاصيل',
            onPressed: widget.onTap,
            color: AppTheme.primaryBlue,
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: isPrimary
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: !isPrimary
                ? BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 0.5,
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isPrimary ? Colors.white : color,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isPrimary ? Colors.white : color,
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

  // Helper Methods
  bool _hasStarted() {
    return widget.booking.checkInDate.isBefore(DateTime.now());
  }

  bool _isCancelledOrDone() {
    return widget.booking.status == BookingStatus.cancelled ||
        widget.booking.status == BookingStatus.completed;
  }

  bool _showAwaitingPayment() {
    return !widget.booking.isPaid &&
        widget.booking.status == BookingStatus.pending;
  }

  double _calculatePaidAmount() {
    double paid = 0.0;
    for (final payment in widget.booking.payments) {
      try {
        if (payment.status == PaymentStatus.completed) {
          paid += payment.amount;
        }
      } catch (_) {}
    }
    return paid;
  }

  double _calculateRemainingAmount() {
    final total = widget.booking.totalAmount;
    final paid = _calculatePaidAmount();
    final remaining = total - paid;
    return remaining > 0 ? remaining : 0.0;
  }

  bool _isPartiallyPaid() {
    if (widget.booking.isPaid) {
      return false;
    }
    final paid = _calculatePaidAmount();
    final remaining = _calculateRemainingAmount();
    return paid > 0.0 && remaining > 0.0;
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case BookingStatus.confirmed:
        return AppTheme.success.withOpacity(0.8);
      case BookingStatus.pending:
        return AppTheme.warning.withOpacity(0.8);
      case BookingStatus.cancelled:
        return AppTheme.error.withOpacity(0.8);
      case BookingStatus.completed:
        return AppTheme.info.withOpacity(0.8);
      case BookingStatus.checkedIn:
        return AppTheme.primaryBlue.withOpacity(0.8);
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case BookingStatus.pending:
        return Icons.hourglass_empty_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.completed:
        return Icons.done_all_rounded;
      case BookingStatus.checkedIn:
        return Icons.login_rounded;
    }
  }
}
