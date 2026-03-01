import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_log.dart';
import '../providers/health_providers.dart';

class HealthMetricDetailPage extends ConsumerWidget {
  final String metricType;

  const HealthMetricDetailPage({super.key, required this.metricType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = HealthMetricType.values.byName(metricType);
    final planAsync = ref.watch(healthPlanProvider);
    final logsAsync = ref.watch(healthLogsProvider(metricType));
    final theme = Theme.of(context);

    final metric = planAsync.valueOrNull
        ?.where((m) => m.metricType == type)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Novo registro',
            onPressed: () =>
                context.push('/health/new-record?metric=$metricType'),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const OldyLoading(message: 'Carregando dados...'),
        error: (error, _) => OldyErrorWidget(
          message: 'Erro ao carregar registros',
          onRetry: () => ref.invalidate(healthLogsProvider(metricType)),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 64,
                    color: type.color.withValues(alpha: 0.3),
                  ),
                  AppSpacing.verticalLg,
                  Text(
                    'Nenhum registro encontrado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.verticalXl,
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/health/new-record?metric=$metricType',
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar registro'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: AppSpacing.paddingScreen,
            children: [
              _ChartSection(
                logs: logs,
                type: type,
                targetMin: metric?.targetMin ?? type.defaultMin,
                targetMax: metric?.targetMax ?? type.defaultMax,
              ),
              AppSpacing.verticalXxl,
              Text(
                'Registros recentes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.verticalMd,
              ...logs.map((log) => _LogTile(log: log, type: type)),
              AppSpacing.verticalXxxl,
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/health/new-record?metric=$metricType'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo registro'),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final List<HealthLog> logs;
  final HealthMetricType type;
  final double targetMin;
  final double targetMax;

  const _ChartSection({
    required this.logs,
    required this.type,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentLogs = logs
        .where((l) =>
            l.measuredAt.isAfter(thirtyDaysAgo) && l.primaryValue != null)
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (recentLogs.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Sem dados nos últimos 30 dias',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final spots = recentLogs.map((log) {
      final dayOffset =
          log.measuredAt.difference(thirtyDaysAgo).inHours / 24.0;
      return FlSpot(dayOffset, log.primaryValue!);
    }).toList();

    final allValues = recentLogs.map((l) => l.primaryValue!).toList();
    final dataMin = allValues.reduce((a, b) => a < b ? a : b);
    final dataMax = allValues.reduce((a, b) => a > b ? a : b);
    var chartMin =
        [dataMin, targetMin].reduce((a, b) => a < b ? a : b) * 0.9;
    var chartMax =
        [dataMax, targetMax].reduce((a, b) => a > b ? a : b) * 1.1;

    if (chartMax - chartMin < 1) {
      final center = (chartMax + chartMin) / 2;
      chartMin = center - 5;
      chartMax = center + 5;
    }

    final gridInterval = ((chartMax - chartMin) / 4).clamp(1.0, 1000.0);

    return Card(
      elevation: AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos 30 dias',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.verticalLg,
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 30,
                  minY: chartMin,
                  maxY: chartMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: type.color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: type.color,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: type.color.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: targetMin,
                        color: AppColors.warning.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                      HorizontalLine(
                        y: targetMax,
                        color: AppColors.warning.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > 30) {
                            return const SizedBox.shrink();
                          }
                          final date = thirtyDaysAgo.add(
                            Duration(hours: (value * 24).toInt()),
                          );
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormatters.dateShort(date),
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: gridInterval,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: gridInterval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          theme.colorScheme.inverseSurface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = thirtyDaysAgo.add(
                            Duration(hours: (spot.x * 24).toInt()),
                          );
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} ${type.unit}\n',
                            TextStyle(
                              color:
                                  theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: DateFormatters.dateShort(date),
                                style: TextStyle(
                                  color: theme
                                      .colorScheme.onInverseSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final HealthLog log;
  final HealthMetricType type;

  const _LogTile({required this.log, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(color: theme.dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              log.source == HealthLogSource.manual
                  ? Icons.edit_outlined
                  : Icons.phone_android_outlined,
              size: AppSpacing.iconSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${log.displayValue} ${type.unit}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    AppSpacing.verticalXs,
                    Text(
                      log.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              DateFormatters.relative(log.measuredAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
