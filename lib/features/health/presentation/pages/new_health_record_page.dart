import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_log.dart';
import '../providers/health_providers.dart';

class NewHealthRecordPage extends ConsumerStatefulWidget {
  final String? initialMetricType;

  const NewHealthRecordPage({super.key, this.initialMetricType});

  @override
  ConsumerState<NewHealthRecordPage> createState() =>
      _NewHealthRecordPageState();
}

class _NewHealthRecordPageState extends ConsumerState<NewHealthRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late HealthMetricType _selectedType;
  final _valueController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialMetricType != null
        ? HealthMetricType.values.byName(widget.initialMetricType!)
        : HealthMetricType.heartRate;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isBloodPressure =>
      _selectedType == HealthMetricType.bloodPressure;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String? _validateNumeric(String? value, double min, double max) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Valor inválido';
    if (number < min || number > max) {
      return 'Deve ser entre ${min.toInt()} e ${max.toInt()}';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum paciente selecionado')),
      );
      return;
    }

    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _saving = true);

    try {
      final measuredAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final Map<String, dynamic> values;
      if (_isBloodPressure) {
        values = {
          'systolic': double.parse(_systolicController.text.trim()),
          'diastolic': double.parse(_diastolicController.text.trim()),
        };
      } else {
        values = {'value': double.parse(_valueController.text.trim())};
      }

      final log = HealthLog(
        id: const Uuid().v4(),
        metricType: _selectedType,
        values: values,
        measuredAt: measuredAt,
        source: HealthLogSource.manual,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
      );

      await ref.read(healthRepositoryProvider).addHealthLog(patientId, log);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(healthPlanProvider).valueOrNull ?? [];
    final availableTypes = plan.isNotEmpty
        ? plan.map((m) => m.metricType).toList()
        : HealthMetricType.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Registro')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            DropdownButtonFormField<HealthMetricType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de métrica',
                prefixIcon: Icon(Icons.monitor_heart_outlined),
              ),
              items: availableTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20, color: type.color),
                      AppSpacing.horizontalSm,
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _valueController.clear();
                    _systolicController.clear();
                    _diastolicController.clear();
                  });
                }
              },
            ),
            AppSpacing.verticalXl,

            if (_isBloodPressure) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sistólica',
                        suffixText: 'mmHg',
                      ),
                      validator: (v) => _validateNumeric(v, 50, 250),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diastólica',
                        suffixText: 'mmHg',
                      ),
                      validator: (v) => _validateNumeric(v, 30, 150),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor',
                  suffixText: _selectedType.unit,
                  prefixIcon: Icon(_selectedType.icon),
                ),
                validator: (v) => _validateNumeric(
                  v,
                  _selectedType.defaultMin * 0.5,
                  _selectedType.defaultMax * 2,
                ),
              ),
            ],
            AppSpacing.verticalXl,

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/'
                      '${_selectedDate.month.toString().padLeft(2, '0')}/'
                      '${_selectedDate.year}',
                    ),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                      '${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalXl,

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Notas sobre a medição (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            AppSpacing.verticalXxxl,

            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar registro'),
            ),
          ],
        ),
      ),
    );
  }
}
