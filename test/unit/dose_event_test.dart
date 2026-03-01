import 'package:flutter_test/flutter_test.dart';
import 'package:oldy/features/medications/domain/entities/dose_event.dart';

void main() {
  final scheduled = DateTime(2025, 6, 15, 8, 0);
  final actual = DateTime(2025, 6, 15, 8, 5);

  DoseEvent makeEvent({
    String id = 'dose1',
    String medPlanId = 'plan1',
    String medicationName = 'Losartana 50mg',
    String status = 'pendente',
    DateTime? scheduledAt,
    DateTime? actualAt,
    String? recordedBy = 'user1',
    String? skipReason,
  }) {
    return DoseEvent(
      id: id,
      medPlanId: medPlanId,
      medicationName: medicationName,
      status: status,
      scheduledAt: scheduledAt ?? scheduled,
      actualAt: actualAt,
      recordedBy: recordedBy,
      skipReason: skipReason,
    );
  }

  group('DoseEvent.fromMap / toMap roundtrip', () {
    test('full event survives roundtrip', () {
      final event = makeEvent(
        status: 'tomado',
        actualAt: actual,
      );
      final map = event.toMap();
      final restored = DoseEvent.fromMap(map);

      expect(restored.id, event.id);
      expect(restored.medPlanId, event.medPlanId);
      expect(restored.medicationName, event.medicationName);
      expect(restored.status, event.status);
      expect(restored.scheduledAt, event.scheduledAt);
      expect(restored.actualAt, event.actualAt);
      expect(restored.recordedBy, event.recordedBy);
      expect(restored.skipReason, event.skipReason);
    });

    test('null optional fields survive roundtrip', () {
      final event = makeEvent(
        actualAt: null,
        recordedBy: null,
        skipReason: null,
      );
      final restored = DoseEvent.fromMap(event.toMap());

      expect(restored.actualAt, isNull);
      expect(restored.recordedBy, isNull);
      expect(restored.skipReason, isNull);
    });

    test('skipped event with reason survives roundtrip', () {
      final event = makeEvent(
        status: 'pulado',
        skipReason: 'Paciente recusou',
      );
      final restored = DoseEvent.fromMap(event.toMap());

      expect(restored.status, 'pulado');
      expect(restored.skipReason, 'Paciente recusou');
    });

    test('medicationName defaults to empty string when missing', () {
      final restored = DoseEvent.fromMap({
        'id': 'dose1',
        'medPlanId': 'plan1',
        'scheduledAt': scheduled.toIso8601String(),
      });
      expect(restored.medicationName, '');
    });

    test('status defaults to pendente when missing', () {
      final restored = DoseEvent.fromMap({
        'id': 'dose1',
        'medPlanId': 'plan1',
        'scheduledAt': scheduled.toIso8601String(),
      });
      expect(restored.status, 'pendente');
    });
  });

  group('DoseEvent status values', () {
    const validStatuses = [
      'pendente',
      'tomado',
      'atrasado',
      'pulado',
      'adiado',
    ];

    for (final status in validStatuses) {
      test('status "$status" roundtrips correctly', () {
        final event = makeEvent(status: status);
        final restored = DoseEvent.fromMap(event.toMap());
        expect(restored.status, status);
      });
    }
  });

  group('DoseEvent.copyWith', () {
    test('changes only specified fields', () {
      final original = makeEvent();
      final updated = original.copyWith(
        status: 'tomado',
        actualAt: actual,
      );

      expect(updated.status, 'tomado');
      expect(updated.actualAt, actual);
      expect(updated.id, original.id);
      expect(updated.medPlanId, original.medPlanId);
      expect(updated.medicationName, original.medicationName);
      expect(updated.scheduledAt, original.scheduledAt);
    });

    test('returns identical values when no arguments passed', () {
      final original = makeEvent();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.medPlanId, original.medPlanId);
      expect(copy.medicationName, original.medicationName);
      expect(copy.status, original.status);
      expect(copy.scheduledAt, original.scheduledAt);
    });
  });
}
