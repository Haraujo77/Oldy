import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../management/presentation/providers/patient_providers.dart';

class MyPatientsPage extends ConsumerWidget {
  const MyPatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patientsAsync = ref.watch(myPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: patientsAsync.when(
        loading: () => const OldyLoading(message: 'Carregando pacientes...'),
        error: (e, _) => OldyErrorWidget(
          message: 'Erro ao carregar pacientes',
          onRetry: () => ref.invalidate(myPatientsProvider),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return OldyEmptyState(
              icon: Icons.people_outlined,
              title: 'Nenhum paciente ainda',
              subtitle: 'Adicione um paciente para começar a usar o Oldy',
              actionLabel: 'Adicionar paciente',
              onAction: () => context.push(AppRoutes.createPatient),
            );
          }
          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: patients.length,
            separatorBuilder: (_, _) => AppSpacing.verticalMd,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ref.read(selectedPatientIdProvider.notifier).state =
                        patient.id;
                    context.go(AppRoutes.home);
                  },
                  child: Padding(
                    padding: AppSpacing.paddingCard,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: AppSpacing.avatarMd / 2,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            patient.fullName.isNotEmpty
                                ? patient.fullName[0].toUpperCase()
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
                                (patient.nickname?.isNotEmpty == true)
                                    ? patient.nickname!
                                    : patient.fullName,
                                style: theme.textTheme.titleMedium,
                              ),
                              AppSpacing.verticalXs,
                              Text(
                                patient.conditions.isNotEmpty
                                    ? patient.conditions.join(', ')
                                    : 'Sem condições registradas',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
