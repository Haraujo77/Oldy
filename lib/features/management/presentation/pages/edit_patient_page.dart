import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/patient_providers.dart';

class _ContactControllers {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final relationController = TextEditingController();

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'nome': nameController.text.trim(),
      'telefone': phoneController.text.trim(),
      'relacao': relationController.text.trim(),
    };
  }
}

class EditPatientPage extends ConsumerStatefulWidget {
  const EditPatientPage({super.key});

  @override
  ConsumerState<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends ConsumerState<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();
  final _conditionController = TextEditingController();
  final _allergyController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _sex;
  final List<String> _conditions = [];
  final List<String> _allergies = [];
  final List<_ContactControllers> _contactControllers = [];
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final patient = ref.read(selectedPatientProvider).valueOrNull;
    if (patient == null) return;

    _fullNameController.text = patient.fullName;
    _nicknameController.text = patient.nickname ?? '';
    _dateOfBirth = patient.dateOfBirth;
    _dateController.text = DateFormat('dd/MM/yyyy').format(patient.dateOfBirth);
    _sex = patient.sex;
    _conditions.addAll(patient.conditions);
    _allergies.addAll(patient.allergies);
    _doctorController.text = patient.responsibleDoctor ?? '';
    _notesController.text = patient.clinicalNotes ?? '';

    for (final contact in patient.emergencyContacts) {
      final controllers = _ContactControllers();
      controllers.nameController.text = contact['nome'] ?? '';
      controllers.phoneController.text = contact['telefone'] ?? '';
      controllers.relationController.text = contact['relacao'] ?? '';
      _contactControllers.add(controllers);
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    _conditionController.dispose();
    _allergyController.dispose();
    _dateController.dispose();
    for (final c in _contactControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _addCondition() {
    final text = _conditionController.text.trim();
    if (text.isNotEmpty && !_conditions.contains(text)) {
      setState(() {
        _conditions.add(text);
        _conditionController.clear();
      });
    }
  }

  void _addAllergy() {
    final text = _allergyController.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyController.clear();
      });
    }
  }

  void _addContact() {
    setState(() => _contactControllers.add(_ContactControllers()));
  }

  void _removeContact(int index) {
    setState(() {
      _contactControllers[index].dispose();
      _contactControllers.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de nascimento')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final existingPatient = ref.read(selectedPatientProvider).valueOrNull;
      if (existingPatient == null) {
        throw Exception('Paciente não encontrado');
      }

      final updated = existingPatient.copyWith(
        fullName: _fullNameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        sex: _sex,
        conditions: List.from(_conditions),
        allergies: List.from(_allergies),
        emergencyContacts:
            _contactControllers.map((c) => c.toMap()).toList(),
        responsibleDoctor: _doctorController.text.trim().isEmpty
            ? null
            : _doctorController.text.trim(),
        clinicalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref.read(patientRepositoryProvider).updatePatient(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente atualizado com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Paciente')),
        body: const Center(child: Text('Paciente não encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Paciente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Editar dados do paciente',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.verticalSm,
                Text(
                  'Altere as informações necessárias e salve.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _fullNameController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome completo'
                      : null,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo *',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                AppSpacing.verticalLg,

                TextFormField(
                  controller: _nicknameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Apelido',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                AppSpacing.verticalLg,

                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Data de nascimento *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        hintText: 'Toque para selecionar',
                      ),
                      validator: (_) => _dateOfBirth == null
                          ? 'Selecione a data de nascimento'
                          : null,
                    ),
                  ),
                ),
                AppSpacing.verticalLg,

                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(
                    labelText: 'Sexo *',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(
                        value: 'feminino', child: Text('Feminino')),
                    DropdownMenuItem(
                        value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                  validator: (v) => v == null ? 'Selecione o sexo' : null,
                ),
                AppSpacing.verticalXl,

                _buildChipSection(
                  label: 'Condições de saúde',
                  icon: Icons.medical_services_outlined,
                  items: _conditions,
                  controller: _conditionController,
                  onAdd: _addCondition,
                  onRemove: (i) => setState(() => _conditions.removeAt(i)),
                ),
                AppSpacing.verticalXl,

                _buildChipSection(
                  label: 'Alergias',
                  icon: Icons.warning_amber_outlined,
                  items: _allergies,
                  controller: _allergyController,
                  onAdd: _addAllergy,
                  onRemove: (i) => setState(() => _allergies.removeAt(i)),
                ),
                AppSpacing.verticalXl,

                _buildContactsSection(theme),
                AppSpacing.verticalXl,

                TextFormField(
                  controller: _doctorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Médico responsável',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                ),
                AppSpacing.verticalLg,

                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observações clínicas',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _handleSave,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar Alterações'),
                ),
                AppSpacing.verticalXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required String label,
    required IconData icon,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        AppSpacing.verticalSm,
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(items.length, (i) {
              return InputChip(
                label: Text(items[i]),
                onDeleted: () => onRemove(i),
              );
            }),
          ),
          AppSpacing.verticalSm,
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Adicionar ${label.toLowerCase()}',
                  prefixIcon: Icon(icon),
                  isDense: true,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            AppSpacing.horizontalSm,
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contatos de emergência',
              style: theme.textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        ...List.generate(_contactControllers.length, (i) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                children: [
                  TextFormField(
                    controller: _contactControllers[i].nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_outlined),
                      isDense: true,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  TextFormField(
                    controller: _contactControllers[i].phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      isDense: true,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  TextFormField(
                    controller: _contactControllers[i].relationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Relação',
                      prefixIcon: Icon(Icons.group_outlined),
                      isDense: true,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _removeContact(i),
                      icon: const Icon(Icons.delete_outlined, size: 18),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
