import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SettingsDialog extends StatefulWidget {
  final Map<String, dynamic> currentSettings;
  final Function(Map<String, dynamic> settings) onSaveSettings;

  const SettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSaveSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> currentSettings,
    required Function(Map<String, dynamic> settings) onSaveSettings,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentSettings: currentSettings,
        onSaveSettings: onSaveSettings,
      ),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.currentSettings);
    _settings.putIfAbsent('showWeekends', () => true);
    _settings.putIfAbsent('highlightToday', () => true);
    _settings.putIfAbsent('showPrices', () => true);
    _settings.putIfAbsent('showStatistics', () => true);
    _settings.putIfAbsent('autoRefresh', () => false);
    _settings.putIfAbsent('compactMode', () => false);
    _settings.putIfAbsent('defaultCurrency', () => 'YER');
    _settings.putIfAbsent('dateFormat', () => 'yyyy-MM-dd');

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: _buildSettingsList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إعدادات الجدول',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'خصص عرض وسلوك الجدول',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          color: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('العرض'),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.weekend_rounded,
          title: 'إظهار عطلة نهاية الأسبوع',
          subtitle: 'تمييز أيام السبت والجمعة',
          settingKey: 'showWeekends',
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.today_rounded,
          title: 'تمييز اليوم الحالي',
          subtitle: 'تسليط الضوء على تاريخ اليوم',
          settingKey: 'highlightToday',
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.attach_money_rounded,
          title: 'إظهار الأسعار',
          subtitle: 'عرض الأسعار في التقويم',
          settingKey: 'showPrices',
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.bar_chart_rounded,
          title: 'إظهار الإحصائيات',
          subtitle: 'عرض لوحة الإحصائيات',
          settingKey: 'showStatistics',
        ),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.compress_rounded,
          title: 'الوضع المضغوط',
          subtitle: 'تصغير حجم البطاقات',
          settingKey: 'compactMode',
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('التحديث'),
        const SizedBox(height: 12),
        _buildSwitchSetting(
          icon: Icons.autorenew_rounded,
          title: 'التحديث التلقائي',
          subtitle: 'تحديث البيانات كل 30 ثانية',
          settingKey: 'autoRefresh',
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('التنسيق'),
        const SizedBox(height: 12),
        _buildCurrencySelector(),
        const SizedBox(height: 12),
        _buildDateFormatSelector(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.primaryPurple,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required String settingKey,
  }) {
    final value = _settings[settingKey] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryPurple.withOpacity(0.3)
              : AppTheme.darkSurface.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: (newValue) {
            HapticFeedback.selectionClick();
            setState(() {
              _settings[settingKey] = newValue;
            });
          },
          activeColor: AppTheme.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final currencies = ['YER', 'USD', 'SAR', 'EUR'];
    final selectedCurrency = _settings['defaultCurrency'] as String? ?? 'YER';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'العملة الافتراضية',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currencies.map((currency) {
              final isSelected = currency == selectedCurrency;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _settings['defaultCurrency'] = currency;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryPurple,
                              AppTheme.primaryBlue,
                            ],
                          )
                        : null,
                    color: isSelected ? null : AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : AppTheme.textMuted.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    currency,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppTheme.textWhiteAlways
                          : AppTheme.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFormatSelector() {
    final formats = {
      'yyyy-MM-dd': '2025-01-15',
      'dd/MM/yyyy': '15/01/2025',
      'MM/dd/yyyy': '01/15/2025',
      'dd-MM-yyyy': '15-01-2025',
    };
    final selectedFormat = _settings['dateFormat'] as String? ?? 'yyyy-MM-dd';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تنسيق التاريخ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...formats.entries.map((entry) {
            final isSelected = entry.key == selectedFormat;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _settings['dateFormat'] = entry.key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPurple.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPurple.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppTheme.textWhite
                                : AppTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onSaveSettings(_settings);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.save_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'حفظ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
