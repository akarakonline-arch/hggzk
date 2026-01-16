import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/price_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/enums/booking_status.dart';
import '../../domain/entities/payment.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/booking_status_widget.dart';
import '../widgets/cancellation_deadline_has_expired_widget.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showQRCode = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
            GetBookingDetailsEvent(
              bookingId: widget.bookingId,
              userId: authState.user.userId,
            ),
          );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _refreshUserBookings();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: _handleBookingState,
          builder: (context, state) {
            if (state is BookingLoading) {
              return _buildLoadingState();
            }

            if (state is BookingError) {
              return _buildErrorState(state);
            }

            if (state is BookingDetailsLoaded) {
              return _buildContent(state.booking);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _handleBookingState(BuildContext context, BookingState state) {
    if (state is BookingError && state.showAsDialog) {
      final code = state.code ?? state.message;
      if (code == 'CANCELLATION_AFTER_CHECKIN') {
        _showPolicyDialog(
          title: 'لا يمكن إلغاء الحجز',
          description: 'لا يمكن إلغاء الحجز بعد وقت تسجيل الوصول.',
        );
      } else if (code == 'CANCELLATION_WINDOW_EXCEEDED') {
        _showPolicyDialog(
          title: 'غير مسموح بالإلغاء',
          description: 'لا يمكن إلغاء الحجز خلال نافذة الإلغاء المحددة.',
        );
      } else if (code == 'REFUND_EXCEEDS_POLICY') {
        _showPolicyDialog(
          title: 'طلب الاسترداد مرفوض',
          description: 'المبلغ المطلوب للاسترداد يتجاوز الحد المسموح.',
        );
      }
    }
  }

  Future<void> _refreshUserBookings() async {
    context.read<BookingBloc>().add(const ResetBookingStateEvent());
  }

  // ═══════════════════════════════════════════════════════════════
  // المحتوى الرئيسي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildContent(dynamic booking) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(booking),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              )),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusCard(booking),
                    const SizedBox(height: 16),
                    _buildQRCodeSection(booking),
                    const SizedBox(height: 16),
                    _buildPropertyCard(booking),
                    const SizedBox(height: 16),
                    _buildBookingInfoCard(booking),
                    const SizedBox(height: 16),
                    _buildGuestInfoCard(booking),
                    const SizedBox(height: 16),
                    _buildPoliciesCard(booking),
                    if (booking.services.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildServicesCard(booking),
                    ],
                    const SizedBox(height: 16),
                    _buildUnpaidWarning(booking),
                    const SizedBox(height: 16),
                    _buildPaymentInfoCard(booking),
                    if (booking.canCancel) ...[
                      const SizedBox(height: 16),
                      _buildCancellationPolicy(booking),
                    ],
                    const SizedBox(height: 20),
                    _buildActionsSection(booking),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAppBar(dynamic booking) {
    final statusColor = _getStatusColor(booking.status);

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: _buildBackButton(),
      actions: [
        _buildAppBarAction(
          icon: Icons.share_rounded,
          tooltip: 'مشاركة الحجز',
          color: AppTheme.primaryBlue,
          onPressed: _shareBooking,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                statusColor.withOpacity(0.15),
                AppTheme.darkBackground,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'تفاصيل الحجز',
                  style: AppTextStyles.h3.copyWith(
                    color: AppTheme.textWhite,
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

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: AppTheme.textWhite,
        onPressed: () {
          HapticFeedback.selectionClick();
          _refreshUserBookings();
          Navigator.pop(context);
        },
      ),
    );
  }

  /// زر خاص بالـ AppBar بحجم ثابت (لتجنب خطأ RenderBox)
  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        tooltip: tooltip,
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة الحالة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatusCard(dynamic booking) {
    final statusColor = _getStatusColor(booking.status);
    final isMissed = _checkIfMissed(booking);

    return _buildCard(
      gradient: LinearGradient(
        colors: [
          statusColor.withOpacity(0.1),
          statusColor.withOpacity(0.05),
        ],
      ),
      borderColor: statusColor.withOpacity(0.25),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(booking.status),
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMissed)
                  Text(
                    'تم تفويت الحجز',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  BookingStatusWidget(
                    status: booking.status,
                    showIcon: false,
                    animated: false,
                  ),
                const SizedBox(height: 4),
                Text(
                  'رقم الحجز: ${booking.bookingNumber}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'تاريخ الحجز: ${DateFormat('dd/MM/yyyy').format(booking.bookingDate)}',
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

  // ═══════════════════════════════════════════════════════════════
  // قسم QR Code
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQRCodeSection(dynamic booking) {
    return Column(
      children: [
        // زر عرض/إخفاء QR
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showQRCode = !_showQRCode);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showQRCode
                      ? Icons.qr_code_2_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _showQRCode ? 'إخفاء رمز QR' : 'عرض رمز QR',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // QR Code
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _showQRCode
              ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: booking.bookingNumber,
                          version: QrVersions.auto,
                          size: 140,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اعرض هذا الكود عند تسجيل الوصول',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة العقار
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPropertyCard(dynamic booking) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.apartment_rounded,
            title: 'تفاصيل العقار',
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 14),

          // صورة العقار
          if (booking.unitImages.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(booking.unitImages.first),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  size: 40,
                ),
              ),
            ),

          const SizedBox(height: 14),
          Text(
            booking.propertyName,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (booking.unitName != null) ...[
            const SizedBox(height: 4),
            Text(
              booking.unitName!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppTheme.primaryCyan,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.propertyAddress ?? 'العنوان غير متوفر',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة معلومات الحجز
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBookingInfoCard(dynamic booking) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.calendar_today_rounded,
            title: 'معلومات الإقامة',
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.login_rounded,
            label: 'تاريخ الوصول',
            value: dateFormat.format(booking.checkInDate),
            color: AppTheme.primaryBlue,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.logout_rounded,
            label: 'تاريخ المغادرة',
            value: dateFormat.format(booking.checkOutDate),
            color: AppTheme.primaryPurple,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.nights_stay_rounded,
            label: 'عدد الليالي',
            value:
                '${booking.numberOfNights} ${booking.numberOfNights == 1 ? 'ليلة' : 'ليالي'}',
            color: AppTheme.primaryCyan,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة معلومات الضيوف
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGuestInfoCard(dynamic booking) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.people_outline_rounded,
            title: 'معلومات الضيوف',
            color: AppTheme.success,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'اسم الضيف',
            value: booking.userName,
            color: AppTheme.success,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.groups_rounded,
            label: 'عدد الضيوف',
            value:
                '${booking.totalGuests} ضيف (${booking.adultGuests} بالغ${booking.childGuests > 0 ? '، ${booking.childGuests} طفل' : ''})',
            color: AppTheme.success,
          ),
          if (booking.specialRequests != null) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.note_rounded,
              label: 'طلبات خاصة',
              value: booking.specialRequests!,
              color: AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة السياسات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPoliciesCard(dynamic booking) {
    final snapshot = booking.policySnapshot as String?;
    if (snapshot == null || snapshot.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    List<dynamic> policies = [];
    try {
      final decoded = jsonDecode(snapshot);
      if (decoded is Map<String, dynamic> && decoded['Policies'] is List) {
        policies = decoded['Policies'] as List;
      }
    } catch (_) {}

    if (policies.isEmpty) return const SizedBox.shrink();

    final Color policyColor =
        Color.lerp(AppTheme.warning, AppTheme.darkCard, 0.9)!;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.policy_rounded,
            title: 'سياسات الحجز',
            color: policyColor,
          ),
          const SizedBox(height: 14),
          ...policies.map((p) {
            String type = '';
            String description = '';
            try {
              if (p is Map) {
                type = (p['Type'] ?? '').toString();
                description = (p['Description'] ?? '').toString();
              }
            } catch (_) {}

            if (description.isEmpty) return const SizedBox.shrink();
            final visual = _getBookingPolicyVisual(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: policyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(visual.icon, size: 16, color: policyColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visual.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).where((w) => w is! SizedBox),
        ],
      ),
    );
  }

  Widget _buildServicesCard(dynamic booking) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.room_service_rounded,
            title: 'الخدمات الإضافية',
            color: AppTheme.primaryViolet,
          ),
          const SizedBox(height: 14),
          ...booking.services.map<Widget>((service) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${service.serviceName} x${service.quantity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                    PriceWidget(
                      price: service.totalPrice,
                      currency: service.currency,
                      displayType: PriceDisplayType.compact,
                      priceStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.primaryViolet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // تحذير عدم الدفع
  // ═══════════════════════════════════════════════════════════════
  Widget _buildUnpaidWarning(dynamic booking) {
    if (booking.isPaid == true) return const SizedBox.shrink();

    final isMissed = _checkIfMissed(booking);
    final isPending = booking.status == BookingStatus.pending;

    final String title;
    final String message;
    final Color warningColor =
        Color.lerp(AppTheme.warning, AppTheme.darkCard, 0.9)!;

    if (isMissed) {
      title = 'تم تفويت الحجز';
      message = 'انتهى وقت الوصول المحدد لهذا الحجز دون تسجيل الوصول.';
    } else if (isPending) {
      title = 'الحجز في انتظار التأكيد';
      message = 'تم إنشاء طلب الحجز وهو في انتظار التأكيد.';
    } else {
      title = 'في انتظار الدفع';
      message = 'يرجى إتمام الدفع لتأكيد الحجز.';
    }

    return _buildCard(
      gradient: LinearGradient(
        colors: [
          warningColor.withOpacity(0.13),
          warningColor.withOpacity(0.06),
        ],
      ),
      borderColor: warningColor.withOpacity(0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: warningColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة معلومات الدفع
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPaymentInfoCard(dynamic booking) {
    final double baseTotal = (booking.totalAmount ?? 0).toDouble();
    final double servicesTotal =
        booking.services != null && booking.services is List
            ? booking.services.fold(0.0, (sum, service) {
                try {
                  return sum + (service.totalPrice ?? 0).toDouble();
                } catch (_) {
                  return sum;
                }
              })
            : 0.0;
    final double total = baseTotal + servicesTotal;
    final String currency = booking.currency ?? 'YER';
    double paid = 0.0;

    if (booking.payments != null && booking.payments is List) {
      for (final p in booking.payments) {
        try {
          if (p.status == PaymentStatus.completed) {
            paid += (p.amount ?? 0).toDouble();
          }
        } catch (_) {}
      }
    }

    final double remaining = (total - paid) > 0 ? (total - paid) : 0.0;
    final bool isFullyPaid = (booking.isPaid == true) || remaining <= 0.0;
    final bool isPartiallyPaid = !isFullyPaid && paid > 0.0;

    final Color paymentBaseColor =
        Color.lerp(AppTheme.success, AppTheme.darkCard, 0.9)!;

    return _buildCard(
      gradient: LinearGradient(
        colors: [
          Color.lerp(AppTheme.darkBackground, paymentBaseColor, 0.24)!,
          Color.lerp(AppTheme.darkBackground, paymentBaseColor, 0.12)!,
        ],
      ),
      borderColor: Color.lerp(AppTheme.darkBackground, paymentBaseColor, 0.32)!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.payment_rounded,
            title: 'معلومات الدفع',
            color: AppTheme.success,
          ),
          const SizedBox(height: 14),

          // حالة الدفع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حالة الدفع',
                style:
                    AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isFullyPaid
                          ? AppTheme.success
                          : isPartiallyPaid
                              ? AppTheme.info
                              : AppTheme.warning)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFullyPaid
                      ? 'مدفوع بالكامل'
                      : isPartiallyPaid
                          ? 'مدفوع جزئياً'
                          : 'غير مدفوع',
                  style: AppTextStyles.caption.copyWith(
                    color: isFullyPaid
                        ? AppTheme.success
                        : isPartiallyPaid
                            ? AppTheme.info
                            : AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildPaymentRow(
              'المبلغ الإجمالي', total, currency, AppTheme.textWhite),
          const SizedBox(height: 8),
          _buildPaymentRow('المدفوع', paid, currency, AppTheme.success),
          const SizedBox(height: 8),
          _buildPaymentRow('المتبقي', remaining, currency, AppTheme.warning),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
      String label, double amount, String currency, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
        ),
        Text(
          '${amount.toStringAsFixed(0)} $currency',
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // سياسة الإلغاء
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCancellationPolicy(dynamic booking) {
    final cancellationDeadline =
        booking.checkInDate.subtract(const Duration(hours: 24));
    final canCancelFree = DateTime.now().isBefore(cancellationDeadline);

    return CancellationDeadlineHasExpiredWidget(
      hasExpired: !canCancelFree,
      deadline: cancellationDeadline,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // قسم الإجراءات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActionsSection(dynamic booking) {
    final canShowPayButton = _canShowPayButton(booking);

    return Column(
      children: [
        _buildActionButton(
          icon: Icons.apartment_rounded,
          label: 'تفاصيل العقار',
          color: AppTheme.primaryBlue,
          onPressed: () => _openPropertyDetails(booking),
        ),
        if (canShowPayButton) ...[
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.payment_rounded,
            label: 'الدفع الآن',
            color: AppTheme.primaryPurple,
            onPressed: () => _goToPayment(booking),
          ),
        ],
        if (booking.canModify) ...[
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.edit_rounded,
            label: 'تعديل الحجز',
            color: AppTheme.primaryCyan,
            onPressed: () => _modifyBooking(booking),
          ),
        ],
        if (booking.canCancel) ...[
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.cancel_rounded,
            label: 'إلغاء الحجز',
            color: AppTheme.error,
            onPressed: () => _cancelBooking(booking),
          ),
        ],
        if (booking.status == BookingStatus.completed && booking.canReview) ...[
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.rate_review_rounded,
            label: 'كتابة تقييم',
            color: AppTheme.warning,
            onPressed: () => _writeReview(booking),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // مكونات مساعدة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCard({
    required Widget child,
    LinearGradient? gradient,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppTheme.darkBorder.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل التفاصيل...',
      ),
    );
  }

  Widget _buildErrorState(BookingError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: AppTextStyles.h3.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookingDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════
  bool _checkIfMissed(dynamic booking) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDate = DateTime(
      booking.checkInDate.year,
      booking.checkInDate.month,
      booking.checkInDate.day,
    );
    return today.isAfter(checkInDate) &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.completed &&
        booking.status != BookingStatus.checkedIn;
  }

  bool _canShowPayButton(dynamic booking) {
    final double total = (booking.totalAmount ?? 0).toDouble();
    double paid = 0.0;
    if (booking.payments != null && booking.payments is List) {
      for (final p in booking.payments) {
        try {
          if (p.status == PaymentStatus.completed) {
            paid += (p.amount ?? 0).toDouble();
          }
        } catch (_) {}
      }
    }
    final double remaining = total - paid;
    final bool isFullyPaid = remaining <= 0;
    final bool isMissed = _checkIfMissed(booking);

    return !isFullyPaid &&
        !isMissed &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.completed;
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppTheme.success;
      case BookingStatus.pending:
        return AppTheme.warning;
      case BookingStatus.cancelled:
        return AppTheme.error;
      case BookingStatus.completed:
        return AppTheme.info;
      case BookingStatus.checkedIn:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.pending:
        return Icons.hourglass_empty_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.completed:
        return Icons.done_all_rounded;
      case BookingStatus.checkedIn:
        return Icons.login_rounded;
    }
  }

  _BookingPolicyVisual _getBookingPolicyVisual(String type) {
    final lower = type.toLowerCase();
    if (lower == 'cancellation') {
      return _BookingPolicyVisual(
        title: 'سياسة الإلغاء',
        icon: Icons.cancel_outlined,
        color: AppTheme.warning,
      );
    }
    if (lower == 'payment') {
      return _BookingPolicyVisual(
        title: 'سياسة الدفع',
        icon: Icons.payment_outlined,
        color: AppTheme.success,
      );
    }
    if (lower.contains('checkin')) {
      return _BookingPolicyVisual(
        title: 'سياسة تسجيل الدخول',
        icon: Icons.login,
        color: AppTheme.info,
      );
    }
    if (lower.contains('checkout')) {
      return _BookingPolicyVisual(
        title: 'سياسة تسجيل الخروج',
        icon: Icons.logout,
        color: AppTheme.info,
      );
    }
    return _BookingPolicyVisual(
      title: 'سياسة أخرى',
      icon: Icons.policy_outlined,
      color: AppTheme.primaryPurple,
    );
  }

  void _showPolicyDialog({required String title, required String description}) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: AppTheme.overlayDark,
      builder: (ctx) => _buildDialog(
        icon: Icons.policy_rounded,
        iconColor: AppTheme.warning,
        title: title,
        message: description,
        primaryButtonText: 'حسناً',
        primaryButtonColor: AppTheme.warning,
        onPrimaryPressed: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String primaryButtonText,
    required Color primaryButtonColor,
    required VoidCallback onPrimaryPressed,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: iconColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPrimaryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Navigation & Actions
  // ═══════════════════════════════════════════════════════════════
  void _shareBooking() => HapticFeedback.selectionClick();

  void _modifyBooking(dynamic booking) => HapticFeedback.selectionClick();

  void _cancelBooking(dynamic booking) => HapticFeedback.mediumImpact();

  void _writeReview(dynamic booking) {
    HapticFeedback.selectionClick();
    context.push('/review/write', extra: {
      'bookingId': booking.id,
      'propertyId': booking.propertyId,
      'propertyName': booking.propertyName,
    });
  }

  void _openPropertyDetails(dynamic booking) {
    HapticFeedback.selectionClick();
    context.push('/property/${booking.propertyId}');
  }

  void _goToPayment(dynamic booking) {
    HapticFeedback.selectionClick();

    final int nights = booking.numberOfNights;
    double servicesTotal = 0.0;
    for (final s in booking.services) {
      servicesTotal += (s.totalPrice).toDouble();
    }

    double pricePerNight = 0.0;
    if (nights > 0) {
      final totalAmount = (booking.totalAmount).toDouble();
      pricePerNight = (totalAmount - servicesTotal) / nights;
    }

    final selectedServices = booking.services
        .map<Map<String, dynamic>>((s) => {
              'name': s.serviceName,
              'price': s.totalPrice,
            })
        .toList();

    final bookingData = {
      'propertyId': booking.propertyId,
      'propertyName': booking.propertyName,
      'unitId': booking.unitId,
      'unitName': booking.unitName,
      'unitImages': booking.unitImages,
      'currency': booking.currency,
      'checkIn': booking.checkInDate,
      'checkOut': booking.checkOutDate,
      'adultsCount': booking.adultGuests,
      'childrenCount': booking.childGuests,
      'selectedServices': selectedServices,
      'specialRequests': booking.specialRequests ?? '',
      'pricePerNight': pricePerNight,
      'bookingId': booking.id,
    };

    context.push('/booking/payment', extra: bookingData);
  }
}

class _BookingPolicyVisual {
  final String title;
  final IconData icon;
  final Color color;

  const _BookingPolicyVisual({
    required this.title,
    required this.icon,
    required this.color,
  });
}
