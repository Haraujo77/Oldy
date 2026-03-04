import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/photo_avatar.dart';
import '../../domain/entities/patient.dart';
import '../providers/patient_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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

class CreatePatientPage extends ConsumerStatefulWidget {
  const CreatePatientPage({super.key});

  @override
  ConsumerState<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends ConsumerState<CreatePatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();
  final _conditionController = TextEditingController();
  final _allergyController = TextEditingController();
  final _dateController = TextEditingController();
  final _imageService = ImageUploadService();

  DateTime? _dateOfBirth;
  String? _sex;
  String? _location;
  String? _localImagePath;
  final List<String> _conditions = [];
  final List<String> _allergies = [];
  final List<_ContactControllers> _contactControllers = [];
  bool _loading = false;

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

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
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
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      final patient = Patient(
        id: '',
        fullName: _fullNameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        sex: _sex!,
        location: _location,
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
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      final created = await ref
          .read(patientRepositoryProvider)
          .createPatient(patient, user.uid);

      if (_localImagePath != null) {
        final photoUrl = await _imageService.uploadPatientPhoto(
          created.id,
          XFile(_localImagePath!),
        );
        await ref
            .read(patientRepositoryProvider)
            .updatePatient(created.copyWith(photoUrl: photoUrl));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente cadastrado com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Paciente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: PhotoAvatar(
                    localPath: _localImagePath,
                    fallbackLetter: _fullNameController.text.isNotEmpty
                        ? _fullNameController.text
                        : '?',
                    radius: 48,
                    editable: true,
                    onTap: _pickPhoto,
                  ),
                ),
                AppSpacing.verticalLg,
                Text(
                  'Dados do paciente',
                  style: theme.textTheme.headlineSmall,
                ),
                AppSpacing.verticalSm,
                Text(
                  'Preencha as informações abaixo para cadastrar um novo paciente.',
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
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                  validator: (v) => v == null ? 'Selecione o sexo' : null,
                ),
                AppSpacing.verticalLg,

                _LocationField(
                  value: _location,
                  onChanged: (v) => setState(() => _location = v),
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
                      : const Text('Cadastrar Paciente'),
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

class _LocationField extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _LocationField({required this.value, required this.onChanged});

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final _customController = TextEditingController();
  bool _showCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ...Patient.defaultLocations
          .map((l) => DropdownMenuItem(value: l, child: Text(l))),
      const DropdownMenuItem(value: '__custom__', child: Text('Outro local...')),
    ];

    final dropdownValue = _showCustom
        ? '__custom__'
        : (widget.value != null && Patient.defaultLocations.contains(widget.value)
            ? widget.value
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: const InputDecoration(
            labelText: 'Localização',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: items,
          onChanged: (v) {
            if (v == '__custom__') {
              setState(() => _showCustom = true);
              widget.onChanged(_customController.text.trim().isEmpty
                  ? null
                  : _customController.text.trim());
            } else {
              setState(() => _showCustom = false);
              widget.onChanged(v);
            }
          },
        ),
        if (_showCustom) ...[
          AppSpacing.verticalSm,
          TextFormField(
            controller: _customController,
            decoration: const InputDecoration(
              labelText: 'Nome do local',
              prefixIcon: Icon(Icons.edit_location_alt_outlined),
            ),
            onChanged: (v) =>
                widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          ),
        ],
      ],
    );
  }
}
