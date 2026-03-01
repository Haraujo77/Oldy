import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_comment.dart';
import '../../domain/entities/activity_post.dart';
import '../../domain/repositories/activity_repository.dart';

class FirebaseActivityRepository implements ActivityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseActivityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _activitiesCol(String patientId) =>
      _firestore
          .collection('patients')
          .doc(patientId)
          .collection('logs')
          .doc('activities')
          .collection('posts');

  CollectionReference<Map<String, dynamic>> _commentsCol(
    String patientId,
    String postId,
  ) =>
      _activitiesCol(patientId).doc(postId).collection('comments');

  @override
  Stream<List<ActivityPost>> watchActivities(
    String patientId, {
    String? category,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query =
        _activitiesCol(patientId).orderBy('eventAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ActivityPost.fromMap(doc.data())).toList());
  }

  @override
  Future<ActivityPost> createPost(String patientId, ActivityPost post) async {
    final docRef = _activitiesCol(patientId).doc(post.id);
    await docRef.set(post.toMap());
    return post;
  }

  @override
  Future<void> updatePost(String patientId, ActivityPost post) async {
    await _activitiesCol(patientId).doc(post.id).update(post.toMap());
  }

  @override
  Future<void> deletePost(String patientId, String postId) async {
    await _activitiesCol(patientId).doc(postId).delete();
  }

  @override
  Future<void> toggleReaction(
    String patientId,
    String postId,
    String emoji,
    String userId,
  ) async {
    final docRef = _activitiesCol(patientId).doc(postId);
    final doc = await docRef.get();
    final data = doc.data();
    if (data == null) return;

    final reactions =
        Map<String, dynamic>.from(data['reactions'] as Map? ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);

    if (users.contains(userId)) {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Stream<List<ActivityComment>> watchComments(
    String patientId,
    String postId,
  ) {
    return _commentsCol(patientId, postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityComment.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> addComment(
    String patientId,
    String postId,
    ActivityComment comment,
  ) async {
    await _commentsCol(patientId, postId).doc(comment.id).set(comment.toMap());
    await _activitiesCol(patientId).doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> deleteComment(
    String patientId,
    String postId,
    String commentId,
  ) async {
    await _commentsCol(patientId, postId).doc(commentId).delete();
    await _activitiesCol(patientId).doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<String> uploadMedia(
    String patientId,
    String filePath,
    String type,
  ) async {
    final fileName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref('patients/$patientId/activities/$type/$fileName');
    final uploadTask = await ref.putFile(File(filePath));
    return uploadTask.ref.getDownloadURL();
  }
}
