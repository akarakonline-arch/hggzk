import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';
import '../widgets/review_form_widget.dart';

class WriteReviewPage extends StatelessWidget {
  final String bookingId;
  final String propertyId;
  final String propertyName;

  const WriteReviewPage({
    super.key,
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReviewBloc>(),
      child: _WriteReviewView(
        bookingId: bookingId,
        propertyId: propertyId,
        propertyName: propertyName,
      ),
    );
  }
}

class _StarryBackground extends StatelessWidget {
  const _StarryBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarryBackgroundPainter(),
    );
  }
}

class _StarryBackgroundPainter extends CustomPainter {
  static const int _starCount = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // خلفية متدرجة داكنة قريبة من ReviewsSummaryWidget
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF050816),
          Color(0xFF050816),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final random = math.Random(7);

    // نجوم صغيرة موزعة عشوائياً
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.32)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < _starCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + random.nextDouble() * 1.3;
      canvas.drawCircle(Offset(dx, dy), radius, starPaint);
    }

    // هالات ضوئية خفيفة تعطي إحساس المستقبلية
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final glowColors = [
      AppTheme.primaryBlue.withOpacity(0.18),
      AppTheme.primaryPurple.withOpacity(0.16),
      AppTheme.primaryCyan.withOpacity(0.14),
    ];

    for (final color in glowColors) {
      glowPaint.color = color;
      final dx = (0.2 + random.nextDouble() * 0.6) * size.width;
      final dy = (0.1 + random.nextDouble() * 0.6) * size.height;
      final radius = size.shortestSide * (0.25 + random.nextDouble() * 0.2);
      canvas.drawCircle(Offset(dx, dy), radius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WriteReviewView extends StatelessWidget {
  final String bookingId;
  final String propertyId;
  final String propertyName;

  const _WriteReviewView({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(
            child: _StarryBackground(),
          ),
          BlocConsumer<ReviewBloc, ReviewState>(
            listener: (context, state) {
              if (state is ReviewCreated) {
                _showSuccessDialog(context);
              } else if (state is ReviewCreateError) {
                _showErrorSnackBar(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is ReviewCreating) {
                return const Center(
                  child: LoadingWidget(
                    type: LoadingType.circular,
                    message: 'جاري إرسال التقييم...',
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSmall,
                  vertical: AppDimensions.paddingMedium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPropertyInfo(),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusLg,
                        ),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.5),
                          width: 0.9,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.darkCard.withOpacity(0.96),
                            AppTheme.darkSurface.withOpacity(0.96),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.22),
                            blurRadius: 26,
                            spreadRadius: 1,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusLg,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.paddingMedium,
                            ),
                            child: ReviewFormWidget(
                              onSubmit: (ratings, comment, images) {
                                context.read<ReviewBloc>().add(
                                      CreateReviewEvent(
                                        bookingId: bookingId,
                                        propertyId: propertyId,
                                        cleanliness: ratings['cleanliness']!,
                                        service: ratings['service']!,
                                        location: ratings['location']!,
                                        value: ratings['value']!,
                                        comment: comment,
                                        imagesBase64: images,
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
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close,
          color: Colors.white,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.98),
              AppTheme.darkCard.withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppTheme.primaryGradient.createShader(bounds),
        child: Text(
          'كتابة تقييم',
          style: AppTextStyles.h2.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.primaryBlue.withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.45),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.98),
            AppTheme.darkSurface.withOpacity(0.98),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تجربتك في',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            AppTheme.primaryCyan.withOpacity(0.9),
                            AppTheme.primaryPurple.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.45),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            propertyName,
            style: AppTextStyles.h2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Text(
                  'شكراً لك!',
                  style: AppTextStyles.h2.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'تم إرسال تقييمك بنجاح',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.pop(true); // Return true to indicate success
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      'حسناً',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
        ),
      ),
    );
  }
}
