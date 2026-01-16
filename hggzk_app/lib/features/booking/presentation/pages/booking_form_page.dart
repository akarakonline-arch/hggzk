import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _specialRequestsController = TextEditingController();
  late AnimationController _controller;

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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _checkInDate = widget.initialCheckIn;
    _checkOutDate = widget.initialCheckOut;
    _adultsCount = (widget.initialAdults ?? 1).clamp(1, 99);
    _childrenCount = widget.initialChildren ?? 0;
    _effectivePropertyServices = widget.propertyServices;
    _initialSelectedServices = widget.initialSelectedServices;

    if (_effectivePropertyServices == null ||
        _effectivePropertyServices!.isEmpty) {
      _maybeLoadPropertyServices();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _specialRequestsController.dispose();
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
          if (state is CheckingAvailability) {
            return _buildLoadingState();
          }

          return _buildFormContent();
        },
      ),
      bottomNavigationBar: _showEditPreview ? _buildEditPreviewBar() : null,
    );
  }

  void _handleBookingState(BuildContext context, BookingState state) {
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
      _showSnackBar(state.message, isError: true);
    } else if (state is BookingUpdated && widget.isEditMode) {
      _showSnackBar('تم تحديث الحجز بنجاح');
      Navigator.of(context).pop(true);
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
      title: FadeTransition(
        opacity: _controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditMode ? 'تعديل الحجز' : 'حجز ${widget.propertyName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!widget.isEditMode)
              Text(
                'الخطوة 1 من 3',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          child: LinearProgressIndicator(
            value: 0.33,
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
          Navigator.pop(context);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // محتوى النموذج
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.unitId != null) ...[
                  _buildUnitPreview(),
                  const SizedBox(height: 20),
                ],
                _buildSectionTitle(
                    'تواريخ الإقامة', Icons.calendar_today_rounded, 1),
                const SizedBox(height: 12),
                _buildDateSelection(),
                const SizedBox(height: 24),
                _buildSectionTitle('عدد الضيوف', Icons.people_rounded, 2),
                const SizedBox(height: 12),
                _buildGuestSelection(),
                const SizedBox(height: 24),
                _buildSectionTitle(
                    'الخدمات الإضافية', Icons.room_service_rounded, 3),
                const SizedBox(height: 12),
                _buildServicesSelection(),
                const SizedBox(height: 24),
                _buildSectionTitle('طلبات خاصة', Icons.note_rounded, 4),
                const SizedBox(height: 12),
                _buildSpecialRequests(),
                const SizedBox(height: 32),
                _buildContinueButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // معاينة الوحدة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildUnitPreview() {
    final images = widget.unitImages ?? const <String>[];
    final hasImages = images.isNotEmpty;
    final displayPrice = _resolvedPricePerNight ?? widget.pricePerNight;
    final displayCurrency = _resolvedCurrency ?? widget.currency ?? 'YER';

    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primaryBlue.withOpacity(0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImages
                ? Image.network(images.first, fit: BoxFit.cover)
                : Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppTheme.textMuted,
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.unitName ?? 'وحدة بدون اسم',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.unitTypeName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.unitTypeName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                if (_buildCapacityText().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _buildCapacityText(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                if (displayPrice != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${displayPrice.toStringAsFixed(0)} $displayCurrency / ليلة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasImages && images.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${images.length}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // عنوان القسم
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, IconData icon, int index) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$index',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 8),
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

  // ═══════════════════════════════════════════════════════════════
  // اختيار التواريخ
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDateSelection() {
    return _buildCard(
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
                if (_checkOutDate != null && _checkOutDate!.isBefore(date)) {
                  _checkOutDate = null;
                }
              });
            },
            icon: Icons.login_rounded,
          ),
          _buildDivider(),
          DatePickerWidget(
            label: 'تاريخ المغادرة',
            selectedDate: _checkOutDate,
            firstDate: _checkInDate?.add(const Duration(days: 1)) ??
                DateTime.now().add(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateSelected: (date) {
              HapticFeedback.selectionClick();
              setState(() => _checkOutDate = date);
            },
            enabled: _checkInDate != null,
            icon: Icons.logout_rounded,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار الضيوف
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGuestSelection() {
    return _buildCard(
      child: Column(
        children: [
          GuestSelectorWidget(
            label: 'البالغين',
            count: _adultsCount,
            minCount: 1,
            maxCount: widget.adultsCapacity ?? 10,
            onChanged: (count) {
              HapticFeedback.selectionClick();
              setState(() => _adultsCount = count);
            },
          ),
          const SizedBox(height: 12),
          GuestSelectorWidget(
            label: 'الأطفال',
            subtitle: '(أقل من 12 سنة)',
            count: _childrenCount,
            minCount: 0,
            maxCount: widget.childrenCapacity ?? 5,
            onChanged: (count) {
              HapticFeedback.selectionClick();
              setState(() => _childrenCount = count);
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار الخدمات
  // ═══════════════════════════════════════════════════════════════
  Widget _buildServicesSelection() {
    return ServicesSelectorWidget(
      key: ValueKey(
        (_effectivePropertyServices?.length ?? 0).toString() +
            (widget.isEditMode ? '-edit' : ''),
      ),
      propertyId: widget.propertyId,
      services: _effectivePropertyServices,
      initialSelected: widget.isEditMode ? _initialSelectedServices : null,
      onServicesChanged: (services) {
        setState(() => _selectedServices = services);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // الطلبات الخاصة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSpecialRequests() {
    return _buildCard(
      child: TextFormField(
        controller: _specialRequestsController,
        maxLines: 3,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'أضف أي طلبات أو ملاحظات خاصة...',
          hintStyle: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted.withOpacity(0.6),
          ),
          filled: false,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // زر المتابعة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildContinueButton() {
    final isValid = _checkInDate != null && _checkOutDate != null;

    return GestureDetector(
      onTap: isValid ? _onContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: isValid ? AppTheme.primaryGradient : null,
          color: isValid ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isValid ? Colors.transparent : AppTheme.darkBorder,
          ),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isEditMode
                  ? Icons.save_rounded
                  : Icons.arrow_forward_rounded,
              color: isValid ? Colors.white : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.isEditMode ? 'حفظ التعديلات' : 'المتابعة إلى الملخص',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isValid ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // شريط معاينة التعديل
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEditPreviewBar() {
    final servicesTotal = _selectedServices.fold<double>(
      0.0,
      (sum, s) => sum + ((s['price'] as num?)?.toDouble() ?? 0.0),
    );
    final nightsAmount = _nightsAmountFromAvailability ?? 0.0;
    final total = nightsAmount + servicesTotal;
    final currency = _resolvedCurrency ?? widget.currency ?? 'YER';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          border: Border(
            top: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceRow('ليالي (${_nightsCountFromAvailability ?? 0})',
                nightsAmount, currency),
            const SizedBox(height: 8),
            _buildPriceRow('الخدمات', servicesTotal, currency),
            const SizedBox(height: 8),
            _buildPriceRow('الإجمالي', total, currency, isBold: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showEditPreview = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.darkBorder),
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmEditSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildPriceRow(String label, double amount, String currency,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isBold ? AppTheme.textWhite : AppTheme.textMuted,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} $currency',
          style: AppTextStyles.bodySmall.copyWith(
            color: isBold ? AppTheme.primaryBlue : AppTheme.textWhite,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // مكونات مساعدة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري التحقق من التوفر...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialogs
  // ═══════════════════════════════════════════════════════════════
  void _showPoliciesDialog() {
    final policies = widget.propertyPolicies ?? const <PropertyPolicy>[];

    if (policies.isEmpty) {
      _navigateToSummary();
      return;
    }

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierColor: AppTheme.overlayDark,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.policy_rounded,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'سياسات وقوانين الحجز',
                  style: AppTextStyles.h3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى مراجعة السياسات قبل تأكيد الحجز.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: PoliciesWidget(policies: policies),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.darkBorder),
                          foregroundColor: AppTheme.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('رجوع'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _navigateToSummary();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('أوافق'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnavailableDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: AppTheme.overlayDark,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'غير متاح',
                  style: AppTextStyles.h3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عذراً، الوحدة غير متاحة في التواريخ المحددة.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════
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

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final maxAdults = widget.adultsCapacity;
    final maxChildren = widget.childrenCapacity;

    if (maxAdults != null && _adultsCount > maxAdults) {
      _showSnackBar('عدد البالغين يتجاوز السعة المتاحة', isError: true);
      return;
    }
    if (maxChildren != null && _childrenCount > maxChildren) {
      _showSnackBar('عدد الأطفال يتجاوز السعة المتاحة', isError: true);
      return;
    }

    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      if (widget.isEditMode && widget.bookingId != null) {
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
      } else if (_existingBookingId != null && _existingBookingId!.isNotEmpty) {
        _navigateToSummary();
      } else {
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

  void _confirmEditSave() {
    if (!(widget.isEditMode && widget.bookingId != null)) return;

    final totalGuests = _adultsCount + _childrenCount;
    final servicesPayload = _selectedServices
        .map((s) => {'serviceId': s['id'], 'quantity': s['quantity']})
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
      either.fold(
        (_) {},
        (detail) {
          setState(() {
            _effectivePropertyServices = detail.services;
          });
        },
      );
    } catch (_) {}
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
