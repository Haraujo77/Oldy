import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/activity_post.dart';
import '../providers/activity_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = AppConstants.activityCategories.first;
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = TimeOfDay.now();
  final List<XFile> _selectedPhotos = [];
  final List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  DateTime get _eventDateTime => DateTime(
        _eventDate.year,
        _eventDate.month,
        _eventDate.day,
        _eventTime.hour,
        _eventTime.minute,
      );

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final maxRemaining = AppConstants.maxPhotosPerPost - _selectedPhotos.length;
    if (maxRemaining <= 0) {
      context.showSnackBar(
        'Máximo de ${AppConstants.maxPhotosPerPost} fotos atingido',
        isError: true,
      );
      return;
    }

    final images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
    );

    if (images.isNotEmpty) {
      setState(() {
        final toAdd = images.take(maxRemaining).toList();
        _selectedPhotos.addAll(toAdd);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );
    if (date != null) {
      setState(() => _eventDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (time != null) {
      setState(() => _eventTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) {
      context.showSnackBar('Nenhum paciente selecionado', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(activityRepositoryProvider);

      final photoUrls = <String>[];
      for (final photo in _selectedPhotos) {
        final url = await repo.uploadMedia(patientId, photo.path, 'photos');
        photoUrls.add(url);
      }

      final post = ActivityPost(
        id: const Uuid().v4(),
        category: _selectedCategory,
        text: _textController.text.trim(),
        photoUrls: photoUrls,
        eventAt: _eventDateTime,
        tags: _tags,
        createdBy: '', // Set by auth layer
        createdByName: '', // Set by auth layer
        createdAt: DateTime.now(),
      );

      await repo.createPost(patientId, post);

      if (mounted) {
        context.showSnackBar('Atividade registrada com sucesso!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erro ao salvar: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Atividade'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
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
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            _buildCategoryDropdown(theme),
            AppSpacing.verticalLg,
            _buildTextField(theme),
            AppSpacing.verticalLg,
            _buildPhotoSection(theme),
            AppSpacing.verticalLg,
            _buildAudioPlaceholder(theme),
            AppSpacing.verticalLg,
            _buildDateTimePickers(theme),
            AppSpacing.verticalLg,
            _buildTagsInput(theme),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Categoria',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: AppConstants.activityCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return TextFormField(
      controller: _textController,
      decoration: const InputDecoration(
        labelText: 'Descrição',
        hintText: 'O que aconteceu?',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.notes_rounded),
      ),
      maxLines: 5,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Insira uma descrição';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                size: AppSpacing.iconMd,
                color: theme.colorScheme.onSurfaceVariant),
            AppSpacing.horizontalSm,
            Text('Fotos', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '${_selectedPhotos.length}/${AppConstants.maxPhotosPerPost}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.verticalSm,
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, _) => AppSpacing.horizontalSm,
              itemBuilder: (context, index) {
                return _PhotoThumbnail(
                  file: _selectedPhotos[index],
                  onRemove: () => _removePhoto(index),
                );
              },
            ),
          ),
          AppSpacing.verticalSm,
        ],
        OutlinedButton.icon(
          onPressed: _selectedPhotos.length >= AppConstants.maxPhotosPerPost
              ? null
              : _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Adicionar fotos'),
        ),
      ],
    );
  }

  Widget _buildAudioPlaceholder(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () {
        context.showSnackBar('Gravação de áudio em breve!');
      },
      icon: const Icon(Icons.mic_outlined),
      label: const Text('Gravar áudio'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDateTimePickers(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormatters.dateFull(_eventDate)),
          ),
        ),
        AppSpacing.horizontalSm,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time_outlined),
            label: Text(DateFormatters.time(
              DateTime(0, 0, 0, _eventTime.hour, _eventTime.minute),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag_rounded,
                size: AppSpacing.iconMd,
                color: theme.colorScheme.onSurfaceVariant),
            AppSpacing.horizontalSm,
            Text('Tags', style: theme.textTheme.titleSmall),
          ],
        ),
        AppSpacing.verticalSm,
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          AppSpacing.verticalSm,
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Adicionar tag...',
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
              ),
            ),
            AppSpacing.horizontalSm,
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _PhotoThumbnail({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Image.asset(
            file.path,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 100,
              height: 100,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
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
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
