// lib/features/auth/presentation/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/route_constants.dart';

class LoginForm extends StatefulWidget {
  final Function(String emailOrPhone, String password, bool rememberMe)
      onSubmit;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailOrPhoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _fieldAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _iconRotationController;
  late AnimationController _shimmerController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _emailOrPhoneFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);

    // Auto-fill for testing (remove in production)
    _emailOrPhoneController.text = "ahmed.mohamed@example.com";
    _passwordController.text = "User@123";

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  void _onFocusChange() {
    if (_emailOrPhoneFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      _fieldAnimationController.forward();
      _iconRotationController.forward();
    } else {
      _fieldAnimationController.reverse();
      _iconRotationController.reverse();
    }
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _emailOrPhoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fieldAnimationController.dispose();
    _buttonAnimationController.dispose();
    _iconRotationController.dispose();
    _shimmerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOptimizedField(
              controller: _emailOrPhoneController,
              focusNode: _emailOrPhoneFocusNode,
              label: 'البريد الإلكتروني أو رقم الهاتف',
              hint: 'أدخل بريدك أو رقمك',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                if (!Validators.isValidEmail(value) &&
                    !Validators.isValidPhoneNumber(value)) {
                  return 'يرجى إدخال بريد إلكتروني أو رقم هاتف صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildOptimizedField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'كلمة المرور',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSubmit(),
              suffixIcon: _buildPasswordToggle(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                if (value.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildOptions(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue.withValues(alpha: 0.4)
              : AppTheme.darkBorder.withValues(alpha: 0.15),
          width: isFocused ? 1.5 : 1,
        ),
        color: AppTheme.darkCard.withValues(alpha: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            enabled: !widget.isLoading,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isFocused
                    ? AppTheme.primaryBlue
                    : AppTheme.textMuted.withValues(alpha: 0.7),
                fontSize: hasText || isFocused ? 11 : 13,
                fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
              ),
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isFocused ? AppTheme.primaryGradient : null,
                  color: !isFocused
                      ? AppTheme.darkCard.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isFocused
                      ? Colors.white
                      : AppTheme.textMuted.withValues(alpha: 0.6),
                ),
              ),
              suffixIcon: suffixIcon,
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
                fontSize: 11,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: _rememberMe ? AppTheme.primaryGradient : null,
                  color: !_rememberMe
                      ? AppTheme.darkCard.withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe
                        ? Colors.transparent
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'تذكرني',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: widget.isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context.push(RouteConstants.forgotPassword);
                },
          child: Text(
            'نسيت كلمة المرور؟',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: widget.isLoading ? null : _onSubmit,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: widget.isLoading
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'جاري التحقق...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تسجيل الدخول',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildUltraFuturisticField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fieldAnimationController,
        _iconRotationController,
        _shimmerController,
      ]),
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final hasError = validator != null &&
            controller.text.isNotEmpty &&
            validator(controller.text) != null;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isFocused ? 1 : 0),
          duration: const Duration(milliseconds: 200),
          builder: (context, focusValue, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (isFocused)
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isFocused
                          ? AppTheme.primaryBlue.withOpacity(0.03)
                          : AppTheme.darkCard.withOpacity(0.15),
                      isFocused
                          ? AppTheme.primaryPurple.withOpacity(0.02)
                          : AppTheme.darkCard.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasError
                        ? AppTheme.error.withOpacity(0.5)
                        : isFocused
                            ? AppTheme.primaryBlue.withOpacity(0.3)
                            : AppTheme.darkBorder.withOpacity(0.15),
                    width: isFocused ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 15,
                      sigmaY: 15,
                    ),
                    child: Stack(
                      children: [
                        // Shimmer Effect
                        if (isFocused)
                          Positioned(
                            top: 0,
                            left: -100 + (_shimmerController.value * 500),
                            child: Container(
                              width: 100,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.primaryBlue.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Input Field
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          obscureText: obscureText,
                          keyboardType: keyboardType,
                          textInputAction: textInputAction,
                          enabled: !widget.isLoading,
                          onFieldSubmitted: onFieldSubmitted,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            labelText: label,
                            hintText: hint,
                            labelStyle: AppTextStyles.bodySmall.copyWith(
                              color: isFocused
                                  ? AppTheme.primaryBlue.withOpacity(0.9)
                                  : AppTheme.textMuted.withOpacity(0.7),
                              fontWeight:
                                  isFocused ? FontWeight.w500 : FontWeight.w400,
                            ),
                            hintStyle: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.3),
                            ),
                            prefixIcon: _buildAnimatedIcon(icon, isFocused),
                            suffixIcon: suffixIcon,
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            errorStyle: AppTextStyles.caption.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                          validator: validator,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedIcon(IconData icon, bool isFocused) {
    return Transform.rotate(
      angle: _iconRotationController.value * 0.1,
      child: Container(
        margin: const EdgeInsets.all(12),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isFocused ? AppTheme.primaryGradient : null,
          color: !isFocused ? AppTheme.darkCard.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isFocused ? Colors.white : AppTheme.textMuted.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildPasswordToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 18,
          color: AppTheme.textMuted.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildMinimalOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me - Minimal Design
        GestureDetector(
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: _rememberMe ? AppTheme.primaryGradient : null,
                  color:
                      !_rememberMe ? AppTheme.darkCard.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _rememberMe
                        ? Colors.transparent
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: AnimatedScale(
                  scale: _rememberMe ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'تذكرني',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        // Forgot Password - Minimal Link
        TextButton(
          onPressed: widget.isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context.push(RouteConstants.forgotPassword);
                },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'نسيت كلمة المرور؟',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton() {
    final isLoading = widget.isLoading;
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'تسجيل الدخول',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.login_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'تسجيل الدخول',
          style: AppTextStyles.buttonMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'جاري التحقق...',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      HapticFeedback.mediumImpact();

      widget.onSubmit(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );
    }
  }
}
