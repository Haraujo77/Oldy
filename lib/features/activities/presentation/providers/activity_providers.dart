import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_activity_repository.dart';
import '../../domain/entities/activity_comment.dart';
import '../../domain/entities/activity_post.dart';
import '../../domain/repositories/activity_repository.dart';

// TODO: Move to a shared provider once patient selection feature is built
final selectedPatientIdProvider = StateProvider<String?>((ref) => null);

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FirebaseActivityRepository();
});

final categoryFilterProvider = StateProvider<String?>((ref) => null);

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
