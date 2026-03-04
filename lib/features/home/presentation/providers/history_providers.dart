import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activities/domain/entities/activity_post.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../health/domain/entities/health_log.dart';
import '../../../health/presentation/providers/health_providers.dart';
import '../../../medications/domain/entities/dose_event.dart';
import '../../../medications/presentation/helpers/dose_status_helper.dart';
import '../../../medications/presentation/providers/medication_providers.dart';
import '../../../management/presentation/providers/patient_providers.dart';
import '../../domain/entities/history_item.dart';

HistoryItem _fromActivity(ActivityPost p) => HistoryItem(
      type: HistoryItemType.activity,
      id: 'act_${p.id}',
      title: p.category,
      subtitle: p.text,
      timestamp: p.eventAt,
      icon: _categoryIcon(p.category),
      data: p,
    );

HistoryItem _fromHealthLog(HealthLog l) => HistoryItem(
      type: HistoryItemType.healthLog,
      id: 'hl_${l.id}',
      title: l.metricType.label,
      subtitle: '${l.displayValue} ${l.metricType.unit}'.trim(),
      timestamp: l.measuredAt,
      icon: l.metricType.icon,
      iconColor: l.metricType.color,
      data: l,
    );

HistoryItem _fromDose(DoseEvent d) {
  final helper = DoseStatusHelper(d);
  return HistoryItem(
    type: HistoryItemType.doseEvent,
    id: 'dose_${d.id}',
    title: d.medicationName,
    subtitle: helper.label,
    timestamp: d.scheduledAt,
    icon: helper.icon,
    iconColor: helper.color,
    data: d,
  );
}

IconData _categoryIcon(String category) => switch (category) {
      'Banho' => Icons.bathtub_outlined,
      'Alimentação' => Icons.restaurant_outlined,
      'Fisioterapia' => Icons.accessibility_new_outlined,
      'Visita médica' => Icons.local_hospital_outlined,
      'Visita familiar' => Icons.family_restroom_outlined,
      'Exercício' => Icons.fitness_center_outlined,
      _ => Icons.event_note_outlined,
    };

final recentHistoryProvider =
    StreamProvider.family<List<HistoryItem>, String>((ref, patientId) {
  final activitiesStream = ref
      .watch(activityRepositoryProvider)
      .watchActivities(patientId, limit: 10);

  final healthLogsStream = ref
      .watch(healthRepositoryProvider)
      .watchHealthLogs(patientId, limit: 10);

  final dosesStream = ref
      .watch(medicationRepositoryProvider)
      .watchDoseHistory(patientId, limit: 10);

  final medPlansStream =
      ref.watch(medicationRepositoryProvider).watchMedPlan(patientId);

  return _combineStreams(
    activitiesStream,
    healthLogsStream,
    dosesStream,
    medPlansStream,
  );
});

Stream<List<HistoryItem>> _combineStreams(
  Stream<List<ActivityPost>> activities,
  Stream<List<HealthLog>> healthLogs,
  Stream<List<DoseEvent>> doses,
  Stream<List<dynamic>> medPlans,
) {
  List<ActivityPost> latestActivities = [];
  List<HealthLog> latestHealthLogs = [];
  List<DoseEvent> latestDoses = [];
  Set<String> validMedPlanIds = {};

  final controller = StreamController<List<HistoryItem>>();

  void emit() {
    final items = <HistoryItem>[
      ...latestActivities.map(_fromActivity),
      ...latestHealthLogs.map(_fromHealthLog),
      ...latestDoses
          .where((d) => validMedPlanIds.contains(d.medPlanId))
          .map(_fromDose),
    ];
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    controller.add(items);
  }

  final sub1 = activities.listen((data) {
    latestActivities = data;
    emit();
  });
  final sub2 = healthLogs.listen((data) {
    latestHealthLogs = data;
    emit();
  });
  final sub3 = doses.listen((data) {
    latestDoses = data;
    emit();
  });
  final sub4 = medPlans.listen((data) {
    validMedPlanIds = data.map<String>((p) => p.id as String).toSet();
    emit();
  });

  controller.onCancel = () {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
    sub4.cancel();
  };

  return controller.stream;
}
