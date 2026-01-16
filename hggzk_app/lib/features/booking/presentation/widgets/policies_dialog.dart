// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import 'dart:math' as math;
// import 'package:go_router/go_router.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';

// class PoliciesDialog extends StatefulWidget {
//   final String? propertyId;
//   final String propertyName;

//   const PoliciesDialog({
//     super.key,
//     this.propertyId,
//     required this.propertyName,
//   });

//   static Future<void> show(
//     BuildContext context, {
//     String? propertyId,
//     required String propertyName,
//   }) {
//     return showDialog(
//       context: context,
//       barrierColor: AppTheme.overlayDark.withOpacity(0.8),
//       builder: (context) => PoliciesDialog(
//         propertyId: propertyId,
//         propertyName: propertyName,
//       ),
//     );
//   }

//   @override
//   State<PoliciesDialog> createState() => _PoliciesDialogState();
// }

// class _PoliciesDialogState extends State<PoliciesDialog>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late AnimationController _contentController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _slideAnimation;

//   int _selectedTabIndex = 0;
//   final PageController _pageController = PageController();

//   final List<PolicyTab> _tabs = [
//     PolicyTab(
//       icon: Icons.cancel_presentation_rounded,
//       title: 'الإلغاء',
//       color: AppTheme.warning,
//     ),
//     PolicyTab(
//       icon: Icons.payment_rounded,
//       title: 'الدفع',
//       color: AppTheme.primaryBlue,
//     ),
//     PolicyTab(
//       icon: Icons.gavel_rounded,
//       title: 'القوانين',
//       color: AppTheme.primaryPurple,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _contentController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _scaleAnimation = Tween<double>(
//       begin: 0.7,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOutBack,
//     ));

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     ));

//     _slideAnimation = Tween<double>(
//       begin: 30.0,
//       end: 0.0,
//     ).animate(CurvedAnimation(
//       parent: _contentController,
//       curve: Curves.easeOutCubic,
//     ));

//     _controller.forward();
//     _contentController.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _contentController.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return FadeTransition(
//           opacity: _fadeAnimation,
//           child: ScaleTransition(
//             scale: _scaleAnimation,
//             child: Dialog(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               insetPadding: const EdgeInsets.all(16),
//               child: Container(
//                 constraints: BoxConstraints(
//                   maxWidth: 500,
//                   maxHeight: size.height * 0.85,
//                 ),
//                 child: Stack(
//                   children: [
//                     // Glass Background
//                     _buildGlassBackground(),

//                     // Main Content
//                     _buildMainContent(),

