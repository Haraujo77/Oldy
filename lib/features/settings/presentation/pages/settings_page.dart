import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
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
          Card(
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSpacing.avatarMd / 2,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (user?.displayName.isNotEmpty == true)
                          ? user!.displayName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
                ],
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
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notificações',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.lock_outlined,
                title: 'Privacidade',
                onTap: () {},
              ),
            ],
          ),
          AppSpacing.verticalLg,
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Termos de uso',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Política de privacidade',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outlined,
                title: 'Sobre o Oldy',
                subtitle: 'Versão 1.0.0',
                onTap: () {},
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
