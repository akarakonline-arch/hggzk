// lib/features/admin_policies/presentation/pages/create_policy_page.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/local_storage_service.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../domain/entities/policy.dart';
import '../bloc/policies_bloc.dart';
import '../bloc/policies_event.dart';
import '../bloc/policies_state.dart';

class CreatePolicyPage extends StatefulWidget {
  final String? initialPropertyId;
  const CreatePolicyPage({super.key, this.initialPropertyId});

  @override
  State<CreatePolicyPage> createState() => _CreatePolicyPageState();
}

class _CreatePolicyPageState extends State<CreatePolicyPage>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _cancellationWindowController = TextEditingController(text: '0');
  final _depositPercentageController = TextEditingController(text: '0');
  final _minHoursController = TextEditingController(text: '0');
  final _cancellationRefundPercentageController = TextEditingController();
  final _cancellationDaysBeforeCheckInController = TextEditingController();
  final _cancellationHoursBeforeCheckInController = TextEditingController();
  final _cancellationPenaltyAfterDeadlineController = TextEditingController();

  final _paymentDepositPercentageController = TextEditingController();
  final _paymentAcceptedMethodsController = TextEditingController();

  final _checkInTimeController = TextEditingController();
  final _checkOutTimeController = TextEditingController();
  final _checkInFromController = TextEditingController();
  final _checkInUntilController = TextEditingController();
  final _checkInEarlyCheckInNoteController = TextEditingController();
  final _checkInLateCheckOutNoteController = TextEditingController();
  final _checkInLateCheckOutFeeController = TextEditingController();

  final _childrenFreeUnderAgeController = TextEditingController();
  final _childrenHalfPriceUnderAgeController = TextEditingController();
  final _childrenMaxChildrenPerRoomController = TextEditingController();
  final _childrenMaxChildrenController = TextEditingController();
  final _childrenCribsNoteController = TextEditingController();

  final _petsReasonController = TextEditingController();
  final _petsFeeAmountController = TextEditingController();
  final _petsMaxWeightController = TextEditingController();

  final _modificationFreeModificationHoursController = TextEditingController();
  final _modificationFeesAfterController = TextEditingController();
  final _modificationReasonController = TextEditingController();
  final _storage = GetIt.I<LocalStorageService>();

  // State
  PolicyType _selectedType = PolicyType.cancellation;
  bool _requireFullPayment = false;
  bool? _cancellationFreeCancel;
  bool? _cancellationFullRefund;
  bool? _cancellationNonRefundable;

  bool? _paymentDepositRequired;
  bool? _paymentFullPaymentRequired;
  bool? _paymentAcceptCash;
  bool? _paymentAcceptCard;
  bool? _paymentPayAtProperty;
  bool? _paymentCashPreferred;

  bool? _checkInFlexible;
  bool? _checkInFlexibleCheckIn;
  bool? _checkInRequiresCoordination;
  bool? _checkInContactOwner;

  bool? _childrenAllowed;
  bool? _childrenPlaygroundAvailable;
  bool? _childrenKidsMenuAvailable;

  bool? _petsAllowed;
  bool? _petsRequiresApproval;
  bool? _petsNoFees;
  bool? _petsPetFriendly;
  bool? _petsOutdoorSpace;
  bool? _petsStrict;

  bool? _modificationAllowed;
  bool? _modificationFlexible;
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  bool _isAdmin = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserRole();
    _selectedPropertyId = widget.initialPropertyId;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _checkUserRole() {
    final role = _storage.getAccountRole();
    setState(() {
      _isAdmin = role.toLowerCase() == 'admin';
      if (!_isAdmin) {
        _selectedPropertyId = _storage.getPropertyId();
        _selectedPropertyName = _storage.getPropertyName();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _descriptionController.dispose();
    _cancellationWindowController.dispose();
    _depositPercentageController.dispose();
    _minHoursController.dispose();
    _cancellationRefundPercentageController.dispose();
    _cancellationDaysBeforeCheckInController.dispose();
    _cancellationHoursBeforeCheckInController.dispose();
    _cancellationPenaltyAfterDeadlineController.dispose();

    _paymentDepositPercentageController.dispose();
    _paymentAcceptedMethodsController.dispose();

    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    _checkInFromController.dispose();
    _checkInUntilController.dispose();
    _checkInEarlyCheckInNoteController.dispose();
    _checkInLateCheckOutNoteController.dispose();
    _checkInLateCheckOutFeeController.dispose();

    _childrenFreeUnderAgeController.dispose();
    _childrenHalfPriceUnderAgeController.dispose();
    _childrenMaxChildrenPerRoomController.dispose();
    _childrenMaxChildrenController.dispose();
    _childrenCribsNoteController.dispose();

    _petsReasonController.dispose();
    _petsFeeAmountController.dispose();
    _petsMaxWeightController.dispose();

    _modificationFreeModificationHoursController.dispose();
    _modificationFeesAfterController.dispose();
    _modificationReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoliciesBloc, PoliciesState>(
      listener: (context, state) {
        if (state is PolicyOperationSuccess) {
          _showSuccessMessage('تم إنشاء السياسة بنجاح');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop({
                'refresh': true,
                'propertyId': _selectedPropertyId,
              });
            }
          });
        } else if (state is PolicyOperationFailure) {
          _showErrorMessage(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Progress Indicator
                  _buildProgressIndicator(),

                  // Form Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildFormContent(),
                      ),
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _CreatePolicyBackgroundPainter(
              glowIntensity: _glowController.value,
              policyType: _selectedType,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withOpacity(0.5),
                    AppTheme.darkSurface.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _getPolicyTypeColor(_selectedType),
                      _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'إضافة سياسة جديدة',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة السياسة',
                  style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildProgressIndicator() {
    final steps = ['المعلومات الأساسية', 'الإعدادات', 'المراجعة'];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              _getPolicyTypeColor(_selectedType),
                              _getPolicyTypeColor(_selectedType)
                                  .withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: !isActive
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? _getPolicyTypeColor(_selectedType).withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _getPolicyTypeColor(_selectedType)
                                  .withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isActive ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  _getPolicyTypeColor(_selectedType),
                                  _getPolicyTypeColor(_selectedType)
                                      .withOpacity(0.5),
                                ],
                              )
                            : null,
                        color: !isCompleted
                            ? AppTheme.darkBorder.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: IndexedStack(
        index: _currentStep,
        children: [
          _buildBasicInfoStep(),
          _buildSettingsStep(),
          _buildReviewStep(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Policy Type Selector
          _buildTypeSelector(),

          const SizedBox(height: 20),

          // Property Selector
          _buildPropertySelector(),

          const SizedBox(height: 20),

          // Description
          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف السياسة',
            icon: Icons.description_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الوصف';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPolicyTypeColor(_selectedType).withOpacity(0.1),
                  _getPolicyTypeColor(_selectedType).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getPolicyTypeColor(_selectedType),
                        _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getPolicyIcon(_selectedType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات ${_selectedType.displayName}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'قم بتكوين الإعدادات الخاصة بالسياسة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Type-specific fields
          _buildTypeSpecificFields(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة البيانات',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildReviewCard(
            title: 'المعلومات الأساسية',
            color: _getPolicyTypeColor(_selectedType),
            items: [
              {'label': 'النوع', 'value': _selectedType.displayName},
              {'label': 'العقار', 'value': _selectedPropertyName ?? 'غير محدد'},
              {'label': 'الوصف', 'value': _descriptionController.text},
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'الإعدادات الخاصة',
            color: _getPolicyTypeColor(_selectedType),
            items: _getTypeSpecificReviewItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع السياسة',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PolicyType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              _getPolicyTypeColor(type),
                              _getPolicyTypeColor(type).withOpacity(0.7),
                            ],
                          )
                        : null,
                    color:
                        isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getPolicyTypeColor(type).withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _getPolicyTypeColor(type).withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPolicyIcon(type),
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
    // للـ Admin: اختيار العقار
    if (_isAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'العقار',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              context.push(
                '/helpers/search/properties',
                extra: {
                  'allowMultiSelect': false,
                  'onPropertySelected': (Property property) {
                    setState(() {
                      _selectedPropertyId = property.id;
                      _selectedPropertyName = property.name;
                    });
                  },
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPropertyId != null
                      ? _getPolicyTypeColor(_selectedType).withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    color: _selectedPropertyId != null
                        ? _getPolicyTypeColor(_selectedType)
                        : AppTheme.textMuted.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPropertyName ?? 'اختر العقار',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedPropertyName == null
                            ? AppTheme.textMuted.withOpacity(0.5)
                            : AppTheme.textWhite,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // للـ Owner/Staff: إخفاء حقل اختيار/عرض العقار تماماً
    return const SizedBox.shrink();
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case PolicyType.cancellation:
        return Column(
          children: [
            _buildInputField(
              controller: _cancellationWindowController,
              label: 'نافذة الإلغاء (بالأيام)',
              hint: 'عدد الأيام المسموح فيها بالإلغاء',
              icon: Icons.event_busy_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'إلغاء مجاني',
              value: _cancellationFreeCancel ?? false,
              onChanged: (v) => setState(() => _cancellationFreeCancel = v),
            ),
            _buildBooleanTile(
              title: 'استرداد كامل',
              value: _cancellationFullRefund ?? false,
              onChanged: (v) => setState(() => _cancellationFullRefund = v),
            ),
            _buildBooleanTile(
              title: 'غير قابل للاسترداد',
              value: _cancellationNonRefundable ?? false,
              onChanged: (v) => setState(() => _cancellationNonRefundable = v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cancellationRefundPercentageController,
              label: 'نسبة الاسترداد (%)',
              hint: 'مثال: 50',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cancellationDaysBeforeCheckInController,
              label: 'عدد الأيام قبل تسجيل الوصول',
              hint: 'مثال: 2',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cancellationHoursBeforeCheckInController,
              label: 'عدد الساعات قبل تسجيل الوصول',
              hint: 'مثال: 24',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cancellationPenaltyAfterDeadlineController,
              label: 'غرامة بعد الموعد النهائي',
              hint: 'مثال: 10%',
              icon: Icons.money_off_rounded,
              maxLines: 2,
            ),
          ],
        );

      case PolicyType.payment:
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _requireFullPayment
                      ? AppTheme.success.withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _requireFullPayment
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        size: 16,
                        color: _requireFullPayment
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يتطلب الدفع الكامل',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'يجب دفع المبلغ كاملاً قبل التأكيد',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                value: _requireFullPayment,
                onChanged: (value) {
                  setState(() {
                    _requireFullPayment = value;
                  });
                },
                activeThumbColor: AppTheme.success,
                activeTrackColor: AppTheme.success.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _depositPercentageController,
              label: 'نسبة الدفعة المقدمة (%)',
              hint: 'النسبة المئوية المطلوبة (0-100)',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'يتطلب دفعة مقدمة',
              value: _paymentDepositRequired ?? false,
              onChanged: (v) => setState(() => _paymentDepositRequired = v),
            ),
            _buildBooleanTile(
              title: 'يتطلب دفع كامل (ضمن سياسة الدفع)',
              value: _paymentFullPaymentRequired ?? false,
              onChanged: (v) => setState(() => _paymentFullPaymentRequired = v),
            ),
            _buildBooleanTile(
              title: 'قبول نقداً',
              value: _paymentAcceptCash ?? false,
              onChanged: (v) => setState(() => _paymentAcceptCash = v),
            ),
            _buildBooleanTile(
              title: 'قبول بطاقة',
              value: _paymentAcceptCard ?? false,
              onChanged: (v) => setState(() => _paymentAcceptCard = v),
            ),
            _buildBooleanTile(
              title: 'الدفع عند العقار',
              value: _paymentPayAtProperty ?? false,
              onChanged: (v) => setState(() => _paymentPayAtProperty = v),
            ),
            _buildBooleanTile(
              title: 'النقد مفضّل',
              value: _paymentCashPreferred ?? false,
              onChanged: (v) => setState(() => _paymentCashPreferred = v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _paymentDepositPercentageController,
              label: 'نسبة الدفعة (ضمن سياسة الدفع) (%)',
              hint: 'مثال: 30',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _paymentAcceptedMethodsController,
              label: 'طرق الدفع المقبولة (افصل بـ , )',
              hint: 'Cash, Card, BankTransfer',
              icon: Icons.list_alt_rounded,
              maxLines: 2,
            ),
          ],
        );

      case PolicyType.checkIn:
        return Column(
          children: [
            _buildInputField(
              controller: _minHoursController,
              label: 'الحد الأدنى للساعات قبل تسجيل الوصول',
              hint: 'عدد الساعات المطلوبة',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInTimeController,
              label: 'وقت تسجيل الدخول',
              hint: '14:00',
              icon: Icons.login_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkOutTimeController,
              label: 'وقت تسجيل الخروج',
              hint: '12:00',
              icon: Icons.logout_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInFromController,
              label: 'تسجيل الدخول من',
              hint: 'مثال: 12:00',
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInUntilController,
              label: 'تسجيل الدخول حتى',
              hint: 'مثال: 22:00',
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'تسجيل دخول مرن',
              value: _checkInFlexible ?? false,
              onChanged: (v) => setState(() => _checkInFlexible = v),
            ),
            _buildBooleanTile(
              title: 'تسجيل دخول مرن (تفصيلي)',
              value: _checkInFlexibleCheckIn ?? false,
              onChanged: (v) => setState(() => _checkInFlexibleCheckIn = v),
            ),
            _buildBooleanTile(
              title: 'يتطلب تنسيق',
              value: _checkInRequiresCoordination ?? false,
              onChanged: (v) => setState(() => _checkInRequiresCoordination = v),
            ),
            _buildBooleanTile(
              title: 'التواصل مع المالك',
              value: _checkInContactOwner ?? false,
              onChanged: (v) => setState(() => _checkInContactOwner = v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInEarlyCheckInNoteController,
              label: 'ملاحظة تسجيل دخول مبكر',
              hint: 'اكتب أي ملاحظة',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInLateCheckOutNoteController,
              label: 'ملاحظة تسجيل خروج متأخر',
              hint: 'اكتب أي ملاحظة',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _checkInLateCheckOutFeeController,
              label: 'رسوم تسجيل خروج متأخر',
              hint: 'مثال: 10',
              icon: Icons.attach_money_rounded,
            ),
          ],
        );

      case PolicyType.children:
        return Column(
          children: [
            _buildBooleanTile(
              title: 'الأطفال مسموح',
              value: _childrenAllowed ?? false,
              onChanged: (v) => setState(() => _childrenAllowed = v),
            ),
            _buildInputField(
              controller: _childrenFreeUnderAgeController,
              label: 'مجاني تحت عمر',
              hint: 'مثال: 6',
              icon: Icons.child_friendly_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _childrenHalfPriceUnderAgeController,
              label: 'نصف السعر تحت عمر',
              hint: 'مثال: 12',
              icon: Icons.child_friendly_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _childrenMaxChildrenPerRoomController,
              label: 'أقصى عدد أطفال لكل غرفة',
              hint: 'مثال: 2',
              icon: Icons.meeting_room_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _childrenMaxChildrenController,
              label: 'أقصى عدد أطفال (إجمالي)',
              hint: 'مثال: 4',
              icon: Icons.group_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _childrenCribsNoteController,
              label: 'ملاحظة الأسرّة للأطفال',
              hint: 'اكتب أي ملاحظة',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'ساحة لعب',
              value: _childrenPlaygroundAvailable ?? false,
              onChanged: (v) => setState(() => _childrenPlaygroundAvailable = v),
            ),
            _buildBooleanTile(
              title: 'قائمة أطفال',
              value: _childrenKidsMenuAvailable ?? false,
              onChanged: (v) => setState(() => _childrenKidsMenuAvailable = v),
            ),
          ],
        );

      case PolicyType.pets:
        return Column(
          children: [
            _buildBooleanTile(
              title: 'الحيوانات مسموحة',
              value: _petsAllowed ?? false,
              onChanged: (v) => setState(() => _petsAllowed = v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _petsReasonController,
              label: 'ملاحظة/سبب',
              hint: 'اكتب أي تفاصيل',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _petsFeeAmountController,
              label: 'رسوم الحيوانات',
              hint: 'مثال: 10',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _petsMaxWeightController,
              label: 'الحد الأقصى للوزن',
              hint: 'مثال: 10kg',
              icon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'يتطلب موافقة',
              value: _petsRequiresApproval ?? false,
              onChanged: (v) => setState(() => _petsRequiresApproval = v),
            ),
            _buildBooleanTile(
              title: 'بدون رسوم',
              value: _petsNoFees ?? false,
              onChanged: (v) => setState(() => _petsNoFees = v),
            ),
            _buildBooleanTile(
              title: 'صديق للحيوانات',
              value: _petsPetFriendly ?? false,
              onChanged: (v) => setState(() => _petsPetFriendly = v),
            ),
            _buildBooleanTile(
              title: 'مساحة خارجية',
              value: _petsOutdoorSpace ?? false,
              onChanged: (v) => setState(() => _petsOutdoorSpace = v),
            ),
            _buildBooleanTile(
              title: 'صارم',
              value: _petsStrict ?? false,
              onChanged: (v) => setState(() => _petsStrict = v),
            ),
          ],
        );

      case PolicyType.modification:
        return Column(
          children: [
            _buildInputField(
              controller: _minHoursController,
              label: 'الحد الأدنى للساعات قبل تسجيل الوصول',
              hint: 'عدد الساعات المطلوبة',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildBooleanTile(
              title: 'السماح بالتعديل',
              value: _modificationAllowed ?? false,
              onChanged: (v) => setState(() => _modificationAllowed = v),
            ),
            _buildBooleanTile(
              title: 'مرن',
              value: _modificationFlexible ?? false,
              onChanged: (v) => setState(() => _modificationFlexible = v),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _modificationFreeModificationHoursController,
              label: 'ساعات تعديل مجاني',
              hint: 'مثال: 24',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _modificationFeesAfterController,
              label: 'رسوم بعد',
              hint: 'مثال: بعد 24 ساعة',
              icon: Icons.money_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _modificationReasonController,
              label: 'سبب/ملاحظة',
              hint: 'اكتب أي ملاحظة',
              icon: Icons.note_rounded,
              maxLines: 2,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBooleanTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: _getPolicyTypeColor(_selectedType),
        activeTrackColor: _getPolicyTypeColor(_selectedType).withOpacity(0.3),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.5),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: maxLines == 1
                  ? Icon(
                      icon,
                      color:
                          _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required Color color,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['label']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['value']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousStep,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'السابق',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next/Submit Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: _currentStep < 2 ? _nextStep : _submitForm,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPolicyTypeColor(_selectedType),
                      _getPolicyTypeColor(_selectedType).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _getPolicyTypeColor(_selectedType).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: BlocBuilder<PoliciesBloc, PoliciesState>(
                    builder: (context, state) {
                      if (state is PolicyOperationInProgress) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Text(
                        _currentStep < 2 ? 'التالي' : 'إضافة السياسة',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = true; // Settings are optional
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_selectedPropertyId == null) {
      _showErrorMessage('الرجاء اختيار العقار');
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء إدخال الوصف');
      return false;
    }
    return true;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        _showErrorMessage('الرجاء اختيار العقار');
        return;
      }

      context.read<PoliciesBloc>().add(
            CreatePolicyEvent(
              propertyId: _selectedPropertyId!,
              type: _selectedType,
              description: _descriptionController.text,
              cancellationWindowDays:
                  int.tryParse(_cancellationWindowController.text) ?? 0,
              requireFullPaymentBeforeConfirmation: _requireFullPayment,
              minimumDepositPercentage:
                  double.tryParse(_depositPercentageController.text) ?? 0,
              minHoursBeforeCheckIn:
                  int.tryParse(_minHoursController.text) ?? 0,

              cancellationFreeCancel: _cancellationFreeCancel,
              cancellationFullRefund: _cancellationFullRefund,
              cancellationRefundPercentage:
                  int.tryParse(_cancellationRefundPercentageController.text),
              cancellationDaysBeforeCheckIn:
                  int.tryParse(_cancellationDaysBeforeCheckInController.text),
              cancellationHoursBeforeCheckIn:
                  int.tryParse(_cancellationHoursBeforeCheckInController.text),
              cancellationNonRefundable: _cancellationNonRefundable,
              cancellationPenaltyAfterDeadline:
                  _cancellationPenaltyAfterDeadlineController.text.isEmpty
                      ? null
                      : _cancellationPenaltyAfterDeadlineController.text,

              paymentDepositRequired: _paymentDepositRequired,
              paymentFullPaymentRequired: _paymentFullPaymentRequired,
              paymentDepositPercentage:
                  double.tryParse(_paymentDepositPercentageController.text),
              paymentAcceptCash: _paymentAcceptCash,
              paymentAcceptCard: _paymentAcceptCard,
              paymentPayAtProperty: _paymentPayAtProperty,
              paymentCashPreferred: _paymentCashPreferred,
              paymentAcceptedMethods:
                  _paymentAcceptedMethodsController.text.trim().isEmpty
                      ? null
                      : _paymentAcceptedMethodsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),

              checkInTime: _checkInTimeController.text.isEmpty
                  ? null
                  : _checkInTimeController.text,
              checkOutTime: _checkOutTimeController.text.isEmpty
                  ? null
                  : _checkOutTimeController.text,
              checkInFrom: _checkInFromController.text.isEmpty
                  ? null
                  : _checkInFromController.text,
              checkInUntil: _checkInUntilController.text.isEmpty
                  ? null
                  : _checkInUntilController.text,
              checkInFlexible: _checkInFlexible,
              checkInFlexibleCheckIn: _checkInFlexibleCheckIn,
              checkInRequiresCoordination: _checkInRequiresCoordination,
              checkInContactOwner: _checkInContactOwner,
              checkInEarlyCheckInNote: _checkInEarlyCheckInNoteController.text.isEmpty
                  ? null
                  : _checkInEarlyCheckInNoteController.text,
              checkInLateCheckOutNote: _checkInLateCheckOutNoteController.text.isEmpty
                  ? null
                  : _checkInLateCheckOutNoteController.text,
              checkInLateCheckOutFee: _checkInLateCheckOutFeeController.text.isEmpty
                  ? null
                  : _checkInLateCheckOutFeeController.text,

              childrenAllowed: _childrenAllowed,
              childrenFreeUnderAge:
                  int.tryParse(_childrenFreeUnderAgeController.text),
              childrenHalfPriceUnderAge:
                  int.tryParse(_childrenHalfPriceUnderAgeController.text),
              childrenMaxChildrenPerRoom:
                  int.tryParse(_childrenMaxChildrenPerRoomController.text),
              childrenMaxChildren: int.tryParse(_childrenMaxChildrenController.text),
              childrenCribsNote: _childrenCribsNoteController.text.isEmpty
                  ? null
                  : _childrenCribsNoteController.text,
              childrenPlaygroundAvailable: _childrenPlaygroundAvailable,
              childrenKidsMenuAvailable: _childrenKidsMenuAvailable,

              petsAllowed: _petsAllowed,
              petsReason: _petsReasonController.text.isEmpty
                  ? null
                  : _petsReasonController.text,
              petsFeeAmount: double.tryParse(_petsFeeAmountController.text),
              petsMaxWeight: _petsMaxWeightController.text.isEmpty
                  ? null
                  : _petsMaxWeightController.text,
              petsRequiresApproval: _petsRequiresApproval,
              petsNoFees: _petsNoFees,
              petsPetFriendly: _petsPetFriendly,
              petsOutdoorSpace: _petsOutdoorSpace,
              petsStrict: _petsStrict,

              modificationAllowed: _modificationAllowed,
              modificationFreeModificationHours:
                  int.tryParse(_modificationFreeModificationHoursController.text),
              modificationFeesAfter: _modificationFeesAfterController.text.isEmpty
                  ? null
                  : _modificationFeesAfterController.text,
              modificationFlexible: _modificationFlexible,
              modificationReason: _modificationReasonController.text.isEmpty
                  ? null
                  : _modificationReasonController.text,
            ),
          );
    }
  }

  List<Map<String, String>> _getTypeSpecificReviewItems() {
    final items = <Map<String, String>>[];

    switch (_selectedType) {
      case PolicyType.cancellation:
        items.add({
          'label': 'نافذة الإلغاء',
          'value': '${_cancellationWindowController.text} يوم',
        });
        break;
      case PolicyType.payment:
        items.add({
          'label': 'دفع كامل مطلوب',
          'value': _requireFullPayment ? 'نعم' : 'لا',
        });
        items.add({
          'label': 'نسبة الدفعة المقدمة',
          'value': '${_depositPercentageController.text}%',
        });
        break;
      case PolicyType.checkIn:
      case PolicyType.modification:
        items.add({
          'label': 'الحد الأدنى للساعات',
          'value': '${_minHoursController.text} ساعة',
        });
        break;
      default:
        items.add({
          'label': 'إعدادات افتراضية',
          'value': 'لا توجد إعدادات خاصة',
        });
    }

    return items;
  }

  Color _getPolicyTypeColor(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getPolicyIcon(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return Icons.cancel_rounded;
      case PolicyType.checkIn:
        return Icons.login_rounded;
      case PolicyType.children:
        return Icons.child_care_rounded;
      case PolicyType.pets:
        return Icons.pets_rounded;
      case PolicyType.payment:
        return Icons.payment_rounded;
      case PolicyType.modification:
        return Icons.edit_rounded;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Background Painter
class _CreatePolicyBackgroundPainter extends CustomPainter {
  final double glowIntensity;
  final PolicyType policyType;

  _CreatePolicyBackgroundPainter({
    required this.glowIntensity,
    required this.policyType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Get policy color
    final color = _getColor(policyType);

    // Draw glowing orbs
    paint.shader = RadialGradient(
      colors: [
        color.withOpacity(0.1 * glowIntensity),
        color.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: 150,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withOpacity(0.1 * glowIntensity),
        AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.7),
      radius: 100,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      100,
      paint,
    );
  }

  Color _getColor(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
