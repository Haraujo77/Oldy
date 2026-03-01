import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';

class MyPatientsPage extends StatelessWidget {
  const MyPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with Riverpod provider for patient list
    final patients = <_PatientPreview>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: patients.isEmpty
          ? OldyEmptyState(
              icon: Icons.people_outlined,
              title: 'Nenhum paciente ainda',
              subtitle: 'Adicione um paciente para começar a usar o Oldy',
              actionLabel: 'Adicionar paciente',
              onAction: () {
                // TODO: Navigate to create patient
              },
            )
          : ListView.separated(
              padding: AppSpacing.paddingScreen,
              itemCount: patients.length,
              separatorBuilder: (_, _) => AppSpacing.verticalMd,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return _PatientCard(
                  patient: patient,
                  onTap: () => context.go(AppRoutes.home),
                );
              },
            ),
      floatingActionButton: patients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to create patient
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo paciente'),
            )
          : null,
    );
  }
}

class _PatientPreview {
  final String id;
  final String name;
  final String? photoUrl;
  final String status;

  const _PatientPreview({
    required this.id,
    required this.name,
    required this.status,
    this.photoUrl,
  });
}

// Suppress warning for now - photoUrl will be used when patient data is loaded

class _PatientCard extends StatelessWidget {
  final _PatientPreview patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarMd / 2,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
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
                      patient.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      patient.status,
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
    );
  }
}
