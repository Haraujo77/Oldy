import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_activity_repository.dart';
import '../../domain/entities/activity_comment.dart';
import '../../domain/entities/activity_plan_item.dart';
import '../../domain/entities/activity_post.dart';
import '../../domain/repositories/activity_repository.dart';

export '../../../management/presentation/providers/patient_providers.dart'
    show selectedPatientIdProvider;

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FirebaseActivityRepository();
});

final categoryFilterProvider = StateProvider<String?>((ref) => null);

enum ActivityStatusFilter { todas, realizadas, programadas }

final activityStatusFilterProvider =
    StateProvider<ActivityStatusFilter>((ref) => ActivityStatusFilter.todas);

/// Category-filtered posts (used by pages that need filtered posts only).
final activitiesProvider =
    StreamProvider.family<List<ActivityPost>, String>((ref, patientId) {
  final category = ref.watch(categoryFilterProvider);
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchActivities(patientId, category: category);
});

final activityCommentsProvider = StreamProvider.family<List<ActivityComment>,
    ({String patientId, String postId})>((ref, params) {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchComments(params.patientId, params.postId);
});

final activityPlansProvider =
    StreamProvider.family<List<ActivityPlanItem>, String>((ref, patientId) {
  return ref.watch(activityRepositoryProvider).watchActivityPlans(patientId);
});

// ---------------------------------------------------------------------------
// Scheduled activity event model
// ---------------------------------------------------------------------------

class ScheduledActivityEvent {
  final String planId;
  final String activityName;
  final String category;
  final DateTime scheduledAt;
  final int? durationMinutes;
  final String? notes;
  final ActivityPlanItem plan;

  const ScheduledActivityEvent({
    required this.planId,
    required this.activityName,
    required this.category,
    required this.scheduledAt,
    this.durationMinutes,
    this.notes,
    required this.plan,
  });

  String get timeLabel {
    final h = scheduledAt.hour.toString().padLeft(2, '0');
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get countdown {
    final now = DateTime.now();
    if (scheduledAt.isBefore(now)) {
      final diff = now.difference(scheduledAt);
      if (diff.inHours > 0) {
        return 'há ${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
      }
      return 'há ${diff.inMinutes}min';
    }
    final diff = scheduledAt.difference(now);
    if (diff.inHours > 0) {
      return 'em ${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
    }
    return 'em ${diff.inMinutes}min';
  }

  bool get isOverdue => scheduledAt.isBefore(DateTime.now());
}

/// Synchronous provider that reads from cached activityPlansProvider.
final todayScheduledActivitiesProvider =
    Provider.family<List<ScheduledActivityEvent>, String>((ref, patientId) {
  final plansAsync = ref.watch(activityPlansProvider(patientId));
  final plans = plansAsync.valueOrNull ?? [];
  return _buildTodayEvents(plans);
});

List<ScheduledActivityEvent> _buildTodayEvents(List<ActivityPlanItem> plans) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekday = today.weekday;
  final events = <ScheduledActivityEvent>[];

  for (final plan in plans) {
    if (plan.startDate.isAfter(today.add(const Duration(days: 1)))) continue;
    if (!plan.continuous &&
        plan.endDate != null &&
        plan.endDate!.isBefore(today)) {
      continue;
    }

    bool appliesForToday = true;
    if (plan.frequencyType == 'weekly') {
      appliesForToday = plan.daysOfWeek.contains(weekday);
    }
    if (!appliesForToday) {
      continue;
    }

    for (final timeStr in plan.scheduledTimes) {
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final scheduled =
          DateTime(today.year, today.month, today.day, hour, minute);

      events.add(ScheduledActivityEvent(
        planId: plan.id,
        activityName: plan.activityName,
        category: plan.category,
        scheduledAt: scheduled,
        durationMinutes: plan.durationMinutes,
        notes: plan.notes,
        plan: plan,
      ));
    }
  }

  events.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return events;
}

// ---------------------------------------------------------------------------
// Combined feed items (posts + scheduled)
// ---------------------------------------------------------------------------

enum ActivityFeedItemType { post, scheduled }

class ActivityFeedItem {
  final ActivityFeedItemType type;
  final ActivityPost? post;
  final ScheduledActivityEvent? scheduled;
  final DateTime sortTime;

  const ActivityFeedItem._({
    required this.type,
    this.post,
    this.scheduled,
    required this.sortTime,
  });

