import 'package:flutter/material.dart';
import 'package:hggzk/core/theme/app_text_styles.dart';
import 'package:hggzk/core/theme/app_theme.dart';

/// Widget لعرض الاقتراحات لتحسين البحث
class SuggestedActionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onActionTap;

  const SuggestedActionsWidget({
    super.key,
    required this.suggestions,
    this.onActionTap,
  });

  IconData _getIconForSuggestion(String suggestion) {
    final lowerSuggestion = suggestion.toLowerCase();
    if (lowerSuggestion.contains('تاريخ') ||
        lowerSuggestion.contains('تواريخ')) {
      return Icons.calendar_today;
    } else if (lowerSuggestion.contains('سعر')) {
      return Icons.attach_money;
    } else if (lowerSuggestion.contains('مراف')) {
      return Icons.settings;
    } else if (lowerSuggestion.contains('نوع') ||
        lowerSuggestion.contains('وحد')) {
      return Icons.home;
    } else if (lowerSuggestion.contains('تقييم')) {
      return Icons.star;
    } else if (lowerSuggestion.contains('مد') ||
        lowerSuggestion.contains('موقع')) {
      return Icons.location_on;
    } else if (lowerSuggestion.contains('ضيوف')) {
      return Icons.people;
    }
    return Icons.lightbulb_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'اقتراحات لتحسين البحث',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                avatar: Icon(
                  _getIconForSuggestion(suggestion),
                  size: 18,
                  color: Colors.blue[700],
                ),
                label: Text(
                  suggestion,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue[900],
                  ),
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.blue[300]!,
                ),
                onPressed:
                    onActionTap != null ? () => onActionTap!(suggestion) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
