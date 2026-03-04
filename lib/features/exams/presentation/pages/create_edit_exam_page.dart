import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/clinical_exam.dart';
import '../providers/exam_providers.dart';

class CreateEditExamPage extends ConsumerStatefulWidget {
  final ClinicalExam? existing;

  const CreateEditExamPage({super.key, this.existing});

  @override
  ConsumerState<CreateEditExamPage> createState() =>
      _CreateEditExamPageState();
}

class _CreateEditExamPageState extends ConsumerState<CreateEditExamPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _labCtrl;
  late final TextEditingController _notesCtrl;
  late ExamCategory _category;
  late DateTime _examDate;
  List<String> _existingPhotoUrls = [];
  final List<XFile> _newPhotos = [];
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.existing != null;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.examName ?? '');
    _labCtrl = TextEditingController(text: e?.labName ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? ExamCategory.bloodWork;
    _examDate = e?.examDate ?? DateTime.now();
    _existingPhotoUrls = List<String>.from(e?.photoUrls ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _labCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      _markDirty();
      setState(() => _examDate = picked);
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (images.isNotEmpty) {
      _markDirty();
      setState(() => _newPhotos.addAll(images));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(examRepositoryProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final examId = widget.existing?.id ?? const Uuid().v4();

      final uploadedUrls = <String>[];
      for (final photo in _newPhotos) {
        final url =
            await repo.uploadExamPhoto(patientId, examId, photo.path);
        uploadedUrls.add(url);
      }

      final allPhotos = [..._existingPhotoUrls, ...uploadedUrls];

      final exam = ClinicalExam(
        id: examId,
        examName: _nameCtrl.text.trim(),
        category: _category,
        examDate: _examDate,
        labName: _labCtrl.text.trim().isEmpty
            ? null
            : _labCtrl.text.trim(),
        photoUrls: allPhotos,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        createdBy: widget.existing?.createdBy ?? currentUser?.uid ?? '',
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await repo.updateExam(patientId, exam);
      } else {
        await repo.addExam(patientId, exam);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Exame atualizado!' : 'Exame adicionado!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('permission-denied') ? 'Sem permissão para adicionar exames a este paciente.' : 'Erro ao salvar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(_isEditing ? 'Editar Exame' : 'Novo Exame'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: ListView(
            padding: AppSpacing.paddingScreen,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do exame *',
                  hintText: 'Ex: Hemograma, Raio-X Tórax',
                  prefixIcon: Icon(Icons.science_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Obrigatório'
                    : null,
              ),
              AppSpacing.verticalLg,

              DropdownButtonFormField<ExamCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExamCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _markDirty();
                    setState(() => _category = v);
                  }
                },
              ),
              AppSpacing.verticalLg,

              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Data: ${dateFmt.format(_examDate)}'),
              ),
              AppSpacing.verticalLg,

              TextFormField(
                controller: _labCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laboratório / Clínica',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              AppSpacing.verticalLg,

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              AppSpacing.verticalXl,

              Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: AppSpacing.iconMd,
                      color: theme.colorScheme.onSurfaceVariant),
                  AppSpacing.horizontalSm,
                  Text('Fotos dos resultados',
                      style: theme.textTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '${_existingPhotoUrls.length + _newPhotos.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSm,

              if (_existingPhotoUrls.isNotEmpty ||
                  _newPhotos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingPhotoUrls.length +
                        _newPhotos.length,
                    separatorBuilder: (_, _) => AppSpacing.horizontalSm,
                    itemBuilder: (context, index) {
                      if (index < _existingPhotoUrls.length) {
                        return _photoThumbnail(
                          child: Image.network(
                            _existingPhotoUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                          onRemove: () {
                            _markDirty();
                            setState(() =>
                                _existingPhotoUrls.removeAt(index));
                          },
                        );
                      }
                      final localIdx =
                          index - _existingPhotoUrls.length;
                      return _photoThumbnail(
                        child: Image.file(
                          File(_newPhotos[localIdx].path),
                          fit: BoxFit.cover,
                        ),
                        onRemove: () {
                          _markDirty();
                          setState(
                              () => _newPhotos.removeAt(localIdx));
                        },
                      );
                    },
                  ),
                ),
                AppSpacing.verticalSm,
              ],

              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Adicionar fotos'),
              ),
              AppSpacing.verticalXxl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoThumbnail(
      {required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(width: 100, height: 100, child: child),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
