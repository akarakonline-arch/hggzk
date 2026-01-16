// lib/features/home/presentation/widgets/sections/section_container_widget.dart

import 'package:flutter/material.dart';
import 'package:hggzk/features/home/domain/entities/section.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/enums/section_type_enum.dart';
import 'models/section_display_item.dart';
import 'section_header_widget.dart';
import 'list_section_widget.dart';
import 'grid_section_widget.dart';
import 'big_cards_section_widget.dart';

class SectionContainerWidget extends StatelessWidget {
  final Section section;
  final List<SectionDisplayItem> items;
  final Function(String)? onItemTap;
  final VoidCallback? onSeeAllTap;

  const SectionContainerWidget({
    super.key,
    required this.section,
    required this.items,
    this.onItemTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 16),

          // Content based on type
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = section.title ?? section.name ?? 'القسم';
    final subtitle = section.subtitle;

    // Choose header style based on section type
    switch (section.uiType) {
      case SectionType.bigCards:
        return SectionHeaderLuxury(
          title: title,
          subtitle: subtitle,
          onSeeAllTap: onSeeAllTap,
        );
      case SectionType.list:
      case SectionType.grid:
      default:
        return SectionHeaderWidget(
          title: title,
          subtitle: subtitle,
          onSeeAllTap: onSeeAllTap,
        );
    }
  }

  Widget _buildContent() {
    switch (section.uiType) {
      case SectionType.bigCards:
        return BigCardsSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
      case SectionType.list:
        return ListSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
      case SectionType.grid:
      default:
        return GridSectionWidget(
          items: items,
          onItemTap: onItemTap,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎭 SKELETON LOADING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class SectionSkeletonWidget extends StatelessWidget {
  final SectionType type;

  const SectionSkeletonWidget({
    super.key,
    this.type = SectionType.grid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120, height: 20),
                    const SizedBox(height: 8),
                    _SkeletonBox(width: 180, height: 14),
                  ],
                ),
                _SkeletonBox(width: 70, height: 32, borderRadius: 10),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content Skeleton
          _buildContentSkeleton(),
        ],
      ),
    );
  }

  Widget _buildContentSkeleton() {
    switch (type) {
      case SectionType.bigCards:
        return SizedBox(
          height: 380,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => _SkeletonBox(
              width: 300,
              height: 380,
              borderRadius: 28,
            ),
          ),
        );
      case SectionType.list:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 130,
                  borderRadius: 20,
                ),
              ),
            ),
          ),
        );
      case SectionType.grid:
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
            children: List.generate(
              4,
              (_) => _SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 22,
              ),
            ),
          ),
        );
    }
  }
}

class _SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.shimmerBase.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
