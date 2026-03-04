import '../entities/clinical_exam.dart';

abstract class ExamRepository {
  Stream<List<ClinicalExam>> watchExams(String patientId);
  Future<void> addExam(String patientId, ClinicalExam exam);
  Future<void> updateExam(String patientId, ClinicalExam exam);
  Future<void> deleteExam(String patientId, String examId);
  Future<String> uploadExamPhoto(String patientId, String examId, String filePath);
}
