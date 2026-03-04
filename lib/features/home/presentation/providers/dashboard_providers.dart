import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activities/domain/entities/activity_post.dart';
import '../../../activities/domain/entities/activity_plan_item.dart';
import '../../../activities/presentation/providers/activity_providers.dart';
import '../../../health/domain/entities/health_log.dart';
import '../../../health/domain/entities/health_metric.dart';
import '../../../health/presentation/providers/health_providers.dart';
import '../../../medications/domain/entities/dose_event.dart';
import '../../../medications/presentation/helpers/dose_status_helper.dart';
import '../../../medications/presentation/providers/medication_providers.dart';
import '../../domain/entities/history_item.dart';
import 'history_providers.dart';

// ---------------------------------------------------------------------------
// Dashboard status models
// ---------------------------------------------------------------------------

enum DashboardLevel { ok, info, warning, alert, empty }

class DashboardStatus {
  final DashboardLevel level;
  final String message;
  final String? cta;
  final IconData? statusIcon;

  const DashboardStatus({
    required this.level,
    required this.message,
    this.cta,
    this.statusIcon,
  });
}

// ---------------------------------------------------------------------------
// Medication dashboard
// ---------------------------------------------------------------------------

final medDashboardProvider =
    Provider.family<AsyncValue<DashboardStatus>, String>((ref, patientId) {
  final dosesAsync = ref.watch(todayDosesProvider(patientId));

  return dosesAsync.whenData((doses) {
    if (doses.isEmpty) {
      final plans = ref.watch(medPlanProvider(patientId));
      final hasPlan = plans.valueOrNull?.isNotEmpty ?? false;
      if (!hasPlan) {
        return const DashboardStatus(
          level: DashboardLevel.empty,
          message: 'Nenhum medicamento cadastrado.',
          cta: 'Adicionar',
        );
      }
      return const DashboardStatus(
        level: DashboardLevel.ok,
        message: 'Nenhuma dose programada para hoje.',
      );
    }

    final overdueNames = <String>{};
    int scheduled = 0;
    int taken = 0;

    for (final dose in doses) {
      final helper = DoseStatusHelper(dose);
      switch (helper.displayStatus) {
        case DoseDisplayStatus.pendente:
          overdueNames.add(dose.medicationName);
          break;
        case DoseDisplayStatus.programado:
          scheduled++;
          break;
        case DoseDisplayStatus.tomado:
          taken++;
          break;
        default:
          break;
      }
    }

    if (overdueNames.isNotEmpty) {
      final names = overdueNames.toList();
      final message = '${names.length} pendência${names.length > 1 ? 's' : ''}: ${names.join(', ')}';
      return DashboardStatus(
        level: DashboardLevel.alert,
        message: message,
        statusIcon: Icons.notifications_active_outlined,
      );
    }

    if (scheduled > 0) {
      return DashboardStatus(
        level: DashboardLevel.ok,
        message: 'Tudo em dia. $scheduled dose${scheduled > 1 ? 's' : ''} programada${scheduled > 1 ? 's' : ''}.',
      );
    }

    return const DashboardStatus(
      level: DashboardLevel.ok,
      message: 'Todas as doses do dia foram administradas.',
    );
  });
});

// ---------------------------------------------------------------------------
// Health dashboard
// ---------------------------------------------------------------------------

