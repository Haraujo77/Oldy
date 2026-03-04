import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/photo_avatar.dart';
import '../../../../core/widgets/unsaved_changes_guard.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageService = ImageUploadService();
  bool _loading = false;
  bool _initialized = false;
  bool _dirty = false;
  String? _localImagePath;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final image = await _imageService.pickImage(source: source);
    if (image != null) {
      setState(() => _localImagePath = image.path);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
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
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      String? photoUrl;
      if (_localImagePath != null) {
        photoUrl = await _imageService.uploadUserPhoto(
          user.uid,
          XFile(_localImagePath!),
        );
      }

      await ref.read(authRepositoryProvider).updateProfile(
            displayName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            photoUrl: photoUrl,
          );
      ref.invalidate(authStateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
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
    final user = ref.watch(authStateProvider).valueOrNull;

    if (!_initialized && user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _initialized = true;
    }

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _handleSave,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: PhotoAvatar(
                    photoUrl: user?.photoUrl,
                    localPath: _localImagePath,
                    fallbackLetter: user?.displayName ?? '?',
                    radius: 48,
                    editable: true,
                    onTap: _pickPhoto,
                  ),
                ),
                AppSpacing.verticalXl,
                TextFormField(
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe seu nome'
                      : null,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                AppSpacing.verticalLg,
                TextFormField(
                  enabled: false,
                  initialValue: user?.email ?? '',
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                AppSpacing.verticalLg,
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                AppSpacing.verticalXl,
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
