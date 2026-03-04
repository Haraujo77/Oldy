import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oldy_loading.dart';
import '../../domain/entities/health_metric.dart';
import '../providers/health_providers.dart';

class HealthPlanConfigPage extends ConsumerStatefulWidget {
  const HealthPlanConfigPage({super.key});

  @override
  ConsumerState<HealthPlanConfigPage> createState() =>
      _HealthPlanConfigPageState();
}

class _HealthPlanConfigPageState
    extends ConsumerState<HealthPlanConfigPage> {
  final Map<HealthMetricType, _MetricConfig> _configs = {};
  bool _initialized = false;
  bool _saving = false;

  static const _frequencies = [
    'Diário',
    '2x ao dia',
    '3x ao dia',
    'Semanal',
    'Sob demanda',
  ];

  void _initializeConfigs(List<HealthMetric> plan) {
    for (final type in HealthMetricType.values) {
      _configs[type] = _MetricConfig(
        enabled: false,
        frequency: 'Diário',
        targetMin: type.defaultMin,
        targetMax: type.defaultMax,
        remindersEnabled: true,
      );
    }
    for (final metric in plan) {
      _configs[metric.metricType] = _MetricConfig(
        enabled: true,
        frequency: metric.frequency,
        targetMin: metric.targetMin ?? metric.metricType.defaultMin,
        targetMax: metric.targetMax ?? metric.metricType.defaultMax,
        remindersEnabled: metric.remindersEnabled,
      );
    }
  }

  Future<void> _save() async {
    final patientId = ref.read(selectedPatientIdProvider);
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum paciente selecionado')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(healthRepositoryProvider);
      final currentPlan = ref.read(healthPlanProvider).valueOrNull ?? [];
      final currentTypes =
          currentPlan.map((m) => m.metricType).toSet();

      for (final entry in _configs.entries) {
        final type = entry.key;
        final config = entry.value;

        if (config.enabled) {
          final metric = HealthMetric(
            metricType: type,
            frequency: config.frequency,
            targetMin: config.targetMin,
            targetMax: config.targetMax,
            remindersEnabled: config.remindersEnabled,
          );
          await repo.updateHealthPlan(patientId, metric);
        } else if (currentTypes.contains(type)) {
          await repo.removeMetricFromPlan(patientId, type.name);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano de saúde atualizado')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('permission-denied') ? 'Sem permissão para alterar o plano de saúde deste paciente.' : 'Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(healthPlanProvider);

    if (!_initialized) {
      if (!planAsync.hasValue) {
        return Scaffold(
          appBar: AppBar(title: const Text('Configurar Plano')),
          body: const OldyLoading(message: 'Carregando plano...'),
        );
      }
      _initializeConfigs(planAsync.value!);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Plano'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: AppSpacing.paddingScreen,
        itemCount: HealthMetricType.values.length,
        separatorBuilder: (_, _) => AppSpacing.verticalMd,
        itemBuilder: (context, index) {
          final type = HealthMetricType.values[index];
          final config = _configs[type]!;

          return Card(
            elevation: AppSpacing.elevationNone,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              side: config.enabled
                  ? BorderSide.none
                  : BorderSide(
                      color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: config.enabled
                              ? type.color.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type.icon,
                          color: config.enabled
                              ? type.color
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: Text(
                          type.label,
                          style:
                              theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: config.enabled,
                        onChanged: (value) {
                          setState(() {
                            _configs[type] =
                                config.copyWith(enabled: value);
                          });
                        },
                      ),
                    ],
                  ),
                  if (config.enabled) ...[
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      value: config.frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequência',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _frequencies.map((f) {
                        return DropdownMenuItem(
                            value: f, child: Text(f));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _configs[type] = config.copyWith(
                                frequency: value);
                          });
                        }
                      },
                    ),
                    AppSpacing.verticalMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _formatTarget(
                                config.targetMin),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Mínimo',
                              suffixText: type.unit,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              if (parsed != null) {
                                _configs[type] = config.copyWith(
                                    targetMin: parsed);
                              }
                            },
                          ),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: TextFormField(
                            initialValue: _formatTarget(
                                config.targetMax),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Máximo',
                              suffixText: type.unit,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              if (parsed != null) {
                                _configs[type] = config.copyWith(
                                    targetMax: parsed);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalMd,
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lembretes',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Switch(
                          value: config.remindersEnabled,
                          onChanged: (value) {
                            setState(() {
                              _configs[type] = config.copyWith(
                                remindersEnabled: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTarget(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _MetricConfig {
  final bool enabled;
  final String frequency;
  final double targetMin;
  final double targetMax;
  final bool remindersEnabled;

  const _MetricConfig({
    required this.enabled,
    required this.frequency,
    required this.targetMin,
    required this.targetMax,
    required this.remindersEnabled,
  });

  _MetricConfig copyWith({
    bool? enabled,
    String? frequency,
    double? targetMin,
    double? targetMax,
    bool? remindersEnabled,
  }) {
    return _MetricConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}
