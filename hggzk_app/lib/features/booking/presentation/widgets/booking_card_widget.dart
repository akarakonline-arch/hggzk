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
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isMissed) ...[
                    BookingStatusWidget(
                      status: widget.booking.status,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      showIcon: false,
                      animated: false,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.booking.isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'مدفوع بالكامل',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.success.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    if (isPartiallyPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.info.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'مدفوع جزئياً',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.info.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else ...[
                      if (!_hasStarted() && !_isCancelledOrDone() && _showAwaitingPayment())
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'في انتظار الدفع',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.warning.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    if (isMissed)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'تم تفويت الحجز',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.error.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${widget.booking.bookingNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPropertyInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildMinimalPropertyImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.propertyName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.booking.unitName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.booking.unitName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
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
                      size: 10,
                      color: AppTheme.primaryCyan.withOpacity(0.7),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.booking.propertyAddress ?? 'موقع العقار',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.6),
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
            : Container(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                child: Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  size: 24,
                ),
              ),
      ),
    );
  }

  Widget _buildCompactBookingDetails(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactDetailItem(
            icon: Icons.calendar_today_rounded,
            iconColor: AppTheme.primaryBlue.withOpacity(0.8),
            label: 'الوصول',
            value: dateFormat.format(widget.booking.checkInDate),
          ),
          _buildMinimalDivider(),
          _buildCompactDetailItem(
            icon: Icons.calendar_today_outlined,
            iconColor: AppTheme.primaryPurple.withOpacity(0.8),
            label: 'المغادرة',
            value: dateFormat.format(widget.booking.checkOutDate),
          ),
          _buildMinimalDivider(),
          _buildCompactDetailItem(
            icon: Icons.people_outline_rounded,
            iconColor: AppTheme.primaryCyan.withOpacity(0.8),
            label: 'الضيوف',
            value: widget.booking.totalGuests.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalDivider() {
    return Container(
      height: 28,
      width: 0.5,
      color: AppTheme.darkBorder.withOpacity(0.1),
    );
  }

  Widget _buildMinimalActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PriceWidget(
            price: widget.booking.totalAmount,
            currency: widget.booking.currency,
            displayType: PriceDisplayType.compact,
            priceStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryBlue.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              if (widget.onCancel != null && widget.booking.canCancel)
                _buildMinimalActionButton(
                  label: 'إلغاء',
                  onPressed: widget.onCancel!,
                  color: AppTheme.error.withOpacity(0.8),
                  icon: Icons.close_rounded,
                ),
              if (widget.onReview != null)
                _buildMinimalActionButton(
                  label: 'تقييم',
                  onPressed: widget.onReview!,
                  color: AppTheme.warning.withOpacity(0.8),
                  icon: Icons.star_outline_rounded,
                ),
              if (widget.onEdit != null && widget.booking.canModify)
                _buildMinimalActionButton(
                  label: 'تعديل',
                  onPressed: widget.onEdit!,
                  color: AppTheme.info.withOpacity(0.8),
                  icon: Icons.edit_rounded,
                ),
              _buildMinimalActionButton(
                label: 'التفاصيل',
                onPressed: widget.onTap,
                color: AppTheme.primaryBlue.withOpacity(0.9),
                icon: Icons.arrow_forward_rounded,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasStarted() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDate = DateTime(
      widget.booking.checkInDate.year,
      widget.booking.checkInDate.month,
      widget.booking.checkInDate.day,
    );
    return today.isAfter(checkInDate);
  }

  bool _isCancelledOrDone() {
    return widget.booking.status == BookingStatus.cancelled ||
        widget.booking.status == BookingStatus.completed ||
        widget.booking.status == BookingStatus.checkedIn;
  }

  bool _showAwaitingPayment() {
    // يظهر "في انتظار الدفع" فقط إذا كان الحجز مؤكد وغير مدفوع
    return widget.booking.status == BookingStatus.confirmed && !widget.booking.isPaid;
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