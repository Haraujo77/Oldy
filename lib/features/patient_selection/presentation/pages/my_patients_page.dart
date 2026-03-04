import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../../core/widgets/photo_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../management/domain/entities/patient.dart';
import '../../../management/presentation/providers/patient_providers.dart';

class MyPatientsPage extends ConsumerWidget {
  const MyPatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(myPatientsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Velhinhos'),
        automaticallyImplyLeading: false,
        actions: [
          _InviteBadgeButton(ref: ref),
          GestureDetector(
            onTap: () => context.push(AppRoutes.settings),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PhotoAvatar(
                photoUrl: user?.photoUrl,
                fallbackLetter: user?.displayName ?? 'U',
                radius: 16,
              ),
            ),
          ),
        ],
      ),
      body: patientsAsync.when(
        loading: () => const OldyLoading(message: 'Carregando pacientes...'),
        error: (e, _) => OldyEmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Bem-vindo ao Oldy!',
          subtitle:
              'Adicione seu primeiro paciente para começar a cuidar de quem você ama.',
          actionLabel: 'Adicionar paciente',
          onAction: () => context.push(AppRoutes.createPatient),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return OldyEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Bem-vindo ao Oldy!',
              subtitle:
                  'Adicione seu primeiro paciente para começar a cuidar de quem você ama.',
              actionLabel: 'Adicionar paciente',
              onAction: () => context.push(AppRoutes.createPatient),
            );
          }
          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: patients.length,
            separatorBuilder: (_, i) => AppSpacing.verticalMd,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return _PatientCard(
                patient: patient,
                onTap: () {
                  ref.read(selectedPatientIdProvider.notifier).state =
                      patient.id;
                  context.go(AppRoutes.home);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createPatient),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo paciente'),
      ),
    );
  }
}

class _InviteBadgeButton extends StatelessWidget {
  final WidgetRef ref;
  const _InviteBadgeButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        ref.watch(pendingInvitesForUserProvider).valueOrNull?.length ?? 0;

    return IconButton(
      icon: Badge(
        isLabelVisible: pendingCount > 0,
        label: Text('$pendingCount'),
        child: const Icon(Icons.mail_outlined),
      ),
      tooltip: 'Convites',
      onPressed: () => context.push(AppRoutes.acceptInvite),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = (patient.nickname?.isNotEmpty == true)
        ? patient.nickname!
        : patient.fullName;

    final subtitleParts = <String>[];
    subtitleParts.add('${patient.age} anos');
    if (patient.sexInitial.isNotEmpty) {
      subtitleParts.add('(${patient.sexInitial})');
    }

    String subtitle = subtitleParts.join(' ');
    if (patient.location != null && patient.location!.isNotEmpty) {
      subtitle += ', ${patient.location!.toLowerCase()}';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              PhotoAvatar(
                photoUrl: patient.photoUrl,
                fallbackLetter: patient.fullName,
                radius: AppSpacing.avatarMd / 2,
              ),
              AppSpacing.horizontalLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
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
    );
  }
}
