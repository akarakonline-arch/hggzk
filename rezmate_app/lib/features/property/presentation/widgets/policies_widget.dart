// lib/features/property/presentation/widgets/policies_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:rezmate/features/property/domain/entities/property_policy.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PoliciesWidget extends StatefulWidget {
  final List<PropertyPolicy> policies;

  const PoliciesWidget({
    super.key,
    required this.policies,
  });

  @override
  State<PoliciesWidget> createState() => _PoliciesWidgetState();
}

class _PoliciesWidgetState extends State<PoliciesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, bool> _expandedPolicies = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePolicyStates();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  void _initializePolicyStates() {
    final groupedPolicies = _groupPoliciesByType();
    for (final type in groupedPolicies.keys) {
      _expandedPolicies[type] = true;
    }
  }

  Map<String, List<PropertyPolicy>> _groupPoliciesByType() {
    final groupedPolicies = <String, List<PropertyPolicy>>{};
    for (final policy in widget.policies) {
      final type = policy.policyType;
      if (!groupedPolicies.containsKey(type)) {
        groupedPolicies[type] = [];
      }
      groupedPolicies[type]!.add(policy);
    }
    return groupedPolicies;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.policies.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedPolicies = _groupPoliciesByType();
    final items = <_PolicyWithType>[];
    groupedPolicies.forEach((type, policies) {
      for (final policy in policies) {
        items.add(_PolicyWithType(type: type, policy: policy));
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPoliciesSectionTitle(),
          const SizedBox(height: 10),
          if (items.isNotEmpty) _buildPoliciesTimeline(items),
        ],
      ),
    );
  }

  Widget _buildPoliciesSectionTitle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سياسات العقار',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.9),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.45),
              width: 0.8,
            ),
          ),
          child: const Icon(
            Icons.policy_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPoliciesTimeline(List<_PolicyWithType> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.9),
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
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _buildUltraMinimalPolicyItem(
              items[i].policy,
              _getPolicyTypeColor(items[i].type),
              i == items.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildUltraMinimalPolicySection(
      String type, List<PropertyPolicy> policies) {
    final isExpanded = _expandedPolicies[type] ?? false;
    final typeColor = _getPolicyTypeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeColor.withOpacity(0.5),
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildMinimalPolicyHeader(type, typeColor, policies.length),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: isExpanded ? null : 0,
              padding: isExpanded
                  ? const EdgeInsets.only(top: 6, bottom: 10)
                  : EdgeInsets.zero,
              child:
                  isExpanded ? _buildMinimalPoliciesList(policies, typeColor) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalPolicyHeader(String type, Color color, int count) {
    final isExpanded = _expandedPolicies[type] ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedPolicies[type] = !isExpanded;
        });
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.6),
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPolicyTypeTitle(type),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite.withOpacity(0.98),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$count سياسة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.4),
                    color.withOpacity(0.15),
                  ],
                ),
              ),
              child: Icon(
                _getPolicyTypeIcon(type),
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: color.withOpacity(0.9),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalPoliciesList(
      List<PropertyPolicy> policies, Color typeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          for (int i = 0; i < policies.length; i++)
            _buildUltraMinimalPolicyItem(
              policies[i],
              typeColor,
              i == policies.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildUltraMinimalPolicyItem(
      PropertyPolicy policy, Color typeColor, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      typeColor.withOpacity(0.9),
                      typeColor.withOpacity(0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        typeColor.withOpacity(0.4),
                        typeColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: policy.isActive
                      ? typeColor.withOpacity(0.55)
                      : AppTheme.darkBorder.withOpacity(0.7),
                  width: 0.9,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkSurface.withOpacity(0.96),
                    policy.isActive
                        ? typeColor.withOpacity(0.24)
                        : AppTheme.darkCard.withOpacity(0.9),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: policy.isActive
                            ? [
                                typeColor.withOpacity(0.55),
                                typeColor.withOpacity(0.2),
                              ]
                            : [
                                AppTheme.darkBorder.withOpacity(0.7),
                                AppTheme.darkBorder.withOpacity(0.3),
                              ],
                      ),
                    ),
                    child: Icon(
                      _getPolicyIcon(policy.policyContent),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                policy.policyContent,
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      AppTheme.textWhite.withOpacity(0.98),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (policy.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppTheme.error.withOpacity(0.14),
                                ),
                                child: Text(
                                  'إلزامي',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.error.withOpacity(0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        if (!policy.isActive) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 10,
                                color:
                                    AppTheme.warning.withOpacity(0.65),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'غير مفعل',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.warning.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPolicyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
        return Icons.login;
      case 'checkout':
      case 'check-out':
        return Icons.logout;
      case 'cancellation':
        return Icons.cancel_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'house_rules':
      case 'rules':
        return Icons.rule;
      case 'safety':
        return Icons.security_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.policy_outlined;
    }
  }

  IconData _getPolicyIcon(String content) {
    final lowerContent = content.toLowerCase();
    if (lowerContent.contains('وقت') || lowerContent.contains('time'))
      return Icons.access_time;
    if (lowerContent.contains('دفع') || lowerContent.contains('payment'))
      return Icons.payment;
    if (lowerContent.contains('إلغاء') || lowerContent.contains('cancel'))
      return Icons.cancel;
    if (lowerContent.contains('تدخين') || lowerContent.contains('smoking'))
      return Icons.smoke_free;
    if (lowerContent.contains('حيوان') || lowerContent.contains('pet'))
      return Icons.pets;
    if (lowerContent.contains('حفلة') || lowerContent.contains('party'))
      return Icons.celebration;
    return Icons.check_circle_outline;
  }

  Color _getPolicyTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
      case 'checkout':
      case 'check-out':
        return AppTheme.info;
      case 'cancellation':
        return AppTheme.warning;
      case 'payment':
        return AppTheme.success;
      case 'house_rules':
      case 'rules':
        return AppTheme.primaryBlue;
      case 'safety':
      case 'health':
        return AppTheme.error;
      default:
        return AppTheme.primaryPurple;
    }
  }

  String _getPolicyTypeTitle(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
        return 'تسجيل الدخول';
      case 'checkout':
      case 'check-out':
        return 'تسجيل الخروج';
      case 'cancellation':
        return 'الإلغاء';
      case 'payment':
        return 'الدفع';
      case 'house_rules':
      case 'rules':
        return 'قوانين المكان';
      case 'safety':
        return 'السلامة';
      case 'health':
        return 'الصحة';
      default:
        return 'سياسات أخرى';
    }
  }
}

