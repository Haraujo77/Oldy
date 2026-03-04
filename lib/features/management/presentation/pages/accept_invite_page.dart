import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_patient_repository.dart';
import '../../domain/entities/invite.dart';
import '../providers/patient_providers.dart';

class AcceptInvitePage extends ConsumerStatefulWidget {
  const AcceptInvitePage({super.key});

  @override
  ConsumerState<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends ConsumerState<AcceptInvitePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      await ref.read(patientRepositoryProvider).acceptInvite(
            _codeController.text.trim().toUpperCase(),
            user.uid,
          );

      ref.invalidate(myPatientsProvider);
      ref.invalidate(pendingInvitesForUserProvider);

      if (mounted) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite aceito! Paciente adicionado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptInvite(Invite invite) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(patientRepositoryProvider).acceptInvite(
            invite.code,
            user.uid,
          );

      ref.invalidate(myPatientsProvider);
      ref.invalidate(pendingInvitesForUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite aceito! Paciente adicionado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissInvite(Invite invite) async {
    try {
      await (ref.read(patientRepositoryProvider) as FirebasePatientRepository)
          .dismissInvite(invite.patientId, invite.id);
      ref.invalidate(pendingInvitesForUserProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingInvites = ref.watch(pendingInvitesForUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Convites')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // -- Pending invites section --
            pendingInvites.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => const SizedBox.shrink(),
              data: (invites) {
                if (invites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.verticalMd,
                    Row(
                      children: [
                        Icon(Icons.mail_outlined,
                            size: 20, color: theme.colorScheme.primary),
                        AppSpacing.horizontalSm,
                        Text(
                          'Convites pendentes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalMd,
                    ...invites.map((invite) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _PendingInviteCard(
                            invite: invite,
                            repo: ref.read(patientRepositoryProvider)
                                as FirebasePatientRepository,
                            onAccept: () => _acceptInvite(invite),
                            onDismiss: () => _dismissInvite(invite),
                          ),
                        )),
                    const Divider(height: 32),
                  ],
                );
              },
            ),

            // -- Manual code entry section --
            AppSpacing.verticalLg,
            Row(
              children: [
                Icon(Icons.key_rounded,
                    size: 20, color: theme.colorScheme.primary),
                AppSpacing.horizontalSm,
                Text(
                  'Inserir código',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSm,
            Text(
              'Insira o código de convite que você recebeu para acessar os dados do paciente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.verticalLg,
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Código do convite',
                      hintText: 'Ex: A1B2C3D4',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Insira o código';
                      if (v.trim().length < 6) return 'Código muito curto';
                      return null;
                    },
                  ),
                  AppSpacing.verticalLg,
                  FilledButton(
                    onPressed: _loading ? null : _handleAcceptCode,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }
}

class _PendingInviteCard extends StatefulWidget {
  final Invite invite;
  final FirebasePatientRepository repo;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _PendingInviteCard({
    required this.invite,
    required this.repo,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<_PendingInviteCard> createState() => _PendingInviteCardState();
}

class _PendingInviteCardState extends State<_PendingInviteCard> {
  String? _patientName;
  bool _loadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientName();
  }

  Future<void> _fetchPatientName() async {
    final name =
        await widget.repo.getPatientDisplayName(widget.invite.patientId);
    if (mounted) {
      setState(() {
        _patientName = name;
        _loadingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invite = widget.invite;
    final roleLabel = {
      'admin': 'Administrador',
      'editor': 'Editor',
      'viewer': 'Visualizador',
    };

    final daysLeft = invite.expiresAt.difference(DateTime.now()).inDays;
    final expiryText = daysLeft > 1
        ? 'Expira em $daysLeft dias'
        : daysLeft == 1
            ? 'Expira amanhã'
            : 'Expira hoje';

    return Card(
      clipBehavior: Clip.antiAlias,
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _loadingName
                          ? SizedBox(
                              height: 16,
                              width: 120,
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          : Text(
                              _patientName ?? 'Paciente',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      const SizedBox(height: 2),
                      Text(
                        '${roleLabel[invite.role] ?? invite.role} · $expiryText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDismiss,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Ignorar'),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onAccept,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
