import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/goal_contribution_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/goals_controller.dart';
import '../widgets/goal_contribution_sheet.dart';
import '../widgets/goal_transfer_sheet.dart';

class GoalDetailsView extends StatefulWidget {
  const GoalDetailsView({super.key});

  @override
  State<GoalDetailsView> createState() => _GoalDetailsViewState();
}

class _GoalDetailsViewState extends State<GoalDetailsView> {
  late final GoalsController _controller = Get.find<GoalsController>();
  late final int _goalId = _parseGoalId(Get.arguments);
  late Future<List<GoalContributionModel>> _contributionsFuture;

  @override
  void initState() {
    super.initState();
    _contributionsFuture = _controller.loadContributions(_goalId);
  }

  int _parseGoalId(dynamic args) {
    if (args is int) return args;
    if (args is Map && args['goalId'] is int) {
      return args['goalId'] as int;
    }
    throw ArgumentError('Goal id is required to open GoalDetailsView');
  }

  void _refreshContributions() {
    setState(() {
      _contributionsFuture = _controller.loadContributions(_goalId);
    });
  }

  Future<void> _handleRefresh() async {
    await _controller.fetchGoals();
    _refreshContributions();
    await _contributionsFuture;
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'goals.details.info.title'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'goals.details.info.body'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('goals.details.title'.tr),
        actions: [
          Obx(() {
            final goal = _controller.goalById(_goalId);
            final canTransfer =
                goal != null && goal.walletId == null && goal.isCompleted;
            if (!canTransfer) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'goals.transfer.button'.tr,
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => showGoalTransferSheet(
                context: context,
                controller: _controller,
                goal: goal!,
                onSuccess: _refreshContributions,
              ),
            );
          }),
          IconButton(
            tooltip: 'goals.details.info.tooltip'.tr,
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoSheet,
          ),
        ],
      ),
      body: Obx(() {
        final goal = _controller.goalById(_goalId);
        if (goal == null) {
          return Center(
            child: Text('goals.details.goal_missing'.tr),
          );
        }
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: FutureBuilder<List<GoalContributionModel>>(
            future: _contributionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 160),
                  children: const [
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              final contributions =
                  snapshot.data ?? const <GoalContributionModel>[];
              final wallet = _controller.walletForId(goal.walletId);
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _GoalSummaryCard(
                    goal: goal,
                    contributionsCount: contributions.length,
                    walletName: wallet?.name,
                    onAddContribution: () => showGoalContributionSheet(
                      context: context,
                      controller: _controller,
                      goal: goal,
                      onCompleted: _refreshContributions,
                    ),
                    onTransferSavings: () => showGoalTransferSheet(
                      context: context,
                      controller: _controller,
                      goal: goal,
                      onSuccess: () {
                        _refreshContributions();
                      },
                    ),
                    onOpenCelebration: () => Get.toNamed(
                      AppRoutes.goalCelebration,
                      arguments: {
                        'goalId': goal.id,
                        'goalName': goal.name,
                        'targetAmount': goal.targetAmount,
                        'currency': goal.currency,
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GoalProgressChart(
                    goal: goal,
                    contributions: contributions,
                  ),
                  const SizedBox(height: 16),
                  _GoalContributionTimeline(
                    contributions: contributions,
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.contributionsCount,
    required this.walletName,
    required this.onAddContribution,
    this.onTransferSavings,
    this.onOpenCelebration,
  });

  final GoalModel goal;
  final int contributionsCount;
  final String? walletName;
  final VoidCallback onAddContribution;
  final VoidCallback? onTransferSavings;
  final VoidCallback? onOpenCelebration;

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.currentAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final progress = goal.progress.clamp(0.0, 1.0).toDouble();
    final isTransferred = goal.walletId != null;
    final walletStatus = goal.walletId == null
        ? 'goals.wallet.pending'.tr
        : 'goals.wallet.created'.trParams({
            'name': walletName ?? '—',
          });
    final isCompleted = goal.isCompleted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'goals.details.deadline'.trParams({
                          'date': Formatters.shortDate(goal.deadline),
                        }),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: isCompleted
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.secondary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isCompleted ? AppColors.success : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                  label: Text(
                    isCompleted
                        ? 'goals.status.completed'.tr
                        : 'goals.status.in_progress'.tr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: Colors.grey.shade200,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _SummaryValue(
                  label: 'goals.details.target'.tr,
                  value: Formatters.currency(
                    goal.targetAmount,
                    symbol: goal.currency,
                  ),
                ),
                _SummaryValue(
                  label: 'goals.details.current'.tr,
                  value: Formatters.currency(
                    goal.currentAmount,
                    symbol: goal.currency,
                  ),
                ),
                _SummaryValue(
                  label: 'goals.details.remaining'.tr,
                  value: Formatters.currency(
                    remaining,
                    symbol: goal.currency,
                  ),
                ),
                _SummaryValue(
                  label: 'goals.details.contributions'.tr,
                  value: 'common.operations_count'.trParams({
                    'count': contributionsCount.toString(),
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              walletStatus,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isTransferred)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'goals.transfer.archived'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
            if (isCompleted && !isTransferred) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTransferSavings,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text('goals.transfer.button'.tr),
                ),
              ),
              TextButton(
                onPressed: onOpenCelebration,
                child: Text('goals.celebration.button.open'.tr),
              ),
            ] else if (isCompleted && isTransferred) ...[
              TextButton(
                onPressed: onOpenCelebration,
                child: Text('goals.celebration.button.open'.tr),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddContribution,
                  icon: const Icon(Icons.savings_outlined),
                  label: Text('goals.contribution.add'.tr),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressChart extends StatelessWidget {
  const _GoalProgressChart({
    required this.goal,
    required this.contributions,
  });

  final GoalModel goal;
  final List<GoalContributionModel> contributions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'goals.details.chart.title'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            contributions.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'goals.details.chart.empty'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 220,
                    child: _GoalLineChart(
                      target: goal.targetAmount,
                      contributions: contributions,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _GoalLineChart extends StatelessWidget {
  const _GoalLineChart({
    required this.target,
    required this.contributions,
  });

  final double target;
  final List<GoalContributionModel> contributions;

  @override
  Widget build(BuildContext context) {
    final sorted = [...contributions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final baseDate = sorted.first.createdAt;
    var running = 0.0;
    double? lastX;
    final spots = <FlSpot>[];
    for (final entry in sorted) {
      var delta = entry.createdAt.difference(baseDate).inHours / 24.0;
      if (lastX != null && delta <= lastX!) {
        delta = lastX! + 0.25;
      }
      running += entry.amount;
      spots.add(FlSpot(delta, running));
      lastX = delta;
    }
    final yMax = ([
          target,
          running,
        ].reduce((a, b) => a > b ? a : b) *
            1.1)
        .clamp(1, double.infinity)
        .toDouble();
    final xMax = spots.isEmpty ? 1.0 : (spots.last.x + 0.5);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: xMax,
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.6,
          ),
          horizontalInterval: yMax / 4,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (spots.isEmpty) return const SizedBox.shrink();
                if (value == spots.first.x) {
                  return Text(
                    Formatters.compactDate(sorted.first.createdAt),
                    style: const TextStyle(fontSize: 11),
                  );
                }
                if ((value - spots.last.x).abs() < 0.3) {
                  return Text(
                    Formatters.compactDate(sorted.last.createdAt),
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black.withOpacity(0.7),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spots.indexOf(spot);
                final entry = sorted[index];
                return LineTooltipItem(
                  '${Formatters.compactDate(entry.createdAt)}\n'
                  '${Formatters.currency(spot.y)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            spots: spots,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withOpacity(0.15),
            ),
          ),
          if (target > 0 && spots.isNotEmpty)
            LineChartBarData(
              isCurved: false,
              color: AppColors.primary.withOpacity(0.6),
              barWidth: 2,
              dashArray: [6, 4],
              spots: [
                FlSpot(0, target),
                FlSpot(spots.last.x, target),
              ],
            ),
        ],
      ),
    );
  }
}

class _GoalContributionTimeline extends StatelessWidget {
  const _GoalContributionTimeline({
    required this.contributions,
  });

  final List<GoalContributionModel> contributions;

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('hh:mm a');
    final sorted = [...contributions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'goals.details.timeline.title'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'goals.details.timeline.count'.trParams({
                    'count': contributions.length.toString(),
                  }),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'goals.details.timeline.empty'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = sorted[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.15),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      Formatters.currency(entry.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Formatters.shortDate(entry.createdAt)} • ${timeFormatter.format(entry.createdAt)}',
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Text(
                            entry.note!,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
