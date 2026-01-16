import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';
import '../widgets/review_card_widget.dart';

class ReviewsListPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const ReviewsListPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends State<ReviewsListPage> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedRating;
  bool _withImagesOnly = false;
  String _sortBy = 'CreatedAt';
  String _sortDirection = 'Desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ReviewBloc>().add(const LoadMoreReviewsEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReviewBloc>()
        ..add(GetPropertyReviewsEvent(propertyId: widget.propertyId)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildFuturisticBackground(),
            Column(
              children: [
                _buildFiltersSection(),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<ReviewBloc, ReviewState>(
                    builder: (context, state) {
                      if (state is ReviewLoading) {
                        return const Center(
                          child: LoadingWidget(
                            type: LoadingType.circular,
                          ),
                        );
                      }

                      if (state is ReviewError) {
                        return Center(
                          child: CustomErrorWidget(
                            message: state.message,
                            onRetry: () {
                              context.read<ReviewBloc>().add(
                                    GetPropertyReviewsEvent(
                                      propertyId: widget.propertyId,
                                    ),
                                  );
                            },
                          ),
                        );
                      }

                      if (state is ReviewsLoaded) {
                        if (state.reviews.items.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<ReviewBloc>().add(
                                  RefreshReviewsEvent(
                                      propertyId: widget.propertyId),
                                );
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(
                                AppDimensions.paddingMedium),
                            itemCount: state.hasReachedMax
                                ? state.reviews.items.length
                                : state.reviews.items.length + 1,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: AppDimensions.spacingMd,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= state.reviews.items.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        AppDimensions.paddingMedium),
                                    child: LoadingWidget(
                                      type: LoadingType.dots,
                                    ),
                                  ),
                                );
                              }
                              return ReviewCardWidget(
                                review: state.reviews.items[index],
                                onLike: () {
                                  // Handle like
                                },
                              );
                            },
                          ),
                        );
                      }

                      if (state is ReviewLoadingMore) {
                        return ListView.separated(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.all(AppDimensions.paddingMedium),
                          itemCount: state.currentReviews.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(
                            height: AppDimensions.spacingMd,
                          ),
                          itemBuilder: (context, index) {
                            if (index >= state.currentReviews.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      AppDimensions.paddingMedium),
                                  child: LoadingWidget(
                                    type: LoadingType.dots,
                                  ),
                                ),
                              );
                            }
                            return ReviewCardWidget(
                              review: state.currentReviews[index],
                              onLike: () {
                                // Handle like
                              },
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2,
            AppTheme.darkBackground3,
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'التقييمات',
              style: AppTextStyles.h2.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.propertyName,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.primaryBlue.withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'الكل',
                        isSelected: _selectedRating == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRating = null;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: AppDimensions.spacingSm,
                          ),
                          child: _buildFilterChip(
                            label: '$rating',
                            icon: Icons.star,
                            isSelected: _selectedRating == rating,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRating = selected ? rating : null;
                              });
                              _applyFilters();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        label: 'مع صور فقط',
                        icon: Icons.photo_library_outlined,
                        isSelected: _withImagesOnly,
                        onSelected: (selected) {
                          setState(() {
                            _withImagesOnly = selected;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        final parts = value.split('-');
                        setState(() {
                          _sortBy = parts[0];
                          _sortDirection = parts[1];
                        });
                        _applyFilters();
                        HapticFeedback.lightImpact();
                      },
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMd,
                        ),
                      ),
                      color: AppTheme.darkCard,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'CreatedAt-Desc',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 18),
                              SizedBox(width: 12),
                              Text('الأحدث'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'CreatedAt-Asc',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 18),
                              SizedBox(width: 12),
                              Text('الأقدم'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Rating-Desc',
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, size: 18),
                              SizedBox(width: 12),
                              Text('الأعلى تقييماً'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Rating-Asc',
                          child: Row(
                            children: [
                              Icon(Icons.trending_down, size: 18),
                              SizedBox(width: 12),
                              Text('الأقل تقييماً'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium,
                          vertical: AppDimensions.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.2),
                              AppTheme.primaryBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSm,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(
                              width: AppDimensions.spacingXs,
                            ),
                            Text(
                              _getSortLabel(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: !isSelected ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingXs),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingLarge),
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.9),
              AppTheme.darkCard.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.warning.withOpacity(0.25),
                    AppTheme.warning.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 40,
                    color: AppTheme.warning.withOpacity(0.6),
                  ),
                  Icon(
                    Icons.rate_review_outlined,
                    size: 26,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'لا توجد تقييمات',
                style: AppTextStyles.h3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              'كن أول من يقيم هذا العقار',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    if (_sortBy == 'CreatedAt' && _sortDirection == 'Desc') {
      return 'الأحدث';
    } else if (_sortBy == 'CreatedAt' && _sortDirection == 'Asc') {
      return 'الأقدم';
    } else if (_sortBy == 'Rating' && _sortDirection == 'Desc') {
      return 'الأعلى تقييماً';
    } else if (_sortBy == 'Rating' && _sortDirection == 'Asc') {
      return 'الأقل تقييماً';
    }
    return 'ترتيب';
  }

  void _applyFilters() {
    context.read<ReviewBloc>().add(
          FilterReviewsEvent(
            rating: _selectedRating,
            withImagesOnly: _withImagesOnly,
            sortBy: _sortBy,
            sortDirection: _sortDirection,
          ),
        );
  }
}
