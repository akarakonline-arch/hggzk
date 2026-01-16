import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/cached_image_widget.dart';

class UploadReviewImageWidget extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final double size;

  const UploadReviewImageWidget({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.onRemove,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLg),
          child: Stack(
            children: [
              CachedImageWidget(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}