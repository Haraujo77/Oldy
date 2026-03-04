import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/med_plan_item.dart';
import '../providers/medication_providers.dart';

class MedPlanListPage extends ConsumerWidget {
  const MedPlanListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final theme = Theme.of(context);

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plano de Medicamentos')),
        body: const OldyEmptyState(
          icon: Icons.medication_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente primeiro',
        ),
      );
    }

    final plansAsync = ref.watch(medPlanProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Plano de Medicamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/medications/create?patientId=$patientId'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: plansAsync.when(
        loading: () => const OldyLoading(message: 'Carregando medicamentos...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return OldyEmptyState(
              icon: Icons.medication_outlined,
              title: 'Nenhum medicamento cadastrado',
              subtitle: 'Adicione o primeiro medicamento ao plano',
              actionLabel: 'Adicionar',
              onAction: () => context.push('/medications/create?patientId=$patientId'),
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: plans.length,
            separatorBuilder: (_, __) => AppSpacing.verticalSm,
            itemBuilder: (_, index) => _MedPlanTile(
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

class _MedPlanTile extends StatefulWidget {
  final MedPlanItem item;
  final String patientId;
  final ThemeData theme;

  const _MedPlanTile({
    required this.item,
    required this.patientId,
    required this.theme,
  });

  @override
  State<_MedPlanTile> createState() => _MedPlanTileState();
}

class _MedPlanTileState extends State<_MedPlanTile> {
  Timer? _timer;
  Duration _nextDoseIn = Duration.zero;
  String? _nextDoseTime;

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
    final times = _allTimesToday(widget.item, today);

    DateTime? nextDose;
    for (final t in times) {
      if (t.isAfter(now)) {
        nextDose = t;
        break;
      }
    }

    if (nextDose == null) {
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowTimes = _allTimesToday(widget.item, tomorrow);
      if (tomorrowTimes.isNotEmpty) nextDose = tomorrowTimes.first;
    }

    if (mounted) {
      setState(() {
        if (nextDose != null) {
          _nextDoseIn = nextDose.difference(now);
          _nextDoseTime =
              '${nextDose.hour.toString().padLeft(2, '0')}:${nextDose.minute.toString().padLeft(2, '0')}';
        } else {
          _nextDoseIn = Duration.zero;
          _nextDoseTime = null;
        }
      });
    }
  }

  List<DateTime> _allTimesToday(MedPlanItem plan, DateTime day) {
    final results = <DateTime>[];
    if (plan.frequencyType == 'fixed') {
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
      final hours = plan.intervalHours ?? 8;
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

  String _frequencyLabel(MedPlanItem item) {
    if (item.frequencyType == 'interval') {
      return 'A cada ${item.intervalHours ?? 8}h';
    }
    final count = item.scheduledTimes.length;
    return '$count×/dia (${item.scheduledTimes.join(', ')})';
  }

  String _periodLabel(MedPlanItem item) {
    if (item.continuous) return 'Uso contínuo';
    final start = _fmtDate(item.startDate);
    if (item.endDate != null) {
      return '$start – ${_fmtDate(item.endDate!)}';
    }
    return 'Desde $start';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _countdownLabel() {
    if (_nextDoseTime == null) return 'Sem horários';
    if (_nextDoseIn.isNegative || _nextDoseIn == Duration.zero) return 'Agora';
    final h = _nextDoseIn.inHours;
    final m = _nextDoseIn.inMinutes % 60;
    if (h > 0) return 'em ${h}h${m > 0 ? '${m}min' : ''}';
    return 'em ${m}min';
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
        onTap: () => context.push(
          '/medications/detail/${item.id}?patientId=${widget.patientId}',
        ),
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
                          ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: isDark
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicationName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          '${item.form} · ${item.dosage}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_nextDoseTime != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _nextDoseTime!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _countdownLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  _InfoChip(
                    icon: Icons.date_range_rounded,
                    label: _periodLabel(item),
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
