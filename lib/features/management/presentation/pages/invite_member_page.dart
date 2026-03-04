import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../domain/entities/invite.dart';
import '../providers/patient_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class InviteMemberPage extends ConsumerStatefulWidget {
  const InviteMemberPage({super.key});

  @override
  ConsumerState<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends ConsumerState<InviteMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _role = 'viewer';
  bool _loading = false;
  Invite? _createdInvite;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final patientId = ref.read(selectedPatientIdProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      if (patientId == null || user == null) {
        throw Exception('Dados insuficientes para criar convite');
      }

      final invite = await ref.read(patientRepositoryProvider).createInvite(
            patientId,
            _emailController.text.trim(),
            _role,
            user.uid,
          );

      if (mounted) {
        setState(() => _createdInvite = invite);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar convite: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyCode() {
    if (_createdInvite == null) return;
    Clipboard.setData(ClipboardData(text: _createdInvite!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UnsavedChangesGuard(
      hasUnsavedChanges: _createdInvite == null && _emailController.text.isNotEmpty,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Convidar Membro'),
          actions: [
            if (_createdInvite == null)
              TextButton(
                onPressed: _loading ? null : _handleInvite,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: _createdInvite != null
                ? _buildSuccess(theme)
                : _buildForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.verticalXl,
          Icon(Icons.person_add_outlined,
              size: 64, color: theme.colorScheme.primary),
          AppSpacing.verticalXl,
          Text(
            'Convidar para a equipe',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSm,
          Text(
            'Envie um convite para um cuidador, familiar ou profissional de saúde.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail do convidado',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          AppSpacing.verticalLg,
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(
              labelText: 'Papel',
              prefixIcon: Icon(Icons.shield_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'editor', child: Text('Editor')),
              DropdownMenuItem(
                  value: 'viewer', child: Text('Visualizador')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
          AppSpacing.verticalSm,
          _buildRoleDescription(theme),
          AppSpacing.verticalXl,
        ],
      ),
    );
  }

  Widget _buildRoleDescription(ThemeData theme) {
    final descriptions = {
      'admin': 'Pode editar dados, gerenciar membros e excluir o paciente.',
      'editor': 'Pode editar dados e registros do paciente.',
      'viewer': 'Pode apenas visualizar as informações do paciente.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        descriptions[_role] ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.check_circle_outline,
            size: 72, color: theme.colorScheme.primary),
        AppSpacing.verticalXl,
        Text(
          'Convite criado!',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.verticalSm,
        Text(
          'Compartilhe o código abaixo com o convidado.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              children: [
                Text(
                  'Código do convite',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.verticalSm,
                SelectableText(
                  _createdInvite!.code,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalMd,
                OutlinedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar código'),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.verticalLg,
        Card(
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('E-mail', _createdInvite!.email, theme),
                AppSpacing.verticalSm,
                _infoRow('Papel', _roleName(_createdInvite!.role), theme),
                AppSpacing.verticalSm,
                _infoRow('Expira em', '7 dias', theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _roleName(String role) {
    return switch (role) {
      'admin' => 'Admin',
      'editor' => 'Editor',
      _ => 'Visualizador',
    };
  }
}
