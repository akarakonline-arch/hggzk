import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hggzk/features/booking/presentation/widgets/policies_dialog.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/price_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/booking_request.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/price_breakdown_widget.dart';

class BookingSummaryPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingSummaryPage({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Calculated values
  late int nights;
  late double pricePerNight;
  late double totalPrice;
  late double servicesTotal;
  late double grandTotal;
  late String currency;

  @override
  void initState() {
    super.initState();
    _calculatePrices();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  void _calculatePrices() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    nights = checkOut.difference(checkIn).inDays;
    pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    currency = (widget.bookingData['currency'] as String?) ?? 'YER';
    totalPrice = nights * pricePerNight;

    final services =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );

    grandTotal = totalPrice + servicesTotal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: _handleBookingState,
        builder: (context, state) {
          if (state is BookingLoading) {
            return const LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري إنشاء الحجز...',
            );
          }

          return _buildContent();
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _handleBookingState(BuildContext context, BookingState state) {
    if (state is BookingCreated) {
      final booking = state.booking;
      final bookingData = Map<String, dynamic>.from(widget.bookingData);
      bookingData['bookingId'] = booking.id;

      context.push('/booking/payment', extra: bookingData).then((result) {
        if (result is Map && result['bookingId'] != null) {
          setState(() {
            widget.bookingData['bookingId'] = result['bookingId'].toString();
          });
        } else {
          setState(() {
            widget.bookingData['bookingId'] = booking.id;
          });
        }
      });
    } else if (state is BookingError) {
      _showSnackBar(state.message, isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkCard.withOpacity(0.5),
      elevation: 0,
      leading: _buildBackButton(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: AppTextStyles.h3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'الخطوة 2 من 3',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          child: LinearProgressIndicator(
            value: 0.66,
            backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: AppTheme.textWhite,
        onPressed: () {
          HapticFeedback.selectionClick();
          final bookingId = widget.bookingData['bookingId'];
          Navigator.pop(
            context,
            bookingId != null && bookingId.toString().isNotEmpty
                ? {'bookingId': bookingId}
                : null,
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // المحتوى الرئيسي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                _buildPropertyCard(),
                const SizedBox(height: 16),
                _buildBookingDetailsCard(),
                const SizedBox(height: 16),
                _buildGuestDetailsCard(),
                const SizedBox(height: 16),
                if ((widget.bookingData['selectedServices'] as List)
                    .isNotEmpty) ...[
                  _buildServicesCard(),
                  const SizedBox(height: 16),
                ],
                if (widget.bookingData['specialRequests']?.isNotEmpty ??
                    false) ...[
                  _buildSpecialRequestsCard(),
                  const SizedBox(height: 16),
                ],
                _buildPriceBreakdown(),
                const SizedBox(height: 16),
                _buildPoliciesCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة العقار
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPropertyCard() {
    final unitImages = (widget.bookingData['unitImages'] as List?)
        ?.map((e) => e.toString())
        .toList();
    final hasImages = unitImages != null && unitImages.isNotEmpty;

    return _buildCard(
      child: Row(
        children: [
          // صورة العقار
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImages
                ? Image.network(unitImages.first, fit: BoxFit.cover)
                : Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // معلومات العقار
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookingData['unitName'] ??
                      widget.bookingData['propertyName'],
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.bookingData['unitTypeName'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.bookingData['unitTypeName'],
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                if (_buildCapacityText().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _buildCapacityText(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pricePerNight.toStringAsFixed(0)} $currency / ليلة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
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
  // بطاقة تفاصيل الحجز
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBookingDetailsCard() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.calendar_month_rounded,
            title: 'تفاصيل الإقامة',
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.login_rounded,
            label: 'تاريخ الوصول',
            value: dateFormat.format(checkIn),
            color: AppTheme.primaryBlue,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.logout_rounded,
            label: 'تاريخ المغادرة',
            value: dateFormat.format(checkOut),
            color: AppTheme.primaryPurple,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.nights_stay_rounded,
            label: 'عدد الليالي',
            value: '$nights ${nights == 1 ? 'ليلة' : 'ليالي'}',
            color: AppTheme.primaryCyan,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة تفاصيل الضيوف
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGuestDetailsCard() {
    final adultsCount = widget.bookingData['adultsCount'] as int;
    final childrenCount = widget.bookingData['childrenCount'] as int;
    final totalGuests = adultsCount + childrenCount;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.people_rounded,
            title: 'معلومات الضيوف',
            color: AppTheme.success,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGuestBadge(
                icon: Icons.person_rounded,
                label: 'بالغين',
                count: adultsCount,
                color: AppTheme.success,
              ),
              const SizedBox(width: 12),
              if (childrenCount > 0)
                _buildGuestBadge(
                  icon: Icons.child_care_rounded,
                  label: 'أطفال',
                  count: childrenCount,
                  color: AppTheme.info,
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalGuests ضيف',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBadge({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة الخدمات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildServicesCard() {
    final services =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;

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
          ...services.map((service) => _buildServiceItem(service)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              service['name'],
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${service['price']} $currency',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryViolet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة الطلبات الخاصة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSpecialRequestsCard() {
    return _buildCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.info.withOpacity(0.08),
          AppTheme.info.withOpacity(0.03),
        ],
      ),
      borderColor: AppTheme.info.withOpacity(0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_alt_outlined,
              color: AppTheme.info,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبات خاصة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bookingData['specialRequests'],
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
  // تفصيل السعر
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPriceBreakdown() {
    return PriceBreakdownWidget(
      nights: nights,
      pricePerNight: pricePerNight,
      servicesTotal: servicesTotal,
      taxRate: 0.0,
      currency: currency,
      services: (widget.bookingData['selectedServices'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // بطاقة السياسات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPoliciesCard() {
    final propertyId = widget.bookingData['propertyId'] as String?;
    final propertyName = widget.bookingData['propertyName'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        PoliciesDialog.show(
          context,
          propertyId: propertyId,
          propertyName: propertyName,
        );
      },
      child: _buildCard(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.08),
            AppTheme.primaryPurple.withOpacity(0.04),
          ],
        ),
        borderColor: AppTheme.primaryBlue.withOpacity(0.2),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.policy_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سياسات وقوانين الحجز',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بتأكيدك للحجز، فإنك توافق على جميع السياسات',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'عرض السياسات',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // الشريط السفلي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          top: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // السعر الإجمالي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المجموع الكلي',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$nights ليالي + الخدمات',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                    child: Text(
                      '${grandTotal.toStringAsFixed(0)} $currency',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // زر المتابعة
              GestureDetector(
                onTap: _navigateToPayment,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'المتابعة إلى الدفع',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  String _buildCapacityText() {
    final adultsCapacity = widget.bookingData['adultsCapacity'] as int?;
    final childrenCapacity = widget.bookingData['childrenCapacity'] as int?;

    final parts = <String>[];
    if (adultsCapacity != null && adultsCapacity > 0) {
      parts.add('$adultsCapacity بالغ');
    }
    if (childrenCapacity != null && childrenCapacity > 0) {
      parts.add('$childrenCapacity طفل');
    }
    return parts.isEmpty ? '' : parts.join('، ');
  }

  // ═══════════════════════════════════════════════════════════════
  // التنقل والإجراءات
  // ═══════════════════════════════════════════════════════════════
  void _navigateToPayment() {
    HapticFeedback.mediumImpact();
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }

    // إذا كان لدينا bookingId مسبقاً
    final existingBookingId = widget.bookingData['bookingId'] as String?;
    if (existingBookingId != null && existingBookingId.isNotEmpty) {
      context.push('/booking/payment', extra: widget.bookingData);
      return;
    }

    final userId = authState.user.userId;
    final unitId = (widget.bookingData['unitId'] as String?) ?? '';
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final adultsCount = widget.bookingData['adultsCount'] as int;
    final childrenCount = widget.bookingData['childrenCount'] as int;
    final guestsCount = adultsCount + childrenCount;

    final selectedServices =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;

    final services = selectedServices
        .map(
          (service) => BookingServiceRequest(
            serviceId: service['id'] as String,
            quantity: (service['quantity'] as int?) ?? 1,
          ),
        )
        .toList();

    final bookingRequest = BookingRequest(
      userId: userId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      guestsCount: guestsCount,
      services: services,
      specialRequests: widget.bookingData['specialRequests'] as String?,
    );

    context.read<BookingBloc>().add(
          CreateBookingEvent(bookingRequest: bookingRequest),
        );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
