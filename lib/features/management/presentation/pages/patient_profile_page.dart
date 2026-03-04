import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_member.dart';
import '../providers/patient_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exams/presentation/providers/exam_providers.dart';

class PatientProfilePage extends ConsumerWidget {
  const PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patientAsync = ref.watch(selectedPatientProvider);
    final membersAsync = ref.watch(patientMembersProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return patientAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Erro ao carregar paciente: $e'),
        ),
      ),
      data: (patient) {
        if (patient == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Paciente não encontrado')),
          );
        }

        final isAdmin = membersAsync.valueOrNull?.any(
              (m) => m.userId == currentUser?.uid && m.role == 'admin',
            ) ??
            false;

        return Scaffold(
          appBar: AppBar(
            title: Text(patient.nickname ?? patient.fullName),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => context.push('/edit-patient'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme, patient),
                AppSpacing.verticalXl,
                _buildBasicInfoSection(theme, patient),
                AppSpacing.verticalLg,
                if (patient.conditions.isNotEmpty) ...[
                  _buildChipsSection(
                    theme,
                    'Condições de saúde',
                    Icons.medical_services_outlined,
                    patient.conditions,
                  ),
                  AppSpacing.verticalLg,
                ],
                if (patient.allergies.isNotEmpty) ...[
                  _buildChipsSection(
                    theme,
                    'Alergias',
                    Icons.warning_amber_outlined,
                    patient.allergies,
                  ),
                  AppSpacing.verticalLg,
                ],
                if (patient.emergencyContacts.isNotEmpty) ...[
                  _buildContactsSection(theme, patient.emergencyContacts),
                  AppSpacing.verticalLg,
                ],
                if (patient.clinicalNotes != null &&
                    patient.clinicalNotes!.isNotEmpty) ...[
                  _buildNotesSection(theme, patient.clinicalNotes!),
                  AppSpacing.verticalLg,
                ],
                _buildExamsSection(context, theme, ref),
                AppSpacing.verticalLg,
                _buildMembersSection(context, theme, membersAsync),
                AppSpacing.verticalXl,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, Patient patient) {
    final age = DateTime.now().difference(patient.dateOfBirth).inDays ~/ 365;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: AppSpacing.avatarLg / 2,
            backgroundImage: patient.photoUrl != null
                ? NetworkImage(patient.photoUrl!)
                : null,
            child: patient.photoUrl == null
                ? Icon(Icons.person, size: AppSpacing.iconLg)
                : null,
          ),
          AppSpacing.verticalMd,
          Text(
            patient.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (patient.nickname != null) ...[
            AppSpacing.verticalXs,
            Text(
              '"${patient.nickname}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          AppSpacing.verticalXs,
          Text(
            '$age anos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme, Patient patient) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final sexLabel = {
      'masculino': 'Masculino',
      'feminino': 'Feminino',
      'outro': 'Outro',
    };

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações básicas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.verticalMd,
            _infoRow(Icons.calendar_today_outlined, 'Data de nascimento',
                dateFormat.format(patient.dateOfBirth), theme),
            AppSpacing.verticalSm,
            _infoRow(Icons.wc_outlined, 'Sexo',
                sexLabel[patient.sex] ?? patient.sex, theme),
            if (patient.location != null &&
                patient.location!.isNotEmpty) ...[
              AppSpacing.verticalSm,
              _infoRow(Icons.location_on_outlined, 'Localização',
                  patient.location!, theme),
            ],
            if (patient.responsibleDoctor != null &&
                patient.responsibleDoctor!.isNotEmpty) ...[
              AppSpacing.verticalSm,
              _infoRow(Icons.local_hospital_outlined, 'Médico responsável',
                  patient.responsibleDoctor!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSm,
            color: theme.colorScheme.onSurfaceVariant),
        AppSpacing.horizontalSm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildChipsSection(
      ThemeData theme, String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSpacing.iconSm,
                    color: theme.colorScheme.primary),
                AppSpacing.horizontalSm,
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection(
      ThemeData theme, List<Map<String, String>> contacts) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.error),
                AppSpacing.horizontalSm,
                Text(
                  'Contatos de emergência',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            ...contacts.map((contact) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.person_outlined, size: AppSpacing.iconSm),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['nome'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (contact['relacao']?.isNotEmpty == true)
                            Text(
                              contact['relacao']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (contact['telefone']?.isNotEmpty == true)
                      Text(
                        contact['telefone']!,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme, String notes) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.primary),
                AppSpacing.horizontalSm,
                Text(
                  'Observações clínicas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Text(notes, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final examsAsync = ref.watch(patientExamsProvider);
    final examCount = examsAsync.valueOrNull?.length ?? 0;
    final lastExam = examsAsync.valueOrNull?.isNotEmpty == true
        ? examsAsync.valueOrNull!.first
        : null;

    String subtitle;
    if (examCount == 0) {
      subtitle = 'Nenhum exame registrado';
    } else {
      final dateFmt = DateFormat('dd/MM/yyyy');
      subtitle =
          '$examCount ${examCount == 1 ? 'exame' : 'exames'} · Último: ${dateFmt.format(lastExam!.examDate)}';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(AppRoutes.exams),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Icon(Icons.science_outlined,
                  size: AppSpacing.iconMd,
                  color: theme.colorScheme.tertiary),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exames Clínicos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<PatientMember>> membersAsync,
  ) {
    final memberCount = membersAsync.valueOrNull?.length ?? 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(AppRoutes.members),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Icon(Icons.group_outlined,
                  size: AppSpacing.iconMd,
                  color: theme.colorScheme.primary),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membros da equipe',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$memberCount ${memberCount == 1 ? 'membro' : 'membros'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
