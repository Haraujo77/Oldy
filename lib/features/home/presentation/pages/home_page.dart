import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../management/presentation/providers/patient_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final patientAsync = ref.watch(selectedPatientProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user?.displayName.split(' ').first ?? 'Usuário'}',
                          style: theme.textTheme.headlineMedium,
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          'Como está seu paciente hoje?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              AppSpacing.verticalXxl,

              // Patient card
              patientAsync.when(
                data: (patient) {
                  if (patient == null) {
                    return _PatientHeaderCard(
                      theme: theme,
                      name: 'Selecione um paciente',
                      subtitle: 'Toque para escolher',
                      onTap: () => context.go(AppRoutes.myPatients),
                    );
                  }
                  return _PatientHeaderCard(
                    theme: theme,
                    name: (patient.nickname?.isNotEmpty == true)
                        ? patient.nickname!
                        : patient.fullName,
                    subtitle: patient.conditions.isNotEmpty
                        ? patient.conditions.join(', ')
                        : 'Sem condições registradas',
                    onTap: () => context.push(AppRoutes.patientProfile),
                    initial: patient.fullName.isNotEmpty
                        ? patient.fullName[0]
                        : '?',
                  );
                },
                loading: () => _PatientHeaderCard(
                  theme: theme,
                  name: 'Carregando...',
                  subtitle: '',
                ),
                error: (_, _) => _PatientHeaderCard(
                  theme: theme,
                  name: 'Erro ao carregar',
                  subtitle: 'Tente novamente',
                ),
              ),

              AppSpacing.verticalXl,

              // 3 summary cards
              _SummaryCard(
                theme: theme,
                icon: Icons.monitor_heart_rounded,
                title: 'Saúde',
                subtitle: 'Verifique os sinais vitais',
                color: theme.colorScheme.primary,
                onTap: () => context.go(AppRoutes.health),
              ),
              AppSpacing.verticalMd,
              _SummaryCard(
                theme: theme,
                icon: Icons.medication_rounded,
                title: 'Medicamentos',
                subtitle: 'Acompanhe as doses do dia',
                color: theme.colorScheme.secondary,
                onTap: () => context.go(AppRoutes.medications),
              ),
              AppSpacing.verticalMd,
              _SummaryCard(
                theme: theme,
                icon: Icons.feed_rounded,
                title: 'Atividades',
                subtitle: 'Registre momentos do cuidado',
                color: theme.colorScheme.tertiary,
                onTap: () => context.go(AppRoutes.activities),
              ),

              AppSpacing.verticalXxl,

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      theme: theme,
                      icon: Icons.add_chart_rounded,
                      label: 'Registrar\nvital',
                      onTap: () => context.push('/health/new-record'),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: _QuickAction(
                      theme: theme,
                      icon: Icons.post_add_rounded,
                      label: 'Nova\natividade',
                      onTap: () => context.push('/activities/create'),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: _QuickAction(
                      theme: theme,
                      icon: Icons.people_outlined,
                      label: 'Membros',
                      onTap: () => context.push(AppRoutes.members),
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalXxl,
              Text('Histórico recente', style: theme.textTheme.titleMedium),
              AppSpacing.verticalMd,
              _EmptyHistory(theme: theme),
              AppSpacing.verticalXl,
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;
  final String? initial;

  const _PatientHeaderCard({
    required this.theme,
    required this.name,
    required this.subtitle,
    this.onTap,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarLg / 2,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  initial ?? '?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              AppSpacing.horizontalLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    AppSpacing.verticalXs,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: AppSpacing.iconLg),
              ),
              AppSpacing.horizontalLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    AppSpacing.verticalXs,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              AppSpacing.verticalSm,
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ThemeData theme;

  const _EmptyHistory({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          AppSpacing.verticalSm,
          Text(
            'Nenhum registro ainda',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