final healthDashboardProvider =
    Provider.family<AsyncValue<DashboardStatus>, ({String patientId, String? patientName})>(
        (ref, params) {
  final planAsync = ref.watch(healthPlanProvider);
  final logsAsync = ref.watch(healthLogsProvider(null));

  if (planAsync is AsyncLoading || logsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  final plan = planAsync.valueOrNull ?? [];
  final logs = logsAsync.valueOrNull ?? [];

  if (plan.isEmpty) {
    return const AsyncData(DashboardStatus(
      level: DashboardLevel.empty,
      message: 'Nenhum plano de saúde configurado.',
      cta: 'Configurar',
    ));
  }

  final latestByType = <HealthMetricType, HealthLog>{};
  for (final log in logs) {
    if (!latestByType.containsKey(log.metricType) ||
        log.measuredAt.isAfter(latestByType[log.metricType]!.measuredAt)) {
      latestByType[log.metricType] = log;
    }
  }

  final alerts = <String>[];
  for (final metric in plan) {
    final log = latestByType[metric.metricType];
    if (log == null) continue;
    final value = log.primaryValue;
    if (value == null) continue;

    final min = metric.targetMin ?? metric.metricType.defaultMin;
    final max = metric.targetMax ?? metric.metricType.defaultMax;

    if (value < min || value > max) {
      alerts.add('${metric.metricType.shortLabel} ${log.displayValue} ${metric.metricType.unit}');
    }
  }

  if (alerts.isNotEmpty) {
    final message = '${alerts.length} sinal${alerts.length > 1 ? 'is' : ''} fora do alvo: ${alerts.join(', ')}';
    return AsyncData(DashboardStatus(
      level: DashboardLevel.warning,
      message: message,
      statusIcon: Icons.warning_amber_outlined,
    ));
  }

  final name = params.patientName;
  final suffix = name != null && name.isNotEmpty ? ' para $name' : '';
  return AsyncData(DashboardStatus(
    level: DashboardLevel.ok,
    message: 'Todos os sinais vitais estão dentro do padrão esperado$suffix.',
  ));
});

// ---------------------------------------------------------------------------
// Activity dashboard
// ---------------------------------------------------------------------------

final activityDashboardProvider =
    Provider.family<AsyncValue<DashboardStatus>, String>((ref, patientId) {
  final plansAsync = ref.watch(activityPlansProvider(patientId));
  final postsAsync = ref.watch(allActivityPostsProvider(patientId));

  if (plansAsync is AsyncLoading || postsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  final plans = plansAsync.valueOrNull ?? [];
  final posts = postsAsync.valueOrNull ?? [];
  final scheduledEvents = ref.watch(todayScheduledActivitiesProvider(patientId));

  if (plans.isEmpty && posts.isEmpty) {
    return const AsyncData(DashboardStatus(
      level: DashboardLevel.empty,
      message: 'Nenhuma atividade programada.',
      cta: 'Criar',
    ));
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayPosts = posts.where((p) {
    final d = p.eventAt;
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }).toSet();

  final matchedPlanIds = <String>{};
  for (final post in todayPosts) {
    for (final event in scheduledEvents) {
      if (post.category == event.category &&
          (post.eventAt.difference(event.scheduledAt).inMinutes).abs() < 120) {
        matchedPlanIds.add('${event.planId}_${event.timeLabel}');
      }
    }
  }

  final pendingActivities = scheduledEvents
      .where((e) => !matchedPlanIds.contains('${e.planId}_${e.timeLabel}'))
      .toList();
  final done = todayPosts.length;

  final now2 = DateTime.now();
  final overdueActivities = pendingActivities
      .where((e) => e.scheduledAt.isBefore(now2))
      .toList();

  if (pendingActivities.isEmpty) {
    if (done > 0) {
      return AsyncData(DashboardStatus(
        level: DashboardLevel.ok,
        message: '$done atividade${done > 1 ? 's' : ''} registrada${done > 1 ? 's' : ''} hoje.',
      ));
    }
    return const AsyncData(DashboardStatus(
      level: DashboardLevel.ok,
      message: 'Nenhuma atividade programada para hoje.',
    ));
  }

  if (overdueActivities.isNotEmpty) {
    final names = overdueActivities.map((e) => e.activityName).toSet().toList();
    final message = '${names.length} pendência${names.length > 1 ? 's' : ''}: ${names.join(', ')}';
    return AsyncData(DashboardStatus(
      level: DashboardLevel.alert,
      message: message,
      statusIcon: Icons.notifications_active_outlined,
    ));
  }

  return AsyncData(DashboardStatus(
    level: DashboardLevel.ok,
    message: 'Tudo em dia. ${pendingActivities.length} atividade${pendingActivities.length > 1 ? 's' : ''} programada${pendingActivities.length > 1 ? 's' : ''}.',
  ));
});

// ---------------------------------------------------------------------------
// Up Next (A Seguir)
// ---------------------------------------------------------------------------

class UpNextItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final DateTime scheduledAt;
  final String countdown;
  final String type; // 'dose' | 'activity'
  final Object? data;

  const UpNextItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.scheduledAt,
    required this.countdown,
    required this.type,
    this.data,
  });
}

