import '../entities/health_metric.dart';
import '../entities/health_log.dart';

abstract class HealthRepository {
  Stream<List<HealthMetric>> watchHealthPlan(String patientId);

  Future<void> updateHealthPlan(String patientId, HealthMetric metric);

  Future<void> removeMetricFromPlan(String patientId, String metricType);

  Stream<List<HealthLog>> watchHealthLogs(
    String patientId, {
    String? metricType,
    int limit = 50,
  });

  Future<void> addHealthLog(String patientId, HealthLog log);

  Future<void> deleteHealthLog(String patientId, String logId);
}