  factory ActivityFeedItem.fromPost(ActivityPost post) => ActivityFeedItem._(
        type: ActivityFeedItemType.post,
        post: post,
        sortTime: post.eventAt,
      );

  factory ActivityFeedItem.fromScheduled(ScheduledActivityEvent event) =>
      ActivityFeedItem._(
        type: ActivityFeedItemType.scheduled,
        scheduled: event,
        sortTime: event.scheduledAt,
      );
}

// ---------------------------------------------------------------------------
// Raw combined data — STABLE StreamProvider, NEVER depends on filters.
// This is the single source of truth for the activity feed.
// Same pattern as upNextProvider that works reliably.
// ---------------------------------------------------------------------------

class RawActivityData {
  final List<ActivityPost> posts;
  final List<ActivityPlanItem> plans;
  const RawActivityData({required this.posts, required this.plans});
}

final rawActivityDataProvider =
    StreamProvider.family<RawActivityData, String>((ref, patientId) {
  final repo = ref.watch(activityRepositoryProvider);

  final postsStream = repo.watchActivities(patientId, limit: 100);
  final plansStream = repo.watchActivityPlans(patientId);

  final controller = StreamController<RawActivityData>();

  List<ActivityPost> latestPosts = [];
  List<ActivityPlanItem> latestPlans = [];
  bool postsReceived = false;

  void emit() {
    if (!postsReceived) return;
    controller.add(
      RawActivityData(posts: latestPosts, plans: latestPlans),
    );
  }

  final sub1 = postsStream.listen(
    (data) {
      latestPosts = data;
      postsReceived = true;
      emit();
    },
    onError: (e) {
      postsReceived = true;
      emit();
    },
  );

  final sub2 = plansStream.listen(
    (data) {
      latestPlans = data;
      emit();
    },
    onError: (e) {
    },
  );

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Filtered feed — lightweight synchronous Provider on top of the raw data.
// Changing filters does NOT recreate Firestore subscriptions.
// ---------------------------------------------------------------------------

/// Also exported so the dashboard can use it.
final allActivityPostsProvider =
    Provider.family<AsyncValue<List<ActivityPost>>, String>((ref, patientId) {
  return ref
      .watch(rawActivityDataProvider(patientId))
      .whenData((raw) => raw.posts);
});

final activityFeedProvider =
    Provider.family<AsyncValue<List<ActivityFeedItem>>, String>(
        (ref, patientId) {
  final rawAsync = ref.watch(rawActivityDataProvider(patientId));
  final statusFilter = ref.watch(activityStatusFilterProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);

  return rawAsync.whenData((raw) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build today's scheduled events from plans
    final scheduledEvents = _buildTodayEvents(raw.plans);

    // Match completed posts to scheduled events
    final todayPosts = raw.posts.where((p) {
      final d = p.eventAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toSet();

    final matchedPlanIds = <String>{};
    for (final post in todayPosts) {
      for (final event in scheduledEvents) {
        if (post.category == event.category &&
            (post.eventAt.difference(event.scheduledAt).inMinutes).abs() <
                120) {
          matchedPlanIds.add('${event.planId}_${event.timeLabel}');
        }
      }
    }

    final unrealizedScheduled = scheduledEvents
        .where(
            (e) => !matchedPlanIds.contains('${e.planId}_${e.timeLabel}'))
        .toList();

    // Apply status filter
    var items = <ActivityFeedItem>[];

    switch (statusFilter) {
      case ActivityStatusFilter.realizadas:
        items = raw.posts.map(ActivityFeedItem.fromPost).toList();
        items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
        break;
      case ActivityStatusFilter.programadas:
        items =
            scheduledEvents.map(ActivityFeedItem.fromScheduled).toList();
        items.sort((a, b) => a.sortTime.compareTo(b.sortTime));
        break;
      case ActivityStatusFilter.todas:
        items = [
          ...raw.posts.map(ActivityFeedItem.fromPost),
          ...unrealizedScheduled.map(ActivityFeedItem.fromScheduled),
        ];
        items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
        break;
    }

    // Apply category filter
    if (categoryFilter != null) {
      items = items.where((item) {
        if (item.type == ActivityFeedItemType.post) {
          return item.post!.category == categoryFilter;
        } else {
          return item.scheduled!.category == categoryFilter;
        }
      }).toList();
    }

    return items;
  });
});
