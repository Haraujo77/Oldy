import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/patient_member.dart';
import '../providers/patient_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(patientMembersProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final patientId = ref.watch(selectedPatientIdProvider);

    final isAdmin = membersAsync.valueOrNull?.any(
          (m) => m.userId == currentUser?.uid && m.role == 'admin',
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Membros')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.invite),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Convidar'),
            )
          : null,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar membros: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Nenhum membro encontrado'));
          }

          return ListView.builder(
            padding: AppSpacing.paddingScreen,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelf = member.userId == currentUser?.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: AppSpacing.paddingCard,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppSpacing.avatarSm / 2,
                        backgroundImage: member.photoUrl != null
                            ? NetworkImage(member.photoUrl!)
                            : null,
                        child: member.photoUrl == null
                            ? Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.titleMedium,
                              )
                            : null,
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.displayName,
                                    style:
                                        theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelf) ...[
                                  AppSpacing.horizontalXs,
                                  Text(
                                    '(você)',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              member.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.horizontalSm,
                      if (isAdmin && !isSelf)
                        _buildRoleDropdown(
                            context, ref, theme, member, patientId)
                      else
                        _buildRoleBadge(theme, member.role),
                      if (isAdmin && !isSelf) ...[
                        AppSpacing.horizontalXs,
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: theme.colorScheme.error),
                          tooltip: 'Remover membro',
                          onPressed: () => _confirmRemove(
                              context, ref, member, patientId),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, String role) {
    final config = _roleConfig(theme, role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        config.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    PatientMember member,
    String? patientId,
  ) {
    return DropdownButton<String>(
      value: member.role,
      underline: const SizedBox.shrink(),
      isDense: true,
      items: const [
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'editor', child: Text('Editor')),
        DropdownMenuItem(value: 'viewer', child: Text('Visualizador')),
      ],
      onChanged: (newRole) async {
        if (newRole == null || newRole == member.role || patientId == null) {
          return;
        }
        try {
          await ref
              .read(patientRepositoryProvider)
              .updateMemberRole(patientId, member.userId, newRole);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Papel atualizado com sucesso')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar papel: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    PatientMember member,
    String? patientId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text(
          'Deseja remover ${member.displayName} da equipe?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (patientId == null) return;
              try {
                await ref
                    .read(patientRepositoryProvider)
                    .removeMember(patientId, member.userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membro removido')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao remover: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _roleConfig(ThemeData theme, String role) {
    return switch (role) {
      'admin' => (label: 'Admin', color: theme.colorScheme.primary),
      'editor' => (label: 'Editor', color: theme.colorScheme.tertiary),
      _ => (label: 'Visualizador', color: theme.colorScheme.outline),
    };
  }
}
