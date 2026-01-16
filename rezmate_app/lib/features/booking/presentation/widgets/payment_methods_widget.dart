import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rezmate/core/enums/payment_method_enum.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentMethodsWidget extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;

  const PaymentMethodsWidget({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // تجميع المحافظ الإلكترونية (جيب، جوالي، فلوسك، ون كاش، كاش)
  final List<PaymentMethod> _wallets = [
    PaymentMethod.jaibWallet,
    PaymentMethod.jwaliWallet,
    PaymentMethod.floskWallet,
    PaymentMethod.oneCashWallet,
    PaymentMethod.cashWallet,
  ];

  // طرق الدفع الأخرى
  final List<PaymentMethod> _otherMethods = [
    PaymentMethod.cash,
    PaymentMethod.creditCard,
    PaymentMethod.paypal,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان المحافظ الإلكترونية
          _buildSectionHeader(
            icon: Icons.account_balance_wallet_rounded,
            title: 'المحافظ الإلكترونية',
            subtitle: 'الدفع الفوري والآمن',
          ),
          const SizedBox(height: 16),

          // عرض المحافظ الإلكترونية
          _buildWalletsSection(),

          const SizedBox(height: 24),

          // عنوان طرق الدفع الأخرى
          _buildSectionHeader(
            icon: Icons.payments_rounded,
            title: 'طرق دفع أخرى',
            subtitle: 'خيارات إضافية',
          ),
          const SizedBox(height: 16),

          // طرق الدفع الأخرى
          _buildOtherPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textLight.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletsSection() {
    return Column(
      children: _wallets.asMap().entries.map((entry) {
        final index = entry.key;
        final wallet = entry.value;
        final isSelected = widget.selectedMethod == wallet;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 80)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(40 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWalletTile(wallet, isSelected),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildWalletTile(PaymentMethod wallet, bool isSelected) {
    final Color baseColor = _getWalletColor(wallet);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onMethodSelected(wallet);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? baseColor.withOpacity(0.08) : AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? baseColor.withOpacity(0.6)
                : AppTheme.darkBorder.withOpacity(0.25),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: baseColor.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // مؤشر التحديد
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? baseColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? baseColor
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // أيقونة المحفظة
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _getWalletIcon(wallet, isSelected),
              ),
            ),

            const SizedBox(width: 12),

            // اسم المحفظة + وصف بسيط
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getWalletShortName(wallet),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.textWhite
                              : AppTheme.textLight,
                        ),
                      ),
                      if (wallet == PaymentMethod.jaibWallet) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: baseColor.withOpacity(0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'مُوصى به',
                            style: AppTextStyles.caption.copyWith(
                              color: baseColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (wallet == PaymentMethod.jaibWallet)
                    Text(
                      'أفضل خيار للدفع السريع والآمن',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textLight.withOpacity(0.7),
                      ),
                    )
                  else
                    Text(
                      'دفع آمن عبر المحفظة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textLight.withOpacity(0.7),
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

  Widget _buildOtherPaymentMethods() {
    return Column(
      children: _otherMethods.map((method) {
        final isSelected = widget.selectedMethod == method;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPaymentMethodTile(
                    method,
                    isSelected,
                    isEnabled: false,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    bool isSelected, {
    bool isEnabled = true,
  }) {
    final Color activeColor = _getMethodColor(method);
    final Color iconColor = isEnabled ? activeColor : AppTheme.textMuted;
    final Color textColor = isEnabled ? AppTheme.textLight : AppTheme.textMuted;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onMethodSelected(method);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected && isEnabled
              ? activeColor.withOpacity(0.1)
              : AppTheme.darkCard.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected && isEnabled
                ? activeColor.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.25),
            width: isSelected && isEnabled ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // مؤشر التحديد
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected && isEnabled ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected && isEnabled
                      ? activeColor
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // أيقونة الطريقة
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEnabled
                    ? activeColor.withOpacity(0.1)
                    : AppTheme.darkCard.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getMethodIcon(method),
                size: 20,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 12),

            // اسم الطريقة والوصف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayNameAr,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected && isEnabled
                          ? AppTheme.textWhite
                          : textColor,
                    ),
                  ),
                  if (_getMethodDescription(method) != null)
                    Text(
                      _getMethodDescription(method)!,
                      style: AppTextStyles.caption.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),

            // شارة إضافية (مثلاً لعرض حالة الطريقة)
            if (!isEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'غير متاح حالياً',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getWalletColor(PaymentMethod wallet) {
    switch (wallet) {
      case PaymentMethod.jwaliWallet:
        return const Color(0xFF6366F1); // Indigo
      case PaymentMethod.cashWallet:
        return const Color(0xFF10B981); // Emerald
      case PaymentMethod.oneCashWallet:
        return const Color(0xFFF59E0B); // Amber
      case PaymentMethod.floskWallet:
        return const Color(0xFFEC4899); // Pink
      case PaymentMethod.jaibWallet:
        return const Color(0xFFEF4444); // Red for Jaib
      default:
        return AppTheme.primaryBlue;
    }
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return const Color(0xFF10B981); // Green
      case PaymentMethod.creditCard:
        return const Color(0xFF3B82F6); // Blue
      case PaymentMethod.paypal:
        return const Color(0xFFFFC439); // PayPal Yellow
      default:
        return AppTheme.primaryBlue;
    }
  }

  Widget _getWalletIcon(PaymentMethod wallet, bool isSelected) {
    // هنا يمكنك استخدام صور حقيقية للمحافظ
    // return Image.asset('assets/images/wallets/${wallet.iconName}.png');

    // مؤقتاً سنستخدم أيقونات
    IconData iconData;
    switch (wallet) {
      case PaymentMethod.jwaliWallet:
        iconData = Icons.phone_android;
        break;
      case PaymentMethod.cashWallet:
        iconData = Icons.account_balance_wallet;
        break;
      case PaymentMethod.oneCashWallet:
        iconData = Icons.looks_one;
        break;
      case PaymentMethod.floskWallet:
        iconData = Icons.monetization_on;
        break;
      case PaymentMethod.jaibWallet:
        iconData = Icons.wallet;
        break;
      default:
        iconData = Icons.payment;
    }

    return Icon(
      iconData,
      size: 24,
      color: isSelected ? Colors.white : _getWalletColor(wallet),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.paypal_outlined;
      default:
        return Icons.payment;
    }
  }

  String _getWalletShortName(PaymentMethod wallet) {
    switch (wallet) {
      case PaymentMethod.jwaliWallet:
        return 'جوالي';
      case PaymentMethod.cashWallet:
        return 'كاش';
      case PaymentMethod.oneCashWallet:
        return 'ون كاش';
      case PaymentMethod.floskWallet:
        return 'فلوس';
      case PaymentMethod.jaibWallet:
        return 'جيب';
      default:
        return '';
    }
  }

  String? _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'الدفع عند الاستلام';
      case PaymentMethod.creditCard:
        return 'فيزا، ماستركارد';
      case PaymentMethod.paypal:
        return 'دفع آمن عبر الإنترنت';
      default:
        return null;
    }
  }
}
