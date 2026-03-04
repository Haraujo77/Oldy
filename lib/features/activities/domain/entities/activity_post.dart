class ActivityPost {
  final String id;
  final String category;
  final String text;
  final List<String> photoUrls;
  final String? audioUrl;
  final DateTime eventAt;
  final int? durationMinutes;
  final List<String> tags;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final int commentCount;

  const ActivityPost({
    required this.id,
    required this.category,
    required this.text,
    this.photoUrls = const [],
    this.audioUrl,
    required this.eventAt,
    this.durationMinutes,
    this.tags = const [],
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.reactions = const {},
    this.commentCount = 0,
  });

  ActivityPost copyWith({
    String? id,
    String? category,
    String? text,
    List<String>? photoUrls,
    String? audioUrl,
    DateTime? eventAt,
    int? durationMinutes,
    List<String>? tags,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    Map<String, List<String>>? reactions,
    int? commentCount,
  }) {
    return ActivityPost(
      id: id ?? this.id,
      category: category ?? this.category,
      text: text ?? this.text,
      photoUrls: photoUrls ?? this.photoUrls,
      audioUrl: audioUrl ?? this.audioUrl,
      eventAt: eventAt ?? this.eventAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'photoUrls': photoUrls,
      'audioUrl': audioUrl,
      'eventAt': eventAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'tags': tags,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'reactions': reactions.map((key, value) => MapEntry(key, value)),
      'commentCount': commentCount,
    };
  }

  factory ActivityPost.fromMap(Map<String, dynamic> map) {
    return ActivityPost(
      id: map['id'] as String,
      category: map['category'] as String,
      text: map['text'] as String? ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      audioUrl: map['audioUrl'] as String?,
      eventAt: map['eventAt'] != null
          ? DateTime.parse(map['eventAt'] as String)
          : DateTime.now(),
      durationMinutes: map['durationMinutes'] as int?,
      tags: List<String>.from(map['tags'] ?? []),
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          ) ??
          {},
      commentCount: map['commentCount'] as int? ?? 0,
    );
  }
}
