import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../../medications/domain/entities/dose_event.dart';
import '../providers/dashboard_providers.dart';

class UpNextPage extends ConsumerWidget {
  const UpNextPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final theme = Theme.of(context);

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('A seguir')),
        body: const OldyEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente para ver a agenda',
        ),
      );
    }

    final upNextAsync = ref.watch(upNextProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('A seguir — Hoje')),
      body: upNextAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const OldyEmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar',
          subtitle: 'Não foi possível carregar a agenda de hoje',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const OldyEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Tudo em dia!',
              subtitle: 'Nenhuma tarefa pendente para hoje',
            );
          }

          final overdue = items.where((i) => i.scheduledAt.isBefore(DateTime.now())).toList();
          final upcoming = items.where((i) => !i.scheduledAt.isBefore(DateTime.now())).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  theme: theme,
                  title: 'Pendentes',
                  count: overdue.length,
                  color: AppColors.warning,
                ),
                AppSpacing.verticalSm,
                ...overdue.map((item) => _UpNextTile(
                      item: item,
                      theme: theme,
                      isOverdue: true,
                    )),
                AppSpacing.verticalXl,
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  theme: theme,
                  title: 'Próximas',
                  count: upcoming.length,
                  color: AppColors.info,
                ),
                AppSpacing.verticalSm,
                ...upcoming.map((item) => _UpNextTile(
                      item: item,
                      theme: theme,
                      isOverdue: false,
                    )),
              ],
              AppSpacing.verticalXl,
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.theme,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AppSpacing.horizontalSm,
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        AppSpacing.horizontalSm,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpNextTile extends StatelessWidget {
  final UpNextItem item;
  final ThemeData theme;
  final bool isOverdue;

  const _UpNextTile({
    required this.item,
    required this.theme,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final h = item.scheduledAt.hour.toString().padLeft(2, '0');
    final m = item.scheduledAt.minute.toString().padLeft(2, '0');
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isOverdue ? AppColors.warning : item.color;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isOverdue
            ? BorderSide(color: AppColors.warning.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          if (item.type == 'dose') {
            context.go(AppRoutes.medications);
          } else {
            context.go(AppRoutes.activities);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 22, color: accentColor),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalXs,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item.type == 'dose'
                                    ? theme.colorScheme.secondary
                                    : const Color(0xFF42A5F5))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            item.type == 'dose' ? 'Medicamento' : 'Atividade',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: item.type == 'dose'
                                  ? theme.colorScheme.secondary
                                  : const Color(0xFF42A5F5),
                            ),
                          ),
                        ),
                        AppSpacing.horizontalSm,
                        Text(
                          '$h:$m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.horizontalSm,
                        Text(
                          item.countdown,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
