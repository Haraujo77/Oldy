import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_health_repository.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_log.dart';
import '../../domain/repositories/health_repository.dart';
import '../../../management/presentation/providers/patient_providers.dart';

export '../../../management/presentation/providers/patient_providers.dart'
    show selectedPatientIdProvider;

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return FirebaseHealthRepository();
});

final healthPlanProvider = StreamProvider<List<HealthMetric>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value([]);
  return ref.watch(healthRepositoryProvider).watchHealthPlan(patientId);
});

final healthLogsProvider =
    StreamProvider.family<List<HealthLog>, String?>((ref, metricType) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Stream.value([]);
  return ref
      .watch(healthRepositoryProvider)
      .watchHealthLogs(patientId, metricType: metricType);
});
