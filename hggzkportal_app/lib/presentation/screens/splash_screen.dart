import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../injection_container.dart';
import '../../services/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _breathController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _breathAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _navigateAfterDelay();
  }

  void _initializeAnimations() {
    // Fade Controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale Controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // Breath Controller
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    // Progress Controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _fadeController.forward();
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _breathController.repeat(reverse: true);
    _progressController.forward();
  }

  void _navigateAfterDelay() {
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final localStorage = sl<LocalStorageService>();
    final isFirstRun = !localStorage.isOnboardingCompleted();

    if (isFirstRun) {
      context.go('/onboarding/select-city-currency');
      return;
    }

    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.isEmailVerified) {
        context.go('/main');
      } else {
        context.go('/verify-otp');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _breathController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF0D1227),
              Color(0xFF0F1433),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // الخلفية الهادئة مع الأضواء الناعمة
            _buildAmbientBackground(size),

            // المحتوى الرئيسي
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // الشعار الأنيق
            _buildElegantLogo(),

            const SizedBox(height: 48),

            // اسم التطبيق
            _buildAppTitle(),

            const Spacer(flex: 2),

            // مؤشر التحميل الأنيق
            _buildElegantLoader(),

            const SizedBox(height: 60),

            // النص السفلي
            _buildFooter(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground(Size size) {
    return Stack(
      children: [
        // ضوء علوي ناعم
        Positioned(
          top: -100,
          left: -50,
          child: AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1E88E5).withOpacity(0.15),
                        const Color(0xFF1E88E5).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ضوء سفلي ناعم
        Positioned(
          bottom: -150,
          right: -100,
          child: AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathAnimation.value,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C4DFF).withOpacity(0.12),
                        const Color(0xFF7C4DFF).withOpacity(0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // نجوم خافتة
        ..._buildStars(size),
      ],
    );
  }

  List<Widget> _buildStars(Size size) {
    return List.generate(20, (index) {
      final random = math.Random(index);
      final top = random.nextDouble() * size.height;
      final left = random.nextDouble() * size.width;
      final starSize = random.nextDouble() * 2 + 1;
      final opacity = random.nextDouble() * 0.3 + 0.1;

      return Positioned(
        top: top,
        left: left,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: starSize,
            height: starSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildElegantLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _breathAnimation,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value * _breathAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E88E5).withOpacity(0.2),
                    const Color(0xFF7C4DFF).withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(60, 60),
                        painter: _ElegantCalendarPainter(
                          color: const Color(0xFF64B5F6),
                          secondaryColor: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // اسم التطبيق
        SlideTransition(
          position: _textSlideAnimation,
          child: FadeTransition(
            opacity: _textFadeAnimation,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF64B5F6),
                  Color(0xFF42A5F5),
                  Color(0xFF7C4DFF),
                ],
              ).createShader(bounds),
              child: const Text(
                'HGGZK',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // الوصف
        FadeTransition(
          opacity: _subtitleFadeAnimation,
          child: Text(
            'نظام الحجوزات المتطور',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantLoader() {
    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // خط التحميل الأنيق
          SizedBox(
            width: 180,
            height: 8,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // الخلفية
                    Container(
                      width: 180,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // الخط المتحرك
                    Container(
                      width: 180 * _progressAnimation.value,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF64B5F6),
                            Color(0xFF7C4DFF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64B5F6).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    // النقطة المتحركة
                    Positioned(
                      left: (180 * _progressAnimation.value) - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF64B5F6).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // نص التحميل
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                'جاري التحضير...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: Colors.white.withOpacity(0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // خط فاصل
          Container(
            width: 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // اسم الشركة
          Text(
            'ARMA-SOFT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 4,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// رسام أيقونة التقويم الأنيقة
class _ElegantCalendarPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  _ElegantCalendarPainter({
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // إطار التقويم
    final calendarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 4),
        width: size.width * 0.75,
        height: size.height * 0.6,
      ),
      const Radius.circular(8),
    );

    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, secondaryColor],
    ).createShader(calendarRect.outerRect);

    canvas.drawRRect(calendarRect, paint);

    // خط الرأس
    final headerY = calendarRect.top + 12;
    canvas.drawLine(
      Offset(calendarRect.left + 4, headerY),
      Offset(calendarRect.right - 4, headerY),
      paint..strokeWidth = 1.5,
    );

    // حلقات التعليق
    final ringPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [color, secondaryColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(centerX - 8, calendarRect.top),
      2.5,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(centerX + 8, calendarRect.top),
      2.5,
      ringPaint,
    );

    // علامة الصح الأنيقة
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final checkPath = Path()
      ..moveTo(centerX - 8, centerY + 6)
      ..lineTo(centerX - 2, centerY + 12)
      ..lineTo(centerX + 10, centerY);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
