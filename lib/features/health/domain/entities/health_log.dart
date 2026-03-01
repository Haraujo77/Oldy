import 'health_metric.dart';

enum HealthLogSource { manual, integrated }

class HealthLog {
  final String id;
  final HealthMetricType metricType;
  final Map<String, dynamic> values;
  final DateTime measuredAt;
  final HealthLogSource source;
  final String? notes;
  final List<String> attachments;
  final String createdBy;
  final DateTime createdAt;

  const HealthLog({
    required this.id,
    required this.metricType,
    required this.values,
    required this.measuredAt,
    this.source = HealthLogSource.manual,
    this.notes,
    this.attachments = const [],
    required this.createdBy,
    required this.createdAt,
  });

  /// Primary numeric value for chart plotting.
  /// For blood pressure returns systolic.
  double? get primaryValue {
    if (metricType == HealthMetricType.bloodPressure) {
      return (values['systolic'] as num?)?.toDouble();
    }
    return (values['value'] as num?)?.toDouble();
  }

  String get displayValue {
    if (metricType == HealthMetricType.bloodPressure) {
      final sys = values['systolic'];
      final dia = values['diastolic'];
      return '$sys/$dia';
    }
    final v = values['value'];
    if (v is double && v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return '$v';
  }

  HealthLog copyWith({
    String? id,
    HealthMetricType? metricType,
    Map<String, dynamic>? values,
    DateTime? measuredAt,
    HealthLogSource? source,
    String? notes,
    List<String>? attachments,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return HealthLog(
      id: id ?? this.id,
      metricType: metricType ?? this.metricType,
      values: values ?? this.values,
      measuredAt: measuredAt ?? this.measuredAt,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metricType': metricType.name,
      'values': values,
      'measuredAt': measuredAt.toIso8601String(),
      'source': source.name,
      'notes': notes,
      'attachments': attachments,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id'] as String,
      metricType: HealthMetricType.values.byName(map['metricType'] as String),
      values: Map<String, dynamic>.from(map['values'] ?? {}),
      measuredAt: DateTime.parse(map['measuredAt'] as String),
      source: HealthLogSource.values.byName(
        map['source'] as String? ?? 'manual',
      ),
      notes: map['notes'] as String?,
      attachments: List<String>.from(map['attachments'] ?? []),
      createdBy: map['createdBy'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
