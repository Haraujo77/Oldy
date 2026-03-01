import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/med_plan_item.dart';
import '../../domain/entities/dose_event.dart';
import '../../domain/entities/medication_catalog_item.dart';
import '../../domain/repositories/medication_repository.dart';

class FirebaseMedicationRepository implements MedicationRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FirebaseMedicationRepository({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _medPlansCol(String patientId) =>
      _firestore.collection('patients/$patientId/plans/meds/items');

  CollectionReference<Map<String, dynamic>> _doseLogsCol(String patientId) =>
      _firestore.collection('patients/$patientId/logs/meds/events');

  CollectionReference<Map<String, dynamic>> get _catalogCol =>
      _firestore.collection('medCatalog');

  @override
  Stream<List<MedPlanItem>> watchMedPlan(String patientId) {
    return _medPlansCol(patientId)
        .orderBy('medicationName')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MedPlanItem.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  @override
  Future<void> addMedPlanItem(String patientId, MedPlanItem item) async {
    await _medPlansCol(patientId).doc(item.id).set(item.toMap());
  }

  @override
  Future<void> updateMedPlanItem(String patientId, MedPlanItem item) async {
    await _medPlansCol(patientId).doc(item.id).update(item.toMap());
  }

  @override
  Future<void> deleteMedPlanItem(String patientId, String itemId) async {
    await _medPlansCol(patientId).doc(itemId).delete();
  }

  @override
  Stream<List<DoseEvent>> watchTodayDoses(String patientId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _doseLogsCol(patientId)
        .where('scheduledAt',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('scheduledAt', isLessThan: endOfDay.toIso8601String())
        .orderBy('scheduledAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DoseEvent.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  @override
  Stream<List<DoseEvent>> watchDoseHistory(
    String patientId, {
    String? medPlanId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query =
        _doseLogsCol(patientId).orderBy('scheduledAt', descending: true);

    if (medPlanId != null) {
      query = query.where('medPlanId', isEqualTo: medPlanId);
    }

    return query.limit(limit).snapshots().map((snap) => snap.docs
        .map((doc) => DoseEvent.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  @override
  Future<void> recordDoseEvent(String patientId, DoseEvent event) async {
    await _doseLogsCol(patientId).doc(event.id).set(event.toMap());
  }

  @override
  Future<List<MedicationCatalogItem>> searchCatalog(String query) async {
    if (query.trim().isEmpty) return [];

    final normalised = query.trim().toLowerCase();
    final snap = await _catalogCol
        .orderBy('name')
        .startAt([normalised])
        .endAt(['$normalised\uf8ff'])
        .limit(20)
        .get();

    return snap.docs
        .map((doc) =>
            MedicationCatalogItem.fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<List<DoseEvent>> generateTodayDoses(String patientId) async {
    final plans = await _medPlansCol(patientId).get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = today.add(const Duration(days: 1));

    final existingSnap = await _doseLogsCol(patientId)
        .where('scheduledAt',
            isGreaterThanOrEqualTo: today.toIso8601String())
        .where('scheduledAt', isLessThan: endOfDay.toIso8601String())
        .get();

    final existingKeys = <String>{};
    for (final doc in existingSnap.docs) {
      final data = doc.data();
      existingKeys.add('${data['medPlanId']}_${data['scheduledAt']}');
    }

    final generated = <DoseEvent>[];

    for (final doc in plans.docs) {
      final plan = MedPlanItem.fromMap({'id': doc.id, ...doc.data()});

      if (plan.startDate.isAfter(today.add(const Duration(days: 1)))) continue;
      if (!plan.continuous &&
          plan.endDate != null &&
          plan.endDate!.isBefore(today)) {
        continue;
      }

      final times = _computeScheduledTimes(plan, today);

      for (final time in times) {
        final key = '${plan.id}_${time.toIso8601String()}';
        if (existingKeys.contains(key)) continue;

        final event = DoseEvent(
          id: _uuid.v4(),
          medPlanId: plan.id,
          medicationName: plan.medicationName,
          status: 'pendente',
          scheduledAt: time,
        );

        await _doseLogsCol(patientId).doc(event.id).set(event.toMap());
        generated.add(event);
        existingKeys.add(key);
      }
    }

    return generated;
  }

  List<DateTime> _computeScheduledTimes(MedPlanItem plan, DateTime today) {
    final results = <DateTime>[];

    if (plan.frequencyType == 'fixed') {
      for (final timeStr in plan.scheduledTimes) {
        final parts = timeStr.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        results.add(DateTime(today.year, today.month, today.day, hour, minute));
      }
    } else if (plan.frequencyType == 'interval') {
      final hours = plan.intervalHours ?? 8;
      final baseHour = plan.scheduledTimes.isNotEmpty
          ? int.tryParse(plan.scheduledTimes.first.split(':').first) ?? 8
          : 8;
      var current =
          DateTime(today.year, today.month, today.day, baseHour);
      final endOfDay = today.add(const Duration(days: 1));
      while (current.isBefore(endOfDay)) {
        results.add(current);
        current = current.add(Duration(hours: hours));
      }
    }

    return results;
  }
}
