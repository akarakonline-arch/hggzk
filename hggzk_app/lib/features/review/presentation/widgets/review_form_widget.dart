import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'rating_selector_widget.dart';

class ReviewFormWidget extends StatefulWidget {
  final Function(Map<String, int> ratings, String comment, List<String>? images)
      onSubmit;

  const ReviewFormWidget({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final Map<String, int> _ratings = {
    'cleanliness': 0,
    'service': 0,
    'location': 0,
    'value': 0,
  };
  bool _isRecommended = true;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallExperience(),
            const Divider(height: 1),
            _buildRatingSection(),
            const Divider(height: 1),
            _buildCommentSection(),
            const Divider(height: 1),
            _buildRecommendationSection(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallExperience() {
    final overallRating = _getOverallRating();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.warning.withOpacity(0.16),
              AppTheme.warning.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          border: Border.all(
            color: AppTheme.warning.withOpacity(0.3),
            width: 0.7,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        overallRating > 0 ? overallRating.toString() : '-',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كيف كانت تجربتك بشكل عام؟',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          'اختر التقييم العام للتجربة، ثم قيّم التفاصيل بالأسفل.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        RatingSelectorWidget(
                          rating: overallRating,
                          starSize: 28,
                          alignment: MainAxisAlignment.start,
                          onRatingChanged: (value) {
                            setState(() {
                              _ratings['cleanliness'] = value;
                              _ratings['service'] = value;
                              _ratings['location'] = value;
                              _ratings['value'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قيّم الجوانب المختلفة',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildRatingItem(
            'النظافة',
            'cleanliness',
            Icons.cleaning_services_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildRatingItem(
            'الخدمة',
            'service',
            Icons.room_service_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildRatingItem(
            'الموقع',
            'location',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildRatingItem(
            'القيمة مقابل السعر',
            'value',
            Icons.attach_money_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String label, String key, IconData icon) {
    final rating = _ratings[key]!;
    final progress = rating / 5;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.9),
            AppTheme.darkCard.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.6),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            rating > 0 ? rating.toString() : '-',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.darkBorder.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0, 1),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getCategoryColor(key),
                                    _getCategoryColor(key).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      RatingSelectorWidget(
                        rating: rating,
                        starSize: 20,
                        alignment: MainAxisAlignment.start,
                        onRatingChanged: (newRating) {
                          setState(() {
                            _ratings[key] = newRating;
                          });
                        },
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

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'شاركنا تفاصيل تجربتك',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب تقييمك هنا...',
              filled: true,
              fillColor: AppTheme.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                borderSide: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'من فضلك اكتب تقييمك';
              }
              if (value.length < 10) {
                return 'التقييم يجب أن يكون 10 أحرف على الأقل';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'هل توصي بهذا المكان؟',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: _isRecommended,
            onChanged: (value) {
              setState(() {
                _isRecommended = value;
              });
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _canSubmit();

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          final baseGradient = AppTheme.primaryGradient;
          final shadowColor = baseGradient.colors.first
              .withOpacity(0.25 + (_glowAnimation.value * 0.2));

          return Opacity(
            opacity: canSubmit ? 1.0 : 0.6,
            child: Container(
              decoration: BoxDecoration(
                gradient: baseGradient,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 14 + (_glowAnimation.value * 6),
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMd,
                  ),
                  onTap: canSubmit ? _submitReview : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Text(
                          'إرسال التقييم',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canSubmit() {
    return _ratings.values.every((rating) => rating > 0) &&
        _commentController.text.isNotEmpty;
  }

  int _getOverallRating() {
    final total = _ratings.values.fold(0, (sum, rating) => sum + rating);
    if (total == 0) return 0;
    return (total / _ratings.length).round();
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _ratings,
        _commentController.text,
        null,
      );
    }
  }

  Color _getCategoryColor(String key) {
    switch (key) {
      case 'cleanliness':
        return AppTheme.primaryBlue;
      case 'service':
        return AppTheme.success;
      case 'location':
        return AppTheme.info;
      case 'value':
        return AppTheme.warning;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
