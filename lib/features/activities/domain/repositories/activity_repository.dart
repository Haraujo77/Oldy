import '../entities/activity_post.dart';
import '../entities/activity_comment.dart';

abstract class ActivityRepository {
  Stream<List<ActivityPost>> watchActivities(
    String patientId, {
    String? category,
    int limit = 20,
  });

  Future<ActivityPost> createPost(String patientId, ActivityPost post);

  Future<void> updatePost(String patientId, ActivityPost post);

  Future<void> deletePost(String patientId, String postId);

  Future<void> toggleReaction(
    String patientId,
    String postId,
    String emoji,
    String userId,
  );

  Stream<List<ActivityComment>> watchComments(
    String patientId,
    String postId,
  );

  Future<void> addComment(
    String patientId,
    String postId,
    ActivityComment comment,
  );

  Future<void> deleteComment(
    String patientId,
    String postId,
    String commentId,
  );

  Future<String> uploadMedia(
    String patientId,
    String filePath,
    String type,
  );
}
