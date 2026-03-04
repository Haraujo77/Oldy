import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_empty_state.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/clinical_exam.dart';
import '../providers/exam_providers.dart';

class ExamListPage extends ConsumerWidget {
  const ExamListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exames Clínicos')),
        body: const OldyEmptyState(
          icon: Icons.science_outlined,
          title: 'Nenhum paciente selecionado',
          subtitle: 'Selecione um paciente para ver os exames',
        ),
      );
    }

    final examsAsync = ref.watch(examsProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exames Clínicos')),
      body: examsAsync.when(
        loading: () => const OldyLoading(message: 'Carregando exames...'),
        error: (e, _) => OldyErrorWidget(
          message: 'Erro ao carregar exames',
          onRetry: () => ref.invalidate(examsProvider(patientId)),
        ),
        data: (exams) {
          if (exams.isEmpty) {
            return OldyEmptyState(
              icon: Icons.science_outlined,
              title: 'Nenhum exame registrado',
              subtitle: 'Adicione o primeiro exame clínico',
              actionLabel: 'Novo exame',
              onAction: () => context.push('/exams/create'),
            );
          }

          final grouped = _groupByMonth(exams);
          return ListView.builder(
            padding: AppSpacing.paddingScreen,
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped[index];
              return _MonthSection(
                label: entry.key,
                exams: entry.value,
                patientId: patientId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exams/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo exame'),
      ),
    );
  }

  List<MapEntry<String, List<ClinicalExam>>> _groupByMonth(
      List<ClinicalExam> exams) {
    final map = <String, List<ClinicalExam>>{};
    final fmt = DateFormat('MMMM yyyy', 'pt_BR');
    for (final exam in exams) {
      final key = fmt.format(exam.examDate);
      map.putIfAbsent(key, () => []).add(exam);
    }
    return map.entries.toList();
  }
}

class _MonthSection extends StatelessWidget {
  final String label;
  final List<ClinicalExam> exams;
  final String patientId;

  const _MonthSection({
    required this.label,
    required this.exams,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...exams.map((exam) => _ExamTile(exam: exam)),
      ],
    );
  }
}

class _ExamTile extends StatelessWidget {
  final ClinicalExam exam;

  const _ExamTile({required this.exam});

  IconData _categoryIcon(ExamCategory cat) => switch (cat) {
        ExamCategory.bloodWork => Icons.bloodtype_outlined,
        ExamCategory.imaging => Icons.image_search_outlined,
        ExamCategory.cardiology => Icons.monitor_heart_outlined,
        ExamCategory.urology => Icons.health_and_safety_outlined,
        ExamCategory.ophthalmology => Icons.visibility_outlined,
        ExamCategory.neurology => Icons.psychology_outlined,
        ExamCategory.other => Icons.science_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push('/exams/${exam.id}', extra: exam),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _categoryIcon(exam.category),
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalXs,
                    Row(
                      children: [
                        Text(
                          exam.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (exam.labName != null &&
                            exam.labName!.isNotEmpty) ...[
                          Text(
                            ' · ${exam.labName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFmt.format(exam.examDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (exam.photoUrls.isNotEmpty) ...[
                    AppSpacing.verticalXs,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${exam.photoUrls.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              AppSpacing.horizontalXs,
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
