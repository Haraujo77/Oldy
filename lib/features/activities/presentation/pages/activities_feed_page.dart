import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/activity_post.dart';
import '../providers/activity_providers.dart';

class ActivitiesFeedPage extends ConsumerWidget {
  const ActivitiesFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

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

    final activitiesAsync = ref.watch(activitiesProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Atividades')),
      body: Column(
        children: [
          _CategoryFilterBar(
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              ref.read(categoryFilterProvider.notifier).state = category;
            },
          ),
          Expanded(
            child: activitiesAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return OldyEmptyState(
                    icon: Icons.feed_outlined,
                    title: 'Nenhuma atividade registrada',
                    subtitle: 'Crie seu primeiro post de atividade',
                    actionLabel: 'Novo post',
                    onAction: () => context.push('/activities/create'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(activitiesProvider(patientId));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => AppSpacing.verticalMd,
                    itemBuilder: (context, index) {
                      return _ActivityCard(
                        post: posts[index],
                        onTap: () => context.push(
                          '/activities/${posts[index].id}',
                          extra: posts[index],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const OldyLoading(message: 'Carregando atividades...'),
              error: (error, _) => OldyErrorWidget(
                message: 'Erro ao carregar atividades',
                onRetry: () => ref.invalidate(activitiesProvider(patientId)),
              ),
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
}

class _CategoryFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onCategorySelected,
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: const Text('Todos'),
              selected: selectedCategory == null,
              onSelected: (_) => onCategorySelected(null),
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            ),
          ),
          ...AppConstants.activityCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) {
                  onCategorySelected(
                    selectedCategory == category ? null : category,
                  );
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityPost post;
  final VoidCallback onTap;

  const _ActivityCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppSpacing.elevationSm,
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
              _buildCategoryChip(theme),
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
              Text(
                post.createdByName,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormatters.relative(post.eventAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _categoryColor(post.category).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        post.category,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _categoryColor(post.category),
          fontWeight: FontWeight.w600,
        ),
      ),
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
                right: index < displayCount - 1 ? AppSpacing.xs : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photos[index],
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    if (index == displayCount - 1 && remaining > 0)
                      Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: Text(
                          '+$remaining',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        _ReactionBadge(emoji: '❤️', count: _reactionCount('❤️'), theme: theme),
        AppSpacing.horizontalSm,
        _ReactionBadge(emoji: '👍', count: _reactionCount('👍'), theme: theme),
        AppSpacing.horizontalSm,
        _ReactionBadge(emoji: '👌', count: _reactionCount('👌'), theme: theme),
        const Spacer(),
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: AppSpacing.iconSm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        AppSpacing.horizontalXs,
        Text(
          '${post.commentCount}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  int _reactionCount(String emoji) {
    return post.reactions[emoji]?.length ?? 0;
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

class _ReactionBadge extends StatelessWidget {
  final String emoji;
  final int count;
  final ThemeData theme;

  const _ReactionBadge({
    required this.emoji,
    required this.count,
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
          Text(emoji, style: const TextStyle(fontSize: 14)),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
