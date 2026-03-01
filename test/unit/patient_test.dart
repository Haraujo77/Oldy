import 'package:flutter_test/flutter_test.dart';
import 'package:oldy/features/management/domain/entities/patient.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);
  final dob = DateTime(1945, 3, 20);

  Patient makePatient({
    String id = 'p1',
    String fullName = 'Maria Silva',
    String? nickname = 'Dona Maria',
    String? photoUrl,
    DateTime? dateOfBirth,
    String sex = 'Feminino',
    List<String> conditions = const ['Hipertensão'],
    List<String> allergies = const ['Dipirona'],
    List<Map<String, String>> emergencyContacts = const [
      {'name': 'João', 'phone': '11999999999'}
    ],
    String? responsibleDoctor = 'Dr. Carlos',
    String? clinicalNotes = 'Acompanhamento mensal',
    DateTime? createdAt,
    String createdBy = 'user1',
  }) {
    return Patient(
      id: id,
      fullName: fullName,
      nickname: nickname,
      photoUrl: photoUrl,
      dateOfBirth: dateOfBirth ?? dob,
      sex: sex,
      conditions: conditions,
      allergies: allergies,
      emergencyContacts: emergencyContacts,
      responsibleDoctor: responsibleDoctor,
      clinicalNotes: clinicalNotes,
      createdAt: createdAt ?? now,
      createdBy: createdBy,
    );
  }

  group('Patient.fromMap / toMap roundtrip', () {
    test('full patient survives roundtrip', () {
      final patient = makePatient();
      final map = patient.toMap();
      final restored = Patient.fromMap(map);

      expect(restored.id, patient.id);
      expect(restored.fullName, patient.fullName);
      expect(restored.nickname, patient.nickname);
      expect(restored.photoUrl, patient.photoUrl);
      expect(restored.dateOfBirth, patient.dateOfBirth);
      expect(restored.sex, patient.sex);
      expect(restored.conditions, patient.conditions);
      expect(restored.allergies, patient.allergies);
      expect(restored.emergencyContacts, patient.emergencyContacts);
      expect(restored.responsibleDoctor, patient.responsibleDoctor);
      expect(restored.clinicalNotes, patient.clinicalNotes);
      expect(restored.createdAt, patient.createdAt);
      expect(restored.createdBy, patient.createdBy);
    });

    test('null optional fields survive roundtrip', () {
      final patient = makePatient(
        nickname: null,
        photoUrl: null,
        responsibleDoctor: null,
        clinicalNotes: null,
      );
      final restored = Patient.fromMap(patient.toMap());

      expect(restored.nickname, isNull);
      expect(restored.photoUrl, isNull);
      expect(restored.responsibleDoctor, isNull);
      expect(restored.clinicalNotes, isNull);
    });

    test('empty lists survive roundtrip', () {
      final patient = makePatient(
        conditions: [],
        allergies: [],
        emergencyContacts: [],
      );
      final restored = Patient.fromMap(patient.toMap());

      expect(restored.conditions, isEmpty);
      expect(restored.allergies, isEmpty);
      expect(restored.emergencyContacts, isEmpty);
    });
  });

  group('Patient.copyWith', () {
    test('changes only specified fields', () {
      final original = makePatient();
      final updated = original.copyWith(fullName: 'Ana Costa', sex: 'Feminino');

      expect(updated.fullName, 'Ana Costa');
      expect(updated.id, original.id);
      expect(updated.nickname, original.nickname);
      expect(updated.dateOfBirth, original.dateOfBirth);
      expect(updated.createdBy, original.createdBy);
    });

    test('returns identical values when no arguments passed', () {
      final original = makePatient();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.fullName, original.fullName);
      expect(copy.nickname, original.nickname);
      expect(copy.conditions, original.conditions);
    });
  });

  group('Patient default values', () {
    test('conditions defaults to empty list', () {
      final patient = Patient(
        id: 'p1',
        fullName: 'Test',
        dateOfBirth: dob,
        sex: 'Masculino',
        createdAt: now,
        createdBy: 'user1',
      );
      expect(patient.conditions, isEmpty);
    });

    test('allergies defaults to empty list', () {
      final patient = Patient(
        id: 'p1',
        fullName: 'Test',
        dateOfBirth: dob,
        sex: 'Masculino',
        createdAt: now,
        createdBy: 'user1',
      );
      expect(patient.allergies, isEmpty);
    });

    test('emergencyContacts defaults to empty list', () {
      final patient = Patient(
        id: 'p1',
        fullName: 'Test',
        dateOfBirth: dob,
        sex: 'Masculino',
        createdAt: now,
        createdBy: 'user1',
      );
      expect(patient.emergencyContacts, isEmpty);
    });

    test('optional nullable fields default to null', () {
      final patient = Patient(
        id: 'p1',
        fullName: 'Test',
        dateOfBirth: dob,
        sex: 'Masculino',
        createdAt: now,
        createdBy: 'user1',
      );
      expect(patient.nickname, isNull);
      expect(patient.photoUrl, isNull);
      expect(patient.responsibleDoctor, isNull);
      expect(patient.clinicalNotes, isNull);
    });

    test('fromMap defaults lists when keys are missing', () {
      final patient = Patient.fromMap({
        'id': 'p1',
        'fullName': 'Test',
        'dateOfBirth': dob.toIso8601String(),
        'sex': 'Masculino',
        'createdAt': now.toIso8601String(),
        'createdBy': 'user1',
      });
      expect(patient.conditions, isEmpty);
      expect(patient.allergies, isEmpty);
      expect(patient.emergencyContacts, isEmpty);
    });
  });
}
