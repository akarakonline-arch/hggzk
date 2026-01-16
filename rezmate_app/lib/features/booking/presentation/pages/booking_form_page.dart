import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/date_picker_widget.dart';
import '../widgets/guest_selector_widget.dart';
import '../widgets/services_selector_widget.dart';
import '../../../property/domain/entities/property_detail.dart';
import '../../../property/domain/entities/property_policy.dart';
import '../../../../injection_container.dart';
import '../../../property/domain/usecases/get_property_details_usecase.dart';
import '../../../property/presentation/widgets/policies_widget.dart';

class BookingFormPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final String? unitId;
  final double? pricePerNight;
  final String? unitName;
  final List<String>? unitImages;
  final String? unitTypeName;
  final int? adultsCapacity;
  final int? childrenCapacity;
  final String? customFeatures;
  final String? currency;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int? initialAdults;
  final int? initialChildren;
  final List<PropertyService>? propertyServices;
  final List<PropertyPolicy>? propertyPolicies;
  final bool isEditMode;
  final String? bookingId;
  final List<Map<String, dynamic>>? initialSelectedServices;

  const BookingFormPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.unitId,
    this.pricePerNight,
    this.unitName,
    this.unitImages,
    this.unitTypeName,
    this.adultsCapacity,
    this.childrenCapacity,
    this.customFeatures,
    this.currency,
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialAdults,
    this.initialChildren,
    this.propertyServices,
    this.propertyPolicies,
    this.isEditMode = false,
    this.bookingId,
    this.initialSelectedServices,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _specialRequestsController = TextEditingController();

  // Animation Controllers - Minimized
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Booking Data
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adultsCount = 1;
  int _childrenCount = 0;
  List<Map<String, dynamic>> _selectedServices = [];
  double? _resolvedPricePerNight;
  String? _resolvedCurrency;
  String? _existingBookingId;
  List<PropertyService>? _effectivePropertyServices;
  List<Map<String, dynamic>>? _initialSelectedServices;
  // Edit preview state
  bool _showEditPreview = false;
  double? _nightsAmountFromAvailability;
  int? _nightsCountFromAvailability;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.initialCheckIn != null) {
      _checkInDate = widget.initialCheckIn;
    }
    if (widget.initialCheckOut != null) {
      _checkOutDate = widget.initialCheckOut;
    }
    _adultsCount = (widget.initialAdults ?? 1);
    if (_adultsCount < 1) _adultsCount = 1;
    _childrenCount = (widget.initialChildren ?? 0);
    _startAnimations();

    // Initialize effective services and initial selected services
    _effectivePropertyServices = widget.propertyServices;
    _initialSelectedServices = widget.initialSelectedServices;

    // If services not provided, fetch property details to obtain services
    if (_effectivePropertyServices == null ||
        _effectivePropertyServices!.isEmpty) {
      _maybeLoadPropertyServices();
    }
  }

  Widget _buildEditPreviewBar() {
    final servicesTotal = _selectedServices.fold<double>(
        0.0, (sum, s) => sum + ((s['price'] as num?)?.toDouble() ?? 0.0));
    final nightsAmount = _nightsAmountFromAvailability ?? 0.0;
    final total = nightsAmount + servicesTotal;
    final currency = _resolvedCurrency ?? widget.currency ?? 'YER';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.9),
          border: Border(
            top: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ليالي (${_nightsCountFromAvailability ?? 0})',
                  style:
                      AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                ),
                Text(
                  '${nightsAmount.toStringAsFixed(0)} $currency',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الخدمات',
                  style:
                      AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                ),
                Text(
                  '${servicesTotal.toStringAsFixed(0)} $currency',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${total.toStringAsFixed(0)} $currency',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.primaryBlue, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showEditPreview = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.darkBorder.withOpacity(0.3)),
                      foregroundColor: AppTheme.textMuted,
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmEditSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تأكيد الحفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmEditSave() {
    if (!(widget.isEditMode && widget.bookingId != null)) return;
    final totalGuests = _adultsCount + _childrenCount;
    final servicesPayload = _selectedServices
        .map((s) => {
              'serviceId': s['id'],
              'quantity': s['quantity'],
            })
        .toList();

    context.read<BookingBloc>().add(
          UpdateBookingEvent(
            bookingId: widget.bookingId!,
            checkIn: _checkInDate!,
            checkOut: _checkOutDate!,
            guestsCount: totalGuests,
            services: servicesPayload,
          ),
        );

    setState(() => _showEditPreview = false);
  }

  void _initializeAnimations() {
    // Slow Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 50),
      vsync: this,
    )..repeat();

    // Form Animation
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildMinimalAppBar(),
        ],
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is AvailabilityChecked) {
              if (state.isAvailable) {
                _resolvedPricePerNight =
                    state.pricePerNight ?? widget.pricePerNight ?? 0.0;
                _resolvedCurrency = state.currency ?? widget.currency ?? 'YER';
                if (widget.isEditMode && widget.bookingId != null) {
                  setState(() {
                    _nightsAmountFromAvailability = state.totalPrice ??
                        (_resolvedPricePerNight ?? 0) * (state.totalDays ?? 0);
                    _nightsCountFromAvailability = state.totalDays;
                    _showEditPreview = true;
                  });
                } else {
                  _showPoliciesDialog();
                }
              } else {
                _showUnavailableDialog();
              }
            } else if (state is BookingError) {
              _showMinimalSnackBar(state.message, isError: true);
            } else if (state is BookingUpdated && widget.isEditMode) {
              _showMinimalSnackBar('تم تحديث الحجز بنجاح');
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            if (state is CheckingAvailability) {
              return Center(
                child: _buildMinimalLoader(),
              );
            }

            return Stack(
              children: [
                // Subtle animated background
                _buildSubtleBackground(),

                // Main Content
                SafeArea(
                  child: _buildForm(),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _showEditPreview ? _buildEditPreviewBar() : null,
    );
  }

  void _showPoliciesDialog() {
    final policies = widget.propertyPolicies ?? const <PropertyPolicy>[];

    // إذا لم توجد سياسات، انتقل مباشرة للملخص
    if (policies.isEmpty) {
      _navigateToSummary();
      return;
    }

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.97),
                    AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.25),
                          AppTheme.primaryPurple.withOpacity(0.15),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.policy_rounded,
                      color: AppTheme.primaryBlue.withOpacity(0.95),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'سياسات وقوانين الحجز',
                    style: AppTextStyles.h3.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قبل تأكيد الحجز، يرجى مراجعة سياسات الإلغاء، الدفع وقوانين المكان الخاصة بهذا العقار.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(dialogContext).size.height * 0.55,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: PoliciesWidget(policies: policies),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.darkBorder.withOpacity(0.6),
                              width: 0.8,
                            ),
                            foregroundColor: AppTheme.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'رجوع',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(dialogContext).pop();
                            _navigateToSummary();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'أوافق وأتابع',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildCapacityText() {
    final parts = <String>[];
    if (widget.adultsCapacity != null && widget.adultsCapacity! > 0) {
      parts.add('${widget.adultsCapacity} بالغ');
    }
    if (widget.childrenCapacity != null && widget.childrenCapacity! > 0) {
      parts.add('${widget.childrenCapacity} طفل');
    }
    return parts.isEmpty ? '' : parts.join('، ');
  }

  Widget _buildUnitPreview() {
    final images = widget.unitImages ?? const <String>[];
    final hasImages = images.isNotEmpty;
    final double? displayPrice = _resolvedPricePerNight ?? widget.pricePerNight;
    final String displayCurrency =
        _resolvedCurrency ?? widget.currency ?? 'YER';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.16),
            AppTheme.darkCard.withOpacity(0.82),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.16),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppTheme.darkBackground.withOpacity(0.3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImages
                      ? Image.network(images.first, fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppTheme.textMuted,
                            size: 24,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unitName ?? 'وحدة بدون اسم',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (widget.unitTypeName != null &&
                          widget.unitTypeName!.isNotEmpty)
                        Text(
                          widget.unitTypeName!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if ((widget.adultsCapacity != null &&
                              widget.adultsCapacity! > 0) ||
                          (widget.childrenCapacity != null &&
                              widget.childrenCapacity! > 0))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _buildCapacityText(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (displayPrice != null)
                        Text(
                          '${displayPrice.toStringAsFixed(0)} $displayCurrency / ليلة',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasImages && images.length > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${images.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildMinimalAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: _buildMinimalBackButton(),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentHeight = constraints.maxHeight;
          final double progress =
              ((currentHeight - kToolbarHeight) / (180.0 - kToolbarHeight))
                  .clamp(0.0, 1.0);
          final double mediaTop = MediaQuery.of(context).padding.top;
          final double topPadding = mediaTop + 4 + (8 * progress);
          final double bottomPadding = 4 + (8 * progress);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.7),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.35),
                        AppTheme.darkCard.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),
              // Blur effect
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 8,
                      sigmaY: 8,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.01),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: topPadding,
                  left: 16,
                  right: 16,
                  bottom: bottomPadding,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.95),
                              AppTheme.primaryPurple.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 3,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إعداد الحجز',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted
                                      .withOpacity(0.8 + (0.1 * progress)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.propertyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h3.copyWith(
                                  color: AppTheme.textWhite
                                      .withOpacity(0.95 + (0.05 * progress)),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (!widget.isEditMode)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color: AppTheme.darkCard.withOpacity(
                                            0.6 - (0.2 * progress)),
                                        border: Border.all(
                                          color: AppTheme.darkBorder
                                              .withOpacity(0.4),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Text(
                                        'الخطوة 1 من 3',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textLight
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          child: LinearProgressIndicator(
            value: 0.33,
            backgroundColor: AppTheme.darkBorder.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              color: AppTheme.darkCard.withOpacity(0.5),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 4,
                sigmaY: 4,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.01),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SubtlePatternPainter(
              rotation: _backgroundAnimationController.value * 2 * math.pi,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: AnimatedBuilder(
          animation: _formAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.unitId != null) ...[
                      _buildUnitPreview(),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('تواريخ الإقامة', 0),
                    const SizedBox(height: 10),
                    _buildCompactDateSelection(),
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('عدد الضيوف', 1),
                    const SizedBox(height: 10),
                    _buildCompactGuestSelection(),
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('الخدمات الإضافية', 2),
                    const SizedBox(height: 10),
                    _buildServicesSelection(),
                    const SizedBox(height: 16),
                    _buildCompactSectionTitle('طلبات خاصة (اختياري)', 3),
                    const SizedBox(height: 10),
                    _buildCompactSpecialRequests(),
                    const SizedBox(height: 20),
                    _buildCompactContinueButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactSectionTitle(String title, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * -20, 0),
          child: Opacity(
            opacity: value,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryBlue.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDateSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.14),
            AppTheme.darkCard.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Column(
            children: [
              DatePickerWidget(
                label: 'تاريخ الوصول',
                selectedDate: _checkInDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _checkInDate = date;
                    if (_checkOutDate != null &&
                        _checkOutDate!.isBefore(date)) {
                      _checkOutDate = null;
                    }
                  });
                },
                icon: Icons.calendar_today_rounded,
              ),
              Container(
                height: 0.5,
                color: AppTheme.darkBorder.withOpacity(0.1),
              ),
              DatePickerWidget(
                label: 'تاريخ المغادرة',
                selectedDate: _checkOutDate,
                firstDate: _checkInDate?.add(const Duration(days: 1)) ??
                    DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _checkOutDate = date;
                  });
                },
                enabled: _checkInDate != null,
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGuestSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.14),
            AppTheme.darkCard.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              GuestSelectorWidget(
                label: 'البالغين',
                count: _adultsCount,
                minCount: 1,
                maxCount: (widget.adultsCapacity != null &&
                        widget.adultsCapacity! > 0)
                    ? widget.adultsCapacity!
                    : 10,
                onChanged: (count) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _adultsCount = count;
                  });
                },
              ),
              const SizedBox(height: 10),
              GuestSelectorWidget(
                label: 'الأطفال',
                subtitle: '(أقل من 12 سنة)',
                count: _childrenCount,
                minCount: 0,
                maxCount: (widget.childrenCapacity != null &&
                        widget.childrenCapacity! > 0)
                    ? widget.childrenCapacity!
                    : 5,
                onChanged: (count) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _childrenCount = count;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSelection() {
    return ServicesSelectorWidget(
      key: ValueKey((_effectivePropertyServices?.length ?? 0).toString() +
          (widget.isEditMode ? '-edit' : '')),
      propertyId: widget.propertyId,
      services: _effectivePropertyServices,
      initialSelected: widget.isEditMode ? _initialSelectedServices : null,
      onServicesChanged: (services) {
        setState(() {
          _selectedServices = services;
        });
      },
    );
  }

  Widget _buildCompactSpecialRequests() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryCyan.withOpacity(0.12),
            AppTheme.darkCard.withOpacity(0.82),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: _specialRequestsController,
            maxLines: 3,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite.withOpacity(0.9),
            ),
            decoration: InputDecoration(
              hintText: 'أضف أي طلبات أو ملاحظات خاصة...',
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContinueButton() {
    final isValid = _checkInDate != null && _checkOutDate != null;

    return GestureDetector(
      onTapDown: isValid ? (_) => HapticFeedback.selectionClick() : null,
      onTap: isValid ? _onContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.7),
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppTheme.darkBorder.withOpacity(0.3),
                    AppTheme.darkBorder.withOpacity(0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isValid ? _onContinue : null,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEditMode
                          ? Icons.save_rounded
                          : Icons.arrow_forward_rounded,
                      color: isValid
                          ? Colors.white
                          : AppTheme.textMuted.withOpacity(0.5),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEditMode
                          ? 'حفظ التعديلات'
                          : 'المتابعة إلى الملخص',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isValid
                            ? Colors.white
                            : AppTheme.textMuted.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.darkCard.withOpacity(0.5),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جاري التحقق من التوفر...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final maxAdults = widget.adultsCapacity;
      final maxChildren = widget.childrenCapacity;
      if (maxAdults != null && _adultsCount > maxAdults) {
        _showMinimalSnackBar('عدد البالغين يتجاوز السعة المتاحة لهذه الوحدة',
            isError: true);
        return;
      }
      if (maxChildren != null && _childrenCount > maxChildren) {
        _showMinimalSnackBar('عدد الأطفال يتجاوز السعة المتاحة لهذه الوحدة',
            isError: true);
        return;
      }

      final totalGuests = _adultsCount + _childrenCount;

      if (widget.isEditMode && widget.bookingId != null) {
        if (context.read<AuthBloc>().state is AuthAuthenticated) {
          // تحقق التوفر أولاً في وضع التعديل واستثناء نفس الحجز
          context.read<BookingBloc>().add(
                CheckAvailabilityEvent(
                  unitId: widget.unitId ?? '',
                  checkIn: _checkInDate!,
                  checkOut: _checkOutDate!,
                  adultsCount: _adultsCount,
                  childrenCount: _childrenCount,
                  excludeBookingId: widget.bookingId,
                ),
              );
        }
      } else {
        if (context.read<AuthBloc>().state is AuthAuthenticated) {
          // إذا كان لدينا حجز مسجل مسبقاً (Draft/Pending) فلنتجاوز فحص التوفر
          if (_existingBookingId != null && _existingBookingId!.isNotEmpty) {
            final formData = {
              'propertyId': widget.propertyId,
              'propertyName': widget.propertyName,
              'unitId': widget.unitId,
              'unitName': widget.unitName,
              'unitTypeName': widget.unitTypeName,
              'unitImages': widget.unitImages,
              'adultsCapacity': widget.adultsCapacity,
              'childrenCapacity': widget.childrenCapacity,
              'customFeatures': widget.customFeatures,
              'currency': _resolvedCurrency ?? widget.currency ?? 'YER',
              'checkIn': _checkInDate,
              'checkOut': _checkOutDate,
              'adultsCount': _adultsCount,
              'childrenCount': _childrenCount,
              'selectedServices': _selectedServices,
              'specialRequests': _specialRequestsController.text,
              'pricePerNight':
                  _resolvedPricePerNight ?? widget.pricePerNight ?? 0.0,
              'bookingId': _existingBookingId,
            };
            context.push('/booking/summary', extra: formData);
          } else {
            // Check availability first with separate adults and children counts
            context.read<BookingBloc>().add(
                  CheckAvailabilityEvent(
                    unitId: widget.unitId ?? '',
                    checkIn: _checkInDate!,
                    checkOut: _checkOutDate!,
                    adultsCount: _adultsCount,
                    childrenCount: _childrenCount,
                    excludeBookingId: _existingBookingId,
                  ),
                );
          }
        }
      }
    }
  }

  Future<void> _maybeLoadPropertyServices() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final usecase = sl<GetPropertyDetailsUseCase>();
      final params = GetPropertyDetailsParams(
        propertyId: widget.propertyId,
        userId: authState is AuthAuthenticated ? authState.user.userId : null,
        userRole: null,
      );
      final either = await usecase(params);
      either.fold((failure) {
        // ignore, keep services empty
      }, (detail) {
        setState(() {
          _effectivePropertyServices = detail.services;
        });
      });
    } catch (_) {}
  }

  Future<void> _navigateToSummary() async {
    final formData = {
      'propertyId': widget.propertyId,
      'propertyName': widget.propertyName,
      'unitId': widget.unitId,
      'unitName': widget.unitName,
      'unitTypeName': widget.unitTypeName,
      'unitImages': widget.unitImages,
      'adultsCapacity': widget.adultsCapacity,
      'childrenCapacity': widget.childrenCapacity,
      'customFeatures': widget.customFeatures,
      'currency': _resolvedCurrency ?? widget.currency ?? 'YER',
      'checkIn': _checkInDate,
      'checkOut': _checkOutDate,
      'adultsCount': _adultsCount,
      'childrenCount': _childrenCount,
      'selectedServices': _selectedServices,
      'specialRequests': _specialRequestsController.text,
      'pricePerNight': _resolvedPricePerNight ?? widget.pricePerNight ?? 0.0,
    };

    final result = await context.push('/booking/summary', extra: formData);
    if (result is Map && result['bookingId'] != null) {
      setState(() {
        _existingBookingId = result['bookingId'].toString();
      });
    }
  }

  void _showUnavailableDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => _buildMinimalDialog(
        title: 'غير متاح',
        content:
            'عذراً، الوحدة غير متاحة في التواريخ المحددة. يرجى اختيار تواريخ أخرى.',
        icon: Icons.event_busy_rounded,
        iconColor: AppTheme.error.withOpacity(0.8),
        actions: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'حسناً',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required List<Widget> actions,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.2),
                      iconColor.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMinimalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.error : AppTheme.success)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isError
                      ? AppTheme.error.withOpacity(0.8)
                      : AppTheme.success.withOpacity(0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard.withOpacity(0.9),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Subtle Pattern Painter
class _SubtlePatternPainter extends CustomPainter {
  final double rotation;

  _SubtlePatternPainter({
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw subtle rotating squares
    for (int i = 0; i < 2; i++) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.02);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + (i * math.pi / 4));

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 150 + i * 100,
        height: 150 + i * 100,
      );

      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
