import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/dashboard_providers.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/activity_plan_item.dart';
import '../../domain/entities/activity_post.dart';
import '../providers/activity_providers.dart';

class ActivitiesFeedPage extends ConsumerWidget {
  const ActivitiesFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final statusFilter = ref.watch(activityStatusFilterProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Atividades')),
        body: const OldyEmptyState(
          icon: Icons.feed_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente para ver as atividades',
        ),
      );
    }

    // Posts from Firestore (works — used by "Realizadas")
    final postsAsync = ref.watch(activitiesProvider(patientId));

    // Scheduled activities from upNextProvider (works — used by "A Seguir")
    final upNextAsync = ref.watch(upNextProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Agenda de Atividades',
            onPressed: () => context.push('/activities/plan-config'),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            statusFilter: statusFilter,
            categoryFilter: categoryFilter,
            onStatusChanged: (f) =>
                ref.read(activityStatusFilterProvider.notifier).state = f,
            onCategoryChanged: (c) =>
                ref.read(categoryFilterProvider.notifier).state = c,
          ),
          Expanded(
            child: _buildBody(
              context,
              ref,
              patientId,
              statusFilter,
              categoryFilter,
              postsAsync,
              upNextAsync,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activities/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo post'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    ActivityStatusFilter statusFilter,
    String? categoryFilter,
    AsyncValue<List<ActivityPost>> postsAsync,
    AsyncValue<List<UpNextItem>> upNextAsync,
  ) {
    // "Realizadas" — just show posts
    if (statusFilter == ActivityStatusFilter.realizadas) {
      return postsAsync.when(
        loading: () => const OldyLoading(message: 'Carregando atividades...'),
        error: (_, _) => _retryEmpty(ref, patientId, statusFilter),
        data: (posts) {
          var filtered = posts;
          if (categoryFilter != null) {
            filtered = posts.where((p) => p.category == categoryFilter).toList();
          }
          if (filtered.isEmpty) {
            return _emptyState(context, statusFilter, patientId);
          }
          return _postList(context, filtered);
        },
      );
    }

    // "Programadas" — use valueOrNull (not .when!) to avoid error-state hiding data
    if (statusFilter == ActivityStatusFilter.programadas) {
      final upNextItems = upNextAsync.valueOrNull;
      if (upNextItems == null && upNextAsync.isLoading) {
        return const OldyLoading(message: 'Carregando atividades...');
      }

      var activityItems = (upNextItems ?? [])
          .where((item) => item.type == 'activity')
          .toList();
      if (categoryFilter != null) {
        activityItems = activityItems.where((item) {
          final plan = item.data;
          if (plan is ActivityPlanItem) {
            return plan.category == categoryFilter;
          }
          return true;
        }).toList();
      }

      if (activityItems.isEmpty) {
        return _emptyState(context, statusFilter, patientId);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: activityItems.length,
        separatorBuilder: (_, __) => AppSpacing.verticalMd,
        itemBuilder: (context, index) {
          return _UpNextActivityCard(
            item: activityItems[index],
            patientId: patientId,
          );
        },
      );
    }

    // "Todas" — combine posts + scheduled activities using valueOrNull
    final posts = postsAsync.valueOrNull ?? [];
    var upNextActivities = (upNextAsync.valueOrNull ?? [])
        .where((item) => item.type == 'activity')
        .toList();

    if (posts.isEmpty && upNextActivities.isEmpty) {
      if (postsAsync.isLoading || upNextAsync.isLoading) {
        return const OldyLoading(message: 'Carregando atividades...');
      }
      return _emptyState(context, statusFilter, patientId);
    }

    var filteredPosts = posts;
    if (categoryFilter != null) {
      filteredPosts =
          posts.where((p) => p.category == categoryFilter).toList();
      upNextActivities = upNextActivities.where((item) {
        final plan = item.data;
        if (plan is ActivityPlanItem) {
          return plan.category == categoryFilter;
        }
        return true;
      }).toList();
    }

    final combined = <_CombinedItem>[
      ...filteredPosts
          .map((p) => _CombinedItem(post: p, sortTime: p.eventAt)),
      ...upNextActivities
          .map((u) => _CombinedItem(upNextItem: u, sortTime: u.scheduledAt)),
    ];
    combined.sort((a, b) => b.sortTime.compareTo(a.sortTime));

    if (combined.isEmpty) {
      return _emptyState(context, statusFilter, patientId);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activitiesProvider(patientId));
        ref.invalidate(upNextProvider(patientId));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: combined.length,
        separatorBuilder: (_, __) => AppSpacing.verticalMd,
        itemBuilder: (context, index) {
          final item = combined[index];
          if (item.post != null) {
            return _ActivityCard(
              post: item.post!,
              onTap: () => context.push(
                '/activities/${item.post!.id}',
                extra: item.post!,
              ),
            );
          } else {
            return _UpNextActivityCard(
              item: item.upNextItem!,
              patientId: patientId,
            );
          }
        },
      ),
    );
  }

  Widget _postList(BuildContext context, List<ActivityPost> posts) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: posts.length,
      separatorBuilder: (_, _) => AppSpacing.verticalMd,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _ActivityCard(
          post: post,
          onTap: () => context.push('/activities/${post.id}', extra: post),
        );
      },
    );
  }

  Widget _scheduledList(BuildContext context, WidgetRef ref,
      List<UpNextItem> items, String patientId) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => AppSpacing.verticalMd,
      itemBuilder: (context, index) {
        return _UpNextActivityCard(
          item: items[index],
          patientId: patientId,
        );
      },
    );
  }

  Widget _retryEmpty(
      WidgetRef ref, String patientId, ActivityStatusFilter filter) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 48),
          const SizedBox(height: 16),
          const Text('Sem permissão para ver atividades deste paciente.'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              ref.invalidate(activitiesProvider(patientId));
              ref.invalidate(upNextProvider(patientId));
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
      BuildContext context, ActivityStatusFilter filter, String patientId) {
    switch (filter) {
      case ActivityStatusFilter.programadas:
        return OldyEmptyState(
          icon: Icons.event_note_outlined,
          title: 'Nenhuma atividade programada',
          subtitle:
              'Configure a agenda de atividades para ver os itens programados',
          actionLabel: 'Configurar agenda',
          onAction: () => context.push('/activities/plan-config'),
        );
      case ActivityStatusFilter.realizadas:
        return OldyEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nenhuma atividade realizada',
          subtitle: 'Registre a primeira atividade do paciente',
          actionLabel: 'Novo post',
          onAction: () => context.push('/activities/create'),
        );
      case ActivityStatusFilter.todas:
        return OldyEmptyState(
          icon: Icons.feed_outlined,
          title: 'Nenhuma atividade',
          subtitle: 'Crie atividades programadas ou registre um novo post',
          actionLabel: 'Novo post',
          onAction: () => context.push('/activities/create'),
        );
    }
  }
}

