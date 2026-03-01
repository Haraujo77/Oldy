import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalMd,
              Text(
                'Olá, Usuário',
                style: theme.textTheme.headlineMedium,
              ),
              AppSpacing.verticalXs,
              Text(
                'Como está seu paciente hoje?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.verticalXxl,
              _PatientHeaderCard(theme: theme),
              AppSpacing.verticalXl,
              _SummaryCard(
                theme: theme,
                icon: Icons.monitor_heart_rounded,
                title: 'Saúde',
                subtitle: 'Sem registros recentes',
                color: theme.colorScheme.primary,
              ),
              AppSpacing.verticalMd,
              _SummaryCard(
                theme: theme,
                icon: Icons.medication_rounded,
                title: 'Medicamentos',
                subtitle: 'Nenhuma dose pendente',
                color: theme.colorScheme.secondary,
              ),
              AppSpacing.verticalMd,
              _SummaryCard(
                theme: theme,
                icon: Icons.feed_rounded,
                title: 'Atividades',
                subtitle: 'Nenhum post hoje',
                color: theme.colorScheme.tertiary,
              ),
              AppSpacing.verticalXxl,
              Text(
                'Histórico recente',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.verticalMd,
              _EmptyHistory(theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final ThemeData theme;

  const _PatientHeaderCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.avatarLg / 2,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.horizontalLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome do Paciente',
                    style: theme.textTheme.titleLarge,
                  ),
                  AppSpacing.verticalXs,
                  Text(
                    'Selecione um paciente para começar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  const _SummaryCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {},
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
