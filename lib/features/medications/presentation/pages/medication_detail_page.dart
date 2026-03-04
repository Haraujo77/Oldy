import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/dose_event.dart';
import '../../domain/entities/med_plan_item.dart';
import '../helpers/dose_status_helper.dart';
import '../providers/medication_providers.dart';
import 'create_edit_med_plan_page.dart';

class MedicationDetailPage extends ConsumerWidget {
  final String patientId;
  final String medPlanId;

  const MedicationDetailPage({
    super.key,
    required this.patientId,
    required this.medPlanId,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar medicamento'),
        content: Text('Deseja apagar "$name" do plano?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(medicationRepositoryProvider)
                    .deleteMedPlanItem(patientId, medPlanId);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao apagar: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
                }
              }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(medPlanProvider(patientId));
    final historyAsync = ref.watch(doseHistoryProvider((
      patientId: patientId,
      medPlanId: medPlanId,
      limit: 30,
    )));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          planAsync.whenOrNull(
                data: (plans) {
                  final item =
                      plans.where((p) => p.id == medPlanId).firstOrNull;
                  if (item == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Editar',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateEditMedPlanPage(
                              patientId: patientId,
                              existing: item,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error),
                        tooltip: 'Apagar',
                        onPressed: () => _confirmDelete(
                            context, ref, item.medicationName),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: planAsync.when(
        loading: () => const OldyLoading(),
        error: (e, _) => OldyErrorWidget(message: '$e'),
        data: (plans) {
          final item = plans.where((p) => p.id == medPlanId).firstOrNull;
          if (item == null) {
            return const OldyErrorWidget(
                message: 'Medicamento não encontrado');
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoSection(item: item, theme: theme),
                AppSpacing.verticalXxl,
                Text('Histórico de doses',
                    style: theme.textTheme.titleMedium),
                AppSpacing.verticalMd,
                historyAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => OldyErrorWidget(message: '$e'),
                  data: (events) {
                    if (events.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          'Nenhum registro de dose ainda',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Column(
                      children: events
                          .map((e) => _DoseEventTile(event: e, theme: theme))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final MedPlanItem item;
  final ThemeData theme;

  const _InfoSection({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: theme.colorScheme.primary,
                    size: AppSpacing.iconLg,
                  ),
                ),
                AppSpacing.horizontalLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.medicationName,
                          style: theme.textTheme.titleLarge),
                      if (item.activeIngredient != null) ...[
                        AppSpacing.verticalXs,
                        Text(
                          item.activeIngredient!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
              AppSpacing.verticalLg,
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.network(
                  item.photoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            AppSpacing.verticalLg,
            const Divider(height: 1),
            AppSpacing.verticalLg,
            _DetailRow(
                label: 'Forma', value: item.form, theme: theme),
            _DetailRow(
                label: 'Dosagem', value: item.dosage, theme: theme),
            _DetailRow(
              label: 'Frequência',
              value: item.frequencyType == 'interval'
                  ? 'A cada ${item.intervalHours}h'
                  : 'Horários fixos',
              theme: theme,
            ),
            if (item.scheduledTimes.isNotEmpty)
              _DetailRow(
                label: 'Horários',
                value: item.scheduledTimes.join(', '),
                theme: theme,
              ),
            _DetailRow(
              label: 'Período',
              value: item.continuous
                  ? 'Uso contínuo'
                  : '${_fmtDate(item.startDate)}${item.endDate != null ? ' – ${_fmtDate(item.endDate!)}' : ''}',
              theme: theme,
            ),
            if (item.instructions != null && item.instructions!.isNotEmpty)
              _DetailRow(
                  label: 'Instruções',
                  value: item.instructions!,
                  theme: theme),
            if (item.notes != null && item.notes!.isNotEmpty)
              _DetailRow(
                  label: 'Observações', value: item.notes!, theme: theme),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DoseEventTile extends StatelessWidget {
  final DoseEvent event;
  final ThemeData theme;

  const _DoseEventTile({required this.event, required this.theme});

  String _fmtDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$day/$month $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final helper = DoseStatusHelper(event);
    final color = helper.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Text(
              _fmtDateTime(event.scheduledAt),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              helper.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
