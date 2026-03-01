import '../entities/med_plan_item.dart';
import '../entities/dose_event.dart';
import '../entities/medication_catalog_item.dart';

abstract class MedicationRepository {
  Stream<List<MedPlanItem>> watchMedPlan(String patientId);

  Future<void> addMedPlanItem(String patientId, MedPlanItem item);

  Future<void> updateMedPlanItem(String patientId, MedPlanItem item);

  Future<void> deleteMedPlanItem(String patientId, String itemId);

  Stream<List<DoseEvent>> watchTodayDoses(String patientId);

  Stream<List<DoseEvent>> watchDoseHistory(
    String patientId, {
    String? medPlanId,
    int limit = 50,
  });

  Future<void> recordDoseEvent(String patientId, DoseEvent event);

  Future<List<MedicationCatalogItem>> searchCatalog(String query);

  Future<List<DoseEvent>> generateTodayDoses(String patientId);
}
