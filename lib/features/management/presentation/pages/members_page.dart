import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/patient_member.dart';
import '../providers/patient_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(patientMembersProvider);
    final invitesAsync = ref.watch(patientInvitesProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final patientId = ref.watch(selectedPatientIdProvider);

    final isAdmin = membersAsync.valueOrNull?.any(
          (m) => m.userId == currentUser?.uid && m.role == 'admin',
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão Membros')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.invite),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Convidar'),
            )
          : null,
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          Text('Membros ativos',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          AppSpacing.verticalSm,
          membersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro ao carregar membros: $e'),
            data: (members) {
              if (members.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text('Nenhum membro encontrado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: members
                    .map((m) => _MemberTile(
                          member: m,
                          isAdmin: isAdmin,
                          isSelf: m.userId == currentUser?.uid,
                          patientId: patientId,
                        ))
                    .toList(),
              );
            },
          ),
          AppSpacing.verticalXl,
          Text('Convites',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          AppSpacing.verticalSm,
          invitesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro ao carregar convites: $e'),
            data: (invites) {
              if (invites.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text('Nenhum convite enviado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: invites
                    .map((inv) => _InviteTile(
                          invite: inv,
                          isAdmin: isAdmin,
                          patientId: patientId,
                        ))
                    .toList(),
              );
            },
          ),
          AppSpacing.verticalXxxl,
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final PatientMember member;
  final bool isAdmin;
  final bool isSelf;
  final String? patientId;

  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.isSelf,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        AppSpacing.horizontalXs,
                        Text('(você)',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                  Text(
                    member.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalSm,
            if (isAdmin && !isSelf)
              _RoleDropdown(member: member, patientId: patientId)
            else
              _RoleBadge(role: member.role),
            if (isAdmin && !isSelf) ...[
              AppSpacing.horizontalXs,
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: theme.colorScheme.error, size: 20),
                tooltip: 'Remover membro',
                onPressed: () =>
                    _confirmRemove(context, ref, member, patientId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref,
      PatientMember member, String? patientId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content:
            Text('Deseja remover ${member.displayName} da equipe?'),
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
                      const SnackBar(content: Text('Membro removido')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao remover: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
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
}

class _InviteTile extends ConsumerWidget {
  final Invite invite;
  final bool isAdmin;
  final String? patientId;

  const _InviteTile({
    required this.invite,
    required this.isAdmin,
    required this.patientId,
  });

  bool get _isExpired =>
      invite.status == 'expired' ||
      (invite.status == 'pending' &&
          invite.expiresAt.isBefore(DateTime.now()));

  bool get _isAccepted => invite.status == 'accepted';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.avatarSm / 2,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    _isAccepted
                        ? Icons.check_rounded
                        : Icons.mail_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invite.email,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500)),
                      AppSpacing.verticalXs,
                      Row(
                        children: [
                          _RoleBadge(role: invite.role),
                          AppSpacing.horizontalSm,
                          _StatusChip(
                            isExpired: _isExpired,
                            isAccepted: _isAccepted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isAccepted && isAdmin)
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      if (!_isExpired && !_isAccepted)
                        const PopupMenuItem(
                          value: 'copy',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.copy_rounded, size: 20),
                            title: Text('Copiar código'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.red),
                          title: Text('Apagar convite',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (action) {
                      if (action == 'copy') {
                        Clipboard.setData(
                            ClipboardData(text: invite.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Código copiado: ${invite.code}')),
                        );
                      } else if (action == 'delete') {
                        _confirmDelete(context, ref);
                      }
                    },
                  ),
              ],
            ),
            if (!_isAccepted && !_isExpired) ...[
              AppSpacing.verticalSm,
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  AppSpacing.horizontalXs,
                  Text(
                    'Expira em ${_formatExpiry(invite.expiresAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: invite.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Código copiado: ${invite.code}')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(invite.code,
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: theme.colorScheme.primary)),
                        AppSpacing.horizontalXs,
                        Icon(Icons.copy_rounded,
                            size: 14, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} dias';
    if (diff.inHours > 0) return '${diff.inHours} horas';
    return '${diff.inMinutes} min';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar convite'),
        content: Text(
            'Deseja apagar o convite para ${invite.email}?'),
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
                    .deleteInvite(patientId!, invite.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Convite apagado')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro: $e'),
                    backgroundColor:
                        Theme.of(context).colorScheme.error,
                  ));
                }
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isExpired;
  final bool isAccepted;

  const _StatusChip({required this.isExpired, required this.isAccepted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String label;
    final Color color;

    if (isAccepted) {
      label = 'Aceito';
      color = Colors.green;
    } else if (isExpired) {
      label = 'Expirado';
      color = theme.colorScheme.error;
    } else {
      label = 'Pendente';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (role) {
      'admin' => ('Admin', theme.colorScheme.primary),
      'editor' => ('Editor', theme.colorScheme.tertiary),
      _ => ('Visualizador', theme.colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleDropdown extends ConsumerWidget {
  final PatientMember member;
  final String? patientId;

  const _RoleDropdown({required this.member, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<String>(
      value: member.role,
      underline: const SizedBox.shrink(),
      isDense: true,
      items: const [
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'editor', child: Text('Editor')),
        DropdownMenuItem(
            value: 'viewer', child: Text('Visualizador')),
      ],
      onChanged: (newRole) async {
        if (newRole == null ||
            newRole == member.role ||
            patientId == null) return;
        try {
          await ref
              .read(patientRepositoryProvider)
              .updateMemberRole(patientId!, member.userId, newRole);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Papel atualizado com sucesso')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erro ao atualizar papel: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
          }
        }
      },
    );
  }
}
