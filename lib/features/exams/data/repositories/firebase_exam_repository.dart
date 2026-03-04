import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/clinical_exam.dart';
import '../../domain/repositories/exam_repository.dart';

class FirebaseExamRepository implements ExamRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseExamRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _examsCol(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('exams');

  @override
  Stream<List<ClinicalExam>> watchExams(String patientId) {
    return _examsCol(patientId)
        .orderBy('examDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClinicalExam.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> addExam(String patientId, ClinicalExam exam) async {
    await _examsCol(patientId).doc(exam.id).set(exam.toMap());
  }

  @override
  Future<void> updateExam(String patientId, ClinicalExam exam) async {
    await _examsCol(patientId).doc(exam.id).update(exam.toMap());
  }

  @override
  Future<void> deleteExam(String patientId, String examId) async {
    await _examsCol(patientId).doc(examId).delete();
  }

  @override
  Future<String> uploadExamPhoto(
    String patientId,
    String examId,
    String filePath,
  ) async {
    final fileName =
        '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref('patients/$patientId/exams/$examId/$fileName');
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
