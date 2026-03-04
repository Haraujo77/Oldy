import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_error_widget.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/dose_event.dart';
import '../helpers/dose_status_helper.dart';
import '../providers/medication_providers.dart';

class DoseHistoryPage extends ConsumerStatefulWidget {
  final String patientId;
  final String? medPlanId;

  const DoseHistoryPage({
    super.key,
    required this.patientId,
    this.medPlanId,
  });

  @override
  ConsumerState<DoseHistoryPage> createState() => _DoseHistoryPageState();
}

class _DoseHistoryPageState extends ConsumerState<DoseHistoryPage> {
  final Set<String> _selectedStatuses = {};
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(doseHistoryProvider((
      patientId: widget.patientId,
      medPlanId: widget.medPlanId,
      limit: 100,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de doses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filtrar por data',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            selected: _selectedStatuses,
            onChanged: (statuses) =>
                setState(() => _selectedStatuses
                  ..clear()
                  ..addAll(statuses)),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  AppSpacing.horizontalSm,
                  Text(
                    '${_fmtDate(_dateRange!.start)} – ${_fmtDate(_dateRange!.end)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => setState(() => _dateRange = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const OldyLoading(message: 'Carregando histórico...'),
              error: (e, _) => OldyErrorWidget(message: '$e'),
              data: (events) {
                final filtered = _applyFilters(events);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        AppSpacing.verticalMd,
                        Text(
                          'Nenhum registro encontrado',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.paddingScreen,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => AppSpacing.verticalSm,
                  itemBuilder: (context, index) =>
                      _HistoryTile(event: filtered[index], theme: theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DoseEvent> _applyFilters(List<DoseEvent> events) {
    var result = events;

    if (_selectedStatuses.isNotEmpty) {
      result = result.where((e) {
        final helper = DoseStatusHelper(e);
        final displayKey = helper.displayStatus.name;
        return _selectedStatuses.contains(displayKey);
      }).toList();
    }

    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(const Duration(days: 1));
      result = result
          .where((e) =>
              !e.scheduledAt.isBefore(start) && e.scheduledAt.isBefore(end))
          .toList();
    }

    return result;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _FilterChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  static const _statuses = [
    ('pendente', 'Pendente', AppColors.error),
    ('programado', 'Programado', AppColors.info),
    ('tomado', 'Tomado', AppColors.success),
    ('pulado', 'Pulado', AppColors.error),
    ('adiado', 'Adiado', AppColors.info),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: _statuses.map((entry) {
          final (value, label, color) = entry;
          final isSelected = selected.contains(value);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: color.withValues(alpha: 0.18),
              checkmarkColor: color,
              onSelected: (sel) {
                final next = Set<String>.from(selected);
                sel ? next.add(value) : next.remove(value);
                onChanged(next);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DoseEvent event;
  final ThemeData theme;

  const _HistoryTile({required this.event, required this.theme});

  String _fmtDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$day/$month $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final helper = DoseStatusHelper(event);
    final color = helper.color;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Icon(helper.icon, color: color, size: AppSpacing.iconMd),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.medicationName,
                    style: theme.textTheme.titleSmall,
                  ),
                  AppSpacing.verticalXs,
                  Text(
                    _fmtDateTime(event.scheduledAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (event.skipReason != null &&
                      event.skipReason!.isNotEmpty) ...[
                    AppSpacing.verticalXs,
                    Text(
                      'Motivo: ${event.skipReason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                helper.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
