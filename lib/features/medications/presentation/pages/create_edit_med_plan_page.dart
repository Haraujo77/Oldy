import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/med_plan_item.dart';
import '../providers/medication_providers.dart';
import 'medication_search_page.dart';

class CreateEditMedPlanPage extends ConsumerStatefulWidget {
  final String patientId;
  final MedPlanItem? existing;

  const CreateEditMedPlanPage({
    super.key,
    required this.patientId,
    this.existing,
  });

  @override
  ConsumerState<CreateEditMedPlanPage> createState() =>
      _CreateEditMedPlanPageState();
}

class _CreateEditMedPlanPageState extends ConsumerState<CreateEditMedPlanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ingredientCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _notesCtrl;

  final _imageService = ImageUploadService();
  String _form = AppConstants.medicationForms.first;
  String _frequencyType = 'fixed';
  int _intervalHours = 8;
  final List<String> _scheduledTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _continuous = false;
  bool _saving = false;
  bool _dirty = false;
  String? _localImagePath;
  String? _existingPhotoUrl;

  bool get _isEditing => widget.existing != null;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.medicationName ?? '');
    _ingredientCtrl =
        TextEditingController(text: e?.activeIngredient ?? '');
    _dosageCtrl = TextEditingController(text: e?.dosage ?? '');
    _instructionsCtrl =
        TextEditingController(text: e?.instructions ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    if (e != null) {
      _form = e.form;
      _frequencyType = e.frequencyType;
      _intervalHours = e.intervalHours ?? 8;
      _scheduledTimes.addAll(e.scheduledTimes);
      _startDate = e.startDate;
      _endDate = e.endDate;
      _continuous = e.continuous;
      _existingPhotoUrl = e.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingredientCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!_scheduledTimes.contains(formatted)) {
      setState(() {
        _scheduledTimes.add(formatted);
        _scheduledTimes.sort();
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await _imageService.pickImage(source: source);
    if (image != null) {
      setState(() => _localImagePath = image.path);
    }
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const MedicationSearchPage()),
    );
    if (result != null && mounted) {
      setState(() {
        _nameCtrl.text = result['name'] ?? '';
        _ingredientCtrl.text = result['activeIngredient'] ?? '';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(medicationRepositoryProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final medId = widget.existing?.id ?? const Uuid().v4();

      String? photoUrl = _existingPhotoUrl;
      if (_localImagePath != null) {
        photoUrl = await _imageService.uploadMedicationPhoto(
          widget.patientId,
          medId,
          XFile(_localImagePath!),
        );
      }

      final item = MedPlanItem(
        id: medId,
        medicationName: _nameCtrl.text.trim(),
        activeIngredient: _ingredientCtrl.text.trim().isEmpty
            ? null
            : _ingredientCtrl.text.trim(),
        form: _form,
        dosage: _dosageCtrl.text.trim(),
        frequencyType: _frequencyType,
        intervalHours:
            _frequencyType == 'interval' ? _intervalHours : null,
        scheduledTimes: _scheduledTimes,
        startDate: _startDate,
        endDate: _continuous ? null : _endDate,
        continuous: _continuous,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        photoUrl: photoUrl,
        createdBy: widget.existing?.createdBy ?? currentUser?.uid,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await repo.updateMedPlanItem(widget.patientId, item);
      } else {
        await repo.addMedPlanItem(widget.patientId, item);
        await repo.generateTodayDoses(widget.patientId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Medicamento atualizado!'
                : 'Medicamento adicionado!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('permission-denied') ? 'Sem permissão para alterar medicamentos deste paciente.' : 'Erro ao salvar: $e'),
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

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar medicamento' : 'Novo medicamento'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
            // ── Name with search ──
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nome do medicamento *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Buscar no catálogo',
                  onPressed: _openSearch,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            AppSpacing.verticalLg,

            // ── Active ingredient ──
            TextFormField(
              controller: _ingredientCtrl,
              decoration:
                  const InputDecoration(labelText: 'Princípio ativo'),
            ),
            AppSpacing.verticalLg,

            // ── Form dropdown ──
            DropdownButtonFormField<String>(
              value: _form,
              decoration: const InputDecoration(labelText: 'Forma'),
              items: AppConstants.medicationForms
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _form = v);
              },
            ),
            AppSpacing.verticalLg,

            // ── Dosage ──
            TextFormField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosagem *',
                hintText: 'Ex: 500mg, 20 gotas',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            AppSpacing.verticalXxl,

            // ── Frequency type ──
            Text('Frequência', style: theme.textTheme.titleSmall),
            AppSpacing.verticalSm,
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'fixed',
                  label: Text('Horários fixos'),
                  icon: Icon(Icons.schedule_rounded),
                ),
                ButtonSegment(
                  value: 'interval',
                  label: Text('Intervalo'),
                  icon: Icon(Icons.timer_rounded),
                ),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (v) =>
                  setState(() => _frequencyType = v.first),
            ),
            AppSpacing.verticalLg,

            if (_frequencyType == 'interval') ...[
              Row(
                children: [
                  Text('A cada', style: theme.textTheme.bodyMedium),
                  AppSpacing.horizontalMd,
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<int>(
                      value: _intervalHours,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [4, 6, 8, 12, 24]
                          .map((h) => DropdownMenuItem(
                              value: h, child: Text('${h}h')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _intervalHours = v);
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSm,
              Text(
                'Horário da primeira dose:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            AppSpacing.verticalSm,

            // ── Scheduled times ──
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ..._scheduledTimes.map(
                  (t) => Chip(
                    label: Text(t),
                    deleteIcon:
                        const Icon(Icons.close_rounded, size: 16),
                    onDeleted: () =>
                        setState(() => _scheduledTimes.remove(t)),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Horário'),
                  onPressed: _pickTime,
                ),
              ],
            ),
            AppSpacing.verticalXxl,

            // ── Period ──
            Text('Período', style: theme.textTheme.titleSmall),
            AppSpacing.verticalSm,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Uso contínuo'),
              value: _continuous,
              onChanged: (v) => setState(() => _continuous = v),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(_fmtDate(_startDate)),
                  ),
                ),
                if (!_continuous) ...[
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.calendar_today_rounded,
                          size: 18),
                      label: Text(
                        _endDate != null
                            ? _fmtDate(_endDate!)
                            : 'Data final',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.verticalXxl,

            // ── Instructions ──
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Instruções',
                hintText: 'Ex: Tomar em jejum',
              ),
              maxLines: 2,
            ),
            AppSpacing.verticalLg,

            // ── Notes ──
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observações',
              ),
              maxLines: 2,
            ),
            AppSpacing.verticalLg,

            // ── Photo ──
            if (_localImagePath != null || _existingPhotoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: _localImagePath != null
                    ? Image.file(
                        File(_localImagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _existingPhotoUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
              AppSpacing.verticalSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Trocar foto'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _localImagePath = null;
                      _existingPhotoUrl = null;
                    }),
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: theme.colorScheme.error),
                    label: Text('Remover',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Adicionar foto'),
              ),
            AppSpacing.verticalXxl,
          ],
        ),
      ),
    ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
