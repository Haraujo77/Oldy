import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/activity_plan_item.dart';
import '../providers/activity_providers.dart';

class CreateEditActivityPlanPage extends ConsumerStatefulWidget {
  final ActivityPlanItem? existing;

  const CreateEditActivityPlanPage({super.key, this.existing});

  @override
  ConsumerState<CreateEditActivityPlanPage> createState() =>
      _CreateEditActivityPlanPageState();
}

class _CreateEditActivityPlanPageState
    extends ConsumerState<CreateEditActivityPlanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _category;
  late String _frequencyType;
  late int _intervalHours;
  late List<TimeOfDay> _fixedTimes;
  late Set<int> _selectedDays;
  late bool _continuous;
  late DateTime _startDate;
  DateTime? _endDate;
  int? _durationMinutes;
  late final TextEditingController _notesCtrl;

  bool get _isEditing => widget.existing != null;

  static const _categories = [
    'Banho',
    'Alimentação',
    'Fisioterapia',
    'Hemodiálise',
    'Exercício',
    'Visita médica',
    'Visita familiar',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.activityName ?? '');
    _category = e?.category ?? _categories.first;
    _frequencyType = e?.frequencyType ?? 'fixed';
    _intervalHours = e?.intervalHours ?? 4;
    _fixedTimes = e?.scheduledTimes.map(_parseTime).toList() ??
        [const TimeOfDay(hour: 8, minute: 0)];
    _selectedDays = e?.daysOfWeek.toSet() ?? {1, 2, 3, 4, 5, 6, 7};
    _continuous = e?.continuous ?? true;
    _startDate = e?.startDate ?? DateTime.now();
    _endDate = e?.endDate;
    _durationMinutes = e?.durationMinutes;
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fixedTimes[index],
    );
    if (picked != null) {
      setState(() => _fixedTimes[index] = picked);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildDurationPicker(ThemeData theme) {
    String label;
    if (_durationMinutes == null) {
      label = 'Sem duração';
    } else {
      final h = _durationMinutes! ~/ 60;
      final m = _durationMinutes! % 60;
      label = h > 0
          ? (m > 0 ? '${h}h ${m}min' : '${h}h')
          : '${m}min';
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined,
            size: AppSpacing.iconMd,
            color: theme.colorScheme.onSurfaceVariant),
        AppSpacing.horizontalSm,
        Text('Duração', style: theme.textTheme.titleSmall),
        const Spacer(),
        ActionChip(
          label: Text(label),
          avatar: const Icon(Icons.edit_outlined, size: 16),
          onPressed: () async {
            int hours = (_durationMinutes ?? 30) ~/ 60;
            int minutes = (_durationMinutes ?? 30) % 60;

            final result = await showDialog<int>(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (ctx, setDialogState) => AlertDialog(
                  title: const Text('Duração da atividade'),
                  content: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Horas'),
                            DropdownButton<int>(
                              value: hours,
                              items: List.generate(
                                  13,
                                  (i) => DropdownMenuItem(
                                      value: i, child: Text('$i'))),
                              onChanged: (v) =>
                                  setDialogState(() => hours = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Minutos'),
                            DropdownButton<int>(
                              value: minutes,
                              items: [0, 5, 10, 15, 20, 30, 45]
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text('$m')))
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => minutes = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, hours * 60 + minutes),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ),
            );
            if (result != null) {
              setState(() => _durationMinutes = result == 0 ? null : result);
            }
          },
        ),
        if (_durationMinutes != null)
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 18, color: theme.colorScheme.error),
            onPressed: () => setState(() => _durationMinutes = null),
            tooltip: 'Remover duração',
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) return;

    final currentUser = ref.read(authStateProvider).valueOrNull;

    final item = ActivityPlanItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      activityName: _nameCtrl.text.trim(),
      category: _category,
      frequencyType: _frequencyType,
      intervalHours: _frequencyType == 'interval' ? _intervalHours : null,
      scheduledTimes: _fixedTimes.map(_fmtTime).toList()..sort(),
      daysOfWeek:
          _frequencyType == 'weekly' ? (_selectedDays.toList()..sort()) : [],
      startDate: _startDate,
      endDate: _continuous ? null : _endDate,
      continuous: _continuous,
      durationMinutes: _durationMinutes,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdBy: widget.existing?.createdBy ?? currentUser?.uid,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      final repo = ref.read(activityRepositoryProvider);
      if (_isEditing) {
        await repo.updateActivityPlan(patientId, item);
      } else {
        await repo.addActivityPlan(patientId, item);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Atividade atualizada'
                  : 'Atividade adicionada')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Atividade' : 'Nova Atividade'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da atividade',
                hintText: 'Ex: Café da manhã, Banho, Fisioterapia',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            AppSpacing.verticalLg,

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            AppSpacing.verticalLg,

            Text('Frequência', style: theme.textTheme.titleSmall),
            AppSpacing.verticalSm,
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'fixed', label: Text('Horários fixos')),
                ButtonSegment(
                    value: 'interval', label: Text('Intervalo')),
                ButtonSegment(value: 'weekly', label: Text('Semanal')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (v) =>
                  setState(() => _frequencyType = v.first),
            ),
            AppSpacing.verticalLg,

            if (_frequencyType == 'fixed' || _frequencyType == 'weekly') ...[
              Row(
                children: [
                  Text('Horários', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: () => setState(() =>
                        _fixedTimes.add(const TimeOfDay(hour: 12, minute: 0))),
                  ),
                ],
              ),
              ..._fixedTimes.asMap().entries.map((entry) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(_fmtTime(entry.value)),
                  trailing: _fixedTimes.length > 1
                      ? IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: theme.colorScheme.error),
                          onPressed: () =>
                              setState(() => _fixedTimes.removeAt(entry.key)),
                        )
                      : null,
                  onTap: () => _pickTime(entry.key),
                );
              }),
              AppSpacing.verticalMd,
            ],

            if (_frequencyType == 'interval') ...[
              Row(
                children: [
                  Text('A cada', style: theme.textTheme.titleSmall),
                  AppSpacing.horizontalMd,
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<int>(
                      value: _intervalHours,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [2, 3, 4, 6, 8, 12]
                          .map((h) => DropdownMenuItem(
                              value: h, child: Text('${h}h')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _intervalHours = v ?? 4),
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalMd,
              Row(
                children: [
                  Text('Início às', style: theme.textTheme.titleSmall),
                  AppSpacing.horizontalMd,
                  ActionChip(
                    label: Text(_fmtTime(_fixedTimes.first)),
                    onPressed: () => _pickTime(0),
                  ),
                ],
              ),
              AppSpacing.verticalMd,
            ],

            if (_frequencyType == 'weekly') ...[
              Text('Dias da semana', style: theme.textTheme.titleSmall),
              AppSpacing.verticalSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final entry in {
                    1: 'Seg',
                    2: 'Ter',
                    3: 'Qua',
                    4: 'Qui',
                    5: 'Sex',
                    6: 'Sáb',
                    7: 'Dom'
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _selectedDays.contains(entry.key),
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedDays.add(entry.key);
                          } else {
                            _selectedDays.remove(entry.key);
                          }
                        });
                      },
                    ),
                ],
              ),
              AppSpacing.verticalMd,
            ],

            const Divider(),
            AppSpacing.verticalMd,

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contínuo'),
              subtitle: const Text('Sem data de término'),
              value: _continuous,
              onChanged: (v) => setState(() => _continuous = v),
            ),
            AppSpacing.verticalSm,

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Data de início'),
              subtitle: Text(
                '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
              ),
              onTap: () => _pickDate(isStart: true),
            ),

            if (!_continuous)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Data de término'),
                subtitle: Text(
                  _endDate != null
                      ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                      : 'Não definida',
                ),
                onTap: () => _pickDate(isStart: false),
              ),

            AppSpacing.verticalLg,
            _buildDurationPicker(theme),
            AppSpacing.verticalLg,
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Instruções especiais...',
              ),
              maxLines: 3,
            ),
            AppSpacing.verticalXxl,
          ],
        ),
      ),
    );
  }
}
