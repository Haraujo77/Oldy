import 'package:flutter_test/flutter_test.dart';
import 'package:oldy/features/health/domain/entities/health_log.dart';
import 'package:oldy/features/health/domain/entities/health_metric.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  HealthLog makeLog({
    String id = 'log1',
    HealthMetricType metricType = HealthMetricType.heartRate,
    Map<String, dynamic> values = const {'value': 72},
    DateTime? measuredAt,
    HealthLogSource source = HealthLogSource.manual,
    String? notes = 'Normal',
    List<String> attachments = const [],
    String createdBy = 'user1',
    DateTime? createdAt,
  }) {
    return HealthLog(
      id: id,
      metricType: metricType,
      values: values,
      measuredAt: measuredAt ?? now,
      source: source,
      notes: notes,
      attachments: attachments,
      createdBy: createdBy,
      createdAt: createdAt ?? now,
    );
  }

  group('HealthLog.fromMap / toMap roundtrip', () {
    test('heart rate log survives roundtrip', () {
      final log = makeLog();
      final map = log.toMap();
      final restored = HealthLog.fromMap(map);

      expect(restored.id, log.id);
      expect(restored.metricType, log.metricType);
      expect(restored.values, log.values);
      expect(restored.measuredAt, log.measuredAt);
      expect(restored.source, log.source);
      expect(restored.notes, log.notes);
      expect(restored.attachments, log.attachments);
      expect(restored.createdBy, log.createdBy);
      expect(restored.createdAt, log.createdAt);
    });

    test('blood pressure log survives roundtrip', () {
      final log = makeLog(
        metricType: HealthMetricType.bloodPressure,
        values: {'systolic': 120, 'diastolic': 80},
      );
      final restored = HealthLog.fromMap(log.toMap());

      expect(restored.metricType, HealthMetricType.bloodPressure);
      expect(restored.values['systolic'], 120);
      expect(restored.values['diastolic'], 80);
    });

    test('null notes survive roundtrip', () {
      final log = makeLog(notes: null);
      final restored = HealthLog.fromMap(log.toMap());
      expect(restored.notes, isNull);
    });

    test('integrated source survives roundtrip', () {
      final log = makeLog(source: HealthLogSource.integrated);
      final restored = HealthLog.fromMap(log.toMap());
      expect(restored.source, HealthLogSource.integrated);
    });

    test('source defaults to manual when missing in map', () {
      final map = makeLog().toMap();
      map.remove('source');
      final restored = HealthLog.fromMap(map);
      expect(restored.source, HealthLogSource.manual);
    });
  });

  group('HealthLog.displayValue', () {
    test('blood pressure returns systolic/diastolic', () {
      final log = makeLog(
        metricType: HealthMetricType.bloodPressure,
        values: {'systolic': 120, 'diastolic': 80},
      );
      expect(log.displayValue, '120/80');
    });

    test('heart rate returns integer string for whole number', () {
      final log = makeLog(
        metricType: HealthMetricType.heartRate,
        values: {'value': 72.0},
      );
      expect(log.displayValue, '72');
    });

    test('temperature returns decimal value', () {
      final log = makeLog(
        metricType: HealthMetricType.temperature,
        values: {'value': 36.5},
      );
      expect(log.displayValue, '36.5');
    });

    test('integer value renders without decimal', () {
      final log = makeLog(
        metricType: HealthMetricType.glucose,
        values: {'value': 95},
      );
      expect(log.displayValue, '95');
    });

    test('steps renders integer value', () {
      final log = makeLog(
        metricType: HealthMetricType.steps,
        values: {'value': 5000.0},
      );
      expect(log.displayValue, '5000');
    });
  });

  group('HealthLog.primaryValue', () {
    test('blood pressure returns systolic', () {
      final log = makeLog(
        metricType: HealthMetricType.bloodPressure,
        values: {'systolic': 130, 'diastolic': 85},
      );
      expect(log.primaryValue, 130.0);
    });

    test('heart rate returns value', () {
      final log = makeLog(values: {'value': 80});
      expect(log.primaryValue, 80.0);
    });

    test('returns null when value key is missing', () {
      final log = makeLog(values: {});
      expect(log.primaryValue, isNull);
    });
  });
}
