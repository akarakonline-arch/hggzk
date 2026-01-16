import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Booking booking;

  const BookingConfirmationPage({
    super.key,
    required this.booking,
  });

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with SingleTickerProviderStateMixin {
  // Simplified Animation
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mainController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBackground,
                    AppTheme.darkSurface.withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // Subtle success glow
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.success
                              .withOpacity(0.1 * _scaleAnimation.value),
                          AppTheme.success
                              .withOpacity(0.05 * _scaleAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Content
            SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildContent(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildCompactSuccessIcon(),
          const SizedBox(height: 24),
          _buildSuccessMessage(),
          const SizedBox(height: 32),
          _buildMinimalBookingCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompactSuccessIcon() {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.success.withOpacity(0.1),
            border: Border.all(
              color: AppTheme.success.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(40, 40),
              painter: _MinimalCheckPainter(
                progress: _checkAnimation.value,
                color: AppTheme.success,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Text(
          'تم الحجز بنجاح!',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'رقم الحجز: ${widget.booking.bookingNumber}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalBookingCard() {
    final dateFormat = DateFormat('dd MMM', 'ar');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Property Name
          _buildCompactRow(
            icon: Icons.home_outlined,
            label: widget.booking.propertyName,
            isTitle: true,
          ),

          if (widget.booking.unitName != null) ...[
            const SizedBox(height: 12),
            _buildCompactRow(
              icon: Icons.door_back_door_outlined,
              label: widget.booking.unitName!,
            ),
          ],

          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),

          // Dates Row
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  title: 'دخول',
                  date: dateFormat.format(widget.booking.checkInDate),
                  icon: Icons.login_rounded,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildDateInfo(
                  title: 'خروج',
                  date: dateFormat.format(widget.booking.checkOutDate),
                  icon: Icons.logout_rounded,
                  isEnd: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),

          // Guests and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Icons.people_outline,
                label: '${widget.booking.totalGuests} ضيف',
              ),
              _buildPriceChip(
                amount: widget.booking.totalAmount,
                currency: widget.booking.currency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow({
    required IconData icon,
    required String label,
    bool isTitle = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: isTitle
                ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  )
                : AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo({
    required String title,
    required String date,
    required IconData icon,
    bool isEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip({
    required double amount,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.15),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '${amount.toStringAsFixed(0)} $currency',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Action - View Details
        _buildMinimalButton(
          label: 'عرض التفاصيل',
          icon: Icons.description_outlined,
          onPressed: () => context.push('/booking/${widget.booking.id}'),
          isPrimary: true,
        ),

        const SizedBox(height: 12),

        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildMinimalButton(
                label: 'مشاركة',
                icon: Icons.share_outlined,
                onPressed: _shareBooking,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMinimalButton(
                label: 'حفظ PDF',
                icon: Icons.download_outlined,
                onPressed: _downloadPDF,
                isCompact: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Home Link
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(
            'العودة للرئيسية',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.textMuted.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        height: isCompact ? 42 : 48,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.9),
                  ],
                )
              : null,
          color: !isPrimary ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(12),
          border: !isPrimary
              ? Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 0.5,
                )
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isPrimary ? Colors.white : AppTheme.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: (isCompact
                        ? AppTextStyles.bodySmall
                        : AppTextStyles.bodyMedium)
                    .copyWith(
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareBooking() {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    final shareText = '''
تم تأكيد الحجز ✅

📍 ${widget.booking.propertyName}
📅 ${dateFormat.format(widget.booking.checkInDate)} - ${dateFormat.format(widget.booking.checkOutDate)}
👥 ${widget.booking.totalGuests} ضيف
💰 ${widget.booking.totalAmount.toStringAsFixed(0)} ${widget.booking.currency}
🎫 ${widget.booking.bookingNumber}
    ''';

    Clipboard.setData(ClipboardData(text: shareText));
    _showMinimalSnackBar('تم نسخ التفاصيل');
  }

  void _downloadPDF() {
    _showMinimalSnackBar('جاري تحميل PDF...');
  }

  void _showMinimalSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Minimal Check Painter
class _MinimalCheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MinimalCheckPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (progress > 0) {
      path.moveTo(size.width * 0.25, size.height * 0.5);

      if (progress <= 0.5) {
        final firstProgress = progress * 2;
        path.lineTo(
          size.width * 0.25 + (size.width * 0.15 * firstProgress),
          size.height * 0.5 + (size.height * 0.15 * firstProgress),
        );
      } else {
        path.lineTo(size.width * 0.4, size.height * 0.65);

        final secondProgress = (progress - 0.5) * 2;
        path.lineTo(
          size.width * 0.4 + (size.width * 0.35 * secondProgress),
          size.height * 0.65 - (size.height * 0.35 * secondProgress),
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
