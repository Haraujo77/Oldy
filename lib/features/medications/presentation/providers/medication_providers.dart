import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_medication_repository.dart';
import '../../domain/entities/med_plan_item.dart';
import '../../domain/entities/dose_event.dart';
import '../../domain/entities/medication_catalog_item.dart';
import '../../domain/repositories/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return FirebaseMedicationRepository();
});

final medPlanProvider =
    StreamProvider.family<List<MedPlanItem>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchMedPlan(patientId);
});

final todayDosesProvider =
    StreamProvider.family<List<DoseEvent>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchTodayDoses(patientId);
});

final doseHistoryProvider = StreamProvider.family<List<DoseEvent>,
    ({String patientId, String? medPlanId, int limit})>((ref, params) {
  return ref.watch(medicationRepositoryProvider).watchDoseHistory(
        params.patientId,
        medPlanId: params.medPlanId,
        limit: params.limit,
      );
});

final catalogSearchProvider =
    FutureProvider.family<List<MedicationCatalogItem>, String>(
        (ref, query) async {
  return ref.read(medicationRepositoryProvider).searchCatalog(query);
});

final generateTodayDosesProvider =
    FutureProvider.family<void, String>((ref, patientId) async {
  await ref.read(medicationRepositoryProvider).generateTodayDoses(patientId);
});
