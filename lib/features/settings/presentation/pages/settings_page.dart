import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/photo_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.editProfile),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Row(
                  children: [
                    PhotoAvatar(
                      photoUrl: user?.photoUrl,
                      fallbackLetter: user?.displayName ?? '?',
                      radius: AppSpacing.avatarMd / 2,
                    ),
                    AppSpacing.horizontalLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Usuário',
                            style: theme.textTheme.titleMedium,
                          ),
                          AppSpacing.verticalXs,
                          Text(
                            user?.email ?? '',
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
          ),
          AppSpacing.verticalXl,
          _SettingsSection(
            title: 'Conta',
            children: [
              _SettingsTile(
                icon: Icons.person_outlined,
                title: 'Editar perfil',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              _SettingsTile(
                icon: Icons.lock_outlined,
                title: 'Alterar senha',
                onTap: () => _showChangePasswordDialog(context, ref),
              ),
            ],
          ),
          AppSpacing.verticalLg,
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsTile(
                icon: Icons.info_outlined,
                title: 'Sobre o Oldy',
                subtitle: 'Versão 1.0.0',
                onTap: () => context.push(AppRoutes.about),
              ),
            ],
          ),
          AppSpacing.verticalXl,
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja realmente sair da sua conta?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
            icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            label: Text('Sair', style: TextStyle(color: theme.colorScheme.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Text(
          'Enviaremos um e-mail para ${user.email} com instruções para alterar sua senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(authRepositoryProvider)
                    .sendPasswordReset(user.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail de redefinição enviado!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar e-mail'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