final upNextProvider =
    StreamProvider.family<List<UpNextItem>, String>((ref, patientId) {
  final dosesStream =
      ref.watch(medicationRepositoryProvider).watchTodayDoses(patientId);
  final plansStream =
      ref.watch(activityRepositoryProvider).watchActivityPlans(patientId);

  final controller = StreamController<List<UpNextItem>>();
  List<DoseEvent> latestDoses = [];
  List<ActivityPlanItem> latestPlans = [];

  void emit() {
    final now = DateTime.now();
    final items = <UpNextItem>[];

    for (final dose in latestDoses) {
      final helper = DoseStatusHelper(dose);
      if (helper.displayStatus == DoseDisplayStatus.programado ||
          helper.displayStatus == DoseDisplayStatus.pendente) {
        items.add(UpNextItem(
          id: 'dose_${dose.id}',
          title: dose.medicationName,
          icon: Icons.medication_outlined,
          color: helper.color,
          scheduledAt: dose.scheduledAt,
          countdown: helper.countdown,
          type: 'dose',
          data: dose,
        ));
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    for (final plan in latestPlans) {
      if (plan.startDate.isAfter(today.add(const Duration(days: 1)))) continue;
      if (!plan.continuous && plan.endDate != null && plan.endDate!.isBefore(today)) continue;

      bool appliesForToday = true;
      if (plan.frequencyType == 'weekly') {
        appliesForToday = plan.daysOfWeek.contains(weekday);
      }
      if (!appliesForToday) continue;

      for (final timeStr in plan.scheduledTimes) {
        final parts = timeStr.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final scheduled = DateTime(today.year, today.month, today.day, hour, minute);

        final isOverdue = scheduled.isBefore(now);
        final diff = isOverdue
            ? now.difference(scheduled)
            : scheduled.difference(now);
        final countdown = isOverdue
            ? (diff.inHours > 0
                ? 'há ${diff.inHours}h ${diff.inMinutes.remainder(60)}min'
                : 'há ${diff.inMinutes}min')
            : (diff.inHours > 0
                ? 'em ${diff.inHours}h ${diff.inMinutes.remainder(60)}min'
                : 'em ${diff.inMinutes}min');

        items.add(UpNextItem(
          id: 'act_${plan.id}_$timeStr',
          title: plan.activityName,
          icon: isOverdue
              ? Icons.warning_amber_rounded
              : Icons.event_note_outlined,
          color: isOverdue ? const Color(0xFFF4A261) : const Color(0xFF42A5F5),
          scheduledAt: scheduled,
          countdown: countdown,
          type: 'activity',
          data: plan,
        ));
      }
    }

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    controller.add(items.toList());
  }

  final sub1 = dosesStream.listen((data) {
    latestDoses = data;
    emit();
  });
  final sub2 = plansStream.listen((data) {
    latestPlans = data;
    emit();
  });

  controller.onCancel = () {
    sub1.cancel();
    sub2.cancel();
  };

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Highlight post (latest activity with photo)
// ---------------------------------------------------------------------------

final highlightPostProvider =
    StreamProvider.family<ActivityPost?, String>((ref, patientId) {
  return ref
      .watch(activityRepositoryProvider)
      .watchActivities(patientId, limit: 10)
      .map((posts) {
    for (final post in posts) {
      if (post.photoUrls.isNotEmpty) return post;
    }
    return null;
  });
});

// ---------------------------------------------------------------------------
// Completed history (for recent history section)
// ---------------------------------------------------------------------------

final completedHistoryProvider =
    Provider.family<AsyncValue<List<HistoryItem>>, String>((ref, patientId) {
  final historyAsync = ref.watch(recentHistoryProvider(patientId));
  return historyAsync.whenData((items) => items
      .where((item) {
        if (item.type == HistoryItemType.doseEvent) {
          final dose = item.data as DoseEvent;
          return dose.status == 'tomado';
        }
        return true;
      })
      .take(5)
      .toList());
});
