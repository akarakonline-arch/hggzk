import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hggzk/core/enums/payment_method_enum.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  int? _pressedIndex;

  final List<PaymentMethod> _wallets = [
    PaymentMethod.jaibWallet,
    PaymentMethod.jwaliWallet,
    PaymentMethod.floskWallet,
    PaymentMethod.oneCashWallet,
    PaymentMethod.cashWallet,
  ];

  final List<PaymentMethod> _otherMethods = [
    PaymentMethod.cash,
    PaymentMethod.creditCard,
    PaymentMethod.paypal,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════
          // قسم المحافظ الإلكترونية
          // ═══════════════════════════════════════════
          _buildSectionTitle(
            icon: Icons.account_balance_wallet_rounded,
            title: 'المحافظ الإلكترونية',
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(height: 20),
          _buildWalletsSection(),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════
          // قسم طرق الدفع الأخرى
          // ═══════════════════════════════════════════
          _buildSectionTitle(
            icon: Icons.payments_rounded,
            title: 'طرق دفع أخرى',
            color: AppTheme.success,
          ),
          const SizedBox(height: 20),
          _buildOtherMethodsSection(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // عنوان القسم
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // قسم المحافظ - تصميم Wrap مع Chips
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWalletsSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: List.generate(_wallets.length, (index) {
        final wallet = _wallets[index];
        final isSelected = widget.selectedMethod == wallet;
        final isPressed = _pressedIndex == index;

        return _buildWalletChip(
          wallet: wallet,
          index: index,
          isSelected: isSelected,
          isPressed: isPressed,
        );
      }),
    );
  }

  Widget _buildWalletChip({
    required PaymentMethod wallet,
    required int index,
    required bool isSelected,
    required bool isPressed,
  }) {
    final color = _getWalletColor(wallet);
    final isRecommended = wallet == PaymentMethod.jaibWallet;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.6 + (value * 0.4),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedIndex = index),
        onTapUp: (_) {
          setState(() => _pressedIndex = null);
          HapticFeedback.lightImpact();
          widget.onMethodSelected(wallet);
        },
        onTapCancel: () => setState(() => _pressedIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : color.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.shadowDark,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة المحفظة
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getWalletIcon(wallet),
                  color: isSelected ? Colors.white : color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),

              // اسم المحفظة
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getWalletName(wallet),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textWhite.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'موصى',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'دفع فوري',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // مؤشر الاختيار
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppTheme.darkBorder.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded, size: 12, color: color)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // قسم طرق الدفع الأخرى - بطاقات أفقية
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOtherMethodsSection() {
    return Row(
      children: List.generate(_otherMethods.length, (index) {
        final method = _otherMethods[index];
        final isSelected = widget.selectedMethod == method;
        final globalIndex = _wallets.length + index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == _otherMethods.length - 1 ? 0 : 5,
            ),
            child: _buildMethodCard(
              method: method,
              index: globalIndex,
              isSelected: isSelected,
              isEnabled: false,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMethodCard({
    required PaymentMethod method,
    required int index,
    required bool isSelected,
    bool isEnabled = true,
  }) {
    final color = _getMethodColor(method);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 25 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onMethodSelected(method);
              }
            : null,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected && isEnabled
                    ? LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected && isEnabled ? null : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected && isEnabled
                      ? color.withOpacity(0.4)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: isSelected && isEnabled ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowDark,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // الأيقونة
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(isEnabled ? 0.15 : 0.08),
                          color.withOpacity(isEnabled ? 0.08 : 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMethodIcon(method),
                      color: isEnabled ? color : AppTheme.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // الاسم
                  Text(
                    method.displayNameAr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isEnabled
                          ? AppTheme.textWhite.withOpacity(0.9)
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),

                  // الوصف
                  Text(
                    _getMethodDescription(method) ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // شارة "قريباً"
            if (!isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.overlayDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.darkBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'قريباً',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // علامة الاختيار
            if (isSelected && isEnabled)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
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

  Color _getWalletColor(PaymentMethod wallet) {
    switch (wallet) {
      case PaymentMethod.jaibWallet:
        return AppTheme.error;
      case PaymentMethod.jwaliWallet:
        return AppTheme.primaryPurple;
      case PaymentMethod.cashWallet:
        return AppTheme.success;
      case PaymentMethod.oneCashWallet:
        return AppTheme.warning;
      case PaymentMethod.floskWallet:
        return AppTheme.neonPurple;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppTheme.success;
      case PaymentMethod.creditCard:
        return AppTheme.primaryBlue;
      case PaymentMethod.paypal:
        return AppTheme.info;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getWalletIcon(PaymentMethod wallet) {
    switch (wallet) {
      case PaymentMethod.jaibWallet:
        return Icons.wallet_rounded;
      case PaymentMethod.jwaliWallet:
        return Icons.phone_android_rounded;
      case PaymentMethod.cashWallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.oneCashWallet:
        return Icons.looks_one_rounded;
      case PaymentMethod.floskWallet:
        return Icons.monetization_on_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethod.paypal:
        return Icons.paypal_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _getWalletName(PaymentMethod wallet) {
    switch (wallet) {
      case PaymentMethod.jaibWallet:
        return 'جيب';
      case PaymentMethod.jwaliWallet:
        return 'جوالي';
      case PaymentMethod.cashWallet:
        return 'كاش';
      case PaymentMethod.oneCashWallet:
        return 'ون كاش';
      case PaymentMethod.floskWallet:
        return 'فلوس';
      default:
        return '';
    }
  }

  String? _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'عند الاستلام';
      case PaymentMethod.creditCard:
        return 'فيزا / ماستر';
      case PaymentMethod.paypal:
        return 'دفع آمن';
      default:
        return null;
    }
  }
}
