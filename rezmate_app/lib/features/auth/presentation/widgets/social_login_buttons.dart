import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FuturisticSocialButton(
          icon: 'assets/icons/google.svg',
          fallbackIcon: Icons.g_mobiledata,
          label: 'Google',
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.2),
          onPressed: () =>
              _handleSocialLogin(context, SocialLoginProvider.google),
        ),
        const SizedBox(height: 16),
        _FuturisticSocialButton(
          icon: 'assets/icons/facebook.svg',
          fallbackIcon: Icons.facebook,
          label: 'Facebook',
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1877F2).withOpacity(0.2),
              const Color(0xFF1877F2).withOpacity(0.1),
            ],
          ),
          borderColor: const Color(0xFF1877F2).withOpacity(0.3),
          onPressed: () =>
              _handleSocialLogin(context, SocialLoginProvider.facebook),
        ),
        const SizedBox(height: 16),
        _FuturisticSocialButton(
          icon: 'assets/icons/apple.svg',
          fallbackIcon: Icons.apple,
          label: 'Apple',
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.2),
          onPressed: () =>
              _handleSocialLogin(context, SocialLoginProvider.apple),
        ),
      ],
    );
  }

  Future<void> _handleSocialLogin(
    BuildContext context,
    SocialLoginProvider provider,
  ) async {
    try {
      switch (provider) {
        case SocialLoginProvider.google:
          debugPrint('🔐 Google Sign-In: بدء عملية تسجيل الدخول...');
          debugPrint('📱 Platform: ${_getCurrentPlatformName()}');

          // الحصول على Client ID المناسب للمنصة (لأغراض التحقق والـ logging)
          final String? platformClientId = _getGoogleClientIdForPlatform();
          if (platformClientId != null && platformClientId.isNotEmpty) {
            debugPrint(
              '🔑 Platform Client ID: ${_truncateId(platformClientId)}',
            );
          }

          // إعداد GoogleSignIn حسب المنصة
          final GoogleSignIn googleSignIn;

          if (kIsWeb) {
            // 🌐 Web: استخدام Web Client ID
            if (AppConstants.googleWebClientId.isEmpty) {
              throw Exception('Web Client ID غير مُعد في AppConstants');
            }
            debugPrint('🌐 Web: استخدام Web Client ID');
            debugPrint(
              '🔑 Web Client ID: ${_truncateId(AppConstants.googleWebClientId)}',
            );
            googleSignIn = GoogleSignIn(
              scopes: ['email', 'profile'],
              clientId: AppConstants.googleWebClientId,
            );
          } else if (defaultTargetPlatform == TargetPlatform.android) {
            // 📱 Android: الاعتماد على google-services.json مع serverClientId للخادم
            debugPrint('📄 Android: استخدام google-services.json');

            // serverClientId اختياري - إذا كان موجوداً يُستخدم للحصول على idToken
            final serverClientId = AppConstants.googleWebClientId.isNotEmpty
                ? AppConstants.googleWebClientId
                : null;

            if (serverClientId != null) {
              debugPrint('🔑 Server Client ID: ${_truncateId(serverClientId)}');
              googleSignIn = GoogleSignIn(
                scopes: ['email', 'profile'],
                serverClientId: serverClientId,
              );
            } else {
              debugPrint(
                '⚠️ Server Client ID غير موجود - سيتم استخدام accessToken بدلاً من idToken',
              );
              googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
            }
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            // 🍎 iOS: استخدام iOS Client ID مع Server Client ID
            if (AppConstants.googleIosClientId.isEmpty) {
              throw Exception('iOS Client ID غير مُعد في AppConstants');
            }
            debugPrint('🍎 iOS: استخدام iOS Client ID');
            debugPrint(
              '🔑 iOS Client ID: ${_truncateId(AppConstants.googleIosClientId)}',
            );

            final serverClientId = AppConstants.googleWebClientId.isNotEmpty
                ? AppConstants.googleWebClientId
                : null;
            if (serverClientId != null) {
              debugPrint('🔑 Server Client ID: ${_truncateId(serverClientId)}');
            }

            googleSignIn = GoogleSignIn(
              scopes: ['email', 'profile'],
              clientId: AppConstants.googleIosClientId,
              serverClientId: serverClientId,
            );
          } else {
            debugPrint('❌ منصة غير مدعومة: ${_getCurrentPlatformName()}');
            throw UnsupportedError('منصة غير مدعومة للمصادقة بـ Google');
          }

          // تسجيل الخروج أولاً لضمان اختيار الحساب الصحيح
          await googleSignIn.signOut();

          // بدء عملية تسجيل الدخول
          final GoogleSignInAccount? account = await googleSignIn.signIn();
          if (account == null) {
            debugPrint('❌ Google Sign-In: المستخدم ألغى العملية');
            return;
          }

          debugPrint(
            '✅ Google Sign-In: تم الحصول على الحساب: ${account.email}',
          );

          final GoogleSignInAuthentication auth = await account.authentication;

          debugPrint('🎫 التحقق من الـ Tokens...');
          debugPrint(
            '   - ID Token: ${auth.idToken != null && auth.idToken!.isNotEmpty ? "✅ موجود" : "❌ مفقود"}',
          );
          debugPrint(
            '   - Access Token: ${auth.accessToken != null && auth.accessToken!.isNotEmpty ? "✅ موجود" : "❌ مفقود"}',
          );

          // استخدام idToken إن وجد، وإلا استخدام accessToken
          final String? token =
              (auth.idToken != null && auth.idToken!.isNotEmpty)
              ? auth.idToken
              : auth.accessToken;

          if (token == null || token.isEmpty) {
            debugPrint('❌ Google Sign-In: لا يوجد token صالح!');
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('خطأ: لم يتم الحصول على رمز المصادقة من Google'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final bool isIdToken =
              auth.idToken != null && auth.idToken!.isNotEmpty;
          debugPrint(
            '📤 Google Sign-In: إرسال ${isIdToken ? "idToken" : "accessToken"} إلى الخادم...',
          );

          // ignore: use_build_context_synchronously
          context.read<AuthBloc>().add(
            SocialLoginEvent(provider: provider, token: token),
          );
          break;
        case SocialLoginProvider.facebook:
          debugPrint('🔐 Facebook Login: بدء عملية تسجيل الدخول...');

          if (kIsWeb) {
            await FacebookAuth.i.webAndDesktopInitialize(
              appId: AppConstants.facebookAppId,
              cookie: true,
              xfbml: true,
              version: "v13.0",
            );
          }

          final res = await FacebookAuth.instance.login(
            permissions: ['public_profile', 'email'],
          );

          if (res.status != LoginStatus.success) {
            debugPrint(
              '❌ Facebook Login: فشل - ${res.status} - ${res.message}',
            );
            return;
          }

          final accessToken = res.accessToken?.token;
          if (accessToken == null || accessToken.isEmpty) {
            debugPrint('❌ Facebook Login: accessToken فارغ!');
            return;
          }

          debugPrint('📤 Facebook Login: إرسال accessToken إلى الخادم...');

          // ignore: use_build_context_synchronously
          context.read<AuthBloc>().add(
            SocialLoginEvent(provider: provider, token: accessToken),
          );
          break;
        case SocialLoginProvider.apple:
          debugPrint('🍎 Apple Sign-In: غير مدعوم حالياً');
          return;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Social Login Error: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الدخول: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// الحصول على Google Client ID المناسب للمنصة الحالية
  String? _getGoogleClientIdForPlatform() {
    if (kIsWeb) {
      return AppConstants.googleWebClientId;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return AppConstants.googleIosClientId;
      case TargetPlatform.android:
        // Android يستخدم google-services.json، لكن نعيد Client ID المخصص لأغراض التتبع والـ logging
        return AppConstants.googleAndroidClientId;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  /// الحصول على اسم المنصة الحالية للـ logging
  String _getCurrentPlatformName() {
    if (kIsWeb) return 'Web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// اختصار Client ID للـ logging بشكل آمن
  String _truncateId(String id) {
    if (id.isEmpty) return '(فارغ)';
    if (id.length <= 30) return id;
    return '${id.substring(0, 30)}...';
  }
}

class _FuturisticSocialButton extends StatefulWidget {
  final String icon;
  final IconData fallbackIcon;
  final String label;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onPressed;

  const _FuturisticSocialButton({
    required this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.gradient,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  State<_FuturisticSocialButton> createState() =>
      _FuturisticSocialButtonState();
}

class _FuturisticSocialButtonState extends State<_FuturisticSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _animationController.reverse();
        setState(() => _isHovered = false);
        widget.onPressed();
      },
      onTapCancel: () {
        _animationController.reverse();
        setState(() => _isHovered = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.borderColor
                    : widget.borderColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.borderColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.fallbackIcon,
                          size: 24,
                          color: AppTheme.textWhite,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تسجيل الدخول بـ ${widget.label}',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
