import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/activity_plan_item.dart';
import '../providers/activity_providers.dart';

class ActivityPlanListPage extends ConsumerWidget {
  const ActivityPlanListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final theme = Theme.of(context);

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agenda de Atividades')),
        body: const OldyEmptyState(
          icon: Icons.event_note_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente primeiro',
        ),
      );
    }

    final plansAsync = ref.watch(activityPlansProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Atividades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activities/plan-create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: plansAsync.when(
        loading: () => const OldyLoading(message: 'Carregando agenda...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return OldyEmptyState(
              icon: Icons.event_note_outlined,
              title: 'Nenhuma atividade programada',
              subtitle:
                  'Programe atividades recorrentes como banho, refeições, fisioterapia',
              actionLabel: 'Adicionar',
              onAction: () => context.push('/activities/plan-create'),
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: plans.length,
            separatorBuilder: (_, __) => AppSpacing.verticalSm,
            itemBuilder: (_, index) => _ActivityPlanTile(
              item: plans[index],
              patientId: patientId,
              theme: theme,
            ),
          );
        },
      ),
    );
  }
}

class _ActivityPlanTile extends ConsumerStatefulWidget {
  final ActivityPlanItem item;
  final String patientId;
  final ThemeData theme;

  const _ActivityPlanTile({
    required this.item,
    required this.patientId,
    required this.theme,
  });

  @override
  ConsumerState<_ActivityPlanTile> createState() => _ActivityPlanTileState();
}

class _ActivityPlanTileState extends ConsumerState<_ActivityPlanTile> {
  Timer? _timer;
  String? _nextTimeStr;
  String _countdownStr = '';

  @override
  void initState() {
    super.initState();
    _computeCountdown();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _computeCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _computeCountdown() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final item = widget.item;

    if (item.frequencyType == 'weekly' &&
        !item.daysOfWeek.contains(now.weekday)) {
      setState(() {
        _nextTimeStr = null;
        _countdownStr = _nextWeekdayLabel(item, now);
      });
      return;
    }

    final times = _allTimesToday(item, today);
    DateTime? nextTime;
    for (final t in times) {
      if (t.isAfter(now)) {
        nextTime = t;
        break;
      }
    }

    if (nextTime == null && item.frequencyType != 'weekly') {
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowTimes = _allTimesToday(item, tomorrow);
      if (tomorrowTimes.isNotEmpty) nextTime = tomorrowTimes.first;
    }

    setState(() {
      if (nextTime != null) {
        _nextTimeStr =
            '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';
        final diff = nextTime.difference(now);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        _countdownStr = h > 0 ? 'em ${h}h${m > 0 ? '${m}min' : ''}' : 'em ${m}min';
      } else {
        _nextTimeStr = null;
        _countdownStr = 'Concluído hoje';
      }
    });
  }

  String _nextWeekdayLabel(ActivityPlanItem item, DateTime now) {
    const names = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    for (int i = 1; i <= 7; i++) {
      final day = (now.weekday + i - 1) % 7 + 1;
      if (item.daysOfWeek.contains(day)) return 'Próximo: ${names[day]}';
    }
    return '';
  }

  List<DateTime> _allTimesToday(ActivityPlanItem plan, DateTime day) {
    final results = <DateTime>[];
    if (plan.frequencyType == 'fixed' || plan.frequencyType == 'weekly') {
      for (final t in plan.scheduledTimes) {
        final parts = t.split(':');
        if (parts.length < 2) continue;
        results.add(DateTime(
          day.year, day.month, day.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        ));
      }
    } else if (plan.frequencyType == 'interval') {
      final hours = plan.intervalHours ?? 4;
      final baseHour = plan.scheduledTimes.isNotEmpty
          ? int.tryParse(plan.scheduledTimes.first.split(':').first) ?? 8
          : 8;
      var current = DateTime(day.year, day.month, day.day, baseHour);
      final endOfDay = day.add(const Duration(days: 1));
      while (current.isBefore(endOfDay)) {
        results.add(current);
        current = current.add(Duration(hours: hours));
      }
    }
    results.sort();
    return results;
  }

  IconData _categoryIcon(String category) => switch (category) {
        'Banho' => Icons.bathtub_outlined,
        'Alimentação' => Icons.restaurant_outlined,
        'Fisioterapia' => Icons.accessibility_new_outlined,
        'Hemodiálise' => Icons.bloodtype_outlined,
        'Exercício' => Icons.fitness_center_outlined,
        'Visita médica' => Icons.local_hospital_outlined,
        'Visita familiar' => Icons.family_restroom_outlined,
        _ => Icons.event_note_outlined,
      };

  String _frequencyLabel(ActivityPlanItem item) {
    if (item.frequencyType == 'interval') {
      return 'A cada ${item.intervalHours ?? 4}h';
    }
    if (item.frequencyType == 'weekly') {
      const names = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final days = item.daysOfWeek.map((d) => names[d]).join(', ');
      return days;
    }
    final count = item.scheduledTimes.length;
    return '$count×/dia';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar atividade?'),
        content: Text(
            'Tem certeza que deseja remover "${widget.item.activityName}" da agenda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(activityRepositoryProvider)
                  .deleteActivityPlan(widget.patientId, widget.item.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final item = widget.item;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push('/activities/plan-create', extra: item),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D47A1).withValues(alpha: 0.3)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      _categoryIcon(item.category),
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : const Color(0xFF1565C0),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.activityName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          item.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_nextTimeStr != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _nextTimeStr!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _countdownStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ] else if (_countdownStr.isNotEmpty) ...[
                    Text(
                      _countdownStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'delete') _confirmDelete(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          title: Text('Apagar',
                              style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: _frequencyLabel(item),
                    theme: theme,
                  ),
                  if (item.scheduledTimes.isNotEmpty)
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: item.scheduledTimes.join(', '),
                      theme: theme,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
