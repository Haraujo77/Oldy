import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/dose_event.dart';
import '../helpers/dose_status_helper.dart';
import '../providers/medication_providers.dart';

class MedicationsTodayPage extends ConsumerWidget {
  const MedicationsTodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicamentos')),
        body: const OldyEmptyState(
          icon: Icons.medication_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente para ver os medicamentos',
        ),
      );
    }

    ref.watch(generateTodayDosesProvider(patientId));
    final todayAsync = ref.watch(todayDosesProvider(patientId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Histórico',
            onPressed: () =>
                context.push('/medications/history?patientId=$patientId'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Plano de Medicamentos',
            onPressed: () => context.push('/medications/plan-config'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/medications/create?patientId=$patientId'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: todayAsync.when(
        loading: () => const OldyLoading(message: 'Carregando doses...'),
        error: (e, _) {
          if (e.toString().contains('permission-denied')) {
            return const OldyEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sem permissão',
              subtitle: 'Você não tem permissão para ver os medicamentos deste paciente.',
            );
          }
          return OldyErrorWidget(
            message: 'Erro ao carregar doses: $e',
            onRetry: () => ref.invalidate(todayDosesProvider(patientId)),
          );
        },
        data: (doses) {
          if (doses.isEmpty) {
            return OldyEmptyState(
              icon: Icons.medication_outlined,
              title: 'Nenhuma dose para hoje',
              subtitle:
                  'Adicione medicamentos ao plano para acompanhar as doses',
              actionLabel: 'Adicionar medicamento',
              onAction: () =>
                  context.push('/medications/create?patientId=$patientId'),
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: doses.length,
            separatorBuilder: (_, __) => AppSpacing.verticalSm,
            itemBuilder: (context, index) =>
                _DoseCard(dose: doses[index], patientId: patientId, theme: theme),
          );
        },
      ),
    );
  }
}

class _DoseCard extends ConsumerWidget {
  final DoseEvent dose;
  final String patientId;
  final ThemeData theme;

  const _DoseCard({required this.dose, required this.patientId, required this.theme});

  String _formattedTime() {
    final h = dose.scheduledAt.hour.toString().padLeft(2, '0');
    final m = dose.scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _markAsTaken(BuildContext context, WidgetRef ref) async {
    final updated = dose.copyWith(
      status: 'tomado',
      actualAt: DateTime.now(),
    );
    await ref
        .read(medicationRepositoryProvider)
        .recordDoseEvent(patientId, updated);
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.snooze_rounded),
                title: const Text('Adiar 30 minutos'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final updated = dose.copyWith(
                    status: 'adiado',
                    scheduledAt:
                        dose.scheduledAt.add(const Duration(minutes: 30)),
                  );
                  await ref
                      .read(medicationRepositoryProvider)
                      .recordDoseEvent(patientId, updated);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined,
                    color: theme.colorScheme.error),
                title: const Text('Pular dose'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final updated = dose.copyWith(
                    status: 'pulado',
                    actualAt: DateTime.now(),
                  );
                  await ref
                      .read(medicationRepositoryProvider)
                      .recordDoseEvent(patientId, updated);
                },
              ),
              ListTile(
                leading: Icon(Icons.note_add_outlined,
                    color: theme.colorScheme.error),
                title: const Text('Pular com motivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSkipReasonDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSkipReasonDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Por que está pulando esta dose?',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = dose.copyWith(
                status: 'pulado',
                actualAt: DateTime.now(),
                skipReason: controller.text.trim(),
              );
              await ref
                  .read(medicationRepositoryProvider)
                  .recordDoseEvent(patientId, updated);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helper = DoseStatusHelper(dose);
    final color = helper.color;
    final countdownText = helper.countdown;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(
          '/medications/detail/${dose.medPlanId}?patientId=$patientId',
        ),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(helper.icon, color: color, size: AppSpacing.iconLg),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.medicationName,
                          style: theme.textTheme.titleMedium,
                        ),
                        AppSpacing.verticalXs,
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            Text(
                              _formattedTime(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (countdownText.isNotEmpty)
                              Text(
                                countdownText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      helper.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (helper.isActionable) ...[
                    AppSpacing.horizontalSm,
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showOptions(context, ref),
                    ),
                  ],
                ],
              ),
              if (helper.isActionable) ...[
                AppSpacing.verticalMd,
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _markAsTaken(context, ref),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Marcar como tomado'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
