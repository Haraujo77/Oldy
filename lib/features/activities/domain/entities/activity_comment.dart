class ActivityComment {
  final String id;
  final String postId;
  final String text;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  const ActivityComment({
    required this.id,
    required this.postId,
    required this.text,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'text': text,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityComment.fromMap(Map<String, dynamic> map) {
    return ActivityComment(
      id: map['id'] as String,
      postId: map['postId'] as String,
      text: map['text'] as String? ?? '',
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
