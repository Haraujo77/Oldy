import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/activity_comment.dart';
import '../../domain/entities/activity_post.dart';
import '../providers/activity_providers.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final ActivityPost post;

  const PostDetailPage({super.key, required this.post});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) return;

    setState(() => _isSendingComment = true);

    try {
      final repo = ref.read(activityRepositoryProvider);
      final comment = ActivityComment(
        id: const Uuid().v4(),
        postId: widget.post.id,
        text: text,
        createdBy: '', // Set by auth layer
        createdByName: '', // Set by auth layer
        createdAt: DateTime.now(),
      );

      await repo.addComment(patientId, widget.post.id, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erro ao enviar comentário', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _toggleReaction(String emoji) async {
    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) return;

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.toggleReaction(
        patientId,
        widget.post.id,
        emoji,
        '', // Current user ID - set by auth layer
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erro ao reagir', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final patientId = ref.watch(selectedPatientIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(post.category),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (post.photoUrls.isNotEmpty) _buildPhotoCarousel(theme, post),
                Padding(
                  padding: AppSpacing.paddingScreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorRow(theme, post),
                      AppSpacing.verticalLg,
                      _buildCategoryAndDate(theme, post),
                      if (post.text.isNotEmpty) ...[
                        AppSpacing.verticalLg,
                        Text(post.text, style: theme.textTheme.bodyLarge),
                      ],
                      if (post.audioUrl != null) ...[
                        AppSpacing.verticalLg,
                        _buildAudioPlaceholder(theme),
                      ],
                      if (post.tags.isNotEmpty) ...[
                        AppSpacing.verticalLg,
                        _buildTags(theme, post),
                      ],
                      AppSpacing.verticalLg,
                      _buildReactionButtons(theme, post),
                      AppSpacing.verticalXl,
                      Divider(color: theme.colorScheme.outlineVariant),
                      AppSpacing.verticalMd,
                      Text(
                        'Comentários',
                        style: theme.textTheme.titleMedium,
                      ),
                      AppSpacing.verticalMd,
                    ],
                  ),
                ),
                if (patientId != null) _buildCommentsSection(theme, patientId, post.id),
              ],
            ),
          ),
          _buildCommentInput(theme),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(ThemeData theme, ActivityPost post) {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        itemCount: post.photoUrls.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: post.photoUrls[index],
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (_, _) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthorRow(ThemeData theme, ActivityPost post) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.avatarMd / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            post.createdByName.isNotEmpty
                ? post.createdByName[0].toUpperCase()
                : '?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        AppSpacing.horizontalMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.createdByName, style: theme.textTheme.titleSmall),
              Text(
                DateFormatters.relative(post.createdAt),
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

  Widget _buildCategoryAndDate(ThemeData theme, ActivityPost post) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            post.category,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppSpacing.horizontalMd,
        Icon(
          Icons.calendar_today_outlined,
          size: AppSpacing.iconSm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        AppSpacing.horizontalXs,
        Text(
          DateFormatters.dateTime(post.eventAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlaceholder(ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: AppSpacing.iconLg,
            color: theme.colorScheme.primary,
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Áudio', style: theme.textTheme.labelLarge),
                Text(
                  'Player em breve',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme, ActivityPost post) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: post.tags.map((tag) {
        return Chip(
          label: Text('#$tag'),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildReactionButtons(ThemeData theme, ActivityPost post) {
    const emojis = ['❤️', '👍', '👌'];
    return Row(
      children: emojis.map((emoji) {
        final count = post.reactions[emoji]?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleReaction(emoji),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentsSection(ThemeData theme, String patientId, String postId) {
    final commentsAsync = ref.watch(
      activityCommentsProvider((patientId: patientId, postId: postId)),
    );

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Nenhum comentário ainda. Seja o primeiro!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: comments.length,
          separatorBuilder: (_, _) => AppSpacing.verticalSm,
          itemBuilder: (context, index) {
            return _CommentTile(comment: comments[index]);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: OldyLoading(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: OldyErrorWidget(message: 'Erro ao carregar comentários'),
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Escreva um comentário...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          AppSpacing.horizontalXs,
          IconButton(
            onPressed: _isSendingComment ? null : _sendComment,
            icon: _isSendingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final ActivityComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            comment.createdByName.isNotEmpty
                ? comment.createdByName[0].toUpperCase()
                : '?',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        AppSpacing.horizontalSm,
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.createdByName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Text(
                      DateFormatters.relative(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalXs,
                Text(comment.text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
