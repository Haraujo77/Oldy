enum ExamCategory {
  bloodWork,
  imaging,
  cardiology,
  urology,
  ophthalmology,
  neurology,
  other;

  String get label => switch (this) {
        bloodWork => 'Exame de sangue',
        imaging => 'Imagem',
        cardiology => 'Cardiologia',
        urology => 'Urologia',
        ophthalmology => 'Oftalmologia',
        neurology => 'Neurologia',
        other => 'Outro',
      };
}

class ClinicalExam {
  final String id;
  final String examName;
  final ExamCategory category;
  final DateTime examDate;
  final String? labName;
  final List<String> photoUrls;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  const ClinicalExam({
    required this.id,
    required this.examName,
    required this.category,
    required this.examDate,
    this.labName,
    this.photoUrls = const [],
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  ClinicalExam copyWith({
    String? id,
    String? examName,
    ExamCategory? category,
    DateTime? examDate,
    String? labName,
    List<String>? photoUrls,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ClinicalExam(
      id: id ?? this.id,
      examName: examName ?? this.examName,
      category: category ?? this.category,
      examDate: examDate ?? this.examDate,
      labName: labName ?? this.labName,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examName': examName,
      'category': category.name,
      'examDate': examDate.toIso8601String(),
      'labName': labName,
      'photoUrls': photoUrls,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClinicalExam.fromMap(Map<String, dynamic> map) {
    return ClinicalExam(
      id: map['id'] as String,
      examName: map['examName'] as String,
      category: ExamCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExamCategory.other,
      ),
      examDate: DateTime.parse(map['examDate'] as String),
      labName: map['labName'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
