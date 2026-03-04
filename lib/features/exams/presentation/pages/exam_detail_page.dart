import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/clinical_exam.dart';
import '../providers/exam_providers.dart';
import 'create_edit_exam_page.dart';

class ExamDetailPage extends ConsumerWidget {
  final ClinicalExam exam;

  const ExamDetailPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final patientId = ref.watch(selectedPatientIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.examName),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_rounded, size: 20),
                  title: Text('Editar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline_rounded,
                      size: 20, color: Colors.red),
                  title:
                      Text('Apagar', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (action) {
              if (action == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEditExamPage(existing: exam),
                  ),
                );
              } else if (action == 'delete') {
                _confirmDelete(context, ref, patientId);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                      Icons.science_outlined, 'Categoria', exam.category.label, theme),
                  AppSpacing.verticalMd,
                  _infoRow(
                      Icons.calendar_today_outlined, 'Data', dateFmt.format(exam.examDate), theme),
                  if (exam.labName != null && exam.labName!.isNotEmpty) ...[
                    AppSpacing.verticalMd,
                    _infoRow(
                        Icons.local_hospital_outlined, 'Laboratório', exam.labName!, theme),
                  ],
                  if (exam.notes != null && exam.notes!.isNotEmpty) ...[
                    AppSpacing.verticalMd,
                    _infoRow(
                        Icons.notes_outlined, 'Observações', exam.notes!, theme),
                  ],
                ],
              ),
            ),
          ),
          if (exam.photoUrls.isNotEmpty) ...[
            AppSpacing.verticalLg,
            Text('Resultados', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: exam.photoUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullScreenImage(
                      context, exam.photoUrls, index),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      exam.photoUrls[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                              child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color:
                            theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          AppSpacing.verticalXl,
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: AppSpacing.iconSm,
            color: theme.colorScheme.onSurfaceVariant),
        AppSpacing.horizontalSm,
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String? patientId) {
    if (patientId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar exame'),
        content: const Text('Deseja apagar este exame?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(examRepositoryProvider)
                    .deleteExam(patientId, exam.id);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao apagar: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(
      BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          urls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatelessWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.urls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: urls.length,
        itemBuilder: (_, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
