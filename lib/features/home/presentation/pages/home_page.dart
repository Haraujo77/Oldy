import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../activities/domain/entities/activity_post.dart';
import '../../../activities/presentation/pages/post_detail_page.dart';
import '../../../health/domain/entities/health_log.dart';
import '../../../management/domain/entities/patient.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../../medications/domain/entities/dose_event.dart';
import '../../../medications/presentation/providers/medication_providers.dart';
import '../../domain/entities/history_item.dart';
import '../providers/dashboard_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patientAsync = ref.watch(selectedPatientProvider);
    final patientId = ref.watch(selectedPatientIdProvider);

    final heroHeight = MediaQuery.of(context).size.width * 0.85;

    final patient = patientAsync.valueOrNull;
    final photoUrl = patient?.photoUrl;
    final nickname = (patient?.nickname?.isNotEmpty == true)
        ? patient!.nickname!
        : (patient?.fullName ?? 'Selecione um paciente');

    final detailParts = <String>[];
    if (patient != null) {
      detailParts.add(patient.fullName);
      if (patient.sexInitial.isNotEmpty) {
        detailParts.add('(${patient.sexInitial})');
      }
      detailParts.add('${patient.age} anos');
      if (patient.location != null && patient.location!.isNotEmpty) {
        detailParts.add(patient.location!.toLowerCase());
      }
    }
    final detailLine = patient != null
        ? detailParts.join(' ')
        : 'Toque para escolher um paciente';
    final conditions = patient != null && patient.conditions.isNotEmpty
        ? patient.conditions.join(', ')
        : '';
    final updatedAt = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: false,
            floating: false,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: GestureDetector(
                onTap: patient != null
                    ? () => context.push(AppRoutes.patientProfile)
                    : () => context.go(AppRoutes.myPatients),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _heroPlaceholder(theme),
                      )
                    else
                      _heroPlaceholder(theme),

                    // Bottom gradient
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: heroHeight * 0.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                                color: Colors.white,
                                tooltip: 'Meus Velhinhos',
                                onPressed: () => context.go(AppRoutes.myPatients),
                              ),
                              Expanded(
                                child: Text(
                                  'Atualizado às $updatedAt',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_outline_rounded, size: 26),
                                color: Colors.white,
                                tooltip: 'Perfil do paciente',
                                onPressed: patient != null
                                    ? () => context.push(AppRoutes.patientProfile)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom text overlay
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nickname,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: patient != null
                                  ? _buildDetailSpan(patient, theme)
                                  : [TextSpan(text: detailLine)],
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (conditions.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              conditions,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.verticalXl,

                  // -- Dashboard cards --
              if (patientId != null) ...[
                _HealthDashboardCard(patientId: patientId, theme: theme),
                AppSpacing.verticalMd,
                _MedDashboardCard(patientId: patientId, theme: theme),
                AppSpacing.verticalMd,
                _ActivityDashboardCard(patientId: patientId, theme: theme),
                AppSpacing.verticalXxl,
              ],

              // -- Quick Actions --
              Text('Ações rápidas', style: theme.textTheme.titleMedium),
              AppSpacing.verticalMd,
              _QuickActionsRow(theme: theme),

              if (patientId != null) ...[
                AppSpacing.verticalXxl,

                // -- Destaque --
                _HighlightSection(patientId: patientId, theme: theme),
                AppSpacing.verticalXxl,

                // -- A Seguir --
                _UpNextSection(patientId: patientId, theme: theme),
                AppSpacing.verticalXxl,

                // -- Historico recente --
                Row(
                  children: [
                    Text('Histórico recente', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                AppSpacing.verticalMd,
                _CompletedHistory(patientId: patientId, theme: theme),
              ],

              AppSpacing.verticalXl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildDetailSpan(Patient patient, ThemeData theme) {
    final spans = <InlineSpan>[];
    spans.add(TextSpan(
      text: patient.fullName,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    if (patient.sexInitial.isNotEmpty) {
      spans.add(TextSpan(text: ' (${patient.sexInitial})'));
    }
    spans.add(TextSpan(text: ' ${patient.age} anos'));
    if (patient.location != null && patient.location!.isNotEmpty) {
      spans.add(TextSpan(text: ', ${patient.location!.toLowerCase()}'));
    }
    return spans;
  }

  static Widget _heroPlaceholder(ThemeData theme) {
    return Container(color: theme.colorScheme.primary);
  }
}

// ==========================================================================

// ==========================================================================
// Dashboard Cards
// ==========================================================================

class _DashboardCardShell extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData titleIcon;
  final Color titleColor;
  final AsyncValue<DashboardStatus> statusAsync;
  final VoidCallback onTap;
  final VoidCallback? onCta;

  const _DashboardCardShell({
    required this.theme,
    required this.title,
    required this.titleIcon,
    required this.titleColor,
    required this.statusAsync,
    required this.onTap,
    this.onCta,
  });

  static const double _cardHeight = 96;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: SizedBox(
          height: _cardHeight,
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: statusAsync.when(
              loading: () => Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                ],
              ),
              data: (status) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          status.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status.cta != null && onCta != null) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: onCta,
                            child: Text(
                              status.cta!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Center(child: _StatusIndicator(status: status, theme: theme, fallbackColor: titleColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final DashboardStatus status;
  final ThemeData theme;
  final Color fallbackColor;

  const _StatusIndicator({required this.status, required this.theme, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    if (status.level == DashboardLevel.ok) {
      return Text(
        'OK',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (status.statusIcon != null) {
      final color = switch (status.level) {
        DashboardLevel.alert => AppColors.warning,
        DashboardLevel.warning => AppColors.error,
        DashboardLevel.info => AppColors.info,
        _ => fallbackColor,
      };
      return Icon(status.statusIcon, color: color, size: 36);
    }

    return const SizedBox.shrink();
  }
}

class _HealthDashboardCard extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _HealthDashboardCard({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(selectedPatientProvider).valueOrNull;
    final name = patient?.nickname ?? patient?.fullName.split(' ').first;
    final statusAsync = ref.watch(healthDashboardProvider((patientId: patientId, patientName: name)));

    return _DashboardCardShell(
      theme: theme,
      title: 'Saúde',
      titleIcon: Icons.monitor_heart_outlined,
      titleColor: theme.colorScheme.primary,
      statusAsync: statusAsync,
      onTap: () => context.go(AppRoutes.health),
      onCta: () => context.push('/health/plan'),
    );
  }
}

class _MedDashboardCard extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _MedDashboardCard({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(generateTodayDosesProvider(patientId));
    final statusAsync = ref.watch(medDashboardProvider(patientId));

    return _DashboardCardShell(
      theme: theme,
      title: 'Medicamentos',
      titleIcon: Icons.medication_outlined,
      titleColor: theme.colorScheme.secondary,
      statusAsync: statusAsync,
      onTap: () => context.go(AppRoutes.medications),
      onCta: () => context.push('/medications/create?patientId=$patientId'),
    );
  }
}

class _ActivityDashboardCard extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _ActivityDashboardCard({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(activityDashboardProvider(patientId));

    return _DashboardCardShell(
      theme: theme,
      title: 'Atividades',
      titleIcon: Icons.feed_outlined,
      titleColor: theme.colorScheme.tertiary,
      statusAsync: statusAsync,
      onTap: () => context.go(AppRoutes.activities),
      onCta: () => context.push('/activities/create'),
    );
  }
}

// ==========================================================================
// A Seguir (Up Next)
// ==========================================================================

class _UpNextSection extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _UpNextSection({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upNextAsync = ref.watch(upNextProvider(patientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('A seguir', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/up-next'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        AppSpacing.verticalMd,
        upNextAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (allItems) {
            if (allItems.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                    AppSpacing.horizontalSm,
                    Text(
                      'Tudo em dia! Nenhuma tarefa pendente.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            final items = allItems.take(5).toList();

            return Column(
              children: items.map((item) {
                final h = item.scheduledAt.hour.toString().padLeft(2, '0');
                final m = item.scheduledAt.minute.toString().padLeft(2, '0');

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () {
                      if (item.type == 'dose') {
                        final dose = item.data as DoseEvent;
                        context.go(AppRoutes.medications);
                      } else {
                        context.go(AppRoutes.activities);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 18, color: item.color),
                          ),
                          AppSpacing.horizontalMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$h:$m  ·  ${item.countdown}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: item.color, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ==========================================================================
// Quick Actions (horizontal scroll)
// ==========================================================================

class _QuickActionsRow extends StatelessWidget {
  final ThemeData theme;

  const _QuickActionsRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_chart_rounded, 'Registrar\nvital', () => context.push('/health/new-record')),
      (Icons.post_add_rounded, 'Nova\natividade', () => context.push('/activities/create')),
      (Icons.medication_outlined, 'Marcar\ndose', () => context.go(AppRoutes.medications)),
      (Icons.science_outlined, 'Novo\nexame', () => context.push(AppRoutes.exams)),
      (Icons.group_outlined, 'Gerir\nequipe', () => context.push(AppRoutes.members)),
      (Icons.person_outline_rounded, 'Perfil', () => context.push(AppRoutes.patientProfile)),
    ];

    const double cardSize = 96;

    return SizedBox(
      height: cardSize + AppSpacing.xs * 2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        clipBehavior: Clip.none,
        itemCount: actions.length,
        separatorBuilder: (_, _) => AppSpacing.horizontalMd,
        itemBuilder: (context, index) {
          final (icon, label, onTap) = actions[index];
          return _QuickActionTile(theme: theme, icon: icon, label: label, onTap: onTap, size: cardSize);
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  const _QuickActionTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 26),
                const Spacer(),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// Destaque (Highlight)
// ==========================================================================

class _HighlightSection extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _HighlightSection({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightAsync = ref.watch(highlightPostProvider(patientId));

    return highlightAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (post) {
        if (post == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destaque', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(post: post),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            post.photoUrls.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xCC000000), Colors.transparent],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Text(
                                    post.category,
                                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                                  ),
                                ),
                                if (post.text.isNotEmpty) ...[
                                  AppSpacing.verticalXs,
                                  Text(
                                    post.text,
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          AppSpacing.horizontalXs,
                          Text(
                            post.createdByName,
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            DateFormatters.relative(post.eventAt),
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================================================
// Completed History
// ==========================================================================

class _CompletedHistory extends ConsumerWidget {
  final String patientId;
  final ThemeData theme;

  const _CompletedHistory({required this.patientId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(completedHistoryProvider(patientId));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, _) => _emptyBox(),
      data: (items) {
        if (items.isEmpty) return _emptyBox();

        return Column(
          children: items.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () => _onTap(context, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _tileColor(item),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 18, color: _iconColor(item)),
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
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.horizontalSm,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _tileColor(item),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Text(
                                    _typeChip(item),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _iconColor(item),
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
                        DateFormatters.relative(item.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _onTap(BuildContext context, HistoryItem item) {
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

  Color _tileColor(HistoryItem item) {
    final isDark = theme.brightness == Brightness.dark;
    if (item.iconColor != null) {
      return item.iconColor!.withValues(alpha: isDark ? 0.25 : 0.15);
    }
    return switch (item.type) {
      HistoryItemType.activity => isDark ? const Color(0xFF0D47A1).withValues(alpha: 0.25) : const Color(0xFFE3F2FD),
      HistoryItemType.healthLog => theme.colorScheme.secondaryContainer,
      HistoryItemType.doseEvent => isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.25) : const Color(0xFFE8F5E9),
    };
  }

  Color _iconColor(HistoryItem item) {
    if (item.iconColor != null) return item.iconColor!;
    final isDark = theme.brightness == Brightness.dark;
    return switch (item.type) {
      HistoryItemType.activity => isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
      HistoryItemType.healthLog => theme.colorScheme.secondary,
      HistoryItemType.doseEvent => isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32),
    };
  }

  String _typeChip(HistoryItem item) => switch (item.type) {
        HistoryItemType.activity => 'Atividade',
        HistoryItemType.healthLog => 'Saúde',
        HistoryItemType.doseEvent => 'Medicamento',
      };

  Widget _emptyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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
