import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../../../presentation/navigation/main_tab_notification.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../../payment/presentation/bloc/payment_event.dart';
import '../../../payment/presentation/bloc/payment_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_state.dart';
import '../bloc/booking_event.dart';
import '../widgets/payment_methods_widget.dart';

class BookingPaymentPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingPaymentPage({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage>
    with SingleTickerProviderStateMixin {
  // Simplified Animation
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // State
  PaymentMethod? _selectedPaymentMethod;
  bool _acceptTerms = false;
  bool _holdNoticeShown = false;
  final TextEditingController _walletCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = PaymentMethod.jaibWallet;
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // أظهر تنبيه الحجز غير المؤكد مرة واحدة عند الدخول لصفحة الدفع
      if (!_holdNoticeShown) {
        _holdNoticeShown = true;
        _showHoldNoticeDialog();
      }
    });
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _walletCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, paymentState) {
        if (paymentState is PaymentError) {
          final message = paymentState.message;
          const unavailableText =
              'عذراً، الوحدة غير متاحة في التواريخ المحددة. يرجى اختيار تواريخ أخرى.';
          if (message.contains(unavailableText)) {
            _showUnitUnavailableDialog();
          } else if (message.contains('BOOKING_MISSED')) {
            _showPaymentErrorDialog(
              title: 'لا يمكن إتمام الدفع',
              message:
                  'لا يمكن إتمام الدفع لأن وقت الوصول المحدد لهذا الحجز قد انقضى. إذا كنت تعتقد أن هناك خطأ، يرجى التواصل مع خدمة العملاء.',
            );
          } else if (message.contains('AMOUNT_MISMATCH')) {
            _showPaymentErrorDialog(
              title: 'خطأ في مبلغ الدفع',
              message:
                  'مبلغ الدفع المرسل لا يطابق مبلغ الحجز. يرجى إعادة المحاولة من خلال صفحة الحجز بدون تعديل المبلغ، أو تواصل مع الدعم الفني.',
            );
          } else if (message.contains('ALREADY_PAID')) {
            _showPaymentErrorDialog(
              title: 'تم الدفع مسبقاً',
              message:
                  'يبدو أن هذا الحجز مدفوع بالفعل ولا يمكن تنفيذ عملية دفع إضافية لنفس الحجز.',
            );
          } else {
            _showMinimalSnackBar(message, isError: true);
          }
        } else if (paymentState is PaymentSuccess) {
          // في حالة محفظة سبأ كاش مع حالة pending نطلب من المستخدم إدخال OTP
          if (_selectedPaymentMethod == PaymentMethod.sabaCashWallet &&
              paymentState.transaction.status == PaymentStatus.pending) {
            _showWalletCodeDialog(
              method: PaymentMethod.sabaCashWallet,
              onConfirm: (otp) {
                _dispatchSabaCashOtpConfirmation(otp);
              },
            );
          } else {
            final bookingId = widget.bookingData['bookingId']?.toString() ?? '';
            if (bookingId.isNotEmpty) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<BookingBloc>().add(
                      GetBookingDetailsEvent(
                        bookingId: bookingId,
                        userId: authState.user.userId,
                      ),
                    );
              }
            }
            _showPaymentSuccessDialog(bookingId: bookingId);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildMinimalAppBar(),
          ],
          body: BlocConsumer<BookingBloc, BookingState>(
            listener: (context, state) {
              if (state is BookingCreated) {
                context.push(
                  '/booking/confirmation',
                  extra: state.booking,
                );
              } else if (state is BookingError) {
                _showMinimalSnackBar(state.message, isError: true);
              }
            },
            builder: (context, state) {
              if (state is BookingLoading ||
                  context.watch<PaymentBloc>().state is PaymentProcessing) {
                return Center(
                  child: _buildMinimalLoader(),
                );
              }

              return _buildContent();
            },
          ),
        ),
      ),
    );
  }

  void _showPaymentErrorDialog({
    required String title,
    required String message,
  }) {
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
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.95),
                    AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.error.withOpacity(0.25),
                              AppTheme.error.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.error.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.error.withOpacity(0.95),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.h3.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getWalletAccentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jwaliWallet:
        return const Color(0xFF6366F1); // Indigo
      case PaymentMethod.cashWallet:
        return const Color(0xFF10B981); // Emerald
      case PaymentMethod.oneCashWallet:
        return const Color(0xFFF59E0B); // Amber
      case PaymentMethod.floskWallet:
        return const Color(0xFFEC4899); // Pink
      case PaymentMethod.jaibWallet:
        return const Color(0xFFEF4444); // Red
      case PaymentMethod.sabaCashWallet:
        return const Color(0xFF0EA5E9); // Cyan for SabaCash
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getWalletDialogTitle(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jaibWallet:
        return 'إدخال كود شراء جيب';
      case PaymentMethod.jwaliWallet:
        return 'إدخال كود شراء جوالي';
      case PaymentMethod.cashWallet:
        return 'إدخال كود شراء كاش';
      case PaymentMethod.oneCashWallet:
        return 'إدخال كود محفظة ون كاش';
      case PaymentMethod.floskWallet:
        return 'إدخال كود محفظة فلوس';
      case PaymentMethod.sabaCashWallet:
        return 'إدخال رمز التحقق (OTP) لمحفظة سبأ كاش';
      default:
        return 'إدخال كود المحفظة';
    }
  }

  String _getWalletDialogDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jaibWallet:
        return 'قم بإدخال كود الشراء المنشأ في تطبيق جيب (من شراء أونلاين ثم كود) في محفظة جيب.';
      case PaymentMethod.jwaliWallet:
        return 'يرجى إدخال كود الشراء الذي تم توليده من تطبيق جوالي.';
      case PaymentMethod.cashWallet:
        return 'يرجى إدخال كود شراء أونلاين (يمكنك الحصول عليه من تطبيق كاش).';
      case PaymentMethod.oneCashWallet:
        return 'يرجى إدخال كود الشراء الذي تم توليده من تطبيق ون كاش.';
      case PaymentMethod.floskWallet:
        return 'يرجى إدخال كود الشراء الذي تم توليده من تطبيق فلوس.';
      case PaymentMethod.sabaCashWallet:
        return 'تم إرسال رمز تحقق (OTP) إلى رقم هاتفك المرتبط بمحفظة سبأ كاش. يرجى إدخال الرمز المكون من 4 أرقام لتأكيد العملية.';
      default:
        return 'يرجى إدخال كود الشراء المرتبط بهذه المحفظة.';
    }
  }

  String _getWalletHintText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jaibWallet:
        return 'أدخل كود شراء جيب';
      case PaymentMethod.jwaliWallet:
        return 'أدخل كود شراء جوالي';
      case PaymentMethod.cashWallet:
        return 'أدخل كود شراء أونلاين من كاش';
      case PaymentMethod.oneCashWallet:
        return 'أدخل كود ون كاش';
      case PaymentMethod.floskWallet:
        return 'أدخل كود فلوس';
      case PaymentMethod.sabaCashWallet:
        return 'أدخل رمز التحقق المكون من 4 أرقام';
      default:
        return 'أدخل كود المحفظة';
    }
  }

  void _showWalletCodeDialog({
    required PaymentMethod method,
    required void Function(String code) onConfirm,
  }) {
    final baseColor = _getWalletAccentColor(method);
    final title = _getWalletDialogTitle(method);
    final description = _getWalletDialogDescription(method);

    _walletCodeController.clear();
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
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.95),
                    AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: baseColor.withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.25),
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
                          baseColor.withOpacity(0.25),
                          baseColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: baseColor.withOpacity(0.9),
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _walletCodeController,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: _getWalletHintText(method),
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      filled: true,
                      fillColor: AppTheme.darkCard.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.darkBorder.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: baseColor.withOpacity(0.9),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(dialogContext);
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
                            'إلغاء',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final code = _walletCodeController.text.trim();
                            if (code.isEmpty) {
                              _showMinimalSnackBar(
                                'يرجى إدخال كود الشراء أولاً',
                                isError: true,
                              );
                              return;
                            }
                            Navigator.pop(dialogContext);
                            onConfirm(code);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: baseColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'متابعة الدفع',
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

  void _showPaymentSuccessDialog({required String bookingId}) {
    final PaymentMethod method = _selectedPaymentMethod ?? PaymentMethod.cash;
    final baseColor = _getWalletAccentColor(method);

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
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
                    AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: baseColor.withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.25),
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
                          baseColor.withOpacity(0.25),
                          baseColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: baseColor.withOpacity(0.9),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تم الدفع بنجاح',
                    style: AppTextStyles.h3.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تم إتمام عملية الدفع بنجاح. يمكنك الآن عرض تفاصيل الحجز.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(dialogContext);
                            context.go('/main');
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                SwitchMainTabNotification(2).dispatch(context);
                              }
                            });
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
                            'إغلاق',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      if (bookingId.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(dialogContext);
                              context.go('/main');
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  SwitchMainTabNotification(2).dispatch(context);
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (mounted) {
                                      context.push('/booking/$bookingId');
                                    }
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: baseColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'عرض تفاصيل الحجز',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showUnitUnavailableDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
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
                  color: AppTheme.error.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.2),
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
                          AppTheme.error.withOpacity(0.2),
                          AppTheme.error.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: AppTheme.error.withOpacity(0.8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'غير متاح',
                    style: AppTextStyles.h3.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عذراً، الوحدة غير متاحة في التواريخ المحددة. يرجى اختيار تواريخ أخرى.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(dialogContext);
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildMinimalAppBar() {
    final propertyName = widget.bookingData['propertyName'] as String? ?? '';

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppTheme.textWhite,
        onPressed: () {
          HapticFeedback.lightImpact();
          final bookingId = widget.bookingData['bookingId'];
          Navigator.pop(
            context,
            bookingId != null && bookingId.toString().isNotEmpty
                ? {'bookingId': bookingId}
                : null,
          );
        },
      ),
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
                          Icons.payment_rounded,
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
                                'إتمام الدفع',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted
                                      .withOpacity(0.8 + (0.1 * progress)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                propertyName.isNotEmpty
                                    ? propertyName
                                    : 'الدفع',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite
                                      .withOpacity(0.95 + (0.05 * progress)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: AppTheme.darkCard
                                          .withOpacity(0.6 - (0.2 * progress)),
                                      border: Border.all(
                                        color: AppTheme.darkBorder
                                            .withOpacity(0.4),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      'الخطوة 3 من 3',
                                      style: AppTextStyles.caption.copyWith(
                                        color:
                                            AppTheme.textLight.withOpacity(0.9),
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
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.darkBorder.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildCompactSummary(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 20),
                  _buildTermsSection(),
                  const SizedBox(height: 24),
                  _buildPayButton(),
                  const SizedBox(height: 16),
                  _buildSecurityNote(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSummary() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight =
        (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    final services =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    final servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    final subtotal = (nights * pricePerNight) + servicesTotal;
    final total = subtotal; // لا ضرائب، نعرض الخدمات فقط

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملخص الحجز',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$nights ليالي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compact price rows
          _buildPriceRow('الإقامة', nights * pricePerNight),
          if (servicesTotal > 0) _buildPriceRow('الخدمات', servicesTotal),

          const SizedBox(height: 8),
          Container(
            height: 0.5,
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ريال',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ريال',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        PaymentMethodsWidget(
          selectedMethod: _selectedPaymentMethod,
          onMethodSelected: (method) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _acceptTerms = !_acceptTerms;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _acceptTerms
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _acceptTerms ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _acceptTerms
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: _acceptTerms
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أوافق على الشروط والأحكام',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'يمكن الإلغاء مجاناً قبل 24 ساعة',
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
    );
  }

  Widget _buildPayButton() {
    final isValid = _selectedPaymentMethod != null && _acceptTerms;

    return GestureDetector(
      onTap: isValid ? _processPayment : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.9),
                  ],
                )
              : null,
          color: !isValid ? AppTheme.darkCard.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: isValid ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'دفع وتأكيد',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: isValid ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_outlined,
            size: 16,
            color: AppTheme.info.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'معلوماتك محمية بتشفير SSL 256-bit',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
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
            color: AppTheme.darkCard.withOpacity(0.3),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جاري المعالجة...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  void _processPayment() {
    HapticFeedback.mediumImpact();

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }

    final paymentMethod = _selectedPaymentMethod ?? PaymentMethod.cash;

    // Calculate total
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight =
        (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    final services =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    final servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    final subtotal = (nights * pricePerNight) + servicesTotal;
    final total = subtotal; // بدون ضرائب

    void dispatchPayment(String? walletCode) {
      context.read<PaymentBloc>().add(
            ProcessPaymentEvent(
              bookingId: widget.bookingData['bookingId'] ?? '',
              userId: authState.user.userId,
              amount: total,
              paymentMethod: paymentMethod,
              currency: 'YER',
              paymentDetails:
                  _getPaymentDetails(paymentMethod, walletCode: walletCode),
            ),
          );
    }

    // محفظة سبأ كاش: الخطوة الأولى فقط تهيئة العملية بدون OTP
    if (paymentMethod == PaymentMethod.sabaCashWallet) {
      dispatchPayment(null);
    } else if (paymentMethod.isWallet) {
      _showWalletCodeDialog(
        method: paymentMethod,
        onConfirm: (code) {
          dispatchPayment(code);
        },
      );
    } else {
      dispatchPayment(null);
    }
  }

  Map<String, dynamic>? _getPaymentDetails(
    PaymentMethod method, {
    String? walletCode,
  }) {
    if (method == PaymentMethod.creditCard) {
      return {
        'cardNumber': '4111111111111111',
        'cardHolderName': 'John Doe',
        'expiryDate': '12/25',
        'cvv': '123',
      };
    } else if (method == PaymentMethod.sabaCashWallet &&
        walletCode != null &&
        walletCode.isNotEmpty) {
      // في سبأ كاش نستخدم walletCode كرمز OTP
      return {
        'otp': walletCode,
      };
    } else if (method.isWallet && walletCode != null && walletCode.isNotEmpty) {
      return {
        // في جوالي نرسل الكود أيضاً كـ voucher ليستفيد منه الباك-إند في JwaliWalletService
        if (method == PaymentMethod.jwaliWallet) 'voucher': walletCode,
        'walletNumber': walletCode,
        'walletPin': walletCode,
      };
    }
    return null;
  }

  void _dispatchSabaCashOtpConfirmation(String otp) {
    HapticFeedback.mediumImpact();

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }

    // إعادة حساب الإجمالي بنفس منطق _processPayment
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight =
        (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    final services =
        widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    final servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    final subtotal = (nights * pricePerNight) + servicesTotal;
    final total = subtotal; // بدون ضرائب

    context.read<PaymentBloc>().add(
          ProcessPaymentEvent(
            bookingId: widget.bookingData['bookingId'] ?? '',
            userId: (authState as AuthAuthenticated).user.userId,
            amount: total,
            paymentMethod: PaymentMethod.sabaCashWallet,
            currency: 'YER',
            paymentDetails: _getPaymentDetails(
              PaymentMethod.sabaCashWallet,
              walletCode: otp,
            ),
          ),
        );
  }

  void _showMinimalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHoldNoticeDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.96),
                    AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warning.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.warning.withOpacity(0.25),
                          AppTheme.warning.withOpacity(0.12),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppTheme.warning.withOpacity(0.95),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'في انتظار الدفع',
                    style: AppTextStyles.h3.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى إتمام الدفع لتأكيد الحجز. الفترة قابلة للحجز من طرف آخر حتى يتم الدفع.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ),
        );
      },
    );
  }
}
