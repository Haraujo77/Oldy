import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_log.dart';
import '../providers/health_providers.dart';

class HealthOverviewPage extends ConsumerWidget {
  const HealthOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(healthPlanProvider);
    final logsAsync = ref.watch(healthLogsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saúde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar plano',
            onPressed: () => context.push('/health/plan-config'),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const OldyLoading(message: 'Carregando métricas...'),
        error: (error, _) => OldyErrorWidget(
          message: 'Erro ao carregar métricas',
          onRetry: () => ref.invalidate(healthPlanProvider),
        ),
        data: (metrics) {
          if (metrics.isEmpty) {
            return OldyEmptyState(
              icon: Icons.monitor_heart_outlined,
              title: 'Nenhuma métrica configurada',
              subtitle:
                  'Configure o plano de saúde para começar a monitorar',
              actionLabel: 'Configurar plano',
              onAction: () => context.push('/health/plan-config'),
            );
          }

          final logs = logsAsync.valueOrNull ?? [];
          final latestByType = <HealthMetricType, HealthLog>{};
          for (final log in logs) {
            latestByType.putIfAbsent(log.metricType, () => log);
          }

          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: metrics.length,
            separatorBuilder: (_, _) => AppSpacing.verticalMd,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              final lastLog = latestByType[metric.metricType];
              return _MetricCard(
                metric: metric,
                lastLog: lastLog,
                onTap: () => context.push(
                  '/health/metric/${metric.metricType.name}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: planAsync.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/health/new-record'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo registro'),
            )
          : null,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final HealthMetric metric;
  final HealthLog? lastLog;
  final VoidCallback onTap;

  const _MetricCard({
    required this.metric,
    required this.lastLog,
    required this.onTap,
  });

  bool get _isInRange {
    final value = lastLog?.primaryValue;
    if (value == null) return true;
    final min = metric.targetMin ?? metric.metricType.defaultMin;
    final max = metric.targetMax ?? metric.metricType.defaultMax;
    return value >= min && value <= max;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inRange = _isInRange;
    final statusColor = lastLog == null
        ? AppColors.neutral400
        : inRange
            ? AppColors.success
            : AppColors.error;

    return Card(
      elevation: AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: metric.metricType.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  metric.metricType.icon,
                  color: metric.metricType.color,
                  size: AppSpacing.iconMd,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.metricType.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    AppSpacing.verticalXs,
                    if (lastLog != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            lastLog!.displayValue,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          AppSpacing.horizontalXs,
                          Text(
                            metric.metricType.unit,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Sem registros',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (lastLog != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: inRange
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        inRange ? 'Normal' : 'Atenção',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      DateFormatters.relative(lastLog!.measuredAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              AppSpacing.horizontalXs,
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