class _PolicyWithType {
  final String type;
  final PropertyPolicy policy;

  _PolicyWithType({
    required this.type,
    required this.policy,
  });
}

// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'package:rezmate/features/property/domain/entities/property_policy.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/theme/app_text_styles.dart';

// class PoliciesWidget extends StatefulWidget {
//   final List<PropertyPolicy> policies;

//   const PoliciesWidget({
//     super.key,
//     required this.policies,
//   });

//   @override
//   State<PoliciesWidget> createState() => _PoliciesWidgetState();
// }

// class _PoliciesWidgetState extends State<PoliciesWidget>
//     with SingleTickerProviderStateMixin {
//   final Map<String, bool> _expandedPolicies = {};
//   late AnimationController _fadeController;

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     )..forward();

//     final groupedPolicies = _groupPoliciesByType();
//     for (final type in groupedPolicies.keys) {
//       _expandedPolicies[type] = false;
//     }
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   Map<String, List<PropertyPolicy>> _groupPoliciesByType() {
//     final groupedPolicies = <String, List<PropertyPolicy>>{};
//     for (final policy in widget.policies) {
//       final type = policy.policyType;
//       if (!groupedPolicies.containsKey(type)) {
//         groupedPolicies[type] = [];
//       }
//       groupedPolicies[type]!.add(policy);
//     }
//     return groupedPolicies;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.policies.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     final groupedPolicies = _groupPoliciesByType();

//     return FadeTransition(
//       opacity: _fadeController,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: groupedPolicies.entries.map((entry) {
//             return _buildElegantPolicySection(entry.key, entry.value);
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildElegantPolicySection(
//       String type, List<PropertyPolicy> policies) {
//     final isExpanded = _expandedPolicies[type] ?? false;
//     final typeColor = _getPolicyTypeColor(type);

//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(milliseconds: 500),
//       curve: Curves.easeOutCubic,
//       builder: (context, value, child) {
//         return Transform.scale(
//           scale: 0.95 + (0.05 * value),
//           child: Opacity(
//             opacity: value,
//             child: Container(
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     typeColor.withOpacity(0.06),
//                     typeColor.withOpacity(0.02),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: typeColor.withOpacity(0.12),
//                   width: 1,
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                   child: Column(
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           setState(() {
//                             _expandedPolicies[type] = !isExpanded;
//                           });
//                         },
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(20),
//                         ),
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 44,
//                                 height: 44,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       typeColor.withOpacity(0.15),
//                                       typeColor.withOpacity(0.08),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   _getPolicyTypeIcon(type),
//                                   size: 22,
//                                   color: typeColor,
//                                 ),
//                               ),
//                               const SizedBox(width: 14),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       _getPolicyTypeTitle(type),
//                                       style: AppTextStyles.bodyMedium.copyWith(
//                                         color: AppTheme.textWhite,
//                                         fontWeight: FontWeight.w600,
//                                         
//                                         letterSpacing: -0.2,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 2),
//                                     Text(
//                                       '${policies.length} ${policies.length == 1 ? "سياسة" : "سياسات"}',
//                                       style: AppTextStyles.caption.copyWith(
//                                         color: AppTheme.textMuted,
//                                         
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               AnimatedRotation(
//                                 turns: isExpanded ? 0.5 : 0,
//                                 duration: const Duration(milliseconds: 300),
//                                 child: Container(
//                                   width: 32,
//                                   height: 32,
//                                   decoration: BoxDecoration(
//                                     color: typeColor.withOpacity(0.08),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Icon(
//                                     Icons.expand_more_rounded,
//                                     color: typeColor,
//                                     size: 20,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       AnimatedCrossFade(
//                         firstChild: const SizedBox.shrink(),
//                         secondChild: Container(
//                           padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                           child: Column(
//                             children: policies.map((policy) {
//                               return _buildElegantPolicyItem(policy, typeColor);
//                             }).toList(),
//                           ),
//                         ),
//                         crossFadeState: isExpanded
//                             ? CrossFadeState.showSecond
//                             : CrossFadeState.showFirst,
//                         duration: const Duration(milliseconds: 300),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildElegantPolicyItem(PropertyPolicy policy, Color typeColor) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: policy.isActive
//             ? AppTheme.darkCard.withOpacity(0.3)
//             : AppTheme.darkCard.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: policy.isActive
//               ? typeColor.withOpacity(0.12)
//               : AppTheme.darkBorder.withOpacity(0.08),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: policy.isActive
//                     ? [typeColor.withOpacity(0.12), typeColor.withOpacity(0.06)]
//                     : [
//                         AppTheme.textMuted.withOpacity(0.08),
//                         AppTheme.textMuted.withOpacity(0.04)
//                       ],
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               _getPolicyIcon(policy.policyContent),
//               size: 16,
//               color: policy.isActive ? typeColor : AppTheme.textMuted,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         policy.policyContent,
//                         style: AppTextStyles.bodySmall.copyWith(
//                           color: AppTheme.textWhite,
//                           fontWeight: FontWeight.w600,
//                           
//                         ),
//                       ),
//                     ),
//                     if (policy.isActive)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 3,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppTheme.error.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(
//                             color: AppTheme.error.withOpacity(0.2),
//                             width: 0.5,
//                           ),
//                         ),
//                         child: Text(
//                           'إلزامي',
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppTheme.error,
//                             
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   policy.description,
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppTheme.textMuted,
//                     
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getPolicyTypeIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'checkin':
//       case 'check-in':
//         return Icons.login_rounded;
//       case 'checkout':
//       case 'check-out':
//         return Icons.logout_rounded;
//       case 'cancellation':
//         return Icons.cancel_rounded;
//       case 'payment':
//         return Icons.payment_rounded;
//       case 'house_rules':
//       case 'rules':
//         return Icons.rule_rounded;
//       case 'safety':
//         return Icons.security_rounded;
//       case 'health':
//         return Icons.health_and_safety_rounded;
//       default:
//         return Icons.policy_rounded;
//     }
//   }

//   IconData _getPolicyIcon(String content) {
//     final lowerContent = content.toLowerCase();
//     if (lowerContent.contains('وقت') || lowerContent.contains('time'))
//       return Icons.access_time_rounded;
//     if (lowerContent.contains('دفع') || lowerContent.contains('payment'))
//       return Icons.payment_rounded;
//     if (lowerContent.contains('إلغاء') || lowerContent.contains('cancel'))
//       return Icons.cancel_rounded;
//     if (lowerContent.contains('تدخين') || lowerContent.contains('smoking'))
//       return Icons.smoke_free_rounded;
//     if (lowerContent.contains('حيوان') || lowerContent.contains('pet'))
//       return Icons.pets_rounded;
//     if (lowerContent.contains('حفلة') || lowerContent.contains('party'))
//       return Icons.celebration_rounded;
//     return Icons.check_circle_rounded;
//   }

//   Color _getPolicyTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'checkin':
//       case 'check-in':
//       case 'checkout':
//       case 'check-out':
//         return AppTheme.info;
//       case 'cancellation':
//         return AppTheme.warning;
//       case 'payment':
//         return AppTheme.success;
//       case 'house_rules':
//       case 'rules':
//         return AppTheme.primaryBlue;
//       case 'safety':
//       case 'health':
//         return AppTheme.error;
//       default:
//         return AppTheme.primaryPurple;
//     }
//   }

//   String _getPolicyTypeTitle(String type) {
//     switch (type.toLowerCase()) {
//       case 'checkin':
//       case 'check-in':
//         return 'تسجيل الدخول';
//       case 'checkout':
//       case 'check-out':
//         return 'تسجيل الخروج';
//       case 'cancellation':
//         return 'الإلغاء والاسترداد';
//       case 'payment':
//         return 'الدفع والحجز';
//       case 'house_rules':
//       case 'rules':
//         return 'قوانين المكان';
//       case 'safety':
//         return 'السلامة والأمان';
//       case 'health':
//         return 'الصحة والنظافة';
//       default:
//         return 'سياسات أخرى';
//     }
//   }
// }
