import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_log.dart';
import '../../domain/repositories/health_repository.dart';

class FirebaseHealthRepository implements HealthRepository {
  final FirebaseFirestore _firestore;

  FirebaseHealthRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// patients/{patientId}/plans/health/metrics/{metricType}
  CollectionReference<Map<String, dynamic>> _metricsCol(String patientId) =>
      _firestore
          .collection('patients')
          .doc(patientId)
          .collection('plans')
          .doc('health')
          .collection('metrics');

  /// patients/{patientId}/health_logs/{logId}
  CollectionReference<Map<String, dynamic>> _logsCol(String patientId) =>
      _firestore
          .collection('patients')
          .doc(patientId)
          .collection('health_logs');

  @override
  Stream<List<HealthMetric>> watchHealthPlan(String patientId) {
    return _metricsCol(patientId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HealthMetric.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> updateHealthPlan(String patientId, HealthMetric metric) async {
    await _metricsCol(patientId)
        .doc(metric.metricType.name)
        .set(metric.toMap());
  }

  @override
  Future<void> removeMetricFromPlan(
    String patientId,
    String metricType,
  ) async {
    await _metricsCol(patientId).doc(metricType).delete();
  }

  @override
  Stream<List<HealthLog>> watchHealthLogs(
    String patientId, {
    String? metricType,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _logsCol(patientId)
        .orderBy('measuredAt', descending: true)
        .limit(limit);

    if (metricType != null) {
      query = query.where('metricType', isEqualTo: metricType);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HealthLog.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> addHealthLog(String patientId, HealthLog log) async {
    await _logsCol(patientId).doc(log.id).set(log.toMap());
  }

  @override
  Future<void> deleteHealthLog(String patientId, String logId) async {
    await _logsCol(patientId).doc(logId).delete();
  }
}