class _CombinedItem {
  final ActivityPost? post;
  final UpNextItem? upNextItem;
  final DateTime sortTime;
  const _CombinedItem({this.post, this.upNextItem, required this.sortTime});
}

// ==========================================================================
// Filter bar
// ==========================================================================

class _FilterBar extends StatelessWidget {
  final ActivityStatusFilter statusFilter;
  final String? categoryFilter;
  final ValueChanged<ActivityStatusFilter> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.categoryFilter,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        children: [
          for (final filter in ActivityStatusFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(_statusLabel(filter)),
                selected: statusFilter == filter && categoryFilter == null,
                onSelected: (_) {
                  onCategoryChanged(null);
                  onStatusChanged(filter);
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
              ),
            ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: theme.colorScheme.outlineVariant,
          ),
          ...AppConstants.activityCategories.map((category) {
            final isSelected = categoryFilter == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  onCategoryChanged(isSelected ? null : category);
                },
                selectedColor:
                    _categoryColor(category).withValues(alpha: 0.2),
                checkmarkColor: _categoryColor(category),
                labelStyle: isSelected
                    ? TextStyle(
                        color: _categoryColor(category),
                        fontWeight: FontWeight.w600,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _statusLabel(ActivityStatusFilter filter) => switch (filter) {
        ActivityStatusFilter.todas => 'Todas',
        ActivityStatusFilter.realizadas => 'Realizadas',
        ActivityStatusFilter.programadas => 'Programadas',
      };

  static Color _categoryColor(String category) {
    const colorMap = {
      'Banho': Color(0xFF42A5F5),
      'Alimentação': Color(0xFFF4A261),
      'Fisioterapia': Color(0xFF2A9D8F),
      'Visita médica': Color(0xFFE76F51),
      'Visita familiar': Color(0xFF9C27B0),
      'Exercício': Color(0xFF4CAF50),
      'Outro': Color(0xFF757575),
    };
    return colorMap[category] ?? const Color(0xFF757575);
  }
}

// ==========================================================================
// Card for a scheduled activity (from upNextProvider)
// ==========================================================================

class _UpNextActivityCard extends ConsumerWidget {
  final UpNextItem item;
  final String patientId;

  const _UpNextActivityCard({required this.item, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOverdue = item.scheduledAt.isBefore(DateTime.now());

    final statusColor = isOverdue ? AppColors.warning : AppColors.info;
    final bgColor = statusColor.withValues(alpha: isDark ? 0.15 : 0.08);

    final plan = item.data as ActivityPlanItem?;
    final category = plan?.category ?? 'Outro';
    final h = item.scheduledAt.hour.toString().padLeft(2, '0');
    final m = item.scheduledAt.minute.toString().padLeft(2, '0');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppSpacing.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(color: bgColor),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: statusColor, size: 20),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.verticalXs,
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _SmallCategoryChip(
                                category: category, theme: theme),
                            Text(
                              '$h:$m  ·  ${item.countdown}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (plan?.notes != null && plan!.notes!.isNotEmpty) ...[
                AppSpacing.verticalSm,
                Text(
                  plan.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (plan?.durationMinutes != null) ...[
                AppSpacing.verticalXs,
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    AppSpacing.horizontalXs,
                    Text(
                      '${plan!.durationMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              AppSpacing.verticalMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      isOverdue ? 'Pendente' : 'Programada',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (plan != null) ...[
                    FilledButton.icon(
                      onPressed: () => _register(context, ref, plan),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Registrar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/activities/plan-create', extra: plan),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register(
      BuildContext context, WidgetRef ref, ActivityPlanItem plan) {
    final user = ref.read(authStateProvider).valueOrNull;
    final prefilled = ActivityPost(
      id: const Uuid().v4(),
      category: plan.category,
      text: '',
      eventAt: item.scheduledAt,
      durationMinutes: plan.durationMinutes,
      tags: [],
      createdBy: user?.uid ?? '',
      createdByName: user?.displayName ?? '',
      createdAt: DateTime.now(),
    );
    context.push('/activities/create', extra: prefilled);
  }
}

class _SmallCategoryChip extends StatelessWidget {
  final String category;
  final ThemeData theme;

  const _SmallCategoryChip({required this.category, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _categoryColor(category).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        category,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _categoryColor(category),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  static Color _categoryColor(String category) {
    const colorMap = {
      'Banho': Color(0xFF42A5F5),
      'Alimentação': Color(0xFFF4A261),
      'Fisioterapia': Color(0xFF2A9D8F),
      'Visita médica': Color(0xFFE76F51),
      'Visita familiar': Color(0xFF9C27B0),
      'Exercício': Color(0xFF4CAF50),
      'Outro': Color(0xFF757575),
    };
    return colorMap[category] ?? const Color(0xFF757575);
  }
}

// ==========================================================================
// Activity post card (completed)
// ==========================================================================

class _ActivityCard extends StatelessWidget {
  final ActivityPost post;
  final VoidCallback onTap;

  const _ActivityCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppSpacing.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              AppSpacing.verticalSm,
              Row(
                children: [
                  _SmallCategoryChip(category: post.category, theme: theme),
                  AppSpacing.horizontalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'Realizada',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (post.text.isNotEmpty) ...[
                AppSpacing.verticalSm,
                Text(
                  post.text,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.photoUrls.isNotEmpty) ...[
                AppSpacing.verticalMd,
                _buildPhotoGrid(theme),
              ],
              AppSpacing.verticalMd,
              _buildReactionBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.avatarSm / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            post.createdByName.isNotEmpty
                ? post.createdByName[0].toUpperCase()
                : '?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        AppSpacing.horizontalSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.createdByName,
                  style: theme.textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                DateFormatters.relative(post.eventAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(ThemeData theme) {
    final photos = post.photoUrls;
    final displayCount = photos.length > 3 ? 3 : photos.length;
    final remaining = photos.length - displayCount;

    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(displayCount, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: index < displayCount - 1 ? AppSpacing.xs : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      photos[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    if (index == displayCount - 1 && remaining > 0)
                      Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: Text('+$remaining',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReactionBar(ThemeData theme) {
    return Row(
      children: [
        _ReactionBadge(emoji: '❤️', count: _rc('❤️'), theme: theme),
        AppSpacing.horizontalSm,
        _ReactionBadge(emoji: '👍', count: _rc('👍'), theme: theme),
        AppSpacing.horizontalSm,
        _ReactionBadge(emoji: '👌', count: _rc('👌'), theme: theme),
        const Spacer(),
        Icon(Icons.chat_bubble_outline_rounded,
            size: AppSpacing.iconSm,
            color: theme.colorScheme.onSurfaceVariant),
        AppSpacing.horizontalXs,
        Text('${post.commentCount}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  int _rc(String emoji) => post.reactions[emoji]?.length ?? 0;
}

class _ReactionBadge extends StatelessWidget {
  final String emoji;
  final int count;
  final ThemeData theme;

  const _ReactionBadge(
      {required this.emoji, required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Text('$count',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
