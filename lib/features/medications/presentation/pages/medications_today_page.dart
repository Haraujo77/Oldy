import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/dose_event.dart';
import '../providers/medication_providers.dart';
import 'create_edit_med_plan_page.dart';
import 'dose_history_page.dart';

// TODO: replace with real selected patient provider
const _kDemoPatientId = 'demo_patient';

class MedicationsTodayPage extends ConsumerWidget {
  const MedicationsTodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayDosesProvider(_kDemoPatientId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Histórico',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DoseHistoryPage(
                  patientId: _kDemoPatientId,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateEditMedPlanPage(
              patientId: _kDemoPatientId,
            ),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: todayAsync.when(
        loading: () => const OldyLoading(message: 'Carregando doses...'),
        error: (e, _) => OldyErrorWidget(
          message: 'Erro ao carregar doses: $e',
          onRetry: () => ref.invalidate(todayDosesProvider(_kDemoPatientId)),
        ),
        data: (doses) {
          if (doses.isEmpty) {
            return OldyEmptyState(
              icon: Icons.medication_outlined,
              title: 'Nenhuma dose para hoje',
              subtitle:
                  'Adicione medicamentos ao plano para acompanhar as doses',
              actionLabel: 'Adicionar medicamento',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateEditMedPlanPage(
                    patientId: _kDemoPatientId,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: doses.length,
            separatorBuilder: (_, _) => AppSpacing.verticalSm,
            itemBuilder: (context, index) =>
                _DoseCard(dose: doses[index], theme: theme),
          );
        },
      ),
    );
  }
}

class _DoseCard extends ConsumerWidget {
  final DoseEvent dose;
  final ThemeData theme;

  const _DoseCard({required this.dose, required this.theme});

  Color _statusColor() {
    switch (dose.status) {
      case 'tomado':
        return AppColors.success;
      case 'pendente':
        return AppColors.warning;
      case 'atrasado':
        return AppColors.error;
      case 'pulado':
        return AppColors.error;
      case 'adiado':
        return AppColors.info;
      default:
        return AppColors.neutral500;
    }
  }

  String _statusLabel() {
    switch (dose.status) {
      case 'tomado':
        return 'Tomado';
      case 'pendente':
        return 'Pendente';
      case 'atrasado':
        return 'Atrasado';
      case 'pulado':
        return 'Pulado';
      case 'adiado':
        return 'Adiado';
      default:
        return dose.status;
    }
  }

  IconData _statusIcon() {
    switch (dose.status) {
      case 'tomado':
        return Icons.check_circle_rounded;
      case 'pendente':
        return Icons.schedule_rounded;
      case 'atrasado':
        return Icons.warning_amber_rounded;
      case 'pulado':
        return Icons.cancel_rounded;
      case 'adiado':
        return Icons.snooze_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

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
        .recordDoseEvent(_kDemoPatientId, updated);
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
                      .recordDoseEvent(_kDemoPatientId, updated);
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
                      .recordDoseEvent(_kDemoPatientId, updated);
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
                  .recordDoseEvent(_kDemoPatientId, updated);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor();
    final isPending = dose.status == 'pendente';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(
          '/medications/detail/${dose.medPlanId}',
        ),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(), color: color, size: AppSpacing.iconLg),
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
                        Text(
                          _formattedTime(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                      _statusLabel(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    AppSpacing.horizontalSm,
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showOptions(context, ref),
                    ),
                  ],
                ],
              ),
              if (isPending) ...[
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
