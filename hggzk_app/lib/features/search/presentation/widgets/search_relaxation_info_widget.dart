import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hggzk/core/theme/app_theme.dart';
import 'package:hggzk/core/enums/search_relaxation_level.dart';
import 'package:hggzk/features/search/domain/entities/search_relaxation_info.dart';

/// Widget لعرض معلومات تخفيف البحث
class SearchRelaxationInfoWidget extends StatefulWidget {
  final SearchRelaxationInfo relaxationInfo;
  final VoidCallback? onDismiss;

  const SearchRelaxationInfoWidget({
    super.key,
    required this.relaxationInfo,
    this.onDismiss,
  });

  @override
  State<SearchRelaxationInfoWidget> createState() =>
      _SearchRelaxationInfoWidgetState();
}

class _SearchRelaxationInfoWidgetState extends State<SearchRelaxationInfoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForLevel() {
    final level = widget.relaxationInfo.relaxationLevel;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return const Color(0xFF4CAF50);
      case SearchRelaxationLevel.minorRelaxation:
        return const Color(0xFF2196F3);
      case SearchRelaxationLevel.moderateRelaxation:
        return const Color(0xFFFF9800);
      case SearchRelaxationLevel.majorRelaxation:
        return const Color(0xFFFF5722);
      case SearchRelaxationLevel.alternativeSuggestions:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getIconForLevel() {
    final level = widget.relaxationInfo.relaxationLevel;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return Icons.verified_rounded;
      case SearchRelaxationLevel.minorRelaxation:
        return Icons.star_rounded;
      case SearchRelaxationLevel.moderateRelaxation:
        return Icons.tune_rounded;
      case SearchRelaxationLevel.majorRelaxation:
        return Icons.lightbulb_rounded;
      case SearchRelaxationLevel.alternativeSuggestions:
        return Icons.auto_awesome_rounded;
    }
  }

  String _getDisplayName() {
    final level = widget.relaxationInfo.relaxationLevel;
    switch (level) {
      case SearchRelaxationLevel.exact:
        return 'تطابق دقيق';
      case SearchRelaxationLevel.minorRelaxation:
        return 'تخفيف بسيط';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'تخفيف متوسط';
      case SearchRelaxationLevel.majorRelaxation:
        return 'تخفيف كبير';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'اقتراحات بديلة';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print relaxation info
    print(
        '📊 [SearchRelaxationInfo] wasRelaxed: ${widget.relaxationInfo.wasRelaxed}');
    print(
        '📊 [SearchRelaxationInfo] level: ${widget.relaxationInfo.relaxationLevel}');
    print(
        '📊 [SearchRelaxationInfo] userMessage: ${widget.relaxationInfo.userMessage}');
    print(
        '📊 [SearchRelaxationInfo] relaxedFilters: ${widget.relaxationInfo.relaxedFilters}');

    if (!widget.relaxationInfo.wasRelaxed) {
      print(
          '⚠️ [SearchRelaxationInfo] Not showing widget - wasRelaxed is false');
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getColorForLevel().withOpacity(0.1),
                _getColorForLevel().withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getColorForLevel().withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getColorForLevel().withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getColorForLevel().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForLevel(),
                            color: _getColorForLevel(),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayName(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _getColorForLevel(),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                              ),
                              if (widget.relaxationInfo.hasUserMessage) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.relaxationInfo.userMessage!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                        fontFamily: 'Cairo',
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.relaxationInfo.relaxedFilters.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: _getColorForLevel(),
                            ),
                            onPressed: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                          ),
                        if (widget.onDismiss != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.grey[600],
                            onPressed: widget.onDismiss,
                          ),
                      ],
                    ),

                    // Expanded details
                    if (_isExpanded &&
                        widget.relaxationInfo.relaxedFilters.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'التعديلات المطبقة:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            widget.relaxationInfo.relaxedFilters.map((filter) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getColorForLevel().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getColorForLevel().withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _getColorForLevel(),
                                    fontFamily: 'Cairo',
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
