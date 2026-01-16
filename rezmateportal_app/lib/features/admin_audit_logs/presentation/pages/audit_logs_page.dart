// lib/features/admin_audit_logs/presentation/pages/audit_logs_page.dart

import 'package:rezmateportal/features/admin_audit_logs/domain/entities/audit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../bloc/audit_logs_bloc.dart';
import '../bloc/audit_logs_event.dart';
import '../bloc/audit_logs_state.dart';
import '../widgets/futuristic_audit_log_card.dart';
import '../widgets/futuristic_audit_logs_table.dart';
import '../widgets/audit_log_filters_widget.dart';
import '../widgets/audit_log_timeline_widget.dart';
import '../widgets/activity_chart_widget.dart';
import '../widgets/audit_log_stats_card.dart';
import '../widgets/audit_log_details_dialog.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _isGridView = false;
  bool _showFilters = false;
  bool _showTimeline = false;
  bool _showCharts = false;
  AuditLogFilters? _activeFilters;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tabController = TabController(length: 3, vsync: this);
    _loadAuditLogs();
    _setupScrollListener();
  }

  void _loadAuditLogs() {
    context.read<AuditLogsBloc>().add(
          LoadAuditLogsEvent(
            query: AuditLogsQuery(
              pageNumber: 1,
              pageSize: 20,
              from: DateTime.now().subtract(const Duration(days: 30)),
              to: DateTime.now(),
            ),
          ),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<AuditLogsBloc>().state;
        if (state is AuditLogsLoaded && !state.hasReachedMax) {
          context.read<AuditLogsBloc>().add(const LoadMoreAuditLogsEvent());
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(),
          if (_showCharts) _buildChartsSection(),
          _buildStatsSection(),
          _buildFilterSection(),
          if (_showTimeline) _buildTimelineSection() else _buildLogsList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'سجل الأنشطة',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withValues(alpha: 0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildActionButton(
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        _buildActionButton(
          icon: _showTimeline ? CupertinoIcons.list_dash : CupertinoIcons.time,
          onPressed: () => setState(() => _showTimeline = !_showTimeline),
          isActive: _showTimeline,
        ),
        _buildActionButton(
          icon: _showCharts
              ? CupertinoIcons.xmark_circle
              : CupertinoIcons.chart_bar_alt_fill,
          onPressed: () => setState(() => _showCharts = !_showCharts),
          isActive: _showCharts,
        ),
        _buildActionButton(
          icon: _showFilters
              ? CupertinoIcons.xmark
              : CupertinoIcons.slider_horizontal_3,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        _buildExportButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryPurple.withValues(alpha: 0.2)
            : AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryPurple.withValues(alpha: 0.5)
              : AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primaryPurple : AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withValues(alpha: 0.2),
                      AppTheme.neonGreen.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withValues(
                      alpha: 0.3 + (_pulseAnimationController.value * 0.2),
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(
                        alpha: 0.1 * _pulseAnimationController.value,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleExport,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.square_arrow_down,
                        color: AppTheme.success,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
        builder: (context, state) {
          if (state is! AuditLogsLoaded) return const SizedBox.shrink();

          return AnimationLimiter(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: ActivityChartWidget(
                auditLogs: state.auditLogs,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
        builder: (context, state) {
          if (state is! AuditLogsLoaded) return const SizedBox.shrink();

          return AnimationLimiter(
            child: Container(
              height: 130,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AuditLogStatsCard(
                auditLogs: state.auditLogs,
                totalCount: state.totalCount,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showFilters ? 180 : 0,
        child: _showFilters
            ? AuditLogFiltersWidget(
                initialFilters: _activeFilters,
                onFiltersChanged: (filters) {
                  setState(() => _activeFilters = filters);
                  context.read<AuditLogsBloc>().add(
                        FilterAuditLogsEvent(
                          userId: filters.userId,
                          from: filters.startDate,
                          to: filters.endDate,
                          operationType: filters.operationType,
                          searchTerm: filters.searchTerm,
                        ),
                      );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
        builder: (context, state) {
          if (state is AuditLogsLoading) {
            return const SizedBox(
              height: 400,
              child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل السجل...',
              ),
            );
          }

          if (state is AuditLogsError) {
            return SizedBox(
              height: 400,
              child: CustomErrorWidget(
                message: state.message,
                onRetry: _loadAuditLogs,
              ),
            );
          }

          if (state is AuditLogsLoaded) {
            if (state.auditLogs.isEmpty) {
              return const SizedBox(
                height: 400,
                child: EmptyWidget(
                  message: 'لا توجد سجلات حالياً',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: AuditLogTimelineWidget(
                auditLogs: state.auditLogs,
                onLogTap: (log) => _showLogDetails(log),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLogsList() {
    return BlocBuilder<AuditLogsBloc, AuditLogsState>(
      builder: (context, state) {
        if (state is AuditLogsLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل السجلات...',
            ),
          );
        }

        if (state is AuditLogsError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadAuditLogs,
            ),
          );
        }

        if (state is AuditLogsLoaded) {
          if (state.auditLogs.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد سجلات حالياً',
              ),
            );
          }

          return _isGridView ? _buildGridView(state) : _buildTableView(state);
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildGridView(AuditLogsLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1, // 🎯 تم تعديل النسبة لتناسب المحتوى بشكل أفضل
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final log = state.auditLogs[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: FuturisticAuditLogCard(
                    auditLog: log,
                    onTap: () => _showLogDetails(log),
                    isGridView: true, // 🎯 تمرير معامل العرض الشبكي
                  ),
                ),
              ),
            );
          },
          childCount: state.auditLogs.length,
        ),
      ),
    );
  }

  Widget _buildTableView(AuditLogsLoaded state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FuturisticAuditLogsTable(
          auditLogs: state.auditLogs,
          onLogTap: (log) => _showLogDetails(log),
        ),
      ),
    );
  }

  void _showLogDetails(AuditLog log) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => AuditLogDetailsDialog(auditLog: log),
    );
  }

  void _handleExport() {
    final state = context.read<AuditLogsBloc>().state;
    if (state is AuditLogsLoaded) {
      context.read<AuditLogsBloc>().add(
            ExportAuditLogsEvent(query: state.currentQuery),
          );
    }
  }
}
