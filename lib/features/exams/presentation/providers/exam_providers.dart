import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_exam_repository.dart';
import '../../domain/entities/clinical_exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../../management/presentation/providers/patient_providers.dart';

export '../../../management/presentation/providers/patient_providers.dart'
    show selectedPatientIdProvider;

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return FirebaseExamRepository();
});

final examsProvider =
    StreamProvider.family<List<ClinicalExam>, String>((ref, patientId) {
  return ref.watch(examRepositoryProvider).watchExams(patientId);
});

final patientExamsProvider = StreamProvider<List<ClinicalExam>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value([]);
  return ref.watch(examRepositoryProvider).watchExams(patientId);
});