//                     // Close Button
//                     _buildCloseButton(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGlassBackground() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(24),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 AppTheme.darkCard.withOpacity(0.8),
//                 AppTheme.darkCard.withOpacity(0.6),
//                 AppTheme.darkBackground.withOpacity(0.7),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: AppTheme.glassLight.withOpacity(0.2),
//               width: 1.5,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: AppTheme.primaryBlue.withOpacity(0.1),
//                 blurRadius: 30,
//                 spreadRadius: 5,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return Column(
//       children: [
//         _buildHeader(),
//         _buildTabBar(),
//         Expanded(
//           child: _buildTabContent(),
//         ),
//         _buildFooter(),
//       ],
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppTheme.primaryBlue.withOpacity(0.1),
//             AppTheme.primaryPurple.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           // Icon with glow effect
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [
//                   AppTheme.primaryBlue.withOpacity(0.2),
//                   AppTheme.primaryPurple.withOpacity(0.2),
//                 ],
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppTheme.glowBlue.withOpacity(0.3),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Icon(
//               Icons.policy_rounded,
//               size: 28,
//               color: AppTheme.glowWhite,
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Title
//           ShaderMask(
//             shaderCallback: (bounds) => LinearGradient(
//               colors: [
//                 AppTheme.textWhite,
//                 AppTheme.textWhite.withOpacity(0.9),
//               ],
//             ).createShader(bounds),
//             child: Text(
//               'سياسات وقوانين الحجز',
//               style: AppTextStyles.heading4.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),

//           const SizedBox(height: 8),

//           // Property Name
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: AppTheme.darkBackground.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: AppTheme.darkBorder.withOpacity(0.2),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.apartment_rounded,
//                   size: 14,
//                   color: AppTheme.textLight,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   widget.propertyName,
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textLight,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabBar() {
//     return Container(
//       height: 60,
//       margin: const EdgeInsets.symmetric(horizontal: 24),
//       decoration: BoxDecoration(
//         color: AppTheme.darkBackground.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: _tabs.asMap().entries.map((entry) {
//           final index = entry.key;
//           final tab = entry.value;
//           final isSelected = _selectedTabIndex == index;

//           return Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 HapticFeedback.lightImpact();
//                 setState(() {
//                   _selectedTabIndex = index;
//                 });
//                 _pageController.animateToPage(
//                   index,
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeOutCubic,
//                 );
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   gradient: isSelected
//                       ? LinearGradient(
//                           colors: [
//                             tab.color.withOpacity(0.2),
//                             tab.color.withOpacity(0.1),
//                           ],
//                         )
//                       : null,
//                   borderRadius: BorderRadius.circular(12),
//                   border: isSelected
//                       ? Border.all(
//                           color: tab.color.withOpacity(0.3),
//                           width: 1.5,
//                         )
//                       : null,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       tab.icon,
//                       size: 18,
//                       color: isSelected ? tab.color : AppTheme.textMuted,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       tab.title,
//                       style: AppTextStyles.bodySmall.copyWith(
//                         color: isSelected
//                             ? AppTheme.textWhite
//                             : AppTheme.textMuted,
//                         fontWeight:
//                             isSelected ? FontWeight.w600 : FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildTabContent() {
//     return AnimatedBuilder(
//       animation: _contentController,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, _slideAnimation.value),
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: PageView(
//               controller: _pageController,
//               onPageChanged: (index) {
//                 setState(() {
//                   _selectedTabIndex = index;
//                 });
//               },
//               children: [
//                 _buildCancellationPolicy(),
//                 _buildPaymentPolicy(),
//                 _buildPropertyRules(),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildCancellationPolicy() {
//     return _buildPolicyContent(
//       policies: [
//         PolicyItem(
//           icon: Icons.free_cancellation_rounded,
//           title: 'إلغاء مجاني',
//           description: 'يمكنك الإلغاء مجاناً قبل 24 ساعة من موعد تسجيل الوصول',
//           type: PolicyType.success,
//         ),
//         PolicyItem(
//           icon: Icons.discount_rounded,
//           title: 'استرداد جزئي',
//           description: 'إلغاء قبل 12 ساعة: استرداد 50% من المبلغ المدفوع',
//           type: PolicyType.warning,
//         ),
//         PolicyItem(
//           icon: Icons.cancel_rounded,
//           title: 'عدم الاسترداد',
//           description: 'لا يمكن الاسترداد في حالة الإلغاء قبل أقل من 12 ساعة',
//           type: PolicyType.error,
//         ),
//         PolicyItem(
//           icon: Icons.event_busy_rounded,
//           title: 'عدم الحضور',
//           description: 'في حالة عدم الحضور، سيتم خصم كامل المبلغ',
//           type: PolicyType.error,
//         ),
//       ],
//     );
//   }

//   Widget _buildPaymentPolicy() {
//     return _buildPolicyContent(
//       policies: [
//         PolicyItem(
//           icon: Icons.payment_rounded,
//           title: 'طرق الدفع المتاحة',
//           description: 'نقداً، بطاقات ائتمانية، محافظ إلكترونية',
//           type: PolicyType.info,
//         ),
//         PolicyItem(
//           icon: Icons.security_rounded,
//           title: 'دفع آمن',
//           description: 'جميع المعاملات محمية بتشفير SSL 256-bit',
//           type: PolicyType.success,
//         ),
//         PolicyItem(
//           icon: Icons.schedule_rounded,
//           title: 'توقيت الدفع',
//           description: 'الدفع الكامل مطلوب عند تأكيد الحجز',
//           type: PolicyType.warning,
//         ),
//         PolicyItem(
//           icon: Icons.receipt_long_rounded,
//           title: 'الفواتير',
//           description: 'ستتلقى فاتورة إلكترونية بعد إتمام الدفع',
//           type: PolicyType.info,
//         ),
//       ],
//     );
//   }

//   Widget _buildPropertyRules() {
//     return _buildPolicyContent(
//       policies: [
//         PolicyItem(
//           icon: Icons.access_time_rounded,
//           title: 'أوقات تسجيل الدخول',
//           description: 'الوصول: 2:00 مساءً | المغادرة: 12:00 ظهراً',
//           type: PolicyType.info,
//         ),
//         PolicyItem(
//           icon: Icons.smoke_free_rounded,
//           title: 'ممنوع التدخين',
//           description: 'التدخين ممنوع في جميع الأماكن المغلقة',
//           type: PolicyType.warning,
//         ),
//         PolicyItem(
//           icon: Icons.pets_rounded,
//           title: 'الحيوانات الأليفة',
//           description: 'غير مسموح باصطحاب الحيوانات الأليفة',
//           type: PolicyType.error,
//         ),
//         PolicyItem(
//           icon: Icons.volume_off_rounded,
//           title: 'ساعات الهدوء',
//           description: 'يرجى الحفاظ على الهدوء من 10 مساءً حتى 8 صباحاً',
//           type: PolicyType.info,
//         ),
//       ],
//     );
//   }

//   Widget _buildPolicyContent({required List<PolicyItem> policies}) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: ListView.separated(
//         physics: const BouncingScrollPhysics(),
//         itemCount: policies.length,
//         separatorBuilder: (context, index) => const SizedBox(height: 16),
//         itemBuilder: (context, index) {
//           final policy = policies[index];
//           return _buildPolicyCard(policy, index);
//         },
//       ),
//     );
//   }

//   Widget _buildPolicyCard(PolicyItem policy, int index) {
//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 300 + (index * 100)),
//       tween: Tween(begin: 0.0, end: 1.0),
//       curve: Curves.easeOutBack,
//       builder: (context, value, child) {
//         // Ensure value is clamped between 0 and 1
//         final clampedValue = value.clamp(0.0, 1.0);
//         final scale = 0.8 + (0.2 * clampedValue);

//         return Transform.scale(
//           scale: scale,
//           child: Opacity(
//             opacity: clampedValue,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     policy.getColor().withOpacity(0.1),
//                     policy.getColor().withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: policy.getColor().withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           policy.getColor().withOpacity(0.2),
//                           policy.getColor().withOpacity(0.1),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       policy.icon,
//                       size: 20,
//                       color: policy.getColor(),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           policy.title,
//                           style: AppTextStyles.bodyMedium.copyWith(
//                             color: AppTheme.textWhite,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           policy.description,
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.textLight.withOpacity(0.8),
//                             height: 1.4,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.transparent,
//             AppTheme.darkBackground.withOpacity(0.3),
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           // Info Note
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: AppTheme.info.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: AppTheme.info.withOpacity(0.2),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.info_outline_rounded,
//                   size: 16,
//                   color: AppTheme.info,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'بتأكيد الحجز، فإنك توافق على جميع السياسات المذكورة أعلاه',
//                     style: AppTextStyles.caption.copyWith(
//                       color: AppTheme.textLight.withOpacity(0.8),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Action Buttons
//           Row(
//             children: [
//               if (widget.propertyId != null && widget.propertyId!.isNotEmpty)
//                 Expanded(
//                   child: _buildActionButton(
//                     onTap: () {
//                       HapticFeedback.lightImpact();
//                       Navigator.pop(context);
//                       context.push('/property/${widget.propertyId}', extra: {
//                         'fromBookingSummary': true,
//                         'propertyName': widget.propertyName,
//                       });
//                     },
//                     icon: Icons.open_in_new_rounded,
//                     label: 'عرض العقار',
//                     isPrimary: false,
//                   ),
//                 ),
//               if (widget.propertyId != null && widget.propertyId!.isNotEmpty)
//                 const SizedBox(width: 12),
//               Expanded(
//                 child: _buildActionButton(
//                   onTap: () {
//                     HapticFeedback.lightImpact();
//                     Navigator.pop(context);
//                   },
//                   icon: Icons.check_rounded,
//                   label: 'فهمت',
//                   isPrimary: true,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required VoidCallback onTap,
//     required IconData icon,
//     required String label,
//     required bool isPrimary,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 48,
//         decoration: BoxDecoration(
//           gradient: isPrimary
//               ? LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     AppTheme.primaryBlue.withOpacity(0.8),
//                     AppTheme.primaryPurple.withOpacity(0.8),
//                   ],
//                 )
//               : null,
//           color: isPrimary ? null : AppTheme.darkCard.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isPrimary
//                 ? Colors.transparent
//                 : AppTheme.darkBorder.withOpacity(0.3),
//             width: 1,
//           ),
//           boxShadow: isPrimary
//               ? [
//                   BoxShadow(
//                     color: AppTheme.primaryBlue.withOpacity(0.3),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ]
//               : null,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 18,
//               color: isPrimary ? Colors.white : AppTheme.textLight,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: AppTextStyles.bodySmall.copyWith(
//                 color: isPrimary ? Colors.white : AppTheme.textLight,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCloseButton() {
//     return Positioned(
//       top: 12,
//       right: 12,
//       child: GestureDetector(
//         onTap: () {
//           HapticFeedback.lightImpact();
//           Navigator.pop(context);
//         },
//         child: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: AppTheme.darkBackground.withOpacity(0.5),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: AppTheme.darkBorder.withOpacity(0.2),
//               width: 1,
//             ),
//           ),
//           child: Icon(
//             Icons.close_rounded,
//             size: 18,
//             color: AppTheme.textLight,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Supporting Classes
// class PolicyTab {
//   final IconData icon;
//   final String title;
//   final Color color;

//   PolicyTab({
//     required this.icon,
//     required this.title,
//     required this.color,
//   });
// }

// enum PolicyType { success, warning, error, info }

// class PolicyItem {
//   final IconData icon;
//   final String title;
//   final String description;
//   final PolicyType type;

//   PolicyItem({
//     required this.icon,
//     required this.title,
//     required this.description,
//     required this.type,
//   });

//   Color getColor() {
//     switch (type) {
//       case PolicyType.success:
//         return AppTheme.success;
//       case PolicyType.warning:
//         return AppTheme.warning;
//       case PolicyType.error:
//         return AppTheme.error;
//       case PolicyType.info:
//         return AppTheme.info;
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PoliciesDialog extends StatefulWidget {
  final String? propertyId;
  final String propertyName;

  const PoliciesDialog({
    super.key,
    this.propertyId,
    required this.propertyName,
  });

  static Future<void> show(
    BuildContext context, {
    String? propertyId,
    required String propertyName,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppTheme.overlayDark.withOpacity(0.9),
      barrierDismissible: false,
      builder: (context) => PoliciesDialog(
        propertyId: propertyId,
        propertyName: propertyName,
      ),
    );
  }

  @override
  State<PoliciesDialog> createState() => _PoliciesDialogState();
}

class _PoliciesDialogState extends State<PoliciesDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scrollIndicatorController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scrollIndicatorAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scrollIndicatorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scrollIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _scrollIndicatorController,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 50;
      if (_showScrollIndicator == isAtBottom) {
        setState(() {
          _showScrollIndicator = !isAtBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollIndicatorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width > 600 ? 40 : 16,
                vertical: 32,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  maxHeight: size.height * 0.9,
                ),
                child: Stack(
                  children: [
                    // Professional Background
                    _buildProfessionalBackground(),

                    // Main Content
                    Column(
                      children: [
                        _buildProfessionalHeader(),
                        Expanded(
                          child: Stack(
                            children: [
                              _buildPoliciesList(),
                              if (_showScrollIndicator)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildScrollIndicator(),
                                ),
                            ],
                          ),
                        ),
                        _buildProfessionalFooter(),
                      ],
                    ),

                    // Close Button
                    _buildElegantCloseButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 60,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkBackground.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Professional Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.15),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 32,
              color: AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            'الشروط والأحكام',
            style: AppTextStyles.h3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Property Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.propertyName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return AnimatedBuilder(
      animation: _scrollIndicatorAnimation,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.9),
                AppTheme.darkCard.withOpacity(0.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, _scrollIndicatorAnimation.value),
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: AppTheme.primaryBlue.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اسحب للأسفل لعرض المزيد',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoliciesList() {
    final allPolicies = _getAllPolicies();

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      radius: const Radius.circular(8),
      thickness: 6,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
        itemCount: allPolicies.length,
        itemBuilder: (context, index) {
          final section = allPolicies[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: _buildPolicySection(section),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPolicySection(PolicySection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  section.color.withOpacity(0.15),
                  section.color.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: section.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    section.icon,
                    size: 18,
                    color: section.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textLight.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Policy Items
          ...section.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildProfessionalPolicyCard(item, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProfessionalPolicyCard(PolicyItem policy, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: policy.getColor().withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Side Color Indicator
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: policy.getColor().withOpacity(0.4),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14).copyWith(left: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number Badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: policy.getColor().withOpacity(0.1),
                      border: Border.all(
                        color: policy.getColor().withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: AppTextStyles.caption.copyWith(
                          color: policy.getColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: policy.getColor().withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      policy.icon,
                      size: 20,
                      color: policy.getColor(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textLight.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                        if (policy.additionalInfo != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: policy.getColor().withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: policy.getColor().withOpacity(0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              policy.additionalInfo!,
                              style: AppTextStyles.caption.copyWith(
                                color: policy.getColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PolicySection> _getAllPolicies() {
    return [
      PolicySection(
        icon: Icons.cancel_outlined,
        title: 'سياسة الإلغاء',
        subtitle: 'شروط وأحكام إلغاء الحجز',
        color: AppTheme.warning,
        items: [
          PolicyItem(
            icon: Icons.check_circle_outline,
            title: 'الإلغاء المجاني',
            description:
                'يمكنك إلغاء حجزك مجاناً قبل 48 ساعة من موعد تسجيل الوصول المحدد',
            additionalInfo: 'استرداد كامل',
            type: PolicyType.success,
          ),
          PolicyItem(
            icon: Icons.schedule,
            title: 'الإلغاء قبل 24 ساعة',
            description:
                'في حالة الإلغاء قبل 24 ساعة من الوصول، سيتم استرداد 75% من المبلغ المدفوع',
            additionalInfo: 'خصم 25%',
            type: PolicyType.warning,
          ),
          PolicyItem(
            icon: Icons.access_time,
            title: 'الإلغاء قبل 12 ساعة',
            description:
                'الإلغاء قبل 12 ساعة من الوصول يترتب عليه استرداد 50% فقط من المبلغ',
            additionalInfo: 'خصم 50%',
            type: PolicyType.warning,
          ),
          PolicyItem(
            icon: Icons.cancel,
            title: 'الإلغاء المتأخر',
            description:
                'لا يمكن استرداد أي مبلغ في حالة الإلغاء قبل أقل من 12 ساعة',
            additionalInfo: 'عدم الاسترداد',
            type: PolicyType.error,
          ),
          PolicyItem(
            icon: Icons.event_busy,
            title: 'عدم الحضور',
            description:
                'في حالة عدم الحضور دون إشعار مسبق، سيتم خصم كامل قيمة الحجز',
            additionalInfo: 'خصم 100%',
            type: PolicyType.error,
          ),
        ],
      ),
      PolicySection(
        icon: Icons.payment_outlined,
        title: 'سياسة الدفع',
        subtitle: 'طرق وشروط الدفع',
        color: AppTheme.primaryBlue,
        items: [
          PolicyItem(
            icon: Icons.payment,
            title: 'طرق الدفع المقبولة',
            description:
                'نقبل الدفع نقداً، بطاقات الائتمان والخصم، والمحافظ الإلكترونية المعتمدة',
            type: PolicyType.info,
          ),
          PolicyItem(
            icon: Icons.security,
            title: 'أمان المعاملات',
            description:
                'جميع المعاملات المالية محمية بتشفير SSL 256-bit وتتم عبر بوابات دفع آمنة',
            additionalInfo: 'معتمد PCI DSS',
            type: PolicyType.success,
          ),
          PolicyItem(
            icon: Icons.schedule_send,
            title: 'توقيت الدفع',
            description:
                'يجب إتمام الدفع الكامل عند تأكيد الحجز لضمان حجز العقار',
            type: PolicyType.warning,
          ),
          PolicyItem(
            icon: Icons.receipt_long,
            title: 'الفواتير والإيصالات',
            description:
                'ستتلقى فاتورة إلكترونية مفصلة عبر البريد الإلكتروني فور إتمام الدفع',
            type: PolicyType.info,
          ),
          PolicyItem(
            icon: Icons.replay,
            title: 'استرداد المدفوعات',
            description:
                'يتم معالجة المبالغ المستردة خلال 7-14 يوم عمل حسب طريقة الدفع الأصلية',
            additionalInfo: '7-14 يوم',
            type: PolicyType.warning,
          ),
        ],
      ),
      PolicySection(
        icon: Icons.rule_outlined,
        title: 'قوانين الإقامة',
        subtitle: 'قواعد وتعليمات العقار',
        color: AppTheme.primaryPurple,
        items: [
          PolicyItem(
            icon: Icons.login,
            title: 'تسجيل الوصول',
            description:
                'وقت تسجيل الوصول من الساعة 2:00 مساءً. يرجى التواصل مسبقاً للوصول المبكر',
            additionalInfo: '2:00 PM',
            type: PolicyType.info,
          ),
          PolicyItem(
            icon: Icons.logout,
            title: 'تسجيل المغادرة',
            description:
                'يجب تسجيل المغادرة قبل الساعة 12:00 ظهراً. التأخير قد يترتب عليه رسوم إضافية',
            additionalInfo: '12:00 PM',
            type: PolicyType.info,
          ),
          PolicyItem(
            icon: Icons.smoke_free,
            title: 'سياسة التدخين',
            description:
                'التدخين ممنوع منعاً باتاً في جميع الأماكن المغلقة. مخالفة هذه السياسة تترتب عليها غرامة',
            additionalInfo: 'ممنوع',
            type: PolicyType.error,
          ),
          PolicyItem(
            icon: Icons.pets,
            title: 'الحيوانات الأليفة',
            description:
                'غير مسموح باصطحاب الحيوانات الأليفة إلا بترتيب مسبق وقد تطبق رسوم إضافية',
            type: PolicyType.warning,
          ),
          PolicyItem(
            icon: Icons.volume_off,
            title: 'ساعات الهدوء',
            description:
                'يرجى احترام ساعات الهدوء من 10:00 مساءً حتى 8:00 صباحاً',
            additionalInfo: '10 PM - 8 AM',
            type: PolicyType.warning,
          ),
          PolicyItem(
            icon: Icons.people_outline,
            title: 'عدد الضيوف',
            description:
                'يجب عدم تجاوز العدد الأقصى للضيوف المحدد. ضيوف إضافيون يتطلبون موافقة مسبقة',
            type: PolicyType.info,
          ),
          PolicyItem(
            icon: Icons.cleaning_services,
            title: 'النظافة والصيانة',
            description:
                'يُتوقع من الضيوف المحافظة على نظافة العقار. أضرار إضافية قد تترتب عليها رسوم',
            type: PolicyType.info,
          ),
        ],
      ),
    ];
  }

  Widget _buildProfessionalFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Agreement Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.info.withOpacity(0.08),
                    AppTheme.info.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.info.withOpacity(0.8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'بإتمام الحجز، فإنك تقر بقراءة وفهم والموافقة على جميع الشروط والأحكام',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textLight.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (widget.propertyId != null &&
                    widget.propertyId!.isNotEmpty) ...[
                  Expanded(
                    child: _buildActionButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        context.push('/property/${widget.propertyId}');
                      },
                      label: 'عرض العقار',
                      icon: Icons.home_outlined,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _buildActionButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    label: 'موافق، فهمت',
                    icon: Icons.check,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.9),
                    AppTheme.primaryPurple.withOpacity(0.8),
                  ],
                )
              : null,
          color: isPrimary ? null : AppTheme.darkCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : AppTheme.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isPrimary ? Colors.white : AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantCloseButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

// Supporting Classes
class PolicySection {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<PolicyItem> items;

  PolicySection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
  });
}

enum PolicyType { success, warning, error, info }

class PolicyItem {
  final IconData icon;
  final String title;
  final String description;
  final String? additionalInfo;
  final PolicyType type;

  PolicyItem({
    required this.icon,
    required this.title,
    required this.description,
    this.additionalInfo,
    required this.type,
  });

  Color getColor() {
    switch (type) {
      case PolicyType.success:
        return AppTheme.success;
      case PolicyType.warning:
        return AppTheme.warning;
      case PolicyType.error:
        return AppTheme.error;
      case PolicyType.info:
        return AppTheme.info;
    }
  }
}
