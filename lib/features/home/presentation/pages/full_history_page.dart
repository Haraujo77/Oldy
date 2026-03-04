import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../activities/domain/entities/activity_post.dart';
import '../../../health/domain/entities/health_log.dart';
import '../../../medications/domain/entities/dose_event.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/history_item.dart';
import '../providers/history_providers.dart';

class FullHistoryPage extends ConsumerWidget {
  const FullHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patientId = ref.watch(selectedPatientIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico completo')),
      body: patientId == null
          ? const Center(child: Text('Nenhum paciente selecionado'))
          : _HistoryBody(patientId: patientId, theme: theme),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _HistoryBody({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(recentHistoryProvider(patientId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
            AppSpacing.verticalMd,
            const Text('Erro ao carregar histórico'),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4)),
                AppSpacing.verticalMd,
                Text('Nenhum registro ainda',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          );
        }

        final grouped = _groupByDay(items);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped[index];
            return _DaySection(
              label: entry.label,
              items: entry.items,
              theme: theme,
              patientId: patientId,
            );
          },
        );
      },
    );
  }

  List<_DayGroup> _groupByDay(List<HistoryItem> items) {
    final groups = <String, List<HistoryItem>>{};
    final order = <String>[];

    for (final item in items) {
      final key = _dayKey(item.timestamp);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(item);
    }

    return order.map((key) {
      return _DayGroup(label: _dayLabel(key), items: groups[key]!);
    }).toList();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _dayLabel(String key) {
    final dt = DateTime.parse(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    return DateFormatters.dayMonth(dt);
  }
}

class _DayGroup {
  final String label;
  final List<HistoryItem> items;
  const _DayGroup({required this.label, required this.items});
}

class _DaySection extends StatelessWidget {
  final String label;
  final List<HistoryItem> items;
  final ThemeData theme;
  final String patientId;

  const _DaySection({
    required this.label,
    required this.items,
    required this.theme,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) => _HistoryTile(item: item, theme: theme, patientId: patientId)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final ThemeData theme;
  final String patientId;

  const _HistoryTile({required this.item, required this.theme, required this.patientId});

  Color _tileColor() {
    final isDark = theme.brightness == Brightness.dark;
    if (item.iconColor != null) {
      return item.iconColor!.withValues(alpha: isDark ? 0.25 : 0.15);
    }
    return switch (item.type) {
      HistoryItemType.activity =>
        isDark ? const Color(0xFF0D47A1).withValues(alpha: 0.25) : const Color(0xFFE3F2FD),
      HistoryItemType.healthLog =>
        theme.colorScheme.secondaryContainer,
      HistoryItemType.doseEvent =>
        isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.25) : const Color(0xFFE8F5E9),
    };
  }

  Color _iconColor() {
    if (item.iconColor != null) return item.iconColor!;
    final isDark = theme.brightness == Brightness.dark;
    return switch (item.type) {
      HistoryItemType.activity =>
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
      HistoryItemType.healthLog =>
        theme.colorScheme.secondary,
      HistoryItemType.doseEvent =>
        isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32),
    };
  }

  String _typeChip() => switch (item.type) {
        HistoryItemType.activity => 'Atividade',
        HistoryItemType.healthLog => 'Saúde',
        HistoryItemType.doseEvent => 'Medicamento',
      };

  void _onTap(BuildContext context) {
    switch (item.type) {
      case HistoryItemType.activity:
        final post = item.data as ActivityPost;
        context.push('/activities/${post.id}', extra: post);
      case HistoryItemType.healthLog:
        final log = item.data as HealthLog;
        context.push('/health/metric/${log.metricType.name}');
      case HistoryItemType.doseEvent:
        final dose = item.data as DoseEvent;
        context.push('/medications/detail/${dose.medPlanId}?patientId=$patientId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _tileColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 18, color: _iconColor()),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.horizontalSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _tileColor(),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            _typeChip(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _iconColor(),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              AppSpacing.horizontalSm,
              Text(
                DateFormatters.time(item.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
